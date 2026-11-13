fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'NOVA'
description 'Gestao de empregos e fechaduras para ESX Legacy'
version '1.0.2'

ui_page 'html/index.html'

shared_scripts {
    '@es_extended/imports.lua',
    'config.lua'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua'
}

files {
    'html/index.html',
    'html/style.css',
    'html/app.js'
}

dependencies {
    'es_extended',
    'oxmysql'
}
