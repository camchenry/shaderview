local loadTimeStart = love.timer.getTime()
require 'globals'

function love.load()
    local save_paths = {
        'save',
        'save/screenshots',
        'save/config',
        'save/projects',
    }

    for _, path in ipairs(save_paths) do
        if not love.filesystem.getInfo(path, 'directory') then
            love.filesystem.createDirectory(path)
        end
    end

    if not love.filesystem.getInfo('save/config/user.lua', 'file') then
        love.filesystem.write('save/config/user.lua', love.filesystem.read('templates/user_config.lua'))
    end

    if not love.filesystem.getInfo('save/config/default.lua', 'file') then
        love.filesystem.write('save/config/default.lua', love.filesystem.read('templates/default_config.lua'))
    end

    if not love.filesystem.getInfo('save/projects/demo', 'directory') then
        copy_directory('templates/demo', 'save/projects')
    end

    love.window.setIcon(love.image.newImageData(CONFIG.window.icon))
    love.graphics.setDefaultFilter(CONFIG.graphics.filter.down,
                                   CONFIG.graphics.filter.up,
                                   CONFIG.graphics.filter.anisotropy)
    love.keyboard.setKeyRepeat(true)


    -- Draw is left out so we can override it ourselves
    local callbacks = {'errhand', 'update'}
    for k in pairs(love.handlers) do
        callbacks[#callbacks+1] = k
    end

    State.registerEvents(callbacks)
    State.switch(States.splash)

    if DEBUG then
        local loadTimeEnd = love.timer.getTime()
        local loadTime = (loadTimeEnd - loadTimeStart)
        print(("Loaded in %.3f seconds."):format(loadTime))
    end
end

function love.update(dt)
    Timer.update(dt)
end

function love.draw()
    local draw_time_start = love.timer.getTime()
    State.current():draw()
    local draw_time_end = love.timer.getTime()
    local draw_time = draw_time_end - draw_time_start
end

function love.keypressed(key, code, isRepeat)
    if not RELEASE and code == CONFIG.debug.key then
        DEBUG = not DEBUG
    end
end

function love.keyreleased(key, code)

end

function love.mousepressed(x, y, button, istouch)

end

function love.mousereleased(x, y, button, istouch)

end

function love.mousemoved(x, y, dx, dy, istouch)

end

function love.textinput(text)

end

function love.wheelmoved(x, y)

end

function love.threaderror(thread, errorMessage)
    print("Thread error!\n" .. errorMessage)
end

function love.quit()
    for name, thread in pairs(Threads) do
        if thread:isRunning() then
            local channel = love.thread.getChannel('channel_' .. name .. '_quit')
            channel:push('quit')
            thread:wait()
        end
    end
end

-----------------------------------------------------------
-- Error screen.
-----------------------------------------------------------

local debug, print = debug, print

local function error_printer(msg, layer)
    print((debug.traceback("Error: " .. tostring(msg), 1+(layer or 1)):gsub("\n[^\n]+$", "")))
end

function love.errhand(msg)
    msg = tostring(msg)

    error_printer(msg, 2)

    if not love.window or not love.graphics or not love.event then
        return
    end

    if not love.graphics.isCreated() or not love.window.isOpen() then
        local success, status = pcall(love.window.setMode, 800, 600)
        if not success or not status then
            return
        end
    end

    -- Reset state.
    if love.mouse then
        love.mouse.setVisible(true)
        love.mouse.setGrabbed(false)
        love.mouse.setRelativeMode(false)
        if love.mouse.hasCursor() then
            love.mouse.setCursor()
        end
    end
    if love.joystick then
        -- Stop all joystick vibrations.
        for i,v in ipairs(love.joystick.getJoysticks()) do
            v:setVibration()
        end
    end
    if love.audio then love.audio.stop() end
    love.graphics.reset()
    local size = math.floor(love.window.toPixels(CONFIG.debug.error.fontSize))
    love.graphics.setFont(CONFIG.debug.error.font[size])

    love.graphics.setBackgroundColor(CONFIG.debug.error.background)
    love.graphics.setColor(CONFIG.debug.error.foreground)

    local trace = debug.traceback()

    love.graphics.clear(love.graphics.getBackgroundColor())
    love.graphics.origin()

    local err = {}

    table.insert(err, "Error")
    table.insert(err, "-------\n")
    table.insert(err, msg.."\n\n")

    local i = 0
    for l in string.gmatch(trace, "(.-)\n") do
        if not string.match(l, "boot.lua") then
            local firstLine = string.match(l, "stack traceback:")
            l = string.gsub(l, "stack traceback:", "Traceback")

            if not firstLine then
                l = ">  " .. l
            end

            table.insert(err, l)

            if firstLine then
                table.insert(err, "-----------\n")
            end
        end
    end

    local p = table.concat(err, "\n")

    p = string.gsub(p, "\t", "")
    p = string.gsub(p, "%[string \"(.-)\"%]", "%1")

    local function draw()
        local x, y = love.window.toPixels(CONFIG.debug.error.position.x), love.window.toPixels(CONFIG.debug.error.position.y)
        love.graphics.clear(love.graphics.getBackgroundColor())
        local sx, sy = CONFIG.debug.error.shadowOffset.x, CONFIG.debug.error.shadowOffset.y
        love.graphics.setColor(CONFIG.debug.error.shadow)
        love.graphics.printf(p, x + sx, y + sy, love.graphics.getWidth() - x)
        love.graphics.setColor(CONFIG.debug.error.foreground)
        love.graphics.printf(p, x, y, love.graphics.getWidth() - x)
        love.graphics.present()
    end

    local fullErrorText = p
    local function copyToClipboard()
        if not love.system then return end
        love.system.setClipboardText(fullErrorText)
        p = p .. "\nCopied to clipboard!"
        draw()
    end

    if love.system then
        p = p .. "\n\nPress Ctrl+C or tap to copy this error"
    end

    while true do
        love.event.pump()

        for e, a, b, c in love.event.poll() do
            if e == "quit" then
                return
            elseif e == "keypressed" and a == "escape" then
                return
            elseif e == "keypressed" and a == "c" and love.keyboard.isDown("lctrl", "rctrl") then
                copyToClipboard()
            elseif e == "touchpressed" then
                local name = love.window.getTitle()
                if #name == 0 or name == "Untitled" then name = "Game" end
                local buttons = {"OK", "Cancel"}
                if love.system then
                    buttons[3] = "Copy to clipboard"
                end
                local pressed = love.window.showMessageBox("Quit "..name.."?", "", buttons)
                if pressed == 1 then
                    return
                elseif pressed == 3 then
                    copyToClipboard()
                end
            end
        end

        draw()

        if love.timer then
            love.timer.sleep(0.1)
        end
    end

end
