
class_name DragController
extends Node3D

#primera etapa del movimiento de ingredientes.

const ALCANCE := 4.0
const DISTANCIA_MANO := 0.72

var arrastrando: Ingrediente = null
var origen: Node3D = null
var bloqueado := false

@onready var camara: Camera3D = get_viewport().get_camera_3d()
@onready var tabla: Tabla = get_parent().get_node("Tabla") as Tabla


func _ready() -> void:
	Events.entradas_bloqueadas.connect(_cambiar_bloqueo)
	Events.intento_iniciado.connect(_reiniciar)


func _physics_process(_delta: float) -> void:
	if bloqueado or camara == null:
		return

	# Mantener el ingrediente delante de la cámara.
	if arrastrando != null:
		arrastrando.global_position = (
			camara.global_position
			- camara.global_transform.basis.z * DISTANCIA_MANO
			- camara.global_transform.basis.y * 0.15
		)

	# Empezar a tomar un ingrediente.
	if Input.is_action_just_pressed("seleccionar"):
		if arrastrando == null:
			_tomar_de_fuente()

	# Soltar sobre la tabla.
	if Input.is_action_just_released("seleccionar"):
		if arrastrando != null:
			_soltar_en_tabla()


func estacion_apuntada() -> Node3D:
	if camara == null:
		return null

	var desde := camara.global_position
	var hasta := desde - camara.global_transform.basis.z * ALCANCE

	var excluidos: Array[RID] = []

	# Ignorar colisiones decorativas de la mesa.
	for i in range(24):
		var consulta := PhysicsRayQueryParameters3D.create(
			desde, hasta
		)
		consulta.exclude = excluidos

		var resultado := get_world_3d().direct_space_state.intersect_ray(
			consulta
		)

		if resultado.is_empty():
			return null

		var cuerpo := resultado.get("collider") as CollisionObject3D

		if cuerpo == null:
			return null

		var nodo: Node = cuerpo

		# Buscar el nodo padre de la colisión.
		while nodo != null:
			if nodo is FuenteIngredientes or nodo is Tabla:
				return nodo as Node3D

			nodo = nodo.get_parent()

		excluidos.append(cuerpo.get_rid())

	return null


func _tomar_de_fuente() -> void:
	var objetivo := estacion_apuntada()

	if objetivo is FuenteIngredientes:
		var fuente := objetivo as FuenteIngredientes
		var nuevo: Ingrediente = fuente.sacar_unidad()

		if nuevo == null:
			push_warning("La fuente no tiene escena de ingrediente.")
			return

		add_child(nuevo)

		arrastrando = nuevo
		origen = fuente

		print("Gabriela: tomaste ", nuevo.nombre)


func _soltar_en_tabla() -> void:
	var objetivo := estacion_apuntada()

	if objetivo == tabla and tabla.recibir(arrastrando):
		print("Gabriela: ingrediente colocado en la tabla.")
	else:
		print("Gabriela: destino inválido, ingrediente devuelto.")
		arrastrando.queue_free()

	arrastrando = null
	origen = null


func _cambiar_bloqueo(valor: bool) -> void:
	bloqueado = valor

	if bloqueado:
		_cancelar_arrastre()


func _cancelar_arrastre() -> void:
	if arrastrando != null and is_instance_valid(arrastrando):
		arrastrando.queue_free()

	arrastrando = null
	origen = null


func _reiniciar() -> void:
	_cancelar_arrastre()
	bloqueado = false
