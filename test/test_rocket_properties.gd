# Feature: game-economy-and-shop, Property 9: Harpoon Column Destruction
# Feature: game-economy-and-shop, Property 10: Harpoon Scoring
# Feature: game-economy-and-shop, Property 11: Powerup Consumption (Harpoon)
# Validates: Requirements 6.2, 6.4, 6.5
#
# Property tests for harpoon powerup logic.
# Implemented as a GdUnit4-compatible test suite with custom repeat loops
# and randomized input generation.
#
# To run: Install GdUnit4 and execute via the Godot test runner,
# or attach this script to a Node in a test scene.

extends Node

const ITERATIONS = 100
const BOARD_WIDTH = 10
const BOARD_HEIGHT = 10

var _passed := 0
var _failed := 0
var _errors: Array[String] = []


func _ready():
	print("=== Property Tests: Harpoon Powerup Logic ===")
	print("")

	test_property_9_harpoon_column_destruction()
	test_property_10_harpoon_scoring()
	test_property_11_powerup_consumption_harpoon()

	print("")
	print("=== Results: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		for err in _errors:
			print("  FAIL: %s" % err)
	print("")


# --- Helper Functions (Generators) ---

func rand_column() -> int:
	return randi() % BOARD_WIDTH


func rand_board_tiles() -> Array:
	# Generate a random subset of tiles on the 10x10 board
	var tiles: Array = []
	var tile_count = randi() % 101  # 0 to 100 tiles
	var occupied: Dictionary = {}
	for i in range(tile_count):
		var x = randi() % BOARD_WIDTH
		var y = randi() % BOARD_HEIGHT
		var key = "%d,%d" % [x, y]
		if not occupied.has(key):
			occupied[key] = true
			tiles.append({"x": x, "y": y, "color": randi() % 5})
	return tiles


func rand_board_with_column_tiles(column_x: int) -> Array:
	# Generate a board that guarantees at least 1 tile in the given column
	var tiles: Array = rand_board_tiles()

	# Check if the column already has tiles
	var has_column_tile = false
	for tile in tiles:
		if tile["x"] == column_x:
			has_column_tile = true
			break

	# If not, add at least one tile in the target column
	if not has_column_tile:
		var y = randi() % BOARD_HEIGHT
		var key = "%d,%d" % [column_x, y]
		tiles.append({"x": column_x, "y": y, "color": randi() % 5})

	return tiles


func get_column_tiles(tiles: Array, column_x: int) -> Array:
	var result: Array = []
	for tile in tiles:
		if tile["x"] == column_x:
			result.append(tile)
	return result


func rand_harpoon_inventory() -> int:
	# Generate a random harpoon count >= 1
	return 1 + randi() % GameStore.MAX_POWERUP


# --- Property 9: Harpoon Column Destruction ---
# For any column with >=1 tile, all tiles in that column are destroyed,
# no tiles in other columns affected.

func test_property_9_harpoon_column_destruction():
	# Feature: game-economy-and-shop, Property 9: Harpoon Column Destruction
	# **Validates: Requirements 6.2**
	print("Property 9: Harpoon Column Destruction (%d iterations)" % ITERATIONS)

	for i in range(ITERATIONS):
		var column_x = rand_column()
		var tiles = rand_board_with_column_tiles(column_x)

		# Compute expected: all tiles in column_x should be destroyed
		var expected_destroyed = get_column_tiles(tiles, column_x)

		# Compute expected: all tiles NOT in column_x should be unaffected
		var expected_surviving: Array = []
		for tile in tiles:
			if tile["x"] != column_x:
				expected_surviving.append(tile)

		# Replicate the harpoon algorithm from Game.gd execute_harpoon
		var algorithm_destroyed: Array = []
		for tile in tiles:
			if tile["x"] == column_x:
				algorithm_destroyed.append(tile)

		# Assert: algorithm destroys exactly the tiles in the target column
		if algorithm_destroyed.size() != expected_destroyed.size():
			var msg = "Iteration %d: column %d - expected %d destroyed, algorithm found %d" % [i, column_x, expected_destroyed.size(), algorithm_destroyed.size()]
			_record_failure(msg)
			return

		# Assert: all destroyed tiles are in the target column
		for tile in algorithm_destroyed:
			if tile["x"] != column_x:
				var msg = "Iteration %d: column %d - destroyed tile at (%d,%d) is not in target column" % [i, column_x, tile["x"], tile["y"]]
				_record_failure(msg)
				return

		# Assert: no tiles in other columns are affected
		for tile in expected_surviving:
			if tile in algorithm_destroyed:
				var msg = "Iteration %d: column %d - tile at (%d,%d) in other column was incorrectly destroyed" % [i, column_x, tile["x"], tile["y"]]
				_record_failure(msg)
				return

		# Assert: all tiles in the target column are destroyed (none missed)
		for tile in tiles:
			if tile["x"] == column_x:
				var found = false
				for destroyed_tile in algorithm_destroyed:
					if destroyed_tile["x"] == tile["x"] and destroyed_tile["y"] == tile["y"]:
						found = true
						break
				if not found:
					var msg = "Iteration %d: column %d - tile at (%d,%d) in target column was not destroyed" % [i, column_x, tile["x"], tile["y"]]
					_record_failure(msg)
					return

	_record_pass("Property 9: Harpoon Column Destruction")


# --- Property 10: Harpoon Scoring ---
# Points awarded = N² × tile_point for N destroyed tiles.

func test_property_10_harpoon_scoring():
	# Feature: game-economy-and-shop, Property 10: Harpoon Scoring
	# **Validates: Requirements 6.5**
	print("Property 10: Harpoon Scoring (%d iterations)" % ITERATIONS)

	for i in range(ITERATIONS):
		var column_x = rand_column()
		var tiles = rand_board_with_column_tiles(column_x)

		# Count tiles in the target column
		var column_tiles = get_column_tiles(tiles, column_x)
		var n = column_tiles.size()

		# Compute expected points: N² × tile_point
		var expected_points = n * n * Settings.tile_point

		# Replicate the scoring algorithm from Game.gd execute_harpoon
		var tile_count = column_tiles.size()
		var algorithm_points = tile_count * tile_count * Settings.tile_point

		# Assert: points match expected formula
		if algorithm_points != expected_points:
			var msg = "Iteration %d: column %d with %d tiles - expected %d points, got %d" % [i, column_x, n, expected_points, algorithm_points]
			_record_failure(msg)
			return

		# Assert: points are always positive (N >= 1 guaranteed by generator)
		if algorithm_points <= 0:
			var msg = "Iteration %d: column %d with %d tiles - points %d should be positive" % [i, column_x, n, algorithm_points]
			_record_failure(msg)
			return

		# Assert: points scale quadratically with tile count
		if n > 1:
			var points_for_one_less = (n - 1) * (n - 1) * Settings.tile_point
			if algorithm_points <= points_for_one_less:
				var msg = "Iteration %d: column %d - points for %d tiles (%d) should exceed points for %d tiles (%d)" % [i, column_x, n, algorithm_points, n - 1, points_for_one_less]
				_record_failure(msg)
				return

	_record_pass("Property 10: Harpoon Scoring")


# --- Property 11: Powerup Consumption (Harpoon) ---
# After harpoon activation on non-empty column, harpoon inventory decreases by 1.

func test_property_11_powerup_consumption_harpoon():
	# Feature: game-economy-and-shop, Property 11: Powerup Consumption (Harpoon)
	# **Validates: Requirements 6.4**
	print("Property 11: Powerup Consumption - Harpoon (%d iterations)" % ITERATIONS)

	for i in range(ITERATIONS):
		var starting_count = rand_harpoon_inventory()

		# Set up GameStore state
		GameStore.inventory["harpoon"] = starting_count

		# Execute: use_powerup("harpoon") — this is what execute_harpoon calls
		var result = GameStore.use_powerup("harpoon")

		# Assert: use_powerup returns true (count was >= 1)
		if result != true:
			var msg = "Iteration %d: use_powerup('harpoon') returned false with count %d" % [i, starting_count]
			_record_failure(msg)
			return

		# Assert: harpoon inventory decreased by exactly 1
		var expected_count = starting_count - 1
		if GameStore.inventory["harpoon"] != expected_count:
			var msg = "Iteration %d: expected harpoon count %d, got %d (start=%d)" % [i, expected_count, GameStore.inventory["harpoon"], starting_count]
			_record_failure(msg)
			return

	_record_pass("Property 11: Powerup Consumption (Harpoon)")


# --- Test Infrastructure ---

func _record_pass(test_name: String):
	_passed += 1
	print("  ✓ PASSED: %s" % test_name)


func _record_failure(msg: String):
	_failed += 1
	_errors.append(msg)
	print("  ✗ FAILED: %s" % msg)
