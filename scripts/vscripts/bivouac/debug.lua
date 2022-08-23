
local function Teleport(name)
    DoEntFire(name, "Teleport", "", 0, Player, Player)
end
function CBaseEntity:DebugFind()
    debugoverlay:Sphere(self:GetOrigin(), 32, 255, 255, 0, 255, true, 5)
end

local function DebugPortalEntrance()
    local target = Entities:FindByName(nil, "@debug_portal_entrance")
    if target then
        -- Player:SetOrigin(target:GetOrigin())
        Teleport("@debug_portal_entrance")
        -- SetOpvarFloatAll("hlvr_global_opvars","opvars","skylight_proximity_beacon",0)
        -- DoEntFire("debug_disable_skylight", "SetDisabledValue", "", 0, Player, Player)
        DoEntFire("debug_disable_skylight", "Enable", "", 0, nil, nil)
    else
        Warning("Couldn't teleport player to portal entrace because @debug_portal_entrance wasn't found!")
    end
end
Convars:RegisterCommand("bivouac_debug_portal_entrance", DebugPortalEntrance, "", 0)

local function DebugPortalEnable()
    DoEntFire("relay_portal_open", "Trigger", "", 0, nil, nil)
end
Convars:RegisterCommand("bivouac_debug_portal_enable", DebugPortalEnable, "", 0)

local function DebugPortalAnimate()
    DoEntFire("relay_portal_open_pre", "Trigger", "", 0, nil, nil)
end
Convars:RegisterCommand("bivouac_debug_portal_animate", DebugPortalAnimate, "", 0)

local function DebugFillBucket()
    if Bucket then
        Bucket:GetPrivateScriptScope().SetWaterLevel(1)
    else
        Warning("Couldn't fill bucket because Bucket entity not found!")
    end
end
Convars:RegisterCommand("bivouac_debug_fill_bucket", DebugFillBucket, "", 0)

local function DebugChargeFlashlight()
    if Flashlight then
        -- Flashlight:SaveNumber("BatteriesInserted", 2)
        Flashlight:SaveBoolean("IsCharged", true)
    else
        Warning("Could not charge flashlight because Flashlight entity not found!")
    end
end
Convars:RegisterCommand("bivouac_debug_charge_flashlight", DebugChargeFlashlight, "", 0)

local function DebugTeleportStonesToPortal()
    local target = Entities:FindByName(nil, "@debug_stone_tp")
    if not target then
        Warning("Could not teleport stones because @debug_stone_tp was not found!")
        return
    end
    for _,ent in ipairs(Entities:FindAllByName("symbol_stone*")) do
        if ent:LoadBoolean("IsSymbolStone", false) then
            ent:SetOrigin(target:GetOrigin())
        end
    end
end
Convars:RegisterCommand("bivouac_debug_teleport_stones_to_portal", DebugTeleportStonesToPortal, "", 0)

local function DebugTeleportRopeToCave()
    local rope = Entities:FindByName(nil, "rope_bundle")
    local target = Entities:FindByName(nil, "@debug_rope_tp")
    if rope and target then
        rope:SetOrigin(target:GetOrigin())
    else
        Warning("Could not teleport rope to cave because either rope or target could not be found!")
    end
end
Convars:RegisterCommand("bivouac_debug_teleport_rope_to_cave", DebugTeleportRopeToCave, "", 0)

local function DebugAttachFlashlightToPlayer()
    if Flashlight then
        -- DebugChargeFlashlight()
        Flashlight:SaveBoolean("IsCharged", true)
        Flashlight:SetParent(Player, "")
        Flashlight:SetLocalOrigin(Vector(0,0,64))
        Flashlight:SetLocalAngles(0,0,0)
        if not Flashlight:LoadBoolean("IsOn", false) then
            Flashlight:GetPrivateScriptScope().ToggleState()
        end
        Flashlight:SetRenderAlpha(0)
    end
end
Convars:RegisterCommand("bivouac_debug_attach_flashlight_to_player", DebugAttachFlashlightToPlayer, "", 0)

local function DebugToggleFlashlight()
    if Flashlight then
        Flashlight:GetPrivateScriptScope().ToggleState()
    end
end
Convars:RegisterCommand("bivouac_debug_toggle_flashlight", DebugToggleFlashlight, "", 0)

local function DebugEnding()
    Teleport("@debug_ending")
    DoEntFire("relay_portal_1_enter", "Trigger", "", 0, nil, nil)
end
Convars:RegisterCommand("bivouac_debug_ending", DebugEnding, "", 0)

local function DebugMainCaveEntrance()
    Teleport("@debug_main_cave_entrance")
end
Convars:RegisterCommand("bivouac_debug_main_cave_entrance", DebugMainCaveEntrance, "", 0)

local function DebugMonster()
    Teleport("@debug_monster")
end
Convars:RegisterCommand("bivouac_debug_monster", DebugMonster, "", 0)

-- if Flashlight then Flashlight:SaveBoolean('IsCharged', true) Flashlight:SetParent(Player, '') Flashlight:SetLocalOrigin(Vector(0,0,64)) Flashlight:SetLocalAngles(0,0,0) if not Flashlight:LoadBoolean('IsOn', false) then Flashlight:GetPrivateScriptScope().ToggleState() end end