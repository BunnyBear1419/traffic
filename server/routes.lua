RegisterNetEvent('traffic:server:addRoute',function(route)
 if not TrafficPermissions.canLearn(source) or type(route)~='table' then return end
 route.id=route.id or ('route_%s_%s'):format(os.time(),math.random(1000,9999))
 route.createdBy=GetPlayerName(source) or 'console'; route.createdAt=os.time(); route.points=route.points or {}
 while #route.points>Config.Learning.maxPointsPerRoute do table.remove(route.points) end
 TrafficRoutes[route.id]=route; TrafficPersistence_save()
 TriggerClientEvent('traffic:client:data',-1,TrafficRoutes,TrafficZones)
end)
RegisterNetEvent('traffic:server:deleteRoute',function(id)
 if not TrafficPermissions.isAdmin(source) then return end
 TrafficRoutes[id]=nil; TrafficPersistence_save(); TriggerClientEvent('traffic:client:data',-1,TrafficRoutes,TrafficZones)
end)
RegisterNetEvent('traffic:server:addZone',function(zone)
 if not TrafficPermissions.isAdmin(source) or type(zone)~='table' then return end
 zone.id=zone.id or ('zone_%s_%s'):format(os.time(),math.random(1000,9999))
 TrafficZones[zone.id]=zone; TrafficPersistence_save(); TriggerClientEvent('traffic:client:data',-1,TrafficRoutes,TrafficZones)
end)
RegisterNetEvent('traffic:server:deleteZone',function(id)
 if not TrafficPermissions.isAdmin(source) then return end
 TrafficZones[id]=nil; TrafficPersistence_save(); TriggerClientEvent('traffic:client:data',-1,TrafficRoutes,TrafficZones)
end)
