fx_version 'cerulean'
game 'gta5'
lua54 'yes'
author 'Merodicoexe (AI v0.dev)'
description 'Community Service Script with Database Support'
version '2.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'shared/config.lua',
    'shared/functions.lua',
    '@es_extended/imports.lua'
}

client_scripts {
    'client/*.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/*.lua',
}

dependencies {
    'oxmysql'
}
