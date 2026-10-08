# Traffic Director

Advanced FiveM NPC traffic intelligence and custom-map self-healing resource.

## What it does

Traffic Director combines learned routing, obstacle intelligence, NPC protection and an admin control center. It is designed to improve NPC behavior around custom maps/MLOs without requiring an administrator to manually map the whole city.

### Traffic intelligence
- Learned routes with admin/ACE Teach Route mode.
- Automatic successful-route discovery and confidence scoring.
- Route scoring using distance, failures, successes, confidence and learned hotspot risk.
- Adaptive hotspot avoidance.
- Smart intersection congestion detection and gridlock release.
- Emergency-class vehicle priority.
- Traffic modes: normal, light, heavy, stop, emergency and race.
- Traffic zones: normal, light, heavy, stop, one-way, closure, emergency and race.
- Performance-adaptive scanning based on population load.

### Custom-map / MLO intelligence
- Repeated NPC stalls become persistent hotspots.
- Hotspots are clustered instead of creating endless duplicate records.
- Hotspots can be classified as building entrances, garages, tunnels, parking areas, dead ends, blocked roads or unknown.
- Route confidence falls after repeated failures and rises after successful discovery.
- The system progressively learns safer alternatives from actual NPC behavior.

### OneSync / networking
- Ownership-aware vehicle tasking.
- Control requests are throttled and retried instead of fighting entity migration.
- Network state bags are used for managed NPC spawn-point identity.
- Shared NPC spawning uses a single elected controller to avoid duplicate networked peds.

### NPC protection
- Managed NPC Appearance Guard for walking/drug-sale/custom-clothing NPCs.
- Invisible/alpha detection.
- Component/prop verification.
- Automatic repair with retry/backoff and repair-attempt limits.
- Optional source-resource repair callback.
- NPC spawn/respawn manager with distance-based lifecycle controls.
- Health telemetry for managed NPCs.

### Admin control center
- Live route, zone and hotspot counts.
- Route confidence/success/failure display.
- Live traffic intelligence heatmap.
- NPC health and appearance-repair telemetry.
- Route point editor.
- Zone creation at the admin's current position.
- Hotspot classification and cleanup.
- Responsive, advanced but simple NUI.

### Persistence and safety
- Persistent routes, zones and obstacle data.
- Automatic .bak.json snapshots before writes.
- Corrupt JSON quarantine and backup recovery.
- Server-side route/zone/obstacle validation.
- Rate limiting for telemetry and discovery events.
- ACE permissions for administration and Teach Route.
- GitHub CI validation for Lua, JSON, JavaScript and required module references.

## Commands

- /traffic — open the admin control panel.
- /trafficteach — toggle Teach Route when the player has traffic.learn.
- /trafficnpcdebug — print managed NPC appearance diagnostics.

## ACE

~~~cfg
add_ace group.admin traffic.admin allow
add_ace group.admin traffic.learn allow
~~~

## Managed NPC integration

A drug-sale or other NPC resource can register a custom-clothed ped:

~~~lua
exports['traffic']:RegisterManagedNPC(ped, {
    type = 'drug_customer',
    appearance = {
        components = {
            {component = 3, drawable = 2, texture = 0, palette = 0},
            {component = 11, drawable = 15, texture = 0, palette = 0}
        },
        props = {
            {prop = 0, drawable = 5, texture = 0}
        }
    }
})
~~~

If the source resource already owns its clothing logic, it can provide a local repair callback:

~~~lua
exports['traffic']:RegisterManagedNPC(ped, {
    type = 'drug_customer',
    repair = function(target)
        -- Re-run the source resource's normal appearance setup here.
    end
})
~~~

Remove a managed NPC when the source resource is done:

~~~lua
exports['traffic']:UnregisterManagedNPC(ped)
~~~

The appearance guard never registers player peds and does not attempt to repair every ambient pedestrian.

## NPC spawn manager integration

A resource that owns custom NPCs can register a controlled spawn point:

~~~lua
exports['traffic']:RegisterNPCSpawnPoint({
    model = joaat('a_m_m_business_01'),
    coords = vector3(100.0, 100.0, 30.0),
    heading = 90.0,
    type = 'drug_customer',
    scenario = 'WORLD_HUMAN_STAND_IMPATIENT'
})
~~~

The manager elects one active client controller and uses a state bag to keep spawn-point identity across ownership migration.

## Persistence

Runtime data is stored in:
- data/routes.json
- data/zones.json
- data/obstacles.json

Backup snapshots are written beside them as .bak.json files. Corrupt files are quarantined with a timestamped .corrupt.*.json file before backup recovery is attempted.

## Important limitation

FiveM/GTA V does not expose a universal reliable MLO flag. Traffic Director therefore learns collision/navigation problem areas from actual NPC behavior instead of claiming perfect MLO detection.

Likewise, custom clothing resources differ in how they stream and apply appearance data. Traffic Director can automatically repair registered NPCs, but the strongest repair path is to register the source resource's normal appearance callback.

## Production testing

GitHub CI validates source syntax and repository data. Actual FiveM runtime testing is still required on the target server for custom map assets, OneSync/entity ownership, NPC clothing resources, population interactions and other resource behavior.
