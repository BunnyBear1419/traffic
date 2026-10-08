TrafficSettings={}
local resourceName=GetCurrentResourceName()
local function defaults()
 local features={}
 for k,v in pairs(Config.FeatureToggles or {}) do features[k]=v end
 return {mode=Config.Adjustor.mode,trafficLevel=Config.Adjustor.trafficLevel,npcLevel=Config.Adjustor.npcLevel,features=features}
end
local function load()
 local raw=LoadResourceFile(resourceName,'data/settings.json')
 if not raw or raw=='' then return defaults() end
 local ok,value=pcall(json.decode,raw)
 if not ok or type(value)~='table' then return defaults() end
 local d=defaults()
 value.features=type(value.features)=='table' and value.features or d.features
 value.mode=value.mode=='manual' and 'manual' or 'auto'
 value.trafficLevel=math.max(0,math.min(100,tonumber(value.trafficLevel) or d.trafficLevel))
 value.npcLevel=math.max(0,math.min(100,tonumber(value.npcLevel) or d.npcLevel))
 for k,v in pairs(d.features) do if value.features[k]==nil then value.features[k]=v end end
 return value
end
local function save()
 local encoded=json.encode(TrafficSettings or defaults())
 if encoded then SaveResourceFile(resourceName,'data/settings.json',encoded,-1) end
end
local function publish(target)
 GlobalState.trafficDirectorSettings=TrafficSettings
 if target then TriggerClientEvent('traffic:client:settings',target,TrafficSettings) else TriggerClientEvent('traffic:client:settings',-1,TrafficSettings) end
end
function TrafficSettings_init()
 TrafficSettings=load()
 publish()
end
RegisterNetEvent('traffic:server:requestSettings',function()
 publish(source)
end)
RegisterNetEvent('traffic:server:updateSettings',function(payload)
 if not TrafficPermissions.isAdmin(source) or type(payload)~='table' then return end
 local d=defaults()
 TrafficSettings=TrafficSettings or load()
 if payload.mode=='auto' or payload.mode=='manual' then TrafficSettings.mode=payload.mode end
 if payload.trafficLevel~=nil then TrafficSettings.trafficLevel=math.max(0,math.min(100,tonumber(payload.trafficLevel) or TrafficSettings.trafficLevel)) end
 if payload.npcLevel~=nil then TrafficSettings.npcLevel=math.max(0,math.min(100,tonumber(payload.npcLevel) or TrafficSettings.npcLevel)) end
 if type(payload.features)=='table' then
  for k,v in pairs(d.features) do if payload.features[k]~=nil then TrafficSettings.features[k]=payload.features[k] == true end end
 end
 save();publish()
end)
AddEventHandler('onResourceStart',function(res) if res==resourceName then CreateThread(function() Wait(0);TrafficSettings_init() end) end end)
AddEventHandler('onResourceStop',function(res) if res==resourceName then save() end end)
