class_name SelectorDisparo
extends Node3D
## El cañón de ONDAS del cerebro-arma: tres ondas pintadas en fila que
## muestran la configuración actual de frascos. La más LEJANA es el
## disparo de adelante (x3, onda grande); la más CERCANA al jugador es
## el de atrás (x1, onda chica). Cambian de color al drenarse y
## reemplazarse los frascos — el cañón siempre dice qué vas a disparar.

## Texturas por color [amarillo, rojo, azul] y tamaño de slot [g, m, c]
const TEXTURAS: Array = [
	[
		preload("res://armas_art/onda_amarilla_g.png"),
		preload("res://armas_art/onda_amarilla_m.png"),
		preload("res://armas_art/onda_amarilla_c.png"),
	],
	[
		preload("res://armas_art/onda_roja_g.png"),
		preload("res://armas_art/onda_roja_m.png"),
		preload("res://armas_art/onda_roja_c.png"),
	],
	[
		preload("res://armas_art/onda_azul_g.png"),
		preload("res://armas_art/onda_azul_m.png"),
		preload("res://armas_art/onda_azul_c.png"),
	],
]

## Ancla del cañón EN PANTALLA, medida desde la esquina inferior derecha
## del viewport (igual que el brazo, que es UI anclada a esa esquina).
## Así las ondas quedan pegadas al cerebro sin importar el tamaño o la
## proporción de la ventana — si fueran solo posiciones 3D fijas, se
## separarían del brazo al redimensionar (era exactamente el bug).
@export var ancla_pantalla: Vector2 = Vector2(-370, -300)

## Paso en pantalla entre onda y onda (el tubo escalona hacia la mira)
@export var paso_pantalla: Vector2 = Vector2(-22, -13)

## Profundidad 3D de cada onda [lejos, medio, cerca]: define su tamaño
## aparente y que el convoy disparado las atraviese
const PROFUNDIDADES: Array[float] = [1.35, 1.05, 0.75]

## Orden = slots de la cola: [0] adelante (lejos), [1] medio, [2] atrás
@onready var _ondas: Array[Sprite3D] = [$OndaLejos, $OndaMedio, $OndaCerca]

func _ready() -> void:
	var config := %Config as ConfiguracionDisparo
	config.config_cambiada.connect(mostrar_config)

func _process(_delta: float) -> void:
	# Cada frame: del punto 2D anclado → al punto 3D a esa profundidad
	var camara := get_viewport().get_camera_3d()
	if camara == null:
		return

	var base: Vector2 = get_viewport().get_visible_rect().size + ancla_pantalla

	for i in 3:
		var punto: Vector2 = base + paso_pantalla * float(2 - i)
		_ondas[i].global_position = camara.project_position(punto, PROFUNDIDADES[i])

func mostrar_config(frascos: Array,ondas: Array) -> void:
	for i in 3:
		#var color: int = frascos[i].color
		var color: int = ondas[i].color
		_ondas[i].texture = TEXTURAS[color][i]
