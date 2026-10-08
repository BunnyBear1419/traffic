TrafficRecovery={}
local state={}
local lastReport={}
local lastFailureReport={}
function TrafficRecovery.reset(v) state[v]=nil;lastReport[v]=nil;lastFailureReport[v]=nil;if TrafficRouting.reset then TrafficRouting.reset(v) end;TrafficOwnership.reset(v) end
function TrafficRecovery.tick(v)
 if not v or not DoesEntityExist(v) or not IsEntityAVehicle(v) or not TrafficAdjustor.isFeatureEnabled('recovery') then return end
 if not TrafficOwnership.isLocal(v) then return end
 local now=GetGameTimer();local s=state[v]
 if not s then state[v]={last=GetEntityCoords(v),since=now,probes=0};return end
 local p=GetEntityCoords(v)
 if Traffic.distance(p,s.last)>3.0 then
  s.last=p;s.since=now;s.probes=0
  return
 end
 if now-s.since<Config.RecoveryTimeout then return end
 local obstacle=TrafficDetection.sampleObstacle(v)
 if obstacle and (not lastReport[v] or now-lastReport[v]>Config.AdaptiveRouting.obstacleReportCooldown) then
  obstacle.reason='stuck';obstacle.vehicleClass=GetVehicleClass(v);obstacle.recoveryCount=(s.probes or 0)+1
  TriggerServerEvent('traffic:server:reportObstacle',obstacle)
  local route=TrafficRouting.getActiveRoute and TrafficRouting.getActiveRoute(v) or TrafficRouting.getRouteForVehicle(v)
  if route and route.id and (not lastFailureReport[v] or now-lastFailureReport[v]>=Config.AdaptiveRouting.obstacleReportCooldown) then
   TriggerServerEvent('traffic:server:routeFailure',{routeId=route.id,reason='stuck',coords={x=p.x,y=p.y,z=p.z},entityModel=obstacle.entityModel,netId=obstacle.netId,progressIndex=TrafficRouting.getProgressIndex and TrafficRouting.getProgressIndex(v) or nil})
   lastFailureReport[v]=now
  end
  lastReport[v]=now
 end
 ClearVehicleTasks(v);TrafficRouting.redirectToRoad(v);s.since=now;s.probes=s.probes+1
end
