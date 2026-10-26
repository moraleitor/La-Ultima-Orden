class_name GameManager
extends Node
## Estados del juego: introducción, turno, pausa, apagón y amanecer (M10, M11).

enum Estado { INTRO, JUGANDO, APAGON, AMANECER, ESPERANDO }

var estado: Estado = Estado.ESPERANDO
var tension := 0
var _tiempo_estado := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS   # sigue escuchando Esc aunque el árbol esté en pausa
	Events.tension_cambio.connect(_on_tension_cambio)
	Events.todos_pedidos_cerrados.connect(_on_todos_cerrados)
	iniciar_intento(true)


func iniciar_intento(con_intro: bool) -> void:
	# El primer intento tiene la introducción de 12 s. Tras un apagón se vuelve
	# directo al cliente 1, sin repetirla.
	tension = 0
	_tiempo_estado = 0.0
	Events.entradas_bloqueadas.emit(false)
	Events.intento_iniciado.emit()
	if con_intro:
		estado = Estado.INTRO
	else:
		_empezar_turno()


func _process(delta: float) -> void:
	if get_tree().paused:
		return
	_tiempo_estado += delta
	match estado:
		Estado.INTRO:
			if _tiempo_estado >= Config.INTRO_SEGUNDOS:
				_empezar_turno()
		Estado.APAGON:
			if _tiempo_estado >= Config.APAGON_SEGUNDOS:
				iniciar_intento(false)
		Estado.AMANECER:
			if _tiempo_estado >= Config.AMANECER_SEGUNDOS:
				estado = Estado.ESPERANDO   # TODO: mostrar "otro intento" (tecla R)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pausa") and estado in [Estado.INTRO, Estado.JUGANDO]:
		get_tree().paused = not get_tree().paused
		Events.pausa_cambiada.emit(get_tree().paused)
	elif event.is_action_pressed("reiniciar") and estado == Estado.ESPERANDO:
		iniciar_intento(false)


func _empezar_turno() -> void:
	estado = Estado.JUGANDO
	_tiempo_estado = 0.0
	Events.turno_iniciado.emit()


func _on_tension_cambio(nivel: int) -> void:
	tension = nivel
	if nivel >= Config.TENSION_MAX and estado == Estado.JUGANDO:
		# La derrota tiene prioridad sobre cualquier otra cosa.
		estado = Estado.APAGON
		_tiempo_estado = 0.0
		Events.entradas_bloqueadas.emit(true)
		Events.apagon_iniciado.emit()


func _on_todos_cerrados() -> void:
	if estado == Estado.JUGANDO and tension < Config.TENSION_MAX:
		estado = Estado.AMANECER
		_tiempo_estado = 0.0
		Events.entradas_bloqueadas.emit(true)
		Events.amanecer_iniciado.emit()
