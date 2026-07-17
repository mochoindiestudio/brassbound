## Owns level sequencing - which level is current, what's next. Peer to
## GameManager, not owned by it: GameManager owns generic run state (coins,
## wave counters), LevelManager owns which level that state belongs to.
## Registered as an Autoload the same way GameManager is, but wrapped in a
## scene (level_manager.tscn) rather than a bare script, since `levels`
## needs to be an author-time-editable array set via the Inspector - same
## reasoning WaveManager.waves_config/HUD.available_towers already follow.
extends Node

@export var levels: Array[LevelData] = []

var current_level_index: int = 0


func current_level_data() -> LevelData:
	return levels[current_level_index]


func current_level_number() -> int:
	return current_level_index + 1


func has_next_level() -> bool:
	return current_level_index + 1 < levels.size()


func advance_to_next_level() -> void:
	current_level_index += 1
	GameManager.reset_for_new_level()
	get_tree().change_scene_to_packed(current_level_data().level_scene)
