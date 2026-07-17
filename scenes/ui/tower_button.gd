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
	GameManager.coins_changed.connect(_on_coins_changed)
	_refresh_text()
	_refresh_affordability()


func _refresh_text() -> void:
	if tower_data == null:
		return
	var cost: int = tower_data.get_level(0).build_cost
	text = "%s\n%d coins" % [tower_data.tower_name, cost]


func _refresh_affordability() -> void:
	if tower_data == null:
		return
	disabled = not GameManager.can_afford(tower_data.get_level(0).build_cost)


func _on_coins_changed(_new_total: int) -> void:
	_refresh_affordability()


func _on_pressed() -> void:
	tower_selected.emit(tower_data)
