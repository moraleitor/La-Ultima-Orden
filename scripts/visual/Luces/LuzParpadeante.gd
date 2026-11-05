class_name LuzParpadeante
extends OmniLight3D # o SpotLight3D en este caso WorkLight

@export var energia_base := 1.5
@export var amplitud := 0.25 
@export var velocidad := 4.0 # qué tan rápido recorre el ruido
@export var semilla := 7

var ruido: FastNoiseLite = FastNoiseLite.new()
var t := 0.0

func _ready() -> void:
	ruido.seed = semilla
	ruido.frequency = 1.0 # sin esto casi no cambia (viene en 0.01)
	print("Prueba pura energia(2.0, 0.3, 1.0): ", energia(2.0, 0.3, 1.0)) # Debe dar 2.6
	print("Prueba pura energia(2.0, 0.3, -1.0): ", energia(2.0, 0.3, -1.0)) # Debe dar 1.4

func _process(delta: float) -> void:
	t += delta
	var valor_ruido = ruido.get_noise_1d(t * velocidad)
	light_energy = energia(energia_base, amplitud, valor_ruido)

static func energia(base: float, amp: float, valor_ruido: float) -> float:
	return maxf(0.0, base * (1.0 + amp * valor_ruido))
