MountModData( "RageLeagueExtraCardsMod" )

local function OnLoad()
    local self_dir = "RageLeagueExtraCardsMod:mod_content/"
    local LOAD_FILE_ORDER =
    {
        "sal_negotiation_mod",
        "sal_battle_mod",
        "parasite_negotiation_override",
        "parasite_battle_override",
        "test_function_override",
        "unlocks_def_mod",
        "game_errata",
        "fix_plax_editor_zoom",
    }
    for k, filepath in ipairs(LOAD_FILE_ORDER) do
        require(self_dir .. filepath)
    end
end

return {
    OnLoad = OnLoad
}