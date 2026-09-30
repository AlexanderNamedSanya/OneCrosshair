local O = OneCrosshair
-- The first reference: three rays, then open upright/inverted triangles.
-- Crossfade complete silhouettes to keep every corner crisp during transitions.
O.PresetRegistry.Register({
    id = "rays", name = SI_ONECROSSHAIR_PRESET_RAYS,
    elements = {
        { size = 32, texture = "OneCrosshair/Assets/RaysNormal.dds" },
        { size = 32, texture = "OneCrosshair/Assets/RaysTarget.dds" },
        { size = 32, texture = "OneCrosshair/Assets/RaysBlock.dds" },
    },
    states = {
        normal = { { alpha = 1 }, { alpha = 0 }, { alpha = 0 } },
        target = { { alpha = 0 }, { alpha = 1 }, { alpha = 0 } },
        block = { { alpha = 0 }, { alpha = 0 }, { alpha = 1 } },
    },
})
