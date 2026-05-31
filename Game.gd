extends Control

@onready var tile_layer = find_child("TileLayer")
@onready var score_label = find_child("ScoreLabel")
@onready var next_label = find_child("NextLabel")
@onready var level_label = find_child("LevelLabel")
@onready var bonus_container = find_child("BonusContainer")
@onready var gold_panel = find_child("GoldPanel")
@onready var game_over_container = find_child("GameOverContainer")
@onready var give_up_button = find_child("GiveUpButton")
@onready var retry_button = find_child("RetryButton")
@onready var menu_button = find_child("MenuButton")
@onready var powerup_bar = find_child("PowerupBar")

var selected_tiles = []
var tiles_to_destroy = []

var tile_move_speed = 750

var state = "PlayerMove"
var active_powerup = ""

# Track remaining tiles and bonus points for coin awards on level clear
var last_remaining_tiles: int = 0
var last_bonus_points: int = 0

# Extra life visual indication
var extra_life_timer: float = 0.0
var extra_life_showing: bool = false

func _ready():
	give_up_button.pressed.connect(on_game_over_button_pressed)
	retry_button.pressed.connect(Global.new_game)
	menu_button.pressed.connect(on_menu_button_pressed)
	powerup_bar.bomb_activated.connect(on_bomb_activated)
	powerup_bar.harpoon_activated.connect(on_harpoon_activated)
	powerup_bar.shuffle_activated.connect(on_shuffle_activated)
	_update_texts()
	init()

func _update_texts():
	give_up_button.text = tr("GAME_GIVE_UP")
	retry_button.text = tr("GAME_RETRY")
	menu_button.text = tr("GAME_MENU")
	var score_title = find_child("Label2")
	if score_title:
		score_title.text = tr("GAME_SCORE")
	var next_title = find_child("Label3")
	if next_title:
		next_title.text = tr("GAME_NEXT")

func init():
	populate_board()
	update_level()
	update_coin_display()
	state = "PlayerMove"
	update_powerup_bar()

func next_level():
	GameStore.next_level()
	init()
	

func populate_board():
	for tile_data in GameStore.data.tiles:
		var tile = Scenes.Tile.instantiate()
		tile.init(tile_data)
		tile.clicked.connect(on_tile_clicked)
		tile.destroyed.connect(on_tile_destroyed)
		tile_layer.add_child(tile)
		

func clear_board(tiles):
	last_remaining_tiles = len(tiles)
	var bonus_points = get_bonus_points(len(tiles))
	last_bonus_points = bonus_points if bonus_points > 0 else 0
	destroy_tiles(tiles)
	if (bonus_points > 0):
		bonus_container.show_bonus(bonus_points)
		add_score(bonus_points)

func reposition_tiles():
	var board = get_board()
	board = reposition_tiles_down(board)
	board = reposition_tiles_left(board)
	state = "MoveTiles"

func get_board():
	var tiles = get_tiles()
	var board = {}
	for x in range(0, Settings.board_width):
		var column = {}
		for y in range(0, Settings.board_height):
			var tile = get_tile(tiles, x, y)
			
			column[y] = tile
			if (tile == null):
				continue
			
			var id = tiles.find(tile)
			tiles.remove_at(id)
		
		board[x] = column
	
	return board

func reposition_tiles_down(board):
	while(true):
		var tiles_moved = false;
		for x in range(Settings.board_width):
			for y in range(Settings.board_height - 2, -1, -1):
				var tile = board[x][y]
				if (tile == null):
					continue
				var other_tile = board[x][y + 1]
				if (other_tile != null):
					continue
				
				board[x][y + 1] = tile
				tile.data.y = y + 1
				board[x][y] = other_tile
				tiles_moved = true
		
		if (!tiles_moved):
			break
	return board

func reposition_tiles_left(board):
	var new_board = []
	for x in range(Settings.board_width):
		var column_full = false
		var current_x = len(new_board)
		for y in range(Settings.board_height):
			var tile = board[x][y]
			if (tile == null):
				continue
				
			if (!column_full):
				column_full = true
			
			if (x != current_x):
				tile.data.x = current_x
			
		if (column_full):
			new_board.append(board[x])
	
	return new_board

func on_tile_clicked(tile):
	if (state == "PowerupTarget"):
		if active_powerup == "bomb":
			execute_bomb(tile.data.x, tile.data.y)
		elif active_powerup == "harpoon":
			execute_harpoon(tile.data.x)
		return

	if (state == "PlayerMove"):
		if (tile.selected):
			add_score(get_tile_points(len(selected_tiles)))
			destroy_tiles(selected_tiles)
			deselect_tiles()
			return
		
		try_select_tiles(tile)

func try_select_tiles(tile):
	var matching_tiles = get_matching_tiles(tile)
	deselect_tiles()
	if (len(matching_tiles) < 2):
		return
	select_tiles(matching_tiles)

func select_tiles(tiles):
	set_selected_tiles(tiles, true)
	selected_tiles = tiles

func deselect_tiles():
	set_selected_tiles(selected_tiles, false)
	selected_tiles = []

func destroy_tiles(tiles):
	for tile in tiles:
		tile.destroy()
	tiles_to_destroy = [] + tiles
	state = "DestroyTiles"

func on_tile_destroyed(tile):
	var id = tiles_to_destroy.find(tile)
	
	var tile_data_id = GameStore.data.tiles.find(tile.data)
	
	if (tile_data_id != -1):
		GameStore.data.tiles.remove_at(tile_data_id)
	
	if (id == -1):
		return
	
	tiles_to_destroy.remove_at(id)
	
	if (len(tiles_to_destroy) > 0):
		return
	
	reposition_tiles()

func set_selected_tiles(tiles, value):
	for tile in tiles:
		tile.selected = value

func get_matching_tiles(tile):
	var result = [tile]
	var tiles = get_tiles()
	get_matching_neighbours(tile, tiles, result)
	return result

func get_matching_neighbours(tile, tiles, result):
	if (tile.data.x > 0):
		var temp_tile = get_tile(tiles, tile.data.x - 1, tile.data.y)
		check_matching_tile(tile, temp_tile, tiles, result)
	
	if (tile.data.y > 0):
		var temp_tile = get_tile(tiles, tile.data.x, tile.data.y - 1)
		check_matching_tile(tile, temp_tile, tiles, result)
	
	if (tile.data.x < Settings.board_width - 1):
		var temp_tile = get_tile(tiles, tile.data.x + 1, tile.data.y)
		check_matching_tile(tile, temp_tile, tiles, result)
	
	if (tile.data.y < Settings.board_height - 1):
		var temp_tile = get_tile(tiles, tile.data.x, tile.data.y + 1)
		check_matching_tile(tile, temp_tile, tiles, result)
	

func check_matching_tile(tile, neighbour_tile, tiles, result):
	if (neighbour_tile == null || neighbour_tile.data.color != tile.data.color || result.has(neighbour_tile)):
		return
	
	result.append(neighbour_tile)
	get_matching_neighbours(neighbour_tile, tiles, result)

func get_tiles():
	var result = []
	var tiles = tile_layer.get_children()
	for tile in tiles:
		if (tile.state == "Destroyed"):
			continue
		result.append(tile)
	
	return result

func get_tile(tiles, x, y):
	for tile in tiles:
		if (tile.data.x == x && tile.data.y == y):
			return tile
	
	return null

func _process(delta):
	# Handle Extra Life display timer
	if extra_life_showing:
		extra_life_timer -= delta
		if extra_life_timer <= 0.0:
			extra_life_showing = false
			hide_extra_life_label()
			next_level()
		return

	if (state == "MoveTiles"):
		var tiles_moved = false
		var tiles = get_tiles()
		var max_move_distance = tile_move_speed * delta
		for tile in tiles:
			var expected_position = Vector2(Settings.tile_width * tile.data.x, Settings.tile_height * tile.data.y)
			if (tile.position == expected_position):
				#tile.sprite.flip_h = false
				continue
			
			tiles_moved = true
			
			var move_vector = expected_position - tile.position
			
			#if (move_vector.x < 0):
				#tile.sprite.flip_h = true
			
			if (abs(move_vector.x) > max_move_distance):
				tile.position.x += sign(move_vector.x) * max_move_distance
			elif(tile.position.x != expected_position.x):
				tile.position.x = expected_position.x
			
			if (abs(move_vector.y) > max_move_distance):
				tile.position.y += sign(move_vector.y) * max_move_distance
			elif(tile.position.y != expected_position.y):
				tile.position.y = expected_position.y
		
		
		if (!tiles_moved):
			var is_over = check_over()
			if (!is_over):
				state = "PlayerMove"
				update_powerup_bar()
			elif (len(tiles)):
				clear_board(tiles)
			elif (can_advance()):
				GameStore.award_bonus_coins(last_remaining_tiles, last_bonus_points)
				update_coin_display()
				next_level()
			elif GameStore.inventory.extra_life > 0:
				GameStore.use_powerup("extra_life")
				show_extra_life_used()
			else:
				GameStore.award_game_over_coins()
				update_coin_display()
				game_over_container.visible = true
				state = "Over"
				update_powerup_bar()

func check_over():
	var board = get_board()
	for x in range(0, Settings.board_width):
		for y in range(0, Settings.board_height):
			var tile = board[x][y]
			if (tile == null):
				continue
			
			if (x < Settings.board_width - 1):
				var horizontal_neighbour = board[x + 1][y]
				if (horizontal_neighbour != null && tile.data.color == horizontal_neighbour.data.color):
					return false
			
			if (y < Settings.board_height - 1):
				var vertical_neighbour = board[x][y + 1]
				if (vertical_neighbour != null && tile.data.color == vertical_neighbour.data.color):
					return false
	
	return true

func get_tile_points(tile_count):
	return tile_count * tile_count * Settings.tile_point

func get_bonus_points(tile_count):
	return Settings.bonus_points - get_tile_points(tile_count) * (Settings.tile_point - 1)

func add_score(points):
	GameStore.add_points(points)
	update_score()

func update_level():
	next_label.text = str(GameStore.data.next)
	level_label.text = tr("GAME_LEVEL") % GameStore.data.level
	update_score()

func update_score():
	score_label.value = GameStore.data.score
	if (can_advance()):
		next_label.add_theme_color_override("font_color", Color(0,1,0))
	else:
		next_label.add_theme_color_override("font_color", Color(1,0,0))

func can_advance():
	return GameStore.data.score >= GameStore.data.next

func on_game_over_button_pressed():
	Global.end_game()

func on_menu_button_pressed():
	if state == "PlayerMove":
		Global.change_scene_to_file(Scenes.SceneEnum.Menu)

# --- Extra Life visual indication ---

func show_extra_life_used():
	state = "ExtraLifeUsed"
	extra_life_showing = true
	extra_life_timer = 1.0
	var remaining = GameStore.inventory.extra_life
	var extra_life_label = get_node_or_null("ExtraLifeLabel")
	if extra_life_label == null:
		extra_life_label = Label.new()
		extra_life_label.name = "ExtraLifeLabel"
		extra_life_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		extra_life_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		extra_life_label.set_anchors_preset(Control.PRESET_CENTER)
		extra_life_label.add_theme_font_size_override("font_size", 48)
		extra_life_label.add_theme_color_override("font_color", Color(0, 1, 0.5))
		add_child(extra_life_label)
	extra_life_label.text = tr("GAME_EXTRA_LIFE") % remaining
	extra_life_label.visible = true

func hide_extra_life_label():
	var extra_life_label = get_node_or_null("ExtraLifeLabel")
	if extra_life_label != null:
		extra_life_label.visible = false

func update_powerup_bar():
	powerup_bar.update_counts()
	powerup_bar.set_buttons_enabled(state, active_powerup)

func update_coin_display():
	gold_panel.update_coins()

# --- Powerup targeting ---

func on_bomb_activated():
	if state == "PowerupTarget" and active_powerup == "bomb":
		# Re-pressing bomb button cancels targeting
		cancel_powerup_targeting()
		return
	if state != "PlayerMove":
		return
	deselect_tiles()
	state = "PowerupTarget"
	active_powerup = "bomb"
	update_powerup_bar()

func cancel_powerup_targeting():
	active_powerup = ""
	state = "PlayerMove"
	update_powerup_bar()

func execute_bomb(cx: int, cy: int):
	var tiles = get_tiles()
	var bomb_targets = []
	for dx in range(-1, 2):
		for dy in range(-1, 2):
			var tx = cx + dx
			var ty = cy + dy
			if tx < 0 or tx >= Settings.board_width:
				continue
			if ty < 0 or ty >= Settings.board_height:
				continue
			var tile = get_tile(tiles, tx, ty)
			if tile != null:
				bomb_targets.append(tile)
	
	if bomb_targets.size() == 0:
		cancel_powerup_targeting()
		return
	
	var tile_count = bomb_targets.size()
	var points = tile_count * tile_count * Settings.tile_point
	add_score(points)
	
	GameStore.use_powerup("bomb")
	active_powerup = ""
	update_powerup_bar()
	destroy_tiles(bomb_targets)

func on_harpoon_activated():
	if state == "PowerupTarget" and active_powerup == "harpoon":
		# Re-pressing harpoon button cancels targeting
		cancel_powerup_targeting()
		return
	if state != "PlayerMove":
		return
	deselect_tiles()
	state = "PowerupTarget"
	active_powerup = "harpoon"
	update_powerup_bar()

func execute_harpoon(column_x: int):
	var tiles = get_tiles()
	var column_tiles = []
	for tile in tiles:
		if tile.data.x == column_x:
			column_tiles.append(tile)
	
	if column_tiles.size() == 0:
		cancel_powerup_targeting()
		return
	
	var tile_count = column_tiles.size()
	var points = tile_count * tile_count * Settings.tile_point
	add_score(points)
	GameStore.use_powerup("harpoon")
	active_powerup = ""
	update_powerup_bar()
	destroy_tiles(column_tiles)

# --- Shuffle powerup ---

func on_shuffle_activated():
	if state != "PlayerMove":
		return
	GameStore.use_powerup("shuffle")
	deselect_tiles()
	update_powerup_bar()
	execute_shuffle()

func execute_shuffle():
	var tiles = get_tiles()
	
	# Group tiles by column
	var columns: Dictionary = {}
	for tile in tiles:
		var col_x = tile.data.x
		if not columns.has(col_x):
			columns[col_x] = []
		columns[col_x].append(tile)
	
	# For each column, rearrange tiles by greedy color grouping
	for col_x in columns.keys():
		var col_tiles = columns[col_x]
		if col_tiles.size() <= 1:
			continue
		
		# Count frequency of each color
		var color_counts: Dictionary = {}
		for tile in col_tiles:
			var color = tile.data.color
			if not color_counts.has(color):
				color_counts[color] = 0
			color_counts[color] += 1
		
		# Sort colors by frequency (most frequent first)
		var color_list = color_counts.keys()
		color_list.sort_custom(func(a, b): return color_counts[a] > color_counts[b])
		
		# Build ordered tile list: group tiles by color in frequency order
		var ordered_tiles: Array = []
		for color in color_list:
			for tile in col_tiles:
				if tile.data.color == color:
					ordered_tiles.append(tile)
		
		# Find the lowest y position (highest row number = bottom of board)
		# Tiles should be placed bottom-up starting from the highest y in the column
		var max_y = 0
		for tile in col_tiles:
			if tile.data.y > max_y:
				max_y = tile.data.y
		
		# Assign new y positions bottom-up (most frequent color at bottom)
		var current_y = max_y
		for tile in ordered_tiles:
			tile.data.y = current_y
			current_y -= 1
	
	state = "MoveTiles"
