class_name PapelView
extends Node3D
## El papel del pedido: contorno al seleccionar, borde rojo en alerta, ampliado con Espacio.

var indice := -1


func _ready() -> void:
	Events.pedido_seleccionado.connect(_on_seleccionado)
	Events.pedido_en_alerta.connect(_on_alerta)
	Events.pedido_alerta_terminada.connect(_on_alerta_terminada)
	Events.consulta_papel.connect(_on_consulta)


func _on_seleccionado(i: int) -> void:
	if i == indice:
		_resaltar(true)


func _on_alerta(i: int) -> void:
	if i == indice:
		_borde_rojo(true)


func _on_alerta_terminada(i: int) -> void:
	if i == indice:
		_borde_rojo(false)


func _on_consulta(i: int, activa: bool) -> void:
	if i == indice:
		_acercar(activa)


func _resaltar(_activo: bool) -> void:
	pass    # TODO: contorno + pequeño desplazamiento


func _borde_rojo(_activo: bool) -> void:
	pass    # TODO: borde rojo y reloj dibujado (color #B3362F)


func _acercar(_activo: bool) -> void:
	pass    # TODO: mostrar el papel ampliado con las siluetas de los ingredientes
