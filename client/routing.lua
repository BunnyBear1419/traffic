TrafficRouting={}
local progress={}
local lastTask={}
local activeRoute={}
local routeStarted={}
local routeDistance={}
local lastSuccessReport={}
local function avoidancePenalty(p,routeId)
 if not Config.RouteAvoidance.enabled then return 0 end
 local score=0
 for _,a in pairs(TrafficClientAvoidance or {}) do
  local d=Traffic.distance(p,a)
  if d<=Config.RouteAvoidance.radius then
   local routeMatch=routeId and a.routeIds and a.routeIds[routeId]
   score=score+(a.hits or 1)*Config.RouteAvoidance.penalty*(routeMatch and 1.25 or 1.0)
  end
 end
 return score
end
local function hotspotPenalty(p)
 if not Config.AdaptiveRouting.enabled then return 0 end
 local score=0
 for _,o in pairs(TrafficClientObstacles or {}) do
  local d=Traffic.distance(p,o)
  if d<=Config.AdaptiveRouting.avoidRadius then score=score+(o.hits or 1)*Config.AdaptiveRouting.failurePenalty end
 end
 return score+avoidancePenalty(p)
end
local function routeScore(route,coords)
 local first=route.points and route.points[1]
 local d=first and Traffic.distance(coords,first) or 99999
 local confidence=tonumber(route.confidence) or 0
 local failures=tonumber(route.failures) or 0
 local successes=tonumber(route.successes) or 0
 local hotspot=hotspotPenalty(first or coords)
 local avoid=avoidancePenalty(first or coords,route.id)
 return d+(failures*Config.AdaptiveRouting.failurePenalty)-(successes*Config.AdaptiveRouting.confidenceBonus)-confidence+hotspot+avoid
end
local function nearestRoute(coords,radius)
 local candidates={}
 for _,route in pairs(TrafficRoutes or {}) do
  if route.points and #route.points>=2 then
   local bestDist,bestIndex=99999,nil
   for i,p in ipairs(route.points) do
    local d=Traffic.distance(coords,p)
    if d<=radius and d<bestDist then bestDist,bestIndex=d,i end
   end
   if bestIndex then
    candidates[#candidates+1]={route=route,distance=bestDist,index=bestIndex,score=routeScore(route,coords)}
   end
  end
 end
 table.sort(candidates,function(a,b) return a.score<b.score end)
 local best=candidates[1]
 return best and best.route,best and best.index
end
function TrafficRouting.getRouteForVehicle(vehicle)
 if not TrafficAdjustor.isFeatureEnabled('routing') then return nil end
 local z=TrafficZones_getAt(GetEntityCoords(vehicle))
 if z and z.routeId and TrafficRoutes[z.routeId] then
  activeRoute[vehicle]=TrafficRoutes[z.routeId]
  return TrafficRoutes[z.routeId]
 end
 local route,index=nearestRoute(GetEntityCoords(vehicle),Config.RouteSnapDistance)
 if route then
  progress[vehicle]=progress[vehicle] or index
  activeRoute[vehicle]=route
 else
  progress[vehicle]=nil;activeRoute[vehicle]=nil
 end
 return route
end
function TrafficRouting.getActiveRoute(vehicle) return activeRoute[vehicle] end
function TrafficRouting.getProgressIndex(vehicle) local s=routeDistance[vehicle];return s and s.nearest or 0 end
function TrafficRouting.trackProgress(vehicle,route)
 if not Config.RouteLearning.enabled or not route or not route.id then return end
 local previous=activeRoute[vehicle]
 activeRoute[vehicle]=route
 if previous and previous.id~=route.id then
  routeStarted[vehicle]=GetGameTimer();routeDistance[vehicle]=nil;lastSuccessReport[vehicle]=nil
 end
 routeStarted[vehicle]=routeStarted[vehicle] or GetGameTimer()
 local p=GetEntityCoords(vehicle);local last=routeDistance[vehicle]
 if not last then routeDistance[vehicle]={x=p.x,y=p.y,z=p.z,total=0,nearest=0};return end
 local d=Traffic.distance(p,last);if d>0 and d<100 then last.total=(last.total or 0)+d end
 last.x=p.x;last.y=p.y;last.z=p.z
 local nearest,best=last.nearest or 0,99999.0
 for i=1,#route.points do
  local pd=Traffic.distance(p,route.points[i])
  if pd<best then best=pd;nearest=i end
 end
 last.nearest=nearest
end
function TrafficRouting.successCandidate(vehicle,route)
 if not Config.RouteLearning.enabled or not route or not route.id or not route.points or #route.points<2 then return false end
 local s=routeDistance[vehicle];local started=routeStarted[vehicle]
 if not s or not started or (s.total or 0)<Config.RouteLearning.minProgressDistance or GetEntitySpeed(vehicle)<Config.RouteLearning.minSuccessSpeed then return false end
 local nearest=s.nearest or 0
 local completed=nearest>=math.max(2,#route.points-1)
 if not completed and route.loop and nearest>=math.floor(#route.points*0.8) then completed=true end
 if not completed then return false end
 local now=GetGameTimer();if lastSuccessReport[vehicle] and now-lastSuccessReport[vehicle]<Config.RouteLearning.successWindow then return false end
 lastSuccessReport[vehicle]=now
 TriggerServerEvent('traffic:server:routeSuccess',{routeId=route.id,distance=s.total,progressIndex=nearest,completed=true})
 return true
end
function TrafficRouting.driveRoute(vehicle,route)
 if not TrafficAdjustor.isFeatureEnabled('routing') then return false end
 if not route or not route.points or #route.points<2 then return false end
 activeRoute[vehicle]=route
 local idx=progress[vehicle] or 1
 local p=GetEntityCoords(vehicle)
 local bestDist=99999.0
 for i=idx,math.min(#route.points,idx+8) do
  local d=Traffic.distance(p,route.points[i])
  if d<bestDist then bestDist=d;idx=i end
 end
 if bestDist<10.0 then idx=idx+1 end
 local candidate=route.points[idx];local tries=0
 -- Turn-aware lookahead: prefer the next learned heading instead of allowing a shortcut around a taught turn.
 if candidate and candidate.heading then
  local lookahead=math.min(#route.points,idx+2)
  local turnPoint=route.points[lookahead]
  if turnPoint and turnPoint.heading then candidate=turnPoint end
 end
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
  if not TrafficOwnership.ensure(vehicle) or not Traffic.nativeSafetyEnabled('vehicleTasks') then return false end
  local mode=Config.Modes[TrafficClientMode] or Config.Modes.normal
  Traffic.nativeProbe('Routing','TaskVehicleDriveToCoordLongrange',true)
  TaskVehicleDriveToCoordLongrange(vehicle,target.x,target.y,target.z,14.0*mode.speed,786603,4.0)
  lastTask[vehicle]=now
 end
 return true
end
function TrafficRouting.redirectToRoad(vehicle)
 if not TrafficAdjustor.isFeatureEnabled('routing') then return false end
 if not TrafficOwnership.ensure(vehicle) then return false end
 local p=GetEntityCoords(vehicle);local node=TrafficDetection.findRoadPoint(p,GetEntityHeading(vehicle))
 if node and Traffic.nativeSafetyEnabled('vehicleTasks') and Traffic.nativeProbe('Routing','TaskVehicleDriveToCoordLongrange',true) then TaskVehicleDriveToCoordLongrange(vehicle,node.x,node.y,node.z,13.0,786603,5.0);return true end
 return false
end
function TrafficRouting.reset(vehicle)
 progress[vehicle]=nil;lastTask[vehicle]=nil;activeRoute[vehicle]=nil;routeStarted[vehicle]=nil;routeDistance[vehicle]=nil;lastSuccessReport[vehicle]=nil
end