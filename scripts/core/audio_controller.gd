class_name AudioController
extends Node
## Sonido exterior: baja al 50 % mientras exista al menos un pedido en alerta (M6).
## Los sonidos de cocina y el reloj NO cambian.

@export var ambiente: AudioStreamPlayer      # TODO (Danna): crear el reproductor y asignarlo
var _en_alerta: Array[int] = []


func _ready() -> void:
	Events.pedido_en_alerta.connect(_on_alerta)
	Events.pedido_alerta_terminada.connect(_on_alerta_terminada)
	Events.intento_iniciado.connect(func():
		_en_alerta.clear()
		_actualizar())


func _on_alerta(indice: int) -> void:
	if indice not in _en_alerta:
		_en_alerta.append(indice)
	_actualizar()


func _on_alerta_terminada(indice: int) -> void:
	_en_alerta.erase(indice)
	_actualizar()


func _actualizar() -> void:
	if ambiente == null:
		return
	var factor := Config.AMBIENTE_EN_ALERTA if not _en_alerta.is_empty() else 1.0
	ambiente.volume_db = linear_to_db(factor)
