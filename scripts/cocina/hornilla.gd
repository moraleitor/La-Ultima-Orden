class_name Hornilla
extends Node3D
## Hornilla (M4): un ingrediente cortado. Se cocina solo 7 s, queda listo 4 s más
## y se quema a los 11 s desde que entró.

var ingrediente: Ingrediente
var tiempo := 0.0
var _aviso_listo := false
var bloqueada := false


func _ready() -> void:
	Events.entradas_bloqueadas.connect(func(b): bloqueada = b)
	Events.intento_iniciado.connect(vaciar)


func recibir(ing: Ingrediente) -> bool:
	if bloqueada or ingrediente != null or ing.estado != Ingrediente.Estado.CORTADO:
		return false
	ingrediente = ing
	tiempo = 0.0
	_aviso_listo = false
	return true


func _process(delta: float) -> void:
	if ingrediente == null:
		return
	tiempo += delta
	if tiempo >= Config.COCCION_SEGUNDOS and ingrediente.estado == Ingrediente.Estado.CORTADO:
		ingrediente.set_estado(Ingrediente.Estado.COCIDO)
		Events.ingrediente_listo.emit(self)
	if tiempo >= Config.QUEMADO_SEGUNDOS and ingrediente.estado == Ingrediente.Estado.COCIDO:
		ingrediente.set_estado(Ingrediente.Estado.QUEMADO)
		Events.ingrediente_quemado.emit(self)


func puede_retirar() -> bool:
	# No se puede retirar antes de los 7 s.
	return ingrediente != null and tiempo >= Config.COCCION_SEGUNDOS


func retirar() -> Ingrediente:
	if not puede_retirar():
		return null
	var ing := ingrediente
	ingrediente = null
	tiempo = 0.0
	return ing


func vaciar() -> void:
	ingrediente = null
	tiempo = 0.0
