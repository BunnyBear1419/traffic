TrafficRoutes = {}
TrafficZones = {}
local resourceName=GetCurrentResourceName()
local function loadJson(name,fallback)
 local raw=LoadResourceFile(resourceName,'data/'..name..'.json')
 if not raw or raw=='' then return fallback end
 local ok,value=pcall(json.decode,raw)
 if ok and value then return value end
 return fallback
end
local function saveJson(name,value) SaveResourceFile(resourceName,'data/'..name..'.json',json.encode(value),-1) end
CreateThread(function() TrafficRoutes=loadJson('routes',{}); TrafficZones=loadJson('zones',{}) end)
function TrafficPersistence_save() saveJson('routes',TrafficRoutes); saveJson('zones',TrafficZones) end
RegisterNetEvent('traffic:server:save',function(routes,zones)
 if not TrafficPermissions.isAdmin(source) then return end
 TrafficRoutes=routes or TrafficRoutes; TrafficZones=zones or TrafficZones; TrafficPersistence_save()
end)
RegisterNetEvent('traffic:server:requestData',function() TriggerClientEvent('traffic:client:data',source,TrafficRoutes,TrafficZones) end)
AddEventHandler('onResourceStop',function(res) if res==resourceName then TrafficPersistence_save() end end)
