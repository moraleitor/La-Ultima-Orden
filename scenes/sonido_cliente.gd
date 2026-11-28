
extends AudioStreamPlayer

# SONIDO DE APARICION DE CLIENTES
# LA ULTIMA ORDEN
#
# Reproduce un gemido cuando llega un cliente.
# No modifica el sistema de pedidos.
# Se detiene al comenzar el apagon o reiniciar.


func _ready() -> void:
	# Evitar que suene al iniciar el juego.
	autoplay = false

	# Comprobar que tenga el MP3 asignado.
	if stream == null:
		push_warning(
			"[CLIENTE] Falta asignar Ghost_moan_2.mp3."
		)

	# Escuchar la llegada de nuevos clientes.
	Events.cliente_llego.connect(_on_cliente_llego)

	# Detener el audio durante el reinicio.
	Events.intento_iniciado.connect(_detener_sonido)
	Events.apagon_iniciado.connect(_detener_sonido)

	print("[CLIENTE] Sonido de aparicion preparado.")


func _on_cliente_llego(
	indice: int,
	_ingredientes: Array,
	_posicion: int
) -> void:
	# Verificar que exista un archivo de audio.
	if stream == null:
		return

	# Reiniciar el sonido si ya estaba sonando.
	if playing:
		stop()

	# Reproducir desde el principio.
	play(0.0)

	print(
		"[CLIENTE] Aparece cliente ",
		indice + 1,
		". Gemido reproducido."
	)


func _detener_sonido() -> void:
	# Evitar que quede reproduciendose
	# al comenzar otro intento.
	if playing:
		stop()
