extends MarginContainer

@onready var bonus_label = get_node("HBoxContainer/BonusLabel")
var disappear_speed = 0.25


func _ready():
	pass

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
