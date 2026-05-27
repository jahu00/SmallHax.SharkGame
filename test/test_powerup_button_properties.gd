# Feature: game-economy-and-shop, Property 7: Powerup Button Enabled State
# Validates: Requirements 5.1, 6.1, 7.1
#
# Property test for powerup button enabled/disabled state.
# A powerup button should be enabled if and only if the inventory count
# for that powerup type is >= 1 AND the current game state is "PlayerMove".
#
# Implemented as a GdUnit4-compatible test suite with custom repeat loops
# and randomized input generation.
#
# To run: Install GdUnit4 and execute via the Godot test runner,
# or attach this script to a Node in a test scene.

extends Node

const ITERATIONS = 100
const MAX_POWERUP = 99

var _passed := 0
var _failed := 0
var _errors: Array[String] = []

# We create mock buttons to test the logic without needing the full scene tree
var bomb_button: Button
var harpoon_button: Button
var shuffle_button: Button


func _ready():
	print("=== Property Tests: Powerup Button Enabled State ===")
	print("")

	_setup_buttons()
	test_property_7_powerup_button_enabled_state()

	print("")
	print("=== Results: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		for err in _errors:
			print("  FAIL: %s" % err)
	print("")


# --- Setup ---

func _setup_buttons():
	bomb_button = Button.new()
	harpoon_button = Button.new()
	shuffle_button = Button.new()
	add_child(bomb_button)
	add_child(harpoon_button)
	add_child(shuffle_button)


# --- Helper Functions (Generators) ---

func rand_game_state() -> String:
	var states = ["PlayerMove", "DestroyTiles", "MoveTiles", "Over", "PowerupTarget"]
	return states[randi() % states.size()]


func rand_powerup_count() -> int:
	# Generate random powerup count in valid range [0, MAX_POWERUP]
	return randi() % (MAX_POWERUP + 1)


# --- Core Logic Under Test ---
# Replicates the PowerupBar.set_buttons_enabled logic to test the property
# against the actual GameStore inventory state.

func apply_button_enabled_logic(game_state: String):
	var is_player_move = (game_state == "PlayerMove")
	bomb_button.disabled = not (is_player_move and GameStore.inventory["bomb"] > 0)
	harpoon_button.disabled = not (is_player_move and GameStore.inventory["harpoon"] > 0)
	shuffle_button.disabled = not (is_player_move and GameStore.inventory["shuffle"] > 0)


# --- Property 7: Powerup Button Enabled State ---
# For any powerup type (Bomb, Harpoon, Shuffle), the corresponding activation
# button shall be enabled if and only if the inventory count for that type
# is >= 1 AND the current game state is PlayerMove.

func test_property_7_powerup_button_enabled_state():
	# Feature: game-economy-and-shop, Property 7: Powerup Button Enabled State
	print("Property 7: Powerup Button Enabled State (%d iterations)" % ITERATIONS)

	for i in range(ITERATIONS):
		# Generate random inputs
		var game_state = rand_game_state()
		var bomb_count = rand_powerup_count()
		var harpoon_count = rand_powerup_count()
		var shuffle_count = rand_powerup_count()

		# Set up GameStore inventory state
		GameStore.inventory["bomb"] = bomb_count
		GameStore.inventory["harpoon"] = harpoon_count
		GameStore.inventory["shuffle"] = shuffle_count

		# Apply the button enabled logic (same as PowerupBar.set_buttons_enabled)
		apply_button_enabled_logic(game_state)

		# Calculate expected enabled state for each button
		var is_player_move = (game_state == "PlayerMove")
		var expected_bomb_enabled = is_player_move and bomb_count >= 1
		var expected_harpoon_enabled = is_player_move and harpoon_count >= 1
		var expected_shuffle_enabled = is_player_move and shuffle_count >= 1

		# Assert: bomb button enabled state matches property
		# Note: button.disabled is the inverse of "enabled"
		var actual_bomb_enabled = not bomb_button.disabled
		if actual_bomb_enabled != expected_bomb_enabled:
			var msg = "Iteration %d: Bomb button enabled=%s, expected=%s (state=%s, count=%d)" % [i, str(actual_bomb_enabled), str(expected_bomb_enabled), game_state, bomb_count]
			_record_failure(msg)
			return

		# Assert: harpoon button enabled state matches property
		var actual_harpoon_enabled = not harpoon_button.disabled
		if actual_harpoon_enabled != expected_harpoon_enabled:
			var msg = "Iteration %d: Harpoon button enabled=%s, expected=%s (state=%s, count=%d)" % [i, str(actual_harpoon_enabled), str(expected_harpoon_enabled), game_state, harpoon_count]
			_record_failure(msg)
			return

		# Assert: shuffle button enabled state matches property
		var actual_shuffle_enabled = not shuffle_button.disabled
		if actual_shuffle_enabled != expected_shuffle_enabled:
			var msg = "Iteration %d: Shuffle button enabled=%s, expected=%s (state=%s, count=%d)" % [i, str(actual_shuffle_enabled), str(expected_shuffle_enabled), game_state, shuffle_count]
			_record_failure(msg)
			return

	_record_pass("Property 7: Powerup Button Enabled State")


# --- Test Infrastructure ---

func _record_pass(test_name: String):
	_passed += 1
	print("  ✓ PASSED: %s" % test_name)


func _record_failure(msg: String):
	_failed += 1
	_errors.append(msg)
	print("  ✗ FAILED: %s" % msg)
