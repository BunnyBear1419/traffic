local function vehicleSettings()
 local s=TrafficAdjustor.state or {}
 return tonumber(s.parkedVehicleLevel) or 70,s.emergencyVehicles~=false,s.militaryVehicles~=false
end

local function isEmergencyVehicle(v)
 return DoesEntityExist(v) and IsEntityAVehicle(v) and GetVehicleClass(v)==18
end

local function currentList(kind)
 local vp=TrafficAdjustor.state and TrafficAdjustor.state.vehiclePolicy or {}
 if kind=='emergency' and type(vp.emergencyModels)=='table' then return vp.emergencyModels end
 if kind=='military' and type(vp.militaryModels)=='table' then return vp.militaryModels end
 if kind=='protected' and type(vp.protectedModels)=='table' then return vp.protectedModels end
 return nil
end

local function modelInList(v,list)
 if not DoesEntityExist(v) or not list then return false end
 local model=GetEntityModel(v)
 for _,name in ipairs(list) do if model==GetHashKey(name) then return true end end
 return false
end

local function isMilitaryVehicle(v)
 return modelInList(v,currentList('military') or (Config.VehiclePopulation and Config.VehiclePopulation.militaryModels))
end

local function isProtectedVehicle(v)
 if not DoesEntityExist(v) or not IsEntityAVehicle(v) then return true end
 if modelInList(v,currentList('protected')) then return true end
 local driver=GetPedInVehicleSeat(v,-1)
 return (driver~=0 and DoesEntityExist(driver) and IsPedAPlayer(driver)) or IsEntityAMissionEntity(v)
end

local lastCategoryState={}
local function applyCategorySuppression()
 local cfg=Config.VehicleCategories or {};local vp=TrafficAdjustor.state and TrafficAdjustor.state.vehiclePolicy or {};local levels=vp.categoryLevels or {}
 for category,models in pairs(cfg.models or {}) do
  local enabled=(tonumber(levels[category]) or 100)>0
  if enabled~=lastCategoryState[category] then
   for _,name in ipairs(models or {}) do SetVehicleModelIsSuppressed(GetHashKey(name),not enabled) end
   lastCategoryState[category]=enabled
  end
 end
end

local lastSuppressedEmergency=nil
local lastSuppressedMilitary=nil
local function applyModelSuppression(emergencyEnabled,militaryEnabled)
   applyCategorySuppression()
 local cfg=Config.VehiclePopulation or {}
 local vp=TrafficAdjustor.state and TrafficAdjustor.state.vehiclePolicy or {}
 local emergencyModels=type(vp.emergencyModels)=='table' and vp.emergencyModels or cfg.emergencyModels or {}
 local militaryModels=type(vp.militaryModels)=='table' and vp.militaryModels or cfg.militaryModels or {}
 if cfg.modelSuppression==false then return end
 if emergencyEnabled~=lastSuppressedEmergency then for _,name in ipairs(emergencyModels) do SetVehicleModelIsSuppressed(GetHashKey(name),not emergencyEnabled) end;lastSuppressedEmergency=emergencyEnabled end
 if militaryEnabled~=lastSuppressedMilitary then for _,name in ipairs(militaryModels) do SetVehicleModelIsSuppressed(GetHashKey(name),not militaryEnabled) end;lastSuppressedMilitary=militaryEnabled end
end

CreateThread(function()
 while true do
  if TrafficAdjustor.isFeatureEnabled('population') then
   local mode=Config.Modes[TrafficClientMode] or Config.Modes.normal
   local trafficEnabled=TrafficAdjustor.isFeatureEnabled('traffic')
   local density=trafficEnabled and TrafficAdjustor.getPopulationDensity(mode.density or 1.0) or 1.0
   local npcDensity=math.max(0,math.min(1.5,TrafficAdjustor.getNPCScale()))
   local parkedScale=TrafficAdjustor.getParkedVehicleScale and TrafficAdjustor.getParkedVehicleScale() or 0.7
   local _,emergencyEnabled,militaryEnabled=vehicleSettings()
   local trafficZero=trafficEnabled and (TrafficAdjustor.getTrafficScale and TrafficAdjustor.getTrafficScale() or 0)<=0
   local npcZero=(TrafficAdjustor.getNPCScale and TrafficAdjustor.getNPCScale() or 0)<=0
   SetVehicleDensityMultiplierThisFrame(trafficZero and 0.0 or density)
   SetRandomVehicleDensityMultiplierThisFrame(trafficZero and 0.0 or density)
   SetParkedVehicleDensityMultiplierThisFrame(parkedScale<=0 and 0.0 or parkedScale)
   SetPedDensityMultiplierThisFrame(npcZero and 0.0 or math.min(npcDensity,1.0))
   SetScenarioPedDensityMultiplierThisFrame(npcZero and 0.0 or math.min(npcDensity,1.0),npcZero and 0.0 or math.min(npcDensity,1.0))
   if trafficZero and npcZero and parkedScale<=0 then SetVehiclePopulationBudget(0);SetPedPopulationBudget(0) else SetVehiclePopulationBudget(3);SetPedPopulationBudget(3) end
   applyModelSuppression(emergencyEnabled,militaryEnabled)
  else
   applyModelSuppression(true,true)
  end
  Wait(0)
 end
end)

local cleanupActive=false
local cleanupBoostUntil=0
local lastTrafficLevel=70
local lastNPCLevel=70
local lastParkedLevel=70
local function cleanupAmbient()
 if not Config.NativeSafety or not Config.NativeSafety.enabled or Config.NativeSafety.populationCleanup~=true then return end
 local radius=Config.NativeSafety.cleanupRadius or 110.0
 local batch=math.max(1,math.min(16,Config.NativeSafety.cleanupBatch or 5))
 local p=GetEntityCoords(PlayerPedId())
 local trafficLevel=tonumber(TrafficAdjustor.state.trafficLevel) or 0
 local npcLevel=tonumber(TrafficAdjustor.state.npcLevel) or 0
 local parkedLevel=tonumber(TrafficAdjustor.state.parkedVehicleLevel) or 70
 local trafficZero=(TrafficAdjustor.getTrafficScale and TrafficAdjustor.getTrafficScale() or 0)<=0
 local npcZero=(TrafficAdjustor.getNPCScale and TrafficAdjustor.getNPCScale() or 0)<=0
 local _,emergencyEnabled,militaryEnabled=vehicleSettings()
 local removed=0
 local handle,vehicle=FindFirstVehicle()
 local success=true
 while success and vehicle and vehicle~=0 and removed<batch do
  if DoesEntityExist(vehicle) and IsEntityAVehicle(vehicle) then
   local vp=GetEntityCoords(vehicle);local dx=vp.x-p.x;local dy=vp.y-p.y;local dz=vp.z-p.z
   if (dx*dx+dy*dy+dz*dz)<=radius*radius and not isProtectedVehicle(vehicle) then
    local driver=GetPedInVehicleSeat(vehicle,-1)
    local empty=driver==0 or not DoesEntityExist(driver)
    local remove=(trafficLevel<=0 or trafficZero) or (parkedLevel<=0 and empty) or (not emergencyEnabled and isEmergencyVehicle(vehicle)) or (not militaryEnabled and isMilitaryVehicle(vehicle))
    if remove then
     if NetworkGetEntityIsNetworked(vehicle) and not NetworkHasControlOfEntity(vehicle) then TrafficOwnership.ensure(vehicle) end
     if not NetworkGetEntityIsNetworked(vehicle) or NetworkHasControlOfEntity(vehicle) then SetEntityAsMissionEntity(vehicle,true,true);DeleteEntity(vehicle);removed=removed+1 end
    end
   end
  end
  if removed<batch then success,vehicle=FindNextVehicle(handle) end
 end
 EndFindVehicle(handle)
 if npcLevel<=0 or npcZero then
  local ph,ped=FindFirstPed();local psuccess=true
  while psuccess and ped and ped~=0 and removed<batch do
   if DoesEntityExist(ped) and not IsPedAPlayer(ped) then
    local pp=GetEntityCoords(ped);local dx=pp.x-p.x;local dy=pp.y-p.y;local dz=pp.z-p.z
    if (dx*dx+dy*dy+dz*dz)<=radius*radius and not IsEntityAMissionEntity(ped) and not IsPedInAnyVehicle(ped,false) then
     if NetworkGetEntityIsNetworked(ped) and not NetworkHasControlOfEntity(ped) then TrafficOwnership.ensure(ped) end
     if not NetworkGetEntityIsNetworked(ped) or NetworkHasControlOfEntity(ped) then SetEntityAsMissionEntity(ped,true,true);DeleteEntity(ped);removed=removed+1 end
    end
   end
   if removed<batch then psuccess,ped=FindNextPed(ph) end
  end
  EndFindPed(ph)
 end
 return removed
end

CreateThread(function()
 while true do
  if TrafficAdjustor.isFeatureEnabled('population') and Config.NativeSafety and Config.NativeSafety.populationCleanup==true then
   local trafficLevel=TrafficAdjustor.state.trafficLevel or 0
   local npcLevel=TrafficAdjustor.state.npcLevel or 0
   local parkedLevel=TrafficAdjustor.state.parkedVehicleLevel or 0
   local _,emergencyEnabled,militaryEnabled=vehicleSettings()
   local emergencyNeedsCleanup=not emergencyEnabled or not militaryEnabled
   if trafficLevel<=0 or npcLevel<=0 or parkedLevel<=0 or emergencyNeedsCleanup or (TrafficAdjustor.getTrafficScale and TrafficAdjustor.getTrafficScale()<=0) or (TrafficAdjustor.getNPCScale and TrafficAdjustor.getNPCScale()<=0) then
    if lastTrafficLevel>0 and trafficLevel<=0 or lastNPCLevel>0 and npcLevel<=0 or lastParkedLevel>0 and parkedLevel<=0 or emergencyNeedsCleanup then cleanupBoostUntil=GetGameTimer()+5000 end
    cleanupActive=true;cleanupAmbient()
   else cleanupActive=false end
   lastTrafficLevel=trafficLevel;lastNPCLevel=npcLevel;lastParkedLevel=parkedLevel
  end
  local interval=(Config.NativeSafety and Config.NativeSafety.cleanupInterval) or 250
  if cleanupActive and GetGameTimer()<cleanupBoostUntil then interval=100 end
  Wait(interval)
 end
end)