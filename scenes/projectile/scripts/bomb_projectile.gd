## A lobbed projectile: launches on a ballistic arc toward a fixed landing
## point (computed once at launch, unlike Projectile's continuous homing -
## a thrown bomb doesn't course-correct in flight) and explodes for area
## damage against every enemy in "enemies" within splash_radius on impact.
class_name BombProjectile
extends Node3D

@export var damage: float = 10.0
@export var splash_radius: float = 3.0
@export var gravity: float = 20.0
@export var arc_height: float = 3.0

## Min/max angular speed (rad/s) rolled per axis at launch - unlike Projectile,
## a lobbed bomb has no target to face, so it just tumbles for visual flair.
@export var tumble_speed_range: Vector2 = Vector2(2.0, 6.0)

var _velocity: Vector3 = Vector3.ZERO
var _landing_y: float = 0.0
var _angular_velocity: Vector3 = Vector3.ZERO


## Solves for the launch velocity that arcs from `from` to `to`, peaking
## roughly `arc_height` above the higher of the two points, then starts the
## fall. Called once by Main right after instancing.
func launch(from: Vector3, to: Vector3) -> void:
	global_position = from
	_landing_y = to.y

	var horizontal: Vector3 = to - from
	horizontal.y = 0.0
	var height_diff: float = to.y - from.y

	var time_up: float = sqrt(2.0 * arc_height / gravity)
	var time_down: float = sqrt(2.0 * max(arc_height - height_diff, 0.01) / gravity)
	var flight_time: float = time_up + time_down

	_velocity = horizontal / flight_time
	_velocity.y = gravity * time_up

	_angular_velocity = Vector3(
		randf_range(tumble_speed_range.x, tumble_speed_range.y) * (-1.0 if randf() < 0.5 else 1.0),
		randf_range(tumble_speed_range.x, tumble_speed_range.y) * (-1.0 if randf() < 0.5 else 1.0),
		randf_range(tumble_speed_range.x, tumble_speed_range.y) * (-1.0 if randf() < 0.5 else 1.0)
	)


func _physics_process(delta: float) -> void:
	_velocity.y -= gravity * delta
	global_position += _velocity * delta
	rotation += _angular_velocity * delta

	if global_position.y <= _landing_y:
		global_position.y = _landing_y
		_explode()


func _explode() -> void:
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(enemy) and enemy.global_position.distance_to(global_position) <= splash_radius:
			enemy.take_damage(damage)
	_spawn_explosion_vfx()
	queue_free()


## Hook for a future explosion particle burst - intentionally a no-op for
## now. When implemented, spawn the effect parented to the scene root (or a
## dedicated VFX container, mirroring Main's "Projectiles" container) rather
## than as a child of this node, since queue_free() above removes this node
## immediately and would cut the effect off before it finishes.
func _spawn_explosion_vfx() -> void:
	pass
