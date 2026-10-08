fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'BunnyBear1419'
description 'Traffic Director - adaptive NPC traffic routing, route learning, zones and recovery'
version '1.0.0'

shared_scripts {'shared/config.lua','shared/utils.lua'}
client_scripts {'client/appearance.lua','client/population.lua','client/traffic.lua','client/detection.lua','client/routing.lua','client/recovery.lua','client/zones.lua','client/learning.lua','client/ui.lua'}
server_scripts {'server/persistence.lua','server/permissions.lua','server/routes.lua','server/main.lua'}
ui_page 'web/index.html'
files {'web/index.html','web/style.css','web/app.js'}
escrow_ignore {'shared/config.lua'}
