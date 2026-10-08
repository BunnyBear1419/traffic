TrafficEventController={active={}}

local presets={
 roadwork={name='Road Construction',duration=120000,settings={trafficLevel=35,npcLevel=45,parkedVehicleLevel=60,mode='light'}},
 checkpoint={name='Police Checkpoint',duration=120000,settings={trafficLevel=45,npcLevel=55,parkedVehicleLevel=55,mode='emergency',emergencyVehicles=true}},
 accident={name='Major Accident',duration=90000,settings={trafficLevel=20,npcLevel=35,parkedVehicleLevel=30,mode='light'}},
 emergency_response={name='Emergency Response',duration=90000,settings={trafficLevel=15,npcLevel=30,parkedVehicleLevel=25,mode='emergency',emergencyVehicles=true}},
 fire_scene={name='Fire Scene',duration=90000,settings={trafficLevel=10,npcLevel=25,parkedVehicleLevel=20,mode='emergency',emergencyVehicles=true}},
 traffic_jam={name='Traffic Jam',duration=120000,settings={trafficLevel=90,npcLevel=85,parkedVehicleLevel=95,mode='heavy'}},
 race_event={name='Race Event',duration=180000,settings={trafficLevel=15,npcLevel=25,parkedVehicleLevel=15,mode='race',emergencyVehicles=false,militaryVehicles=false}},
 military_convoy={name='Military Convoy',duration=180000,settings={trafficLevel=25,npcLevel=35,parkedVehicleLevel=30,mode='emergency',emergencyVehicles=true,militaryVehicles=true}},
 police_pursuit={name='Police Pursuit',duration=90000,settings={trafficLevel=20,npcLevel=30,parkedVehicleLevel=20,mode='emergency',emergencyVehicles=true}}
}

local function publish()
 local e=TrafficEventController.active
 TriggerClientEvent('traffic:client:trafficEvent',-1,e and {id=e.id,name=e.name,type=e.type,startedAt=e.startedAt,expiresAt=e.expiresAt,settings=e.settings} or nil)
end

RegisterNetEvent('traffic:server:startEvent',function(kind,duration)
 if not TrafficPermissions.canEvents(source) or type(kind)~='string' or not Config.TrafficEvents.enabled then return end
 local p=presets[kind];if not p then return end
 local ms=math.max(10000,math.min(900000,tonumber(duration) or p.duration or Config.TrafficEvents.defaultDuration))
 local now=GetGameTimer()
 TrafficEventController.active={id=('event_%s_%s'):format(kind,now),name=p.name,type=kind,startedAt=now,expiresAt=now+ms,settings=p.settings}
 publish()
end)

RegisterNetEvent('traffic:server:stopEvent',function()
 if not TrafficPermissions.canEvents(source) then return end
 TrafficEventController.active=nil;publish()
end)

RegisterNetEvent('traffic:server:requestEvent',function() TriggerClientEvent('traffic:client:trafficEvent',source,TrafficEventController.active) end)

CreateThread(function()
 while true do
  Wait(1000)
  local e=TrafficEventController.active
  if e and GetGameTimer()>=e.expiresAt then TrafficEventController.active=nil;publish() end
 end
end)
