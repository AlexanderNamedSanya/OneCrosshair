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
    T.cooldowns = {[3]={900,1200,true,ACTION_TYPE_ABILITY}, [4]={5000,10000,false}}
    O.GCD.Read(g); assert(g.active); close(g.progress,.25); assert(not g.ready)
    T.cooldowns = {[3]={0,1200,true,ACTION_TYPE_ABILITY}}; O.GCD.Read(g); assert(not g.active)
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
    assert(ring.textured)
    for _,key in ipairs({"health","bottom"}) do
        local a,b,center = O.ArcRenderer.Range(key,.5,ring.length)
        close(center-a,b-center)
        local _,_,fullCenter=O.ArcRenderer.Range(key,1,ring.length)
        close(center,fullCenter)
    end
    for _,key in ipairs({"magicka","stamina"}) do
        local a,b=O.ArcRenderer.Range(key,.5,ring.length)
        local fullA,fullB=O.ArcRenderer.Range(key,1,ring.length)
        if key=="magicka" then close(a,fullA); assert(b<fullB)
        else close(b,fullB); assert(a>fullA) end
    end
end)
test("optional effects threshold boundaries", function()
    assert(O.LowResource.Active(true,.25)); assert(not O.LowResource.Active(true,.251))
    assert(not O.LowResource.Active(false,.1)); assert(O.CriticalState == nil)
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
test("ping-zone boundary, whole-bar latch and immediate idle", function()
    local g = O.GCD.New()
    T.latency = 100; T.weaponUsable = true
    T.cooldowns = {[3]={1000,1000,true,ACTION_TYPE_ABILITY}}
    O.GCD.Read(g); assert(not g.ready)
    T.cooldowns[3][1] = 101; O.GCD.Read(g); assert(not g.ready)
    T.cooldowns[3][1] = 100; O.GCD.Read(g); assert(g.ready)
    local fill,color,alpha = O.GCD.Presentation(g)
    close(fill,1); assert(color == O.GCD.readyColor); close(alpha,1)
    T.latency = 10; T.weaponUsable = false; T.weaponFailure = true
    T.cooldowns[3][1] = 99; O.GCD.Read(g); assert(g.ready)
    T.cooldowns = {}; O.GCD.Read(g); assert(not g.active and not g.ready)
    fill,color,alpha = O.GCD.Presentation(g)
    close(fill,1); assert(color == O.GCD.idleColor); close(alpha,.25)
    T.latency = 100; T.weaponFailure = false
end)

test("physical slots 3..8 only, ultimate included, item globals rejected", function()
    local g = O.GCD.New()
    T.cooldowns = {[2]={1000,1000,true,ACTION_TYPE_ABILITY}, [3]={100,500,true,ACTION_TYPE_ITEM}}
    O.GCD.Read(g); assert(not g.active)
    T.cooldowns[8] = {100,800,true,ACTION_TYPE_CRAFTED_ABILITY}
    O.GCD.Read(g); assert(g.active); close(g.progress,.875)
    T.cooldowns = {}
end)
test("LA availability is observational, never the cue gate", function()
    local g = O.GCD.New()
    T.cooldowns = {[3]={100,800,true,ACTION_TYPE_ABILITY}}
    T.emptyWeapon = true; O.GCD.Read(g); assert(g.active and g.ready)
    T.emptyWeapon = false
    local usable = IsSlotUsable; IsSlotUsable = nil
    O.GCD.Read(g); assert(g.active and g.ready); IsSlotUsable = usable
end)

test("warning spans the empty resource and fades outward independently of solid fill", function()
    local ring = O.runtime.ring
    O.ResourceRing.Draw(ring,"health",.1,O.runtime.health.color,1,true)
    close(ring.arcs.health.glow.color[4],.6)
    close(ring.arcs.health.fill,.1)
    O.ResourceRing.Draw(ring,"health",0,O.runtime.health.color,1,true)
    close(ring.arcs.health.glow.color[4],.6)
    close(ring.arcs.health.first.color[4],0); close(ring.arcs.health.second.color[4],0)
    O.ResourceRing.Draw(ring,"health",.1,O.runtime.health.color,1,false)
    close(ring.arcs.health.glow.color[4],0)
end)

test("circular geometry and shield use the same path and outward-only 200 percent glow", function()
    local ring = O.runtime.ring
    local top = ring.arcs.health
    close(O.ArcAssets.radius,45.25); close(O.ArcAssets.thickness,5)
    close(top.first.width,2*O.ArcAssets.extent)
    close(top.first.width,ring.arcs.shield.first.width)
    close(top.first.anchor[4],ring.arcs.shield.first.anchor[4])
    close(top.first.anchor[5],ring.arcs.shield.first.anchor[5])
    local a,b=O.ArcRenderer.Range("health",.5,ring.length)
    local sa,sb=O.ArcRenderer.Range("shield",.5,ring.length)
    close(a,sa); close(b,sb)
    close(O.PresetRegistry.Get("dot").elements[1].size,1.5)
end)

test("heavy overrides green with gray, cancel restores GCD in same frame", function()
    T.now = 5000; O.settings.visibility = "ALWAYS"; O.settings.resources = true
    O.settings.gcd = true; T.weaponUsable = true
    T.cooldowns = {[3]={100,800,true,ACTION_TYPE_ABILITY}}
    O.HeavyChannel.provider = {Read=function() return {active=true,startMs=4000,endMs=6000} end}
    O.Runtime.Update(O.runtime)
    close(O.runtime.ring.arcs.bottom.fill,.5); assert(O.runtime.ring.arcs.bottom.color == O.GCD.idleColor)
    O.HeavyChannel.provider = nil; O.Runtime.Update(O.runtime)
    close(O.runtime.ring.arcs.bottom.fill,1); assert(O.runtime.ring.arcs.bottom.color == O.GCD.readyColor)
    T.cooldowns = {}; O.Runtime.Update(O.runtime)
    assert(O.runtime.ring.arcs.bottom.color == O.GCD.idleColor)
end)
test("low health warns without dimming other resources and respects its switch", function()
    T.powers[1] = 10; T.now = 6000; O.Runtime.Update(O.runtime)
    T.now = 6200; O.Runtime.Update(O.runtime)
    close(O.runtime.ring.arcs.health.fill,.1)
    close(O.runtime.ring.arcs.magicka.alpha, O.settings.hudOpacity)
    close(O.runtime.ring.arcs.bottom.alpha, O.settings.hudOpacity*.25)
    assert(O.runtime.ring.arcs.health.glow.color[4]>0)
    O.settings.lowResource = false; O.Runtime.Update(O.runtime)
    close(O.runtime.ring.arcs.health.glow.color[4],0)
    O.settings.lowResource = true; T.powers[1] = 26; O.Runtime.Update(O.runtime)
    close(O.runtime.ring.arcs.health.glow.color[4],0)
end)
