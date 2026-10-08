TrafficPermissions = {}
function TrafficPermissions.isAdmin(src) return src==0 or IsPlayerAceAllowed(src,Config.AdminAce) end
function TrafficPermissions.can(src,capability)
 if TrafficPermissions.isAdmin(src) then return true end
 local ace=(Config.PermissionAces or {})[capability]
 return ace and IsPlayerAceAllowed(src,ace) or false
end
function TrafficPermissions.canLearn(src) return TrafficPermissions.isAdmin(src) or IsPlayerAceAllowed(src,Config.LearnAce) end
function TrafficPermissions.canControl(src) return TrafficPermissions.can(src,'control') end
function TrafficPermissions.canEvents(src) return TrafficPermissions.can(src,'events') end
function TrafficPermissions.canJobs(src) return TrafficPermissions.can(src,'jobs') end
function TrafficPermissions.canVehicles(src) return TrafficPermissions.can(src,'vehicles') end
function TrafficPermissions.canZones(src) return TrafficPermissions.can(src,'zones') end
function TrafficPermissions.canRoutes(src) return TrafficPermissions.can(src,'routes') end
function TrafficPermissions.canDiagnostics(src) return TrafficPermissions.can(src,'diagnostics') end
RegisterCommand('traffic',function(source)
 if not TrafficPermissions.isAdmin(source) then TriggerClientEvent('chat:addMessage',source,{args={'Traffic Director','No permission.'}}) return end
 TriggerClientEvent('traffic:client:open',source)
end,false)
RegisterCommand('trafficteach',function(source)
 if not TrafficPermissions.canLearn(source) then TriggerClientEvent('chat:addMessage',source,{args={'Traffic Director','No permission.'}}) return end
 TriggerClientEvent('traffic:client:toggleLearning',source)
end,false)
RegisterCommand('trafficnpcdebug',function(source)
 if not TrafficPermissions.isAdmin(source) then TriggerClientEvent('chat:addMessage',source,{args={'Traffic Director','No permission.'}}) return end
 TriggerClientEvent('traffic:appearance:debug',source)
end,false)
