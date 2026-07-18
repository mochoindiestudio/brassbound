## Landing screen after the splash sequence. Play drops into whichever level
## LevelManager currently points at (index 0 on a fresh boot), Quit exits.
extends Control

@onready var _play_button: Button = $CenterContainer/VBox/PlayButton
@onready var _quit_button: Button = $CenterContainer/VBox/QuitButton


func _ready() -> void:
	_play_button.pressed.connect(_on_play_pressed)
	_quit_button.pressed.connect(_on_quit_pressed)


func _on_play_pressed() -> void:
	get_tree().change_scene_to_packed(LevelManager.current_level_data().level_scene)


func _on_quit_pressed() -> void:
	get_tree().quit()
