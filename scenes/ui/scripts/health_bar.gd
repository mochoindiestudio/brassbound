## Reusable world-space health bar: tracks a 3D node's screen position and
## shows its current health as a colored fill layered over a framed container.
## Any script for something that can take damage (Enemy, Structure, ...)
## instances this as a child of its own node - that way queue_free() on the
## owner frees the bar too, with no separate manager needed - then drives it
## through follow() once and set_health() whenever health changes.
##
## Background and Fill are separate nodes on purpose: Background is the
## steampunk frame art (healthbar.png) sized to the full control, and Fill is
## a plain ColorRect inset to sit inside the frame's dark slot (see
## FILL_INSET/FILL_SIZE) - swap Fill for a tintable texture later without
## touching Background.
class_name HealthBar
extends Control

## Screen-space gap, in pixels, between the tracked point and the bar's
## bottom edge - keeps the bar from overlapping the subject's model.
const GAP_PX: float = 16.0

const BAR_SIZE: Vector2 = Vector2(72.0, 13.78)

## Top-left position and size of the fill strip, in local control coordinates -
## keeps the fill inside the dark slot baked into the healthbar.png frame art
## rather than overlapping its bronze/gear border.
const FILL_INSET: Vector2 = Vector2(11.0, 5.5)
const FILL_SIZE: Vector2 = Vector2(50.0, 4.0)

@onready var _fill: ColorRect = $Fill

var _target: Node3D
var _world_offset: Vector3 = Vector3.ZERO
var _gradient: Gradient = _build_gradient()


func _ready() -> void:
	# Detaches from the owner's 3D transform entirely - position is set
	# every frame in screen space via camera.unproject_position(), so this
	# must not also inherit whatever transform its Node3D parent has.
	top_level = true
	custom_minimum_size = BAR_SIZE
	size = BAR_SIZE
	visible = false


## Green at full health, yellow at half, red at empty - matches the request
## that shorter bars trend redder rather than a flat two-color split.
func _build_gradient() -> Gradient:
	var gradient := Gradient.new()
	# Setting offsets/colors directly (rather than add_point, which inserts
	# and re-sorts by offset) avoids fighting with index shifts - point 1
	# from add_point would land at whatever index sorting puts it, not
	# necessarily the index you just passed to set_color.
	gradient.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
	gradient.colors = PackedColorArray([Color(0.85, 0.1, 0.1), Color(0.95, 0.85, 0.1), Color(0.2, 0.8, 0.2)])
	return gradient


## Called once by the owning node right after instancing. world_offset is
## how far above `target`'s origin, in world units, counts as its "top
## center" (roughly the subject's height) - the fixed 16px screen gap is
## added on top of that point, not baked into the offset itself.
func follow(target: Node3D, world_offset: Vector3) -> void:
	_target = target
	_world_offset = world_offset


func set_health(current: float, max_health: float) -> void:
	var ratio: float = clampf(current / max_health, 0.0, 1.0) if max_health > 0.0 else 0.0
	_fill.size.x = FILL_SIZE.x * ratio
	_fill.color = _gradient.sample(ratio)


func _process(_delta: float) -> void:
	if _target == null or not is_instance_valid(_target):
		visible = false
		return

	var camera: Camera3D = get_viewport().get_camera_3d()
	if camera == null:
		visible = false
		return

	var world_pos: Vector3 = _target.global_position + _world_offset
	if camera.is_position_behind(world_pos):
		visible = false
		return

	visible = true
	var screen_pos: Vector2 = camera.unproject_position(world_pos)
	position = screen_pos - Vector2(size.x * 0.5, size.y + GAP_PX)
