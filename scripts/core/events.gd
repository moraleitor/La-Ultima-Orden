extends Node
## Bus de señales: el contrato entre los tres sistemas.
## Regla del equipo: si necesitas una señal nueva, se agrega aquí y se avisa en el grupo.
## Cada quien emite SOLO las señales de su área y escucha las de las demás.

# --- Flujo del turno (Felipe) ---
signal intento_iniciado                       # se reinició todo; limpiar estado
signal turno_iniciado                         # termina la introducción; t = 0
signal apagon_iniciado                        # tensión llegó a 3
signal amanecer_iniciado                      # victoria
signal pausa_cambiada(en_pausa: bool)
signal entradas_bloqueadas(bloqueadas: bool)  # durante apagón y amanecer

# --- Pedidos (Felipe) ---
signal cliente_llego(indice: int, ingredientes: Array, posicion: int)
signal pedido_actualizado(indice: int, restante: float)   # cada frame, por pedido abierto
signal pedido_en_alerta(indice: int)
signal pedido_alerta_terminada(indice: int)
signal pedido_vencido(indice: int)
signal pedido_entregado(indice: int, correcto: bool)
signal reaccion_terminada(indice: int, correcto: bool)
signal todos_pedidos_cerrados

# --- Tensión y luz (Felipe) ---
signal tension_cambio(nivel: int)
signal racha_cambio(racha: int)
signal luz_recuperada

# --- Cocina (Gabriela) ---
signal pedido_seleccionado(indice: int)
signal consulta_papel(indice: int, activa: bool)          # Espacio presionado o soltado
signal entrega_intentada(indice: int, ingredientes: Array) # Gabriela -> Felipe
signal ingrediente_cortado(posicion: Vector3)
signal ingrediente_listo(estacion: Node)
signal ingrediente_quemado(estacion: Node)
signal ingrediente_descartado
