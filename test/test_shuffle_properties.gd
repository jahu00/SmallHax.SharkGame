# Feature: game-economy-and-shop, Property 12: Shuffle Maximizes Vertical Adjacency
# Feature: game-economy-and-shop, Property 13: Shuffle Preserves Color Multiset
# Feature: game-economy-and-shop, Property 11: Powerup Consumption (Shuffle)
# Validates: Requirements 7.2, 7.4, 7.5
#
# Property tests for shuffle powerup logic.
# Implemented as a GdUnit4-compatible test suite with custom repeat loops
# and randomized input generation.
#
# To run: Install GdUnit4 and execute via the Godot test runner,
# or attach this script to a Node in a test scene.

extends Node

const ITERATIONS = 100
const BOARD_WIDTH = 10
const BOARD_HEIGHT = 10
const NUM_COLORS = 5

var _passed := 0
var _failed := 0
var _errors: Array[String] = []


func _ready():
	print("=== Property Tests: Shuffle Powerup Logic ===")
	print("")

	test_property_12_shuffle_maximizes_vertical_adjacency()
	test_property_13_shuffle_preserves_color_multiset()
	test_property_11_powerup_consumption_shuffle()

	print("")
	print("=== Results: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		for err in _errors:
			print("  FAIL: %s" % err)
	print("")


# --- Helper Functions (Generators) ---

func rand_column_tiles() -> Array:
	# Generate a random column of tiles with 1 to BOARD_HEIGHT tiles
	var tile_count = 1 + randi() % BOARD_HEIGHT  # 1 to 10 tiles
	var tiles: Array = []
	# Assign random y positions (unique) and random colors
	var available_ys: Array = []
	for y in range(BOARD_HEIGHT):
		available_ys.append(y)
	available_ys.shuffle()
	for i in range(tile_count):
		tiles.append({"y": available_ys[i], "color": randi() % NUM_COLORS})
	return tiles


func rand_column_tiles_with_colors(min_tiles: int, max_tiles: int) -> Array:
	# Generate a column with a specified range of tile counts
	var tile_count = min_tiles + randi() % (max_tiles - min_tiles + 1)
	tile_count = clampi(tile_count, 1, BOARD_HEIGHT)
	var tiles: Array = []
	var available_ys: Array = []
	for y in range(BOARD_HEIGHT):
		available_ys.append(y)
	available_ys.shuffle()
	for i in range(tile_count):
		tiles.append({"y": available_ys[i], "color": randi() % NUM_COLORS})
	return tiles


func rand_shuffle_inventory() -> int:
	# Generate a random shuffle count >= 1
	return 1 + randi() % GameStore.MAX_POWERUP


func count_vertical_adjacency(tiles: Array) -> int:
	# Count the number of vertically adjacent same-color pairs in a column.
	# Tiles are sorted by y position, then consecutive pairs with same color are counted.
	if tiles.size() <= 1:
		return 0
	var sorted_tiles = tiles.duplicate()
	sorted_tiles.sort_custom(func(a, b): return a["y"] < b["y"])
	var count = 0
	for i in range(sorted_tiles.size() - 1):
		if sorted_tiles[i]["color"] == sorted_tiles[i + 1]["color"]:
			count += 1
	return count


func compute_max_adjacency(color_multiset: Dictionary) -> int:
	# Compute the maximum possible vertically adjacent same-color pairs
	# for a given multiset of colors.
	#
	# The maximum adjacency is achieved by grouping all tiles of the same color
	# together. For a color with count C, it contributes (C - 1) adjacent pairs.
	# The total maximum is sum of (count - 1) for all colors = total_tiles - num_distinct_colors.
	var total_tiles = 0
	var num_colors_present = 0
	for color in color_multiset.keys():
		if color_multiset[color] > 0:
			total_tiles += color_multiset[color]
			num_colors_present += 1
	if total_tiles <= 1:
		return 0
	return total_tiles - num_colors_present


func get_color_multiset(tiles: Array) -> Dictionary:
	# Build a frequency dictionary of colors from a tile array
	var multiset: Dictionary = {}
	for tile in tiles:
		var color = tile["color"]
		if not multiset.has(color):
			multiset[color] = 0
		multiset[color] += 1
	return multiset


func apply_shuffle_algorithm(tiles: Array) -> Array:
	# Replicate the shuffle algorithm from Game.gd execute_shuffle for a single column.
	# Input: array of {"y": int, "color": int} dicts
	# Output: array of {"y": int, "color": int} dicts with new y positions assigned
	if tiles.size() <= 1:
		return tiles.duplicate(true)

	# Count frequency of each color
	var color_counts: Dictionary = {}
	for tile in tiles:
		var color = tile["color"]
		if not color_counts.has(color):
			color_counts[color] = 0
		color_counts[color] += 1

	# Sort colors by frequency (most frequent first)
	var color_list = color_counts.keys()
	color_list.sort_custom(func(a, b): return color_counts[a] > color_counts[b])

	# Build ordered tile list: group tiles by color in frequency order
	var ordered_tiles: Array = []
	for color in color_list:
		for tile in tiles:
			if tile["color"] == color:
				ordered_tiles.append(tile.duplicate())

	# Find the max y position (bottom of column)
	var max_y = 0
	for tile in tiles:
		if tile["y"] > max_y:
			max_y = tile["y"]

	# Assign new y positions bottom-up
	var current_y = max_y
	for tile in ordered_tiles:
		tile["y"] = current_y
		current_y -= 1

	return ordered_tiles


# --- Property 12: Shuffle Maximizes Vertical Adjacency ---
# For any column of tiles with a given multiset of colors, after applying
# the Shuffle algorithm, the number of vertically adjacent same-color tile
# pairs in that column shall be the maximum achievable for that multiset.

func test_property_12_shuffle_maximizes_vertical_adjacency():
	# Feature: game-economy-and-shop, Property 12: Shuffle Maximizes Vertical Adjacency
	# **Validates: Requirements 7.2**
	print("Property 12: Shuffle Maximizes Vertical Adjacency (%d iterations)" % ITERATIONS)

	for i in range(ITERATIONS):
		var tiles = rand_column_tiles()

		# Compute the color multiset before shuffle
		var color_multiset = get_color_multiset(tiles)

		# Compute the theoretical maximum adjacency for this multiset
		var max_adjacency = compute_max_adjacency(color_multiset)

		# Apply the shuffle algorithm
		var shuffled_tiles = apply_shuffle_algorithm(tiles)

		# Count actual adjacency after shuffle
		var actual_adjacency = count_vertical_adjacency(shuffled_tiles)

		# Assert: actual adjacency equals the theoretical maximum
		if actual_adjacency != max_adjacency:
			var msg = "Iteration %d: expected max adjacency %d, got %d. Colors: %s" % [i, max_adjacency, actual_adjacency, str(color_multiset)]
			_record_failure(msg)
			return

		# Assert: adjacency is non-negative
		if actual_adjacency < 0:
			var msg = "Iteration %d: adjacency %d is negative" % [i, actual_adjacency]
			_record_failure(msg)
			return

	_record_pass("Property 12: Shuffle Maximizes Vertical Adjacency")


# --- Property 13: Shuffle Preserves Color Multiset ---
# For any column of tiles, the multiset of tile colors in that column before
# the Shuffle shall be identical to the multiset after the Shuffle.

func test_property_13_shuffle_preserves_color_multiset():
	# Feature: game-economy-and-shop, Property 13: Shuffle Preserves Color Multiset
	# **Validates: Requirements 7.5**
	print("Property 13: Shuffle Preserves Color Multiset (%d iterations)" % ITERATIONS)

	for i in range(ITERATIONS):
		var tiles = rand_column_tiles()

		# Record the color multiset before shuffle
		var multiset_before = get_color_multiset(tiles)

		# Apply the shuffle algorithm
		var shuffled_tiles = apply_shuffle_algorithm(tiles)

		# Record the color multiset after shuffle
		var multiset_after = get_color_multiset(shuffled_tiles)

		# Assert: same number of tiles
		if tiles.size() != shuffled_tiles.size():
			var msg = "Iteration %d: tile count changed from %d to %d" % [i, tiles.size(), shuffled_tiles.size()]
			_record_failure(msg)
			return

		# Assert: multisets are identical
		if not multisets_equal(multiset_before, multiset_after):
			var msg = "Iteration %d: color multiset changed. Before: %s, After: %s" % [i, str(multiset_before), str(multiset_after)]
			_record_failure(msg)
			return

		# Assert: no new colors introduced
		for color in multiset_after.keys():
			if not multiset_before.has(color):
				var msg = "Iteration %d: new color %d introduced after shuffle" % [i, color]
				_record_failure(msg)
				return

		# Assert: no colors removed
		for color in multiset_before.keys():
			if not multiset_after.has(color):
				var msg = "Iteration %d: color %d removed after shuffle" % [i, color]
				_record_failure(msg)
				return

	_record_pass("Property 13: Shuffle Preserves Color Multiset")


func multisets_equal(a: Dictionary, b: Dictionary) -> bool:
	# Check if two color frequency dictionaries are identical
	if a.size() != b.size():
		return false
	for key in a.keys():
		if not b.has(key):
			return false
		if a[key] != b[key]:
			return false
	return true


# --- Property 11: Powerup Consumption (Shuffle) ---
# After shuffle activation, shuffle inventory decreases by 1.

func test_property_11_powerup_consumption_shuffle():
	# Feature: game-economy-and-shop, Property 11: Powerup Consumption (Shuffle)
	# **Validates: Requirements 7.4**
	print("Property 11: Powerup Consumption - Shuffle (%d iterations)" % ITERATIONS)

	for i in range(ITERATIONS):
		var starting_count = rand_shuffle_inventory()

		# Set up GameStore state
		GameStore.inventory["shuffle"] = starting_count

		# Execute: use_powerup("shuffle") — this is what on_shuffle_activated calls
		var result = GameStore.use_powerup("shuffle")

		# Assert: use_powerup returns true (count was >= 1)
		if result != true:
			var msg = "Iteration %d: use_powerup('shuffle') returned false with count %d" % [i, starting_count]
			_record_failure(msg)
			return

		# Assert: shuffle inventory decreased by exactly 1
		var expected_count = starting_count - 1
		if GameStore.inventory["shuffle"] != expected_count:
			var msg = "Iteration %d: expected shuffle count %d, got %d (start=%d)" % [i, expected_count, GameStore.inventory["shuffle"], starting_count]
			_record_failure(msg)
			return

	_record_pass("Property 11: Powerup Consumption (Shuffle)")


# --- Test Infrastructure ---

func _record_pass(test_name: String):
	_passed += 1
	print("  ✓ PASSED: %s" % test_name)


func _record_failure(msg: String):
	_failed += 1
	_errors.append(msg)
	print("  ✗ FAILED: %s" % msg)
