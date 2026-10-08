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

-- Entity cleanup intentionally disabled while native pool scanning is isolated.
