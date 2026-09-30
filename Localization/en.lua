local strings = {
    PRESET_DOT = "Dot", NORMAL = "Normal", TARGET = "Target", BLOCK = "Block",
    CROSSHAIR = "Crosshair", PRESET = "Preset", APPEARANCE = "Appearance",
    CROSSHAIR_OPACITY = "Crosshair Opacity", HUD_OPACITY = "HUD Opacity", HUD = "HUD",
    RESOURCES = "Resources", GCD = "GCD", VISIBILITY = "Visibility",
    ALWAYS = "Always", COMBAT_ONLY = "Combat Only", DYNAMIC = "Dynamic", OFF = "Off",
    EFFECTS = "Effects", LOW_RESOURCE = "Low Resource Warning", CRITICAL_STATE = "Critical State",
    SHIELD = "Shield", HEAVY_CHANNEL = "Heavy Attack / Channel Progress", COMBAT_FEEDBACK = "Combat Feedback",
    TIMING_DESCRIPTION = "Shows estimated Heavy Attack, cast and channel progress. Interrupted actions return to the current GCD. Some special abilities may not provide reliable timing events.",
}
for key, value in pairs(strings) do
    local id = "SI_ONECROSSHAIR_" .. key
    if not _G[id] then ZO_CreateStringId(id, value) end
end
