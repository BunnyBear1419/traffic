TrafficDetection={}

-- Native-safe obstacle detection.
-- Deliberately avoids shape tests and road-node natives. A stuck vehicle is
-- treated as evidence of a problem area; repeated reports build confidence.
function TrafficDetection.forwardBlocked(vehicle)
 if not vehicle or not DoesEntityExist(vehicle) or not IsEntityAVehicle(vehicle) then return false,nil,0 end
 return false,nil,0
end

function TrafficDetection.sampleObstacle(vehicle)
 if not vehicle or not DoesEntityExist(vehicle) or not IsEntityAVehicle(vehicle) then return nil end
 local p=GetEntityCoords(vehicle)
 return {x=p.x,y=p.y,z=p.z,vehicleX=p.x,vehicleY=p.y,vehicleZ=p.z,heading=GetEntityHeading(vehicle),entity=0,netId=0,entityModel=GetEntityModel(vehicle),entityType=2}
end

-- Compatibility API. Road-node probing stays disabled because it caused native
-- access violations on this server/build.
function TrafficDetection.findRoadPoint(coords,heading)
 return nil
end
