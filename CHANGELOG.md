# Changelog

All notable changes to this project are documented here. Format loosely follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [0.8.0] - 2026-07-20

### Added
- In-game pause menu (Escape during a level): Resume, New Game (with a discard-progress
  confirmation), Load Game and Settings (both stubbed pending a save system and settings
  screen), Credits, Exit to Main Menu, and Exit Game.
- Victory/defeat end panel now shows dedicated artwork instead of a text label, and pauses
  the game while displayed.

### Changed
- Credits screen's back button now just reads "Back". Reached from the pause menu, it
  returns to the paused game instead of leaving the level; reached from the main menu or
  the victory screen, it still goes to the main menu.

### Fixed
- Credits' back button did nothing: `main_menu.gd` and `credits.gd` preloaded each other's
  scenes, a compile-time cycle Godot resolved by silently handing back an incomplete
  resource. Now loaded by path at call time instead.

## [0.7.1] - 2026-07-20

### Changed
- Upgrade button label now reads "Next level: N" / "Cost: X" instead of "Level N/M" /
  "X coins".

### Fixed
- Tower data resources (`double_barrel`, `laser`, `machinegun`, `mortar`, `single_barrel`,
  `tesla_coil`) resaved with proper resource UIDs and stripped of redundant stat overrides
  that just duplicated their default values.

## [0.7.0] - 2026-07-20

### Added
- Credits button on the main menu, between Play and Quit, taking the player to the credits
  screen without needing to reach it via Victory first.
- Custom steampunk cursor (`scenes/ui/images/cursor-01.png`) and app icon, set project-wide
  via `mouse_cursor/custom_image` and `config/icon`.

### Changed
- Bumped shadow filter quality (directional and positional), forced Lambert diffuse over
  Burley, raised depth-of-field bokeh quality, and enabled occlusion culling - a visual
  quality pass on the default rendering settings.

## [0.6.1] - 2026-07-20

### Fixed
- Credits scene had no way back to the main menu - added a "Back to Main Menu" button
  (`scenes/menu/credits.gd`), styled with the same `Tier2Button` variation used on the main
  menu's own buttons.

## [0.6.0] - 2026-07-20

### Added
- All 6 tower types (single/double barrel, machinegun, laser, mortar, tesla coil) are now
  buyable from the shop panel in every level - previously only 2 placeholder types were
  wired into `available_towers`.
- `SimpleButton` theme variation (`scenes/ui/styles/simple_button.tres`): a 9-sliced brass
  plate style built from `simple_button.png`, now used for the Upgrade and Sell buttons in
  the tower upgrade popup instead of default engine buttons.

### Fixed
- Upgrade button showed "Level 5/4" on a tower's second-to-last upgrade instead of "Level
  5/5" - the max level shown in the button text was hardcoded to 4 rather than derived from
  `TowerData.max_level_index()`, so it fell out of sync once 5-level tower data replaced the
  old placeholders.

## [0.5.0] - 2026-07-18

### Added
- Tower selling: the upgrade popup now shows a Sell button alongside Upgrade, refunding 75%
  of everything spent on that tower (build cost plus every upgrade paid so far), rounded down.
- Victory and Defeat each show two buttons now instead of freezing the game. Victory offers
  Credits and Back to Main Menu; Defeat (renamed from "GAME OVER" to "Defeat!") offers Try
  Again - which resets coins/wave state and reloads the current level fresh - and Back to
  Main Menu.
- Credits scene (`scenes/menu/credits.tscn`): reuses the main menu's background art behind a
  90%-opaque dark panel showing author/studio credits, engine attribution, and an AI-use
  disclaimer for the game's generated art and models.
- Custom UI theme: Oswald (headings, buttons, counters) and Roboto Slab (body text,
  descriptions) applied project-wide through a single `Theme` resource
  (`scenes/ui/theme.tres`) set as the project's default GUI theme, so new UI elements pick up
  the right font automatically. Only the variable-weight font files are kept - Godot 4.7
  supports OpenType variable fonts natively, so each needed weight (Oswald Medium/SemiBold,
  Roboto Slab Regular/Medium) is a small `FontVariation` resource pinning the `wght` axis
  rather than a separate static font file.

## [0.4.0] - 2026-07-18

### Added
- Animated splash screen (`scenes/splash/`) as the new `run/main_scene`: "Made with Godot"
  and the studio logo each fade in, hold, and fade out, with a slow continuous scale-up
  (Unity-style camera dolly) running the whole time each is on screen. A click, key press, or
  controller button cancels whichever tween is running and skips straight to the main menu.
  `fade_duration`, `hold_duration`, and `scale_amount` are all `@export`ed on the `Splash`
  node for Inspector tuning.
- Main menu (`scenes/menu/`) with Play/Quit, using the existing Brassbound title art and
  background. Play hands off to whatever level `LevelManager` currently points at rather than
  a hardcoded level path, so it stays correct if levels are ever reordered.

### Changed
- Native engine boot splash image disabled (`boot_splash/show_image=false`) - the new in-scene
  splash sequence covers that beat instead.

## [0.3.0] - 2026-07-17

### Added
- Multi-level scene management: a new `LevelManager` autoload chains levels together - clearing
  all of a level's waves resets coins/wave counters and loads the next level instead of ending
  the run, with a "Level N - Get ready!" 3-2-1 countdown before each level's waves start
  (players can build during the countdown).
- Two levels: `Level 1` (the original layout) and `Level 2` (new tower spot layout, enemy path,
  ground color, and wave set). Each level can scale enemy toughness via a single tunable
  `enemy_health_multiplier`, no new enemy data needed.
- `Terrain` now exposes its ground material to the Inspector, so each level can have its own
  ground color.

### Changed
- `scenes/main/` renamed to `scenes/level/` (`main.gd` -> `level.gd`) since every level now
  shares the same template scene instead of there being one privileged "main" scene.

## [0.2.0] - 2026-07-17

### Added
- Tower info overlay: a HUD checkbox toggles, for every built tower, a ground-plane range
  gizmo and a floating label showing range/rate/damage (and splash radius, if set) - updates
  live on upgrade, broadcast via a new `"towers"` group.
- **Bomber Tower**: a second buyable tower type - big damage, slow fire rate, short range -
  firing a new lobbed `BombProjectile` that arcs upward and falls under gravity instead of
  homing in a straight line, exploding for area damage against every enemy (new `"enemies"`
  group) within its splash radius on impact. Has a placeholder hook for a future explosion
  particle effect.
- `TowerData` now carries `tower_scene`/`projectile_scene` per tower type (previously
  hardcoded to a single tower/projectile scene project-wide), and the shop supports multiple
  buyable tower types instead of one.

## [0.1.1] - 2026-07-17

### Changed
- Shop panel is now always visible, pinned to the bottom of the screen, instead of only
  appearing when an empty tower spot is selected.
- Shop buttons disable automatically when the player can't afford them, live-updated as
  coins change.
- Upgrade panel replaced with a single button (next level + cost) that pops up beside the
  selected tower in-world instead of living in a fixed HUD panel.
- Renamed the existing tower from "Basic Tower" to "Sniper Tower".

## [0.1.0] - 2026-07-17

### Added
- Two new enemy types alongside `Grunt`: `Runner` (smaller, faster, weaker) and `Troll`
  (bigger, slower, stronger), each its own scene + `EnemyStats` resource.
- Data-driven wave composition: `WaveManager.waves_config` is now an array of `WaveConfig`
  resources, each an ordered list of `WaveEnemyGroup` entries (enemy scene + stats + count),
  replacing the old flat per-wave enemy-count array. Lets a single wave mix enemy types in a
  specific spawn order instead of being locked to one type.
- 10 waves authored with a Grunt -> Runner -> Troll difficulty ramp.

## [0.0.1] - 2026-07-17

### Added
- Git repository with git-lfs tracking for binary asset types (textures, audio, models, fonts).
- First playable slice of the tower defense learning project:
  - Flat terrain, a bezier waypoint path (`Path3D`/`Curve3D`), and 3 fixed tower-building spots.
  - `Tower` (grey box + rotating rotor/muzzle) with a `TowerData`/`TowerStats` Resource-based
	upgrade system, capped at 4 levels.
  - `Enemy` (red sphere) that walks the path and deals damage to the `Structure` if it reaches
	the end unharmed.
  - `Structure`: the defended base, with HP and a `destroyed` signal.
  - Wave-based spawning (`WaveManager`, 10 waves) with a coin economy (`GameManager` autoload).
  - Win/lose conditions: survive all 10 waves for victory; `Structure` HP hitting 0 is a loss.
  - HUD: coins, current wave, structure HP, and live spawned/killed/reached-goal debug counters.
- Project identity: renamed to **Brassbound**, versioned `0.0.1`, custom icon, fixed
  1920x1080 windowed display mode.

### Fixed
- `Enemy.take_damage()` could be called twice on the same enemy in one physics frame
  (two towers landing hits before `queue_free()` removes the node), double-counting a
  single kill. Guarded with a `_resolved` flag.
- Victory condition now compares two independent counters (`enemies_spawned` vs.
  `enemies_killed + enemies_reached_goal`) instead of a single incrementally-updated
  tally, so a spawn/resolve mismatch is visible on the HUD instead of silently stalling
  the win condition.
