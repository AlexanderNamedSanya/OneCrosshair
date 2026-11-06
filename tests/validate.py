"""Run with Python and lupa installed (uses its Lua 5.1 runtime)."""
from pathlib import Path
import re
from lupa.lua51 import LuaRuntime

ROOT = Path(__file__).resolve().parents[1]
ADDON = ROOT / "OneCrosshair"
lua = LuaRuntime(unpack_returned_tuples=True)
compile_lua = lua.eval("function(source, name) local f, err = loadstring(source, name); assert(f, err) end")
files = list(ADDON.rglob("*.lua"))
for path in files:
    compile_lua(path.read_text(encoding="utf-8-sig"), str(path))

def load(path):
    lua.execute((ADDON / path).read_text(encoding="utf-8-sig"))

lua.execute('''
strings = {}
function ZO_CreateStringId(key, value) _G[key] = key; strings[key] = value end
function SafeAddString(key, value) assert(key); strings[key] = value end
function GetString(key) return assert(strings[key]) end
''')
load("Localization/en.lua")
english = dict(lua.globals().strings.items())
assert len(english) == 29
for path in (ADDON / "Localization").glob("*.lua"):
    if path.name == "en.lua":
        continue
    lua.execute("strings = {}")
    load("Localization/" + path.name)
    translated = dict(lua.globals().strings.items())
    assert translated.keys() == english.keys(), path.name
    assert all(translated.values()), path.name

load("Core/Namespace.lua")
load("Core/Config.lua")
load("Crosshair/PresetRegistry.lua")
for name in ("Dot", "LargeDot", "Rays", "Diamonds", "ESO"):
    load("Crosshair/Presets/" + name + ".lua")
load("Settings/Settings.lua")
lua.execute('''
world = "EU Megaserver"
function GetWorldName() return world end
function GetDisplayName() return "@test" end
OneCrosshairSavedVariables = { Default = { ["@test"] = { ["$AccountWide"] = {
    version = 1, resources = false, preset = "rays", crosshairOpacity = .3,
    resourceRadius = 63.25, criticalState = true, customLegacyField = "keep"
} } } }
local legacy = OneCrosshairSavedVariables.Default["@test"]["$AccountWide"]
ZO_SavedVars = {}
function ZO_SavedVars:NewAccountWide(name, version, namespace, defaults, profile)
    assert(version == 1 and namespace == nil and profile == world)
    local root = _G[name]; root[profile] = root[profile] or {}
    local account = root[profile]; account["@test"] = account["@test"] or {}
    local data = account["@test"]["$AccountWide"] or { version = version }
    account["@test"]["$AccountWide"] = data
    return setmetatable({default = defaults}, {__index = data, __newindex = data})
end
local O = OneCrosshair
settings = O.Settings.Load()
assert(settings.resources == false and settings.preset == "rays")
assert(settings.crosshairOpacity == .3 and settings.resourceRadius == 63.25)
assert(settings.gcd == true and settings.hudOpacity == O.Config.hudOpacity)
settings.resources = true; settings.crosshairOpacity = .7
assert(O.Settings.Load().resources and O.Settings.Load().crosshairOpacity == .7)
world = "NA Megaserver"
local na = O.Settings.Load()
assert(na.resources == false and na.crosshairOpacity == .3)
na.crosshairOpacity = .9
world = "EU Megaserver"
assert(O.Settings.Load().crosshairOpacity == .7)
assert(legacy.crosshairOpacity == .3 and legacy.customLegacyField == "keep" and legacy.criticalState)
-- Existing server values take priority over legacy data, even on first migration.
world = "PTS"
OneCrosshairSavedVariables.PTS = { ["@test"] = { ["$AccountWide"] = {
    version = 1, crosshairOpacity = .8, resources = true,
    resourceRadius = 999, resourceThickness = 0, resourceLength = -1,
    hudOpacity = 0/0, preset = "invalid", visibility = "invalid"
} } }
local pts = O.Settings.Load()
assert(pts.resources and pts.crosshairOpacity == .8)
assert(pts.resourceRadius == 100 and pts.resourceThickness == 1 and pts.resourceLength == 0)
assert(pts.hudOpacity == O.Config.hudOpacity and pts.preset == "dot" and pts.visibility == "DYNAMIC")
pts.crosshairOpacity = math.huge; pts.resources = "invalid"
assert(O.Settings.Load().crosshairOpacity == O.Config.crosshairOpacity and pts.resources == true)
-- Fresh install uses defaults, not any other account's settings.
OneCrosshairSavedVariables = {}
settings = O.Settings.Load()
for key, value in pairs(O.Settings.defaults) do assert(settings[key] == value, key) end
-- Verify every editable option has a working default and setter.
local refreshes = 0
O.Preview = { Refresh = function() refreshes = refreshes + 1 end }
LibAddonMenu2 = {
    RegisterAddonPanel = function(_, _, panel) assert(panel.registerForDefaults); return {} end,
    RegisterOptionControls = function(_, _, options) controls = options end
}
CALLBACK_MANAGER = { RegisterCallback = function() end }
O.Settings.Initialize(settings)
local sliders, editable = 0, 0
for _, option in ipairs(controls) do
    if option.getFunc then
        editable = editable + 1
        assert(option.default ~= nil)
        if option.type == "slider" then
            sliders = sliders + 1
            option.setFunc(option.min); assert(option.getFunc() == option.min)
            option.setFunc(option.max); assert(option.getFunc() == option.max)
        elseif option.type == "checkbox" then
            option.setFunc(false); assert(option.getFunc() == false)
        elseif option.type == "dropdown" then
            for _, value in ipairs(option.choicesValues) do
                option.setFunc(value); assert(option.getFunc() == value)
            end
        end
        option.setFunc(option.default); assert(option.getFunc() == option.default)
    end
end
assert(sliders == 5 and editable == 12 and refreshes > 0)
for key, value in pairs(O.Settings.defaults) do assert(settings[key] == value, key) end
''')

load("Effects/HeavyChannelData.lua")
load("Effects/HeavyChannel.lua")
for name in set(re.findall(r"\bEVENT_[A-Z_]+", (ADDON / "Effects/HeavyChannel.lua").read_text())):
    lua.globals()[name] = name
lua.execute('''
REGISTER_FILTER_ABILITY_ID = "ability"
REGISTER_FILTER_SOURCE_COMBAT_UNIT_TYPE = "source"
COMBAT_UNIT_TYPE_PLAYER = 1
local events, filters = {}, {}
EVENT_MANAGER = {
    RegisterForEvent = function(_, name, event, callback) events[name] = event end,
    AddFilterForEvent = function(_, name, event, filter, value)
        assert(events[name] == event)
        filters[name] = filters[name] or {}; filters[name][filter] = value
    end
}
OneCrosshair.HeavyChannel.Initialize(settings)
local count = 0
for id in pairs(OneCrosshair.HeavyChannelData.beams) do
    local name = "OneCrosshairTimingEffect" .. id
    assert(events[name] == EVENT_EFFECT_CHANGED)
    assert(filters[name].ability == id and filters[name].source == COMBAT_UNIT_TYPE_PLAYER)
    count = count + 1
end
assert(count == 3 and not events.OneCrosshairTimingEffect)
''')

load("Effects/CombatFeedback.lua")
lua.execute('''
local handlers = {}
EVENT_MANAGER.RegisterForEvent = function(_, name, _, callback) handlers[name] = callback end
EVENT_MANAGER.AddFilterForEvent = function() end
local now, pulses = 1000, 0
function GetFrameTimeMilliseconds() return now end
function GetSlotBoundId() return 42 end
ACTION_TYPE_CRAFTED_ABILITY = 100
function GetSlotType() return ACTION_TYPE_CRAFTED_ABILITY end
function GetAbilityIdForCraftedAbilityId(id) assert(id == 42); return 999 end
ACTION_BAR_FIRST_NORMAL_SLOT_INDEX = 2
COMBAT_UNIT_TYPE_NONE = 0
ACTION_RESULT_DAMAGE = 10
ACTION_RESULT_DOT_TICK = 11
ACTION_SLOT_TYPE_NORMAL_ABILITY = 20
OneCrosshair.CrosshairController = { Pulse = function() pulses = pulses + 1 end }
OneCrosshair.CombatFeedback.Initialize({combatFeedback = true}, {})
local function hit(result, id)
    handlers.OneCrosshairFeedback(nil, result, false, nil, nil,
        ACTION_SLOT_TYPE_NORMAL_ABILITY, nil, COMBAT_UNIT_TYPE_PLAYER, nil, 2,
        nil, nil, nil, nil, nil, nil, id)
end
handlers.OneCrosshairAction(nil, 3)
hit(ACTION_RESULT_DAMAGE, 42); assert(pulses == 0)
hit(ACTION_RESULT_DOT_TICK, 999); assert(pulses == 0)
hit(ACTION_RESULT_DAMAGE, 999); assert(pulses == 1)
now = now + 200
hit(ACTION_RESULT_DAMAGE, 999); assert(pulses == 1) -- consume once
handlers.OneCrosshairAction(nil, 3)
now = now + 1600
hit(ACTION_RESULT_DAMAGE, 999); assert(pulses == 1) -- expired action
''')

manifest = (ADDON / "OneCrosshair.txt").read_text(encoding="utf-8-sig")
assert "## DependsOn: LibAddonMenu-2.0>=43" in manifest
version = re.search(r"^## Version: (.+)$", manifest, re.M).group(1).strip()
assert lua.globals().OneCrosshair.version == version
year, month, release = map(int, version.split("."))
assert f"## AddOnVersion: {year * 10000 + month * 100 + release}" in manifest
for line in manifest.splitlines():
    if line and not line.startswith("#"):
        assert (ADDON / line.replace("$(language)", "en")).is_file(), line
print(f"PASS: {len(files)} Lua files compile in Lua 5.1; 7 locales x 29 strings; migration, server isolation, validation, 12 settings controls, event filters, scribed hit feedback and version consistency.")
