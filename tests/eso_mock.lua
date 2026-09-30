-- Deliberately explicit API surface. Unknown functions cause normal Lua errors.
CT_CONTROL, CT_TEXTURE, CT_LABEL, CENTER, TOPLEFT, TOPRIGHT, TOP = 1, 2, 3, 4, 5, 6, 7
CT_LINE, BOTTOMRIGHT = 8, 9
COMBAT_MECHANIC_FLAGS_HEALTH, COMBAT_MECHANIC_FLAGS_MAGICKA, COMBAT_MECHANIC_FLAGS_STAMINA = 1, 2, 4
ATTRIBUTE_VISUAL_POWER_SHIELDING, STAT_MITIGATION, ATTRIBUTE_HEALTH = 10, 11, 12
ACTION_BAR_FIRST_NORMAL_SLOT_INDEX, ACTION_BAR_ULTIMATE_SLOT_INDEX = 2, 7
ACTION_TYPE_ABILITY, ACTION_TYPE_CRAFTED_ABILITY, ACTION_TYPE_ITEM = 1, 2, 3
COMBAT_UNIT_TYPE_NONE, COMBAT_UNIT_TYPE_PLAYER = 0, 1
ACTION_SLOT_TYPE_LIGHT_ATTACK, ACTION_SLOT_TYPE_HEAVY_ATTACK, ACTION_SLOT_TYPE_NORMAL_ABILITY = 1, 2, 3
ACTION_RESULT_DAMAGE, ACTION_RESULT_CRITICAL_DAMAGE, ACTION_RESULT_DAMAGE_SHIELDED = 1, 2, 3
ACTION_RESULT_BLOCKED_DAMAGE, ACTION_RESULT_DOT_TICK, ACTION_RESULT_HOT_TICK = 4, 5, 6
EVENT_ADD_ON_LOADED, EVENT_PLAYER_ACTIVATED, EVENT_PLAYER_DEACTIVATED = 1, 2, 3
EVENT_ACTION_SLOT_ABILITY_USED, EVENT_COMBAT_EVENT = 4, 5
REGISTER_FILTER_SOURCE_COMBAT_UNIT_TYPE = 1
T = { now = 0, latency = 100, target = false, interact = false, block = false, combat = false,
      camera = true, menu = false, reticleHidden = false, dead = false, powers = {100,100,[4]=100},
      maxHealth = 100, shield = 0, cooldowns = {}, ids = {[1]=101,[2]=102,[3]=103} }
local methods = {}
function methods:SetTexture(v) self.texture = v end
function methods:SetDimensions(w,h) self.width, self.height = w,h end
function methods:SetHidden(v) self.hidden = v end
function methods:IsHidden() return self.hidden or (self.parent and self.parent:IsHidden()) or false end
function methods:SetAnchor(...) self.anchor = {...}; self.anchors = self.anchors or {}; self.anchors[(...)] = {...} end
function methods:ClearAnchors() self.anchor = nil; self.anchors = {} end
function methods:SetPixelRoundingEnabled(v) self.rounding = v end
function methods:SetThickness(v) self.thickness = v end
function methods:SetColor(...) self.color = {...} end
function methods:SetAlpha(v) self.alpha = v end
function methods:SetScale(v) self.scale = v end
function methods:SetTextureRotation(v) self.rotation = v end
function methods:SetDrawLevel(v) self.level = v end
function methods:SetMouseEnabled(v) self.mouse = v end
function methods:SetFont(v) self.font = v end
function methods:SetText(v) self.text = v end
local function control(parent) return setmetatable({parent=parent}, {__index=methods}) end
GuiRoot = control()
WINDOW_MANAGER = {}
function WINDOW_MANAGER:CreateControl(name,parent,kind) return control(parent) end
function WINDOW_MANAGER:CreateTopLevelWindow(name) return control(GuiRoot) end
EVENT_MANAGER = { events = {}, updates = {} }
function EVENT_MANAGER:RegisterForEvent(name,event,fn) self.events[name..":"..event] = {event,fn} end
function EVENT_MANAGER:UnregisterForEvent(name,event) self.events[name..":"..event] = nil end
function EVENT_MANAGER:AddFilterForEvent(...) end
function EVENT_MANAGER:RegisterForUpdate(name,ms,fn) self.updates[name] = fn end
function Fire(event, ...)
    local handlers = {}
    for _,v in pairs(EVENT_MANAGER.events) do if v[1] == event then handlers[#handlers+1] = v[2] end end
    for _,fn in ipairs(handlers) do fn(event, ...) end
end
function GetFrameTimeMilliseconds() return T.now end
function DoesUnitExist(tag) assert(tag == "reticleover"); return T.target end
function GetGameCameraInteractableInfo() return T.interact end
function IsBlockActive() return T.block end
function IsUnitInCombat(tag) return T.combat end
function IsUnitDead(tag) return T.dead end
function IsGameCameraActive() return T.camera end
function IsGameCameraUIModeActive() return T.menu end
function IsReticleHidden() return T.reticleHidden end
function GetUnitPower(tag,power) return T.powers[power], power == 1 and T.maxHealth or 100, 100 end
function GetUnitAttributeVisualizerEffectInfo(tag,visual,stat,attribute,power)
    assert(tag == "player" and visual == 10 and stat == 11 and attribute == 12 and power == 1)
    return T.shield
end
function GetSlotCooldownInfo(slot)
    local c = T.cooldowns[slot] or {0,0,false}
    return unpack(c)
end
function GetSlotBoundId(slot) return T.ids[slot] or 0 end
function IsSlotUsed(slot) return T.ids[slot] ~= nil and not T.emptyWeapon end
function IsSlotUsable(slot) return T.weaponUsable == true end
function ActionSlotHasNonCostStateFailure(slot) return T.weaponFailure == true end
function GetSlotType(slot) return T.slotTypes and T.slotTypes[slot] or ACTION_TYPE_ABILITY end
function GetActiveHotbarCategory() return T.hotbar or 0 end
SLASH_COMMANDS = {}
T.chat = {}
function d(message) T.chat[#T.chat + 1] = message end
RETICLE = {control=control(), reticleTexture=control()}
function RETICLE:UpdateHiddenState() self.reticleTexture:SetHidden(T.stealth or false) end
function ZO_PostHook(object,key,fn)
    local old = object[key]
    object[key] = function(...) old(...); fn(...) end
end
local strings = {}
function ZO_CreateStringId(id,value) _G[id] = id; strings[id] = value end
function SafeAddString(id,value,version) assert(id); strings[id] = value end
function GetString(id) assert(strings[id], tostring(id)); return strings[id] end
ZO_SavedVars = {}
function ZO_SavedVars:NewAccountWide(name,version,namespace,defaults)
    assert(name == "OneCrosshairSavedVariables" and version == 1)
    local result = {}; for k,v in pairs(defaults) do result[k] = v end; return result
end
LibAddonMenu2 = {}
function LibAddonMenu2:RegisterAddonPanel(name,data) self.panel = control(); self.data = data; return self.panel end
function LibAddonMenu2:RegisterOptionControls(name,options)
    self.options = options
    for _,option in ipairs(options) do if option.createFunc then option.createFunc(control(self.panel)) end end
end
CALLBACK_MANAGER = { handlers = {} }
function CALLBACK_MANAGER:RegisterCallback(name,fn) self.handlers[name] = fn end

function GetLatency() return T.latency end

-- Heavy/channel reference event contract; values are mock-only, not ESO IDs.
EVENT_ACTION_UPDATE_COOLDOWNS, EVENT_EFFECT_CHANGED = 20, 21
EVENT_ACTION_SLOTS_ACTIVE_HOTBAR_UPDATED, EVENT_WEAPON_PAIR_LOCK_CHANGED = 22, 23
EVENT_PLAYER_DEAD, EVENT_MOUNTED_STATE_CHANGED = 24, 25
EFFECT_RESULT_GAINED, EFFECT_RESULT_UPDATED, EFFECT_RESULT_FADED = 1, 2, 3
ACTION_RESULT_BEGIN, ACTION_RESULT_BEGIN_CHANNEL = 100, 101
ACTION_RESULT_EFFECT_GAINED, ACTION_RESULT_EFFECT_FADED = 102, 103
ACTION_RESULT_KNOCKBACK, ACTION_RESULT_PACIFIED, ACTION_RESULT_STAGGERED = 104, 105, 106
ACTION_RESULT_STUNNED, ACTION_RESULT_INTERRUPT, ACTION_RESULT_FEARED, ACTION_RESULT_LEVITATED = 107, 108, 109, 110
ACTION_RESULT_FAILED, ACTION_RESULT_FAILED_REQUIREMENTS, ACTION_RESULT_ABILITY_ON_COOLDOWN = 111, 112, 113
ACTION_RESULT_INSUFFICIENT_RESOURCE, ACTION_RESULT_SILENCED, ACTION_RESULT_TARGET_DEAD = 114, 115, 116
ACTION_RESULT_NO_LOCATION_FOUND, ACTION_RESULT_IMMUNE, ACTION_RESULT_CASTER_DEAD = 117, 118, 119
ACTION_RESULT_DIED, ACTION_RESULT_DIED_XP = 120, 121
function GetAbilityCastInfo(id) local info = T.castInfo and T.castInfo[id]; if info then return unpack(info) end; return false, 0 end
function GetAbilityIdForCraftedAbilityId(id) return T.crafted and T.crafted[id] or 0 end
function IsSlotToggled(slot) return T.toggled == slot end
function IsMounted() return T.mounted or false end
function ArePlayerWeaponsSheathed() return T.sheathed or false end
function GetNumBuffs(tag) return T.crux and 1 or 0 end
function GetUnitBuffInfo(tag,index) return "Crux",0,0,1,T.crux,"","",0,0,0,184220 end

EVENT_SKILLS_FULL_UPDATE, EVENT_SKILL_LINE_ADDED, EVENT_END_CRAFTING_STATION_INTERACT = 26, 27, 28
MORPH_SLOT_BASE, MORPH_SLOT_MORPH_1, MORPH_SLOT_MORPH_2 = 0, 1, 2
function GetAbilityName(id) return "Ability " .. id end
function GetNumSkillTypes() return 1 end
function GetNumSkillLines(kind) return T.skills and 1 or 0 end
function GetNumSkillAbilities(kind,line) return #T.skills end
function IsCraftedAbilitySkill(kind,line,skill) return T.skills[skill].crafted ~= nil end
function IsSkillAbilityPassive(kind,line,skill) return T.skills[skill].passive or false end
function GetCraftedAbilitySkillCraftedAbilityId(kind,line,skill) return T.skills[skill].crafted end
function GetSkillAbilityId(kind,line,skill) return T.skills[skill].id end
function GetProgressionSkillProgressionId(kind,line,skill) return T.skills[skill].progression or 0 end
function GetSpecificSkillAbilityInfo(kind,line,skill,morph,rank)
    return T.skills[skill].ranks[morph * 4 + rank] or 0
end
function GetProgressionSkillMorphSlotChainedAbilityIds(progression,morph)
    return unpack(T.chained and T.chained[morph] or {})
end
