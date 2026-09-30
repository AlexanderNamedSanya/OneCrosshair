local strings = {
    PRESET_DOT = "Dot", NORMAL = "Normal", TARGET = "Target", BLOCK = "Block",
    CROSSHAIR = "Crosshair", PRESET = "Preset", APPEARANCE = "Appearance",
    CROSSHAIR_OPACITY = "Crosshair Opacity", HUD_OPACITY = "HUD Opacity", HUD = "HUD",
    RESOURCES = "Resources", GCD = "GCD", VISIBILITY = "Visibility",
    ALWAYS = "Always", COMBAT_ONLY = "Combat Only", DYNAMIC = "Dynamic", OFF = "Off",
    EFFECTS = "Effects", LOW_RESOURCE = "Low Resource Warning", CRITICAL_STATE = "Critical State",
    SHIELD = "Shield", HEAVY_CHANNEL = "Heavy Attack / Channel Progress", COMBAT_FEEDBACK = "Combat Feedback",
}
for key, value in pairs(strings) do
    local id = "SI_ONECROSSHAIR_" .. key
    if not _G[id] then ZO_CreateStringId(id, value) end
end
