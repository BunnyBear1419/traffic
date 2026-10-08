TrafficAppearance={}
local managed={}
local repairs={}
local repairCount=0
local lastRepair={}
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
 repairs[ped]=now()
 repairCount=repairCount+1
 lastRepair[ped]=now()
 TriggerEvent('traffic:appearance:repaired',ped,entry.type)
 return true
end
function TrafficAppearance.register(ped,definition)
 if not Config.AppearanceGuard.enabled then return false end
 if not DoesEntityExist(ped) or not IsEntityAPed(ped) or IsPedAPlayer(ped) then return false end
 local max=Config.AppearanceGuard.maxManagedNPCs
 if max then
  local count=0
  for _ in pairs(managed) do count=count+1 end
  if not managed[ped] and count>=max then return false end
 end
 definition=definition or {}
 managed[ped]={type=definition.type or 'managed',appearance=definition.appearance,repair=definition.repair,model=definition.model or GetEntityModel(ped),verify=definition.verify ~= false}
 return true
end
function TrafficAppearance.unregister(ped) managed[ped]=nil;repairs[ped]=nil;lastRepair[ped]=nil end
function TrafficAppearance.stats()
 local count=0
 for ped in pairs(managed) do if DoesEntityExist(ped) then count=count+1 end end
 return count,repairCount
end
exports('RegisterManagedNPC',function(ped,definition) return TrafficAppearance.register(ped,definition) end)
exports('UnregisterManagedNPC',function(ped) TrafficAppearance.unregister(ped) end)
exports('GetNPCAppearanceStats',function() local a,b=TrafficAppearance.stats();return {managed=a,repairs=b} end)
RegisterNetEvent('traffic:appearance:register',function(ped,definition) TrafficAppearance.register(ped,definition) end)
RegisterNetEvent('traffic:appearance:unregister',function(ped) TrafficAppearance.unregister(ped) end)
local function needsRepair(ped)
 if not Config.AppearanceGuard.repairInvisible then return false end
 return not IsEntityVisible(ped) or GetEntityAlpha(ped)<250
end
CreateThread(function()
 while true do
  if Config.AppearanceGuard.enabled then
   local t=now()
   for ped,entry in pairs(managed) do
    if not DoesEntityExist(ped) then managed[ped]=nil;repairs[ped]=nil;lastRepair[ped]=nil
    elseif entry.verify and needsRepair(ped) and (not repairs[ped] or t-repairs[ped]>=Config.AppearanceGuard.repairCooldown) then softRepair(ped,entry) end
   end
  end
  Wait(Config.AppearanceGuard.interval)
 end
end)
RegisterCommand('trafficnpcdebug',function()
 local count,repairsTotal=TrafficAppearance.stats()
 print(('[Traffic Director] Managed NPCs: %s | Appearance repairs: %s'):format(count,repairsTotal))
end,false)
