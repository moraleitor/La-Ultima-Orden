class_name SistemaEventos
extends Node

@export var luz_evento: OmniLight3D
@export var pico_destello := 4.0
@export var k_destello := 4.0

@export var luz_variable: Light3D
@export var color_bajo: Color = Color("8FB38A") # Verde ambiente (Tensión baja)
@export var color_alto: Color = Color("B3362F") # Rojo alerta (Tensión alta)
@export var k_variable := 4.0

var variable := 0.0 # Control de nivel de tensión de 0 a 1

func _ready() -> void:
	for d in get_tree().get_nodes_in_group("disparadores"):
		d.evento.connect(_on_evento)
	if luz_evento:
		luz_evento.light_energy = 0.0

func _process(delta: float) -> void:
	if luz_evento:
		luz_evento.light_energy = decaer(luz_evento.light_energy, 0.0, k_destello, delta)

	# Control manual con teclado para probar la variable de tensión
	if Input.is_key_pressed(KEY_UP):
		variable = minf(1.0, variable + delta * 0.5)
	elif Input.is_key_pressed(KEY_DOWN):
		variable = maxf(0.0, variable - delta * 0.5)

	if luz_variable:
		var target_color = color_bajo.lerp(color_alto, clampf(variable, 0.0, 1.0))
		luz_variable.light_color = target_color
		var target_energy = 0.75 + 1.25 * variable
		luz_variable.light_energy = decaer(luz_variable.light_energy, target_energy, k_variable, delta)

func _on_evento(posicion: Vector3) -> void:
	if luz_evento:
		luz_evento.global_position = posicion + Vector3.UP * 1.5
		luz_evento.light_energy = pico_destello

static func decaer(actual: float, base: float, k: float, dt: float) -> float:
	var alpha = 1.0 - exp(-k * dt)
	return actual + (base - actual) * alpha
