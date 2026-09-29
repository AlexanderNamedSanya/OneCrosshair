local O = OneCrosshair
O.CriticalState = {}
function O.CriticalState.Read(enabled, health)
    local active = enabled and health <= .25
    return active, active and .35 or 1
end
