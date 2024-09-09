fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Buller'
description 'Jobgarage for ESX'
dependencies { 'ox_lib', 'es_extended', 'oxmysql' }

client_script 'client/*'
server_script 'server/*'
shared_scripts { '@ox_lib/init.lua', 'config.lua' }

ui_page 'web/index.html'
files { 'web/index.html', 'web/index.js', 'web/index.css' }