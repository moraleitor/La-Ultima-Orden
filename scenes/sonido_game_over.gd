
extends AudioStreamPlayer

# SONIDO DE GAME OVER - LA ULTIMA ORDEN
# Se activa cuando comienza el apagon.
# Espera a que el screamer se acerque.
# Se detiene automaticamente al reiniciar.


@export_category("Configuracion Game Over")

# Retraso para sincronizar el piano con el ataque.
@export_range(0.0, 2.0, 0.05)
var retraso_segundos: float = 1.4


# -1 significa que no hay sonido pendiente.
var _cuenta_atras: float = -1.0


func _ready() -> void:
	autoplay = false

	if stream == null:
		push_warning(
			"[GAME OVER] Falta asignar el MP3."
		)

	# Escuchar las señales originales del juego.
	Events.apagon_iniciado.connect(_on_apagon)
	Events.intento_iniciado.connect(_reiniciar)
	Events.amanecer_iniciado.connect(_reiniciar)

	print("[GAME OVER] Audio preparado.")


func _process(delta: float) -> void:
	# No hacer nada si no existe una cuenta atras.
	if _cuenta_atras < 0.0:
		return

	_cuenta_atras -= delta

	if _cuenta_atras <= 0.0:
		_cuenta_atras = -1.0
		_reproducir_piano()


func _on_apagon() -> void:
	# Detener cualquier sonido anterior.
	stop()

	# Programar el piano para el momento del susto.
	_cuenta_atras = retraso_segundos

	print("[GAME OVER] Apagon detectado.")


func _reproducir_piano() -> void:
	if stream == null:
		push_warning(
			"[GAME OVER] No hay audio asignado."
		)
		return

	# Reproducir desde el principio.
	play(0.0)

	print("[GAME OVER] Piano reproducido.")


func _reiniciar() -> void:
	# Cancelar cualquier reproduccion pendiente.
	_cuenta_atras = -1.0

	# Detener el sonido al comenzar otro intento.
	if playing:
		stop()

	print("[GAME OVER] Audio reiniciado.")
