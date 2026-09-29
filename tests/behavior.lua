local O = OneCrosshair
local function test(name, fn) fn(); print("PASS " .. name) end
local function close(a,b) assert(math.abs(a-b) < .001, tostring(a).." ~= "..tostring(b)) end
test("block priority and immediate underlying target reevaluation", function()
    assert(O.StateController.Read().geometry == "normal")
    T.target = true; assert(O.StateController.Read().geometry == "target")
    T.block = true; T.target = false; assert(O.StateController.Read().geometry == "block")
    T.block = false; assert(O.StateController.Read().geometry == "normal")
    T.interact = true; assert(O.StateController.Read().geometry == "target"); T.interact = false
end)
test("interpolation duration and interrupted transition continuity", function()
    local a = O.Animator.New(0)
    O.Animator.To(a,1,0,250); close(O.Animator.Value(a,125), .5)
    O.Animator.To(a,0,125,250); close(O.Animator.Value(a,125), .5); close(O.Animator.Value(a,375),0)
end)
test("dynamic and combat hold/fade, mode change and independent enable", function()
    local v = O.VisibilityController.New()
    local function alpha(mode,enabled,combat,active,time)
        return O.VisibilityController.Alpha(v,"health",mode,enabled,combat,active,time)
    end
    close(alpha("DYNAMIC",true,false,false,0),0)
    alpha("DYNAMIC",true,false,true,1); close(alpha("DYNAMIC",true,false,true,101),1)
    close(alpha("DYNAMIC",true,false,false,2100),1)
    alpha("DYNAMIC",true,false,false,2101); close(alpha("DYNAMIC",true,false,false,2301),0)
    alpha("COMBAT_ONLY",true,true,false,2400); close(alpha("COMBAT_ONLY",true,true,false,2500),1)
    close(alpha("COMBAT_ONLY",true,false,false,4499),1)
    alpha("COMBAT_ONLY",true,false,false,4500); close(alpha("COMBAT_ONLY",true,false,false,4700),0)
    close(alpha("OFF",true,true,true,4800),0)
    alpha("ALWAYS",true,false,false,4900); close(alpha("ALWAYS",true,false,false,5000),1)
    close(alpha("ALWAYS",false,false,false,5010),0)
end)
test("actual variable GCD timing, local cooldown exclusion and immediate idle", function()
    local g = O.GCD.New()
    T.cooldowns = {[3]={900,1200,true}, [4]={5000,10000,false}}
    O.GCD.Read(g); assert(g.active); close(g.progress,.25); assert(not g.gold)
    T.cooldowns = {[3]={0,1200,true}}; O.GCD.Read(g); assert(not g.active)
end)
test("resources smooth and shield clamped against maximum health", function()
    local h = O.Health.New(); close(O.Resource.Read(h,0),1)
    T.powers[1] = 20; O.Resource.Read(h,1); close(O.Resource.Read(h,151),.2)
    local shield = O.Shield.New(); T.shield = 150
    O.Shield.Read(shield,100,0); close(O.Shield.Read(shield,100,150),1)
    O.Shield.Read(shield,0,200); close(O.Shield.Read(shield,0,350),0)
    T.powers[1], T.shield = 100, 0
end)
test("fixed arc directions and centered health/bottom fill", function()
    local ring = O.runtime.ring
    for _,key in ipairs({"health","bottom"}) do
        local arc = ring.arcs[key]; close(arc[1].threshold,arc[64].threshold)
        assert(arc[32].threshold < arc[1].threshold)
    end
    for _,key in ipairs({"magicka","stamina"}) do
        local arc = ring.arcs[key]
        assert(arc[1].control.anchor[5] > arc[64].control.anchor[5])
        assert(arc[1].threshold < arc[64].threshold)
    end
end)
test("optional effects threshold boundaries", function()
    assert(O.LowResource.Active(true,.25)); assert(not O.LowResource.Active(true,.251))
    local critical,dim = O.CriticalState.Read(true,.25); assert(critical); close(dim,.35)
    assert(not O.CriticalState.Read(false,.1))
end)
test("direct feedback consumes action and rejects periodic/incoming events", function()
    local c = O.runtime.crosshair
    local function hit(result,source,id,kind)
        Fire(EVENT_COMBAT_EVENT,result,false,"",0,kind or ACTION_SLOT_TYPE_NORMAL_ABILITY,"",source,"",2,1,1,1,false,1,2,id)
    end
    T.now = 1000; Fire(EVENT_ACTION_SLOT_ABILITY_USED,3)
    hit(ACTION_RESULT_DOT_TICK,1,103); assert(c.pulseStart == nil)
    hit(ACTION_RESULT_DAMAGE,2,103); assert(c.pulseStart == nil)
    hit(ACTION_RESULT_DAMAGE,1,103); assert(c.pulseStart == 1000)
    T.now = 1200; hit(ACTION_RESULT_DAMAGE,1,103); assert(c.pulseStart == 1000)
    Fire(EVENT_ACTION_SLOT_ABILITY_USED,1); hit(ACTION_RESULT_DAMAGE,1,101,ACTION_SLOT_TYPE_LIGHT_ATTACK)
    assert(c.pulseStart == 1200)
    T.now = 1400; hit(ACTION_RESULT_DAMAGE,1,101,ACTION_SLOT_TYPE_LIGHT_ATTACK); assert(c.pulseStart == 1200)
end)
test("unsupported timing degrades without fabricated progress; cancellation contract", function()
    assert(O.HeavyChannel.Read(true,100) == nil)
    O.HeavyChannel.provider = {Read=function(now) return {active=now<150,startMs=0,endMs=200} end}
    close(O.HeavyChannel.Read(true,100),.5)
    assert(O.HeavyChannel.Read(true,150) == nil)
    assert(O.HeavyChannel.Read(false,100) == nil)
    O.HeavyChannel.provider = nil
end)
test("automatic preview white and isolated; preset element count extensibility", function()
    CALLBACK_MANAGER.handlers["LAM-PanelOpened"](LibAddonMenu2.panel)
    assert(not O.Preview.root:IsHidden())
    for _,example in ipairs(O.Preview.examples) do
        close(example.crosshair.elements[1].control.color[1],1)
        close(example.crosshair.elements[1].control.color[2],1)
    end
    local states, elements = {normal={},target={},block={}}, {}
    for i=1,7 do elements[i]={size=2}; for _,state in pairs(states) do state[i]={x=i,y=i} end end
    O.PresetRegistry.Register({id="test",name=SI_ONECROSSHAIR_PRESET_DOT,elements=elements,states=states})
    O.settings.preset = "test"; O.Preview.Refresh()
    assert(#O.Preview.examples[1].crosshair.elements == 7)
    assert(O.runtime.crosshair.preset == nil) -- preview never mutates gameplay
    O.settings.preset = "dot"; O.Preview.Refresh()
    CALLBACK_MANAGER.handlers["LAM-PanelClosed"](LibAddonMenu2.panel)
    assert(O.Preview.root:IsHidden()); assert(not LibAddonMenu2.data.registerForDefaults)
end)
test("runtime replacement restores vanilla texture on menus/deactivation", function()
    Fire(EVENT_PLAYER_ACTIVATED); T.now = 2000; O.Runtime.Update(O.runtime)
    assert(not O.runtime.root:IsHidden()); assert(RETICLE.reticleTexture:IsHidden())
    T.menu = true; O.Runtime.Update(O.runtime)
    assert(O.runtime.root:IsHidden()); assert(not RETICLE.reticleTexture:IsHidden())
    T.menu = false; O.Runtime.Update(O.runtime)
    RETICLE:UpdateHiddenState(); assert(RETICLE.reticleTexture:IsHidden())
    Fire(EVENT_PLAYER_DEACTIVATED); assert(not RETICLE.reticleTexture:IsHidden())
end)
test("resources disabled does not hide enabled GCD; shield follows health", function()
    Fire(EVENT_PLAYER_ACTIVATED)
    O.settings.resources = false; O.settings.visibility = "ALWAYS"
    T.now=3000; O.Runtime.Update(O.runtime); T.now=3100; O.Runtime.Update(O.runtime)
    close(O.runtime.ring.arcs.health.alpha,0); close(O.runtime.ring.arcs.shield.alpha,0)
    assert(O.runtime.ring.arcs.bottom.alpha > 0)
    O.settings.visibility = "OFF"; O.Runtime.Update(O.runtime)
    close(O.runtime.ring.arcs.bottom.alpha,0)
end)
