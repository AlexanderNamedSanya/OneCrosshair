local O = OneCrosshair
O.ResourceRing = {}
local segments = {
    health = { -130, -50, true }, shield = { -130, -50, true },
    magicka = { 140, 220, false }, stamina = { 40, -40, false },
    bottom = { 50, 130, true },
}
function O.ResourceRing.New(parent)
    local self = { root = O.Control(parent), arcs = {} }
    self.root:SetAnchor(CENTER, parent, CENTER, 0, 0)
    self.root:SetDimensions(76, 66)
    -- Overlapping antialiased discs produce rounded, continuous fixed arcs.
    -- Every preset uses exactly the same geometry.
    for _, name in ipairs({ "health", "magicka", "stamina", "bottom", "shield" }) do
        local spec, arc = segments[name], {}
        for i = 1, 64 do
            local t = (i - .5) / 64
            local angle = math.rad(spec[1] + (spec[2] - spec[1]) * t)
            local x, y = 36 * math.cos(angle), 31 * math.sin(angle)
            local glow = O.Dot(self.root, 9)
            glow:SetTexture("OneCrosshair/Assets/Glow.dds")
            glow:SetAnchor(CENTER, self.root, CENTER, x, y)
            glow:SetDrawLevel(name == "shield" and 3 or 0)
            local dot = O.Dot(self.root, name == "shield" and 4 or 2)
            dot:SetAnchor(CENTER, self.root, CENTER, x, y)
            dot:SetDrawLevel(name == "shield" and 4 or 2)
            arc[i] = { control = dot, glow = glow, threshold = spec[3] and math.abs(t - .5) * 2 or t }
        end
        self.arcs[name] = arc
    end
    return self
end
function O.ResourceRing.Draw(self, name, fill, color, alpha, glowing)
    local arc = self.arcs[name]
    if arc.fill == fill and arc.color == color and arc.alpha == alpha and arc.glowing == glowing then return end
    arc.fill, arc.color, arc.alpha, arc.glowing = fill, color, alpha, glowing
    for _, point in ipairs(arc) do
        local coverage = O.Clamp((fill - point.threshold) * 64 + .5)
        local a = coverage * alpha
        point.control:SetColor(color[1], color[2], color[3], a)
        point.glow:SetColor(color[1], color[2], color[3], glowing and a * .45 or 0)
    end
end
