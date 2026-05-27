extends Node2D

@onready var back_button = get_node("CenterContainer/VBoxContainer/BackButton")
@onready var reset_button = get_node("CenterContainer/VBoxContainer/ResetRow/ResetButton")
@onready var confirmation_label = get_node("CenterContainer/VBoxContainer/ConfirmationLabel")

var _confirm_reset: bool = false

func _ready():
	back_button.pressed.connect(_on_back_pressed)
	reset_button.pressed.connect(_on_reset_pressed)

func _on_back_pressed():
	Global.change_scene_to_file(Scenes.SceneEnum.Menu)

func _on_reset_pressed():
	if not _confirm_reset:
		_confirm_reset = true
		reset_button.text = "Are you sure?"
		confirmation_label.text = "This will erase all progress!"
		confirmation_label.add_theme_color_override("font_color", Color(0.9, 0.2, 0.2, 1))
	else:
		GameStore.reset_all_data()
		_confirm_reset = false
		reset_button.text = "Reset Game Data"
		confirmation_label.text = "Game data has been reset."
		confirmation_label.add_theme_color_override("font_color", Color(0.2, 0.8, 0.2, 1))
