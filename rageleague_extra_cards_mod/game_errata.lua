local CONTENT = Content.internal

local stagger_condition = CONTENT.BATTLE_CONDITIONS[ "STAGGER" ]
if stagger_condition then
    stagger_condition.ctype = CTYPE.DEBUFF
end

local vendetta_condition = CONTENT.BATTLE_CONDITIONS["VENDETTA"]
if vendetta_condition then
    vendetta_condition.desc_fn = function( self, fmt_str, battle )
        if battle then
            if self.owner then
                return loc.format(fmt_str, self.owner:GetName(), self.battle:GetPlayerFighter().agent:GetName() )
            end
        end
        return LOC "Will always attack the player in combat."
    end
end