fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'ptech_botanica_tobacco'
author 'P-Tech Botanica'
description 'Botanica tobacco items and smoking effects'
version '0.1.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
}

client_script 'client/main.lua'
server_script 'server/main.lua'

dependencies {
    'ox_lib',
    'ox_inventory',
    'qbx_core',
    'nova-stress',
}
