class_name DragController
extends Node3D
## Arrastrar y soltar con clic izquierdo (controles del documento).
## Soltar en un destino inválido devuelve el objeto al origen sin castigo.
## Clic derecho descarta una unidad; sobre el plato, descarta todo su contenido.

var arrastrando: Ingrediente
var origen: Node3D
var bloqueado := false


func _ready() -> void:
	Events.entradas_bloqueadas.connect(func(b): bloqueado = b)


func _unhandled_input(event: InputEvent) -> void:
	if bloqueado:
		return
	if event.is_action_pressed("seleccionar"):
		pass    # TODO: raycast -> si hay ingrediente o plato, empezar a arrastrar
	elif event.is_action_released("seleccionar"):
		pass    # TODO: raycast -> soltar en Tabla/Hornilla/Plato/Cliente o devolver al origen
	elif event.is_action_pressed("descartar"):
		pass    # TODO: descartar unidad (o plato completo) y emitir Events.ingrediente_descartado
