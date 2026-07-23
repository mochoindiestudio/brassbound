## One buildable tower option shown in the shop panel.
## A thin wrapper around the SquareButton2 base (see square_button_2.tscn) -
## it just fills in the turret icon and price from a TowerData resource and
## turns a click into a typed signal, so HUD doesn't need to know anything
## about button internals. This is the reusable-UI-widget pattern: instance
## this scene once per option instead of hand-building N buttons inline.
class_name TowerButton
extends Button

signal tower_selected(data: TowerData)

@export var tower_data: TowerData

@onready var _icon: TextureRect = $Icon
@onready var _price_label: Label = $PriceLabel


func _ready() -> void:
	pressed.connect(_on_pressed)
	GameManager.coins_changed.connect(_on_coins_changed)
	_refresh_text()
	_refresh_affordability()


func _refresh_text() -> void:
	if tower_data == null:
		return
	_icon.texture = tower_data.icon
	_price_label.text = "%d" % tower_data.get_level(0).build_cost


func _refresh_affordability() -> void:
	if tower_data == null:
		return
	var affordable: bool = GameManager.can_afford(tower_data.get_level(0).build_cost)
	disabled = not affordable
	# Icon/PriceLabel sit on top of the Button and aren't covered by its
	# built-in disabled styling, so dim the whole button ourselves.
	modulate = Color.WHITE if affordable else Color(0.45, 0.45, 0.45)


func _on_coins_changed(_new_total: int) -> void:
	_refresh_affordability()


func _on_pressed() -> void:
	tower_selected.emit(tower_data)
