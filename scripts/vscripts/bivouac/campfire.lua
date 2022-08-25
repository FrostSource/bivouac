
require 'bivouac.init'

---@type EntityHandle
local fire_pt = nil
local fire_level = 1
---@type EntityHandle
local fire_scalar = 2

local fire_putout_multiplier = 0.6

local last_steam_sound = 0
local steam_sound_time = 0.3

local function BucketOverFireThink()
    -- print(1)
    if fire_pt then
        -- print(2)
        local o = thisEntity:GetOrigin()
        if
        Bucket.is_pouring and
        VectorDistance(Vector(Bucket.pour_position.x,Bucket.pour_position.y,0),Vector(o.x,o.y,0)) < 20
        -- VectorDistance(Vector(Bucket:GetOrigin().x,Bucket:GetOrigin().y,0),Vector(o.x,o.y,0)) < 20
        then
            fire_level = fire_level - Bucket.pour_speed * fire_putout_multiplier
            if Time() - last_steam_sound >= steam_sound_time then
                last_steam_sound = Time()
                StartSoundEventFromPosition("Bivouac.FireSteam", fire_pt:GetOrigin())
            end
            -- print(fire_level)
            fire_scalar:SetOrigin(Vector(fire_level))
            thisEntity:SaveNumber("FireLevel", fire_level)
            if fire_level <= 0 then
                fire_level = 0
                DoEntFireByInstanceHandle(fire_pt, "Stop", "", 0, thisEntity, thisEntity)
                DoEntFireByInstanceHandle(
                    thisEntity:FindInPrefab("campfire_snd")--[[@as EntityHandle]],
                    "StopSound", "", 0, thisEntity, thisEntity
                )
                thisEntity:FireOutput("OnUser1", thisEntity, thisEntity, nil, 0)
                return nil
            end
        end
    end
    return 0
end

local function BucketClose()
    thisEntity:SetThink(BucketOverFireThink, "BucketOverFireThink", 0)
end
util.SanitizeFunctionForHammer(BucketClose)
local function BucketFar()
    thisEntity:StopThink("BucketOverFireThink")
end
util.SanitizeFunctionForHammer(BucketFar)

local function DebugLowerFire()
    if fire_pt then
        fire_level = fire_level - 0.1
        fire_scalar:SetOrigin(Vector(fire_level))
        if fire_level <= 0 then
            fire_level = 0
            DoEntFireByInstanceHandle(fire_pt, "Stop", "", 0, thisEntity, thisEntity)
        end
        thisEntity:SaveNumber("FireLevel", fire_level)
        -- ParticleManager:SetParticleControl(fire_pt, 1, Vector(fire_level))
    end
end
Convars:RegisterCommand("debug_campfire_lower", DebugLowerFire, "", 0)


local function ready(saveLoaded)
    print('campfire create')
    fire_level = thisEntity:LoadNumber("FireLevel", 1)
    fire_pt = thisEntity:FindInPrefab("campfire_particle")--[[@as EntityHandle]]
    print(fire_scalar)
    fire_scalar = thisEntity:FindInPrefab("campfire_scalar")--[[@as EntityHandle]]
    print(fire_scalar)
    fire_scalar:SetOrigin(Vector(fire_level))
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


---@param context CScriptPrecacheContext
function Precache(context)
    PrecacheResource("particle", "particles/nature/campfire.vpcf", context)
    PrecacheResource("sound", "Bivouac.FireSteam", context)
end
