class_name EnemyBase
extends CharacterBody3D
## Base común de todos los enemigos (HERENCIA de scripts en Godot).
##
## Aquí vive lo que comparten: gravedad, persecución con NavigationAgent3D,
## separación entre vecinos, salud, y la muerte (sonido + botín por
## cercanía). Cada tipo hereda con `extends EnemyBase` y aporta lo suyo
## sobreescribiendo los "hooks": _tick_attack() y _update_hurt_feedback().

const DEATH_SOUND: AudioStream = preload("res://sfx/sfx_enemy_die.wav")
const PICKUP_SCENE: PackedScene = preload("res://ammo_pickup.tscn")

@export var max_health: float = 100.0

## Velocidad de persecución; 0 = enemigo estacionario (el Coloso)
@export var move_speed: float = 5.0

## Distancia a la que detecta al jugador y empieza a perseguir
@export var detection_radius: float = 15.0

const SEPARATION_RADIUS: float = 2.5
const SEPARATION_WEIGHT: float = 1.5

var current_health: float

@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var target: Node3D = $"../avatar"

func _ready() -> void:
	# Los hijos que sobreescriban _ready() deben llamar super._ready():
	# en GDScript el _ready del padre NO se ejecuta solo al sobreescribir.
	current_health = max_health
	add_to_group("enemigos")

func _physics_process(delta: float) -> void:
	# 1. Gravedad
	if not is_on_floor():
		velocity += get_gravity() * delta

	# 2. Persecución (si este tipo se mueve)
	if move_speed > 0.0:
		_chase()

	# 3. Ataque propio de cada tipo (hook)
	_tick_attack(delta)

	# 4. Resolución de físicas y colisiones
	move_and_slide()

## Persecución + separación de Reynolds (la lógica original del pilar)
func _chase() -> void:
	if not is_instance_valid(target):
		return

	var distance_to_target: float = global_position.distance_to(target.global_position)

	if distance_to_target <= detection_radius:
		nav_agent.target_position = target.global_position

		var next_location: Vector3 = nav_agent.get_next_path_position()
		var target_direction: Vector3 = (next_location - global_position)
		target_direction.y = 0.0

		if target_direction.length_squared() > 0.01:
			target_direction = target_direction.normalized()
		else:
			target_direction = Vector3.ZERO

		var separation_vector: Vector3 = _calculate_separation_vector()
		var final_direction: Vector3 = (target_direction + separation_vector * SEPARATION_WEIGHT)

		if final_direction.length_squared() > 0.01:
			final_direction = final_direction.normalized()
			velocity.x = final_direction.x * move_speed
			velocity.z = final_direction.z * move_speed
		else:
			velocity.x = 0.0
			velocity.z = 0.0
	else:
		velocity.x = move_toward(velocity.x, 0.0, 0.5)
		velocity.z = move_toward(velocity.z, 0.0, 0.5)

# --- Salud ---

## Punto de entrada del daño. hit_point permite a los hijos saber DÓNDE
## pegó el disparo (puntos débiles del Coloso); INF = desconocido.
func take_damage(amount: float, _hit_point: Vector3 = Vector3.INF) -> void:
	current_health = maxf(current_health - amount, 0.0)
	_update_hurt_feedback(1.0 - (current_health / max_health))
	print("%s recibió %.0f de daño → HP %.0f/%.0f" % [name, amount, current_health, max_health])

	if current_health <= 0.0:
		_die()

# --- Hooks para los hijos ---

## Ataque por tick de física (cada tipo implementa el suyo)
func _tick_attack(_delta: float) -> void:
	pass

## Feedback visual de daño (tinte del pilar, brillo de sprites...)
func _update_hurt_feedback(_hurt_ratio: float) -> void:
	pass

# --- Muerte y recompensa ---

func _die() -> void:
	_play_death_sound()
	_drop_reward()
	queue_free()

## Jerarquización de radio: entre MÁS CERCA estés al matarlo, más VIDA
## cura el botiquín que suelta. Riesgo y recompensa: acercarse duele,
## pero paga — y con el reloj drenándote, cazar es la única medicina.
func _drop_reward() -> void:
	var curacion: float = 4.0
	var dist: float = -1.0

	if is_instance_valid(target):
		dist = global_position.distance_to(target.global_position)
		if dist <= 4.0:
			curacion = 12.0
		elif dist <= 9.0:
			curacion = 8.0

	var pickup := PICKUP_SCENE.instantiate() as Botiquin
	pickup.curacion = curacion
	get_parent().add_child(pickup)
	pickup.global_position = global_position
	print("%s cayó a %.1f m → botiquín: +%.0f de vida" % [name, dist, curacion])

func _play_death_sound() -> void:
	var player := AudioStreamPlayer3D.new()
	player.stream = DEATH_SOUND
	get_tree().root.add_child(player)
	player.global_position = global_position
	player.play()
	player.finished.connect(player.queue_free)
	# Respaldo de limpieza (si `finished` no llega, p. ej. headless)
	get_tree().create_timer(1.5).timeout.connect(player.queue_free)

# Sumatorio de vectores repulsivos respecto a vecinos próximos en el plano XZ
func _calculate_separation_vector() -> Vector3:
	var separation: Vector3 = Vector3.ZERO
	var neighbors: Array = get_tree().get_nodes_in_group("enemigos")

	for neighbor in neighbors:
		if neighbor == self or not is_instance_valid(neighbor):
			continue

		var diff: Vector3 = global_position - neighbor.global_position
		diff.y = 0.0
		var dist_sq: float = diff.length_squared()

		if dist_sq > 0.0 and dist_sq < (SEPARATION_RADIUS * SEPARATION_RADIUS):
			var d: float = sqrt(dist_sq)
			separation += (diff / d) / d

	return separation
