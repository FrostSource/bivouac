
require 'util.util'
require 'util.storage'
require 'util.player'
require 'util.input'

require 'bivouac.debug'

---Set entity pitch, yaw, roll from a `QAngle`. If parented, this is set relative to the parents local space.
---@param qangle any
function CBaseEntity:SetAngle(qangle)
    self:SetAngles(qangle.x, qangle.y, qangle.z)
end

---Find an entity within the same prefab as another entity.
---Will have issues in nested prefabs.
---@param entity EntityHandle
---@param name string
---@return EntityHandle?
function Entities:FindInPrefab(entity, name)
    local myname = entity:GetName()
    for _,ent in ipairs(Entities:FindAllByName('*' .. name)) do
        local prefab_part = ent:GetName():sub(1, #ent:GetName() - #name)
        if prefab_part == myname:sub(1, #prefab_part) then
            return ent
        end
    end
    return nil
end
---Find an entity within the same prefab as this entity.
---Will have issues in nested prefabs.
---@param name string
---@return EntityHandle?
function CEntityInstance:FindInPrefab(name)
    return Entities:FindInPrefab(self, name)
end

function CBaseEntity:GetMaxSize()
    return #(self:GetBoundingMaxs() - self:GetBoundingMins())
end

function CBaseEntity:DisablePickup()
    DoEntFireByInstanceHandle(self, "DisablePickup", "", 0, self, self)
end
function CBaseEntity:EnablePickup()
    DoEntFireByInstanceHandle(self, "EnablePickup", "", 0, self, self)
end

---Get hand name.
---@return string
function CPropVRHand:HandName()
    return self:GetHandID() == 0 and "Left hand" or "Right hand"
end

---@type EntityHandle
LastHintDisplayed = nil

---Show a hint
---@param skin "hint_1"|"hint_2"|"hint_3"
---@param attach 0|1|2 # 0 = none, 1 = primary hand, 2 = secondary hand
function CreateHint(skin, attach)
    if not Convars:GetBool("gameinstructor_enable") or Convars:GetBool("sv_gameinstructor_disable") then
        return
    end
    -- print("Spawning hint")
    local hint = SpawnEntityFromTableSynchronous("prop_dynamic", {
        model = "models/bivouac/hint_panel.vmdl",
        vscripts = "bivouac/hint_panel",
        skin = skin,
        targetname = "hint_panel"
    })
    hint.attach = attach
    LastHintDisplayed = hint
    hint:GetPrivateScriptScope():ShowHint()
end

function HideLastHint()
    if LastHintDisplayed then
        LastHintDisplayed:GetPrivateScriptScope():HideHint()
        LastHintDisplayed = nil
    end
end
function ShowFirstHint()
    print("Showing first hint")
    CreateHint("hint_1", 2)
end
function ShowSecondHint()
    print("Showing second hint")
    local hand = 1
    if Player.PrimaryHand.ItemHeld and Player.PrimaryHand.ItemHeld:GetName() == "@backpack" then
        hand = 2
    end
    CreateHint("hint_2", hand)
end
function ShowThirdHint()
    print("Showing third hint")
    local hand = 2
    if Player.PrimaryHand.ItemHeld and Player.PrimaryHand.ItemHeld:GetName() == "@backpack" then
        hand = 1
    end
    CreateHint("hint_3", hand)
end

local PortalScreenFog = -1
local PortalScreenFogScalar
function GetPortalScreenFog()
    return PortalScreenFog
end

function CreatePortalScreenFog()
    DoEntFire("PortalScreenFogParticle", "Stop", "", 0, nil, nil)
    PortalScreenFogScalar = Entities:FindByName(nil, "PortalScreenFogAlphaScalar")
    -- local pt = Entities:FindByName(nil, "PortalScreenFogParticle")
    SetPortalScreenFogValue(0)
    DoEntFire("PortalScreenFogParticle", "Start", "", 0, nil, nil)

    -- if PortalScreenFog then
    --     ParticleManager:DestroyParticle(PortalScreenFog, true)
    -- end
    -- PortalScreenFog = ParticleManager:CreateParticleForPlayer("particles/bivouac/screen_portal.vpcf", 0, Player, Player)
end
function SetPortalScreenFogValue(value)
    if PortalScreenFogScalar then
        PortalScreenFogScalar:SetOrigin(Vector(value))
    end

    -- if PortalScreenFog > -1 then
    --     ParticleManager:SetParticleControl(PortalScreenFog, 0, Vector(1))
    -- end
end

function SetWindValue(value)
    SetOpvarFloatAll('hlvr_global_opvars', 'opvars', 'wind_val_raw', value)
end

-- ---Add a function to the global scope with alternate casing styles.
-- ---Makes a function easier to call from Hammer through I/O.
-- ---@param func function # The function to sanitize.
-- ---@param name? string # Optionally the name of the function for faster processing. Is required if using a local function.
-- ---@param scope? table # Optionally the explicit scope to put the sanitized functions in.
-- function Expose(func, name, scope)
--     util.SanitizeFunctionForHammer(func, name, scope)
-- end

Input:TrackNoButtons()
Input.PressedTolerance = 0.1
Input.ReleasedTolerance = 0.1

---@class Bucket
---@field is_pouring boolean
---@field pour_position Vector
---@field pour_speed number

---The bucket entity.
---@type EntityHandle|Bucket
Bucket = nil

---The backpack entity.
---@type EntityHandle
Backpack = nil

---The flashlight entity.
---@type EntityHandle
Flashlight = nil

RegisterPlayerEventCallback("player_activate", function(data)
    ---@cast data PLAYER_EVENT_PLAYER_ACTIVATE

    for _, ent in ipairs(Entities:FindAllByName("*bucket*")) do
        if ent:LoadBoolean("IsBucket", false) then
            Bucket = ent
            break
        end
    end

    Backpack = Entities:FindByName(nil, "@backpack")
    -- If first time startup, put note in backpack for hints
    if not data.game_loaded and Backpack then
        print("Putting start note in backpack")
        local note = Entities:FindByName(nil, "note_1")
        Backpack:GetPrivateScriptScope().PutItemInBackpack(note, nil, true)
    end

    for _, ent in ipairs(Entities:FindAllByName("*flashlight*")) do
        if ent:LoadBoolean("IsFlashlight", false) then
            Flashlight = ent
            break
        end
    end

    local val = Player:LoadNumber("RawWindValue", 0)
    SetWindValue(val)

end)
RegisterPlayerEventCallback("vr_player_ready", function()
    local left_hand = Entities:FindByName(nil, "@hand_lowpoly_left")
    if left_hand then
        Player.LeftHand:MergeProp(left_hand, true)
    end
    local right_hand = Entities:FindByName(nil, "@hand_lowpoly_right")
    if right_hand then
        Player.RightHand:MergeProp(right_hand, true)
    end
    Input:StartTrackingOn(Player)
end)



