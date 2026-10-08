TrafficDiscovery={active={},lastSend={}}
local function npc(v)
 if not DoesEntityExist(v) or not IsEntityAVehicle(v) then return false end
 local d=GetPedInVehicleSeat(v,-1)
 return d~=0 and DoesEntityExist(d) and not IsPedAPlayer(d)
end
local function push(v,s)
 local now=GetGameTimer()
 if now-(TrafficDiscovery.lastSend[v] or 0)<Config.AutoDiscovery.sampleInterval then return end
 local p=GetEntityCoords(v)
 local a=s.points[#s.points]
 if not a or Traffic.distance(p,a)>=Config.RouteSampleDistance then
  s.points[#s.points+1]={x=p.x,y=p.y,z=p.z,heading=GetEntityHeading(v)}
 end
 TrafficDiscovery.lastSend[v]=now
end
CreateThread(function()
 while true do
  if TrafficAdjustor.isFeatureEnabled('discovery') and Config.AutoDiscovery.enabled then
   local player=PlayerPedId()
   local pp=GetEntityCoords(player)
   local radius=math.min(140.0,math.max(60.0,(Config.AutoDiscovery.sampleInterval or 1200)/10.0))
   local v=GetClosestVehicle(pp.x,pp.y,pp.z,radius,0,70)
   if v and v~=0 and npc(v) and TrafficOwnership.isLocal(v) and GetEntitySpeed(v)>=Config.AutoDiscovery.minSpeed then
     local s=TrafficDiscovery.active[v]
     if not s then s={points={},started=GetGameTimer(),last=GetGameTimer()};TrafficDiscovery.active[v]=s end
     push(v,s);s.last=GetGameTimer()
    end
   end
   local now=GetGameTimer()
   for v,s in pairs(TrafficDiscovery.active) do
    if not DoesEntityExist(v) then TrafficDiscovery.active[v]=nil;TrafficDiscovery.lastSend[v]=nil
    elseif now-s.last>Config.AutoDiscovery.successWindow and #s.points>=Config.AutoDiscovery.minSamples then
     TriggerServerEvent('traffic:server:discoverRoute',{points=s.points,successes=1,confidence=Config.AutoDiscovery.confidenceStart})
     TrafficIntelligence.stats.discoveries=TrafficIntelligence.stats.discoveries+1
     TrafficDiscovery.active[v]=nil;TrafficDiscovery.lastSend[v]=nil
    elseif now-s.last>Config.AutoDiscovery.successWindow then
     TrafficDiscovery.active[v]=nil;TrafficDiscovery.lastSend[v]=nil
    end
   end
  end
  Wait(1000)
 end
end)
