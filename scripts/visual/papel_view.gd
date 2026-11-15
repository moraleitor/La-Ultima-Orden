class_name PapelView
extends Node3D
## El papel del pedido: contorno al seleccionar y ampliado con Espacio.

var indice := -1:
	set(valor):
		indice = valor
		visible = (indice >= 0) and not _en_consulta
		if indice < 0:
			_en_consulta = false
			_resaltar(false)

var _pos_base_y := 0.0
var _en_consulta := false


func _ready() -> void:
	_pos_base_y = position.y
	visible = false

	Events.pedido_seleccionado.connect(_on_seleccionado)
	Events.consulta_papel.connect(_on_consulta)
	Events.intento_iniciado.connect(_on_reiniciar)


func _on_seleccionado(i: int) -> void:
	_resaltar(indice >= 0 and i == indice)


func _on_consulta(i: int, activa: bool) -> void:
	if i == indice:
		_acercar(activa)


func _resaltar(activo: bool) -> void:
	# Contorno / elevación sobre la mesa al hacer clic
	position.y = _pos_base_y + (0.04 if activo else 0.0)


func _acercar(activo: bool) -> void:
	# Oculta el papel de la mesa mientras se sostiene ampliado en pantalla con Espacio
	_en_consulta = activo
	visible = (indice >= 0) and not _en_consulta


func _on_reiniciar() -> void:
	indice = -1
	_en_consulta = false
	visible = false
	_resaltar(false)
