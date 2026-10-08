TrafficRoutes={}
TrafficActive=true
local tracked={}
local function npc(v)
 if not DoesEntityExist(v) or not IsEntityAVehicle(v) then return false end
 local d=GetPedInVehicleSeat(v,-1)
 return d~=0 and DoesEntityExist(d) and not IsPedAPlayer(d)
end
local function emergency(v) return GetVehicleClass(v)==18 end
local function zoneControl(v)
 local z=TrafficZones_getAt(GetEntityCoords(v))
 if not z then return false end
 if z.type=='stop' and not emergency(v) then ClearVehicleTasks(v);SetVehicleMaxSpeed(v,0.5);return true end
 if z.type=='closure' and not emergency(v) then SetVehicleMaxSpeed(v,6.0);return true end
 if z.type=='oneway' and z.heading and not emergency(v) then
  local diff=math.abs(((GetEntityHeading(v)-z.heading+180.0)%360.0)-180.0)
  if diff>95.0 then TaskVehicleDriveWander(v,10.0,786603);return true end
 end
 local m=Config.Modes[z.type]
 if m and not emergency(v) then SetVehicleMaxSpeed(v,18.0*m.speed) end
 return false
end
local function manage(v)
 if not npc(v) then return end
 tracked[v]=true
 if zoneControl(v) then return end
 local route=TrafficRouting.getRouteForVehicle(v)
 if route and not IsVehicleStuckOnRoof(v) then TrafficRouting.driveRoute(v,route) end
 TrafficRecovery.tick(v)
end
CreateThread(function()
 while true do
  if TrafficActive then
   local list=GetGamePool('CVehicle');local n=0
   for i=1,#list do
    if n<Config.MaxTrafficTasks and npc(list[i]) then manage(list[i]);n=n+1 end
   end
  end
  Wait(Config.ScanInterval)
 end
end)
CreateThread(function()
 while true do
  Wait(5000)
  for v in pairs(tracked) do
   if not DoesEntityExist(v) then tracked[v]=nil;TrafficRecovery.reset(v) end
  end
 end
end)
