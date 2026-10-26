class_name Plato
extends Node3D
## Plato de dos espacios (M2, M5). Solo entran ingredientes cocidos y sin quemar.

var contenido: Array[Ingrediente] = []


func _ready() -> void:
	Events.intento_iniciado.connect(vaciar)


func recibir(ing: Ingrediente) -> bool:
	if contenido.size() >= Config.CAPACIDAD_PLATO or ing.estado != Ingrediente.Estado.COCIDO:
		return false
	contenido.append(ing)
	return true


func nombres() -> Array:
	var lista: Array = []
	for ing in contenido:
		lista.append(ing.nombre)
	return lista


func entregar(indice_cliente: int) -> void:
	# Gabriela solo avisa; OrderManager compara el plato con el pedido (M5).
	if contenido.is_empty():
		return
	Events.entrega_intentada.emit(indice_cliente, nombres())
	vaciar()       # cualquier entrega vacía el plato


func vaciar() -> void:
	for ing in contenido:
		ing.queue_free()
	contenido.clear()
