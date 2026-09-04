extends EnemyBase
## El Sarcófago: no tiene manos propias — usa unas como las del Coloso,
## orbitando a su alrededor con un radio que RESPIRA (varía todo el
## tiempo, como pediste: "que sea interesante"). Tocar una mano duele.

## Arte por variante de color (índices como el arma: amarillo, rojo, azul)
const CUERPOS: Array = [
	preload("res://enemies/art/sarcofago_q_amarillo.png"),
	preload("res://enemies/art/sarcofago_q_rojo.png"),
	preload("res://enemies/art/sarcofago_q_azul.png"),
]
const MANOS_A: Array = [
	preload("res://enemies/art/mano_q_a_amarillo.png"),
	preload("res://enemies/art/mano_q_a_rojo.png"),
	preload("res://enemies/art/mano_q_a_azul.png"),
]
const MANOS_B: Array = [
	preload("res://enemies/art/mano_q_b_amarillo.png"),
	preload("res://enemies/art/mano_q_b_rojo.png"),
	preload("res://enemies/art/mano_q_b_azul.png"),
]

## Variante de color de ESTA instancia
@export_enum("Amarillo", "Rojo", "Azul") var variante_color: int = 0

@export var hand_damage: float = 8.0
@export var hand_hit_cooldown: float = 0.6
@export var orbit_speed: float = 2.4
@export var orbit_base_radius: float = 1.5

## Amplitud y velocidad de la "respiración" del radio
@export var orbit_breath: float = 0.7
@export var orbit_breath_speed: float = 1.6

const HAND_REACH: float = 1.1

@onready var _hand_a: Sprite3D = $ManoA
@onready var _hand_b: Sprite3D = $ManoB

var _angle: float = 0.0
var _time: float = 0.0
var _hit_cooldown: float = 0.0

func _ready() -> void:
	super._ready()

	# Arte pintado según la variante: cuerpo con calavera y las dos
	# manos (poses A y B) que le orbitan
	var cuerpo := $Cuerpo as Sprite3D
	cuerpo.texture = CUERPOS[variante_color]
	cuerpo.pixel_size = 0.0017
	_hand_a.texture = MANOS_A[variante_color]
	_hand_a.pixel_size = 0.0014
	_hand_a.flip_h = false
	_hand_b.texture = MANOS_B[variante_color]
	_hand_b.pixel_size = 0.0014
	_hand_b.flip_h = false

func _tick_attack(delta: float) -> void:
	_time += delta
	_angle += orbit_speed * delta

	# Radio variable: base + onda senoidal → nunca es el mismo círculo
	var radius: float = orbit_base_radius + sin(_time * orbit_breath_speed) * orbit_breath
	_place_hand(_hand_a, _angle, radius)
	_place_hand(_hand_b, _angle + PI, radius)

	_hit_cooldown = maxf(_hit_cooldown - delta, 0.0)
	if _hit_cooldown > 0.0 or not is_instance_valid(target):
		return

	for hand: Sprite3D in [_hand_a, _hand_b]:
		if hand.global_position.distance_to(target.global_position) <= HAND_REACH:
			var health := target.get_node_or_null("Health") as Health
			if health != null:
				health.take_damage(hand_damage)
				_hit_cooldown = hand_hit_cooldown
			break

## Coloca una mano en su órbita (plano XZ, altura propia de la mano)
func _place_hand(hand: Node3D, angle: float, radius: float) -> void:
	hand.position = Vector3(cos(angle) * radius, hand.position.y, sin(angle) * radius)
