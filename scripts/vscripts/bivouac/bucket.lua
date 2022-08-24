

require 'bivouac.init'
-- local POUR_FACTOR = 0.01

---@type integer
local water_level = 0
---@type EntityHandle
local water_ent = nil

local pour_pt

---Set the water level [0-1]
---@param level number
local function SetWaterLevel(level)
    level = Clamp(level, 0, 1)
    water_level = level
    local scale = Lerp(level, 0.6, 0.95)
    local height = Lerp(level, 0.1, 11)
    water_ent:SetAbsScale(scale)
    water_ent:SetOrigin(thisEntity:TransformPointEntityToWorld(Vector(0, 0, height)))
    water_ent:SetParent(thisEntity, "")
    if water_level > 0 then
        EnablePour()
    end
    thisEntity:SaveNumber("water_level", water_level)
    -- debugoverlay:Sphere(water:GetOrigin(), 8, 255, 0, 0, 255, true, 0)
end
thisEntity:GetPrivateScriptScope().SetWaterLevel = SetWaterLevel

local fill_from_pond = false

local function StartFillFromPond(io)
    print("StartFillFromPond")
    fill_from_pond = true
end
thisEntity:GetPrivateScriptScope().StartFillFromPond = StartFillFromPond

local function StopFillFromPond(io)
    print("StopFillFromPond")
    fill_from_pond = false
end
thisEntity:GetPrivateScriptScope().StopFillFromPond = StopFillFromPond

local function disposeParticle()
    if pour_pt then
        ParticleManager:DestroyParticle(pour_pt, false)
        pour_pt = nil
    end
end

local just_started_pouring = false

local function PourThink()
    -- debugoverlay:Text(thisEntity:GetOrigin(), 0, tostring(thisEntity:GetUpVector()), 100, 255,255,255,255,0)
    -- 1 is up -1 is down

    -- any value above this will never pour
    local top_tip_value = 0.45
    -- any value below this will always pour
    local bottom_tip_value = -0.15
    -- pour speed at top tip
    local top_pour_value = 0.0005
    -- pour speed at full upside down
    local bottom_pour_value = 0.01
    local tip_value = RemapVal(water_level, 0, 1, bottom_tip_value, top_tip_value)
    local this = thisEntity

    if fill_from_pond then
        -- print("Checking if bucket is up")
        local fill_z = thisEntity:GetAttachmentOrigin(thisEntity:ScriptLookupAttachment('pour_pos')).z
        -- hard coded
        local water_z = -9.6
        print(fill_z, water_z, (fill_z - water_z))
        if thisEntity:GetUpVector().z >= 0 and (fill_z - water_z) < 4 then
            SetWaterLevel(water_level + 0.02)
            print("\tAdding water", water_level)
        end
    elseif thisEntity:GetUpVector().z < tip_value then
        local pour_pos = thisEntity:GetAttachmentOrigin(thisEntity:ScriptLookupAttachment('pour_pos'))
        local origin = CalcClosestPointOnEntityOBB(thisEntity, Vector(pour_pos.x, pour_pos.y, 0))
        local point = pour_pos + (origin - pour_pos):Normalized() * 6.5
        -- local ppd = Entities:FindByName(nil, 'pour_point_debug')
        -- ppd:SetOrigin(point)

        if pour_pt == nil then
            pour_pt = ParticleManager:CreateParticle("particles/nature/bucket_pour.vpcf", 4, thisEntity)
        end
        ParticleManager:SetParticleControl(pour_pt, 0, point)
        -- clamp probably isn't necessary
        local pour_value = Clamp(
            RemapVal(thisEntity:GetUpVector().z, top_tip_value, -1, top_pour_value, bottom_pour_value),
            top_pour_value,
            bottom_pour_value)
        -- print("pour_value:",pour_value)
        SetWaterLevel(water_level - pour_value)
        if not this.is_pouring then
            this.is_pouring = true
            thisEntity:EmitSound("Bivouac.WaterPourLp")
        end
        this.pour_position = point
        this.pour_speed = pour_value
    else
        if this.is_pouring then
            thisEntity:StopSound("Bivouac.WaterPourLp")
            this.is_pouring = false
            disposeParticle()
        end
    end
    if not fill_from_pond and water_level <= 0 then
        thisEntity:StopSound("Bivouac.WaterPourLp")
        water_level = 0
        disposeParticle()
        thisEntity:SaveBoolean("IsThinking", false)
        return nil
    end
    return 0
end

function DisablePour()
    print("disable")
    if thisEntity:LoadBoolean("IsThinking", false) then
        print("Bucket pouring is disabled")
        thisEntity:StopThink("PourThink")
        thisEntity:SaveBoolean("IsThinking", false)
    end
end
-- thisEntity:GetPrivateScriptScope().DisablePour = DisablePour
function EnablePour()
    if not thisEntity:LoadBoolean("IsThinking", false) then
        print("Bucket pouring is enabled")
        thisEntity:SetThink(PourThink, "PourThink", 0)
        thisEntity:SaveBoolean("IsThinking", true)
    end
end
-- thisEntity:GetPrivateScriptScope().EnablePour = EnablePour

---@param context CScriptPrecacheContext
function Precache(context)
    PrecacheResource("particle", "particles/nature/bucket_pour.vpcf", context)
end

thisEntity:SaveBoolean("IsBucket", true)

local function ready(saveLoaded)
    water_ent = Entities:FindByName(nil,thisEntity:GetName().."_water")
    thisEntity:SaveBoolean("IsThinking", false)
                                                            -- change to 0 when water source added
    water_level = thisEntity:LoadNumber("water_level", 0)
    SetWaterLevel(water_level)
    -- Consider dynamic think setting by player distance
    -- EnablePour()
end

-- Fix for script executing twice on restore.
-- This binds to the new local ready function on second execution.
if thisEntity:GetPrivateScriptScope().savewasloaded then
    thisEntity:SetContextThink("init", function() ready(true) end, 0)
end

---@param activateType "0"|"1"|"2"
function Activate(activateType)
    -- If game is being restored then set the script scope ready for next execution.
    if activateType == 2 then
        thisEntity:GetPrivateScriptScope().savewasloaded = true
        return
    end
    -- Otherwise just run the ready function after "instant" delay (player will be ready).
    thisEntity:SetContextThink("init", function() ready(false) end, 0)
end

-- Add local functions to private script scope to avoid environment pollution.
local _a,_b=1,thisEntity:GetPrivateScriptScope()while true do local _c,_d=debug.getlocal(1,_a)if _c==nil then break end;if type(_d)=='function'then _b[_c]=_d end;_a=1+_a end

-- DEBUG
-- local debugspeed = 0.0025
-- local debuglevel = 0
-- local debugraise = true
-- local function debugThink()
--     if debugraise then
--         debuglevel = debuglevel + debugspeed
--         if debuglevel >= 1 then debugraise = false end
--     else
--         debuglevel = debuglevel - debugspeed
--         if debuglevel <= 0 then debugraise = true end
--     end
--     -- print(debuglevel)
--     SetWaterLevel(debuglevel)
--     return 0
-- end
-- thisEntity:SetThink(debugThink, "debugthink", 0)
