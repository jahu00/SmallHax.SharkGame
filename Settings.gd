extends Node


var tile_height = 64
var tile_width = 64
var tile_y_offset = 32
var tile_x_offset = 32
var board_width = 10
var board_height = 10
var colors = 5
var level_points = 1000
var bonus_points = 2000
var tile_point = 5

# Economy
var coins_per_level = 50
var bonus_to_coins_coefficient = 50
var bonus_tile_threshold = 10

# Shop prices
var bomb_price = 250
var harpoon_price = 500
var shuffle_price = 1000
var extra_life_price = 5000
var net_price = 100

# Powerup visibility
var hide_extra_life = true

# Spinning wheel
var spin_cost = 100

# Localization
const SUPPORTED_LOCALES: Array[String] = ["en", "pl", "es", "de", "fr", "ja"]
const LOCALE_NAMES: Dictionary = {
	"en": "English",
	"pl": "Polski",
	"es": "Español",
	"de": "Deutsch",
	"fr": "Français",
	"ja": "日本語",
}
const SETTINGS_PATH = "user://settings.json"

signal language_changed

var _font_default: Font = null
var _font_japanese: Font = null

func _ready():
	_font_default = load("res://fonts/Ultra/Ultra-Regular.ttf")
	_font_japanese = load("res://fonts/PottaOne/PottaOne-Regular.ttf")
	_load_language()

func get_font() -> Font:
	if TranslationServer.get_locale() == "ja":
		return _font_japanese
	return _font_default

func apply_font(node: Node):
	var font = get_font()
	_apply_font_recursive(node, font)

func _apply_font_recursive(node: Node, font: Font):
	if node is Control:
		if node.has_theme_font_override("font"):
			node.add_theme_font_override("font", font)
	for child in node.get_children():
		_apply_font_recursive(child, font)

func _load_language():
	if FileAccess.file_exists(SETTINGS_PATH):
		var file = FileAccess.open(SETTINGS_PATH, FileAccess.READ)
		if file:
			var content = file.get_as_text()
			file.close()
			var json = JSON.new()
			if json.parse(content) == OK and typeof(json.data) == TYPE_DICTIONARY:
				var data = json.data
				if data.has("locale") and data["locale"] in SUPPORTED_LOCALES:
					TranslationServer.set_locale(data["locale"])
					return
	# First launch: detect system language
	var system_locale = OS.get_locale_language()
	if system_locale in SUPPORTED_LOCALES:
		TranslationServer.set_locale(system_locale)
	else:
		TranslationServer.set_locale("en")
	_save_language()

func set_language(locale: String):
	if locale in SUPPORTED_LOCALES:
		TranslationServer.set_locale(locale)
		_save_language()
		language_changed.emit()

func get_current_locale() -> String:
	return TranslationServer.get_locale()

func _save_language():
	var data = {}
	if FileAccess.file_exists(SETTINGS_PATH):
		var file = FileAccess.open(SETTINGS_PATH, FileAccess.READ)
		if file:
			var content = file.get_as_text()
			file.close()
			var json = JSON.new()
			if json.parse(content) == OK and typeof(json.data) == TYPE_DICTIONARY:
				data = json.data
	data["locale"] = TranslationServer.get_locale()
	var file = FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))
		file.close()
