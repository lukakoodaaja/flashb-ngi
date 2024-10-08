fx_version "cerulean"
game "gta5"

author "lukakoodaaja"
version "8.0.0"

data_file "WEAPON_METADATA_FILE" "data/weaponarchetypes.meta"
data_file "WEAPON_ANIMATIONS_FILE" "data/weaponanimations.meta"
data_file "LOADOUTS_FILE" "data/loadouts.meta"
data_file "WEAPONINFO_FILE" "data/weapons.meta"
data_file "PED_PERSONALITY_FILE" "data/pedpersonality.meta"

ui_page "html/index.html"

files {
    "data/loadouts.meta",
    "data/weaponarchetypes.meta",
    "data/weaponanimations.meta",
    "data/pedpersonality.meta",
    "data/weapons.meta",
    "html/*.js",
    "html/index.html",
    "html/*.ogg",
}



client_scripts {
    "config.lua",
    "client.lua"
}

server_scripts { 
    'server.lua',   
    '@mysql-async/lib/MySQL.lua' 
}
