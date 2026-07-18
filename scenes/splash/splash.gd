## Plays a short "Made with Godot" + studio logo sequence before handing off
## to the main menu. A click, key press, or controller button cancels
## whichever fade is running and jumps straight to the menu - the intro is
## nice to see once, not something to sit through on every playtest launch.
extends Control

const MAIN_MENU_SCENE: PackedScene = preload("res://scenes/menu/main_menu.tscn")

@export var fade_duration: float = 0.4
@export var scale_amount: float = 0.4
@export var hold_duration: float = 1.2

@onready var _godot_logo: TextureRect = $GodotLogo
@onready var _studio_logo: TextureRect = $StudioLogo

var _current_tween: Tween = null
var _current_scale_tween: Tween = null
var _transitioned: bool = false


func _ready() -> void:
	_play_sequence()


func _unhandled_input(event: InputEvent) -> void:
	if _transitioned:
		return
	if _is_skip_event(event):
		get_viewport().set_input_as_handled()
		_go_to_main_menu()


func _is_skip_event(event: InputEvent) -> bool:
	if event is InputEventMouseButton and event.pressed:
		return true
	if event is InputEventKey and event.pressed:
		return true
	if event is InputEventJoypadButton and event.pressed:
		return true
	return false


func _play_sequence() -> void:
	await _show_logo(_godot_logo)
	if _transitioned:
		return
	await _show_logo(_studio_logo)
	if _transitioned:
		return
	_go_to_main_menu()


## Fades `logo` in, holds, fades it out, while a second tween runs a slow
## continuous scale-up (the "dolly") across that same total duration. Two
## separate tweens rather than one, since Tween only runs same-object steps
## in parallel with awkward set_parallel() toggling - independent tweens on
## different properties don't need to fight over that.
## If `_go_to_main_menu` kills `_current_tween` mid-fade, `finished` never
## fires and this simply stays suspended - harmless, since the whole scene
## is about to be freed anyway.
func _show_logo(logo: TextureRect) -> void:
	var total_duration: float = fade_duration * 2.0 + hold_duration

	_current_scale_tween = create_tween()
	_current_scale_tween.tween_property(logo, "scale", Vector2.ONE * (1.0 + scale_amount), total_duration)

	_current_tween = create_tween()
	_current_tween.tween_property(logo, "modulate:a", 1.0, fade_duration)
	_current_tween.tween_interval(hold_duration)
	_current_tween.tween_property(logo, "modulate:a", 0.0, fade_duration)
	await _current_tween.finished


func _go_to_main_menu() -> void:
	if _transitioned:
		return
	_transitioned = true
	if _current_tween != null and _current_tween.is_valid():
		_current_tween.kill()
	if _current_scale_tween != null and _current_scale_tween.is_valid():
		_current_scale_tween.kill()
	_godot_logo.modulate.a = 0.0
	_studio_logo.modulate.a = 0.0
	get_tree().change_scene_to_packed(MAIN_MENU_SCENE)
