"""Original white alpha stroke for ESO native lines; no colors or game art.

U runs along the line, V across its thickness. Endpoints remain opaque to
avoid seams between the ring's existing chords. The outer 10% on each side
uses a smooth alpha ramp. Render at nominal thickness / .9 so the half-alpha
contours retain the approved thickness, with a small transparent fringe.
"""
from pathlib import Path
from PIL import Image

SIZE = 256
image = Image.new("RGBA", (SIZE, SIZE))
for y in range(SIZE):
    distance = min(y, SIZE - 1 - y) / (SIZE - 1)
    t = min(1, distance / .10)
    alpha = round(255 * t * t * (3 - 2 * t))
    for x in range(SIZE):
        image.putpixel((x, y), (255, 255, 255, alpha))
image.save(Path(__file__).resolve().parents[1] / "Assets" / "Stroke.dds")
