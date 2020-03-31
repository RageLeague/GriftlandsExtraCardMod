local CONTENT = Content.internal

local function deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == "table" then
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
                if item.battle_card.series == id or item.battle_card.series == CARD_SERIES.GENERAL then
                    item.unlock_id = Content.AddUnlock(item.battle_card)
                end
            elseif item.deck_id then
                 assert( Content.GetDeck( item.deck_id ), item.deck_id )
                 item.unlock_id = Content.AddUnlock(item.deck_id)
            elseif item.negotiation_card then
                assert( Content.GetNegotiationCard( item.negotiation_card ), item.negotiation_card )
                if item.negotiation_card.series == id or item.negotiation_card.series == CARD_SERIES.GENERAL then
                    item.unlock_id = Content.AddUnlock(item.negotiation_card)
                end
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
        id = "rageleague_griftland_mod_1",
        name = "Mod: Politics and Payoffs",
        negotiation_name = "Politics",
        battle_name = "Payoffs",
        icon = "battle/decks/card_unlock_sal.tex",
        icon_locked = "battle/decks/card_unlock_sal_locked.tex",
        pts = 4000,
        items = 
        {
            { negotiation_card = "back_down"},
            { negotiation_card = "preach"},
            { negotiation_card = "darvo"},

            { battle_card = "bloodletting"},
            { battle_card = "bodyguard"},
            { battle_card = "bullseye"},
        }
    },
    { 
        --Additional stuff
        id = "rageleague_griftland_mod_2",
        name = "Mod: Deception and Ailments",
        negotiation_name = "Deception",
        battle_name = "Ailments",
        icon = "battle/decks/card_unlock_sal.tex",
        icon_locked = "battle/decks/card_unlock_sal_locked.tex",
        pts = 4000,
        items = 
        {
            { negotiation_card = "blackmail"},
            { negotiation_card = "fake_promise"},
            { negotiation_card = "clairvoyance"},
            { negotiation_card = "surprise_information"},
            
            { battle_card = "critical_strike"},
            { battle_card = "provoking_kick"},
            { battle_card = "ailment_storm"},
        }
    },
}
local function FilterInvalidCards( tracks, condition, set_id )
    for k,track_item in ipairs(tracks) do
        track_item.id = track_item.id .. set_id
        local i = 1
        while i <= #track_item.items do
            if condition(track_item.items[i], set_id) then
                table.remove(track_item.items, i)
            else
                i = i + 1
            end
        end
    end
    return tracks
end
local function CardFilter(item, set_id)
    if item.battle_card then
        local battle_card = Content.GetBattleCard( item.battle_card )
        if battle_card and (battle_card.series == set_id or battle_card.series == CARD_SERIES.GENERAL) then
            --item.unlock_id = Content.AddUnlock(item.battle_card)
            return false
        else
            return true
        end
    elseif item.negotiation_card then
        local negotiation_card = Content.GetNegotiationCard( item.negotiation_card )
        if negotiation_card and (negotiation_card.series == set_id or negotiation_card.series == CARD_SERIES.GENERAL) then
            return false
        else
            return true
        end
    end
    return false
end

for i,series_name in ipairs(UNLOCK_SERIES) do
    local get_track = Content.GetUnlockTrack(series_name)
    local start_pts = get_track[#get_track].total_pts
    for i, unlock_item in ipairs(ADDITIONAL_UNLOCKS) do
        unlock_item.start_pts = start_pts
        start_pts = start_pts + unlock_item.pts
        unlock_item.total_pts = start_pts
    end
    AddUnlockTrack(series_name, FilterInvalidCards(deepcopy(ADDITIONAL_UNLOCKS), CardFilter, series_name))
end

