shader_type canvas_item;

// Drenado gradual de la vena de vida.
//
// `vida` va de 1.0 (vena llena) a 0.0 (vena seca). El vaciado avanza a lo
// largo de la vena — muere primero en las PUNTAS (arriba-izquierda del
// dibujo) y al final en la BASE del tronco (abajo-derecha) — con un borde
// irregular por ruido, para que se seque de forma orgánica, rama por
// rama, y un destello claro en la frontera del drenado.

uniform float vida : hint_range(0.0, 1.0) = 1.0;
uniform sampler2D ruido : repeat_enable, filter_linear;

void fragment() {
	vec4 color = texture(TEXTURE, UV);

	// Coordenada a lo largo de la vena: 0 en las puntas, 1 en la base,
	// distorsionada por ruido para que la frontera no sea una línea recta
	float n = texture(ruido, UV * 1.5).r - 0.5;
	float coord = (UV.x + UV.y) * 0.5 + n * 0.22;

	// El umbral avanza al perder vida (con márgenes para que vida=1.0
	// muestre TODO y vida=0.0 no deje nada, ni con el ruido extremo)
	float umbral = (1.0 - vida) * 1.4 - 0.18;

	color.a *= smoothstep(umbral - 0.04, umbral + 0.06, coord);

	// Brillo en la frontera: la sangre "retrocediendo"
	float borde = smoothstep(umbral - 0.04, umbral, coord)
		- smoothstep(umbral + 0.02, umbral + 0.10, coord);
	color.rgb += borde * 0.35;

	COLOR = color;
}
