local O = OneCrosshair
O.CriticalState = {}
function O.CriticalState.Read(enabled, health)
    local active = enabled and health <= .25
    -- A subdued, full-geometry halo remains visibly distinct from solid HP.
    return active, active and .35 or 1, active and .12 or nil
end
