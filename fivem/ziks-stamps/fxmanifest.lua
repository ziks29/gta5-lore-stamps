fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'ziks-stamps'
author 'ziks (github.com/ziks29)'
description 'GTA V Lore Stamps: lore-friendly document stamps for NUI, with random wear and live fields (MIT)'
version '1.3.0'
repository 'https://github.com/ziks29/gta5-lore-stamps'

shared_script 'config.lua'
client_script 'client.lua'
server_script 'server.lua'

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/app.js',
    'html/stamp-wear.js',
    'html/stamps.json',
    'html/svg/*.svg',
    'html/svg/status/*.svg',
    'html/svg/mini/*.svg',
}
