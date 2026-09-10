extends Control

@export_file_path("*.tscn") var ESCENA_INICIO = "res://menu/menu_inicio.tscn"
@export_file_path("*.tscn") var ESCENA_JUEGO = "res://mapa/nivel_leiva.tscn"
@onready var info_panel: PanelContainer = $Instrucciones/InfoPanel

func _ready() -> void:
	Input.mouse_mode =Input.MOUSE_MODE_VISIBLE

func _on_btn_reiniciar_pressed() -> void:
	get_tree().change_scene_to_file(ESCENA_JUEGO)
	#get_tree().reload_current_scene()
	pass # Replace with function body.


func _on_btn_inicio_pressed() -> void:
	get_tree().change_scene_to_file(ESCENA_INICIO)
	pass # Replace with function body.


func _on_btn_exit_pressed() -> void:
	get_tree().quit()
	pass # Replace with function body.


func _on_btn_info_pressed() -> void:
	if info_panel.visible == false:
		info_panel.visible = true
	else:
		info_panel.visible = false
	pass # Replace with function body.
