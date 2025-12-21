-- nearby check yes/no? slowdown may be an isue if someone leaves the mod enabled and always replace node
local GatherMateData = LibStub("AceAddon-3.0"):NewAddon("GatherMate2_Data")
local GatherMate = LibStub("AceAddon-3.0"):GetAddon("GatherMate2")

local bcZones = {
	[3522] = true, -- Blade's Edge Mountains
	[3483] = true, -- Hellfire Peninsula
	[3518] = true, -- Nagrand
	[3523] = true, -- Netherstorm
	[3520] = true, -- Shadowmoon Valley
	[3703] = true, -- Shattrath City
	[3519] = true, -- Terokkar Forest
	[3521] = true, -- Zangarmarsh
	[3430] = true, -- Eversong Woods
	[3433] = true, -- Ghostlands
	[4080] = true, -- Isle of Quel'Danas
	[3487] = true, -- Silvermoon City
	[3524] = true, -- Azuremyst Isle
	[3525] = true, -- Bloodmyst Isle
	[3557] = true, -- The Exodar
}
-- FIX to new Zone numbers
local wrathZones = {
	[3537] = true, -- Borean Tundra
	[2817] = true, -- Crystalsong Forest
	[4395] = true, -- Dalaran
	[65] = true, -- Dragonblight
	[394] = true, -- Grizzly Hills
	[495] = true, -- Howling Fjord
	[4742] = true, -- Hrothgar's Landing
	[210] = true, -- Icecrown
	[3711] = true, -- Sholazar Basin
	[67] = true, -- The Storm Peaks
	[4197] = true, -- Wintergrasp
	[66] = true, -- Zul'Drak
	[4298] = true, -- Plaguelands: The Scarlet Enclave
}

function GatherMateData:PerformMerge(dbs,style, zoneFilter)
	local filter = nil
	if zoneFilter and type(zoneFilter) == "string" then
		if zoneFilter == "TBC" then
			filter = bcZones
		elseif zoneFilter == "WRATH" then
			filter = wrathZones
		end
	elseif zoneFilter then
		filter = bcZones
	end
	if dbs["Mines"]    then self:MergeNodes(style ~= "Merge", filter, "Mining", GatherMateData2MineDB) end
	if dbs["Herbs"]    then self:MergeNodes(style ~= "Merge", filter, "Herb Gathering", GatherMateData2HerbDB) end
	if dbs["Gases"]    then self:MergeNodes(style ~= "Merge", filter, "Extract Gas", GatherMateData2GasDB) end
	if dbs["Fish"]     then self:MergeNodes(style ~= "Merge", filter, "Fishing", GatherMateData2FishDB) end
	if dbs["Treasure"] then self:MergeNodes(style ~= "Merge", filter, "Treasure", GatherMateData2TreasureDB) end
	if dbs["Woodcutting"] then self:MergeNodes(style ~= "Merge", filter, "Woodcutting", GatherMateData2TreeDB) end
	if dbs["Worldforged"] then self:MergeNodes(style ~= "Merge" and not dbs["Treasure"], filter, "Treasure", GatherMateData2WFDB) end -- put worldforged items in the treasure table
	self:CleanupImportData()
	GatherMate:SendMessage("GatherMateData2Import")
	--GatherMate:CleanupDB()
end

-- Insert data
function GatherMateData:MergeNodes(clear, zoneFilter, ntype, sourcevar)
	if GatherMate.db.profile.dbLocks[ntype] then
		GatherMate:Print(string.format("%s is locked and cannot be updated at this time", ntype))
		return
	end
	if clear then GatherMate:ClearDB(ntype) end
	for zoneID, node_table in pairs(sourcevar) do
		if not zoneFilter or (zoneFilter and zoneFilter[zoneID]) then
			for nodeID, nodes in pairs(node_table) do
				for _, coord in ipairs(nodes) do
					GatherMate:InjectNode(zoneID, coord, ntype, nodeID)
				end
			end
		end
	end
end


function GatherMateData:CleanupImportData()
	GatherMateData2HerbDB = nil
	GatherMateData2MineDB = nil
	GatherMateData2GasDB = nil
	GatherMateData2FishDB = nil
	GatherMateData2TreasureDB = nil
	GatherMateData2TreeDB = nil
	GatherMateData2WFDB = nil
end
