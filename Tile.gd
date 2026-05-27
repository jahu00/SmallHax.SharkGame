extends Control


var selected = false: set = set_selected
@onready var sprite = get_node("Sprite2D")
@onready var animationPlayer = get_node("AnimationPlayer")
var state = "Normal"

var data = {
	"color": 0,
	"x": 0,
	"y": 0
}

signal clicked
signal destroyed

func _ready():
	set_color(data.color)
	animationPlayer.play("Default")

func init(tile_data):
	data = tile_data
	position = get_expected_position()

func get_expected_position():
	return Vector2(data.x * Settings.tile_width, data.y * Settings.tile_height)

func set_color(value):
	sprite.frame_coords.x = data.color

func set_selected(value):
	selected = value
	sprite.frame_coords.y = 1 if selected else 0

func _gui_input(event):
	if event is InputEventMouseButton:
		if event.is_pressed():
			emit_signal("clicked", self)

func destroy():
	animationPlayer.connect("animation_finished", Callable(self, "_on_destroyed"))
	animationPlayer.play("Destroy")

func _on_destroyed(animation_name):
	state = "Destroyed"
	queue_free()
	emit_signal("destroyed", self)
