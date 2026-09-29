local O = OneCrosshair
O.ResourceRing = {}
-- Fixed UI-unit geometry; the mean 0.1.1 radius (36+29)/2 grows by 30%.
-- One radial profile is rotated for all four bars, preserving visible gaps.
local geometry = { radius = 42.25, halfSpan = 27, bow = 9,
    thickness = 4, shieldExtra = 2, glowSize = 11, samples = 64 }
local segments = {
    health = { horizontal = true, sign = -1, centered = true },
    shield = { horizontal = true, sign = -1, centered = true },
    bottom = { horizontal = true, sign = 1, centered = true },
    magicka = { sign = -1 }, stamina = { sign = 1 },
}
function O.ResourceRing.New(parent)
    local self = { root = O.Control(parent), arcs = {} }
    self.root:SetAnchor(CENTER, parent, CENTER, 0, 0)
    local extent = 2 * geometry.radius + geometry.glowSize
    self.root:SetDimensions(extent, extent)
    -- Identical rotated shallow bars have a square envelope and small corner
    -- gaps. They remain independent bars rather than full-circle quadrants.
    for _, name in ipairs({ "health", "magicka", "stamina", "bottom", "shield" }) do
        local spec, arc = segments[name], {}
        for i = 1, geometry.samples do
            local t = (i - .5) / geometry.samples
            local u = 2 * t - 1
            local radius = geometry.radius - geometry.bow * u * u
            local x = spec.horizontal and geometry.halfSpan * u or spec.sign * radius
            local y = spec.horizontal and spec.sign * radius or -geometry.halfSpan * u
            local glow = O.Dot(self.root, geometry.glowSize)
            glow:SetTexture("OneCrosshair/Assets/Glow.dds")
            glow:SetAnchor(CENTER, self.root, CENTER, x, y)
            glow:SetDrawLevel(name == "shield" and 3 or 0)
            local dot = O.Dot(self.root, geometry.thickness + (name == "shield" and geometry.shieldExtra or 0))
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
        local coverage = O.Clamp((fill - point.threshold) * geometry.samples + .5)
        local a = coverage * alpha
        point.control:SetColor(color[1], color[2], color[3], a)
        -- The full critical halo never contributes to the solid fill layer.
        local glowAlpha = fullGlow and alpha * fullGlow or (glowing and a * .45 or 0)
        point.glow:SetColor(color[1], color[2], color[3], glowAlpha)
    end
end
