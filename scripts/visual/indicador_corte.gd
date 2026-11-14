extends Label3D
## Indicador tipo cronómetro con barra de progreso para la tabla de corte.

@onready var tabla: Tabla = get_parent() as Tabla

func _ready() -> void:
	visible = false
	if tabla == null:
		push_error("El indicador debe ser hijo directo del nodo Tabla.")
		set_process(false)

func _process(_delta: float) -> void:
	var ing: Ingrediente = tabla.ingrediente

	# Ocultar si la tabla está vacía, bloqueada o el ingrediente ya no está crudo (ya se cortó)
	if not is_instance_valid(ing) or tabla.bloqueada or ing.estado != Ingrediente.Estado.CRUDO:
		visible = false
		return

	visible = true

	# Si hay progreso de corte activo (el jugador mantiene presionado el clic)
	if tabla.progreso > 0.0:
		var restante: float = maxf(Config.CORTE_SEGUNDOS - tabla.progreso, 0.0)
		text = "🔪Cortando\n[%s] %.1f s" % [_obtener_barra_progreso(tabla.progreso, Config.CORTE_SEGUNDOS), restante]
		modulate = Color("B8C2CC") 

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
