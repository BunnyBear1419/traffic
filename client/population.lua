CreateThread(function()
 while true do
  if not TrafficAdjustor.isFeatureEnabled('population') then Wait(250); goto continue end
  local mode=Config.Modes[TrafficClientMode] or Config.Modes.normal
  local density=TrafficAdjustor.getPopulationDensity(mode.density or 1.0)
  local npcDensity=math.max(0,math.min(1.5,(TrafficAdjustor.getNPCScale and TrafficAdjustor.getNPCScale() or 1.0)))
  local trafficZero=(TrafficAdjustor.getTrafficScale and TrafficAdjustor.getTrafficScale() or 0)<=0
  local npcZero=(TrafficAdjustor.getNPCScale and TrafficAdjustor.getNPCScale() or 0)<=0
  SetVehicleDensityMultiplierThisFrame(trafficZero and 0.0 or density)
  SetRandomVehicleDensityMultiplierThisFrame(trafficZero and 0.0 or density)
  SetParkedVehicleDensityMultiplierThisFrame(trafficZero and 0.0 or math.min(density,1.0))
  SetPedDensityMultiplierThisFrame(npcZero and 0.0 or math.min(npcDensity,1.0))
  SetScenarioPedDensityMultiplierThisFrame(npcZero and 0.0 or math.min(npcDensity,1.0),npcZero and 0.0 or math.min(npcDensity,1.0))
  if density<=0 and npcDensity<=0 then
   SetVehiclePopulationBudget(0)
   SetPedPopulationBudget(0)
  else
   SetVehiclePopulationBudget(3)
   SetPedPopulationBudget(3)
  end
  Wait(0)
  ::continue::
 end
end)

local cleanupActive=false
local cleanupBoostUntil=0
local lastTrafficLevel=70
local lastNPCLevel=70

local function cleanupAmbient()
 if not Config.NativeSafety or not Config.NativeSafety.enabled or Config.NativeSafety.populationCleanup~=true then return end
 local radius=Config.NativeSafety.cleanupRadius or 110.0
 local batch=math.max(1,math.min(8,Config.NativeSafety.cleanupBatch or 5))
 local p=GetEntityCoords(PlayerPedId())
 local trafficLevel=TrafficAdjustor.state.trafficLevel or 0
 local npcLevel=TrafficAdjustor.state.npcLevel or 0
 local trafficZero=(TrafficAdjustor.getTrafficScale and TrafficAdjustor.getTrafficScale() or 0)<=0
 local npcZero=(TrafficAdjustor.getNPCScale and TrafficAdjustor.getNPCScale() or 0)<=0
 local removed=0
 if trafficLevel<=0 or trafficZero then
  for i=1,batch do
   local v=GetClosestVehicle(p.x,p.y,p.z,radius,0,70)
   if not v or v==0 or not DoesEntityExist(v) or not IsEntityAVehicle(v) then break end
   local driver=GetPedInVehicleSeat(v,-1)
   if driver~=0 and DoesEntityExist(driver) and not IsPedAPlayer(driver) then
    if NetworkGetEntityIsNetworked(v) and not NetworkHasControlOfEntity(v) then
     TrafficOwnership.ensure(v)
    end
    if not NetworkGetEntityIsNetworked(v) or NetworkHasControlOfEntity(v) then
     SetEntityAsMissionEntity(v,true,true)
     DeleteEntity(v)
     removed=removed+1
    else break end
   else
    break
   end
  end
 end
 if npcLevel<=0 or npcZero then
  for i=1,batch do
   local ped=GetClosestPed(p.x,p.y,p.z,radius,1,1,1,1,1,28,0)
   if not ped or ped==0 or not DoesEntityExist(ped) or IsPedAPlayer(ped) then break end
   if IsPedInAnyVehicle(ped,false) then break end
   if NetworkGetEntityIsNetworked(ped) and not NetworkHasControlOfEntity(ped) then
    TrafficOwnership.ensure(ped)
   end
   if not NetworkGetEntityIsNetworked(ped) or NetworkHasControlOfEntity(ped) then
    SetEntityAsMissionEntity(ped,true,true)
    DeleteEntity(ped)
    removed=removed+1
   else break end
  end
 end
 return removed
end

CreateThread(function()
 while true do
  if TrafficAdjustor.isFeatureEnabled('population') and Config.NativeSafety and Config.NativeSafety.populationCleanup==true then
   local trafficLevel=TrafficAdjustor.state.trafficLevel or 0
   local npcLevel=TrafficAdjustor.state.npcLevel or 0
   local trafficZero=(TrafficAdjustor.getTrafficScale and TrafficAdjustor.getTrafficScale() or 0)<=0
   local npcZero=(TrafficAdjustor.getNPCScale and TrafficAdjustor.getNPCScale() or 0)<=0
   if trafficLevel<=0 or npcLevel<=0 or trafficZero or npcZero then
    if lastTrafficLevel>0 and (trafficLevel<=0 or trafficZero) or lastNPCLevel>0 and (npcLevel<=0 or npcZero) then cleanupBoostUntil=GetGameTimer()+5000 end
    cleanupActive=true
    cleanupAmbient()
   else
    cleanupActive=false
   end
   lastTrafficLevel=trafficLevel
   lastNPCLevel=npcLevel
  end
  local interval=(Config.NativeSafety and Config.NativeSafety.cleanupInterval) or 250
  if cleanupActive and GetGameTimer()<cleanupBoostUntil then interval=100 end
  Wait(interval)
 end
end)

