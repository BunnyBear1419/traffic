TrafficClientZones={}
TrafficClientObstacles={}
TrafficClientMode=Config.DefaultMode
RegisterNetEvent('traffic:client:data',function(routes,zones,obstacles)
 TrafficRoutes=routes or {};TrafficClientZones=zones or {};TrafficClientObstacles=obstacles or {}
end)
function TrafficZones_getAt(coords)
 local best,bd
 for _,z in pairs(TrafficClientZones) do
  local d=Traffic.distance(coords,z)
  local radius=z.radius or (Config.ZoneTypes[z.type] and Config.ZoneTypes[z.type].radius) or 60.0
  if d<=radius and (not bd or d<bd) then best,bd=z,d end
 end
 return best
end
CreateThread(function() while true do TrafficClientMode=GlobalState.trafficDirectorMode or Config.DefaultMode;Wait(1000) end end)
