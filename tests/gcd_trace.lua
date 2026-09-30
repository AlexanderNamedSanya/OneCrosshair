local O = OneCrosshair
local function test(name, fn) fn(); print("PASS " .. name) end
local function setup()
    T.now, T.chat, T.latency = 0, {}, 100
    T.emptyWeapon, T.weaponUsable, T.weaponFailure = false, true, false
    T.cooldowns = {[3]={700,1000,true,ACTION_TYPE_ABILITY}, [1]={20,100,false,ACTION_TYPE_ABILITY}}
end
test("client trace replay: only late ping zone is green", function()
    setup(); local g = O.GCD.New()
    local remaining = {966,866,833,733,633,533,433,333,233,133,33,0,1000,900,800,700}
    for i,ms in ipairs(remaining) do
        T.weaponFailure = i <= 2
        T.cooldowns = {[3]={ms,1000,true,ACTION_TYPE_ABILITY},[1]={ms,1000,true,ACTION_TYPE_ABILITY}}
        O.GCD.Read(g)
        assert(g.ready == (ms > 0 and ms <= 100), "trace row " .. i)
    end
end)
