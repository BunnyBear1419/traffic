TrafficRecovery={}
local state={}
function TrafficRecovery.reset(v) state[v]=nil; if TrafficRouting.reset then TrafficRouting.reset(v) end end
function TrafficRecovery.tick(v)
 if not DoesEntityExist(v) then return end
 local now=GetGameTimer();local s=state[v]
 if not s then state[v]={last=GetEntityCoords(v),since=now,probes=0};return end
 local p=GetEntityCoords(v)
 if Traffic.distance(p,s.last)>3.0 then s.last=p;s.since=now;s.probes=0;return end
 if now-s.since<Config.RecoveryTimeout then return end
 local obstacle=TrafficDetection.sampleObstacle(v)
 if obstacle then TriggerServerEvent('traffic:server:reportObstacle',obstacle) end
 ClearVehicleTasks(v);TrafficRouting.redirectToRoad(v);s.since=now;s.probes=s.probes+1
end
