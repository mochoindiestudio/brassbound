## Per-level tuning: which scene holds this level's spatial layout, and how
## much tougher its enemies are compared to their base EnemyStats. Same
## ScriptableObject-style pattern as TowerData/EnemyStats - authored as a
## .tres file, edited entirely in the Inspector.
class_name LevelData
extends Resource

@export var level_scene: PackedScene

## Multiplies Enemy.setup()'s starting health - one tunable number per
## level instead of needing a whole new set of hand-authored EnemyStats
## resources just to make enemies feel tougher.
@export var enemy_health_multiplier: float = 1.0
