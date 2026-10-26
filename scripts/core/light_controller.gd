class_name LightController
extends Node
## Intensidad de la luz según la tensión (sección 9).
## Tensión 0 -> 1,00 | 1 -> 0,75 | 2 -> 0,50 | 3 -> apagón.

var luz: Light3D          # lo asigna main.gd
var _nivel := 0
var _tween: Tween


func _ready() -> void:
	Events.tension_cambio.connect(_on_tension_cambio)
	Events.intento_iniciado.connect(_on_intento)


func _on_intento() -> void:
	_nivel = 0
	_fijar(Config.LUZ_POR_NIVEL[0])


func _on_tension_cambio(nivel: int) -> void:
	var subio := nivel > _nivel
	var bajo := nivel < _nivel
	_nivel = nivel
	if nivel >= Config.TENSION_MAX:
		_fijar(0.0)     # TODO (Danna): el apagón oculta cocina e interfaz durante 3 s
		return
	var objetivo: float = Config.LUZ_POR_NIVEL[nivel]
	if _tween:
		_tween.kill()
	_tween = create_tween()
	if subio:
		# Al fallar: caída breve de 0,2 s y llegada al nuevo nivel en 0,5 s.
		_tween.tween_property(luz, "light_energy", objetivo * 0.6, Config.LUZ_CAIDA_SEGUNDOS)
		_tween.tween_property(luz, "light_energy", objetivo, Config.LUZ_CAMBIO_SEGUNDOS)
	elif bajo:
		_tween.tween_property(luz, "light_energy", objetivo, Config.LUZ_RECUPERACION_SEGUNDOS)


func _fijar(valor: float) -> void:
	if _tween:
		_tween.kill()
	if luz:
		luz.light_energy = valor
