local O = OneCrosshair
O.Runtime = {}
function O.Runtime.New(settings)
    local self = { settings = settings, active = false, visibility = O.VisibilityController.New(),
        health = O.Health.New(), magicka = O.Magicka.New(), stamina = O.Stamina.New(),
        shield = O.Shield.New(), gcd = O.GCD.New() }
    self.root = WINDOW_MANAGER:CreateTopLevelWindow("OneCrosshairHUD")
    self.root:SetAnchor(CENTER, GuiRoot, CENTER, 0, 0)
    self.root:SetDimensions(80, 70)
    self.root:SetMouseEnabled(false)
    self.root:SetHidden(true)
    self.crosshair = O.CrosshairController.New(self.root)
    self.crosshair.root:SetAnchor(CENTER, self.root, CENTER, 0, 0)
    self.ring = O.ResourceRing.New(self.root)
    O.ReticleReplacement.Initialize()
    O.CombatFeedback.Initialize(settings, self.crosshair)
    EVENT_MANAGER:RegisterForEvent(O.name .. "Activated", EVENT_PLAYER_ACTIVATED, function()
        self.active = true
        self.visibility = O.VisibilityController.New()
    end)
    EVENT_MANAGER:RegisterForEvent(O.name .. "Deactivated", EVENT_PLAYER_DEACTIVATED, function()
        self.active = false
        self.root:SetHidden(true)
        O.ReticleReplacement.SetActive(false)
    end)
    -- RegisterForUpdate keeps running while our top-level window is hidden.
    EVENT_MANAGER:RegisterForUpdate(O.name, 16, function() O.Runtime.Update(self) end)
    return self
end
function O.Runtime.Update(self)
    local s, now = self.settings, GetFrameTimeMilliseconds()
    local visible = self.active and IsGameCameraActive() and not IsGameCameraUIModeActive()
        and not IsReticleHidden() and not IsUnitDead("player")
        and (not RETICLE or not RETICLE.control:IsHidden())
    self.root:SetHidden(not visible)
    O.ReticleReplacement.SetActive(visible)
    if not visible then return end
    local state = O.StateController.Read()
    O.CrosshairController.SetPreset(self.crosshair, s.preset, state.geometry)
    O.CrosshairController.Update(self.crosshair, state, s.crosshairOpacity, now)
    local fills = { health = O.Resource.Read(self.health, now), magicka = O.Resource.Read(self.magicka, now),
        stamina = O.Resource.Read(self.stamina, now) }
    local critical, dim = O.CriticalState.Read(s.criticalState, self.health.fraction)
    local healthAlpha
    for _, name in ipairs({ "health", "magicka", "stamina" }) do
        local resource = self[name]
        local alpha = O.VisibilityController.Alpha(self.visibility, name, s.visibility, s.resources,
            state.combat, resource.fraction < 1, now) * s.hudOpacity
        if name == "health" then healthAlpha = alpha else alpha = alpha * dim end
        local glow = name == "health" and critical or (name ~= "health" and O.LowResource.Active(s.lowResource, resource.fraction))
        O.ResourceRing.Draw(self.ring, name, fills[name], resource.color, alpha, glow)
    end
    O.ResourceRing.Draw(self.ring, "shield", O.Shield.Read(self.shield, self.health.maximum, now),
        O.Shield.color, s.shield and healthAlpha or 0, false)
    local gcd = O.GCD.Read(self.gcd)
    local heavy = O.HeavyChannel.Read(s.heavyChannel, now)
    local active = heavy ~= nil or (s.gcd and gcd.active)
    local alpha = O.VisibilityController.Alpha(self.visibility, "bottom", s.visibility,
        s.gcd or heavy ~= nil, state.combat, active, now) * s.hudOpacity
    local fill = heavy or (gcd.active and gcd.progress or 1)
    local color = gcd.gold and heavy == nil and O.GCD.goldColor or O.GCD.idleColor
    O.ResourceRing.Draw(self.ring, "bottom", fill, color, alpha * (active and 1 or .25), false)
end
