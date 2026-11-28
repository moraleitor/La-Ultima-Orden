
class_name Tabla
extends Node3D

#corte de ingredientes durante 2 segundos.

# Punto de agarre en el modelo del cuchillo y recorrido de la hoja.
const MANGO_LOCAL := Vector3(0.23, 0.02, -0.027)
const ALTURA_CUCHILLO := 0.215
const RECORRIDO_CORTE := 0.13
const FRECUENCIA_CORTE := 2.5

# Punto de la muñeca y dirección del codo en los ejes locales de la tabla.
const APOYO_IZQUIERDO := Vector3(-0.165, 0.045, 0.085)
const DIRECCION_CODO_IZQUIERDO := Vector3(-0.55, -0.10, 1.0)

var ingrediente: Ingrediente = null
var progreso := 0.0
var bloqueada := false

var _corte_en_curso := false
var _golpe_anterior := 0.0
var _cuchillo_reposo: Transform3D
var _tween_cuchillo: Tween
var _particulas: CPUParticles3D
var _mat_particulas: StandardMaterial3D
var _pose_zanahoria: Transform3D

@onready var cuchillo := get_node_or_null("Cuchillo") as Node3D
@onready var controlador: DragController = (
	get_parent().get_node("DragController") as DragController
)
@onready var sonido_corte: AudioStreamPlayer = $SonidoCorte

func _ready() -> void:
	Events.entradas_bloqueadas.connect(_cambiar_bloqueo)
	Events.intento_iniciado.connect(vaciar)
	if cuchillo:
		_cuchillo_reposo = cuchillo.transform
	_preparar_particulas()


func recibir(ing: Ingrediente) -> bool:
	# Solo permite un ingrediente crudo.
	if bloqueada or ing == null:
		return false

	if ingrediente != null:
		return false

	if ing.estado != Ingrediente.Estado.CRUDO:
		return false

	ingrediente = ing
	progreso = 0.0

	# Colocar el ingrediente encima de la tabla.
	ing.reparent(self, false)
	ing.position = Vector3(0.0, 0.12, 0.0)
	if ing.nombre == "zanahoria":
		var modelo := ing.get_node_or_null("Modelo") as Node3D
		if modelo:
			# Acuesta el modelo a lo largo de la tabla y lo centra bajo el cuchillo.
			_pose_zanahoria = modelo.transform
			modelo.rotation_degrees.z = 90.0
			modelo.position += Vector3(0.107, -0.04, 0.0)

	print("Tabla: recibido ", ing.nombre)
	return true


func _physics_process(delta: float) -> void:
	if bloqueada or not is_instance_valid(ingrediente):
		_detener_corte()
		return

	if ingrediente.get_parent() != self:
		_detener_corte()
		# DragController conserva la referencia hasta resolver dónde lo deja.
		return

	var presionando := Input.is_action_pressed("seleccionar") and (
		Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
	)
	if not presionando or controlador.arrastrando != null or controlador.arrastrando_plato:
		_detener_corte()
		return

	if not _corte_en_curso:
		if ingrediente.estado != Ingrediente.Estado.CRUDO:
			return
		if not controlador.selector_papel.puede_manipular_comida():
			return
		# La mira solo importa al iniciar, así se puede mirar alrededor al cortar.
		if controlador.estacion_apuntada() != self:
			return

		_corte_en_curso = true

		if _tween_cuchillo:
			_tween_cuchillo.kill()

		# Reproducir el sonido al comenzar a cortar.
		if sonido_corte.stream != null:
			sonido_corte.stop()
			sonido_corte.play(2.9)
			print("[AUDIO CORTE] Sonido iniciado.")


	# Al completar el cronómetro el puño conserva el mango hasta soltar.
	if ingrediente.estado != Ingrediente.Estado.CRUDO:
		return

	progreso = minf(progreso + delta, Config.CORTE_SEGUNDOS)
	var golpe := (1.0 - cos(progreso * TAU * FRECUENCIA_CORTE)) * 0.5
	_mover_cuchillo(golpe)

	if _golpe_anterior < 0.85 and golpe >= 0.85:
		_emitir_particulas_ingrediente()
	_golpe_anterior = golpe


	if progreso >= Config.CORTE_SEGUNDOS:
		# Detener el audio cuando finalizan los 2 segundos.
		_detener_sonido()

		ingrediente.set_estado(
			Ingrediente.Estado.CORTADO
		)
		_mostrar_ingrediente_picado()

		Events.ingrediente_cortado.emit(
			global_position
		)

		print("Tabla: ", ingrediente.nombre, " CORTADA.")


func _mover_cuchillo(golpe: float) -> void:
	if not is_instance_valid(cuchillo):
		return

	var diagonal := Basis(Vector3.UP, deg_to_rad(-22.0))
	var inclinacion := Basis(Vector3.FORWARD, deg_to_rad(12.0))
	var orientacion_mango := diagonal * inclinacion
	var giro_filo := Basis(Vector3.RIGHT, PI * 0.5)
	var base := (orientacion_mango * giro_filo).scaled_local(
		_cuchillo_reposo.basis.get_scale()
	)
	# Alinea el filo con el centro de la tabla aunque la hoja esté en diagonal.
	var punto_filo := Vector3(-0.22, 0.02, 0.05)
	var altura_filo := ALTURA_CUCHILLO - RECORRIDO_CORTE * golpe
	var destino_filo := Vector3(0.0, altura_filo, 0.0)
	cuchillo.transform = Transform3D(base, destino_filo - base * punto_filo)

	var jugador := get_tree().get_first_node_in_group("player")
	if jugador and jugador.has_method("actualizar_agarre_corte"):
		var mango := cuchillo.global_transform.orthonormalized()
		mango.basis *= giro_filo.inverse()
		mango.origin = cuchillo.to_global(MANGO_LOCAL)
		jugador.actualizar_agarre_corte(mango, global_position)

		# El rig ya está orientado hacia la tabla cuando se coloca la izquierda.
		if jugador.has_method("actualizar_apoyo_izquierdo"):
			var muneca_global := to_global(ingrediente.position + APOYO_IZQUIERDO)
			jugador.actualizar_apoyo_izquierdo(
				muneca_global,
				global_basis * DIRECCION_CODO_IZQUIERDO,
				progreso,
				global_basis.orthonormalized()
			)



func _detener_sonido() -> void:
	# Detener el sonido si todavía se está reproduciendo.
	if sonido_corte != null and sonido_corte.playing:
		sonido_corte.stop()


func _detener_corte() -> void:
	# Siempre detener el audio al cancelar el corte.
	_detener_sonido()

	if not _corte_en_curso:
		return

	_corte_en_curso = false
	_golpe_anterior = 0.0

	# Si suelta antes de terminar, debe comenzar nuevamente.
	if is_instance_valid(ingrediente) and ingrediente.estado == Ingrediente.Estado.CRUDO:
		progreso = 0.0

	# Devolver el cuchillo suavemente a su posición inicial.
	if is_instance_valid(cuchillo):
		_tween_cuchillo = create_tween().set_trans(
			Tween.TRANS_SINE
		).set_ease(Tween.EASE_OUT)

		_tween_cuchillo.tween_property(
			cuchillo,
			"transform",
			_cuchillo_reposo,
			0.18
		)

	# Restaurar las manos del jugador.
	var jugador := get_tree().get_first_node_in_group("player")

	if jugador and jugador.has_method("finalizar_agarre_corte"):
		jugador.finalizar_agarre_corte()


func _preparar_particulas() -> void:
	_mat_particulas = StandardMaterial3D.new()
	_mat_particulas.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var malla := BoxMesh.new()
	malla.size = Vector3(0.025, 0.025, 0.025)
	malla.material = _mat_particulas

	_particulas = CPUParticles3D.new()
	_particulas.emitting = false
	_particulas.amount = 10
	_particulas.lifetime = 0.45
	_particulas.one_shot = true
	_particulas.explosiveness = 0.85
	_particulas.mesh = malla
	_particulas.direction = Vector3.UP
	_particulas.spread = 65.0
	_particulas.initial_velocity_min = 1.1
	_particulas.initial_velocity_max = 2.1
	_particulas.gravity = Vector3(0.0, -6.5, 0.0)
	add_child(_particulas)


func _obtener_color_ingrediente() -> Color:
	var nombre_min := ingrediente.nombre.to_lower()
	if "zanahoria" in nombre_min:
		return Color(1.0, 0.45, 0.05)
	if "cebolla" in nombre_min:
		return Color(0.947, 0.806, 0.965, 0.373)
	return Color(0.776, 0.376, 0.271, 1.0)


func _emitir_particulas_ingrediente() -> void:
	var color_ing := _obtener_color_ingrediente()
	_mat_particulas.albedo_color = color_ing
	_particulas.color = color_ing
	_particulas.position = ingrediente.position + Vector3(0.0, 0.04, 0.0)
	_particulas.restart()
	_particulas.emitting = true


func _mostrar_ingrediente_picado() -> void:
	if ingrediente.nombre == "zanahoria":
		var modelo := ingrediente.get_node_or_null("Modelo") as Node3D
		if modelo:
			# Recupera la pose que usa el ingrediente al quedar picado.
			modelo.transform = _pose_zanahoria

	var nodo_picado := ingrediente.get_node_or_null("Picado") as Node3D
	var nodo_entero := ingrediente.get_node_or_null("Entero") as Node3D
	if nodo_picado and nodo_entero:
		nodo_entero.hide()
		nodo_picado.show()
		return

	# Si el modelo no trae una versión picada, muestra los trozos aquí.
	ingrediente.scale = Vector3(1.15, 0.45, 1.15)
	var trozos_picados := Node3D.new()
	trozos_picados.name = "TrozoPicadosVisual"
	ingrediente.add_child(trozos_picados)
	trozos_picados.scale = Vector3(1.0 / 1.15, 1.0 / 0.45, 1.0 / 1.15)
	trozos_picados.position = Vector3(0.0, -0.02, 0.0)

	var mat_trozo := StandardMaterial3D.new()
	mat_trozo.albedo_color = _obtener_color_ingrediente()
	mat_trozo.roughness = 0.7
	var offsets := [
		Vector3(-0.045, 0.015, 0.03),
		Vector3(0.05, 0.015, -0.025),
		Vector3(0.02, 0.015, 0.045),
		Vector3(-0.035, 0.015, -0.04),
	]
	for offset: Vector3 in offsets:
		var cubito := MeshInstance3D.new()
		var caja := BoxMesh.new()
		caja.size = Vector3(0.032, 0.022, 0.032)
		caja.material = mat_trozo
		cubito.mesh = caja
		cubito.position = offset
		cubito.rotation_degrees.y = offset.x * 400.0
		trozos_picados.add_child(cubito)


func retirar() -> Ingrediente:
	_detener_corte()
	var ing := ingrediente
	ingrediente = null
	progreso = 0.0
	return ing


func vaciar() -> void:
	_detener_corte()
	if ingrediente != null and is_instance_valid(ingrediente):
		ingrediente.queue_free()

	ingrediente = null
	progreso = 0.0


func _cambiar_bloqueo(valor: bool) -> void:
	bloqueada = valor
	if bloqueada:
		_detener_corte()
		progreso = 0.0
