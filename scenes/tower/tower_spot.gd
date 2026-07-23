## A fixed, pre-placed pad the player can build one tower on.
## Lives as an Area3D purely so Main's click raycast can hit its
## CollisionShape3D - it doesn't need physics response either.
class_name TowerSpot
extends Area3D

## Emitted after a tower is successfully built here, so Main can wire up
## that tower's `shoot` signal without TowerSpot needing to know anything
## about projectiles, the Projectiles container, or Main itself.
signal tower_built(tower: Tower)

var current_tower: Tower = null

## Where a built tower's origin is placed, so it sits on top of the pad
## mesh instead of intersecting it. Height is authored in the editor to
## match the pad model, not computed - keeps this independent of mesh internals.
@onready var _mount_point: Marker3D = $MountPoint


func _ready() -> void:
	add_to_group("tower_spots")


func is_occupied() -> bool:
	return current_tower != null


func build_tower(data: TowerData) -> bool:
	if is_occupied():
		return false

	if not GameManager.spend(data.get_level(0).build_cost):
		return false

	var tower: Tower = data.tower_scene.instantiate()
	# Assign data BEFORE add_child: add_child triggers the tower's _ready()
	# immediately, and _ready() needs `data` to already be set to size the
	# range shape correctly.
	tower.data = data
	add_child(tower)
	tower.position.y = _mount_point.position.y

	current_tower = tower
	tower_built.emit(tower)
	return true


func sell_tower() -> void:
	if not is_occupied():
		return

	GameManager.add_coins(current_tower.sell_value())
	current_tower.queue_free()
	current_tower = null
