TrafficRoutes={}
TrafficZones={}
TrafficObstacles={}
TrafficRouteAvoidance={}
TrafficMLOEvidence={}
local resourceName=GetCurrentResourceName()
local function loadJson(name,fallback)
 local raw=LoadResourceFile(resourceName,'data/'..name..'.json')
 if not raw or raw=='' then return fallback end
 local ok,value=pcall(json.decode,raw)
 if ok and type(value)=='table' then return value end
 SaveResourceFile(resourceName,'data/'..name..'.corrupt.'..os.time()..'.json',raw,-1)
 local backup=LoadResourceFile(resourceName,'data/'..name..'.bak.json')
 if backup then
  local bok,bvalue=pcall(json.decode,backup)
  if bok and type(bvalue)=='table' then return bvalue end
 end
 return fallback
end
local function saveJson(name,value)
 local encoded=json.encode(value or {})
 if not encoded then return false end
 local current=LoadResourceFile(resourceName,'data/'..name..'.json')
 if current and current~='' then SaveResourceFile(resourceName,'data/'..name..'.bak.json',current,-1) end
 SaveResourceFile(resourceName,'data/'..name..'.json',encoded,-1)
 return true
end
CreateThread(function()
 TrafficRoutes=loadJson('routes',{})
 TrafficZones=loadJson('zones',{})
 TrafficObstacles=loadJson('obstacles',{})
 TrafficRouteAvoidance=loadJson('avoidance',{})
 TrafficMLOEvidence=loadJson('mlo_evidence',{})
 TriggerClientEvent('traffic:client:data',-1,TrafficRoutes,TrafficZones,TrafficObstacles)
end)
local function decayRouteConfidence(now)
 if not Config.RouteLearning.enabled or Config.RouteLearning.decayHours<=0 then return false end
 local changed=false;local ttl=Config.RouteLearning.decayHours*3600
 for _,r in pairs(TrafficRoutes) do local t=r.lastSuccess or r.updatedAt or r.createdAt;if t and now-t>ttl and (tonumber(r.confidence) or 0)>0 then r.confidence=math.max(0,(r.confidence or 0)-Config.RouteLearning.confidenceLoss);r.lastSuccess=now;changed=true end end
 return changed
end
function TrafficPersistence_save()
 saveJson('routes',TrafficRoutes);saveJson('zones',TrafficZones);saveJson('obstacles',TrafficObstacles)
 saveJson('avoidance',TrafficRouteAvoidance);saveJson('mlo_evidence',TrafficMLOEvidence)
end
RegisterNetEvent('traffic:server:save',function(routes,zones)
 if not TrafficPermissions.isAdmin(source) then return end
 TrafficRoutes=type(routes)=='table' and routes or TrafficRoutes
 TrafficZones=type(zones)=='table' and zones or TrafficZones
 TrafficPersistence_save()
end)
RegisterNetEvent('traffic:server:requestData',function()
 TriggerClientEvent('traffic:client:data',source,TrafficRoutes,TrafficZones,TrafficObstacles,TrafficRouteAvoidance)
end)
CreateThread(function()
 while Config.RouteLearning.enabled and Config.RouteLearning.decayHours>0 do
  Wait(math.max(60000,math.floor(Config.RouteLearning.decayHours*3600000/2)))
  if decayRouteConfidence(os.time()) then TrafficPersistence_save() end
 end
end)
AddEventHandler('onResourceStop',function(res) if res==resourceName then TrafficPersistence_save() end end)
