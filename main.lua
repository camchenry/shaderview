file = require 'src.file'
hotswap = require 'src.hotswap'
require 'src.config'

config = {}
config_reload()

error_occurred = false
error_log = {}

shaders = {}
shader_uniforms = {}

local function shader_load(path)
    local basename = file.get_basename(path)
    local filename = file.remove_extension(basename)
    local function errhand(...)
        error_occurred = true
        error_log = {...}
    end
    local ok, shader = xpcall(function()
        return love.graphics.newShader(path)
    end, errhand)
    if ok then
        error_occurred = false
        shaders[filename] = shader
        if not shader_uniforms[filename] then
            shader_uniforms[filename] = {}
        end

        local old_send = getmetatable(shader).send
        getmetatable(shader).send = function(...)
            old_send(...)
            local args = {...}
            local shader = args[1]
            table.remove(args, 1)
            local variable = args[1]
            table.remove(args, 1)
            shader_uniforms[filename][variable] = args
        end

        for k, v in pairs(shader_uniforms[filename]) do
            shader:send(k, unpack(v))
        end
    end
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
    love.graphics.setBlendMode("alpha", "premultiplied")
    app_handlers['draw']()
    love.graphics.setBlendMode("alpha", "alphamultiply")
    love.graphics.setCanvas()

    love.graphics.draw(canvas, 0, 0)

    if error_occurred then
        love.graphics.setColor(0, 0, 0, 127)
        love.graphics.rectangle('fill', 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
        love.graphics.setColor(255, 255, 255)
        love.graphics.print('Error', 70, 70)
        local line_height = love.graphics.getFont():getHeight()
        local i = 2
        for k, v in pairs(error_log) do
            love.graphics.print(k .. ' ' .. v, 70, 70 + i * line_height)
            i = i + 1
        end
    end
end
