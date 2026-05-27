extends Control

const PRIZES = [
	{"type": "nothing", "amount": 0},
	{"type": "bomb", "amount": 1},
	{"type": "harpoon", "amount": 1},
	{"type": "bomb", "amount": 2},
	{"type": "shuffle", "amount": 1},
	{"type": "bomb", "amount": 3},
	{"type": "extra_life", "amount": 1},
	{"type": "coins", "amount": 1000},
	{"type": "bomb", "amount": 3},
]

const SEGMENT_COUNT = 9
const SEGMENT_ANGLE = TAU / SEGMENT_COUNT

@onready var gold_panel = get_node("GoldPanel")
@onready var spin_button = get_node("CenterContainer/VBoxContainer/SpinButton")
@onready var back_button = get_node("CenterContainer/VBoxContainer/BackButton")
@onready var prize_result_label = get_node("CenterContainer/VBoxContainer/PrizeResultLabel")
@onready var spin_cost_label = get_node("CenterContainer/VBoxContainer/SpinCostLabel")
@onready var wheel_node = get_node("CenterContainer/VBoxContainer/WheelContainer/WheelNode")

var _is_spinning: bool = false
var _result_display_timer: float = 0.0

func _ready():
	spin_cost_label.text = "Cost: " + str(Settings.spin_cost) + " coins"
	spin_button.pressed.connect(_on_spin_pressed)
	back_button.pressed.connect(_on_back_pressed)
	_update_coin_display()
	_update_spin_affordability()
	_draw_wheel_segments()

func _process(delta):
	if _result_display_timer > 0.0:
		_result_display_timer -= delta
		if _result_display_timer <= 0.0:
			prize_result_label.text = ""
			_update_spin_affordability()

	gold_panel.update_coins()

func _draw_wheel_segments():
	# Draw 9 colored segments on the wheel node
	var colors = [
		Color(0.6, 0.6, 0.6),   # 0: Nothing - gray
		Color(0.9, 0.3, 0.3),   # 1: 1x Bomb - red
		Color(0.3, 0.5, 0.9),   # 2: 1x Harpoon - blue
		Color(0.9, 0.4, 0.4),   # 3: 2x Bomb - light red
		Color(0.3, 0.9, 0.5),   # 4: 1x Shuffle - green
		Color(0.8, 0.2, 0.2),   # 5: 3x Bomb - dark red
		Color(0.9, 0.9, 0.3),   # 6: 1x Extra Life - yellow
		Color(0.9, 0.7, 0.1),   # 7: 1000 coins - gold
		Color(0.8, 0.2, 0.2),   # 8: 3x Bomb - dark red
	]

	var labels = [
		"Nothing", "1x Bomb", "1x Harpoon", "2x Bomb",
		"1x Shuffle", "3x Bomb", "1x Extra Life", "1000 Coins", "3x Bomb"
	]

	var radius = 200.0

	for i in range(SEGMENT_COUNT):
		var segment = _create_segment(i, radius, colors[i], labels[i])
		wheel_node.add_child(segment)

func _create_segment(index: int, radius: float, color: Color, label_text: String) -> Node2D:
	var segment = Node2D.new()

	# Create the colored polygon for this segment
	var polygon = Polygon2D.new()
	var points: PackedVector2Array = PackedVector2Array()
	points.append(Vector2.ZERO)

	var start_angle = index * SEGMENT_ANGLE
	var end_angle = (index + 1) * SEGMENT_ANGLE
	var steps = 16
	for s in range(steps + 1):
		var angle = start_angle + (end_angle - start_angle) * s / steps
		points.append(Vector2(cos(angle), sin(angle)) * radius)

	polygon.polygon = points
	polygon.color = color
	segment.add_child(polygon)

	# Add label at the midpoint of the segment
	var mid_angle = start_angle + SEGMENT_ANGLE / 2.0
	var label_pos = Vector2(cos(mid_angle), sin(mid_angle)) * (radius * 0.6)
	var label = Label.new()
	label.text = label_text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.position = label_pos - Vector2(50, 10)
	label.custom_minimum_size = Vector2(100, 20)
	label.add_theme_font_size_override("font_size", 12)
	segment.add_child(label)

	return segment

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
	# Determine winning segment from final angle
	var segment_index = int(floor(final_angle / SEGMENT_ANGLE))
	segment_index = clampi(segment_index, 0, SEGMENT_COUNT - 1)
	_on_spin_complete(segment_index)

func _on_spin_complete(segment_index: int):
	var prize = get_prize(segment_index)

	# Award the prize
	match prize.type:
		"nothing":
			pass
		"coins":
			GameStore.add_coins(prize.amount)
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
			return "Nothing! Better luck next time."
		"coins":
			return "Won " + str(prize.amount) + " coins!"
		"bomb":
			return "Won " + str(prize.amount) + "x Bomb!"
		"harpoon":
			return "Won " + str(prize.amount) + "x Harpoon!"
		"shuffle":
			return "Won " + str(prize.amount) + "x Shuffle!"
		"extra_life":
			return "Won " + str(prize.amount) + "x Extra Life!"
	return ""

func _on_back_pressed():
	Global.change_scene_to_file(Scenes.SceneEnum.Menu)

func _update_coin_display():
	gold_panel.update_coins()

func _update_spin_affordability():
	spin_button.disabled = _is_spinning or GameStore.coins < Settings.spin_cost
