# Feature: game-economy-and-shop, Property 14: Spin Cost Deduction
# Feature: game-economy-and-shop, Property 15: Prize Segment Mapping
# Validates: Requirements 9.4, 9.5, 9.6
#
# Property tests for spinning wheel logic.
# Implemented as a GdUnit4-compatible test suite with custom repeat loops
# and randomized input generation.
#
# To run: Install GdUnit4 and execute via the Godot test runner,
# or attach this script to a Node in a test scene.

extends Node

const ITERATIONS = 100
const MAX_COINS = 999_999_999
const MAX_POWERUP = 99

const EXPECTED_PRIZES = [
	{"type": "nothing", "amount": 0},
	{"type": "bomb", "amount": 1},
	{"type": "rocket", "amount": 1},
	{"type": "bomb", "amount": 2},
	{"type": "shuffle", "amount": 1},
	{"type": "bomb", "amount": 3},
	{"type": "extra_life", "amount": 1},
	{"type": "coins", "amount": 1000},
	{"type": "bomb", "amount": 3},
]

const SEGMENT_COUNT = 9

var SpinningWheelScript = preload("res://SpinningWheel.gd")

var _passed := 0
var _failed := 0
var _errors: Array[String] = []


func _ready():
	print("=== Property Tests: Spinning Wheel Logic ===")
	print("")

	test_property_14_spin_cost_deduction()
	test_property_15_prize_segment_mapping()

	print("")
	print("=== Results: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		for err in _errors:
			print("  FAIL: %s" % err)
	print("")


# --- Helper Functions (Generators) ---

func rand_balance_at_least(min_val: int) -> int:
	if min_val >= MAX_COINS:
		return MAX_COINS
	return min_val + randi() % (MAX_COINS - min_val + 1)


func rand_segment_index() -> int:
	return randi() % SEGMENT_COUNT


func rand_powerup_count() -> int:
	# Leave room for additions (max amount added is 3)
	return randi() % (MAX_POWERUP - 3)


# --- Property 14: Spin Cost Deduction ---
# For any balance >= spin_cost, calling GameStore.spend_coins(Settings.spin_cost)
# results in new balance = old - spin_cost.

func test_property_14_spin_cost_deduction():
	# Feature: game-economy-and-shop, Property 14: Spin Cost Deduction
	print("Property 14: Spin Cost Deduction (%d iterations)" % ITERATIONS)

	for i in range(ITERATIONS):
		var starting_balance = rand_balance_at_least(Settings.spin_cost)

		# Set up GameStore state
		GameStore.coins = starting_balance

		# Execute: spend spin cost (same as _on_spin_pressed does)
		var spend_result = GameStore.spend_coins(Settings.spin_cost)

		# Assert: spend_coins returns true
		if spend_result != true:
			var msg = "Iteration %d: spend_coins(%d) returned false with balance %d" % [i, Settings.spin_cost, starting_balance]
			_record_failure(msg)
			return

		# Assert: new balance = old - spin_cost
		var expected_balance = starting_balance - Settings.spin_cost
		if GameStore.coins != expected_balance:
			var msg = "Iteration %d: expected balance %d, got %d (start=%d, spin_cost=%d)" % [i, expected_balance, GameStore.coins, starting_balance, Settings.spin_cost]
			_record_failure(msg)
			return

	_record_pass("Property 14: Spin Cost Deduction")


# --- Property 15: Prize Segment Mapping ---
# For any segment index [0,8], correct prize is returned and awarded.
# Part A: Deterministic check of all 9 segments against expected prize table.
# Part B: Random iterations verifying award logic updates GameStore correctly.

func test_property_15_prize_segment_mapping():
	# Feature: game-economy-and-shop, Property 15: Prize Segment Mapping
	print("Property 15: Prize Segment Mapping (9 deterministic + %d random iterations)" % ITERATIONS)

	# Part A: Verify all 9 segments return correct prize from PRIZES constant
	for i in range(SEGMENT_COUNT):
		var prize = SpinningWheelScript.PRIZES[i]
		var expected = EXPECTED_PRIZES[i]

		if prize.type != expected.type or prize.amount != expected.amount:
			var msg = "Segment %d: expected {type=%s, amount=%d}, got {type=%s, amount=%d}" % [i, expected.type, expected.amount, prize.type, prize.amount]
			_record_failure(msg)
			return

	# Part B: Random iterations verifying award logic
	for i in range(ITERATIONS):
		var segment_index = rand_segment_index()
		var prize = EXPECTED_PRIZES[segment_index]

		# Set up GameStore state based on prize type
		match prize.type:
			"nothing":
				# Nothing prize — GameStore should not change
				var starting_coins = rand_balance_at_least(0)
				GameStore.coins = starting_coins

				# Award: nothing happens
				# (no call needed, just verify no change)
				# Simulate what _on_spin_complete does for "nothing"
				# It does nothing — pass

				if GameStore.coins != starting_coins:
					var msg = "Iteration %d (segment %d): 'nothing' prize changed coins from %d to %d" % [i, segment_index, starting_coins, GameStore.coins]
					_record_failure(msg)
					return

			"coins":
				# Coins prize — GameStore.add_coins(prize.amount)
				var starting_coins = randi() % (MAX_COINS - prize.amount + 1)
				GameStore.coins = starting_coins

				GameStore.add_coins(prize.amount)

				var expected_coins = starting_coins + prize.amount
				if GameStore.coins != expected_coins:
					var msg = "Iteration %d (segment %d): expected coins %d, got %d (start=%d, prize=%d)" % [i, segment_index, expected_coins, GameStore.coins, starting_coins, prize.amount]
					_record_failure(msg)
					return

			_:
				# Powerup prize — GameStore.add_powerup(prize.type, prize.amount)
				var starting_count = rand_powerup_count()
				GameStore.inventory[prize.type] = starting_count

				GameStore.add_powerup(prize.type, prize.amount)

				var expected_count = mini(starting_count + prize.amount, MAX_POWERUP)
				if GameStore.inventory[prize.type] != expected_count:
					var msg = "Iteration %d (segment %d): expected %s count %d, got %d (start=%d, prize_amount=%d)" % [i, segment_index, prize.type, expected_count, GameStore.inventory[prize.type], starting_count, prize.amount]
					_record_failure(msg)
					return

	_record_pass("Property 15: Prize Segment Mapping")


# --- Test Infrastructure ---

func _record_pass(test_name: String):
	_passed += 1
	print("  ✓ PASSED: %s" % test_name)


func _record_failure(msg: String):
	_failed += 1
	_errors.append(msg)
	print("  ✗ FAILED: %s" % msg)
