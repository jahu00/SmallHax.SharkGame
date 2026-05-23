extends Node

signal scene_changing
signal game_closing
signal game_ending
signal game_starting
signal coins_changed
signal inventory_changed

func new_game():
	GameStore.new_game()
	game_starting.emit()

func change_scene_to_file(target_scene):
	scene_changing.emit(target_scene)

func close_game():
	game_closing.emit()

func end_game():
	game_ending.emit()
