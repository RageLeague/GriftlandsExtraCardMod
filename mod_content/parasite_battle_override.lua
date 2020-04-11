local CONTENT = Content.internal
local battle_defs = require "battle/battle_defs"
local CARD_FLAGS = battle_defs.CARD_FLAGS
local BATTLE_EVENT = ExtendEnum( battle_defs.EVENT,
{
    "PRIMED_GAINED",
    "PRIMED_LOST",
    "LUMIN_CHARGED",
    "LUMIN_SPENT",
})
local CONFIG = require "RageLeagueExtraCardsMod:config"

local parasites = {
}
for i, id, data in sorted_pairs(parasites) do
    local basic_id = data.base_id or id:match( "(.*)_plus.*$" ) or id:match( "(.*)_upgraded[%w]*$") or id:match( "(.*)_supplemental.*$" )
    if CONFIG.enable_all_parasite_cards or CONFIG.enabled_cards[id] or CONFIG.enabled_cards[basic_id] then
        for j, param, val in sorted_pairs(data) do
            CONTENT.BATTLE_CARDS[id][param] = val
        end
    end
end