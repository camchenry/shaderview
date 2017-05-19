file = require 'src.file'
hotswap = require 'src.hotswap'
require 'src.config'

config = {}
config_reload()

shaders = {}

local function shader_load(path)
    local basename = file.get_basename(path)
    local filename = file.remove_extension(basename)
    if not love.filesystem.isFile(path) then
        error('Path is not a file: "' .. path .. '"')
    end
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
        hotswap.hook(path, function(path)
            shader_load(path)
        end)
    end

    hotswap.hook('config/default.lua', config_reload)
    hotswap.hook('config/user.lua', config_reload)

    app_handlers['load']()
end

function love.update(dt)
    app_handlers['update'](dt)

    hotswap.update(dt)
end

function love.draw()
    love.graphics.setCanvas(canvas)
    app_handlers['draw']()
    love.graphics.setCanvas()

    love.graphics.draw(canvas, 0, 0)
end
