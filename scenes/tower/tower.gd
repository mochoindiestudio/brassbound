## A placed, upgradeable tower. All tuning numbers come from `data` (a
## TowerData resource) instead of being hardcoded here - that's the
## Resource/ScriptableObject split: this script is *behavior*, the .tres
## file is *tuning*.
class_name Tower
extends Node3D

## Emitted every time this tower fires. Main connects to this once, right
## after the tower is built, to spawn the actual Projectile node - Tower
## has no idea where the "Projectiles" container even is, and doesn't need to.
signal shoot(from_position: Vector3, target: Node3D, damage: float)

## Fraction of total coins spent on this tower (build + every upgrade paid
## so far) refunded when it's sold - the standard TD "sell for less than
## you paid" rule, so spamming build/sell isn't free money.
const SELL_REFUND_RATIO: float = 0.75

@export var data: TowerData

var level: int = 0

var _cooldown: float = 0.0
var _enemies_in_range: Array[Node3D] = []

@onready var _rotor: Node3D = $Rotor
@onready var _muzzle: Marker3D = $Rotor/Muzzle
@onready var _range_shape: CollisionShape3D = $RangeArea/CollisionShape3D
@onready var _range_gizmo: MeshInstance3D = $RangeGizmo
@onready var _info_label: Label3D = $InfoLabel


func _ready() -> void:
	add_to_group("towers")
	# Sub-resources embedded in a .tscn are shared across every instance of
	# that scene unless duplicated - without this, resizing one tower's
	# range ring would resize every other tower's ring too.
	_range_gizmo.mesh = _range_gizmo.mesh.duplicate()
	_apply_stats()
	$RangeArea.area_entered.connect(_on_range_area_entered)
	$RangeArea.area_exited.connect(_on_range_area_exited)


func current_stats() -> TowerStats:
	return data.get_level(level)


func can_upgrade() -> bool:
	return level < data.max_level_index()


func upgrade() -> bool:
	if not can_upgrade():
		return false

	var next_stats: TowerStats = data.get_level(level + 1)
	if not GameManager.spend(next_stats.upgrade_cost):
		return false

	level += 1
	_apply_stats()
	return true


## Sum of build_cost plus every upgrade_cost paid to reach the current
## level - upgrade_cost on level N is what it cost to upgrade INTO N, so
## level 0 never contributes one (that's what build_cost already covers).
func total_invested() -> int:
	var total: int = data.get_level(0).build_cost
	for i in range(1, level + 1):
		total += data.get_level(i).upgrade_cost
	return total


func sell_value() -> int:
	return floori(total_invested() * SELL_REFUND_RATIO)


func _apply_stats() -> void:
	var stats: TowerStats = current_stats()
	var shape: SphereShape3D = _range_shape.shape
	shape.radius = stats.attack_range

	var ring: TorusMesh = _range_gizmo.mesh
	ring.inner_radius = stats.attack_range - 0.05
	ring.outer_radius = stats.attack_range + 0.05

	var text := "Range: %.1f\nRate: %.1f/s\nDmg: %.0f" % [stats.attack_range, stats.fire_rate, stats.damage]
	if stats.splash_radius > 0.0:
		text += "\nSplash: %.1f" % stats.splash_radius
	_info_label.text = text


func _physics_process(delta: float) -> void:
	_cooldown -= delta

	# Drop any target that died or otherwise left the tree since last frame -
	# `is_instance_valid` is how GDScript checks a freed node reference
	# without crashing on it.
	_enemies_in_range = _enemies_in_range.filter(func(e): return is_instance_valid(e))

	if _enemies_in_range.is_empty():
		return

	var target: Node3D = _enemies_in_range[0]
	_face_target(target)

	if _cooldown <= 0.0:
		var stats: TowerStats = current_stats()
		shoot.emit(_muzzle.global_position, target, stats.damage)
		_cooldown = 1.0 / stats.fire_rate


func _face_target(target: Node3D) -> void:
	# Only rotate around the vertical axis (yaw) so the turret doesn't tip
	# up/down toward enemies - look_at would tilt it on other axes too if we
	# pointed it straight at target.global_position without flattening the Y.
	var look_pos := Vector3(target.global_position.x, _rotor.global_position.y, target.global_position.z)
	if look_pos.distance_to(_rotor.global_position) > 0.001:
		_rotor.look_at(look_pos, Vector3.UP)


func _on_range_area_entered(area: Area3D) -> void:
	var enemy := area.get_parent()
	if enemy is Enemy and not _enemies_in_range.has(enemy):
		_enemies_in_range.append(enemy)


func _on_range_area_exited(area: Area3D) -> void:
	var enemy := area.get_parent()
	_enemies_in_range.erase(enemy)
