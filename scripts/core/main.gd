extends Node3D
## Arma los sistemas del núcleo y los conecta con la escena.
## Danna: tu escena va como hija de este nodo (o instanciada aquí).

func _ready() -> void:
	var tension := TensionSystem.new()
	tension.name = "TensionSystem"
	add_child(tension)

	var pedidos := OrderManager.new()
	pedidos.name = "OrderManager"
	add_child(pedidos)

	var luz := LightController.new()
	luz.name = "LightController"
	luz.luz = $WorkLight
	add_child(luz)

	var audio := AudioController.new()
	audio.name = "AudioController"
	add_child(audio)

	var juego := GameManager.new()
	juego.name = "GameManager"
	add_child(juego)
