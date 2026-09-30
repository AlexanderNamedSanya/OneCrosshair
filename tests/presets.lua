local O = OneCrosshair
local function test(name,fn) fn(); print("PASS "..name) end
local function close(a,b) assert(math.abs(a-b)<.001) end

test("four presets are selectable with stable IDs and existing Dot default", function()
    assert(#O.PresetRegistry.list==4 and O.Settings.defaults.preset=="dot")
    for _,id in ipairs({"dot","rays","diamonds","eso"}) do
        assert(O.PresetRegistry.Get(id).id==id)
    end
    local count=0
    for _,option in ipairs(LibAddonMenu2.options) do
        if option.name==GetString(SI_ONECROSSHAIR_PRESET) then
            assert(#option.choicesValues==4)
            for _,id in ipairs(option.choicesValues) do
                option.setFunc(id)
                for _,example in ipairs(O.Preview.examples) do assert(example.crosshair.preset.id==id) end
                count=count+1
            end
        end
    end
    assert(count==4)
end)

test("reference presets display their three states and interpolate transitions", function()
    local c=O.CrosshairController.New(GuiRoot)
    for _,id in ipairs({"rays","diamonds"}) do
        O.CrosshairController.SetPreset(c,id,"normal")
        for _,state in ipairs({"normal","target","block"}) do
            O.CrosshairController.Update(c,{geometry=state},1,0,true)
            local visible=0
            for _,e in ipairs(c.elements) do if e.control.color[4]>.99 then visible=visible+1 end end
            assert(visible==(id=="rays" and 1 or (state=="normal" and 1 or 3)))
        end
        O.CrosshairController.Update(c,{geometry="normal"},1,0,true)
        O.CrosshairController.Update(c,{geometry="target"},1,1)
        O.CrosshairController.Update(c,{geometry="target"},1,126)
        close(c.elements[2].control.color[4],.5)
        O.CrosshairController.Update(c,{geometry="target"},1,251)
        close(c.elements[2].control.color[4],1)
    end
end)

test("ESO preview uses single atlas cells; pooled controls reset UV and dimensions", function()
    local c=O.CrosshairController.New(GuiRoot)
    O.CrosshairController.SetPreset(c,"eso","normal")
    assert(c.elements[1].control.texture=="EsoUI/Art/Reticle/reticleAnim.dds")
    close(c.elements[1].control.textureCoords[2],1/16)
    close(c.elements[2].control.textureCoords[1],15/16)
    close(c.elements[1].control.width,64)
    for _,id in ipairs({"dot","rays","diamonds"}) do
        O.CrosshairController.SetPreset(c,id,"normal")
        for _,e in ipairs(c.elements) do
            close(e.control.textureCoords[1],0); close(e.control.textureCoords[2],1)
            assert(not e.control:IsHidden())
        end
        O.CrosshairController.SetPreset(c,"eso","normal")
        assert(c.pool[3]:IsHidden())
    end
end)

test("native preset restores ESO ownership while resources stay active; switching is reversible", function()
    O.settings.preset="dot"; O.settings.visibility="ALWAYS"; T.now=1000
    Fire(EVENT_PLAYER_ACTIVATED); O.Runtime.Update(O.runtime)
    assert(RETICLE.reticleTexture:IsHidden() and not O.runtime.crosshair.root:IsHidden())
    O.settings.preset="eso"; T.now=1200; O.Runtime.Update(O.runtime)
    assert(not O.ReticleReplacement.active and not RETICLE.reticleTexture:IsHidden())
    assert(O.runtime.crosshair.root:IsHidden() and not O.runtime.root:IsHidden())
    assert(O.runtime.ring.arcs.health.alpha>0)
    RETICLE:UpdateHiddenState(); assert(not RETICLE.reticleTexture:IsHidden())
    T.stealth=true; RETICLE:UpdateHiddenState(); assert(RETICLE.reticleTexture:IsHidden())
    O.settings.preset="rays"; O.Runtime.Update(O.runtime)
    assert(O.ReticleReplacement.active and not O.runtime.crosshair.root:IsHidden())
    O.settings.preset="eso"; O.Runtime.Update(O.runtime)
    assert(RETICLE.reticleTexture:IsHidden()) -- native stealth hiding preserved
    T.stealth=false; RETICLE:UpdateHiddenState(); assert(not RETICLE.reticleTexture:IsHidden())
    T.menu=true; O.Runtime.Update(O.runtime); assert(O.runtime.root:IsHidden())
    T.menu=false; O.settings.preset="diamonds"; O.Runtime.Update(O.runtime)
    assert(O.ReticleReplacement.active and not O.runtime.crosshair.root:IsHidden())
    Fire(EVENT_PLAYER_DEACTIVATED); assert(not RETICLE.reticleTexture:IsHidden())
end)

test("native preview has full opacity and does not change the live reticle", function()
    O.settings.preset="eso"; O.settings.crosshairOpacity=.2
    local hidden=RETICLE.reticleTexture:IsHidden()
    O.Preview.Refresh()
    assert(RETICLE.reticleTexture:IsHidden()==hidden)
    for _,e in ipairs(O.Preview.examples) do close(e.crosshair.root.alpha,1) end
    for _,option in ipairs(LibAddonMenu2.options) do
        if option.name==GetString(SI_ONECROSSHAIR_CROSSHAIR_OPACITY) then
            assert(option.disabled()); O.settings.preset="rays"; assert(not option.disabled())
        end
    end
    O.Preview.Refresh()
    close(O.Preview.examples[1].crosshair.root.alpha,.2)
end)
