extends Control
## menu_inicio.gd
## ---------------
## La pantalla de inicio (main scene del juego): por ahora una imagen
## estática con grano y temblor de "proyector viejo" (ver
## menu_grain.gdshader). CUALQUIER tecla o clic arranca el nivel 1.

const ESCENA_NIVEL := "res://nivel_mapa.tscn"

var _arrancando := false


func _input(event: InputEvent) -> void:
	# "Cualquier tecla" de verdad: teclas (al presionar, sin repeticiones
	# de auto-repeat) o cualquier botón del mouse.
	#var es_tecla := event is InputEventKey and event.is_pressed() and not event.is_echo()
	#var es_clic := event is InputEventMouseButton and event.is_pressed()
	#if not (es_tecla or es_clic):
		#return
	#if _arrancando:
		#return
	#_arrancando = true
	#var _resultado := get_tree().change_scene_to_file(ESCENA_NIVEL)
	pass


func _on_btn_inicio_pressed() -> void:
	get_tree().change_scene_to_file(ESCENA_NIVEL)
	pass # Replace with function body.
