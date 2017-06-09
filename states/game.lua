local function file_get_basename(path)
    return path:gsub("(.*/)(.*)", "%2")
end

local function file_remove_extension(filename)
    return (filename:gsub('%..-$', ''))
end

local config = require 'src.config'
local hotswap = require 'src.hotswap'
local notify = require 'src.notification'
local help = require 'src.help'
local gui = require 'src.gui'

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
local channel_filechange = love.thread.getChannel("channel_filechange")

local function errhand(...)
    errors[error_region] = {
        message = tostring(...)
    }
    print(...)
end

local old_error = error
error = function(...)
    return old_error(... or 'nil')
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
        config:load('user_config.lua')
        local channel_config = love.thread.getChannel("channel_filechange_config")
        channel_config:push(config.data)
        print('Config reloaded')
        if self.notification_queue and config.data.notification_reload_config then
            self.notification_queue:add(notify.Notification{
                text = 'Config reloaded'
            })
        end
    end

    hotswap:hook('config/default.lua', config_reload)

    if not love.filesystem.exists('user_config.lua') then
        love.filesystem.write('user_config.lua', [[
-- This is the user config file
-- Properties here will overwrite the default config
return {
}
]])
    end

    hotswap:hook('user_config.lua', config_reload)

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

    if not Threads.filechange:isRunning() then
        local channel_name = "channel_filechange"
        Threads.filechange:start("channel_filechange",
                                 "channel_filechange_config",
                                 "channel_filechange_files",
                                 "channel_filechange_quit")
        local channel_config = love.thread.getChannel("channel_filechange_config")
        channel_config:push(config.data)
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
            if self.notification_queue and config.data.notification_reload_shader then
                self.notification_queue:add(notify.Notification{
                    text = 'Shader reloaded: ' .. path
                })
            end
        end)
    end

    app_reload()

    hotswap:hook('app/main.lua', function()
        app_reload()
        if self.notification_queue and config.data.notification_reload_app then
            self.notification_queue:add(notify.Notification{
                text = 'App reloaded'
            })
        end
    end)

    for handler, fn in pairs(love.handlers) do
        if not self[handler] then
            self[handler] = function(...)
                if app[handler] then
                    local region = error_region
                    error_region = "app_" .. handler
                    xpcall(app[handler], errhand, ...)
                    error_region = region
                end
            end
        end
    end

    self.new_shader_check = Timer.every(1, function()
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

    self.notification_queue = notify.Queue()
    self.help_panel = help.Panel{
        visible = config.data.show_help_on_start
    }

    local nk = Nuklear
    gui_instance = gui.Instance{
        font_header = Fonts.default[16],
        style = {
            font = Fonts.monospace[14],
            text = {
                color = nk.colorRGBA(255, 255, 255)
            },
        }
    }

    self.input = Input()

    Keybinds['f5'] = "Reload all shaders and app files"
    Keybinds['ctrl + f5'] = "Restart Shaderview"
    self.input:bind('f5', function()
        if love.keyboard.isDown('lctrl', 'rctrl') then
            love.event.quit('restart')
        else
            for filepath, _ in pairs(hotswap.hooks) do
                if not string.match(filepath, 'config') then
                    hotswap:on_file_changed(filepath)
                end
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

    if channel_filechange:peek() then
        local filepath = channel_filechange:pop()
        print('File changed: ' .. filepath)
        hotswap:on_file_changed(filepath)
    end

    self.notification_queue:update(dt)
    self.help_panel:update(dt)

    if DEBUG then
        gui_instance:update(dt)
    end

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

    self.notification_queue:draw()
    self.help_panel:draw()

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
