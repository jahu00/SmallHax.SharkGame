extends MarginContainer

@onready var bonus_label = get_node("HBoxContainer/BonusLabel")
@onready var bonus_title_label = get_node("HBoxContainer/Label")
var disappear_speed = 0.25


func _ready():
	bonus_title_label.text = tr("GAME_BONUS")
	Settings.apply_font(self)

func show_bonus(value):
	bonus_label.display_value = 0
	bonus_label.value = value
	modulate.a = 1.0

func _process(delta):
	if (modulate.a == 0 || bonus_label.display_value < bonus_label.value):
		return
	
	var alpha = modulate.a - disappear_speed * delta
	
	if (alpha < 0):
		alpha = 0
	
	modulate.a = alpha
