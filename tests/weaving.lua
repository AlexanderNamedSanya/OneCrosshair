local O = OneCrosshair
local function test(name, fn) fn(); print("PASS " .. name) end
local function sample(g, time, remaining, duration, latency)
    T.now, T.latency = time, latency
    T.cooldowns = {[3]={remaining,duration,true,ACTION_TYPE_ABILITY}}
    return O.GCD.Read(g)
end
test("latency cap and inclusive boundary across variable GCD durations", function()
    for _,duration in ipairs({800,1000,1200}) do
        local g=O.GCD.New()
        sample(g,0,151,duration,350); assert(not g.ready and g.lead==150)
        sample(g,1,150,duration,350); assert(g.ready)
    end
end)
test("zero negative and unavailable latency never invent a pre-end window", function()
    for _,ping in ipairs({0,-10}) do
        local g=O.GCD.New(); sample(g,0,1,1000,ping); assert(not g.ready and g.lead==0)
    end
    local api=GetLatency; GetLatency=nil
    local g=O.GCD.New(); sample(g,0,1,1000,100); assert(not g.ready and g.latency==nil)
    GetLatency=api
end)
test("live latency changes before cue and latch after cue", function()
    local g=O.GCD.New()
    sample(g,0,140,1000,100); assert(not g.ready)
    sample(g,10,130,1000,150); assert(g.ready)
    sample(g,20,120,1000,0); assert(g.ready)
    sample(g,140,0,1000,100); assert(not g.active and not g.ready)
end)
test("consecutive GCD resets green without an intervening zero sample", function()
    local g=O.GCD.New()
    sample(g,0,1000,1000,100); assert(not g.ready)
    sample(g,900,100,1000,100); assert(g.ready)
    sample(g,1016,984,1000,100); assert(not g.ready and g.cycle==2)
    sample(g,1900,100,1000,100); assert(g.ready)
end)
test("expired sampled cycle cannot carry latch across a long update gap", function()
    local g=O.GCD.New()
    sample(g,900,100,1000,100); assert(g.ready)
    sample(g,1910,90,1000,10); assert(not g.ready and g.cycle==2)
end)
test("skill-only and early late missed LA sequences have identical timing", function()
    for _,attackTime in ipairs({-1,0,400,900,980}) do
        local g=O.GCD.New()
        for _,time in ipairs({0,400,899,900,980,1000}) do
            T.weaponUsable=time~=attackTime; T.weaponFailure=time==attackTime
            T.now=time
            if time==attackTime then Fire(EVENT_ACTION_SLOT_ABILITY_USED,1) end
            sample(g,time,1000-time,1000,100)
            assert(g.ready==(time>=900 and time<1000))
        end
    end
    T.weaponUsable,T.weaponFailure=true,false
end)
test("hidden HUD and player deactivation discard the cue latch", function()
    local r=O.runtime
    Fire(EVENT_PLAYER_ACTIVATED)
    sample(r.gcd,900,100,1000,100); assert(r.gcd.ready)
    T.menu=true; O.Runtime.Update(r); assert(not r.gcd.ready)
    T.menu=false; sample(r.gcd,910,90,1000,10); assert(not r.gcd.ready)
    sample(r.gcd,920,80,1000,100); assert(r.gcd.ready)
    Fire(EVENT_PLAYER_DEACTIVATED); assert(not r.gcd.ready)
end)
