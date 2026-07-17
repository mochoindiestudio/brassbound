## Tuning numbers for one enemy type - the ScriptableObject equivalent for
## enemies, same pattern as TowerStats.
class_name EnemyStats
extends Resource

@export var display_name: String = "Grunt"
@export var max_health: float = 30.0
@export var move_speed: float = 2.5

## Coins awarded to the player when this enemy dies.
@export var coin_reward: int = 5

## Damage dealt to the Structure if this enemy walks the path unharmed.
@export var structure_damage: float = 10.0
