local O = OneCrosshair
local function close(a,b) assert(math.abs(a-b)<1e-8,tostring(a).." ~= "..tostring(b)) end
local ring = O.ResourceRing.New(GuiRoot)
assert(ring.textured and ring.fallback == nil)
local count=0
for name,arc in pairs(ring.arcs) do
    count=count+2+(arc.glow and 1 or 0)
    assert(arc.first.texture=="OneCrosshair/Assets/"..(name=="shield" and "ArcShield" or "ArcFill")..".dds")
    assert(arc.first.rounding==false)
    for _,fill in ipairs({0,.001,.1,.25,.501,.75,.999,1}) do
        local color={.2,.4,.8}
        for _,alpha in ipairs({0,.25,.5,1}) do
            O.ResourceRing.Draw(ring,name,fill,color,alpha,true)
            local lower,upper=arc.first.color[4],arc.second.color[4]
            close(lower+upper*(1-lower),fill==0 and 0 or alpha)
            close(arc.first.color[1],.2); close(arc.second.color[3],.8)
            if arc.glow then close(arc.glow.color[4],alpha*.6) end
            for _,c in ipairs({arc.first,arc.second}) do
                local uv=c.textureCoords
                assert(uv[1]>=0 and uv[2]<=1 and uv[3]>=0 and uv[4]<=1)
                close(uv[2]-uv[1],1/8); close(uv[4]-uv[3],1/16)
            end
        end
    end
end
assert(count==13)
for _,fill in ipairs({0,.1,.5,1}) do
    local ha,hb=O.ArcRenderer.Range("health",fill,90)
    local sa,sb=O.ArcRenderer.Range("shield",fill,90)
    close(ha,sa); close(hb,sb); close((ha+hb)/2,-math.pi/2)
    local ba,bb=O.ArcRenderer.Range("bottom",fill,90)
    close((ba+bb)/2,math.pi/2); close(bb-ba,hb-ha)
    local ma,mb=O.ArcRenderer.Range("magicka",fill,90)
    close(ma,math.pi-math.pi*.225)
    local ta,tb=O.ArcRenderer.Range("stamina",fill,90)
    close(tb,math.pi*.225)
    close(mb-ma,tb-ta)
end
O.ResourceRing.Configure(ring,{resourceRadius=70,resourceThickness=8,resourceLength=100})
assert(not ring.textured and ring.fallback and ring.textureArcs.health.first.hidden)
O.ResourceRing.Configure(ring,{})
assert(ring.textured and ring.fallback.root.hidden and not ring.arcs.health.first.hidden)
O.ResourceRing.Draw(ring,"health",1,{1,0,0},.5,true)
close(ring.arcs.health.first.color[4],.5)
print("PASS curved textures: 13 controls, UV cells, opacity, fill ranges, shield alignment and geometry fallback")
