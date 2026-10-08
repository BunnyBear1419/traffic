TrafficClientDeployables={}
local function notify(message)
 BeginTextCommandThefeedPost('STRING');AddTextComponentSubstringPlayerName('~b~Traffic Director~s~: '..tostring(message));EndTextCommandThefeedPostTicker(false,false)
end
RegisterNetEvent('traffic:client:deployNotice',function(message) notify(message) end)
RegisterNetEvent('traffic:client:deployables',function(items)
 TrafficClientDeployables={}
 for _,p in ipairs(items or {}) do TrafficClientDeployables[#TrafficClientDeployables+1]=p end
end)
local allowed={cone=true,barrier=true,police_barrier=true,spikes=true,flare=true}
RegisterCommand('trafficprop',function(_,args)
 local kind=tostring(args[1] or ''):lower()
 local ped=PlayerPedId()
 if kind=='remove' then
  local c=GetEntityCoords(ped)
  TriggerServerEvent('traffic:server:removeProp',{x=c.x,y=c.y,z=c.z})
  return
 end
 if not allowed[kind] then
  notify('Use /trafficprop cone, barrier, police_barrier, spikes, flare, or remove.')
  return
 end
 local ahead=GetOffsetFromEntityInWorldCoords(ped,0.0,Config.Deployables.placementDistance or 3.0,0.0)
 local found,z=GetGroundZFor_3dCoord(ahead.x,ahead.y,ahead.z+2.0,false)
 if found then ahead=vector3(ahead.x,ahead.y,z+0.03) end
 TriggerServerEvent('traffic:server:deployProp',kind,{x=ahead.x,y=ahead.y,z=ahead.z},GetEntityHeading(ped))
end,false)
RegisterNetEvent('traffic:client:requestDeployables',function() TriggerServerEvent('traffic:server:requestDeployables') end)
CreateThread(function()
 Wait(1500);TriggerServerEvent('traffic:server:requestDeployables')
 local cooldown={}
 while true do
  Wait(700)
  local strips={}
  for _,p in ipairs(TrafficClientDeployables) do if p.type=='spikes' then strips[#strips+1]=p end end
  if #strips>0 then
   for _,veh in ipairs(GetGamePool('CVehicle')) do
    if DoesEntityExist(veh) and GetEntitySpeed(veh)>2.0 then
     local c=GetEntityCoords(veh)
     for _,s in ipairs(strips) do
      local dx,dy,dz=c.x-s.x,c.y-s.y,c.z-s.z
      if dx*dx+dy*dy+dz*dz<=(Config.Deployables.spikeRadius or 2.2)^2 then
       local key=tostring(NetworkGetNetworkIdFromEntity(veh))
       if not cooldown[key] or GetGameTimer()-cooldown[key]>10000 then
        cooldown[key]=GetGameTimer()
        for tyre=0,5 do if not IsVehicleTyreBurst(veh,tyre,false) then SetVehicleTyreBurst(veh,tyre,true,1000.0) end end
       end
       break
      end
     end
    end
   end
  end
 end
end)
