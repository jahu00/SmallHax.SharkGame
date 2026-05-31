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
var bomb_price = 100
var harpoon_price = 250
var shuffle_price = 500
var extra_life_price = 1000

# Spinning wheel
var spin_cost = 100

# Localization
const SUPPORTED_LOCALES: Array[String] = ["en", "pl", "es", "de", "fr"]
const LOCALE_NAMES: Dictionary = {
	"en": "English",
	"pl": "Polski",
	"es": "Español",
	"de": "Deutsch",
	"fr": "Français",
}
const SETTINGS_PATH = "user://settings.json"

func _ready():
	_load_language()

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
