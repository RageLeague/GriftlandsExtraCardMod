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

        series = "SAL",

        min_damage = 3,
        max_damage = 5,

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
                        if self.additionalDebuff then
                            hit.target:AddCondition(self.additionalDebuff, 1, self)
                        end
                    end
                    hit.target:AddCondition("BLEED", math.floor(initBleedCount * self.maintainRatio), self)
                end
            end
            self.hit_count = 1
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
        name = "Crippling Bloodletting",
        desc = "Target enemy fighter triggers {BLEED} damage until the fighter dies or {BLEED} goes away.\n<#UPGRADE>Apply 1 {CRIPPLE} each time it is triggered.</>",
        --target_mod = TARGET_MOD.TEAM,
        additionalDebuff = "CRIPPLE",
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
    bullseye =
    {
        name = "Bullseye",
        desc = "Gain: Ranged cards have an additional {1} percent change of dealing {CRITICAL_DAMAGE}.",
        desc_fn = function( self, fmt_str )
            return loc.format( fmt_str, self.bullseye_amt )
        end,
        icon = "battle/target_practice.tex",

        target_type = TARGET_TYPE.SELF,
        cost = 1,
        rarity = CARD_RARITY.UNCOMMON,
        flags = CARD_FLAGS.SKILL | CARD_FLAGS.EXPEND,
        bullseye_amt = 10,
        OnPostResolve = function( self, battle, attack)
            self.owner:AddCondition("bullseye", self.bullseye_amt, self)
        end,

        condition = 
        {
            desc = "Ranged cards have a {1} percent chance of dealing {CRITICAL_DAMAGE}.",
            desc_fn = function(self, fmt_str)
                return loc.format(fmt_str, self.stacks)
            end,
            icon = "battle/conditions/combo.tex",
            max_stacks = 100,
            priority = 1,
            --[[OnPostDamage = function( self, damage, attacker, battle, source )
                local card
                if is_instance( source, Battle.Card ) then
                    card = source
                elseif is_instance( source, Battle.Attack ) then
                    card = source.card
                end
                if card.temp_piercing then
                    card.temp_piercing = false
                    card.flags = card.flags & (~CARD_FLAGS.PIERCING)
                end
            end,--]]
            event_handlers =
            {
                [ BATTLE_EVENT.PRE_RESOLVE ] = function( self, battle, attack )
                    if (attack and attack.attacker == self.owner) then
                        if attack.card and attack.card:IsFlagged(CARD_FLAGS.RANGED) then
                            if math.random() * 100 < self.stacks then

                                if (not attack.card:IsFlagged(CARD_FLAGS.PIERCING)) then
                                    attack.card.temp_piercing = true
                                    attack.card:SetFlags(CARD_FLAGS.PIERCING)
                                end
                                for i, hit in attack:Hits() do
                                    hit.target:AddCondition("CRITICAL_DAMAGE",1,self)
                                end
                            end
                        end
                    end
                end,
                [ BATTLE_EVENT.POST_RESOLVE ] = function( self, battle, attack )
                    if (attack and attack.attacker == self.owner) then
                        if attack.card and attack.card:IsFlagged(CARD_FLAGS.RANGED) then
                            if attack.card.temp_piercing then
                                attack.card.temp_piercing = false
                                attack.card:ClearFlags(CARD_FLAGS.PIERCING)
                            end
                            for i, hit in attack:Hits() do
                                hit.target:RemoveCondition("CRITICAL_DAMAGE")
                            end
                        end
                    end
                end,
            }
        },
    },
    bullseye_plus =
    {
        name = "Boosted Bullseye",
        desc = "Gain: Ranged cards have an additional <#UPGRADE>{1}</> percent change of dealing {CRITICAL_DAMAGE}.",
        bullseye_amt = 15,

    },
    bullseye_plus2 =
    {
        name = "Initial Bullseye",
        desc = "Gain: Ranged cards have an additional {1} percent change of dealing {CRITICAL_DAMAGE}.",
        flags = CARD_FLAGS.SKILL | CARD_FLAGS.EXPEND | CARD_FLAGS.AMBUSH,
    },
    provoking_kick =
    {
        name = "Provoking Kick",
        desc = "If the target is a sentient humanoid, apply {STUN} and {VENDETTA}.",
        anim = "kick",
        target_type = TARGET_TYPE.ENEMY,

        min_damage = 8,
        max_damage = 8,

        rarity = CARD_RARITY.UNCOMMON,
        cost = 2,
        max_xp = 4,
        flags = CARD_FLAGS.MELEE | CARD_FLAGS.EXPEND,

        must_be_humanoid = true,

        OnPostResolve = function( self, battle, attack)
            for i, hit in attack:Hits() do
                local hitTarget = hit.target
                if (not must_be_humanoid) or hitTarget.agent:IsSentient() then
                    hitTarget:AddCondition("STUN",1,self)
                    if hitTarget:GetConditionStacks("VENDETTA") == 0 then
                        hitTarget:AddCondition("VENDETTA",1,self)
                    end
                end
            end
        end,
    },
    provoking_kick_plus =
    {
        name = "Boosted Provoking Kick",
        min_damage = 12,
        max_damage = 12,
    },
    provoking_kick_plus2 =
    {
        name = "Enhanced Provoking Kick",
        desc = "<#UPGRADE>Apply {STUN} and {VENDETTA}.</>",
        must_be_humanoid = false,
    },
}

for i, id, data in sorted_pairs(attacks) do
    if not data.series then
        data.series = CARD_SERIES.GENERAL
    end
    Content.AddBattleCard( id, data )
end

local CONDITIONS = 
{
    CRITICAL_DAMAGE =
    {
        name = "Critical Damage",
        desc = "A card that does critical damage does double the usual damage, and has {PIERCING}.",
        hidden = true,
        priority = 1,
        OnPreDamage = function( self, damage, attacker, battle, source, piercing )
            if source == nil then
                return damage
            end
            local card
            if is_instance( source, Battle.Card ) then
                card = source
            elseif is_instance( source, Battle.Attack ) then
                card = source.card
            end
            if (card) then
                return damage * 2
            end
        
            return damage
        end,
    },
}

for id, def in pairs( CONDITIONS ) do
    Content.AddBattleCondition( id, def )
end
--[[
local FEATURES =
{
    
}

for id, data in pairs( FEATURES ) do
    local def = BattleFeatureDef(id, data)
    Content.AddBattleCardFeature(id, def)
end
--]]