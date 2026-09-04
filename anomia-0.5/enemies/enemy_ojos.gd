extends EnemyBase
## EL DE LOS OJOS: artillería viviente. Un cuerpo con tres ANILLOS-CUENCA
## habitados por ojos; deriva lento manteniendo distancia (retrocede si
## te acercas) y DISPARA sus ojos como proyectiles, uno por anillo en
## ciclo. El anillo que disparó queda con una esfera BLANCA (vacía) un
## momento — ese parpadeo es su recarga, visible desde lejos.
##
## Los ojos deben verse DENTRO de los anillos desde cualquier ángulo, así
## que este enemigo no usa billboard por sprite: todo el conjunto vive en
## una "Vitrina" (Node3D) que giramos a mano hacia la cámara cada frame —
## cuerpo y ojos rotan como UNA sola lámina y nada se desalinea.

const ORBE_ESCENA: PackedScene = preload("res://enemies/coloso_orbe.tscn")

const CUERPOS: Array = [
	preload("res://enemies/art/ojos_cuerpo_amarillo.png"),
	preload("res://enemies/art/ojos_cuerpo_rojo.png"),
	preload("res://enemies/art/ojos_cuerpo_azul.png"),
]
const OJOS: Array = [
	preload("res://enemies/art/ojos_ojo_amarillo.png"),
	preload("res://enemies/art/ojos_ojo_rojo.png"),
	preload("res://enemies/art/ojos_ojo_azul.png"),
]
const BLANCAS: Array = [
	preload("res://enemies/art/ojos_blanca_amarillo.png"),
	preload("res://enemies/art/ojos_blanca_rojo.png"),
	preload("res://enemies/art/ojos_blanca_azul.png"),
]

@export_enum("Amarillo", "Rojo", "Azul") var variante_color: int = 0

@export var dano_disparo: float = 8.0
@export var cadencia: float = 2.6
@export var alcance_disparo: float = 16.0
## Si te acercas a menos de esto, retrocede (no le gusta el cuerpo a cuerpo)
@export var distancia_comoda: float = 6.0

const T_REGENERA := 1.4

@onready var _vitrina: Node3D = $Vitrina
@onready var _anillos: Array = [$Vitrina/OjoIzq, $Vitrina/OjoCentro, $Vitrina/OjoDer]

var _cooldown := 1.2
var _siguiente_anillo := 0


func _ready() -> void:
	super._ready()
	var cuerpo := $Vitrina/Cuerpo as Sprite3D
	cuerpo.texture = CUERPOS[variante_color]
	cuerpo.pixel_size = 0.00035
	for anillo in _anillos:
		(anillo as Sprite3D).texture = OJOS[variante_color]
		(anillo as Sprite3D).pixel_size = 0.00055


func _process(_delta: float) -> void:
	# La vitrina encara la cámara SOLO en el eje Y (como billboard 2,
	# pero del conjunto entero).
	var cam := get_viewport().get_camera_3d()
	if cam != null:
		var d := cam.global_position - global_position
		_vitrina.rotation.y = atan2(d.x, d.z)


func _tick_attack(delta: float) -> void:
	_cooldown = maxf(_cooldown - delta, 0.0)
	if not is_instance_valid(target):
		return

	var dist := global_position.distance_to(target.global_position)

	# Mantener la distancia: si te le echas encima, recula.
	if dist < distancia_comoda:
		var huida := (global_position - target.global_position)
		huida.y = 0.0
		if huida.length_squared() > 0.01:
			huida = huida.normalized()
			velocity.x = huida.x * 2.2
			velocity.z = huida.z * 2.2

	if _cooldown > 0.0 or dist > alcance_disparo:
		return

	# ¿Hay línea de tiro? (no dispara a través de los muros)
	var origen := (_anillos[_siguiente_anillo] as Sprite3D).global_position
	var destino := target.global_position + Vector3(0, 1.3, 0)
	var q := PhysicsRayQueryParameters3D.create(origen, destino, 1)
	q.exclude = [get_rid()]
	if not get_world_3d().direct_space_state.intersect_ray(q).is_empty():
		return

	_disparar_ojo(origen, destino)
	_cooldown = cadencia


func _disparar_ojo(origen: Vector3, destino: Vector3) -> void:
	var anillo := _anillos[_siguiente_anillo] as Sprite3D
	_siguiente_anillo = (_siguiente_anillo + 1) % _anillos.size()

	# El proyectil ES el orbe del Coloso reutilizado, con cara de ojo.
	var orbe := ORBE_ESCENA.instantiate() as ColosoOrbe
	orbe.textura = OJOS[variante_color]
	orbe.damage = dano_disparo
	get_parent().add_child(orbe)
	orbe.global_position = origen
	orbe.setup(destino - origen, self)

	# El anillo queda VACÍO (esfera blanca) mientras "regenera" el ojo.
	anillo.texture = BLANCAS[variante_color]
	var timer := get_tree().create_timer(T_REGENERA)
	timer.timeout.connect(func() -> void:
		if is_instance_valid(anillo):
			anillo.texture = OJOS[variante_color])
