extends Node2D

func _ready():
	Global.scene_changing.connect(on_scene_changing)
	Global.game_starting.connect(on_game_starting)
	Global.game_ending.connect(on_game_ending)
	Global.game_closing.connect(on_game_closing)
	Global.change_scene_to_file(Scenes.SceneEnum.Menu)

func on_scene_changing(scene_enum):
	clear_scene()
	await get_tree().process_frame
	match (scene_enum):
		Scenes.SceneEnum.Menu:
			var scene = Scenes.Menu.instantiate()
			add_child(scene)
		Scenes.SceneEnum.Game:
			var scene = Scenes.Game.instantiate()
			add_child(scene)
		Scenes.SceneEnum.Shop:
			var scene = Scenes.Shop.instantiate()
			add_child(scene)
		Scenes.SceneEnum.SpinningWheel:
			var scene = Scenes.SpinningWheel.instantiate()
			add_child(scene)

func clear_scene():
	for child in get_children():
		child.queue_free()

func on_game_starting():
	Global.change_scene_to_file(Scenes.SceneEnum.Game)

func on_game_ending():
	GameStore.save_data()
	GameStore.clear_data()
	Global.change_scene_to_file(Scenes.SceneEnum.Menu)

func on_game_closing():
	get_tree().quit()
