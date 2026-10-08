RegisterNetEvent('traffic:server:setMode',function(mode)
 if not TrafficPermissions.isAdmin(source) or not Config.Modes[mode] then return end
 GlobalState.trafficDirectorMode=mode
end)
AddEventHandler('onResourceStart',function(resource)
 if resource==GetCurrentResourceName() then GlobalState.trafficDirectorMode=Config.DefaultMode end
end)
