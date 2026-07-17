# Changelog

All notable changes to this project are documented here. Format loosely follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

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
