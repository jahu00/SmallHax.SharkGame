extends Node

var data

# Persistent state (loaded on _ready, saved on change)
var coins: int = 0
var inventory: Dictionary = {"bomb": 0, "harpoon": 0, "shuffle": 0, "extra_life": 0, "net": 0}

const SAVE_PATH = "user://save_data.json"
const MAX_COINS = 999_999_999
const MAX_POWERUP = 99

func _ready():
	randomize()
	load_data()

func load_data():
	if not FileAccess.file_exists(SAVE_PATH):
		_initialize_defaults()
		return

	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		_initialize_defaults()
		return

	var content = file.get_as_text()
	file.close()

	var json = JSON.new()
	var parse_result = json.parse(content)
	if parse_result != OK:
		_initialize_defaults()
		return

	var parsed = json.data
	if typeof(parsed) != TYPE_DICTIONARY:
		_initialize_defaults()
		return

	# Restore coins
	if parsed.has("coins") and typeof(parsed["coins"]) in [TYPE_INT, TYPE_FLOAT]:
		coins = clampi(int(parsed["coins"]), 0, MAX_COINS)
	else:
		coins = 0

	# Restore inventory
	if parsed.has("inventory") and typeof(parsed["inventory"]) == TYPE_DICTIONARY:
		var saved_inv = parsed["inventory"]
		# Migrate old "rocket" key to "harpoon"
		if saved_inv.has("rocket") and not saved_inv.has("harpoon"):
			saved_inv["harpoon"] = saved_inv["rocket"]
		for key in inventory.keys():
			if saved_inv.has(key) and typeof(saved_inv[key]) in [TYPE_INT, TYPE_FLOAT]:
				inventory[key] = clampi(int(saved_inv[key]), 0, MAX_POWERUP)
			else:
				inventory[key] = 0
	else:
		_initialize_defaults_inventory()

func save_data():
	var save_dict = {
		"coins": coins,
		"inventory": inventory.duplicate()
	}

	var json_string = JSON.stringify(save_dict)

	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		# Write failed — retain in-memory state, will reattempt on next change
		return

	file.store_string(json_string)
	file.close()

func add_coins(amount: int):
	coins = mini(coins + amount, MAX_COINS)
	save_data()

func spend_coins(amount: int) -> bool:
	if coins < amount:
		return false
	coins -= amount
	save_data()
	return true

func add_powerup(type: String, count: int = 1):
	if not inventory.has(type):
		return
	inventory[type] = mini(inventory[type] + count, MAX_POWERUP)
	save_data()

func use_powerup(type: String) -> bool:
	if not inventory.has(type):
		return false
	if inventory[type] <= 0:
		return false
	inventory[type] -= 1
	save_data()
	return true

func award_game_over_coins():
	var earned = data.level * Settings.coins_per_level
	add_coins(earned)

func award_bonus_coins(remaining_tiles: int, bonus_points: int):
	if remaining_tiles <= Settings.bonus_tile_threshold:
		var bonus_coins = int(floor((Settings.bonus_tile_threshold - remaining_tiles) * Settings.bonus_to_coins_coefficient))
		add_coins(bonus_coins)

func reset_all_data():
	_initialize_defaults()
	clear_data()
	save_data()

func _initialize_defaults():
	coins = 0
	_initialize_defaults_inventory()

func _initialize_defaults_inventory():
	inventory = {"bomb": 0, "harpoon": 0, "shuffle": 0, "extra_life": 0, "net": 0}

# --- Existing game session methods ---

func clear_data():
	data = null

func new_game():
	data = {
		"score": 0,
		"next": 0,
		"level": 0,
	}
	next_level()

func next_level():
	data.level += 1
	data.next += Settings.level_points * data.level
	clear_tiles()
	prepare_tiles()

func clear_tiles():
	data.tiles = []

func prepare_tiles():
	for y in range(Settings.board_height):
		for x in range(Settings.board_width):
			var tile = {
				"x": x,
				"y": y,
				"color": randi() % Settings.colors
			}
			data.tiles.append(tile)

func remove_tile(tile):
	var id = data.tiles.find(tile)
	if (id == -1):
		return

	data.tiles.remove_at(id)

func add_points(points):
	data.score += points
