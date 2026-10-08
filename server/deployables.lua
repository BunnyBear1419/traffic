TrafficDeployables = TrafficDeployables or {}
local sceneCounter=0
local audit={}
local function logAction(src,action,detail)
 local entry={time=os.time(),source=tonumber(src) or 0,name=(src and tonumber(src) and GetPlayerName(src)) or 'Console',action=action,detail=tostring(detail or '')}
 audit[#audit+1]=entry
 while #audit>150 do table.remove(audit,1) end
 print(('[Traffic Director] deployables: %s (%s) %s %s'):format(entry.name,tostring(entry.source),action,entry.detail))
end
local function authorized(src)
 if TrafficPermissions.isAdmin(src) then return true end
 if not TrafficJobController or not TrafficJobController.resolve then return false end
 local ctx=TrafficJobController.resolve(src)
 return ctx and ctx.active and ctx.rule and ctx.rule.actions and ctx.rule.actions.props==true
end
local function playerCoords(src)
 local ped=GetPlayerPed(src); if not ped or ped==0 then return nil end
 local c=GetEntityCoords(ped); return {x=c.x,y=c.y,z=c.z}
end
local function distance(a,b)
 local x,y,z=a.x-b.x,a.y-b.y,a.z-b.z; return math.sqrt(x*x+y*y+z*z)
end
local function publish()
 local items={}
 for id,p in pairs(TrafficDeployables) do
  if p.entity and DoesEntityExist(p.entity) then
   local c=GetEntityCoords(p.entity)
   items[#items+1]={id=id,type=p.type,x=c.x,y=c.y,z=c.z,heading=p.heading or 0,scene=p.scene or '',ownerName=p.ownerName or 'Unknown'}
  else TrafficDeployables[id]=nil end
 end
 TriggerClientEvent('traffic:client:deployables',-1,items)
end
local function counts(src)
 local mine,total=0,0
 for _,p in pairs(TrafficDeployables) do total=total+1;if p.owner==src then mine=mine+1 end end
 return mine,total
end
local function createProp(src,kind,pos,heading,scene)
 if not Config.Deployables or not Config.Deployables.enabled then return false,'Deployables are disabled.' end
 local model=Config.Deployables.models[kind]; if not model then return false,'Unknown prop type.' end
 local player=playerCoords(src); if not player then return false,'Player position unavailable.' end
 if not pos or not pos.x or not pos.y or not pos.z or distance(player,pos)>(Config.Deployables.placementDistance or 3.0)+8.0 then return false,'Placement is too far away.' end
 local mine,total=counts(src)
 if mine>=(Config.Deployables.maxPerPlayer or 18) or total>=(Config.Deployables.maxTotal or 160) then return false,'Deployment limit reached. Remove props before placing more.' end
 local obj=CreateObjectNoOffset(GetHashKey(model),pos.x,pos.y,pos.z,true,true,false)
 if not obj or obj==0 or not DoesEntityExist(obj) then return false,'Could not create prop. Check OneSync and model availability.' end
 local h=(tonumber(heading) or 0)%360
 if kind=='spikes' then h=(h+90)%360 end
 SetEntityHeading(obj,h); FreezeEntityPosition(obj,true)
 if SetEntityOrphanMode then SetEntityOrphanMode(obj,2) end
 local id=('tdprop_%s_%s_%s'):format(os.time(),src,math.random(10000,99999))
 TrafficDeployables[id]={id=id,entity=obj,type=kind,owner=src,ownerName=GetPlayerName(src) or ('Player '..src),heading=h,createdAt=os.time(),scene=scene or ''}
 logAction(src,'deploy',kind..(scene and (' scene='..scene) or ''))
 return true,id
end
RegisterNetEvent('traffic:server:deployProp',function(kind,coords,heading,scene)
 local src=source
 if not authorized(src) then TriggerClientEvent('traffic:client:deployNotice',src,'Your job is not authorized to deploy Traffic Director props.');return end
 if type(kind)~='string' or type(coords)~='table' then return end
 local pos={x=tonumber(coords.x),y=tonumber(coords.y),z=tonumber(coords.z)}
 if not pos.x or not pos.y or not pos.z then return end
 local ok,msg=createProp(src,kind,pos,heading,type(scene)=='string' and scene:sub(1,48) or '')
 if not ok then TriggerClientEvent('traffic:client:deployNotice',src,msg);return end
 publish()
 TriggerClientEvent('traffic:client:deployNotice',src,kind=='spikes' and 'Spike strip deployed.' or (kind:gsub('_',' ')..' deployed.'))
end)
RegisterNetEvent('traffic:server:deployKit',function(kit,origin,heading)
 local src=source
 if not authorized(src) then TriggerClientEvent('traffic:client:deployNotice',src,'Your job is not authorized to deploy Traffic Director props.');return end
 if type(kit)~='string' or type(origin)~='table' then return end
 local layout=Config.Deployables and Config.Deployables.kits and Config.Deployables.kits[kit]
 if type(layout)~='table' then TriggerClientEvent('traffic:client:deployNotice',src,'Unknown deployment kit.');return end
 local player=playerCoords(src); local base={x=tonumber(origin.x),y=tonumber(origin.y),z=tonumber(origin.z)}
 if not player or not base.x or not base.y or not base.z or distance(player,base)>(Config.Deployables.placementDistance or 3.0)+8.0 then return end
 sceneCounter=sceneCounter+1; local scene=('scene_%s_%s_%s'):format(os.time(),src,sceneCounter); local placed=0
 local rad=math.rad(tonumber(heading) or 0); local fx,fy=math.sin(rad),-math.cos(rad); local rx,ry=math.cos(rad),math.sin(rad)
 for _,item in ipairs(layout) do
  local pos={x=base.x+rx*(item.x or 0)+fx*(item.y or 0),y=base.y+ry*(item.x or 0)+fy*(item.y or 0),z=base.z}
  local ok=createProp(src,item.type,pos,heading,scene); if ok then placed=placed+1 else break end
 end
 publish()
 TriggerClientEvent('traffic:client:deployNotice',src,placed>0 and (('Placed %d props for %s.'):format(placed,kit:gsub('_',' '))) or 'Kit could not be placed. Check limits and OneSync.')
end)
RegisterNetEvent('traffic:server:removeProp',function(coords)
 local src=source
 if not authorized(src) then TriggerClientEvent('traffic:client:deployNotice',src,'Your job is not authorized to remove Traffic Director props.');return end
 if type(coords)~='table' then return end
 local pos={x=tonumber(coords.x),y=tonumber(coords.y),z=tonumber(coords.z)}
 if not pos.x or not pos.y or not pos.z then return end
 local player=playerCoords(src); if not player or distance(player,pos)>4.0 then return end
 local target,dist
 for id,p in pairs(TrafficDeployables) do
  if p.entity and DoesEntityExist(p.entity) then local c=GetEntityCoords(p.entity);local d=distance(pos,{x=c.x,y=c.y,z=c.z});if d<=(Config.Deployables.removeDistance or 8.0) and (not dist or d<dist) then target,dist=id,d end end
 end
 if not target then TriggerClientEvent('traffic:client:deployNotice',src,'No Traffic Director prop nearby.');return end
 local p=TrafficDeployables[target];if p and p.entity and DoesEntityExist(p.entity) then DeleteEntity(p.entity) end
 logAction(src,'remove',p and (p.type..' scene='..(p.scene or '')) or target)
 TrafficDeployables[target]=nil;publish();TriggerClientEvent('traffic:client:deployNotice',src,'Nearest deployed prop removed.')
end)
RegisterNetEvent('traffic:server:clearScene',function(scene)
 local src=source
 if not authorized(src) then TriggerClientEvent('traffic:client:deployNotice',src,'Not authorized to clear scenes.');return end
 if type(scene)~='string' or #scene>64 then return end
 local removed=0
 for id,p in pairs(TrafficDeployables) do if p.scene==scene and (p.owner==src or TrafficPermissions.isAdmin(src)) then if p.entity and DoesEntityExist(p.entity) then DeleteEntity(p.entity) end;TrafficDeployables[id]=nil;removed=removed+1 end end
 logAction(src,'clear_scene',scene..' count='..removed);publish();TriggerClientEvent('traffic:client:deployNotice',src,('Scene cleared (%d props).'):format(removed))
end)
RegisterNetEvent('traffic:server:clearOwnProps',function()
 local src=source
 if not authorized(src) then TriggerClientEvent('traffic:client:deployNotice',src,'Not authorized to clear props.');return end
 local removed=0
 for id,p in pairs(TrafficDeployables) do if p.owner==src then if p.entity and DoesEntityExist(p.entity) then DeleteEntity(p.entity) end;TrafficDeployables[id]=nil;removed=removed+1 end end
 logAction(src,'clear_own','count='..removed);publish();TriggerClientEvent('traffic:client:deployNotice',src,('Your props cleared (%d).'):format(removed))
end)
RegisterNetEvent('traffic:server:clearAllProps',function()
 local src=source
 if not TrafficPermissions.isAdmin(src) then return end
 local removed=0
 for id,p in pairs(TrafficDeployables) do if p.entity and DoesEntityExist(p.entity) then DeleteEntity(p.entity) end;TrafficDeployables[id]=nil;removed=removed+1 end
 logAction(src,'clear_all','count='..removed);publish();TriggerClientEvent('traffic:client:deployNotice',src,('All field props cleared (%d).'):format(removed))
end)
RegisterNetEvent('traffic:server:requestDeployables',function() publish() end)
RegisterNetEvent('traffic:server:requestDeployAudit',function()
 local src=source;if not TrafficPermissions.isAdmin(src) then return end
 TriggerClientEvent('traffic:client:deployAudit',src,audit)
end)
AddEventHandler('playerDropped',function()
 local src=source
 for id,p in pairs(TrafficDeployables) do if p.owner==src then if p.entity and DoesEntityExist(p.entity) then DeleteEntity(p.entity) end;TrafficDeployables[id]=nil end end
 publish()
end)
AddEventHandler('onResourceStop',function(res)
 if res~=GetCurrentResourceName() then return end
 for _,p in pairs(TrafficDeployables) do if p.entity and DoesEntityExist(p.entity) then DeleteEntity(p.entity) end end
end)
