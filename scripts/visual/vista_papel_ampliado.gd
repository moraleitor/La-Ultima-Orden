extends Panel
## Muestra la hoja de comanda física acercándose al centro de la pantalla al mantener Espacio.

@onready var fondo: ColorRect = $FondoHoja
@onready var borde: ReferenceRect = $FondoHoja/BordeSucio
@onready var titulo_label: Label = $FondoHoja/TituloOrden
@onready var contenedor: VBoxContainer = $FondoHoja/ContenedorIngredientes

var _consultando := false
var _tiempo := 0.0
var _pos_objetivo := Vector2.ZERO
var _pos_oculta := Vector2.ZERO
var _rotacion_objetivo := 0.0
var _indice_actual := -1
var _en_alerta := {}
var _color_borde_base: Color


func _ready() -> void:
	visible = false
	clip_contents = true
	custom_minimum_size = Vector2(140, 155)
	size = Vector2(140, 155)
	pivot_offset = size * 0.5

	if fondo != null:
		fondo.position = Vector2.ZERO
		fondo.size = size
		fondo.color = Color("#E8E1CF")

	if borde != null:
		borde.position = Vector2.ZERO
		borde.size = size
		borde.pivot_offset = size * 0.5
		borde.editor_only = false
		# Conserva el color exacto que configuraste en el Inspector
		_color_borde_base = borde.border_color

	if titulo_label != null:
		titulo_label.position = Vector2(6, 6)
		titulo_label.size = Vector2(size.x - 12, 18)
		titulo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		titulo_label.add_theme_font_size_override("font_size", 11)
		titulo_label.add_theme_color_override("font_color", Color("#14161C"))
		# Contorno del mismo color de tinta para engrosar el trazo
		titulo_label.add_theme_color_override("font_outline_color", Color("#14161C"))
		titulo_label.add_theme_constant_override("outline_size", 1)

	if contenedor != null:
		contenedor.position = Vector2(8, 26)
		contenedor.size = Vector2(size.x - 16, size.y - 32)
		contenedor.alignment = BoxContainer.ALIGNMENT_CENTER
		contenedor.add_theme_constant_override("separation", 4)

	Events.consulta_papel.connect(_on_consulta_papel)
	Events.pedido_en_alerta.connect(_on_pedido_en_alerta)
	Events.pedido_alerta_terminada.connect(_on_pedido_alerta_terminada)
	Events.intento_iniciado.connect(_ocultar_inmediato)
	Events.entradas_bloqueadas.connect(_on_bloqueo)


func _on_pedido_en_alerta(i: int) -> void:
	_en_alerta[i] = true
	_actualizar_borde()


func _on_pedido_alerta_terminada(i: int) -> void:
	_en_alerta.erase(i)
	_actualizar_borde()


func _actualizar_borde() -> void:
	if borde == null:
		return
	if _en_alerta.has(_indice_actual):
		borde.border_color = Color("#B3362F")
	else:
		borde.border_color = _color_borde_base


func _calcular_posiciones() -> void:
	var pantalla := get_viewport_rect().size
	_pos_objetivo = Vector2((pantalla.x - size.x) * 0.5, (pantalla.y - size.y) * 0.5)
	_pos_oculta = Vector2(_pos_objetivo.x, pantalla.y + 20.0)


func _on_consulta_papel(indice: int, activo: bool) -> void:
	if not activo or indice < 0 or indice >= Config.PEDIDOS.size():
		_consultando = false
		return

	_calcular_posiciones()
	_consultando = true
	_indice_actual = indice
	_actualizar_borde()
	visible = true

	position = _pos_oculta
	_rotacion_objetivo = randf_range(-2.5, 2.5)
	rotation_degrees = _rotacion_objetivo * 2.0

	if titulo_label != null:
		titulo_label.text = "╪ ORDEN #%02d ╪" % (indice + 1)

	if contenedor != null:
		for hijo in contenedor.get_children():
			hijo.queue_free()

		var ingredientes: Array = Config.PEDIDOS[indice]
		var es_doble := ingredientes.size() > 1
		for ing in ingredientes:
			var tarjeta := _crear_tarjeta_ingrediente(str(ing), es_doble)
			contenedor.add_child(tarjeta)


func _crear_tarjeta_ingrediente(nombre_ing: String, compacto: bool) -> VBoxContainer:
	var caja := VBoxContainer.new()
	caja.alignment = BoxContainer.ALIGNMENT_CENTER
	caja.add_theme_constant_override("separation", 2)
	caja.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var alto_dibujo := 38 if compacto else 64
	var icono := _VectorIngrediente.new(nombre_ing.to_lower())
	icono.custom_minimum_size = Vector2(110, alto_dibujo)
	icono.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	caja.add_child(icono)

	var lbl := Label.new()
	lbl.text = "~ %s ~" % nombre_ing.to_upper()
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 10 if compacto else 12)
	lbl.add_theme_color_override("font_color", Color("#14161C"))
	# Engrosa la letra dándole cuerpo tipo sello impreso
	lbl.add_theme_color_override("font_outline_color", Color("#14161C"))
	lbl.add_theme_constant_override("outline_size", 1)
	caja.add_child(lbl)

	return caja


func _process(delta: float) -> void:
	if not visible:
		return

	_tiempo += delta

	if _consultando:
		position = position.lerp(_pos_objetivo, minf(1.0, delta * 18.0))
		var temblor_x := sin(_tiempo * 14.0) * 0.6
		var temblor_y := cos(_tiempo * 11.0) * 0.6
		position += Vector2(temblor_x, temblor_y) * delta * 8.0
		rotation_degrees = lerpf(rotation_degrees, _rotacion_objetivo, minf(1.0, delta * 15.0))

		# Efecto de movimiento independiente en el borde
		if borde != null:
			var b_x := cos(_tiempo * 13.0) * 0.65
			var b_y := sin(_tiempo * 15.0) * 0.65
			borde.position = Vector2(b_x, b_y)
			borde.rotation_degrees = sin(_tiempo * 10.0) * 0.45
	else:
		position = position.lerp(_pos_oculta, minf(1.0, delta * 22.0))
		if borde != null:
			borde.position = borde.position.lerp(Vector2.ZERO, minf(1.0, delta * 22.0))
			borde.rotation_degrees = lerpf(borde.rotation_degrees, 0.0, minf(1.0, delta * 22.0))
		if position.y >= _pos_oculta.y - 8.0:
			visible = false


func _ocultar_inmediato() -> void:
	_consultando = false
	_en_alerta.clear()
	visible = false


func _on_bloqueo(bloqueado: bool) -> void:
	if bloqueado:
		_ocultar_inmediato()


class _VectorIngrediente extends Control:
	var tipo: String

	func _init(p_tipo: String) -> void:
		tipo = p_tipo

	func _draw() -> void:
		var c := size * 0.5
		var s := minf(size.x, size.y) / 64.0
		var tinta := Color("#14161C")

		draw_arc(c, 26.0 * s, 0.0, TAU, 32, Color("#14161C", 0.18), 1.0, true)

		if "papa" in tipo:
			var cuerpo := PackedVector2Array([
				c + Vector2(-22, -4) * s, c + Vector2(-16, -15) * s,
				c + Vector2(2, -17) * s, c + Vector2(20, -10) * s,
				c + Vector2(24, 3) * s, c + Vector2(14, 15) * s,
				c + Vector2(-6, 16) * s, c + Vector2(-20, 9) * s
			])
			draw_colored_polygon(cuerpo, Color("#C9A86A"))
			var contorno := cuerpo.duplicate()
			contorno.append(cuerpo[0])
			draw_polyline(contorno, tinta, 1.8, true)
			draw_arc(c + Vector2(-8, -4) * s, 2.2 * s, 0.2, 2.8, 8, tinta, 1.3, true)
			draw_arc(c + Vector2(9, 4) * s, 2.5 * s, 3.3, 6.0, 8, tinta, 1.3, true)
			draw_circle(c + Vector2(3, -8) * s, 1.2 * s, tinta)
			draw_circle(c + Vector2(-5, 8) * s, 1.2 * s, tinta)

		elif "zanahoria" in tipo:
			var hojas := PackedVector2Array([
				c + Vector2(8, -10) * s, c + Vector2(16, -25) * s,
				c + Vector2(21, -20) * s, c + Vector2(14, -9) * s,
				c + Vector2(26, -13) * s, c + Vector2(24, -7) * s,
				c + Vector2(11, -5) * s
			])
			draw_colored_polygon(hojas, Color("#8FB38A"))
			var cont_hojas := hojas.duplicate()
			cont_hojas.append(hojas[0])
			draw_polyline(cont_hojas, tinta, 1.4, true)

			var zanahoria := PackedVector2Array([
				c + Vector2(4, -14) * s, c + Vector2(15, -3) * s,
				c + Vector2(2, 12) * s, c + Vector2(-20, 22) * s,
				c + Vector2(-22, 19) * s, c + Vector2(-10, -2) * s
			])
			draw_colored_polygon(zanahoria, Color("#C8643B"))
			var cont_z := zanahoria.duplicate()
			cont_z.append(zanahoria[0])
			draw_polyline(cont_z, tinta, 1.8, true)

			draw_line(c + Vector2(1, -7) * s, c + Vector2(7, -1) * s, tinta, 1.3, true)
			draw_line(c + Vector2(-6, 2) * s, c + Vector2(-1, 7) * s, tinta, 1.3, true)
			draw_line(c + Vector2(-13, 11) * s, c + Vector2(-10, 14) * s, tinta, 1.2, true)

		elif "cebolla" in tipo:
			var bulbo := PackedVector2Array([
				c + Vector2(0, -24) * s, c + Vector2(5, -14) * s,
				c + Vector2(17, -6) * s, c + Vector2(19, 8) * s,
				c + Vector2(10, 18) * s, c + Vector2(0, 20) * s,
				c + Vector2(-10, 18) * s, c + Vector2(-19, 8) * s,
				c + Vector2(-17, -6) * s, c + Vector2(-5, -14) * s
			])
			draw_colored_polygon(bulbo, Color("#B98B9E"))
			var cont_c := bulbo.duplicate()
			cont_c.append(bulbo[0])
			draw_polyline(cont_c, tinta, 1.8, true)

			# Brillo sutil en el costado izquierdo para dar volumen
			draw_arc(c + Vector2(-1, 2) * s, 11.0 * s, PI + 0.35, PI + 1.05, 10, Color("#EAD4DD"), 1.5, true)

			# Raíces inferiores
			draw_line(c + Vector2(-4, 20) * s, c + Vector2(-6, 25) * s, tinta, 1.2, true)
			draw_line(c + Vector2(0, 20) * s, c + Vector2(0, 26) * s, tinta, 1.2, true)
			draw_line(c + Vector2(4, 20) * s, c + Vector2(6, 25) * s, tinta, 1.2, true)
