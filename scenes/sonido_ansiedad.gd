
extends AudioStreamPlayer

# LA ULTIMA ORDEN
# RESPIRACION DEL JUGADOR EN TENSION 3
#
# Cuando la tension alcanza el nivel 3,
# el jugador comienza a respirar con ansiedad.
# El sonido continua durante el apagon.
# Se detiene cuando se reinicia el intento.


@export_category("Respiracion del jugador")

@export_range(-30.0, 6.0, 0.5)
var volumen_objetivo_db: float = -2.0

@export_range(0.0, 3.0, 0.05)
var entrada_suave: float = 0.5

@export_range(0.0, 3.0, 0.05)
var salida_suave: float = 0.4


var _respirando := false
var _fundido: Tween


func _ready() -> void:
	# Permitir que el sonido siga funcionando
	# aunque otros sistemas pausen el juego.
	process_mode = Node.PROCESS_MODE_ALWAYS

	autoplay = false
	stream_paused = false
	volume_db = -60.0

	if stream == null:
		push_warning(
			"[RESPIRACION] Falta asignar el WAV."
		)

	# Detectar cambios de tension.
	Events.tension_cambio.connect(
		_on_tension_cambio
	)

	# El apagon tambien activa la respiracion.
	# No se detiene al aparecer el screamer.
	Events.apagon_iniciado.connect(
		_on_apagon
	)

	# Detener al reiniciar la partida.
	Events.intento_iniciado.connect(
		_detener_inmediato
	)

	Events.amanecer_iniciado.connect(
		_detener_inmediato
	)

	# Repetir el sonido mientras exista panico.
	finished.connect(_repetir_respiracion)

	print("[RESPIRACION] Sistema preparado.")


# ----------------------------------------
# DETECTAR TENSION 3
# ----------------------------------------

func _on_tension_cambio(nivel: int) -> void:
	if nivel == 3:
		_iniciar_respiracion()
	else:
		_detener_suavemente()


# ----------------------------------------
# COMIENZA EL APAGON
# ----------------------------------------

func _on_apagon() -> void:
	# Garantizar que la respiracion se active
	# incluso si el apagon comienza antes de
	# que este nodo procese el cambio de tension.
	_iniciar_respiracion()


# ----------------------------------------
# COMENZAR A RESPIRAR
# ----------------------------------------

func _iniciar_respiracion() -> void:
	if _respirando:
		return

	if stream == null:
		push_warning(
			"[RESPIRACION] No existe audio asignado."
		)
		return

	_respirando = true

	_cancelar_fundido()



	# Comenzar con volumen bajo.
	volume_db = -40.0
	stream_paused = false

	# Reproducir desde el principio.
	stop()
	play(0.0)

	# Subir el volumen gradualmente.
	_fundido = create_tween()

	_fundido.tween_property(
		self,
		"volume_db",
		volumen_objetivo_db,
		entrada_suave
	)

	print(
		"[RESPIRACION] TENSION 3: jugador respirando."
	)


# ----------------------------------------
# REPETIR LA RESPIRACION
# ----------------------------------------

func _repetir_respiracion() -> void:
	if _respirando:
		play(0.0)


# ----------------------------------------
# DETENER SUAVEMENTE
# ----------------------------------------

func _detener_suavemente() -> void:
	if not _respirando:
		return

	_respirando = false

	_cancelar_fundido()

	if not playing:
		return

	_fundido = create_tween()

	_fundido.tween_property(
		self,
		"volume_db",
		-60.0,
		salida_suave
	)

	_fundido.tween_callback(stop)



# REINICIO DEL INTENTO


func _detener_inmediato() -> void:
	_respirando = false

	_cancelar_fundido()

	stop()
	volume_db = -60.0

	print("[RESPIRACION] Respiracion reiniciada.")


func _cancelar_fundido() -> void:
	if _fundido != null and _fundido.is_valid():
		_fundido.kill()
