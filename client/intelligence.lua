TrafficIntelligence={stats={congestion=0,gridlocks=0,discoveries=0}}
local lastIntersection={}

local function isNpcVehicle(v)
 if not v or not DoesEntityExist(v) or not IsEntityAVehicle(v) then return false end
 local d=GetPedInVehicleSeat(v,-1)
 return d~=0 and DoesEntityExist(d) and not IsPedAPlayer(d)
end

function TrafficIntelligence.tick(v)
 if not TrafficAdjustor.isFeatureEnabled('intelligence') or not Config.Intersections.enabled or not isNpcVehicle(v) or GetVehicleClass(v)==18 then return false end

 -- Native-safe congestion sampling. Do not use road-node probing here:
 -- GetClosestVehicleNode was confirmed to trigger a client access violation
 -- on this server/build.
 local p=GetEntityCoords(v)
 local nearby=0
 local slow=0
 local radius=Config.Intersections.radius
 local probes={{x=radius,y=0},{x=-radius,y=0},{x=0,y=radius},{x=0,y=-radius}}

 for _,q in ipairs(probes) do
  local other=GetClosestVehicle(p.x+q.x,p.y+q.y,p.z,math.min(radius,18.0),0,70)
  if other and other~=0 and other~=v and isNpcVehicle(other) then
   nearby=nearby+1
   if GetEntitySpeed(other)<=Config.Intersections.gridlockSpeed then slow=slow+1 end
  end
 end

 if nearby<3 or slow<3 then return false end

 TrafficIntelligence.stats.congestion=TrafficIntelligence.stats.congestion+1
 local now=GetGameTimer()
 if lastIntersection[v] and now-lastIntersection[v]<Config.Intersections.cooldown then return true end
 lastIntersection[v]=now

 -- Without safe road-node/shape-test access, record the gridlock event and
 -- let the existing traffic/recovery systems handle vehicle movement.
 TrafficIntelligence.stats.gridlocks=TrafficIntelligence.stats.gridlocks+1
 return true
end
