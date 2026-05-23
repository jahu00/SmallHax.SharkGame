extends Node

signal scene_changing
signal game_closing
signal game_ending
signal game_starting

func new_game():
	GameStore.new_game()
	emit_signal("game_starting")

func change_scene_to_file(target_scene):
	emit_signal("scene_changing", target_scene)

func close_game():
	emit_signal("game_closing")

func end_game():
	emit_signal("game_ending")
