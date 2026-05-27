extends MarginContainer

@onready var coin_label = find_child("CoinLabel")

func update_coins():
	coin_label.text = str(GameStore.coins)
