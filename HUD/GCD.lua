local O = OneCrosshair
O.GCD = { idleColor = { .8, .82, .85 }, goldColor = { 1, .76, .19 } }
function O.GCD.New() return { active = false, progress = 0 } end
function O.GCD.Read(self)
    self.active, self.progress, self.gold = false, 0, false
    if not GetSlotCooldownInfo then return self end
    -- Ignore potion/item/individual cooldowns: the explicit global flag is required.
    -- Scan the active bar; a locally cooling slot may mask its global cooldown.
    local bestRemaining, bestDuration = 0, 0
    for slot = ACTION_BAR_FIRST_NORMAL_SLOT_INDEX, ACTION_BAR_ULTIMATE_SLOT_INDEX do
        local remaining, duration, global = GetSlotCooldownInfo(slot)
        if global and duration > 0 and remaining > bestRemaining then
            bestRemaining, bestDuration = remaining, duration
        end
    end
    if bestRemaining > 0 then
        self.active = true
        self.progress = O.Clamp(1 - bestRemaining / bestDuration)
    end
    -- Public cooldown data does not identify a reliable weaving window.
    -- Never claim readiness using an arbitrary 70/80/90% threshold.
    return self
end
