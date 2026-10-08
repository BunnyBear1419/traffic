TrafficNPCManager={}
local points={}
local managed={}
local function isController()
 return (GlobalState.trafficDirectorController or 0)==GetPlayerServerId(PlayerId())
end
local function validModel(model) return type(model)=='number' and IsModelInCdimage(model) and IsModelValid(model) end
local function loadModel(model)
 if not validModel(model) then return false end
 RequestModel(model)
 local untilAt=GetGameTimer()+5000
 while not HasModelLoaded(model) and GetGameTimer()<untilAt do Wait(50) end
 return HasModelLoaded(model)
end
local function spawn(def)
 if not isController() or not Config.NPCManager.enabled or not def or not loadModel(def.model) then return 0 end
 local p=def.coords
 local ped=CreatePed(4,def.model,p.x,p.y,p.z,def.heading or 0.0,true,true)
 if ped==0 then return 0 end
 SetEntityAsMissionEntity(ped,true,true)
 if def.freeze then FreezeEntityPosition(ped,true) end
 if def.scenario then TaskStartScenarioInPlace(ped,def.scenario,0,true) end
 if def.appearance then TrafficAppearance.register(ped,{type=def.type or 'managed',appearance=def.appearance,repair=def.repair}) end
 local id=('%s:%s'):format(def.id,GetGameTimer());managed[id]={ped=ped,pointId=def.id,def=def,spawned=GetGameTimer()}
 SetModelAsNoLongerNeeded(def.model)
 return ped
end
function TrafficNPCManager.registerPoint(def)
 if not Config.NPCManager.enabled or type(def)~='table' or not def.coords or not def.model then return false end
 local count=0;for _ in pairs(points) do count=count+1 end
 if count>=Config.NPCManager.maxSpawnPoints then return false end
 def.id=def.id or ('spawn_'..GetGameTimer()..'_'..math.random(1000,9999));points[def.id]=def
 return true
end
function TrafficNPCManager.unregisterPoint(id) points[id]=nil end
function TrafficNPCManager.stats()
 local alive=0;for _,e in pairs(managed) do if DoesEntityExist(e.ped) then alive=alive+1 end end
 local total=0;for _ in pairs(points) do total=total+1 end
 return {spawnPoints=total,managed=alive}
end
exports('RegisterNPCSpawnPoint',function(def) return TrafficNPCManager.registerPoint(def) end)
exports('UnregisterNPCSpawnPoint',function(id) TrafficNPCManager.unregisterPoint(id) end)
exports('GetNPCManagerStats',TrafficNPCManager.stats)
CreateThread(function()
 while true do
  if isController() and Config.NPCManager.enabled then
   local me=GetEntityCoords(PlayerPedId())
   for id,def in pairs(points) do
    local existing=false
    for _,e in pairs(managed) do if e.pointId==id and DoesEntityExist(e.ped) then existing=true end end
    if not existing and Config.NPCManager.respawn and Traffic.distance(me,def.coords)<=Config.NPCManager.spawnDistance then
     local total=0;for _ in pairs(managed) do total=total+1 end
     if total<Config.NPCManager.maxManaged then spawn(def) end
    end
   end
   for id,e in pairs(managed) do
    if not DoesEntityExist(e.ped) then managed[id]=nil
    elseif Traffic.distance(me,GetEntityCoords(e.ped))>Config.NPCManager.despawnDistance then
     TrafficAppearance.unregister(e.ped);DeleteEntity(e.ped);managed[id]=nil
    end
   end
  end
  Wait(1000)
 end
end)
