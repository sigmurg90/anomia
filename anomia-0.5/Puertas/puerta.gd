@tool
extends Node3D

@onready var orbe: Sprite3D = $Orbe

@export var orbe_textura : Texture2D :
	set(_orbe_textura):
		orbe_textura = _orbe_textura
		if orbe:
			orbe.texture = orbe_textura
		

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _get_configuration_warnings() -> PackedStringArray:
	var warnings = []
	if not orbe:
		warnings.append("No hay imagen asignada.")
	return warnings
	
