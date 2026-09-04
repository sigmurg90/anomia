class_name Health
extends Node
## Componente genérico de salud: puro estado + señales.
##
## No sabe QUIÉN es su dueño ni qué pasa al morir — solo lleva la cuenta
## y avisa. El dueño (avatar hoy; cualquier cosa mañana) decide cómo
## reaccionar conectándose a las señales (patrón observador).

## Cambió la salud (daño o curación). El HUD escucha esta.
signal changed(current: float, max_health: float)

## Recibió daño (no se emite al curar). Para sonidos/efectos de golpe.
signal damaged(amount: float)

## La salud llegó a 0. Se emite UNA sola vez.
signal died

@export var max_health: float = 100.0

var current_health: float
var _dead := false

func _ready() -> void:
	current_health = max_health

	# Diferido: garantiza que los oyentes (HUD) ya se conectaron
	_emit_changed.call_deferred()

func take_damage(amount: float) -> void:
	if _dead or amount <= 0.0:
		return

	current_health = maxf(current_health - amount, 0.0)
	damaged.emit(amount)
	_emit_changed()

	if current_health <= 0.0:
		_dead = true
		died.emit()

func heal(amount: float) -> void:
	if _dead or amount <= 0.0:
		return

	current_health = minf(current_health + amount, max_health)
	_emit_changed()

func _emit_changed() -> void:
	changed.emit(current_health, max_health)
