---@param context CScriptPrecacheContext
function Precache(context)
    PrecacheModel("models/bivouac/hint_panel.vmdl", context)
    -- print("start precache")
    -- PrecacheEntityFromTable("prop_dynamic", {
    --     model = "models/bivouac/hint_panel.vmdl",
    --     skin = "default",
    --     targetname = "hint_panel"
    -- }, context)
    -- print("end precache")
end