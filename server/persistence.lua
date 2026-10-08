TrafficRoutes={}
TrafficZones={}
TrafficObstacles={}
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
 TriggerClientEvent('traffic:client:data',-1,TrafficRoutes,TrafficZones,TrafficObstacles)
end)
function TrafficPersistence_save()
 saveJson('routes',TrafficRoutes);saveJson('zones',TrafficZones);saveJson('obstacles',TrafficObstacles)
end
RegisterNetEvent('traffic:server:save',function(routes,zones)
 if not TrafficPermissions.isAdmin(source) then return end
 TrafficRoutes=type(routes)=='table' and routes or TrafficRoutes
 TrafficZones=type(zones)=='table' and zones or TrafficZones
 TrafficPersistence_save()
end)
RegisterNetEvent('traffic:server:requestData',function()
 TriggerClientEvent('traffic:client:data',source,TrafficRoutes,TrafficZones,TrafficObstacles)
end)
AddEventHandler('onResourceStop',function(res) if res==resourceName then TrafficPersistence_save() end end)
