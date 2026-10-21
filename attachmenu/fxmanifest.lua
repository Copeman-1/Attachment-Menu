fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'attachmenu'
description 'Weapon attachment menu for qb-core + ox_inventory'
version '1.0.0'
author 'Copeman'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
}

client_script 'client.lua'
server_script 'server.lua'

dependencies {
    'ox_lib',
    'ox_inventory',
    'qb-core',
}
