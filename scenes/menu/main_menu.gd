## Landing screen after the splash sequence. Play drops into whichever level
## LevelManager currently points at (index 0 on a fresh boot), Credits shows
## the credits screen, and Quit exits.
extends Control

const CREDITS_SCENE: PackedScene = preload("res://scenes/menu/credits.tscn")

@onready var _play_button: Button = $CenterContainer/VBox/PlayButton
@onready var _credits_button: Button = $CenterContainer/VBox/CreditsButton
@onready var _quit_button: Button = $CenterContainer/VBox/QuitButton


func _ready() -> void:
	_play_button.pressed.connect(_on_play_pressed)
	_credits_button.pressed.connect(_on_credits_pressed)
	_quit_button.pressed.connect(_on_quit_pressed)


func _on_play_pressed() -> void:
	get_tree().change_scene_to_packed(LevelManager.current_level_data().level_scene)


func _on_credits_pressed() -> void:
	get_tree().change_scene_to_packed(CREDITS_SCENE)


func _on_quit_pressed() -> void:
	get_tree().quit()
