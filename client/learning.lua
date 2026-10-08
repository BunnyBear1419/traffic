TrafficLearning={active=false,pending=false,points={},lastSample=0,distance=0,status='IDLE',lastSaved='',startedAt=0}
local function hv(h) local r=math.rad(h); return math.sin(r),math.cos(r) end
local function notify()
 if TrafficLearning.snapshot then
  SendNUIMessage({action='learning',learning=TrafficLearning.snapshot()})
 end
end
function TrafficLearning.snapshot()
 return {active=TrafficLearning.active,pending=TrafficLearning.pending,points=#TrafficLearning.points,distance=TrafficLearning.distance,status=TrafficLearning.status,lastSaved=TrafficLearning.lastSaved,startedAt=TrafficLearning.startedAt}
end
function TrafficLearning.onSaved(data)
 TrafficLearning.pending=false
 TrafficLearning.active=false
 TrafficLearning.status=('Saved %d route points'):format(tonumber(data and data.points) or #TrafficLearning.points)
 TrafficLearning.lastSaved=('Saved at %.1fs'):format(GetGameTimer()/1000)
 TriggerEvent('chat:addMessage',{args={'Traffic Director',('Route saved: %s (%d points).'):format(tostring(data and data.name or 'Learned Route'),tonumber(data and data.points) or #TrafficLearning.points)}})
 TrafficLearning.points={}
 TrafficLearning.distance=0
 TrafficLearning.lastSample=0
 notify()
end
function TrafficLearning.toggle()
 if not TrafficLearning.active then
  if not TrafficAdjustor.isFeatureEnabled('learning') then
   TrafficLearning.status='Learning feature is disabled';notify();return
  end
  TrafficLearning.active=true;TrafficLearning.pending=false;TrafficLearning.points={};TrafficLearning.distance=0;TrafficLearning.lastSample=0;TrafficLearning.startedAt=GetGameTimer();TrafficLearning.status='Recording';notify()
  TriggerEvent('chat:addMessage',{args={'Traffic Director','Teach Route enabled. Drive the intended path, then use /trafficteach again to save it.'}})
 else
  TrafficLearning.active=false
  if #TrafficLearning.points>=2 then
   TrafficLearning.pending=true;TrafficLearning.status='Saving';notify()
   TriggerServerEvent('traffic:server:addRoute',{name='Learned Route',loop=false,points=TrafficLearning.points})
  else
   TrafficLearning.status='Not enough route points';TrafficLearning.points={};TrafficLearning.distance=0;notify()
   TriggerEvent('chat:addMessage',{args={'Traffic Director','Not enough route points to save.'}})
  end
 end
end
RegisterNetEvent('traffic:client:toggleLearning',TrafficLearning.toggle)
CreateThread(function()
 while true do
  if TrafficLearning.active then
   local ped=PlayerPedId()
   local v=GetVehiclePedIsIn(ped,false)
   if v~=0 and GetPedInVehicleSeat(v,-1)==ped and GetEntitySpeed(v)>=Config.Learning.minSpeed then
    local now=GetGameTimer()
    if now-TrafficLearning.lastSample>=Config.Learning.sampleInterval then
     local p=GetEntityCoords(v)
     if #TrafficLearning.points==0 or Traffic.distance(p,TrafficLearning.points[#TrafficLearning.points])>=Config.RouteSampleDistance then
      local previous=TrafficLearning.points[#TrafficLearning.points]
      local h=GetEntityHeading(v);local dx,dy=hv(h)
      TrafficLearning.points[#TrafficLearning.points+1]={x=p.x,y=p.y,z=p.z,heading=h,dx=dx,dy=dy}
      if previous then TrafficLearning.distance=TrafficLearning.distance+Traffic.distance(p,previous) end
      TrafficLearning.status='Recording'
      notify()
     end
     TrafficLearning.lastSample=now
    end
   end
   Wait(100)
  else Wait(500) end
 end
end)