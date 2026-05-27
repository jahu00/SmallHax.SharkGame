extends HBoxContainer

signal bomb_activated
signal rocket_activated
signal shuffle_activated

@onready var bomb_button: Button = $BombButton
@onready var rocket_button: Button = $RocketButton
@onready var shuffle_button: Button = $ShuffleButton

func _ready():
	bomb_button.pressed.connect(_on_bomb_pressed)
	rocket_button.pressed.connect(_on_rocket_pressed)
	shuffle_button.pressed.connect(_on_shuffle_pressed)
	update_counts()

func update_counts():
	bomb_button.text = "Bomb (%d)" % GameStore.inventory["bomb"]
	rocket_button.text = "Rocket (%d)" % GameStore.inventory["rocket"]
	shuffle_button.text = "Shuffle (%d)" % GameStore.inventory["shuffle"]

func set_buttons_enabled(game_state: String):
	var is_player_move = (game_state == "PlayerMove")
	bomb_button.disabled = not (is_player_move and GameStore.inventory["bomb"] > 0)
	rocket_button.disabled = not (is_player_move and GameStore.inventory["rocket"] > 0)
	shuffle_button.disabled = not (is_player_move and GameStore.inventory["shuffle"] > 0)

func _on_bomb_pressed():
	bomb_activated.emit()

func _on_rocket_pressed():
	rocket_activated.emit()

func _on_shuffle_pressed():
	shuffle_activated.emit()
