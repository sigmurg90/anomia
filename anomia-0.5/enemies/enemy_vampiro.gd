extends EnemyBase
## El VAMPIRO (murciélago): el enemigo volador. Aletea a ~2 m del piso
## persiguiéndote y, cuando te tiene cerca, TELEGRAFÍA (se eleva y aprieta
## las alas) y se lanza EN PICADA hacia donde estabas — esquivable, como
## todo ataque de este juego.
##
## Es el único enemigo SIN gravedad: sobreescribe _physics_process
## completo (no llama al del padre) porque su locomoción es aérea, pero
## REUTILIZA _chase() del padre para la persecución con navegación.

## Arte por variante (índices como el arma: amarillo, rojo, azul)
const ALAS: Array = [
	preload("res://enemies/art/vampiro_alas_amarillo.png"),
	preload("res://enemies/art/vampiro_alas_rojo.png"),
	preload("res://enemies/art/vampiro_alas_azul.png"),
]
const CABEZAS: Array = [
	preload("res://enemies/art/vampiro_cabeza_amarillo.png"),
	preload("res://enemies/art/vampiro_cabeza_rojo.png"),
	preload("res://enemies/art/vampiro_cabeza_azul.png"),
]

@export_enum("Amarillo", "Rojo", "Azul") var variante_color: int = 0

@export var dano_picada: float = 10.0
@export var radio_inicio_picada: float = 7.0
@export var enfriamiento: float = 2.4

const ALTURA_VUELO := 2.1
const VEL_PICADA := 12.0
const T_TELEGRAFO := 0.42
const T_PICADA_MAX := 0.9

enum Estado { CAZANDO, TELEGRAFO, PICADA }

@onready var _alas: Sprite3D = $Alas
@onready var _cabeza: Sprite3D = $Cabeza

var _estado: Estado = Estado.CAZANDO
var _timer := 0.0
var _cooldown := 0.0
var _objetivo_picada := Vector3.ZERO
var _golpeado_en_picada := false
var _t := 0.0


func _ready() -> void:
	super._ready()
	_alas.texture = ALAS[variante_color]
	_alas.pixel_size = 0.00029
	_cabeza.texture = CABEZAS[variante_color]
	_cabeza.pixel_size = 0.00026


func _process(delta: float) -> void:
	# El aleteo: las alas "respiran" rápido; en el telegrafo, frenético.
	_t += delta
	var ritmo := 22.0 if _estado == Estado.TELEGRAFO else 11.0
	var f := sin(_t * ritmo)
	_alas.scale = Vector3(1.0 - f * 0.06, 1.0 + f * 0.16, 1.0)


func _physics_process(delta: float) -> void:
	# SIN super(): el murciélago no usa gravedad. Reutilizamos la
	# persecución del padre y le añadimos la altura de vuelo.
	if _estado == Estado.CAZANDO:
		_chase()
		var bob := sin(_t * 2.6) * 0.22
		velocity.y = (ALTURA_VUELO + bob - global_position.y) * 4.0
	_tick_attack(delta)
	move_and_slide()


func _tick_attack(delta: float) -> void:
	_cooldown = maxf(_cooldown - delta, 0.0)
	if not is_instance_valid(target):
		return

	match _estado:
		Estado.CAZANDO:
			if _cooldown <= 0.0 and global_position.distance_to(target.global_position) <= radio_inicio_picada:
				_estado = Estado.TELEGRAFO
				_timer = 0.0
		Estado.TELEGRAFO:
			_timer += delta
			# Se eleva un poco: tu aviso de que viene el clavado.
			velocity = Vector3(0, 2.4, 0)
			if _timer >= T_TELEGRAFO:
				# Apunta a donde ESTÁS ahorita: si te mueves, falla.
				_objetivo_picada = target.global_position + Vector3(0, 0.9, 0)
				_golpeado_en_picada = false
				_estado = Estado.PICADA
				_timer = 0.0
		Estado.PICADA:
			_timer += delta
			var dir := (_objetivo_picada - global_position)
			if dir.length() < 0.5 or _timer >= T_PICADA_MAX:
				_estado = Estado.CAZANDO
				_cooldown = enfriamiento
				return
			velocity = dir.normalized() * VEL_PICADA
			# ¿Te alcanzó al pasar?
			if not _golpeado_en_picada and global_position.distance_to(target.global_position) <= 1.4:
				_golpeado_en_picada = true
				var health := target.get_node_or_null("Health") as Health
				if health != null:
					health.take_damage(dano_picada)
