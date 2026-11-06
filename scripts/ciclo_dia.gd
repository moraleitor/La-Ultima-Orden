class_name CicloDia

extends Node

const COLOR_BASE := Color("d9b44a") 
const COLOR_BAJO := Color("6d5a25") # d9b44a atenuado, cerca del horizonte
const COLOR_ALTO := Color("d9b44a") # Color personalizado de nestra paleta

@export var hora := 8.0 # h, al empezar

@export var duracion_dia := 48.0 # s reales que dura un día de 24 h

@export var pausado := false

func avanzar(dt: float) -> void:
	if not pausado:
		hora = fposmod(hora + (24.0 * dt / duracion_dia), 24.0) # horas de juego en dt segundos
		
static func elevacion(h: float) -> float:
	return (h - 6.0) * 15.0  # 6 h → 0°, 12 h → 90°, 18 h → 180°

static func factor_sol(h: float) -> float:
	return maxf(0.0, sin(deg_to_rad(elevacion(h)))) # el seno de la elevación (¡en radianes!)

static func color_sol(h: float) -> Color:
	return COLOR_BAJO.lerp(COLOR_ALTO, factor_sol(h))
