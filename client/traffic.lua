TrafficRoutes={}
TrafficActive=true
local tracked={}
local zoneState={}
local rerouteAt={}
local scanInterval=Config.ScanInterval
local maxTasks=Config.MaxTrafficTasks
local function npc(v)
 if not v or not DoesEntityExist(v) or not IsEntityAVehicle(v) then return false end
 local d=GetPedInVehicleSeat(v,-1)
 return d~=0 and DoesEntityExist(d) and not IsPedAPlayer(d)
end
local function emergency(v) return GetVehicleClass(v)==18 end
local function setSpeed(v,speed)
 if TrafficOwnership.ensure(v) and Traffic.nativeSafetyEnabled('speedControl') and Traffic.nativeProbe('Traffic','SetVehicleMaxSpeed',true) then SetVehicleMaxSpeed(v,math.max(0.1,tonumber(speed) or 22.0)) return true end
 return false
end
local function resetVehicle(v)
 if not zoneState[v] then return end
 if TrafficOwnership.ensure(v) and Traffic.nativeSafetyEnabled('speedControl') and Traffic.nativeProbe('Traffic','SetVehicleMaxSpeed',true) then SetVehicleMaxSpeed(v,1000.0) end
 zoneState[v]=nil
end
local function rerouteOutOfZone(v,z)
 local now=GetGameTimer()
 if rerouteAt[v] and now-rerouteAt[v]<((Config.ZoneBehavior and Config.ZoneBehavior.rerouteCooldown) or 2500) then return end
 rerouteAt[v]=now
 local p=GetEntityCoords(v);local dx=p.x-z.x;local dy=p.y-z.y;local len=math.sqrt(dx*dx+dy*dy)
 if len<0.1 then local h=math.rad(z.heading or GetEntityHeading(v));dx=math.sin(h);dy=math.cos(h);len=1 end
 local buffer=(Config.ZoneBehavior and Config.ZoneBehavior.closureExitBuffer) or 35.0
 local tx=p.x+(dx/len)*((z.radius or 60.0)+buffer);local ty=p.y+(dy/len)*((z.radius or 60.0)+buffer)
 local road=TrafficDetection.findRoadPoint({x=tx,y=ty,z=p.z},GetEntityHeading(v))
 if road and TrafficOwnership.ensure(v) and Traffic.nativeSafetyEnabled('vehicleTasks') and Traffic.nativeProbe('Traffic','TaskVehicleDriveToCoordLongrange',true) then ClearVehicleTasks(v);TaskVehicleDriveToCoordLongrange(v,road.x,road.y,road.z,14.0,786603,8.0) end
end
local function forceDirection(v,z)
 local diff=math.abs(((GetEntityHeading(v)-(z.heading or 0)+180.0)%360.0)-180.0)
 if diff<=95.0 then return false end
 local now=GetGameTimer()
 if rerouteAt[v] and now-rerouteAt[v]<((Config.ZoneBehavior and Config.ZoneBehavior.rerouteCooldown) or 2500) then return true end
 rerouteAt[v]=now
 local h=math.rad(z.heading or 0);local p=GetEntityCoords(v);local distance=(z.radius or 60.0)+60.0
 local target={x=z.x+math.sin(h)*distance,y=z.y+math.cos(h)*distance,z=p.z}
 local road=TrafficDetection.findRoadPoint(target,z.heading or GetEntityHeading(v))
 if road and TrafficOwnership.ensure(v) and Traffic.nativeSafetyEnabled('vehicleTasks') and Traffic.nativeProbe('Traffic','TaskVehicleDriveToCoordLongrange',true) then ClearVehicleTasks(v);TaskVehicleDriveToCoordLongrange(v,road.x,road.y,road.z,14.0,786603,7.0) end
 return true
end
local function zoneControl(v)
 local z=TrafficZones_getAt(GetEntityCoords(v))
 if not z then resetVehicle(v);return false end
 zoneState[v]=z.id or z.type
 local behavior=Config.ZoneBehavior or {}
 if z.type=='stop' then
  if not emergency(v) and TrafficOwnership.ensure(v) then ClearVehicleTasks(v);if Traffic.nativeSafetyEnabled('speedControl') then SetVehicleMaxSpeed(v,0.1);SetVehicleForwardSpeed(v,0.0) end end
  return true
 end
 if z.type=='closure' and not emergency(v) then
  rerouteOutOfZone(v,z);setSpeed(v,behavior.yieldSpeed or 7.0);return true
 end
 if z.type=='oneway' and not emergency(v) then
  if forceDirection(v,z) then setSpeed(v,behavior.heavySpeed or 16.0);return true end
  setSpeed(v,behavior.baseSpeed or 22.0);return false
 end
 if z.type=='emergency' then
  setSpeed(v,emergency(v) and (behavior.emergencySpeed or 34.0) or (behavior.yieldSpeed or 7.0));return false
 end
 if z.type=='light' then setSpeed(v,behavior.lightSpeed or 24.0);return false end
 if z.type=='heavy' then setSpeed(v,behavior.heavySpeed or 16.0);return false end
 if z.type=='race' then setSpeed(v,behavior.raceSpeed or 30.0);return false end
 setSpeed(v,behavior.baseSpeed or 22.0);return false
end
local function globalModeControl(v)
 local mode=TrafficClientMode or Config.DefaultMode
 local b=Config.ZoneBehavior or {}
 if mode=='stop' then
  if not emergency(v) and TrafficOwnership.ensure(v) then ClearVehicleTasks(v);if Traffic.nativeSafetyEnabled('speedControl') then SetVehicleMaxSpeed(v,0.1);SetVehicleForwardSpeed(v,0.0) end end
  return true
 end
 if mode=='emergency' then setSpeed(v,emergency(v) and (b.emergencySpeed or 34.0) or (b.yieldSpeed or 7.0));return false end
 if mode=='race' then setSpeed(v,b.raceSpeed or 30.0);return false end
 if mode=='heavy' then setSpeed(v,b.heavySpeed or 16.0);return false end
 if mode=='light' then setSpeed(v,b.lightSpeed or 24.0);return false end
 setSpeed(v,b.baseSpeed or 22.0);return false
end
local function manage(v)
 if not npc(v) then return end
 tracked[v]=true
 if TrafficIntelligence.tick(v) then return end
 if globalModeControl(v) then return end
 if zoneControl(v) then return end
 if not TrafficOwnership.ensure(v) then return end
 local route=TrafficRouting.getRouteForVehicle(v)
 if route and not IsVehicleStuckOnRoof(v) then TrafficRouting.driveRoute(v,route) end
 TrafficRecovery.tick(v)
end
CreateThread(function()
 while true do
  if TrafficActive and TrafficAdjustor.isFeatureEnabled('traffic') then
   local n=0
   local player=PlayerPedId()
   local p=GetEntityCoords(player)
   local radius=math.min(120.0,math.max(40.0,(TrafficAdjustor.getScanInterval() or Config.ScanInterval)/10.0))
   Traffic.nativeProbe('Traffic','GetClosestVehicle',true)
   local vehicle=GetClosestVehicle(p.x,p.y,p.z,radius,0,70)
   if vehicle and vehicle~=0 and npc(vehicle) then manage(vehicle);n=1 end
   if TrafficAdjustor.isFeatureEnabled('performance') and Config.Performance.enabled then
    scanInterval=TrafficAdjustor.getScanInterval();maxTasks=math.min(TrafficAdjustor.getMaxTasks(),Config.Performance.minTasks+1)
   end
  end
  Wait(scanInterval)
  ::continue::
 end
end)
CreateThread(function()
 while true do
  Wait(5000)
  for v in pairs(tracked) do
   if not DoesEntityExist(v) then tracked[v]=nil;zoneState[v]=nil;rerouteAt[v]=nil;TrafficRecovery.reset(v);TrafficOwnership.reset(v) end
  end
 end
end)
