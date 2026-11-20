class_name Hornilla
extends Node3D
## Hornilla (M4): un ingrediente cortado. Se cocina solo 7 s, queda listo 4 s más
## y se quema a los 11 s desde que entró.

## Recibe un ingrediente cortado y controla su cocción y salteado.

# Altura y centro del fondo interior de la sartén.
const FONDO_SARTEN := 0.094
const SEPARACION := 0.002
const CENTRO_SARTEN := Vector3(0.071, FONDO_SARTEN, 0.0)

var ingrediente: Ingrediente
var tiempo := 0.0
var _aviso_listo := false
var bloqueada := false

var _ingrediente_colocado: Ingrediente
var _burbujas: CPUParticles3D
var _humo: CPUParticles3D
var _sarten: Node3D
var _reposo_sarten: Vector3
var _reposo_ingrediente: Vector3


func _ready() -> void:
	Events.entradas_bloqueadas.connect(func(b): bloqueada = b)
	Events.intento_iniciado.connect(vaciar)

	_sarten = get_node_or_null("Sarten") as Node3D
	if _sarten:
		# Apoya la sartén sobre el quemador y deja visible el interior.
		_sarten.position.y += 0.023
		_reposo_sarten = _sarten.position
		var tapa := _sarten.find_child("pan frying pan lid", true, false) as Node3D
		if tapa:
			tapa.hide()

	_burbujas = _crear_particulas(Color(1.0, 0.79, 0.40), 16, 0.28, 0.007, 0.13)
	_humo = _crear_particulas(Color(0.28, 0.26, 0.24), 12, 0.75, 0.021, 0.20)


func recibir(ing: Ingrediente) -> bool:
	if bloqueada or ing == null:
		return false

	if ingrediente != null:
		return false

	if ing.estado != Ingrediente.Estado.CORTADO:
		return false

	ingrediente = ing
	tiempo = 0.0
	_aviso_listo = false

	ing.reparent(self, false)
	_colocar_en_sarten()
	_actualizar_particulas()

	print("Hornilla: comenzó la cocción de ", ing.nombre)
	return true


func _process(delta: float) -> void:
	if not is_instance_valid(ingrediente) or ingrediente.get_parent() != self:
		_detener_particulas()
		return

	# Vuelve a centrar el ingrediente si regresa de un arrastre fallido.
	if _ingrediente_colocado != ingrediente:
		_colocar_en_sarten()

	tiempo += delta

	if tiempo >= Config.COCCION_SEGUNDOS and ingrediente.estado == Ingrediente.Estado.CORTADO:
		ingrediente.set_estado(Ingrediente.Estado.COCIDO)
		_aplicar_color_cocido()
		Events.ingrediente_listo.emit(self)

		print(
			"Hornilla: ", ingrediente.nombre,
			" COCIDA a los ", snapped(tiempo, 0.1), " segundos."
		)

	if tiempo >= Config.QUEMADO_SEGUNDOS and ingrediente.estado == Ingrediente.Estado.COCIDO:
		ingrediente.set_estado(Ingrediente.Estado.QUEMADO)
		_teñir_ingrediente(Color(0.21, 0.20, 0.18))
		Events.ingrediente_quemado.emit(self)

		print(
			"Hornilla: ", ingrediente.nombre,
			" QUEMADA a los ", snapped(tiempo, 0.1), " segundos."
		)

	_mover_sarten()
	_actualizar_particulas()


func _colocar_en_sarten() -> void:
	ingrediente.position = Vector3.ZERO
	var limites := AABB()
	var hay_malla := false
	var a_hornilla := global_transform.affine_inverse()

	# Usa la malla visible para apoyar y centrar el ingrediente.
	for nodo in ingrediente.find_children("*", "MeshInstance3D", true, false):
		var visual := nodo as MeshInstance3D
		if visual.mesh == null or not visual.is_visible_in_tree():
			continue

		var caja := (a_hornilla * visual.global_transform) * visual.get_aabb()
		limites = limites.merge(caja) if hay_malla else caja
		hay_malla = true

	var centro_inferior := limites.get_center()
	centro_inferior.y = limites.position.y
	_reposo_ingrediente = CENTRO_SARTEN + Vector3.UP * SEPARACION - centro_inferior
	ingrediente.position = _reposo_ingrediente
	_ingrediente_colocado = ingrediente


func _mover_sarten() -> void:
	if not _sarten:
		return

	const INTERVALO := 1.25
	const DURACION := 0.48
	const ALTURA_SARTEN := 0.018
	const ALTURA_SALTO := 0.065

	var fase := fmod(tiempo, INTERVALO) / DURACION
	var desplazamiento := Vector3.ZERO
	var salto := 0.0

	if fase < 1.0 and ingrediente.estado != Ingrediente.Estado.QUEMADO:
		var impulso := sin(PI * fase)
		desplazamiento.z = sin(TAU * fase) * 0.022
		desplazamiento.y = impulso * ALTURA_SARTEN

		# La comida despega después del tirón y cae en el centro.
		var vuelo := clampf((fase - 0.15) / 0.75, 0.0, 1.0)
		salto = 4.0 * vuelo * (1.0 - vuelo) * ALTURA_SALTO

	_sarten.position = _reposo_sarten + desplazamiento
	ingrediente.position = _reposo_ingrediente + desplazamiento + Vector3.UP * salto
	_burbujas.position = CENTRO_SARTEN + Vector3.UP * 0.04 + desplazamiento
	_humo.position = _burbujas.position


func _aplicar_color_cocido() -> void:
	# El primer color tiñe el modelo con textura. El segundo pinta los trozos lisos.
	match ingrediente.nombre.to_lower():
		"zanahoria":
			_teñir_ingrediente(Color(1.0, 0.66, 0.35), Color("ff4019ff"))
		"cebolla":
			_teñir_ingrediente(Color(0.90, 0.76, 0.98), Color("9b6ba5ff"))
		"papa":
			_teñir_ingrediente(Color(1.0, 0.88, 0.65), Color("d7a82eff"))
		_:
			_teñir_ingrediente(Color(1.0, 0.66, 0.35))


func _teñir_ingrediente(tinte: Color, color_liso: Color = Color.TRANSPARENT) -> void:
	for nodo in ingrediente.find_children("*", "MeshInstance3D", true, false):
		var visual := nodo as MeshInstance3D
		if visual.mesh == null or not visual.is_visible_in_tree():
			continue

		# Cambia una copia del material para teñir solo este ingrediente.
		if visual.material_override is BaseMaterial3D:
			visual.material_override = _copiar_material_teñido(
				visual.material_override as BaseMaterial3D, tinte, color_liso
			)
			continue

		for superficie in visual.mesh.get_surface_count():
			var material := visual.get_active_material(superficie) as BaseMaterial3D
			if material:
				visual.set_surface_override_material(
					superficie, _copiar_material_teñido(material, tinte, color_liso)
				)


func _copiar_material_teñido(
	material: BaseMaterial3D, tinte: Color, color_liso: Color
) -> BaseMaterial3D:
	var copia := material.duplicate() as BaseMaterial3D

	if copia.albedo_texture == null and color_liso.a > 0.0:
		var opacidad := copia.albedo_color.a
		copia.albedo_color = Color(color_liso.r, color_liso.g, color_liso.b, opacidad)
	else:
		copia.albedo_color *= tinte

	return copia


func _crear_particulas(
	color: Color, cantidad: int, vida: float, tamano: float, velocidad: float
) -> CPUParticles3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	var malla := BoxMesh.new()
	malla.size = Vector3.ONE * tamano
	malla.material = material

	var efecto := CPUParticles3D.new()
	efecto.emitting = false
	efecto.mesh = malla
	efecto.amount = cantidad
	efecto.lifetime = vida
	efecto.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	efecto.emission_sphere_radius = 0.035
	efecto.direction = Vector3.UP
	efecto.spread = 20.0
	efecto.gravity = Vector3.ZERO
	efecto.initial_velocity_min = velocidad * 0.6
	efecto.initial_velocity_max = velocidad

	add_child(efecto)
	efecto.position = CENTRO_SARTEN + Vector3.UP * 0.04
	return efecto


func _actualizar_particulas() -> void:
	_burbujas.emitting = (
		ingrediente.estado == Ingrediente.Estado.CORTADO
		or ingrediente.estado == Ingrediente.Estado.COCIDO
	)
	_humo.emitting = ingrediente.estado == Ingrediente.Estado.QUEMADO


func _detener_particulas() -> void:
	if _sarten:
		_sarten.position = _reposo_sarten
	_burbujas.emitting = false
	_humo.emitting = false


func puede_retirar() -> bool:
	return ingrediente != null and tiempo >= Config.COCCION_SEGUNDOS


func retirar() -> Ingrediente:
	if not puede_retirar():
		return null

	var ing := ingrediente
	ingrediente = null
	_ingrediente_colocado = null
	tiempo = 0.0
	_detener_particulas()
	return ing


func vaciar() -> void:
	if is_instance_valid(ingrediente):
		ingrediente.queue_free()

	ingrediente = null
	_ingrediente_colocado = null
	tiempo = 0.0
	_aviso_listo = false
	_detener_particulas()
