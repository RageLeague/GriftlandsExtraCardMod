local negotiation_defs = require "negotiation/negotiation_defs"
local CARD_FLAGS = negotiation_defs.CARD_FLAGS
local EVENT = ExtendEnum( negotiation_defs.EVENT,
{
    "PRE_GAMBLE",
    "GAMBLE",
})
local CONFIG = require "RageLeagueExtraCardsMod:config"

local QUIPS =
{
    ["back_down_quips"] = {
        {
            tags = "target_self",
            [[
                !placate
                $neutralTakenAback
                Fine, fine. You win this one.
            ]],
            [[
                !placate
                $neutralTakenAback
                Okay, you got me.
            ]],
        },
        {
            tags = "target_other",
            [[
                !angry
                !point
                You step down!
            ]],
        },
        {
            tags = "target_both",
            [[
                I'll step down if you step down.
            ]],
        }
    },
}

local CARDS =
{
    back_down = 
    {
        name = "Back Down",
        desc = "Remove one of your arguments or bounties. Its controller gain resolve equal to the argument's resolve.",
        flavour = "'Alright, alright, you're right about this. And only this.'",
        icon = "negotiation/stammer.tex",
        quips = QUIPS["back_down_quips"],

        flags = CARD_FLAGS.DIPLOMACY,
        rarity = CARD_RARITY.UNCOMMON,

        max_xp = 5,
        cost = 1,
        healModifier = 1,

        target_self = TARGET_FLAG.ARGUMENT | TARGET_FLAG.BOUNTY,

        Reconsider = function( self, minigame, targets )
            for i, target in ipairs( targets ) do
                local argumentResolve = target:GetResolve()
                if target.negotiator == self.negotiator then
                    target:GetNegotiator():RemoveModifier( target )
                else
                    target:GetNegotiator():DestroyModifier( target, self )
                end
                target:GetNegotiator():RestoreResolve( argumentResolve * self.healModifier, self )
                
            end
        end,
        OnPreResolve = function( self, minigame, targets )
            local selfTarget = 0
            local otherTarget = 0
            for i, target in ipairs( targets ) do
                if target.negotiator == self.negotiator then
                    selfTarget = selfTarget + 1
                else
                    otherTarget = otherTarget + 1
                end
            end
            ---[[
            if selfTarget == 0 then
                self.quip = "target_other"
            else
                if otherTarget == 0 then
                    self.quip = "target_self"
                else
                    self.quip = "target_both"
                end
            end
            --]]
        end,

        OnPostResolve = function( self, minigame, targets )
            self:Reconsider(minigame, targets)
        end,
    },
    back_down_plus = 
    {
        name = "Sticky Back Down",
        flavour = "'Alright, alright, I'll back down. Eventually.'",
        flags = CARD_FLAGS.DIPLOMACY | CARD_FLAGS.STICKY,
        --quips = QUIPS["back_down_quips"],
    },
    back_down_plus2 =
    {
        name = "Wide Back Down",
        desc = "Remove <#UPGRADE>any one argument or bounty</>. Its controller gain resolve equal to the argument's resolve.",
        flavour = "'I'm done backing down. Why don't <i>you</> back down instead?'",
        target_enemy = TARGET_FLAG.ARGUMENT | TARGET_FLAG.BOUNTY,
        flags = CARD_FLAGS.HOSTILE,
        --quips = QUIPS["back_down_quips"],
    },
    preach =
    {
        name = "Preach",
        desc = "{INCEPT} {1} {INDOCTRINATION}.",
        flavour = "'Are you interested in our lord and savior, Hesh?'",
        icon = "negotiation/beguile.tex",
        desc_fn = function( self, fmt_str )
            return loc.format( fmt_str, self.num_indoctrination )
        end,
        
        flags = CARD_FLAGS.MANIPULATE,
        rarity = CARD_RARITY.UNCOMMON,
        
        cost = 1,
        num_indoctrination = 4,

        OnPostResolve = function( self, minigame )
            minigame:GetOpponentNegotiator():AddModifier( "INDOCTRINATION", self.num_indoctrination )
            if (self.draw_count or 0) > 0 then
                minigame:DrawCards( self.draw_count )
            end
        end,
    },
    preach_plus = 
    {
        name = "Visionary Preach",
        desc = "{INCEPT} {1} {INDOCTRINATION}.\n<#UPGRADE>Draw a card.</>",
        draw_count = 1,
    },
    preach_plus2 = 
    {
        name = "Enhanced Preach",
        num_indoctrination = 6,
    },
    blackmail = 
    {
        name = "Blackmail",
        desc = "Deal +{1} damage for every {INFLUENCE} you have.",
        flavour = "'Your secrets are safe with me... As long as you do as I say.'",
        icon = "negotiation/kicker.tex",
        desc_fn = function( self, fmt_str )
            return loc.format(fmt_str, self.dmg_per_arg)
        end,
        cost = 1,

        flags = CARD_FLAGS.HOSTILE,
        rarity = CARD_RARITY.COMMON,

        min_persuasion = 0,
        max_persuasion = 3,
        dmg_per_arg = 1,
        additionStack = "INFLUENCE",

        event_handlers = 
        {
            [ EVENT.CALC_PERSUASION ] = function( self, source, persuasion )
                if source == self then
                    local count = self.negotiator:GetModifierStacks(self.additionStack)
                    persuasion:AddPersuasion(count * self.dmg_per_arg, count * self.dmg_per_arg, self)
                end
            end
        },
    },
    blackmail_plus = 
    {
        name = "Tall Blackmail",
        --min_persuasion = 0,
        max_persuasion = 5,
    },
    blackmail_plus2 =
    {
        name = "Twisted Blackmail(?)",
        desc = "Deal +{1} damage for every <#UPGRADE>{DOMINANCE}</> you have.",
        flags = CARD_FLAGS.DIPLOMACY,
        additionStack = "DOMINANCE",
        --min_persuasion = 0,
        max_persuasion = 5,
    },
    darvo = 
    {
        name = "DARVO",
        desc = "Gain: Every time you take damage, deal half that damage to a random enemy argument.\nGain {1} {VULNERABILITY}.",
        desc_fn = function( self, fmt_str )
            return loc.format(fmt_str, self.vulnerabilityAdd)
        end,
        icon = "negotiation/swift_rebuttal.tex",
        flavour = "DARVO, Randy. Deny, Attack, Reverse Victim and Offender.",
        cost = 1,

        flags = CARD_FLAGS.HOSTILE | CARD_FLAGS.EXPEND,
        rarity = CARD_RARITY.RARE,
        
        doNegateDamage = false,
        reflectionMultiplier = 0.5,
        vulnerabilityAdd = 3,
        
        modifierName = "No, U",
        --[[
        CanPlayCard = function( self, card, engine, target )
            if card == self then
                return self.negotiator:GetModifierStacks( "darvo" ) == 0
            end
        end,
        --]]
        OnPostResolve = function( self, minigame, targets )
            local count = self.negotiator:GetModifierStacks( "darvo" )
            self.negotiator:RemoveModifier("darvo", count)
            self.negotiator:AddModifier("VULNERABILITY",self.vulnerabilityAdd,self)
            local newMod = self.negotiator:CreateModifier("darvo", 1, self)
            newMod.name = self.modifierName
            newMod.doNegateDamage = self.doNegateDamage
            newMod.reflectionMultiplier = self.reflectionMultiplier
            newMod:NotifyChanged()
        end,
        modifier =
        {
            name = "No, U",
            desc = "Every time {1} take damage, deal {2}x that damage to a random enemy argument{3}.\nOnly 1 modifier of this name can exist at a time. If a new modifier is created, the old one is removed.",
            desc_fn = function ( self, fmt_str )
                return loc.format( fmt_str, self.negotiator:GetName() or "owner", self.reflectionMultiplier,self.doNegateDamage and " and gain that much resolve on the damaged argument" or "")
            end,
            
            doNegateDamage = false,
            reflectionMultiplier = 0.5,
            
            max_resolve = 3,
            OnInit = function(self)
                self.icon = engine.asset.Texture("negotiation/modifiers/animosity.tex")
                self.engine:BroadcastEvent( negotiation_defs.EVENT.UPDATE_MODIFIER_ICON, self)
            end,
            event_handlers =
            {
            ---[[
                [ EVENT.ATTACK_RESOLVE ] = function( self, source, target, damage, params, defended )
                    if source == self then
                        if self.doNegateDamage then
                            self.negotiator:RestoreResolve( damage, self )
                        end
                    end
                    if target.negotiator == self.negotiator then
                        local negatedDamage = math.floor(damage * self.reflectionMultiplier)
                        --Workaround: Heal instead of negate. Probably trigger something, though no one can tell.
                        if negatedDamage > 0 then
                            --[[
                            if self.doNegateDamage then
                                target:RestoreResolve( negatedDamage, self )
                            end
                            --]]
                            self.min_persuasion = negatedDamage
                            self.max_persuasion = negatedDamage
                            self.target_enemy = TARGET_ANY_RESOLVE
                            self:ApplyPersuasion()
                            self.target_enemy = nil
                            
                        end
                    end
                end,
            --]]
            },
        }
    },
    darvo_plus =
    {
        name = "Draining DARVO",
        desc = "Gain: Every time you take damage, deal half that damage to a random enemy argument <#UPGRADE>and gain that much resolve on the damaged argument</>.\nGain {1} {VULNERABILITY}.",
        doNegateDamage = true,
        modifierName = "Draining No, U",
    },
    darvo_plus2 =
    {
        name = "Strong DARVO",
        desc = "Gain: Every time you take damage, deal <#UPGRADE>that much damage</> to a random enemy argument.\nGain {1} {VULNERABILITY}.",
        reflectionMultiplier = 1,
        modifierName = "Strong No, U",
    },
    fake_promise =
    {
        name = "Fake Promise",
        desc = "Create a {GAIN_SHILLS_AT_END} argument with <#UPGRADE>{1}</> stacks.",
        icon = "negotiation/prominence.tex",
        flavour = "'Yes, yes. I promise I will pay you for your cooperation.'\n'Since when did I promise that? Do you have any proof?'",
        cost = 1,
        desc_fn = function( self, fmt_str )
            return loc.format( fmt_str, math.floor(self.money_cost / 5) )
        end,
        flags = CARD_FLAGS.MANIPULATE,
        rarity = CARD_RARITY.COMMON,
        money_cost = 10,
        min_persuasion = 2,
        max_persuasion = 7,
        OnPostResolve = function( self, minigame, targets )
            self.negotiator:CreateModifier("GAIN_SHILLS_AT_END", math.floor(self.money_cost / 5), self)
        end,
    },
    fake_promise_plus =
    {
        name = "Pale Promise",
        cost = 0,
    },
    fake_promise_plus2 =
    {
        name = "Enhanced Promise",
        min_persuasion = 5,
        max_persuasion = 10,
        money_cost = 20,
    },
    clairvoyance = 
    {
        name = "Clairvoyance",
        desc = "Gain: Choose {HEADS} or {SNAILS} at the end of each turn. Whenever you get the chosen side, apply {1} {COMPOSURE} to a random argument.",
        icon = "negotiation/hyperactive.tex",
        flavour = "'I'm a psychic. I can predict which side this coin will land on. Watch this - wait, hold on, let's try this again...'",

        cost = 2,
        desc_fn = function( self, fmt_str )
            return loc.format( fmt_str, self.composure_stacks )
        end,
        flags = CARD_FLAGS.MANIPULATE | CARD_FLAGS.EXPEND,
        rarity = CARD_RARITY.UNCOMMON,
        series = "ROOK",
        max_xp = 4, 

        composure_stacks = 2,

        OnPostResolve = function( self, minigame, targets )
            self.negotiator:CreateModifier("clairvoyance", self.composure_stacks, self)
        end,
        modifier = 
        {
            name = "Clairvoyance",
            desc = "Choose {HEADS} or {SNAILS} at the end of each turn. Whenever you get the chosen side, apply {1} {COMPOSURE} to a random argument.",
            chosen_side_str = "You have chosen: {{2}}",
            desc_fn = function( self, fmt_str )
                if self.chosen_side then
                    return loc.format( fmt_str .. "\n" ..self.chosen_side_str, self.stacks, self.chosen_side )
                else
                    return loc.format( fmt_str, self.stacks )
                end
            end,
            
            max_resolve = 5,
            OnInit = function(self)
                self:UpdateIcon()
            end,

            UpdateIcon = function(self)
                if (self.chosen_side) then
                    if self.chosen_side == "HEADS" then
                        self.icon = engine.asset.Texture("negotiation/modifiers/rig_heads.tex")
                    elseif self.chosen_side == "SNAILS" then
                        self.icon = engine.asset.Texture("negotiation/modifiers/rig_snails.tex")
                    else
                        self.icon = engine.asset.Texture("negotiation/modifiers/lucky_coin.tex")
                    end
                else
                    self.icon = engine.asset.Texture("negotiation/modifiers/lucky_coin.tex")
                end
                self.engine:BroadcastEvent( negotiation_defs.EVENT.UPDATE_MODIFIER_ICON, self)
            end,

            event_handlers = 
            {
                [ EVENT.END_PLAYER_TURN ] = function( self, minigame )
                    local cards = {
                        Negotiation.Card( "coin_snails", self.owner ),
                        Negotiation.Card( "coin_heads", self.owner ),
                    }
                    local pick = self.engine:ImproviseCards( cards, 1 )[1]
                    local side = pick and pick.side or "HEADS"
                    if pick then self.engine:ExpendCard(pick) end
                    if side == "HEADS" then
                        --self.negotiator:AddModifier("RIG_HEADS", 2)
                        self.chosen_side = "HEADS"
                    else
                        --self.negotiator:AddModifier("RIG_SNAILS", 2)
                        self.chosen_side = "SNAILS"
                    end
                    self:UpdateIcon()
                    self:NotifyChanged()
                end,
                [ EVENT.GAMBLE ] = function( self, result, source, ignore_bonuses )
                    if not ignore_bonuses and result == self.chosen_side then
                        local targets = self.engine:CollectAlliedTargets(self.negotiator)
                        if #targets > 0 then
                            local target = targets[math.random(#targets)]
                            target:DeltaComposure(self.stacks, self)
                        end
                    end
                end,
            },
        },
    },
    clairvoyance_plus = 
    {
        name = "Pale Clairvoyance",
        cost = 1,
    },
    clairvoyance_plus2 =
    {
        name = "Boosted Clairvoyance",
        desc = "Gain: Choose {HEADS} or {SNAILS} at the end of each turn. Whenever you get the chosen side, apply <#UPGRADE>{1}</> {COMPOSURE} to a random argument.",
        composure_stacks = 3,
    },
    surprise_information =
    {
        name = "Surprise Information",
        desc = "Remove {1} {IMPATIENCE} from the opponent.",
        flavour =
[[You'll never see it coming
You'll see that my mind is too fast for eyes
You're done in
By the time it's hit you, your last surprise]],
        cost = 1,
        desc_fn = function( self, fmt_str )
            return loc.format( fmt_str, self.impatience_remove )
        end,
        icon = "negotiation/sealed_admiralty_envelope.tex",
        flags = CARD_FLAGS.DIPLOMACY | CARD_FLAGS.EXPEND,
        rarity = CARD_RARITY.UNCOMMON,

        min_persuasion = 2,
        max_persuasion = 5,

        impatience_remove = 1,

        RemoveImpatienceFunction = function(self, minigame, target)
        end,
        OnPreResolve = function( self, minigame, targets )
            local target = targets[1]
            if target.negotiator:HasModifier("IMPATIENCE") then
                target.negotiator:RemoveModifier("IMPATIENCE", 1, self)
                if self.RemoveImpatienceFunction then
                    self:RemoveImpatienceFunction(minigame,target)
                end
            end
        end,
    },
    surprise_information_plus =
    {
        name = "Boosted Surprise Information",
        min_persuasion = 4,
        max_persuasion = 7,
    },
    surprise_information_plus2 =
    {
        name = "Enhanced Surprise Information",
        desc = "Remove <#UPGRADE>{1}</> {IMPATIENCE} from the opponent.",
        impatience_remove = 2,
    },
    violent_tendencies =
    {
        name = "Violent Tendencies",
        desc = "Gain 1 bonus damage for each stacks of {DOMINANCE}.\n{INCEPT} 1 {IMPATIENCE}.",
        icon = "negotiation/grunt.tex",
        min_persuasion = 6,
        max_persuasion = 6,
        murder_card = true,
        must_loot = true,
        rarity = CARD_RARITY.BASIC,
        flags = CARD_FLAGS.STATUS | CARD_FLAGS.EXPEND,
        cost = 1,
        OnPostResolve = function( self, minigame, targets )
            self.anti_negotiator:AddModifier("IMPATIENCE", 1, self )
        end,
        event_handlers = {
            [ EVENT.CALC_PERSUASION ] = function ( self, source, persuasion )
                if source == self then
                    local count = self.negotiator:GetModifierStacks("DOMINANCE")
                    persuasion:AddPersuasion( count, count, self )
                end
            end,
        }
    },
}
---[[
local MODIFIERS =
{
    GAIN_SHILLS_AT_END =
    {
        name = "Gain Shills At The End",
        desc = "Gain {1#money} at the end of this negotiation for each stacks on this bounty if this bounty still exists, regardless whether you win or lose.",
        feature_desc = "Gain {1} {GAIN_SHILLS_AT_END}.",
        desc_fn = function( self, fmt_str )
            return loc.format( fmt_str, 5 )
        end,

        max_resolve = 2,
        modifier_type = MODIFIER_TYPE.BOUNTY,

        OnInit = function(self)
            self.icon = engine.asset.Texture("negotiation/modifiers/frisk.tex")
            --self.engine:BroadcastEvent( negotiation_defs.EVENT.UPDATE_MODIFIER_ICON, self)
        end,
        endGameCheck = function( self, minigame )
            --If the game is ended, gain money equal to the stack number * 5
            if minigame:CheckGameOver() then
                minigame:ModifyMoney( 5 * self.stacks )
                self:GetNegotiator():RemoveModifier( self )
            end
        end,

        event_handlers =
        {
            [ EVENT.END_TURN ] = function( self, engine, negotiator )
                self:endGameCheck(self.engine)
            end,
            [ EVENT.END_RESOLVE ] = function(self, minigame, card)
                self:endGameCheck(self.engine)
            end,
            [ EVENT.ATTACK_RESOLVE ] = function( self, source, target, damage, params, defended )
                self:endGameCheck(self.engine)
            end,
            [ EVENT.DELTA_RESOLVE ] = function( self, modifier, resolve, max_resolve, delta, source, params )
                self:endGameCheck(self.engine)
            end,
        },
        
    },
}
for id, def in pairs( MODIFIERS ) do
    Content.AddNegotiationModifier( id, def )
end
--]]


for i, id, carddef in sorted_pairs( CARDS ) do
    if not carddef.series then
        carddef.series = CARD_SERIES.GENERAL
    end
    local basic_id = carddef.base_id or id:match( "(.*)_plus.*$" ) or id:match( "(.*)_upgraded[%w]*$") or id:match( "(.*)_supplemental.*$" )
    if CONFIG.enabled_cards[id] or CONFIG.enabled_cards[basic_id] then
        Content.AddNegotiationCard( id, carddef )
    end
end
