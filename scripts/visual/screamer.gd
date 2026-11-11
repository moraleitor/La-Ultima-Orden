extends Node3D
## El screamer vive en la oscuridad del fondo. Cuando se va la luz (apagón) corre
## hasta la mesa; con el amanecer o un intento nuevo se esconde otra vez.

const FONDO := Vector3(0.0, 0.0, -14.0)
const FRENTE := Vector3(0.0, 0.0, -0.9)
const CORRIDA := 1.4      # s

var _tween: Tween


func _ready() -> void:
	_esconder()
	Events.apagon_iniciado.connect(_on_apagon)
	Events.amanecer_iniciado.connect(_esconder)
	Events.intento_iniciado.connect(_esconder)


func _on_apagon() -> void:
	if _tween:
		_tween.kill()
	position = FONDO
	visible = true
	_tween = create_tween()
	_tween.tween_property(self, "position", FRENTE, CORRIDA).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)


func _esconder() -> void:
	if _tween:
		_tween.kill()
	visible = false
	position = FONDO
