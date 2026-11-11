extends Node3D
## El jugador en primera persona: solo se ven los brazos. La cámara mira la mesa en diagonal.

const TEXTURA_BRAZOS := preload("res://assets/modelos/fps arms/new_diff.png")

@onready var brazos: Node = $Camara/Brazos


func _ready() -> void:
	_pintar_brazos()
	var ap := brazos.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if ap == null or ap.get_animation_list().is_empty():
		return
	var nombre := ap.get_animation_list()[0]
	ap.get_animation(nombre).loop_mode = Animation.LOOP_LINEAR
	ap.play(nombre)


func _pintar_brazos() -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = TEXTURA_BRAZOS
	mat.roughness = 1.0
	for m in brazos.find_children("*", "MeshInstance3D", true, false):
		(m as MeshInstance3D).material_override = mat
