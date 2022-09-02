
require'bivouac.init'
require'util.player'
require 'util.input'

local COLUMNS = 2
local ROWS = 3
local SLOT_SIZE = 3
local PADDING = 1
---Distance from the back of the backpack
local DEPTH_OFFSET = 4.5
---Extra units to add downwards
local HEIGHT_OFFSET = 1
---Distance item/hand can be from a slot to interact
---Consider using item max size instead
local SLOT_INTERACT_DIST = 5
local SLOT_TARGETNAME = "backpack_item_slot"
---Absolute size of the object in the backpack icon
local ICON_PREVIEW_SIZE = 2.5

local SOUND_TAKE_ITEM = "Inventory.Open"
local SOUND_STORE_ITEM = "Inventory.Close"
local SOUND_TAKE_BACKPACK = "Inventory.BackpackGrab"
local SOUND_STORE_BACKPACK = "Inventory.BackpackAcquire"

-- x = -(( ((SLOT_SIZE + PADDING) * (COLUMNS - 1) ) - PADDING) / 2)
-- y = -(( ((SLOT_SIZE + PADDING) * (ROWS - 1) ) - PADDING) / 2)
local function CreateSlot(x, y)
    print("Spawning backpack slot")
    local slot = SpawnEntityFromTableSynchronous("prop_dynamic", {
        model = "models/bivouac/backpack_slot.vmdl",
        bodygroups = "{shape = 1}",
        targetname = SLOT_TARGETNAME,
        solid = "0",
        disableshadows = "1",
    })
    local local_position = Vector(-DEPTH_OFFSET, x, y - HEIGHT_OFFSET)
    local world_position = thisEntity:TransformPointEntityToWorld(local_position)
    slot:SetOrigin(world_position)
    slot:SetAngle(thisEntity:GetAngles())
    slot:SetParent(thisEntity, "")
    return slot
end





local function SlotHasItem(slot, has)
    if has == nil then
        return slot:LoadBoolean("HasStoredEntity", false)
    else
        slot:SaveBoolean("HasStoredEntity", has)
        return has
    end
end

---Quick fix for right hand overriding left hand highlights
---@type table<integer,EntityHandle>
local hand_slot = {
    [0] = nil,
    [1] = nil,
}

---Puts an item at the storage location by dropping and waiting a frame
---@param ent EntityHandle
local function PutItemInStorage(ent)
    ent:Drop()
    util.Delay(function()
    local storage_ent = Entities:FindByName(nil, "@backpack_storage")
    -- print("Storage pos", storage_ent:GetOrigin())
    ent:SetOrigin(storage_ent:GetOrigin())
    if ent ~= thisEntity then
        ent:SetRenderAlpha(0)
    end
    -- print(ent:GetOrigin())
    end, 0.01)
end

---Get the nearest slot to an entity and optionally set others to default.
---@param entity EntityHandle
---@param animate? boolean
---@param clear? boolean
---@return EntityHandle?
local function GetNearestSlot(entity, animate, clear)
    local slot = nil
    local ent_pos = entity:GetOrigin()
    local smallest_dist = 1024
    local max_slot_dist = max(entity:GetMaxSize() / 2, SLOT_INTERACT_DIST)
    for _, ent in ipairs(Entities:FindAllByName(SLOT_TARGETNAME)) do
        local dist = #(ent_pos - ent:GetOrigin())
        -- was SLOT_INTERACT_DIST
        if dist <= max_slot_dist and dist < smallest_dist then
            smallest_dist = dist
            slot = ent
        end
    end
    if clear then
        for _, ent in ipairs(Entities:FindAllByName(SLOT_TARGETNAME)) do
            if ent ~= slot and ent ~= hand_slot[0] and ent ~= hand_slot[1] then
                ent:SetAbsScale(1)
                ent:SetRenderColor(255,255,255)
            end
        end
    end
    if animate and slot then
        slot:SetAbsScale(1.2)
        slot:SetRenderColor(255,255,0)
    end
    return slot
end

---Gets the first free slot
---@return EntityHandle
local function GetFirstFreeSlot()
    -- for _, ent in ipairs(Entities:FindAllByName(SLOT_TARGETNAME)) do
    for _, ent in ipairs(thisEntity:GetChildren()) do
        if ent:GetName() == SLOT_TARGETNAME and not ent:LoadBoolean("HasStoredEntity", false)-- #ent:GetChildren() == 0 then
        then
            return ent
        end
    end
    return nil
end

local haptic_flags = {}
local hand_enter_icon_flag = false

---Get if a given hand is behind the player head.
---@param hand CPropVRHand
---@return boolean
local function HandIsBehindHead(hand, val)
    return Player.HMDAvatar:GetForwardVector():Dot((hand:GetOrigin() - Player.HMDAvatar:GetOrigin()):Normalized()) < -(val or 0.5)
end

local function BackpackThink()
    if thisEntity:LoadBoolean("BackpackStored") then
        for _, hand in ipairs(Player.Hands) do
            -- If hand is behind head
            if not hand.ItemHeld and HandIsBehindHead(hand) then
                if not haptic_flags[hand] then
                    -- print(hand:HandName(), "went behind head for grabbing backpack")
                    -- hand:FireHapticPulse(2)
                    hand:FireHapticPulsePrecise(500000)
                    haptic_flags[hand] = true
                end
                if hand:IsButtonPressed(3) then
                    thisEntity:GetPrivateScriptScope().TakeFromBack(hand)
                end
            -- Hand is in front of head
            elseif haptic_flags[hand] then
                haptic_flags[hand] = nil
            end
        end
    -- Backpack is not stored, check placing and taking items
    else
        -- Consider merging fors
        for _, hand in ipairs(Player.Hands) do
            hand_slot[hand:GetHandID()] = nil
            -- Holding item, placing in backpack
            if hand.ItemHeld then
                if hand.ItemHeld ~= thisEntity then
                    -- local slot = Entities:FindByNameNearest(SLOT_TARGETNAME, hand.ItemHeld:GetOrigin(), SLOT_PLACE_DIST)
                    local slot = GetNearestSlot(hand.ItemHeld, true, true)
                    hand_slot[hand:GetHandID()] = slot
                    --if slot then
                        -- Actual storing is done in released callback
                        -- slot:SetRenderColor(255, 255, 0)
                    --end
                end
            -- Not holding item, check for retrieving
            else
                local slot = GetNearestSlot(hand:GetGlove(), true, true)
                hand_slot[hand:GetHandID()] = slot
                if slot and SlotHasItem(slot) then
                    if not hand_enter_icon_flag then
                        thisEntity:DisablePickup()
                        hand_enter_icon_flag = true
                    end
                    -- if hand:IsButtonPressed(3) then
                    if Input:Pressed(hand:GetHandID(), 3, true) then
                        thisEntity:GetPrivateScriptScope().TakeItemFromBackpack(slot, hand)
                    end
                elseif hand_enter_icon_flag then
                    thisEntity:EnablePickup()
                    hand_enter_icon_flag = false
                end
            end
        end
    end
    return 0
end

local function PrintItems()
    for _, ent in ipairs(Entities:FindAllByName(SLOT_TARGETNAME)) do
        print(ent:LoadString("debug_slot_index"), "has item", SlotHasItem(ent), "item", ent:LoadEntity("StoredEntity"))
    end
end
thisEntity:GetPrivateScriptScope().PrintItems = PrintItems


---Take backpack out and make player grab it.
---@param hand CPropVRHand
local function TakeFromBack(hand)
    print("Taking backpack from back")
    -- local attachment = hand:GetHandID() == 0 and "left_hand_grab" or "right_hand_grab"
    -- thisEntity:GetAttachmentOrigin(thisEntity:ScriptLookupAttachment(attachment))
    -- thisEntity:TransformPointWorldToEntity()
    -- thisEntity:SetAngles(0,0,0)
    thisEntity:SetAngle(Player:GetAngles())
    thisEntity:SetOrigin((Player.HMDAvatar:GetOrigin() + Player.HMDAvatar:GetForwardVector() * -32) + Vector(0,0,-8))
    thisEntity:Grab(hand)
    thisEntity:SaveBoolean("BackpackStored", false)
    EmitSoundOn(SOUND_TAKE_BACKPACK, thisEntity)
end
thisEntity:GetPrivateScriptScope().TakeFromBack = TakeFromBack

---Put backpack away.
---@param silent boolean?
local function PutOnBack(silent)
    print("Putting backpack on back")
    thisEntity:Drop()
    PutItemInStorage(thisEntity)
    thisEntity:SaveBoolean("BackpackStored", true)
    if not silent then EmitSoundOn(SOUND_STORE_BACKPACK, Player) end
end
thisEntity:GetPrivateScriptScope().PutOnBack = PutOnBack

---Put an item in a backpack slot.
---@param item EntityHandle # The entity to store
---@param slot EntityHandle? # The slot to put it in, or nil for first free one
---@param silent boolean? # If a sound should be played or not
local function PutItemInBackpack(item, slot, silent)
    -- Random free slot
    if slot == nil then
        slot = GetFirstFreeSlot()
    end
    if not slot then
        Warning("Trying to place item in occupied backpack slot!")
        return
    end
    print("Putting item in backpack", item:GetName(), slot:LoadString("debug_slot_index"))
    PutItemInStorage(item)
    local icon = SpawnEntityFromTableSynchronous("prop_dynamic_override",{
        model = item:GetModelName(),
        solid = "0",
        disableshadows = "1",
    })
    -- Attachments must be modified by scale to get original value.
    -- If model uses scale modifier then retrieving the original value is not possible.
    local angle = item:TransformPointWorldToEntity(item:GetAttachmentOrigin(item:ScriptLookupAttachment("backpack_angle")))
    -- print("pre scale angle", angle)
    angle = angle / item:GetAbsScale()
    local offset = item:TransformPointWorldToEntity(item:GetAttachmentOrigin(item:ScriptLookupAttachment("backpack_offset")))
    -- print("pre scale offset", offset)
    offset = offset / item:GetAbsScale()
    -- print("Putting "..item:GetModelName().." in backpack"
    --     .." at angle ["..angle.x..","..angle.y..","..angle.z.."]"
    --     ..", offset ["..offset.x..","..offset.y..","..offset.z.."]"
    --     ..", at scale "..item:GetAbsScale()
    --     .."\n"
    -- )
    icon:SetParent(slot, "")
    icon:SetLocalOrigin(offset)
    icon:SetLocalAngles(angle.x,angle.y,angle.z)
    -- size I want it to be divided by current size
    icon:SetAbsScale(ICON_PREVIEW_SIZE / icon:GetMaxSize())
    icon:SetMaterialGroupHash(item:GetMaterialGroupHash())
    slot:SaveBoolean("HasStoredEntity", true)
    slot:SaveEntity("StoredEntity", item)
    if not silent then EmitSoundOn(SOUND_STORE_ITEM, slot) end
end
thisEntity:GetPrivateScriptScope().PutItemInBackpack = PutItemInBackpack
---Take an item from a slot.
---@param slot EntityHandle
---@param hand CPropVRHand|0|1
local function TakeItemFromBackpack(slot, hand)
    print("Taking item from backpack", slot:LoadString("debug_slot_index"), hand:HandName())
    local icon = slot:GetChildren()[1]
    local has = slot:LoadBoolean("HasStoredEntity", false)
    local item = slot:LoadEntity("StoredEntity")
    if icon and has and item then
        item:SetRenderAlpha(255)
        item:SetOrigin(slot:GetOrigin())
        item:SetAngle(icon:GetAngles())
        item:Grab(hand)
        -- DoEntFireByInstanceHandle(item, "DisableMotion", "", 0, nil, nil)
        icon:Kill()
        slot:SaveBoolean("HasStoredEntity", false)
        EmitSoundOn(SOUND_TAKE_ITEM, item)
    end
end
thisEntity:GetPrivateScriptScope().TakeItemFromBackpack = TakeItemFromBackpack

function CBaseEntity:PutInBackpack()
    PutItemInBackpack(self, nil, true)
end

---Used to check if player is grabbing backpack with other hand
---while behind the head, stop storing for that case
local transferred_hand = false

---Pickup
---@param data PLAYER_EVENT_ITEM_PICKUP
local function ItemPickup(data)
    --if data.item == thisEntity then
    --end
end
RegisterPlayerEventCallback("item_pickup", ItemPickup)


---Drop
---@param data PLAYER_EVENT_ITEM_RELEASED
local function ItemReleased(data)
    if data.item == thisEntity then
        -- Returning to back
        -- for now just immediately
        -- print("Player released backpack")
        thisEntity:SetContextThink("transfer_hand_test", function()
            -- print("Checking if holding backpack before storing, possible hand transfer")
            -- print("\tIs holding", Player:IsHolding(thisEntity))
            -- print("\tIs behind", HandIsBehindHead(data.hand))
            if not Player:IsHolding(thisEntity) and HandIsBehindHead(data.hand, 0.2) then
                EndBackpackHints()
                PutOnBack()
            end
        end, 0.1)
    elseif data.item then
        local slot = GetNearestSlot(data.item)
        if slot and not SlotHasItem(slot) then
            -- print("Released item into slot", data.item:GetName())
            PutItemInBackpack(data.item, slot)
        end
    end
end
RegisterPlayerEventCallback("item_released", ItemReleased)



---@param context CScriptPrecacheContext
function Precache(context)
    PrecacheModel("models/bivouac/backpack_slot.vmdl", context)
    PrecacheResource("sound", SOUND_STORE_BACKPACK, context)
    PrecacheResource("sound", SOUND_STORE_ITEM, context)
    PrecacheResource("sound", SOUND_TAKE_BACKPACK, context)
    PrecacheResource("sound", SOUND_TAKE_ITEM, context)
end

---@param spawnkeys CScriptKeyValues
function Spawn(spawnkeys)
    local start_x = (( ((SLOT_SIZE + PADDING) * (COLUMNS - 1) ) - 0) / 2)
    local start_y = (( ((SLOT_SIZE + PADDING) * (ROWS - 1) ) - 0) / 2)
    for column = 0, COLUMNS-1 do
        for row = 0, ROWS-1 do
            local slot = CreateSlot(
                start_x - (column * (SLOT_SIZE + PADDING)),
                start_y - (row * (SLOT_SIZE + PADDING))
            )
            slot:SaveString("debug_slot_index", '[' .. column .. ',' .. row .. ']')
        end
    end
end

-- local function LoadData()
--     for _, slot in ipairs(Entities:FindAllByName(SLOT_TARGETNAME)) do
--         if slot:LoadBoolean("HasStoredEntity", false) then
--             local stored = slot:LoadEntity("StoredEntity", nil)
--             if stored then
--                 PutItemInBackpack(stored, )
--             end
--         end
--     end
-- end



local function ready(saveLoaded)
    local init = function()
        print("VR backpack ready")
        Input:TrackButton(3)
        -- consider making 'first time game load' callback
        print("checking if backpack is stored")
        if not thisEntity:LoadBoolean("BackpackStored", false) then
            print('backpack is stored')
            PutOnBack(true)
        end
        thisEntity:SetThink(BackpackThink, "BackpackThink", 0)
    end
    if Player and Player.HMDAvatar then
        init()
    else
        RegisterPlayerEventCallback("vr_player_ready", init)
    end
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
-- local _a,_b=1,thisEntity:GetPrivateScriptScope()while true do local _c,_d=debug.getlocal(1,_a)if _c==nil then break end;if type(_d)=='function'then _b[_c]=_d end;_a=1+_a end

