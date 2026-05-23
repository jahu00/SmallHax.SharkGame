extends Node2D

func _ready():
	Global.connect("scene_changing", Callable(self, "on_scene_changing"))
	Global.connect("game_starting", Callable(self, "on_game_starting"))
	Global.connect("game_ending", Callable(self, "on_game_ending"))
	Global.connect("game_closing", Callable(self, "on_game_closing"))
	Global.change_scene_to_file(Scenes.SceneEnum.Menu)

func on_scene_changing(scene_enum):
	clear_scene()
	match (scene_enum):
		Scenes.SceneEnum.Menu:
			var menu = Scenes.Menu.instantiate()
			add_child(menu)
		Scenes.SceneEnum.Game:
			var menu = Scenes.Game.instantiate()
			add_child(menu)

func clear_scene():
	for child in get_children():
		child.queue_free()

func on_game_starting():
	Global.change_scene_to_file(Scenes.SceneEnum.Game)

func on_game_ending():
	GameStore.clear_data()
	Global.change_scene_to_file(Scenes.SceneEnum.Menu)

func on_game_closing():
	get_tree().quit()
