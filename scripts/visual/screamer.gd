
extends Node3D

## SCREAMER CINEMATOGRAFICO - LA ULTIMA ORDEN
## Mantiene las animaciones originales estilo PS1.
## Obliga a mirar al monstruo durante el apagon.
## Hace zoom cuando esta lejos y oscurece los bordes.
## Restaura la camara y los controles al reiniciar.


# -----------------------------------------------
# MOVIMIENTO ORIGINAL
# -----------------------------------------------

const FONDO := Vector3(0.0, 0.0, -14.0)
const FRENTE := Vector3(0.0, 0.0, -0.9)

const CORRIDA := 1.4
const SALTO := 0.2
const MORDIDAS := 3
const FPS_PS1 := 12.0


# -----------------------------------------------
# CONFIGURACION DESDE EL INSPECTOR
# -----------------------------------------------

@export_category("Sonido")
@export var sonido_al_saltar: bool = false

@export_category("Camara de terror")
@export var forzar_mirada: bool = true

@export_range(30.0, 75.0, 1.0)
var zoom_lejano_grados: float = 44.0

@export_range(1.0, 25.0, 0.5)
var velocidad_enfoque: float = 12.0

@export_range(1.0, 20.0, 0.5)
var velocidad_zoom: float = 9.0

@export_category("Oscuridad")
@export_range(0.0, 1.0, 0.01)
var oscuridad_bordes: float = 0.88

@export_range(0.05, 0.5, 0.01)
var radio_visible: float = 0.23

@export_range(0.05, 0.6, 0.01)
var suavidad_bordes: float = 0.30


# -----------------------------------------------
# REFERENCIAS AL MONSTRUO
# -----------------------------------------------

@onready var _modelo: Node3D = $Modelo

@onready var _cuerpo: Node3D = _modelo.find_child(
	"Cadera", true, false
)

@onready var _cabeza: Node3D = _modelo.find_child(
	"Cabeza", true, false
)

@onready var _mandibula: Node3D = _modelo.find_child(
	"Mandibula", true, false
)

@onready var _hombros: Array[Node3D] = [
	_modelo.find_child("HombroIzq", true, false),
	_modelo.find_child("HombroDer", true, false)
]

@onready var _codos: Array[Node3D] = [
	_modelo.find_child("CodoIzq", true, false),
	_modelo.find_child("CodoDer", true, false)
]

@onready var _piernas: Array[Node3D] = [
	_modelo.find_child("CaderaIzq", true, false),
	_modelo.find_child("CaderaDer", true, false)
]

@onready var sonido_screamer: AudioStreamPlayer = (
	get_node_or_null("SonidoScreamer") as AudioStreamPlayer
)


# -----------------------------------------------
# ESTADOS DEL SCREAMER
# -----------------------------------------------

var _tween: Tween
var _tweens_golpes: Array[Tween] = []

var _corriendo := false
var _atacando := false

var _t := 0.0
var _paso := 0.0

var _apertura := 0.7
var _sacudida := 0.0

var _mandibula_base := 0.0
var _hombros_base: Array[float] = []
var _piernas_base: Array[float] = []


# -----------------------------------------------
# CAMARA Y EFECTOS
# -----------------------------------------------

var _camara: Camera3D
var _jugador: Node

var _camara_bloqueada := false
var _entrada_jugador_anterior := false

var _rotacion_camara_original := Vector3.ZERO
var _fov_original := 75.0
var _offset_h_original := 0.0
var _offset_v_original := 0.0

var _rojo: ColorRect
var _vineta: ColorRect
var _material_vineta: ShaderMaterial


# -----------------------------------------------
# INICIALIZACION
# -----------------------------------------------

func _ready() -> void:
	# Ejecutar el enfoque despues de otros procesos.
	process_priority = 100

	_preparar_material()

	_mandibula_base = _mandibula.rotation.x

	for h in _hombros:
		_hombros_base.append(h.rotation.x)

	for p in _piernas:
		_piernas_base.append(p.rotation.x)

	# Crear efectos visuales.
	var capa := CanvasLayer.new()
	capa.layer = 5
	add_child(capa)

	# Viento visual negro alrededor de la camara.
	_crear_vineta(capa)

	# Capa roja original de las mordidas.
	_rojo = ColorRect.new()
	capa.add_child(_rojo)

	_rojo.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

	_rojo.color = Color(0.6, 0.0, 0.02, 0.0)
	_rojo.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Preparar audio.
	if sonido_screamer == null:
		push_warning(
			"SCREAMER: falta SonidoScreamer."
		)
	elif sonido_screamer.stream == null:
		push_warning(
			"SCREAMER: falta asignar el MP3."
		)
	else:
		sonido_screamer.autoplay = false

	_esconder()

	# Señales ya existentes del proyecto.
	Events.apagon_iniciado.connect(_on_apagon)
	Events.amanecer_iniciado.connect(_esconder)
	Events.intento_iniciado.connect(_esconder)

	print("[SCREAMER] Sistema cinematografico listo.")


# -----------------------------------------------
# CREAR LA OSCURIDAD PERIFERICA
# -----------------------------------------------

func _crear_vineta(capa: CanvasLayer) -> void:
	_vineta = ColorRect.new()
	capa.add_child(_vineta)

	_vineta.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

	_vineta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vineta.color = Color.WHITE
	_vineta.visible = false

	# Crear el shader de oscurecimiento.
	var shader := Shader.new()

	shader.code = """
shader_type canvas_item;
render_mode unshaded;

uniform float fuerza = 0.0;
uniform float radio = 0.23;
uniform float suavidad = 0.30;
uniform float aspecto = 1.7777;

void fragment() {
	vec2 centro = vec2(0.5, 0.5);

	vec2 distancia_uv = UV - centro;
	distancia_uv.x *= aspecto;

	float distancia = length(distancia_uv);

	float borde = smoothstep(
		radio,
		radio + suavidad,
		distancia
	);

	COLOR = vec4(
		0.0,
		0.0,
		0.0,
		borde * fuerza
	);
}
"""

	_material_vineta = ShaderMaterial.new()
	_material_vineta.shader = shader

	_vineta.material = _material_vineta

	_material_vineta.set_shader_parameter(
		"fuerza", 0.0
	)

	_material_vineta.set_shader_parameter(
		"radio", radio_visible
	)

	_material_vineta.set_shader_parameter(
		"suavidad", suavidad_bordes
	)


# -----------------------------------------------
# ACTUALIZACION DEL PERSONAJE
# -----------------------------------------------

func _process(delta: float) -> void:
	if not visible:
		return

	_t += delta

	# La camara se actualiza suavemente cada frame.
	_actualizar_camara_terror(delta)
	_actualizar_vineta(delta)
	_agitar_camara()

	# Mantener animacion PS1 a 12 FPS.
	_paso += delta

	if _paso < 1.0 / FPS_PS1:
		return

	_paso = 0.0

	var vel := 22.0 if _atacando else (
		16.0 if _corriendo else 5.0
	)

	var s := sin(_t * vel)

	# Mandibula.
	if _atacando:
		_mandibula.rotation.x = lerpf(
			0.0, 1.35, _apertura
		)
	else:
		_mandibula.rotation.x = (
			_mandibula_base
			+ (0.25 if _corriendo else 0.1)
			* (0.5 + 0.5 * sin(_t * vel * 1.7))
		)

	# Brazos y piernas.
	for i in 2:
		var fase := s if i == 0 else -s

		_hombros[i].rotation.x = (
			_hombros_base[i]
			+ fase * (
				0.9 if (_corriendo or _atacando)
				else 0.15
			)
		)

		_codos[i].rotation.x = (
			-absf(fase)
			* (0.5 if _corriendo else 0.1)
		)

		_piernas[i].rotation.x = (
			_piernas_base[i]
			- fase * (
				0.7 if _corriendo else 0.05
			)
		)

	# Movimiento corporal.
	_cuerpo.position.y = (
		0.95
		+ (
			absf(s) * 0.07
			if _corriendo else 0.0
		)
	)

	# Movimientos bruscos de la cabeza.
	_cabeza.rotation = Vector3(
		randf_range(-0.12, 0.12),
		randf_range(-0.25, 0.25),
		randf_range(-0.2, 0.2)
	)


# -----------------------------------------------
# BLOQUEAR CAMARA Y MOVIMIENTO DEL MOUSE
# -----------------------------------------------

func _activar_camara_terror() -> void:
	_camara = get_viewport().get_camera_3d()

	if _camara == null:
		push_warning(
			"SCREAMER: no se encontro la camara."
		)
		return

	# Guardar los valores reales del jugador.
	_rotacion_camara_original = _camara.rotation
	_fov_original = _camara.fov

	_offset_h_original = _camara.h_offset
	_offset_v_original = _camara.v_offset

	# El jugador es hermano del Screamer en Main.
	_jugador = get_parent().get_node_or_null("Player")

	if forzar_mirada and _jugador != null:
		# Recordar si el Player procesaba el mouse.
		_entrada_jugador_anterior = (
			_jugador.is_processing_unhandled_input()
		)

		# Bloquear temporalmente su control del mouse.
		_jugador.set_process_unhandled_input(false)

	_camara_bloqueada = true

	# Mostrar el oscurecimiento.
	if _vineta != null:
		_vineta.visible = true

	print("[SCREAMER] Enfoque cinematografico activado.")


# -----------------------------------------------
# SEGUIMIENTO Y ZOOM DINAMICO
# -----------------------------------------------

func _actualizar_camara_terror(delta: float) -> void:
	if not _camara_bloqueada or _camara == null:
		return

	# Apuntar hacia la cabeza del monstruo.
	if forzar_mirada and _cabeza != null:
		var objetivo := (
			_cabeza.global_position
			+ Vector3(0.0, 0.08, 0.0)
		)

		# Evitar giros inestables al estar muy cerca.
		if _camara.global_position.distance_to(
			objetivo
		) > 0.18:

			var transform_deseada := (
				_camara.global_transform.looking_at(
					objetivo,
					Vector3.UP
				)
			)

			var rot_actual := (
				_camara.global_transform.basis
				.get_rotation_quaternion()
			)

			var rot_destino := (
				transform_deseada.basis
				.get_rotation_quaternion()
			)

			var suavizado := clampf(
				delta * velocidad_enfoque,
				0.0,
				1.0
			)

			var rot_nueva := rot_actual.slerp(
				rot_destino,
				suavizado
			)

			# Girar la camara sin mover al jugador.
			_camara.global_transform = Transform3D(
				Basis(rot_nueva),
				_camara.global_position
			)

	# Calcular avance de la carrera.
	var progreso := clampf(
		_t / CORRIDA,
		0.0,
		1.0
	)

	var fov_destino := _fov_original
	var zoom_lejano := minf(
		_fov_original,
		zoom_lejano_grados
	)

	if _corriendo:
		if progreso < 0.35:
			# Zoom rapido sobre el monstruo lejano.
			var entrada := smoothstep(
				0.0,
				0.35,
				progreso
			)

			fov_destino = lerpf(
				_fov_original,
				zoom_lejano,
				entrada
			)
		else:
			# Abrir el zoom al acercarse el monstruo.
			var salida := smoothstep(
				0.35,
				1.0,
				progreso
			)

			fov_destino = lerpf(
				zoom_lejano,
				_fov_original,
				salida
			)

	elif _atacando:
		# Ver la cara completa durante las mordidas.
		fov_destino = _fov_original

	_camara.fov = lerpf(
		_camara.fov,
		fov_destino,
		clampf(
			delta * velocidad_zoom,
			0.0,
			1.0
		)
	)


# -----------------------------------------------
# OSCURECER LOS BORDES DE LA PANTALLA
# -----------------------------------------------

func _actualizar_vineta(delta: float) -> void:
	if _material_vineta == null:
		return

	var progreso := clampf(
		_t / CORRIDA,
		0.0,
		1.0
	)

	# Oscuridad creciente durante la carrera.
	var fuerza_objetivo := (
		oscuridad_bordes
		* (0.65 + 0.35 * progreso)
	)

	if _atacando:
		fuerza_objetivo = oscuridad_bordes

	var fuerza_actual: float = (
		_material_vineta.get_shader_parameter(
			"fuerza"
		)
	)

	var fuerza_nueva := move_toward(
		fuerza_actual,
		fuerza_objetivo,
		delta * 2.5
	)

	_material_vineta.set_shader_parameter(
		"fuerza",
		fuerza_nueva
	)

	# Adaptar el circulo al tamaño de la pantalla.
	var pantalla := get_viewport().get_visible_rect().size

	if pantalla.y > 0.0:
		_material_vineta.set_shader_parameter(
			"aspecto",
			pantalla.x / pantalla.y
		)


# -----------------------------------------------
# REPRODUCCION DEL GRITO
# -----------------------------------------------

func _reproducir_grito() -> void:
	if sonido_screamer == null:
		push_warning(
			"[SCREAMER] Falta SonidoScreamer."
		)
		return

	if sonido_screamer.stream == null:
		push_warning(
			"[SCREAMER] No tiene audio asignado."
		)
		return

	sonido_screamer.stop()
	sonido_screamer.play(0.0)

	print("[SCREAMER] Grito iniciado.")


# -----------------------------------------------
# COMIENZA EL APAGON
# -----------------------------------------------

func _on_apagon() -> void:
	if _tween:
		_tween.kill()

	position = FONDO

	_corriendo = true
	_atacando = false

	_t = 0.0
	_paso = 0.0
	_sacudida = 0.0

	visible = true

	# Activar la camara antes de la carrera.
	_activar_camara_terror()

	if not sonido_al_saltar:
		_reproducir_grito()

	print("[SCREAMER] Apagon y enfoque iniciados.")

	_tween = create_tween()

	_tween.tween_property(
		self,
		"position",
		FRENTE,
		CORRIDA
	).set_trans(
		Tween.TRANS_CUBIC
	).set_ease(
		Tween.EASE_IN
	)

	_tween.tween_callback(_saltar_y_morder)


# -----------------------------------------------
# SALTO Y TRES MORDIDAS
# -----------------------------------------------

func _saltar_y_morder() -> void:
	_corriendo = false
	_atacando = true
	_apertura = 1.0

	if sonido_al_saltar:
		_reproducir_grito()

	var cam := get_viewport().get_camera_3d()
	var destino := position

	if cam:
		var boca := _cabeza.to_global(
			Vector3(0.0, -0.22, 0.42)
		)

		destino = (
			position
			+ (
				cam.global_position
				- cam.global_transform.basis.z * 0.32
				- boca
			)
		)

	_tween = create_tween()

	_tween.tween_property(
		self,
		"position",
		destino,
		SALTO
	).set_trans(
		Tween.TRANS_EXPO
	).set_ease(
		Tween.EASE_IN
	)

	for i in MORDIDAS:
		_tween.tween_property(
			self,
			"_apertura",
			0.0,
			0.08
		)

		_tween.tween_callback(_mordisco)

		if i < MORDIDAS - 1:
			_tween.tween_property(
				self,
				"_apertura",
				0.85,
				0.12
			)
		else:
			_tween.tween_interval(0.25)

	_tween.tween_property(
		_rojo,
		"color:a",
		0.0,
		0.15
	)


# -----------------------------------------------
# MORDIDAS Y SACUDIDA
# -----------------------------------------------

func _mordisco() -> void:
	_sacudida = 1.0
	_rojo.color.a = 0.55

	var tween_rojo := create_tween()

	tween_rojo.tween_property(
		_rojo,
		"color:a",
		0.25,
		0.1
	)

	var tween_sacudida := create_tween()

	tween_sacudida.tween_property(
		self,
		"_sacudida",
		0.35,
		0.2
	)

	_tweens_golpes.append(tween_rojo)
	_tweens_golpes.append(tween_sacudida)


func _agitar_camara() -> void:
	if _camara == null:
		return

	if _sacudida > 0.01:
		_camara.h_offset = (
			_offset_h_original
			+ randf_range(-1.0, 1.0)
			* _sacudida * 0.12
		)

		_camara.v_offset = (
			_offset_v_original
			+ randf_range(-1.0, 1.0)
			* _sacudida * 0.12
		)
	else:
		_camara.h_offset = _offset_h_original
		_camara.v_offset = _offset_v_original


# -----------------------------------------------
# RESTAURAR CAMARA Y CONTROLES
# -----------------------------------------------

func _restaurar_camara() -> void:
	if not _camara_bloqueada:
		return

	if _camara != null:
		_camara.rotation = _rotacion_camara_original
		_camara.fov = _fov_original

		_camara.h_offset = _offset_h_original
		_camara.v_offset = _offset_v_original

	# Recuperar el control del mouse.
	if forzar_mirada and _jugador != null:
		_jugador.set_process_unhandled_input(
			_entrada_jugador_anterior
		)

	if _material_vineta != null:
		_material_vineta.set_shader_parameter(
			"fuerza",
			0.0
		)

	if _vineta != null:
		_vineta.visible = false

	_camara_bloqueada = false

	print("[SCREAMER] Camara y controles restaurados.")



# LIMPIEZA DESPUES DEL SUSTO


func _esconder() -> void:
	if _tween:
		_tween.kill()

	# Detener tweens secundarios del ataque.
	for tween_golpe in _tweens_golpes:
		if tween_golpe.is_valid():
			tween_golpe.kill()

	_tweens_golpes.clear()

	if sonido_screamer != null:
		sonido_screamer.stop()

	_corriendo = false
	_atacando = false

	_sacudida = 0.0
	_apertura = 0.7

	_t = 0.0
	_paso = 0.0

	# Restaurar la vision antes de ocultar.
	_restaurar_camara()

	if _rojo != null:
		_rojo.color.a = 0.0

	visible = false
	position = FONDO



# MATERIAL ORIGINAL ESTILO PS1


func _preparar_material() -> void:
	for m in _modelo.find_children(
		"*",
		"MeshInstance3D",
		true,
		false
	):
		var mi := m as MeshInstance3D

		if mi.mesh == null:
			continue

		for i in mi.mesh.get_surface_count():
			var base := mi.mesh.surface_get_material(i)

			if base is StandardMaterial3D:
				var mat := (
					base as StandardMaterial3D
				).duplicate() as StandardMaterial3D

				mat.texture_filter = (
					BaseMaterial3D.TEXTURE_FILTER_NEAREST
				)

				mat.emission_enabled = true
				mat.emission_texture = mat.albedo_texture
				mat.emission_energy_multiplier = 0.35

				mi.set_surface_override_material(i, mat)
