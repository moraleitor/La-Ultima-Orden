
class_name Disparador
extends Area3D

#Detecta alertas de los pedidos y de la cocina.
#No usa teclas ni necesita colisiones físicas.
#No modifica la tensión global del juego.

signal evento(posicion: Vector3, cantidad: int, motivo: String)

const UMBRALES := [0.50, 0.60, 0.80]

@export var destellos_por_umbral: int = 3
@export var avisar_errores: bool = true
@export var avisar_quemados: bool = true

var _turno_activo := false
var _pedidos: Dictionary = {}


func _ready() -> void:
	# Este disparador funciona mediante señales.
	monitoring = false
	monitorable = false

	# Conectar los eventos que ya existen en el proyecto.
	Events.intento_iniciado.connect(_reiniciar)
	Events.turno_iniciado.connect(_iniciar_turno)
	Events.apagon_iniciado.connect(_detener_turno)
	Events.amanecer_iniciado.connect(_detener_turno)

	Events.cliente_llego.connect(_cliente_llego)
	Events.pedido_actualizado.connect(_pedido_actualizado)
	Events.pedido_entregado.connect(_pedido_entregado)
	Events.pedido_vencido.connect(_pedido_vencido)
	Events.ingrediente_quemado.connect(_ingrediente_quemado)

	print("Disparador preparado.")


func _reiniciar() -> void:
	# Borrar el seguimiento de los pedidos anteriores.
	_turno_activo = false
	_pedidos.clear()

	print("Disparador reiniciado.")


func _iniciar_turno() -> void:
	_turno_activo = true


func _detener_turno() -> void:
	_turno_activo = false


func _cliente_llego(
	indice: int,
	_ingredientes: Array,
	posicion: int
) -> void:
	if not _turno_activo:
		return

	# Utilizar los plazos oficiales del proyecto.
	var plazo: float = Config.PLAZO_RESTO

	if indice < Config.CLIENTES_CON_PLAZO_LARGO:
		plazo = Config.PLAZO_PRIMEROS

	# Cada cliente guarda sus propias alertas.
	_pedidos[indice] = {
		"plazo": plazo,
		"posicion": posicion,
		"avisos": []
	}

	print("Seguimiento del cliente ", indice + 1)


func _pedido_actualizado(indice: int, restante: float) -> void:
	if not _turno_activo:
		return

	if not _pedidos.has(indice):
		return

	var datos: Dictionary = _pedidos[indice]
	var plazo: float = float(datos["plazo"])

	# Porcentaje del tiempo que ya consumió el cliente.
	var progreso := clampf(
		1.0 - restante / plazo,
		0.0,
		1.0
	)

	var avisos: Array = datos["avisos"]

	for umbral in UMBRALES:
		# Cada umbral se activa una sola vez por pedido.
		if progreso >= umbral and not avisos.has(umbral):
			avisos.append(umbral)

			var porcentaje := int(umbral * 100.0)
			var motivo := "Cliente %d alcanzo %d%%" % [
				indice + 1,
				porcentaje
			]

			var punto := _ubicacion_cliente(
				int(datos["posicion"])
			)

			_enviar_alerta(
				punto,
				destellos_por_umbral,
				motivo
			)


func _pedido_entregado(indice: int, correcto: bool) -> void:
	if not _turno_activo:
		return

	if not _pedidos.has(indice):
		return

	var datos: Dictionary = _pedidos[indice]

	if not correcto and avisar_errores:
		_enviar_alerta(
			_ubicacion_cliente(int(datos["posicion"])),
			1,
			"Pedido incorrecto"
		)

	_pedidos.erase(indice)


func _pedido_vencido(indice: int) -> void:
	if not _turno_activo:
		return

	if not _pedidos.has(indice):
		return

	var datos: Dictionary = _pedidos[indice]

	if avisar_errores:
		_enviar_alerta(
			_ubicacion_cliente(int(datos["posicion"])),
			1,
			"Pedido vencido"
		)

	_pedidos.erase(indice)


func _ingrediente_quemado(estacion: Node) -> void:
	if not _turno_activo or not avisar_quemados:
		return

	var punto: Vector3 = global_position

	if estacion is Node3D:
		punto = (estacion as Node3D).global_position

	_enviar_alerta(punto, 1, "Ingrediente quemado")


func _ubicacion_cliente(posicion: int) -> Vector3:
	# Los clientes son hijos directos de Main.
	var nombre := "Cliente%d" % (posicion + 1)
	var cliente := get_parent().get_node_or_null(nombre) as Node3D

	if cliente != null:
		return cliente.global_position

	# Si no se encuentra al cliente, usar la posición
	# del propio Disparador.
	return global_position


func _enviar_alerta(
	punto: Vector3,
	cantidad: int,
	motivo: String
) -> void:
	if not _turno_activo:
		return

	print(
		"[DISPARADOR] ",
		motivo,
		" | Destellos: ",
		cantidad
	)

	evento.emit(punto, cantidad, motivo)
