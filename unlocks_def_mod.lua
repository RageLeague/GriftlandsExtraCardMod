local CONTENT = Content.internal

local function deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[deepcopy(orig_key)] = deepcopy(orig_value)
        end
        setmetatable(copy, deepcopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

local function AddUnlockTrack( id, track )
    
    local unlock_track = CONTENT.UNLOCK_TRACKS[id] or {}

    for k,track_item in ipairs(track) do
        
        for k, item in ipairs(track_item.items) do

            if item.battle_card then
                assert( Content.GetBattleCard( item.battle_card ), item.battle_card )
                item.unlock_id = Content.AddUnlock(item.battle_card)
            elseif item.deck_id then
                 assert( Content.GetDeck( item.deck_id ), item.deck_id )
                 item.unlock_id = Content.AddUnlock(item.deck_id)
            elseif item.negotiation_card then
                assert( Content.GetNegotiationCard( item.negotiation_card ), item.negotiation_card )
                item.unlock_id = Content.AddUnlock(item.negotiation_card)
            elseif item.graft_id then
                assert( Content.GetGraft( item.graft_id ), item.graft_id )
                item.unlock_id = Content.AddUnlock(item.graft_id)
            elseif item.outfit_id then
                assert( Content.GetOutfit( item.outfit_id ), item.outfit_id )
                item.unlock_id = Content.AddUnlock(item.outfit_id)
            elseif item.player_background then
                assert( GetPlayerBackground( item.player_background ), item.player_background )
                item.unlock_id = Content.AddUnlock(item.player_background)
            end
        end
        if track_item.icon then
            track_item.icon = engine.asset.Texture( track_item.icon, true )
        end
        if track_item.icon_locked then
            track_item.icon_locked = engine.asset.Texture( track_item.icon_locked, true )
        end
        unlock_track[#unlock_track + 1] = track_item
    end
end

local UNLOCK_SERIES = {
    "SAL",
    "ROOK",
}
local ADDITIONAL_UNLOCKS = {
    { 
        --Additional stuff
        id = "rageleague_griftland_mod",
        name = "Griftlands Mod Content",
        negotiation_name = "Modded Negotiation",
        battle_name = "Modded Battle",
        icon = "battle/decks/card_unlock_sal.tex",
        icon_locked = "battle/decks/card_unlock_sal_locked.tex",
        pts = 6000,
        items = 
        {
            { negotiation_card = "back_down"},
            { negotiation_card = "preach"},
            { negotiation_card = "blackmail"},
            { negotiation_card = "darvo"},
            { negotiation_card = "fake_promise"},
            { battle_card = "bloodletting"},
            { battle_card = "bodyguard"},
            { battle_card = "critical_strike"},
        }
    },
}


for i,series_name in ipairs(UNLOCK_SERIES) do
    local get_track = Content.GetUnlockTrack(series_name)
    local start_pts = get_track[#get_track].total_pts
    for i, unlock_item in ipairs(ADDITIONAL_UNLOCKS) do
        unlock_item.start_pts = start_pts
        start_pts = start_pts + unlock_item.pts
        unlock_item.total_pts = start_pts
    end
    AddUnlockTrack(series_name, deepcopy(ADDITIONAL_UNLOCKS))
end

