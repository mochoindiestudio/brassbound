## Owns all on-screen UI: coin/wave readouts, the always-visible bottom Shop
## panel, and the Upgrade popup that appears beside a selected built tower.
##
## HUD never reaches back into the 3D scene directly - it only emits
## signals and lets Main decide what to do about them. This keeps UI code
## reusable and testable independent of whatever's happening in the level.
extends CanvasLayer

signal build_requested(data: TowerData)
signal upgrade_requested()
signal sell_requested()

## Every tower type currently buyable from the shop - one TowerButton per
## entry (see _populate_shop).
@export var available_towers: Array[TowerData] = []

const TOWER_BUTTON_SCENE: PackedScene = preload("res://scenes/ui/tower_button.tscn")
const MAIN_MENU_SCENE: PackedScene = preload("res://scenes/menu/main_menu.tscn")
const CREDITS_SCENE: PackedScene = preload("res://scenes/menu/credits.tscn")

@onready var _coins_label: Label = $Margin/VBox/TopBar/Coins/CoinsLabel
@onready var _wave_label: Label = $Margin/VBox/TopBar/Wave/WaveLabel
@onready var _structure_label: Label = $Margin/VBox/TopBar/Structure/StructureLabel
@onready var _spawned_label: Label = $Margin/VBox/TopBar/Spawned/SpawnedLabel
@onready var _killed_label: Label = $Margin/VBox/TopBar/Killed/KilledLabel
@onready var _shop_buttons: HBoxContainer = $ShopPanel/ShopButtons
@onready var _upgrade_panel: HBoxContainer = $UpgradePanel
@onready var _upgrade_button: Button = $UpgradePanel/UpgradeButton
@onready var _sell_button: Button = $UpgradePanel/SellButton
@onready var _end_panel: PanelContainer = $EndPanel
@onready var _end_label: Label = $EndPanel/CenterContainer/VBox/EndLabel
@onready var _end_primary_button: Button = $EndPanel/CenterContainer/VBox/ButtonRow/PrimaryButton
@onready var _end_secondary_button: Button = $EndPanel/CenterContainer/VBox/ButtonRow/SecondaryButton
@onready var _level_intro_panel: PanelContainer = $LevelIntroPanel
@onready var _level_intro_label: Label = $LevelIntroPanel/CenterContainer/VBox/LevelIntroLabel
@onready var _level_intro_countdown_label: Label = $LevelIntroPanel/CenterContainer/VBox/LevelIntroCountdownLabel
@onready var _cog: TextureRect = $TopBarBackground/Cog

const COG_ROTATION_SPEED_DEGREES: float = 60.0

## The tower the upgrade popup is currently showing, so its affordability
## can be re-checked live if coins change while it's open. Null when hidden.
var _upgrade_tower: Tower = null

## What the End Panel's two buttons do - set alongside the message and
## button labels in _show_end_screen, invoked from the connections made
## once in _ready.
var _end_primary_action: Callable = Callable()
var _end_secondary_action: Callable = Callable()


func _ready() -> void:
	GameManager.coins_changed.connect(_on_coins_changed)
	GameManager.wave_started.connect(_on_wave_started)
	GameManager.game_over.connect(_on_game_over)
	GameManager.victory.connect(_on_victory)
	GameManager.enemy_counts_changed.connect(_on_enemy_counts_changed)
	_coins_label.text = "%d" % GameManager.coins
	_wave_label.text = "%d" % GameManager.current_wave
	_on_enemy_counts_changed(GameManager.enemies_spawned, GameManager.enemies_killed, GameManager.enemies_reached_goal)
	_upgrade_button.pressed.connect(func(): upgrade_requested.emit())
	_sell_button.pressed.connect(func(): sell_requested.emit())
	_end_primary_button.pressed.connect(func(): _end_primary_action.call())
	_end_secondary_button.pressed.connect(func(): _end_secondary_action.call())
	_end_panel.visible = false
	_level_intro_panel.visible = false
	hide_panels()
	_populate_shop()


func _process(delta: float) -> void:
	_cog.rotation_degrees += COG_ROTATION_SPEED_DEGREES * delta


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


## Shows "Level N - Get ready!" with a 3-2-1 countdown, one second per
## tick. Callers `await` this directly - a function containing awaits can
## itself be awaited by its caller, same coroutine pattern WaveManager
## already uses for its inter-wave delays.
func show_level_intro(level_number: int) -> void:
	_level_intro_label.text = "Level %d - Get ready!" % level_number
	_level_intro_panel.visible = true
	for count in [3, 2, 1]:
		_level_intro_countdown_label.text = str(count)
		await get_tree().create_timer(1.0).timeout
	_level_intro_panel.visible = false


## Shop is always visible now - this just makes sure the upgrade popup
## from a previously-selected tower isn't left hanging around.
func show_shop() -> void:
	hide_panels()


## `screen_pos` is where (in viewport pixels) to center the popup - Main
## computes it via Camera3D.unproject_position() so HUD never needs to know
## about the 3D scene or camera itself.
func show_upgrade(tower: Tower, screen_pos: Vector2) -> void:
	_upgrade_tower = tower
	_upgrade_panel.visible = true
	_refresh_upgrade_button()
	_refresh_sell_button()
	_upgrade_panel.position = screen_pos - _upgrade_panel.size * 0.5


func _refresh_upgrade_button() -> void:
	if _upgrade_tower == null or not _upgrade_tower.can_upgrade():
		_upgrade_button.text = "Level 4/4\n(max)"
		_upgrade_button.disabled = true
		return

	var next_stats: TowerStats = _upgrade_tower.data.get_level(_upgrade_tower.level + 1)
	_upgrade_button.text = "Level %d/4\n%d coins" % [_upgrade_tower.level + 2, next_stats.upgrade_cost]
	_upgrade_button.disabled = not GameManager.can_afford(next_stats.upgrade_cost)


func _refresh_sell_button() -> void:
	if _upgrade_tower == null:
		return
	_sell_button.text = "Sell\n%d coins" % _upgrade_tower.sell_value()


func hide_panels() -> void:
	_upgrade_panel.visible = false
	_upgrade_tower = null


func update_structure_health(current_health: float, max_health: float) -> void:
	_structure_label.text = "%d/%d" % [current_health, max_health]


func _on_coins_changed(new_total: int) -> void:
	_coins_label.text = "%d" % new_total
	if _upgrade_panel.visible:
		_refresh_upgrade_button()


func _on_wave_started(wave_number: int) -> void:
	_wave_label.text = "%d" % wave_number


func _on_enemy_counts_changed(spawned: int, killed: int, _reached_goal: int) -> void:
	_spawned_label.text = "%d" % spawned
	_killed_label.text = "%d" % killed


func _on_game_over() -> void:
	_show_end_screen("Defeat!", "Try again", _restart_level, "Back to Main Menu", _go_to_main_menu)


func _on_victory() -> void:
	_show_end_screen("VICTORY!", "Credits", _go_to_credits, "Back to Main Menu", _go_to_main_menu)


func _show_end_screen(message: String, primary_text: String, primary_action: Callable, secondary_text: String, secondary_action: Callable) -> void:
	hide_panels()
	_end_label.text = message
	_end_primary_button.text = primary_text
	_end_primary_action = primary_action
	_end_secondary_button.text = secondary_text
	_end_secondary_action = secondary_action
	_end_panel.visible = true


func _restart_level() -> void:
	GameManager.reset_for_new_level()
	get_tree().change_scene_to_packed(LevelManager.current_level_data().level_scene)


func _go_to_credits() -> void:
	get_tree().change_scene_to_packed(CREDITS_SCENE)


func _go_to_main_menu() -> void:
	get_tree().change_scene_to_packed(MAIN_MENU_SCENE)
