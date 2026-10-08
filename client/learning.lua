TrafficLearning={active=false,points={},lastSample=0}
local function hv(h) local r=math.rad(h); return math.sin(r),math.cos(r) end
function TrafficLearning.toggle()
 TrafficLearning.active=not TrafficLearning.active
 if TrafficLearning.active then
  TrafficLearning.points={}
  TriggerEvent('chat:addMessage',{args={'Traffic Director','Teach Route enabled. Drive the intended path, then use /trafficteach again to save it.'}})
 else
  if #TrafficLearning.points>=2 then
   TriggerServerEvent('traffic:server:addRoute',{name='Learned Route '..os.date('%H:%M:%S'),loop=false,points=TrafficLearning.points})
   TriggerEvent('chat:addMessage',{args={'Traffic Director',('Saved %d route points.'):format(#TrafficLearning.points)}})
  else TriggerEvent('chat:addMessage',{args={'Traffic Director','Not enough route points to save.'}}) end
  TrafficLearning.points={}
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
      local h=GetEntityHeading(v);local dx,dy=hv(h)
      TrafficLearning.points[#TrafficLearning.points+1]={x=p.x,y=p.y,z=p.z,heading=h,dx=dx,dy=dy}
     end
     TrafficLearning.lastSample=now
    end
   end
   Wait(100)
  else Wait(500) end
 end
end)
