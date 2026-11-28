
extends AudioStreamPlayer

#Se reproduce cuando el jugador:
# 1-Entrega un pedido incorrecto.
# 2-Deja vencer un pedido.


func _ready() -> void:
	# El sonido no debe comenzar automaticamente.
	autoplay = false

	# Comprobar que el MP3 este asignado.
	if stream == null:
		push_warning(
			"[INSATISFACCION] Falta asignar el audio."
		)

	# Detectar entregas correctas e incorrectas.
	Events.pedido_entregado.connect(
		_on_pedido_entregado
	)

	# Detectar cuando se vence un pedido.
	Events.pedido_vencido.connect(
		_on_pedido_vencido
	)

	# Detener el sonido al reiniciar.
	Events.intento_iniciado.connect(
		_detener_sonido
	)

	# Detenerlo cuando comience el screamer.
	Events.apagon_iniciado.connect(
		_detener_sonido
	)

	print("[INSATISFACCION] Audio preparado.")


# CUANDO SE ENTREGA UN PEDIDO


func _on_pedido_entregado(
	indice: int,
	correcto: bool
) -> void:

	# Si el pedido es correcto, no sonar.
	if correcto:
		return

	print(
		"[INSATISFACCION] Pedido incorrecto: ",
		indice + 1
	)

	_reproducir_queja()



# CUANDO SE VENCE UN PEDIDO


func _on_pedido_vencido(indice: int) -> void:

	print(
		"[INSATISFACCION] Pedido vencido: ",
		indice + 1
	)

	_reproducir_queja()



# REPRODUCIR EL SONIDO


func _reproducir_queja() -> void:

	# Verificar que exista el audio.
	if stream == null:
		push_warning(
			"[INSATISFACCION] No hay MP3 asignado."
		)
		return

	# Evitar que se superponga consigo mismo.
	if playing:
		stop()

	# Reproducir desde el comienzo.
	play(0.0)

	print("[INSATISFACCION] Queja reproducida.")



# REINICIO Y APAGON


func _detener_sonido() -> void:
	if playing:
		stop()
