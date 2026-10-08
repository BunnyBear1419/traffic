CreateThread(function()
 while true do
  if not TrafficAdjustor.isFeatureEnabled('population') then Wait(250); goto continue end
  local mode=Config.Modes[TrafficClientMode] or Config.Modes.normal
  local density=TrafficAdjustor.getPopulationDensity(mode.density or 1.0)
  local npcDensity=math.max(0,math.min(1.5,(TrafficAdjustor.getNPCScale and TrafficAdjustor.getNPCScale() or 1.0)))
  SetVehicleDensityMultiplierThisFrame(density)
  SetRandomVehicleDensityMultiplierThisFrame(density)
  SetParkedVehicleDensityMultiplierThisFrame(math.min(density,1.0))
  SetPedDensityMultiplierThisFrame(math.min(npcDensity,1.0))
  SetScenarioPedDensityMultiplierThisFrame(math.min(npcDensity,1.0),math.min(npcDensity,1.0))
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

CreateThread(function()
 while true do
  if TrafficAdjustor.isFeatureEnabled('population') and TrafficAdjustor.getTrafficScale()<=0 and TrafficAdjustor.getNPCScale()<=0 then
   local vehicles={}
   if Traffic.nativeSafetyEnabled('poolScanning') then Traffic.nativeProbe('Population','GetGamePool(CVehicle)',true);vehicles=GetGamePool('CVehicle') end
   for i=1,#vehicles do
    local v=vehicles[i]
    if DoesEntityExist(v) and IsEntityAVehicle(v) then
     local driver=GetPedInVehicleSeat(v,-1)
     if driver~=0 and DoesEntityExist(driver) and not IsPedAPlayer(driver) then
      if NetworkHasControlOfEntity(v) then
       if Traffic.nativeSafetyEnabled('populationCleanup') then SetEntityAsMissionEntity(v,true,true);DeleteEntity(v) end
      else
       NetworkRequestControlOfEntity(v)
      end
     end
    end
   end
  end
  if TrafficAdjustor.isFeatureEnabled('population') and TrafficAdjustor.getNPCScale()<=0 then
   local peds={}
   if Traffic.nativeSafetyEnabled('poolScanning') then Traffic.nativeProbe('Population','GetGamePool(CPed)',true);peds=GetGamePool('CPed') end
   for i=1,#peds do
    local ped=peds[i]
    if DoesEntityExist(ped) and IsEntityAPed(ped) and not IsPedAPlayer(ped) and not IsPedInAnyVehicle(ped,false) and not IsEntityAMissionEntity(ped) then
     if NetworkGetEntityIsNetworked(ped) then
      if NetworkHasControlOfEntity(ped) then
       if Traffic.nativeSafetyEnabled('populationCleanup') then SetEntityAsMissionEntity(ped,true,true);DeleteEntity(ped) end
      else
       NetworkRequestControlOfEntity(ped)
      end
     else
      if Traffic.nativeSafetyEnabled('populationCleanup') then SetEntityAsMissionEntity(ped,true,true);DeleteEntity(ped) end
     end
    end
   end
  end
  Wait(1000)
 end
end)
