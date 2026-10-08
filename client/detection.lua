TrafficDetection={}

function TrafficDetection.forwardBlocked(vehicle)
 if not Traffic.nativeSafetyEnabled('shapeTests') then return false,nil,0 end
 if not vehicle or not DoesEntityExist(vehicle) or not IsEntityAVehicle(vehicle) then return false,nil,0 end
 local p=GetEntityCoords(vehicle)
 local f=GetEntityForwardVector(vehicle)
 local a=vector3(p.x,p.y,p.z+0.65)
 local b=vector3(p.x+f.x*Config.ObstacleProbeDistance,p.y+f.y*Config.ObstacleProbeDistance,p.z+0.65)
 Traffic.nativeProbe('Detection','StartShapeTestRay',true)
 local ray=StartShapeTestRay(a.x,a.y,a.z,b.x,b.y,b.z,1,vehicle,7)
 Traffic.nativeProbe('Detection','GetShapeTestResult',true)
 local _,hit,hitCoords,_,entity=GetShapeTestResult(ray)
 if hit~=1 or not hitCoords then return false,nil,entity or 0 end
 return true,hitCoords,entity or 0
end

function TrafficDetection.sampleObstacle(vehicle)
 local blocked,hitCoords,entity=TrafficDetection.forwardBlocked(vehicle)
 if not blocked then return nil end
 local p=GetEntityCoords(vehicle)
 local entityId=entity or 0
 local netId=0
 local model=0
 local entityType=0
 if entityId~=0 and DoesEntityExist(entityId) then
  netId=NetworkGetNetworkIdFromEntity(entityId) or 0
  model=GetEntityModel(entityId) or 0
  entityType=GetEntityType(entityId) or 0
 end
 return {x=hitCoords.x,y=hitCoords.y,z=hitCoords.z,vehicleX=p.x,vehicleY=p.y,vehicleZ=p.z,
  heading=GetEntityHeading(vehicle),entity=entityId,netId=netId,entityModel=model,entityType=entityType}
end

function TrafficDetection.findRoadPoint(coords,heading)
 if not Traffic.nativeSafetyEnabled('roadNodes') then return nil end
 Traffic.nativeProbe('Detection','GetClosestVehicleNodeWithHeading',true)
 local ok,node=GetClosestVehicleNodeWithHeading(coords.x,coords.y,coords.z,heading or 0.0,1,3.0,0)
 if ok then return node end
 Traffic.nativeProbe('Detection','GetClosestVehicleNode',true)
 local ok2,node2=GetClosestVehicleNode(coords.x,coords.y,coords.z,1,3.0,0)
 if ok2 then return node2 end
end
