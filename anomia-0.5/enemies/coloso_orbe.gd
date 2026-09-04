class_name ColosoOrbe
extends Area3D
## Orbe que lanza el Coloso en modo PANCITA: viaja en línea recta hacia
## donde estabas al dispararlo (es ESQUIVABLE: muévete). Daña al tocarte
## y revienta contra el suelo o al agotar su vida. Se limpia solo.

const SPEED: float = 9.0
const LIFETIME: float = 3.5
const SPARK_SCENE: PackedScene = preload("res://spark.tscn")

@export var damage: float = 10.0

## Arte del orbe según la variante de color del Coloso que lo lanza
var textura: Texture2D

var _direction: Vector3 = Vector3.FORWARD
var _shooter: Node3D

## El Coloso llama esto justo después de add_child
func setup(direction: Vector3, shooter: Node3D) -> void:
	_direction = direction.normalized()
	_shooter = shooter

func _ready() -> void:
	if textura != null:
		($Sprite as Sprite3D).texture = textura

	body_entered.connect(_on_body_entered)

	# Vida máxima: si no pega nada, desaparece solo
	await get_tree().create_timer(LIFETIME).timeout
	queue_free()

func _physics_process(delta: float) -> void:
	global_position += _direction * SPEED * delta

	# Latido visual: crece y encoge levemente mientras vuela
	var pulse: float = 1.0 + 0.15 * sin(Time.get_ticks_msec() * 0.02)
	scale = Vector3.ONE * pulse

func _on_body_entered(body: Node3D) -> void:
	if body == _shooter:
		return

	# ¿Le pegó al jugador?
	var health := body.get_node_or_null("Health") as Health
	if health != null:
		health.take_damage(damage)

	# Reventar con chispas contra lo que sea (jugador o suelo)
	var spark := SPARK_SCENE.instantiate() as Node3D
	get_tree().root.add_child(spark)
	spark.global_position = global_position
	queue_free()
