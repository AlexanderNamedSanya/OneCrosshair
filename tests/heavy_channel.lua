local O, H = OneCrosshair, OneCrosshair.HeavyChannel
local function test(name, fn) fn(); print("PASS " .. name) end
local function close(a,b) assert(a and math.abs(a-b)<.001, tostring(a).." ~= "..tostring(b)) end
local function setup()
    H.Stop("test-reset", T.now); H.provider=nil
    T.now,T.latency,T.hotbar=0,100,0
    T.block,T.dead,T.mounted,T.sheathed,T.menu=false,false,false,false,false
    T.camera,T.reticleHidden,T.weaponUsable=true,false,true
    T.cooldowns,T.castInfo,T.slotTypes,T.crafted={}, {}, {}, {}
    T.ids={[1]=101,[2]=102,[3]=103}; T.crux,T.toggled=nil,nil
    O.settings.heavyChannel,O.settings.gcd,O.settings.visibility=true,true,"ALWAYS"
    O.runtime.gcd=O.GCD.New()
    Fire(EVENT_PLAYER_ACTIVATED)
    T.now=-100; O.Runtime.Update(O.runtime)
    T.now=0; O.Runtime.Update(O.runtime)
end
local function combat(result,id,kind,source,target,err,targetId)
    Fire(EVENT_COMBAT_EVENT,result,err or false,"",0,kind or ACTION_SLOT_TYPE_NORMAL_ABILITY,
        "",source or COMBAT_UNIT_TYPE_PLAYER,"",target or 2,0,0,0,false,1,targetId or 22,id)
end
local function heavy(duration, channel)
    T.castInfo[102]={channel or false,duration or 1000}
    combat(ACTION_RESULT_BEGIN,102,ACTION_SLOT_TYPE_HEAVY_ATTACK)
end
local function skill(duration,channel,id)
    id=id or 103; T.ids[3]=id; T.castInfo[id]={channel or false,duration}
    Fire(EVENT_ACTION_SLOT_ABILITY_USED,3)
end
local function update(time,remaining)
    T.now=time
    if remaining~=nil then T.cooldowns[3]={remaining,1000,true,ACTION_TYPE_ABILITY} end
    O.Runtime.Update(O.runtime)
    return O.runtime.ring.arcs.bottom
end
local function ended(reason)
    assert(not H.state.active and H.Read(true,T.now)==nil)
    assert(H.state.reason==reason, tostring(H.state.reason).." ~= "..reason)
end

test("heavy BEGIN uses equipped slot and API duration; duplicate BEGIN cannot restart", function()
    setup(); heavy(1000)
    assert(H.state.kind=="heavy" and H.state.source=="heavy-begin"); close(H.Read(true,0),0)
    T.now=250; close(H.Read(true,T.now),.25)
    combat(ACTION_RESULT_BEGIN_CHANNEL,102,ACTION_SLOT_TYPE_HEAVY_ATTACK)
    close(H.Read(true,500),.5); assert(H.state.startMs==0)
    combat(ACTION_RESULT_BEGIN,999,ACTION_SLOT_TYPE_HEAVY_ATTACK)
    assert(H.state.abilityId==102)
end)
test("heavy direct release and cooldown release restore idle without sticky ownership", function()
    setup(); heavy(); T.now=350
    combat(ACTION_RESULT_DAMAGE,102,ACTION_SLOT_TYPE_HEAVY_ATTACK); ended("heavy-release")
    local bar=update(350,0); assert(bar.color==O.GCD.idleColor); close(bar.alpha,O.settings.hudOpacity*.25)
    heavy(); T.now=500; T.cooldowns[2]={0,0,false}
    Fire(EVENT_ACTION_UPDATE_COOLDOWNS); ended("heavy-cooldown")
end)
test("channeled heavy damage ticks do not end charge; timeout always completes", function()
    setup(); heavy(2000,true); T.now=500
    combat(ACTION_RESULT_DAMAGE,102,ACTION_SLOT_TYPE_HEAVY_ATTACK)
    close(H.Read(true,1000),.5)
    T.now=2000; assert(H.Read(true,T.now)==nil); ended("completed"); close(H.state.progress,1)
end)
test("heavy overrides green and restores current green in the same runtime frame", function()
    setup(); update(900,100); assert(O.runtime.gcd.ready)
    heavy(1000); local bar=update(900,100)
    assert(bar.color==O.GCD.idleColor); close(bar.fill,0)
    T.now=920; combat(ACTION_RESULT_EFFECT_FADED,102,ACTION_SLOT_TYPE_HEAVY_ATTACK)
    bar=update(920,80); assert(bar.color==O.GCD.readyColor); close(bar.fill,1)
    close(O.runtime.gcd.remaining,80)
end)
test("GCD to heavy to current gray GCD never restarts underlying timer", function()
    setup(); update(0,1000); heavy(); update(400,600)
    T.now=700; T.block=true
    local bar=update(700,300); ended("block")
    close(bar.fill,.7); assert(bar.color==O.GCD.idleColor and O.runtime.gcd.remaining==300)
end)
test("heavy can outlive GCD then complete into idle", function()
    setup(); update(0,1000); heavy(2000)
    update(1000,0); assert(H.state.active and not O.runtime.gcd.active)
    local bar=update(2000,0); ended("completed"); close(bar.alpha,O.settings.hudOpacity*.25)
end)
test("heavy release signature requires cooldown event, not empty slot polling", function()
    setup(); heavy(); T.now=100; T.cooldowns[2]={0,0,false}
    close(H.Read(true,100),.1)
    Fire(EVENT_ACTION_UPDATE_COOLDOWNS); ended("heavy-cooldown")
end)
test("new accepted skill replaces heavy while failed skill leaves charge intact", function()
    setup(); heavy(2000); T.now=100; skill(0)
    combat(ACTION_RESULT_INSUFFICIENT_RESOURCE,103,nil,nil,nil,true)
    assert(H.state.active and not H.pending)
    T.now=200; skill(0); T.cooldowns[3]={1000,1000,true,ACTION_TYPE_ABILITY}
    Fire(EVENT_ACTION_UPDATE_COOLDOWNS); assert(not H.state.active)
    local bar=update(200,1000); close(bar.fill,0)
end)
test("channel queued slot requires confirmed GCD and backdates start", function()
    setup(); skill(2000,true); assert(not H.state.active and H.pending)
    T.now=20; T.cooldowns[3]={980,1000,true,ACTION_TYPE_ABILITY}
    Fire(EVENT_ACTION_UPDATE_COOLDOWNS)
    assert(H.state.kind=="channel" and H.state.startMs==0)
    close(H.Read(true,1000),.5)
    T.now=2000; assert(H.Read(true,T.now)==nil); ended("completed")
end)
test("cast under 1 second finishes at its own duration and reveals current GCD", function()
    setup(); skill(600,false); T.cooldowns[3]={1000,1000,true,ACTION_TYPE_ABILITY}
    Fire(EVENT_ACTION_UPDATE_COOLDOWNS)
    assert(H.state.kind=="cast"); close(H.Read(true,300),.5)
    local bar=update(600,400); ended("completed"); close(bar.fill,.6)
end)
test("combat confirmation permits a cast without a global timer", function()
    setup(); skill(1200,false); T.now=50
    combat(ACTION_RESULT_BEGIN,103); assert(H.state.source=="combat-confirmed" and H.state.startMs==50)
    close(H.Read(true,650),.5)
    local bar=update(1250,0); ended("completed"); close(bar.alpha,O.settings.hudOpacity*.25)
end)
test("queued press cannot borrow an old GCD and unconfirmed queue expires", function()
    setup(); update(0,1000); T.now=600; T.cooldowns[3]={400,1000,true,ACTION_TYPE_ABILITY}
    skill(1500,true); H.Read(true,616); assert(not H.state.active)
    T.now=2200; T.cooldowns={}; H.Read(true,T.now); assert(not H.pending and not H.state.active)
end)
test("poll confirms a renewed GCD when cooldown event was missed", function()
    setup(); skill(1000,true)
    T.now=32; T.cooldowns[3]={968,1000,true,ACTION_TYPE_ABILITY}
    close(H.Read(true,32),.032); assert(H.state.source=="gcd-poll")
end)
test("channel cancellation restores live GCD or idle for each termination signal", function()
    local causes={
        {"block",function() T.block=true end},
        {"dodge",function() combat(ACTION_RESULT_EFFECT_GAINED,28549) end},
        {"bar-swap",function() Fire(EVENT_ACTION_SLOTS_ACTIVE_HOTBAR_UPDATED,true) end},
        {"interrupted",function() combat(ACTION_RESULT_INTERRUPT,999,nil,2,COMBAT_UNIT_TYPE_PLAYER) end},
        {"combat-faded",function() combat(ACTION_RESULT_EFFECT_FADED,103) end},
        {"death",function() Fire(EVENT_PLAYER_DEAD) end},
        {"mounted",function() Fire(EVENT_MOUNTED_STATE_CHANGED,true) end},
        {"weapon-state",function() T.sheathed=true end},
    }
    for _,entry in ipairs(causes) do
        setup(); T.cooldowns[3]={1000,1000,true,ACTION_TYPE_ABILITY}; skill(2000,true)
        assert(H.state.active); T.now=700; entry[2]()
        local bar=update(700,300); ended(entry[1]); close(bar.fill,.7)
        bar=update(1000,0); close(bar.alpha,O.settings.hudOpacity*.25)
    end
end)
test("cast weapon unlock cancels early but does not cancel channel", function()
    setup(); skill(1500,false); combat(ACTION_RESULT_BEGIN,103)
    T.now=200; Fire(EVENT_WEAPON_PAIR_LOCK_CHANGED,false); ended("weapon-unlock")
    skill(1500,true); combat(ACTION_RESULT_BEGIN_CHANNEL,103)
    T.now=400; Fire(EVENT_WEAPON_PAIR_LOCK_CHANGED,false); assert(H.state.active)
end)
test("incoming unrelated events and wrong-target fades cannot cancel a channel", function()
    setup(); skill(1500,true); combat(ACTION_RESULT_BEGIN_CHANNEL,103)
    T.now=100; combat(ACTION_RESULT_INTERRUPT,999,nil,2,2)
    combat(ACTION_RESULT_EFFECT_FADED,103,nil,2,2)
    combat(ACTION_RESULT_EFFECT_FADED,103,nil,nil,2,false,33)
    assert(H.state.active)
    combat(ACTION_RESULT_DIED,999,nil,2,2,false,22); ended("target-dead")
end)
test("failed channel, toggle off, changed weapon and deactivation clear ownership", function()
    setup(); skill(1500,true); combat(ACTION_RESULT_BEGIN_CHANNEL,103); T.now=100
    combat(ACTION_RESULT_SILENCED,103,nil,nil,nil,true); assert(not H.state.active)
    skill(1500,true); combat(ACTION_RESULT_BEGIN_CHANNEL,103); T.toggled=3
    Fire(EVENT_ACTION_SLOT_ABILITY_USED,3); ended("toggle")
    T.toggled=nil; heavy(); T.ids[2]=999; H.Read(true,T.now); ended("weapon-changed")
    T.ids[2]=102; heavy(); Fire(EVENT_PLAYER_DEACTIVATED); ended("deactivated")
    combat(ACTION_RESULT_BEGIN,102,ACTION_SLOT_TYPE_HEAVY_ATTACK); assert(not H.state.active)
end)
test("turning feature off immediately reveals GCD and ignores new timing events", function()
    setup(); heavy(); update(500,500)
    O.settings.heavyChannel=false; local bar=update(600,400); ended("disabled"); close(bar.fill,.6)
    heavy(); skill(2000,true); combat(ACTION_RESULT_BEGIN,103); assert(not H.state.active and not H.pending)
    O.settings.heavyChannel=true; update(700,300); assert(not H.state.active)
    heavy(); assert(H.state.active)
end)
test("crafted ability resolves runtime ID and duration without stale metadata cache", function()
    setup(); T.ids[3]=7; T.slotTypes[3]=ACTION_TYPE_CRAFTED_ABILITY; T.crafted[7]=103
    T.castInfo[103]={true,1800}; Fire(EVENT_ACTION_SLOT_ABILITY_USED,3); combat(ACTION_RESULT_BEGIN_CHANNEL,103)
    assert(H.state.abilityId==103 and H.state.duration==1800)
    H.Stop("test",0); T.castInfo[103]={false,600}; Fire(EVENT_ACTION_SLOT_ABILITY_USED,3); combat(ACTION_RESULT_BEGIN,103)
    assert(H.state.kind=="cast" and H.state.duration==600)
end)
test("Fatecarver samples pre-consumption Crux and applies only relevant correction", function()
    setup(); T.crux=3; skill(4000,true,183122); T.crux=0
    combat(ACTION_RESULT_BEGIN_CHANNEL,183122)
    assert(H.state.duration==5014)
    close(H.Read(true,2507),.5)
end)
local function effect(change,beginTime,target)
    Fire(EVENT_EFFECT_CHANGED,change,1,"","reticleover",beginTime,2,1,"","",0,0,0,"",target or 22,63029,COMBAT_UNIT_TYPE_PLAYER)
end
test("beam effect fade correlates epoch and target; stale prior cast fade ignored", function()
    setup(); T.now=1000; skill(1800,true,63029); combat(ACTION_RESULT_BEGIN_CHANNEL,63029)
    effect(EFFECT_RESULT_GAINED,1); T.now=1100
    effect(EFFECT_RESULT_FADED,0); assert(H.state.active)
    effect(EFFECT_RESULT_FADED,1,33); assert(H.state.active)
    effect(EFFECT_RESULT_FADED,1); ended("beam-faded")
end)
test("unbounded toggles and missing cast metadata do not fabricate progress", function()
    setup()
    for _,id in ipairs({103665,103492,103652,107579,118645}) do
        skill(1000,true,id); combat(ACTION_RESULT_BEGIN_CHANNEL,id); assert(not H.state.active)
    end
    T.castInfo[102]={false,0}; combat(ACTION_RESULT_BEGIN,102,ACTION_SLOT_TYPE_HEAVY_ATTACK)
    assert(not H.state.active)
end)
test("missing reference-only result globals are nil-safe with cooldown fallback", function()
    setup(); local a,b,c,d=ACTION_RESULT_BEGIN,ACTION_RESULT_BEGIN_CHANNEL,ACTION_RESULT_EFFECT_GAINED,ACTION_RESULT_EFFECT_FADED
    ACTION_RESULT_BEGIN,ACTION_RESULT_BEGIN_CHANNEL,ACTION_RESULT_EFFECT_GAINED,ACTION_RESULT_EFFECT_FADED=nil,nil,nil,nil
    heavy(); assert(not H.state.active)
    T.cooldowns[3]={1000,1000,true,ACTION_TYPE_ABILITY}; skill(1000,true); assert(H.state.active)
    T.block=true; H.Read(true,100); ended("block")
    ACTION_RESULT_BEGIN,ACTION_RESULT_BEGIN_CHANNEL,ACTION_RESULT_EFFECT_GAINED,ACTION_RESULT_EFFECT_FADED=a,b,c,d
end)
test("hidden HUD still processes termination and cannot resurrect expired progress", function()
    setup(); heavy(1000); T.menu=true
    update(1100,0); ended("completed")
    T.menu=false; local bar=update(1116,0); close(bar.alpha,O.settings.hudOpacity*.25)
end)
test("heavy/channel diagnostics capture idle-GCD owner, immutable snapshots and stop reason", function()
    setup(); T.chat={}; SLASH_COMMANDS["/ocgcd"]("on")
    heavy(); update(0,0); local first=O.GCDDiagnostics.rows[1]
    assert(first.owner=="heavy" and first.progress==0 and first.timingId==102)
    update(500,0); assert(first.progress==0)
    T.now=600; combat(ACTION_RESULT_EFFECT_FADED,102,ACTION_SLOT_TYPE_HEAVY_ATTACK); update(600,0)
    local rows=O.GCDDiagnostics.rows; assert(rows[#rows].owner=="idle" and rows[#rows].timingReason=="combat-faded")
    assert(#T.chat==1); SLASH_COMMANDS["/ocgcd"]("off"); SLASH_COMMANDS["/ocgcd"]("1")
    assert(T.chat[#T.chat]:find("reason=combat-faded",1,true))
    local updates=0; for _ in pairs(EVENT_MANAGER.updates) do updates=updates+1 end; assert(updates==1)
end)

test("late failed repeat cannot cancel accepted channel; immediate rejection can", function()
    setup(); skill(1500,true); combat(ACTION_RESULT_BEGIN_CHANNEL,103)
    T.now=400; skill(1500,true)
    combat(ACTION_RESULT_ABILITY_ON_COOLDOWN,103,nil,nil,nil,true); assert(H.state.active and not H.pending)
    T.now=500; combat(ACTION_RESULT_ABILITY_ON_COOLDOWN,103,nil,nil,nil,true); assert(H.state.active)
    setup(); skill(1500,true); combat(ACTION_RESULT_BEGIN_CHANNEL,103)
    T.now=50; combat(ACTION_RESULT_ABILITY_ON_COOLDOWN,103,nil,nil,nil,true); assert(not H.state.active)
end)
test("queued next cast survives natural completion of previous owner", function()
    setup(); skill(1000,true); combat(ACTION_RESULT_BEGIN_CHANNEL,103)
    T.now=950; T.cooldowns[3]={50,1000,true,ACTION_TYPE_ABILITY}; skill(1000,true)
    T.now=1000; T.cooldowns={}; H.Read(true,T.now)
    assert(not H.state.active and H.pending)
    T.now=1016; T.cooldowns[3]={984,1000,true,ACTION_TYPE_ABILITY}
    Fire(EVENT_ACTION_UPDATE_COOLDOWNS)
    assert(H.state.active and H.state.startMs==1000)
end)
test("invalid duration values never create unbounded ownership", function()
    setup()
    for _,duration in ipairs({0,-1,math.huge,0/0}) do
        T.castInfo[102]={false,duration}; combat(ACTION_RESULT_BEGIN,102,ACTION_SLOT_TYPE_HEAVY_ATTACK)
        assert(not H.state.active)
    end
end)
test("channel completion can reveal green and Heavy works with GCD display disabled", function()
    setup(); T.cooldowns[3]={1000,1000,true,ACTION_TYPE_ABILITY}; skill(920,true)
    local bar=update(900,100); assert(bar.color==O.GCD.idleColor and H.state.active)
    bar=update(920,80); assert(bar.color==O.GCD.readyColor and not H.state.active)
    setup(); O.settings.gcd=false; heavy(); bar=update(500,0)
    close(bar.fill,.5); assert(bar.color==O.GCD.idleColor and bar.alpha>0)
end)
test("accepted channel replacement ends Heavy and keeps its pending confirmation", function()
    setup(); heavy(2000); T.now=200; skill(1500,true)
    T.cooldowns[3]={1000,1000,true,ACTION_TYPE_ABILITY}; Fire(EVENT_ACTION_UPDATE_COOLDOWNS)
    assert(H.state.active and H.state.kind=="channel" and H.state.startMs==200 and H.pending==nil)
end)
