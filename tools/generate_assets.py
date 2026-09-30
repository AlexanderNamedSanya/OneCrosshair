"""Generate original antialiased UI textures; requires Pillow, no downloaded art."""
from pathlib import Path
import math
from PIL import Image, ImageDraw

root = Path(__file__).resolve().parents[1] / "Assets"
root.mkdir(exist_ok=True)
for name in ("Disc", "Glow"):
    image = Image.new("RGBA", (64, 64))
    for y in range(64):
        for x in range(64):
            radius = math.hypot(x - 31.5, y - 31.5) / 32
            alpha = max(0, min(1, (0.94 - radius) * 16)) if name == "Disc" else max(0, 1 - radius) ** 2
            image.putpixel((x, y), (255, 255, 255, round(alpha * 255)))
    image.save(root / f"{name}.dds")

# Code-native geometric presets reconstructed from the user's references.
# Draw at 8x and downsample; transparent backgrounds, no screenshot pixels.
SCALE = 8

def shape(name, draw_shape):
    image = Image.new("RGBA", (32 * SCALE, 32 * SCALE))
    draw_shape(ImageDraw.Draw(image))
    image.resize((128, 128), Image.Resampling.LANCZOS).save(root / f"{name}.dds")

def segment(draw, a, b, thickness=1.2):
    dx, dy = b[0] - a[0], b[1] - a[1]
    length = math.hypot(dx, dy)
    nx, ny = -dy / length * thickness / 2, dx / length * thickness / 2
    points = [(a[0]+nx,a[1]+ny),(b[0]+nx,b[1]+ny),
              (b[0]-nx,b[1]-ny),(a[0]-nx,a[1]-ny)]
    draw.polygon([((x+16)*SCALE,(y+16)*SCALE) for x,y in points], fill="white")

def rays(draw):
    for angle in (-90, 30, 150):
        a = math.radians(angle)
        segment(draw, (3*math.cos(a),3*math.sin(a)), (10*math.cos(a),10*math.sin(a)))

def corners(draw, inverted=False):
    # Open triangular corners, with broad gaps along each triangle side.
    vertices = [(0,-10),(-8.66,5),(8.66,5)]
    if inverted:
        vertices = [(-x,-y) for x,y in vertices]
    for i, vertex in enumerate(vertices):
        for neighbor in (vertices[(i+1)%3], vertices[(i+2)%3]):
            dx,dy=neighbor[0]-vertex[0],neighbor[1]-vertex[1]
            ratio=5.2/math.hypot(dx,dy)
            segment(draw, vertex, (vertex[0]+dx*ratio,vertex[1]+dy*ratio))

shape("RaysNormal", rays)
shape("RaysTarget", corners)
shape("RaysBlock", lambda draw: corners(draw, True))
# A centered diamond with transparent margins, rendered at 5 UI units.
image = Image.new("RGBA", (128,128))
ImageDraw.Draw(image).polygon([(64,4),(124,64),(64,124),(4,64)],fill="white")
image.save(root / "Diamond.dds")
