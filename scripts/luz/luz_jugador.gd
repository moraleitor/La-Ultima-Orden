class_name LuzJugador
extends SpotLight3D
## Tarea C - La luz del cocinero (la de la ventanilla, hacia abajo).
## Es hija del Jugador, por eso su position es relativa a él.

@export var rango := 1.5            # m: hasta dónde alumbra en la cocina
@export var altura := 0.9           # m sobre los pies del cocinero
@export var adelante := 0.0         # m hacia la cámara (para alumbrar de frente)
@export var minimo_en_rango := 0.1  # lo que debe llegar justo al borde del rango
@export var exponente := 2.0        # atenuación tipo 1/d^2
@export var imprimir_pruebas := true # las luces de los clientes lo apagan

var _tween: Tween


func _ready() -> void:
	position = Vector3(0.0, altura, adelante)
	spot_range = rango
	spot_attenuation = exponente
	light_energy = energia_para(rango, minimo_en_rango, exponente)
	if not imprimir_pruebas:
		return
	# Nivel 1: función pura (debe dar 1, 0.25, 0.0625)
	print("atenuacion 1, 2, 4 m: ", atenuacion(1.0), " ", atenuacion(2.0), " ", atenuacion(4.0))
	# Nivel 3: Blinn-Phong (debe dar 1.0 y 0.0794)
	var n := Vector3(0, 1, 0)
	var l := Vector3(0, 1, 1)
	print("blinn_phong v=(0,1,-1): ", blinn_phong(n, l, Vector3(0, 1, -1), 32.0))
	print("blinn_phong v=(0,1,0): ", blinn_phong(n, l, Vector3(0, 1, 0), 32.0))


## Nivel 1: cuánta luz llega a la distancia d si a 1 m llega 1.
static func atenuacion(d: float, exp: float = 2.0) -> float:
	return 1.0 / pow(maxf(d, 0.0001), exp)


## Energía que hay que poner para que a la distancia d llegue "minimo".
static func energia_para(d: float, minimo: float, exp: float = 2.0) -> float:
	return minimo / atenuacion(d, exp)


## Nivel 3: brillo de una superficie lisa, max(0, n . h) ^ brillo.
static func blinn_phong(normal: Vector3, hacia_luz: Vector3,
		hacia_ojo: Vector3, brillo: float) -> float:
	var n := _normalizar(normal)
	var l := _normalizar(hacia_luz)
	var v := _normalizar(hacia_ojo)
	var h := _normalizar(l + v)
	return pow(maxf(0.0, n.dot(h)), brillo)


static func _normalizar(vec: Vector3) -> Vector3:
	if vec.length() < 0.0001:
		return Vector3.ZERO
	return vec / vec.length()


## Vacío de C: una apariencia que reduce el plazo se anuncia con luz.
## La luz del cocinero baja a la mitad y vuelve, dos veces, antes de empezar.
## (Solo avisa; la regla del plazo no se toca aquí.)
func anunciar_plazo_reducido() -> void:
	var base := energia_para(rango, minimo_en_rango, exponente)
	if _tween:
		_tween.kill()
	_tween = create_tween()
	for i in 2:
		_tween.tween_property(self, "light_energy", base * 0.5, 0.15)
		_tween.tween_property(self, "light_energy", base, 0.15)
