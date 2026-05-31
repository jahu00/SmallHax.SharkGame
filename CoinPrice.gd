extends HBoxContainer

@export var amount: int = 0:
	set(value):
		amount = value
		if is_inside_tree():
			_update_label()

@onready var price_label = $PriceLabel

func _ready():
	_update_label()

func _update_label():
	price_label.text = str(amount)
