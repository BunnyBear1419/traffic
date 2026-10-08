TrafficSettings={}
local resourceName=GetCurrentResourceName()
local BuiltInPresets={
 {id='performance_safe',name='Performance Safe',description='Lower traffic and NPC processing for busy servers.',mode='manual',trafficMode='light',trafficLevel=35,npcLevel=30,parkedVehicleLevel=45,emergencyVehicles=true,militaryVehicles=false},
 {id='normal_traffic',name='Normal Traffic',description='Balanced everyday traffic.',mode='manual',trafficMode='normal',trafficLevel=70,npcLevel=70,parkedVehicleLevel=70,emergencyVehicles=true,militaryVehicles=true},
 {id='busy_city',name='Busy City',description='Denser city traffic with stronger NPC activity.',mode='manual',trafficMode='heavy',trafficLevel=88,npcLevel=82,parkedVehicleLevel=90,emergencyVehicles=true,militaryVehicles=true},
 {id='heavy_traffic',name='Heavy Traffic',description='Maximum road activity while retaining automatic performance control.',mode='manual',trafficMode='heavy',trafficLevel=96,npcLevel=90,parkedVehicleLevel=100,emergencyVehicles=true,militaryVehicles=true},
 {id='npc_heavy',name='NPC Heavy',description='Prioritizes managed NPC activity.',mode='manual',trafficMode='normal',trafficLevel=65,npcLevel=100,parkedVehicleLevel=75,emergencyVehicles=true,militaryVehicles=true},
 {id='race_event',name='Race / Event',description='High-performance event profile with race-friendly traffic.',mode='manual',trafficMode='race',trafficLevel=45,npcLevel=55,parkedVehicleLevel=35,emergencyVehicles=false,militaryVehicles=false},
 {id='emergency_response',name='Emergency Response',description='Reduced civilian density for emergency operations.',mode='manual',trafficMode='emergency',trafficLevel=25,npcLevel=35,parkedVehicleLevel=25,emergencyVehicles=true,militaryVehicles=false},
 {id='disabled',name='Traffic Director Disabled',description='Turns Traffic Director systems off.',mode='manual',trafficMode='normal',trafficLevel=0,npcLevel=0,parkedVehicleLevel=0,emergencyVehicles=false,militaryVehicles=false}
}
local function defaultFeatures()
 local features={}
 for k,v in pairs(Config.FeatureToggles or {}) do features[k]=v end
 return features
end
local function presetPayload(preset)
 local features=defaultFeatures()
 if preset.features then for k,v in pairs(features) do if preset.features[k]~=nil then features[k]=preset.features[k] end end end
 if preset.id=='disabled' then for k in pairs(features) do features[k]=false end end
 return {mode=preset.mode,trafficMode=preset.trafficMode or Config.DefaultMode,trafficLevel=preset.trafficLevel,npcLevel=preset.npcLevel,parkedVehicleLevel=preset.parkedVehicleLevel or 70,emergencyVehicles=preset.emergencyVehicles~=false,militaryVehicles=preset.militaryVehicles~=false,features=features}
end
local function defaults()
 return {mode=Config.Adjustor.mode,profile='normal_traffic',trafficMode=Config.DefaultMode,trafficLevel=Config.Adjustor.trafficLevel,npcLevel=Config.Adjustor.npcLevel,parkedVehicleLevel=(Config.VehiclePopulation and Config.VehiclePopulation.parkedVehicleLevel) or 70,emergencyVehicles=Config.VehiclePopulation and Config.VehiclePopulation.emergencyVehicles~=false,militaryVehicles=Config.VehiclePopulation and Config.VehiclePopulation.militaryVehicles~=false,features=defaultFeatures(),presets={}}
end
local function load()
 local raw=LoadResourceFile(resourceName,'data/settings.json')
 if not raw or raw=='' then return defaults() end
 local ok,value=pcall(json.decode,raw)
 if not ok or type(value)~='table' then return defaults() end
 local d=defaults()
 value.features=type(value.features)=='table' and value.features or d.features
 value.presets=type(value.presets)=='table' and value.presets or {}
 value.mode=value.mode=='manual' and 'manual' or 'auto';value.profile=type(value.profile)=='string' and value.profile or d.profile;value.trafficMode=type(value.trafficMode)=='string' and Config.Modes[value.trafficMode] and value.trafficMode or d.trafficMode
 value.trafficLevel=math.max(0,math.min(100,tonumber(value.trafficLevel) or d.trafficLevel))
 value.npcLevel=math.max(0,math.min(100,tonumber(value.npcLevel) or d.npcLevel));value.parkedVehicleLevel=math.max(0,math.min(100,tonumber(value.parkedVehicleLevel) or d.parkedVehicleLevel));if value.emergencyVehicles==nil then value.emergencyVehicles=d.emergencyVehicles end;if value.militaryVehicles==nil then value.militaryVehicles=d.militaryVehicles end
 for k,v in pairs(d.features) do if value.features[k]==nil then value.features[k]=v end end
 return value
end
local function save()
 local encoded=json.encode(TrafficSettings or defaults())
 if encoded then SaveResourceFile(resourceName,'data/settings.json',encoded,-1) end
end
TrafficSettings_save=save
local function publish(target)
 GlobalState.trafficDirectorSettings=TrafficSettings
 if target then TriggerClientEvent('traffic:client:settings',target,TrafficSettings) else TriggerClientEvent('traffic:client:settings',-1,TrafficSettings) end
end
local function publicPresets()
 local out={}
 for _,p in ipairs(BuiltInPresets) do local x=presetPayload(p);out[#out+1]={id=p.id,name=p.name,description=p.description,builtIn=true,mode=x.mode,trafficMode=x.trafficMode,trafficLevel=x.trafficLevel,npcLevel=x.npcLevel,features=x.features} end
 for id,p in pairs(TrafficSettings.presets or {}) do out[#out+1]={id=id,name=p.name or id,description=p.description or 'Custom preset',builtIn=false,mode=p.mode,trafficMode=p.trafficMode or Config.DefaultMode,trafficLevel=p.trafficLevel,npcLevel=p.npcLevel,parkedVehicleLevel=p.parkedVehicleLevel or 70,emergencyVehicles=p.emergencyVehicles~=false,militaryVehicles=p.militaryVehicles~=false,features=p.features or defaultFeatures()} end
 return out
end
local function publishPresets(target) TriggerClientEvent('traffic:client:presets',target or -1,publicPresets()) end
function TrafficSettings_init() TrafficSettings=load();publish();publishPresets() end
RegisterNetEvent('traffic:server:requestSettings',function() publish(source);publishPresets(source) end)
RegisterNetEvent('traffic:server:requestPresets',function() publishPresets(source) end)
RegisterNetEvent('traffic:server:applyPreset',function(id)
 if not TrafficPermissions.isAdmin(source) or type(id)~='string' then return end
 TrafficSettings=TrafficSettings or load()
 local chosen
 for _,p in ipairs(BuiltInPresets) do if p.id==id then chosen=presetPayload(p) break end end
 if not chosen and TrafficSettings.presets[id] then chosen=TrafficSettings.presets[id] end
 if not chosen then return end
 TrafficSettings.mode=chosen.mode
 TrafficSettings.profile=id
 TrafficSettings.trafficMode=chosen.trafficMode or Config.DefaultMode
 TrafficSettings.trafficLevel=math.max(0,math.min(100,tonumber(chosen.trafficLevel) or 70))
 TrafficSettings.npcLevel=math.max(0,math.min(100,tonumber(chosen.npcLevel) or 70));TrafficSettings.parkedVehicleLevel=math.max(0,math.min(100,tonumber(chosen.parkedVehicleLevel) or 70));TrafficSettings.emergencyVehicles=chosen.emergencyVehicles~=false;TrafficSettings.militaryVehicles=chosen.militaryVehicles~=false
 TrafficSettings.features=chosen.features or defaultFeatures()
 save();publish();publishPresets()
end)
RegisterNetEvent('traffic:server:savePreset',function(payload)
 if not TrafficPermissions.isAdmin(source) or type(payload)~='table' then return end
 local id=tostring(payload.id or ''):lower():gsub('[^%w_%-]','_')
 if id=='' or #id>48 then return end
 for _,p in ipairs(BuiltInPresets) do if p.id==id then return end end
 local features=defaultFeatures()
 if type(payload.features)=='table' then for k in pairs(features) do if payload.features[k]~=nil then features[k]=payload.features[k]==true end end end
 TrafficSettings=TrafficSettings or load();TrafficSettings.presets=TrafficSettings.presets or {}
 TrafficSettings.presets[id]={name=tostring(payload.name or id):sub(1,60),description=tostring(payload.description or 'Custom preset'):sub(1,160),mode=payload.mode=='manual' and 'manual' or 'auto',trafficMode=(type(payload.trafficMode)=='string' and Config.Modes[payload.trafficMode] and payload.trafficMode or TrafficSettings.trafficMode or Config.DefaultMode),trafficLevel=math.max(0,math.min(100,tonumber(payload.trafficLevel) or 70)),npcLevel=math.max(0,math.min(100,tonumber(payload.npcLevel) or 70)),parkedVehicleLevel=math.max(0,math.min(100,tonumber(payload.parkedVehicleLevel) or 70)),emergencyVehicles=payload.emergencyVehicles~=false,militaryVehicles=payload.militaryVehicles~=false,features=features}
 save();publishPresets(source)
end)
RegisterNetEvent('traffic:server:deletePreset',function(id)
 if not TrafficPermissions.isAdmin(source) or type(id)~='string' then return end
 TrafficSettings=TrafficSettings or load();if TrafficSettings.presets then TrafficSettings.presets[id]=nil end;save();publishPresets(source)
end)
RegisterNetEvent('traffic:server:updateSettings',function(payload)
 if not TrafficPermissions.isAdmin(source) or type(payload)~='table' then return end
 local d=defaults();TrafficSettings=TrafficSettings or load()
 if payload.mode=='auto' or payload.mode=='manual' then TrafficSettings.mode=payload.mode end
 TrafficSettings.profile='custom'
 if payload.trafficLevel~=nil then TrafficSettings.trafficLevel=math.max(0,math.min(100,tonumber(payload.trafficLevel) or TrafficSettings.trafficLevel)) end
 if type(payload.trafficMode)=='string' and Config.Modes[payload.trafficMode] then TrafficSettings.trafficMode=payload.trafficMode end
 if payload.npcLevel~=nil then TrafficSettings.npcLevel=math.max(0,math.min(100,tonumber(payload.npcLevel) or TrafficSettings.npcLevel)) end
 if payload.parkedVehicleLevel~=nil then TrafficSettings.parkedVehicleLevel=math.max(0,math.min(100,tonumber(payload.parkedVehicleLevel) or TrafficSettings.parkedVehicleLevel)) end
 if payload.emergencyVehicles~=nil then TrafficSettings.emergencyVehicles=payload.emergencyVehicles==true end
 if payload.militaryVehicles~=nil then TrafficSettings.militaryVehicles=payload.militaryVehicles==true end
 if type(payload.features)=='table' then for k,v in pairs(d.features) do if payload.features[k]~=nil then TrafficSettings.features[k]=payload.features[k]==true end end end
 save();publish()
end)
AddEventHandler('onResourceStart',function(res) if res==resourceName then CreateThread(function() Wait(0);TrafficSettings_init() end) end end)
AddEventHandler('onResourceStop',function(res) if res==resourceName then save() end end)
