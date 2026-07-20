## The Credits screen reached from the HUD's Victory end panel.
extends Control

const MAIN_MENU_SCENE: PackedScene = preload("res://scenes/menu/main_menu.tscn")

@onready var _back_button: Button = $CenterContainer/DarkPanel/Margin/VBox/BackButton


func _ready() -> void:
	_back_button.pressed.connect(_on_back_pressed)


func _on_back_pressed() -> void:
	get_tree().change_scene_to_packed(MAIN_MENU_SCENE)
