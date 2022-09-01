
require 'bivouac.init'
require 'util.input'

local SOUND_BUTTON = "ScriptedSeq.Russel_Button_Map"
local SOUND_INSERT = "Bivouac.BatteryInsert"

---@type EntityHandle
local light
---@type EntityHandle
local lid
---@type EntityHandle
local battery_trigger
---@type EntityHandle
local beam_pt


local function ToggleState()
    if not thisEntity:LoadBoolean("IsCharged", false) then return end
    if thisEntity:LoadBoolean("IsOn", false) then
        -- turn off
        print("Flashlight turned off")
        DoEntFireByInstanceHandle(light, "TurnOff", "", 0, nil, nil)
        DoEntFireByInstanceHandle(thisEntity, "Skin", "0", 0, nil, nil)
        DoEntFireByInstanceHandle(beam_pt, "Stop", "", 0, nil, nil)
        thisEntity:SaveBoolean("IsOn", false)
    else
        -- turn on
        print("Flashlight turned on")
        DoEntFireByInstanceHandle(light, "TurnOn", "", 0, nil, nil)
        DoEntFireByInstanceHandle(thisEntity, "Skin", "1", 0, nil, nil)
        DoEntFireByInstanceHandle(beam_pt, "Start", "", 0, nil, nil)
        thisEntity:SaveBoolean("IsOn", true)
    end
end
util.SanitizeFunctionForHammer(ToggleState)

---Called from hammer IO
---@param io TypeIOInvoke
local function BatteryInserted(io)
    -- Don't insert if player isn't holding battery
    if not Player.LeftHand.ItemHeld == io.activator and not Player.RightHand.ItemHeld == io.activator then
        return
    end
    print("Player inserted battery into flashlight")
    if thisEntity:LoadNumber("BatteriesInserted", 0) == 1 then
        print("\tSecond battery")
        -- charged
        -- Delete battery inside
        for _, child in ipairs(thisEntity:GetChildren()) do
            if child:GetName() == "battery_in_flashlight" then
                child:Kill()
            end
        end
        -- Close the lid
        lid:SetLocalAngles(0,0,0)
        battery_trigger:Disable()
        thisEntity:SaveNumber("BatteriesInserted", 2)
        thisEntity:SaveBoolean("IsCharged", true)
        CreateHint("hint_flashlight_button", 3, thisEntity)
    else
        print("\tFirst battery")
        -- add battery
        local battery = SpawnEntityFromTableSynchronous("prop_dynamic_override", {
            targetname = "battery_in_flashlight",
            model = io.activator:GetModelName(),
            solid = "0",
            disablereceiveshadows = "1",
            disableshadows = "1",
        })
        battery:SetParent(thisEntity, "battery")
        battery:SetLocalAngles(0,0,0)
        battery:SetLocalOrigin(Vector())
        thisEntity:SaveNumber("BatteriesInserted", 1)
    end
    thisEntity:EmitSound(SOUND_INSERT)
    io.activator:Kill()
end
util.SanitizeFunctionForHammer(BatteryInserted)


local function EndHint()
    if not thisEntity:LoadBoolean("done_button_hint", false) then
        HideLastHint()
        thisEntity:SaveBoolean("done_button_hint", true)
    end
end

---Callback for grenade button press
---@param data INPUT_CALLBACK
local function ButtonPress(data)
    if data.hand.ItemHeld == thisEntity then
        thisEntity:EmitSound(SOUND_BUTTON)
        print("Player pressed flashlight button, checking if charged")
        if thisEntity:LoadBoolean("IsCharged", false) then
            print("\tFlashlight charged")
            EndHint()
            ToggleState()
        end
    end
end


thisEntity:SaveBoolean("IsFlashlight", true)

local function ready(saveLoaded)
    for _, child in ipairs(thisEntity:GetChildren()) do
        if child:GetClassname() == "trigger_multiple" then
            battery_trigger = child
        elseif child:GetClassname() == "light_spot" then
            light = child
        elseif child:GetModelName() == "models/bivouac/flashlight_lid.vmdl" then
            lid = child
        elseif child:GetClassname() == "info_particle_system" then
            beam_pt = child
        end
    end
    Input:TrackButton(16)
    Input:RegisterCallback("press", 0, 16, ButtonPress)
    Input:RegisterCallback("press", 1, 16, ButtonPress)
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
    PrecacheResource("sound", SOUND_BUTTON, context)
    PrecacheResource("sound", SOUND_INSERT, context)
end
