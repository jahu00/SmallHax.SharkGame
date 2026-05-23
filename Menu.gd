extends Node2D

@onready var continue_button = get_node("CenterContainer2/VBoxContainer/ContinueButton")
@onready var new_game_button = get_node("CenterContainer2/VBoxContainer/NewGameButton")
@onready var exit_button = get_node("CenterContainer2/VBoxContainer/ExitButton")

func _ready():
	exit_button.connect("gui_input", Callable(self, "exit_button_input"))
	new_game_button.connect("gui_input", Callable(self, "new_game_button_input"))
	continue_button.connect("gui_input", Callable(self, "continue_button_input"))

func new_game_button_input(event):
	if event is InputEventMouseButton or event is InputEventScreenTouch:
		Global.new_game()

func continue_button_input(event):
	if event is InputEventMouseButton or event is InputEventScreenTouch:
		Global.change_scene_to_file(Scenes.SceneEnum.Game)

func exit_button_input(event):
	if event is InputEventMouseButton or event is InputEventScreenTouch:
		Global.close_game()

func _process(delta):
	if (GameStore.data == null && continue_button.visible):
		continue_button.visible = false
	
	if (GameStore.data != null && !continue_button.visible):
		continue_button.visible = true
