class_name RelojHud
extends CanvasLayer
## Reloj del turno arriba a la derecha (los corazones van arriba a la izquierda).
## Avanza de 8:00 PM a 6:00 AM mientras dura el turno; el progreso lo manda GameManager.

const MARGEN := Vector2(14.0, 10.0)
const TAMANO := 26
const PASO_MINUTOS := 10            # la hora avanza de 10 en 10, como un reloj de pared

var _texto: Label
var _ultima := ""


func _ready() -> void:
	layer = 0                       # debajo del tinte, el flash y la pantalla del apagón
	process_mode = Node.PROCESS_MODE_ALWAYS
	_texto = Label.new()
	_texto.name = "Hora"
	_texto.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_texto.offset_left = -190.0 - MARGEN.x
	_texto.offset_right = -MARGEN.x
	_texto.offset_top = MARGEN.y
	_texto.offset_bottom = MARGEN.y + 40.0
	_texto.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_texto.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_texto.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_texto.add_theme_font_size_override("font_size", TAMANO)
	_texto.add_theme_color_override("font_color", Color(0.93, 0.9, 0.78))
	_texto.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0))
	_texto.add_theme_constant_override("outline_size", 6)
	add_child(_texto)
	_poner(0.0)
	Events.reloj_cambio.connect(_poner)
	Events.intento_iniciado.connect(func(): _poner(0.0))


func _poner(progreso: float) -> void:
	var texto := formatear(progreso)
	if texto == _ultima:
		return
	_ultima = texto
	_texto.text = texto


## Convierte el progreso del turno (0 a 1) en una hora como "11:40 PM".
static func formatear(progreso: float) -> String:
	var minutos_turno := int(clampf(progreso, 0.0, 1.0) * Config.HORAS_TURNO * 60.0)
	minutos_turno = minutos_turno / PASO_MINUTOS * PASO_MINUTOS
	var total := Config.HORA_INICIO * 60 + minutos_turno
	var hora24 := (total / 60) % 24
	var minuto := total % 60
	var sufijo := "PM" if hora24 >= 12 else "AM"
	var hora12 := hora24 % 12
	if hora12 == 0:
		hora12 = 12
	return "%d:%02d %s" % [hora12, minuto, sufijo]
