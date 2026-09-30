-- TEMPORARY slot-1 probe. Remove after client semantics are established.
-- No SavedVariables, extra events/update callbacks, or unsolicited frame output.
local O = OneCrosshair
local D = { enabled = false, rows = {}, counts = {} }
O.GCDDiagnostics = D
local LIMIT, WINDOW, INTERVAL, PAGE = 256, 15000, 100, 8
local function Print(message) d("[OCGCD] " .. message) end
local function Stop(reason)
    if not D.enabled then return end
    D.enabled = false
    Print("STOP " .. reason .. " rows=" .. #D.rows .. "; /ocgcd summary; /ocgcd 1")
end
local function Expire(now)
    if D.enabled and now - D.start >= WINDOW then Stop("15s") end
end
local function Count(key, blocked)
    if blocked then D.counts[key] = (D.counts[key] or 0) + 1 end
end
function D.Capture(gcd)
    if not D.enabled then return end
    local now = GetFrameTimeMilliseconds()
    Expire(now)
    if not D.enabled then return end
    local la = gcd.la or {}
    if gcd.active then
        Count("active", true)
        Count("ready", gcd.ready)
        Count("apiMissing", not la.available)
        Count("usedBlocked", not la.used)
        Count("usableBlocked", not la.usable)
        Count("failureBlocked", la.failure)
        Count("cooldownBlocked", not la.cooldownClear)
    end
    local key = table.concat({ tostring(gcd.active), tostring(gcd.ready), tostring(la.available),
        tostring(la.used), tostring(la.usable), tostring(la.failure),
        tostring(la.cooldownClear), tostring(la.sharedGCD), tostring(la.global), tostring(la.globalSlotType) }, ":")
    -- Periodic active samples plus gate changes and a single completion row.
    if key == D.lastKey and (not gcd.active or now - D.lastAt < INTERVAL) then return end
    if not gcd.active and not D.wasActive then return end
    D.wasActive, D.lastKey, D.lastAt = gcd.active, key, now
    local row = { time = now - D.start, active = gcd.active, ready = gcd.ready,
        gcdRemaining = gcd.remaining, gcdDuration = gcd.duration, sourceSlot = gcd.sourceSlot,
        la = la }
    if GetSlotBoundId then row.ability = GetSlotBoundId(1) end
    if GetSlotType then row.slotType = GetSlotType(1) end
    if GetActiveHotbarCategory then row.hotbar = GetActiveHotbarCategory() end
    D.rows[#D.rows + 1] = row
    if #D.rows >= LIMIT then Stop("buffer-full") end
end
local function Summary()
    local parts = {}
    for _, key in ipairs({ "active", "ready", "apiMissing", "usedBlocked", "usableBlocked", "failureBlocked", "cooldownBlocked" }) do
        parts[#parts + 1] = key .. "=" .. (D.counts[key] or 0)
    end
    Print("recording=" .. tostring(D.enabled) .. " rows=" .. #D.rows .. " frames: " .. table.concat(parts, " "))
end
SLASH_COMMANDS["/ocgcd"] = function(command)
    command = string.lower((command or ""):match("^%s*(.-)%s*$"))
    Expire(GetFrameTimeMilliseconds())
    if command == "on" then
        D.rows, D.counts = {}, {}
        D.start, D.lastAt, D.lastKey, D.wasActive = GetFrameTimeMilliseconds(), 0, nil, false
        D.enabled = true
        Print("START 15s; slot1; memory-only; /ocgcd off; /ocgcd summary; /ocgcd 1")
    elseif command == "off" then
        Stop("manual")
    elseif command == "summary" then
        Summary()
    else
        local page = tonumber(command)
        if not page or page < 1 or page ~= math.floor(page) or page > math.max(1, math.ceil(#D.rows / PAGE)) then
            Print("/ocgcd on | off | summary | <page>; rows/page=8; cooldown=remaining/duration/global/type")
            return
        end
        Print("page=" .. page .. "/" .. math.max(1, math.ceil(#D.rows / PAGE)))
        for i = (page - 1) * PAGE + 1, math.min(page * PAGE, #D.rows) do
            local row = D.rows[i]
            local s = row.la
            Print(string.format("#%d t=%d active=%s ready=%s gcd=%s/%s source=%s api=%s used=%s usable=%s fail=%s cd=%s/%s/%s/%s shared=%s id=%s type=%s bar=%s",
                i, row.time, tostring(row.active), tostring(row.ready), tostring(row.gcdRemaining), tostring(row.gcdDuration),
                tostring(row.sourceSlot), tostring(s.available), tostring(s.used), tostring(s.usable), tostring(s.failure),
                tostring(s.remaining), tostring(s.duration), tostring(s.global), tostring(s.globalSlotType), tostring(s.sharedGCD),
                tostring(row.ability), tostring(row.slotType), tostring(row.hotbar)))
        end
    end
end
