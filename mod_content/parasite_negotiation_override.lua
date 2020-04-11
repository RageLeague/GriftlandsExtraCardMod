local CONTENT = Content.internal
local negotiation_defs = require "negotiation/negotiation_defs"
local CARD_FLAGS = negotiation_defs.CARD_FLAGS
local EVENT = ExtendEnum( negotiation_defs.EVENT,
{
    "PRE_GAMBLE",
    "GAMBLE",
})
local CONFIG = require "RageLeagueExtraCardsMod:config"

local function CreateDrawnHatcher(fn)
    local ret = function( self, card, source_deck, source_idx, target_deck, target_idx )
                 if card == self and target_deck == self.engine:GetHandDeck() and source_deck == self.engine:GetDrawDeck() then
                    self.engine:PushPostHandler( function()
                        self:NotifyTriggeredPre()
                        fn(self)
                        --self.owner:ApplyDamage(1, self.owner, self)
                        if self.engine then
                            self:AddXP(1)
                            if card:UpgradeReady() then
                                if card.hatch_fn then 
                                    card:hatch_fn(self.engine)
                                end
                            end
                        end
                        self:NotifyTriggeredPost()
                    end )
                end
            end
    return ret  
end

local parasites = {
    earworm = {
        desc = "If this is in your hand at the end of your turn, take {1} damage and add another <b>Earworm</> to your draw pile.\nGain 1 damage for each other <b>Earworm</> in your hand, draw, or discard.",
        desc_fn = function( self, fmt_str )
            return loc.format( fmt_str, self.eot_damage )
        end,
        eot_damage = 1,
        min_persuasion = 3,
        max_persuasion = 3,

        target_enemy = TARGET_ANY_RESOLVE,

        event_handlers = 
        {
            [ EVENT.CALC_PERSUASION ] = function( self, source, persuasion )
                local minigame = self.engine
                if source ~= self and source.id == "earworm" and (self.deck == minigame:GetHandDeck() or self.deck == minigame:GetDrawDeck() or self.deck == minigame:GetDiscardDeck()) then
                    persuasion:AddPersuasion(1, 1, self)
                end
            end,
            [ EVENT.END_PLAYER_TURN ] = function( self, minigame )
                if self.deck == minigame:GetHandDeck() then
                    self.negotiator:AttackResolve(2, self)
                    local clone = self:Duplicate()
                    clone:TransferCard( minigame:GetDrawDeck() )
                end
            end,
        },
    },
    voices = {
        desc = "When this card is drawn, discard a random card from your hand and gain actions equal to its cost.",
        event_handlers = 
        {
            [ EVENT.CARD_MOVED ] = CreateDrawnHatcher(function(self) 
                    local valid_cards = shallowcopy(self.engine:GetHandDeck().cards)
                    for i,card in ipairs(valid_cards) do
                        if card == self then
                            table.remove(valid_cards, i)
                            break
                        end
                    end
                    if #valid_cards > 0 then
                        local chosen_card = table.arraypick(valid_cards)
                        self.engine:DiscardCard(chosen_card)
                        self.engine:ModifyActionCount( chosen_card.cost, self )
                    end
            end)
        },
    },
    tinnitus =
    {
        desc = "When this card is drawn, deal {1} damage to a random friendly target and a random opponent target.",
        desc_fn = function( self, fmt_str )
            return loc.format( fmt_str, self.damage )
        end,
        damage = 2,
        event_handlers = 
        {
            [ EVENT.CARD_MOVED ] = CreateDrawnHatcher(function(self) 
                    local targets = self.engine:CollectAlliedTargets(self.negotiator)
                    if #targets > 0 then
                        local target = targets[math.random(#targets)]
                        target:AttackResolve(self.damage, self)
                    end
                    local etargets = self.engine:CollectAlliedTargets(self.anti_negotiator)
                    if #etargets > 0 then
                        local etarget = etargets[math.random(#etargets)]
                        etarget:AttackResolve(self.damage, self)
                    end
            end)
        },
    },
    drowsiness = 
    {
        desc = "When this card is drawn, lose 1 action, gain {1} resolve, and {EXPEND} this card.",
        desc_fn = function( self, fmt_str )
            return loc.format( fmt_str, self.healamt )
        end,
        healamt = 2,
        event_handlers = 
        {
            [ EVENT.CARD_MOVED ] = function( self, card, source_deck, source_idx, target_deck, target_idx )
                 if card == self and target_deck == self.engine:GetHandDeck() and source_deck == self.engine:GetDrawDeck() then
                    self.engine:PushPostHandler( function()
                        self:NotifyTriggeredPre()
                        if self.engine then
                            self.engine:ModifyActionCount(-1)
                            self:AddXP(1)
                            if card:UpgradeReady() then
                                if card.hatch_fn then 
                                    card:hatch_fn(self.engine)
                                end
                            end
                        end
                        self.negotiator:RestoreResolve( self.healamt, self )
                        self:NotifyTriggeredPost()
                        self.engine:ExpendCard(self)
                    end )
                end
            end
        },
    },
}
for i, id, data in sorted_pairs(parasites) do
    local basic_id = data.base_id or id:match( "(.*)_plus.*$" ) or id:match( "(.*)_upgraded[%w]*$") or id:match( "(.*)_supplemental.*$" )
    if CONFIG.enable_all_parasite_cards or CONFIG.enabled_cards[id] or CONFIG.enabled_cards[basic_id] then
        for j, param, val in sorted_pairs(data) do
            CONTENT.NEGOTIATION_CARDS[id][param] = val
        end
    end
end