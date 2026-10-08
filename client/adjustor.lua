TrafficAdjustor={state={mode=Config.Adjustor.mode,trafficLevel=Config.Adjustor.trafficLevel,npcLevel=Config.Adjustor.npcLevel,population=0,players=0,reason='Configured'},features={}}
local defaults=Config.FeatureToggles or {}
for k,v in pairs(defaults) do TrafficAdjustor.features[k]=v end

local function clamp(v,a,b) return math.max(a,math.min(b,v)) end
local function feature(name)
 return TrafficAdjustor.features[name] ~= false
end
function TrafficAdjustor.isFeatureEnabled(name) return feature(name) end
function TrafficAdjustor.getTrafficScale()
 local a=Config.Adjustor or {}
 return a.minTrafficScale + ((TrafficAdjustor.state.trafficLevel or 70)/100)*(a.maxTrafficScale-a.minTrafficScale)
end
function TrafficAdjustor.getNPCScale()
 local a=Config.Adjustor or {}
 return a.minNPCScale + ((TrafficAdjustor.state.npcLevel or 70)/100)*(a.maxNPCScale-a.minNPCScale)
end
function TrafficAdjustor.getMaxTasks()
 return math.max(1,math.floor(Config.MaxTrafficTasks*TrafficAdjustor.getTrafficScale()))
end
function TrafficAdjustor.getScanInterval()
 local a=Config.Adjustor or {}
 local scale=TrafficAdjustor.getTrafficScale()
 return math.floor(a.maxTrafficScale>0 and clamp(Config.ScanInterval/(0.45+scale*0.55),a.minScanInterval or 350,a.maxScanInterval or 2000) or Config.ScanInterval)
end
function TrafficAdjustor.snapshot()
 return {mode=TrafficAdjustor.state.mode,trafficLevel=TrafficAdjustor.state.trafficLevel,npcLevel=TrafficAdjustor.state.npcLevel,population=TrafficAdjustor.state.population,players=TrafficAdjustor.state.players,reason=TrafficAdjustor.state.reason,features=TrafficAdjustor.features,trafficScale=TrafficAdjustor.getTrafficScale(),npcScale=TrafficAdjustor.getNPCScale(),maxTasks=TrafficAdjustor.getMaxTasks(),scanInterval=TrafficAdjustor.getScanInterval()}
end
local function applySettings(settings)
 if type(settings)~='table' then return end
 for k,v in pairs(defaults) do TrafficAdjustor.features[k]=settings.features and settings.features[k] ~= false or v end
 local a=Config.Adjustor or {}
 TrafficAdjustor.state.mode=settings.mode=='manual' and 'manual' or 'auto'
 TrafficAdjustor.state.trafficLevel=clamp(tonumber(settings.trafficLevel) or a.trafficLevel,0,100)
 TrafficAdjustor.state.npcLevel=clamp(tonumber(settings.npcLevel) or a.npcLevel,0,100)
end
RegisterNetEvent('traffic:client:settings',function(settings) applySettings(settings) end)

CreateThread(function()
 while true do
  if feature('performance') and (Config.Adjustor.enabled ~= false) then
   local pool=GetGamePool('CVehicle')
   local population=#pool
   local players=#GetActivePlayers()
   TrafficAdjustor.state.population=population
   TrafficAdjustor.state.players=players
   if TrafficAdjustor.state.mode=='auto' then
    local a=Config.Adjustor
    local traffic=TrafficAdjustor.state.trafficLevel
    if population>=a.criticalPopulation then traffic=math.max(0,traffic-35);TrafficAdjustor.state.reason='Critical traffic population'
    elseif population>=a.highPopulation then traffic=math.max(0,traffic-18);TrafficAdjustor.state.reason='High traffic population'
    elseif population<=a.lowPopulation then traffic=math.min(100,traffic+12);TrafficAdjustor.state.reason='Low traffic population'
    else TrafficAdjustor.state.reason='Balanced server load' end
    if players>=a.highPlayerCount then traffic=math.max(0,traffic-10)
    elseif players<=a.lowPlayerCount then traffic=math.min(100,traffic+5) end
    TrafficAdjustor.state.trafficLevel=clamp(traffic,0,100)
    TrafficAdjustor.state.npcLevel=clamp(traffic,0,100)
   end
  end
  Wait((Config.Adjustor and Config.Adjustor.updateInterval) or 3000)
 end
end)
