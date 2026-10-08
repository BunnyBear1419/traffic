TrafficAdjustor={state={mode=Config.Adjustor.mode,trafficLevel=Config.Adjustor.trafficLevel,npcLevel=Config.Adjustor.npcLevel,population=0,players=0,reason='Configured'},features={},baseTrafficLevel=Config.Adjustor.trafficLevel,baseNPCLevel=Config.Adjustor.npcLevel}
local defaults=Config.FeatureToggles or {}
for k,v in pairs(defaults) do TrafficAdjustor.features[k]=v end

local function clamp(v,a,b) return math.max(a,math.min(b,v)) end
local function feature(name) return TrafficAdjustor.features[name] ~= false end
function TrafficAdjustor.isFeatureEnabled(name) return feature(name) end
function TrafficAdjustor.getTrafficScale()
 local a=Config.Adjustor or {}
 local level=tonumber(TrafficAdjustor.state.trafficLevel) or 70
 if level<=0 then return 0 end
 local mode=TrafficClientMode or Config.DefaultMode
 if mode=='stop' then return 0 end
 local modeScale=(Config.Modes[mode] and tonumber(Config.Modes[mode].density)) or 1.0
 return math.max(0,a.minTrafficScale + (level/100)*(a.maxTrafficScale-a.minTrafficScale))*modeScale
end
function TrafficAdjustor.getPopulationDensity(base)
 local density=tonumber(base) or 1.0
 return math.max(0,math.min(1.5,density*TrafficAdjustor.getTrafficScale()))
end
function TrafficAdjustor.getNPCScale()
 local a=Config.Adjustor or {}
 local level=tonumber(TrafficAdjustor.state.npcLevel) or 70
 if level<=0 then return 0 end
 local mode=TrafficClientMode or Config.DefaultMode
 if mode=='stop' then return 0 end
 local modeScale=(Config.Modes[mode] and tonumber(Config.Modes[mode].density)) or 1.0
 return math.max(0,a.minNPCScale + (level/100)*(a.maxNPCScale-a.minNPCScale))*modeScale
end
function TrafficAdjustor.getMaxTasks()
 local scale=TrafficAdjustor.getTrafficScale()
 if scale<=0 then return 0 end
 return math.max(1,math.floor(Config.MaxTrafficTasks*scale))
end
function TrafficAdjustor.getScanInterval()
 local a=Config.Adjustor or {}
 local scale=TrafficAdjustor.getTrafficScale()
 return math.floor(a.maxTrafficScale>0 and clamp(Config.ScanInterval/(0.45+scale*0.55),a.minScanInterval or 350,a.maxScanInterval or 2000) or Config.ScanInterval)
end
function TrafficAdjustor.snapshot()
 return {mode=TrafficAdjustor.state.mode,trafficMode=TrafficClientMode or Config.DefaultMode,trafficLevel=TrafficAdjustor.state.trafficLevel,npcLevel=TrafficAdjustor.state.npcLevel,population=TrafficAdjustor.state.population,players=TrafficAdjustor.state.players,reason=TrafficAdjustor.state.reason,features=TrafficAdjustor.features,trafficScale=TrafficAdjustor.getTrafficScale(),npcScale=TrafficAdjustor.getNPCScale(),maxTasks=TrafficAdjustor.getMaxTasks(),scanInterval=TrafficAdjustor.getScanInterval()}
end
local function applySettings(settings)
 if type(settings)~='table' then return end
 for k,v in pairs(defaults) do TrafficAdjustor.features[k]=settings.features and settings.features[k] ~= false or v end
 local a=Config.Adjustor or {}
 TrafficAdjustor.state.mode=settings.mode=='manual' and 'manual' or 'auto'
 TrafficAdjustor.state.trafficLevel=clamp(tonumber(settings.trafficLevel) or a.trafficLevel,0,100)
 TrafficAdjustor.state.npcLevel=clamp(tonumber(settings.npcLevel) or a.npcLevel,0,100)
 TrafficAdjustor.baseTrafficLevel=TrafficAdjustor.state.trafficLevel
 TrafficAdjustor.baseNPCLevel=TrafficAdjustor.state.npcLevel
 TrafficAdjustor.state.reason=TrafficAdjustor.state.mode=='manual' and 'Manual control' or 'Configured'
 if type(settings.trafficMode)=='string' and Config.Modes[settings.trafficMode] then TrafficClientMode=settings.trafficMode end
 TrafficAdjustor.state.lastAppliedAt=GetGameTimer()
end
RegisterNetEvent('traffic:client:settings',function(settings) applySettings(settings) end)

CreateThread(function()
 while true do
  if feature('performance') and (Config.Adjustor.enabled ~= false) then
   -- Avoid GetGamePool here: it previously contributed to native instability.
   -- Population is intentionally a bounded local-proximity signal, not a full pool count.
   local player=PlayerPedId()
   local p=GetEntityCoords(player)
   local nearby=GetClosestVehicle(p.x,p.y,p.z,120.0,0,70)
   TrafficAdjustor.state.population=(nearby and nearby~=0 and DoesEntityExist(nearby)) and 1 or 0
   TrafficAdjustor.state.players=#GetActivePlayers()
   if TrafficAdjustor.state.mode=='auto' then
    local a=Config.Adjustor
    local traffic=TrafficAdjustor.baseTrafficLevel
    local npc=TrafficAdjustor.baseNPCLevel
    -- Auto mode uses server/player load plus a bounded nearby-traffic signal.
    if TrafficAdjustor.state.population>=1 and TrafficAdjustor.state.players>=a.highPlayerCount then
     traffic=traffic-10;npc=npc-8;TrafficAdjustor.state.reason='High player load'
    elseif TrafficAdjustor.state.population==0 and TrafficAdjustor.state.players<=a.lowPlayerCount then
     traffic=traffic+5;npc=npc+4;TrafficAdjustor.state.reason='Low nearby traffic'
    else
     TrafficAdjustor.state.reason='Balanced server load'
    end
    TrafficAdjustor.state.trafficLevel=clamp(traffic,0,100)
    TrafficAdjustor.state.npcLevel=clamp(npc,0,100)
   end
  end
  Wait((Config.Adjustor and Config.Adjustor.updateInterval) or 3000)
 end
end)