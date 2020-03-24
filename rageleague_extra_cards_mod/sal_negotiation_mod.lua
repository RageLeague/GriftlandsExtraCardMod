local negotiation_defs = require "negotiation/negotiation_defs"
local CARD_FLAGS = negotiation_defs.CARD_FLAGS
local EVENT = negotiation_defs.EVENT

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
        min_persuasion = 0,
        max_persuasion = 5,
    },
    blackmail_plus2 =
    {
        name = "Twisted Blackmail(?)",
        desc = "Deal +{1} damage for every <#UPGRADE>{DOMINANCE}</> you have.",
        flags = CARD_FLAGS.DIPLOMACY,
        additionStack = "DOMINANCE",
        min_persuasion = 0,
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
    carddef.series = CARD_SERIES.GENERAL

    Content.AddNegotiationCard( id, carddef )
end
