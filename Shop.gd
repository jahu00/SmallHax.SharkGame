extends Control

@onready var gold_panel = find_child("GoldPanel")
@onready var back_button = find_child("BackButton")

@onready var bomb_button = find_child("BuyBombButton")
@onready var harpoon_button = find_child("BuyHarpoonButton")
@onready var shuffle_button = find_child("BuyShuffleButton")
@onready var extra_life_button = find_child("BuyExtraLifeButton")

@onready var bomb_price_label = find_child("BombPriceLabel")
@onready var harpoon_price_label = find_child("HarpoonPriceLabel")
@onready var shuffle_price_label = find_child("ShufflePriceLabel")
@onready var extra_life_price_label = find_child("ExtraLifePriceLabel")

@onready var confirmation_label = find_child("ConfirmationLabel")

@onready var bomb_power_button = find_child("BombPowerButton")
@onready var harpoon_power_button = find_child("HarpoonPowerButton")
@onready var shuffle_power_button = find_child("ShufflePowerButton")
@onready var extra_life_power_button = find_child("ExtraLifePowerButton")

@onready var speach_bubble = find_child("Speach")
@onready var speach_label = find_child("SpeachLabel")

var _confirmation_timer: float = 0.0

# --- Pirate dialogue settings ---
## How long pirate text stays visible (seconds)
@export var pirate_text_duration: float = 4.0
## How long before the pirate says an idle line (seconds)
@export var pirate_idle_delay: float = 8.0

var _pirate_text_timer: float = 0.0
var _pirate_idle_timer: float = 0.0
var _pirate_is_speaking: bool = false

var _greetings: Array[String] = [
	"Ahoy, matey!",
	"Welcome aboard!",
	"What'll it be today?",
	"Back for more, eh?",
	"Step right up!",
]

var _idle_lines: Array[String] = [
	"Take yer time...",
	"What treasury be ye after?",
	"Fine goods, fair prices!",
	"Don't be shy now.",
	"I got all day, matey.",
	"See anything\nye fancy?",
]

var _purchase_lines: Array[String] = [
	"Excellent choice!",
	"Ye won't regret that!",
	"A wise investment!",
	"Good pick, matey!",
	"That'll serve ye well!",
	"Pleasure doin' business!",
]

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

	# Pirate greets the player on shop open
	_pirate_say(_greetings.pick_random())

func _process(delta):
	if _confirmation_timer > 0.0:
		_confirmation_timer -= delta
		if _confirmation_timer <= 0.0:
			confirmation_label.text = ""

	# Pirate text timer
	if _pirate_text_timer > 0.0:
		_pirate_text_timer -= delta
		if _pirate_text_timer <= 0.0:
			_pirate_clear()

	# Idle timer — only ticks when pirate is not speaking
	if not _pirate_is_speaking:
		_pirate_idle_timer += delta
		if _pirate_idle_timer >= pirate_idle_delay:
			_pirate_say(_idle_lines.pick_random())

	gold_panel.update_coins()

func _on_buy_pressed(item_type: String):
	var price = _get_price(item_type)
	if GameStore.spend_coins(price):
		GameStore.add_powerup(item_type)
		_show_confirmation(item_type)
		update_affordability()
		update_powerup_counts()
		# Pirate comments on purchase (only if not already speaking)
		if not _pirate_is_speaking:
			_pirate_say(_purchase_lines.pick_random())

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

# --- Pirate dialogue helpers ---

func _pirate_say(text: String):
	speach_label.text = text
	speach_bubble.visible = true
	_pirate_text_timer = pirate_text_duration
	_pirate_is_speaking = true
	_pirate_idle_timer = 0.0

func _pirate_clear():
	speach_label.text = ""
	speach_bubble.visible = false
	_pirate_is_speaking = false
	_pirate_idle_timer = 0.0
