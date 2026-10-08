TrafficRouting={}
local progress={}
local lastTask={}
local function hotspotPenalty(p)
 if not Config.AdaptiveRouting.enabled then return 0 end
 local score=0
 for _,o in pairs(TrafficClientObstacles or {}) do
  local d=Traffic.distance(p,o)
  if d<=Config.AdaptiveRouting.avoidRadius then score=score+(o.hits or 1)*Config.AdaptiveRouting.failurePenalty end
 end
 return score
end
local function routeScore(route,coords)
 local first=route.points and route.points[1]
 local d=first and Traffic.distance(coords,first) or 99999
 local confidence=tonumber(route.confidence) or 0
 local failures=tonumber(route.failures) or 0
 local successes=tonumber(route.successes) or 0
 return d+(failures*Config.AdaptiveRouting.failurePenalty)-(successes*Config.AdaptiveRouting.confidenceBonus)-confidence-hotspotPenalty(first or coords)
end
local function nearestRoute(coords,radius)
 local best,bd,bestIndex,bestScore
 for _,route in pairs(TrafficRoutes or {}) do
  for i,p in ipairs(route.points or {}) do
   local d=Traffic.distance(coords,p)
   if d<=radius then
    local score=d+(route.failures or 0)*Config.AdaptiveRouting.failurePenalty-(route.successes or 0)*Config.AdaptiveRouting.confidenceBonus-(route.confidence or 0)+hotspotPenalty(p)
    if not bestScore or score<bestScore then best,bd,bestIndex,bestScore=route,d,i,score end
   end
  end
 end
 return best,bestIndex
end
function TrafficRouting.getRouteForVehicle(vehicle)
 if not TrafficAdjustor.isFeatureEnabled('routing') then return nil end
 local z=TrafficZones_getAt(GetEntityCoords(vehicle))
 if z and z.routeId and TrafficRoutes[z.routeId] then return TrafficRoutes[z.routeId] end
 local route,index=nearestRoute(GetEntityCoords(vehicle),Config.RouteSnapDistance)
 if route then progress[vehicle]=progress[vehicle] or index end
 return route
end
function TrafficRouting.driveRoute(vehicle,route)
 if not TrafficAdjustor.isFeatureEnabled('routing') then return false end
 if not route or not route.points or #route.points<2 then return false end
 local idx=progress[vehicle] or 1
 local p=GetEntityCoords(vehicle)
 local bestDist=99999.0
 for i=idx,math.min(#route.points,idx+8) do
  local d=Traffic.distance(p,route.points[i])
  if d<bestDist then bestDist=d;idx=i end
 end
 if bestDist<10.0 then idx=idx+1 end
 local candidate=route.points[idx];local tries=0
 while candidate and hotspotPenalty(candidate)>Config.AdaptiveRouting.failurePenalty do
  idx=idx+1;tries=tries+1
  if tries>=8 then break end
  if idx>#route.points then idx=route.loop and 1 or #route.points end
  candidate=route.points[idx]
 end
 if idx>#route.points then idx=route.loop and 1 or #route.points end
 progress[vehicle]=idx
 local target=route.points[idx]
 if not target then return false end
 local now=GetGameTimer()
 if not lastTask[vehicle] or now-lastTask[vehicle]>1500 then
  if not TrafficOwnership.ensure(vehicle) then return false end
  local mode=Config.Modes[TrafficClientMode] or Config.Modes.normal
  TaskVehicleDriveToCoordLongrange(vehicle,target.x,target.y,target.z,14.0*mode.speed,786603,4.0)
  lastTask[vehicle]=now
 end
 return true
end
function TrafficRouting.redirectToRoad(vehicle)
 if not TrafficAdjustor.isFeatureEnabled('routing') then return false end
 if not TrafficOwnership.ensure(vehicle) then return false end
 local p=GetEntityCoords(vehicle);local node=TrafficDetection.findRoadPoint(p,GetEntityHeading(vehicle))
 if node then TaskVehicleDriveToCoordLongrange(vehicle,node.x,node.y,node.z,13.0,786603,5.0);return true end
 return false
end
function TrafficRouting.reset(vehicle) progress[vehicle]=nil;lastTask[vehicle]=nil end
