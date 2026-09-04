class_name RelojGenerador
extends Node2D
## reloj_generador.gd
## -------------------
## EL RELOJ DEL CEREBRO: el corazón de la nueva economía del juego.
## Va incrustado en la aguja libre del cerebro-arma (HUD) y su manecilla
## gira sin parar. Cada vuelta completa (duracion_ciclo segundos):
##
##   +1 de munición a LOS TRES frascos  (la munición ya no se recoge:
##                                       GOTEA del tiempo)
##   −vida para el jugador              (el tiempo COBRA en sangre)
##
## Este nodo solo lleva el TIEMPO y lo anuncia con la señal; quién cobra
## y quién reparte lo decide el avatar (avatar.gd), que es el que conoce
## su salud y su arma. La idea de diseño: estás obligado a cazar — los
## enemigos sueltan botiquines de vida, y quedarte quieto te desangra.

signal ciclo_cumplido

## Segundos por vuelta completa de la manecilla.
@export var duracion_ciclo: float = 5.0

## La manecilla del arte apunta un pelín a la izquierda de las 12 en el
## PNG; este offset la endereza para que progreso 0 = mediodía exacto.
@export var rotacion_base: float = 0.24

@onready var _manecilla: Sprite2D = $Manecilla

var _progreso := 0.0
var _tween_pop: Tween


func _process(delta: float) -> void:
	_progreso += delta / duracion_ciclo
	if _progreso >= 1.0:
		_progreso -= 1.0
		ciclo_cumplido.emit()
		_pop()
	_manecilla.rotation = rotacion_base + _progreso * TAU


## Pulso visual al cumplir la vuelta: el reloj "late" para que se lea el
## momento exacto del cobro/regalo aunque no veas los números.
func _pop() -> void:
	if _tween_pop:
		_tween_pop.kill()
	scale = Vector2.ONE * 1.22
	_tween_pop = create_tween()
	_tween_pop.tween_property(self, "scale", Vector2.ONE, 0.3)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
