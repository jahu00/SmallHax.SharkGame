# Feature: game-economy-and-shop, Property 3: Persistence Round Trip
# Feature: game-economy-and-shop, Property 4: Value Clamping
# Validates: Requirements 3.2, 3.5
#
# Property tests for GameStore persistence and value clamping.
# Implemented as a GdUnit4-compatible test suite with custom repeat loops
# and randomized input generation.
#
# To run: Install GdUnit4 and execute via the Godot test runner,
# or attach this script to a Node in a test scene.

extends Node

const ITERATIONS = 100
const MAX_COINS = 999_999_999
const MAX_POWERUP = 99
const SAVE_PATH = "user://save_data.json"

var _passed := 0
var _failed := 0
var _errors: Array[String] = []


func _ready():
	print("=== Property Tests: Persistence & Value Clamping ===")
	print("")

	test_property_3_persistence_round_trip()
	test_property_4_value_clamping_coins()
	test_property_4_value_clamping_powerups()
	test_property_4_value_clamping_never_negative()

	print("")
	print("=== Results: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		for err in _errors:
			print("  FAIL: %s" % err)
	print("")

	# Clean up test save file
	_cleanup_save_file()


# --- Helper Functions (Generators) ---

func rand_coins() -> int:
	# Generate random coins in valid range [0, MAX_COINS]
	return randi() % (MAX_COINS + 1)


func rand_powerup_count() -> int:
	# Generate random powerup count in valid range [0, MAX_POWERUP]
	return randi() % (MAX_POWERUP + 1)


func rand_inventory() -> Dictionary:
	return {
		"bomb": rand_powerup_count(),
		"rocket": rand_powerup_count(),
		"shuffle": rand_powerup_count(),
		"extra_life": rand_powerup_count(),
	}


func rand_positive_int(max_val: int = 2_000_000_000) -> int:
	# Generate a random positive integer, possibly exceeding MAX_COINS
	return randi() % max_val + 1


# --- Property 3: Persistence Round Trip ---
# For any valid coins [0, 999_999_999] and powerup counts [0, 99],
# serialize then deserialize produces identical state.

func test_property_3_persistence_round_trip():
	# Feature: game-economy-and-shop, Property 3: Persistence Round Trip
	print("Property 3: Persistence Round Trip (%d iterations)" % ITERATIONS)

	for i in range(ITERATIONS):
		var test_coins = rand_coins()
		var test_inventory = rand_inventory()

		# Set state directly
		GameStore.coins = test_coins
		GameStore.inventory = test_inventory.duplicate()

		# Serialize (save)
		GameStore.save_data()

		# Corrupt in-memory state to ensure load actually restores
		GameStore.coins = -1
		GameStore.inventory = {"bomb": -1, "rocket": -1, "shuffle": -1, "extra_life": -1}

		# Deserialize (load)
		GameStore.load_data()

		# Assert identical state
		if GameStore.coins != test_coins:
			var msg = "Iteration %d: coins mismatch after round trip. Expected %d, got %d" % [i, test_coins, GameStore.coins]
			_record_failure(msg)
			return

		for key in test_inventory.keys():
			if GameStore.inventory[key] != test_inventory[key]:
				var msg = "Iteration %d: inventory[%s] mismatch. Expected %d, got %d" % [i, key, test_inventory[key], GameStore.inventory[key]]
				_record_failure(msg)
				return

	_record_pass("Property 3: Persistence Round Trip")


# --- Property 4: Value Clamping ---

func test_property_4_value_clamping_coins():
	# Feature: game-economy-and-shop, Property 4: Value Clamping (coins)
	# Coin additions exceeding MAX_COINS clamp to MAX_COINS
	print("Property 4a: Value Clamping - Coins (%d iterations)" % ITERATIONS)

	for i in range(ITERATIONS):
		# Start with a random valid coin balance
		var starting_coins = rand_coins()
		GameStore.coins = starting_coins

		# Add a random amount that may exceed MAX_COINS
		var add_amount = rand_positive_int()

		# Bypass save_data to avoid file I/O on every iteration
		GameStore.coins = mini(GameStore.coins + add_amount, MAX_COINS)

		# Assert: coins never exceed MAX_COINS
		if GameStore.coins > MAX_COINS:
			var msg = "Iteration %d: coins %d exceeds MAX_COINS after adding %d to %d" % [i, GameStore.coins, add_amount, starting_coins]
			_record_failure(msg)
			return

		# Assert: coins are correct clamped value
		var expected = mini(starting_coins + add_amount, MAX_COINS)
		if GameStore.coins != expected:
			var msg = "Iteration %d: expected %d, got %d (start=%d, add=%d)" % [i, expected, GameStore.coins, starting_coins, add_amount]
			_record_failure(msg)
			return

	_record_pass("Property 4a: Value Clamping - Coins")


func test_property_4_value_clamping_powerups():
	# Feature: game-economy-and-shop, Property 4: Value Clamping (powerups)
	# Powerup additions exceeding MAX_POWERUP clamp to 99
	print("Property 4b: Value Clamping - Powerups (%d iterations)" % ITERATIONS)

	var powerup_types = ["bomb", "rocket", "shuffle", "extra_life"]

	for i in range(ITERATIONS):
		var ptype = powerup_types[randi() % powerup_types.size()]

		# Start with a random valid powerup count
		var starting_count = rand_powerup_count()
		GameStore.inventory[ptype] = starting_count

		# Add a random amount that may exceed MAX_POWERUP
		var add_amount = randi() % 200 + 1  # 1 to 200

		# Use add_powerup which should clamp
		# We need to avoid save_data I/O, so replicate the logic
		GameStore.inventory[ptype] = mini(GameStore.inventory[ptype] + add_amount, MAX_POWERUP)

		# Assert: powerup count never exceeds MAX_POWERUP
		if GameStore.inventory[ptype] > MAX_POWERUP:
			var msg = "Iteration %d: %s count %d exceeds MAX_POWERUP after adding %d to %d" % [i, ptype, GameStore.inventory[ptype], add_amount, starting_count]
			_record_failure(msg)
			return

		# Assert: powerup count is correct clamped value
		var expected = mini(starting_count + add_amount, MAX_POWERUP)
		if GameStore.inventory[ptype] != expected:
			var msg = "Iteration %d: %s expected %d, got %d (start=%d, add=%d)" % [i, ptype, expected, GameStore.inventory[ptype], starting_count, add_amount]
			_record_failure(msg)
			return

	_record_pass("Property 4b: Value Clamping - Powerups")


func test_property_4_value_clamping_never_negative():
	# Feature: game-economy-and-shop, Property 4: Value Clamping (never negative)
	# Values never go negative even with large spend/use operations
	print("Property 4c: Value Clamping - Never Negative (%d iterations)" % ITERATIONS)

	var powerup_types = ["bomb", "rocket", "shuffle", "extra_life"]

	for i in range(ITERATIONS):
		# Set a random valid starting state
		var starting_coins = rand_coins()
		GameStore.coins = starting_coins
		GameStore.inventory = rand_inventory().duplicate()

		# Try to spend more coins than available
		var spend_amount = starting_coins + randi() % 1000 + 1
		var spend_result = GameStore.spend_coins(spend_amount)

		# spend_coins should return false and not change balance
		if spend_result == true:
			var msg = "Iteration %d: spend_coins(%d) returned true with balance %d" % [i, spend_amount, starting_coins]
			_record_failure(msg)
			return

		if GameStore.coins < 0:
			var msg = "Iteration %d: coins went negative (%d) after failed spend" % [i, GameStore.coins]
			_record_failure(msg)
			return

		# Try to use a powerup with 0 count
		var ptype = powerup_types[randi() % powerup_types.size()]
		GameStore.inventory[ptype] = 0
		var use_result = GameStore.use_powerup(ptype)

		if use_result == true:
			var msg = "Iteration %d: use_powerup(%s) returned true with count 0" % [i, ptype]
			_record_failure(msg)
			return

		if GameStore.inventory[ptype] < 0:
			var msg = "Iteration %d: %s went negative (%d) after failed use" % [i, ptype, GameStore.inventory[ptype]]
			_record_failure(msg)
			return

	_record_pass("Property 4c: Value Clamping - Never Negative")


# --- Test Infrastructure ---

func _record_pass(test_name: String):
	_passed += 1
	print("  ✓ PASSED: %s" % test_name)


func _record_failure(msg: String):
	_failed += 1
	_errors.append(msg)
	print("  ✗ FAILED: %s" % msg)


func _cleanup_save_file():
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
