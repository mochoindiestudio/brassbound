# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

"Brassbound" — a 3D steampunk tower defense game built in Godot 4.7 (GDScript), using Forward+ rendering
and Jolt Physics. This is a learning project; current version tracked in `project.godot`
(`config/version`) and `CHANGELOG.md`.

There is no build/test/lint tooling in this repo — it's a Godot project, opened and run via the Godot
editor (or the `mcp__godot__*` MCP tools: `run_project`, `stop_project`, `get_debug_output`,
`launch_editor`). Per project convention, Claude does not launch/test the game itself unless explicitly
asked — the user tests changes in-editor.

## Architecture

**Autoloads (global singletons, Godot's answer to Unity persistent singletons):**
- `GameManager` (`autoload/game_manager.gd`) — generic run state: coins, current wave, win/loss signals
  (`game_over`, `victory`), enemy spawn/kill/reached-goal counters. `is_game_active` is the single flag
  everything checks to stop acting once a run is decided.
- `LevelManager` (`autoload/level_manager.tscn` + `.gd`) — which level is current/next
  (`@export var levels: Array[LevelData]`), and advances scenes. Peer to GameManager, not owned by it:
  GameManager resets its own state via `reset_for_new_level()`, called by LevelManager before swapping scenes.

**Data-driven tuning (ScriptableObject-equivalent pattern):** Godot `Resource` subclasses authored as
`.tres` files and edited entirely in the Inspector, no code changes needed to retune numbers:
- `TowerData` (`resources/tower_data/`) — one per tower type, holds 5 `TowerStats` slots (levels 1-5,
  0-indexed in code) plus which scenes to instantiate for the tower and its projectile.
- `TowerStats` — per-level numbers: range, fire rate, damage, splash radius, build/upgrade cost.
- `EnemyStats` (`resources/enemy_data/`), `WaveConfig`/`WaveEnemyGroup` (`resources/wave_data/`),
  `LevelData` (`resources/level_data/`) — same pattern for enemies, wave composition, and per-level config.
- Continuous-attack towers (Laser, Tesla Coil) have no `fire_rate` — damage is applied per-frame instead
  of on a cooldown (see `LaserTower` below).

**Signal-driven flow, no direct cross-system references:**
`Level` (`scenes/level/level.gd`) is the top-level per-level orchestrator. It never contains gameplay
logic itself — it only wires signals between nodes that don't know about each other:
- `TowerSpot.tower_built` → Level connects the new `Tower.shoot` signal → Level spawns the actual
  projectile (Tower doesn't know about the Projectiles container or projectile scenes).
- `HUD` signals (`build_requested`, `upgrade_requested`, `sell_requested`) → Level calls the matching
  method on the currently-selected `TowerSpot`.
- `Structure.damaged` → Level updates the HUD health readout.
- `WaveManager` (`scenes/level/wave_manager.gd`) owns wave spawning and the win/lose check. Victory is
  checked as `enemies_killed + enemies_reached_goal >= enemies_spawned` once all waves have finished
  spawning (two independent monotonic totals, both visible on the HUD, rather than one running tally).
  `Structure.destroyed` → `GameManager.trigger_game_over()`; clearing the last wave → advances
  `LevelManager` or triggers victory.

**Tower targeting/combat:** `Tower` (`scenes/tower/scripts/tower.gd`) tracks enemies inside its `RangeArea`
via `area_entered`/`area_exited`, always targets index 0 of `_enemies_in_range`, and fires on a cooldown
(`shoot` signal, consumed by Level). `LaserTower` (`scenes/tower/scripts/tower_laser.gd`) extends `Tower`
and fully overrides `_physics_process` for continuous beam damage-per-frame instead of discrete shots —
subclass, don't branch inside the base class, when a tower's attack model fundamentally differs.

**Enemies:** `Enemy` (`scenes/enemy/scripts/enemy.gd`) is a plain `Node3D` (no physics body — movement is fully
scripted along a `Path3D` via `curve.sample_baked()`), spawned and configured by `WaveManager.setup()`.
Health is scaled by the current level's `enemy_health_multiplier` at spawn time, not hardcoded per-level
enemy data. `take_damage`/goal-reached both guard against being called twice in the same physics frame
via a `_resolved` flag (two towers can hit the same enemy in one frame before `queue_free()` takes effect).

## Conventions

- **Folder layout**: each `scenes/<feature>/` folder that has non-script assets (models, materials,
  textures) splits into `models/` (one subfolder per model, bundling its mesh + textures + material
  together), `prefabs/` (`.tscn` files), and `scripts/` (`.gd` files) — see `scenes/tower/` and
  `scenes/projectile/`, and `scenes/enemy/`. Feature folders that are just a script + a couple scenes
  (`structure/`, `menu/`, etc.) stay flat until they grow enough assets to warrant the split — don't
  create empty `models/` folders pre-emptively.
- SRP/composition over inheritance where reasonable; signals over direct method calls between systems
  that shouldn't know about each other; `@export` over public fields for Inspector-tunable values; no
  magic numbers — pull tuning into `TowerStats`/`EnemyStats`/etc. resources.
- Every exported field, signal, and non-obvious method has a doc comment (`##`) explaining *why*, not
  just what — keep that up when adding to existing scripts.
- Version bumps: patch = bugfix/small change, minor = new feature/larger change, major = only on
  explicit request. Always update `CHANGELOG.md` and `project.godot`'s `config/version` together.
- **"push up" pipeline**: when the user says the exact phrase "push up", it means the full ceremony,
  not a plain commit+push:
  1. Commit the relevant work (ask first if it's unclear which pending changes belong).
  2. Bump `config/version` in `project.godot` per the semver rule above.
  3. Add a `CHANGELOG.md` entry for the new version, matching the existing format.
  4. Push to the remote.
