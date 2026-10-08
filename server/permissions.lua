TrafficPermissions = {}
function TrafficPermissions.isAdmin(src) return src==0 or IsPlayerAceAllowed(src,Config.AdminAce) end
function TrafficPermissions.canLearn(src) return TrafficPermissions.isAdmin(src) or IsPlayerAceAllowed(src,Config.LearnAce) end
RegisterCommand('traffic',function(source)
 if not TrafficPermissions.isAdmin(source) then TriggerClientEvent('chat:addMessage',source,{args={'Traffic Director','No permission.'}}) return end
 TriggerClientEvent('traffic:client:open',source)
end,false)
RegisterCommand('trafficteach',function(source)
 if not TrafficPermissions.canLearn(source) then TriggerClientEvent('chat:addMessage',source,{args={'Traffic Director','No permission.'}}) return end
 TriggerClientEvent('traffic:client:toggleLearning',source)
end,false)
