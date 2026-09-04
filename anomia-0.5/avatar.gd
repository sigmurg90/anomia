extends CharacterBody3D

# Parámetros
@export var SPEED: float = 50.0
## Con GRAVITY_MULTIPLIER 5 la gravedad efectiva es ~49 m/s²: con 25 de
## impulso el brinco llegaba a 6.4 m — por ENCIMA de los muros del mapa
## (4.5 m) y se salía del nivel. Con 12 el brinco es ~1.5 m: sirve para
## esquivar, jamás para escaparse.
const JUMP_VELOCITY: float = 12.0
const GRAVITY_MULTIPLIER: float = 5.0

## Lo que el RELOJ del cerebro te cobra en vida por cada ciclo (a cambio
## de +1 de munición en cada frasco). La cuenta de diseño: sin cazar, la
## vida se agota en (100 / DRENADO_RELOJ) ciclos — cazar es la medicina.
const DRENADO_RELOJ: float = 3.0

@onready var camera_3d: Camera3D = $Camera3D
@onready var _health: Health = %Health
@onready var _hurt_sound: AudioStreamPlayer = $HurtSound
@onready var _reloj: RelojGenerador = $CanvasLayer/BrazoArma/Reloj
@onready var _config: ConfiguracionDisparo = %Config

func _ready() -> void:
	# El avatar REACCIONA a su componente de salud: el dato vive en
	# Health; aquí solo se decide qué hacer cuando cambia.
	_health.damaged.connect(_on_damaged)
	_health.died.connect(_on_died)

	# El reloj del cerebro: cada vuelta regala munición y cobra sangre.
	_reloj.ciclo_cumplido.connect(_on_ciclo_reloj)

func _on_ciclo_reloj() -> void:
	_config.regenerar(1.0)
	_health.take_damage(DRENADO_RELOJ)

func _on_damaged(amount: float) -> void:
	# El quejido solo para golpes DE VERDAD (enemigos pegan >= 8): el
	# drenado del reloj es un goteo constante y con gruñido cada 5 s
	# sería insoportable — su feedback es el parpadeo rojo del HUD.
	if amount >= 5.0:
		_hurt_sound.play()

func _on_died() -> void:
	%DeathLabel.visible = true

	# Congelar el mundo: paused detiene la física y los _process de todos
	# los nodos "pausables"; el dibujo y este timer siguen corriendo.
	get_tree().paused = true
	await get_tree().create_timer(1.5).timeout
	get_tree().paused = false

	# Recargar la escena completa reinicia TODO el estado gratis:
	# enemigos, munición, cajas, salud. El poder de las escenas.
	var _result := get_tree().reload_current_scene()

func _physics_process(delta: float) -> void:
	# GRAVEDAD
	if not is_on_floor():
		velocity += get_gravity() * GRAVITY_MULTIPLIER * delta

	# SALTO
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# INPUT
	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var direction := Vector3.ZERO

	if input_dir != Vector2.ZERO:
		var cam_transform: Transform3D = camera_3d.global_transform
		
		var forward: Vector3 = -cam_transform.basis.z
		forward.y = 0.0
		
		var right: Vector3 = cam_transform.basis.x
		right.y = 0.0

		direction = (right * input_dir.x - forward * input_dir.y).normalized()

	# VELOCIDAD
	if direction != Vector3.ZERO:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		# Frenado abrupto
		velocity.x = 0.0
		velocity.z = 0.0

	move_and_slide()
