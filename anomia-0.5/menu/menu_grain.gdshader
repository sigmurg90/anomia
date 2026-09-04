shader_type canvas_item;
// menu_grain.gdshader
// --------------------
// El "proyector viejo" de la pantalla de inicio: tres efectos sutiles
// sobre la imagen estática para que se sienta VIVA sin dejar de ser una
// imagen estática:
//   1. TEMBLOR: toda la imagen se desplaza ~2-3 px con un vaivén suave e
//      irregular (suma de senos desfasados ≈ ruido lento y orgánico).
//   2. GRANO de película: ruido por pixel distinto en cada frame.
//   3. PARPADEO: la exposición fluctúa apenas, como lámpara de proyector.

uniform float fuerza_grano : hint_range(0.0, 0.3) = 0.085;
uniform float fuerza_temblor : hint_range(0.0, 0.01) = 0.0016;
uniform float parpadeo : hint_range(0.0, 0.2) = 0.035;

// Hash clásico: convierte un par de números en "azar" determinista.
float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	vec2 temblor = vec2(
		sin(TIME * 9.7) + 0.6 * sin(TIME * 17.3 + 1.7),
		cos(TIME * 8.1 + 0.9) + 0.6 * sin(TIME * 14.9)
	) * fuerza_temblor;

	vec4 col = texture(TEXTURE, UV + temblor);

	float grano = hash(UV * vec2(1920.0, 1080.0) + vec2(TIME * 61.7, TIME * 41.3));
	col.rgb += (grano - 0.5) * fuerza_grano;

	col.rgb *= 1.0 + (hash(vec2(floor(TIME * 24.0), 3.7)) - 0.5) * parpadeo;

	COLOR = col;
}
