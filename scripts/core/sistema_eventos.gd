
class_name SistemaEventos
extends Node

#Control visual de las alertas y del apagón.
#TensionSystem decide cuánta tensión existe.
#LightController controla la energía de WorkLight.
#GameManager controla cuándo reiniciar el juego.

@export_category("Luces")
@export var luz_evento: OmniLight3D
@export var luz_variable: Light3D
@export var disparador: Disparador

@export var color_alerta: Color = Color("B3362F")
@export var pico_destello: float = 9.0
@export var duracion_pulso: float = 0.20
@export var pausa_entre_pulsos: float = 0.14

@export_category("Efectos visuales")
@export var tinte_pantalla: ColorRect
@export var flash_pantalla: ColorRect
@export var apagon_pantalla: ColorRect
@export var mensaje_apagon: Label

var tension_actual := 0
var _color_inicial := Color.WHITE

var _en_apagon := false
var _tiempo_apagon := 0.0

# Las alertas esperan aquí si llegan varias juntas.
var _cola: Array[Dictionary] = []

var _pulsos_restantes := 0
var _posicion_destello := Vector3.ZERO
var _tiempo_pulso := 0.0
var _tiempo_entre_pulsos := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	# Buscar referencias si no fueron enlazadas
	# desde el Inspector.
	if luz_evento == null:
		luz_evento = get_node_or_null(
			"../LuzEvento"
		) as OmniLight3D

	if luz_variable == null:
		luz_variable = get_node_or_null(
			"../WorkLight"
		) as Light3D

	if disparador == null:
		disparador = get_node_or_null(
			"../Disparador"
		) as Disparador

	if tinte_pantalla == null:
		tinte_pantalla = get_node_or_null(
			"../UI/TinteAlerta"
		) as ColorRect

	if flash_pantalla == null:
		flash_pantalla = get_node_or_null(
			"../UI/FlashRojo"
		) as ColorRect

	if apagon_pantalla == null:
		apagon_pantalla = get_node_or_null(
			"../UI/PantallaApagon"
		) as ColorRect

	if mensaje_apagon == null:
		mensaje_apagon = get_node_or_null(
			"../UI/MensajeApagon"
		) as Label

	# Guardar el color original de Gabriela.
	if luz_variable != null:
		_color_inicial = luz_variable.light_color
	else:
		push_warning("No se encontro WorkLight.")

	# La luz roja siempre comienza apagada.
	if luz_evento != null:
		luz_evento.light_energy = 0.0
	else:
		push_warning("No se encontro LuzEvento.")

	# Conectar las alertas del disparador.
	if disparador != null:
		if not disparador.evento.is_connected(_recibir_evento):
			disparador.evento.connect(_recibir_evento)
	else:
		push_warning("No se encontro Disparador.")

	# Escuchar las señales oficiales del equipo.
	Events.tension_cambio.connect(_cambiar_tension)
	Events.apagon_iniciado.connect(_iniciar_apagon)
	Events.intento_iniciado.connect(_reiniciar)
	Events.amanecer_iniciado.connect(_terminar_destellos)

	_limpiar_pantallas()

	print("[SISTEMA] SistemaEventos preparado.")
	print("[SISTEMA] SistemaEventos preparado.")


func _process(delta: float) -> void:
	# Respetar la pausa del juego.
	if get_tree().paused:
		return

	_actualizar_color_ambiente(delta)

	if _en_apagon:
		_actualizar_apagon(delta)
		return

	_actualizar_tinte(delta)
	_procesar_destellos(delta)


func _actualizar_color_ambiente(delta: float) -> void:
	if luz_variable == null:
		return

	# Convertir tension 0, 1, 2, 3 a un factor 0..1.
	var factor := clampf(
		float(tension_actual) / float(Config.TENSION_MAX),
		0.0,
		1.0
	)

	var color_objetivo := _color_inicial.lerp(
		color_alerta,
		factor
	)

	# Solo cambiar el COLOR, nunca light_energy.
	luz_variable.light_color = luz_variable.light_color.lerp(
		color_objetivo,
		clampf(delta * 4.0, 0.0, 1.0)
	)


func _actualizar_tinte(delta: float) -> void:
	if tinte_pantalla == null:
		return

	var opacidad_objetivo := 0.0

	if tension_actual == 1:
		opacidad_objetivo = 0.06
	elif tension_actual >= 2:
		opacidad_objetivo = 0.14

	var opacidad_actual: float = tinte_pantalla.color.a

	var nueva_opacidad := move_toward(
		opacidad_actual,
		opacidad_objetivo,
		delta * 0.45
	)

	# Color vino oscuro y semitransparente.
	tinte_pantalla.color = Color(
		0.22,
		0.01,
		0.035,
		nueva_opacidad
	)


func _recibir_evento(
	posicion: Vector3,
	cantidad: int,
	motivo: String
) -> void:
	if _en_apagon:
		return

	# Encolar la alerta para no perder otras
	# que hayan llegado al mismo tiempo.
	_cola.append({
		"posicion": posicion,
		"cantidad": cantidad
	})

	print("[SISTEMA] Alerta recibida: ", motivo)


func _procesar_destellos(delta: float) -> void:
	# Fase 1: hay un destello encendido.
	if _tiempo_pulso > 0.0:
		_tiempo_pulso = maxf(
			0.0,
			_tiempo_pulso - delta
		)

		var fuerza := _tiempo_pulso / maxf(
			duracion_pulso,
			0.001
		)

		if luz_evento != null:
			luz_evento.light_energy = pico_destello * fuerza

		if flash_pantalla != null:
			flash_pantalla.color = Color(
				0.85, 0.04, 0.08, 0.27 * fuerza
			)

		return

	# Fase 2: apagar completamente el destello.
	if luz_evento != null:
		luz_evento.light_energy = 0.0

	if flash_pantalla != null:
		flash_pantalla.color = Color(
			0.85, 0.04, 0.08, 0.0
		)

	# Fase 3: pausa breve entre parpadeos.
	if _tiempo_entre_pulsos > 0.0:
		_tiempo_entre_pulsos = maxf(
			0.0,
			_tiempo_entre_pulsos - delta
		)
		return

	# Fase 4: ejecutar el siguiente destello.
	if _pulsos_restantes > 0:
		_encender_destello()

	elif not _cola.is_empty():
		var alerta: Dictionary = _cola.pop_front()

		_pulsos_restantes = int(alerta["cantidad"])
		_posicion_destello = alerta["posicion"]

		_encender_destello()


func _encender_destello() -> void:
	_pulsos_restantes -= 1

	_tiempo_pulso = maxf(duracion_pulso, 0.01)
	_tiempo_entre_pulsos = pausa_entre_pulsos

	if luz_evento != null:
		# Posicionar el fogonazo por encima
		# de la zona que produjo el aviso.
		luz_evento.global_position = (
			_posicion_destello
			+ Vector3(0.0, 1.35, 0.5)
		)

		luz_evento.light_energy = pico_destello

	if flash_pantalla != null:
		flash_pantalla.color = Color(
			0.85, 0.04, 0.08, 0.27
		)

	print(
		"[LUZ] Destello rojo. Faltan ",
		_pulsos_restantes
	)


func _cambiar_tension(nivel: int) -> void:
	tension_actual = clampi(
		nivel,
		0,
		Config.TENSION_MAX
	)

	print("[TENSION] Nivel: ", tension_actual)


func _iniciar_apagon() -> void:
	_en_apagon = true
	_tiempo_apagon = 0.0

	_terminar_destellos()

	if apagon_pantalla != null:
		apagon_pantalla.visible = true
		apagon_pantalla.color = Color(0.0, 0.0, 0.0, 0.0)

	if mensaje_apagon != null:
		mensaje_apagon.visible = false

	print("[APAGON] Apagon iniciado.")


func _actualizar_apagon(delta: float) -> void:
	_tiempo_apagon += delta

	# El screamer original corre durante 1.4 s.
	# Esperamos antes de taparlo por completo.
	var opacidad := clampf(
		(_tiempo_apagon - 1.4) / 0.35,
		0.0,
		1.0
	)

	if apagon_pantalla != null:
		apagon_pantalla.color = Color(
			0.0, 0.0, 0.0, opacidad
		)

	if mensaje_apagon != null:
		mensaje_apagon.visible = _tiempo_apagon >= 1.75


func _terminar_destellos() -> void:
	_cola.clear()
	_pulsos_restantes = 0
	_tiempo_pulso = 0.0
	_tiempo_entre_pulsos = 0.0

	if luz_evento != null:
		luz_evento.light_energy = 0.0

	if flash_pantalla != null:
		flash_pantalla.color = Color(
			0.85, 0.04, 0.08, 0.0
		)


func _reiniciar() -> void:
	tension_actual = 0
	_en_apagon = false
	_tiempo_apagon = 0.25

	_terminar_destellos()

	if luz_variable != null:
		luz_variable.light_color = _color_inicial

	_limpiar_pantallas()

	print("[REINICIO] Efectos visuales limpiados.")


func _limpiar_pantallas() -> void:
	if tinte_pantalla != null:
		tinte_pantalla.color = Color(
			0.22, 0.01, 0.035, 0.0
		)

	if flash_pantalla != null:
		flash_pantalla.color = Color(
			0.85, 0.04, 0.08, 0.0
		)

	if apagon_pantalla != null:
		apagon_pantalla.color = Color(
			0.0, 0.0, 0.0, 0.0
		)
		apagon_pantalla.visible = false

	if mensaje_apagon != null:
		mensaje_apagon.visible = false
