## Owns all on-screen UI: coin/wave readouts, plus the two contextual panels
## that appear depending on what the player just clicked (an empty spot vs.
## an already-built tower).
##
## HUD never reaches back into the 3D scene directly - it only emits
## signals and lets Main decide what to do about them. This keeps UI code
## reusable and testable independent of whatever's happening in the level.
extends CanvasLayer

signal build_requested(data: TowerData)
signal upgrade_requested()

## The one tower type this scaffold ships with. Add more TowerButton
## instances in `_populate_shop` (looping over an Array[TowerData]) once you
## have more than one type to offer.
@export var basic_tower_data: TowerData

const TOWER_BUTTON_SCENE: PackedScene = preload("res://scenes/ui/tower_button.tscn")

@onready var _coins_label: Label = $Margin/VBox/TopBar/CoinsLabel
@onready var _wave_label: Label = $Margin/VBox/TopBar/WaveLabel
@onready var _structure_label: Label = $Margin/VBox/TopBar/StructureLabel
@onready var _debug_counts_label: Label = $Margin/VBox/TopBar/DebugCountsLabel
@onready var _shop_panel: PanelContainer = $Margin/VBox/ShopPanel
@onready var _shop_buttons: HBoxContainer = $Margin/VBox/ShopPanel/ShopButtons
@onready var _upgrade_panel: PanelContainer = $Margin/VBox/UpgradePanel
@onready var _upgrade_label: Label = $Margin/VBox/UpgradePanel/VBox/UpgradeLabel
@onready var _upgrade_button: Button = $Margin/VBox/UpgradePanel/VBox/UpgradeButton
@onready var _end_panel: PanelContainer = $EndPanel
@onready var _end_label: Label = $EndPanel/CenterContainer/EndLabel


func _ready() -> void:
	GameManager.coins_changed.connect(_on_coins_changed)
	GameManager.wave_started.connect(_on_wave_started)
	GameManager.game_over.connect(_on_game_over)
	GameManager.victory.connect(_on_victory)
	GameManager.enemy_counts_changed.connect(_on_enemy_counts_changed)
	_coins_label.text = "Coins: %d" % GameManager.coins
	_wave_label.text = "Wave: %d" % GameManager.current_wave
	_on_enemy_counts_changed(GameManager.enemies_spawned, GameManager.enemies_killed, GameManager.enemies_reached_goal)
	_upgrade_button.pressed.connect(func(): upgrade_requested.emit())
	_end_panel.visible = false
	hide_panels()
	_populate_shop()


func _populate_shop() -> void:
	for child in _shop_buttons.get_children():
		child.queue_free()

	if basic_tower_data == null:
		return

	var button: TowerButton = TOWER_BUTTON_SCENE.instantiate()
	button.tower_data = basic_tower_data
	button.tower_selected.connect(_on_tower_button_selected)
	_shop_buttons.add_child(button)


func _on_tower_button_selected(data: TowerData) -> void:
	build_requested.emit(data)


func show_shop() -> void:
	_shop_panel.visible = true
	_upgrade_panel.visible = false


func show_upgrade(tower: Tower) -> void:
	_shop_panel.visible = false
	_upgrade_panel.visible = true

	if tower.can_upgrade():
		var next_stats: TowerStats = tower.data.get_level(tower.level + 1)
		_upgrade_label.text = "Level %d/4" % (tower.level + 1)
		_upgrade_button.text = "Upgrade (%d coins)" % next_stats.upgrade_cost
		_upgrade_button.disabled = false
	else:
		_upgrade_label.text = "Level 4/4 (max)"
		_upgrade_button.text = "Maxed"
		_upgrade_button.disabled = true


func hide_panels() -> void:
	_shop_panel.visible = false
	_upgrade_panel.visible = false


func update_structure_health(current_health: float, max_health: float) -> void:
	_structure_label.text = "Structure: %d/%d" % [current_health, max_health]


func _on_coins_changed(new_total: int) -> void:
	_coins_label.text = "Coins: %d" % new_total


func _on_wave_started(wave_number: int) -> void:
	_wave_label.text = "Wave: %d" % wave_number


## Temporary debug readout - see if spawned/killed+reached ever diverge.
## Safe to delete once the win condition is confirmed solid.
func _on_enemy_counts_changed(spawned: int, killed: int, reached_goal: int) -> void:
	_debug_counts_label.text = "Spawned: %d  Killed: %d  Reached: %d  Resolved: %d" % [spawned, killed, reached_goal, killed + reached_goal]


func _on_game_over() -> void:
	_show_end_screen("GAME OVER")


func _on_victory() -> void:
	_show_end_screen("VICTORY!")


func _show_end_screen(message: String) -> void:
	hide_panels()
	_end_label.text = message
	_end_panel.visible = true
