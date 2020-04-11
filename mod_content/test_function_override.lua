require "ui/widgets/screen"
require "ui/widgets/label"
require "ui/widgets/image"
require "ui/widgets/panelbutton"
require "ui/widgets/plax_nameplate"
require "ui/widgets/imagebutton"
require "ui/widgets/locationbutton"
require "ui/widgets/plax"
require "encounter/encounter"
local LocationScreen = CLASSES["Screen.LocationScreen"]

local function GetAgentSortPriority(a)
    if a.quest_membership and next(a.quest_membership) then
        return 3
    end

    if a:GetBrain():IsOnDuty() then
        return 2.5
    end
    
    if a:GetRoleAtLocation() then
        return 2
    end

    if a:IsSentient() then
        return 1
    end

    return 0.5
end


local function agent_sort_fn(a,b)
    return GetAgentSortPriority(b) < GetAgentSortPriority(a)
end

LocationScreen.RefreshPlaxClickables = function( self, force )

    local convo = TheGame:FE():FindScreen( Screen.ConversationScreen )
    local content = self.location:GetContent()
    if not force and convo and not content.show_agents then
        return
    end

    -- Remove invalid plax slots.
    for slot_id, slot in self.plax:Slots() do
        if slot.agent then
            local agent_role = slot.agent:GetRoleAtLocation()
            if slot.agent:GetLocation() ~= self.location or slot.role ~= agent_role then
                self.plax:ClearSlot( slot_id )
            end
        end
    end
    
    local can_show_new_agents = force or convo == nil
    if can_show_new_agents then
        local sorted_agents = {}

        for i, agent in self.location:Agents( ) do
            local should_show = true
            --[[
            if agent:IsInPlayerParty() and not self.location:GetContent().show_player then
                should_show = false
            end
            --]]
            if not agent:IsInPlayerParty() and not agent:CanTalk() then
                should_show = false
            end

            if should_show then
                table.insert(sorted_agents, agent)
            end
        end
        
        table.sort(sorted_agents, agent_sort_fn)

        for _,agent in ipairs(sorted_agents) do
            local character_widget = self:AddAgentToSlot( agent )
            if character_widget and not agent:IsPlayer() and agent:CanTalk() then
                local fn = function() self:EnterConvo( agent ) end
                character_widget:SetClickFn( fn )
            	local slot = self.plax:GetAgentSlot( agent )
            	local nameplate = slot and self.plax:GetSlotLabel( slot and slot.slot_id )
            	if nameplate then
                        character_widget:SetOnHoverFn( function(hovered) 
                            if not nameplate.removed then
                                nameplate:SetCharacterFocused( hovered or self.current_hover_agent == agent ) 
                            end
                        end)
            	end
			end
        end
    end
end