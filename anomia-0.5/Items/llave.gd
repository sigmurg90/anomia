@tool
extends Node3D
class_name Llave

@onready var sprite_llave: Sprite3D = $SpriteLlave
enum eLlave {AZUL,BLANCO,MORADO,NARANJA,ROSA,VERDE} 
@export var tipo := eLlave.AZUL
@export var textura : Texture2D :
	set(_textura):
		textura = _textura
		if sprite_llave:
			sprite_llave.texture = textura
		update_configuration_warnings()

@export var cerradura : Node3D :
	set(_cerradura):
		cerradura = _cerradura
		update_configuration_warnings()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	sprite_llave.texture = textura
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _get_configuration_warnings() -> PackedStringArray:
	var warnings = []
	if not textura:
		warnings.append("No hay imagen asignada.")
	
	if not cerradura:
		warnings.append("Asigne una cerradura.")
		
	return warnings
	pass
