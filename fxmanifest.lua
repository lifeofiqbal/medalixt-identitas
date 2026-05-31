fx_version 'cerulean'
game 'gta5'
author 'MEDALIXT'
description 'Sistem Identitas QBOX'
version '1.0'

shared_scripts {
    'config.lua'
}

dependencies {
    'ox_lib',
    'ox_inventory'
}

server_scripts {
    'server.lua'
}

client_scripts {
    '@ox_lib/init.lua',
    'client.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js',
    'html/img/*.png'
}