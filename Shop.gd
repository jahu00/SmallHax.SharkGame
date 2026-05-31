extends Control

@onready var gold_panel = get_node("GoldPanel")
@onready var back_button = get_node("CenterContainer/VBoxContainer/BackButton")

@onready var bomb_button = get_node("CenterContainer/VBoxContainer/BombRow/BuyBombButton")
@onready var harpoon_button = get_node("CenterContainer/VBoxContainer/HarpoonRow/BuyHarpoonButton")
@onready var shuffle_button = get_node("CenterContainer/VBoxContainer/ShuffleRow/BuyShuffleButton")
@onready var extra_life_button = get_node("CenterContainer/VBoxContainer/ExtraLifeRow/BuyExtraLifeButton")

@onready var bomb_price_label = get_node("CenterContainer/VBoxContainer/BombRow/BombPriceLabel")
@onready var harpoon_price_label = get_node("CenterContainer/VBoxContainer/HarpoonRow/HarpoonPriceLabel")
@onready var shuffle_price_label = get_node("CenterContainer/VBoxContainer/ShuffleRow/ShufflePriceLabel")
@onready var extra_life_price_label = get_node("CenterContainer/VBoxContainer/ExtraLifeRow/ExtraLifePriceLabel")

@onready var confirmation_label = get_node("CenterContainer/VBoxContainer/ConfirmationLabel")

@onready var bomb_power_button = get_node("CenterContainer/VBoxContainer/BombRow/BombPowerButton")
@onready var harpoon_power_button = get_node("CenterContainer/VBoxContainer/HarpoonRow/HarpoonPowerButton")
@onready var shuffle_power_button = get_node("CenterContainer/VBoxContainer/ShuffleRow/ShufflePowerButton")
@onready var extra_life_power_button = get_node("CenterContainer/VBoxContainer/ExtraLifeRow/ExtraLifePowerButton")

var _confirmation_timer: float = 0.0

func _ready():
	bomb_price_label.text = str(Settings.bomb_price) + " coins"
	harpoon_price_label.text = str(Settings.harpoon_price) + " coins"
	shuffle_price_label.text = str(Settings.shuffle_price) + " coins"
	extra_life_price_label.text = str(Settings.extra_life_price) + " coins"

	bomb_button.pressed.connect(_on_buy_pressed.bind("bomb"))
	harpoon_button.pressed.connect(_on_buy_pressed.bind("harpoon"))
	shuffle_button.pressed.connect(_on_buy_pressed.bind("shuffle"))
	extra_life_button.pressed.connect(_on_buy_pressed.bind("extra_life"))
	back_button.pressed.connect(_on_back_pressed)

	update_affordability()
	update_powerup_counts()

func _process(delta):
	if _confirmation_timer > 0.0:
		_confirmation_timer -= delta
		if _confirmation_timer <= 0.0:
			confirmation_label.text = ""

	gold_panel.update_coins()

func _on_buy_pressed(item_type: String):
	var price = _get_price(item_type)
	if GameStore.spend_coins(price):
		GameStore.add_powerup(item_type)
		_show_confirmation(item_type)
		update_affordability()
		update_powerup_counts()

func _on_back_pressed():
	Global.change_scene_to_file(Scenes.SceneEnum.Menu)

func update_affordability():
	gold_panel.update_coins()

	bomb_button.disabled = GameStore.coins < Settings.bomb_price
	harpoon_button.disabled = GameStore.coins < Settings.harpoon_price
	shuffle_button.disabled = GameStore.coins < Settings.shuffle_price
	extra_life_button.disabled = GameStore.coins < Settings.extra_life_price

func _get_price(item_type: String) -> int:
	match item_type:
		"bomb":
			return Settings.bomb_price
		"harpoon":
			return Settings.harpoon_price
		"shuffle":
			return Settings.shuffle_price
		"extra_life":
			return Settings.extra_life_price
	return 0

func _show_confirmation(item_type: String):
	var display_name = item_type.replace("_", " ").capitalize()
	confirmation_label.text = "Purchased " + display_name + "!"
	_confirmation_timer = 2.0

func update_powerup_counts():
	bomb_power_button.count = GameStore.inventory["bomb"]
	harpoon_power_button.count = GameStore.inventory["harpoon"]
	shuffle_power_button.count = GameStore.inventory["shuffle"]
	extra_life_power_button.count = GameStore.inventory["extra_life"]
