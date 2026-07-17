## Owns all on-screen UI: coin/wave readouts, the always-visible bottom Shop
## panel, and the Upgrade popup that appears beside a selected built tower.
##
## HUD never reaches back into the 3D scene directly - it only emits
## signals and lets Main decide what to do about them. This keeps UI code
## reusable and testable independent of whatever's happening in the level.
extends CanvasLayer

signal build_requested(data: TowerData)
signal upgrade_requested()

## Every tower type currently buyable from the shop - one TowerButton per
## entry (see _populate_shop).
@export var available_towers: Array[TowerData] = []

const TOWER_BUTTON_SCENE: PackedScene = preload("res://scenes/ui/tower_button.tscn")

@onready var _coins_label: Label = $Margin/VBox/TopBar/CoinsLabel
@onready var _wave_label: Label = $Margin/VBox/TopBar/WaveLabel
@onready var _structure_label: Label = $Margin/VBox/TopBar/StructureLabel
@onready var _debug_counts_label: Label = $Margin/VBox/TopBar/DebugCountsLabel
@onready var _tower_info_check: CheckBox = $Margin/VBox/TopBar/ShowTowerInfoCheck
@onready var _shop_buttons: HBoxContainer = $ShopPanel/ShopButtons
@onready var _upgrade_button: Button = $UpgradeButton
@onready var _end_panel: PanelContainer = $EndPanel
@onready var _end_label: Label = $EndPanel/CenterContainer/EndLabel

## The tower the upgrade popup is currently showing, so its affordability
## can be re-checked live if coins change while it's open. Null when hidden.
var _upgrade_tower: Tower = null


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
	_tower_info_check.button_pressed = GameManager.show_tower_info
	_tower_info_check.toggled.connect(func(enabled: bool): GameManager.show_tower_info = enabled)
	_end_panel.visible = false
	hide_panels()
	_populate_shop()


func _populate_shop() -> void:
	for child in _shop_buttons.get_children():
		child.queue_free()

	for tower_data in available_towers:
		var button: TowerButton = TOWER_BUTTON_SCENE.instantiate()
		button.tower_data = tower_data
		button.tower_selected.connect(_on_tower_button_selected)
		_shop_buttons.add_child(button)


func _on_tower_button_selected(data: TowerData) -> void:
	build_requested.emit(data)


## Shop is always visible now - this just makes sure the upgrade popup
## from a previously-selected tower isn't left hanging around.
func show_shop() -> void:
	hide_panels()


## `screen_pos` is where (in viewport pixels) to center the popup - Main
## computes it via Camera3D.unproject_position() so HUD never needs to know
## about the 3D scene or camera itself.
func show_upgrade(tower: Tower, screen_pos: Vector2) -> void:
	_upgrade_tower = tower
	_upgrade_button.visible = true
	_refresh_upgrade_button()
	_upgrade_button.position = screen_pos - _upgrade_button.size * 0.5


func _refresh_upgrade_button() -> void:
	if _upgrade_tower == null or not _upgrade_tower.can_upgrade():
		_upgrade_button.text = "Level 4/4\n(max)"
		_upgrade_button.disabled = true
		return

	var next_stats: TowerStats = _upgrade_tower.data.get_level(_upgrade_tower.level + 1)
	_upgrade_button.text = "Level %d/4\n%d coins" % [_upgrade_tower.level + 2, next_stats.upgrade_cost]
	_upgrade_button.disabled = not GameManager.can_afford(next_stats.upgrade_cost)


func hide_panels() -> void:
	_upgrade_button.visible = false
	_upgrade_tower = null


func update_structure_health(current_health: float, max_health: float) -> void:
	_structure_label.text = "Structure: %d/%d" % [current_health, max_health]


func _on_coins_changed(new_total: int) -> void:
	_coins_label.text = "Coins: %d" % new_total
	if _upgrade_button.visible:
		_refresh_upgrade_button()


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
