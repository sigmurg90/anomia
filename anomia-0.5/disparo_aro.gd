class_name DisparoAro
extends Area3D
## Aro de energía del cerebro-arma: un halo del color del modo activo que
## viaja recto por el mundo, daña lo primero que toca (cuerpos, o las
## manos-área del Coloso) y revienta en chispas. Su tiempo de vida define
## el ALCANCE real del arma: lo que no alcanza en 2 s, no se puede herir.

const SPEED: float = 34.0
const LIFETIME: float = 2.0
const SPARK_SCENE: PackedScene = preload("res://spark.tscn")

var damage: float = 25.0
var color: Color = Color.WHITE

## Tamaño visual según el peso del frasco (adelante grande, atrás chico)
var escala: float = 1.0

var _direction: Vector3 = Vector3.FORWARD
var _shooter: Node3D

@onready var _mesh: MeshInstance3D = $MeshInstance3D

func _ready() -> void:
	scale = Vector3.ONE * escala

	body_entered.connect(_on_impacto)
	# Las manos del Coloso son Area3D disparables: también cuentan
	area_entered.connect(_on_impacto)

	# Material propio tintado del color del disparo (unshaded = brilla solo)
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color
	_mesh.material_override = material

	# Vida máxima: si no toca nada, el aro se disuelve solo
	await get_tree().create_timer(LIFETIME).timeout
	queue_free()

## El arma llama esto justo después de add_child
func lanzar(direccion: Vector3, shooter: Node3D) -> void:
	_direction = direccion.normalized()
	_shooter = shooter

	# El plano del aro queda PERPENDICULAR al vuelo (un halo que avanza):
	# look_at apunta -Z al destino y el giro alinea el eje Y del torus.
	look_at(global_position + _direction)
	rotate_object_local(Vector3.RIGHT, TAU / 4.0)

func _physics_process(delta: float) -> void:
	global_position += _direction * SPEED * delta

func _on_impacto(objetivo: Node3D) -> void:
	if objetivo == _shooter:
		return

	if objetivo.has_method("take_damage"):
		objetivo.take_damage(damage, global_position)

	var spark := SPARK_SCENE.instantiate() as Node3D
	get_tree().root.add_child(spark)
	spark.global_position = global_position
	queue_free()
