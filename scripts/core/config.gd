extends Node
## Todos los números del documento de concepto en un solo lugar.
## Si cambia una regla, se cambia aquí y no en cada script.

# Turno y llegadas (M6, M7)
const INTRO_SEGUNDOS := 12.0
const PLAZO_PRIMEROS := 60.0      # clientes 1 a 3
const PLAZO_RESTO := 45.0         # desde el cliente 4
const CLIENTES_CON_PLAZO_LARGO := 3
const ALERTA_SEGUNDOS := 15.0
const REACCION_SEGUNDOS := 3.0
const POSICIONES_CLIENTE := 4
const LLEGADAS := [0, 30, 60, 90, 110, 130, 150, 170, 190, 210, 230, 250, 270]

# Pedidos: secuencia fija de 13 clientes
const PEDIDOS := [
	["papa"], ["zanahoria"], ["cebolla"],
	["papa", "cebolla"], ["zanahoria"], ["zanahoria", "cebolla"],
	["papa"], ["papa", "zanahoria"], ["cebolla"],
	["papa", "cebolla"], ["papa"], ["zanahoria", "cebolla"],
	["zanahoria"],
]

# Cocina (M2 a M5)
const CORTE_SEGUNDOS := 2.0
const COCCION_SEGUNDOS := 7.0
const LISTO_SEGUNDOS := 4.0       # tiempo extra antes de quemarse
const QUEMADO_SEGUNDOS := 11.0    # desde que entró a la hornilla
const CAPACIDAD_PLATO := 2

# Tensión (M8 a M10)
const TENSION_MAX := 3
const RACHA_PARA_RECUPERAR := 4
const APAGON_SEGUNDOS := 3.0
const AMANECER_SEGUNDOS := 5.0

# Luz (sección 9). Índice = nivel de tensión 0, 1, 2.
const LUZ_POR_NIVEL := [1.0, 0.75, 0.5]
const LUZ_CAIDA_SEGUNDOS := 0.2
const LUZ_CAMBIO_SEGUNDOS := 0.5
const LUZ_RECUPERACION_SEGUNDOS := 1.0
const AMBIENTE_EN_ALERTA := 0.5   # el sonido exterior baja al 50 %


func _ready() -> void:
	_registrar_acciones()


func _registrar_acciones() -> void:
	_accion_tecla("consultar", KEY_SPACE)
	_accion_tecla("pausa", KEY_ESCAPE)
	_accion_tecla("reiniciar", KEY_R)
	_accion_mouse("seleccionar", MOUSE_BUTTON_LEFT)
	_accion_mouse("descartar", MOUSE_BUTTON_RIGHT)


func _accion_tecla(nombre: String, tecla: Key) -> void:
	if InputMap.has_action(nombre):
		return
	InputMap.add_action(nombre)
	var ev := InputEventKey.new()
	ev.physical_keycode = tecla
	InputMap.action_add_event(nombre, ev)


func _accion_mouse(nombre: String, boton: MouseButton) -> void:
	if InputMap.has_action(nombre):
		return
	InputMap.add_action(nombre)
	var ev := InputEventMouseButton.new()
	ev.button_index = boton
	InputMap.action_add_event(nombre, ev)
