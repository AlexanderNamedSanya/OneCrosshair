local O = OneCrosshair
O.GCD = { idleColor = { .8, .82, .85 }, readyColor = { .26, .88, .38 } }
local LIGHT_ATTACK_SLOT = 1 -- physical Lua slot, unlike zero-based ACTION_BAR_* constants
function O.GCD.New() return { active = false, progress = 0 } end
local function ReadLightAttackState()
    local state = { available = IsSlotUsed ~= nil and IsSlotUsable ~= nil
        and ActionSlotHasNonCostStateFailure ~= nil and GetSlotCooldownInfo ~= nil }
    -- Evaluate independently: short-circuiting hid which gates failed in-game.
    if IsSlotUsed then state.used = IsSlotUsed(LIGHT_ATTACK_SLOT) end
    if IsSlotUsable then state.usable = IsSlotUsable(LIGHT_ATTACK_SLOT) end
    if ActionSlotHasNonCostStateFailure then state.failure = ActionSlotHasNonCostStateFailure(LIGHT_ATTACK_SLOT) end
    if GetSlotCooldownInfo then
        state.remaining, state.duration, state.global, state.globalSlotType = GetSlotCooldownInfo(LIGHT_ATTACK_SLOT)
    end
    return state
end
function O.GCD.Read(self)
    self.active, self.progress, self.ready = false, 0, false
    self.remaining, self.duration, self.sourceSlot, self.la = 0, 0, nil, nil
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
            self.sourceSlot = slot
        end
    end
    if bestRemaining > 0 then
        self.active = true
        self.remaining, self.duration = bestRemaining, bestDuration
        self.progress = O.Clamp(1 - bestRemaining / bestDuration)
    end
    -- Derived readiness, not an advertised server-side "optimal weave" event:
    -- a live ability GCD overlaps a currently usable light attack.
    -- No percentage, latency fudge or fixed-duration timer is involved.
    -- Client trace: slot 1 mirrors the ability GCD even after its state failure
    -- clears. Only an explicitly matching ability-global timer is exempted;
    -- unrelated or local weapon cooldowns still block readiness.
    if self.active then
        self.la = ReadLightAttackState()
        local la = self.la
        la.sharedGCD = la.global == true
            and (la.globalSlotType == ACTION_TYPE_ABILITY or la.globalSlotType == ACTION_TYPE_CRAFTED_ABILITY)
            and la.duration == self.duration and la.remaining == self.remaining
        la.cooldownClear = la.remaining ~= nil and (la.remaining <= 0 or la.sharedGCD)
        self.ready = la.available and la.used and la.usable and not la.failure
            and la.cooldownClear or false
    end
    O.GCDDiagnostics.Capture(self)
    return self
end
function O.GCD.Presentation(self)
    if not self.active then return 1, O.GCD.idleColor, .25 end
    if self.ready then return 1, O.GCD.readyColor, 1 end
    return self.progress, O.GCD.idleColor, 1
end
