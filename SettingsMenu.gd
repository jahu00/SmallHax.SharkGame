extends Control

@onready var back_button = get_node("CenterContainer/VBoxContainer/BackButton")
@onready var reset_button = get_node("CenterContainer/VBoxContainer/ResetRow/ResetButton")
@onready var confirmation_label = get_node("CenterContainer/VBoxContainer/ConfirmationLabel")
@onready var language_option = get_node("CenterContainer/VBoxContainer/LanguageRow/LanguageOptionButton")

var _confirm_reset: bool = false

func _ready():
	back_button.pressed.connect(_on_back_pressed)
	reset_button.pressed.connect(_on_reset_pressed)
	language_option.item_selected.connect(_on_language_selected)
	_setup_language_options()
	_update_texts()

func _setup_language_options():
	language_option.clear()
	var current_locale = Settings.get_current_locale()
	var selected_index = 0
	for i in range(Settings.SUPPORTED_LOCALES.size()):
		var locale = Settings.SUPPORTED_LOCALES[i]
		var name = Settings.LOCALE_NAMES[locale]
		language_option.add_item(name, i)
		if locale == current_locale:
			selected_index = i
	language_option.selected = selected_index

func _on_language_selected(index: int):
	var locale = Settings.SUPPORTED_LOCALES[index]
	Settings.set_language(locale)
	_update_texts()

func _update_texts():
	back_button.text = tr("SHOP_BACK")
	reset_button.text = tr("SETTINGS_RESET_BUTTON") if not _confirm_reset else tr("SETTINGS_CONFIRM")
	get_node("CenterContainer/VBoxContainer/TitleLabel").text = tr("SETTINGS_TITLE")
	get_node("CenterContainer/VBoxContainer/ResetRow/ResetLabel").text = tr("SETTINGS_ERASE_PROGRESS")
	get_node("CenterContainer/VBoxContainer/LanguageRow/LanguageLabel").text = tr("SETTINGS_LANGUAGE")

func _on_back_pressed():
	Global.change_scene_to_file(Scenes.SceneEnum.Menu)

func _on_reset_pressed():
	if not _confirm_reset:
		_confirm_reset = true
		reset_button.text = tr("SETTINGS_CONFIRM")
		confirmation_label.text = tr("SETTINGS_CONFIRM_WARNING")
		confirmation_label.add_theme_color_override("font_color", Color(0.9, 0.2, 0.2, 1))
	else:
		GameStore.reset_all_data()
		_confirm_reset = false
		reset_button.text = tr("SETTINGS_RESET_BUTTON")
		confirmation_label.text = tr("SETTINGS_RESET_DONE")
		confirmation_label.add_theme_color_override("font_color", Color(0.2, 0.8, 0.2, 1))
