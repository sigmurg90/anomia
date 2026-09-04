class_name ReloadIndicator
extends Control
## Anillo circular de progreso de recarga, dibujado POR CÓDIGO (sin
## texturas) con la API de dibujo 2D de Godot: cada Control puede
## implementar _draw() y pintar formas propias. queue_redraw() marca el
## nodo "sucio" y Godot vuelve a llamar _draw() en el siguiente frame.

## Radio y grosor del anillo, en píxeles
const RADIUS: float = 42.0
const WIDTH: float = 5.0

## Anillo de fondo (la pista completa, tenue) y arco de progreso
const TRACK_COLOR: Color = Color(1, 1, 1, 0.15)
const FILL_COLOR: Color = Color(1.0, 0.85, 0.4)

var _duration: float = 0.0
var _elapsed: float = 0.0

func _ready() -> void:
	hide()
	# Sin recarga activa no hay nada que animar: el _process se apaga
	set_process(false)

## Muestra el anillo y lo llena de 0 a 100% durante `duration` segundos
func start(duration: float) -> void:
	_duration = maxf(duration, 0.01)
	_elapsed = 0.0
	show()
	set_process(true)
	queue_redraw()

func stop() -> void:
	hide()
	set_process(false)

func _process(delta: float) -> void:
	_elapsed += delta

	if _elapsed >= _duration:
		stop()
		return

	queue_redraw()

func _draw() -> void:
	var center: Vector2 = size * 0.5
	var progress: float = clampf(_elapsed / _duration, 0.0, 1.0)

	# Pista completa de fondo
	draw_arc(center, RADIUS, 0.0, TAU, 64, TRACK_COLOR, WIDTH, true)

	# Arco de progreso: arranca arriba (-90°) y crece en sentido horario
	# (en 2D el eje Y apunta hacia abajo, así que los ángulos positivos
	# giran en sentido horario en pantalla).
	if progress > 0.0:
		draw_arc(center, RADIUS, -TAU / 4.0, -TAU / 4.0 + TAU * progress, 64, FILL_COLOR, WIDTH, true)
