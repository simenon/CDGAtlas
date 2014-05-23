local ATLAS = ZO_Object:Subclass()
ATLAS.addonName = "Atlas"

local ATLAS_LOCATION_DATA = 1
local ATLAS_DROPS_BOSS_DATA = 2
local ATLAS_DROPS_DROP_DATA = 3

ZO_CreateStringId("ATLAS_LOOT_NAME", "ATLAS LOOT")

local ATLAS_ScrollList_SORT_KEYS =
{
    ["locationName"] = { },
    ["factionIcon"] = {  tiebreaker = "locationName" },
    ["NormalLevel"] = {  tiebreaker = "locationName" },
    ["VeteranLevel"] = {  tiebreaker = "locationName" },
}
--
-- list of control object references
--
local ATLAS_TLW = nil
local ATLAS_LootWindow = nil
local ATLAS_Map = nil
local ATLAS_RIGHTPANE = nil
--
-- more constants
--
local ATLAS_MAP_SCALE = 0.8

local DAGGERFALL = "D"
local EBONHEART  = "E"
local ALDMERI    = "A"
local UNKNOWN	 = "?"
--
-- Some variables that should be saved ...
--
ATLAS.isVeteranDifficulty = true
ATLAS.lastZoneRequested = nil
ATLAS.chatWasMinimized = false

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
	["Wayrest Sewers"] = {"/art/maps/stormhaven/wayrestsewers_base_", 3, 3},
	["Darkshade Caverns"] = {"/art/maps/deshaan/darkshadecaverns_base_",3,3},
	["Elden Hollow"] = {"/art/maps/grahtwood/eldenhollow_base_",3,3},
	["Arx Corinium"] = {"/art/maps/shadowfen/arxcorinium_base_",3,3},
	["Crypt of Hearts"] = {"/art/maps/rivenspire/cryptofhearts_base_",3,3},
	["Volenfell"] = {"/art/maps/alikr/volenfell_base_",3,3},
	["Tempest Island"] = {"/art/maps/malabaltor/tempestisland_base_",3,3},
	["City of Ash"] = {"/art/maps/greenshade/cityofashmain_base_",3,3},
	["Direfrost Keep"] = {"/art/maps/eastmarch/direfrostkeep_base_",3,3},
}

local ATLAS_MAP_TEXTURES_IN_USE = -1
local ATLAS_MAP_PINS_IN_USE = -1

local function showAtlasLoot(zone)	
	if ATLASData[zone] then		
		local dataSource = ATLASData[zone]["NORMAL"]["BOSS"]
		if ATLAS.isVeteranDifficulty then
			dataSource = ATLASData[zone]["VETERAN"]["BOSS"]
		end 
		if dataSource then
			--
			-- Add data to the scrollList
			--
			local scrollData = ZO_ScrollList_GetDataList(ATLAS_LootWindow.scrollList)
			ZO_ClearNumericallyIndexedTable(scrollData)

			for i, v in ipairs(dataSource) do
				table.insert(scrollData, ZO_ScrollList_CreateDataEntry(ATLAS_DROPS_BOSS_DATA, {bossName = v["NAME"]})) 
				for i, v in ipairs(v["DROPS"]) do
					table.insert(scrollData, ZO_ScrollList_CreateDataEntry(ATLAS_DROPS_DROP_DATA, {ItemLink = zo_strformat("<<1>>",v)})) 
				end	
			end
			if #dataSource <= 0 then
				table.insert(scrollData, ZO_ScrollList_CreateDataEntry(ATLAS_DROPS_BOSS_DATA, {bossName = "No Loot Known !"})) 
			end 
			ZO_ScrollList_Commit(ATLAS_LootWindow.scrollList)	
		end
		ATLAS.lastZoneRequested = zone
	end
end

local function refreshAtlasLoot()
	if ATLAS.lastZoneRequested then
		showAtlasLoot(ATLAS.lastZoneRequested)
	end
end

local function showAtlasWindows(toggle)	
	ATLAS_LootWindow:SetHidden( not toggle )
	ATLAS_Map:SetHidden( not toggle )
	ATLAS_TLW:SetHidden( not toggle )
	if not toggle then
		if not ATLAS.chatWasMinimized then
			CHAT_SYSTEM:Maximize()
		end
	end
end

local function createAtlasMapPins(parent, mapPinId, text, x, y)
	local mapPin = WINDOW_MANAGER:GetControlByName("ATLASMapPin"..mapPinId)
	if not mapPin then
		mapPin = WINDOW_MANAGER:CreateControl("ATLASMapPin"..mapPinId,  parent, CT_TEXTURE)
	end
  	mapPin:SetDimensions(32,32)
  	mapPin:SetTexture("/esoui/art/icons/poi/poi_groupboss_complete.dds")
  	mapPin:SetAnchor(TOPLEFT, parent, TOPLEFT, x, y)  
  	mapPin:SetHidden(false)	
  	mapPin:SetMouseEnabled(true)

  	mapPin:SetHandler("OnMouseEnter", function() 
  			InitializeTooltip(InformationTooltip, mapPin, BOTTOM, 0, 0)
  			InformationTooltip:AddLine(text, "", ZO_TOOLTIP_DEFAULT_COLOR:UnpackRGB())
  			InformationTooltip:SetHidden(false) 
  		end )
  	mapPin:SetHandler("OnMouseExit", function() 
  			InformationTooltip:ClearLines()
  			InformationTooltip:SetHidden(true) 
  		end )	
end

local function hideAtlasMapPin(mapPinId)
	WINDOW_MANAGER:GetControlByName("ATLASMapPin"..mapPinId):SetHidden(true)
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
	local x,y = ATLAS_Map:GetDimensions()
	--local tileSize = 270 * ATLAS_MAP_SCALE

	if map then
		showAtlasWindows(true)
		for i = 0 , (map[2]*map[3]) - 1 do			
			local name = "AtlasMapTexture"..i
			local texture = WINDOW_MANAGER:GetControlByName(name)

			if not texture then
				texture = WINDOW_MANAGER:CreateControl(name, ATLAS_Map.bd, CT_TEXTURE)
			end
		
			texture:SetDimensions(x/map[2],y/map[3])  		
			texture:SetAnchor( TOPLEFT, ATLAS_Map, TOPLEFT, (x/map[2])*(math.fmod(i,map[2])), (y/map[3])*(math.floor(i/map[3])) )
			texture:SetTexture(map[1]..i..".dds") 			
			texture:SetHidden( false )			
			texture:SetDrawLayer(0)
			
		end
		if ATLAS_MAP_TEXTURES_IN_USE < ((map[2]*map[3]) - 1) then
			ATLAS_MAP_TEXTURES_IN_USE = ((map[2]*map[3]) - 1)
		end	

		--
		-- Add map pins for bosses (Needs rewrite ....)
		--
		local dataSource = ATLASData[zone]["NORMAL"]["BOSS"]
		if ATLAS.isVeteranDifficulty then
			dataSource = ATLASData[zone]["VETERAN"]["BOSS"]
		end 
		local mapPinsMade = 0
		for i,v in ipairs(dataSource) do
			if v["LOCATION"]["X"] > 0 or v["LOCATION"]["Y"] > 0 then
	   			createAtlasMapPins(ATLAS_Map.bd, i, v["NAME"], v["LOCATION"]["X"]*x, v["LOCATION"]["Y"]*y)
	   			mapPinsMade = mapPinsMade + 1
	   		end
		end
		
		if ATLAS_MAP_PINS_IN_USE < mapPinsMade then
			ATLAS_MAP_PINS_IN_USE = mapPinsMade
		end

		for i = mapPinsMade + 1, ATLAS_MAP_PINS_IN_USE  do
			hideAtlasMapPin(i)			
		end
	else
		--
		-- hide everything
		--				
		showAtlasWindows(false)		
	end	
	--
	-- Adjust Ui related to zone
	--
	if ATLASData[zone] then
		local titleText = zone
		if ATLAS.isVeteranDifficulty then
			if ATLASData[zone]["VETERAN"]["INFO"] then
				titleText = titleText .. " [V"..ATLASData[zone]["VETERAN"]["INFO"]["MINLEVEL"].."-V"..ATLASData[zone]["VETERAN"]["INFO"]["MAXLEVEL"].."]"
			end
		else
			if ATLASData[zone]["NORMAL"]["INFO"] then
				titleText = titleText .. " ["..ATLASData[zone]["NORMAL"]["INFO"]["MINLEVEL"].."-"..ATLASData[zone]["NORMAL"]["INFO"]["MAXLEVEL"].."]"
			end
		end		
		ATLAS_Map.MapTitle:SetText(titleText)

		ATLAS_Map.MapTitleIcon:SetTexture("/esoui/art/icons/poi/poi_groupinstance_complete.dds")
		--ATLAS_Map.MapTitleIcon:SetTexture("/esoui/art/icons/poi/poi_groupdungeon_complete.dds")
    	--ATLAS_Map.MapTitleIcon:SetTexture("/esoui/art/icons/poi/poi_dungeon_complete.dds")  
		if ATLASData[zone]["INFO"]["FACTION"] == "E" then
			ATLAS_TLW.factionTextureLeft:SetTexture("/esoui/art/campaign/overview_scoringbg_ebonheart_left.dds")
			ATLAS_TLW.factionTextureRight:SetTexture("/esoui/art/campaign/overview_scoringbg_ebonheart_right.dds")
			ATLAS_LootWindow.iconTexture:SetTexture("/esoui/art/guild/banner_ebonheart.dds")			
			ATLAS_LootWindow.iconTexture:SetHidden(false)
			
			ATLAS_TLW.FactionHeaderIconTexture:SetTexture("/esoui/art/compass/ava_borderkeep_pin_ebonheart.dds")
			--ATLAS_TLW.FactionHeaderIconTexture:SetTexture("/esoui/art/campaign/overview_allianceicon_ebonheart.dds")
			ATLAS_TLW.FactionHeaderIconTexture:SetHidden(false)				
		elseif ATLASData[zone]["INFO"]["FACTION"] == "D" then
			ATLAS_TLW.factionTextureLeft:SetTexture("/esoui/art/campaign/overview_scoringbg_daggerfall_left.dds")
			ATLAS_TLW.factionTextureRight:SetTexture("/esoui/art/campaign/overview_scoringbg_daggerfall_right.dds")
			ATLAS_LootWindow.iconTexture:SetTexture("/esoui/art/guild/banner_daggerfall.dds")
			ATLAS_LootWindow.iconTexture:SetHidden(false)
			ATLAS_TLW.FactionHeaderIconTexture:SetTexture("/esoui/art/compass/ava_borderkeep_pin_daggerfall.dds")
			--ATLAS_TLW.FactionHeaderIconTexture:SetTexture("/esoui/art/campaign/overview_allianceicon_daggefall.dds")
			ATLAS_TLW.FactionHeaderIconTexture:SetHidden(false)				
		elseif ATLASData[zone]["INFO"]["FACTION"] == "A" then
			ATLAS_TLW.factionTextureLeft:SetTexture("/esoui/art/campaign/overview_scoringbg_aldmeri_left.dds")
			ATLAS_TLW.factionTextureRight:SetTexture("/esoui/art/campaign/overview_scoringbg_aldmeri_right.dds")
			ATLAS_LootWindow.iconTexture:SetTexture("/esoui/art/guild/banner_aldmeri.dds")
			ATLAS_LootWindow.iconTexture:SetHidden(false)
			ATLAS_TLW.FactionHeaderIconTexture:SetTexture("/esoui/art/compass/ava_borderkeep_pin_aldmeri.dds")
			--ATLAS_TLW.FactionHeaderIconTexture:SetTexture("/esoui/art/campaign/overview_allianceicon_aldmeri.dds")
			ATLAS_TLW.FactionHeaderIconTexture:SetHidden(false)				
		else
			ATLAS_TLW.factionTextureLeft:SetTexture("Atlas/art/background_common_left.dds")
			ATLAS_TLW.factionTextureRight:SetTexture("Atlas/art/background_common_right.dds")							
			--ATLAS_LootWindow.iconTexture:SetTexture("")
			ATLAS_LootWindow.iconTexture:SetHidden(true)
			--ATLAS_TLW.FactionHeaderIconTexture:SetTexture("")
			ATLAS_TLW.FactionHeaderIconTexture:SetHidden(true)		
		end		
	end
	ZO_WorldMap:SetHidden( true )	
end

local function createAtlasRIghtPane()
	--
	-- Steal dimensions and anchor from similar object (location list)
	--
	local x,y = ZO_WorldMapLocations:GetDimensions()
	local isValidAnchor, point, relativeTo, relativePoint, offsetX, offsetY = ZO_WorldMapLocations:GetAnchor()
	--
	-- Define the toplevelwindow to hold the scrollList
	--
	ATLAS_RIGHTPANE = WINDOW_MANAGER:CreateTopLevelWindow(ATLAS.addonName.."TLW".."RIGHTPANE")
	ATLAS_RIGHTPANE:SetMouseEnabled(true)		
	ATLAS_RIGHTPANE:SetMovable( false )
	ATLAS_RIGHTPANE:SetClampedToScreen(true)
	ATLAS_RIGHTPANE:SetDimensions( x, y )
	ATLAS_RIGHTPANE:SetAnchor( point, relativeTo, relativePoint, offsetX, offsetY )
	ATLAS_RIGHTPANE:SetHidden( true )
	--
	-- Create Sort Headers
	--
	ATLAS_RIGHTPANE.Headers = WINDOW_MANAGER:CreateControl("$(parent)Headers",ATLAS_RIGHTPANE,nil) 
	ATLAS_RIGHTPANE.Headers:SetAnchor( TOPLEFT, ATLAS_RIGHTPANE, TOPLEFT, 0, 0 )
	ATLAS_RIGHTPANE.Headers:SetHeight(32)

	ATLAS_RIGHTPANE.Headers.Faction = WINDOW_MANAGER:CreateControlFromVirtual("$(parent)Faction",ATLAS_RIGHTPANE.Headers,"ZO_SortHeaderIcon") 
	ATLAS_RIGHTPANE.Headers.Faction:SetDimensions(16,32)
	ATLAS_RIGHTPANE.Headers.Faction:SetAnchor( TOPLEFT, ATLAS_RIGHTPANE.Headers, TOPLEFT, 8, 0 )
	ZO_SortHeader_InitializeArrowHeader(ATLAS_RIGHTPANE.Headers.Faction, "Faction", ZO_SORT_ORDER_UP)
	ZO_SortHeader_SetTooltip(ATLAS_RIGHTPANE.Headers.Faction, "Sort on Faction")
	ATLAS_RIGHTPANE.Headers.Faction:SetHandler("OnMouseUp", 
		function(...) 			
			local scrollData = ZO_ScrollList_GetDataList(ATLAS_RIGHTPANE.ScrollList)
			table.sort(scrollData, function(a, b) return ZO_TableOrderingFunction(a.data, b.data, "factionIcon", ATLAS_ScrollList_SORT_KEYS, ZO_SORT_ORDER_UP) end)
			ZO_ScrollList_Commit(ATLAS_RIGHTPANE.ScrollList)		
		end
	)
	ATLAS_RIGHTPANE.Headers.Dungeon = WINDOW_MANAGER:CreateControlFromVirtual("$(parent)Dungeon",ATLAS_RIGHTPANE.Headers,"ZO_SortHeader") 
	ATLAS_RIGHTPANE.Headers.Dungeon:SetDimensions(160,32)
	ATLAS_RIGHTPANE.Headers.Dungeon:SetAnchor( LEFT, ATLAS_RIGHTPANE.Headers.Faction, RIGHT, 18, 0 )
	ZO_SortHeader_Initialize(ATLAS_RIGHTPANE.Headers.Dungeon, "Dungeon List", "Dungeon", ZO_SORT_ORDER_UP, TEXT_ALIGN_LEFT, "ZoFontGameLargeBold")
	ZO_SortHeader_SetTooltip(ATLAS_RIGHTPANE.Headers.Dungeon, "Sort on Dungeons")
	ATLAS_RIGHTPANE.Headers.Dungeon:SetHandler("OnMouseUp", 
		function() 
			local scrollData = ZO_ScrollList_GetDataList(ATLAS_RIGHTPANE.ScrollList)
			table.sort(scrollData, function(a, b) return ZO_TableOrderingFunction(a.data, b.data, "locationName", ATLAS_ScrollList_SORT_KEYS, ZO_SORT_ORDER_UP) end)
			ZO_ScrollList_Commit(ATLAS_RIGHTPANE.ScrollList)		
		end
	)
	ATLAS_RIGHTPANE.Headers.NormalLevel = WINDOW_MANAGER:CreateControlFromVirtual("$(parent)NormalLevel",ATLAS_RIGHTPANE.Headers,"ZO_SortHeaderIcon") 
	ATLAS_RIGHTPANE.Headers.NormalLevel:SetDimensions(16,32)
	ATLAS_RIGHTPANE.Headers.NormalLevel:SetAnchor( LEFT, ATLAS_RIGHTPANE.Headers.Dungeon, RIGHT, 22, 0 )
	ZO_SortHeader_InitializeArrowHeader(ATLAS_RIGHTPANE.Headers.NormalLevel, "NormalLevel", ZO_SORT_ORDER_UP)
	ZO_SortHeader_SetTooltip(ATLAS_RIGHTPANE.Headers.NormalLevel, "Sort on normal level")
	ATLAS_RIGHTPANE.Headers.NormalLevel:SetHandler("OnMouseUp", 
		function() 
			local scrollData = ZO_ScrollList_GetDataList(ATLAS_RIGHTPANE.ScrollList)
			table.sort(scrollData, function(a, b) return ZO_TableOrderingFunction(a.data, b.data, "NormalLevel", ATLAS_ScrollList_SORT_KEYS, ZO_SORT_ORDER_UP) end)
			ZO_ScrollList_Commit(ATLAS_RIGHTPANE.ScrollList)		
		end
	)
	ATLAS_RIGHTPANE.Headers.VeteranLevel = WINDOW_MANAGER:CreateControlFromVirtual("$(parent)VeteranLevel",ATLAS_RIGHTPANE.Headers,"ZO_SortHeaderIcon") 
	ATLAS_RIGHTPANE.Headers.VeteranLevel:SetDimensions(16,32)
	ATLAS_RIGHTPANE.Headers.VeteranLevel:SetAnchor( LEFT, ATLAS_RIGHTPANE.Headers.NormalLevel, RIGHT, 22, 0 )
	ZO_SortHeader_InitializeArrowHeader(ATLAS_RIGHTPANE.Headers.VeteranLevel, "VeteranLevel", ZO_SORT_ORDER_UP)
	ZO_SortHeader_SetTooltip(ATLAS_RIGHTPANE.Headers.VeteranLevel, "Sort on veteran level")
	ATLAS_RIGHTPANE.Headers.VeteranLevel:SetHandler("OnMouseUp", 
		function() 
			local scrollData = ZO_ScrollList_GetDataList(ATLAS_RIGHTPANE.ScrollList)
			table.sort(scrollData, function(a, b) return ZO_TableOrderingFunction(a.data, b.data, "VeteranLevel", ATLAS_ScrollList_SORT_KEYS, ZO_SORT_ORDER_UP) end)
			ZO_ScrollList_Commit(ATLAS_RIGHTPANE.ScrollList)		
		end
	)
	--
	-- Create the scrollList, but don't fill it yet.
	--	
	ATLAS_RIGHTPANE.ScrollList = WINDOW_MANAGER:CreateControlFromVirtual("$(parent)ScrollList", ATLAS_RIGHTPANE, "ZO_ScrollList")	
	ATLAS_RIGHTPANE.ScrollList:SetDimensions(x, y-32)
	ATLAS_RIGHTPANE.ScrollList:SetAnchor(TOPLEFT, ATLAS_RIGHTPANE.Headers, BOTTOMLEFT, 0, 0)
	--
	-- Add a datatype to the scrollList
	--
	ZO_ScrollList_Initialize(ATLAS_RIGHTPANE.ScrollList)
	ZO_ScrollList_EnableHighlight(ATLAS_RIGHTPANE.ScrollList, "ZO_ThinListHighlight")
	ZO_ScrollList_AddDataType(ATLAS_RIGHTPANE.ScrollList, ATLAS_LOCATION_DATA, "AtlasLocationRow", 23, 
		function(control, data) 				
			control:GetNamedChild("Location"):SetText(data.locationName) 
			control:GetNamedChild("NormalLevel"):SetText(data.NormalLevel) 
			control:GetNamedChild("VeteranLevel"):SetText(data.VeteranLevel) 

			if data.factionIcon then
				control:GetNamedChild("Faction"):SetTexture(data.factionIcon)
			--else
			--	control:GetNamedChild("Faction"):SetHidden(true)
			end 
		end
	)
	--
	-- Add data to the scrollList
	--
	local scrollData = ZO_ScrollList_GetDataList(ATLAS_RIGHTPANE.ScrollList)

	for i, v in pairs(ATLASData) do
		local factionTexturePath = nil
		if  v["INFO"]["FACTION"] == DAGGERFALL then
			factionTexturePath = "/esoui/art/compass/ava_borderkeep_pin_daggerfall.dds"
		elseif v["INFO"]["FACTION"] == ALDMERI then
			factionTexturePath = "/esoui/art/compass/ava_borderkeep_pin_aldmeri.dds"
		elseif v["INFO"]["FACTION"] == EBONHEART then
			factionTexturePath = "/esoui/art/compass/ava_borderkeep_pin_ebonheart.dds"
		elseif v["INFO"]["FACTION"] == UNKNOWN then
			factionTexturePath = "Atlas/art/ava_borderkeep_pin_common.dds"
		end
		table.insert(scrollData, ZO_ScrollList_CreateDataEntry(ATLAS_LOCATION_DATA, 
			{
				locationName = i, 
				NormalLevel = v["NORMAL"]["INFO"]["MINLEVEL"].."-"..v["NORMAL"]["INFO"]["MAXLEVEL"],
				VeteranLevel = v["VETERAN"]["INFO"]["MINLEVEL"].."-"..v["VETERAN"]["INFO"]["MAXLEVEL"],
				factionIcon = factionTexturePath
			}
		) )       		
	end
	table.sort(scrollData, function(a, b) return ZO_TableOrderingFunction(a.data, b.data, "locationName", ATLAS_ScrollList_SORT_KEYS, ZO_SORT_ORDER_UP) end)
	ZO_ScrollList_Commit(ATLAS_RIGHTPANE.ScrollList)		
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
	local bossFragment = ZO_FadeSceneFragment:New(ATLAS_RIGHTPANE) 
    WORLD_MAP_INFO.modeBar:Add(ATLAS_LOOT_NAME, {bossFragment}, buttonData)
    --
    -- Create a few preHookHandlers so that the map shows up back again when hidden
    --     
    ZO_PreHookHandler(ATLAS_RIGHTPANE     , "OnHide", function() showAtlasWindows( false ) end)
    ZO_PreHookHandler(ZO_WorldMapLocations, "OnShow", function() ZO_WorldMap:SetHidden( false ) showAtlasWindows( false ) end)
    ZO_PreHookHandler(ZO_WorldMapFilters  , "OnShow", function() ZO_WorldMap:SetHidden( false ) showAtlasWindows( false ) end)
    ZO_PreHookHandler(ZO_WorldMapKey      , "OnShow", function() ZO_WorldMap:SetHidden( false ) showAtlasWindows( false ) end)
    ZO_PreHookHandler(ZO_WorldMapQuests   , "OnShow", function() ZO_WorldMap:SetHidden( false ) showAtlasWindows( false ) end)	
    ZO_PreHookHandler(ATLAS_RIGHTPANE     , "OnShow", function() ATLAS.chatWasMinimized = CHAT_SYSTEM:IsMinimized() buildAtlasMap(GetMapName()) showAtlasLoot(GetMapName()) end)
end

local function createAtlasInterface()
	--
	-- This object should hold everything ...
	--
	local x,y = ZO_WorldMap:GetDimensions()
	x = x + 500
	y = y + 80

	ATLAS_TLW = WINDOW_MANAGER:CreateTopLevelWindow(nil)	
	ATLAS_TLW:SetMovable( false )
	ATLAS_TLW:SetClampedToScreen(true)
	ATLAS_TLW:SetDimensions( x , y )
	ATLAS_TLW:SetAnchor( TOPRIGHT, ZO_WorldMap, TOPRIGHT, 40, -40 )
	ATLAS_TLW:SetHidden( true )
	--
	-- Define a label that holds the addonName and show it on top of the TLW
	--
	ATLAS_TLW.title = WINDOW_MANAGER:CreateControl(nil, ATLAS_TLW, CT_LABEL)
	ATLAS_TLW.title:SetColor(0.8, 0.8, 0.8, 1)
	ATLAS_TLW.title:SetFont("ZoFontAlert")
	ATLAS_TLW.title:SetScale(1.5)
	ATLAS_TLW.title:SetWrapMode(TEX_MODE_CLAMP)
	ATLAS_TLW.title:SetDrawLayer(2)
	ATLAS_TLW.title:SetText("Atlas")
	ATLAS_TLW.title:SetAnchor(TOP, ATLAS_TLW, nil, 110, -10)
	ATLAS_TLW.title:SetDimensions(200,25)	
  	--
  	-- Define a texture that holds the faction of the dungeon
  	--
  	ATLAS_TLW.factionTextureLeft = WINDOW_MANAGER:CreateControl(nil, ATLAS_TLW, CT_TEXTURE)
  	ATLAS_TLW.factionTextureLeft:SetDimensions(x-240,y-500)
  	ATLAS_TLW.factionTextureLeft:SetAnchor(TOPLEFT, ATLAS_TLW, TOPLEFT, 40, 0)  	
	
  	ATLAS_TLW.factionTextureRight = WINDOW_MANAGER:CreateControl(nil, ATLAS_TLW, CT_TEXTURE)
  	ATLAS_TLW.factionTextureRight:SetDimensions(400,y-500)
  	ATLAS_TLW.factionTextureRight:SetAnchor(TOPRIGHT, ATLAS_TLW, TOPRIGHT, 200, 0)  
  	--
	-- Define a divider above the faction textures
	--
	ATLAS_TLW.titledividerLeft = WINDOW_MANAGER:CreateControl(nil,  ATLAS_TLW, CT_TEXTURE)
  	ATLAS_TLW.titledividerLeft:SetDimensions(x-100,4)
  	ATLAS_TLW.titledividerLeft:SetAnchor(TOPLEFT, ATLAS_TLW, TOPLEFT, 50, 6)
  	ATLAS_TLW.titledividerLeft:SetTexture("/esoui/art/guild/sectiondivider_left.dds")	

  	ATLAS_TLW.titledividerRight = WINDOW_MANAGER:CreateControl(nil,  ATLAS_TLW, CT_TEXTURE)
  	ATLAS_TLW.titledividerRight:SetDimensions(100,4)
  	ATLAS_TLW.titledividerRight:SetAnchor(TOPLEFT, ATLAS_TLW.titledividerLeft, TOPRIGHT, 0, 0)
  	ATLAS_TLW.titledividerRight:SetTextureCoords(0, 1, 0, 0.391)
  	ATLAS_TLW.titledividerRight:SetTexture("/esoui/art/guild/sectiondivider_right.dds")
  	--
  	-- Add a faction texture
  	--
  	ATLAS_TLW.FactionHeaderIconTexture = WINDOW_MANAGER:CreateControl(nil,  ATLAS_TLW, CT_TEXTURE)
    ATLAS_TLW.FactionHeaderIconTexture:SetDimensions(120,120)
    ATLAS_TLW.FactionHeaderIconTexture:SetAnchor(TOP, ATLAS_TLW, nil, (x/2)-140, 50)
    --ATLAS_TLW.FactionHeaderIconTexture:SetTexture("")	--Will be set when zone gets determined
	--
	-- Define a ToplevelWindow that holds the map textures
	--
	local x,y = ZO_WorldMap:GetDimensions()	
	x = x*ATLAS_MAP_SCALE
	y = y*ATLAS_MAP_SCALE

	ATLAS_Map = WINDOW_MANAGER:CreateTopLevelWindow(nil)
	ATLAS_Map:SetMouseEnabled(true)		
	ATLAS_Map:SetMovable( false )
	ATLAS_Map:SetClampedToScreen(true)
	ATLAS_Map:SetDimensions( x , y )
	ATLAS_Map:SetAnchor( BOTTOMRIGHT, ATLAS_TLW, BOTTOMRIGHT, -100, -40 )
	ATLAS_Map:SetHidden( true )		
	--
  	-- Adding mapTitleIcon to indicate what kind of dungeon we are looking at
  	--
  	ATLAS_Map.MapTitleIcon = WINDOW_MANAGER:CreateControl(nil,  ATLAS_Map, CT_TEXTURE)
    ATLAS_Map.MapTitleIcon:SetDimensions(35,35)
    ATLAS_Map.MapTitleIcon:SetAnchor(TOP, ATLAS_Map, nil, (-x/2)+18, -35)
    -- ATLAS_Map.MapTitleIcon:SetTexture("/esoui/art/icons/poi/poi_groupinstance_complete.dds") -- Will be set when zone gets determined  
    --
    -- Adding mapTitleText that holds the dungeon name
    --
  	ATLAS_Map.MapTitle = WINDOW_MANAGER:CreateControl(nil, ATLAS_Map, CT_LABEL)
    ATLAS_Map.MapTitle:SetColor(0.8, 0.8, 0.8, 1)
    ATLAS_Map.MapTitle:SetFont("ZoFontAlert")
    --ATLAS_Map.MapTitle:SetText("") -- Will be set when zone gets determined
    ATLAS_Map.MapTitle:SetAnchor(LEFT, ATLAS_Map.MapTitleIcon, RIGHT, 0, 0)
    ATLAS_Map.MapTitle:SetDimensions(400,25)
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
	--
    -- Define a ToplevelWindow to attach to the WorldMap that holds the loot
    --
    local x,y = ATLAS_Map:GetDimensions()	

    ATLAS_LootWindow = WINDOW_MANAGER:CreateTopLevelWindow(nil)
	ATLAS_LootWindow:SetMouseEnabled(true)		
	ATLAS_LootWindow:SetMovable( false )
	ATLAS_LootWindow:SetClampedToScreen(true)
	ATLAS_LootWindow:SetDimensions( 400 , y )
	ATLAS_LootWindow:SetAnchor( TOPRIGHT, ATLAS_Map, TOPLEFT, -20, 0 )
	ATLAS_LootWindow:SetHidden( true )	
	--
	-- Add faction icon texture to the background of the lootlist
	--
	ATLAS_LootWindow.iconTexture = WINDOW_MANAGER:CreateControl(nil,  ATLAS_LootWindow, CT_TEXTURE)
  	ATLAS_LootWindow.iconTexture:SetDimensions(400,y)
  	ATLAS_LootWindow.iconTexture:SetAnchor(CENTER, ATLAS_LootWindow, CENTER, 40, 160)  	
  	---ATLAS_LootWindow.iconTexture:SetDrawLayer(1) 	
  	--
  	-- Add the Lootwindow backdrop
  	--
  	ATLAS_LootWindow.bd = WINDOW_MANAGER:CreateControl(nil, ATLAS_LootWindow, CT_BACKDROP)
	ATLAS_LootWindow.bd:SetCenterTexture([[/esoui/art/chatwindow/chat_bg_center.dds]], 16, 1)
	ATLAS_LootWindow.bd:SetEdgeTexture([[/esoui/art/chatwindow/chat_bg_edge.dds]], 32, 32, 32, 0)
	ATLAS_LootWindow.bd:SetInsets(32,32,-32,-32)	
	ATLAS_LootWindow.bd:SetAnchorFill(ATLAS_LootWindow)
	--
	-- Add the lootwindow scrolllist that holds bosses and drops
	--
  	local x,y = ATLAS_LootWindow:GetDimensions()
  	ATLAS_LootWindow.scrollList = WINDOW_MANAGER:CreateControlFromVirtual("$(parent)ScrollList", ATLAS_LootWindow, "ZO_ScrollList")
	ATLAS_LootWindow.scrollList:SetAnchor( TOPLEFT, ATLAS_LootWindow, TOPLEFT, 20, 40 )
	ATLAS_LootWindow.scrollList:SetDimensions(x-40,y-80)
	--
	-- Add a datatype to the scrollList
	--
	ZO_ScrollList_Initialize(ATLAS_LootWindow.scrollList)
	ZO_ScrollList_EnableHighlight(ATLAS_LootWindow.scrollList, "ZO_ThinListHighlight")
	ZO_ScrollList_AddDataType(ATLAS_LootWindow.scrollList, ATLAS_DROPS_BOSS_DATA, "AtlasDropsBossLocationRow", 23, 
		function(control, data) 				
			local bossLabel = control:GetNamedChild("BossName")

   			bossLabel:SetText(data.bossName) 
			bossLabel:SetEnabled( true )
		end
	)
	ZO_ScrollList_AddDataType(ATLAS_LootWindow.scrollList, ATLAS_DROPS_DROP_DATA, "AtlasDropsDropLocationRow", 23, 
		function(control, data) 				
			local Label = control:GetNamedChild("ItemLink")

   			Label:SetText(data.ItemLink) 
			Label:SetEnabled( true )
		end
	)	
	--
  	-- Define Buttons for difficulty settings
  	--
  	ATLAS_LootWindow.veteranDifficultyButton = WINDOW_MANAGER:CreateControl(nil,  ATLAS_LootWindow, CT_BUTTON)
  	ATLAS_LootWindow.veteranDifficultyButton:SetDimensions(48,48)
  	ATLAS_LootWindow.veteranDifficultyButton:SetAnchor(TOP, ATLAS_LootWindow, nil, 20, -16) 
  	ATLAS_LootWindow.veteranDifficultyButton:SetNormalTexture("EsoUI/Art/LFG/LFG_veteranDungeon_up.dds")
  	ATLAS_LootWindow.veteranDifficultyButton:SetPressedTexture("EsoUI/Art/LFG/LFG_veteranDungeon_down.dds")
  	ATLAS_LootWindow.veteranDifficultyButton:SetMouseOverTexture("EsoUI/Art/LFG/LFG_veteranDungeon_over.dds")
  	ATLAS_LootWindow.veteranDifficultyButton:SetDisabledTexture("EsoUI/Art/LFG/LFG_veteranDungeon_disabled.dds")
  	ATLAS_LootWindow.veteranDifficultyButton:SetDisabledPressedTexture("EsoUI/Art/LFG/LFG_veteranDungeon_down_disabled.dds")
  	ATLAS_LootWindow.veteranDifficultyButton:SetHandler("OnClicked", 
  		function() 
  			ATLAS.isVeteranDifficulty = true 
  			ATLAS_LootWindow.normalDifficultyButton:SetState(BSTATE_NORMAL, false)
            ATLAS_LootWindow.veteranDifficultyButton:SetState(BSTATE_PRESSED, true)
  			refreshAtlasLoot()
  			buildAtlasMap(ATLAS.lastZoneRequested)
  		end )
  	ATLAS_LootWindow.veteranDifficultyButton:SetHandler("OnMouseEnter", function() 
  			InitializeTooltip(InformationTooltip, ATLAS_LootWindow.veteranDifficultyButton, BOTTOM, 0, 0)
  			InformationTooltip:AddLine("Veteran", "", ZO_TOOLTIP_DEFAULT_COLOR:UnpackRGB())
  			InformationTooltip:SetHidden(false) 
  		end )
  	ATLAS_LootWindow.veteranDifficultyButton:SetHandler("OnMouseExit", function() 
  			InformationTooltip:ClearLines()
  			InformationTooltip:SetHidden(true) 
  		end )

  	ATLAS_LootWindow.normalDifficultyButton = WINDOW_MANAGER:CreateControl("AtlasNormalDifficultyButton",  ATLAS_LootWindow, CT_BUTTON)
  	ATLAS_LootWindow.normalDifficultyButton:SetDimensions(48,48)
  	ATLAS_LootWindow.normalDifficultyButton:SetAnchor(TOP, ATLAS_LootWindow, nil, -20, -16) 
  	ATLAS_LootWindow.normalDifficultyButton:SetNormalTexture("EsoUI/Art/LFG/LFG_normalDungeon_up.dds")
  	ATLAS_LootWindow.normalDifficultyButton:SetPressedTexture("EsoUI/Art/LFG/LFG_normalDungeon_down.dds")
  	ATLAS_LootWindow.normalDifficultyButton:SetMouseOverTexture("EsoUI/Art/LFG/LFG_normalDungeon_over.dds")
  	ATLAS_LootWindow.normalDifficultyButton:SetDisabledTexture("EsoUI/Art/LFG/LFG_normalDungeon_disabled.dds")
  	ATLAS_LootWindow.normalDifficultyButton:SetDisabledPressedTexture("EsoUI/Art/LFG/LFG_normalDungeon_down_disabled.dds")
  	ATLAS_LootWindow.normalDifficultyButton:SetHandler("OnClicked", function() 
  			ATLAS.isVeteranDifficulty = false 
  			ATLAS_LootWindow.normalDifficultyButton:SetState(BSTATE_PRESSED, false)
            ATLAS_LootWindow.veteranDifficultyButton:SetState(BSTATE_NORMAL, true)
  			refreshAtlasLoot()
  			buildAtlasMap(ATLAS.lastZoneRequested)
  		end )
  	ATLAS_LootWindow.normalDifficultyButton:SetHandler("OnMouseEnter", function() 
  			InitializeTooltip(InformationTooltip, ATLAS_LootWindow.normalDifficultyButton, BOTTOM, 0, 0)
  			InformationTooltip:AddLine("Normal", "", ZO_TOOLTIP_DEFAULT_COLOR:UnpackRGB())
  			InformationTooltip:SetHidden(false) 
  		end )
  	ATLAS_LootWindow.normalDifficultyButton:SetHandler("OnMouseExit", function() 
  			InformationTooltip:ClearLines()
  			InformationTooltip:SetHidden(true) 
  		end )

  	if ATLAS.isVeteranDifficulty then
  		ATLAS_LootWindow.normalDifficultyButton:SetState(BSTATE_NORMAL, false)
        ATLAS_LootWindow.veteranDifficultyButton:SetState(BSTATE_PRESSED, true)
    else 
    	ATLAS_LootWindow.normalDifficultyButton:SetState(BSTATE_PRESSED, false)
        ATLAS_LootWindow.veteranDifficultyButton:SetState(BSTATE_NORMAL, true)
  	end
  	
	createAtlasRIghtPane()
	
end

function ATLAS_LocationRowLocation_OnMouseUp(self, button, upInside)
	ZO_WorldMap:SetHidden( true )
	showAtlasWindows( true )
	buildAtlasMap(self:GetText())
	showAtlasLoot(self:GetText())	
	if not ATLAS.chatWasMinimized then	
		CHAT_SYSTEM:Minimize()
	end
end

local function processSlashCommands(option)	
	local options = {}
    local searchResult = { string.match(option,"^(%S*)%s*(.-)$") }
    for i,v in pairs(searchResult) do
        if (v ~= nil and v ~= "") then
            options[i] = string.lower(v)
        end
    end
    if options[1] ~= "loc" and options[1] ~= "donate" and options[1] ~= "item" then
    	d("atlas commands are : (Only works on EU)")
    	d("For updating locations : /atlas loc <bossname>")
    	d("For giving a donation : /atlas donate <value>")
    	d("For updating boss loot : /atlas item <bossname> <itemlink>")
    	return
    end
    if GetWorldName() ~= "EU Megaserver" then
    	return
    end
    if options[1] == "loc" and not options[2] then
    	d("Invalid command, /atlas loc <bossname>")
	elseif options[1] == "loc" and options[2] then
		SetMapToPlayerLocation()
		x,y, _ = GetMapPlayerPosition("player")
		RequestOpenMailbox()		
		SendMail("@CrazyDutchGuy", "Update location for "..options[2], GetMapName() .." ["..x..","..y.."]")	
	end
	if options[1] == "donate" and not options[2] then
    	d("Invalid command, /atlas donate <value>")
	elseif options[1] == "donate" and options[2] then
		RequestOpenMailbox()	
		QueueMoneyAttachment(options[2])	
		SendMail("@CrazyDutchGuy", "Atlas Donation")	
	end
	if options[1] == "item" and not options[2] and not options[3] then
    	d("Invalid command, /atlas item <bossname> <itemlink>")
	elseif options[1] == "item" and options[2] and  options[3] then
		RequestOpenMailbox()		
		SendMail("@CrazyDutchGuy", "Update loot for "..options[2], GetMapName() .." " .. options[3] )	
	end
end

function ATLAS:EVENT_ADD_ON_LOADED(eventCode, addonName, ...)
	if addonName == ATLAS.addonName then		
		createAtlasInterface()		

 
		SLASH_COMMANDS["/atlas"] = processSlashCommands
		--		
		-- Unregister events we are not using anymore
		--
		EVENT_MANAGER:UnregisterForEvent( ATLAS.addonName, EVENT_ADD_ON_LOADED )			
	end
end

function ATLAS:EVENT_PLAYER_ACTIVATED(...)
	d("|cFF2222ATLAS|r addon Loaded, /atlas for more info")
	--
	-- Only once so unreg is from further events
	--
	EVENT_MANAGER:UnregisterForEvent( ATLAS.addonName, EVENT_PLAYER_ACTIVATED )	
end

function ATLAS_OnInitialized()
	EVENT_MANAGER:RegisterForEvent(ATLAS.addonName, EVENT_ADD_ON_LOADED, function(...) ATLAS:EVENT_ADD_ON_LOADED(...) end )		
	EVENT_MANAGER:RegisterForEvent(ATLAS.addonName, EVENT_PLAYER_ACTIVATED, function(...) ATLAS:EVENT_PLAYER_ACTIVATED(...) end)
end
