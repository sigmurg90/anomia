@tool
extends Node3D
class_name Puerta

@onready var orbe: Sprite3D = $Orbe
@onready var animation_player: AnimationPlayer = $AnimationPlayer
var IsOpen := false


const ORVE_AZUL = preload("uid://b64woig1usyrc")
const ORBE_BLANCO = preload("uid://3urraxty3eor")
const ORBE_MORADO = preload("uid://d5h4q63r6jyc")
const ORBE_NARAJANJA = preload("uid://cj277lss5uxpj")
const ORBE_VERDE = preload("uid://6iirgljp4v3a")
const ORBER_ROSA = preload("uid://djo0sw84uyeel")

		
@export var la_llave : Llave.eLlave :
	set(_la_llave):
		la_llave = _la_llave
		if orbe:
			_carga_texturas()
		update_configuration_warnings()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_carga_texturas()
	animation_player.stop()
	pass # Replace with function body.

func _carga_texturas():
	match la_llave:
		Llave.eLlave.AZUL: orbe.texture = ORVE_AZUL
		Llave.eLlave.BLANCO: orbe.texture = ORBE_BLANCO
		Llave.eLlave.MORADO: orbe.texture = ORBE_MORADO
		Llave.eLlave.NARANJA: orbe.texture = ORBE_NARAJANJA
		Llave.eLlave.ROSA: orbe.texture = ORBER_ROSA
		Llave.eLlave.VERDE: orbe.texture = ORBE_VERDE
	
func _get_configuration_warnings() -> PackedStringArray:
	var warnings = []
	if not la_llave:
		warnings.append("Asigne una llave.")
	return warnings
	
func _abrir_puerta()-> void:
	animation_player.play("Apertura")
	pass
	
func _on_area_3d_body_entered(body: Node3D) -> void:
	
	if body is Avatar:
		if la_llave in body.llaves:
			if not IsOpen:
				_abrir_puerta()
				IsOpen = true
	pass # Replace with function body.
