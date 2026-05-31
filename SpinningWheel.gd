extends Control

const PRIZES = [
	{"type": "nothing", "amount": 0},
	{"type": "bomb", "amount": 1},
	{"type": "nothing", "amount": 0},
	{"type": "harpoon", "amount": 1},
	{"type": "nothing", "amount": 0},
	{"type": "shuffle", "amount": 1},
	{"type": "nothing", "amount": 0},
	{"type": "extra_life", "amount": 1},
]

const SEGMENT_COUNT = 8
const SEGMENT_ANGLE = TAU / SEGMENT_COUNT

# Reward icons — loaded once, reused per segment
var _reward_textures: Dictionary = {}

# Tuning variables for icon placement and rotation
@export var icon_radius: float = 200.0          # Distance from center to icon
@export var icon_angle_offset: float = 0 #0.5 * SEGMENT_ANGLE    # Angular offset for icon placement (radians)
@export var icon_rotation_offset: float = 0 # Extra rotation applied to each icon (radians)

@onready var gold_panel = get_node("GoldPanel")
@onready var spin_button = get_node("CenterContainer/VBoxContainer/SpinButton")
@onready var back_button = get_node("CenterContainer/VBoxContainer/BackButton")
@onready var prize_result_label = get_node("CenterContainer/VBoxContainer/PrizeResultLabel")
@onready var spin_cost_label = get_node("CenterContainer/VBoxContainer/SpinCostLabel")
@onready var wheel_node = get_node("CenterContainer/VBoxContainer/WheelContainer/WheelNode")

var _is_spinning: bool = false
var _result_display_timer: float = 0.0
var _icon_sprites: Array = []

func _ready():
	_load_reward_textures()
	spin_cost_label.text = tr("SPIN_COST") % Settings.spin_cost
	spin_button.pressed.connect(_on_spin_pressed)
	back_button.pressed.connect(_on_back_pressed)
	_update_texts()
	Settings.apply_font(self)
	_update_coin_display()
	_update_spin_affordability()
	_draw_wheel_segments()

func _update_texts():
	spin_button.text = tr("SPIN_BUTTON")
	back_button.text = tr("SPIN_BACK")
	get_node("CenterContainer/VBoxContainer/PanelContainer/TitleLabel").text = tr("SPIN_TITLE")

func _load_reward_textures():
	_reward_textures = {
		"bomb": load("res://assets/bomb.png"),
		"harpoon": load("res://assets/harpoon.png"),
		"shuffle": load("res://assets/shuffle.png"),
		"extra_life": load("res://assets/extra_life.png"),
		"nothing": null,
	}

func _process(delta):
	if _result_display_timer > 0.0:
		_result_display_timer -= delta
		if _result_display_timer <= 0.0:
			prize_result_label.text = ""
			_update_spin_affordability()

	# Counter-rotate icons so they stay upright while the wheel spins
	# Each icon is a child of wheel_node, so its global rotation = wheel_node.rotation + sprite.rotation
	# We want global rotation = 0 (upright), so sprite.rotation = -wheel_node.rotation
	for sprite in _icon_sprites:
		sprite.rotation = -wheel_node.rotation + icon_rotation_offset

	gold_panel.update_coins()

func _draw_wheel_segments():
	var radius = 200.0

	# Place the steering-wheel.png texture as the wheel background
	var wheel_texture = load("res://assets/steering-wheel.png")
	if wheel_texture:
		var wheel_sprite = Sprite2D.new()
		wheel_sprite.texture = wheel_texture
		var tex_size = wheel_texture.get_size()
		var desired_diameter = radius * 2.2
		wheel_sprite.scale = Vector2(desired_diameter / tex_size.x, desired_diameter / tex_size.y)
		wheel_node.add_child(wheel_sprite)

	# Add reward icons in front of the wheel
	for i in range(SEGMENT_COUNT):
		var icon_node = _create_reward_icon(i, radius)
		wheel_node.add_child(icon_node)

func _create_reward_icon(index: int, _radius: float) -> Node2D:
	var icon_container = Node2D.new()

	var prize = PRIZES[index]
	var tex = _reward_textures.get(prize.type, null)

	var mid_angle = index * SEGMENT_ANGLE + SEGMENT_ANGLE / 2.0 + icon_angle_offset
	var icon_pos = Vector2(cos(mid_angle), sin(mid_angle)) * icon_radius

	if tex:
		# Draw a semi-transparent white circle behind the icon
		var circle_bg = _create_circle_background(icon_pos)
		icon_container.add_child(circle_bg)
		_icon_sprites.append(circle_bg)

		var sprite = Sprite2D.new()
		sprite.texture = tex
		# Scale icon to be prominent in the segment (target ~64x64 pixels)
		var icon_size = 64.0
		var tex_size = tex.get_size()
		sprite.scale = Vector2(icon_size / tex_size.x, icon_size / tex_size.y)
		sprite.position = icon_pos
		# rotation = 0 means upright at start (wheel_node.rotation = 0)
		sprite.rotation = 0
		icon_container.add_child(sprite)
		_icon_sprites.append(sprite)

	return icon_container

func _create_circle_background(pos: Vector2) -> Node2D:
	# Create a white semi-transparent circle using a Polygon2D
	var circle = Polygon2D.new()
	var points: PackedVector2Array = PackedVector2Array()
	var circle_radius = 40.0
	var segments = 24
	for i in range(segments):
		var angle = TAU * i / segments
		points.append(Vector2(cos(angle), sin(angle)) * circle_radius)
	circle.polygon = points
	circle.color = Color(1.0, 1.0, 1.0, 0.6)
	circle.position = pos
	return circle

func _on_spin_pressed():
	if _is_spinning:
		return
	if GameStore.coins < Settings.spin_cost:
		return

	# Deduct spin cost
	GameStore.spend_coins(Settings.spin_cost)
	_update_coin_display()

	# Disable spin button and start animation
	_is_spinning = true
	spin_button.disabled = true
	prize_result_label.text = ""

	_start_spin_animation()

func _start_spin_animation():
	# "reset" rotation
	wheel_node.rotation = fposmod(wheel_node.rotation, TAU)
	# Generate random final position
	var final_angle = randf() * TAU
	# Randomized duration between 2 and 4 seconds
	var spin_duration = randf_range(2.0, 4.0)
	# Multiple full rotations (3-5) plus the final position
	var full_rotations = randi_range(3, 5) * TAU
	var total_rotation = full_rotations + final_angle

	# Tween the wheel rotation with ease-out
	var tween = create_tween()
	tween.tween_property(wheel_node, "rotation", total_rotation, spin_duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_callback(_on_spin_animation_complete.bind(final_angle))

func _on_spin_animation_complete(final_angle: float):
	# The pointer is at the top (angle = -PI/2 in Godot's coordinate system).
	# After the wheel rotates by total_rotation, we need to find which segment
	# is under the pointer. The wheel's final rotation = final_angle (mod TAU).
	# The segment originally at angle A is now at angle (A + wheel_rotation).
	# We want A + wheel_rotation ≡ -PI/2 (mod TAU), so A = -PI/2 - final_angle.
	# Normalize to [0, TAU] and divide by SEGMENT_ANGLE to get the index.
	var pointer_angle = -PI / 2.0
	var segment_angle = fposmod(pointer_angle - final_angle, TAU)
	var segment_index = int(floor(segment_angle / SEGMENT_ANGLE))
	segment_index = clampi(segment_index, 0, SEGMENT_COUNT - 1)
	_on_spin_complete(segment_index)

func _on_spin_complete(segment_index: int):
	var prize = get_prize(segment_index)

	# Award the prize
	match prize.type:
		"nothing":
			pass
		_:
			GameStore.add_powerup(prize.type, prize.amount)

	# Display result
	var result_text = _get_prize_display_text(prize)
	prize_result_label.text = result_text
	_result_display_timer = 2.5

	# Update coin display
	_update_coin_display()

	# Re-enable spinning after result display
	_is_spinning = false

func get_prize(index: int) -> Dictionary:
	if index < 0 or index >= PRIZES.size():
		return {"type": "nothing", "amount": 0}
	return PRIZES[index]

func _get_prize_display_text(prize: Dictionary) -> String:
	match prize.type:
		"nothing":
			return tr("SPIN_NOTHING")
		"bomb":
			return tr("SPIN_WON") % [prize.amount, tr("POWERUP_BOMB")]
		"harpoon":
			return tr("SPIN_WON") % [prize.amount, tr("POWERUP_HARPOON")]
		"shuffle":
			return tr("SPIN_WON") % [prize.amount, tr("POWERUP_SHUFFLE")]
		"extra_life":
			return tr("SPIN_WON") % [prize.amount, tr("POWERUP_EXTRA_LIFE")]
	return ""

func _on_back_pressed():
	Global.change_scene_to_file(Scenes.SceneEnum.Menu)

func _update_coin_display():
	gold_panel.update_coins()

func _update_spin_affordability():
	spin_button.disabled = _is_spinning or GameStore.coins < Settings.spin_cost
