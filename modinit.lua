MountModData( "RageLeagueExtraCardsMod" )

local function OnLoad()
    local self_dir = "RageLeagueExtraCardsMod:mod_content/"
    local LOAD_FILE_ORDER =
    {
        "sal_negotiation_mod",
        "sal_battle_mod",
        --"test_function_override",
        "unlocks_def_mod",
        "game_errata",
    }
    for k, filepath in ipairs(LOAD_FILE_ORDER) do
        require(self_dir .. filepath)
    end
end

return {
    OnLoad = OnLoad
}