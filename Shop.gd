extends Control

@onready var gold_panel = find_child("GoldPanel")
@onready var back_button = find_child("BackButton")

@onready var bomb_button = find_child("BuyBombButton")
@onready var harpoon_button = find_child("BuyHarpoonButton")
@onready var shuffle_button = find_child("BuyShuffleButton")
@onready var extra_life_button = find_child("BuyExtraLifeButton")
@onready var net_button = find_child("BuyNetButton")

@onready var bomb_price_label = find_child("BombPriceContainer")
@onready var harpoon_price_label = find_child("HarpoonPriceContainer")
@onready var shuffle_price_label = find_child("ShufflePriceContainer")
@onready var extra_life_price_label = find_child("ExtraLifePriceContainer")
@onready var net_price_label = find_child("NetPriceContainer")

@onready var bomb_name_label = find_child("BombNameLabel")
@onready var harpoon_name_label = find_child("HarpoonNameLabel")
@onready var shuffle_name_label = find_child("ShuffleNameLabel")
@onready var extra_life_name_label = find_child("ExtraLifeNameLabel")
@onready var net_name_label = find_child("NetNameLabel")

@onready var title_label = find_child("TitleLabel")

@onready var confirmation_label = find_child("ConfirmationLabel")

@onready var bomb_power_button = find_child("BombPowerButton")
@onready var harpoon_power_button = find_child("HarpoonPowerButton")
@onready var shuffle_power_button = find_child("ShufflePowerButton")
@onready var extra_life_power_button = find_child("ExtraLifePowerButton")
@onready var net_power_button = find_child("NetPowerButton")

@onready var extra_life_row = find_child("ExtraLifeRow")

@onready var speach_bubble = find_child("Speach")
@onready var speach_label = find_child("SpeachLabel")
@onready var pirate_node = find_child("Pirate")

var _confirmation_timer: float = 0.0

# --- Pirate dialogue settings ---
## How long pirate text stays visible (seconds)
@export var pirate_text_duration: float = 4.0
## How long before the pirate says an idle line (seconds)
@export var pirate_idle_delay: float = 8.0

var _pirate_text_timer: float = 0.0
var _pirate_idle_timer: float = 0.0
var _pirate_is_speaking: bool = false

# --- Easter egg: pirate singing ---
var _sing_idle_timer: float = 0.0
var _sing_click_times: Array[float] = []
var _singing: bool = false
var _song_lines: Array[String] = []
var _song_line_index: int = 0
var _song_line_timer: float = 0.0
const SONG_LINE_DURATION: float = 3.0
const SONG_GAP_DURATION: float = 0.3

var _song_in_gap: bool = false

var _greetings_keys: Array[String] = [
	"PIRATE_GREET_1",
	"PIRATE_GREET_2",
	"PIRATE_GREET_3",
	"PIRATE_GREET_4",
	"PIRATE_GREET_5",
]

var _idle_lines_keys: Array[String] = [
	"PIRATE_IDLE_1",
	"PIRATE_IDLE_2",
	"PIRATE_IDLE_3",
	"PIRATE_IDLE_4",
	"PIRATE_IDLE_5",
	"PIRATE_IDLE_6",
]

var _purchase_lines_keys: Array[String] = [
	"PIRATE_BUY_1",
	"PIRATE_BUY_2",
	"PIRATE_BUY_3",
	"PIRATE_BUY_4",
	"PIRATE_BUY_5",
	"PIRATE_BUY_6",
]

func _ready():
	bomb_price_label.amount = Settings.bomb_price
	harpoon_price_label.amount = Settings.harpoon_price
	shuffle_price_label.amount = Settings.shuffle_price
	extra_life_price_label.amount = Settings.extra_life_price
	net_price_label.amount = Settings.net_price

	bomb_button.pressed.connect(_on_buy_pressed.bind("bomb"))
	harpoon_button.pressed.connect(_on_buy_pressed.bind("harpoon"))
	shuffle_button.pressed.connect(_on_buy_pressed.bind("shuffle"))
	extra_life_button.pressed.connect(_on_buy_pressed.bind("extra_life"))
	net_button.pressed.connect(_on_buy_pressed.bind("net"))
	back_button.pressed.connect(_on_back_pressed)

	if Settings.hide_extra_life:
		extra_life_row.visible = false

	# Make pirate clickable
	pirate_node.mouse_filter = Control.MOUSE_FILTER_STOP
	pirate_node.gui_input.connect(_on_pirate_gui_input)

	_update_texts()
	Settings.apply_font(self)
	update_affordability()
	update_powerup_counts()

	# Pirate greets the player on shop open
	_pirate_say(tr(_greetings_keys.pick_random()))

func _update_texts():
	title_label.text = tr("SHOP_TITLE")
	bomb_name_label.text = tr("SHOP_BOMB")
	harpoon_name_label.text = tr("SHOP_HARPOON")
	shuffle_name_label.text = tr("SHOP_SHUFFLE")
	extra_life_name_label.text = tr("SHOP_EXTRA_LIFE")
	net_name_label.text = tr("SHOP_NET")
	bomb_button.text = tr("SHOP_BUY")
	harpoon_button.text = tr("SHOP_BUY")
	shuffle_button.text = tr("SHOP_BUY")
	extra_life_button.text = tr("SHOP_BUY")
	net_button.text = tr("SHOP_BUY")
	back_button.text = tr("SHOP_BACK")

func _process(delta):
	if _confirmation_timer > 0.0:
		_confirmation_timer -= delta
		if _confirmation_timer <= 0.0:
			confirmation_label.text = ""

	# Easter egg: singing sequence
	if _singing:
		_song_line_timer -= delta
		if _song_line_timer <= 0.0:
			if _song_in_gap:
				# Gap finished, show next line
				_song_in_gap = false
				_pirate_say_raw(_song_lines[_song_line_index])
				_song_line_timer = SONG_LINE_DURATION
			else:
				# Line finished, start gap or end song
				_song_line_index += 1
				if _song_line_index < _song_lines.size():
					speach_bubble.visible = false
					speach_label.text = ""
					_song_in_gap = true
					_song_line_timer = SONG_GAP_DURATION
				else:
					_singing = false
					_song_in_gap = false
					speach_label.add_theme_font_size_override("font_size", 64)
					_pirate_clear()
					_sing_idle_timer = 0.0
		gold_panel.update_coins()
		return

	# Pirate text timer
	if _pirate_text_timer > 0.0:
		_pirate_text_timer -= delta
		if _pirate_text_timer <= 0.0:
			_pirate_clear()

	# Idle timer — only ticks when pirate is not speaking
	if not _pirate_is_speaking:
		_pirate_idle_timer += delta
		if _pirate_idle_timer >= pirate_idle_delay:
			_pirate_say(tr(_idle_lines_keys.pick_random()))

	# Easter egg: inactivity singing trigger
	_sing_idle_timer += delta
	if _sing_idle_timer >= Settings.pirate_sing_idle_time:
		_start_singing()

	gold_panel.update_coins()

func _on_buy_pressed(item_type: String):
	_sing_idle_timer = 0.0
	var price = _get_price(item_type)
	if GameStore.spend_coins(price):
		GameStore.add_powerup(item_type)
		_show_confirmation(item_type)
		update_affordability()
		update_powerup_counts()
		# Pirate comments on purchase (only if not already speaking)
		if not _pirate_is_speaking:
			_pirate_say(tr(_purchase_lines_keys.pick_random()))

func _on_back_pressed():
	Global.change_scene_to_file(Scenes.SceneEnum.Menu)

func update_affordability():
	gold_panel.update_coins()

	bomb_button.disabled = GameStore.coins < Settings.bomb_price
	harpoon_button.disabled = GameStore.coins < Settings.harpoon_price
	shuffle_button.disabled = GameStore.coins < Settings.shuffle_price
	extra_life_button.disabled = GameStore.coins < Settings.extra_life_price
	net_button.disabled = GameStore.coins < Settings.net_price

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
		"net":
			return Settings.net_price
	return 0

func _show_confirmation(item_type: String):
	var display_name = _get_item_display_name(item_type)
	confirmation_label.text = tr("SHOP_PURCHASED") % display_name
	_confirmation_timer = 2.0

func _get_item_display_name(item_type: String) -> String:
	match item_type:
		"bomb":
			return tr("SHOP_BOMB")
		"harpoon":
			return tr("SHOP_HARPOON")
		"shuffle":
			return tr("SHOP_SHUFFLE")
		"extra_life":
			return tr("SHOP_EXTRA_LIFE")
		"net":
			return tr("SHOP_NET")
	return item_type

func update_powerup_counts():
	bomb_power_button.count = GameStore.inventory["bomb"]
	harpoon_power_button.count = GameStore.inventory["harpoon"]
	shuffle_power_button.count = GameStore.inventory["shuffle"]
	extra_life_power_button.count = GameStore.inventory["extra_life"]
	net_power_button.count = GameStore.inventory["net"]

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

# --- Easter egg: pirate singing ---

func _on_pirate_gui_input(event: InputEvent):
	if _singing:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_sing_idle_timer = 0.0
		var now = Time.get_ticks_msec() / 1000.0
		_sing_click_times.append(now)
		# Remove clicks outside the window
		var window_start = now - Settings.pirate_sing_click_window
		_sing_click_times = _sing_click_times.filter(func(t): return t >= window_start)
		if _sing_click_times.size() >= Settings.pirate_sing_click_count:
			_sing_click_times.clear()
			_start_singing()

func _start_singing():
	_singing = true
	_song_lines = [
		tr("PIRATE_SONG_1A"),
		tr("PIRATE_SONG_1B"),
		tr("PIRATE_SONG_1C"),
		tr("PIRATE_SONG_1D"),
		tr("PIRATE_SONG_2A"),
		tr("PIRATE_SONG_2B"),
		tr("PIRATE_SONG_2C"),
		tr("PIRATE_SONG_2D"),
	]
	_song_line_index = 0
	_song_line_timer = SONG_LINE_DURATION
	speach_label.add_theme_font_size_override("font_size", 48)
	_pirate_say_raw(_song_lines[0])

func _pirate_say_raw(text: String):
	speach_label.text = text
	speach_bubble.visible = true
	_pirate_is_speaking = true
	_pirate_idle_timer = 0.0
