local open=false
local function pushData()
 if not open then return end
 SendNUIMessage({action='data',routes=TrafficRoutes,zones=TrafficClientZones,obstacles=TrafficClientObstacles,mode=TrafficClientMode})
end
RegisterNetEvent('traffic:client:open',function()
 open=true;SetNuiFocus(true,true);pushData()
end)
RegisterNetEvent('traffic:client:data',function(routes,zones,obstacles)
 TrafficRoutes=routes or {};TrafficClientZones=zones or {};TrafficClientObstacles=obstacles or {};pushData()
end)
RegisterNUICallback('close',function(_,cb) open=false;SetNuiFocus(false,false);cb('ok') end)
RegisterNUICallback('setMode',function(d,cb) TriggerServerEvent('traffic:server:setMode',d.mode);cb('ok') end)
RegisterNUICallback('deleteRoute',function(d,cb) TriggerServerEvent('traffic:server:deleteRoute',d.id);cb('ok') end)
RegisterNUICallback('updateRoute',function(d,cb) TriggerServerEvent('traffic:server:updateRoute',d.route);cb('ok') end)
RegisterNUICallback('deleteZone',function(d,cb) TriggerServerEvent('traffic:server:deleteZone',d.id);cb('ok') end)
RegisterNUICallback('deleteObstacle',function(d,cb) TriggerServerEvent('traffic:server:deleteObstacle',d.id);cb('ok') end)
CreateThread(function() TriggerServerEvent('traffic:server:requestData') end)
