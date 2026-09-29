local O = OneCrosshair
O.ResourceRing = {}
local segments = {
    health = { horizontal = true, sign = -1, centered = true },
    shield = { horizontal = true, sign = -1, centered = true },
    bottom = { horizontal = true, sign = 1, centered = true },
    magicka = { sign = -1 }, stamina = { sign = 1 },
}
function O.ResourceRing.New(parent)
    local self = { root = O.Control(parent), arcs = {} }
    self.root:SetAnchor(CENTER, parent, CENTER, 0, 0)
    self.root:SetDimensions(76, 66)
    -- Four shallow bowed bars, not quadrants of one ellipse. Their endpoints
    -- remain separated by ~6.4 units (before the rounded 2-unit stroke).
    for _, name in ipairs({ "health", "magicka", "stamina", "bottom", "shield" }) do
        local spec, arc = segments[name], {}
        for i = 1, 64 do
            local t = (i - .5) / 64
            local u = 2 * t - 1
            local x = spec.horizontal and 26 * u or spec.sign * (36 - 6 * u * u)
            local y = spec.horizontal and spec.sign * (29 - 6 * u * u) or -18 * u
            local glow = O.Dot(self.root, 9)
            glow:SetTexture("OneCrosshair/Assets/Glow.dds")
            glow:SetAnchor(CENTER, self.root, CENTER, x, y)
            glow:SetDrawLevel(name == "shield" and 3 or 0)
            local dot = O.Dot(self.root, name == "shield" and 4 or 2)
            dot:SetAnchor(CENTER, self.root, CENTER, x, y)
            dot:SetDrawLevel(name == "shield" and 4 or 2)
            arc[i] = { control = dot, glow = glow, threshold = spec.centered and math.abs(u) or t }
        end
        self.arcs[name] = arc
    end
    return self
end
function O.ResourceRing.Draw(self, name, fill, color, alpha, glowing, fullGlow)
    local arc = self.arcs[name]
    if arc.fill == fill and arc.color == color and arc.alpha == alpha and arc.glowing == glowing
        and arc.fullGlow == fullGlow then return end
    arc.fill, arc.color, arc.alpha, arc.glowing, arc.fullGlow = fill, color, alpha, glowing, fullGlow
    for _, point in ipairs(arc) do
        local coverage = O.Clamp((fill - point.threshold) * 64 + .5)
        local a = coverage * alpha
        point.control:SetColor(color[1], color[2], color[3], a)
        -- The full critical halo never contributes to the solid fill layer.
        local glowAlpha = fullGlow and alpha * fullGlow or (glowing and a * .45 or 0)
        point.glow:SetColor(color[1], color[2], color[3], glowAlpha)
    end
end
