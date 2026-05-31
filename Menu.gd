extends Control

@onready var continue_button = get_node("CenterContainer2/VBoxContainer/ContinueButton")
@onready var new_game_button = get_node("CenterContainer2/VBoxContainer/NewGameButton")
@onready var exit_button = get_node("CenterContainer2/VBoxContainer/ExitButton")
@onready var shop_button = get_node("CenterContainer2/VBoxContainer/ShopButton")
@onready var spinning_wheel_button = get_node("CenterContainer2/VBoxContainer/SpinningWheelButton")
@onready var settings_button = get_node("CenterContainer2/VBoxContainer/SettingsButton")
@onready var gold_panel = get_node("GoldPanel")

func _ready():
	new_game_button.pressed.connect(_on_new_game_pressed)
	continue_button.pressed.connect(_on_continue_pressed)
	exit_button.pressed.connect(_on_exit_pressed)
	shop_button.pressed.connect(_on_shop_pressed)
	spinning_wheel_button.pressed.connect(_on_spinning_wheel_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	_update_texts()
	Settings.apply_font(self)
	_update_coin_display()

func _update_texts():
	continue_button.text = tr("MENU_CONTINUE")
	new_game_button.text = tr("MENU_NEW_GAME")
	shop_button.text = tr("MENU_SHOP")
	spinning_wheel_button.text = tr("MENU_SPIN_THE_WHEEL")
	settings_button.text = tr("MENU_SETTINGS")
	exit_button.text = tr("MENU_EXIT")

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

func _on_settings_pressed():
	Global.change_scene_to_file(Scenes.SceneEnum.SettingsMenu)

func _update_coin_display():
	gold_panel.update_coins()

func _process(delta):
	if GameStore.data == null and continue_button.visible:
		continue_button.visible = false

	if GameStore.data != null and not continue_button.visible:
		continue_button.visible = true

	_update_coin_display()
