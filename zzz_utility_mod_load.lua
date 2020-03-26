local filepath = require "util/filepath"
do
    for k, filepath in ipairs( filepath.list_files( "scripts/content/mods/", "mod_main.lua", true )) do
        local name = filepath:match( "scripts/(.+)[.]lua$" )
        require ( name )
    end
end