## A single tower level's tuning numbers.
## Equivalent to a Unity ScriptableObject: this is authored as a .tres file
## and edited entirely in the Inspector - no code changes needed to retune
## range, damage, or cost.
class_name TowerStats
extends Resource

## Shown in the shop button and the upgrade panel.
@export var display_name: String = "Tower"

## Radius (in meters) of the detection sphere. Drives RangeArea's shape.
## Named `attack_range` (not `range`) because `range()` is a built-in
## GDScript function - shadowing it works but Godot warns about it.
@export var attack_range: float = 6.0

## Shots per second.
@export var fire_rate: float = 1.0

## Damage dealt per shot.
@export var damage: float = 10.0

## Radius of splash/area damage around the hit target. 0 = single-target
## only (no splash) - not used by any tower yet, but the info overlay shows
## it once a tower's projectile actually deals area damage.
@export var splash_radius: float = 0.0

## Coin cost to place a brand-new tower (only meaningful on level 0).
@export var build_cost: int = 50

## Coin cost to upgrade INTO this level from the previous one.
## Ignored on level 0 - that's what build_cost is for.
@export var upgrade_cost: int = 40
