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
	if bloqueada or ing == null:
		return false
		
	if ingrediente != null:
		return false

	if ing.estado != Ingrediente.Estado.CORTADO:
		return false

	ingrediente = ing
	tiempo = 0.0
	_aviso_listo = false

	# Colocar el ingrediente sobre la sartén.
	ing.reparent(self, false)
	ing.position = Vector3(0.0, 0.18, 0.0)

	print("Hornilla: comenzó la cocción de ", ing.nombre)

	return true


func _process(delta: float) -> void:
	if ingrediente == null:
		return

	tiempo += delta

	# Después de 7 segundos, queda cocido.
	if tiempo >= Config.COCCION_SEGUNDOS \
	and ingrediente.estado == Ingrediente.Estado.CORTADO:

		ingrediente.set_estado(Ingrediente.Estado.COCIDO)
		Events.ingrediente_listo.emit(self)

		print("Hornilla: ", ingrediente.nombre,
			" COCIDA a los ", snapped(tiempo, 0.1),
			" segundos.")

	# Después de 11 segundos, queda quemado.
	if tiempo >= Config.QUEMADO_SEGUNDOS \
	and ingrediente.estado == Ingrediente.Estado.COCIDO:

		ingrediente.set_estado(Ingrediente.Estado.QUEMADO)
		Events.ingrediente_quemado.emit(self)

		print("Hornilla: ", ingrediente.nombre,
			" QUEMADA a los ", snapped(tiempo, 0.1),
			" segundos.")

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
	if ingrediente != null and is_instance_valid(ingrediente):
		ingrediente.queue_free()

	ingrediente = null
	tiempo = 0.0
	_aviso_listo = false
