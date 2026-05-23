extends Node

var data

func _ready():
	randomize()

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
