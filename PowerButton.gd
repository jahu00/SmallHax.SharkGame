@tool extends Button

class_name PowerButton

@onready var power_count_label: Label = find_child("PowerCount")
@onready var power_indicator: ReferenceRect = find_child("PowerIndicator")
@onready var outline: ReferenceRect = find_child("Outline")

@export var count: int:
	set(value):
		count = value
		if power_count_label:
			power_count_label.text = str(value)

@export var selected: bool:
	set(value):
		selected = value
		if power_indicator:
			power_indicator.visible = value

@export var show_outline: bool:
	set(value):
		show_outline = value
		if outline:
			outline.visible = value

func _ready() -> void:
	power_count_label.text = str(count)
	power_indicator.visible = selected
	outline.visible = show_outline
