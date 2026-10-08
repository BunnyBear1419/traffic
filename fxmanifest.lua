fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'BunnyBear1419'
description 'Traffic Director - adaptive NPC traffic routing, learned map intelligence, zones, recovery and NPC protection'
version '2.0.0'

shared_scripts {'shared/config.lua','shared/utils.lua'}
client_scripts {
 'client/appearance.lua','client/ownership.lua','client/adjustor.lua',
 'client/detection.lua','client/zones.lua',
 'client/learning.lua','client/intelligence.lua',
 'client/ui.lua'
}
server_scripts {'server/persistence.lua','server/permissions.lua','server/settings.lua','server/routes.lua','server/mlo_audit.lua','server/main.lua'}
ui_page 'web/index.html'
files {'web/index.html','web/style.css','web/app.js'}
escrow_ignore {'shared/config.lua'}
