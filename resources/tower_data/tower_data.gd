## Groups all 5 upgrade levels for one tower "type" into a single asset -
## the ScriptableObject-style data source Tower.gd reads from.
##
## Each level is its own TowerStats slot rather than one array, so the
## Inspector shows 5 clearly labeled resource pickers instead of a growable
## list - and it sidesteps typed-array-of-Resource serialization entirely,
## which is a bit finicky to hand-author. If you add more tower types later,
## duplicate this resource and tune the 5 slots differently per type.
class_name TowerData
extends Resource

@export var tower_name: String = "Basic Tower"
@export var icon: Texture2D

## Which scene TowerSpot instantiates when this tower type is built, and
## which projectile scene it fires - both tied to the tower's *type*, not
## its level, so they live here rather than on TowerStats.
@export var tower_scene: PackedScene
@export var projectile_scene: PackedScene

## Multiplier on Tower's base turret turn speed - 1.0 is the baseline speed,
## higher values turn faster, lower values slower. A per-type trait (not
## per-level) since it's about the physical turret, not its firepower.
@export var rotation_speed_multiplier: float = 1.0

@export var level_1: TowerStats
@export var level_2: TowerStats
@export var level_3: TowerStats
@export var level_4: TowerStats
@export var level_5: TowerStats


## Levels are 0-indexed here (0 = level_1) so Tower.gd can use `level`
## directly as both an array-style index and an upgrade counter.
func get_level(index: int) -> TowerStats:
	match index:
		0: return level_1
		1: return level_2
		2: return level_3
		3: return level_4
		_: return level_5


## Capped at 5 levels (index 0-4), per the design brief.
func max_level_index() -> int:
	return 4
