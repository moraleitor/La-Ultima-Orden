extends Node
## El cliente sale caminando de la oscuridad del pasillo hasta la mesa.

const DISTANCIA := 9.0     # m que recorre desde el fondo oscuro
const DURACION := 3.0      # s

@onready var modelo: Node3D = get_parent().get_node("Modelo")
var _tween: Tween


func _ready() -> void:
	Events.cliente_llego.connect(_on_llego)


func _on_llego(_i: int, _ingredientes: Array, pos: int) -> void:
	if pos != get_parent().posicion:
		return
	if _tween:
		_tween.kill()
	modelo.position.z = -DISTANCIA
	_tween = create_tween()
	_tween.tween_property(modelo, "position:z", 0.0, DURACION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
