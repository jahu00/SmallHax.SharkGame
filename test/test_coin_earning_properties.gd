# Feature: game-economy-and-shop, Property 1: Coin Award on Game Over
# Feature: game-economy-and-shop, Property 2: Bonus Coin Calculation
# Validates: Requirements 1.1, 2.1, 2.3
#
# Property tests for coin earning mechanics.
# Implemented as a GdUnit4-compatible test suite with custom repeat loops
# and randomized input generation.
#
# To run: Install GdUnit4 and execute via the Godot test runner,
# or attach this script to a Node in a test scene.

extends Node

const ITERATIONS = 100
const MAX_COINS = 999_999_999

var _passed := 0
var _failed := 0
var _errors: Array[String] = []


func _ready():
	print("=== Property Tests: Coin Earning ===")
	print("")

	test_property_1_coin_award_on_game_over()
	test_property_2_bonus_coin_calculation()

	print("")
	print("=== Results: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		for err in _errors:
			print("  FAIL: %s" % err)
	print("")


# --- Helper Functions (Generators) ---

func rand_level() -> int:
	# Generate random level in range [1, 1000]
	return randi() % 1000 + 1


func rand_coins() -> int:
	# Generate random coins in valid range [0, MAX_COINS]
	return randi() % (MAX_COINS + 1)


func rand_remaining_tiles() -> int:
	# Generate random remaining tiles [0, 100] (board is 10x10 = 100 tiles max)
	return randi() % 101


func rand_bonus_points() -> int:
	# Generate random bonus points [0, 100000]
	return randi() % 100001


# --- Property 1: Coin Award on Game Over ---
# For any level >= 1 and any existing balance, coins awarded = level * coins_per_level,
# new balance = old + awarded (clamped to MAX_COINS).

func test_property_1_coin_award_on_game_over():
	# Feature: game-economy-and-shop, Property 1: Coin Award on Game Over
	print("Property 1: Coin Award on Game Over (%d iterations)" % ITERATIONS)

	for i in range(ITERATIONS):
		var level = rand_level()
		var starting_coins = rand_coins()

		# Set up GameStore state
		GameStore.coins = starting_coins
		GameStore.data = {
			"level": level,
			"score": 0,
			"next": 0,
			"tiles": []
		}

		# Calculate expected award
		var expected_award = level * Settings.coins_per_level
		var expected_balance = mini(starting_coins + expected_award, MAX_COINS)

		# Execute
		GameStore.award_game_over_coins()

		# Assert: coins awarded equals level * coins_per_level
		if GameStore.coins != expected_balance:
			var msg = "Iteration %d: level=%d, start=%d, expected balance=%d, got=%d" % [i, level, starting_coins, expected_balance, GameStore.coins]
			_record_failure(msg)
			return

	_record_pass("Property 1: Coin Award on Game Over")


# --- Property 2: Bonus Coin Calculation ---
# For any remaining tiles and bonus points, correct bonus coins are calculated
# based on threshold: if remaining_tiles <= bonus_tile_threshold, award
# floor(bonus_points * bonus_to_coins_coefficient); otherwise award zero.

func test_property_2_bonus_coin_calculation():
	# Feature: game-economy-and-shop, Property 2: Bonus Coin Calculation
	print("Property 2: Bonus Coin Calculation (%d iterations)" % ITERATIONS)

	for i in range(ITERATIONS):
		var remaining_tiles = rand_remaining_tiles()
		var bonus_points = rand_bonus_points()
		var starting_coins = rand_coins()

		# Set up GameStore state
		GameStore.coins = starting_coins

		# Calculate expected bonus coins
		var expected_bonus: int
		if remaining_tiles <= Settings.bonus_tile_threshold:
			expected_bonus = int(floor(bonus_points * Settings.bonus_to_coins_coefficient))
		else:
			expected_bonus = 0

		var expected_balance = mini(starting_coins + expected_bonus, MAX_COINS)

		# Execute
		GameStore.award_bonus_coins(remaining_tiles, bonus_points)

		# Assert: balance is correct
		if GameStore.coins != expected_balance:
			var msg = "Iteration %d: remaining_tiles=%d, bonus_points=%d, start=%d, expected balance=%d, got=%d (threshold=%d)" % [i, remaining_tiles, bonus_points, starting_coins, expected_balance, GameStore.coins, Settings.bonus_tile_threshold]
			_record_failure(msg)
			return

	_record_pass("Property 2: Bonus Coin Calculation")


# --- Test Infrastructure ---

func _record_pass(test_name: String):
	_passed += 1
	print("  ✓ PASSED: %s" % test_name)


func _record_failure(msg: String):
	_failed += 1
	_errors.append(msg)
	print("  ✗ FAILED: %s" % msg)
