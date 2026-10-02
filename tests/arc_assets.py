"""Inspect decoded shipping DDS pixels; this does not test ESO rasterization."""
from pathlib import Path
import math
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
extent, radius, tile = 58.75, 45.25, 256
def cell(atlas, frame):
    x, y = frame % 8 * tile, frame // 8 * tile
    return atlas.crop((x, y, x + tile, y + tile)).convert("RGBA")
def coverage(image):
    return sum(image.getchannel("A").getdata())
for name, thickness in (("ArcFill", 5), ("ArcShield", 7)):
    path = ROOT / "Assets" / f"{name}.dds"
    assert path.read_bytes()[84:88] == b"DXT5"
    atlas = Image.open(path)
    assert atlas.size == (2048, 4096)
    sums = [coverage(cell(atlas, i)) for i in range(65)]
    assert sums[0] == 0 and all(a < b for a, b in zip(sums, sums[1:]))
    for i in (16, 32, 48):
        assert abs(sums[i] / sums[64] - i / 64) < .015
    full = cell(atlas, 64)
    assert all(p[:3] == (255, 255, 255) for p in full.getdata())
    assert any(0 < p[3] < 255 for p in full.getdata())
    vertical = [extent - (y + .5) * 2 * extent / tile for y in range(tile // 2)
                if full.getpixel((tile // 2, y))[3] >= 128]
    assert abs(min(vertical) - (radius - thickness / 2)) < .6
    assert abs(max(vertical) - (radius + thickness / 2)) < .6
warning = Image.open(ROOT / "Assets/ArcWarning.dds").convert("RGBA")
assert warning.size == (256, 256)
for distance in (radius - 1, radius + 1):
    y = round((extent - distance) * tile / (2 * extent) - .5)
    assert warning.getpixel((128, y))[3] == 0
print("PASS decoded curved DDS: BC3 format, 65 monotonic fills, fill proportions, nominal radius/thickness, white RGB, alpha edges and outward warning")
