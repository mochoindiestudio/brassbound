## Continuous-beam variant of Tower: instead of firing discrete shots on a
## cooldown, damage is applied every physics frame (so `damage` is really a
## damage-per-second figure) for as long as a target stays in range, and a
## placeholder beam mesh is stretched from the muzzle to the target to
## visualize the ray. Fully replaces Tower's _physics_process rather than
## extending it - the cooldown/shoot-signal model doesn't apply here.
class_name LaserTower
extends Tower

@onready var _beam: MeshInstance3D = $Beam


func _physics_process(delta: float) -> void:
	_enemies_in_range = _enemies_in_range.filter(func(e): return is_instance_valid(e))

	if _enemies_in_range.is_empty():
		_beam.visible = false
		return

	var target: Node3D = _enemies_in_range[0]
	_face_target(target, delta)
	target.take_damage(current_stats().damage * delta)
	_update_beam(target)


func _update_beam(target: Node3D) -> void:
	var from: Vector3 = _muzzle.global_position
	var to: Vector3 = target.global_position
	var beam_length: float = from.distance_to(to)

	if beam_length <= 0.001:
		_beam.visible = false
		return

	_beam.visible = true
	_beam.global_position = from.lerp(to, 0.5)
	_beam.look_at(to, Vector3.UP)
	_beam.scale = Vector3(1.0, 1.0, beam_length)
