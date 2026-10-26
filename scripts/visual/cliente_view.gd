class_name ClienteView
extends Node3D
## Un cliente en pantalla: 3 apariencias reutilizables y 3 expresiones.

enum Expresion { ESPERA, ALERTA, REACCION_BUENA, REACCION_MALA }

@export var posicion: int = 0        # 0 a 3 (las cuatro posiciones de cliente)
var indice := -1


func _ready() -> void:
	visible = false
	Events.cliente_llego.connect(_on_llego)
	Events.pedido_en_alerta.connect(_on_alerta)
	Events.reaccion_terminada.connect(_on_reaccion_terminada)
	Events.pedido_entregado.connect(_on_entregado)
	Events.intento_iniciado.connect(_ocultar)


func _on_llego(i: int, _ingredientes: Array, pos: int) -> void:
	if pos != posicion:
		return
	indice = i
	visible = true
	set_expresion(Expresion.ESPERA)
	# TODO: elegir una de las 3 apariencias (indice % 3) y dejar el papel con siluetas.


func _on_alerta(i: int) -> void:
	if i == indice:
		set_expresion(Expresion.ALERTA)


func _on_reaccion_terminada(i: int, _correcto: bool) -> void:
	if i == indice:
		_irse()


func _ocultar() -> void:
	visible = false


func _on_entregado(i: int, correcto: bool) -> void:
	if i != indice:
		return
	# Asiente (o mira fijo) durante 3 s antes de irse.
	set_expresion(Expresion.REACCION_BUENA if correcto else Expresion.REACCION_MALA)


func set_expresion(_e: Expresion) -> void:
	pass    # TODO: cambiar textura/animación


func _irse() -> void:
	visible = false
	indice = -1
