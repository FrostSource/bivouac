
require 'bivouac.init'

local north = 0
local local_angle = 0
local acceleration = 1
local speed = 0

local magnetic_disruption = false
local magnetic_disruption_angle = 0

local function MagneticDisruptionThink()
    magnetic_disruption_angle = RandomInt(0, 359)
    return RandomFloat(0, 0.5)
end

local function EnableMagneticDisruption()
    magnetic_disruption = true
    thisEntity:SetThink(MagneticDisruptionThink, "MagneticDisruptionThink", 0)
end
util.SanitizeFunctionForHammer(EnableMagneticDisruption)
local function DisableMagneticDisruption()
    magnetic_disruption = false
    thisEntity:StopThink("MagneticDisruptionThink")
end
util.SanitizeFunctionForHammer(DisableMagneticDisruption)

local function Think()
    -- local base = Entities:FindByName(nil, "compass_base")
    local base = thisEntity:GetMoveParent()
    local base_degrees = math.atan2(base:GetForwardVector().y, base:GetForwardVector().x) * 180 / math.pi
    local point_to = north
    if magnetic_disruption then point_to = magnetic_disruption_angle end
    local base_diff = AngleDiff(base_degrees, point_to)
    local current_diff = AngleDiff(base_diff, local_angle)
    local_angle = local_angle + current_diff / 30
    -- if local_angle < base_diff then
    --     speed = speed + acceleration / (abs(base_diff) / 1)
    -- else
    --     speed = speed - acceleration / (abs(base_diff) / 1)
    -- end
    -- local_angle = local_angle + speed
    thisEntity:SetLocalAngles(0,-local_angle,0)

    return 0
end
thisEntity:SetThink(Think, "Think", 0.1)

local function DebugCompassBaseAngle()
    local base = Entities:FindByName(nil, "compass_base")
    local angle = RandomInt(0,359)
    base:SetForwardVector(Vector(RandomFloat(-1,1),RandomFloat(-1,1),RandomFloat(-1,1)))
    -- base:SetAngles(0,angle,0)
end
Convars:RegisterCommand("debug_compass_base_angle", DebugCompassBaseAngle, "", 0)

local function DebugCompassBaseAngle10()
    local base = Entities:FindByName(nil, "compass_base")
    local a = base:GetAngles().y + 10
    if a >= 360 then a = a - 360 end
    base:SetAngles(0,a,0)
end
Convars:RegisterCommand("debug_compass_base_angle_10", DebugCompassBaseAngle10, "", 0)
SendToServerConsole("bind h debug_compass_base_angle_10")



--debug
-- EnableMagneticDisruption()
