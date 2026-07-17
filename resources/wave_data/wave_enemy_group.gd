## One ordered spawn step within a wave: "spawn `count` of this enemy type."
## WaveConfig strings several of these together to build a wave's full
## spawn sequence.
class_name WaveEnemyGroup
extends Resource

@export var enemy_scene: PackedScene
@export var enemy_stats: EnemyStats
@export var count: int = 1
