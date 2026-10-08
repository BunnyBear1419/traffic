TrafficDetection={}

function TrafficDetection.forwardBlocked(vehicle)
 -- Safe fallback: do not use GTA shape-test natives. They are unstable on some
 -- custom maps/builds. Detect roadless/abnormal locations from bounded road-node data.
 if not vehicle or not DoesEntityExist(vehicle) or not IsEntityAVehicle(vehicle) then return false,nil,0 end
 local p=GetEntityCoords(vehicle)
 local heading=GetEntityHeading(vehicle)
 if not Traffic.nativeSafetyEnabled('roadNodes') then return false,nil,0 end
 Traffic.nativeProbe('Detection','GetClosestVehicleNodeWithHeading',true)
 local ok,node=GetClosestVehicleNodeWithHeading(p.x,p.y,p.z,heading or 0.0,1,3.0,0)
 if not ok or not node then
  return true,p,0
 end
 local dx=p.x-node.x
 local dy=p.y-node.y
 local dz=p.z-node.z
 local distance=math.sqrt(dx*dx+dy*dy+dz*dz)
 local threshold=math.max(12.0,tonumber(Config.RouteSnapDistance) or 18.0)
 if distance>threshold then return true,p,0 end
 return false,nil,0
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
