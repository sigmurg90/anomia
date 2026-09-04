extends EnemyBase
## El Pilar: el enemigo original. Toda la persecución, salud y botín
## viven en EnemyBase; aquí solo queda lo SUYO: el golpe por contacto
## con su área de alcance y el tinte rojo como feedback de daño.

@export var attack_damage: float = 10.0
@export var attack_interval: float = 0.8

var _attack_cooldown: float = 0.0

@onready var _mesh: MeshInstance3D = $MeshInstance3D
@onready var _attack_area: Area3D = $Area3D

# Color base del material y color al que se tiende conforme baja la salud
var _base_color: Color
const HURT_COLOR: Color = Color(0.85, 0.12, 0.12)

func _ready() -> void:
	# super._ready() ejecuta la inicialización del padre (salud + grupo);
	# al sobreescribir _ready, GDScript NO llama al del padre por sí solo.
	super._ready()

	# Los materiales en Godot son RECURSOS COMPARTIDOS entre instancias:
	# se duplica una copia propia para teñir este pilar sin afectar al resto.
	var shared_material: Material = _mesh.get_active_material(0)
	if shared_material is StandardMaterial3D:
		var own_material: StandardMaterial3D = shared_material.duplicate()
		_base_color = own_material.albedo_color
		_mesh.material_override = own_material

## Hook de ataque: golpea a quien esté dentro del área y cargue un Health.
## El sondeo (no la señal body_entered) permite daño SOSTENIDO.
func _tick_attack(delta: float) -> void:
	_attack_cooldown = maxf(_attack_cooldown - delta, 0.0)
	if _attack_cooldown > 0.0:
		return

	for body in _attack_area.get_overlapping_bodies():
		var health := body.get_node_or_null("Health") as Health
		if health != null:
			health.take_damage(attack_damage)
			_attack_cooldown = attack_interval
			return

## Hook de feedback: tiñe el material propio hacia rojo según el daño
func _update_hurt_feedback(hurt_ratio: float) -> void:
	var own_material := _mesh.material_override as StandardMaterial3D
	if own_material == null:
		return

	own_material.albedo_color = _base_color.lerp(HURT_COLOR, hurt_ratio)
