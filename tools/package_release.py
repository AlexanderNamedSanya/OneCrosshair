"""Build a runtime-only release ZIP; verify every archived file against source."""
from pathlib import Path
import hashlib
import re
import zipfile

ROOT = Path(__file__).resolve().parents[1]
manifest = (ROOT / "OneCrosshair.txt").read_text(encoding="utf-8")
version = re.search(r"^## Version: ([0-9.]+)$", manifest, re.M).group(1)
assert "## Author: oneDOK" in manifest
files = {Path("OneCrosshair.txt")}
for line in manifest.splitlines():
    if line.endswith(".lua"):
        for locale in ("en", "ru", "de", "fr", "es", "jp", "zh"):
            files.add(Path(line.replace("$(language)", locale)))
files.update(path.relative_to(ROOT) for path in (ROOT / "Assets").glob("*.dds"))
for path in files:
    assert not path.is_absolute() and ".." not in path.parts
    assert (ROOT / path).is_file(), path
output = ROOT / "dist"
output.mkdir(exist_ok=True)
archive = output / f"OneCrosshair-{version}.zip"
with zipfile.ZipFile(archive, "w", zipfile.ZIP_DEFLATED) as package:
    for path in sorted(files):
        package.write(ROOT / path, "OneCrosshair/" + path.as_posix())
with zipfile.ZipFile(archive) as package:
    assert package.testzip() is None
    assert len(package.namelist()) == len(files)
    for path in files:
        assert package.read("OneCrosshair/" + path.as_posix()) == (ROOT / path).read_bytes(), path
checksum = hashlib.sha256(archive.read_bytes()).hexdigest()
archive.with_suffix(".zip.sha256").write_text(f"{checksum}  {archive.name}\n", encoding="utf-8")
print(f"Built and verified {len(files)} runtime files: {archive}")
print(f"SHA256 {checksum}")
