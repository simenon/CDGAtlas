--[[
	Veteran icon texture : EsoUI/Art/Progression/veteranIcon_large.dds
	ZO_MenuBar_OnInitialized
]]--
local CDGBD = ZO_Object:Subclass()

local CDGBossDrops = {
	general = {
		addonName = "CDGBossDrops"
	},
	window = {
		ID = nil
	},
	defaults = {}
}

local LOOTCOLOR = {
	JUNK = "C3C3C3",
	NORMAL = "FFFFFF",
	FINE = "2DC50E",
	SUPERIOR = "3A92FF",
	EPIC = "A02EF7",
	LEGENDARY = "EECA2A"
}

local CDGBossDrops_SV = {}

local function knownZone(zone)
	if CDGBDData[zone] then
		return true
	else
		return false
	end
end

local function addLabel(name, text, xOffSet, yOffSet)
	local label = WINDOW_MANAGER:GetControlByName(name)

	if not label then
		label = WINDOW_MANAGER:CreateControl(name, CDGBossDrops.window.ID, CT_LABEL)
	end

	label:SetWidth(300)
	label:SetAnchor(TOPLEFT, lastLabel, TOPLEFT, xOffSet , yOffSet)
	label:SetFont("EsoUi/Common/Fonts/Univers57.otf|20|")
	label:SetText(text)
	label:SetHidden( false )
	label:SetMouseEnabled(false)
	label:SetHandler("OnMouseEnter", function(self, ...) end) 
	label:SetHandler("OnMouseExit", function(self, ...) end) 
end

local function addLootLabel(name, text, xOffSet, yOffSet)
	local label = WINDOW_MANAGER:GetControlByName(name)

	if not label then
		label = WINDOW_MANAGER:CreateControl(name, CDGBossDrops.window.ID, CT_LABEL)
	end

	label:SetWidth(300)
	label:SetAnchor(TOPLEFT, lastLabel, TOPLEFT, xOffSet , yOffSet)
	label:SetFont("EsoUi/Common/Fonts/Univers57.otf|16|")
	label:SetText(text)
	label:SetMouseEnabled(true)
	label:SetHidden( false )
	label:SetHandler("OnMouseEnter", function(self, ...) 
		ZO_PopupTooltip_SetLink(label:GetText()) 
	end) 
	label:SetHandler("OnMouseExit", function(self, ...) 
		ZO_PopupTooltip_Hide()
	end) 
end

local function showUI()
		local currentZone = GetMapName()
		if knownZone(currentZone) then			

			local xOffSet = 32
			local yOffSet = 32
			local labelIdx = 0			
			local labelName = "CDGBD".."Label"..labelIdx			
			local dataSource = CDGBDData[currentZone]["NORMAL"]
			if IsUnitUsingVeteranDifficulty("player") then
				dataSource = CDGBDData[currentZone]["VETERAN"]
			end
			for _, v in ipairs(dataSource["BOSS"]) do
				labelIdx = labelIdx + 1
				labelName = "CDGBD".."Label"..labelIdx
				addLabel(labelName, v["NAME"], xOffSet, yOffSet )
				yOffSet = yOffSet + 30
				for _, x in ipairs(v["DROPS"]) do
					labelIdx = labelIdx + 1
					labelName = "CDGBD".."Label"..labelIdx

					addLootLabel(labelName, x, xOffSet + 22, yOffSet)
					yOffSet = yOffSet + 22
		
				end
				yOffSet = yOffSet + 8
			end
		end
end 

local function hideUI()
	-- 
	-- Iterate over all the children and remove them somehow, actually we should reset them to blank state
	-- name like label_1..n
	--
	local numChildren = CDGBossDrops.window.ID:GetNumChildren()
	for i = 1, numChildren do
		local child = CDGBossDrops.window.ID:GetChild(i) 
		if child then
			child:SetHidden( true )
		end
	end

end

local function createUI()
	if CDGBossDrops.window.ID == nil then
		x,y = ZO_WorldMap:GetDimensions()

		CDGBossDrops.window.ID = WINDOW_MANAGER:CreateTopLevelWindow(nil)
		CDGBossDrops.window.ID:SetMouseEnabled(true)		
		CDGBossDrops.window.ID:SetMovable( false )
		CDGBossDrops.window.ID:SetClampedToScreen(true)
		CDGBossDrops.window.ID:SetDimensions( 400, y )
		CDGBossDrops.window.ID:SetAnchor( TOPLEFT, GuiRoot, TOPLEFT, 0, 200 )
		CDGBossDrops.window.ID:SetHidden( true )	
		--
		--	Derive the background from the default Left Panel BG
		--	
		CDGBossDrops.window.BACKDROP = WINDOW_MANAGER:CreateControlFromVirtual(nil, CDGBossDrops.window.ID, "ZO_LeftPanelBG")
		CDGBossDrops.window.BACKDROP:SetAnchorFill(CDGBossDrops.window.ID)
		--
		-- Add to the world map
		--
		local fragment = ZO_SimpleSceneFragment:New( CDGBossDrops.window.ID )
		SCENE_MANAGER:GetScene("worldMap"):AddFragment( fragment )	
		--
		-- Set Handlers for display and hide functionality
		--
		CDGBossDrops.window.ID:SetHandler( "OnShow", function(self, ...)
			--
			-- Override the default scene manager behavior and dont show if
			-- we dont know this zone as a boss zone
			--
			if not knownZone(GetMapName()) then
				CDGBossDrops.window.ID:SetHidden( true )
			else
				showUI()
			end
		end )

		CDGBossDrops.window.ID:SetHandler( "OnHide", function(self, ...)  			
			hideUI()
		end )

		local buttonData = 
		{ 
			descriptor = "CDGBDButton",
		  	normal = "EsoUI/Art/mainmenu/menubar_journal_up.dds",
            pressed = "EsoUI/Art/mainmenu/menubar_journal_down.dds",
            disabled = "EsoUI/Art/mainmenu/menubar_journal_disabled.dds",
            highlight = "EsoUI/Art/mainmenu/menubar_journal_over.dds",
            callback = function(...) end,
            helpMessage = "help",
            categoryName = "doh",
            tooltipText = "efef"

        }

		local control = WINDOW_MANAGER:GetControlByName("ZO_WorldMapInfoMenuBar")

		local button = ZO_MenuBar_AddButton(control, buttonData)
		SetTooltipText(InformationTooltip, "test")	
		--button:SetTooltipText(InformationTooltip, zo_strformat(SI_MENU_BAR_TOOLTIP, "test"))
		--button:SetTooltipText(InformationTooltip, "test")		

	end
end

function CDGBD:EVENT_ADD_ON_LOADED(eventCode, addOnName, ...)
	if addOnName == "CDGBossDrops" then
		CDGBossDrops_SV = ZO_SavedVars:New("CDGBossDrops_SavedVariables", 1, nil, {}) 

		createUI()

		d("|cFF2222CrazyDutchGuy's|r Boss Drops |c0066990.1|r Loaded")
	end
end

function CDGBD_OnInitialized()
	EVENT_MANAGER:RegisterForEvent("CDGBossDrops", EVENT_ADD_ON_LOADED, function(...) CDGBD:EVENT_ADD_ON_LOADED(...) end )		
end
