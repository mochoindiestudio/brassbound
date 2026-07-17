## A single shot fired from a tower toward a specific enemy.
## Instead of relying on physics collision (which can miss fast, thin
## projectiles between frames), this just tracks its target directly and
## deals damage once it's close enough - simpler to reason about, and
## there's no gameplay reason to need "real" physics for a bullet here.
class_name Projectile
extends Node3D

@export var speed: float = 20.0
@export var damage: float = 10.0
@export var hit_distance: float = 0.3

## The enemy this shot is chasing. If the enemy dies before the shot lands,
## this becomes invalid and the projectile just removes itself next frame.
var target: Node3D


func _physics_process(delta: float) -> void:
	if not is_instance_valid(target):
		queue_free()
		return

	var to_target: Vector3 = target.global_position - global_position
	var distance: float = to_target.length()

	if distance <= hit_distance:
		if target.has_method("take_damage"):
			target.take_damage(damage)
		queue_free()
		return

	global_position += to_target.normalized() * speed * delta
