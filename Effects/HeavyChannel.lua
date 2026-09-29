local O = OneCrosshair
O.HeavyChannel = { supported = false }
-- A presentation boundary for an authoritative timing provider. Public 101051
-- has ability tooltip cast durations, but no general active player cast snapshot
-- with reliable early release/cancel. No built-in provider is registered.
-- A future verified integration may supply Read(now) -> {startMs,endMs,active}.
-- Polling the provider every frame ensures cancellation restores GCD immediately.
function O.HeavyChannel.Read(enabled, now)
    local provider = O.HeavyChannel.provider
    if not enabled or not provider then return nil end
    local timing = provider.Read(now)
    if not timing or not timing.active or timing.endMs <= timing.startMs or now >= timing.endMs then return nil end
    return O.Clamp((now - timing.startMs) / (timing.endMs - timing.startMs))
end
