class_name ArmaCerebro
extends Node3D
## El cerebro-arma del avatar.
##
## Cada disparo es TRIPLE: lanza los 3 frascos de la configuración al
## mismo tiempo, como un convoy de ondas — la de ADELANTE pega x3, la de
## en medio x2 y la más cercana x1. No hay recarga: los frascos se
## drenan y la cola los repone sola con el color de la pulsera (rueda
## del mouse). La estrategia es la MEZCLA, no la munición.

const DISPARO_SCENE: PackedScene = preload("res://disparo_aro.tscn")

## Colores del juego, índice compartido por todo el sistema
const COLORES_DISPARO: Array[Color] = [
	Color(1.0, 0.85, 0.25),
	Color(1.0, 0.28, 0.22),
	Color(0.3, 0.55, 1.0),
]

## Tono del sonido según el color del frasco DELANTERO
const TONOS_DISPARO: Array[float] = [1.0, 0.82, 1.22]

## Separación del convoy a lo largo del vuelo (adelante, medio, atrás)
const OFFSETS_CONVOY: Array[float] = [0.9, 0.55, 0.2]

## Tamaño visual de cada onda del convoy (según su peso 3/2/1)
const ESCALAS_CONVOY: Array[float] = [1.25, 1.0, 0.78]

## Daño de UNA unidad: adelante pega 3 de estas, medio 2 y atrás 1
@export var dano_unidad: float = 4.5

## Segundos mínimos entre disparos (cadencia al mantener presionado)
@export var fire_cooldown: float = 0.25

## Boca del cañón: el convoy nace aquí, junto al cerebro en pantalla
@onready var _muzzle: Marker3D = $Muzzle

## La cola de frascos (nombre único de escena, vive en el avatar)
@onready var _config: ConfiguracionDisparo = %Config

@onready var _shot_sound: AudioStreamPlayer = $ShotSound

var _cooldown_remaining: float = 0.0

## La rueda del mouse llega como EVENTOS de botón (4 = arriba, 5 = abajo)
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("disparo_siguiente"):
		_config.cambiar_pulsera(1)
	elif event.is_action_pressed("disparo_anterior"):
		_config.cambiar_pulsera(-1)

func _physics_process(delta: float) -> void:
	_cooldown_remaining = maxf(_cooldown_remaining - delta, 0.0)

	if Input.is_action_pressed("shoot") and _cooldown_remaining <= 0.0:
		_cooldown_remaining = fire_cooldown
		_shoot()
	if Input.is_action_just_pressed("mouse_clutch"):
		#Lógica del clutch
		_config.clutch()
	if Input.is_action_just_pressed("reset_ammo"):
		_config._reset_ammo()
		

func _shoot() -> void:
	# La cola drena los frascos y nos dice qué colores salen volando
	var colores: Array[int] = _config.consumir_disparo()

	_shot_sound.pitch_scale = TONOS_DISPARO[colores[0]]
	_shot_sound.play()

	# Dirección convergente a la mira: del cañón hacia el punto que la
	# cámara ve a 100 m sobre su eje
	var camara := get_parent() as Camera3D
	var destino: Vector3 = camara.global_position \
		- camara.global_transform.basis.z * 100.0
	var direccion: Vector3 = (destino - _muzzle.global_position).normalized()

	# El convoy: tres ondas simultáneas, escalonadas en el vuelo
	for i in 3:
		var aro := DISPARO_SCENE.instantiate() as DisparoAro
		aro.damage = dano_unidad * ConfiguracionDisparo.PESOS[i]
		#aro.color = COLORES_DISPARO[colores[i]]
		aro.color = COLORES_DISPARO[_config.ondas[i].color]
		aro.escala = ESCALAS_CONVOY[i]
		get_tree().root.add_child(aro)
		aro.global_position = _muzzle.global_position \
			+ direccion * OFFSETS_CONVOY[i]
		aro.lanzar(direccion, owner)
