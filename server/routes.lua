local function broadcast()
 TriggerClientEvent('traffic:client:data',-1,TrafficRoutes,TrafficZones,TrafficObstacles)
end
RegisterNetEvent('traffic:server:addRoute',function(route)
 if not TrafficPermissions.canLearn(source) or type(route)~='table' then return end
 route.id=route.id or ('route_%s_%s'):format(os.time(),math.random(1000,9999))
 route.createdBy=GetPlayerName(source) or 'console';route.createdAt=os.time();route.points=route.points or {}
 while #route.points>Config.Learning.maxPointsPerRoute do table.remove(route.points) end
 TrafficRoutes[route.id]=route;TrafficPersistence_save();broadcast()
end)
RegisterNetEvent('traffic:server:updateRoute',function(route)
 if not TrafficPermissions.isAdmin(source) or type(route)~='table' or not route.id then return end
 if not TrafficRoutes[route.id] then return end
 route.updatedAt=os.time();route.updatedBy=GetPlayerName(source) or 'console';route.points=route.points or {}
 while #route.points>Config.Learning.maxPointsPerRoute do table.remove(route.points) end
 TrafficRoutes[route.id]=route;TrafficPersistence_save();broadcast()
end)
RegisterNetEvent('traffic:server:deleteRoute',function(id)
 if not TrafficPermissions.isAdmin(source) then return end
 TrafficRoutes[id]=nil;TrafficPersistence_save();broadcast()
end)
RegisterNetEvent('traffic:server:addZone',function(zone)
 if not TrafficPermissions.isAdmin(source) or type(zone)~='table' then return end
 zone.id=zone.id or ('zone_%s_%s'):format(os.time(),math.random(1000,9999))
 TrafficZones[zone.id]=zone;TrafficPersistence_save();broadcast()
end)
RegisterNetEvent('traffic:server:deleteZone',function(id)
 if not TrafficPermissions.isAdmin(source) then return end
 TrafficZones[id]=nil;TrafficPersistence_save();broadcast()
end)
RegisterNetEvent('traffic:server:reportObstacle',function(hit)
 if type(hit)~='table' or not hit.x or not hit.y or not hit.z then return end
 local best,dist
 for id,o in pairs(TrafficObstacles) do
  local d=Traffic.distance({x=hit.x,y=hit.y,z=hit.z},{x=o.x,y=o.y,z=o.z})
  if d<12.0 and (not dist or d<dist) then best,dist=id,d end
 end
 if best then
  local o=TrafficObstacles[best];o.hits=(o.hits or 0)+1;o.lastSeen=os.time();o.heading=hit.heading or o.heading
 else
  local id=('obstacle_%s_%s'):format(os.time(),math.random(1000,9999))
  TrafficObstacles[id]={id=id,x=hit.x,y=hit.y,z=hit.z,hits=1,firstSeen=os.time(),lastSeen=os.time(),heading=hit.heading or 0}
 end
 TrafficPersistence_save();broadcast()
end)
RegisterNetEvent('traffic:server:deleteObstacle',function(id)
 if not TrafficPermissions.isAdmin(source) then return end
 TrafficObstacles[id]=nil;TrafficPersistence_save();broadcast()
end)
