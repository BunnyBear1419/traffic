local reportRate={}
local failureRate={}
local function broadcast() TriggerClientEvent('traffic:client:data',-1,TrafficRoutes,TrafficZones,TrafficObstacles,TrafficRouteAvoidance) end
local function cleanupAvoidance(now)
 if not Config.RouteAvoidance.enabled then return false end
 local changed=false;local ttl=Config.RouteAvoidance.decayHours*3600
 for id,a in pairs(TrafficRouteAvoidance) do
  if ttl>0 and now-(a.lastSeen or now)>ttl then TrafficRouteAvoidance[id]=nil;changed=true end
 end
 return changed
end
local function upsertAvoidance(data,now)
 if not Config.RouteAvoidance.enabled or not data.coords then return end
 local c=data.coords;local best,dist
 for id,a in pairs(TrafficRouteAvoidance) do
  local d=Traffic.distance(c,a)
  if d<=Config.RouteAvoidance.radius and (not dist or d<dist) then best,dist=id,d end
 end
 if best then
  local a=TrafficRouteAvoidance[best];a.hits=(a.hits or 0)+1;a.lastSeen=now;a.reason=tostring(data.reason or a.reason or 'route_failure'):sub(1,40);a.routeIds=a.routeIds or {};if data.routeId then a.routeIds[data.routeId]=true end
 else
  local count=0;for _ in pairs(TrafficRouteAvoidance) do count=count+1 end
  if count>=Config.RouteAvoidance.maxEntries then
   local oldestId,oldest
   for id,a in pairs(TrafficRouteAvoidance) do if not oldest or (a.lastSeen or 0)<oldest then oldestId,oldest=id,a.lastSeen or 0 end end
   if oldestId then TrafficRouteAvoidance[oldestId]=nil end
  end
  local id=('avoid_%s_%s'):format(os.time(),math.random(1000,9999))
  TrafficRouteAvoidance[id]={id=id,x=num(c.x,0),y=num(c.y,0),z=num(c.z,0),hits=1,firstSeen=now,lastSeen=now,reason=tostring(data.reason or 'route_failure'):sub(1,40),routeIds=data.routeId and {[data.routeId]=true} or {}}
 end
end
local function allowedReport(src)
 local now=os.time();local last=reportRate[src] or 0
 if now-last<2 then return false end
 reportRate[src]=now
 return true
end
local function num(v,default)
 v=tonumber(v);if not v or v~=v or math.abs(v)>10000000 then return default end
 return v
end
local function sanitizePoint(p)
 if type(p)~='table' then return nil end
 if not p.x or not p.y or not p.z then return nil end
 return {x=num(p.x,0),y=num(p.y,0),z=num(p.z,0),heading=num(p.heading,0),dx=num(p.dx,nil),dy=num(p.dy,nil)}
end
local function sanitizeRoute(route)
 if type(route)~='table' then return nil end
 local points={}
 for _,p in ipairs(route.points or {}) do
  local q=sanitizePoint(p);if q then points[#points+1]=q end
  if #points>=Config.Learning.maxPointsPerRoute then break end
 end
 if #points<2 then return nil end
 route.points=points;route.name=tostring(route.name or 'Learned Route'):sub(1,80)
 route.loop=route.loop==true
 route.confidence=num(route.confidence,0);route.successes=math.max(0,math.floor(num(route.successes,0)))
 route.failures=math.max(0,math.floor(num(route.failures,0)))
 return route
end
local function classifyObstacle(hit)
 if not Config.MLOIntelligence.enabled then return 'unknown' end
 if hit.category and type(hit.category)=='string' then
  for _,name in ipairs(Config.MLOIntelligence.categories) do if hit.category==name then return name end end
 end
 if hit.reason=='garage' then return 'garage' end
 if hit.reason=='tunnel' then return 'tunnel' end
 if hit.reason=='parking' then return 'parking' end
 if (hit.hits or 1)>=Config.MLOIntelligence.minimumHits then return 'building_entrance' end
 return 'blocked_road'
end
RegisterNetEvent('traffic:server:addRoute',function(route)
 if not TrafficPermissions.canLearn(source) then return end
 route=sanitizeRoute(route);if not route then return end
 route.id=route.id or ('route_%s_%s'):format(os.time(),math.random(1000,9999))
 route.createdBy=GetPlayerName(source) or 'console';route.createdAt=os.time()
 TrafficRoutes[route.id]=route;TrafficPersistence_save();broadcast()
end)
RegisterNetEvent('traffic:server:discoverRoute',function(route)
 if not Config.AutoDiscovery.enabled or type(route)~='table' then return end
 if not allowedReport(source) then return end
 route=sanitizeRoute(route);if not route then return end
 local merged=nil
 for id,r in pairs(TrafficRoutes) do
  if r.autoDiscovered and r.points and r.points[1] and route.points[1] and Traffic.distance(r.points[1],route.points[1])<Config.RouteSnapDistance then merged=id;break end
 end
 if merged then
  local r=TrafficRoutes[merged];r.successes=(r.successes or 0)+1;r.confidence=math.min(100,(r.confidence or 0)+Config.AutoDiscovery.confidenceGain)
  if #r.points<#route.points then r.points=route.points end
 else
  local count=0;for _,r in pairs(TrafficRoutes) do if r.autoDiscovered then count=count+1 end end
  if count<Config.AutoDiscovery.maxCandidates then
   route.id=('auto_%s_%s'):format(os.time(),math.random(1000,9999));route.name='Auto-discovered route';route.autoDiscovered=true
   route.createdBy='Traffic Intelligence';route.createdAt=os.time();route.successes=1;route.confidence=Config.AutoDiscovery.confidenceStart
   TrafficRoutes[route.id]=route
  end
 end
 TrafficPersistence_save();broadcast()
end)
RegisterNetEvent('traffic:server:updateRoute',function(route)
 if not TrafficPermissions.isAdmin(source) or type(route)~='table' or not route.id or not TrafficRoutes[route.id] then return end
 route=sanitizeRoute(route);if not route then return end
 route.id=route.id;route.updatedAt=os.time();route.updatedBy=GetPlayerName(source) or 'console'
 TrafficRoutes[route.id]=route;TrafficPersistence_save();broadcast()
end)
RegisterNetEvent('traffic:server:deleteRoute',function(id)
 if not TrafficPermissions.isAdmin(source) or type(id)~='string' then return end
 TrafficRoutes[id]=nil
 if Config.RouteAvoidance.clearOnRouteDelete then
  for aid,a in pairs(TrafficRouteAvoidance) do if a.routeIds then a.routeIds[id]=nil;local any=false;for _ in pairs(a.routeIds) do any=true;break end;if not any then TrafficRouteAvoidance[aid]=nil end end end
 end
 TrafficPersistence_save();broadcast()
end)
RegisterNetEvent('traffic:server:deleteAvoidance',function(id)
 if not TrafficPermissions.isAdmin(source) or type(id)~='string' then return end
 TrafficRouteAvoidance[id]=nil;TrafficPersistence_save();broadcast()
end)
RegisterNetEvent('traffic:server:addZone',function(zone)
 if not TrafficPermissions.isAdmin(source) or type(zone)~='table' then return end
 zone.id=zone.id or ('zone_%s_%s'):format(os.time(),math.random(1000,9999))
 zone.type=Config.ZoneTypes[zone.type] and zone.type or 'normal'
 zone.radius=math.max(10,math.min(500,num(zone.radius,Config.ZoneTypes[zone.type].radius)))
 zone.x=num(zone.x,0);zone.y=num(zone.y,0);zone.z=num(zone.z,0);zone.heading=num(zone.heading,0)
 zone.name=tostring(zone.name or zone.type):sub(1,80)
 TrafficZones[zone.id]=zone;TrafficPersistence_save();broadcast()
end)
RegisterNetEvent('traffic:server:deleteZone',function(id)
 if not TrafficPermissions.isAdmin(source) or type(id)~='string' then return end
 TrafficZones[id]=nil;TrafficPersistence_save();broadcast()
end)
RegisterNetEvent('traffic:server:reportObstacle',function(hit)
 if not allowedReport(source) or type(hit)~='table' then return end
 hit.x=num(hit.x,nil);hit.y=num(hit.y,nil);hit.z=num(hit.z,nil)
 if not hit.x or not hit.y or not hit.z then return end
 local best,dist
 for id,o in pairs(TrafficObstacles) do
  local d=Traffic.distance({x=hit.x,y=hit.y,z=hit.z},{x=o.x,y=o.y,z=o.z})
  if d<12.0 and (not dist or d<dist) then best,dist=id,d end
 end
 if best then
  local o=TrafficObstacles[best];o.hits=(o.hits or 0)+1;o.lastSeen=os.time();o.heading=hit.heading or o.heading;o.category=classifyObstacle(o)
  o.reason=hit.reason or o.reason
 else
  local id=('obstacle_%s_%s'):format(os.time(),math.random(1000,9999))
  TrafficObstacles[id]={id=id,x=hit.x,y=hit.y,z=hit.z,hits=1,firstSeen=os.time(),lastSeen=os.time(),heading=num(hit.heading,0),category=classifyObstacle(hit),reason=tostring(hit.reason or 'blocked'):sub(1,40)}
 end
 TrafficPersistence_save();broadcast()
end)
RegisterNetEvent('traffic:server:routeFailure',function(data)
 local now=os.time();if (failureRate[source] or 0)>now-1 then return end;failureRate[source]=now
 if type(data)~='table' or not data.routeId then return end
 local r=TrafficRoutes[data.routeId]
 if r then r.failures=(r.failures or 0)+1;r.confidence=math.max(-100,(r.confidence or 0)-Config.AutoDiscovery.confidenceLoss) end
 local dataCoords=type(data.coords)=='table' and data.coords or nil
 if dataCoords and dataCoords.x and dataCoords.y and dataCoords.z then upsertAvoidance({routeId=data.routeId,reason=data.reason,coords=dataCoords},now) end
 cleanupAvoidance(now)
 TrafficPersistence_save();broadcast()
end)
RegisterNetEvent('traffic:server:deleteObstacle',function(id)
 if not TrafficPermissions.isAdmin(source) or type(id)~='string' then return end
 TrafficObstacles[id]=nil;TrafficPersistence_save();broadcast()
end)
AddEventHandler('playerDropped',function() reportRate[source]=nil;failureRate[source]=nil end)
