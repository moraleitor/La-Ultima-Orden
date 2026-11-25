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
var _mirada_forzada := false     # durante el screamer el jugador no controla la cabeza
var _tween_mirada: Tween
var _pitch_inicial := 0.0

# Variables relacionadas a la pose de corte (brazos, malla modelo y posiciones) para volver al agarre normal al soltar el clic.
var _reposo_brazos: Transform3D
var _clavicula := -1
var _mano := -1
var _malla_brazos: MeshInstance3D
var _malla_normal: Mesh
var _malla_corte: ArrayMesh
var _giro_antebrazo := Basis.IDENTITY
var _pose_clavicula: Transform3D
var _pose_mano: Transform3D
var _mango_en_mano: Transform3D
var _pose_corte_mano: Transform3D
var _en_corte := false

# Huesos y poses del brazo que sostiene el ingrediente.
var _clavicula_izq := -1
var _mano_izq := -1
var _antebrazo_izq := -1
var _clavicula_izq_base: Transform3D
var _mano_izq_base: Transform3D
var _codo_izq_base: Vector3
var _pose_apoyo_izq: Transform3D
var _pose_clavicula_apoyo: Transform3D
var _peso_apoyo_izq := 0.0
var _dedos_izq: Array[int] = []
var _dedos_izq_base: Array[Quaternion] = []
var _ejes_dedos_izq: Array[Vector3] = []
var _base_palma_izq := Basis.IDENTITY
var _palma_izq_calibrada := false


func _ready() -> void:
	# La tabla busca al jugador aquí para sincronizar la mano con el cuchillo.
	add_to_group("player")
	_pintar_brazos()
	_pose_quieta()
	_preparar_apoyo_izquierdo()
	_preparar_malla_corte()
	_reposo_brazos = brazos.transform
	_pos_brazos = brazos.position
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_pitch_inicial = camara.rotation.x
	Events.apagon_iniciado.connect(_mirar_screamer)
	Events.intento_iniciado.connect(_recuperar_mirada)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and not _mirada_forzada:
		rotation.y = clampf(rotation.y - event.relative.x * SENSIBILIDAD, -YAW_MAX, YAW_MAX)
		camara.rotation.x = clampf(camara.rotation.x - event.relative.y * SENSIBILIDAD, PITCH_MIN, PITCH_MAX)
	elif event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	# Durante el corte, la tabla se encarga del agarre y de soltarlo.
	elif event.is_action_pressed("seleccionar") and not _en_corte:
		if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		else:
			_agarrar()
	elif event.is_action_released("seleccionar") and not _en_corte:
		_soltar()


func _agarrar() -> void:
	var desde := camara.global_position
	var hasta := desde - camara.global_transform.basis.z * ALCANCE
	var q := PhysicsRayQueryParameters3D.create(desde, hasta)
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	if hit.is_empty():
		return

	# La mano se estira hacia lo que tocó y los dedos se cierran.
	var destino := (camara.to_local(hit.position) - Vector3(0.0, -0.26, -0.5)) * 0.2
	_animar(1.0, _pos_brazos + destino.limit_length(0.06))


func _soltar() -> void:
	if _agarre > 0.0 or (_tween and _tween.is_running()):
		_animar(0.0, _pos_brazos)


# Tabla entrega la transformación del mango, ya animado en el mundo.
func actualizar_agarre_corte(mango: Transform3D, centro_tabla: Vector3) -> void:
	if _mano < 0 or _clavicula < 0:
		return

	if not _en_corte:
		if _tween:
			_tween.kill()
		_en_corte = true
		_colocar_brazo_derecho(_pose_mano)
		_poner_agarre(1.0)

		# Usa una orientación hacia la tabla independiente de la mira actual.
		var mirada_tabla := Transform3D(Basis.IDENTITY, camara.global_position)
		mirada_tabla = mirada_tabla.looking_at(centro_tabla)
		brazos.top_level = true
		brazos.global_transform = mirada_tabla * _reposo_brazos
		_calibrar_mango_en_mano()
		_preparar_pose_antebrazo()
		if _malla_corte:
			_malla_brazos.mesh = _malla_corte

	# Pasa el mango al espacio del esqueleto para alinear el puño.
	var mango_local := _esqueleto.global_transform.affine_inverse() * mango
	mango_local.basis = mango_local.basis.orthonormalized()
	_pose_corte_mano = mango_local * _mango_en_mano.affine_inverse()
	_pose_corte_mano.basis = _pose_corte_mano.basis.scaled_local(
		_pose_mano.basis.get_scale()
	)
	_colocar_brazo_derecho(_pose_corte_mano, 1.0)


func _calibrar_mango_en_mano() -> void:
	var indice := _esqueleto.get_bone_global_pose(_esqueleto.find_bone("f_index.01.R")).origin
	var menique := _esqueleto.get_bone_global_pose(_esqueleto.find_bone("f_pinky.01.R")).origin
	var medio := _esqueleto.get_bone_global_pose(_esqueleto.find_bone("f_middle.01.R")).origin
	var falange := _esqueleto.get_bone_global_pose(_esqueleto.find_bone("f_middle.02.R")).origin
	var centro := medio.lerp(falange, 0.58)
	var eje_mango := (menique - indice).normalized()
	var arriba := (medio - centro).slide(eje_mango).normalized()
	var base_mango := Basis(eje_mango, arriba, eje_mango.cross(arriba))
	var mano_sin_escala := Transform3D(_pose_mano.basis.orthonormalized(), _pose_mano.origin)
	_mango_en_mano = mano_sin_escala.affine_inverse() * Transform3D(base_mango, centro)


func _preparar_malla_corte() -> void:
	if _esqueleto == null or _mano < 0:
		return

	var antebrazo := _esqueleto.find_bone("forearm.R")
	if antebrazo < 0:
		return

	for nodo in brazos.find_children("*", "MeshInstance3D", true, false):
		var visual := nodo as MeshInstance3D
		if visual.skin and visual.mesh and visual.mesh.get_surface_count() == 1:
			_malla_brazos = visual
			break

	if _malla_brazos == null:
		return

	_malla_normal = _malla_brazos.mesh
	var datos := _malla_normal.surface_get_arrays(0)
	var vertices: PackedVector3Array = datos[Mesh.ARRAY_VERTEX]
	var indices: PackedInt32Array = datos[Mesh.ARRAY_INDEX]
	var huesos: PackedInt32Array = datos[Mesh.ARRAY_BONES]
	var pesos: PackedFloat32Array = datos[Mesh.ARRAY_WEIGHTS]
	if vertices.is_empty() or indices.is_empty() or huesos.is_empty():
		return

	# Conserva la parte de la malla que sigue a la mano y al antebrazo derechos.
	var skin := _malla_brazos.skin
	var binds_visibles := PackedByteArray()
	binds_visibles.resize(skin.get_bind_count())
	for i in skin.get_bind_count():
		var hueso := skin.get_bind_bone(i)
		var nombre := skin.get_bind_name(i)
		if not nombre.is_empty():
			hueso = _esqueleto.find_bone(nombre)
		while hueso >= 0:
			if (
				hueso == antebrazo or hueso == _mano
				or hueso == _antebrazo_izq or hueso == _mano_izq
			):
				binds_visibles[i] = 1
				break
			hueso = _esqueleto.get_bone_parent(hueso)

	var pesos_por_vertice := int(float(huesos.size()) / vertices.size())
	var visibles := PackedByteArray()
	visibles.resize(vertices.size())
	for vertice in vertices.size():
		var peso_visible := 0.0
		for slot in pesos_por_vertice:
			var entrada := vertice * pesos_por_vertice + slot
			if binds_visibles[huesos[entrada]] == 1:
				peso_visible += pesos[entrada]
		visibles[vertice] = 1 if peso_visible >= 0.55 else 0

	var indices_corte := PackedInt32Array()
	for i in range(0, indices.size(), 3):
		if visibles[indices[i]] and visibles[indices[i + 1]] and visibles[indices[i + 2]]:
			indices_corte.append(indices[i])
			indices_corte.append(indices[i + 1])
			indices_corte.append(indices[i + 2])

	if indices_corte.is_empty():
		return
	datos[Mesh.ARRAY_INDEX] = indices_corte
	_malla_corte = ArrayMesh.new()
	_malla_corte.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, datos)


func _preparar_pose_antebrazo() -> void:
	_giro_antebrazo = Basis.IDENTITY
	var antebrazo := _esqueleto.find_bone("forearm.R")
	if antebrazo < 0 or _malla_corte == null:
		return

	var codo := _esqueleto.get_bone_global_pose(antebrazo).origin
	var hacia_codo := (codo - _pose_mano.origin).normalized()
	# Sube el codo sin desplazar la mano del mango.
	var direccion_corte := Vector3(-0.88, 0.12, -0.93).normalized()
	_giro_antebrazo = Basis(Quaternion(hacia_codo, direccion_corte))


func _colocar_brazo_derecho(pose_mano: Transform3D, peso_giro: float = 0.0) -> void:
	var giro := Basis.IDENTITY.slerp(_giro_antebrazo, peso_giro)
	var clavicula := _pose_clavicula
	# Gira el brazo alrededor de la muñeca y conserva la unión con la mano.
	clavicula.origin = pose_mano.origin + giro * (_pose_clavicula.origin - _pose_mano.origin)
	clavicula.basis = giro * _pose_clavicula.basis
	_esqueleto.set_bone_pose_position(_clavicula, clavicula.origin)
	_esqueleto.set_bone_pose_rotation(_clavicula, clavicula.basis.get_rotation_quaternion())
	_esqueleto.set_bone_pose_position(_mano, pose_mano.origin)
	_esqueleto.set_bone_pose_rotation(_mano, pose_mano.basis.get_rotation_quaternion())


func finalizar_agarre_corte() -> void:
	if not _en_corte:
		return
	_en_corte = false

	# Retoma el espacio de la cámara conservando la pose de este cuadro.
	var pose_global := brazos.global_transform
	brazos.top_level = false
	brazos.global_transform = pose_global
	_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_tween.tween_property(brazos, "transform", _reposo_brazos, 0.18)
	_tween.tween_method(_poner_agarre, _agarre, 0.0, 0.18)
	_tween.tween_method(_volver_mano, 0.0, 1.0, 0.18)


func _volver_mano(peso: float) -> void:
	_colocar_brazo_derecho(_pose_corte_mano.interpolate_with(_pose_mano, peso), 1.0 - peso)
	if _peso_apoyo_izq > 0.0:
		_posar_apoyo_izquierdo(_peso_apoyo_izq * (1.0 - peso))

	if peso >= 1.0:
		_peso_apoyo_izq = 0.0
		_restaurar_malla_brazos()


func _restaurar_malla_brazos() -> void:
	if _malla_corte:
		_malla_brazos.mesh = _malla_normal


func _animar(agarre: float, pos: Vector3) -> void:
	if _tween:
		_tween.kill()

	if _peso_apoyo_izq > 0.0:
		_posar_apoyo_izquierdo(0.0)
		_peso_apoyo_izq = 0.0

	_restaurar_malla_brazos()
	brazos.basis = _reposo_brazos.basis
	if _mano >= 0 and _clavicula >= 0:
		_colocar_brazo_derecho(_pose_mano)
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

	var esqueletos := brazos.find_children("*", "Skeleton3D", true, false)
	if esqueletos.is_empty():
		return
	_esqueleto = esqueletos[0] as Skeleton3D
	_clavicula = _esqueleto.find_bone("clavicle.R")
	_mano = _esqueleto.find_bone("hand.R.control")
	if _clavicula >= 0 and _mano >= 0:
		_pose_clavicula = _esqueleto.get_bone_pose(_clavicula)
		_pose_mano = _esqueleto.get_bone_pose(_mano)
	for i in _esqueleto.get_bone_count():
		var nombre := _esqueleto.get_bone_name(i)
		if nombre.ends_with(".R") and (nombre.begins_with("f_") or nombre.begins_with("thumb")) and not nombre.ends_with("_end"):
			_dedos.append(i)
			_dedos_base.append(_esqueleto.get_bone_pose_rotation(i))


func _pintar_brazos() -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = TEXTURA_BRAZOS
	mat.roughness = 1.0
	mat.emission_enabled = true     # para que las manos se vean aunque haya poca luz
	mat.emission_texture = TEXTURA_BRAZOS
	mat.emission_energy_multiplier = 0.45
	for m in brazos.find_children("*", "MeshInstance3D", true, false):
		(m as MeshInstance3D).material_override = mat


func _preparar_apoyo_izquierdo() -> void:
	if _esqueleto == null:
		return

	_clavicula_izq = _esqueleto.find_bone("clavicle.L")
	_mano_izq = _esqueleto.find_bone("hand.L.control")
	_antebrazo_izq = _esqueleto.find_bone("forearm.L")
	if _clavicula_izq < 0 or _mano_izq < 0 or _antebrazo_izq < 0:
		return

	_clavicula_izq_base = _esqueleto.get_bone_global_pose(_clavicula_izq)
	_mano_izq_base = _esqueleto.get_bone_global_pose(_mano_izq)
	_codo_izq_base = _esqueleto.get_bone_global_pose(_antebrazo_izq).origin

	var indice := _esqueleto.find_bone("f_index.01.L")
	var menique := _esqueleto.find_bone("f_pinky.01.L")
	var medio := _esqueleto.find_bone("f_middle.01.L")
	if indice < 0 or menique < 0 or medio < 0:
		return

	# Los nudillos definen el ancho y la dirección de la palma.
	var hacia_dedos := (
		_esqueleto.get_bone_global_pose(medio).origin - _mano_izq_base.origin
	).normalized()
	var ancho := (
		_esqueleto.get_bone_global_pose(indice).origin
		- _esqueleto.get_bone_global_pose(menique).origin
	).slide(hacia_dedos).normalized()
	_base_palma_izq = Basis(ancho, hacia_dedos.cross(ancho), hacia_dedos)
	_palma_izq_calibrada = true

	for i in _esqueleto.get_bone_count():
		var nombre := _esqueleto.get_bone_name(i)
		if nombre.begins_with("f_") and nombre.ends_with(".L"):
			var base_hueso := _esqueleto.get_bone_global_pose(i).basis
			_dedos_izq.append(i)
			_dedos_izq_base.append(_esqueleto.get_bone_pose_rotation(i))
			_ejes_dedos_izq.append((base_hueso.inverse() * ancho).normalized())


func actualizar_apoyo_izquierdo(
	muneca_global: Vector3,
	direccion_codo_global: Vector3,
	progreso_corte: float,
	base_tabla: Basis
) -> void:
	if not _en_corte or _clavicula_izq < 0 or _mano_izq < 0 or _antebrazo_izq < 0:
		return

	var muneca := _esqueleto.to_local(muneca_global)
	var mundo_a_rig := _esqueleto.global_basis.inverse()
	var codo_base := (_codo_izq_base - _mano_izq_base.origin).normalized()
	var codo_destino := (mundo_a_rig * direccion_codo_global).normalized()
	var giro := Basis(Quaternion(codo_base, codo_destino))
	var ajuste := Transform3D(giro, muneca - giro * _mano_izq_base.origin)

	_pose_clavicula_apoyo = ajuste * _clavicula_izq_base
	_pose_apoyo_izq = ajuste * _mano_izq_base

	if _palma_izq_calibrada:
		# La palma va hacia abajo y los dedos apuntan en diagonal a la verdura.
		var hacia_dedos := (
			mundo_a_rig * (base_tabla * Vector3(0.70, 0.0, -0.72))
		).normalized()
		var arriba := (mundo_a_rig * base_tabla.y).normalized()
		var ancho := hacia_dedos.cross(arriba).normalized()
		var base_destino := Basis(ancho, hacia_dedos.cross(ancho), hacia_dedos)
		_pose_apoyo_izq.basis = (
			base_destino * _base_palma_izq.inverse() * _mano_izq_base.basis
		)

	_peso_apoyo_izq = smoothstep(0.0, 0.16, progreso_corte)
	_posar_apoyo_izquierdo(_peso_apoyo_izq)


func _posar_apoyo_izquierdo(peso: float) -> void:
	_esqueleto.set_bone_global_pose(
		_clavicula_izq,
		_clavicula_izq_base.interpolate_with(_pose_clavicula_apoyo, peso)
	)
	_esqueleto.set_bone_global_pose(
		_mano_izq,
		_mano_izq_base.interpolate_with(_pose_apoyo_izq, peso)
	)

	for i in _dedos_izq.size():
		var curva := Quaternion(_ejes_dedos_izq[i], -0.24 * peso)
		_esqueleto.set_bone_pose_rotation(
			_dedos_izq[i], _dedos_izq_base[i] * curva
		)
    
    
func _mirar_screamer() -> void:
	# La cabeza se levanta hacia el fondo para ver al screamer de frente.
	_mirada_forzada = true
	_soltar()
	if _tween_mirada:
		_tween_mirada.kill()
	_tween_mirada = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_tween_mirada.tween_property(camara, "rotation:x", deg_to_rad(-4.0), 0.45)
	_tween_mirada.tween_property(self, "rotation:y", 0.0, 0.45)


func _recuperar_mirada() -> void:
	_mirada_forzada = false
	if _tween_mirada:
		_tween_mirada.kill()
	camara.rotation.x = _pitch_inicial
	rotation.y = 0.0
