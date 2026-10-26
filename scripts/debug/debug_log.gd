extends Node
## Opcional: arrástralo a la escena principal para ver en la consola qué pasa.

func _ready() -> void:
	Events.turno_iniciado.connect(func(): print("[turno] inicia"))
	Events.cliente_llego.connect(func(i, ing, pos): print("[cliente %d] llega en posición %d: %s" % [i, pos, ing]))
	Events.pedido_en_alerta.connect(func(i): print("[alerta] pedido %d" % i))
	Events.pedido_vencido.connect(func(i): print("[vencido] pedido %d" % i))
	Events.pedido_entregado.connect(func(i, ok): print("[entrega] pedido %d correcto=%s" % [i, ok]))
	Events.tension_cambio.connect(func(n): print("[tensión] %d" % n))
	Events.apagon_iniciado.connect(func(): print("[apagón]"))
	Events.amanecer_iniciado.connect(func(): print("[amanecer]"))
