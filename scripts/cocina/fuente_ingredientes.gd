class_name FuenteIngredientes
extends Node3D
## Recipiente con unidades ilimitadas (M2). Hay tres: papa, zanahoria y cebolla.

@export var nombre_ingrediente: String = "papa"
@export var escena_ingrediente: PackedScene

# TODO: al arrastrar desde aquí, instanciar una unidad nueva y entregarla al DragController.
func sacar_unidad() -> Ingrediente:
	if escena_ingrediente == null:
		return null
	var ing: Ingrediente = escena_ingrediente.instantiate()
	ing.nombre = nombre_ingrediente
	return ing
