local open=false
local function npcStats()
 if exports[GetCurrentResourceName()] and exports['traffic'].GetNPCAppearanceStats then return exports['traffic']:GetNPCAppearanceStats() end
 return {managed=0,repairs=0}
end
local function pushData()
 if not open then return end
 local stats=npcStats()
 SendNUIMessage({action='data',routes=TrafficRoutes,zones=TrafficClientZones,obstacles=TrafficClientObstacles,mode=TrafficClientMode,npc=stats})
end
RegisterNetEvent('traffic:client:open',function() open=true;SetNuiFocus(true,true);pushData() end)
RegisterNetEvent('traffic:client:data',function(routes,zones,obstacles) TrafficRoutes=routes or {};TrafficClientZones=zones or {};TrafficClientObstacles=obstacles or {};pushData() end)
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
CreateThread(function() TriggerServerEvent('traffic:server:requestData') end)
