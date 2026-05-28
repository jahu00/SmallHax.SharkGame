extends HBoxContainer

signal bomb_activated
signal harpoon_activated
signal shuffle_activated

@onready var bomb_button: PowerButton = $BombButton
@onready var harpoon_button: PowerButton = $HarpoonButton
@onready var shuffle_button: PowerButton = $ShuffleButton
@onready var extra_life_button: PowerButton = $ExtraLifeButton

func _ready():
	bomb_button.pressed.connect(_on_bomb_pressed)
	harpoon_button.pressed.connect(_on_harpoon_pressed)
	shuffle_button.pressed.connect(_on_shuffle_pressed)
	update_counts()

func update_counts():
	bomb_button.count = GameStore.inventory["bomb"]
	harpoon_button.count = GameStore.inventory["harpoon"]
	shuffle_button.count = GameStore.inventory["shuffle"]
	extra_life_button.count = GameStore.inventory["extra_life"]

func set_buttons_enabled(game_state: String, active_powerup: String):
	var is_player_move = (game_state == "PlayerMove")
	var is_powerup_target = (game_state == "PowerupTarget")
	bomb_button.selected = active_powerup == "bomb"
	harpoon_button.selected = active_powerup == "harpoon"
	shuffle_button.selected = active_powerup == "shuffle"
	
	if (is_powerup_target):
		bomb_button.disabled = active_powerup != "bomb"
		harpoon_button.disabled = active_powerup != "harpoon"
		shuffle_button.disabled = active_powerup != "shuffle"
	else:
		bomb_button.disabled = !is_player_move or GameStore.inventory["bomb"] == 0
		harpoon_button.disabled = !is_player_move or GameStore.inventory["harpoon"] == 0
		shuffle_button.disabled = !is_player_move or GameStore.inventory["shuffle"] == 0

func _on_bomb_pressed():
	bomb_activated.emit()

func _on_harpoon_pressed():
	harpoon_activated.emit()

func _on_shuffle_pressed():
	shuffle_activated.emit()
