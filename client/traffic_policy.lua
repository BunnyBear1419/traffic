TrafficPolicy={}
TrafficPolicy.jobContext={active=false}
TrafficPolicy.activeEvent=nil
TrafficPolicy.safeMode=true
TrafficPolicy.externalState={}

local function clamp(v) return math.max(0,math.min(100,tonumber(v) or 0)) end
local function hourNow() return GetClockHours() end
local function inRush(h) return (h>=6 and h<10) or (h>=16 and h<20) end

local function applySmart(base)
 local cfg=Config.SmartTraffic or {}
 if cfg.enabled==false then return base end
 local h=hourNow()
 local out={traffic=base.traffic,npc=base.npc,parked=base.parked}
 if cfg.timeOfDay then
  if h>=23 or h<5 then out.traffic=math.min(out.traffic,clamp(cfg.nightTraffic or 25));out.npc=math.min(out.npc,clamp(cfg.lateNightNPC or 20));out.parked=math.min(out.parked,clamp(cfg.lateNightParked or 30))
  elseif inRush(h) then out.traffic=math.max(out.traffic,clamp(cfg.rushHourTraffic or 90));out.npc=math.max(out.npc,clamp(cfg.rushHourNPC or 85));out.parked=math.max(out.parked,clamp(cfg.rushHourParked or 95))
  else out.traffic=math.max(out.traffic,clamp(cfg.dayTraffic or 70)) end
 end
 local z=TrafficZones_getAt and TrafficZones_getAt(GetEntityCoords(PlayerPedId())) or nil
 if z and cfg.location then
  if z.type=='light' then out.traffic=math.min(out.traffic,45);out.npc=math.min(out.npc,50);out.parked=math.min(out.parked,55)
  elseif z.type=='heavy' then out.traffic=math.max(out.traffic,85);out.npc=math.max(out.npc,80);out.parked=math.max(out.parked,85)
  elseif z.type=='stop' or z.type=='closure' then out.traffic=0;out.npc=math.min(out.npc,25)
  elseif z.type=='emergency' then out.traffic=math.min(out.traffic,35);out.npc=math.min(out.npc,45);out.parked=math.min(out.parked,40)
  elseif z.type=='race' then out.traffic=math.min(out.traffic,45);out.parked=math.min(out.parked,35) end
 end
 return out
end

local function applyEvent(base)
 local e=TrafficPolicy.activeEvent
 if type(e)~='table' then return base end
 local s=e.settings or {}
 if s.trafficLevel~=nil then base.traffic=clamp(s.trafficLevel) end
 if s.npcLevel~=nil then base.npc=clamp(s.npcLevel) end
 if s.parkedVehicleLevel~=nil then base.parked=clamp(s.parkedVehicleLevel) end
 if s.emergencyVehicles~=nil then base.emergency=s.emergencyVehicles==true end
 if s.militaryVehicles~=nil then base.military=s.militaryVehicles==true end
 if s.mode then TrafficClientMode=s.mode end
 return base
end

local function applyJob(base)
 local c=TrafficPolicy.jobContext
 if not c or not c.active or not c.rule then return base end
 local r=c.rule;local a=r.actions or {}
 if a.traffic~=false then base.traffic=clamp(r.trafficLevel) end
 if a.npc~=false then base.npc=clamp(r.npcLevel) end
 if a.parked~=false then base.parked=clamp(r.parkedVehicleLevel) end
 if a.emergency~=false then base.emergency=r.emergencyVehicles~=false end
 if a.military~=false then base.military=r.militaryVehicles==true end
 TrafficClientMode=r.mode or TrafficClientMode
 return base
end

function TrafficPolicy.recalculate()
 if not TrafficAdjustor then return end
 local s=TrafficAdjustor.state
 TrafficClientMode=TrafficAdjustor.baseTrafficMode or TrafficClientMode or Config.DefaultMode
 local base={traffic=TrafficAdjustor.baseTrafficLevel or s.trafficLevel or 70,npc=TrafficAdjustor.baseNPCLevel or s.npcLevel or 70,parked=s.parkedVehicleLevel or 70,emergency=s.emergencyVehicles~=false,military=s.militaryVehicles~=false}
 local out=base
 if TrafficPolicy.jobContext and TrafficPolicy.jobContext.active then out=applyJob(out) else out=applySmart(out) end
 out=applyEvent(out)
 s.trafficLevel=clamp(out.traffic);s.npcLevel=clamp(out.npc);s.parkedVehicleLevel=clamp(out.parked);s.emergencyVehicles=out.emergency~=false;s.militaryVehicles=out.military==true
 s.policyReason=(TrafficPolicy.jobContext and TrafficPolicy.jobContext.active and ('Job: '..tostring(TrafficPolicy.jobContext.rule.name))) or (TrafficPolicy.activeEvent and ('Event: '..tostring(TrafficPolicy.activeEvent.name))) or 'Smart Traffic'
end

RegisterNetEvent('traffic:client:jobContext',function(ctx) TrafficPolicy.jobContext=ctx or {active=false};TrafficPolicy.recalculate() end)
RegisterNetEvent('traffic:client:trafficEvent',function(e) TrafficPolicy.activeEvent=e;TrafficPolicy.recalculate() end)

CreateThread(function()
 while true do
  TrafficPolicy.recalculate()
  TriggerServerEvent('traffic:server:requestJobContext')
  Wait((Config.JobTraffic and Config.JobTraffic.pollInterval) or 3000)
 end
end)

AddEventHandler('onClientResourceStop',function(res)
 if res~=GetCurrentResourceName() or not Config.SafeMode or Config.SafeMode.restoreOnStop==false then return end
 if TrafficAdjustor then
  local s=TrafficAdjustor.state
  s.trafficLevel=TrafficAdjustor.baseTrafficLevel or s.trafficLevel
  s.npcLevel=TrafficAdjustor.baseNPCLevel or s.npcLevel
 end
end)
