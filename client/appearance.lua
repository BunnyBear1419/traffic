TrafficAppearance={}
local managed={}
local repairs={}\nlocal repairCount=0\nlocal lastRepair={}
local function now() return GetGameTimer() end

local function applyVariation(ped,appearance)
 if not appearance then return end
 for _,c in ipairs(appearance.components or {}) do
  SetPedComponentVariation(ped,c.component or c.slot or 0,c.drawable or 0,c.texture or 0,c.palette or 0)
 end
 for _,p in ipairs(appearance.props or {}) do
  local prop=p.prop or p.slot or 0
  if (p.drawable or -1)<0 then ClearPedProp(ped,prop) else SetPedPropIndex(ped,prop,p.drawable or 0,p.texture or 0,true) end
 end
end

local function softRepair(ped,entry)
 if not DoesEntityExist(ped) or IsEntityDead(ped) then return false end
 SetEntityVisible(ped,true,false)
 ResetEntityAlpha(ped)
 SetEntityAlpha(ped,255,false)
 SetEntityCollision(ped,true,true)
 if entry.appearance then applyVariation(ped,entry.appearance) end
 if entry.repair then pcall(entry.repair,ped) end
 repairs[ped]=now()\n repairCount=repairCount+1\n lastRepair[ped]=now()\n TriggerEvent('traffic:appearance:repaired',ped,entry.type)
 return true
end

function TrafficAppearance.register(ped,definition)
 if not DoesEntityExist(ped) or not IsEntityAPed(ped) or IsPedAPlayer(ped) then return false end\n if Config.AppearanceGuard and Config.AppearanceGuard.maxManagedNPCs then\n  local count=0 for _ in pairs(managed) do count=count+1 end\n  if not managed[ped] and count>=Config.AppearanceGuard.maxManagedNPCs then return false end\n end
 definition=definition or {}
 managed[ped]={
  type=definition.type or 'managed',
  appearance=definition.appearance,
  repair=definition.repair,
  model=definition.model or GetEntityModel(ped),
  verify=definition.verify ~= false
 }
 return true
end

function TrafficAppearance.unregister(ped) managed[ped]=nil;repairs[ped]=nil end

exports('RegisterManagedNPC',function(ped,definition) return TrafficAppearance.register(ped,definition) end)
exports('UnregisterManagedNPC',function(ped) TrafficAppearance.unregister(ped) end)

RegisterNetEvent('traffic:appearance:register',function(ped,definition)
 TrafficAppearance.register(ped,definition)
end)
RegisterNetEvent('traffic:appearance:unregister',function(ped)
 TrafficAppearance.unregister(ped)
end)

local function needsRepair(ped)
 return not IsEntityVisible(ped) or GetEntityAlpha(ped)<250
end

CreateThread(function()
 while true do
  local t=now()
  for ped,entry in pairs(managed) do
   if not DoesEntityExist(ped) then
    managed[ped]=nil;repairs[ped]=nil
   elseif entry.verify and needsRepair(ped) and (not repairs[ped] or t-repairs[ped]>=((Config.AppearanceGuard and Config.AppearanceGuard.repairCooldown) or 5000)) then
    softRepair(ped,entry)
   end
  end
  Wait((Config.AppearanceGuard and Config.AppearanceGuard.interval) or 2000)
 end
end)

RegisterCommand('trafficnpcdebug',function()
 local count=0
 for ped in pairs(managed) do if DoesEntityExist(ped) then count=count+1 end end
 print(('[Traffic Director] Managed NPCs: %s | Appearance repairs: %s'):format(count,0))
end,false)
