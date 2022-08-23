
---0, initial, play sound
---1 = enter
---2 = main
---3 = exit
local state = 0
local fade_speed = 4
local grow_speed = 0.03
local z_offset = Vector(0,0,4)

local function FadeOut()
    local alpha = thisEntity:GetRenderAlpha() - fade_speed
    thisEntity:SetRenderAlpha(alpha)
    return alpha <= 0 and true or false
end

local function Grow()
    local scale = thisEntity:GetAbsScale() + grow_speed
    thisEntity:SetAbsScale(scale)
    return scale >= 1 and true or false
end

local function Think()
---@diagnostic disable-next-line: undefined-field
    if thisEntity.attach == 1 then
        thisEntity:SetOrigin(Player.PrimaryHand:GetCenter() + z_offset)
---@diagnostic disable-next-line: undefined-field
    elseif thisEntity.attach == 2 then
        thisEntity:SetOrigin(Player.SecondaryHand:GetCenter() + z_offset)
    end

    thisEntity:SetForwardVector((Player:EyePosition() - thisEntity:GetOrigin()):Normalized())
    if state == 0 then
        thisEntity:EmitSound("Instructor.StartLesson")
        state = 1
    elseif state == 1 then
        if Grow() then
            print("finished growing")
            state = 2
        end
    elseif state == 3 then
        if FadeOut() then
            print("finished fading out")
            thisEntity:Kill()
            return nil
        end
    end
    return 0
end

local function ShowHint()
    state = 0
    thisEntity:SetAbsScale(0)
    thisEntity:SetRenderAlpha(255)
    thisEntity:SetThink(Think, "Think", 0)
end
thisEntity:GetPrivateScriptScope().ShowHint = ShowHint

local function HideHint()
    print("Hiding hint in hint itself")
    state = 3
end
thisEntity:GetPrivateScriptScope().HideHint = HideHint

---@param context CScriptPrecacheContext
function Precache(context)
    -- PrecacheModel(thisEntity:GetModelName(), context)
    print("start precache")
    PrecacheEntityFromTable("prop_dynamic", {
        model = "models/bivouac/hint_panel.vmdl",
        skin = "default",
        targetname = "hint_panel"
    }, context)
    print("end precache")
end
