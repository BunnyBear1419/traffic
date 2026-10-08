TrafficMLOAudit={last=nil,ignored={}}
local collisionExt=Config.MLOCollisionAudit.includeExtensions
local function ext(path) local e=path:match('%.([^%.%/]+)$');return e and e:lower() or nil end
local function fingerprint(raw)
 local h=2166136261
 for i=1,#raw do h=((h ~ raw:byte(i))*16777619)%4294967296 end
 return ('%08x:%d'):format(h,#raw)
end
local function addFile(files,resource,path,kind)
 if #files>=Config.MLOCollisionAudit.maxFilesPerResource then return end
 local e=ext(path);if not e or not collisionExt[e] then return end
 local raw=LoadResourceFile(resource,path)
 if not raw or #raw<Config.MLOCollisionAudit.minimumDuplicateSize then return end
 files[#files+1]={resource=resource,path=path,ext=e,size=#raw,fingerprint=fingerprint(raw),kind=kind}
end
local function scanResource(resource)
 local files={}
 local n=GetNumResourceMetadata(resource,'files') or 0
 for i=0,n-1 do addFile(files,resource,GetResourceMetadata(resource,'files',i) or '','manifest') end
 local d=GetNumResourceMetadata(resource,'data_file') or 0
 for i=0,d-1 do
  local value=GetResourceMetadata(resource,'data_file',i) or ''
  for path in value:gmatch("['\"]([^'\"]+%.%w+)['\"]") do addFile(files,resource,path,'data_file') end
 end
 return files
end
local function resourceIgnored(resource)
 for _,r in ipairs(Config.MLOCollisionAudit.ignoreResources or {}) do if r==resource then return true end end
 return false
end
function TrafficMLOAudit.scan()
 if not Config.MLOCollisionAudit.enabled then return {enabled=false} end
 local byFingerprint,resources={},{}
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
     files=files+1;byFingerprint[f.fingerprint]=byFingerprint[f.fingerprint] or {};table.insert(byFingerprint[f.fingerprint],f)
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
 local report={enabled=true,scannedAt=os.time(),resources=resources,resourceCount=resourceCount,fileCount=files,findings=findings,findingCount=#findings}
 TrafficMLOAudit.last=report;return report
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
CreateThread(function()
 if Config.MLOCollisionAudit.enabled and Config.MLOCollisionAudit.scanOnStart then Wait(5000);TrafficMLOAudit.scan() end
 while Config.MLOCollisionAudit.enabled and Config.MLOCollisionAudit.scanInterval>0 do Wait(Config.MLOCollisionAudit.scanInterval);TrafficMLOAudit.scan() end
end)
