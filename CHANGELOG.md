# Changelog

All notable changes to this project are documented here. Format loosely follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

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
