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
 local batch=math.max(1,math.min(12,Config.NativeSafety.cleanupBatch or 5))
 local p=GetEntityCoords(PlayerPedId())
 local trafficLevel=tonumber(TrafficAdjustor.state.trafficLevel) or 0
 local npcLevel=tonumber(TrafficAdjustor.state.npcLevel) or 0
 local trafficZero=(TrafficAdjustor.getTrafficScale and TrafficAdjustor.getTrafficScale() or 0)<=0
 local npcZero=(TrafficAdjustor.getNPCScale and TrafficAdjustor.getNPCScale() or 0)<=0
 local removed=0

 -- Do not stop at the first protected/player vehicle. Scan past it so an
 -- ordinary ambient vehicle farther away can still be removed.
 if trafficLevel<=0 or trafficZero then
  local handle,vehicle=FindFirstVehicle()
  local success=true
  while success and vehicle and vehicle~=0 and removed<batch do
   if DoesEntityExist(vehicle) and IsEntityAVehicle(vehicle) then
    local vp=GetEntityCoords(vehicle)
    local dx=vp.x-p.x
    local dy=vp.y-p.y
    local dz=vp.z-p.z
    if (dx*dx+dy*dy+dz*dz)<=radius*radius then
     local driver=GetPedInVehicleSeat(vehicle,-1)
     local playerVehicle=driver~=0 and DoesEntityExist(driver) and IsPedAPlayer(driver)
     local missionVehicle=IsEntityAMissionEntity(vehicle)
     if not playerVehicle and not missionVehicle then
      if NetworkGetEntityIsNetworked(vehicle) and not NetworkHasControlOfEntity(vehicle) then
       TrafficOwnership.ensure(vehicle)
      end
      if not NetworkGetEntityIsNetworked(vehicle) or NetworkHasControlOfEntity(vehicle) then
       SetEntityAsMissionEntity(vehicle,true,true)
       DeleteEntity(vehicle)
       removed=removed+1
      end
     end
    end
   end
   if removed<batch then
    success,vehicle=FindNextVehicle(handle)
   end
  end
  EndFindVehicle(handle)
 end

 -- The same rule applies to pedestrians: skip players/managed mission peds
 -- rather than breaking the scan at the first protected entity.
 if npcLevel<=0 or npcZero then
  local handle,ped=FindFirstPed()
  local success=true
  while success and ped and ped~=0 and removed<batch do
   if DoesEntityExist(ped) and not IsPedAPlayer(ped) then
    local pp=GetEntityCoords(ped)
    local dx=pp.x-p.x
    local dy=pp.y-p.y
    local dz=pp.z-p.z
    if (dx*dx+dy*dy+dz*dz)<=radius*radius and not IsEntityAMissionEntity(ped) and not IsPedInAnyVehicle(ped,false) then
     if NetworkGetEntityIsNetworked(ped) and not NetworkHasControlOfEntity(ped) then
      TrafficOwnership.ensure(ped)
     end
     if not NetworkGetEntityIsNetworked(ped) or NetworkHasControlOfEntity(ped) then
      SetEntityAsMissionEntity(ped,true,true)
      DeleteEntity(ped)
      removed=removed+1
     end
    end
   end
   if removed<batch then
    success,ped=FindNextPed(handle)
   end
  end
  EndFindPed(handle)
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

