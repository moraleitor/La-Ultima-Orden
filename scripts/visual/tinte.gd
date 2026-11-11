class_name Tinte
extends Node3D
## Pinta de un color todas las mallas de este modelo (sirve para reusar un modelo).

@export var color := Color.WHITE


func _ready() -> void:
	for m in find_children("*", "MeshInstance3D", true, false):
		var mi := m as MeshInstance3D
		for i in mi.mesh.get_surface_count():
			var base := mi.mesh.surface_get_material(i)
			var mat: StandardMaterial3D = base.duplicate() if base is StandardMaterial3D else StandardMaterial3D.new()
			mat.albedo_color = mat.albedo_color * color
			mi.set_surface_override_material(i, mat)
