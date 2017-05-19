require 'src.config'
require 'src.file'

config = {}
config_reload()

-- @Global
shaders = {}

local function shader_load(path)
    local basename = file_get_basename(path)
    local filename = file_remove_extension(basename)
    shaders[filename] = love.graphics.newShader(path)
end

require 'app.main'

local app_handlers = {
    load   = love.load,
    update = love.update,
    draw   = love.draw,
}

for k, v in pairs(love.handlers) do
    app_handlers[k] = v
end

local canvas = love.graphics.newCanvas()

function love.load()
    if not love.filesystem.exists(config.shader_directory) then
        error('Shader directory "' .. config.shader_directory .. '" does not exist.')
    end

    local files = love.filesystem.getDirectoryItems(config.shader_directory)
    for i, file in ipairs(files) do
        local path = config.shader_directory .. '/' .. file
        shader_load(path)
        file_hook_on_change(path, function(path)
            shader_load(path)
        end)
    end

    file_hook_on_change('config/default.lua', config_reload)
    file_hook_on_change('config/user.lua', config_reload)

    app_handlers['load']()
end

function love.update(dt)
    app_handlers['update'](dt)

    file_hook_check_changes(dt)
end

function love.draw()
    love.graphics.setCanvas(canvas)
    app_handlers['draw']()
    love.graphics.setCanvas()

    love.graphics.draw(canvas, 0, 0)
end
