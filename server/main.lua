local function controllerOnline(id)
 id=tonumber(id) or 0
 return id>0 and GetPlayerName(tostring(id))~=nil
end

local function electController()
 local players=GetPlayers()
 table.sort(players,function(a,b) return (tonumber(a) or 0)<(tonumber(b) or 0) end)
 GlobalState.trafficDirectorController=tonumber(players[1] or 0) or 0
end

local function ensureController()
 local current=tonumber(GlobalState.trafficDirectorController or 0) or 0
 if current==0 or not controllerOnline(current) then electController() end
end

RegisterNetEvent('traffic:server:setMode',function(mode)
 if not TrafficPermissions.isAdmin(source) or not Config.Modes[mode] then return end
 GlobalState.trafficDirectorMode=mode
end)

AddEventHandler('onResourceStart',function(resource)
 if resource==GetCurrentResourceName() then
  GlobalState.trafficDirectorMode=Config.DefaultMode
  electController()
 end
end)

AddEventHandler('playerJoining',function()
 ensureController()
end)

AddEventHandler('playerDropped',function()
 local dropped=tonumber(source) or 0
 if dropped==tonumber(GlobalState.trafficDirectorController) then
  electController()
 else
  ensureController()
 end
end)
