class_name SelectorPapel
extends Node
## Gestiona los cuatro papeles por POSICION de cliente.
## La apariencia del papel sigue siendo responsabilidad visual de Danna.

var seleccionado: int = -1  # ID real del pedido, no posicion del papel.
var consultando := false
var ocupantes: Array[int] = []
var papeles: Array[PapelView] = []

@onready var controlador: DragController = get_parent().get_node("DragController") as DragController


func _ready() -> void:
	for posicion in range(Config.POSICIONES_CLIENTE):
		var papel := get_parent().get_node_or_null("Papel%d" % (posicion + 1)) as PapelView
		papeles.append(papel)

	Events.intento_iniciado.connect(_reiniciar)
	Events.cliente_llego.connect(_on_cliente_llego)
	Events.reaccion_terminada.connect(_on_reaccion_terminada)
	Events.entradas_bloqueadas.connect(_on_bloqueo)
	_reiniciar()


func _reiniciar() -> void:
	_finalizar_consulta()
	seleccionado = -1
	ocupantes.clear()
	for posicion in range(Config.POSICIONES_CLIENTE):
		ocupantes.append(-1)
		if papeles[posicion] != null:
			papeles[posicion].indice = -1
	print("Gabriela: papeles reiniciados.")


func _on_cliente_llego(indice: int, _ingredientes: Array, posicion: int) -> void:
	if posicion < 0 or posicion >= ocupantes.size():
		return
	ocupantes[posicion] = indice
	if papeles[posicion] != null:
		papeles[posicion].indice = indice
	print("Gabriela: papel ", posicion + 1, " asignado al pedido ", indice + 1)


func _on_reaccion_terminada(indice: int, _correcto: bool) -> void:
	var posicion := ocupantes.find(indice)
	if posicion == -1:
		return
	ocupantes[posicion] = -1
	if papeles[posicion] != null:
		papeles[posicion].indice = -1
	if seleccionado == indice:
		_finalizar_consulta()
		seleccionado = -1


func seleccionar_papel(papel: PapelView) -> void:
	if consultando:
		return
	var posicion := papeles.find(papel)
	if posicion == -1:
		return
	var indice := ocupantes[posicion]
	if indice < 0:
		print("Gabriela: el papel ", posicion + 1, " aun no tiene cliente.")
		return

	seleccionado = indice
	Events.pedido_seleccionado.emit(indice)
	print("Gabriela: seleccionaste papel ", posicion + 1, " del pedido ", indice + 1)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("consultar") and not consultando:
		if seleccionado < 0:
			return
		# No permitir que Espacio interrumpa un arrastre de comida o plato.
		if controlador.arrastrando != null or controlador.arrastrando_plato:
			return
		consultando = true
		Events.consulta_papel.emit(seleccionado, true)
		print("Gabriela: CONSULTANDO pedido ", seleccionado + 1, ": ", Config.PEDIDOS[seleccionado])
	elif event.is_action_released("consultar"):
		_finalizar_consulta()


func _finalizar_consulta() -> void:
	if not consultando:
		return
	consultando = false
	Events.consulta_papel.emit(seleccionado, false)
	print("Gabriela: consulta terminada.")


func _on_bloqueo(valor: bool) -> void:
	if valor:
		_finalizar_consulta()


func puede_manipular_comida() -> bool:
	return not consultando
