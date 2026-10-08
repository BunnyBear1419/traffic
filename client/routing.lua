TrafficRouting={}
local progress={}
local lastTask={}
local function nearestRoute(coords,radius)
 local best,bd,bestIndex
 for _,route in pairs(TrafficRoutes or {}) do
  for i,p in ipairs(route.points or {}) do
   local d=Traffic.distance(coords,p)
   if d<=radius and (not bd or d<bd) then best,bd,bestIndex=route,d,i end
  end
 end
 return best,bestIndex
end
function TrafficRouting.getRouteForVehicle(vehicle)
 local z=TrafficZones_getAt(GetEntityCoords(vehicle))
 if z and z.routeId and TrafficRoutes[z.routeId] then return TrafficRoutes[z.routeId] end
 local route,index=nearestRoute(GetEntityCoords(vehicle),Config.RouteSnapDistance)
 if route then progress[vehicle]=progress[vehicle] or index end
 return route
end
function TrafficRouting.driveRoute(vehicle,route)
 if not route or not route.points or #route.points<2 then return false end
 local idx=progress[vehicle] or 1
 local p=GetEntityCoords(vehicle)
 local bestDist=99999.0
 for i=idx,math.min(#route.points,idx+8) do
  local d=Traffic.distance(p,route.points[i])
  if d<bestDist then bestDist=d;idx=i end
 end
 if bestDist<10.0 then idx=idx+1 end
 if idx>#route.points then idx=route.loop and 1 or #route.points end
 progress[vehicle]=idx
 local target=route.points[idx]
 if not target then return false end
 local now=GetGameTimer()
 if not lastTask[vehicle] or now-lastTask[vehicle]>1500 then
  local mode=Config.Modes[TrafficClientMode] or Config.Modes.normal
  TaskVehicleDriveToCoordLongrange(vehicle,target.x,target.y,target.z,14.0*mode.speed,786603,4.0)
  lastTask[vehicle]=now
 end
 return true
end
function TrafficRouting.redirectToRoad(vehicle)
 local p=GetEntityCoords(vehicle)
 local node=TrafficDetection.findRoadPoint(p,GetEntityHeading(vehicle))
 if node then TaskVehicleDriveToCoordLongrange(vehicle,node.x,node.y,node.z,13.0,786603,5.0);return true end
 return false
end
function TrafficRouting.reset(vehicle) progress[vehicle]=nil;lastTask[vehicle]=nil end
