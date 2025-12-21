--[[
Basic node sharing for Gathermate2

Will attempt to send any gathered nodes to guild and receive nodes from other guildies

Allows:
    Silent Allow List
    Deny List for senders
    Delay sending nodes if not in No Risk
    Report any recieved node, can filter messages from auto accept list
    Send to Guild, Party, Raid
    Receive from Guild, Party, Raid

TODO:
    Allow sharing of all known nodes of specific types to another player, group, or raid
    LibDeflate
]]

local GatherMate = LibStub("AceAddon-3.0"):GetAddon("GatherMate2")
local Comm = LibStub:GetLibrary("AceComm-3.0")
local defaultPrefix = "GatherMate2"

-- Send Gather Data
function GatherMate:SendNode(zone, id, nodeType, nodeid)
    local text = string.format("%d:%s:%s:%d", zone, tostring(id), nodeType, nodeid)

    if GatherMate.db.profile.accept_guild then Comm:SendCommMessage(defaultPrefix, text, "GUILD") end
    if GatherMate.db.profile.accept_guild then Comm:SendCommMessage(defaultPrefix, text, "PARTY") end
    if GatherMate.db.profile.accept_guild then Comm:SendCommMessage(defaultPrefix, text, "RAID") end

    if GatherMate.db.profile.print_gather then 
        local x, y = GatherMate.mapData:DecodeLoc(id)
        GatherMate:Pour(string.format("Gathered %s Node. (%.2f, %.2f) in %s", GatherMate.reverseNodeIDs[nodeType][nodeid], x*100, y*100, GatherMate.mapData:MapLocalize(zone)))
    end
end

local lastmessage = ""
-- Get Gather Data
Comm:RegisterComm(defaultPrefix, function(prefix, message, source, sender)
    if sender == UnitName("player") or -- ignore messages from yourself
       message == lastmessage or -- Since we can accept messages from party, raid, and guild.  Simple check to cut down on some of the spam
       GatherMate.db.profile.ignored_players[sender] or
       (source == "GUILD" and not GatherMate.db.profile.accept_guild) or
       (source == "PARTY" and not GatherMate.db.profile.accept_party) or
       (source == "RAID" and not GatherMate.db.profile.accept_raid) then return end

    lastmessage = message
    local zoneID, coord, ntype, nodeID = string.match(message, "^(.+):(.+):(.+):(.+)$")
    zoneID = tonumber(zoneID)
    local coord = tonumber(coord)
    nodeID = tonumber(nodeID)
    GatherMate:InjectNode(zoneID, coord, ntype, nodeID)
    if WorldMapFrame:IsShown() then GatherMate:UpdateWorldMap(true) end
    if (source == "GUILD" and GatherMate.db.profile.print_guild) or
       (source == "PARTY" and GatherMate.db.profile.print_party) or
       (source == "RAID" and GatherMate.db.profile.print_raid) then
        local x, y = GatherMate.mapData:DecodeLoc(coord)
        GatherMate:Pour(string.format("%s Node from %s. (%.2f, %.2f) in %s", GatherMate.reverseNodeIDs[ntype][nodeID], sender, x*100, y*100, GatherMate.mapData:MapLocalize(zoneID)))
    end
end)