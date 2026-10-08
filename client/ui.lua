local open=false
local function npcStats()
 local ok,result=pcall(function() return TrafficAppearance and select(1,TrafficAppearance.stats()) end)
 local s=exports[GetCurrentResourceName()]:GetNPCAppearanceStats() or {}
 local m=exports[GetCurrentResourceName()]:GetNPCManagerStats() or {}
 return {managed=s.managed or 0,repairs=s.repairs or 0,invisible=s.invisible or 0,mismatched=s.mismatched or 0,spawnPoints=m.spawnPoints or 0,spawned=m.managed or 0}
end
local function pushData()
 if not open then return end
 local stats=npcStats()
 SendNUIMessage({
  action='data',routes=TrafficRoutes,zones=TrafficClientZones,obstacles=TrafficClientObstacles,
  mode=TrafficClientMode,npc=stats,intelligence=TrafficIntelligence and TrafficIntelligence.stats or {},
  performance={scanInterval=Config.ScanInterval,maxTasks=Config.MaxTrafficTasks}
 })
end
RegisterNetEvent('traffic:client:open',function() open=true;SetNuiFocus(true,true);pushData() end)
RegisterNetEvent('traffic:client:data',function(routes,zones,obstacles)
 TrafficRoutes=routes or {};TrafficClientZones=zones or {};TrafficClientObstacles=obstacles or {};pushData()
end)
RegisterNUICallback('close',function(_,cb) open=false;SetNuiFocus(false,false);cb('ok') end)
RegisterNUICallback('setMode',function(d,cb) TriggerServerEvent('traffic:server:setMode',d.mode);cb('ok') end)
RegisterNUICallback('deleteRoute',function(d,cb) TriggerServerEvent('traffic:server:deleteRoute',d.id);cb('ok') end)
RegisterNUICallback('updateRoute',function(d,cb) TriggerServerEvent('traffic:server:updateRoute',d.route);cb('ok') end)
RegisterNUICallback('deleteZone',function(d,cb) TriggerServerEvent('traffic:server:deleteZone',d.id);cb('ok') end)
RegisterNUICallback('deleteObstacle',function(d,cb) TriggerServerEvent('traffic:server:deleteObstacle',d.id);cb('ok') end)
RegisterNUICallback('createZone',function(d,cb)
 local p=GetEntityCoords(PlayerPedId())
 TriggerServerEvent('traffic:server:addZone',{name=d.name or 'Admin Zone',type=d.type or 'normal',radius=tonumber(d.radius) or 60.0,x=p.x,y=p.y,z=p.z,heading=GetEntityHeading(PlayerPedId()),routeId=d.routeId})
 cb('ok')
end)
CreateThread(function()
 while true do
  if open then pushData() end
  Wait(2000)
 end
end)
CreateThread(function() TriggerServerEvent('traffic:server:requestData') end)
