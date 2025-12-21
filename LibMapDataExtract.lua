--[[
A trimmed down version of LibMapData-1.0 including only the parts that Gathermate2 uses
]]

local GatherMate = LibStub("AceAddon-3.0"):GetAddon("GatherMate2")

GatherMate.mapData = {}

local nametoid = {}
local idtodxdy = {}
local mapToLocal = {}

-- Don't know a better way
-- Build list of areaIDs
for i=0,9999 do
	if C_WorldMap.GetWorldPosition(i, 0, 0) then -- and mapToLocal[C_WorldMap.GetMapFileByAreaID(i)] then
		local x1, y1 = C_WorldMap.GetWorldPosition(i, 0, 0)
		local x2, y2 = C_WorldMap.GetWorldPosition(i, 1, 1)
        local mapfile = C_WorldMap.GetMapFileByAreaID(i)
		nametoid[mapfile] = i
        -- if map zoneid isn't valid then save mapfile name.  Prevents issue with MapLocalize
		local zoneID = C_WorldMap.GetZoneIDByAreaID(i)
		if zoneID > 0 then
			mapToLocal[mapfile] = GetAreaName(zoneID)
		else
			mapToLocal[mapfile] = mapfile
		end
        idtodxdy[i] = { [1] = abs(x1-x2), [2] = abs(y1-y2) }
	end
end

function GatherMate.mapData:MapLocalize(mapfile)
	if mapfile == WORLDMAP_COSMIC_ID then return WORLD_MAP end
	if type(mapfile) == "number" then
		local zoneID = C_WorldMap.GetZoneIDByAreaID(mapfile)
		if zoneID > 0 and GetAreaName(zoneID)then
			return GetAreaName(zoneID)
		else
			return C_WorldMap.GetMapFileByAreaID(mapfile)
		end
	end
    return mapToLocal[mapfile]
end

function GatherMate.mapData:EncodeLoc(x,y,level)
	local level = level or 0
	if x > 0.9999 then
		x = 0.9999
	end
	if y > 0.9999 then
		y = 0.9999
	end
	return floor( x * 10000 + 0.5 ) * 1000000 + floor( y * 10000  + 0.5 ) * 100 + level
end

function GatherMate.mapData:DecodeLoc(id)
	return floor(id/1000000)/10000, floor(id % 1000000 / 100)/10000, id % 100
end

function GatherMate.mapData:GetAllMapIDs(id)
	return nametoid
end

function GatherMate.mapData:MapAreaId(mapFile)
	return nametoid[mapFile]
end

function GatherMate.mapData:MapArea(id)
	if type(id) == "string" then
		id = nametoid[id]
	end
    if idtodxdy[id] then
    	return idtodxdy[id][1], idtodxdy[id][2]
    else
        return 0, 0
    end
end
