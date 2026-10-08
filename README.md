# Traffic Director

Advanced **FiveM / GTA V traffic, NPC, route, population and server-control resource** for server owners who want deep control over ambient traffic and NPC behavior without manually scripting every road.

> **Status:** Release Candidate / server-owner testing
> **Version:** 2.0.0


## Police / FIB field deployment

Admins can enable **Deploy/remove road props** in **Traffic Director → Jobs & Access** for the Police, FIB, Sheriff, or a custom job rule. Save the rule after checking the capability. Job names must match the names used by the configured ESX/QBCore adapter. Server admins can always deploy props.

In game, use:
- `/trafficprop cone` — place a road cone in front of you
- `/trafficprop barrier` — place a road barrier
- `/trafficprop police_barrier` — place a police-style barrier
- `/trafficprop spikes` — deploy a spike strip
- `/trafficprop flare` — place a flare
- `/trafficprop remove` — remove the nearest Traffic Director prop

Props are networked, server-authorized, and capped per player and globally. Spike strips puncture tires when a moving vehicle gets close enough. Props deployed by a player are cleaned up when that player disconnects or when the resource stops. This feature requires OneSync/server entity creation support and should be tested with the server's current artifact and framework before public release.

## What Traffic Director does

Traffic Director manages and intelligently adjusts the ambient GTA V world around players.

### Traffic control
- Live traffic density: 0-100%
- Live NPC density: 0-100%
- Parked-vehicle density
- Normal, Light, Heavy, Stop, Emergency and Race modes
- Automatic/adaptive traffic
- Performance-aware task scaling
- Emergency and military vehicle controls
- Custom emergency/military model lists
- Protected player and mission vehicles
- Bounded ambient cleanup when density is intentionally reduced

A 0% traffic/NPC setting is an actual population-control setting, not only a UI value.

### Smart Traffic
Traffic can adapt to:
- Time of day
- Rush hour
- Late night
- Traffic zones
- Active events
- Police/FIB/Sheriff job authority
- Server/player load

### Admin Control Center
Open it with:
~~~text
/traffic
~~~

The Control Center includes:
- Live traffic/NPC/parked controls
- Presets
- Traffic modes
- Traffic events
- Job traffic authority
- Vehicle policies
- Protected models
- Traffic zones
- Teach Route
- Route editor
- Learned hotspots
- MLO/collision intelligence
- NPC health/appearance telemetry
- Diagnostics
- Configuration export/import
- Master safety switch

## Emergency and military traffic

Administrators can independently control police, sheriff, FIB, ambulance, fire, riot/emergency and military vehicles.

Player-driven and mission vehicles are protected by the cleanup safety layer.

## Traffic Events

Built-in events:
- Road Construction
- Police Checkpoint
- Major Accident
- Emergency Response
- Fire Scene
- Traffic Jam
- Race Event
- Military Convoy
- Police Pursuit

Events have controlled durations and automatically expire.

## Job Traffic Authority

Optional ESX/QBCore integration supports:
- Police
- FIB
- Sheriff
- Custom jobs

Rules can control traffic, NPCs, parked vehicles, emergency vehicles, military vehicles, events and zones.

Rules support minimum grade, priority and on-duty behavior.

## Traffic Zones

Supported zone types:
- Normal
- Light
- Heavy
- Stop
- One-way
- Closure
- Emergency
- Race

Useful for downtown areas, highways, race tracks, construction sites, police scenes and custom maps.

## Teach Route and route intelligence

Use:
~~~text
/trafficteach
~~~

Traffic Director can learn routes, track successes/failures, build confidence, record avoidance hotspots and discover safer alternatives from actual NPC behavior.

## Custom-map / MLO intelligence

The resource can correlate repeated NPC stalls, route failures, runtime collision evidence and duplicate map/collision assets.

Possible classifications include building entrance, garage, tunnel, parking, dead end, blocked road and unknown.

It does **not** automatically rewrite or delete original MLO files. Fix planning is review-first because FiveM does not expose a universal Lua API for perfect MLO geometry/resource ownership detection.

## NPC protection

Managed-NPC protection includes:
- Invisible NPC detection
- Appearance/component verification
- Prop verification
- Repair retry/backoff
- Health telemetry
- Managed NPC registration
- Optional source-resource repair callbacks
- NPC spawn-point management

Example:
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

Remove it with:
~~~lua
exports['traffic']:UnregisterManagedNPC(ped)
~~~

## OneSync / networking

Traffic Director is designed around FiveM's OneSync/entity ownership model and uses ownership-aware behavior for controlled network entities.

OneSync is strongly recommended for production servers. FiveM documents OneSync as its state-awareness/entity-synchronization system. citeturn0search2turn0search10

## Release Safety

### Master safety switch
The Control Center can disable Traffic Director's live traffic/population control while leaving the resource installed. This is useful when troubleshooting another population resource or preparing maintenance.

### First-run setup
The Control Center tracks whether initial configuration has been completed.

### Diagnostics
Diagnostics can report:
- Resource state
- Framework
- OneSync mode
- Population setting
- Player count
- Traffic/NPC/parked levels
- Traffic/NPC scales
- Task budget
- Master switch state
- Active event
- Job-rule count
- Client runtime state

### Configuration backup
Export a known-good configuration before major changes. Imports create a pre-import settings backup before replacing the active configuration.

## Permissions / ACE

Master administrator:
~~~cfg
add_ace group.admin traffic.admin allow
add_ace group.admin traffic.learn allow
~~~

Granular permissions:
~~~cfg
add_ace group.trafficmanager traffic.control allow
add_ace group.trafficevents traffic.events allow
add_ace group.trafficjobs traffic.jobs allow
add_ace group.trafficvehicles traffic.vehicles allow
add_ace group.trafficzones traffic.zones allow
add_ace group.trafficroutes traffic.routes allow
add_ace group.trafficdiagnostics traffic.diagnostics allow
~~~

This lets owners separate traffic managers, event staff, job administrators, map staff and diagnostics access.

## Installation

### 1. Download the resource

Place the resource in the server's resources directory. A recommended layout is:

~~~text
resources/
└── [local]/
    └── traffic/
        ├── fxmanifest.lua
        ├── shared/
        ├── client/
        ├── server/
        ├── web/
        └── data/
~~~

Every FiveM resource needs an fxmanifest.lua that declares its scripts/files. citeturn0search0turn0search1

### 2. Start it

Add to server.cfg:
~~~cfg
ensure traffic
~~~

### 3. Add administrator access

Example:
~~~cfg
add_ace group.admin traffic.admin allow
add_ace group.admin traffic.learn allow
add_principal identifier.license:YOUR_LICENSE_HERE group.admin
~~~

Replace the example license identifier with your real server administrator identifier.

### 4. Refresh/restart

For a running development server:
~~~text
refresh
ensure traffic
~~~

FiveM loads resources from the resources directory and starts them using the resource name. citeturn0search1turn0search3

### 5. Open the Control Center

Join as an administrator and run:
~~~text
/traffic
~~~

### 6. Complete first-run setup

Recommended order:
1. Confirm Master Switch is enabled.
2. Review traffic/NPC/parked levels.
3. Review emergency/military settings.
4. Configure job authority if needed.
5. Run Diagnostics.
6. Click Finish First-Run Setup.
7. Test gameplay before giving staff access.

## Framework configuration

Standalone is the default:
~~~lua
Config.Framework = 'standalone'
~~~

ESX:
~~~lua
Config.Framework = 'esx'
~~~

QBCore:
~~~lua
Config.Framework = 'qbcore'
~~~

Optional automatic framework detection:
~~~lua
Config.FrameworkAdapters = {
    enabled = true,
    esx = true,
    qbcore = true
}
~~~

Framework support is optional; core traffic, routing, NPC management, persistence, NUI and ACE features do not require ESX/QBCore.

## Recommended OneSync configuration

For production, enable OneSync in server.cfg:
~~~cfg
set onesync on
~~~

FiveM documents OneSync as the state-awareness system for server-side entity synchronization and ownership. citeturn0search2turn0search10

## Persistent data

Traffic Director stores persistent data in:
~~~text
data/
~~~

Important files include:
~~~text
data/settings.json
data/routes.json
data/zones.json
data/obstacles.json
~~~

Backup/recovery files may also be created automatically.

## Commands

| Command | Purpose | Permission |
|---|---|---|
| /traffic | Open Control Center | traffic.admin |
| /trafficteach | Start/stop Teach Route | traffic.learn |
| /trafficnpcdebug | NPC appearance diagnostics | traffic.admin |

## Built-in presets

- Minimal
- City
- Rush Hour
- Military Zone
- Late Night
- Apocalypse
- Performance Safe
- Normal Traffic
- Busy City
- Heavy Traffic
- NPC Heavy
- Race / Event
- Emergency Response
- Traffic Director Disabled

Custom presets can also be created.

## Troubleshooting

### Resource does not start
Check:
~~~text
ensure traffic
~~~
Then inspect the server console for Lua errors and verify traffic/fxmanifest.lua exists.

### UI does not open
Verify:
- traffic.admin ACE is granted
- resource is running
- web/index.html exists
- web/app.js has no NUI runtime error

### Sliders do not appear to affect gameplay
Check:
1. Master Switch is enabled.
2. Traffic Director is running.
3. Another resource is not overriding GTA population natives.
4. Test Normal and Stop modes.
5. Run Diagnostics.
6. Temporarily stop other traffic/population controllers.

### Job authority does not activate
Check framework setting, job name, grade, duty state, rule priority and framework startup order.

### Custom MLO still causes NPC problems
Use Teach Route, obstacle learning and MLO Collision Lab. Runtime evidence is not the same as guaranteed proof of bad geometry.

## Compatibility

Traffic Director is standalone-first and does not require a database or paid framework.

Multiple resources that manipulate vehicle density, ped density, parked vehicles, population budgets or ambient suppression can override one another. Test overlapping population resources separately.

Use the Master Safety Switch to isolate Traffic Director while troubleshooting.

## Production testing checklist

- [ ] Resource starts cleanly
- [ ] /traffic opens
- [ ] Admin ACE works
- [ ] Non-admin cannot use admin functions
- [ ] Traffic 0% works
- [ ] NPC 0% works
- [ ] Parked 0% works
- [ ] Emergency toggle works
- [ ] Military toggle works
- [ ] Protected vehicles remain protected
- [ ] Master safety switch works
- [ ] Diagnostics works
- [ ] Export works
- [ ] Import creates a backup
- [ ] Teach Route works
- [ ] Routes save/edit/delete correctly
- [ ] Zones work
- [ ] Events start and expire
- [ ] ESX/QBCore job authority works if enabled
- [ ] OneSync behavior is verified
- [ ] Custom maps/MLOs are tested
- [ ] Other population resources have been checked
- [ ] GitHub Actions validation is green

## CI / development

GitHub Actions validates:
- Lua syntax
- JSON
- NUI JavaScript syntax
- Required NUI elements
- Manifest/module references

CI cannot replace actual FiveM gameplay testing. Entity ownership, OneSync, framework jobs, map assets and other server resources must be tested on the target server.

## Limitations

FiveM/GTA V does not provide a universal Lua API for perfect MLO geometry ownership and spatial overlap detection. Traffic Director therefore treats MLO findings and runtime route failures as evidence rather than absolute proof.

Custom clothing systems also differ between resources. The strongest appearance repair path is to register the source resource's normal appearance callback.

## Credits

Built by **BunnyBear1419**.

Traffic Director is an independent FiveM resource and is not affiliated with Cfx.re, Rockstar Games, or third-party frameworks/resources mentioned in this README.
