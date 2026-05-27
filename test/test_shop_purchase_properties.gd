# Feature: game-economy-and-shop, Property 5: Purchase Transaction Integrity
# Feature: game-economy-and-shop, Property 6: Affordability Determination
# Validates: Requirements 4.3, 4.4
#
# Property tests for shop purchase logic.
# Implemented as a GdUnit4-compatible test suite with custom repeat loops
# and randomized input generation.
#
# To run: Install GdUnit4 and execute via the Godot test runner,
# or attach this script to a Node in a test scene.

extends Node

const ITERATIONS = 100
const MAX_COINS = 999_999_999
const MAX_POWERUP = 99

var _passed := 0
var _failed := 0
var _errors: Array[String] = []


func _ready():
	print("=== Property Tests: Shop Purchase Logic ===")
	print("")

	test_property_5_purchase_transaction_integrity()
	test_property_6_affordability_determination()

	print("")
	print("=== Results: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		for err in _errors:
			print("  FAIL: %s" % err)
	print("")


# --- Helper Functions (Generators) ---

func rand_powerup_type() -> String:
	var types = ["bomb", "harpoon", "shuffle", "extra_life"]
	return types[randi() % types.size()]


func rand_price_for_type(type: String) -> int:
	match type:
		"bomb":
			return Settings.bomb_price
		"harpoon":
			return Settings.harpoon_price
		"shuffle":
			return Settings.shuffle_price
		"extra_life":
			return Settings.extra_life_price
	return 100


func rand_balance_at_least(min_val: int) -> int:
	# Generate a balance in [min_val, MAX_COINS]
	if min_val >= MAX_COINS:
		return MAX_COINS
	return min_val + randi() % (MAX_COINS - min_val + 1)


func rand_balance_below(max_val: int) -> int:
	# Generate a balance in [0, max_val - 1]
	if max_val <= 0:
		return 0
	return randi() % max_val


func rand_powerup_count() -> int:
	# Generate random powerup count in valid range [0, MAX_POWERUP - 1]
	# Leave room for +1 increment
	return randi() % MAX_POWERUP


func rand_any_balance() -> int:
	# Generate any valid balance [0, MAX_COINS]
	return randi() % (MAX_COINS + 1)


func rand_any_price() -> int:
	# Pick a random shop price from the available items
	var prices = [Settings.bomb_price, Settings.harpoon_price, Settings.shuffle_price, Settings.extra_life_price]
	return prices[randi() % prices.size()]


# --- Property 5: Purchase Transaction Integrity ---
# For any balance >= price, calling spend_coins(price) returns true,
# new balance = old - price, and calling add_powerup(type) increases count by 1.

func test_property_5_purchase_transaction_integrity():
	# Feature: game-economy-and-shop, Property 5: Purchase Transaction Integrity
	print("Property 5: Purchase Transaction Integrity (%d iterations)" % ITERATIONS)

	for i in range(ITERATIONS):
		var powerup_type = rand_powerup_type()
		var price = rand_price_for_type(powerup_type)
		var starting_balance = rand_balance_at_least(price)
		var starting_powerup_count = rand_powerup_count()

		# Set up GameStore state
		GameStore.coins = starting_balance
		GameStore.inventory[powerup_type] = starting_powerup_count

		# Execute purchase: spend coins
		var spend_result = GameStore.spend_coins(price)

		# Assert: spend_coins returns true
		if spend_result != true:
			var msg = "Iteration %d: spend_coins(%d) returned false with balance %d (type=%s)" % [i, price, starting_balance, powerup_type]
			_record_failure(msg)
			return

		# Assert: new balance = old - price
		var expected_balance = starting_balance - price
		if GameStore.coins != expected_balance:
			var msg = "Iteration %d: expected balance %d, got %d (start=%d, price=%d, type=%s)" % [i, expected_balance, GameStore.coins, starting_balance, price, powerup_type]
			_record_failure(msg)
			return

		# Execute purchase: add powerup
		GameStore.add_powerup(powerup_type)

		# Assert: powerup count increased by 1
		var expected_count = mini(starting_powerup_count + 1, MAX_POWERUP)
		if GameStore.inventory[powerup_type] != expected_count:
			var msg = "Iteration %d: expected %s count %d, got %d (start_count=%d)" % [i, powerup_type, expected_count, GameStore.inventory[powerup_type], starting_powerup_count]
			_record_failure(msg)
			return

	_record_pass("Property 5: Purchase Transaction Integrity")


# --- Property 6: Affordability Determination ---
# Item affordable iff balance >= price (spend_coins returns true iff coins >= amount).

func test_property_6_affordability_determination():
	# Feature: game-economy-and-shop, Property 6: Affordability Determination
	print("Property 6: Affordability Determination (%d iterations)" % ITERATIONS)

	for i in range(ITERATIONS):
		var price = rand_any_price()
		var balance = rand_any_balance()

		# Set up GameStore state
		GameStore.coins = balance

		# Determine expected affordability
		var expected_affordable = balance >= price

		# Execute: attempt spend
		var result = GameStore.spend_coins(price)

		# Assert: result matches expected affordability
		if result != expected_affordable:
			var msg = "Iteration %d: spend_coins(%d) returned %s with balance %d, expected %s" % [i, price, str(result), balance, str(expected_affordable)]
			_record_failure(msg)
			return

		# Assert: if affordable, balance was deducted correctly
		if result == true:
			var expected_balance = balance - price
			if GameStore.coins != expected_balance:
				var msg = "Iteration %d: after successful spend, expected balance %d, got %d (start=%d, price=%d)" % [i, expected_balance, GameStore.coins, balance, price]
				_record_failure(msg)
				return
		else:
			# If not affordable, balance should be unchanged
			if GameStore.coins != balance:
				var msg = "Iteration %d: after failed spend, balance changed from %d to %d (price=%d)" % [i, balance, GameStore.coins, price]
				_record_failure(msg)
				return

	_record_pass("Property 6: Affordability Determination")


# --- Test Infrastructure ---

func _record_pass(test_name: String):
	_passed += 1
	print("  ✓ PASSED: %s" % test_name)


func _record_failure(msg: String):
	_failed += 1
	_errors.append(msg)
	print("  ✗ FAILED: %s" % msg)
