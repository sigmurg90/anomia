#!/usr/bin/env python3
"""Generador de las texturas de muro/piso del mapa (estilo "tinta GRIS").

Pinta con puro stdlib de Python dos capas en PPM:
  - base: gradiente índigo profundo + manchas suaves de acuarela +
    haces de luz verticales + grano.
  - venas: ramas pálidas que crecen hacia arriba bifurcándose (paseo
    aleatorio con herencia de dirección), sobre negro.

Luego el Makefile humano es una línea de ImageMagick (ver al final) que
compone base + venas (con y sin desenfoque = brillo) y produce
tex_muro.png y tex_piso.png. Regenerable cuando se quiera: es código,
no un archivo pintado a mano.

Uso:  python3 mapa/gen_textura_muros.py && (los comandos magick de abajo)
"""
import math
import random
import struct

ANCHO, ALTO = 768, 768
random.seed(20260827)  # reproducible: mismas venas en cada regeneración


def guardar_ppm(nombre, buf):
    with open(nombre, "wb") as f:
        f.write(b"P6\n%d %d\n255\n" % (ANCHO, ALTO))
        f.write(bytes(bytearray(buf)))


def idx(x, y):
    return (y * ANCHO + x) * 3


# ---------------------------------------------------------------- base
# Gradiente vertical índigo (más claro arriba, como luz que baja).
ARRIBA = (42, 52, 96)
ABAJO = (14, 18, 38)
base = bytearray(ANCHO * ALTO * 3)
for y in range(ALTO):
    t = y / (ALTO - 1)
    r = ARRIBA[0] * (1 - t) + ABAJO[0] * t
    g = ARRIBA[1] * (1 - t) + ABAJO[1] * t
    b = ARRIBA[2] * (1 - t) + ABAJO[2] * t
    for x in range(ANCHO):
        i = idx(x, y)
        base[i] = int(r)
        base[i + 1] = int(g)
        base[i + 2] = int(b)

# Manchas de acuarela: sumas suaves de "blobs" gaussianos anchos, unos
# que aclaran (azul lavanda) y otros que oscurecen (tinta).
for _ in range(26):
    cx = random.uniform(0, ANCHO)
    cy = random.uniform(0, ALTO)
    radio = random.uniform(90, 240)
    fuerza = random.uniform(-16, 20)
    tinte = (fuerza * 0.9, fuerza * 0.95, fuerza * 1.35)
    x0 = max(0, int(cx - radio * 2.6))
    x1 = min(ANCHO, int(cx + radio * 2.6))
    y0 = max(0, int(cy - radio * 2.6))
    y1 = min(ALTO, int(cy + radio * 2.6))
    inv = 1.0 / (2 * radio * radio)
    for y in range(y0, y1):
        dy2 = (y - cy) * (y - cy)
        for x in range(x0, x1):
            d2 = (x - cx) * (x - cx) + dy2
            w = math.exp(-d2 * inv)
            if w < 0.003:
                continue
            i = idx(x, y)
            for c in range(3):
                v = base[i + c] + tinte[c] * w
                base[i + c] = 0 if v < 0 else (255 if v > 255 else int(v))

# Haces de luz verticales: columnas apenas más claras, con borde suave.
for _ in range(5):
    cx = random.uniform(0, ANCHO)
    medio = random.uniform(26, 60)
    fuerza = random.uniform(9, 16)
    for x in range(ANCHO):
        # distancia horizontal envolvente (la textura repite en X)
        dx = min(abs(x - cx), ANCHO - abs(x - cx))
        w = math.exp(-(dx * dx) / (2 * medio * medio))
        if w < 0.03:
            continue
        for y in range(ALTO):
            i = idx(x, y)
            # el haz se desvanece hacia abajo
            fy = 1.0 - y / ALTO * 0.55
            v = fuerza * w * fy
            for c, extra in ((0, 0.85), (1, 0.9), (2, 1.1)):
                nv = base[i + c] + v * extra
                base[i + c] = 255 if nv > 255 else int(nv)

# Grano leve (que no se vea "plástico")
for _ in range(ANCHO * ALTO // 14):
    x = random.randrange(ANCHO)
    y = random.randrange(ALTO)
    i = idx(x, y)
    d = random.randint(-7, 7)
    for c in range(3):
        v = base[i + c] + d
        base[i + c] = 0 if v < 0 else (255 if v > 255 else v)

guardar_ppm("mapa/_tex_base.ppm", base)

# --------------------------------------------------------------- venas
# Ramas estilo GRIS: nacen abajo, suben serpenteando y se bifurcan.
venas = bytearray(ANCHO * ALTO * 3)  # negro


def punto(x, y, brillo, grosor):
    xi, yi = int(x), int(y)
    for oy in range(-grosor, grosor + 1):
        for ox in range(-grosor, grosor + 1):
            px = (xi + ox) % ANCHO  # envuelve en X para que azuleje
            py = yi + oy
            if 0 <= py < ALTO:
                i = idx(px, py)
                v = venas[i] + brillo // (1 + abs(ox) + abs(oy))
                v = 255 if v > 255 else v
                venas[i] = v
                venas[i + 1] = v
                venas[i + 2] = min(255, int(v * 1.0))


def rama(x, y, angulo, largo, grosor, profundidad):
    """Paseo aleatorio hacia arriba que deja trazo y engendra hijas."""
    paso = 2.2
    for _ in range(int(largo / paso)):
        x += math.cos(angulo) * paso
        y += math.sin(angulo) * paso
        if y < 8 or y > ALTO - 4:
            return
        angulo += random.uniform(-0.11, 0.11)
        # tirar suavemente hacia arriba (las ramas buscan la luz)
        angulo += (-math.pi / 2 - angulo) * 0.03
        punto(x, y, 150, grosor)
        # ¿bifurcar?
        if profundidad > 0 and random.random() < 0.011:
            lado = random.choice((-1, 1))
            rama(x, y, angulo + lado * random.uniform(0.5, 0.95),
				largo * random.uniform(0.3, 0.5), max(0, grosor - 1), profundidad - 1)


# troncos principales repartidos a lo ancho
for k in range(3):
    x0 = (k + random.uniform(0.25, 0.75)) * ANCHO / 3
    rama(x0, ALTO - random.uniform(4, 60), -math.pi / 2 + random.uniform(-0.25, 0.25),
		random.uniform(ALTO * 0.6, ALTO * 0.95), 2, 2)

# motitas de polvo brillante
for _ in range(140):
    punto(random.uniform(0, ANCHO), random.uniform(0, ALTO), random.randint(35, 90), 0)

guardar_ppm("mapa/_tex_venas.ppm", venas)
print("listo: mapa/_tex_base.ppm y mapa/_tex_venas.ppm")
print("ahora compón con magick (ver comentario al final del script)")

# Composición (correr en la raíz del proyecto):
#  magick mapa/_tex_base.ppm \
#    \( mapa/_tex_venas.ppm -blur 0x6 \) -compose screen -composite \
#    \( mapa/_tex_venas.ppm -blur 0x1 \) -compose screen -composite \
#    mapa/tex_muro.png
#  magick mapa/tex_muro.png -modulate 55,85 mapa/tex_piso.png
#  rm mapa/_tex_base.ppm mapa/_tex_venas.ppm
