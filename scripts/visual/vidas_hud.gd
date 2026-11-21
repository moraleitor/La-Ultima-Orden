class_name VidasHud
extends CanvasLayer
## Tres corazones arriba a la izquierda. Cada error rompe uno (tiembla, se parte en dos y
## desaparece). Si se recupera una vida, el corazón vuelve a aparecer.
## La tensión sigue siendo la fuente: vidas = VIDAS_MAX - tensión.

const TEXTURA := preload("res://assets/ui/corazon.png")
const ALTO := 44.0                  # px en la pantalla de 640 x 360
const SEPARACION := 10.0
const MARGEN := Vector2(14.0, 12.0)
const TEMBLOR_SEGUNDOS := 0.35
const CAIDA_SEGUNDOS := 0.75

var _slots: Array[Control] = []
var _vivo: Array[bool] = []
var _tween: Dictionary = {}         # indice -> Tween en curso
var _ancho: float


func _ready() -> void:
	layer = 0                       # debajo del tinte, el flash y la pantalla del apagón
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ancho = ALTO * TEXTURA.get_width() / TEXTURA.get_height()
	for i in Config.VIDAS_MAX:
		var slot := Control.new()
		slot.name = "Corazon%d" % (i + 1)
		slot.position = MARGEN + Vector2(i * (_ancho + SEPARACION), 0.0)
		slot.size = Vector2(_ancho, ALTO)
		slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(slot)
		slot.add_child(_crear_pieza(Rect2(Vector2.ZERO, TEXTURA.get_size()), Vector2(_ancho, ALTO), Vector2.ZERO, "Entero"))
		_slots.append(slot)
		_vivo.append(true)
	Events.vidas_cambio.connect(_on_vidas)


func _on_vidas(vidas: int, _perdida: bool) -> void:
	for i in _slots.size():
		var debe_vivir := i < vidas
		if debe_vivir == _vivo[i]:
			continue
		_vivo[i] = debe_vivir
		if debe_vivir:
			_aparecer(i)
		else:
			_romper(i)


func _crear_pieza(region: Rect2, tam: Vector2, pos: Vector2, nombre: String) -> TextureRect:
	var atlas := AtlasTexture.new()
	atlas.atlas = TEXTURA
	atlas.region = region
	var t := TextureRect.new()
	t.name = nombre
	t.texture = atlas
	t.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_SCALE
	t.position = pos
	t.size = tam
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return t


func _nuevo_tween(i: int) -> Tween:
	if _tween.has(i) and _tween[i] != null:
		(_tween[i] as Tween).kill()
	var tw := create_tween()
	_tween[i] = tw
	return tw


func _limpiar_trozos(slot: Control) -> void:
	for hijo in slot.get_children():
		if hijo.name != "Entero":
			hijo.queue_free()


func _romper(i: int) -> void:
	var slot := _slots[i]
	var entero := slot.get_node("Entero") as TextureRect
	_limpiar_trozos(slot)
	entero.visible = true
	entero.modulate = Color.WHITE
	entero.scale = Vector2.ONE
	entero.pivot_offset = entero.size / 2.0
	var base := slot.position
	var tw := _nuevo_tween(i)
	# 1. Tiembla y se pone al rojo vivo.
	tw.set_parallel(true)
	tw.tween_method(func(t: float):
		slot.position = base + Vector2(sin(t * 90.0) * 3.0 * (1.0 - t), cos(t * 70.0) * 2.0 * (1.0 - t))
		entero.modulate = Color.WHITE.lerp(Color(1.9, 0.5, 0.5), t),
		0.0, 1.0, TEMBLOR_SEGUNDOS)
	tw.chain().tween_callback(func():
		slot.position = base
		_partir(slot, entero, i))


func _partir(slot: Control, entero: TextureRect, i: int) -> void:
	entero.visible = false
	var mitad := TEXTURA.get_width() / 2.0
	var alto_t := float(TEXTURA.get_height())
	var izq := _crear_pieza(Rect2(0, 0, mitad, alto_t), Vector2(_ancho / 2.0, ALTO), Vector2.ZERO, "MitadIzq")
	var der := _crear_pieza(Rect2(mitad, 0, mitad, alto_t), Vector2(_ancho / 2.0, ALTO), Vector2(_ancho / 2.0, 0.0), "MitadDer")
	izq.pivot_offset = Vector2(_ancho / 2.0, ALTO * 0.3)     # giran sobre el corte, arriba
	der.pivot_offset = Vector2(0.0, ALTO * 0.3)
	slot.add_child(izq)
	slot.add_child(der)
	var tw := _nuevo_tween(i)
	tw.set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(izq, "rotation", deg_to_rad(-38.0), CAIDA_SEGUNDOS)
	tw.tween_property(der, "rotation", deg_to_rad(38.0), CAIDA_SEGUNDOS)
	tw.tween_property(izq, "position", izq.position + Vector2(-9.0, 46.0), CAIDA_SEGUNDOS)
	tw.tween_property(der, "position", der.position + Vector2(9.0, 52.0), CAIDA_SEGUNDOS)
	tw.tween_property(izq, "modulate:a", 0.0, CAIDA_SEGUNDOS)
	tw.tween_property(der, "modulate:a", 0.0, CAIDA_SEGUNDOS)
	tw.chain().tween_callback(func(): _limpiar_trozos(slot))


func _aparecer(i: int) -> void:
	var slot := _slots[i]
	_limpiar_trozos(slot)
	slot.position = MARGEN + Vector2(i * (_ancho + SEPARACION), 0.0)
	var entero := slot.get_node("Entero") as TextureRect
	entero.visible = true
	entero.pivot_offset = entero.size / 2.0
	entero.scale = Vector2(0.4, 0.4)
	entero.modulate = Color(1, 1, 1, 0)
	var tw := _nuevo_tween(i)
	tw.set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(entero, "scale", Vector2.ONE, 0.4)
	tw.tween_property(entero, "modulate", Color.WHITE, 0.4)
