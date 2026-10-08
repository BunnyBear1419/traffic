TrafficDetection={}
function TrafficDetection.forwardBlocked(vehicle)
 local p=GetEntityCoords(vehicle); local f=GetEntityForwardVector(vehicle)
 local a=vector3(p.x,p.y,p.z+0.65); local b=vector3(p.x+f.x*Config.ObstacleProbeDistance,p.y+f.y*Config.ObstacleProbeDistance,p.z+0.65)
 local ray=StartShapeTestRay(a.x,a.y,a.z,b.x,b.y,b.z,1,vehicle,7)
 local _,hit,hitCoords,_,entity=GetShapeTestResult(ray)
 return hit==1,hitCoords,entity
end
function TrafficDetection.findRoadPoint(coords,heading)
 local ok,node=GetClosestVehicleNodeWithHeading(coords.x,coords.y,coords.z,heading or 0.0,1,3.0,0)
 if ok then return node end
 local ok2,node2=GetClosestVehicleNode(coords.x,coords.y,coords.z,1,3.0,0)
 if ok2 then return node2 end
end
