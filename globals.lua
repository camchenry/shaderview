-- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
-- !! This flag controls the ability to toggle the debug view.         !!
-- !! You will want to turn this to 'true' when you publish your game. !!
-- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
RELEASE = false

-- Enables the debug stats
DEBUG = not RELEASE

CONFIG = {
    graphics = {
        filter = {
            -- FilterModes: linear (blurry) / nearest (blocky)
            -- Default filter used when scaling down
            down = "nearest",

            -- Default filter used when scaling up
            up = "nearest",

            -- Amount of anisotropic filter performed
            anisotropy = 1,
        }
    },

    window = {
        icon = 'assets/images/icon.png'
    },

    debug = {
        -- The key (scancode) that will toggle the debug state.
        -- Scancodes are independent of keyboard layout so it will always be in the same
        -- position on the keyboard. The positions are based on an American layout.
        key = 'f2',

        stats = {
            font            = nil, -- set after fonts are created
            fontSize        = 16,
            lineHeight      = 18,
            foreground      = {255, 255, 255, 225},
            shadow          = {0, 0, 0, 225},
            shadowOffset    = {x = 1, y = 1},
            position        = {x = 8, y = love.graphics.getHeight()-170},

            kilobytes = false,
        },

        -- Error screen config
        error = {
            font            = nil, -- set after fonts are created
            fontSize        = 16,
            background      = {26, 79, 126},
            foreground      = {255, 255, 255},
            shadow          = {0, 0, 0, 225},
            shadowOffset    = {x = 1, y = 1},
            position        = {x = 70, y = 70},
        },

        lovebird = {
            enabled = false,
            port = 8000,
            wrapPrint = true,
            echoInput = true,
            updateInterval = 0.2,
            maxLines = 200,
            openInBrowser = false,
        }
    }
}

local function makeFont(path)
    return setmetatable({}, {
        __index = function(t, size)
            local f = love.graphics.newFont(path, size)
            rawset(t, size, f)
            return f
        end
    })
end

Fonts = {
    default = nil,

    regular         = makeFont 'assets/fonts/FiraSans-Regular.ttf',
    bold            = makeFont 'assets/fonts/FiraSans-Bold.ttf',
    light           = makeFont 'assets/fonts/FiraSans-Light.ttf',

    monospace       = makeFont 'assets/fonts/FiraCode-Regular.ttf',
}
Fonts.default = Fonts.regular

CONFIG.debug.stats.font = Fonts.monospace
CONFIG.debug.stats.position.y = love.graphics.getHeight() - CONFIG.debug.stats.font[CONFIG.debug.stats.fontSize]:getHeight()*6
CONFIG.debug.error.font = Fonts.monospace

Shaderview = {
    _NAME = "Shaderview",
    _VERSION = "v0.1.0",
}

Keybinds = {}

shaders = {}
shader_name_lookup = {}
shader_uniforms = {}
shader_sends = {}

textures = {}

Threads = {
    filechange = love.thread.newThread('threads/filechange.lua'),
}

Lume    = require 'libs.lume'
Husl    = require 'libs.husl'
Class   = require 'libs.class'
Vector  = require 'libs.vector'
State   = require 'libs.state'
Signal  = require 'libs.signal'
Inspect = require 'libs.inspect'
Camera  = require 'libs.camera'
Timer   = require 'libs.timer'
Input   = require 'libs.boipushy'

if DEBUG and CONFIG.debug.lovebird.enabled then
    Lovebird = require 'libs.lovebird'
    Lovebird.port = CONFIG.debug.lovebird.port
    Lovebird.wrapprint = CONFIG.debug.lovebird.wrapPrint
    Lovebird.echoinput = CONFIG.debug.lovebird.echoInput
    Lovebird.updateinterval = CONFIG.debug.lovebird.updateInterval
    Lovebird.maxlines = CONFIG.debug.lovebird.maxLines
    print('Running lovebird on localhost:' .. Lovebird.port)
    if CONFIG.debug.lovebird.openInBrowser then
        love.system.openURL("http://localhost:" .. Lovebird.port)
    end
end

States = {
    game = require 'states.game',
    splash = require 'states.splash',
}

Active_Project = {}

local function basename(str)
    return string.gsub(str, "(.*/)(.*)", "%2")
end

function copy_directory(source, dest, dir_name, depth)
    if not depth then
        depth = 1
    end
    if not love.filesystem.isDirectory(source) then
        error("Source folder '" .. source .. "' does not exist.")
    end
    local files = love.filesystem.getDirectoryItems(source)

    if depth == 1 then
        dest_src_name = basename(source)
        if dir_name then
            dest = dest .. '/' .. dir_name
        else
            dest = dest .. '/' .. basename(source)
        end
    end
    dest = dest .. '/'
    source = source .. '/'

    if not love.filesystem.exists(dest) then
        love.filesystem.createDirectory(dest)
    end

    for _, file in ipairs(files) do
        if love.filesystem.isDirectory(source .. file) then
            copy_directory(source .. file, dest .. file, nil, depth + 1)
        elseif love.filesystem.isFile(source .. file) then
            love.filesystem.write(dest .. file, love.filesystem.read(source .. file))
        end
    end
end

