extends CanvasLayer
## HUD del avatar: salud (etiqueta + vena drenándose), la configuración
## de frascos del arma (tres frascos con su nivel REAL de líquido) y la
## pulsera activa. Solo ESCUCHA señales (patrón observador).

## Hojas de frascos por color [amarillo, rojo, azul] — 15 estados de
## llenado cada una (0 = lleno, 14 = vacío)
const HOJAS_FRASCOS: Array = [
	preload("res://armas_art/frascos_amarillo.png"),
	preload("res://armas_art/frascos_rojo.png"),
	preload("res://armas_art/frascos_azul.png"),
]

const TEXTURAS_PULSERA: Array = [
	preload("res://armas_art/pulsera_amarilla.png"),
	preload("res://armas_art/pulsera_roja.png"),
	preload("res://armas_art/pulsera_azul.png"),
]

const ESCALA_PULSERA: float = 0.28

@onready var _health_label: Label = $HealthLabel

## La vena, la pulsera y los frascos son HIJOS del TextureRect del brazo:
## heredan su anclaje y viajan con él en cualquier tamaño de ventana.
#@onready var _vena: Sprite2D = $BrazoArma/VenaVida
@onready var _vena: AnimatedSprite2D = $BrazoArma/VenaVidaSprite
#@onready var vena_vida_sprite: AnimatedSprite2D = $BrazoArma/VenaVidaSprite
@onready var _pulsera: Sprite2D = $BrazoArma/Pulsera
@onready var control_label: Label = $ControlLabel

## Orden = la cola del arma: [adelante, medio, atrás]
@onready var _frascos_hud: Array[Sprite2D] = [
	$BrazoArma/FrascoAdelante,
	$BrazoArma/FrascoMedio,
	$BrazoArma/FrascoAtras,
]

@onready var _health: Health = %Health
@onready var _config: ConfiguracionDisparo = %Config
@onready var _brazo: TextureRect = $BrazoArma

var _tween_vena: Tween
var _tween_pulsera: Tween
var _tween_golpe: Tween

func _ready() -> void:
	_health.changed.connect(_on_health_changed)
	_health.damaged.connect(_on_golpe_flash)
	_config.config_cambiada.connect(_on_config_cambiada)
	_config.pulsera_cambiada.connect(_on_pulsera_cambiada)


## TODO daño (el goteo del reloj o un golpe de enemigo) parpadea EN ROJO
## el conjunto completo del jugador: el BrazoArma y, por herencia de
## modulate, todos sus hijos (vena, frascos, pulsera y el reloj mismo).
## Leve y rápido: un latigazo de 0.22 s, no una alarma.
func _on_golpe_flash(_amount: float) -> void:
	if _tween_golpe:
		_tween_golpe.kill()
	_brazo.modulate = Color(1.9, 0.32, 0.32)
	_tween_golpe = create_tween()
	_tween_golpe.tween_property(_brazo, "modulate", Color.WHITE, 0.22)

	# Estado inicial de la pulsera (la señal solo avisa los cambios)
	_pulsera.texture = TEXTURAS_PULSERA[_config.pulsera]
	_pulsera.scale = Vector2.ONE * ESCALA_PULSERA

## La cola cambió: refrescar color y nivel de líquido de cada frasco
func _on_config_cambiada(frascos: Array,ondas: Array) -> void:
	control_label.text = "Frascos: %s\nOndas: %s" % [frascos,ondas]
	for i in 3:
		var frasco: Dictionary = frascos[i]
		var visor := _frascos_hud[i]
		visor.texture = HOJAS_FRASCOS[frasco.color]

		var vaciado: float = 1.0 - (frasco.cantidad / _config.capacidad)
		visor.frame = clampi(roundi(vaciado * 14.0), 0, 14)

## Cambió la pulsera: nueva textura + pop de confirmación
func _on_pulsera_cambiada(color: int) -> void:
	_pulsera.texture = TEXTURAS_PULSERA[color]

	if _tween_pulsera:
		_tween_pulsera.kill()

	_pulsera.scale = Vector2.ONE * ESCALA_PULSERA * 1.4
	_tween_pulsera = create_tween()
	_tween_pulsera.tween_property(
		_pulsera, "scale", Vector2.ONE * ESCALA_PULSERA, 0.22
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _on_health_changed(current: float, max_health: float) -> void:
	_health_label.text = "SALUD %d" % roundi(current)

	# Rojo de alerta cuando queda poca vida
	var low: bool = current <= max_health * 0.3
	_health_label.add_theme_color_override(
		"font_color",
		Color(0.95, 0.3, 0.3) if low else Color(1, 1, 1),
	)

	# La VENA del brazo es la vida: el shader la drena de forma CONTINUA
	# con el parámetro `vida` (1.0 = llena, 0.0 = seca). El tween recorre
	# todos los estados intermedios — duración proporcional a la sangre
	# perdida — y al recibir daño la vena destella.
	var material := _vena.material as ShaderMaterial
	var vida_actual: float = material.get_shader_parameter("vida")
	var vida_meta: float = current / max_health

	if is_equal_approx(vida_actual, vida_meta):
		return

	var perdiendo: bool = vida_meta < vida_actual

	if _tween_vena:
		_tween_vena.kill()

	_tween_vena = create_tween()
	_tween_vena.tween_property(
		material,
		"shader_parameter/vida",
		vida_meta,
		maxf(absf(vida_meta - vida_actual) * 2.2, 0.25)
	)

	if perdiendo:
		# Destello del golpe (modulate arriba de 1 = brillo sobre blanco)
		_vena.modulate = Color(2.6, 2.6, 2.6)
		_tween_vena.parallel().tween_property(_vena, "modulate", Color.WHITE, 0.35)
