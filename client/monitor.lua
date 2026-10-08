TrafficMonitor={stats={healthy=0,invisible=0,repairs=0,ownership=0,failures=0}}
function TrafficMonitor.snapshot()
 local pool={};local npc=0;local owned=0
 if Traffic.nativeSafetyEnabled('monitorScanning') then Traffic.nativeProbe('Monitor','GetGamePool(CVehicle)',true);pool=GetGamePool('CVehicle') end
 for i=1,#pool do
  local v=pool[i];local d=GetPedInVehicleSeat(v,-1)
  if d~=0 and DoesEntityExist(d) and not IsPedAPlayer(d) then
   npc=npc+1;if TrafficOwnership.isLocal(v) then owned=owned+1 end
  end
 end
 local a={};local ok,v=pcall(function() return exports[GetCurrentResourceName()]:GetNPCAppearanceStats() end);if ok and type(v)=='table' then a=v end
 TrafficMonitor.stats.npcVehicles=npc
 TrafficMonitor.stats.ownedVehicles=owned
 TrafficMonitor.stats.managedNPCs=a.managed or 0
 TrafficMonitor.stats.appearanceRepairs=a.repairs or 0
 TrafficMonitor.stats.lastUpdate=GetGameTimer()
 return TrafficMonitor.stats
end
CreateThread(function() while true do TrafficMonitor.snapshot();Wait(2000) end end)
