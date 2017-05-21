local function file_get_basename(path)
    return path:gsub("(.*/)(.*)", "%2")
end

local function file_remove_extension(filename)
    return (filename:gsub('%..-$', ''))
end

local config = require 'src.config'
local hotswap = require 'src.hotswap'

local error_occurred = false
local error_region = "main"
local errors = {}

local function errhand(...)
    errors[error_region] = {...}
    print(...)
end

local old_xpcall = xpcall
xpcall = function(...)
    errors[error_region] = nil
    return old_xpcall(...)
end

local function shader_load(path)
    local basename = file_get_basename(path)
    local filename = file_remove_extension(basename)

    error_region = "shader_load"
    local ok, shader = xpcall(function()
        return love.graphics.newShader(path)
    end, errhand)

    if ok and shader then
        shaders[filename] = shader
        if not shader_uniforms[filename] then
            shader_uniforms[filename] = {}
        end

        local old_send = getmetatable(shader).send
        getmetatable(shader).send = function(...)
            local args = {...}

            local ok, result = xpcall(function()
                old_send(unpack(args))
            end, errhand)

            if ok then
                local shader = args[1]
                table.remove(args, 1)
                local variable = args[1]
                table.remove(args, 1)
                shader_uniforms[filename][variable] = args
            end
        end

        for name, args in pairs(shader_uniforms[filename]) do
            if shader:getExternVariable(name) then
                shader:send(name, unpack(args))
            else
                shader_uniforms[filename][name] = nil
            end
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

    local function app_reload()
        package.loaded['app.main'] = nil
        error_region = "app_load"
        xpcall(function()
            app = require 'app.main'

            if app then
                app:load()
            end
        end, errhand)
    end

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

    app_reload()

    hotswap:hook('app/main.lua', app_reload)

    self.newShaderCheck = Timer.every(1, function()
        local files = love.filesystem.getDirectoryItems(config.data.shader_directory)
        for i, file in ipairs(files) do
            local path = config.data.shader_directory .. '/' .. file
            local basename = file_get_basename(path)
            local filename = file_remove_extension(basename)
            if not shaders[filename] then
                shader_load(path)
                hotswap:hook(path, function(path)
                    shader_load(path)
                end)
            end
        end
    end)
end

function game:enter()

end

function game:update(dt)
    error_region = "main"

    error_region = "app_update"
    xpcall(function()
        app:update(dt)
    end, errhand)

    hotswap:update(dt)

    error_occurred = false
    for region, err in pairs(errors) do
        if err then
            error_occurred = true
            break
        end
    end
end

function game:keypressed(key, code)

end

function game:mousepressed(x, y, mbutton)

end

local function print_with_shadow(text, x, y, r, sx, sy, ox, oy, skx, sky)
    local b = 1
    love.graphics.setColor(0, 0, 0)
    love.graphics.print(text, x + b, y + b, sx, sy, ox, oy, skx, sky)
    love.graphics.setColor(255, 255, 255)
    love.graphics.print(text, x, y, sx, sy, ox, oy, skx, sky)
end

function game:draw()
    love.graphics.push("all")
    love.graphics.setCanvas(self.canvas)
    love.graphics.clear(love.graphics.getBackgroundColor())
    error_region = "app_draw"
    xpcall(function()
        app:draw()
    end, errhand)
    love.graphics.setCanvas()
    love.graphics.pop()

    love.graphics.draw(self.canvas, 0, 0)

    if error_occurred then
        love.graphics.setColor(0, 0, 0, 160)
        love.graphics.rectangle('fill', 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
        love.graphics.setColor(255, 255, 255)
        love.graphics.setFont(Fonts.bold[30])
        local x = 70
        local y = 70
        print_with_shadow('Error', x, y)
        local line_height = love.graphics.getFont():getHeight()
        y = y + line_height
        local baseFont = Fonts.monospace[18]
        love.graphics.setFont(baseFont)
        local line_height = love.graphics.getFont():getHeight()

        for region, error_log in pairs(errors) do
            if error_log then
                -- @TODO include filename
                y = y + 30
                love.graphics.setFont(Fonts.bold[18])
                print_with_shadow('Error during region: "'..region..'"', x, y)
                y = y + love.graphics.getFont():getHeight()
                love.graphics.setFont(baseFont)
                for _, text in ipairs(error_log) do
                    love.graphics.setColor(0, 0, 0)
                    love.graphics.print(text, x + 1, y + 1)
                    love.graphics.setColor(255, 255, 255)
                    love.graphics.print(text, x, y)

                    local _, lines = text:gsub('\n', '\n')
                    y = y + line_height * (lines + 1)
                end
            end
        end
    end
end

return game
