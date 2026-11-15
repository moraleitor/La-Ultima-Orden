extends Label3D
## Indicador tipo cronómetro con barra de progreso, punto perfecto y estado quemado para la hornilla.

@onready var hornilla: Hornilla = get_parent() as Hornilla

func _ready() -> void:
	visible = false
	if hornilla == null:
		push_error("El indicador debe ser hijo directo del nodo Hornilla.")
		set_process(false)

func _process(_delta: float) -> void:
	var ing: Ingrediente = hornilla.ingrediente

	# Ocultar si la hornilla está vacía o el turno está bloqueado
	if not is_instance_valid(ing) or hornilla.bloqueada:
		visible = false
		return

	visible = true

	match ing.estado:
		Ingrediente.Estado.CORTADO:
			# Fase de cocción: muestra una barra estilo cronómetro y el tiempo restante
			var restante: float = maxf(Config.COCCION_SEGUNDOS - hornilla.tiempo, 0.0)
			text = "⏳ Cocinando\n[%s] %.1f s" % [_obtener_barra_progreso(hornilla.tiempo, Config.COCCION_SEGUNDOS), restante]
			modulate = Color("#FFD166") # Amarillo de proceso

		Ingrediente.Estado.COCIDO:
			# Fase de punto perfecto: el ingrediente está listo para llevar al plato con margen de seguridad
			var margen: float = maxf(Config.QUEMADO_SEGUNDOS - hornilla.tiempo, 0.0)
			text = "Perfecto \n%.1f s" % margen
			modulate = Color("9acd20ff")

		Ingrediente.Estado.QUEMADO:
			# Fase de error/quemado
			text = "🔥 ¡QUEMADO! 🔥"
			modulate = Color("fc644eff") # Rojo alerta

		_:
			visible = false

func _obtener_barra_progreso(actual: float, total: float) -> String:
	# Dibuja una barra de progreso en bloques tipo cronómetro (8 niveles)
	var total_bloques = 8
	var progreso = int(clampf((actual / total) * total_bloques, 0, total_bloques))
	var barra = ""
	for i in range(total_bloques):
		if i < progreso:
			barra += "■"
		else:
			barra += "□"
	return barra
