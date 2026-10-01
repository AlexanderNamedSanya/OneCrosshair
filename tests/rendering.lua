local O = OneCrosshair
local ring = O.ResourceRing.New(GuiRoot)
local count = 0
for name, arc in pairs(ring.arcs) do
    for _, point in ipairs(arc) do
        assert(point.control.texture == "OneCrosshair/Assets/Stroke.dds")
        assert(point.control.rounding == false)
        count = count + 1 + #point.glows
        for _, glow in ipairs(point.glows) do
            assert(glow.texture == point.control.texture)
        end
    end
    for _, fill in ipairs({0, .1, .25, .5, .75, 1}) do
        local color = { .2, .4, .8 }
        O.ResourceRing.Draw(ring, name, fill, color, .5, true)
        for i, point in ipairs(arc) do
            local expected = O.Clamp((fill - point.threshold) * 64 + .5) * .5
            assert(math.abs(point.control.color[4] - expected) < 1e-9)
            assert(point.control.color[1] == .2 and point.control.color[3] == .8)
            if name == "health" or name == "bottom" or name == "shield" then
                assert(math.abs(point.control.color[4] - arc[65-i].control.color[4]) < 1e-9)
            end
        end
    end
end
assert(count == 1856)
print("PASS textured strokes retain control count, tint, opacity and symmetric fills")
