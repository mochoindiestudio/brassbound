## One buildable tower option shown in the shop panel.
## A thin wrapper around a plain Button - it just translates a TowerData
## resource into button text and turns a click into a typed signal, so HUD
## doesn't need to know anything about button internals. This is the
## reusable-UI-widget pattern: instance this scene once per option instead
## of hand-building N buttons inline.
class_name TowerButton
extends Button

signal tower_selected(data: TowerData)

@export var tower_data: TowerData


func _ready() -> void:
	pressed.connect(_on_pressed)
	_refresh_text()


func _refresh_text() -> void:
	if tower_data == null:
		return
	var cost: int = tower_data.get_level(0).build_cost
	text = "%s\n%d coins" % [tower_data.tower_name, cost]


func _on_pressed() -> void:
	tower_selected.emit(tower_data)
