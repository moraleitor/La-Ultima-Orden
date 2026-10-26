# La Última Orden (Godot 4.3 o superior)

Esqueleto del proyecto del equipo Borealis. Los números de reglas vienen del Documento de concepto (M1 a M11) y están en `scripts/core/config.gd`. Si una regla cambia, se cambia ahí.

## Cómo abrirlo
1. Instalar Godot 4.3 o superior (versión estándar, GDScript).
2. Abrir Godot, "Importar" y escoger `project.godot`.
3. Ejecutar con F5. La escena principal es `scenes/main.tscn`.

El esqueleto no fue ejecutado todavía. Es normal que Godot muestre algún aviso o error la primera vez; hay que corregirlo antes de seguir.

## Reparto
| Quién | Carpeta | Qué construye |
|---|---|---|
| Felipe | `scripts/core/` | Estados del juego, pedidos, llegadas y plazos, tensión, luz, sonido ambiente, repositorio y pruebas. |
| Gabriela | `scripts/cocina/` | Selección y consulta de papel, arrastrar y soltar, tabla, hornilla, plato, entrega y descarte. |
| Danna | `scripts/visual/` y `assets/` | Escena 3D, clientes, papeles, interfaz, paleta y sonidos. |

Lo que ya funciona en `core`: la secuencia de 13 clientes, los plazos, la alerta de 15 s, la tensión, la racha, la recuperación, el apagón y el amanecer. Todo lo marcado con `TODO` está pendiente.

## Cómo se comunican los sistemas
Todo pasa por `scripts/core/events.gd`. Cada persona emite solo las señales de su área y escucha las de las demás.
- Gabriela emite `entrega_intentada(indice, ingredientes)` y `pedido_seleccionado`. Felipe compara el plato con el pedido y responde con `pedido_entregado`.
- Danna no emite nada: solo escucha y dibuja (`cliente_llego`, `pedido_en_alerta`, `tension_cambio`, etc.).
- Si necesitas una señal nueva, se agrega en `events.gd` y se avisa al grupo.

## Reglas para no estorbarse en Git
- Una rama por persona: `felipe`, `gabriela`, `danna`. Se une a `main` cuando algo funciona.
- Cada quien es dueño de sus escenas `.tscn`. No se editan las de otra persona; se le pide el cambio.
- Antes de unir a `main`, abrir el proyecto y comprobar que no da errores.
- La carpeta `.godot/` no se sube.

## Plan de seis semanas
1. Reglas y escena (cubos de colores en las estaciones).
2. Preparación: arrastrar, cortar y cocinar.
3. Pedidos y plazos conectados a la cocina.
4. Tensión, luz y cierre del turno.
5. Recursos finales (modelos, texturas, sonidos) y pruebas con 5 compañeros.
6. Correcciones y entrega.

## Criterios de terminado (del documento)
1. Los 13 pedidos se resuelven y se ve el amanecer en menos de 6 minutos sin pausar.
2. Un error baja la luz, tres aciertos no la recuperan y el cuarto sí. Tres puntos de tensión provocan apagón y reinicio desde el cliente 1.
3. Con dos pedidos pendientes se puede seleccionar y acercar cualquiera mientras sigue la cocción, y la alerta de 15 s se activa aunque esté seleccionado el otro.
