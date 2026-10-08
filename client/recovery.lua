TrafficRecovery={}
local state={}
function TrafficRecovery.reset(v) state[v]=nil end
function TrafficRecovery.tick(v)
 if not DoesEntityExist(v) then return end
 local now=GetGameTimer(); local s=state[v]
 if not s then state[v]={last=GetEntityCoords(v),since=now}; return end
 local p=GetEntityCoords(v)
 if Traffic.distance(p,s.last)>3.0 then s.last=p;s.since=now;return end
 if now-s.since<Config.RecoveryTimeout then return end
 ClearVehicleTasks(v); TrafficRouting.redirectToRoad(v); s.since=now
end
