class_name HUD
extends CanvasLayer
## Interfaz 2D: reloj del pedido seleccionado, barra de cocción, círculo de corte,
## pictogramas y pausa. NO se muestra ninguna barra ni número de tensión.

var _seleccionado := -1


func _ready() -> void:
	Events.pedido_seleccionado.connect(_on_seleccionado)
	Events.pedido_actualizado.connect(_on_pedido_actualizado)
	Events.pausa_cambiada.connect(_on_pausa)


func _on_seleccionado(i: int) -> void:
	_seleccionado = i


func _on_pedido_actualizado(indice: int, restante: float) -> void:
	if indice == _seleccionado:
		pass    # TODO: dibujar el reloj con "restante" segundos


func _on_pausa(_en_pausa: bool) -> void:
	pass    # TODO: iconos de continuar y reiniciar
