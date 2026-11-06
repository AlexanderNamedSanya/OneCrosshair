"""Build and verify the installable addon ZIP using only the Python standard library."""
from pathlib import Path
import hashlib
import re
import zipfile

root = Path(__file__).resolve().parents[1]
addon = root / "OneCrosshair"
manifest = (addon / "OneCrosshair.txt").read_text(encoding="utf-8-sig")
version = re.search(r"^## Version: (.+)$", manifest, re.M).group(1).strip()
assert re.fullmatch(r"\d{2}\.\d{2}\.\d+", version)
assert f'version = "{version}"' in (addon / "Core/Namespace.lua").read_text()
files = {p.relative_to(root).as_posix(): p for p in addon.rglob("*") if p.is_file()}
for name in ("README.md", "CHANGELOG.md"):
    files["OneCrosshair/" + name] = root / name
for name, path in files.items():
    assert not any(part.startswith(".") for part in Path(name).parts), name
    assert path.suffix.lower() in {".lua", ".txt", ".dds", ".md"}, name
dist = root / "dist"
dist.mkdir(exist_ok=True)
archive = dist / f"OneCrosshair-{version}.zip"
with zipfile.ZipFile(archive, "w", zipfile.ZIP_DEFLATED) as output:
    for name, path in sorted(files.items()):
        output.write(path, name)
with zipfile.ZipFile(archive) as output:
    assert output.testzip() is None
    assert set(output.namelist()) == files.keys()
    for name, path in files.items():
        assert output.read(name) == path.read_bytes(), name
    for line in manifest.splitlines():
        if line and not line.startswith("#"):
            locales = ("en", "ru", "de", "fr", "es", "jp", "zh") if "$(language)" in line else ("en",)
            for locale in locales:
                assert "OneCrosshair/" + line.replace("$(language)", locale) in files
digest = hashlib.sha256(archive.read_bytes()).hexdigest()
archive.with_suffix(".zip.sha256").write_text(f"{digest}  {archive.name}\n", encoding="ascii")
print(f"Built and verified {archive.name}: {len(files)} files, {archive.stat().st_size} bytes. SHA256 {digest}")
