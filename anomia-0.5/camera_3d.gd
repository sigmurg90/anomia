extends Camera3D

## Coeficiente de sensibilidad angular
@export var mouse_sensitivity: float = 0.005

## Limites de rotación vertical 
@export_range(0.0, 20.0, 0.1) var pitch_limit_degrees: float = 89.0

func _ready() -> void:
	# Capturar y ocultar el cursor 
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		# 1. Rotación en el eje Y
		rotation.y -= event.relative.x * mouse_sensitivity
		
		# 2. Rotación en el eje X
		rotation.x -= event.relative.y * mouse_sensitivity
		
		# 3. Limites de camara vertical 
		var max_pitch_rad: float = deg_to_rad(pitch_limit_degrees)
		rotation.x = clamp(rotation.x, -max_pitch_rad, max_pitch_rad)

func _input(event: InputEvent) -> void:
	# 
	if event.is_action_pressed("ui_cancel"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
