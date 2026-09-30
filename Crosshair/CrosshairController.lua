local O = OneCrosshair
local A = O.Animator
O.CrosshairController = {}
function O.CrosshairController.New(parent)
    return { root = O.Control(parent), elements = {}, color = { A.New(1), A.New(1), A.New(1) } }
end
function O.CrosshairController.SetPreset(self, id, state)
    local preset = O.PresetRegistry.Get(id)
    if self.preset == preset then return end
    for _, element in ipairs(self.elements) do element.control:SetHidden(true) end
    self.elements, self.preset = {}, preset
    -- Reuse a control pool across preset switches; element count is unrestricted.
    self.pool = self.pool or {}
    for i, definition in ipairs(preset.elements) do
        local c = self.pool[i] or O.Dot(self.root, definition.size or 3)
        self.pool[i] = c
        c:SetHidden(false)
        c:SetTexture(definition.texture or "OneCrosshair/Assets/Disc.dds")
        local uv = definition.textureCoords or { 0, 1, 0, 1 }
        c:SetTextureCoords(uv[1], uv[2], uv[3], uv[4])
        c:SetDimensions(definition.width or definition.size or 3, definition.height or definition.size or 3)
        local p = preset.states[state or "normal"][i] or {}
        self.elements[i] = { control = c, x = A.New(p.x or 0), y = A.New(p.y or 0),
            alpha = A.New(p.alpha or 1), rotation = A.New(p.rotation or 0) }
    end
    self.pulseStart = nil
end
function O.CrosshairController.Pulse(self, now) self.pulseStart = now end
function O.CrosshairController.Update(self, state, opacity, now, immediate)
    local color = state.combat and { 1, .15, .12 } or (state.pursuit and { 1, .85, .1 } or { 1, 1, 1 })
    for i = 1, 3 do A.To(self.color[i], color[i], now, immediate and 0 or 100) end
    local r, g, b = A.Value(self.color[1], now), A.Value(self.color[2], now), A.Value(self.color[3], now)
    local elapsed = self.pulseStart and now - self.pulseStart or 130
    local pulse = elapsed < 130 and math.sin(math.pi * elapsed / 130) or 0
    self.root:SetAlpha(opacity)
    self.root:SetScale(self.preset.combatFeedback and 1 or 1 + .12 * pulse)
    for i, element in ipairs(self.elements) do
        local p = self.preset.states[state.geometry][i] or { alpha = 0 }
        for _, key in ipairs({ "x", "y", "alpha", "rotation" }) do
            A.To(element[key], p[key] or (key == "alpha" and 1 or 0), now, immediate and 0 or 250)
        end
        local x, y = A.Value(element.x, now), A.Value(element.y, now)
        if self.preset.combatFeedback then x, y = self.preset.combatFeedback(i, x, y, pulse) end
        element.control:ClearAnchors()
        element.control:SetAnchor(CENTER, self.root, CENTER, x, y)
        element.control:SetColor(r, g, b, A.Value(element.alpha, now))
        element.control:SetTextureRotation(A.Value(element.rotation, now))
    end
end
