class_name Tracer
extends MeshInstance3D
## Estela visual de un disparo hitscan: un prisma delgado y brillante que
## se estira desde el cañón hasta el punto de impacto y se desvanece.
## Es PURO efecto — no colisiona ni hace daño; el daño ya lo aplicó el rayo.

## Duración del desvanecimiento, en segundos
const LIFETIME: float = 0.12

## Debe llamarse DESPUÉS de add_child: posicionar en coordenadas globales
## requiere que el nodo ya esté dentro del árbol de escena.
func setup(from: Vector3, to: Vector3) -> void:
	if from.is_equal_approx(to):
		queue_free()
		return

	# La malla es una caja de 1 m de largo en Z centrada en su origen:
	# colocada en el punto medio, mirando al destino y escalada en Z a la
	# distancia exacta, cubre justo el segmento from→to.
	global_position = (from + to) * 0.5
	look_at(to)
	scale = Vector3(1.0, 1.0, from.distance_to(to))

	# Tween: anima `transparency` de 0 a 1 y al terminar libera el nodo.
	# Cada disparo crea su estela y ella misma se destruye — sin fugas.
	var tween: Tween = create_tween()
	tween.tween_property(self, "transparency", 1.0, LIFETIME)
	tween.tween_callback(queue_free)
