local defaultConfig = require 'config.default'
local userConfig    = require 'config.user'

local config = {}

-- This will modify the config table directly
local function mix_into_config(t)
    for k, v in pairs(t) do
        if type(v) == "table" then
            mix_into_config(v)
        else
            config[k] = v
        end
    end
end

mix_into_config(defaultConfig)
mix_into_config(userConfig)

-- @Global
shaders = {}

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
    if not love.filesystem.exists(config.shaderDirectory) then
        error('Shader directory "' .. config.shaderDirectory .. '" does not exist.')
    end

    local function remove_file_extension(filename)
        return (filename:gsub('%..-$', ''))
    end

    local files = love.filesystem.getDirectoryItems(config.shaderDirectory)
    for i, file in ipairs(files) do
        local path = config.shaderDirectory .. '/' .. file
        local filename = remove_file_extension(file)
        shaders[filename] = love.graphics.newShader(path)
    end

    app_handlers['load']()
end

function love.update(dt)
    app_handlers['update'](dt)
end

function love.draw()
    love.graphics.setCanvas(canvas)
    app_handlers['draw']()
    love.graphics.setCanvas()

    love.graphics.draw(canvas, 0, 0)
end
