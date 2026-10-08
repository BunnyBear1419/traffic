local function electController()
 local players=GetPlayers()
 GlobalState.trafficDirectorController=tonumber(players[1] or 0) or 0
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
AddEventHandler('playerJoining',function() if not GlobalState.trafficDirectorController or GlobalState.trafficDirectorController==0 then electController() end end)
AddEventHandler('playerDropped',function(src)
 if tonumber(src)==tonumber(GlobalState.trafficDirectorController) then electController() end
end)
