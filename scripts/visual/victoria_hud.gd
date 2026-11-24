class_name VictoriaHud
extends CanvasLayer
## Pantalla de victoria al llegar las 6 AM con vida: la pantalla se oscurece, aparece
## "6:00 AM" y debajo "Sobreviviste la noche". Al terminar se invita a jugar otra vez (R).

const FUNDIDO := 1.2
const HORA_APARECE := 0.8           # s después de empezar el fundido
const SUBTITULO_APARECE := 2.2
const REINTENTO_APARECE := Config.AMANECER_SEGUNDOS

var _fondo: ColorRect
var _hora: Label
var _subtitulo: Label
var _reintento: Label
var _tween: Tween


func _ready() -> void:
	layer = 10                      # por encima de todo, incluido el apagón
	process_mode = Node.PROCESS_MODE_ALWAYS
	_fondo = ColorRect.new()
	_fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fondo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fondo.color = Color(0.0, 0.0, 0.0, 0.0)
	add_child(_fondo)
	_hora = _crear_texto("Hora", 64, Color(0.95, 0.92, 0.78), -60.0)
	_subtitulo = _crear_texto("Subtitulo", 24, Color(0.85, 0.82, 0.7), 22.0)
	_reintento = _crear_texto("Reintento", 16, Color(0.6, 0.58, 0.52), 120.0)
	_hora.text = "6:00 AM"
	_subtitulo.text = "Sobreviviste la noche"
	_reintento.text = "Presiona R para jugar otra vez"
	_ocultar()
	Events.amanecer_iniciado.connect(_mostrar)
	Events.intento_iniciado.connect(_ocultar)


func _crear_texto(nombre: String, tamano: int, color: Color, desplazamiento_y: float) -> Label:
	var l := Label.new()
	l.name = nombre
	l.set_anchors_preset(Control.PRESET_CENTER)
	l.anchor_left = 0.0
	l.anchor_right = 1.0
	l.anchor_top = 0.5
	l.anchor_bottom = 0.5
	l.offset_left = 0.0
	l.offset_right = 0.0
	l.offset_top = desplazamiento_y
	l.offset_bottom = desplazamiento_y + tamano + 14.0
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_size_override("font_size", tamano)
	l.add_theme_color_override("font_color", color)
	l.modulate.a = 0.0
	add_child(l)
	return l


func _ocultar() -> void:
	if _tween:
		_tween.kill()
	_fondo.color.a = 0.0
	for l in [_hora, _subtitulo, _reintento]:
		l.modulate.a = 0.0
	visible = false


func _mostrar() -> void:
	if _tween:
		_tween.kill()
	visible = true
	_tween = create_tween()
	_tween.tween_property(_fondo, "color:a", 1.0, FUNDIDO)
	_tween.parallel().tween_property(_hora, "modulate:a", 1.0, 1.0).set_delay(HORA_APARECE)
	_tween.parallel().tween_property(_subtitulo, "modulate:a", 1.0, 1.0).set_delay(SUBTITULO_APARECE)
	_tween.parallel().tween_property(_reintento, "modulate:a", 1.0, 0.8).set_delay(REINTENTO_APARECE)
