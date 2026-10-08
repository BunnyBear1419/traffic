Traffic = Traffic or {}
function Traffic.distance(a,b) local dx,dy,dz=a.x-b.x,a.y-b.y,a.z-b.z return math.sqrt(dx*dx+dy*dy+dz*dz) end
function Traffic.clamp(v,a,b) return math.max(a,math.min(b,v)) end
function Traffic.vec(v) return {x=v.x+0.0,y=v.y+0.0,z=v.z+0.0} end
function Traffic.validPoint(p) return p and p.x and p.y and p.z end

function Traffic.nativeSafetyEnabled(name)
 local safety=Config.NativeSafety or {}
 return safety.enabled~=false and safety[name]~=false
end
function Traffic.nativeProbe(subsystem,operation,enabled)
 local safety=Config.NativeSafety or {}
 if safety.debug then
  print(('[Traffic Director][NativeProbe] subsystem=%s operation=%s enabled=%s'):format(tostring(subsystem),tostring(operation),tostring(enabled~=false)))
 end
 return enabled~=false
end
