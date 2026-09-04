class_name ConfiguracionDisparo
extends Node
## La configuración de disparo del cerebro-arma: una COLA de 3 frascos.
##
##   [0] ADELANTE  → pega x3 y se drena 3 por disparo
##   [1] EN MEDIO  → pega x2 y se drena 2
##   [2] ATRÁS     → pega x1 y se drena 1 (el más próximo al jugador)
##
## NO hay recarga: se vacía constantemente. Cuando un frasco se agota,
## sale de la cola, los demás avanzan, y al fondo entra un frasco NUEVO
## del color de la PULSERA — que es lo único que el jugador decide
## (con la rueda del mouse).

signal config_cambiada(frascos: Array,ondas: Array)
signal pulsera_cambiada(color: int)

## Drenado por disparo según la posición en la cola
const PESOS: Array[int] = [3, 2, 1]

## Capacidad de cada frasco nuevo
@export var capacidad: float = 30.0

var frascos: Array[Dictionary] = []
var ondas: Array[Dictionary] = [] #Aquí se maneja el orden de las ondas
var pulsera: int = 0


func _ready() -> void:
	# Arranque: un frasco de cada color (amarillo adelante, rojo, azul)
	for color in 3:
		frascos.append({ "color": color, "cantidad": capacidad })
		ondas.append({ "color": color, "cantidad": capacidad })
			
	# Diferido: garantiza que el HUD y el cañón ya se conectaron
	_emitir_config.call_deferred()

func _reset_ammo() -> void:
	frascos.clear()
	ondas.clear()
	for color in 3:
		frascos.append({ "color": color, "cantidad": capacidad })
		ondas.append({ "color": color, "cantidad": capacidad })
	_emitir_config()
	
## Drena los 3 frascos según su posición y devuelve los colores del
## disparo [adelante, medio, atrás]. Los que se vacíen salen de la cola
## y entra un frasco lleno del color de la pulsera por cada uno.
func consumir_disparo() -> Array[int]:
	var colores: Array[int] = []
	var o := 0
	for itm in ondas:
		frascos[itm.color].cantidad -= PESOS[o]
		colores.append(frascos[o].color)
		o+=1
		
	#for i in 3:
		#colores.append(frascos[i].color)
		#frascos[i].cantidad -= PESOS[i]

	#var i := 0
	#while i < frascos.size():
		#if frascos[i].cantidad <= 0.0:
			#frascos.remove_at(i)
			#frascos.append({ "color": pulsera, "cantidad": capacidad })
		#else:
			#i += 1

	_emitir_config()
	return colores

## El RELOJ del cerebro llama esto cada ciclo: +cantidad a CADA frasco de
## la cola (sin rebasar su capacidad). La munición ya no viene de cajas
## ni de recargas: GOTEA del tiempo — y el tiempo cuesta vida (ver
## reloj_generador.gd y avatar.gd).
func regenerar(cantidad: float) -> void:
	for frasco in frascos:
		frasco.cantidad = minf(frasco.cantidad + cantidad, capacidad)
	_emitir_config()


## La rueda del mouse cicla la pulsera (el color del PRÓXIMO frasco)
func cambiar_pulsera(direccion: int) -> void:
	pulsera = posmod(pulsera + direccion, 3)
	pulsera_cambiada.emit(pulsera)

func _emitir_config() -> void:
	#config_cambiada.emit(frascos)
	printt("Frascos:", frascos,"Ondas:", ondas)
	config_cambiada.emit(frascos,ondas)
	
	
func clutch() -> void:
	print("CLUTCH")
	ondas.pop_front()
	ondas.push_back(frascos[pulsera])
	
	#Emite la nueva configuración de ondas
	_emitir_config()
	
	pass
