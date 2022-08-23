
local top_z = thisEntity:GetBoundingMaxs().z
-- space around eye pos that counts as being underwater
local eye_margin = 1
local is_underwater = false

local function Thinker()
    if Player:EyePosition().z < (top_z + eye_margin) then
        if not is_underwater then
            is_underwater = true
            -- Head dipped below water
            thisEntity:FireOutput("OnUser1", thisEntity, thisEntity, nil, 0)
        end
    else
        if is_underwater then
            is_underwater = false
            -- Head rose above water
            thisEntity:FireOutput("OnUser2", thisEntity, thisEntity, nil, 0)
        end
    end
    return 0.2
end

local function OnStartTouch(io)
    thisEntity:SetThink(Thinker, "Thinker", 0)
end
thisEntity:GetPrivateScriptScope().OnStartTouch = OnStartTouch
local function OnEndTouch(io)
    thisEntity:StopThink("Thinker")
end
thisEntity:GetPrivateScriptScope().OnEndTouch = OnEndTouch

-- To make sure underwater stuff is turned off on game load
thisEntity:FireOutput("OnUser2", thisEntity, thisEntity, nil, 0)
