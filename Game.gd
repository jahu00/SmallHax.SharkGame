extends Node2D

onready var tile_layer = get_node("TileLayer")
onready var score_label = get_node("VBoxContainer/HBoxContainer/VBoxContainer/FrameContainer2/ScoreLabel")
onready var next_label = get_node("VBoxContainer/HBoxContainer/VBoxContainer2/MarginContainer/NextLabel")
onready var level_label = get_node("VBoxContainer/MarginContainer/LevelLabel")
onready var bonus_container = get_node("VBoxContainer/BonusContainer")
onready var game_over_container = get_node("GameOverContainer")

var selected_tiles = []
var tiles_to_destroy = []

var tile_move_speed = 750

var data = {
	"score": 0,
	"next": 0,
	"level": 0
}

var state = "PlayerMove"

func _ready():
	randomize()
	next_level()

func next_level():
	data.level += 1
	data.next += 1000 * data.level
	populate_board()
	update_level()
	state = "PlayerMove"

func populate_board():
	for y in range(Settings.board_height):
		for x in range(Settings.board_width):
			var tile = Scenes.Tile.instance()
			tile.data.x = x
			tile.data.y = y
			tile.position = Vector2(x * Settings.tile_width, y * Settings.tile_height)
			tile.data.color = randi() % Settings.colors
			tile.connect("clicked", self, "_on_tile_clicked")
			tile.connect("destroyed", self, "_on_tile_destroyed")
			tile_layer.add_child(tile)

func clear_board(tiles):
	destroy_tiles(tiles)
	var bonus_points = get_bonus_points(len(tiles))
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
			tiles.remove(id)
		
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

func _on_tile_clicked(tile):
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

func _on_tile_destroyed(tile):
	var id = tiles_to_destroy.find(tile)
	if (id == -1):
		return
	
	tiles_to_destroy.remove(id)
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
	if (state == "MoveTiles"):
		var tiles_moved = false
		var tiles = get_tiles()
		var max_move_distance = tile_move_speed * delta
		for tile in tiles:
			var expected_position = Vector2(Settings.tile_width * tile.data.x, Settings.tile_height * tile.data.y)
			if (tile.position == expected_position):
				continue
			
			tiles_moved = true
			
			var move_vector = expected_position - tile.position
			
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
			elif (len(tiles)):
				clear_board(tiles)
			elif (can_advance()):
				next_level()
			else:
				game_over_container.visible = true
				state = "Over"

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
	return tile_count * tile_count * 5

func get_bonus_points(tile_count):
	return 2000 - get_tile_points(tile_count) * 4

func add_score(points):
	data.score += points
	update_score()

func update_level():
	next_label.text = str(data.next)
	level_label.text = "Level " + str(data.level)
	update_score()

func update_score():
	score_label.value = data.score
	if (can_advance()):
		next_label.add_color_override("font_color", Color(0,1,0))
	else:
		next_label.add_color_override("font_color", Color(1,0,0))

func can_advance():
	return data.score >= data.next
