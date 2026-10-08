CreateThread(function()
 while true do
  if not TrafficAdjustor.isFeatureEnabled('population') then Wait(250); goto continue end
  local mode=Config.Modes[TrafficClientMode] or Config.Modes.normal
  local density=TrafficAdjustor.getPopulationDensity(mode.density or 1.0)
  local npcDensity=math.max(0,math.min(1.5,(TrafficAdjustor.getNPCScale and TrafficAdjustor.getNPCScale() or 1.0)))
  local trafficZero=(TrafficAdjustor.state.trafficLevel or 0)<=0
  local npcZero=(TrafficAdjustor.state.npcLevel or 0)<=0
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

-- Entity cleanup intentionally disabled while native pool scanning is isolated.
