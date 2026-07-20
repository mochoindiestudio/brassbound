## The Credits screen reached from the main menu, the HUD's Victory end
## panel, and the in-game pause menu.
##
## Normally a full scene (Back goes to the main menu). When the pause menu
## opens it, HUD instances this scene as an overlay on top of the still-live
## level instead - see configure_as_overlay(). In that case Back must return
## to the paused game rather than blow the level away, so it emits `closed`
## for HUD to handle instead of navigating anywhere itself.
class_name Credits
extends Control

signal closed()

## main_menu.gd preloads credits.tscn, so preloading main_menu.tscn back
## here would form a compile-time cycle between the two scripts - Godot
## resolves that by silently handing back an incomplete resource instead
## of erroring, which made Back quietly do nothing. change_scene_to_file
## loads by path at call time instead, sidestepping the cycle entirely.
const MAIN_MENU_SCENE_PATH: String = "res://scenes/menu/main_menu.tscn"

@onready var _back_button: Button = $CenterContainer/DarkPanel/Margin/VBox/BackButton

var _return_to_caller: bool = false


func _ready() -> void:
	_back_button.pressed.connect(_on_back_pressed)


## Called by HUD right after instantiating this scene as a pause-menu
## overlay, so Back knows to hand control back instead of leaving the level.
func configure_as_overlay() -> void:
	_return_to_caller = true


func _on_back_pressed() -> void:
	if _return_to_caller:
		closed.emit()
	else:
		get_tree().change_scene_to_file(MAIN_MENU_SCENE_PATH)
