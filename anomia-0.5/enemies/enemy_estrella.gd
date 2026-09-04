extends EnemyBase
## La Estrella: el enemigo pequeño y rápido. Su cabeza FLOTA sobre el
## cuerpo; para atacar la junta con el cuerpo (telegraph visible de medio
## segundo) y al tocarlo suelta un pulso de daño en un radio corto.

const SPARK_SCENE: PackedScene = preload("res://spark.tscn")

## Arte por variante de color (índices como el arma: amarillo, rojo, azul)
const CABEZAS: Array = [
	preload("res://enemies/art/estrella_q_cabeza_amarillo.png"),
	preload("res://enemies/art/estrella_q_cabeza_rojo.png"),
	preload("res://enemies/art/estrella_q_cabeza_azul.png"),
]
const CUERPOS: Array = [
	preload("res://enemies/art/estrella_q_cuerpo_amarillo.png"),
	preload("res://enemies/art/estrella_q_cuerpo_rojo.png"),
	preload("res://enemies/art/estrella_q_cuerpo_azul.png"),
]

## Variante de color de ESTA instancia (se elige en el editor por enemigo)
@export_enum("Amarillo", "Rojo", "Azul") var variante_color: int = 0

@export var attack_damage: float = 15.0
@export var attack_radius: float = 2.4
@export var attack_cooldown: float = 1.8

## Segundos que tarda la cabeza en bajar (tu ventana para alejarte)
const WINDUP_TIME: float = 0.5
const HEAD_SLAM_Y: float = 0.45

@onready var _head: Sprite3D = $Cabeza

var _cooldown: float = 0.0
var _windup: float = -1.0  # negativo = sin ataque en curso
var _head_rest_y: float
var _time: float = 0.0

func _ready() -> void:
	super._ready()
	_head_rest_y = _head.position.y

	# Arte pintado según la variante de esta instancia
	_head.texture = CABEZAS[variante_color]
	_head.pixel_size = 0.0011
	var cuerpo := $Cuerpo as Sprite3D
	cuerpo.texture = CUERPOS[variante_color]
	cuerpo.pixel_size = 0.0015

func _process(delta: float) -> void:
	# Flotación ambiental de la cabeza (solo cuando no está atacando)
	_time += delta
	if _windup < 0.0:
		_head.position.y = _head_rest_y + sin(_time * 3.0) * 0.08

func _tick_attack(delta: float) -> void:
	_cooldown = maxf(_cooldown - delta, 0.0)

	# Ataque en curso: la cabeza baja hacia el cuerpo
	if _windup >= 0.0:
		_windup += delta
		var t: float = clampf(_windup / WINDUP_TIME, 0.0, 1.0)
		_head.position.y = lerpf(_head_rest_y, HEAD_SLAM_Y, t)

		if _windup >= WINDUP_TIME:
			_slam()
			_windup = -1.0
			_cooldown = attack_cooldown
		return

	if _cooldown > 0.0 or not is_instance_valid(target):
		return

	# Jugador dentro del radio: arranca el telegraph
	if global_position.distance_to(target.global_position) <= attack_radius:
		_windup = 0.0

## La cabeza tocó el cuerpo: pulso de área
func _slam() -> void:
	var spark := SPARK_SCENE.instantiate() as Node3D
	get_tree().root.add_child(spark)
	spark.global_position = global_position + Vector3(0.0, 0.5, 0.0)

	if not is_instance_valid(target):
		return

	# Solo pega si el jugador SIGUE dentro del radio: el telegraph
	# era tu oportunidad de escapar
	if global_position.distance_to(target.global_position) <= attack_radius:
		var health := target.get_node_or_null("Health") as Health
		if health != null:
			health.take_damage(attack_damage)
