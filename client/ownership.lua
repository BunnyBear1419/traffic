TrafficOwnership={}
local attempts={}
function TrafficOwnership.owner(entity)
 if not entity or not DoesEntityExist(entity) then return PlayerId() end
 if not NetworkGetEntityIsNetworked(entity) then return PlayerId() end
 return NetworkGetEntityOwner(entity)
end
function TrafficOwnership.isLocal(entity)
 if not entity or not DoesEntityExist(entity) then return true end
 if not NetworkGetEntityIsNetworked(entity) then return true end
 return NetworkHasControlOfEntity(entity)
end
function TrafficOwnership.ensure(entity)
 if not TrafficAdjustor.isFeatureEnabled('oneSync') or not Config.OneSync.enabled or not DoesEntityExist(entity) then return true end
 if not NetworkGetEntityIsNetworked(entity) or NetworkHasControlOfEntity(entity) then return true end
 local now=GetGameTimer()
 local s=attempts[entity] or {count=0,untilAt=0}
 if now<s.untilAt then return false end
 if s.count>=Config.OneSync.maxControlAttempts then s.count=0;s.untilAt=now+Config.OneSync.migrationGrace;attempts[entity]=s;return false end
 NetworkRequestControlOfEntity(entity)
 s.count=s.count+1;s.untilAt=now+Config.OneSync.requestTimeout;attempts[entity]=s
 return NetworkHasControlOfEntity(entity)
end
function TrafficOwnership.reset(entity) attempts[entity]=nil end
CreateThread(function()
 while true do
  Wait(5000)
  for entity in pairs(attempts) do
   if not DoesEntityExist(entity) then attempts[entity]=nil end
  end
 end
end)
