class_name Botiquin
extends Area3D
## Botiquín de VIDA recogible (antes era caja de munición: en la economía
## del reloj la munición gotea sola del tiempo, y lo que escasea es la
## SANGRE — los enemigos sueltan esto al morir).
##
## Es un Area3D: una ZONA que detecta cuerpos entrando en ella, sin ser
## sólida — el avatar la atraviesa y la señal `body_entered` avisa.
## Al recogerlo cura al jugador y desaparece.

## Vida que cura. Al ser @export, cada botiquín colocado en el nivel (o
## soltado por un enemigo) puede curar distinto desde el Inspector.
@export var curacion: float = 8.0

## Velocidad del giro clásico de "esto se puede agarrar" (rad/s)
@export var spin_speed: float = 1.5

@onready var _collect_sound: AudioStreamPlayer = $CollectSound

func _ready() -> void:
	add_to_group("botiquines")

	# Conexión por CÓDIGO (equivalente a usar el panel Señales del editor,
	# pero autocontenida: la escena funciona sola donde sea que se instancie).
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	# Multiplicar por delta hace el giro constante sin importar los FPS
	rotate_y(spin_speed * delta)

func _on_body_entered(body: Node3D) -> void:
	# Solo recoge quien cargue un nodo Health (el avatar). Los enemigos
	# también son cuerpos y disparan esta señal: para ellos esto es null
	# y el botiquín los ignora.
	var health := body.get_node_or_null("Health") as Health
	if health == null:
		return

	# Salud llena: el botiquín se queda esperando a que te hagan falta
	if health.current_health >= health.max_health:
		return

	health.heal(curacion)
	print("Botiquín recogido: +%.0f de vida → %.0f" % [curacion, health.current_health])

	# GOTCHA de audio: si hiciéramos queue_free() ya, el sonido moriría con
	# el nodo y no se oiría. En su lugar: el botiquín se vuelve invisible e
	# inerte, suena, y SOLO ENTONCES se libera.
	remove_from_group("botiquines")
	# set_deferred: prohibido apagar `monitoring` en medio del callback de
	# física que nos trajo aquí; se pospone al final del frame.
	set_deferred("monitoring", false)
	hide()
	set_process(false)
	_collect_sound.play()
	await get_tree().create_timer(0.5).timeout
	queue_free()
