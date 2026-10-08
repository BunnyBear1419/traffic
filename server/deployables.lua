TrafficDeployables = TrafficDeployables or {}
local function authorized(src)
 if TrafficPermissions.isAdmin(src) then return true end
 if not TrafficJobController or not TrafficJobController.resolve then return false end
 local ctx=TrafficJobController.resolve(src)
 return ctx and ctx.active and ctx.rule and ctx.rule.actions and ctx.rule.actions.props==true
end
local function playerCoords(src)
 local ped=GetPlayerPed(src)
 if not ped or ped==0 then return nil end
 local c=GetEntityCoords(ped)
 return {x=c.x,y=c.y,z=c.z}
end
local function distance(a,b)
 local x,y,z=a.x-b.x,a.y-b.y,a.z-b.z
 return math.sqrt(x*x+y*y+z*z)
end
local function publish()
 local items={}
 for id,p in pairs(TrafficDeployables) do
  if p.entity and DoesEntityExist(p.entity) then
   local c=GetEntityCoords(p.entity)
   items[#items+1]={id=id,type=p.type,x=c.x,y=c.y,z=c.z,heading=p.heading or 0}
  else TrafficDeployables[id]=nil end
 end
 TriggerClientEvent('traffic:client:deployables',-1,items)
end
RegisterNetEvent('traffic:server:deployProp',function(kind,coords,heading)
 local src=source
 if not Config.Deployables or not Config.Deployables.enabled then return end
 if not authorized(src) then TriggerClientEvent('traffic:client:deployNotice',src,'Your job is not authorized to deploy Traffic Director props.');return end
 if type(kind)~='string' or type(coords)~='table' then return end
 local model=Config.Deployables.models[kind]
 if not model then return end
 local player=playerCoords(src)
 if not player then return end
 local pos={x=tonumber(coords.x),y=tonumber(coords.y),z=tonumber(coords.z)}
 if not pos.x or not pos.y or not pos.z or distance(player,pos)>(Config.Deployables.placementDistance or 3.0)+5.0 then return end
 local mine,total=0,0
 for _,p in pairs(TrafficDeployables) do total=total+1;if p.owner==src then mine=mine+1 end end
 if mine>=(Config.Deployables.maxPerPlayer or 12) or total>=(Config.Deployables.maxTotal or 120) then
  TriggerClientEvent('traffic:client:deployNotice',src,'Deployment limit reached. Remove nearby props before placing more.')
  return
 end
 local hash=GetHashKey(model)
 local obj=CreateObjectNoOffset(hash,pos.x,pos.y,pos.z,true,true,false)
 if not obj or obj==0 or not DoesEntityExist(obj) then
  TriggerClientEvent('traffic:client:deployNotice',src,'Could not create this prop. Check OneSync and model availability.')
  return
 end
 local h=tonumber(heading) or 0
 if kind=='spikes' then h=h+90.0 end
 SetEntityHeading(obj,h)
 FreezeEntityPosition(obj,true)
 local id=('tdprop_%s_%s'):format(os.time(),math.random(10000,99999))
 TrafficDeployables[id]={id=id,entity=obj,type=kind,owner=src,heading=h,createdAt=os.time()}
 publish()
 TriggerClientEvent('traffic:client:deployNotice',src,kind=='spikes' and 'Spike strip deployed.' or (kind:gsub('_',' ')..' deployed.'))
end)
RegisterNetEvent('traffic:server:removeProp',function(coords)
 local src=source
 if not authorized(src) then TriggerClientEvent('traffic:client:deployNotice',src,'Your job is not authorized to remove Traffic Director props.');return end
 if type(coords)~='table' then return end
 local pos={x=tonumber(coords.x),y=tonumber(coords.y),z=tonumber(coords.z)}
 if not pos.x or not pos.y or not pos.z then return end
 local player=playerCoords(src)
 if not player or distance(player,pos)>4.0 then return end
 local target,dist
 for id,p in pairs(TrafficDeployables) do
  if p.entity and DoesEntityExist(p.entity) then
   local c=GetEntityCoords(p.entity);local d=distance(pos,{x=c.x,y=c.y,z=c.z})
   if d<=(Config.Deployables.removeDistance or 8.0) and (not dist or d<dist) then target,dist=id,d end
  end
 end
 if not target then TriggerClientEvent('traffic:client:deployNotice',src,'No Traffic Director prop nearby.');return end
 local p=TrafficDeployables[target]
 if p and p.entity and DoesEntityExist(p.entity) then DeleteEntity(p.entity) end
 TrafficDeployables[target]=nil;publish()
 TriggerClientEvent('traffic:client:deployNotice',src,'Nearest deployed prop removed.')
end)
AddEventHandler('playerDropped',function()
 local src=source
 for id,p in pairs(TrafficDeployables) do
  if p.owner==src then
   if p.entity and DoesEntityExist(p.entity) then DeleteEntity(p.entity) end
   TrafficDeployables[id]=nil
  end
 end
 publish()
end)
AddEventHandler('onResourceStop',function(res)
 if res~=GetCurrentResourceName() then return end
 for _,p in pairs(TrafficDeployables) do if p.entity and DoesEntityExist(p.entity) then DeleteEntity(p.entity) end end
end)
RegisterNetEvent('traffic:server:requestDeployables',function() publish() end)
