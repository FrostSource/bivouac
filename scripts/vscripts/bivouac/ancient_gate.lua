
require"util.player"

local UPDATE_INTERVAL = 0

local is_exit = thisEntity:GetName() == "portal_exit" and true or false
local player_must_cross_boundary_first = false

---Get if a position is across the portal boundary.
---@param pos Vector
---@return boolean
local function IsAcrossBoundary(pos)
    return (is_exit and pos.x < 0) or (not is_exit and pos.x > 0)
end

local function Thinker()
    -- needs to be refined to avoid slow peeks
    local loc = thisEntity:TransformPointWorldToEntity(Player:EyePosition())
    if IsAcrossBoundary(loc) and not player_must_cross_boundary_first then
        -- DoEntFire(thisEntity:GetName().."_tp", "Enable", "", 0, nil, nil)
        thisEntity:FireOutput("OnUser1", thisEntity, thisEntity, nil, 0)
        Player:EmitSound("ScriptedSeq.InnerVaultBubbleExpand")
        return nil
    elseif player_must_cross_boundary_first then
        player_must_cross_boundary_first = false
    end

    if (is_exit and loc.x >= 0) or (not is_exit and loc.x <= 0) then
        SetPortalScreenFogValue((64 - math.abs(loc.x)) / 64)
    else
        SetPortalScreenFogValue(0)
    end

    return UPDATE_INTERVAL
end

local function EnableThink()
    player_must_cross_boundary_first = true
    thisEntity:SetThink(Thinker, "Thinker", 0)
end
thisEntity:GetPrivateScriptScope().EnableThink = EnableThink
local function DisableThink()
    thisEntity:StopThink("Thinker")
end
thisEntity:GetPrivateScriptScope().DisableThink = DisableThink

