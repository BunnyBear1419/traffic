TrafficAppearance={}
local managed={}
local repairs={}
local attempts={}
local repairCount=0
local lastRepair={}
local function now() return GetGameTimer() end
local function applyVariation(ped,appearance)
 if not appearance then return end
 for _,c in ipairs(appearance.components or {}) do SetPedComponentVariation(ped,c.component or c.slot or 0,c.drawable or 0,c.texture or 0,c.palette or 0) end
 for _,p in ipairs(appearance.props or {}) do
  local prop=p.prop or p.slot or 0
  if (p.drawable or -1)<0 then ClearPedProp(ped,prop) else SetPedPropIndex(ped,prop,p.drawable or 0,p.texture or 0,true) end
 end
end
local function variationMismatch(ped,appearance)
 if not Config.AppearanceGuard.verifyVariation or not appearance then return false end
 for _,c in ipairs(appearance.components or {}) do
  if GetPedDrawableVariation(ped,c.component or c.slot or 0)~=(c.drawable or 0) or GetPedTextureVariation(ped,c.component or c.slot or 0)~=(c.texture or 0) then return true end
 end
 return false
end
local function softRepair(ped,entry)
 if not DoesEntityExist(ped) or IsEntityDead(ped) then return false end
 local t=now();attempts[ped]=(attempts[ped] or 0)+1
 SetEntityVisible(ped,true,false);ResetEntityAlpha(ped);SetEntityAlpha(ped,255,false);SetEntityCollision(ped,true,true)
 if entry.appearance then applyVariation(ped,entry.appearance) end
 if entry.repair then pcall(entry.repair,ped) end
 repairs[ped]=t;lastRepair[ped]=t;repairCount=repairCount+1
 TriggerEvent('traffic:appearance:repaired',ped,entry.type,attempts[ped])
 return true
end
function TrafficAppearance.register(ped,definition)
 if not TrafficAdjustor.isFeatureEnabled('appearance') or not Config.AppearanceGuard.enabled or not DoesEntityExist(ped) or not IsEntityAPed(ped) or IsPedAPlayer(ped) then return false end
 local count=0;for _ in pairs(managed) do count=count+1 end
 if not managed[ped] and count>=Config.AppearanceGuard.maxManagedNPCs then return false end
 definition=definition or {}
 managed[ped]={type=definition.type or 'managed',appearance=definition.appearance,repair=definition.repair,model=definition.model or GetEntityModel(ped),verify=definition.verify ~= false}
 attempts[ped]=0
 return true
end
function TrafficAppearance.unregister(ped) managed[ped]=nil;repairs[ped]=nil;lastRepair[ped]=nil;attempts[ped]=nil end
function TrafficAppearance.stats()
 local count=0;local invisible=0;local mismatched=0
 for ped,entry in pairs(managed) do
  if DoesEntityExist(ped) then
   count=count+1;if not IsEntityVisible(ped) or GetEntityAlpha(ped)<250 then invisible=invisible+1 end
   if variationMismatch(ped,entry.appearance) then mismatched=mismatched+1 end
  end
 end
 return count,repairCount,invisible,mismatched
end
exports('RegisterManagedNPC',function(ped,definition) return TrafficAppearance.register(ped,definition) end)
exports('UnregisterManagedNPC',function(ped) TrafficAppearance.unregister(ped) end)
exports('GetNPCAppearanceStats',function() local a,b,c,d=TrafficAppearance.stats();return {managed=a,repairs=b,invisible=c,mismatched=d} end)
RegisterNetEvent('traffic:appearance:register',function(ped,definition) TrafficAppearance.register(ped,definition) end)
RegisterNetEvent('traffic:appearance:unregister',function(ped) TrafficAppearance.unregister(ped) end)
local function needsRepair(ped,entry) return Config.AppearanceGuard.repairInvisible and (not IsEntityVisible(ped) or GetEntityAlpha(ped)<250 or variationMismatch(ped,entry.appearance)) end
CreateThread(function()
 while true do
  if TrafficAdjustor.isFeatureEnabled('appearance') and Config.AppearanceGuard.enabled then
   local t=now()
   for ped,entry in pairs(managed) do
    if not DoesEntityExist(ped) then managed[ped]=nil;repairs[ped]=nil;attempts[ped]=nil
    elseif entry.verify and needsRepair(ped,entry) and (not repairs[ped] or t-repairs[ped]>=Config.AppearanceGuard.retryBackoff) and (attempts[ped] or 0)<Config.AppearanceGuard.maxRepairAttempts then softRepair(ped,entry) end
   end
  end
  Wait(Config.AppearanceGuard.interval)
 end
end)
RegisterCommand('trafficnpcdebug',function()
 local a,b,c,d=TrafficAppearance.stats()
 print(('[Traffic Director] Managed NPCs: %s | Repairs: %s | Invisible: %s | Variation mismatches: %s'):format(a,b,c,d))
end,false)
