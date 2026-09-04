extends GPUParticles3D
## Chispas de impacto: ráfaga one-shot de partículas en el punto donde
## pegó el disparo. Se autodestruye al terminar — quien la instancia
## solo necesita colocarla; no tiene que acordarse de limpiarla.

func _ready() -> void:
	# `finished` avisa cuando un emisor one-shot terminó su ciclo
	finished.connect(queue_free)
	emitting = true

	# Respaldo por si `finished` nunca llega (p. ej. corriendo sin GPU
	# en modo headless, donde las partículas no se simulan). Si el nodo
	# ya fue liberado por `finished`, este await simplemente no despierta.
	await get_tree().create_timer(lifetime + 1.0).timeout
	queue_free()
