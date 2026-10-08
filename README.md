# Traffic Director

Advanced FiveM NPC traffic management and adaptive routing resource.

## Features
- NPC vehicle traffic control without taking control of player-driven vehicles.
- Learned routes with admin/ACE Teach Route mode.
- Adaptive obstacle hotspot learning from repeated NPC failures.
- Learned hotspot avoidance during route execution.
- Automatic stuck recovery and road-node fallback.
- Traffic modes: normal, light, heavy, stop, emergency and race.
- Traffic zones: normal, light, heavy, stop, one-way, closure, emergency and race.
- Emergency-class vehicles are protected from restrictive zone controls.
- Admin NUI with route editing, hotspot management, live NPC appearance diagnostics and zone creation at the admin's position.
- Persistent routes, zones and obstacle data.
- Managed NPC Appearance Guard for walking/drug-sale NPCs.
- Custom clothing component/prop restoration and invisible NPC repair.
- Export API for external NPC/drug resources.
- ACE permissions and server-side validation.
- GitHub CI validation for Lua, JSON and NUI JavaScript syntax.

## Commands
- `/traffic` — open the admin control panel.
- `/trafficteach` — toggle Teach Route when the player has `traffic.learn`.
- `/trafficnpcdebug` — print managed NPC and appearance-repair diagnostics.

## ACE
Add permissions in your server configuration:
```cfg
add_ace group.admin traffic.admin allow
add_ace group.admin traffic.learn allow
```

## Managed NPC integration
A drug-sale or other NPC resource can register a custom-clothed ped:

```lua
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
```

If the source resource already owns its clothing logic, it can provide a local repair callback:

```lua
exports['traffic']:RegisterManagedNPC(ped, {
    type = 'drug_customer',
    repair = function(target)
        -- Re-run the source resource's normal appearance setup here.
    end
})
```

Remove a managed NPC when the source resource is done with it:

```lua
exports['traffic']:UnregisterManagedNPC(ped)
```

The appearance guard never registers player peds and does not attempt to repair every ambient pedestrian.

## Persistence
Runtime data is stored in:
- `data/routes.json`
- `data/zones.json`
- `data/obstacles.json`

## Important limitation
FiveM/GTA V does not expose a universal reliable MLO flag. Traffic Director therefore learns collision/navigation problem areas from actual NPC behavior instead of pretending every custom building can be detected perfectly.

## Production testing
The GitHub workflow validates source syntax and data files. Actual FiveM runtime testing is still required on the target server for custom map assets, NPC clothing resources, OneSync behavior and resource interactions.
