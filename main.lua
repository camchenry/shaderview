local loadTimeStart = love.timer.getTime()
require 'globals'

local tree = (...)
local cpaths = {}

local function c_loader(modname, fn_name)
    local os = love.system.getOS()
    if not os then
        error("Cannot load native modules, OS not found.")
    end

    local ext  = os == 'Windows' and ".dll" or ".so"
    local file = modname:gsub("%.", "/") .. ext

    for _, elem in ipairs(cpaths) do
        elem = elem:gsub('%?', file)

        local base = nil
        if love.filesystem.isFused() then
            base = love.filesystem.getSourceBaseDirectory()
            if can_open(base .. "/" ..elem) == false then
                base = nil -- actually, file not found
            end
        elseif love.filesystem.exists(elem) then
            base = love.filesystem.getRealDirectory(elem)
        end

        if base then
            local path = base .. "/" .. elem
            local lib, err1 = package.loadlib(path, "loveopen_"..fn_name)
            if lib then return lib end

            local err2
            lib, err2 = package.loadlib(path, "luaopen_"..fn_name)
            if lib then return lib end

            if err1 == err2 then
                error(err1)
            else
                error(err1.."\n"..err2)
            end
        end
    end

    error("no library '" .. file .. "' in path.")
end

local function c_load(modname)
    return c_loader(modname, modname:gsub("%.", "_"))
end

function love.load()
    if love.system.getOS() == "Windows" then
        cpaths[#cpaths+1] = "/libs/nuklear/win64/?"
        Nuklear = c_load('nuklear')()
    elseif love.system.getOS() == "Linux" then
        cpaths[#cpaths+1] = "/libs/nuklear/linux64/?"
        Nuklear = c_load('nuklear')()
    elseif love.system.getOS() == "OS X" then
        --cpaths[#cpaths+1] = "/libs/nuklear/osx64/?"
        --Nuklear = c_load('nuklear')
        error([[
OS X binaries for the love-nuklear GUI are currently not included. If you are
willing, please open an issue to help build the binaries.
    ]])
    else
        error(([[
Your operating system is currently not supported. Please open an issue with the
issue tracker and include your OS and device info.

OS: %s
    ]]):format(love.system.getOS()))
    end

    local save_paths = {
        'save',
        'save/screenshots',
        'save/config',
        'save/projects',
    }

    for _, path in ipairs(save_paths) do
        if not love.filesystem.exists(path) then
            love.filesystem.createDirectory(path)
        end
    end

    if not love.filesystem.exists('save/config/user.lua') then
        love.filesystem.write('save/config/user.lua', love.filesystem.read('templates/user_config.lua'))
    end

    if not love.filesystem.exists('save/config/default.lua') then
        love.filesystem.write('save/config/default.lua', love.filesystem.read('templates/default_config.lua'))
    end

    if not love.filesystem.exists('save/projects/demo') then
        copy_directory('templates/demo', 'save/projects')
    end

    love.window.setIcon(love.image.newImageData(CONFIG.window.icon))
    love.graphics.setDefaultFilter(CONFIG.graphics.filter.down,
                                   CONFIG.graphics.filter.up,
                                   CONFIG.graphics.filter.anisotropy)
    love.keyboard.setKeyRepeat(true)


    -- Draw is left out so we can override it ourselves
    local callbacks = {'errhand', 'update'}
    local leftoutCallbacks = {'keypressed', 'keyreleased', 'mousepressed', 'mousereleased', 'mousemoved', 'textinput', 'wheelmoved'}
    for k in pairs(love.handlers) do
        if not Lume.find(leftoutCallbacks, k) then
            callbacks[#callbacks+1] = k
        end
    end

    State.registerEvents(callbacks)
    State.switch(States.splash)

    Nuklear.init()

    if DEBUG then
        local loadTimeEnd = love.timer.getTime()
        local loadTime = (loadTimeEnd - loadTimeStart)
        print(("Loaded in %.3f seconds."):format(loadTime))
        if Lovebird then
            Lovebird.print(("Loaded in %.3f seconds."):format(loadTime))
        end
    end
end

function love.update(dt)
    if DEBUG and Lovebird then
        Lovebird.update()
    end
    Timer.update(dt)
end

function love.draw()
    local draw_time_start = love.timer.getTime()
    State.current():draw()
    local draw_time_end = love.timer.getTime()
    local draw_time = draw_time_end - draw_time_start

    Nuklear.draw()
end

function love.keypressed(key, code, isRepeat)
    if not RELEASE and code == CONFIG.debug.key then
        DEBUG = not DEBUG
    end

    if Nuklear.keypressed(key, code, isRepeat) then
        return
    end

    State.current():keypressed(key, code, isRepeat)
end

function love.keyreleased(key, code)
    if Nuklear.keyreleased(key, code) then
        return
    end

    State.current():keyreleased(key, code)
end

function love.mousepressed(x, y, button, istouch)
    if Nuklear.mousepressed(x, y, button, istouch) then
        return
    end

    State.current():mousepressed(x, y, button, istouch)
end

function love.mousereleased(x, y, button, istouch)
    if Nuklear.mousereleased(x, y, button, istouch) then
        return
    end

    State.current():mousereleased(x, y, button, istouch)
end

function love.mousemoved(x, y, dx, dy, istouch)
    if Nuklear.mousemoved(x, y, dx, dy, istouch) then
        return
    end

    State.current():mousemoved(x, y, dx, dy, istouch)
end

function love.textinput(text)
    if Nuklear.textinput(text) then
        return
    end

    State.current():textinput(text)
end

function love.wheelmoved(x, y)
    if Nuklear.wheelmoved(x, y) then
        return
    end

    State.current():wheelmoved(x, y)
end

function love.threaderror(thread, errorMessage)
    print("Thread error!\n" .. errorMessage)
end

function love.quit()
    Nuklear.shutdown()
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
