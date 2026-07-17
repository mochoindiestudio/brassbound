## Spawns enemies in waves along the path and reports wave progress to
## GameManager. This is a plain Node (not an autoload) because it only
## makes sense in the context of one level - unlike coins, wave state here
## is local to whichever Main scene happens to be running.
##
## Also owns the actual win/lose check: surviving all of waves_config
## (10 waves, by default) triggers victory; the Structure being destroyed
## along the way triggers game over. Both funnel through GameManager so
## HUD (and anything else) can react without needing to know WaveManager
## or Structure exist.
##
## Victory is checked against GameManager's spawned/killed/reached_goal
## totals (spawned == killed + reached_goal) rather than a single
## incrementally-updated counter - two independent monotonic totals are
## harder to let drift out of sync than one running tally, and they're
## visible on the HUD so any mismatch is obvious immediately instead of
## silently stalling the win condition.
class_name WaveManager
extends Node

## Each entry is one wave's ordered enemy-group sequence (see WaveConfig /
## WaveEnemyGroup in resources/wave_data/) - wave 1 spawns waves_config[0]'s
## groups in order, wave 2 spawns waves_config[1]'s, etc. Surviving every
## wave in this list is the win condition, so its length IS "how many waves
## to reach victory". Populated via main.tscn, not a script default, since
## it's hand-tuned composite data (same reasoning as sniper_tower.tres).
@export var waves_config: Array[WaveConfig] = []
@export var seconds_between_spawns: float = 1.0
@export var seconds_between_waves: float = 4.0

@onready var _path: Path3D = get_node("../EnemyPath")
@onready var _enemies_container: Node3D = get_node("../Enemies")
@onready var _structure: Structure = get_node("../Structure")

var _all_waves_spawned: bool = false


func _ready() -> void:
	_structure.destroyed.connect(_on_structure_destroyed)
	_run_waves()


## `await`ing a timer's `timeout` signal is GDScript's answer to
## coroutines/async-await: execution pauses right here without blocking the
## rest of the game (physics, rendering, input all keep running), and this
## function simply resumes from this point once the timer fires.
func _run_waves() -> void:
	for i in range(waves_config.size()):
		if not GameManager.is_game_active:
			return

		var wave_number := i + 1
		GameManager.start_wave(wave_number)

		for group in waves_config[i].groups:
			for j in range(group.count):
				if not GameManager.is_game_active:
					return
				_spawn_enemy(group.enemy_scene, group.enemy_stats)
				await get_tree().create_timer(seconds_between_spawns).timeout

		if i == waves_config.size() - 1:
			_all_waves_spawned = true

		await get_tree().create_timer(seconds_between_waves).timeout


func _spawn_enemy(scene: PackedScene, stats: EnemyStats) -> void:
	var enemy: Enemy = scene.instantiate()
	enemy.stats = stats
	_enemies_container.add_child(enemy)
	enemy.setup(_path)
	enemy.died.connect(_on_enemy_died)
	enemy.reached_goal.connect(_on_enemy_reached_goal)
	GameManager.record_enemy_spawned()


func _on_enemy_died(coin_reward: int) -> void:
	GameManager.add_coins(coin_reward)
	GameManager.record_enemy_killed()
	_check_wave_complete()


func _on_enemy_reached_goal(damage_to_structure: float) -> void:
	_structure.take_damage(damage_to_structure)
	GameManager.record_enemy_reached_goal()
	_check_wave_complete()


func _on_structure_destroyed() -> void:
	GameManager.trigger_game_over()


func _check_wave_complete() -> void:
	if not GameManager.is_game_active:
		return

	var resolved := GameManager.enemies_killed + GameManager.enemies_reached_goal
	if _all_waves_spawned and resolved >= GameManager.enemies_spawned:
		GameManager.complete_wave(GameManager.current_wave)
		GameManager.trigger_victory()
