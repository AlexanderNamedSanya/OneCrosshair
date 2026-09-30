"""Lua 5.1 contract tests; install lupa or use .reference/python. No ESO client needed."""
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / ".reference/python"))
from lupa.lua51 import LuaRuntime

def runtime(locale):
    lua = LuaRuntime(unpack_returned_tuples=True)
    lua.execute((ROOT / "tests/eso_mock.lua").read_text(encoding="utf-8"))
    for line in (ROOT / "OneCrosshair.txt").read_text().splitlines():
        if line.endswith(".lua"):
            path = ROOT / line.replace("$(language)", locale)
            lua.execute(path.read_text(encoding="utf-8"), name=str(path))
    lua.execute('Fire(EVENT_ADD_ON_LOADED, "Unrelated"); assert(OneCrosshair.runtime == nil)')
    lua.execute('Fire(EVENT_ADD_ON_LOADED, "OneCrosshair")')
    return lua

for locale in ("en", "ru", "de", "fr", "es", "jp", "zh"):
    lua = runtime(locale)
    lua.execute('assert(OneCrosshair.runtime); assert(OneCrosshair.settings.preset == "dot")')
    if locale == "ru":
        lua.execute('assert(GetString(SI_ONECROSSHAIR_PRESET_DOT) == "Точка")')
print("PASS manifest load order, initialization, account-wide save and 7 locales")

lua = runtime("en")
lua.execute((ROOT / "tests/behavior.lua").read_text(encoding="utf-8"))
lua.execute((ROOT / "tests/diagnostics.lua").read_text(encoding="utf-8"))

lua.execute((ROOT / "tests/weaving.lua").read_text(encoding="utf-8"))

lua = runtime("en")
lua.execute((ROOT / "tests/heavy_channel.lua").read_text(encoding="utf-8"))

# Verify public API symbols against the inspected upstream reference, when present.
api_path = ROOT / ".reference/API.txt"
if api_path.exists():
    api = api_path.read_text(encoding="utf-8")
    code = "\n".join((ROOT / line.replace("$(language)", "en")).read_text(encoding="utf-8")
                     for line in (ROOT / "OneCrosshair.txt").read_text().splitlines()
                     if line.endswith(".lua"))
    functions = set(re.findall(r"\b((?:Get|Is|Does|Are|ActionSlotHas)[A-Z]\w+)\(", code))
    # GetString is an ESO Lua library function, not an engine API function.
    missing = [name for name in functions - {"GetString"} if f"* {name}(" not in api]
    assert not missing, missing
    constants = set(re.findall(r"\b(?:COMBAT_MECHANIC_FLAGS|ACTION_RESULT|ACTION_TYPE|ACTION_SLOT_TYPE|COMBAT_UNIT_TYPE|EVENT|REGISTER_FILTER|ATTRIBUTE_VISUAL|STAT|ATTRIBUTE|ACTION_BAR|EFFECT_RESULT)_[A-Z_]+\b", code)) - {"EVENT_MANAGER"}
    # Reference-used client globals absent from this public documentation snapshot.
    # Runtime nil-guards and missing-capability tests cover these explicitly.
    optional_results = {"ACTION_RESULT_BEGIN", "ACTION_RESULT_BEGIN_CHANNEL",
                        "ACTION_RESULT_EFFECT_GAINED", "ACTION_RESULT_EFFECT_FADED"}
    assert all(f"* {name}" in api for name in constants - optional_results), sorted(
        name for name in constants - optional_results if f"* {name}" not in api)
    print("PASS public API symbols match 101051; four guarded reference-only result globals excepted")
