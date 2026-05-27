extends Control

@onready var continue_button = get_node("CenterContainer2/VBoxContainer/ContinueButton")
@onready var new_game_button = get_node("CenterContainer2/VBoxContainer/NewGameButton")
@onready var exit_button = get_node("CenterContainer2/VBoxContainer/ExitButton")
@onready var shop_button = get_node("CenterContainer2/VBoxContainer/ShopButton")
@onready var spinning_wheel_button = get_node("CenterContainer2/VBoxContainer/SpinningWheelButton")
@onready var coin_label = get_node("CoinDisplay/CoinLabel")

func _ready():
	new_game_button.pressed.connect(_on_new_game_pressed)
	continue_button.pressed.connect(_on_continue_pressed)
	exit_button.pressed.connect(_on_exit_pressed)
	shop_button.pressed.connect(_on_shop_pressed)
	spinning_wheel_button.pressed.connect(_on_spinning_wheel_pressed)
	_update_coin_display()

func _on_new_game_pressed():
	Global.new_game()

func _on_continue_pressed():
	Global.change_scene_to_file(Scenes.SceneEnum.Game)

func _on_exit_pressed():
	Global.close_game()

func _on_shop_pressed():
	Global.change_scene_to_file(Scenes.SceneEnum.Shop)

func _on_spinning_wheel_pressed():
	Global.change_scene_to_file(Scenes.SceneEnum.SpinningWheel)

func _update_coin_display():
	coin_label.text = str(GameStore.coins)

func _process(delta):
	if GameStore.data == null and continue_button.visible:
		continue_button.visible = false

	if GameStore.data != null and not continue_button.visible:
		continue_button.visible = true

	_update_coin_display()
