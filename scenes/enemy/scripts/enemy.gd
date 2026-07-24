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

## Pool of interchangeable movement animations - one is picked at random and
## looped for this enemy's lifetime. A single-entry array pins a specific
## enemy to its own dedicated animation (e.g. Tanker's walk); multiple
## entries let several enemy types share the same generic clips (e.g.
## Grunt's 3 walk variants) at random, so adding a new enemy type or a new
## shared clip never needs a code change - just populate this array per scene.
## Each entry is one of the animation-only FBX scenes under
## scenes/enemy/animations/ (Mixamo-rigged, so any clip retargets onto any
## enemy model that shares its bone names).
@export var move_animations: Array[PackedScene] = []

const HEALTH_BAR_SCENE: PackedScene = preload("res://scenes/ui/prefabs/health_bar.tscn")

var _path: Path3D
var _distance_traveled: float = 0.0
var _health: float
var _max_health: float
var _resolved: bool = false
var _health_bar: HealthBar
var _animation_player: AnimationPlayer


func _ready() -> void:
	add_to_group("enemies")
	_health_bar = HEALTH_BAR_SCENE.instantiate()
	add_child(_health_bar)
	_health_bar.follow(self, Vector3(0.0, health_bar_offset_y, 0.0))
	_animation_player = get_node_or_null("AnimationPlayer")
	_play_random_move_animation()


func _play_random_move_animation() -> void:
	if move_animations.is_empty() or _animation_player == null:
		return

	# The animation-only FBX scenes each import as a normal PackedScene
	# holding their own AnimationPlayer - instantiate briefly just to lift
	# out its AnimationLibrary resource (which lives on independently of the
	# node), then discard the instance.
	var source_scene: PackedScene = move_animations[randi() % move_animations.size()]
	var source_root: Node = source_scene.instantiate()
	var source_player: AnimationPlayer = _find_animation_player(source_root)
	var library: AnimationLibrary = source_player.get_animation_library("") if source_player else null
	source_root.queue_free()

	if library == null:
		return
	var animation_names: PackedStringArray = library.get_animation_list()
	if animation_names.is_empty():
		return

	# Added under the default/global library name ("") so the animation can
	# be looked up and played by its bare name below, with no per-enemy
	# knowledge of which specific clip it ended up with.
	_animation_player.add_animation_library("", library)
	var animation_name: StringName = animation_names[0]
	_animation_player.get_animation(animation_name).loop_mode = Animation.LOOP_LINEAR
	_animation_player.play(animation_name)


func _find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node
	for child in node.get_children():
		var found: AnimationPlayer = _find_animation_player(child)
		if found:
			return found
	return null


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
	var new_position: Vector3 = _path.to_global(_path.curve.sample_baked(_distance_traveled))
	var direction: Vector3 = new_position - global_position
	global_position = new_position

	# look_at aims local -Z at the target, same convention Projectile uses -
	# the model's own authored rotation is what makes its "nose" agree with
	# that axis. Skipped on a near-zero step (e.g. the first frame after
	# setup()) since look_at can't derive a direction from a zero vector.
	if direction.length_squared() > 0.0001:
		look_at(global_position + direction, Vector3.UP)


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
