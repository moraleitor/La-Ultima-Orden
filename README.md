# La Última Orden

Una noche, un puesto de comida a las afueras de la ciudad y trece clientes que no hablan. Elisa corta, cocina y sirve cada pedido a tiempo, mientras la luz del local se apaga con cada error.

Proyecto del equipo Borealis para Desarrollo conceptual de videojuegos.

## Para abrirlo

Necesitas Godot 4.3 o superior. Abre Godot, elige *Importar* y selecciona `project.godot`.

## Qué hay dentro

- `scripts/core`: turnos, pedidos, tensión y luz
- `scripts/cocina`: tabla, hornilla, plato y arrastre
- `scripts/visual`: clientes, papeles e interfaz
- `assets`: modelos, texturas y sonidos

## Equipo

Gabriela Bautista, Juan Felipe Morales y Danna Alfonso.
## Criterios de terminado (del documento)
1. Los 13 pedidos se resuelven y se ve el amanecer en menos de 6 minutos sin pausar.
2. Un error baja la luz, tres aciertos no la recuperan y el cuarto sí. Tres puntos de tensión provocan apagón y reinicio desde el cliente 1.
3. Con dos pedidos pendientes se puede seleccionar y acercar cualquiera mientras sigue la cocción, y la alerta de 15 s se activa aunque esté seleccionado el otro.
