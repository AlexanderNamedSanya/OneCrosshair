local O = OneCrosshair
O.GCD = { idleColor = { .8, .82, .85 }, readyColor = { .26, .88, .38 } }
local LIGHT_ATTACK_SLOT = 1 -- physical Lua slot, unlike zero-based ACTION_BAR_* constants
function O.GCD.New() return { active = false, progress = 0 } end
function O.GCD.Read(self)
    self.active, self.progress, self.ready = false, 0, false
    if not GetSlotCooldownInfo then return self end
    -- Ignore potion/item/individual cooldowns: the explicit global flag is required.
    -- Scan the active bar; a locally cooling slot may mask its global cooldown.
    local bestRemaining, bestDuration = 0, 0
    -- ESO's own actionbar.lua converts these engine constants with +1.
    for slot = ACTION_BAR_FIRST_NORMAL_SLOT_INDEX + 1, ACTION_BAR_ULTIMATE_SLOT_INDEX + 1 do
        local remaining, duration, global, globalSlotType = GetSlotCooldownInfo(slot)
        local abilityCooldown = globalSlotType == ACTION_TYPE_ABILITY or globalSlotType == ACTION_TYPE_CRAFTED_ABILITY
        if global and abilityCooldown and duration > 0 and remaining > bestRemaining then
            bestRemaining, bestDuration = remaining, duration
        end
    end
    if bestRemaining > 0 then
        self.active = true
        self.progress = O.Clamp(1 - bestRemaining / bestDuration)
    end
    -- Derived readiness, not an advertised server-side "optimal weave" event:
    -- a live ability GCD overlaps a currently usable, non-cooling light attack.
    -- No percentage, latency fudge or fixed-duration timer is involved.
    if self.active and IsSlotUsed and IsSlotUsable and ActionSlotHasNonCostStateFailure
        and IsSlotUsed(LIGHT_ATTACK_SLOT) and IsSlotUsable(LIGHT_ATTACK_SLOT)
        and not ActionSlotHasNonCostStateFailure(LIGHT_ATTACK_SLOT) then
        local remaining = GetSlotCooldownInfo(LIGHT_ATTACK_SLOT)
        self.ready = remaining ~= nil and remaining <= 0
    end
    return self
end
function O.GCD.Presentation(self)
    if not self.active then return 1, O.GCD.idleColor, .25 end
    if self.ready then return 1, O.GCD.readyColor, 1 end
    return self.progress, O.GCD.idleColor, 1
end
