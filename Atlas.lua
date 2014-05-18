local ATLAS = ZO_Object:Subclass()
ATLAS.addonName = "Atlas"

local ATLAS_LOCATION_DATA = 1
local ATLAS_DROPS_BOSS_DATA = 2
local ATLAS_DROPS_DROP_DATA = 3

ZO_CreateStringId("ATLAS_LOOT_NAME", "ATLAS LOOT")

local ATLAS_ScrollList = nil
local ATLAS_LootWindow = nil
local ATLAS_Map = nil
local ATLAS_ScrollList_Drops = nil

local ATLAS_MAP_TEXTURES = 
{
	["Fungal Grotto"]     = {"/art/maps/stonefalls/fungalgrotto_base_", 3, 3},
	["Vaults of Madness"] = {"/art/maps/coldharbor/vaultsofmadness1_base_", 3, 3},
	--["Vaults of Madness 2"] = {"/art/maps/coldharbor/vaultsofmadness2_base_", 3, 3}, -- Exists but no difference with first level ?
	["Selene\'s Web"]     = {"/art/maps/reapersmarch/selenesweb_base_", 3, 3},
	["Spindleclutch"]     = {"/art/maps/glenumbra/spindleclutch_base_", 3, 3},
	["Blackheart Haven"]  = {"/art/maps/bangkorai/blackhearthavenarea1_base_", 3, 3},
	["Blackheart Haven 2"]  = {"/art/maps/bangkorai/blackhearthavenarea2_base_", 3, 3},
	["Blackheart Haven 3"]  = {"/art/maps/bangkorai/blackhearthavenarea3_base_", 3, 3},
	["Blackheart Haven 4"]  = {"/art/maps/bangkorai/blackhearthavenarea4_base_", 3, 3},
	["The Banished Cells"]  = {"/art/maps/auridon/thebanishedcells_base_", 3, 3},
	["Blessed Crucible"]  = {"/art/maps/therift/blessedcrucible1_base_", 3, 3},
	["Blessed Crucible 2"]  = {"/art/maps/therift/blessedcrucible2_base_", 3, 3},
	--["Blessed Crucible 3"]  = {"/art/maps/therift/blessedcrucible3_base_", 3, 3},
	--["Blessed Crucible 4"]  = {"/art/maps/therift/blessedcrucible4_base_", 3, 3},
	--["Blessed Crucible 5"]  = {"/art/maps/therift/blessedcrucible5_base_", 3, 3},
	--["Blessed Crucible 6"]  = {"/art/maps/therift/blessedcrucible6_base_", 3, 3},
	--["Blessed Crucible 7"]  = {"/art/maps/therift/blessedcrucible7_base_", 3, 3},
}

local ATLAS_MAP_TEXTURES_IN_USE = -1
local ATLAS_BOSS_LABELS_IN_USE = -1
local ATLAS_DROP_LABELS_IN_USE = -1

local function showAtlasLoot(zone)	
	local dataSource = ATLASData[zone]["NORMAL"]["BOSS"]
	if IsUnitUsingVeteranDifficulty("player") then
		dataSource = ATLASData[zone]["VETERAN"]["BOSS"]
	end 
	if dataSource then
	--
	-- Add data to the scrollList
	--
	local scrollData = ZO_ScrollList_GetDataList(ATLAS_ScrollList_Drops)
	ZO_ClearNumericallyIndexedTable(scrollData)

	for i, v in pairs(dataSource) do
		table.insert(scrollData, ZO_ScrollList_CreateDataEntry(ATLAS_DROPS_BOSS_DATA, {bossName = v["NAME"]})) 
		for i, v in ipairs(v["DROPS"]) do
			table.insert(scrollData, ZO_ScrollList_CreateDataEntry(ATLAS_DROPS_DROP_DATA, {ItemLink = zo_strformat("<<1>>",v)})) 
		end	
	end

	ZO_ScrollList_Commit(ATLAS_ScrollList_Drops)	
end
end

local function showAtlasWindows(toggle)	
	ATLAS_LootWindow:SetHidden( not toggle )
	ATLAS_Map:SetHidden( not toggle )
end

local function buildAtlasMap(zone)	
	--
	-- Blank out all previous textures
	--
	for i = 0, ATLAS_MAP_TEXTURES_IN_USE do		
		WINDOW_MANAGER:GetControlByName("AtlasMapTexture"..i):SetHidden(true)
	end
	--
	-- Rebuild the map textures
	--
	local map = ATLAS_MAP_TEXTURES[zone]
	if map then
		showAtlasWindows(true)
		for i = 0 , (map[2]*map[3]) - 1 do			
			local name = "AtlasMapTexture"..i
			local texture = WINDOW_MANAGER:GetControlByName(name)

			if not texture then
				texture = WINDOW_MANAGER:CreateControl(name, ATLAS_Map.bd, CT_TEXTURE)
			end
		
			texture:SetDimensions(270,270)  		
			texture:SetAnchor( TOPLEFT, ATLAS_Map, TOPLEFT, 270*(math.fmod(i,map[2])), 270*(math.floor(i/map[3])) )
			texture:SetTexture(map[1]..i..".dds") 			
			texture:SetHidden( false )			
			texture:SetDrawLayer(0)
			
		end
		if ATLAS_MAP_TEXTURES_IN_USE < ((map[2]*map[3]) - 1) then
			ATLAS_MAP_TEXTURES_IN_USE = ((map[2]*map[3]) - 1)
		end	
	else
		--
		-- hide everything
		--				
		showAtlasWindows(false)		
	end
	ZO_WorldMap:SetHidden( true )
end

local function createAtlasInterface()
	--
	-- Steal dimensions and anchor from similar object (location list)
	--
	local x,y = ZO_WorldMapLocations:GetDimensions()
	local isValidAnchor, point, relativeTo, relativePoint, offsetX, offsetY = ZO_WorldMapLocations:GetAnchor()
	--
	-- Define the toplevelwindow to hold the scrollList
	--
	local window = WINDOW_MANAGER:CreateTopLevelWindow(ATLAS.addonName.."TLW".."SL")
	window:SetMouseEnabled(true)		
	window:SetMovable( false )
	window:SetClampedToScreen(true)
	window:SetDimensions( x, y )
	window:SetAnchor( point, relativeTo, relativePoint, offsetX, offsetY )
	window:SetHidden( true )
	--
	-- Create the scrollList, but don't fill it yet.
	--	
	ATLAS_ScrollList = WINDOW_MANAGER:CreateControlFromVirtual("$(parent)ScrollList", window, "ZO_ScrollList")
	ATLAS_ScrollList:SetAnchorFill(ATLASTLW)
	--
	-- Add a datatype to the scrollList
	--
	ZO_ScrollList_Initialize(ATLAS_ScrollList)
	ZO_ScrollList_EnableHighlight(ATLAS_ScrollList, "ZO_ThinListHighlight")
	ZO_ScrollList_AddDataType(ATLAS_ScrollList, ATLAS_LOCATION_DATA, "AtlasLocationRow", 23, 
		function(control, data) 				
			local locationLabel = control:GetNamedChild("Location")

   			locationLabel:SetText(data.locationName) 
			locationLabel:SetEnabled( true )
			locationLabel:SetMouseEnabled( true )	
		end
	)
	--
	-- Add data to the scrollList
	--
	local scrollData = ZO_ScrollList_GetDataList(ATLAS_ScrollList)

	for i, v in pairs(ATLASData) do
		table.insert(scrollData, ZO_ScrollList_CreateDataEntry(ATLAS_LOCATION_DATA, {locationName = i}))       		
	end

	ZO_ScrollList_Commit(ATLAS_ScrollList)		
	--
	-- Create button for adding to the Rightpane
	--
	local buttonData = 
	{ 
		--descriptor = "AtlasRightPaneButton",
	  	normal = "EsoUI/Art/mainmenu/menubar_journal_up.dds",
        pressed = "EsoUI/Art/mainmenu/menubar_journal_down.dds",
        --disabled = "EsoUI/Art/mainmenu/menubar_journal_disabled.dds",
        highlight = "EsoUI/Art/mainmenu/menubar_journal_over.dds",                  
    }
    --
	-- Create a fragment from the window and add it to the modeBar of the WorldMap RightPane
	--
	local bossFragment = ZO_FadeSceneFragment:New(window) 
    WORLD_MAP_INFO.modeBar:Add(ATLAS_LOOT_NAME, {bossFragment}, buttonData)
    --
    -- Create a few preHookHandlers so that the map shows up back again when hidden
    --     
    ZO_PreHookHandler(window              , "OnHide", function() showAtlasWindows( false ) end)
    ZO_PreHookHandler(ZO_WorldMapLocations, "OnShow", function() ZO_WorldMap:SetHidden( false ) showAtlasWindows( false ) end)
    ZO_PreHookHandler(ZO_WorldMapFilters  , "OnShow", function() ZO_WorldMap:SetHidden( false ) showAtlasWindows( false ) end)
    ZO_PreHookHandler(ZO_WorldMapKey      , "OnShow", function() ZO_WorldMap:SetHidden( false ) showAtlasWindows( false ) end)
    ZO_PreHookHandler(ZO_WorldMapQuests   , "OnShow", function() ZO_WorldMap:SetHidden( false ) showAtlasWindows( false ) end)	
    ZO_PreHookHandler(window              , "OnShow", function() buildAtlasMap(GetMapName()) showAtlasLoot(GetMapName()) end)
    --
    -- Define a ToplevelWindow to attach to the WorldMap that holds the loot
    --
    local x,y = ZO_WorldMap:GetDimensions()	

    ATLAS_LootWindow = WINDOW_MANAGER:CreateTopLevelWindow(nil)
	ATLAS_LootWindow:SetMouseEnabled(true)		
	ATLAS_LootWindow:SetMovable( false )
	ATLAS_LootWindow:SetClampedToScreen(true)
	ATLAS_LootWindow:SetDimensions( x/2 , y )
	ATLAS_LootWindow:SetAnchor( TOPRIGHT, ZO_WorldMap, TOPLEFT, 0, 0 )
	ATLAS_LootWindow:SetHidden( true )

	ATLAS_LootWindow.bd = WINDOW_MANAGER:CreateControl(nil, ATLAS_LootWindow, CT_BACKDROP)
	ATLAS_LootWindow.bd:SetCenterTexture([[/esoui/art/chatwindow/chat_bg_center.dds]], 16, 1)
	ATLAS_LootWindow.bd:SetEdgeTexture([[/esoui/art/chatwindow/chat_bg_edge.dds]], 32, 32, 32, 0)
	ATLAS_LootWindow.bd:SetInsets(32,32,-32,-32)	
	ATLAS_LootWindow.bd:SetAnchorFill(ATLAS_LootWindow)

	local x,y = ATLAS_LootWindow:GetDimensions()	
	ATLAS_ScrollList_Drops = WINDOW_MANAGER:CreateControlFromVirtual("$(parent)ScrollList", ATLAS_LootWindow, "ZO_ScrollList")
	ATLAS_ScrollList_Drops:SetAnchor( TOPleft, ATLAS_LootWindow, TOPLEFT, 20, 40 )
	ATLAS_ScrollList_Drops:SetDimensions(x-40,y-80)
	--
	-- Add a datatype to the scrollList
	--
	ZO_ScrollList_Initialize(ATLAS_ScrollList_Drops)
	ZO_ScrollList_EnableHighlight(ATLAS_ScrollList_Drops, "ZO_ThinListHighlight")
	ZO_ScrollList_AddDataType(ATLAS_ScrollList_Drops, ATLAS_DROPS_BOSS_DATA, "AtlasDropsBossLocationRow", 23, 
		function(control, data) 				
			local bossLabel = control:GetNamedChild("BossName")

   			bossLabel:SetText(data.bossName) 
			bossLabel:SetEnabled( true )
			bossLabel:SetMouseEnabled( true )	
		end
	)
	ZO_ScrollList_AddDataType(ATLAS_ScrollList_Drops, ATLAS_DROPS_DROP_DATA, "AtlasDropsDropLocationRow", 23, 
		function(control, data) 				
			local Label = control:GetNamedChild("ItemLink")

   			Label:SetText(data.ItemLink) 
			Label:SetEnabled( true )
			Label:SetMouseEnabled( true )	
		end
	)
	
	--
	-- Define a ToplevelWindow that holds the map textures
	--
	local x,y = ZO_WorldMap:GetDimensions()	

    ATLAS_Map = WINDOW_MANAGER:CreateTopLevelWindow(nil)
	ATLAS_Map:SetMouseEnabled(true)		
	ATLAS_Map:SetMovable( false )
	ATLAS_Map:SetClampedToScreen(true)
	ATLAS_Map:SetDimensions( x , y )
	ATLAS_Map:SetAnchor( TOPLEFT, ZO_WorldMap, TOPLEFT, 0, 0 )
	ATLAS_Map:SetHidden( true )	
	--
	-- Define the Frame that goes around the map
	-- 
	ATLAS_Map.bd = WINDOW_MANAGER:CreateControl(nil, ATLAS_Map, CT_BACKDROP)	
	ATLAS_Map.bd:SetAnchorFill(ATLAS_Map)
	ATLAS_Map.bd:SetCenterColor(0,0,0,0)
	ATLAS_Map.bd:SetEdgeTexture("EsoUI/Art/WorldMap/worldmap_frame_edge.dds",128,16,0,0)
	ATLAS_Map.bd:SetInsets(16,16,-16,-16)	
	ATLAS_Map.bd:SetDrawLayer(1)
	--
	-- Make the frame dirty
	--
	ATLAS_Map.bd.texturetop = WINDOW_MANAGER:CreateControlFromVirtual(nil, ATLAS_Map, "ZO_WorldMapFrameMunge")
	ATLAS_Map.bd.texturetop:SetAnchor( TOPLEFT, ATLAS_Map.bd, TOPLEFT, 4, 0 )
	ATLAS_Map.bd.texturetop:SetDimensions( x-8, 2)	
	
	ATLAS_Map.bd.textureleft = WINDOW_MANAGER:CreateControlFromVirtual(nil, ATLAS_Map, "ZO_WorldMapFrameMunge")
	ATLAS_Map.bd.textureleft:SetAnchor( TOPLEFT, ATLAS_Map.bd, TOPLEFT, 0, 4 )
	ATLAS_Map.bd.textureleft:SetDimensions( 2, y-8)

	ATLAS_Map.bd.textureright = WINDOW_MANAGER:CreateControlFromVirtual(nil, ATLAS_Map, "ZO_WorldMapFrameMunge")
	ATLAS_Map.bd.textureright:SetAnchor( TOPRIGHT, ATLAS_Map.bd, TOPRIGHT, 0, 4 )
	ATLAS_Map.bd.textureright:SetDimensions( 2, y-8)

	ATLAS_Map.bd.texturebottom = WINDOW_MANAGER:CreateControlFromVirtual(nil, ATLAS_Map, "ZO_WorldMapFrameMunge")
	ATLAS_Map.bd.texturebottom:SetAnchor( BOTTOMLEFT, ATLAS_Map.bd, BOTTOMLEFT, 4, 0 )
	ATLAS_Map.bd.texturebottom:SetDimensions( x-8, 2)	
end

function ATLAS_LocationRowLocation_OnMouseUp(self, button, upInside)
	ZO_WorldMap:SetHidden( true )
	showAtlasWindows( true )
	buildAtlasMap(self:GetText())
	showAtlasLoot(self:GetText())
end

function ATLAS:EVENT_ADD_ON_LOADED(eventCode, addonName, ...)
	if addonName == ATLAS.addonName then		
		createAtlasInterface()		
		--		
		-- Unregister events we are not using anymore
		--
		EVENT_MANAGER:UnregisterForEvent( ATLAS.addonName, EVENT_ADD_ON_LOADED )			
	end
end

function ATLAS_OnInitialized()
	EVENT_MANAGER:RegisterForEvent(ATLAS.addonName, EVENT_ADD_ON_LOADED, function(...) ATLAS:EVENT_ADD_ON_LOADED(...) end )		
end
