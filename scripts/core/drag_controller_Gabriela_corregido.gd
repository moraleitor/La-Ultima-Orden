class_name DragController
extends Node3D
## Gabriela - Interaccion de cocina y entrega de platos.
## Usa la mira central de la camara para detectar las estaciones.

const ALCANCE := 4.0
const DISTANCIA_MANO := 0.72

var arrastrando: Ingrediente = null
var origen: Node3D = null
var bloqueado := false
var tiempo_al_retirar := 0.0
var arrastrando_plato := false

@onready var camara: Camera3D = get_viewport().get_camera_3d()
@onready var tabla: Tabla = get_parent().get_node("Tabla") as Tabla
@onready var hornilla: Hornilla = get_parent().get_node("Hornilla") as Hornilla
@onready var plato: Plato = get_parent().get_node("Plato") as Plato
@onready var transform_original_plato: Transform3D = plato.transform


func _ready() -> void:
	Events.entradas_bloqueadas.connect(_cambiar_bloqueo)
	Events.intento_iniciado.connect(_reiniciar)
	Events.pedido_entregado.connect(_resultado_entrega)


func _physics_process(_delta: float) -> void:
	if bloqueado or camara == null:
		return

	if arrastrando != null and is_instance_valid(arrastrando):
		arrastrando.global_position = (
			camara.global_position
			- camara.global_transform.basis.z * DISTANCIA_MANO
			- camara.global_transform.basis.y * 0.15
		)

	# El plato permanece en su escena y solo cambia su posicion temporalmente.
	if arrastrando_plato:
		plato.global_position = (
			camara.global_position
			- camara.global_transform.basis.z * 0.85
			- camara.global_transform.basis.y * 0.15
		)

	if Input.is_action_just_pressed("seleccionar"):
		if arrastrando == null and not arrastrando_plato:
			_comenzar_arrastre()

	if Input.is_action_just_released("seleccionar"):
		if arrastrando_plato:
			_soltar_plato()
		elif arrastrando != null:
			_soltar_ingrediente()


func estacion_apuntada() -> Node3D:
	if camara == null:
		return null

	var desde := camara.global_position
	var hasta := desde - camara.global_transform.basis.z * ALCANCE
	var excluidos: Array[RID] = []

	# Los rayos atraviesan colisiones decorativas y el plato transportado.
	for _intento in range(24):
		var consulta := PhysicsRayQueryParameters3D.create(desde, hasta)
		consulta.exclude = excluidos
		var resultado := get_world_3d().direct_space_state.intersect_ray(consulta)
		if resultado.is_empty():
			return null

		var cuerpo := resultado.get("collider") as CollisionObject3D
		if cuerpo == null:
			return null

		var nodo: Node = cuerpo
		while nodo != null:
			if nodo is Plato and arrastrando_plato:
				break

			if nodo is ClienteView:
				var cliente := nodo as ClienteView
				if cliente.visible and cliente.indice >= 0:
					return cliente
				break

			if (nodo is FuenteIngredientes or nodo is Tabla
					or nodo is Hornilla or nodo is Plato):
				return nodo as Node3D

			nodo = nodo.get_parent()

		excluidos.append(cuerpo.get_rid())

	return null


func _tomar_de_fuente() -> void:
	var objetivo := estacion_apuntada()
	if not (objetivo is FuenteIngredientes):
		return

	var fuente := objetivo as FuenteIngredientes
	var nuevo: Ingrediente = fuente.sacar_unidad()
	if nuevo == null:
		push_warning("No se pudo crear el ingrediente.")
		return

	add_child(nuevo)
	arrastrando = nuevo
	origen = fuente
	print("Gabriela: tomaste ", nuevo.nombre)


func _comenzar_arrastre() -> void:
	var objetivo := estacion_apuntada()

	if objetivo is FuenteIngredientes:
		_tomar_de_fuente()
		return

	if objetivo == tabla:
		var ing: Ingrediente = tabla.ingrediente
		if ing == null or not is_instance_valid(ing):
			return
		if ing.estado != Ingrediente.Estado.CORTADO:
			print("Gabriela: primero debes cortar el ingrediente.")
			return

		arrastrando = ing
		origen = tabla
		arrastrando.reparent(self, true)
		print("Gabriela: recogiste ", ing.nombre, " cortada.")
		return

	if objetivo == hornilla:
		if hornilla.ingrediente == null:
			print("Gabriela: la hornilla esta vacia.")
			return
		if not hornilla.puede_retirar():
			print("Gabriela: todavia se esta cocinando.")
			return
		if hornilla.ingrediente.estado != Ingrediente.Estado.COCIDO:
			print("Gabriela: el ingrediente esta quemado.")
			return

		tiempo_al_retirar = hornilla.tiempo
		var ing_cocido: Ingrediente = hornilla.retirar()
		if ing_cocido == null:
			return
		arrastrando = ing_cocido
		origen = hornilla
		arrastrando.reparent(self, true)
		print("Gabriela: recogiste ", ing_cocido.nombre, " cocida.")
		return

	if objetivo == plato:
		if plato.contenido.is_empty():
			print("Gabriela: el plato esta vacio.")
			return
		arrastrando_plato = true
		print("Gabriela: recogiste el plato preparado.")
		return


func _soltar_ingrediente() -> void:
	if arrastrando == null:
		return

	var destino := estacion_apuntada()
	var aceptado := false

	if origen is FuenteIngredientes and destino == tabla:
		aceptado = tabla.recibir(arrastrando)

	elif origen == tabla and destino == hornilla:
		aceptado = hornilla.recibir(arrastrando)
		if aceptado:
			tabla.retirar()

	elif origen == hornilla and destino == plato:
		aceptado = plato.recibir(arrastrando)
		if aceptado:
			arrastrando.reparent(plato, false)
			var indice := plato.contenido.size() - 1
			arrastrando.position = Vector3(-0.07 + indice * 0.14, 0.06, 0.0)

	if aceptado:
		print("Gabriela: transferencia correcta.")
	else:
		print("Gabriela: destino invalido; el ingrediente vuelve al origen.")
		_devolver_ingrediente()

	arrastrando = null
	origen = null
	tiempo_al_retirar = 0.0


func _devolver_ingrediente() -> void:
	if arrastrando == null or not is_instance_valid(arrastrando):
		return

	if origen is FuenteIngredientes:
		arrastrando.queue_free()
	elif origen == tabla:
		arrastrando.reparent(tabla, false)
		arrastrando.position = Vector3(0.0, 0.12, 0.0)
	elif origen == hornilla:
		arrastrando.reparent(hornilla, false)
		arrastrando.position = Vector3(0.0, 0.18, 0.0)
		hornilla.ingrediente = arrastrando
		hornilla.tiempo = tiempo_al_retirar


func _soltar_plato() -> void:
	var destino := estacion_apuntada()
	if destino is ClienteView:
		var cliente := destino as ClienteView
		if cliente.visible and cliente.indice >= 0:
			print("Gabriela: entregando al cliente ", cliente.indice + 1)
			plato.entregar(cliente.indice)
		else:
			print("Gabriela: no hay un pedido activo.")
	else:
		print("Gabriela: debes soltar el plato sobre un cliente.")

	_devolver_plato()


func _devolver_plato() -> void:
	if not arrastrando_plato:
		return
	plato.transform = transform_original_plato
	arrastrando_plato = false


func _resultado_entrega(indice: int, correcto: bool) -> void:
	if correcto:
		print("Gabriela: pedido ", indice + 1, " CORRECTO.")
	else:
		print("Gabriela: pedido ", indice + 1, " INCORRECTO.")


func _cambiar_bloqueo(valor: bool) -> void:
	bloqueado = valor
	if bloqueado:
		_cancelar_arrastre()


func _cancelar_arrastre() -> void:
	_devolver_plato()
	if arrastrando != null:
		_devolver_ingrediente()
	arrastrando = null
	origen = null
	tiempo_al_retirar = 0.0


func _reiniciar() -> void:
	_cancelar_arrastre()
	bloqueado = false
