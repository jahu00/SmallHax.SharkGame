# Requirements Document

## Introduction

This feature adds an in-game economy system to SharkGame, a Same Game (tile-matching puzzle) built in Godot 4. Players earn coins through gameplay, spend them in a persistent shop for powerups, and can try their luck on a spinning wheel. The feature also addresses an input leak bug and code quality issues from the Godot 3 to 4 migration.

## Glossary

- **Game**: The SharkGame tile-matching puzzle application
- **Player**: The human user interacting with the Game
- **Coin_System**: The subsystem responsible for tracking, awarding, and spending the in-game currency (coins)
- **Shop**: The persistent store interface where the Player purchases powerups using coins
- **Spinning_Wheel**: A randomized reward mechanism that costs coins to use and awards prizes from a fixed pool
- **Powerup_Inventory**: The persistent collection of powerups the Player owns
- **Bomb**: An active powerup that clears all tiles in a 3x3 area centered on the Player's selected position
- **Rocket**: An active powerup that clears all tiles in the entire column of the Player's selected position
- **Shuffle**: An active powerup that rearranges tiles within every column so that the maximum number of tiles have a matching-color neighbour
- **Extra_Life**: A passive powerup that allows the Player to advance to the next level even without reaching the required score threshold; consumed upon activation
- **Settings_Autoload**: The Settings.gd autoload script that defines all game constants and configuration values
- **Persistence_Layer**: The subsystem responsible for saving and loading Player data (coins, powerup inventory) across application restarts
- **Input_Handler**: The subsystem responsible for processing Player touch and click events
- **Board**: The grid of tiles (10x10) where gameplay takes place
- **Game_Over_State**: The state entered when no more valid moves exist and the Player cannot advance to the next level

## Requirements

### Requirement 1: Coin Earning on Game Over

**User Story:** As a Player, I want to earn coins when my game ends, so that I am rewarded for my progress even when I lose.

#### Acceptance Criteria

1. WHEN the Game enters Game_Over_State, THE Coin_System SHALL award the Player a number of coins equal to the current level (minimum 1) multiplied by the `coins_per_level` constant defined in Settings_Autoload, and add the result to the Player's existing coin balance.
2. WHEN the Game enters Game_Over_State, THE Coin_System SHALL persist the updated coin balance to the Persistence_Layer before the scene transitions to the menu.
3. THE Settings_Autoload SHALL define a `coins_per_level` integer constant with a default value of 1.
4. IF the Persistence_Layer fails to save the updated coin balance, THEN THE Coin_System SHALL retain the awarded coins in memory for the current session and reattempt persistence on the next save opportunity.

### Requirement 2: Bonus Points to Coins Conversion

**User Story:** As a Player, I want to earn bonus coins when I clear a level efficiently, so that I am rewarded for skillful play.

#### Acceptance Criteria

1. WHEN the Player completes a level with tiles remaining on the Board equal to or fewer than the configurable `bonus_tile_threshold` defined in Settings_Autoload, THE Coin_System SHALL award bonus coins equal to the floor of (bonus points earned multiplied by `bonus_to_coins_coefficient`).
2. THE Settings_Autoload SHALL define a `bonus_to_coins_coefficient` constant with a default value of 0.5 that determines the conversion rate from bonus points to coins.
3. WHEN the Player completes a level with more tiles remaining on the Board than `bonus_tile_threshold`, THE Coin_System SHALL award zero bonus coins for that level.
4. THE Settings_Autoload SHALL define a `bonus_tile_threshold` integer constant with a default value of 10 that determines the maximum number of remaining tiles for which bonus coins are awarded.

### Requirement 3: Persistent Coin and Inventory Storage

**User Story:** As a Player, I want my coins and purchased powerups to persist across application restarts, so that I do not lose my progress.

#### Acceptance Criteria

1. THE Persistence_Layer SHALL save the Player's coin balance and Powerup_Inventory to a JSON file at the path "user://save_data.json".
2. WHEN the Game application starts, THE Persistence_Layer SHALL load the previously saved coin balance and Powerup_Inventory from "user://save_data.json" and restore them as the active state.
3. IF the save file does not exist or cannot be parsed as valid JSON containing the required keys (coin balance and each Powerup_Inventory type), THEN THE Persistence_Layer SHALL initialize the coin balance to zero and the Powerup_Inventory to zero for each powerup type (Bomb, Rocket, Shuffle, Extra_Life).
4. WHEN the coin balance changes or any Powerup_Inventory count changes, THE Persistence_Layer SHALL write the complete updated state to "user://save_data.json" before the end of the current frame.
5. THE Persistence_Layer SHALL store the coin balance as an integer in the range 0 to 999,999,999 and each powerup count (Bomb, Rocket, Shuffle, Extra_Life) as an integer in the range 0 to 99.
6. IF a write to "user://save_data.json" fails, THEN THE Persistence_Layer SHALL retain the current in-memory state unchanged and reattempt the save on the next state change.

### Requirement 4: Shop Interface

**User Story:** As a Player, I want to access a shop from the main menu, so that I can purchase powerups with my earned coins.

#### Acceptance Criteria

1. THE Shop SHALL display the following items with their prices: Bomb (100 coins), Rocket (250 coins), Shuffle (500 coins), Extra_Life (1000 coins).
2. THE Shop SHALL display the Player's current coin balance as a numeric value.
3. WHEN the Player selects a purchasable item and the Player's coin balance is greater than or equal to the item's price, THE Shop SHALL deduct the item price from the coin balance, add one unit of the item to the Powerup_Inventory, and display a visual confirmation indicating the purchase succeeded.
4. WHILE the Player's coin balance is less than an item's price, THE Shop SHALL display that item as non-interactive and visually distinct from affordable items.
5. THE Settings_Autoload SHALL define the price for each shop item (`bomb_price`, `rocket_price`, `shuffle_price`, `extra_life_price`).
6. WHEN the Player presses the Shop button on the main menu, THE System SHALL navigate to the Shop scene.
7. WHEN the Player presses the Back button in the Shop, THE System SHALL navigate back to the main menu.

### Requirement 5: Bomb Powerup Activation

**User Story:** As a Player, I want to use a Bomb powerup during gameplay, so that I can clear a 3x3 area of tiles to create new matching opportunities.

#### Acceptance Criteria

1. WHILE the Player owns at least one Bomb in the Powerup_Inventory and the game state is PlayerMove, THE Game SHALL display the Bomb as activatable and accept Player input to activate the Bomb powerup.
2. WHEN the Player activates the Bomb powerup and selects a board position (column 0–9, row 0–9), THE Game SHALL destroy all tiles within a 3x3 area centered on the selected position, awarding zero points for the destroyed tiles.
3. WHEN the Bomb destroys tiles, THE Game SHALL decrement the Bomb count in the Powerup_Inventory by one and update the displayed inventory count.
4. WHEN the Bomb destroys tiles at the edge of the Board, THE Game SHALL destroy only the tiles that exist within the valid board bounds (columns 0–9, rows 0–9) and ignore positions outside the grid.
5. WHEN the Bomb destroys tiles, THE Game SHALL transition the game state to DestroyTiles, then reposition remaining tiles using the existing gravity and column-compaction logic (state MoveTiles), and then evaluate whether valid moves remain before returning to PlayerMove or triggering game-over.
6. IF the Player activates the Bomb powerup while tiles are currently selected, THEN THE Game SHALL deselect all currently selected tiles before applying the Bomb effect.

### Requirement 6: Rocket Powerup Activation

**User Story:** As a Player, I want to use a Rocket powerup during gameplay, so that I can clear an entire column of tiles.

#### Acceptance Criteria

1. WHILE the Player owns at least one Rocket in the Powerup_Inventory and the game state is PlayerMove, THE Game SHALL allow the Player to activate the Rocket powerup.
2. WHEN the Player activates the Rocket powerup and selects a column (index 0 through 9) on the Board that contains at least one tile, THE Game SHALL destroy all remaining tiles in that column regardless of gaps between them.
3. IF the Player activates the Rocket powerup and selects a column that contains zero tiles, THEN THE Game SHALL cancel the activation without consuming a Rocket from the Powerup_Inventory.
4. WHEN the Rocket destroys tiles, THE Game SHALL remove one Rocket from the Powerup_Inventory and update the Powerup_Inventory count displayed to the Player.
5. WHEN the Rocket destroys tiles, THE Game SHALL award score points using the same tile-point formula applied to normal tile removal, based on the number of tiles destroyed.
6. WHEN the Rocket destroys tiles, THE Game SHALL reposition remaining tiles using the existing gravity (tiles fall down) and column-compaction (columns shift left to fill empty columns) logic.
7. WHILE the Rocket powerup is activated and awaiting column selection, IF the Player cancels the activation (e.g., by re-pressing the Rocket button), THEN THE Game SHALL return to the PlayerMove state without consuming a Rocket.

### Requirement 7: Shuffle Powerup Activation

**User Story:** As a Player, I want to use a Shuffle powerup during gameplay, so that I can rearrange tiles to create new matching opportunities.

#### Acceptance Criteria

1. WHILE the Player owns at least one Shuffle in the Powerup_Inventory and the game state is PlayerMove, THE Game SHALL display the Shuffle powerup button as enabled and allow the Player to activate it.
2. WHEN the Player activates the Shuffle powerup, THE Game SHALL rearrange tiles within each column independently so that the number of vertically adjacent same-color tile pairs in that column is maximized, without moving tiles across columns.
3. WHEN the Player activates the Shuffle powerup, THE Game SHALL transition the game state to MoveTiles, blocking player input until all tile movement animations complete, then return to PlayerMove.
4. WHEN the Shuffle rearranges tiles, THE Game SHALL remove exactly one Shuffle from the Powerup_Inventory and persist the updated count to the game data store before the animation begins.
5. WHEN the Shuffle rearranges tiles, THE Game SHALL not add or remove any tiles from the Board; the set of tile colors present in each column before and after the shuffle SHALL be identical.
6. WHEN the Shuffle rearranges tiles, THE Game SHALL animate each tile moving to its new position at the existing tile_move_speed (750 pixels per second).
7. IF the Player activates the Shuffle powerup and the tiles in every column are already arranged with maximum vertical adjacency, THEN THE Game SHALL still consume one Shuffle from the Powerup_Inventory and complete the activation without error.

### Requirement 8: Extra Life Powerup Activation

**User Story:** As a Player, I want an Extra Life powerup to automatically save me from game over, so that I can continue progressing.

#### Acceptance Criteria

1. WHEN no valid moves remain and the board has been cleared and the Player's score is below the level threshold (GameStore.data.score < GameStore.data.next) and the Player owns at least one Extra_Life in the Powerup_Inventory, THE Game SHALL consume one Extra_Life from the Powerup_Inventory, bypass the score threshold check, and advance the Player to the next level by calling next_level().
2. WHEN the Extra_Life is consumed, THE Game SHALL persist the updated Powerup_Inventory to disk within the same operation before advancing to the next level.
3. WHEN no valid moves remain and the board has been cleared and the Player's score is below the level threshold and the Player owns zero Extra_Life items in the Powerup_Inventory, THE Game SHALL display the game over overlay and enter Game_Over_State.
4. WHEN the Extra_Life is consumed, THE Game SHALL display a visual indication to the Player that an Extra_Life was used, showing the remaining Extra_Life count, for a minimum of 1 second before advancing to the next level.

### Requirement 9: Spinning Wheel

**User Story:** As a Player, I want to spin a wheel for a chance at prizes, so that I have an exciting way to spend coins and potentially gain powerups.

#### Acceptance Criteria

1. THE Spinning_Wheel SHALL be accessible via a dedicated button on the main menu screen.
2. THE Spinning_Wheel SHALL cost 100 coins per spin, defined as `spin_cost` in Settings_Autoload.
3. WHILE the Player's coin balance is less than the spin cost, THE Spinning_Wheel SHALL disable the spin action and the spin button SHALL appear visually disabled.
4. WHEN the Player spins the wheel, THE Spinning_Wheel SHALL deduct the spin cost from the coin balance before starting the spin animation.
5. THE Spinning_Wheel SHALL have exactly 9 prize slots with equal probability (1/9 each): Nothing, 1x Bomb, 1x Rocket, 2x Bomb, 1x Shuffle, 3x Bomb, 1x Extra_Life, 1000 coins, 3x Bomb.
6. WHEN the wheel lands on a powerup prize, THE Spinning_Wheel SHALL add the corresponding items to the Powerup_Inventory and persist the change.
7. WHEN the wheel lands on the 1000 coins prize, THE Spinning_Wheel SHALL add 1000 coins to the Player's balance and persist the change.
8. WHEN the wheel lands on Nothing, THE Spinning_Wheel SHALL award no prize.
9. WHEN the Player spins the wheel, THE Spinning_Wheel SHALL display a spinning animation lasting between 2 and 4 seconds before revealing the result.
10. WHEN the wheel stops spinning, THE Spinning_Wheel SHALL display the prize result to the Player for at least 2 seconds before allowing another spin or dismissal.
11. WHILE the spinning animation is playing, THE Spinning_Wheel SHALL disable the spin button to prevent multiple concurrent spins.

### Requirement 10: Input Leak Bug Fix

**User Story:** As a Player, I want button presses to only affect the current screen, so that navigating between screens does not trigger unintended actions.

#### Acceptance Criteria

1. WHEN the Player presses a button that triggers a scene transition (menu button, game over tap), THE System SHALL handle the input through an event-consuming mechanism (such as Godot 4 Control "pressed" signals or `accept_event()`) so that the input event does not propagate to the next scene.
2. THE Menu scene buttons (NewGameButton, ContinueButton, ExitButton) SHALL connect to Godot 4 Control "pressed" signals instead of connecting to `gui_input` with manual `InputEventMouseButton`/`InputEventScreenTouch` type checks.
3. THE Game scene menu button SHALL connect to a Godot 4 Control "pressed" signal instead of `gui_input`, and SHALL only trigger a scene transition when the game state is "PlayerMove".
4. THE Game scene game over overlay SHALL handle tap input through an event-consuming mechanism (a child Button node with a "pressed" signal, or calling `accept_event()` within `_gui_input`) so that the tap does not propagate to the next scene.
5. WHEN a scene transition is requested via `Global.change_scene_to_file`, THE Main scene manager SHALL defer the new scene instantiation by at least one idle frame (e.g., using `call_deferred` or `await get_tree().process_frame`) before adding the new scene to the tree.
6. WHEN a scene transition occurs, THE Main scene manager SHALL remove the current scene's node tree before the deferred frame elapses, so that no input events can reach the old scene's handlers during the deferral period.

### Requirement 11: Code Quality Improvements

**User Story:** As a developer, I want the codebase to follow Godot 4 best practices, so that the code is maintainable and free of anti-patterns from the Godot 3 migration.

#### Acceptance Criteria

1. THE Menu scene SHALL use Button or TextureButton nodes for the ContinueButton, NewGameButton, and ExitButton interactive elements instead of FrameContainer instances with manual gui_input event handling.
2. THE Game scene SHALL use a Button or TextureButton node for the MenuButton interactive element instead of a FrameContainer instance with manual gui_input event handling.
3. WHEN connecting signals in Menu.gd, Game.gd, and Main.gd, THE Game SHALL use the direct reference syntax (signal_name.connect(method_reference)) instead of the Callable(self, "method_name") string-based syntax.
4. WHEN emitting signals in Global.gd, THE Game SHALL use the direct emit syntax (signal_name.emit()) instead of the string-based emit_signal("signal_name") syntax.
5. THE Menu scene SHALL connect menu button actions using the "pressed" signal instead of the "gui_input" signal with manual InputEventMouseButton or InputEventScreenTouch type checks.
6. THE Game scene SHALL connect the menu button and game over container actions using the "pressed" signal instead of the "gui_input" signal with manual InputEventMouseButton or InputEventScreenTouch type checks.

### Requirement 12: Centralized Configuration

**User Story:** As a developer, I want all economy constants defined in one place, so that balancing the game is straightforward.

#### Acceptance Criteria

1. THE Settings_Autoload SHALL define the following economy-related constants as simple `var` declarations with integer values: `coins_per_level`, `bonus_to_coins_coefficient`, `bomb_price`, `rocket_price`, `shuffle_price`, `extra_life_price`, `spin_cost`, and `bonus_tile_threshold` (default value: 10), following the same declaration pattern as the existing `tile_height`, `board_width`, and `level_points` constants.
2. THE Coin_System, Shop, and Spinning_Wheel SHALL read all pricing and reward values exclusively from Settings_Autoload, with no economy-related numeric literals hardcoded in those scripts.
3. THE Settings_Autoload SHALL contain only `var` declarations and no functions, conditional statements, signal emissions, or node references beyond what is required by the `extends Node` declaration.
4. WHEN a new economy-related constant is needed by Coin_System, Shop, or Spinning_Wheel, THE developer SHALL add it to Settings_Autoload rather than defining it locally in the consuming script.
