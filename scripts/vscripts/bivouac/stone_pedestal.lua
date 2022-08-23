
require 'bivouac.init'

local ANGLES = {
    [0]   = "1",
    [60]  = "6",
    [120] = "5",
    [180] = "4",
    [240] = "3",
    [300] = "2",
    [360] = "1",
}

---@param activateType "0"|"1"|"2"
function Activate(activateType)
    -- Kill preview stuff just in case accidentally left in
    for _, child in ipairs(thisEntity:GetChildren()) do
        if child:GetName():find("preview") then
            child:Kill()
        end
    end
end

---Checks if the target parented to this has a rock parented to it
local function UpdateState()
    -- for _, child in ipairs(thisEntity:GetChildren()) do
    --     if #child:GetChildren() > 0 then
    --         return
    --     end
    -- end
    if thisEntity:LoadBoolean("HasStoneAttached", false) then
        thisEntity:FireOutput("OnUser2", thisEntity, thisEntity, nil, 0)
        thisEntity:SaveBoolean("HasStoneAttached", false)
    end
end
thisEntity:GetPrivateScriptScope().UpdateState = UpdateState

---comment
---@param io TypeIOInvoke
local function Attach(io)
    local top = io.activator:GetAttachmentOrigin(io.activator:ScriptLookupAttachment("top"))
    local angle_vector = thisEntity:TransformPointWorldToEntity(top):Normalized()
    local angle = (math.atan2(angle_vector.y,angle_vector.x)*180/math.pi) + 180
    local snapped = math.floor((angle / 60) + 0.5) * 60
    local adjusted = ANGLES[snapped]
    print("attaching stone "..io.activator:GetName().." to pedestal at angle", angle, snapped, adjusted)
    local target = Entities:FindByName(nil, thisEntity:GetName() .. "_target_" .. adjusted)

    io.activator:EmitSound("Bivouac.StonePlace")

    local data = thisEntity:FindInPrefab("pedestal_data")
    if data and data:LoadString("correct_angle") == adjusted
    and data:LoadString("correct_stone") == io.activator:GetName() then
        thisEntity:FireOutput("OnUser1", thisEntity, thisEntity, nil, 0)
    end

    -- local top = io.activator:GetAttachmentOrigin(io.activator:ScriptLookupAttachment("top"))
    -- local angle_vector = io.activator:TransformPointWorldToEntity(top):Normalized()
    -- RotatePosition(io.activator:GetOrigin(), QAngle(0,0,60), io.activator:GetForwardVector())
    io.activator:Drop()
    io.activator:SetOrigin(target:GetOrigin())
    io.activator:SetAngle(target:GetAngles())
    io.activator:SetParent(target, "")
    thisEntity:SaveBoolean("HasStoneAttached", true)
end
thisEntity:GetPrivateScriptScope().Attach = Attach

---@type EntityHandle
local debug_stone

local function DebugStoneCreate()
    if not debug_stone then
        debug_stone = SpawnEntityFromTableSynchronous("prop_dynamic_override",{
            origin = thisEntity:GetOrigin(),
            angles = thisEntity:GetAngles(),
            model = "models/bivouac/stone_symbol_0.vmdl",
        })
        print(thisEntity:GetName())
        print(thisEntity:GetAngles())
        print(debug_stone:GetAngles())
        -- debug_stone:SetOrigin(thisEntity:GetOrigin())
        -- debug_stone:SetAngle(thisEntity:GetAngles())
    end
end
Convars:RegisterCommand("debug_stone_create", DebugStoneCreate, "", 0)
local function DebugStoneDestroy()
    if debug_stone then
        debug_stone:Kill()
        debug_stone = nil
    end
end
Convars:RegisterCommand("debug_stone_destroy", DebugStoneDestroy, "", 0)
local function DebugStoneRotate()
    if debug_stone then
        print("Forward", debug_stone:GetForwardVector())
        local rot = RotatePosition(
            debug_stone:GetOrigin(),
            QAngle(0,60,0),
            debug_stone:GetForwardVector())
        print("New rotation", rot)
        debug_stone:SetForwardVector(rot)
        print("New forward", debug_stone:GetForwardVector())
    end
end
Convars:RegisterCommand("debug_stone_rotate", DebugStoneRotate, "", 0)
local function DebugStoneSnap()
    if debug_stone then
        local top = debug_stone:GetAttachmentOrigin(debug_stone:ScriptLookupAttachment("top"))
        local angle_vector = debug_stone:TransformPointWorldToEntity(top):Normalized()
    end
end
Convars:RegisterCommand("debug_stone_snap", DebugStoneSnap, "", 0)

-- local function testthink()
--     local s = Entities:FindByName(nil, 'tesy_stone')
--     local top = s:GetAttachmentOrigin(s:ScriptLookupAttachment("top"))
--     local angle_vector = thisEntity:TransformPointWorldToEntity(top):Normalized()
--     local angle = (math.atan2(angle_vector.y,angle_vector.x)*180/math.pi) + 180
--     local snapped = math.floor((angle / 60) + 0.5) * 60
--     print("angle_vector", angle_vector)
--     print("angle", snapped)
--     return 0.5
-- end
-- thisEntity:SetThink(testthink, 'testthink', 1)

-- 0
-- 60
-- 120
-- 180
-- 240
-- 300
-- 360