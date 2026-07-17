## Groups all 4 upgrade levels for one tower "type" into a single asset -
## the ScriptableObject-style data source Tower.gd reads from.
##
## Each level is its own TowerStats slot rather than one array, so the
## Inspector shows 4 clearly labeled resource pickers instead of a growable
## list - and it sidesteps typed-array-of-Resource serialization entirely,
## which is a bit finicky to hand-author. If you add more tower types later,
## duplicate this resource and tune the 4 slots differently per type.
class_name TowerData
extends Resource

@export var tower_name: String = "Basic Tower"

@export var level_1: TowerStats
@export var level_2: TowerStats
@export var level_3: TowerStats
@export var level_4: TowerStats


## Levels are 0-indexed here (0 = level_1) so Tower.gd can use `level`
## directly as both an array-style index and an upgrade counter.
func get_level(index: int) -> TowerStats:
	match index:
		0: return level_1
		1: return level_2
		2: return level_3
		_: return level_4


## Capped at 4 levels (index 0-3), per the design brief.
func max_level_index() -> int:
	return 3
