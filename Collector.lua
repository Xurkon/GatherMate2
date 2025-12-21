local GatherMate = LibStub("AceAddon-3.0"):GetAddon("GatherMate2")
local Collector = GatherMate:NewModule("Collector", "AceEvent-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("GatherMate2",true)
local NL = LibStub("AceLocale-3.0"):GetLocale("GatherMate2Nodes")   -- for get the local name of Gas Cloud´s
local Display = nil
-- prevSpell, curSpell are markers for what has been cast now and the lastcast
-- gatherevents if a flag for wether we are listening to events
local prevSpell, curSpell, foundTarget, gatherEvents, ga

--[[
Convert for 2.4 spell IDs
]]
local miningSpell = (GetSpellInfo(2575))
local herbSpell = (GetSpellInfo(2366))
local herbSkill = (GetSpellInfo(9134))
local fishSpell = (GetSpellInfo(33095))
local gasSpell = (GetSpellInfo(30427))
--local gasSpell = (GetSpellInfo(48929))  --other gasspell
local openUnlocking = (GetSpellInfo(6527))
local openUnlocking2 = (GetSpellInfo(10738))
local openSpell = (GetSpellInfo(3365))
local openNoTextSpell = (GetSpellInfo(22810))
local pickSpell = (GetSpellInfo(1804))
local woodSpell1 = (GetSpellInfo(93462)) -- Apprentice
local woodSpell2 = (GetSpellInfo(93463)) -- Journeyman
local woodSpell3 = (GetSpellInfo(93464)) -- Expert
local woodSpell4 = (GetSpellInfo(93465)) -- Artisan

local spells = { -- spellname to "database name"
--	[miningSpell] = "Mining",
--	[herbSpell] = "Herb Gathering",
	[fishSpell] = "Fishing",
	[gasSpell] = "Extract Gas",
--	[openUnlocking] = "Treasure",
--	[openUnlocking2] = "Treasure",
--	[openSpell] = "Treasure",
--	[openNoTextSpell] = "Treasure",
--	[pickSpell] = "Treasure",
--	[woodSpell1] = "Woodcutting",
--	[woodSpell2] = "Woodcutting",
--	[woodSpell3] = "Woodcutting",
--	[woodSpell4] = "Woodcutting",
}
local tooltipLeftText1 = _G["GameTooltipTextLeft1"]
local strfind, stringmatch = string.find, string.match
local pii = math.pi
local sin = math.sin
local cos = math.cos
local gsub = gsub
local strtrim = strtrim
--[[
	This search string code no longer needed since we use CombatEvent to detect gas clouds harvesting
]]
-- buffsearchstring is for gas extartion detection of the aura event
-- local buffSearchString
--local sub_string = GetLocale() == "deDE" and "%%%d$s" or "%%s"
--buffSearchString = string.gsub(AURAADDEDOTHERHELPFUL, sub_string, "(.+)")

local function getArrowDirection(...)
	if GetPlayerFacing then
		return GetPlayerFacing()
	else
		if(GetCVar("rotateMinimap") == "1") then return -MiniMapCompassRing:GetFacing()	end
		for i=select("#",...),1,-1 do
			local model=select(i,...)
			if model:IsObjectType("Model") and not model:GetName() then	return model and model:GetFacing() end
		end
		return nil
	end
end

--[[
	Enable the collector
]]
function Collector:OnEnable()
	self:RegisterGatherEvents()
end

--[[
	Register the events we are interesting
]]
function Collector:RegisterGatherEvents()
	self:RegisterEvent("GAMEOBJECT_USED","GameObject")
	self:RegisterEvent("UNIT_SPELLCAST_SENT","SpellStarted")
	self:RegisterEvent("UNIT_SPELLCAST_STOP","SpellStopped")
	self:RegisterEvent("UNIT_SPELLCAST_FAILED","SpellFailed")
	self:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED","SpellFailed")
	self:RegisterEvent("CURSOR_UPDATE","CursorChange")
--	self:RegisterEvent("UI_ERROR_MESSAGE","UIError")
	self:RegisterEvent("LOOT_CLOSED","GatherCompleted")
	self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED", "GasBuffDetector")
	self:RegisterEvent("CHAT_MSG_LOOT","SecondaryGasCheck") -- for Storm Clouds
	gatherEvents = true
end

--[[
	Unregister the events
]]
function Collector:UnregisterGatherEvents()
	self:UnregisterEvent("GAMEOBJECT_USED")
	self:UnregisterEvent("UNIT_SPELLCAST_SENT")
	self:UnregisterEvent("UNIT_SPELLCAST_STOP")
	self:UnregisterEvent("UNIT_SPELLCAST_FAILED")
	self:UnregisterEvent("UNIT_SPELLCAST_INTERRUPTED")
	self:UnregisterEvent("CURSOR_UPDATE")
--	self:UnregisterEvent("UI_ERROR_MESSAGE")
	self:UnregisterEvent("LOOT_CLOSED")
	self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	gatherEvents = false
end

local CrystalizedWater = (GetItemInfo(37705)) or ""

function Collector:SecondaryGasCheck(event,msg)
	if ga ~= gasSpell then return end
	if not msg then return end
	if foundTarget then return end
	if ga == gasSpell and strfind(msg,CrystalizedWater) then
		-- check for Steam Clouds by assuming your always getting water from Steam Clouds
		foundTarget = true
		self:addItem(ga,NL["Steam Cloud"])
		ga = "No"
	end
end

--[[
	This is a hack for scanning mote extraction, hopefully blizz will make the mote mobs visible so we can mouse over
	or get a better event instead of cha msg parsing
	UNIT_DISSIPATES,0x0000000000000000,nil,0x80000000,0xF1307F0A00002E94,"Cinder Cloud",0xa28 now fires in cataclysm so hack not needed any more
]]
function Collector:GasBuffDetector(b,timestamp, eventType, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellId,spellName,spellSchool,auraType)
	if foundTarget or (prevSpell and prevSpell ~= gasSpell) then return end
	if eventType == "SPELL_CAST_SUCCESS" and  spellName == gasSpell then
		ga = gasSpell
	elseif eventType == "UNIT_DISSIPATES" and  ga == gasSpell then
		foundTarget = true
		self:addItem(ga,dstName)
		ga = "No"
	end
end

--[[
	Any time we close a loot window stop checking for targets ala the Fishing bobber
]]
function Collector:GatherCompleted()
	prevSpell, curSpell = nil, nil
	foundTarget = false
end

--[[
	When the hand icon goes to a gear see if we can find a node under the gear ala for the fishing bobber OR herb of mine
]]
function Collector:CursorChange()
	if foundTarget then return end
	if (MinimapCluster:IsMouseOver()) then return end
	if spells[prevSpell] then
		self:GetWorldTarget()
	end
end

--[[
	We stopped casting the spell
]]
function Collector:SpellStopped(event,unit)
	if unit ~= "player" then return end
	if spells[prevSpell] then
		self:GetWorldTarget()
	end
	-- prev spel needs set since it is used for cursor changes
	prevSpell, curSpell = curSpell, curSpell
end

--[[
	We failed to cast
]]
function Collector:SpellFailed(event,unit)
	if unit ~= "player" then return end
	prevSpell, curSpell = nil, nil
end

--[[
	UI Error from gathering when you dont have the required skill
]]
--[[
function Collector:UIError(event,msg)
	local what = tooltipLeftText1:GetText();
	if not what then return end
	if strfind(msg, miningSpell) then
		self:addItem(miningSpell,what)
	elseif strfind(msg, herbSkill) then
		self:addItem(herbSpell,what)
	elseif strfind(msg, pickSpell) or strfind(msg, openSpell) then -- locked box or failed pick
		self:addItem(openSpell, what)
	end
end
]]
--[[
	spell cast started
]]

function Collector:SpellStarted(event,unit,spellcast,rank,target)
	if unit ~= "player" then return end
	foundTarget = false
	ga ="No"
	if spells[spellcast] then
		curSpell = spellcast
		prevSpell = spellcast
		local nodeID = GatherMate:GetIDForNode(spells[prevSpell], target)
		if nodeID then -- seem 2.4 has the node name now as the target
			self:addItem(prevSpell,target)
			foundTarget = true
		else
			self:GetWorldTarget()
		end
	else
		prevSpell, curSpell = nil, nil
	end
end

--[[
	add an item to the map (we delgate to GatherMate)
]]
local lastNode = ""
local lastNodeCoords = 0

-- Should only be called for fishing and gas clouds
function Collector:addItem(skill,what)
	local x, y = GetPlayerMapPosition("player")
	if x == 0 and y == 0 then return end
	-- Temporary fix, the map "ScarletEnclave" and "EasternPlaguelands"
	-- both have the same English display name as "Eastern Plaguelands"
	-- so we ignore the new Death Knight starting zone for now.
	-- if GetMapInfo() == "ScarletEnclave" then return end TODO Validate in wrath, shoud be fine
	--self:GatherCompleted()
	if WorldMapFrame:IsShown() then return else SetMapToCurrentZone() end
	local zone = GetCurrentMapAreaID()
	local level = GetCurrentMapDungeonLevel()
	local node_type = spells[skill]
	if not node_type or not what then return end
	-- db lock check
	if GatherMate.db.profile.dbLocks[node_type] then return	end

	local range = GatherMate.db.profile.cleanupRange[node_type]
	-- special case for fishing and gas extraction guage the pointing direction
	if node_type == fishSpell or node_type == gasSpell then
		local yw, yh = GatherMate:GetZoneSize(zone,level)
		if yw == 0 or yh == 0 then return end -- No zone size data
		x,y = self:GetFloatingNodeLocation(x, y, yw, yh)
	end
	local nid = GatherMate:GetIDForNode(node_type, what)
	-- if we couldnt find the node id for what was found, exit the add
	if not nid then return end
	local rares = self.rareNodes
	-- run through the nearby's
	local skip = false
	local foundCoord = GatherMate.mapData:EncodeLoc(x, y, level)
	local specialNode = false
	local specialWhat = what
	if foundCoord == lastNodeCoords and what == lastNode then return end
	--[[ DISABLE SPECIAL NODE PROCESSING FOR HERBS
	if self.specials[zone] and self.specials[zone][node_type] ~= nil then
		specialWhat = GatherMate:GetNameForNode(node_type,self.specials[zone][node_type])
		specialNode = true
	end
	--]]
	for coord, nodeID in GatherMate:FindNearbyNode(zone, x, y, level, node_type, range, true) do
		if (nodeID == nid or rares[nodeID] and rares[nodeID][nid]) then
			GatherMate:RemoveNodeByID(zone, node_type, coord)
		-- we're trying to add a rare node, but there is already a normal node present, skip the adding
		elseif rares[nid] and rares[nid][nodeID] then
			skip = true
		elseif specialNode then -- handle special case zone mappings
			skip = false
			GatherMate:RemoveNodeByID(zone, node_type, coord)
		end
	end

	if not skip then
		if specialNode then
			GatherMate:AddNode(zone, x, y, level, node_type, specialWhat)
		else
			GatherMate:AddNode(zone, x, y, level, node_type, what)
		end
		lastNode = what
		lastNodeCoords = foundCoord
	end
end

--[[
	move the node 20 yards in the direction the player is looking at
]]
function Collector:GetFloatingNodeLocation(x,y,yardWidth,yardHeight)
	local facing = getArrowDirection(Minimap:GetChildren())
	if not facing then	-- happens when minimap rotation is on
		return x,y
	else
		local rad = facing + pii
		return x + sin(rad)*20/yardWidth, y + cos(rad)*20/yardHeight
	end
end

--[[
	get the target your clicking on
]]
function Collector:GetWorldTarget()
	if foundTarget or not spells[curSpell] then return end
	if (MinimapCluster:IsMouseOver()) then return end
	local what = tooltipLeftText1:GetText()
	local nodeID = GatherMate:GetIDForNode(spells[prevSpell], what)
	if what and prevSpell and what ~= prevSpell and nodeID then
		self:addItem(prevSpell,what)
		foundTarget = true
	end
end

local mining = {
	[1731] = 201, -- Copper Vein
	[2055] = 201, -- Copper Vein
	[3763] = 201, -- Copper Vein
	[100145] = 201, -- Copper Vein
	[103713] = 201, -- Copper Vein
	[181248] = 201, -- Copper Vein
	[1732] = 202, -- Tin Vein
	[2054] = 202, -- Tin Vein
	[3764] = 202, -- Tin Vein
	[100147] = 202, -- Tin Vein
	[100224] = 202, -- Tin Vein
	[103711] = 202, -- Tin Vein
	[181249] = 202, -- Tin Vein
	[1735] = 203, -- Iron Deposit
	[100163] = 203, -- Iron Deposit
	[1733] = 204, -- Silver Vein
	[100162] = 204, -- Silver Vein
	[1734] = 205, -- Gold Vein
	[100666] = 205, -- Gold Vein
	[150080] = 205, -- Gold Vein
	[2040] = 206, -- Mithril Deposit
	[100176] = 206, -- Mithril Deposit
	[150079] = 206, -- Mithril Deposit
	[176645] = 206, -- Mithril Deposit
	[123310] = 207, -- Ooze Covered Mithril Deposit
	[2047] = 208, -- Truesilver Deposit
	[100197] = 208, -- Truesilver Deposit
	[150081] = 208, -- Truesilver Deposit
	[181108] = 208, -- Truesilver Deposit
	[73940] = 209, -- Ooze Covered Silver Vein
	[73941] = 210, -- Ooze Covered Gold Vein
	[123309] = 211, -- Ooze Covered Truesilver Deposit
	[177388] = 212, -- Ooze Covered Rich Thorium Vein
	[123848] = 213, -- Ooze Covered Thorium Vein
	[324] = 214, -- Small Thorium Vein
	[150082] = 214, -- Small Thorium Vein
	[176643] = 214, -- Small Thorium Vein
	[175404] = 215, -- Rich Thorium Vein
	[180215] = 216, -- Hakkari Thorium Vein -- found on in ZG
	[165658] = 217, -- Dark Iron Deposit
	[2653] = 218, -- Lesser Bloodstone Deposit
	[1610] = 219, -- Incendicite Mineral Vein
	[1667] = 219, -- Incendicite Mineral Vein
	[19903] = 220, -- Indurium Mineral Vein
	[181555] = 221, -- Fel Iron Deposit
	[181556] = 222, -- Adamantite Deposit
	[181569] = 223, -- Rich Adamantite Deposit
	[181570] = 223, -- Rich Adamantite Deposit
	[181557] = 224, -- Khorium Vein
	[400005] = 225, -- Large Obsidian Chunk -- found only in AQ20/40
	[400004] = 226, -- Small Obsidian Chunk -- found only in AQ20/40
	[185877] = 227, -- Nethercite Deposit
	[189978] = 228, -- Cobalt Deposit
	[189979] = 229, -- Rich Cobalt Deposit
	[191133] = 230, -- Titanium Vein
	[189980] = 231, -- Saronite Deposit
	[189981] = 232, -- Rich Saronite Deposit
	[195036] = 233, -- Pure Saronite Deposit
}
local herbs = {
	[1618] = 401, -- Peacebloom
	[1617] = 402, -- Silverleaf
	[1619] = 403, -- Earthroot
	[1620] = 404, -- Mageroyal
	[100022] = 404, -- Mageroyal
	[1621] = 405, -- Briarthorn
	[100027] = 405, -- Briarthorn
--	[0000] = 406, -- Swiftthistle -- found it briathorn nodes
	[2045] = 407, -- Stranglekelp
	[100177] = 407, -- Stranglekelp
	[1622] = 408, -- Bruiseweed
	[100045] = 408, -- Bruiseweed
	[1623] = 409, -- Wild Steelbloom
	[100433] = 409, -- Wild Steelbloom
	[1628] = 410, -- Grave Moss
	[1624] = 411, -- Kingsblood
	[100134] = 411, -- Kingsblood
	[2041] = 412, -- Liferoot
	[2042] = 413, -- Fadeleaf
	[2046] = 414, -- Goldthorn
	[2043] = 415, -- Khadgar's Whisker
	[2044] = 416, -- Wintersbite
	[2866] = 417, -- Firebloom
	[142140] = 418, -- Purple Lotus
	[180165] = 418, -- Purple Lotus (zg so 2x, 3x, 4x same nodes)
	[280165] = 418, -- Purple Lotus (zg so 2x, 3x, 4x same nodes)
	[380165] = 418, -- Purple Lotus (zg so 2x, 3x, 4x same nodes)
	[480165] = 418, -- Purple Lotus (zg so 2x, 3x, 4x same nodes)
--	[0000] = 419, -- Wildvine -- found in purple lotus nodes
	[142141] = 420, -- Arthas' Tears
	[176642] = 420, -- Arthas' Tears
	[142142] = 421, -- Sungrass
	[176636] = 421, -- Sungrass
	[180164] = 421, -- Sungrass (zg so 2x, 3x, 4x same nodes)
	[280164] = 421, -- Sungrass (zg so 2x, 3x, 4x same nodes)
	[380164] = 421, -- Sungrass (zg so 2x, 3x, 4x same nodes)
	[480164] = 421, -- Sungrass (zg so 2x, 3x, 4x same nodes)
	[142143] = 422, -- Blindweed
	[142144] = 423, -- Ghost Mushroom
	[142145] = 424, -- Gromsblood
	[176637] = 424, -- Gromsblood
	[176583] = 425, -- Golden Sansam
	[176638] = 425, -- Golden Sansam
	[180167] = 425, -- Golden Sansam (zg so 2x, 3x, 4x same nodes)
	[280167] = 425, -- Golden Sansam (zg so 2x, 3x, 4x same nodes)
	[380167] = 425, -- Golden Sansam (zg so 2x, 3x, 4x same nodes)
	[480167] = 425, -- Golden Sansam (zg so 2x, 3x, 4x same nodes)
	[176584] = 426, -- Dreamfoil
	[176639] = 426, -- Dreamfoil
	[180168] = 426, -- Dreamfoil (zg so 2x, 3x, 4x same nodes)
	[280168] = 426, -- Dreamfoil (zg so 2x, 3x, 4x same nodes)
	[380168] = 426, -- Dreamfoil (zg so 2x, 3x, 4x same nodes)
	[480168] = 426, -- Dreamfoil (zg so 2x, 3x, 4x same nodes)
	[176586] = 427, -- Mountain Silversage
	[176640] = 427, -- Mountain Silversage
	[180166] = 427, -- Mountain Silversage (zg so 2x, 3x, 4x same nodes)
	[280166] = 427, -- Mountain Silversage (zg so 2x, 3x, 4x same nodes)
	[380166] = 427, -- Mountain Silversage (zg so 2x, 3x, 4x same nodes)
	[480166] = 427, -- Mountain Silversage (zg so 2x, 3x, 4x same nodes)
	[176587] = 428, -- Plaguebloom
	[176641] = 428, -- Plaguebloom
	[176588] = 429, -- Icecap
--	[0000] = 430, -- Bloodvine -- zg bush loot
	[176589] = 431, -- Black Lotus
	[181270] = 432, -- Felweed
	[183044] = 432, -- Felweed
	[181271] = 433, -- Dreaming Glory
	[183045] = 433, -- Dreaming Glory
	[181277] = 434, -- Terocone
	[181278] = 435, -- Ancient Lichen -- instance only node
	[181166] = 436, -- Bloodthistle
	[181281] = 437, -- Mana Thistle
	[181279] = 438, -- Netherbloom
	[181280] = 439, -- Nightmare Vine
	[181275] = 440, -- Ragveil
	[183043] = 440, -- Ragveil
	[181276] = 441, -- Flame Cap
	[185881] = 442, -- Netherdust Bush
	[191019] = 443, -- Adder's Tongue
--	[3189974] = 444, -- Constrictor Grass -- drop from others
--	[0000] = 445, -- Deadnettle --looted from other plants
	[189973] = 446, -- Goldclover
	[190172] = 447, -- Icethorn
	[190171] = 448, -- Lichbloom
	[190170] = 449, -- Talandra's Rose
	[190169] = 450, -- Tiger Lily
	[191303] = 451, -- Firethorn
	[190173] = 452, -- Frozen Herb
	[190174] = 452, -- Frozen Herb
	[190175] = 452, -- Frozen Herb
	[190176] = 453, -- Frost Lotus -- found in lake wintergrasp only
	[254477] = 454, -- Emerald Amanita
}
local treasure = {
	[2744] = 501, -- Giant Clam
	[19017] = 501, -- Giant Clam
	[19018] = 501, -- Giant Clam
	[2843] = 502, -- Battered Chest
	[2849] = 502, -- Battered Chest
	[106318] = 502, -- Battered Chest
	[106319] = 502, -- Battered Chest
	[2844] = 503, -- Tattered Chest
	[2845] = 503, -- Tattered Chest
	[2846] = 503, -- Tattered Chest
	[2847] = 503, -- Tattered Chest
	[3715] = 503, -- Tattered Chest
	[4096] = 503, -- Tattered Chest
	[100559] = 503, -- Tattered Chest
	[100605] = 503, -- Tattered Chest
	[105578] = 503, -- Tattered Chest
	[105579] = 503, -- Tattered Chest
	[105581] = 503, -- Tattered Chest
	[111095] = 503, -- Tattered Chest
	[2850] = 504, -- Solid Chest
	[2852] = 504, -- Solid Chest
	[2855] = 504, -- Solid Chest
	[2857] = 504, -- Solid Chest
	[4149] = 504, -- Solid Chest
	[100598] = 504, -- Solid Chest
	[100606] = 504, -- Solid Chest
	[100614] = 504, -- Solid Chest
	[153451] = 504, -- Solid Chest
	[153453] = 504, -- Solid Chest
	[153454] = 504, -- Solid Chest
	[74447] = 505, -- Large Iron Bound Chest - 25
	[75295] = 5051, -- Large Iron Bound Chest - 1
	[75296] = 5052, -- Large Iron Bound Chest - 70
	[75297] = 5053, -- Large Iron Bound Chest - 125
	[74448] = 506, -- Large Solid Chest
	[75298] = 506, -- Large Solid Chest
	[75299] = 506, -- Large Solid Chest
	[75300] = 506, -- Large Solid Chest
	[153464] = 506, -- Large Solid Chest
	[253464] = 506, -- Large Solid Chest
	[353464] = 506, -- Large Solid Chest
	[453464] = 506, -- Large Solid Chest
	[75293] = 507, -- Large Battered Chest
	[123330] = 508, -- Buccaneer's Strongbox -1
	[123331] = 508, -- Buccaneer's Strongbox -1 (dupe)
	[123332] = 508, -- Buccaneer's Strongbox -1 (dupe)
	[123333] = 508, -- Buccaneer's Strongbox -1 (dupe)
	[131978] = 509, -- Large Mithril Bound Chest
	[153468] = 509, -- Large Mithril Bound Chest
	[153469] = 509, -- Large Mithril Bound Chest
	[131979] = 510, -- Large Darkwood Chest
	[157936] = 511, -- Un'Goro Dirt Pile
	[164958] = 512, -- Bloodpetal Sprout
	[176213] = 513, -- Blood of Heroes
	[178244] = 514, -- Practice Lockbox - 1
	[178246] = 514, -- Practice Lockbox - 1
	[100653] = 515, -- Battered Footlocker - 70
	[100661] = 5151, -- Battered Footlocker - 110
	[179486] = 515, -- Battered Footlocker - 70
	[179488] = 5151, -- Battered Footlocker - 110
	[179490] = 5152, -- Battered Footlocker - 150
	[179487] = 516, -- Waterlogged Footlocker - 70
	[179489] = 5161, -- Waterlogged Footlocker - 110
	[179491] = 5162, -- Waterlogged Footlocker - 150
	[179492] = 517, -- Dented Footlocker - 175
	[179494] = 5171, -- Dented Footlocker - 200
	[179496] = 5172, -- Dented Footlocker - 225
	[184741] = 5173, -- Dented Footlocker - 325
	[179493] = 518, -- Mossy Footlocker - 175
	[179497] = 5181, -- Mossy Footlocker - 225
	[179498] = 519, -- Scarlet Footlocker - 250
	[181665] = 520, -- Burial Chest - 1
	[181798] = 521, -- Fel Iron Chest
	[181800] = 522, -- Heavy Fel Iron Chest
	[181802] = 523, -- Adamantite Bound Chest - 350
	[181804] = 524, -- Felsteel Chest
	[182053] = 525, -- Glowcap
	[184740] = 526, -- Wicker Chest - 300
	[184793] = 527, -- Primitive Chest - 20
	[184930] = 528, -- Solid Fel Iron Chest
	[184931] = 529, -- Bound Fel Iron Chest - 300
	[184934] = 529, -- Bound Fel Iron Chest - 300
	[184936] = 530, -- Bound Adamantite Chest - 350
	[185915] = 531, -- Netherwing Egg
	[193997] = 532, -- Everfrost Chip
	[113768] = 533, -- Brightly Colored Egg
	[113769] = 533, -- Brightly Colored Egg
	[113770] = 533, -- Brightly Colored Egg
	[113771] = 533, -- Brightly Colored Egg
	[113772] = 533, -- Brightly Colored Egg
	[180228] = 535, -- Jinxed Hoodoo Pile (zg so 2x, 3x, 4x same nodes)
	[180229] = 535, -- Jinxed Hoodoo Pile (zg so 2x, 3x, 4x same nodes)
	[280228] = 535, -- Jinxed Hoodoo Pile (zg so 2x, 3x, 4x same nodes)
	[280229] = 535, -- Jinxed Hoodoo Pile (zg so 2x, 3x, 4x same nodes)
	[380228] = 535, -- Jinxed Hoodoo Pile (zg so 2x, 3x, 4x same nodes)
	[380229] = 535, -- Jinxed Hoodoo Pile (zg so 2x, 3x, 4x same nodes)
	[480228] = 535, -- Jinxed Hoodoo Pile (zg so 2x, 3x, 4x same nodes)
	[480229] = 535, -- Jinxed Hoodoo Pile (zg so 2x, 3x, 4x same nodes)
	--Silithus
	[967048] = 536, -- Hidden Cache
	[967049] = 537, -- Rare Hidden Cache
	[967050] = 538, -- Epic Hidden Cache
	[394922] = 539, -- Intangible Rose
	-- Burning Steppes
	[967039] = 536, -- Hidden Cache
	[967040] = 537, -- Rare Hidden Cache
	[967041] = 538, -- Epic Hidden Cache
	[395804] = 541, -- Lava Bloom
	--Blasted Lands
--	[000000] = 536, -- Hidden Cache
--	[000000] = 537, -- Rare Hidden Cache
--	[000000] = 538, -- Epic Hidden Cache
	--Azshara
	[967033] = 536, -- Hidden Cache
	[967034] = 537, -- Rare Hidden Cache
	[967035] = 538, -- Epic Hidden Cache
	[395798] = 540, -- Carnivorous Clam
	-- Eastern Plaguelands
	[967042] = 536, -- Hidden Cache
	[967043] = 537, -- Rare Hidden Cache
	[967044] = 538, -- Epic Hidden Cache
	[395743] = 542, -- Ravenous Scourgethorn
	--Western Plaguelands
	[967045] = 536, -- Hidden Cache
	[967046] = 537, -- Rare Hidden Cache
	[967047] = 538, -- Epic Hidden Cache
	--Un'Garo Crater
	[967017] = 536, -- Hidden Cache
	[967030] = 537, -- Rare Hidden Cache
	[967031] = 538, -- Epic Hidden Cache
	--Winterspring
	[967051] = 536, -- Hidden Cache
	[967052] = 537, -- Rare Hidden Cache
	[967053] = 538, -- Epic Hidden Cache
}
local trees = {
	[244630] = 601, -- Ashenvale Tree
	[244634] = 602, -- Azshara Tree
	[244631] = 603, -- Darkshore Tree
	[244620] = 604, -- Dun Morogh Tree
	[244628] = 605, -- Durotar Tree
	[244618] = 606, -- Duskwood Tree
	[244614] = 607, -- Elwynn Tree
	[244633] = 608, -- Felwood Tree
	[244621] = 609, -- Hillsbrad Tree
	[244622] = 610, -- Hinterland Tree
	[244619] = 611, -- Loch Modan Tree
	[244629] = 612, -- Mulgore Tree
	[244627] = 613, -- Plagueland Stump
	[244626] = 614, -- Plagueland Tree
	[244616] = 615, -- Redridge Tree
	[244623] = 616, -- Silverpine Tree
	[244636] = 617, -- Stonetalon Tree
	[244625] = 618, -- Swamp Stump
	[244632] = 619, -- Teldrassil Tree
	[244624] = 620, -- Tirisfal Tree
	[244617] = 621, -- Westfall Tree
	[244635] = 622, -- Winterspring Tree
}

local lastNode_ID = 0
-- Should be called for herb, mine, tree, treasure
function Collector:GameObject(event, objid)
	local x, y = GetPlayerMapPosition("player")
	if x == 0 and y == 0 then return end
	-- Temporary fix, the map "ScarletEnclave" and "EasternPlaguelands"
	-- both have the same English display name as "Eastern Plaguelands"
	-- so we ignore the new Death Knight starting zone for now.
	-- if GetMapInfo() == "ScarletEnclave" then return end TODO Validate in wrath, shoud be fine
	--self:GatherCompleted()
	if WorldMapFrame:IsShown() then return else SetMapToCurrentZone() end
	local zone = GetCurrentMapAreaID()
	local level = GetCurrentMapDungeonLevel()
	local node_type, node_id
	if mining[objid] then
		node_type = "Mining"
		node_id = mining[objid]
	elseif herbs[objid] then
		node_type = "Herb Gathering"
		node_id = herbs[objid]
	elseif treasure[objid] then
		node_type = "Treasure"
		node_id = treasure[objid]
	elseif trees[objid] then
		node_type = "Woodcutting"
		node_id = trees[objid]
	end
	-- print(objid, node_type, node_id) -- debug print
	if not node_type or not node_id then return end
	-- db lock check
	if GatherMate.db.profile.dbLocks[node_type] then return	end

	local range = GatherMate.db.profile.cleanupRange[node_type]
	local rares = self.rareNodes
	-- run through the nearby's
	local skip = false
	local foundCoord = GatherMate.mapData:EncodeLoc(x, y, level)
	local specialNode = false
	local specialNode_ID = node_id
	if foundCoord == lastNodeCoords and objid == lastNode_ID then return end
	--[[ DISABLE SPECIAL NODE PROCESSING FOR HERBS
	if self.specials[zone] and self.specials[zone][node_type] ~= nil then
		specialWhat = GatherMate:GetNameForNode(node_type,self.specials[zone][node_type])
		specialNode = true
	end
	--]]
	for coord, nodeID in GatherMate:FindNearbyNode(zone, x, y, level, node_type, range, true) do
		if (nodeID == node_id or rares[nodeID] and rares[nodeID][node_id]) then
			GatherMate:RemoveNodeByID(zone, node_type, coord)
		-- we're trying to add a rare node, but there is already a normal node present, skip the adding
		elseif rares[node_id] and rares[node_id][nodeID] then
			skip = true
		elseif specialNode then -- handle special case zone mappings
			skip = false
			GatherMate:RemoveNodeByID(zone, node_type, coord)
		end
	end

	if not skip then
		if specialNode then
			GatherMate:AddNodeByID(zone, x, y, level, node_type, specialNode_ID)
		else
			GatherMate:AddNodeByID(zone, x, y, level, node_type, node_id)
		end
		lastNode_ID = objid
		lastNodeCoords = foundCoord
	end
end