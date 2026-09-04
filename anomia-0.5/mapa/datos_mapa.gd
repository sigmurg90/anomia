class_name DatosMapa
## datos_mapa.gd
## --------------
## EL PLANO DEL NIVEL COMO DATOS. Aquí vive la traducción 1:1 del diseño
## del mapa (el diagrama de salas y puertas de colores): qué salas hay,
## dónde están, de qué forma/tamaño son, y qué puertas las conectan.
##
## constructor_mapa.gd lee estas tablas y LEVANTA la geometría (pisos,
## muros con sus huecos, túneles y marcos de puerta) solito. La gracia de
## tener el mapa como datos:
##   - Cambiar el layout = editar esta tabla, no re-modelar nada.
##   - Cuando toque la lógica de LLAVES, cada puerta ya sabe su color:
##     solo habrá que darle comportamiento al marco, no re-construir nada.
##
## Convenciones:
##   - Coordenadas en METROS sobre el plano XZ (xderecha, z abajo como en
##     el diagrama), 1 px del diagrama ≈ 0.1 m. El mapa queda centrado
##     cerca del origen.
##   - "centro" es el centro de la sala; "tam" es (ancho, fondo) para las
##     rectangulares; las octagonales usan "ancho" (distancia entre caras
##     planas opuestas).

## --- Paleta de las puertas (los colores del diseño) ------------------------
const COLORES := {
	"amarillo": Color(0.92, 0.72, 0.06),
	"palido": Color(0.75, 0.85, 0.83),
	"magenta": Color(0.64, 0.31, 0.64),
	"naranja": Color(0.91, 0.35, 0.12),
	"verde": Color(0.42, 0.75, 0.25),
	"marino": Color(0.17, 0.31, 0.63),
	"celeste": Color(0.16, 0.64, 0.91),
}

## --- Salas -----------------------------------------------------------------
## La retícula: columnas en x = -24 / -8 / +8 / +24 y filas en z = -16 / 0
## / +16 (cuadros de 15 m con 1 m de separación); los octágonos rematan a
## los lados. "pasillo" y "centro_der" son las salas chaparras del diseño.
const SALAS := {
	"oct_izq": {"forma": "octagono", "centro": Vector2(-42.3, 0.0), "ancho": 19.5},
	"pasillo": {"forma": "rect", "centro": Vector2(-24.0, 0.0), "tam": Vector2(15.0, 9.0)},
	"arriba_izq": {"forma": "rect", "centro": Vector2(-24.0, -16.0), "tam": Vector2(15.0, 15.0)},
	"abajo_izq": {"forma": "rect", "centro": Vector2(-24.0, 16.0), "tam": Vector2(15.0, 15.0)},
	"arriba_centro": {"forma": "rect", "centro": Vector2(-8.0, -16.0), "tam": Vector2(15.0, 15.0)},
	"centro": {"forma": "rect", "centro": Vector2(-8.0, 0.0), "tam": Vector2(15.0, 15.0)},
	"abajo_centro": {"forma": "rect", "centro": Vector2(-8.0, 16.0), "tam": Vector2(15.0, 15.0)},
	"arriba_der": {"forma": "rect", "centro": Vector2(8.0, -16.0), "tam": Vector2(15.0, 15.0)},
	"centro_der": {"forma": "rect", "centro": Vector2(8.0, 0.0), "tam": Vector2(15.0, 9.0)},
	"abajo_der": {"forma": "rect", "centro": Vector2(8.0, 16.0), "tam": Vector2(15.0, 15.0)},
	"ancho": {"forma": "rect", "centro": Vector2(24.0, 0.0), "tam": Vector2(15.0, 15.0)},
	"oct_der": {"forma": "octagono", "centro": Vector2(42.3, 0.0), "ancho": 19.5},
}

## --- Puertas ---------------------------------------------------------------
## Cada puerta conecta dos salas VECINAS (alineadas en fila o columna) y
## trae el color del diseño. El constructor deduce solo el eje, el hueco
## en cada muro y el túnel que las une.
const PUERTAS := [
	{"a": "oct_izq", "b": "pasillo", "color": "amarillo"},
	{"a": "pasillo", "b": "arriba_izq", "color": "palido"},
	{"a": "pasillo", "b": "abajo_izq", "color": "palido"},
	{"a": "pasillo", "b": "centro", "color": "amarillo"},
	{"a": "arriba_izq", "b": "arriba_centro", "color": "palido"},
	{"a": "arriba_centro", "b": "arriba_der", "color": "magenta"},
	{"a": "centro", "b": "centro_der", "color": "naranja"},
	{"a": "arriba_der", "b": "centro_der", "color": "naranja"},
	{"a": "centro_der", "b": "abajo_der", "color": "verde"},
	{"a": "abajo_izq", "b": "abajo_centro", "color": "palido"},
	{"a": "abajo_centro", "b": "abajo_der", "color": "marino"},
	{"a": "centro_der", "b": "ancho", "color": "verde"},
	{"a": "ancho", "b": "oct_der", "color": "celeste"},
]

## --- Puntos especiales del diseño -----------------------------------------
## La "diana" del diagrama = dónde nace el jugador; el puntito del pasillo
## = un pickup de munición. (Las llaves de cada sala vendrán después.)
const SALA_INICIO := "oct_izq"
const SALA_PICKUP := "pasillo"

## --- Enemigos (segunda lámina del diseño) ----------------------------------
## Transcripción figura-por-figura del diagrama de spawns del equipo:
##   triángulo = "vampiro" (murciélago), cuadrado = "calaca",
##   círculo = "ojos"; el color de la figura = variante (0 amarillo,
##   1 rojo, 2 azul — los mismos índices del arma).
## "pos" es el desplazamiento en metros desde el centro de la sala.
## (El octágono de inicio no tiene enemigos: sus figuritas del diagrama
## son la leyenda, no spawns.)
const ENEMIGOS := {
	"arriba_izq": [
		{"tipo": "vampiro", "color": 1, "pos": Vector2(-1.0, -4.0)},
		{"tipo": "vampiro", "color": 1, "pos": Vector2(-4.0, 2.0)},
		{"tipo": "vampiro", "color": 0, "pos": Vector2(3.0, 2.5)},
	],
	"pasillo": [
		{"tipo": "vampiro", "color": 2, "pos": Vector2(3.0, -2.0)},
		{"tipo": "vampiro", "color": 1, "pos": Vector2(-2.5, 2.0)},
		{"tipo": "vampiro", "color": 0, "pos": Vector2(2.5, 2.0)},
	],
	"abajo_izq": [
		{"tipo": "vampiro", "color": 2, "pos": Vector2(-1.5, -2.5)},
		{"tipo": "vampiro", "color": 2, "pos": Vector2(2.5, -3.0)},
		{"tipo": "vampiro", "color": 0, "pos": Vector2(-3.5, 2.0)},
	],
	"arriba_centro": [
		{"tipo": "calaca", "color": 0, "pos": Vector2(-3.0, -3.0)},
		{"tipo": "vampiro", "color": 2, "pos": Vector2(3.0, -3.5)},
		{"tipo": "vampiro", "color": 2, "pos": Vector2(-3.0, 1.0)},
		{"tipo": "calaca", "color": 0, "pos": Vector2(3.0, 1.5)},
	],
	"centro": [
		{"tipo": "ojos", "color": 2, "pos": Vector2(-2.0, -3.0)},
		{"tipo": "ojos", "color": 0, "pos": Vector2(3.0, 0.0)},
		{"tipo": "ojos", "color": 1, "pos": Vector2(-2.0, 3.5)},
	],
	"arriba_der": [
		{"tipo": "calaca", "color": 2, "pos": Vector2(1.5, -3.5)},
		{"tipo": "calaca", "color": 1, "pos": Vector2(-3.5, 0.5)},
		{"tipo": "calaca", "color": 1, "pos": Vector2(3.0, 2.5)},
	],
	"centro_der": [
		{"tipo": "calaca", "color": 2, "pos": Vector2(-3.0, 0.0)},
		{"tipo": "calaca", "color": 0, "pos": Vector2(3.0, 0.5)},
	],
	"abajo_centro": [
		{"tipo": "calaca", "color": 2, "pos": Vector2(-3.0, -2.5)},
		{"tipo": "vampiro", "color": 0, "pos": Vector2(2.5, -3.0)},
		{"tipo": "vampiro", "color": 0, "pos": Vector2(-2.5, 0.5)},
		{"tipo": "calaca", "color": 1, "pos": Vector2(3.0, 3.0)},
	],
	"abajo_der": [
		{"tipo": "calaca", "color": 1, "pos": Vector2(-2.0, -3.0)},
		{"tipo": "calaca", "color": 1, "pos": Vector2(3.0, -2.5)},
		{"tipo": "calaca", "color": 0, "pos": Vector2(-0.5, 2.5)},
	],
	"ancho": [
		{"tipo": "vampiro", "color": 2, "pos": Vector2(-3.0, -3.0)},
		{"tipo": "vampiro", "color": 0, "pos": Vector2(2.5, -3.5)},
		{"tipo": "vampiro", "color": 1, "pos": Vector2(-4.0, 2.5)},
		{"tipo": "vampiro", "color": 0, "pos": Vector2(0.5, 2.0)},
		{"tipo": "vampiro", "color": 0, "pos": Vector2(3.5, 0.5)},
	],
	"oct_der": [
		{"tipo": "ojos", "color": 0, "pos": Vector2(-4.0, -3.5)},
		{"tipo": "ojos", "color": 2, "pos": Vector2(0.0, 0.0)},
		{"tipo": "ojos", "color": 1, "pos": Vector2(-3.5, 3.0)},
		{"tipo": "vampiro", "color": 0, "pos": Vector2(3.0, -4.0)},
		{"tipo": "vampiro", "color": 2, "pos": Vector2(4.5, 0.0)},
		{"tipo": "vampiro", "color": 1, "pos": Vector2(3.5, 3.5)},
	],
}
