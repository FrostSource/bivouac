--[[
    Couldn't figure out how to make model walk in a direction so scripted instead.
    Also setting the scripted velocity in hammer causes a crash.
]]
require 'bivouac.init'
local speed = 0
local trace_down = true
local kill_dist = 116
local has_killed = false
local footstep_time = 0.23--0.26
local footstep_timer = 0

local function Think()
    if speed > 0 then
        local point_at = (thisEntity:GetOrigin() - Player:GetOrigin()):Normalized()
        local forward = Vector(point_at.x, point_at.y, 0)
        forward = RotatePosition(Vector(), QAngle(0,90,0), forward)
        thisEntity:SetForwardVector(forward)
        local new_pos = thisEntity:GetAbsOrigin() + -thisEntity:GetRightVector() * speed
        if trace_down then
            ---@type TraceTableLine
            local traceTable = {
                startpos = new_pos + Vector(0,0,16),
                endpos = new_pos + Vector(0,0,-512),
            }
            TraceLine(traceTable)
            if traceTable.hit then
                new_pos.z = traceTable.pos.z
            end
        end
        thisEntity:SetAbsOrigin(new_pos)
        if Time() - footstep_timer > footstep_time then
            footstep_timer = Time()
            -- thisEntity:EmitSound("NPC_Antlion.Step_Rear_Manual_Default")
            StartSoundEventFromPosition("Bivouac.Footstep", thisEntity:GetOrigin())
            -- thisEntity:EmitSoundParams("NPC_Antlion.Step_Rear_Manual_Default", 1, 5, 0)
        end
    end
    if VectorDistance(thisEntity:GetOrigin(), Player:GetOrigin()) < kill_dist then
        if not has_killed then
            thisEntity:FireOutput("OnUser1", nil, nil, nil, 0)
            has_killed = true
        end
    elseif has_killed then
        has_killed = false
    end
    return 0
end

local function Walk()
    DoEntFireByInstanceHandle(thisEntity, "SetAnimation", "walk", 0, nil, nil)
    speed = 0.8
end
util.SanitizeFunctionForHammer(Walk)

local function Run()
    DoEntFireByInstanceHandle(thisEntity, "SetAnimation", "run", 0, nil, nil)
    speed = 2.5 * 2
end
util.SanitizeFunctionForHammer(Run)

local function Idle()
    DoEntFireByInstanceHandle(thisEntity, "SetAnimation", "idle", 0, nil, nil)
    speed = 0
end
util.SanitizeFunctionForHammer(Idle)

local function MoveToBoundary()
    local player_origin = Player:GetOrigin()
    local targets = Entities:FindAllByNameWithin("monster_boundary_target", player_origin, 1024)
    local target = nil
    local max_dist = 0
    for _,ent in ipairs(targets) do
        local dist = VectorDistance(player_origin, ent:GetOrigin())
        if dist > max_dist then
            max_dist = dist
            target = ent
        end
    end
    if target then
        thisEntity:SetOrigin(target:GetOrigin())
    else
        print("Could not move monster to boundary, no target found!")
    end
end
util.SanitizeFunctionForHammer(MoveToBoundary)

Idle()
thisEntity:SetThink(Think, "Think", 0)