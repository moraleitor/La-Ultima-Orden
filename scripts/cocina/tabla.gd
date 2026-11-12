
class_name Tabla
extends Node3D

# Gabriela: corte de ingredientes durante 2 segundos.

var ingrediente: Ingrediente = null
var progreso := 0.0
var bloqueada := false

@onready var controlador: DragController = (
	get_parent().get_node("DragController") as DragController
)


func _ready() -> void:
	Events.entradas_bloqueadas.connect(_cambiar_bloqueo)
	Events.intento_iniciado.connect(vaciar)


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

	print("Tabla: recibido ", ing.nombre)
	return true


func _physics_process(delta: float) -> void:
	if bloqueada or ingrediente == null:
		return

	if ingrediente.estado != Ingrediente.Estado.CRUDO:
		return

	# Cortar solo cuando la mira apunta a la tabla
	# y no se está transportando otro ingrediente.
	if Input.is_action_pressed("seleccionar") \
	and controlador.arrastrando == null \
	and controlador.estacion_apuntada() == self:

		progreso += delta

		if progreso >= Config.CORTE_SEGUNDOS:
			progreso = Config.CORTE_SEGUNDOS

			ingrediente.set_estado(
				Ingrediente.Estado.CORTADO
			)

			Events.ingrediente_cortado.emit(
				global_position
			)

			print("Tabla: ", ingrediente.nombre, " CORTADA.")

	else:
		# Si suelta antes de 2 segundos,
		# debe comenzar nuevamente.
		progreso = 0.0


func retirar() -> Ingrediente:
	var ing := ingrediente
	ingrediente = null
	progreso = 0.0
	return ing


func vaciar() -> void:
	if ingrediente != null and is_instance_valid(ingrediente):
		ingrediente.queue_free()

	ingrediente = null
	progreso = 0.0


func _cambiar_bloqueo(valor: bool) -> void:
	bloqueada = valor
	if bloqueada:
		progreso = 0.0
