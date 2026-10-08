TrafficClientDeployables={}
local menuOpen=false
local selected='cone'
local rotation=0.0
local placementDistance=Config.Deployables.placementDistance or 3.0
local preview=true
local lastPreview=nil
local allowed={cone=true,barrier=true,police_barrier=true,spikes=true,flare=true}
local kits={traffic_stop='Traffic Stop',road_closure='Road Closure',checkpoint='Checkpoint',accident_scene='Accident Scene'}
local function notify(message)
 BeginTextCommandThefeedPost('STRING');AddTextComponentSubstringPlayerName('~b~Traffic Director~s~: '..tostring(message));EndTextCommandThefeedPostTicker(false,false)
end
local function coordsAhead(distance)
 local ped=PlayerPedId();local ahead=GetOffsetFromEntityInWorldCoords(ped,0.0,distance or placementDistance,0.0)
 local found,z=GetGroundZFor_3dCoord(ahead.x,ahead.y,ahead.z+3.0,false)
 if found then ahead=vector3(ahead.x,ahead.y,z+0.04) end
 return ahead
end
local function place(kind,scene)
 local ped=PlayerPedId();local ahead=coordsAhead(placementDistance)
 TriggerServerEvent('traffic:server:deployProp',kind,{x=ahead.x,y=ahead.y,z=ahead.z},(GetEntityHeading(ped)+rotation)%360,scene or '')
end
local function placeKit(kit)
 local ped=PlayerPedId();local ahead=coordsAhead(Config.Deployables.placementDistance or 3.0)
 TriggerServerEvent('traffic:server:deployKit',kit,{x=ahead.x,y=ahead.y,z=ahead.z},(GetEntityHeading(ped)+rotation)%360)
end
local function closeMenu()
 menuOpen=false;SetNuiFocus(false,false);SendNUIMessage({action='deployMenuClose'})
end
RegisterNetEvent('traffic:client:deployNotice',function(message) notify(message) end)
RegisterNetEvent('traffic:client:deployables',function(items)
 TrafficClientDeployables={}
 for _,p in ipairs(items or {}) do TrafficClientDeployables[#TrafficClientDeployables+1]=p end
end)
RegisterNetEvent('traffic:client:deployAudit',function(items) SendNUIMessage({action='deployAudit',items=items or {}}) end)
RegisterCommand('trafficprop',function(_,args)
 local kind=tostring(args[1] or ''):lower()
 if kind=='remove' then local c=GetEntityCoords(PlayerPedId());TriggerServerEvent('traffic:server:removeProp',{x=c.x,y=c.y,z=c.z});return end
 if kind=='clear' then TriggerServerEvent('traffic:server:clearOwnProps');return end
 if kind=='clearall' then TriggerServerEvent('traffic:server:clearAllProps');return end
 if not allowed[kind] then notify('Use /trafficprop cone, barrier, police_barrier, spikes, flare, remove, or clear.');return end
 place(kind)
end,false)
RegisterCommand('trafficprops',function()
 menuOpen=true;SetNuiFocus(true,true);SendNUIMessage({action='deployMenuOpen',selected=selected,rotation=rotation,distance=placementDistance,kits=kits})
end,false)
RegisterNUICallback('deployMenuClose',function(_,cb) closeMenu();cb({ok=true}) end)
RegisterNUICallback('deployPlace',function(data,cb)
 local kind=type(data)=='table' and tostring(data.kind or selected) or selected
 if allowed[kind] then selected=kind;place(kind) end
 cb({ok=true})
end)
RegisterNUICallback('deployKit',function(data,cb)
 local kit=type(data)=='table' and tostring(data.kit or '') or ''
 if kits[kit] then placeKit(kit) end
 cb({ok=true})
end)
RegisterNUICallback('deployDistance',function(data,cb) placementDistance=math.max(1.0,math.min(8.0,placementDistance+(type(data)=='table' and tonumber(data.delta) or 0)));SendNUIMessage({action='deployDistance',distance=placementDistance});cb({ok=true,distance=placementDistance}) end)
RegisterNUICallback('deployRotate',function(data,cb)
 local delta=type(data)=='table' and tonumber(data.delta) or 15
 rotation=(rotation+(delta or 15))%360
 SendNUIMessage({action='deployRotation',rotation=rotation});cb({ok=true,rotation=rotation})
end)
RegisterNUICallback('deployRemove',function(_,cb) local c=GetEntityCoords(PlayerPedId());TriggerServerEvent('traffic:server:removeProp',{x=c.x,y=c.y,z=c.z});cb({ok=true}) end)
RegisterNUICallback('deployClearScene',function(data,cb) if type(data)=='table' and type(data.scene)=='string' then TriggerServerEvent('traffic:server:clearScene',data.scene) end;cb({ok=true}) end)
RegisterNUICallback('deployClearOwn',function(_,cb) TriggerServerEvent('traffic:server:clearOwnProps');cb({ok=true}) end)
RegisterNUICallback('deployClearAll',function(_,cb) TriggerServerEvent('traffic:server:clearAllProps');cb({ok=true}) end)
RegisterNUICallback('deployAuditRequest',function(_,cb) TriggerServerEvent('traffic:server:requestDeployAudit');cb({ok=true}) end)
CreateThread(function()
 while true do
  if menuOpen and preview then
   Wait(0)
   local p=coordsAhead(Config.Deployables.placementDistance or 3.0)
   DrawMarker(1,p.x,p.y,p.z-0.9,0.0,0.0,0.0,0.0,0.0,GetEntityHeading(PlayerPedId())+rotation,0.55,0.55,0.12,190,215,240,125,false,false,2,false,nil,nil,false)
  else Wait(500) end
 end
end)
RegisterNetEvent('traffic:client:requestDeployables',function() TriggerServerEvent('traffic:server:requestDeployables') end)
CreateThread(function()
 Wait(1500);TriggerServerEvent('traffic:server:requestDeployables')
 local cooldown,previous,pending={},{},{}
 local function burst(veh)
  for tyre=0,5 do if not IsVehicleTyreBurst(veh,tyre,false) then SetVehicleTyreBurst(veh,tyre,true,1000.0) end end
 end
 while true do
  Wait(#TrafficClientDeployables>0 and 350 or 1800)
  local strips={}
  for _,p in ipairs(TrafficClientDeployables) do if p.type=='spikes' then strips[#strips+1]=p end end
  if #strips>0 then
   for _,veh in ipairs(GetGamePool('CVehicle')) do
    if DoesEntityExist(veh) and GetEntitySpeed(veh)>2.0 then
     local c=GetEntityCoords(veh);local key=tostring(NetworkGetNetworkIdFromEntity(veh));local prior=previous[key]
     if prior then
      for _,strip in ipairs(strips) do
       local dx,dy=c.x-strip.x,c.y-strip.y
       local theta=math.rad(tonumber(strip.heading) or 0)
       local signed=dx*math.cos(theta)+dy*math.sin(theta)
       local along=-dx*math.sin(theta)+dy*math.cos(theta)
       local pdx,pdy=prior.x-strip.x,prior.y-strip.y
       local priorSigned=pdx*math.cos(theta)+pdy*math.sin(theta)
       local priorAlong=-pdx*math.sin(theta)+pdy*math.cos(theta)
       local zNear=math.abs(c.z-strip.z)<=2.0 and math.abs(prior.z-strip.z)<=2.0
       local crossed=(signed==0 or priorSigned==0 or (signed<0 and priorSigned>0) or (signed>0 and priorSigned<0))
       if crossed and zNear and math.abs(along)<=2.4 and math.abs(priorAlong)<=2.4 then
        if not cooldown[key] or GetGameTimer()-cooldown[key]>(Config.Deployables.spikeCooldown or 10000) then pending[key]={vehicle=veh,expires=GetGameTimer()+2000};cooldown[key]=GetGameTimer() end
        break
       end
      end
     end
     previous[key]={x=c.x,y=c.y,z=c.z}
     local task=pending[key]
     if task then
      if GetGameTimer()>task.expires or not DoesEntityExist(task.vehicle) then pending[key]=nil
      elseif NetworkHasControlOfEntity(task.vehicle) then burst(task.vehicle);pending[key]=nil
      else NetworkRequestControlOfEntity(task.vehicle) end
     end
    end
   end
  else previous={} end
 end
end)
