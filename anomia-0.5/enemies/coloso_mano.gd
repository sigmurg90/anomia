extends Area3D
## Mano del Coloso: es un Area3D CON colisión para que el rayo del arma
## pueda golpearla (el arma activa collide_with_areas). No decide nada:
## reenvía el disparo al Coloso usando SU propia posición como punto de
## impacto — precisión perfecta de "me pegaste a mí".

func take_damage(amount: float, _hit_point: Vector3 = Vector3.INF) -> void:
	var coloso := get_parent() as EnemyBase
	if coloso != null:
		coloso.take_damage(amount, global_position)
