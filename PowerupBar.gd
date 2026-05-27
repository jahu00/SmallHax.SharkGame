extends HBoxContainer

signal bomb_activated
signal harpoon_activated
signal shuffle_activated

@onready var bomb_button: Button = $BombButton
@onready var harpoon_button: Button = $HarpoonButton
@onready var shuffle_button: Button = $ShuffleButton

func _ready():
	bomb_button.pressed.connect(_on_bomb_pressed)
	harpoon_button.pressed.connect(_on_harpoon_pressed)
	shuffle_button.pressed.connect(_on_shuffle_pressed)
	update_counts()

func update_counts():
	bomb_button.text = "Bomb (%d)" % GameStore.inventory["bomb"]
	harpoon_button.text = "Harpoon (%d)" % GameStore.inventory["harpoon"]
	shuffle_button.text = "Shuffle (%d)" % GameStore.inventory["shuffle"]

func set_buttons_enabled(game_state: String):
	var is_player_move = (game_state == "PlayerMove")
	bomb_button.disabled = not (is_player_move and GameStore.inventory["bomb"] > 0)
	harpoon_button.disabled = not (is_player_move and GameStore.inventory["harpoon"] > 0)
	shuffle_button.disabled = not (is_player_move and GameStore.inventory["shuffle"] > 0)

func _on_bomb_pressed():
	bomb_activated.emit()

func _on_harpoon_pressed():
	harpoon_activated.emit()

func _on_shuffle_pressed():
	shuffle_activated.emit()
