"""Generate original antialiased UI textures; requires Pillow, no downloaded art."""
from pathlib import Path
import math
from PIL import Image

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
