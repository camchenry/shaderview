
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
local error_clear_error = true
local error_overlay = {
    opacity = 0,
    foreground = {255, 255, 255, 255},
    shadow = {0, 0, 0, 255},
    background = {0, 0, 0, 160},
}
local errors = {}

local function errhand(...)
    errors[error_region] = {
        message = ...
    }
    print(...)
end

local old_xpcall = xpcall
xpcall = function(...)
    if error_clear_error then
        errors[error_region] = nil
    end
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

            error_clear_error = false
            local region = error_region
            local ok, result = xpcall(function()
                old_send(unpack(args))
            end, errhand)
            error_region = region
            error_clear_error = true

            if ok then
                local shader = args[1]
                table.remove(args, 1)
                local variable = args[1]
                table.remove(args, 1)
                shader_uniforms[filename][variable] = args
            end
        end

        for name, args in pairs(shader_uniforms[filename]) do
            shader:send(name, unpack(args))
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

local function call_app_update(dt)
    if app then
        app:update(dt)
    end
end

function game:update(dt)
    error_region = "main"

    error_region = "app_update"
    xpcall(call_app_update, errhand, dt)

    hotswap:update(dt)

    error_occurred = false
    for region, err in pairs(errors) do
        if err then
            if not error_occurred then
                if self.opacityTween then
                    Timer.cancel(self.opacityTween)
                end
                self.opacityTween = Timer.tween(0.1, error_overlay, {opacity=1})
            end
            error_occurred = true
            break
        end
    end

    if not error_occurred then
        error_overlay.opacity = 0
    end

    print(error_overlay.opacity)
end

function game:keypressed(key, code)

end

function game:mousepressed(x, y, mbutton)

end

local function print_with_shadow(text, x, y, r, sx, sy, ox, oy, skx, sky)
    local shadow_size = 1

    local r, g, b, a = unpack(error_overlay.shadow)
    love.graphics.setColor(r, g, b, a * error_overlay.opacity)
    love.graphics.print(text, x + shadow_size, y + shadow_size, sx, sy, ox, oy, skx, sky)

    local r, g, b, a = unpack(error_overlay.foreground)
    love.graphics.setColor(r, g, b, a * error_overlay.opacity)
    love.graphics.print(text, x, y, sx, sy, ox, oy, skx, sky)
end

local function call_app_draw()
    if app then
        app:draw()
    end
end

function game:draw()
    love.graphics.push("all")
    error_region = "app_draw"
    xpcall(call_app_draw, errhand)
    love.graphics.pop()

    if error_occurred then
        local r, g, b, a = unpack(error_overlay.background)
        love.graphics.setColor(r, g, b, a * error_overlay.opacity)
        love.graphics.rectangle('fill', 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
        local x = 70
        local y = 70
        love.graphics.setFont(Fonts.bold[30])
        print_with_shadow('Error', x, y)
        local line_height = love.graphics.getFont():getHeight()
        y = y + line_height
        local baseFont = Fonts.monospace[18]
        love.graphics.setFont(baseFont)
        local line_height = love.graphics.getFont():getHeight()

        for region, err in pairs(errors) do
            if err then
                -- @TODO include filename
                y = y + 30
                love.graphics.setFont(Fonts.bold[18])
                print_with_shadow('Error during region: "'..region..'"', x, y)
                y = y + love.graphics.getFont():getHeight()
                love.graphics.setFont(baseFont)
                local text = err.message
                print_with_shadow(text, x, y)

                local _, lines = text:gsub('\n', '\n')
                y = y + line_height * (lines + 1)
            end
        end
    end
end

return game
