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

local function ConditionalInclusion(condition)
    local returnF = function( self, card, source_deck, source_idx, target_deck, target_idx )
        if card == self and target_deck == self.engine:GetHandDeck() then
            if not condition(card, self.engine) then
                self.engine:ExpendCard(card)
                self.engine:DrawCards(1,false)
            end
        end
    end
    return returnF
    
end

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
        flavour = "Think the cards already have a lot of RNG built in it? Well think again.",

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
        icon = "battle/kick.tex",
        flavour = "'Now you've gone too far.'",
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
                if (not self.must_be_humanoid) or hitTarget.agent:IsSentient() then
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
        flavour = "'How the Hesh are you able to provoke drones and automechs?'",

        must_be_humanoid = false,
    },
    ailment_storm =
    {
        name = "Ailment Storm",
        desc = "{MULTILEVEL}(Level {2})\nEvery time this card levels up, choose from {1} debuffs and add that effect to this card.",
        desc_fn = function( self, fmt_str )
            if self.userdata.applied_features and #self.userdata.applied_features then
                local applyString = "{1} {{2}}"
                local totalApplyString = {}
                for debuff_id, debuff_amt in pairs(self.userdata.applied_features) do
                    table.insert(totalApplyString, loc.format((#totalApplyString > 0 and ", " or "Apply ").. applyString, debuff_amt, debuff_id))
                end
                return loc.format( fmt_str .. "\n{3}.", self.debuff_choices, self.userdata.upgraded_times or 0, table.concat(totalApplyString))
            else
                return loc.format( fmt_str, self.debuff_choices, self.userdata.upgraded_times or 0 )
            end
        end,
        anim = "whip",
        icon = "battle/cataclysm.tex",
        flavour = "'Ok, you hit me. What does that even do?'\n" ..
            "'It barely tickles me.'\n" ..
            "'Ok it's starting to get a bit annoying.'\n" ..
            "'Ow now it's starting to hurt.'\n" ..
            "'Ow stop it!'\n" ..
            "'PLEASE STOP! YOU ARE KILLING ME!'\n" ..
            "'AAAAAAAHHHHHHHHHH'",
        target_type = TARGET_TYPE.ENEMY,
        manual_desc = true,

        min_damage = 3,
        max_damage = 3,

        rarity = CARD_RARITY.RARE,
        cost = 1,
        max_xp = 5,
        flags = CARD_FLAGS.MELEE | CARD_FLAGS.HATCH,

        additional_features =
        {
            ["WOUND"] = 2,
            ["CRIPPLE"] = 2,
            ["STAGGER"] = 3,
            -- For some reason weakpoint is always reduced by 1 when using this attack, and it doesn't double the damage.
            ["WEAK_POINT"] = 2,
            ["EXPOSED"] = 2,
            ["MARK"] = 3,
            ["BLEED"] = 4,
            ["BURN"] = 4,
            ["SCORCHED"] = 2,
            ["RICOCHET"] = 3,
            ["SCANNED"] = 1,
            ["dread"] = 2,
        },
        debuff_choices = 3,
        hatch = true,
        hatch_fn = function( self, battle )
            self.userdata.xp = 0
            self.userdata.upgraded_times = (self.userdata.upgraded_times or 0) + 1
            if not self.userdata.applied_features then
                self.userdata.applied_features = {}
            end
            -- This is to make sure that no duplicates until it is too late.
            local available_upgrades = {}
            for debuff_id, debuff_amt in pairs(self.additional_features) do
                if not self.userdata.applied_features[debuff_id] then
                    available_upgrades[debuff_id] = debuff_amt
                end
            end
            ---[[
            -- Add options if everything has chosen at least once
            local EntryNumbers = function(table_entry)
                local count = 0
                for i, j in pairs(table_entry) do
                    count = count + 1

                end
                return count
            end
            while EntryNumbers(available_upgrades) < self.debuff_choices do
                local random_debuff = {}
                for debuff_id, debuff_amt in pairs(self.additional_features) do
                    if not available_upgrades[debuff_id] then
                        table.insert(random_debuff, debuff_id)
                    end
                end
                if #random_debuff > 0 then
                    local choice = random_debuff[math.random(#random_debuff)]
                    available_upgrades[choice] = math.ceil(self.additional_features[choice] * 0.5)
                end
            end
            --]]
            -- At this point there should be at least 3 choices.
            local cards = {}
            for debuff_id, debuff_amt in pairs(available_upgrades) do
                local choice_card = Battle.Card("ailment_storm_supplemental",self.owner)
                choice_card.debuff_name = debuff_id
                choice_card.add_stacks = debuff_amt
                choice_card.name = debuff_id
                table.insert(cards, choice_card)
            end
            -- Finally, present cards as improvised choice
            cards = table.multipick( cards, self.debuff_choices )
            battle:ImproviseCards( cards, 1 )
            
        end,
        OnPostResolve = function( self, battle, attack)
            if not self.userdata.applied_features then
                self.userdata.applied_features = {}
            end
            for i, hit in attack:Hits() do
                for debuff_id, debuff_amt in pairs(self.userdata.applied_features) do
                    hit.target:AddCondition(debuff_id,debuff_amt,self)
                end
            end
        end,
        event_handlers =
        {
            [BATTLE_EVENT.CARD_IMPROVISED] = function(self, card, battle)
                if not self.userdata.applied_features then
                    self.userdata.applied_features = {}
                end
                if card and card.debuff_name then
                    local picked_debuff = card.debuff_name
                    local picked_stacks = card.add_stacks
                    battle:ExpendCard(card)
                    self.userdata.applied_features[picked_debuff] = (self.userdata.applied_features[picked_debuff] or 0) + picked_stacks
                end
            end,
        }
    },
    ailment_storm_supplemental =
    {
        name = "Ailment Storm: Upgrade",
        desc = "Add \"Apply {1} {{2}}\" to this card as an upgrade.",
        desc_fn = function( self, fmt_str )
            return loc.format( fmt_str, self.add_stacks, self.debuff_name)
        end,
        icon = "battle/cataclysm.tex",
        debuff_name = "DEBUFF",
        add_stacks = 1,
        manual_desc = true,
        cost = 0,

        flags = CARD_FLAGS.UNPLAYABLE | CARD_FLAGS.MELEE,
        rarity = CARD_RARITY.UNIQUE,
        hide_in_cardex = true,
    },
    cover_fire = 
    {
        name = "Cover Fire",
        desc = "Apply {3} {DEFEND}.\nSpend up to {1} {CHARGE}: Apply {2} additional {DEFEND}.",
        desc_fn = function( self, fmt_str )
            return loc.format( fmt_str, self.max_charge_cost, self.additional_defend, self:CalculateDefendText(self.features.DEFEND))
        end,
        manual_desc = true,
        icon = "battle/suppressing_fire.tex",
        anim = "suppressing",

        rarity = CARD_RARITY.COMMON,
        cost = 1,
        max_xp = 6,
        flags = CARD_FLAGS.SKILL,
        target_type = TARGET_TYPE.FRIENDLY_OR_SELF,
        series = "ROOK",

        max_charge_cost = 1,
        additional_defend = 2,

        features =
        {
            DEFEND = 4,
        },

        OnPostResolve = function( self, battle, attack )
            local charge_count = 0
            local tracker = self.owner:GetCondition("lumin_tracker")
            if tracker then
                charge_count = tracker:GetCharges()
            end
            if charge_count > 0 then
                tracker:RemoveCharges(math.min(self.max_charge_cost, charge_count), self)
            end
        end,

        event_handlers =
        {
            [ BATTLE_EVENT.CALC_MODIFY_STACKS ] = function( self, acc, condition_id, fighter, card )
                if condition_id == "DEFEND" and card == self then
                    local charge_count = 0
                    local tracker = self.owner:GetCondition("lumin_tracker")
                    if tracker then
                        charge_count = tracker:GetCharges()
                    end
                    if charge_count > 0 then
                        acc:AddValue( math.min(charge_count, self.max_charge_cost) * self.additional_defend )
                    end
                end
            end,

        },
    },
    cover_fire_plus =
    {
        name = "Boosted Cover Fire",
        desc = "Apply {3} {DEFEND}.\nSpend up to {1} {CHARGE}: Apply <#UPGRADE>{2}</> additional {DEFEND}.",
        additional_defend = 5,
    },
    cover_fire_plus2 =
    {
        name = "Enhanced Cover Fire",
        desc = "Apply {3} {DEFEND}.\nSpend up to <#UPGRADE>{1}</> {CHARGE}: Apply {2} additional {DEFEND}.",
        max_charge_cost = 2,
    },
    baton_pass =
    {
        name = "Baton Pass",
        desc = "Target ally immediately take their action and prepare a new one.\n{CONDITIONAL_INCLUSION}: There are at least 1 active ally on the team.",
        anim = "call_in",
        icon = "negotiation/empathy.tex",

        rarity = CARD_RARITY.UNCOMMON,
        cost = 1,
        max_xp = 6,
        flags = CARD_FLAGS.SKILL | CARD_FLAGS.EXPEND,
        target_type = TARGET_TYPE.FRIENDLY,
        CanPlayCard = function( self, battle, target )
            return target == nil or target:IsActive(), "MUST BE AN ACTIVE FIGHTER"
        end,

        playTimes = 1,

        OnPostResolve = function( self, battle, attack )
            for i = 1,self.playTimes do
                for i, hit in attack:Hits() do
                    if hit.target:GetConditionStacks("STUN") == 0 then
                        hit.target:PlayBehaviour()
                        hit.target.last_turn = battle:GetTurns() - 1
                        hit.target:PrepareTurn()
                    else
                        hit.target:RemoveCondition("STUN")
                    end
                end
            end
        end,
        event_handlers =
        {
            [ BATTLE_EVENT.CARD_MOVED ] = ConditionalInclusion(
                function(card,battle)
                    return #(card.owner:GetTeam().fighters) > 1
                end
            ),
        },
    },
    baton_pass_plus =
    {
        name = "Enduring Baton Pass",
        flags = CARD_FLAGS.SKILL,
    },
    baton_pass_plus2 =
    {
        name = "Boosted Baton Pass",
        desc = "Target ally immediately take <#UPGRADE>two of</> their action and prepare a new one.\n{CONDITIONAL_INCLUSION}: There are at least 1 active ally on the team.",
        playTimes = 2,

    }
}

for i, id, data in sorted_pairs(attacks) do
    if not data.series then
        data.series = CARD_SERIES.GENERAL
    end
    local basic_id = data.base_id or id:match( "(.*)_plus.*$" ) or id:match( "(.*)_upgraded[%w]*$") or id:match( "(.*)_supplemental.*$" )
    if CONFIG.enabled_cards[id] or CONFIG.enabled_cards[basic_id] then
        Content.AddBattleCard( id, data )
    end
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
---[[
local FEATURES =
{
    MULTILEVEL =
    {
        name = "Multi-level",
        desc = "This card can level up multiple times.",
    },
    CONDITIONAL_INCLUSION =
    {
        name = "Conditional Inclusion",
        desc = "This card is included only after certain conditions are met.\nIf those conditions are not met when this card is drawn, {EXPEND} this card and a replacement card is drawn."
    },
}

for id, data in pairs( FEATURES ) do
    local def = BattleFeatureDef(id, data)
    Content.AddBattleCardFeature(id, def)
end
--]]