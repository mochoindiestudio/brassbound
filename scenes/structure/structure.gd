## The thing the player is actually defending. Every enemy that reaches the
## end of the path deals damage here instead of just vanishing - once
## health hits zero, the run is over. Placeholder art (a colored box) for
## now; none of this logic changes when you swap in real art later.
class_name Structure
extends Node3D

@export var max_health: float = 100.0

## How far above this structure's origin its health bar's "top center"
## sits, in world units - tuned to roughly match the model's height.
@export var health_bar_offset_y: float = 3.0

## Fired every time damage lands, so the HUD can update a health readout
## without polling every frame.
signal damaged(current_health: float, max_health: float)

## Fired once, the instant health reaches zero.
signal destroyed()

const HEALTH_BAR_SCENE: PackedScene = preload("res://scenes/ui/health_bar.tscn")

var _current_health: float
var _health_bar: HealthBar


func _ready() -> void:
	_current_health = max_health
	_health_bar = HEALTH_BAR_SCENE.instantiate()
	add_child(_health_bar)
	_health_bar.follow(self, Vector3(0.0, health_bar_offset_y, 0.0))
	_health_bar.set_health(_current_health, max_health)


func get_current_health() -> float:
	return _current_health


func take_damage(amount: float) -> void:
	if _current_health <= 0.0:
		return

	_current_health = maxf(_current_health - amount, 0.0)
	_health_bar.set_health(_current_health, max_health)
	damaged.emit(_current_health, max_health)

	if _current_health <= 0.0:
		destroyed.emit()
