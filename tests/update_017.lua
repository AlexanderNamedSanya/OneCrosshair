local O, H, A = OneCrosshair, OneCrosshair.HeavyChannel, OneCrosshair.AbilityTimings
local function test(name, fn) fn(); print("PASS " .. name) end
local function close(a,b) assert(math.abs(a-b)<.001, tostring(a).." ~= "..tostring(b)) end
local function cast(duration, channel)
    H.Stop(); H.provider=nil
    O.settings.gcd=true; O.settings.visibility="ALWAYS"
    T.skills=nil; T.now=0; T.latency=100; T.block=false; T.dead=false
    T.mounted=false; T.sheathed=false; T.hotbar=0; T.toggled=nil
    T.ids={[3]=103}; T.castInfo={[103]={channel,duration}}; T.cooldowns={}; T.slotTypes={}
    Fire(EVENT_PLAYER_ACTIVATED)
    Fire(EVENT_ACTION_SLOT_ABILITY_USED,3)
    Fire(EVENT_COMBAT_EVENT,ACTION_RESULT_BEGIN,false,"",0,ACTION_SLOT_TYPE_NORMAL_ABILITY,
        "",COMBAT_UNIT_TYPE_PLAYER,"",2,0,0,0,false,1,22,103)
    assert(H.state.active)
end

test("cast and channel cue exactly at ping threshold, latch, and release at real end", function()
    for _, channel in ipairs({false,true}) do
        cast(2000,channel)
        local p, ready=H.Read(true,1899); assert(not ready); close(p,.9495)
        p,ready=H.Read(true,1900); assert(ready); close(p,.95)
        local fill,color=H.Presentation(p,ready); close(fill,1); assert(color==O.GCD.readyColor)
        T.latency=10; p,ready=H.Read(true,1901); assert(ready)
        assert(H.Read(true,2000)==nil and not H.state.active)
    end
end)
test("short cast waits for GCD; normal GCD takes over with its unchanged threshold", function()
    cast(600,false); T.cooldowns[3]={500,1000,true,ACTION_TYPE_ABILITY}
    local _,ready=H.Read(true,500); assert(not ready)
    T.now=600; T.cooldowns[3][1]=400; assert(H.Read(true,600)==nil)
    local g=O.GCD.New(); O.GCD.Read(g); assert(not g.ready)
    T.now=900; T.cooldowns[3][1]=100; O.GCD.Read(g); assert(g.ready)
end)
test("cast ping is capped at 150 ms and zero ping creates no early cue", function()
    cast(2000,true); T.latency=900
    local _,ready=H.Read(true,1849); assert(not ready)
    _,ready=H.Read(true,1850); assert(ready)
    for _,ping in ipairs({0,-50}) do
        cast(2000,true); T.latency=ping
        _,ready=H.Read(true,1999); assert(not ready)
        assert(H.Read(true,2000)==nil)
    end
end)
test("early cancellation discards channel green immediately; next action starts gray", function()
    cast(2000,true); local _,ready=H.Read(true,1900); assert(ready)
    T.block=true; assert(H.Read(true,1901)==nil)
    cast(2000,true); _,ready=H.Read(true,0); assert(not ready)
end)
test("catalog enumerates all active morph ranks, chains, current scribing and excludes passives", function()
    T.castInfo={}; local ranks={}
    for i=1,12 do ranks[i]=200+i; T.castInfo[200+i]={false,600+i} end
    T.castInfo[300]={true,1800}; T.castInfo[301]={false,0}
    T.castInfo[400]={true,2500}; T.castInfo[500]={false,900}; T.castInfo[600]={false,300}
    T.skills={{id=201,progression=1,ranks=ranks},{crafted=7},{id=500,passive=true},{id=600}}
    T.chained={[0]={300,301}}; T.crafted={[7]=400}
    Fire(EVENT_SKILLS_FULL_UPDATE)
    for i=1,12 do close(A.entries[200+i].duration,600+i) end
    assert(A.entries[300].channeled and A.entries[400].channeled and A.entries[600])
    assert(not A.entries[301] and not A.entries[500])
    T.castInfo[400]={true,2700}; Fire(EVENT_END_CRAFTING_STATION_INTERACT)
    close(A.entries[400].duration,2700)
    T.skills=nil; T.chained=nil
end)
test("per-use catalog refresh covers noncatalog skills and removes stale instant rows", function()
    T.castInfo={[777]={false,1200}}; close(A.Refresh(777).duration,1200)
    T.castInfo[777]={false,700}; close(A.Refresh(777).duration,700)
    T.castInfo[777]={false,0}; assert(A.Refresh(777)==nil and A.entries[777]==nil)
end)
test("Fatecarver table records pre-use Crux and indefinite exceptions", function()
    T.castInfo={[183122]={true,2000},[103665]={true,1000}}; T.crux=3
    local row=A.Refresh(183122); close(row.baseDuration,2000); close(row.duration,3014)
    T.crux=0; close(row.duration,3014); close(A.Refresh(183122).duration,2000)
    assert(A.Refresh(103665).excluded)
end)
test("four maximum arcs join at corners; zero length hides solids glow and shield", function()
    local ring=O.ResourceRing.New(GuiRoot)
    O.ResourceRing.Configure(ring,{resourceLength=100,resourceRadius=100,resourceThickness=12})
    local arcs=ring.arcs
    local pairsToCheck={
        {arcs.health[64].control.anchors[BOTTOMRIGHT],arcs.stamina[64].control.anchors[BOTTOMRIGHT]},
        {arcs.health[1].control.anchors[TOPLEFT],arcs.magicka[64].control.anchors[BOTTOMRIGHT]},
        {arcs.bottom[1].control.anchors[TOPLEFT],arcs.magicka[1].control.anchors[TOPLEFT]},
        {arcs.bottom[64].control.anchors[BOTTOMRIGHT],arcs.stamina[1].control.anchors[TOPLEFT]},
    }
    for _,p in ipairs(pairsToCheck) do close(p[1][4],p[2][4]); close(p[1][5],p[2][5]) end
    O.ResourceRing.Draw(ring,"health",1,{1,0,0},1,true)
    O.ResourceRing.Configure(ring,{resourceLength=0})
    assert(ring.root:IsHidden() and arcs.health[1].glows[1]:IsHidden() and arcs.shield[1].control:IsHidden())
    O.ResourceRing.Configure(ring,{resourceLength=100})
    assert(not ring.root:IsHidden())
end)
test("preview rings obey switches, opacity, geometry, and stay isolated from gameplay", function()
    local s=O.settings; s.resources=true; s.gcd=true; s.shield=true; s.lowResource=true; s.visibility="ALWAYS"
    s.resourceThickness=8; s.resourceLength=100; s.resourceRadius=70; s.hudOpacity=.6
    local liveRadius=O.runtime.ring.radius
    O.Preview.Refresh()
    for _,example in ipairs(O.Preview.examples) do
        local ring=example.ring; close(ring.radius,70); close(ring.thickness,8); close(ring.length,100)
        close(ring.arcs.health.alpha,.6); close(ring.arcs.bottom.alpha,.6)
        assert(ring.arcs.health[1].glows[1].color[4]>0)
    end
    close(O.runtime.ring.radius,liveRadius)
    s.resources=false; O.Preview.Refresh()
    local ring=O.Preview.examples[1].ring
    close(ring.arcs.health.alpha,0); close(ring.arcs.shield.alpha,0); close(ring.arcs.bottom.alpha,.6)
    s.gcd=false; O.Preview.Refresh(); close(ring.arcs.bottom.alpha,0)
    s.resources=true; s.visibility="OFF"; O.Preview.Refresh(); close(ring.arcs.health.alpha,0)
    s.visibility="ALWAYS"; s.resourceLength=0; O.Preview.Refresh(); assert(ring.root.hidden)
end)
test("saved settings retire old switches and clamp invalid experimental geometry", function()
    local old=ZO_SavedVars.NewAccountWide
    ZO_SavedVars.NewAccountWide=function() return {gcd=false,heavyChannel=true,criticalState=true,
        resourceThickness=99,resourceLength=-10,resourceRadius=0/0} end
    local s=O.Settings.Load()
    ZO_SavedVars.NewAccountWide=old
    assert(s.criticalState==nil and s.heavyChannel==nil and not s.gcd)
    close(s.resourceThickness,12); close(s.resourceLength,0); close(s.resourceRadius,42.25)
end)
test("geometry and feature controls immediately refresh preview", function()
    local found=0
    for _,option in ipairs(LibAddonMenu2.options) do
        if option.name==GetString(SI_ONECROSSHAIR_RESOURCE_LENGTH) then
            option.setFunc(85); close(O.Preview.examples[1].ring.length,85); found=found+1
        elseif option.name==GetString(SI_ONECROSSHAIR_GCD) then
            option.setFunc(true); assert(O.Preview.examples[1].ring.arcs.bottom.alpha>0); found=found+1
        end
    end
    assert(found==2)
end)
