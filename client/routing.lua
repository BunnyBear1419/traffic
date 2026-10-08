TrafficRouting={}
local function nearestRoute(coords,radius)
 local best,bd
 for _,route in pairs(TrafficRoutes or {}) do
  for i,p in ipairs(route.points or {}) do
   local d=Traffic.distance(coords,p)
   if d<=radius and (not bd or d<bd) then best,bd=route,d; route._runtimeIndex=i end
  end
 end
 return best
end
function TrafficRouting.getRouteForVehicle(vehicle)
 local z=TrafficZones_getAt(GetEntityCoords(vehicle))
 if z and z.routeId and TrafficRoutes[z.routeId] then return TrafficRoutes[z.routeId] end
 return nearestRoute(GetEntityCoords(vehicle),Config.RouteSnapDistance)
end
function TrafficRouting.driveRoute(vehicle,route)
 if not route or not route.points or #route.points<2 then return false end
 local idx=route._runtimeIndex or 1; local target=route.points[idx]
 if Traffic.distance(GetEntityCoords(vehicle),target)<10.0 then
  idx=idx+1; if idx>#route.points then idx=route.loop and 1 or #route.points end
  route._runtimeIndex=idx; target=route.points[idx]
 end
 if not target then return false end
 local mode=Config.Modes[TrafficClientMode] or Config.Modes.normal
 TaskVehicleDriveToCoordLongrange(vehicle,target.x,target.y,target.z,14.0*mode.speed,786603,4.0)
 return true
end
function TrafficRouting.redirectToRoad(vehicle)
 local p=GetEntityCoords(vehicle); local node=TrafficDetection.findRoadPoint(p,GetEntityHeading(vehicle))
 if node then TaskVehicleDriveToCoordLongrange(vehicle,node.x,node.y,node.z,13.0,786603,5.0); return true end
 return false
end
