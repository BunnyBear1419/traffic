TrafficMLOAudit={last=nil,ignored={},modelIndex={},evidence=TrafficMLOEvidence or {}}
local collisionExt=Config.MLOCollisionAudit.includeExtensions

local function ext(path)
 local e=path:match('%.([^%.%/]+)$')
 return e and e:lower() or nil
end

local function basename(path)
 local name=path:gsub('\\','/'):match('([^/]+)$') or path
 return (name:gsub('%.[^%.]+$','')):lower()
end

local function fingerprint(raw)
 local h=2166136261
 for i=1,#raw do h=((h ~ raw:byte(i))*16777619)%4294967296 end
 return ('%08x:%d'):format(h,#raw)
end

local function addFile(files,resource,path,kind)
 if #files>=Config.MLOCollisionAudit.maxFilesPerResource then return end
 local e=ext(path)
 if not e or not collisionExt[e] then return end
 local raw=LoadResourceFile(resource,path)
 if not raw or #raw<Config.MLOCollisionAudit.minimumDuplicateSize then return end
 files[#files+1]={resource=resource,path=path,ext=e,size=#raw,fingerprint=fingerprint(raw),kind=kind,modelName=basename(path)}
end

local function scanResource(resource)
 local files={}
 local n=GetNumResourceMetadata(resource,'files') or 0
 for i=0,n-1 do addFile(files,resource,GetResourceMetadata(resource,'files',i) or '','manifest') end
 local d=GetNumResourceMetadata(resource,'data_file') or 0
 for i=0,d-1 do
  local value=GetResourceMetadata(resource,'data_file',i) or ''
  for path in value:gmatch("['\"]([^'\"]+%.[%w_]+)['\"]") do addFile(files,resource,path,'data_file') end
 end
 return files
end

local function resourceIgnored(resource)
 for _,r in ipairs(Config.MLOCollisionAudit.ignoreResources or {}) do
  if r==resource then return true end
 end
 return false
end

local function modelHash(name)
 if type(name)~='string' or name=='' or not GetHashKey then return nil end
 local ok,h=pcall(GetHashKey,name)
 return ok and tonumber(h) or nil
end

local function addModelIndex(file)
 local h=modelHash(file.modelName)
 if not h then return end
 TrafficMLOAudit.modelIndex[h]=TrafficMLOAudit.modelIndex[h] or {}
 local list=TrafficMLOAudit.modelIndex[h]
 for _,v in ipairs(list) do if v.resource==file.resource and v.path==file.path then return end end
 if #list<12 then list[#list+1]={resource=file.resource,path=file.path,ext=file.ext,size=file.size} end
end

local function distance(a,b)
 local dx=(a.x or 0)-(b.x or 0);local dy=(a.y or 0)-(b.y or 0);local dz=(a.z or 0)-(b.z or 0)
 return math.sqrt(dx*dx+dy*dy+dz*dz)
end

local function decayEvidence(now)
 if not Config.MLOCollisionAudit.runtime.enabled or Config.MLOCollisionAudit.runtime.confidenceDecayHours<=0 then return false end
 local ttl=Config.MLOCollisionAudit.runtime.confidenceDecayHours*3600
 local changed=false
 for id,e in pairs(TrafficMLOEvidence or {}) do
  if not e.verified and (e.lastSeen or 0)>0 and now-(e.lastSeen or now)>ttl then
   e.confidence=math.max(0,(tonumber(e.confidence) or 0)-10)
   e.hits=math.max(0,(tonumber(e.hits) or 0)-1)
   e.state=evidenceState and evidenceState(e) or 'suspected'
   e.lastDecay=now
   changed=true
   if (e.confidence or 0)<=0 and (e.hits or 0)<=0 then TrafficMLOEvidence[id]=nil end
  end
 end
 return changed
end

local function evidenceState(e)
 local hits=tonumber(e.hits) or 0
 local candidates=e.resources or {}
 local candidateCount=0
 for _ in pairs(candidates) do candidateCount=candidateCount+1 end
 if e.verified then return 'verified' end
 if candidateCount>0 and hits>=5 then return 'high_confidence' end
 if hits>=Config.MLOCollisionAudit.runtime.minHits then return 'likely' end
 return 'suspected'
end

local function upsertEvidence(hit)
 if not Config.MLOCollisionAudit.runtime.enabled then return nil end
 if type(hit)~='table' or not hit.x or not hit.y or not hit.z then return nil end
 local now=os.time()
 local bestId,bestDist
 for id,e in pairs(TrafficMLOEvidence) do
  local d=distance(hit,e)
  if d<=Config.MLOCollisionAudit.runtime.mergeRadius and (not bestDist or d<bestDist) then bestId,bestDist=id,d end
 end
 if not bestId then
  local count=0;for _ in pairs(TrafficMLOEvidence) do count=count+1 end
  if count>=Config.MLOCollisionAudit.runtime.maxEvidence then
   local oldestId,oldest
   for id,e in pairs(TrafficMLOEvidence) do if not oldest or (e.lastSeen or 0)<oldest then oldestId,oldest=id,e.lastSeen or 0 end end
   if oldestId then TrafficMLOEvidence[oldestId]=nil end
  end
  bestId=('mlo_%s_%s'):format(now,math.random(1000,9999))
  TrafficMLOEvidence[bestId]={id=bestId,x=hit.x,y=hit.y,z=hit.z,hits=0,firstSeen=now,lastSeen=now,resources={},models={},reasons={},confidence=0,state='suspected',ignored=false}
 end
 local e=TrafficMLOEvidence[bestId]
 e.hits=(e.hits or 0)+1;e.lastSeen=now;e.lastEntityModel=tonumber(hit.entityModel) or 0
 local reason=tostring(hit.reason or 'runtime_collision'):sub(1,40);e.reasons[reason]=(e.reasons[reason] or 0)+1
 local h=tonumber(hit.entityModel) or 0
 if h~=0 then
  e.models[tostring(h)]=true
  for _,candidate in ipairs(TrafficMLOAudit.modelIndex[h] or {}) do
   e.resources[candidate.resource]=e.resources[candidate.resource] or {resource=candidate.resource,files={},score=0}
   local r=e.resources[candidate.resource]
   r.score=(r.score or 0)+1
   if #r.files<8 then r.files[#r.files+1]=candidate.path end
  end
 end
 local candidates=0;for _ in pairs(e.resources) do candidates=candidates+1 end
 e.confidence=math.min(100,(e.hits or 0)*10+math.min(40,candidates*20))
 e.state=evidenceState(e)
 return e
end

function TrafficMLOAudit.recordRuntimeHit(hit)
 local e=upsertEvidence(hit)
 if e then
  TrafficPersistence_save()
  return e
 end
end

function TrafficMLOAudit.prepareFix(id)
 local e=TrafficMLOEvidence[id]
 if not e or not Config.MLOCollisionAudit.fix.enabled then return nil end
 local resources={}
 for name in pairs(e.resources or {}) do resources[#resources+1]=name end
 table.sort(resources)
 return {id=id,mode=Config.MLOCollisionAudit.fix.dryRun and 'dry_run' or 'manual_confirmation',
  backup=Config.MLOCollisionAudit.fix.backup,rollback=Config.MLOCollisionAudit.fix.rollback,
  resources=resources,recommended='Review suspected map resources and disable only the conflicting resource; Traffic Director will not delete or rewrite original map files.',
  createdAt=os.time()}
end

function TrafficMLOAudit.scan()
 if not Config.MLOCollisionAudit.enabled then return {enabled=false} end
 local byFingerprint,resources={},{}
 TrafficMLOAudit.modelIndex={}
 local files,resourceCount=0,0
 for i=0,GetNumResources()-1 do
  if resourceCount>=Config.MLOCollisionAudit.maxResources then break end
  local res=GetResourceByFindIndex(i)
  local state=res and GetResourceState(res)
  if res and state and state~='missing' and not resourceIgnored(res) then
   local list=scanResource(res)
   if #list>0 then
    resourceCount=resourceCount+1;resources[res]={name=res,state=state,files=#list}
    for _,f in ipairs(list) do
     files=files+1
     byFingerprint[f.fingerprint]=byFingerprint[f.fingerprint] or {}
     table.insert(byFingerprint[f.fingerprint],f)
     addModelIndex(f)
    end
   end
  end
 end
 local findings={}
 for fp,list in pairs(byFingerprint) do
  local resourceSet={}
  for _,f in ipairs(list) do resourceSet[f.resource]=true end
  local count=0;for _ in pairs(resourceSet) do count=count+1 end
  if count>1 then
   local key='dup_'..fp
   if not TrafficMLOAudit.ignored[key] then
    findings[#findings+1]={key=key,type='duplicate_collision_asset',severity='high',fingerprint=fp,size=list[1].size,files=list,resources=resourceSet,resourceCount=count,message='Identical map/collision asset content is present in multiple resources.'}
   end
  end
  if #findings>=Config.MLOCollisionAudit.maxFindings then break end
 end
 table.sort(findings,function(a,b) return (a.size or 0)>(b.size or 0) end)
 local evidence={}
 for id,e in pairs(TrafficMLOEvidence or {}) do
  e.state=evidenceState(e)
  evidence[#evidence+1]=e
 end
 table.sort(evidence,function(a,b) return (a.confidence or 0)>(b.confidence or 0) end)
 local report={enabled=true,scannedAt=os.time(),resources=resources,resourceCount=resourceCount,fileCount=files,
  findings=findings,findingCount=#findings,evidence=evidence,evidenceCount=#evidence,
  capability={duplicateAssets=true,runtimeCorrelation=true,spatialGeometry=false,automaticDestructiveFix=false}}
 TrafficMLOAudit.last=report
 return report
end

RegisterNetEvent('traffic:server:mloScan',function()
 if not TrafficPermissions.isAdmin(source) then return end
 TriggerClientEvent('traffic:client:mloAudit',source,TrafficMLOAudit.scan())
end)

RegisterNetEvent('traffic:server:mloIgnore',function(key)
 if not TrafficPermissions.isAdmin(source) or type(key)~='string' then return end
 TrafficMLOAudit.ignored[key]=true
 TriggerClientEvent('traffic:client:mloAudit',source,TrafficMLOAudit.scan())
end)

RegisterNetEvent('traffic:server:mloPrepareFix',function(id)
 if not TrafficPermissions.isAdmin(source) or type(id)~='string' then return end
 local plan=TrafficMLOAudit.prepareFix(id)
 if plan then TriggerClientEvent('traffic:client:mloFixPlan',source,plan) end
end)

CreateThread(function()
 if Config.MLOCollisionAudit.enabled and Config.MLOCollisionAudit.runtime.enabled then
  Wait(30000)
  while Config.MLOCollisionAudit.enabled do
   Wait(math.max(3600000,math.floor(Config.MLOCollisionAudit.runtime.confidenceDecayHours*3600000/2)))
   if decayEvidence(os.time()) then TrafficPersistence_save() end
  end
 end
end)
CreateThread(function()
 if Config.MLOCollisionAudit.enabled and Config.MLOCollisionAudit.scanOnStart then
  Wait(5000);TrafficMLOAudit.scan()
 end
 while Config.MLOCollisionAudit.enabled and Config.MLOCollisionAudit.scanInterval>0 do
  Wait(Config.MLOCollisionAudit.scanInterval);TrafficMLOAudit.scan()
 end
end)
