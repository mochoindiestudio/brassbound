## A single enemy walking the fixed waypoint path.
## Root is a plain Node3D, not a CharacterBody3D - movement here is fully
## scripted along a curve with no physics response needed, so a physics
## body would just be extra weight for nothing.
class_name Enemy
extends Node3D

## Fired the instant health hits zero, right before this node frees itself.
## WaveManager listens to award coins and track how many enemies are left.
signal died(coin_reward: int)

## Fired when this enemy reaches the end of the path (walked in unharmed).
## Carries how much damage it deals to the Structure on arrival.
signal reached_goal(damage_to_structure: float)

@export var stats: EnemyStats

## How far above this enemy's origin its health bar's "top center" sits, in
## world units - tuned per enemy scene to roughly match its model height.
@export var health_bar_offset_y: float = 0.5

const HEALTH_BAR_SCENE: PackedScene = preload("res://scenes/ui/health_bar.tscn")

var _path: Path3D
var _distance_traveled: float = 0.0
var _health: float
var _max_health: float
var _resolved: bool = false
var _health_bar: HealthBar


func _ready() -> void:
	add_to_group("enemies")
	_health_bar = HEALTH_BAR_SCENE.instantiate()
	add_child(_health_bar)
	_health_bar.follow(self, Vector3(0.0, health_bar_offset_y, 0.0))


## Called by WaveManager right after instancing, since `stats` needs to be
## assigned before this can compute starting health/position. Health is
## scaled by the current level's enemy_health_multiplier so later levels
## can feel tougher without needing their own hand-tuned EnemyStats.
func setup(path: Path3D) -> void:
	_path = path
	_max_health = stats.max_health * LevelManager.current_level_data().enemy_health_multiplier
	_health = _max_health
	_health_bar.set_health(_health, _max_health)
	global_position = _path.to_global(_path.curve.sample_baked(0.0))


func _physics_process(delta: float) -> void:
	if _path == null:
		return

	_distance_traveled += stats.move_speed * delta
	var curve_length: float = _path.curve.get_baked_length()

	if _distance_traveled >= curve_length:
		if not _resolved:
			_resolved = true
			reached_goal.emit(stats.structure_damage)
			queue_free()
		return

	# sample_baked reads a position along the curve at a given distance, so
	# we never need to manually lerp between individual waypoints - Godot
	# does that math for us based on however the curve is currently shaped.
	global_position = _path.to_global(_path.curve.sample_baked(_distance_traveled))


func take_damage(amount: float) -> void:
	# Guards against a rare but real race: two towers can each fire at this
	# enemy in the same physics frame. queue_free() doesn't remove the node
	# until the frame ends, so without this check a second, already-in-flight
	# projectile could call take_damage again on an enemy that's already
	# dying, double-counting one kill as two.
	if _resolved:
		return

	_health -= amount
	_health_bar.set_health(_health, _max_health)
	if _health <= 0.0:
		_resolved = true
		died.emit(stats.coin_reward)
		queue_free()
