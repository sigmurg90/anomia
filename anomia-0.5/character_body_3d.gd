extends CharacterBody3D

const SPEED: float = 5.0
const JUMP_VELOCITY: float = 6.0

@onready var camera_3d: Camera3D = $Camera3D

func _physics_process(delta: float) -> void:
	# Aplicación de la aceleración gravitacional
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Manejo del impulso de salto
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Captura de entradas (x: izquierda/derecha, y: adelante/atrás)
	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	# Extracción de la base de orientación de la cámara
	var cam_transform: Transform3D = camera_3d.global_transform
	
	# Proyección en el plano XZ (anulando inclinación vertical Y)
	var forward: Vector3 = -cam_transform.basis.z
	forward.y = 0.0
	forward = forward.normalized()
	
	var right: Vector3 = cam_transform.basis.x
	right.y = 0.0
	right = right.normalized()

	# CORRECCIÓN: Se invierte input_dir.y porque 'move_up' equivale a -1.0
	var direction: Vector3 = (right * input_dir.x + forward * (-input_dir.y)).normalized()

	# Vectorización de la velocidad lineal
	if direction != Vector3.ZERO:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0.0, SPEED)
		velocity.z = move_toward(velocity.z, 0.0, SPEED)

	move_and_slide()
