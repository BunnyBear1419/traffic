CreateThread(function()
 while true do
  if not TrafficAdjustor.isFeatureEnabled('population') then Wait(250); goto continue end
  local mode=Config.Modes[TrafficClientMode] or Config.Modes.normal
  local density=TrafficAdjustor.getPopulationDensity(mode.density or 1.0)
  SetVehicleDensityMultiplierThisFrame(density)
  SetRandomVehicleDensityMultiplierThisFrame(density)
  SetParkedVehicleDensityMultiplierThisFrame(math.min(density,1.0))
  SetPedDensityMultiplierThisFrame(math.min(density,1.0))
  SetScenarioPedDensityMultiplierThisFrame(math.min(density,1.0),math.min(density,1.0))
  Wait(0)
  ::continue::
 end
end)
