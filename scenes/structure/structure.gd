## The thing the player is actually defending. Every enemy that reaches the
## end of the path deals damage here instead of just vanishing - once
## health hits zero, the run is over. Placeholder art (a colored box) for
## now; none of this logic changes when you swap in real art later.
class_name Structure
extends Node3D

@export var max_health: float = 100.0

## Fired every time damage lands, so the HUD can update a health readout
## without polling every frame.
signal damaged(current_health: float, max_health: float)

## Fired once, the instant health reaches zero.
signal destroyed()

var _current_health: float


func _ready() -> void:
	_current_health = max_health


func get_current_health() -> float:
	return _current_health


func take_damage(amount: float) -> void:
	if _current_health <= 0.0:
		return

	_current_health = maxf(_current_health - amount, 0.0)
	damaged.emit(_current_health, max_health)

	if _current_health <= 0.0:
		destroyed.emit()
