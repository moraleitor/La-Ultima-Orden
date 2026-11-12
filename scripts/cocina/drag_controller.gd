
class_name DragController
extends Node3D

## Controlador para seleccionar, arrastrar y soltar ingredientes.

var arrastrando: Ingrediente
var origen: Node3D
var bloqueado := false


func _ready() -> void:
	Events.entradas_bloqueadas.connect(
		func(b): bloqueado = b
	)


func _physics_process(_delta: float) -> void:
	if bloqueado:
		return

	if Input.is_action_just_pressed("seleccionar"):
		detectar_objeto()


func detectar_objeto() -> void:
	# Obtener la cámara activa del juego.
	var camara: Camera3D = get_viewport().get_camera_3d()

	if camara == null:
		push_warning("No se encontró una cámara activa.")
		return

	# Crear un rayo desde el centro de la cámara.
	var desde: Vector3 = camara.global_position
	var hasta: Vector3 = desde - camara.global_transform.basis.z * 4.0

	var consulta := PhysicsRayQueryParameters3D.create(
		desde,
		hasta
	)

	# Detectar objetos con colisiones.
	var resultado := get_world_3d().direct_space_state.intersect_ray(
		consulta
	)

	if not resultado.is_empty():
		var objeto := resultado["collider"] as CollisionObject3D

		if objeto != null:
			print("Objeto detectado: ", objeto.name)
	else:
		print("No se detectó ningún objeto.")


func _unhandled_input(event: InputEvent) -> void:
	if bloqueado:
		return

	if event.is_action_pressed("descartar"):
		pass  # Pendiente: descartar ingrediente.

	if event.is_action_released("seleccionar"):
		pass  # Pendiente: soltar ingrediente.
