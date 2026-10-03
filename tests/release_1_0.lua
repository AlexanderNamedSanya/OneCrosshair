local O, N = OneCrosshair, OneCrosshair.NativeReticleColor
local function test(name,fn) fn(); print("PASS "..name) end
local function close(a,b) assert(math.abs(a-b)<.001,tostring(a).." ~= "..tostring(b)) end
local function color(r,g,b,a)
    local cr,cg,cb,ca=RETICLE.reticleTexture:GetColor()
    close(cr,r); close(cg,g); close(cb,b); close(ca,a)
end

test("release metadata and fixed appearance remain while UI has no sliders", function()
    assert(O.version=="26.1" and O.author=="oneDOK" and LibAddonMenu2.data.author=="oneDOK")
    close(O.settings.resourceLength,90); close(O.settings.resourceRadius,45.25)
    close(O.settings.resourceThickness,5); close(O.settings.crosshairOpacity,.65); close(O.settings.hudOpacity,.5)
    for _,option in ipairs(LibAddonMenu2.options) do assert(option.type~="slider") end
end)

test("code config overrides old appearance while preserving other saved choices", function()
    local old=ZO_SavedVars.NewAccountWide
    ZO_SavedVars.NewAccountWide=function() return {preset="rays",visibility="ALWAYS",gcd=false,
        resourceLength=20,resourceThickness=2,resourceRadius=25,crosshairOpacity=.1,hudOpacity=.2} end
    local saved=O.Settings.Load(); assert(saved.preset=="rays" and saved.visibility=="ALWAYS" and not saved.gcd)
    for key,value in pairs(O.Config) do close(saved[key],value) end
    local previous=O.Config.resourceLength; O.Config.resourceLength=80
    close(O.Settings.Load().resourceLength,80); O.Config.resourceLength=previous
    ZO_SavedVars.NewAccountWide=old
end)

test("both dot sizes halve while only small dots gain 25 percent spacing", function()
    local small,large=O.PresetRegistry.Get("dot"),O.PresetRegistry.Get("large_dot")
    local c=O.CrosshairController.New(GuiRoot)
    for _,item in ipairs({{"dot",3},{"large_dot",15}}) do
        O.CrosshairController.SetPreset(c,item[1],"target")
        O.CrosshairController.Update(c,{geometry="target"},1,0,true)
        close(c.elements[1].control.width*c.root.scale,item[2])
    end
    close(small.states.target[2].x,-6*1.25); close(small.states.block[2].x,-3.5*1.25)
    close(large.states.target[2].x,-9); close(large.states.block[2].x,-9)
end)

test("native combat color fades in and out and hit animation cannot overwrite it", function()
    RETICLE.reticleTexture:SetColor(.7,.8,.9,.6)
    O.settings.preset="eso"; T.now=1000; T.combat=false; Fire(EVENT_PLAYER_ACTIVATED)
    O.Runtime.Update(O.runtime); T.now=1100; O.Runtime.Update(O.runtime); color(1,1,1,.6)
    T.combat=true; T.now=1200; O.Runtime.Update(O.runtime)
    T.now=1250; O.Runtime.Update(O.runtime); color(1,.575,.56,.6)
    T.now=1300; O.Runtime.Update(O.runtime); color(1,.15,.12,.6)
    RETICLE:OnImpactfulHit(); color(1,.15,.12,.6); assert(not RETICLE.hitIndicatorTimeline.playing)
    T.combat=false; T.now=1400; O.Runtime.Update(O.runtime)
    T.now=1500; O.Runtime.Update(O.runtime); color(1,1,1,.6)
    Fire(EVENT_PLAYER_DEACTIVATED); color(.7,.8,.9,.6); assert(not N.active)
end)

test("native color ownership restores on menus and preset changes without affecting preview", function()
    T.combat=true; O.settings.preset="eso"; T.now=2000; Fire(EVENT_PLAYER_ACTIVATED)
    O.Runtime.Update(O.runtime); T.now=2100; O.Runtime.Update(O.runtime); color(1,.15,.12,.6)
    O.Preview.Refresh(); color(1,.15,.12,.6)
    T.menu=true; O.Runtime.Update(O.runtime); color(.7,.8,.9,.6); assert(not N.active)
    T.menu=false; T.now=2200; O.Runtime.Update(O.runtime)
    O.settings.preset="dot"; O.Runtime.Update(O.runtime); color(.7,.8,.9,.6); assert(not N.active)
    RETICLE:OnImpactfulHit(); assert(RETICLE.hitIndicatorTimeline.playing)
    Fire(EVENT_PLAYER_DEACTIVATED)
end)
