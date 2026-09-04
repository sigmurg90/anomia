class_name AmmoInventory
extends Node
## Inventario de munición del avatar: solo DATOS y reglas (cuántas balas
## hay y cómo se mueven). No sabe nada de disparos, rayos ni UI — el arma
## le pide balas y el HUD lo escucha. Esa separación permite cambiar de
## arma o de interfaz sin tocar esta lógica.

## Señal propia: se emite cada vez que las cantidades cambian. Quien
## quiera enterarse (el HUD) se conecta; este nodo no conoce a sus oyentes.
signal ammo_changed(in_magazine: int, in_reserve: int)

## Capacidad del cargador
@export var magazine_size: int = 8

## Balas de reserva con las que se inicia
@export var starting_reserve: int = 24

## Tope de reserva: las cajas no se acumulan infinitamente
@export var max_reserve: int = 48

var ammo_in_magazine: int
var ammo_in_reserve: int

func _ready() -> void:
	ammo_in_magazine = magazine_size
	ammo_in_reserve = starting_reserve

	# call_deferred pospone el primer aviso al final del frame: garantiza
	# que el HUD ya se conectó, sin importar el orden de _ready entre nodos.
	_emit_changed.call_deferred()

## Intenta sacar una bala del cargador. Devuelve false si está vacío
## (el arma decide qué hacer: recargar, sonar "click", etc.).
func try_consume_round() -> bool:
	if ammo_in_magazine <= 0:
		return false

	ammo_in_magazine -= 1
	_emit_changed()
	return true

## Suma balas a la reserva (cajas recogidas del nivel, recompensas...).
## Devuelve false si no cupo nada (reserva llena): la caja no se consume.
func add_reserve(amount: int) -> bool:
	if amount <= 0 or ammo_in_reserve >= max_reserve:
		return false

	ammo_in_reserve = mini(ammo_in_reserve + amount, max_reserve)
	_emit_changed()
	return true

## ¿Tiene sentido recargar? (hay reserva y el cargador no está lleno)
func can_reload() -> bool:
	return ammo_in_reserve > 0 and ammo_in_magazine < magazine_size

## Mueve balas de la reserva al cargador hasta llenarlo (o agotarla)
func refill_magazine() -> void:
	var needed: int = magazine_size - ammo_in_magazine
	var moved: int = mini(needed, ammo_in_reserve)

	if moved <= 0:
		return

	ammo_in_magazine += moved
	ammo_in_reserve -= moved
	_emit_changed()

func _emit_changed() -> void:
	ammo_changed.emit(ammo_in_magazine, ammo_in_reserve)
