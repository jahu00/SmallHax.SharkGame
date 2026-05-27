 # Implementation Plan: Game Economy and Shop

## Overview

This plan implements the full game economy system for SharkGame: coin earning, persistence, shop, powerups (Bomb, Rocket, Shuffle, Extra Life), spinning wheel, input leak fix, and code quality improvements. Tasks are ordered by dependency — foundational infrastructure first, then features that build on it, then integration and wiring.

## Tasks

- [x] 1. Centralized configuration and persistence infrastructure
  - [x] 1.1 Add economy constants to Settings.gd
    - Add `coins_per_level = 1`, `bonus_to_coins_coefficient = 0.5`, `bonus_tile_threshold = 10`
    - Add `bomb_price = 100`, `rocket_price = 250`, `shuffle_price = 500`, `extra_life_price = 1000`
    - Add `spin_cost = 100`
    - Follow the existing `var` declaration pattern (no functions, no conditionals)
    - _Requirements: 12.1, 12.3, 1.3, 2.2, 2.4, 4.5, 9.2_

  - [x] 1.2 Implement persistence layer in GameStore.gd
    - Add `var coins: int = 0` and `var inventory: Dictionary = {"bomb": 0, "rocket": 0, "shuffle": 0, "extra_life": 0}`
    - Add constants `SAVE_PATH = "user://save_data.json"`, `MAX_COINS = 999_999_999`, `MAX_POWERUP = 99`
    - Implement `load_data()`: read JSON from SAVE_PATH, parse and restore coins/inventory, initialize defaults if file missing or corrupt
    - Implement `save_data()`: serialize coins/inventory to JSON, write to SAVE_PATH, handle write failures by retaining in-memory state
    - Call `load_data()` in `_ready()`
    - Implement `add_coins(amount)` with clamping to MAX_COINS, calls `save_data()`
    - Implement `spend_coins(amount) -> bool` that returns false if insufficient, otherwise deducts and saves
    - Implement `add_powerup(type, count)` with clamping to MAX_POWERUP, calls `save_data()`
    - Implement `use_powerup(type) -> bool` that returns false if count ≤ 0, otherwise decrements and saves
    - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 3.6_

  - [x] 1.3 Write property tests for persistence and value clamping
    - **Property 3: Persistence Round Trip** — For any valid coins [0, 999_999_999] and powerup counts [0, 99], serialize then deserialize produces identical state
    - **Property 4: Value Clamping** — Coin additions exceeding MAX_COINS clamp to MAX_COINS; powerup additions exceeding MAX_POWERUP clamp to 99; values never negative
    - **Validates: Requirements 3.2, 3.5**

- [x] 2. Coin earning system
  - [x] 2.1 Implement game-over coin award in GameStore.gd
    - Add `award_game_over_coins()` function: calculates `data.level * Settings.coins_per_level`, calls `add_coins()`
    - _Requirements: 1.1, 1.2_

  - [x] 2.2 Implement bonus coin award in GameStore.gd
    - Add `award_bonus_coins(remaining_tiles: int, bonus_points: int)` function
    - If `remaining_tiles <= Settings.bonus_tile_threshold`: award `int(floor(bonus_points * Settings.bonus_to_coins_coefficient))`
    - If `remaining_tiles > Settings.bonus_tile_threshold`: award zero
    - _Requirements: 2.1, 2.3, 2.4_

  - [x] 2.3 Write property tests for coin earning
    - **Property 1: Coin Award on Game Over** — For any level ≥ 1 and any existing balance, coins awarded = level * coins_per_level, new balance = old + awarded
    - **Property 2: Bonus Coin Calculation** — For any remaining tiles and bonus points, correct bonus coins are calculated based on threshold
    - **Validates: Requirements 1.1, 2.1, 2.3**

- [x] 3. Checkpoint - Ensure persistence and coin systems work
  - Ensure all tests pass, ask the user if questions arise.

- [x] 4. Code quality improvements and input leak fix
  - [x] 4.1 Modernize Global.gd signal syntax
    - Replace `emit_signal("signal_name")` with `signal_name.emit()` for all signals
    - Add `coins_changed` and `inventory_changed` signals if needed for UI reactivity
    - _Requirements: 11.4_

  - [x] 4.2 Fix Main.gd scene transitions with deferred instantiation
    - Replace `Callable(self, "method_name")` connections with direct reference syntax (`signal.connect(method)`)
    - In `on_scene_changing()`: call `clear_scene()` to remove old scene immediately, then `await get_tree().process_frame` before instantiating the new scene
    - Add Shop and SpinningWheel to the match statement
    - _Requirements: 10.5, 10.6, 11.3_

  - [x] 4.3 Update Scenes.gd with new scene preloads
    - Add `Shop` and `SpinningWheel` to `SceneEnum`
    - Add `var Shop = preload("res://Shop.tscn")` and `var SpinningWheel = preload("res://SpinningWheel.tscn")`
    - _Requirements: 4.6, 9.1_

  - [x] 4.4 Refactor Menu.gd to use pressed signals and proper buttons
    - Replace `gui_input` connections with `pressed` signal connections for NewGameButton, ContinueButton, ExitButton
    - Use direct reference signal syntax (`button.pressed.connect(method)`)
    - Add Shop button and SpinningWheel button with `pressed` signal connections
    - Display current coin balance on the menu
    - _Requirements: 10.2, 11.1, 11.3, 11.5, 4.6, 9.1_

  - [x] 4.5 Refactor Game.gd menu button and game over to use pressed signals
    - Replace `gui_input` connection on menu_button with `pressed` signal; only allow transition when state == "PlayerMove"
    - Replace game_over_container `gui_input` with a child Button node using `pressed` signal (or use `accept_event()` in `_gui_input`)
    - Use direct reference signal syntax throughout
    - _Requirements: 10.1, 10.3, 10.4, 11.2, 11.3, 11.6_

- [x] 5. Checkpoint - Ensure code quality and input leak fixes work
  - Ensure all tests pass, ask the user if questions arise.

- [x] 6. Shop implementation
  - [x] 6.1 Create Shop scene (Shop.tscn + Shop.gd)
    - Create Shop.tscn with a VBoxContainer layout: coin balance label at top, item rows (Bomb, Rocket, Shuffle, Extra_Life) each with name, price, and Buy button, and a Back button
    - In `_ready()`: populate prices from Settings, update affordability based on `GameStore.coins`
    - Implement `_on_buy_pressed(item_type)`: call `GameStore.spend_coins(price)`, if true call `GameStore.add_powerup(item_type)`, show visual confirmation, update affordability
    - Implement `_on_back_pressed()`: navigate to Menu via `Global.change_scene_to_file(Scenes.SceneEnum.Menu)`
    - Implement `update_affordability()`: disable/visually distinguish items where `GameStore.coins < price`
    - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.7, 12.2_

  - [x] 6.2 Write property tests for shop purchase logic
    - **Property 5: Purchase Transaction Integrity** — For any balance ≥ price, purchase results in new_balance = old - price and powerup count += 1
    - **Property 6: Affordability Determination** — Item affordable iff balance >= price
    - **Validates: Requirements 4.3, 4.4**

- [x] 7. Spinning wheel implementation
  - [x] 7.1 Create SpinningWheel scene (SpinningWheel.tscn + SpinningWheel.gd)
    - Create SpinningWheel.tscn with a wheel visual (9 equal segments), spin button, coin balance display, prize result label, and Back button
    - Define `PRIZES` array constant with 9 entries matching the design prize table
    - In `_ready()`: set up wheel, check affordability (`GameStore.coins >= Settings.spin_cost`)
    - Implement `_on_spin_pressed()`: deduct `Settings.spin_cost` via `GameStore.spend_coins()`, disable spin button, start spin animation
    - Implement spin animation: use Tween with ease-out curve, randomized duration 2–4 seconds, multiple full rotations + random final position
    - Implement `_on_spin_complete(segment_index)`: look up prize from PRIZES array, award via `GameStore.add_coins()` or `GameStore.add_powerup()`, display result for 2+ seconds, re-enable spin button
    - Implement `_on_back_pressed()`: navigate to Menu
    - Disable spin button while animation plays and while balance < spin_cost
    - _Requirements: 9.1, 9.2, 9.3, 9.4, 9.5, 9.6, 9.7, 9.8, 9.9, 9.10, 9.11, 12.2_

  - [x] 7.2 Write property tests for spinning wheel
    - **Property 14: Spin Cost Deduction** — For any balance >= spin_cost, new balance = old - spin_cost after spin
    - **Property 15: Prize Segment Mapping** — For any segment index [0,8], correct prize is returned and awarded
    - **Validates: Requirements 9.4, 9.5, 9.6**

- [x] 8. Checkpoint - Ensure shop and spinning wheel work
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 9. PowerupBar UI component
  - [ ] 9.1 Create PowerupBar component (PowerupBar.tscn + PowerupBar.gd)
    - Create PowerupBar.tscn as an HBoxContainer with buttons for Bomb, Rocket, Shuffle, each showing inventory count
    - Implement `update_counts()`: refresh displayed counts from `GameStore.inventory`
    - Define signals: `bomb_activated`, `rocket_activated`, `shuffle_activated`
    - Buttons emit their respective signal on press; disabled when count == 0 or game state is not PlayerMove
    - _Requirements: 5.1, 6.1, 7.1_

  - [ ]* 9.2 Write property test for powerup button enabled state
    - **Property 7: Powerup Button Enabled State** — Button enabled iff inventory count >= 1 AND game state is PlayerMove
    - **Validates: Requirements 5.1, 6.1, 7.1**

- [ ] 10. Bomb powerup activation in Game.gd
  - [ ] 10.1 Implement Bomb targeting and destruction logic
    - Add `PowerupTarget` sub-state to Game.gd state machine
    - When `bomb_activated` signal received: deselect any selected tiles, set state to "PowerupTarget", store active powerup type as "bomb"
    - On tile click in PowerupTarget state with bomb: calculate 3x3 area centered on clicked tile's (x, y), collect all tiles within bounds [0,9], destroy them (zero points), call `GameStore.use_powerup("bomb")`, transition to DestroyTiles
    - If player re-presses bomb button during PowerupTarget: cancel, return to PlayerMove
    - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5, 5.6_

  - [ ]* 10.2 Write property tests for Bomb
    - **Property 8: Bomb Area Destruction** — For any center (cx, cy), exactly tiles with |x-cx|≤1 AND |y-cy|≤1 within [0,9] are destroyed, zero points awarded
    - **Property 11: Powerup Consumption (Bomb)** — After bomb activation on valid target, bomb inventory decreases by 1
    - **Validates: Requirements 5.2, 5.3, 5.4**

- [ ] 11. Rocket powerup activation in Game.gd
  - [ ] 11.1 Implement Rocket targeting and destruction logic
    - When `rocket_activated` signal received: deselect any selected tiles, set state to "PowerupTarget", store active powerup type as "rocket"
    - On tile click in PowerupTarget state with rocket: determine column from clicked tile's x, collect all tiles in that column
    - If column is empty: cancel activation, return to PlayerMove without consuming
    - If column has tiles: calculate points (count² × tile_point), destroy all tiles in column, award points, call `GameStore.use_powerup("rocket")`, transition to DestroyTiles
    - If player re-presses rocket button during PowerupTarget: cancel, return to PlayerMove
    - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5, 6.6, 6.7_

  - [ ]* 11.2 Write property tests for Rocket
    - **Property 9: Rocket Column Destruction** — For any column with ≥1 tile, all tiles in that column destroyed, no tiles in other columns affected
    - **Property 10: Rocket Scoring** — Points awarded = N² × tile_point for N destroyed tiles
    - **Property 11: Powerup Consumption (Rocket)** — After rocket activation on non-empty column, rocket inventory decreases by 1
    - **Validates: Requirements 6.2, 6.4, 6.5**

- [ ] 12. Shuffle powerup activation in Game.gd
  - [ ] 12.1 Implement Shuffle logic
    - When `shuffle_activated` signal received and state is PlayerMove: call `GameStore.use_powerup("shuffle")`
    - For each column independently: collect tile colors, sort by frequency (greedy grouping), assign new y positions bottom-up
    - Update `tile.data.y` for each rearranged tile
    - Transition to MoveTiles state (existing animation at tile_move_speed handles movement)
    - After movement completes, return to PlayerMove (existing _process logic handles this)
    - _Requirements: 7.1, 7.2, 7.3, 7.4, 7.5, 7.6, 7.7_

  - [ ]* 12.2 Write property tests for Shuffle
    - **Property 12: Shuffle Maximizes Vertical Adjacency** — After shuffle, each column has maximum possible vertically adjacent same-color pairs
    - **Property 13: Shuffle Preserves Color Multiset** — Multiset of colors per column is identical before and after shuffle
    - **Property 11: Powerup Consumption (Shuffle)** — After shuffle activation, shuffle inventory decreases by 1
    - **Validates: Requirements 7.2, 7.4, 7.5**

- [ ] 13. Checkpoint - Ensure all powerups work correctly
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 14. Extra Life and game-over coin integration
  - [ ] 14.1 Integrate Extra Life and coin awards into Game.gd game-over flow
    - In the MoveTiles completion logic (when no moves remain and board is clear):
      - If `can_advance()`: call `GameStore.award_bonus_coins(remaining_tiles, bonus_points)`, then `next_level()`
      - If NOT `can_advance()` and `GameStore.inventory.extra_life > 0`: call `GameStore.use_powerup("extra_life")`, show visual indication for 1 second (remaining count), then call `next_level()`
      - If NOT `can_advance()` and no Extra_Life: call `GameStore.award_game_over_coins()`, show game over overlay, enter "Over" state
    - Ensure persistence is called before scene transition on game over
    - _Requirements: 1.1, 1.2, 2.1, 8.1, 8.2, 8.3, 8.4_

  - [ ] 14.2 Wire PowerupBar into Game scene
    - Add PowerupBar instance to Game.tscn (lower panel area)
    - Connect `bomb_activated`, `rocket_activated`, `shuffle_activated` signals to Game.gd handlers
    - Call `powerup_bar.update_counts()` after any powerup use or state change
    - Disable powerup buttons when state != PlayerMove
    - _Requirements: 5.1, 6.1, 7.1_

- [ ] 15. Final integration and wiring
  - [ ] 15.1 Wire coin display into Menu and Game scenes
    - Menu: show coin balance, update when returning from Shop/SpinningWheel
    - Game: optionally show coin balance in upper panel (or rely on end-of-game display)
    - Ensure `GameStore.coins` is always loaded from persistence on app start
    - _Requirements: 4.2, 3.2_

  - [ ] 15.2 Update Game.gd end-of-game flow to integrate all systems
    - Ensure `on_game_over_container_input` (now using pressed signal) calls `Global.end_game()`
    - In `Global.end_game()` or `Main.on_game_ending()`: ensure coins are persisted, then transition to Menu
    - Verify bonus coins are awarded on level completion when tiles ≤ threshold
    - _Requirements: 1.2, 2.1, 10.1_

- [ ] 16. Final checkpoint - Ensure all systems integrated and tests pass
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- Tasks marked with `*` are optional and can be skipped for faster MVP
- Each task references specific requirements for traceability
- Checkpoints ensure incremental validation
- Property tests validate universal correctness properties from the design document
- Unit tests validate specific examples and edge cases
- The project uses GDScript with Godot 4.6 and the existing autoload architecture (Settings, GameStore, Global, Scenes)
- All economy constants are centralized in Settings.gd per Requirement 12
- Persistence uses a single JSON file at `user://save_data.json`
- The PowerupTarget sub-state is added to the existing Game state machine for Bomb/Rocket targeting

## Task Dependency Graph

```json
{
  "waves": [
    { "id": 0, "tasks": ["1.1", "4.1"] },
    { "id": 1, "tasks": ["1.2", "4.3"] },
    { "id": 2, "tasks": ["1.3", "2.1", "2.2", "4.2", "4.4", "4.5"] },
    { "id": 3, "tasks": ["2.3", "6.1", "7.1", "9.1"] },
    { "id": 4, "tasks": ["6.2", "7.2", "9.2", "10.1", "11.1", "12.1"] },
    { "id": 5, "tasks": ["10.2", "11.2", "12.2"] },
    { "id": 6, "tasks": ["14.1", "14.2"] },
    { "id": 7, "tasks": ["15.1", "15.2"] }
  ]
}
```
