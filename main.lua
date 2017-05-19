local config_default = require 'config.default'
local config_user    = require 'config.user'

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

mix_into_config(config_default)
mix_into_config(config_user)

local file_last_modified = {}
local file_hotswap_interval = config.hotswap_interval
local file_hotswap_timer = 0
local file_hotswap_hooks = {}
local function file_hook_on_change(path, fn)
    if not file_hotswap_hooks[path] then
        file_hotswap_hooks[path] = {}
    end

    table.insert(file_hotswap_hooks[path], fn)

    if not file_last_modified[path] then
        file_last_modified[path] = love.filesystem.getLastModified(path)
    end
end

local function file_get_basename(path)
    return path:gsub("(.*/)(.*)", "%2")
end

local function file_remove_extension(filename)
    return (filename:gsub('%..-$', ''))
end

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
        file_hook_on_change(path, function()
            shader_load(path)
        end)
    end

    app_handlers['load']()
end

function love.update(dt)
    app_handlers['update'](dt)

    file_hotswap_timer = file_hotswap_timer + dt

    if file_hotswap_timer > file_hotswap_interval then
        file_hotswap_timer = file_hotswap_timer - file_hotswap_interval

        -- Scan for file changes
        for filepath, hooks in pairs(file_hotswap_hooks) do
            local last_modified = love.filesystem.getLastModified(filepath)

            print(last_modified, file_last_modified[filepath])
            -- Has the file changed?
            if last_modified > file_last_modified[filepath] then
                print('File changed: ' .. filepath)
                for i, fn in ipairs(hooks) do
                    fn(filepath)
                end
            end

            file_last_modified[filepath] = last_modified
        end
    end
end

function love.draw()
    love.graphics.setCanvas(canvas)
    app_handlers['draw']()
    love.graphics.setCanvas()

    love.graphics.draw(canvas, 0, 0)
end
