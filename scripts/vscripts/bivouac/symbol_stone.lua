
require 'bivouac.init'

local wind_val = 0
local wind_velocity = 0.00075
local wind_max = 0.5
local wind_up = true

local function PickupThink()
    if wind_up then
        wind_val = wind_val + wind_velocity
        if wind_val >= wind_max then
            wind_val = wind_max
            wind_up = false
        end
    else
        wind_val = wind_val - wind_velocity
        if wind_val <= 0 then
            wind_val = 0
            SetWindValue(wind_val)
            DoEntFire("@pp_blackandwhite_stone", "Disable", "", 0, nil, nil)
            return nil
        end
    end
    SetWindValue(wind_val)
    return 0
end

local function FirstPickup(io)
    if thisEntity:LoadBoolean("FirstPickup", true) then
        local stones_found = Player:LoadNumber("StonesFound", 0) + 1
        Player:SaveNumber("StonesFound", stones_found)
        wind_max = stones_found / 6
        thisEntity:SaveBoolean("FirstPickup", false)
        thisEntity:SetThink(PickupThink, "PickupThink", 1)
        DoEntFire("@pp_blackandwhite_stone", "Enable", "", 0, nil, nil)
    end
end
util.SanitizeFunctionForHammer(FirstPickup)

thisEntity:SaveBoolean("IsSymbolStone", true)
