local open=false
local function npcStats()
 local s={};local m={}
 local ok,a=pcall(function() return exports[GetCurrentResourceName()]:GetNPCAppearanceStats() end);if ok and type(a)=='table' then s=a end
 local ok2,b=pcall(function() return exports[GetCurrentResourceName()]:GetNPCManagerStats() end);if ok2 and type(b)=='table' then m=b end
 return {managed=s.managed or 0,repairs=s.repairs or 0,invisible=s.invisible or 0,mismatched=s.mismatched or 0,spawnPoints=m.spawnPoints or 0,spawned=m.managed or 0}
end
local function pushData()
 if not open then return end
 local stats=npcStats()
 SendNUIMessage({
  action='data',routes=TrafficRoutes,zones=TrafficClientZones,obstacles=TrafficClientObstacles,avoidance=TrafficClientAvoidance,
  mode=TrafficClientMode,npc=stats,intelligence=TrafficIntelligence and TrafficIntelligence.stats or {},
  performance={scanInterval=Config.ScanInterval,maxTasks=Config.MaxTrafficTasks},monitor={},adjustor=TrafficAdjustor.snapshot(),learning=(TrafficLearning and TrafficLearning.snapshot and TrafficLearning.snapshot() or {})
 })
end
RegisterNetEvent('traffic:client:open',function() open=true;SetNuiFocus(false,false);SetNuiFocus(true,true);SendNUIMessage({action='open'});TriggerServerEvent('traffic:server:requestSettings');TriggerServerEvent('traffic:server:requestData');pushData() end)
RegisterNetEvent('traffic:client:mode',function(mode) TrafficClientMode=mode or TrafficClientMode;SendNUIMessage({action='mode',mode=TrafficClientMode}) end)
RegisterNetEvent('traffic:client:routeSaved',function(data) if TrafficLearning and TrafficLearning.onSaved then TrafficLearning.onSaved(data) end end)
RegisterNetEvent('traffic:client:settings',function(settings) if type(settings)=='table' and settings.profile then TrafficClientMode=settings.profile end;TrafficAdjustor.state.mode=settings.mode or TrafficAdjustor.state.mode;TrafficAdjustor.state.trafficLevel=tonumber(settings.trafficLevel) or TrafficAdjustor.state.trafficLevel;TrafficAdjustor.state.npcLevel=tonumber(settings.npcLevel) or TrafficAdjustor.state.npcLevel;TrafficAdjustor.baseTrafficLevel=TrafficAdjustor.state.trafficLevel;TrafficAdjustor.baseNPCLevel=TrafficAdjustor.state.npcLevel;TrafficAdjustor.features=settings.features or TrafficAdjustor.features;pushData() end)
RegisterNetEvent('traffic:client:presets',function(presets) SendNUIMessage({action='presets',presets=presets or {}}) end)
RegisterNetEvent('traffic:client:data',function(routes,zones,obstacles,avoidance)
 TrafficRoutes=routes or {};TrafficClientZones=zones or {};TrafficClientObstacles=obstacles or {};TrafficClientAvoidance=avoidance or {};pushData()
end)
RegisterNetEvent('traffic:client:mloAudit',function(report)
 SendNUIMessage({action='mloAudit',report=report or {}})
end)
RegisterNetEvent('traffic:client:mloFixPlan',function(plan)
 SendNUIMessage({action='mloFixPlan',plan=plan or {}})
end)
RegisterNUICallback('close',function(_,cb) open=false;SetNuiFocus(false,false);cb('ok') end)
RegisterNUICallback('applyPreset',function(d,cb) TriggerServerEvent('traffic:server:applyPreset',d.id);cb('ok') end)
RegisterNUICallback('savePreset',function(d,cb) TriggerServerEvent('traffic:server:savePreset',d);cb('ok') end)
RegisterNUICallback('deletePreset',function(d,cb) TriggerServerEvent('traffic:server:deletePreset',d.id);cb('ok') end)
RegisterNUICallback('updateSettings',function(d,cb) TriggerEvent('traffic:client:settings',d);TriggerServerEvent('traffic:server:updateSettings',d);cb('ok') end)
RegisterNUICallback('setMode',function(d,cb) if type(d)=='table' and type(d.mode)=='string' then TrafficClientMode=d.mode end;TriggerServerEvent('traffic:server:setMode',d.mode);cb('ok') end)
RegisterNUICallback('deleteRoute',function(d,cb) TriggerServerEvent('traffic:server:deleteRoute',d.id);cb('ok') end)
RegisterNUICallback('updateRoute',function(d,cb) TriggerServerEvent('traffic:server:updateRoute',d.route);cb('ok') end)
RegisterNUICallback('deleteZone',function(d,cb) TriggerServerEvent('traffic:server:deleteZone',d.id);cb('ok') end)
RegisterNUICallback('deleteObstacle',function(d,cb) TriggerServerEvent('traffic:server:deleteObstacle',d.id);cb('ok') end)
RegisterNUICallback('deleteAvoidance',function(d,cb) TriggerServerEvent('traffic:server:deleteAvoidance',d.id);cb('ok') end)
RegisterNUICallback('scanMLOs',function(_,cb) TriggerServerEvent('traffic:server:mloScan');cb('ok') end)
RegisterNUICallback('mloIgnore',function(d,cb) TriggerServerEvent('traffic:server:mloIgnore',d.key);cb('ok') end)
RegisterNUICallback('mloFixPlan',function(d,cb) TriggerServerEvent('traffic:server:mloPrepareFix',d.id);cb('ok') end)
RegisterNUICallback('createZone',function(d,cb)
 local p=GetEntityCoords(PlayerPedId())
 TriggerServerEvent('traffic:server:addZone',{name=d.name or 'Admin Zone',type=d.type or 'normal',radius=tonumber(d.radius) or 60.0,x=p.x,y=p.y,z=p.z,heading=GetEntityHeading(PlayerPedId()),routeId=d.routeId})
 cb('ok')
end)
CreateThread(function()
 while true do
  if open then pushData() end
  Wait(750)
 end
end)
CreateThread(function() TriggerServerEvent('traffic:server:requestData') end)
