## One wave's full spawn sequence: an ordered list of WaveEnemyGroup steps,
## spawned in array order. Lets a single wave mix enemy types instead of
## being locked to one type per wave.
class_name WaveConfig
extends Resource

@export var groups: Array[WaveEnemyGroup] = []
