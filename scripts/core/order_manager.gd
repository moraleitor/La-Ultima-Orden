class_name OrderManager
extends Node
## Pedidos, llegadas, plazos y alerta (M1, M6, M7) y la comparación de entregas (M5).

enum EstadoPedido { ABIERTO, ENTREGADO, VENCIDO }

var t := 0.0                        # tiempo del turno (t = 0 al terminar la introducción)
var activo := false
var siguiente := 0                  # próxima llegada de la secuencia
var pedidos: Array[Dictionary] = []
var posiciones: Array[int] = []     # 4 posiciones de cliente; -1 = libre
var reacciones: Dictionary = {}     # indice -> segundos restantes de reacción


func _ready() -> void:
	Events.intento_iniciado.connect(_reiniciar)
	Events.turno_iniciado.connect(func(): activo = true)
	Events.apagon_iniciado.connect(func(): activo = false)
	Events.amanecer_iniciado.connect(func(): activo = false)
	Events.entrega_intentada.connect(_on_entrega_intentada)
	_reiniciar()


func _reiniciar() -> void:
	activo = false
	t = 0.0
	siguiente = 0
	pedidos.clear()
	reacciones.clear()
	posiciones.clear()
	for i in Config.POSICIONES_CLIENTE:
		posiciones.append(-1)


func _process(delta: float) -> void:
	if not activo:
		return
	t += delta
	# Orden de resolución (M11): vencimientos, luego entregas (llegan por señal), luego llegadas.
	_revisar_vencimientos_y_alertas()
	_avanzar_reacciones(delta)
	_procesar_llegadas()
	_revisar_fin()


func _procesar_llegadas() -> void:
	while siguiente < Config.LLEGADAS.size() and Config.LLEGADAS[siguiente] <= t:
		_llega_cliente(siguiente)
		siguiente += 1


func _llega_cliente(indice: int) -> void:
	var plazo := Config.PLAZO_PRIMEROS if indice < Config.CLIENTES_CON_PLAZO_LARGO else Config.PLAZO_RESTO
	var pos := posiciones.find(-1)
	if pos == -1:
		push_warning("No hay posición libre para el cliente %d (revisar M7)" % indice)
		pos = 0
	posiciones[pos] = indice
	pedidos.append({
		"indice": indice,
		"ingredientes": Config.PEDIDOS[indice],
		"llegada": t,
		"plazo": plazo,
		"estado": EstadoPedido.ABIERTO,
		"alerta": false,
	})
	Events.cliente_llego.emit(indice, Config.PEDIDOS[indice], pos)


func _revisar_vencimientos_y_alertas() -> void:
	for p in pedidos:
		if p.estado != EstadoPedido.ABIERTO:
			continue
		var restante: float = p.llegada + p.plazo - t
		if restante <= 0.0:
			_cerrar(p, false, true)
		else:
			Events.pedido_actualizado.emit(p.indice, restante)
			if restante <= Config.ALERTA_SEGUNDOS and not p.alerta:
				p.alerta = true
				Events.pedido_en_alerta.emit(p.indice)


func _on_entrega_intentada(indice: int, ingredientes: Array) -> void:
	var p := _buscar(indice)
	if p.is_empty() or p.estado != EstadoPedido.ABIERTO:
		return
	var restante: float = p.llegada + p.plazo - t
	if restante <= 0.0:
		_cerrar(p, false, true)     # entregar con 0 s restantes cuenta como tarde
		return
	var pedido_ordenado: Array = (p.ingredientes as Array).duplicate()
	var entrega_ordenada: Array = ingredientes.duplicate()
	pedido_ordenado.sort()
	entrega_ordenada.sort()
	_cerrar(p, pedido_ordenado == entrega_ordenada, false)


func _cerrar(p: Dictionary, correcto: bool, vencido: bool) -> void:
	# Un pedido se cierra una sola vez (M8).
	p.estado = EstadoPedido.VENCIDO if vencido else EstadoPedido.ENTREGADO
	if p.alerta:
		p.alerta = false
		Events.pedido_alerta_terminada.emit(p.indice)
	if vencido:
		Events.pedido_vencido.emit(p.indice)
	else:
		Events.pedido_entregado.emit(p.indice, correcto)
	reacciones[p.indice] = Config.REACCION_SEGUNDOS
	p["correcto"] = correcto


func _avanzar_reacciones(delta: float) -> void:
	for indice in reacciones.keys():
		reacciones[indice] -= delta
		if reacciones[indice] <= 0.0:
			reacciones.erase(indice)
			var pos := posiciones.find(indice)
			if pos != -1:
				posiciones[pos] = -1
			Events.reaccion_terminada.emit(indice, _buscar(indice).get("correcto", false))


func _revisar_fin() -> void:
	if siguiente < Config.LLEGADAS.size() or not reacciones.is_empty():
		return
	for p in pedidos:
		if p.estado == EstadoPedido.ABIERTO:
			return
	activo = false
	Events.todos_pedidos_cerrados.emit()


func _buscar(indice: int) -> Dictionary:
	for p in pedidos:
		if p.indice == indice:
			return p
	return {}
