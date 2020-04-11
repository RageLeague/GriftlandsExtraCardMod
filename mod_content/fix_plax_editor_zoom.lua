require "ui/widgets/screen"
require "ui/widgets/plax"
require "ui/widgets/checkbox"
require "ui/widgets/polyline"

require "ui/widgets/slider"
require "ui/screens/plaxdemoscreen"
require "ui/screens/fightscreen"
require "ui/screens/debugtoolsmenu"

local debug_menus = require "debug/debug_menus"
local DebugUtil = require "debug/debug_util"
local posedefs = require "content/character_pose_defs"
local path = require "util/filepath"
local sColourSettings = require "content/colour_settings"


local NODE_TYPE = Widget.Plax.NODE_TYPE
local DEFAULT_PROP_TEX = "debug/default_plax_prop.tex"

local day_phases = {DAY_PHASE.DAY, DAY_PHASE.NIGHT }
local day_phase_txt = {"Day", "Night"}

local game_modes = {GAME_MODE.CONVERSATION, GAME_MODE.BATTLE }
local game_mode_txt = {"Conversation", "Battle"}

local ASPECT_FRAMING = MakeBitField{ "CONVO", "BATTLE" }


local PlaxEditor = Screen.PlaxEditor--CLASSES["Screen.PlaxEditor"]
print("alloosea")
print(PlaxEditor.DeltaZoom)

function PlaxEditor:DeltaZoom(delta)
    print("Override function successful")
    -- Zoom in and out to the current mouse cursor position:
    local mx, my = TheGame:GetInput():GetMousePos()
    
    my = 768 - my

    local lx, ly = self:FindChild("SCALE"):TransformFromWorld(mx, my)
    --print("local pos = " .. lx .. ", " .. ly );


    local zoomfactor = clamp(1.0 + (delta * zoom_sensitivity), 0.5, 2.0);   -- Allow only 50%-200% size changes in one step
    self.zoom_scale = clamp((self.zoom_scale or 1.0) * zoomfactor, minZoom, maxZoom)    -- Clamp the modified zoom scale to minZoom and maxZoom
    self:FindChild("SCALE"):SetScale(self.zoom_scale)

    local lx2, ly2 = self:FindChild("SCALE"):TransformFromWorld(mx, my)
    local dx = (lx2 - lx) * self.zoom_scale;
    local dy = (ly2 - ly) * self.zoom_scale;

    self:SetPanCoordinates((self.pan_x or 0) + dx, (self.pan_y or 0) + dy)
end