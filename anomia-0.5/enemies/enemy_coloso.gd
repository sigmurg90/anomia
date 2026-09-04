extends EnemyBase
## El Coloso: jefe estacionario. Alterna AL AZAR entre dos modos y lo
## ANUNCIA con aros de color sobre sus partes:
##   🔴 aro ROJO  = esta parte ATACA (cuidado con ella)
##   🟢 aro VERDE = esta parte es el PUNTO DÉBIL (dispárale: daño x2)
## Modo MANOS: una mano se LANZA a golpearte y regresa (esquivable).
## Modo PANCITA: te dispara un ORBE visible en línea recta (esquivable).
## La parte activa resiste tus balas (x0.2); la débil las sufre (x2).

enum Modo { MANOS, PANCITA }

const SPARK_SCENE: PackedScene = preload("res://spark.tscn")
const ORB_SCENE: PackedScene = preload("res://enemies/coloso_orbe.tscn")

## Arte por variante de color (índices como el arma: amarillo, rojo, azul).
## El cuerpo pintado INCLUYE las manos con hoyos: las Area3D de las manos
## son hitboxes invisibles colocadas sobre las manos del dibujo, y los
## aros rojo/verde siguen siendo los indicadores de ataque/punto débil.
const CUERPOS: Array = [
	preload("res://enemies/art/coloso_q_amarillo.png"),
	preload("res://enemies/art/coloso_q_rojo.png"),
	preload("res://enemies/art/coloso_q_azul.png"),
]
const ORBES: Array = [
	preload("res://enemies/art/orbe_q_amarillo.png"),
	preload("res://enemies/art/orbe_q_rojo.png"),
	preload("res://enemies/art/orbe_q_azul.png"),
]

## Variante de color de ESTA instancia
@export_enum("Amarillo", "Rojo", "Azul") var variante_color: int = 0

@export var hand_damage: float = 12.0
@export var orb_damage: float = 10.0
@export var orb_interval: float = 2.2

## Alcance de sus ataques: orbe (pancita) y manotazo (manos)
@export var orb_range: float = 20.0
@export var lunge_range: float = 11.0

@export var weak_multiplier: float = 2.0
@export var resist_multiplier: float = 0.2

const HAND_REACH: float = 1.2
const BELLY_BAND: float = 0.55  # media altura de la franja de la pancita
const LUNGE_SPEED: float = 14.0

var modo: Modo = Modo.MANOS

@onready var _hand_l: Area3D = $ManoIzq
@onready var _hand_r: Area3D = $ManoDer
@onready var _belly: Marker3D = $PuntoPancita
@onready var _ring_l: Sprite3D = $ManoIzq/Aro
@onready var _ring_r: Sprite3D = $ManoDer/Aro
@onready var _belly_ring: Sprite3D = $AroPancita

var _time: float = 0.0
var _mode_left: float = 0.0
var _orb_cooldown: float = 0.0
var _touch_cooldown: float = 0.0

# Estado del manotazo lanzado
var _lunge_phase: int = 0  # 0 = en reposo, 1 = ida, 2 = regreso
var _lunge_hand: Area3D
var _lunge_point: Vector3
var _lunge_hit_done: bool = false
var _lunge_next: float = 1.2
var _use_left: bool = true

func _ready() -> void:
	super._ready()

	# Arte pintado según la variante
	var cuerpo := $Cuerpo as Sprite3D
	cuerpo.texture = CUERPOS[variante_color]
	cuerpo.pixel_size = 0.0023
	cuerpo.position.y = 1.6

	_pick_mode()

## Ancla de reposo de una mano: SIEMPRE a los costados del cuerpo VISTOS
## desde el jugador (perpendicular a la dirección hacia él). No orbitan —
## la órbita es exclusiva del Sarcófago; esto solo mantiene la composición
## de la lámina (cuerpo al centro, manos flanqueando) desde cualquier ángulo.
func _hand_anchor(side_sign: float) -> Vector3:
	var side: Vector3 = Vector3.RIGHT

	if is_instance_valid(target):
		var to_player: Vector3 = target.global_position - global_position
		to_player.y = 0.0
		if to_player.length_squared() > 0.01:
			side = to_player.normalized().cross(Vector3.UP)

	# Las manos pintadas del cuerpo quedan a ~0.9 m del eje, arriba
	return side * 0.9 * side_sign + Vector3(0.0, 2.0, 0.0)

## Elige modo al azar y cuánto durará antes del siguiente cambio
func _pick_mode() -> void:
	modo = Modo.MANOS if randi() % 2 == 0 else Modo.PANCITA
	_mode_left = randf_range(4.0, 7.0)
	print("%s cambia de modo → ataca con %s (punto débil: %s)" % [
		name,
		"MANOS" if modo == Modo.MANOS else "PANCITA",
		"la pancita" if modo == Modo.MANOS else "las manos",
	])

func _tick_attack(delta: float) -> void:
	_time += delta
	_mode_left -= delta
	if _mode_left <= 0.0:
		# No cambiar de modo a media embestida (la mano quedaría suelta)
		if _lunge_phase == 0:
			_pick_mode()

	if modo == Modo.MANOS:
		_tick_hands(delta)
	else:
		_tick_belly(delta)

	_update_part_indicators()

## Modo MANOS: reposan a los costados y, por turnos, UNA se lanza a
## golpearte y regresa. También duele tocarlas.
func _tick_hands(delta: float) -> void:
	# Manotazo en curso
	if _lunge_phase == 1:
		_lunge_hand.global_position = _lunge_hand.global_position.move_toward(_lunge_point, LUNGE_SPEED * delta)

		if not _lunge_hit_done and is_instance_valid(target) \
				and _lunge_hand.global_position.distance_to(target.global_position) <= HAND_REACH:
			var health := target.get_node_or_null("Health") as Health
			if health != null:
				health.take_damage(hand_damage)
			_lunge_hit_done = true

		if _lunge_hand.global_position.distance_to(_lunge_point) < 0.1:
			_lunge_phase = 2
		return

	if _lunge_phase == 2:
		var home: Vector3 = global_position + _hand_anchor(1.0 if _lunge_hand == _hand_l else -1.0)
		_lunge_hand.global_position = _lunge_hand.global_position.move_toward(home, LUNGE_SPEED * 0.7 * delta)

		if _lunge_hand.global_position.distance_to(home) < 0.15:
			_lunge_phase = 0
			_lunge_next = 1.8
		return

	# En reposo: vibración agresiva en el sitio + contacto que duele
	var jab: float = sin(_time * 14.0) * 0.12
	_hand_l.position = _hand_l.position.lerp(_hand_anchor(1.0) + Vector3(0.0, jab, 0.0), delta * 8.0)
	_hand_r.position = _hand_r.position.lerp(_hand_anchor(-1.0) + Vector3(0.0, -jab, 0.0), delta * 8.0)

	_touch_cooldown = maxf(_touch_cooldown - delta, 0.0)
	if _touch_cooldown <= 0.0 and is_instance_valid(target):
		for hand: Area3D in [_hand_l, _hand_r]:
			if hand.global_position.distance_to(target.global_position) <= HAND_REACH:
				var health := target.get_node_or_null("Health") as Health
				if health != null:
					health.take_damage(hand_damage)
					_touch_cooldown = 0.6
				break

	# ¿Lanzar el siguiente manotazo?
	_lunge_next -= delta
	if _lunge_next <= 0.0 and is_instance_valid(target) \
			and global_position.distance_to(target.global_position) <= lunge_range:
		_lunge_hand = _hand_l if _use_left else _hand_r
		_use_left = not _use_left
		# Apunta a donde ESTABAS: si te mueves, lo esquivas
		_lunge_point = target.global_position
		_lunge_hit_done = false
		_lunge_phase = 1

## Modo PANCITA: las manos quedan QUIETAS (¡punto débil!) y la pancita
## te dispara orbes visibles en línea recta
func _tick_belly(delta: float) -> void:
	_hand_l.position = _hand_l.position.lerp(_hand_anchor(1.0), delta * 5.0)
	_hand_r.position = _hand_r.position.lerp(_hand_anchor(-1.0), delta * 5.0)

	_orb_cooldown = maxf(_orb_cooldown - delta, 0.0)
	if _orb_cooldown > 0.0 or not is_instance_valid(target):
		return

	if global_position.distance_to(target.global_position) <= orb_range:
		_launch_orb()
		_orb_cooldown = orb_interval

func _launch_orb() -> void:
	var direction: Vector3 = (target.global_position - _belly.global_position).normalized()

	var orb := ORB_SCENE.instantiate() as ColosoOrbe
	orb.damage = orb_damage
	orb.textura = ORBES[variante_color]
	get_tree().root.add_child(orb)
	# Nace fuera del cuerpo del Coloso para no chocar consigo mismo
	orb.global_position = _belly.global_position + direction * 1.3
	orb.setup(direction, self)

## 🔴 rojo = parte que ataca | 🟢 verde = punto débil (pulsan)
func _update_part_indicators() -> void:
	var pulse: float = 0.7 + 0.3 * sin(_time * 5.0)
	var attack_color := Color(1.0, 0.25, 0.2, pulse)
	var weak_color := Color(0.3, 1.0, 0.35, pulse)

	var hands_attack: bool = modo == Modo.MANOS
	_ring_l.modulate = attack_color if hands_attack else weak_color
	_ring_r.modulate = attack_color if hands_attack else weak_color
	_belly_ring.modulate = weak_color if hands_attack else attack_color

	# El aro de la pancita se asoma hacia el jugador para no hundirse
	# en el plano del sprite del cuerpo
	if is_instance_valid(target):
		var dir: Vector3 = target.global_position - global_position
		dir.y = 0.0
		if dir.length_squared() > 0.01:
			_belly_ring.position = Vector3(0.0, 1.7, 0.0) + dir.normalized() * 0.45

## Sobreescritura del daño: multiplica según dónde pegó el disparo
func take_damage(amount: float, hit_point: Vector3 = Vector3.INF) -> void:
	var mult: float = 1.0

	if hit_point != Vector3.INF:
		if _is_weak_hit(hit_point):
			mult = weak_multiplier
			print("¡PUNTO DÉBIL del %s! (x%.1f)" % [name, mult])
		else:
			mult = resist_multiplier
			print("%s resiste el golpe — dispara a lo VERDE" % name)

	super.take_damage(amount * mult, hit_point)

func _is_weak_hit(hit_point: Vector3) -> bool:
	if modo == Modo.MANOS:
		# Pancita débil: el disparo pegó en la franja de altura del torso
		return absf(hit_point.y - _belly.global_position.y) <= BELLY_BAND

	# Manos débiles: el disparo pegó en (o muy cerca de) una mano
	var d: float = minf(
		hit_point.distance_to(_hand_l.global_position),
		hit_point.distance_to(_hand_r.global_position),
	)
	return d <= HAND_REACH

## Dónde conviene apuntar ahora (lo usan las pruebas automatizadas)
func get_weak_point_position() -> Vector3:
	if modo == Modo.MANOS:
		return _belly.global_position
	return _hand_l.global_position
