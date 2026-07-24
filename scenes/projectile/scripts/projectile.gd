## A single shot fired from a tower, in a straight line only - true to real
## ballistics, it can't change course once it leaves the muzzle. Instead of
## homing on a specific target (which looked absurd at low speeds, visibly
## curving to chase a moving enemy), it travels the direction it was aimed
## at launch and either comes close enough to any enemy along that line to
## hit it, or reaches the ground and is discarded as a miss.
class_name Projectile
extends Node3D

@export var speed: float = 20.0
@export var damage: float = 10.0
@export var hit_distance: float = 0.3

var _direction: Vector3 = Vector3.ZERO


## Aims once at wherever `target_position` was at the moment of firing -
## called once by Main right after instancing, mirroring BombProjectile's
## own `launch()`.
func launch(from: Vector3, target_position: Vector3) -> void:
	global_position = from
	_direction = (target_position - from).normalized()
	# look_at aims local -Z at the initial direction - fixed for the whole
	# flight now, since there's no more per-frame homing to keep it updated.
	look_at(global_position + _direction, Vector3.UP)


func _physics_process(delta: float) -> void:
	global_position += _direction * speed * delta

	# The terrain is a flat plane at y = 0 - reaching it without hitting
	# anything first means this shot missed.
	if global_position.y <= 0.0:
		queue_free()
		return

	for enemy in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(enemy) and enemy.global_position.distance_to(global_position) <= hit_distance:
			enemy.take_damage(damage)
			queue_free()
			return
