class_name SelectorPapel
extends Node
## Seleccionar un papel con clic y acercarlo manteniendo Espacio (M1).
## Mientras consulta no puede manipular comida, pero relojes y cocción siguen.

var seleccionado := -1
var consultando := false


func _ready() -> void:
	Events.intento_iniciado.connect(func():
		seleccionado = -1
		consultando = false)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("consultar") and seleccionado != -1:
		consultando = true
		Events.consulta_papel.emit(seleccionado, true)
	elif event.is_action_released("consultar") and consultando:
		consultando = false
		Events.consulta_papel.emit(seleccionado, false)


func seleccionar(indice: int) -> void:
	# TODO: llamarla cuando el clic caiga sobre el papel de un cliente.
	seleccionado = indice
	Events.pedido_seleccionado.emit(indice)


func puede_manipular_comida() -> bool:
	return not consultando
