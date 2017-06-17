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

local orig_error = error
error = function(...)
    return orig_error(... or 'nil')
end

local orig_xpcall = xpcall
xpcall = function(...)
    if error_clear_error then
        errors[error_region] = nil
    end
    return orig_xpcall(...)
end

-- This override allows dynamically switching the Shader:send function so that
-- we can inspect what's going into it and extract the values.
local function shader_metatable_send_override(filename, shader, ...)
    shader_sends[filename](shader, ...)
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

        if not shader_metatable_send_default then
            shader_metatable_send_default = getmetatable(shader).send
        end

        shader_name_lookup[shader] = filename

        shader_sends[filename] = function(...)
            local args = {...}

            error_clear_error = false
            local region = error_region
            local ok, result = xpcall(function()
                shader_metatable_send_default(unpack(args))
            end, errhand)
            error_region = region
            error_clear_error = true

            if ok then
                local shader = args[1]
                table.remove(args, 1)
                local variable = args[1]
                table.remove(args, 1)
                shader_uniforms[shader_name_lookup[shader]][variable] = args
            end
        end

        getmetatable(shader).send = function(...)
            shader_metatable_send_override(filename, ...)
        end

        for name, args in pairs(shader_uniforms[filename]) do
            if shader:getExternVariable(name) then
                shader:send(name, unpack(args))
            end
        end
    end
end

local game = {}

function game:init()
    local function config_reload()
        config.data = {}
        config:load('save/config/default.lua')
        config:load('save/config/user.lua')
        local channel_config = love.thread.getChannel("channel_filechange_config")
        channel_config:push(config.data)
        print('Config reloaded')
        if self.notification_queue and config.data.notification_reload_config then
            self.notification_queue:add(notify.Notification{
                text = 'Config reloaded'
            })
        end
    end

    hotswap:hook('save/config/default.lua', config_reload)
    hotswap:hook('save/config/user.lua', config_reload)

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

    original_package_path = package.path

    local function load_project(project_name)
        Active_Project = {}
        Active_Project.name = project_name
        package.path = original_package_path .. ';' .. love.filesystem.getSaveDirectory() .. '/save/projects/' .. project_name .. '/?.lua'

        local project_dir = 'save/projects/' .. project_name
        local shader_dir = project_dir .. '/shaders'
        local files = love.filesystem.getDirectoryItems(shader_dir)
        for i, file in ipairs(files) do
            local path = shader_dir .. '/' .. file
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

        hotswap:hook('save/projects/' .. project_name .. '/app/main.lua', function()
            app_reload()
            if self.notification_queue and config.data.notification_reload_app then
                self.notification_queue:add(notify.Notification{
                    text = 'App reloaded'
                })
            end
        end)

        -- @TODO Undefine handlers when switching projects
        for handler, fn in pairs(love.handlers) do
            if not self[handler] then
                self[handler] = function(...)
                    if app and app[handler] then
                        local region = error_region
                        error_region = "app_" .. handler
                        xpcall(app[handler], errhand, ...)
                        error_region = region
                    end
                end
            end
        end

        if self.new_shader_check then
            Timer.cancel(self.new_shader_check)
        end
        self.new_shader_check = Timer.every(1, function()
            local shader_dir = 'save/projects/' .. project_name .. '/shaders'
            local files = love.filesystem.getDirectoryItems(shader_dir)
            for i, file in ipairs(files) do
                local path = shader_dir .. '/' .. file
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

    self.load_project = function(self, project)
        load_project(project)
    end

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

    Keybinds[CONFIG.debug.key] = "Toggle debug windows"
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

    Keybinds['f11'] = "Toggle fullscreen"
    self.input:bind('f11', function()
        local w, h, flags = love.window.getMode()
        local x, y = flags.x, flags.y
        if flags.fullscreen then
            w = self.windowed_w
            h = self.windowed_h
            x = self.windowed_x
            y = self.windowed_y
        else
            self.windowed_w = w
            self.windowed_h = h
            self.windowed_x = x
            self.windowed_y = y
        end
        flags.fullscreen = not flags.fullscreen
        flags.x = x
        flags.y = y
        love.window.setMode(w, h, flags)
        -- @Bug for some reason the resize needs to be triggered manually
        self:resize(w, h)
    end)

    Keybinds['f12'] = "Take screenshot"
    self.input:bind('f12', function()
        local screenshot = love.graphics.newScreenshot()
        local save_dir = love.filesystem.getSaveDirectory()
        local screenshot_dir = 'save/screenshots/'
        local _, msec = math.modf(love.timer.getTime())
        msec = math.floor(msec * 1000)
        local filename = os.date('%Y_%m_%d_%H_%M_%S') .. '_' .. msec .. '.png'
        screenshot:encode('png', screenshot_dir .. filename)
        local fullpath = love.filesystem.getSaveDirectory() .. screenshot_dir .. filename
        self.notification_queue:add(notify.Notification{
            text = 'Screenshot captured. (' .. screenshot_dir .. filename .. ')'
        })
    end)
end

function game:enter(prev, project)
    self:load_project(project)
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
