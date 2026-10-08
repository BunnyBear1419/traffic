TrafficMonitor={stats={healthy=0,invisible=0,repairs=0,ownership=0,failures=0}}
local function scanEnabled() return Config.NativeSafety and Config.NativeSafety.enabled and Config.NativeSafety.monitorScanning==true end
function TrafficMonitor.snapshot()
 local npc,owned=0,0
 if scanEnabled() then
  local p=GetEntityCoords(PlayerPedId())
  Traffic.nativeProbe('Monitor','GetClosestVehicle',true)
  local v=GetClosestVehicle(p.x,p.y,p.z,60.0,0,70)
  if v and v~=0 and DoesEntityExist(v) and IsEntityAVehicle(v) then
   local d=GetPedInVehicleSeat(v,-1)
   if d~=0 and DoesEntityExist(d) and not IsPedAPlayer(d) then npc=1 if TrafficOwnership.isLocal(v) then owned=1 end end
  end
 end
 local a={}
 local ok,v=pcall(function() return exports[GetCurrentResourceName()]:GetNPCAppearanceStats() end)
 if ok and type(v)=='table' then a=v end
 TrafficMonitor.stats.npcVehicles=npc
 TrafficMonitor.stats.ownedVehicles=owned
 TrafficMonitor.stats.managedNPCs=a.managed or 0
 TrafficMonitor.stats.appearanceRepairs=a.repairs or 0
 TrafficMonitor.stats.lastUpdate=GetGameTimer()
 return TrafficMonitor.stats
end
CreateThread(function() while true do if scanEnabled() then TrafficMonitor.snapshot() end Wait(2000) end end)
