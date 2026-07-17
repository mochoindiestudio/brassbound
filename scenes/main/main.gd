## Top-level orchestrator: wires up input (clicking a tower spot), the
## HUD's signals, and each TowerSpot's `tower_built` signal to actually
## spawn projectiles. Nothing about *how* a tower decides to shoot lives
## here - Main only reacts to signals other nodes emit, and never reaches
## into their internals directly.
extends Node3D

const PROJECTILE_SCENE: PackedScene = preload("res://scenes/projectile/projectile.tscn")

@onready var _camera: Camera3D = $Camera3D
@onready var _hud: CanvasLayer = $HUD
@onready var _tower_spots: Node3D = $TowerSpots
@onready var _projectiles: Node3D = $Projectiles
@onready var _structure: Structure = $Structure

var _selected_spot: TowerSpot = null


func _ready() -> void:
	for spot in _tower_spots.get_children():
		spot.tower_built.connect(_on_tower_built)

	_hud.build_requested.connect(_on_build_requested)
	_hud.upgrade_requested.connect(_on_upgrade_requested)

	_structure.damaged.connect(_on_structure_damaged)
	_hud.update_structure_health(_structure.get_current_health(), _structure.max_health)


func _unhandled_input(event: InputEvent) -> void:
	if not GameManager.is_game_active:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_handle_click(event.position)


func _on_structure_damaged(current_health: float, max_health: float) -> void:
	_hud.update_structure_health(current_health, max_health)


func _handle_click(screen_position: Vector2) -> void:
	# The classic "click on a 3D object" pattern: cast a ray from the camera
	# through the clicked pixel and ask the physics world what it hits.
	var from: Vector3 = _camera.project_ray_origin(screen_position)
	var to: Vector3 = from + _camera.project_ray_normal(screen_position) * 1000.0

	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = 2 # tower spots live on layer 2 - see tower_spot.tscn
	query.collide_with_areas = true
	query.collide_with_bodies = false

	var result := get_world_3d().direct_space_state.intersect_ray(query)
	if result.is_empty():
		_deselect()
		return

	var spot := result.collider as TowerSpot
	if spot == null:
		_deselect()
		return

	_select_spot(spot)


func _select_spot(spot: TowerSpot) -> void:
	_selected_spot = spot
	if spot.is_occupied():
		_show_upgrade_for(spot.current_tower)
	else:
		_hud.show_shop()


func _deselect() -> void:
	_selected_spot = null
	_hud.hide_panels()


## Offsets the tower's world position (+X "to the side", +Y up to roughly
## head height) before projecting to screen space, so the popup reads as
## sitting beside the tower rather than on top of it.
func _show_upgrade_for(tower: Tower) -> void:
	var popup_anchor: Vector3 = tower.global_position + Vector3(1.5, 1.2, 0)
	var screen_pos: Vector2 = _camera.unproject_position(popup_anchor)
	_hud.show_upgrade(tower, screen_pos)


func _on_build_requested(data: TowerData) -> void:
	if _selected_spot == null or _selected_spot.is_occupied():
		return
	if _selected_spot.build_tower(data):
		_show_upgrade_for(_selected_spot.current_tower)


func _on_upgrade_requested() -> void:
	if _selected_spot == null or not _selected_spot.is_occupied():
		return
	if _selected_spot.current_tower.upgrade():
		_show_upgrade_for(_selected_spot.current_tower)


func _on_tower_built(tower: Tower) -> void:
	tower.shoot.connect(_on_tower_shoot)


func _on_tower_shoot(from_position: Vector3, target: Node3D, damage: float) -> void:
	var projectile: Projectile = PROJECTILE_SCENE.instantiate()
	_projectiles.add_child(projectile)
	projectile.global_position = from_position
	projectile.damage = damage
	projectile.target = target
