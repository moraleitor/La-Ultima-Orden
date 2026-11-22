extends Node3D
## El screamer vive en la oscuridad del fondo. Cuando se va la luz (apagón) corre
## hasta la mesa; con el amanecer o un intento nuevo se esconde otra vez.
## El modelo es una criatura estilo PS1 (assets/modelos/screamer) y se anima por código.

const FONDO := Vector3(0.0, 0.0, -14.0)
const FRENTE := Vector3(0.0, 0.0, -1.7)
const CORRIDA := 0.85     # s; llega antes de que la pantalla se ponga negra (1,4 s)
const FPS_PS1 := 12.0     # las poses cambian a saltos, como en los juegos de PS1

var _tween: Tween
var _corriendo := false
var _t := 0.0
var _paso := 0.0

@onready var _modelo: Node3D = $Modelo
@onready var _cuerpo: Node3D = _modelo.find_child("Cadera", true, false)
@onready var _cabeza: Node3D = _modelo.find_child("Cabeza", true, false)
@onready var _mandibula: Node3D = _modelo.find_child("Mandibula", true, false)
@onready var _hombros: Array[Node3D] = [_modelo.find_child("HombroIzq", true, false), _modelo.find_child("HombroDer", true, false)]
@onready var _codos: Array[Node3D] = [_modelo.find_child("CodoIzq", true, false), _modelo.find_child("CodoDer", true, false)]
@onready var _piernas: Array[Node3D] = [_modelo.find_child("CaderaIzq", true, false), _modelo.find_child("CaderaDer", true, false)]
var _mandibula_base := 0.0
var _hombros_base: Array[float] = []
var _piernas_base: Array[float] = []


func _ready() -> void:
	_preparar_material()
	_mandibula_base = _mandibula.rotation.x
	for h in _hombros:
		_hombros_base.append(h.rotation.x)
	for p in _piernas:
		_piernas_base.append(p.rotation.x)
	_esconder()
	Events.apagon_iniciado.connect(_on_apagon)
	Events.amanecer_iniciado.connect(_esconder)
	Events.intento_iniciado.connect(_esconder)


func _process(delta: float) -> void:
	if not visible:
		return
	_t += delta
	# Solo se actualiza la pose 12 veces por segundo.
	_paso += delta
	if _paso < 1.0 / FPS_PS1:
		return
	_paso = 0.0
	var vel := 16.0 if _corriendo else 5.0
	var s := sin(_t * vel)
	# Mandíbula que castañea, más abierta mientras corre.
	_mandibula.rotation.x = _mandibula_base + (0.25 if _corriendo else 0.1) * (0.5 + 0.5 * sin(_t * vel * 1.7))
	# Brazos y piernas.
	for i in 2:
		var fase := s if i == 0 else -s
		_hombros[i].rotation.x = _hombros_base[i] + fase * (0.9 if _corriendo else 0.15)
		_codos[i].rotation.x = -absf(fase) * (0.5 if _corriendo else 0.1)
		_piernas[i].rotation.x = _piernas_base[i] - fase * (0.7 if _corriendo else 0.05)
	# Cuerpo y cabeza: balanceo y tics.
	_cuerpo.position.y = 0.95 + (absf(s) * 0.07 if _corriendo else 0.0)
	_cabeza.rotation = Vector3(randf_range(-0.12, 0.12), randf_range(-0.25, 0.25), randf_range(-0.2, 0.2))


func _on_apagon() -> void:
	if _tween:
		_tween.kill()
	position = FONDO
	visible = true
	_corriendo = true
	_tween = create_tween()
	_tween.tween_property(self, "position", FRENTE, CORRIDA).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	_tween.tween_callback(func(): _corriendo = false)


func _esconder() -> void:
	if _tween:
		_tween.kill()
	_corriendo = false
	visible = false
	position = FONDO


func _preparar_material() -> void:
	# Textura sin suavizar y un brillo mínimo para que se distinga en la oscuridad.
	for m in _modelo.find_children("*", "MeshInstance3D", true, false):
		var mi := m as MeshInstance3D
		for i in mi.mesh.get_surface_count():
			var base := mi.mesh.surface_get_material(i)
			if base is StandardMaterial3D:
				var mat := (base as StandardMaterial3D).duplicate() as StandardMaterial3D
				mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
				mat.emission_enabled = true
				mat.emission_texture = mat.albedo_texture
				mat.emission_energy_multiplier = 0.35
				mi.set_surface_override_material(i, mat)
