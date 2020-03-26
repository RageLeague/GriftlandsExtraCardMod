local self_dir = "content/mods/rageleague_extra_cards_mod/"
local LOAD_FILE_ORDER =
{
    "sal_negotiation_mod",
    "sal_battle_mod",
    "unlocks_def_mod",
    "game_errata",
}
for k, filepath in ipairs(LOAD_FILE_ORDER) do
    require(self_dir .. filepath)
end