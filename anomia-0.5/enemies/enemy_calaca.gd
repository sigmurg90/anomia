extends EnemyBase
## La CALACA: espectro de manto con cráneo y dos manos flotantes. Se
## desliza hacia ti a paso medio; cuando te tiene a tiro, TELEGRAFÍA
## (las manos se alzan y abren) y EMBISTE en línea recta. La embestida
## es esquivable moviéndote de lado — quedarte quieto es lo que castiga.

const CUERPOS: Array = [
	preload("res://enemies/art/calaca_cuerpo_amarillo.png"),
	preload("res://enemies/art/calaca_cuerpo_rojo.png"),
	preload("res://enemies/art/calaca_cuerpo_azul.png"),
]
const MANOS_IZQ: Array = [
	preload("res://enemies/art/calaca_mano_izq_amarillo.png"),
	preload("res://enemies/art/calaca_mano_izq_rojo.png"),
	preload("res://enemies/art/calaca_mano_izq_azul.png"),
]
const MANOS_DER: Array = [
	preload("res://enemies/art/calaca_mano_der_amarillo.png"),
	preload("res://enemies/art/calaca_mano_der_rojo.png"),
	preload("res://enemies/art/calaca_mano_der_azul.png"),
]

@export_enum("Amarillo", "Rojo", "Azul") var variante_color: int = 0

@export var dano_embestida: float = 12.0
@export var radio_inicio: float = 4.4
@export var enfriamiento: float = 2.0

const T_TELEGRAFO := 0.45
const T_EMBESTIDA := 0.38
const VEL_EMBESTIDA := 10.0

enum Estado { ACECHO, TELEGRAFO, EMBESTIDA }

@onready var _mano_izq: Sprite3D = $ManoIzq
@onready var _mano_der: Sprite3D = $ManoDer

var _estado: Estado = Estado.ACECHO
var _timer := 0.0
var _cooldown := 0.0
var _dir_embestida := Vector3.ZERO
var _golpeo := false
var _t := 0.0
var _pos_mano_izq: Vector3
var _pos_mano_der: Vector3


func _ready() -> void:
	super._ready()
	($Cuerpo as Sprite3D).texture = CUERPOS[variante_color]
	($Cuerpo as Sprite3D).pixel_size = 0.00048
	_mano_izq.texture = MANOS_IZQ[variante_color]
	_mano_izq.pixel_size = 0.00039
	_mano_der.texture = MANOS_DER[variante_color]
	_mano_der.pixel_size = 0.00039
	_pos_mano_izq = _mano_izq.position
	_pos_mano_der = _mano_der.position


func _process(delta: float) -> void:
	_t += delta
	# Las manos flotan con respiración espectral (fases opuestas); en el
	# telegrafo SE ALZAN — ese es tu aviso para hacerte a un lado.
	var alza := 0.0
	if _estado == Estado.TELEGRAFO:
		alza = clampf(_timer / T_TELEGRAFO, 0.0, 1.0) * 0.55
	_mano_izq.position = _pos_mano_izq + Vector3(0, sin(_t * 2.2) * 0.09 + alza, 0)
	_mano_der.position = _pos_mano_der + Vector3(0, sin(_t * 2.2 + PI) * 0.09 + alza, 0)


func _tick_attack(delta: float) -> void:
	_cooldown = maxf(_cooldown - delta, 0.0)
	if not is_instance_valid(target):
		return

	match _estado:
		Estado.ACECHO:
			if _cooldown <= 0.0 and global_position.distance_to(target.global_position) <= radio_inicio:
				_estado = Estado.TELEGRAFO
				_timer = 0.0
		Estado.TELEGRAFO:
			_timer += delta
			# Clavada en su sitio mientras alza las manos.
			velocity.x = 0.0
			velocity.z = 0.0
			if _timer >= T_TELEGRAFO:
				var dir := target.global_position - global_position
				dir.y = 0.0
				_dir_embestida = dir.normalized()
				_golpeo = false
				_estado = Estado.EMBESTIDA
				_timer = 0.0
		Estado.EMBESTIDA:
			_timer += delta
			# Sobrescribe lo que _chase haya puesto: la embestida es recta.
			velocity.x = _dir_embestida.x * VEL_EMBESTIDA
			velocity.z = _dir_embestida.z * VEL_EMBESTIDA
			if not _golpeo and global_position.distance_to(target.global_position) <= 1.5:
				_golpeo = true
				var health := target.get_node_or_null("Health") as Health
				if health != null:
					health.take_damage(dano_embestida)
			if _timer >= T_EMBESTIDA:
				_estado = Estado.ACECHO
				_cooldown = enfriamiento
