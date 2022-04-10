extends Area2D


# Declare member variables here. Examples:
var selected = false setget set_selected
onready var sprite = get_node("Sprite")
onready var animationPlayer = get_node("AnimationPlayer")
var state = "Normal"

var data = {
	"color": 0,
	"x": 0,
	"y": 0
}

signal clicked
signal destroyed

# Called when the node enters the scene tree for the first time.
func _ready():
	connect("input_event", self, "_on_Tile_input_event")
	set_color(data.color)
	animationPlayer.play("Default")
	pass # Replace with function body.


func set_color(value):
	sprite.frame_coords.x = data.color

func set_selected(value):
	selected = value
	sprite.frame_coords.y = 1 if selected else 0

func _on_Tile_input_event(camera, event, _position):
	if (event is InputEventMouseButton):
		if (event.is_pressed()):
			emit_signal("clicked", self)
		#setSelected(!selected)

func destroy():
	animationPlayer.connect("animation_finished", self, "_on_destroyed")
	animationPlayer.play("Destroy")

func _on_destroyed(animation_name):
	state = "Destroyed"
	queue_free()
	emit_signal("destroyed", self)
