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
 local adjustor=TrafficAdjustor and TrafficAdjustor.snapshot and TrafficAdjustor.snapshot() or {}
 local learning=TrafficLearning and TrafficLearning.snapshot and TrafficLearning.snapshot() or {}
 local monitor=TrafficMonitor and TrafficMonitor.stats or {}
 SendNUIMessage({
  action='data',routes=TrafficRoutes,zones=TrafficClientZones,obstacles=TrafficClientObstacles,avoidance=TrafficClientAvoidance,
  mode=TrafficClientMode,npc=stats,intelligence=TrafficIntelligence and TrafficIntelligence.stats or {},
  performance={scanInterval=(adjustor.scanInterval or Config.ScanInterval),maxTasks=(adjustor.maxTasks or Config.MaxTrafficTasks)},monitor=monitor,adjustor=adjustor,learning=learning
 })
end
RegisterNetEvent('traffic:client:open',function() open=true;SetNuiFocus(false,false);SetNuiFocus(true,true);SendNUIMessage({action='open'});TriggerServerEvent('traffic:server:requestSettings');TriggerServerEvent('traffic:server:requestJobRules');TriggerServerEvent('traffic:server:requestEvent'); end)
RegisterNetEvent('traffic:client:mode',function(mode) TrafficClientMode=mode or TrafficClientMode;SendNUIMessage({action='mode',mode=TrafficClientMode}) end)
RegisterNetEvent('traffic:client:routeSaved',function(data) if TrafficLearning and TrafficLearning.onSaved then TrafficLearning.onSaved(data) end end)
RegisterNetEvent('traffic:client:settings',function(settings) if type(settings)=='table' and type(settings.trafficMode)=='string' and Config.Modes[settings.trafficMode] then TrafficClientMode=settings.trafficMode elseif type(settings)=='table' and type(settings.profile)=='string' and Config.Modes[settings.profile] then TrafficClientMode=settings.profile end;TrafficAdjustor.state.mode=settings.mode or TrafficAdjustor.state.mode;TrafficAdjustor.state.trafficLevel=tonumber(settings.trafficLevel) or TrafficAdjustor.state.trafficLevel;TrafficAdjustor.state.npcLevel=tonumber(settings.npcLevel) or TrafficAdjustor.state.npcLevel;TrafficAdjustor.state.parkedVehicleLevel=tonumber(settings.parkedVehicleLevel) or TrafficAdjustor.state.parkedVehicleLevel or 70;if settings.masterEnabled~=nil then TrafficAdjustor.state.masterEnabled=settings.masterEnabled==true end;if settings.configured~=nil then TrafficAdjustor.state.configured=settings.configured==true end;if settings.emergencyVehicles~=nil then TrafficAdjustor.state.emergencyVehicles=settings.emergencyVehicles==true end;if settings.militaryVehicles~=nil then TrafficAdjustor.state.militaryVehicles=settings.militaryVehicles==true end;TrafficClientMode=settings.trafficMode or TrafficClientMode or Config.DefaultMode;TrafficAdjustor.baseTrafficLevel=TrafficAdjustor.state.trafficLevel;TrafficAdjustor.baseNPCLevel=TrafficAdjustor.state.npcLevel;TrafficAdjustor.baseTrafficMode=TrafficClientMode;TrafficAdjustor.features=settings.features or TrafficAdjustor.features;TrafficAdjustor.state.vehiclePolicy=settings.vehiclePolicy or TrafficAdjustor.state.vehiclePolicy;pushData() end)
RegisterNetEvent('traffic:client:diagnostics',function(snapshot) SendNUIMessage({action='diagnostics',snapshot=snapshot or {}}) end)
RegisterNetEvent('traffic:client:diagnosticsServer',function(snapshot) TrafficUIDiagnosticsServer=snapshot or {} end)
RegisterNetEvent('traffic:client:diagnosticsRequest',function()
 local d=TrafficAdjustor and TrafficAdjustor.snapshot and TrafficAdjustor.snapshot() or {}
 d.clientResource=GetCurrentResourceName();d.clientPed=DoesEntityExist(PlayerPedId());d.clientCoords=GetEntityCoords(PlayerPedId());d.server=TrafficUIDiagnosticsServer or {}
 SendNUIMessage({action='diagnostics',snapshot=d})
end)
RegisterNetEvent('traffic:client:configExport',function(snapshot) SendNUIMessage({action='configExport',snapshot=snapshot or {}}) end)
RegisterNetEvent('traffic:client:importResult',function(ok,message) SendNUIMessage({action='importResult',ok=ok,message=message}) end)
RegisterNetEvent('traffic:client:presets',function(presets) SendNUIMessage({action='presets',presets=presets or {}}) end)
RegisterNetEvent('traffic:client:jobRules',function(rules) SendNUIMessage({action='jobRules',rules=rules or {}}) end)
RegisterNetEvent('traffic:client:data',function(routes,zones,obstacles,avoidance)
 TrafficRoutes=routes or {};TrafficClientZones=zones or {};TrafficClientObstacles=obstacles or {};TrafficClientAvoidance=avoidance or {};pushData()
end)
RegisterNetEvent('traffic:client:mloAudit',function(report)
 SendNUIMessage({action='mloAudit',report=report or {}})
end)
RegisterNetEvent('traffic:client:mloFixPlan',function(plan)
 SendNUIMessage({action='mloFixPlan',plan=plan or {}})
end)
RegisterNUICallback('toggleLearning',function(_,cb) TriggerEvent('traffic:client:toggleLearning');cb('ok') end)
RegisterNUICallback('close',function(_,cb) open=false;SetNuiFocus(false,false);cb('ok') end)
RegisterNUICallback('applyPreset',function(d,cb) TriggerServerEvent('traffic:server:applyPreset',d.id);cb('ok') end)
RegisterNUICallback('savePreset',function(d,cb) TriggerServerEvent('traffic:server:savePreset',d);cb('ok') end)
RegisterNUICallback('deletePreset',function(d,cb) TriggerServerEvent('traffic:server:deletePreset',d.id);cb('ok') end)
RegisterNUICallback('updateSettings',function(d,cb) TriggerEvent('traffic:client:settings',d);TriggerServerEvent('traffic:server:updateSettings',d);cb('ok') end)
RegisterNUICallback('startEvent',function(d,cb) TriggerServerEvent('traffic:server:startEvent',d and d.kind,d and d.duration);cb('ok') end)
RegisterNUICallback('stopEvent',function(_,cb) TriggerServerEvent('traffic:server:stopEvent');cb('ok') end)
RegisterNUICallback('saveJobRule',function(d,cb) TriggerServerEvent('traffic:server:saveJobRule',d);cb('ok') end)
RegisterNUICallback('deleteJobRule',function(d,cb) TriggerServerEvent('traffic:server:deleteJobRule',d.id);cb('ok') end)
RegisterNUICallback('requestJobRules',function(_,cb) TriggerServerEvent('traffic:server:requestJobRules');cb('ok') end)
RegisterNUICallback('saveVehiclePolicy',function(d,cb) TriggerServerEvent('traffic:server:updateSettings',{vehiclePolicy=d});cb('ok') end)
RegisterNUICallback('completeSetup',function(_,cb) TriggerServerEvent('traffic:server:completeSetup');cb('ok') end)
RegisterNUICallback('setMasterEnabled',function(d,cb) TriggerServerEvent('traffic:server:setMasterEnabled',d and d.enabled==true);cb('ok') end)
RegisterNUICallback('exportSettings',function(_,cb) TriggerServerEvent('traffic:server:exportSettings');cb('ok') end)
RegisterNUICallback('requestDiagnostics',function(_,cb) TriggerServerEvent('traffic:server:requestDiagnostics');cb('ok') end)
RegisterNUICallback('importSettings',function(d,cb) TriggerServerEvent('traffic:server:importSettings',d and d.config);cb('ok') end)
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
  Wait(1000)
 end
end)

