TrafficJobController={}
local resourceName=GetCurrentResourceName()

local function getFramework()
 local fw=Config.Framework
 if fw and fw~='standalone' then return fw end
 if Config.FrameworkAdapters and Config.FrameworkAdapters.enabled then
  if Config.FrameworkAdapters.qbcore then
   local ok=pcall(function() return exports['qb-core']:GetCoreObject() end)
   if ok then return 'qbcore' end
  end
  if Config.FrameworkAdapters.esx then
   local ok=pcall(function() return exports['es_extended']:getSharedObject() end)
   if ok then return 'esx' end
  end
 end
 return 'standalone'
end

local function playerJob(src)
 local fw=getFramework()
 if fw=='qbcore' then
  local ok,QBCore=pcall(function() return exports['qb-core']:GetCoreObject() end)
  if ok and QBCore and QBCore.Functions then
   local p=QBCore.Functions.GetPlayer(src)
   local j=p and p.PlayerData and p.PlayerData.job
   if j then return tostring(j.name or ''),tonumber(j.grade and (j.grade.level or j.grade) or 0) or 0,j.onduty~=false end
  end
 elseif fw=='esx' then
  local ok,ESX=pcall(function() return exports['es_extended']:getSharedObject() end)
  if ok and ESX and ESX.GetPlayerFromId then
   local p=ESX.GetPlayerFromId(src)
   local j=p and p.getJob and p.getJob() or p and p.job
   if j then return tostring(j.name or ''),tonumber(j.grade or 0) or 0,j.onDuty~=false end
  end
 end
 return '',0,true
end

local function normalizeRule(r)
 if type(r)~='table' then return nil end
 local jobs={}
 for _,j in ipairs(r.jobs or {}) do jobs[#jobs+1]=tostring(j):lower() end
 return {id=tostring(r.id or ''),name=tostring(r.name or r.id or 'Job'),jobs=jobs,minimumGrade=tonumber(r.minimumGrade) or 0,priority=tonumber(r.priority) or 0,mode=Config.Modes[r.mode] and r.mode or Config.DefaultMode,trafficLevel=math.max(0,math.min(100,tonumber(r.trafficLevel) or 70)),npcLevel=math.max(0,math.min(100,tonumber(r.npcLevel) or 70)),parkedVehicleLevel=math.max(0,math.min(100,tonumber(r.parkedVehicleLevel) or 70)),emergencyVehicles=r.emergencyVehicles~=false,militaryVehicles=r.militaryVehicles~=false,actions=r.actions or {traffic=true,npc=true,parked=true,emergency=true,military=true,events=true,zones=true}}
end

function TrafficJobController.getRules()
 local rules={}
 local sourceRules=(TrafficSettings and TrafficSettings.jobRules) or Config.JobTraffic.rules or {}
 for _,r in ipairs(sourceRules) do local n=normalizeRule(r);if n then rules[#rules+1]=n end end
 return rules
end

function TrafficJobController.resolve(src)
 if not Config.JobTraffic or Config.JobTraffic.enabled==false then return {active=false,job='',grade=0,duty=true} end
 local job,grade,duty=playerJob(src)
 local best=nil
 for _,r in ipairs(TrafficJobController.getRules()) do
  local matches=false
  for _,j in ipairs(r.jobs) do if j==job:lower() then matches=true;break end end
  if matches and grade>=r.minimumGrade and (not best or r.priority>best.priority) then best=r end
 end
 if not best then return {active=false,job=job,grade=grade,duty=duty} end
 if duty==false then return {active=false,job=job,grade=grade,duty=false,rule=best} end
 return {active=true,job=job,grade=grade,duty=duty,rule=best}
end

local function publish(src)
 TriggerClientEvent('traffic:client:jobContext',src,TrafficJobController.resolve(src))
end

RegisterNetEvent('traffic:server:requestJobContext',function() publish(source) end)

RegisterNetEvent('traffic:server:saveJobRule',function(rule)
 if not TrafficPermissions.isAdmin(source) or type(rule)~='table' then return end
 local id=tostring(rule.id or ''):lower():gsub('[^%w_%-]','_')
 if id=='' or #id>48 then return end
 local jobs={}
 for _,j in ipairs(rule.jobs or {}) do local s=tostring(j):lower():gsub('[^%s]','');if s~='' then jobs[#jobs+1]=s end end
 if #jobs==0 then return end
 TrafficSettings=TrafficSettings or {}
 TrafficSettings.jobRules=TrafficSettings.jobRules or {}
 TrafficSettings.jobRules[id]={
  id=id,name=tostring(rule.name or id):sub(1,60),jobs=jobs,minimumGrade=math.max(0,math.floor(tonumber(rule.minimumGrade) or 0)),priority=math.floor(tonumber(rule.priority) or 0),
  mode=Config.Modes[rule.mode] and rule.mode or 'normal',trafficLevel=math.max(0,math.min(100,tonumber(rule.trafficLevel) or 70)),npcLevel=math.max(0,math.min(100,tonumber(rule.npcLevel) or 70)),parkedVehicleLevel=math.max(0,math.min(100,tonumber(rule.parkedVehicleLevel) or 70)),emergencyVehicles=rule.emergencyVehicles~=false,militaryVehicles=rule.militaryVehicles==true,actions=rule.actions or {}
 }
 if TrafficSettings_save then TrafficSettings_save() end
 publish(source)
 TriggerClientEvent('traffic:client:jobRules',source,TrafficJobController.getRules())
end)

RegisterNetEvent('traffic:server:deleteJobRule',function(id)
 if not TrafficPermissions.isAdmin(source) or type(id)~='string' then return end
 TrafficSettings=TrafficSettings or {}
 if TrafficSettings.jobRules then TrafficSettings.jobRules[id]=nil end
 if TrafficSettings_save then TrafficSettings_save() end
 TriggerClientEvent('traffic:client:jobRules',source,TrafficJobController.getRules())
end)

RegisterNetEvent('traffic:server:requestJobRules',function()
 if TrafficPermissions.isAdmin(source) then TriggerClientEvent('traffic:client:jobRules',source,TrafficJobController.getRules()) end
end)

AddEventHandler('playerJoining',function() local src=source;SetTimeout(1500,function() if GetPlayerName(tostring(src)) then publish(src) end end) end)
