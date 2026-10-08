TrafficIntelligence={stats={congestion=0,gridlocks=0,discoveries=0}}
local lastIntersection={}
local function isNpcVehicle(v)
 if not DoesEntityExist(v) or not IsEntityAVehicle(v) then return false end
 local d=GetPedInVehicleSeat(v,-1)
 return d~=0 and DoesEntityExist(d) and not IsPedAPlayer(d)
end
function TrafficIntelligence.tick(v)
 if not TrafficAdjustor.isFeatureEnabled('intelligence') or not Config.Intersections.enabled or not isNpcVehicle(v) or GetVehicleClass(v)==18 then return false end
 local p=GetEntityCoords(v)
 local ok=GetClosestVehicleNode(p.x,p.y,p.z,1,Config.Intersections.radius,0)
 if not ok then return false end
 local pool=GetGamePool('CVehicle');local nearby=0;local slow=0
 for i=1,#pool do
  local other=pool[i]
  if other~=v and isNpcVehicle(other) and Traffic.distance(p,GetEntityCoords(other))<=Config.Intersections.radius then
   nearby=nearby+1;if GetEntitySpeed(other)<=Config.Intersections.gridlockSpeed then slow=slow+1 end
  end
 end
 if nearby<3 or slow<3 then return false end
 TrafficIntelligence.stats.congestion=TrafficIntelligence.stats.congestion+1
 local now=GetGameTimer()
 if lastIntersection[v] and now-lastIntersection[v]<Config.Intersections.cooldown then return true end
 lastIntersection[v]=now
 if TrafficOwnership.ensure(v) then
  ClearVehicleTasks(v)
  local road=TrafficDetection.findRoadPoint(p,GetEntityHeading(v))
  if road then TaskVehicleDriveToCoordLongrange(v,road.x,road.y,road.z,12.0,786603,5.0) end
 end
 TrafficIntelligence.stats.gridlocks=TrafficIntelligence.stats.gridlocks+1
 return true
end
