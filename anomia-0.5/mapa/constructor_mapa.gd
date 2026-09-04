class_name ConstructorMapa
extends Node3D
## constructor_mapa.gd
## --------------------
## El "albañil" del nivel: lee el plano de datos_mapa.gd y construye TODA
## la geometría del mapa al arrancar la escena (_ready):
##
##   - Por cada SALA: su piso y sus muros. Los muros se levantan por
##     segmentos, dejando HUECOS donde el plano dice que hay puerta.
##     Las salas octagonales arman sus 8 caras (con hueco en la cara
##     que tenga puerta).
##   - Por cada PUERTA: el túnel que une las dos salas (piso + paredes
##     laterales) y el MARCO de color del diseño (dos postes + dintel,
##     con material emisivo para que el color se lea de lejos). Por ahora
##     los marcos son decorativos — la lógica de llaves vendrá después y
##     se colgará de estos mismos nodos (cada marco guarda su color).
##
## Todo es geometría simple: BoxMesh + StaticBody3D/CollisionShape3D.
## Nada se modela a mano — si el diseño cambia, se cambia la TABLA.

## --- Dimensiones generales (en metros) -------------------------------------
const ALTO_MURO := 4.5
const GROSOR_MURO := 0.5
const GROSOR_PISO := 0.5
## Ancho del hueco/túnel de cada puerta (los postes del marco comen un
## poco de cada lado, ver ANCHO_POSTE).
const ANCHO_PUERTA := 3.6
## El marco: postes a los lados, dintel arriba (queda un claro de 3.2 m
## de alto para pasar caminando de sobra).
const ANCHO_POSTE := 0.5
const ALTO_CLARO := 3.2
const GROSOR_MARCO := 0.7

## --- Materiales ------------------------------------------------------------
var _mat_piso: StandardMaterial3D
var _mat_muro: StandardMaterial3D
var _mat_metal: StandardMaterial3D
var _mat_barrote: StandardMaterial3D
var _mats_marco: Dictionary = {}

## --- Texturas --------------------------------------------------------------
@export_file_path("*.png") var textura_muros 
@export_file_path("*.png") var textura_piso
## Toda la geometría cuelga de esta región de navegación: así, al final,
## el "horneado" del navmesh encuentra los pisos y muros él solo y los
## enemigos pueden trazar rutas que CRUZAN puertas en vez de rascar
## paredes.
var _region_nav: NavigationRegion3D


func _ready() -> void:
	_preparar_materiales()

	_region_nav = NavigationRegion3D.new()
	_region_nav.name = "Navegacion"
	var nm := NavigationMesh.new()
	nm.agent_radius = 0.6
	nm.agent_height = 1.8
	nm.cell_size = 0.25
	nm.agent_max_climb = 0.4
	nm.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
	_region_nav.navigation_mesh = nm
	add_child(_region_nav)

	# 1) Averiguar, por sala, dónde van los huecos de puerta en sus muros.
	var huecos := _calcular_huecos_por_sala()

	# 2) Levantar cada sala (piso + muros con sus huecos).
	for nombre in DatosMapa.SALAS:
		var sala: Dictionary = DatosMapa.SALAS[nombre]
		if sala["forma"] == "octagono":
			_construir_octagono(nombre, sala, huecos.get(nombre, []))
		else:
			_construir_rectangulo(nombre, sala, huecos.get(nombre, []))

	# 3) Tender los túneles y plantar los marcos de color.
	for puerta in DatosMapa.PUERTAS:
		_construir_puerta(puerta)

	# 4) Hornear el navmesh sobre TODO lo construido (síncrono: es una
	# sola vez al cargar el nivel y el mapa es chico).
	_region_nav.bake_navigation_mesh(false)


func _preparar_materiales() -> void:
	# Muros y pisos con la textura "tinta GRIS" (generada por
	# gen_textura_muros.py). El mapeo TRIPLANAR proyecta la textura desde
	# los ejes del mundo: cada segmento de muro azuleja solo, sin tener
	# que acomodar UVs pieza por pieza.
	_mat_muro = StandardMaterial3D.new()
	_mat_muro.albedo_texture = load(textura_muros)
	_mat_muro.uv1_triplanar = true
	_mat_muro.uv1_scale = Vector3(0.16, 0.16, 0.16)
	_mat_muro.roughness = 0.9

	_mat_piso = StandardMaterial3D.new()
	_mat_piso.albedo_texture = load(textura_piso)
	_mat_piso.uv1_triplanar = true
	_mat_piso.uv1_scale = Vector3(0.09, 0.09, 0.09)
	_mat_piso.roughness = 0.95

	# Metal de las rejas (marco y barrotes, como la referencia del equipo).
	_mat_metal = StandardMaterial3D.new()
	_mat_metal.albedo_color = Color(0.3, 0.31, 0.35)
	_mat_metal.metallic = 0.75
	_mat_metal.roughness = 0.45
	_mat_barrote = StandardMaterial3D.new()
	_mat_barrote.albedo_color = Color(0.2, 0.21, 0.24)
	_mat_barrote.metallic = 0.8
	_mat_barrote.roughness = 0.4

	for nombre in DatosMapa.COLORES:
		var m := StandardMaterial3D.new()
		var c: Color = DatosMapa.COLORES[nombre]
		m.albedo_color = c
		# Emisión: el color de la puerta BRILLA (esfera-faro y tira del
		# dintel) — legible de lejos aunque la luz no le pegue.
		m.emission_enabled = true
		m.emission = c
		m.emission_energy_multiplier = 1.4
		_mats_marco[nombre] = m


## ¿Media sala (del centro a la orilla) en cada eje? Sirve igual para
## rectángulos (mitad del tam) que para octágonos (su "inradio").
func _media_sala(sala: Dictionary) -> Vector2:
	if sala["forma"] == "octagono":
		var r: float = sala["ancho"] / 2.0
		return Vector2(r, r)
	return (sala["tam"] as Vector2) / 2.0


## Recorre las puertas y arma, por sala, la lista de huecos que sus muros
## deben dejar: cada hueco es {"lado": "N/S/E/O", "coord": <x o z del
## centro del hueco>}. El eje se deduce de la posición relativa de las
## dos salas (están alineadas en fila o en columna).
func _calcular_huecos_por_sala() -> Dictionary:
	var huecos: Dictionary = {}
	for puerta in DatosMapa.PUERTAS:
		var a: Dictionary = DatosMapa.SALAS[puerta["a"]]
		var b: Dictionary = DatosMapa.SALAS[puerta["b"]]
		var delta: Vector2 = (b["centro"] as Vector2) - (a["centro"] as Vector2)
		var horizontal := absf(delta.x) > absf(delta.y)
		var lado_a := ""
		var lado_b := ""
		var coord := 0.0
		if horizontal:
			lado_a = "E" if delta.x > 0.0 else "O"
			lado_b = "O" if delta.x > 0.0 else "E"
			coord = (a["centro"].y + b["centro"].y) / 2.0
		else:
			lado_a = "S" if delta.y > 0.0 else "N"
			lado_b = "N" if delta.y > 0.0 else "S"
			coord = (a["centro"].x + b["centro"].x) / 2.0
		huecos.get_or_add(puerta["a"], []).append({"lado": lado_a, "coord": coord})
		huecos.get_or_add(puerta["b"], []).append({"lado": lado_b, "coord": coord})
	return huecos


# ---------------------------------------------------------------------
# SALAS RECTANGULARES
# ---------------------------------------------------------------------

func _construir_rectangulo(nombre: String, sala: Dictionary, huecos: Array) -> void:
	var raiz := Node3D.new()
	raiz.name = "Sala_" + nombre
	_region_nav.add_child(raiz)

	var c: Vector2 = sala["centro"]
	var mitad := _media_sala(sala)

	# Piso (la cara de arriba queda en y = 0).
	_caja(raiz, Vector3(c.x, -GROSOR_PISO / 2.0, c.y),
		Vector3(mitad.x * 2.0, GROSOR_PISO, mitad.y * 2.0), _mat_piso)

	# Los 4 lados. Cada lado es una línea recta que puede traer huecos.
	for lado in ["N", "S", "E", "O"]:
		var huecos_del_lado: Array = []
		for h in huecos:
			if h["lado"] == lado:
				huecos_del_lado.append(h["coord"])
		_muro_con_huecos(raiz, c, mitad, lado, huecos_del_lado)


## Levanta un lado del rectángulo por segmentos, saltándose los huecos.
## El muro corre a lo largo del eje T (x para N/S, z para E/O), centrado
## sobre la línea de la orilla.
func _muro_con_huecos(raiz: Node3D, c: Vector2, mitad: Vector2, lado: String, coords_huecos: Array) -> void:
	var horizontal := lado == "N" or lado == "S"
	var t_ini := (c.x - mitad.x) if horizontal else (c.y - mitad.y)
	var t_fin := (c.x + mitad.x) if horizontal else (c.y + mitad.y)
	var fija := 0.0
	match lado:
		"N": fija = c.y - mitad.y
		"S": fija = c.y + mitad.y
		"E": fija = c.x + mitad.x
		"O": fija = c.x - mitad.x

	coords_huecos.sort()
	var cursor := t_ini
	var cortes: Array = []
	for hc in coords_huecos:
		cortes.append([cursor, hc - ANCHO_PUERTA / 2.0])
		cursor = hc + ANCHO_PUERTA / 2.0
	cortes.append([cursor, t_fin])

	for tramo in cortes:
		var largo: float = tramo[1] - tramo[0]
		if largo < 0.05:
			continue
		var medio: float = (tramo[0] + tramo[1]) / 2.0
		var pos := Vector3(medio, ALTO_MURO / 2.0, fija) if horizontal else Vector3(fija, ALTO_MURO / 2.0, medio)
		var tam := Vector3(largo, ALTO_MURO, GROSOR_MURO) if horizontal else Vector3(GROSOR_MURO, ALTO_MURO, largo)
		_caja(raiz, pos, tam, _mat_muro)


# ---------------------------------------------------------------------
# SALAS OCTAGONALES
# ---------------------------------------------------------------------

## Un octágono regular "de caras planas": 8 muros a 45° uno del otro, a
## distancia inradio del centro. Si una cara cardinal tiene puerta, esa
## cara se parte en dos segmentos dejando el hueco al centro.
func _construir_octagono(nombre: String, sala: Dictionary, huecos: Array) -> void:
	var raiz := Node3D.new()
	raiz.name = "Sala_" + nombre
	_region_nav.add_child(raiz)

	var c: Vector2 = sala["centro"]
	var inradio: float = sala["ancho"] / 2.0
	# Largo de cada cara de un octágono regular con ese inradio.
	var largo_cara := 2.0 * inradio * tan(PI / 8.0)

	# Piso: una caja cuadrada se saldría de las esquinas ochavadas, así
	# que usamos un cilindro de 8 lados = la tapa octagonal exacta.
	var piso := MeshInstance3D.new()
	var malla := CylinderMesh.new()
	malla.top_radius = inradio / cos(PI / 8.0)
	malla.bottom_radius = malla.top_radius
	malla.height = GROSOR_PISO
	malla.radial_segments = 8
	piso.mesh = malla
	piso.material_override = _mat_piso
	# Girado 22.5° para que las caras planas queden en N/S/E/O como en el
	# diagrama (el cilindro nace con un vértice en +X).
	piso.position = Vector3(c.x, -GROSOR_PISO / 2.0, c.y)
	piso.rotation.y = PI / 8.0
	raiz.add_child(piso)
	var cuerpo := StaticBody3D.new()
	var col := CollisionShape3D.new()
	var forma := CylinderShape3D.new()
	forma.radius = malla.top_radius
	forma.height = GROSOR_PISO
	col.shape = forma
	cuerpo.position = piso.position
	cuerpo.add_child(col)
	raiz.add_child(cuerpo)

	# Las 8 caras: ángulo 0 = cara Este, y de ahí cada 45°.
	for i in range(8):
		var ang := i * PI / 4.0
		var dir := Vector2(cos(ang), sin(ang))
		var centro_cara := c + dir * inradio
		# ¿Esta cara cardinal tiene puerta? (nuestros octágonos solo
		# conectan por Este/Oeste, pero se revisa en general)
		var con_hueco := false
		for h in huecos:
			var lado_ang: float = {"E": 0.0, "S": PI / 2.0, "O": PI, "N": -PI / 2.0}[h["lado"]]
			if absf(angle_difference(ang, lado_ang)) < 0.01:
				con_hueco = true
		# La caja del muro es larga en su X local; la giramos para que
		# quede perpendicular a la dirección de la cara.
		var giro := atan2(dir.y, -dir.x) + PI / 2.0
		if con_hueco:
			var seg := (largo_cara - ANCHO_PUERTA) / 2.0
			for signo: float in [-1.0, 1.0]:
				var tangente := Vector2(-dir.y, dir.x)
				var pos2 := centro_cara + tangente * signo * (ANCHO_PUERTA / 2.0 + seg / 2.0)
				_caja_girada(raiz, Vector3(pos2.x, ALTO_MURO / 2.0, pos2.y),
					Vector3(seg + 0.3, ALTO_MURO, GROSOR_MURO), giro, _mat_muro)
		else:
			_caja_girada(raiz, Vector3(centro_cara.x, ALTO_MURO / 2.0, centro_cara.y),
				Vector3(largo_cara + 0.6, ALTO_MURO, GROSOR_MURO), giro, _mat_muro)


# ---------------------------------------------------------------------
# PUERTAS: túnel + marco de color
# ---------------------------------------------------------------------

func _construir_puerta(puerta: Dictionary) -> void:
	var a: Dictionary = DatosMapa.SALAS[puerta["a"]]
	var b: Dictionary = DatosMapa.SALAS[puerta["b"]]
	var ca: Vector2 = a["centro"]
	var cb: Vector2 = b["centro"]
	var delta := cb - ca
	var horizontal := absf(delta.x) > absf(delta.y)

	# Bordes enfrentados de ambas salas -> el túnel cubre ese hueco.
	var borde_a := 0.0
	var borde_b := 0.0
	var coord := 0.0
	if horizontal:
		borde_a = ca.x + signf(delta.x) * _media_sala(a).x
		borde_b = cb.x - signf(delta.x) * _media_sala(b).x
		coord = (ca.y + cb.y) / 2.0
	else:
		borde_a = ca.y + signf(delta.y) * _media_sala(a).y
		borde_b = cb.y - signf(delta.y) * _media_sala(b).y
		coord = (ca.x + cb.x) / 2.0

	var medio := (borde_a + borde_b) / 2.0
	var largo := absf(borde_b - borde_a) + 0.6 # un pelo adentro de cada sala, sin rendijas

	# Un nodo "eje de la puerta": todo se construye en su X local y el
	# nodo entero se gira 90° si la puerta es vertical. Así el mismo
	# código sirve para ambas orientaciones.
	var eje := Node3D.new()
	eje.name = "Puerta_%s_%s" % [puerta["a"], puerta["b"]]
	eje.position = Vector3(medio, 0.0, coord) if horizontal else Vector3(coord, 0.0, medio)
	if not horizontal:
		eje.rotation.y = PI / 2.0
	_region_nav.add_child(eje)

	# Piso y paredes laterales del túnel (en locales del eje).
	_caja_local(eje, Vector3(0, -GROSOR_PISO / 2.0, 0),
		Vector3(largo, GROSOR_PISO, ANCHO_PUERTA), _mat_piso)
	for signo in [-1.0, 1.0]:
		_caja_local(eje, Vector3(0, ALTO_MURO / 2.0, signo * (ANCHO_PUERTA / 2.0 + GROSOR_MURO / 2.0)),
			Vector3(largo, ALTO_MURO, GROSOR_MURO), _mat_muro)

	# LA REJA (la referencia del equipo: portón de metal con picos, placa
	# y esfera de color). Guarda su color en metadata para la futura
	# lógica de llaves — cuando existan, el rastrillo podrá BAJAR.
	var mat_color: StandardMaterial3D = _mats_marco[puerta["color"]]
	eje.set_meta("color_puerta", puerta["color"])

	# Marco metálico: dos postes y el dintel.
	for signo in [-1.0, 1.0]:
		_caja_local(eje, Vector3(0, ALTO_CLARO / 2.0, signo * (ANCHO_PUERTA / 2.0 - ANCHO_POSTE / 2.0)),
			Vector3(GROSOR_MARCO, ALTO_CLARO, ANCHO_POSTE), _mat_metal)
	_caja_local(eje, Vector3(0, ALTO_CLARO + (ALTO_MURO - ALTO_CLARO) / 2.0, 0),
		Vector3(GROSOR_MARCO, ALTO_MURO - ALTO_CLARO, ANCHO_PUERTA), _mat_metal)

	# Tira de color emisiva bajo el dintel (se ve al cruzar).
	_caja_local(eje, Vector3(0, ALTO_CLARO - 0.07, 0),
		Vector3(GROSOR_MARCO + 0.06, 0.14, ANCHO_PUERTA - 2.0 * ANCHO_POSTE), mat_color, false)

	# El RASTRILLO LEVANTADO: barrotes con pico colgando del dintel (la
	# reja está "arriba" — cuando lleguen las llaves, bajará). Cuelgan
	# 0.9 m: muy por encima de la cabeza del jugador. Sin colisión.
	var ancho_libre := ANCHO_PUERTA - 2.0 * ANCHO_POSTE
	var num_barrotes := 6
	for k in range(num_barrotes):
		var t := (float(k) + 0.5) / float(num_barrotes) - 0.5
		var z_local := t * ancho_libre
		_caja_local(eje, Vector3(0, ALTO_CLARO - 0.45, z_local),
			Vector3(0.09, 0.9, 0.09), _mat_barrote, false)
		_pico_local(eje, Vector3(0, ALTO_CLARO - 0.9 - 0.13, z_local))

	# Placas talladas a ambos lados del dintel (guiño a la referencia).
	for signo in [-1.0, 1.0]:
		_caja_local(eje, Vector3(signo * (GROSOR_MARCO / 2.0 + 0.04), ALTO_CLARO + (ALTO_MURO - ALTO_CLARO) / 2.0, 0),
			Vector3(0.08, 0.55, 0.85), _mat_barrote, false)

	# LA ESFERA-FARO del color, sobre el dintel: sobresale de la línea de
	# muros, así que desde cualquier sala ves de qué color son las
	# puertas cercanas — orientación gratis.
	var pedestal := MeshInstance3D.new()
	var malla_ped := CylinderMesh.new()
	malla_ped.top_radius = 0.14
	malla_ped.bottom_radius = 0.2
	malla_ped.height = 0.5
	pedestal.mesh = malla_ped
	pedestal.material_override = _mat_metal
	pedestal.position = Vector3(0, ALTO_MURO + 0.25, 0)
	eje.add_child(pedestal)

	var esfera := MeshInstance3D.new()
	var malla_esf := SphereMesh.new()
	malla_esf.radius = 0.34
	malla_esf.height = 0.68
	esfera.mesh = malla_esf
	esfera.material_override = mat_color
	esfera.position = Vector3(0, ALTO_MURO + 0.78, 0)
	esfera.name = "Esfera"
	eje.add_child(esfera)


## Un pico de reja: cono metálico apuntando hacia abajo.
func _pico_local(padre: Node3D, pos_local: Vector3) -> void:
	var pico := MeshInstance3D.new()
	var malla := CylinderMesh.new()
	malla.top_radius = 0.075
	malla.bottom_radius = 0.005
	malla.height = 0.26
	pico.mesh = malla
	pico.material_override = _mat_barrote
	pico.position = pos_local
	padre.add_child(pico)


# ---------------------------------------------------------------------
# LADRILLOS BÁSICOS (caja con malla + colisión)
# ---------------------------------------------------------------------

func _caja(raiz: Node3D, pos: Vector3, tam: Vector3, mat: StandardMaterial3D) -> void:
	_caja_girada(raiz, pos, tam, 0.0, mat)


func _caja_girada(raiz: Node3D, pos: Vector3, tam: Vector3, giro_y: float, mat: StandardMaterial3D) -> void:
	var cuerpo := StaticBody3D.new()
	cuerpo.position = pos
	cuerpo.rotation.y = giro_y
	var visual := MeshInstance3D.new()
	var malla := BoxMesh.new()
	malla.size = tam
	visual.mesh = malla
	visual.material_override = mat
	cuerpo.add_child(visual)
	var col := CollisionShape3D.new()
	var forma := BoxShape3D.new()
	forma.size = tam
	col.shape = forma
	cuerpo.add_child(col)
	raiz.add_child(cuerpo)


## Igual que _caja pero en coordenadas LOCALES de un nodo padre ya
## posicionado/girado (lo usan los túneles de puerta). Las piezas
## decorativas (barrotes altos, tiras, placas) pasan con_colision=false:
## no hace falta chocar con lo que está fuera de tu alcance.
func _caja_local(padre: Node3D, pos_local: Vector3, tam: Vector3, mat: StandardMaterial3D, con_colision: bool = true) -> void:
	var visual := MeshInstance3D.new()
	var malla := BoxMesh.new()
	malla.size = tam
	visual.mesh = malla
	visual.material_override = mat

	if not con_colision:
		visual.position = pos_local
		padre.add_child(visual)
		return

	var cuerpo := StaticBody3D.new()
	cuerpo.position = pos_local
	cuerpo.add_child(visual)
	var col := CollisionShape3D.new()
	var forma := BoxShape3D.new()
	forma.size = tam
	col.shape = forma
	cuerpo.add_child(col)
	padre.add_child(cuerpo)
