extends Node3D
## El jugador en primera persona frente a la mesa. Solo mueve la cabeza (mouse);
## el cuerpo no se mueve. Al hacer clic sobre algo de la mesa la mano derecha lo agarra.

const TEXTURA_BRAZOS := preload("res://assets/modelos/fps arms/new_diff.png")
const SENSIBILIDAD := 0.0025
const YAW_MAX := deg_to_rad(60.0)
const PITCH_MIN := deg_to_rad(-75.0)
const PITCH_MAX := deg_to_rad(25.0)
const ALCANCE := 4.0          # m del rayo del clic
const CURVA_DEDOS := 1.2      # rad que se cierra cada articulación
const EJE_CURVA := Vector3.RIGHT

@onready var camara: Camera3D = $Camara
@onready var brazos: Node3D = $Camara/Brazos

var _esqueleto: Skeleton3D
var _dedos: Array[int] = []
var _dedos_base: Array[Quaternion] = []
var _pos_brazos: Vector3
var _agarre := 0.0            # 0 mano abierta, 1 agarrando
var _tween: Tween


func _ready() -> void:
	_pintar_brazos()
	_pose_quieta()
	_pos_brazos = brazos.position
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotation.y = clampf(rotation.y - event.relative.x * SENSIBILIDAD, -YAW_MAX, YAW_MAX)
		camara.rotation.x = clampf(camara.rotation.x - event.relative.y * SENSIBILIDAD, PITCH_MIN, PITCH_MAX)
	elif event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event.is_action_pressed("seleccionar"):
		if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		else:
			_agarrar()
	elif event.is_action_released("seleccionar"):
		_soltar()


func _agarrar() -> void:
	var desde := camara.global_position
	var hasta := desde - camara.global_transform.basis.z * ALCANCE
	var q := PhysicsRayQueryParameters3D.create(desde, hasta)
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	if hit.is_empty():
		return
	# La mano se estira hacia lo que tocó y los dedos se cierran.
	var destino := camara.to_local(hit.position) - Vector3(0.15, -0.3, -0.55)
	_animar(1.0, _pos_brazos + destino * 0.3)


func _soltar() -> void:
	if _agarre > 0.0 or (_tween and _tween.is_running()):
		_animar(0.0, _pos_brazos)


func _animar(agarre: float, pos: Vector3) -> void:
	if _tween:
		_tween.kill()
	_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_tween.tween_method(_poner_agarre, _agarre, agarre, 0.18)
	_tween.tween_property(brazos, "position", pos, 0.18)


func _poner_agarre(v: float) -> void:
	_agarre = v
	for i in _dedos.size():
		var giro := Quaternion(EJE_CURVA, CURVA_DEDOS * v)
		_esqueleto.set_bone_pose_rotation(_dedos[i], _dedos_base[i] * giro)


func _pose_quieta() -> void:
	# Sin animación: se queda en la pose del primer cuadro.
	var ap := brazos.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if ap and not ap.get_animation_list().is_empty():
		ap.play(ap.get_animation_list()[0])
		ap.seek(0.0, true)
		ap.stop()
		ap.active = false
	_esqueleto = brazos.find_child("*", true, false) as Skeleton3D
	for n in brazos.find_children("*", "Skeleton3D", true, false):
		_esqueleto = n
	for i in _esqueleto.get_bone_count():
		var nombre := _esqueleto.get_bone_name(i)
		if nombre.ends_with(".R") and (nombre.begins_with("f_") or nombre.begins_with("thumb")) and not nombre.ends_with("_end"):
			_dedos.append(i)
			_dedos_base.append(_esqueleto.get_bone_pose_rotation(i))


func _pintar_brazos() -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = TEXTURA_BRAZOS
	mat.roughness = 1.0
	for m in brazos.find_children("*", "MeshInstance3D", true, false):
		(m as MeshInstance3D).material_override = mat
