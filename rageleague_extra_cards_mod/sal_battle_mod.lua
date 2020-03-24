local battle_defs = require "battle/battle_defs"
local CARD_FLAGS = battle_defs.CARD_FLAGS
local BATTLE_EVENT = battle_defs.BATTLE_EVENT

local attacks =
{
    bloodletting = 
    {
        name = "Bloodletting",
        anim = "lacerate",
        desc = "Target enemy fighter triggers {BLEED} damage until the fighter dies or {BLEED} goes away.",
        flavour = "Better known as: Mandatory Blood Donation.",

        icon = "battle/hemorrhage.tex",
        flags = CARD_FLAGS.MELEE,
        rarity = CARD_RARITY.RARE,
        cost = 1,
        target_type = TARGET_TYPE.ENEMY,

        maintainRatio = 0,

        OnPostResolve = function( self, battle, attack)
            for i, hit in attack:Hits() do
                if not attack:CheckHitResult( hit.target, "evaded" ) then
                    local initBleedCount = hit.target:GetConditionStacks("BLEED")
                    local bleed = hit.target:GetCondition("BLEED")
                    bleed:AddApplicant(self)
                    while hit.target:GetConditionStacks("BLEED") > 0 and hit.target:IsAlive() do
                        local bleedStack = hit.target:GetConditionStacks("BLEED")
                        bleed.event_handlers[BATTLE_EVENT.BEGIN_TURN](bleed, hit.target)
                        if bleedStack <= hit.target:GetConditionStacks("BLEED") then
                            bleed:SetStacks(bleedStack - 1)
                        end
                    end
                    hit.target:AddCondition("BLEED", math.floor(initBleedCount * self.maintainRatio), self)
                end
            end
        end,
    },
    bloodletting_plus =
    {
        name = "Maintained Bloodletting",
        desc = "Target enemy fighter triggers {BLEED} damage until the fighter dies or {BLEED} goes away.\n<#UPGRADE>That enemy gains {BLEED} equal to half the initial stacks.</>",
        maintainRatio = 0.5,
    },
    bloodletting_plus2 =
    {
        name = "Wide Bloodletting",
        desc = "<#UPGRADE>Each</> enemy fighter triggers {BLEED} damage until the fighter dies or {BLEED} goes away.",
        target_mod = TARGET_MOD.TEAM,
    },
    bodyguard =
    {
        name = "Bodyguard",
        desc = "Gain {1} {DEFEND} and {2} {PROTECT} for every fighter on your team.",
        flavour = "'Don't worry everyone, I'll take one for the team!'",
        desc_fn = function( self, fmt_str )
            return loc.format( fmt_str, self.defend_amt, self.protect_amt, self.riposte_amt )
        end,
        anim = "run_forward",
        icon = "battle/active_defense.tex",
        target_type = TARGET_TYPE.SELF,

        rarity = CARD_RARITY.UNCOMMON,
        cost = 1,
        max_xp = 7,
        flags = CARD_FLAGS.SKILL,

        defend_amt = 5,
        protect_amt = 1,
        riposte_amt = 0,

        OnPostResolve = function(self, battle, attack)
            local count = #self.owner:GetTeam():GetFighters()
            for i, hit in attack:Hits() do
                hit.target:AddCondition("DEFEND", self.defend_amt * count, self)
                hit.target:AddCondition("PROTECT", self.protect_amt * count, self)
                hit.target:AddCondition("RIPOSTE", self.riposte_amt * count, self)
            end
        end,
    },
    bodyguard_plus =
    {
        name = "Spined Bodyguard",
        desc = "Gain {1} {DEFEND}, <#UPGRADE>{3} {RIPOSTE}</>, and {2} {PROTECT} for every fighter on your team.",
        riposte_amt = 2,
    },
    bodyguard_plus2 =
    {
        name = "Targeted Bodyguard",
        desc = "<#UPGRADE>Apply</> {1} {DEFEND} and {2} {PROTECT} for every fighter on your team.",
        flavour = "'On second thought, why don't you take one for the team?'\n'Wait, what?'",
        target_type = TARGET_TYPE.FRIENDLY_OR_SELF,
    },
    critical_strike =
    {
        name = "Critical Strike",
        desc = "Apply 1 {STAGGER} for each debuff on the target.",
        desc_fn = function( self, fmt_str )
            return loc.format( fmt_str, self.stagger_delta, self.stagger_delta_threshold )
        end,
        flavour = "It's like adding salt to the wound.",
        anim = "strike",
        icon = "battle/vital_strikes.tex",
        target_type = TARGET_TYPE.ENEMY,

        min_damage = 3,
        max_damage = 3,

        rarity = CARD_RARITY.COMMON,
        cost = 1,
        max_xp = 7,
        flags = CARD_FLAGS.MELEE,

        stagger_delta = 0,
        stagger_delta_threshold = 0,

        OnPostResolve = function(self, battle, attack)
            for i, hit in attack:Hits() do
                local count = 0
                for i,condition in pairs(hit.target:GetConditions()) do
                    if condition.ctype == CTYPE.DEBUFF then
                        count = count + 1
                    end
                end
                hit.target:AddCondition("STAGGER", count + (count >= self.stagger_delta_threshold and self.stagger_delta or 0), self)
            end
        end,
    },
    critical_strike_plus =
    {
        name = "Boosted Critical Strike",
        min_damage = 6,
        max_damage = 6,
    },
    critical_strike_plus2 = 
    {
        name = "Enhanced Critical Strike",
        desc = "Apply 1 {STAGGER} for each debuff on the target. <#UPGRADE>If the target has at least {2} {2*debuff|debuffs}, {STAGGER} applied is increased by {1}.</>",
        stagger_delta = 1,
        stagger_delta_threshold = 2,
    },
}

for i, id, data in sorted_pairs(attacks) do
    data.series = CARD_SERIES.GENERAL
    
    Content.AddBattleCard( id, data )
end