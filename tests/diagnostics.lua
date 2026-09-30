local O = OneCrosshair
local D = O.GCDDiagnostics
local command = SLASH_COMMANDS["/ocgcd"]
local function test(name, fn) fn(); print("PASS " .. name) end
local function setup()
    T.now, T.chat = 0, {}
    T.emptyWeapon, T.weaponUsable, T.weaponFailure = false, true, false
    T.cooldowns = {[3]={700,1000,true,ACTION_TYPE_ABILITY}, [1]={20,100,false,ACTION_TYPE_ABILITY}}
end
test("client trace replay: shared GCD stops blocking once state failure clears", function()
    setup()
    local g = O.GCD.New()
    local remaining = {966,866,833,733,633,533,433,333,233,133,33,0,1000,900,800,700}
    for i,ms in ipairs(remaining) do
        T.weaponFailure = i <= 2
        T.cooldowns = {[3]={ms,1000,true,ACTION_TYPE_ABILITY},[1]={ms,1000,true,ACTION_TYPE_ABILITY}}
        O.GCD.Read(g)
        assert(g.ready == (i >= 3 and ms > 0), "trace row " .. i)
        local fill,color,intensity = O.GCD.Presentation(g)
        if g.ready then assert(fill == 1 and color == O.GCD.readyColor and intensity == 1) end
        if ms == 0 then assert(color == O.GCD.idleColor and intensity == .25) end
    end
end)
test("only matching ability-global cooldown is exempt, other gates remain required", function()
    setup(); local g = O.GCD.New()
    local rejected = {{700,1000,false,ACTION_TYPE_ABILITY}, {700,1000,true,ACTION_TYPE_ITEM},
        {600,1000,true,ACTION_TYPE_ABILITY}, {700,1200,true,ACTION_TYPE_ABILITY}, {}}
    for _,cd in ipairs(rejected) do T.cooldowns[1]=cd; O.GCD.Read(g); assert(not g.ready) end
    T.cooldowns[1]={700,1000,true,ACTION_TYPE_ABILITY}
    T.emptyWeapon=true; O.GCD.Read(g); assert(not g.ready)
    T.emptyWeapon=false; T.weaponUsable=false; O.GCD.Read(g); assert(not g.ready)
    T.weaponUsable=true; T.weaponFailure=true; O.GCD.Read(g); assert(not g.ready)
    T.weaponFailure=false; O.GCD.Read(g); assert(g.ready)
end)
test("temporary diagnostics are off by default and silent during normal play", function()
    setup(); assert(not D.enabled)
    local g = O.GCD.New()
    for i=1,20 do T.now=i*16; O.GCD.Read(g) end
    assert(#D.rows == 0 and #T.chat == 0)
end)
test("capture reads all readiness gates even when first gate fails", function()
    setup(); command("on")
    T.emptyWeapon, T.weaponUsable, T.weaponFailure = true, false, true
    local g = O.GCD.New(); O.GCD.Read(g)
    local row = D.rows[1]
    assert(row.la.used == false and row.la.usable == false and row.la.failure == true)
    assert(row.la.remaining == 20 and row.la.duration == 100 and row.la.global == false)
    assert(row.la.globalSlotType == ACTION_TYPE_ABILITY and row.gcdRemaining == 700 and row.gcdDuration == 1000)
    assert(row.ability == 101 and row.sourceSlot == 3 and not row.ready)
    assert(D.counts.usedBlocked == 1 and D.counts.usableBlocked == 1 and D.counts.failureBlocked == 1 and D.counts.cooldownBlocked == 1)
    assert(#T.chat == 1) -- only START, no frame spam
    command("off")
end)
test("recorded readiness matches rendered condition and missing API remains visible", function()
    setup(); command("on")
    local g = O.GCD.New(); O.GCD.Read(g); assert(not g.ready)
    T.now=16; T.cooldowns[1]={0,100,false,ACTION_TYPE_ABILITY}; O.GCD.Read(g)
    assert(g.ready and D.rows[2].ready and O.GCD.Presentation(g) == 1)
    local saved = IsSlotUsable; IsSlotUsable = nil; T.now=32; O.GCD.Read(g)
    assert(not g.ready and not D.rows[3].la.available and D.rows[3].la.usable == nil)
    assert(D.rows[3].la.remaining == 0)
    IsSlotUsable = saved; T.cooldowns={}; T.now=48; O.GCD.Read(g)
    assert(not D.rows[4].active and D.rows[4].gcdRemaining == 0)
    command("off")
end)
test("diagnostics sample periodically, retain gate changes and paginate output", function()
    setup(); command("on")
    local g = O.GCD.New()
    for i=0,80 do T.now=i*16; O.GCD.Read(g) end
    assert(#D.rows > 8 and #D.rows < 15 and #T.chat == 1)
    command("off"); local before=#T.chat; command("1")
    assert(#T.chat-before == 9) -- header + eight records
    before=#T.chat; command("summary"); assert(#T.chat-before == 1)
    assert(T.chat[#T.chat]:find("cooldownBlocked=81",1,true))
    command("on"); assert(#D.rows == 0 and D.counts.active == nil)
    command("off")
end)
test("capture has fixed capacity and time limit without extra update loops", function()
    setup(); command("on"); local g = O.GCD.New()
    for i=1,300 do T.now=i; T.weaponUsable=i%2==0; O.GCD.Read(g) end
    assert(#D.rows == 256 and not D.enabled and #T.chat == 2)
    setup(); command("on"); O.GCD.Read(g); T.now=15000; O.GCD.Read(g)
    assert(not D.enabled and #T.chat == 2)
    setup(); command("on"); T.now=16000; command("summary")
    assert(not D.enabled) -- command also expires captures while HUD is hidden
    local count=0; for _ in pairs(EVENT_MANAGER.updates) do count=count+1 end
    assert(count==1)
end)
