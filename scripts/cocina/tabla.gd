class_name Tabla
extends Node3D
## Tabla de corte (M3): un ingrediente, 2 s manteniendo clic izquierdo.

var ingrediente: Ingrediente
var progreso := 0.0
var bloqueada := false


func _ready() -> void:
	Events.entradas_bloqueadas.connect(func(b): bloqueada = b)
	Events.intento_iniciado.connect(vaciar)


func recibir(ing: Ingrediente) -> bool:
	# Solo acepta un ingrediente crudo y solo si la tabla está vacía.
	if bloqueada or ingrediente != null or ing.estado != Ingrediente.Estado.CRUDO:
		return false
	ingrediente = ing
	progreso = 0.0
	return true


func _process(delta: float) -> void:
	if bloqueada or ingrediente == null or ingrediente.estado != Ingrediente.Estado.CRUDO:
		return
	if Input.is_action_pressed("seleccionar") and _mouse_sobre_tabla():
		progreso += delta
		if progreso >= Config.CORTE_SEGUNDOS:
			ingrediente.set_estado(Ingrediente.Estado.CORTADO)
			Events.ingrediente_cortado.emit(global_position)
	else:
		progreso = 0.0     # soltar antes reinicia el progreso a cero


func retirar() -> Ingrediente:
	var ing := ingrediente
	ingrediente = null
	progreso = 0.0
	return ing


func vaciar() -> void:
	ingrediente = null
	progreso = 0.0


func _mouse_sobre_tabla() -> bool:
	return true     # TODO: raycast desde la cámara hasta esta tabla
