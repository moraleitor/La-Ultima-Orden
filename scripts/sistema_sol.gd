class_name SistemaSol
extends Node

signal cambio_noche(es_noche: bool)

const ENERGIA_POR_TENSION := [1.0, 0.75, 0.5, 0.0]
@export var k_energia := 6.0
@export var bajada_aviso := 0.3

var tension := 0
var energia_objetivo := 1.0

@export var sol: DirectionalLight3D
@export var entorno: WorldEnvironment
@export var energia_sol := 1.0
@export var azimut := -30.0 # grados en Y: hacia dónde caen las sombras
@export var ambiente_dia := 1.0
@export var ambiente_noche := 0.2

var era_noche := false

@onready var ciclo: CicloDia = $CicloDia

func _ready() -> void:
	aplicar_hora()

	era_noche = CicloDia.factor_sol(ciclo.hora) <= 0.0
	Events.tension_cambio.connect(_on_tension_cambio)
	Events.pedido_en_alerta.connect(_on_pedido_en_alerta)


func _process(delta: float) -> void:
	ciclo.avanzar(delta)
	energia_sol = decaer(energia_sol, energia_objetivo, k_energia, delta)
	aplicar_hora()
	var es_noche := CicloDia.factor_sol(ciclo.hora) <= 0.0
	if es_noche != era_noche:
		era_noche = es_noche
		cambio_noche.emit(es_noche)

func aplicar_hora() -> void:
	var h := ciclo.hora
	var f := CicloDia.factor_sol(h)

	sol.rotation_degrees = Vector3(-CicloDia.elevacion(h), azimut, 0.0)
	sol.light_energy = energia_sol * f
	sol.light_color = CicloDia.color_sol(h)
	entorno.environment.ambient_light_energy = lerpf(ambiente_noche, ambiente_dia, f)

func _on_tension_cambio(nivel: int) -> void:
	tension = nivel
	energia_objetivo = ENERGIA_POR_TENSION[clampi(nivel, 0, 3)]

func _on_pedido_en_alerta(_indice: int) -> void:
	if tension == 2:
		energia_sol = maxf(0.0, energia_objetivo - bajada_aviso)

static func decaer(actual: float, objetivo: float, k: float, dt: float) -> float:
	return actual + (objetivo - actual) * (1.0 - exp(-k * dt))

static func lambert(normal: Vector3, hacia_luz: Vector3) -> float:
	var n := normal.normalized()
	var l := hacia_luz.normalized()
	return maxf(0.0, n.dot(l))

func prediccion_piso() -> float:
	var hacia_luz := sol.global_transform.basis.z
	var rojo_lineal := sol.light_color.srgb_to_linear().r
	return sol.light_energy * rojo_lineal * lambert(Vector3.UP, hacia_luz)
