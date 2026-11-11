# Pendientes por persona

## Felipe
- [ ] Probar el flujo completo con `debug_log.gd` (ver en consola llegadas, alertas, tensión y apagón).
- [ ] Mostrar "otro intento" tras el amanecer (hoy espera la tecla R).
- [ ] Comprobar M11: resolución cuando coinciden vencimiento, entrega y llegada.
- [ ] Revisar el código de Gabriela y Danna antes de unir a `main`.

## Gabriela
- [ ] Raycast del mouse para tabla, hornilla, plato, cliente y papel.
- [ ] Completar `drag_controller.gd` (arrastrar, soltar, devolver al origen, descartar).
- [ ] Conectar `selector_papel.gd` con el clic sobre un papel.
- [ ] Impedir manipular comida mientras se consulta el papel.
- [ ] Probar con cubos de colores antes de esperar los modelos.

## Danna
- [x] Mapa nuevo: pasillo rectangular oscuro con la mesa de cocina al frente, cámara en diagonal y resolución de referencia 640 x 360. Está en `scenes/mapa/` (pasillo, mesa_cocina y mapa) y se arma en `scenes/main.tscn` junto con los clientes (`scenes/cliente/`), el jugador con brazos (`scenes/player/`) y el screamer (`scenes/screamer/`). Cliente y screamer son siluetas de relleno hasta tener modelos. La papa usa el modelo de la remolacha pintado, porque no hay modelo de papa.
- [ ] Tres apariencias de cliente con expresión de espera, alerta y reacción.
- [ ] Papeles con siluetas de ingredientes, borde rojo y reloj.
- [ ] Interfaz: reloj, barra de cocción de 7 s, círculo de corte, pictogramas.
- [ ] Sonidos: reloj, puerta, utensilios, calle y apagón; asignar el reproductor `ambiente` en `AudioController`.
- [ ] Apagón: ocultar cocina e interfaz durante 3 s.

## Notas de la escena del nivel 1
- Escala: 1 cuadro del mapa = 0.2 m, la pantalla de 320 x 180 equivale a 3.2 x 1.8 m (cámara ortográfica de tamaño 1.8).
- Cada estación, cliente y papel tiene un `StaticBody3D` llamado `Colision`, listo para el raycast de Gabriela. Grupos: `tabla`, `hornilla`, `plato`, `fuente`, `cliente`, `papel`.
- Falta asignar `indice` en `PapelView` (hoy queda en -1 y no reacciona a las señales). Debe tomar el índice del cliente de su posición cuando llega.
- Aún no hay reproductor de ambiente para `AudioController`.
- La escena no se ha abierto en Godot desde el entorno donde se creó: abrirla y revisar que cargue sin errores.
