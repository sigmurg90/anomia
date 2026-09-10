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
		
@onready var collect_sound: AudioStreamPlayer = $CollectSound

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	sprite_llave.texture = textura
	pass # Replace with function body.

func _get_configuration_warnings() -> PackedStringArray:
	var warnings = []
	if not textura:
		warnings.append("No hay imagen asignada.")
		
	return warnings



func _on_area_3d_body_entered(body: Node3D) -> void:
	if body is Avatar:
		body.llaves.append(tipo)
		collect_sound.play()
		await get_tree().create_timer(0.5).timeout
		queue_free.call_deferred()
	pass # Replace with function body.
