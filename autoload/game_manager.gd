## Global game state: coins and the current wave number.
## Registered as an Autoload (Project Settings > Autoload) - Godot's answer
## to a Unity persistent singleton. Any script can reach this by the name
## "GameManager" without holding a direct reference, since autoloads are
## added to the scene tree root automatically before any other scene loads.
extends Node

## Emitted whenever the coin total changes, so the HUD can just listen
## instead of polling every frame.
signal coins_changed(new_total: int)

## Emitted when a new wave starts. Argument is the 1-based wave number.
signal wave_started(wave_number: int)

## Emitted once a wave's enemies have all been spawned and are all dead.
signal wave_completed(wave_number: int)

## Emitted once, the moment the protected structure is destroyed.
signal game_over()

## Emitted once, the moment the player survives the last configured wave.
signal victory()

## False as soon as either game_over or victory fires. WaveManager and Main
## both check this to stop spawning enemies / accepting input once the run
## is decided, instead of each needing their own separate "is it over yet"
## bookkeeping.
var is_game_active: bool = true

## A GDScript property setter: assigning to `coins` anywhere (`coins -= 10`,
## `coins = 100`) automatically runs this and emits the signal - callers
## never need to remember to emit it themselves.
var coins: int = 100:
	set(value):
		coins = value
		coins_changed.emit(coins)

var current_wave: int = 0

## Debug/diagnostic counters for the current run - shown on the HUD so it's
## obvious at a glance whether every spawned enemy actually got accounted
## for (killed or reached the goal) by the time a wave is declared "done".
## WaveManager is the only thing that calls these.
signal enemy_counts_changed(spawned: int, killed: int, reached_goal: int)

var enemies_spawned: int = 0
var enemies_killed: int = 0
var enemies_reached_goal: int = 0


func record_enemy_spawned() -> void:
	enemies_spawned += 1
	enemy_counts_changed.emit(enemies_spawned, enemies_killed, enemies_reached_goal)


func record_enemy_killed() -> void:
	enemies_killed += 1
	enemy_counts_changed.emit(enemies_spawned, enemies_killed, enemies_reached_goal)


func record_enemy_reached_goal() -> void:
	enemies_reached_goal += 1
	enemy_counts_changed.emit(enemies_spawned, enemies_killed, enemies_reached_goal)


func can_afford(amount: int) -> bool:
	return coins >= amount


## Attempts to spend `amount` coins. Returns false (and spends nothing) if
## the player can't afford it - always check the return value before
## treating a purchase as successful.
func spend(amount: int) -> bool:
	if not can_afford(amount):
		return false
	coins -= amount
	return true


func add_coins(amount: int) -> void:
	coins += amount


func start_wave(wave_number: int) -> void:
	current_wave = wave_number
	wave_started.emit(wave_number)


func complete_wave(wave_number: int) -> void:
	wave_completed.emit(wave_number)


func trigger_game_over() -> void:
	if not is_game_active:
		return
	is_game_active = false
	game_over.emit()


func trigger_victory() -> void:
	if not is_game_active:
		return
	is_game_active = false
	victory.emit()
