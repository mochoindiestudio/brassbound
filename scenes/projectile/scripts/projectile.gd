## A single shot fired from a tower, in a straight line only - true to real
## ballistics, it can't change course once it leaves the muzzle. Instead of
## homing on a specific target (which looked absurd at low speeds, visibly
## curving to chase a moving enemy), it travels the direction it was aimed
## at launch and relies on `HitArea` to tell it what it ran into: an enemy's
## hurtbox deals damage, anything else (the ground) just destroys it as a miss.
class_name Projectile
extends Node3D

@export var speed: float = 20.0
@export var damage: float = 10.0

var _direction: Vector3 = Vector3.ZERO
var _resolved: bool = false

@onready var _hit_area: Area3D = $HitArea


func _ready() -> void:
	_hit_area.area_entered.connect(_on_hit_area_area_entered)
	_hit_area.body_entered.connect(_on_hit_area_body_entered)


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


func _on_hit_area_area_entered(area: Area3D) -> void:
	if _resolved:
		return

	var enemy := area.get_parent()
	if enemy is Enemy:
		_resolved = true
		enemy.take_damage(damage)
		queue_free()


## Anything that isn't an enemy's hurtbox and still overlaps HitArea is the
## ground (a PhysicsBody, unlike Enemy's Area3D hurtbox) - just a miss.
func _on_hit_area_body_entered(_body: Node3D) -> void:
	if _resolved:
		return

	_resolved = true
	queue_free()
