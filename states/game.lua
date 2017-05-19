local function file_get_basename(path)
    return path:gsub("(.*/)(.*)", "%2")
end

local function file_remove_extension(filename)
    return (filename:gsub('%..-$', ''))
end

local config = require 'src.config'
local hotswap = require 'src.hotswap'

local app = require 'app.main'

local error_occurred = false
local error_log = {}

local function shader_load(path)
    local basename = file_get_basename(path)
    local filename = file_remove_extension(basename)
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

local game = {}

function game:init()
    local function config_reload()
        config.data = {}
        config:load('config/default.lua')
        config:load('config/user.lua')
        hotswap:load_config_data(config.data)
        print('Config loaded')
    end

    config_reload()

    if not love.filesystem.exists(config.data.shader_directory) then
        error('Shader directory "' .. config.data.shader_directory .. '" does not exist.')
    end

    local files = love.filesystem.getDirectoryItems(config.data.shader_directory)
    for i, file in ipairs(files) do
        local path = config.data.shader_directory .. '/' .. file
        shader_load(path)
        hotswap:hook(path, function(path)
            shader_load(path)
        end)
    end

    self.canvas = love.graphics.newCanvas()

    hotswap:hook('config/default.lua', config_reload)
    hotswap:hook('config/user.lua', config_reload)

    app:load()
end

function game:enter()

end

function game:update(dt)
    app:update(dt)

    hotswap:update(dt)
end

function game:keypressed(key, code)

end

function game:mousepressed(x, y, mbutton)

end

function game:draw()
    love.graphics.setCanvas(self.canvas)
    love.graphics.setBlendMode("alpha", "premultiplied")
    app:draw()
    love.graphics.setBlendMode("alpha", "alphamultiply")
    love.graphics.setCanvas()

    love.graphics.draw(self.canvas, 0, 0)

    if error_occurred then
        love.graphics.setColor(0, 0, 0, 160)
        love.graphics.rectangle('fill', 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
        love.graphics.setColor(255, 255, 255)
        love.graphics.setFont(Fonts.bold[30])
        local x = 70
        local y = 70
        love.graphics.print('Error', x, y)
        local line_height = love.graphics.getFont():getHeight()
        y = y + line_height
        y = y + 30
        love.graphics.setFont(Fonts.monospace[18])
        local line_height = love.graphics.getFont():getHeight()
        for k, v in pairs(error_log) do
            y = y + line_height
            love.graphics.setColor(0, 0, 0)
            love.graphics.print(k .. ' ' .. v, x + 1, y + 1)
            love.graphics.setColor(255, 255, 255)
            love.graphics.print(k .. ' ' .. v, x, y)
        end
    end
end

return game
