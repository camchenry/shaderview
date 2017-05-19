-- This will modify the config table directly
function config_mixin(t)
    for k, v in pairs(t) do
        if type(v) == "table" then
            mix_into_config(v)
        else
            config[k] = v
        end
    end
end

function config_load(file)
    config_mixin(love.filesystem.load(file)())
end

function config_reload()
    config = {}
    config_load('config/default.lua')
    config_load('config/user.lua')
    print('Config reloaded')
end
