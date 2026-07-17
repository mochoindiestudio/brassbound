class_name Terrain
extends StaticBody3D

@export var terrain_material: Material

func _ready() -> void:
	if terrain_material != null:
		$Mesh.set_surface_override_material(0, terrain_material)
