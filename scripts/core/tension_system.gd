class_name TensionSystem
extends Node
## Tensión oculta, racha y recuperación (M8, M9). El contador NO se muestra al jugador.

var tension := 0
var racha := 0
var _recuperacion_pendiente := -1   # índice del cliente cuya reacción dispara la recuperación


func _ready() -> void:
	Events.intento_iniciado.connect(_reiniciar)
	Events.pedido_vencido.connect(_on_error.unbind(1))
	Events.pedido_entregado.connect(_on_entrega)
	Events.reaccion_terminada.connect(_on_reaccion_terminada)


func _reiniciar() -> void:
	tension = 0
	racha = 0
	_recuperacion_pendiente = -1
	Events.tension_cambio.emit(tension)
	Events.racha_cambio.emit(racha)


func _on_entrega(indice: int, correcto: bool) -> void:
	if correcto:
		racha += 1
		if racha >= Config.RACHA_PARA_RECUPERAR:
			# La recuperación se programa para el final de la reacción de este cliente.
			_recuperacion_pendiente = indice
			racha = 0
		Events.racha_cambio.emit(racha)
	else:
		_on_error()


func _on_error() -> void:
	tension = mini(tension + 1, Config.TENSION_MAX)
	racha = 0
	_recuperacion_pendiente = -1    # un error antes de que termine la reacción la cancela
	Events.racha_cambio.emit(racha)
	Events.tension_cambio.emit(tension)


func _on_reaccion_terminada(indice: int, _correcto: bool) -> void:
	if indice != _recuperacion_pendiente:
		return
	_recuperacion_pendiente = -1
	if tension > 0:
		tension -= 1
		Events.tension_cambio.emit(tension)
		Events.luz_recuperada.emit()
