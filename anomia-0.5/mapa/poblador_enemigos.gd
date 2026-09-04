class_name PobladorEnemigos
extends Node
## poblador_enemigos.gd
## ---------------------
## Lee la tabla DatosMapa.ENEMIGOS (la transcripción del diagrama de
## spawns) y puebla el nivel: instancia cada enemigo en su sala, con su
## variante de color, como HERMANO del avatar — los enemigos esperan
## encontrar al jugador en `$"../avatar"`, así que deben colgar del mismo
## padre (la raíz de la escena).

const ESCENAS := {
	"vampiro": preload("res://enemies/enemy_vampiro.tscn"),
	"calaca": preload("res://enemies/enemy_calaca.tscn"),
	"ojos": preload("res://enemies/enemy_ojos.tscn"),
}


func _ready() -> void:
	# Un frame de cortesía: deja que el Mapa (hermano anterior) termine de
	# construir la geometría y hornear el navmesh antes de soltar bichos.
	await get_tree().process_frame

	var raiz := get_parent()
	var total := 0
	for sala in DatosMapa.ENEMIGOS:
		var centro: Vector2 = DatosMapa.SALAS[sala]["centro"]
		for e in DatosMapa.ENEMIGOS[sala]:
			var escena: PackedScene = ESCENAS[e["tipo"]]
			var enemigo := escena.instantiate()
			enemigo.variante_color = e["color"]
			enemigo.name = "%s_%s_%d" % [e["tipo"], sala, total]
			raiz.add_child(enemigo)
			var off: Vector2 = e["pos"]
			enemigo.global_position = Vector3(centro.x + off.x, 0.15, centro.y + off.y)
			total += 1
	print("PobladorEnemigos: %d enemigos colocados en el mapa" % total)
