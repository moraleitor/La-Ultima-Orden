class_name Ingrediente
extends Node3D
## Un ingrediente en la escena. Estados: crudo -> cortado -> cocido -> quemado.

enum Estado { CRUDO, CORTADO, COCIDO, QUEMADO }

@export var nombre: String = "papa"       # "papa", "zanahoria" o "cebolla"
var estado: Estado = Estado.CRUDO

# TODO (Gabriela + Danna): cambiar el modelo o la textura al cambiar de estado.
func set_estado(nuevo: Estado) -> void:
	estado = nuevo
