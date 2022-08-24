
---@param spawnkeys CScriptKeyValues
function Spawn(spawnkeys)
    -- Consider saving directly to stone pedestal after it spawns
    thisEntity:SaveString("correct_angle", spawnkeys:GetValue("Group00") or "")
    thisEntity:SaveString("correct_stone", spawnkeys:GetValue("Group01") or "")
    print("LALALALA")
    print(spawnkeys:GetValue("Group01"))
    print(thisEntity:LoadString("correct_stone"))
end
