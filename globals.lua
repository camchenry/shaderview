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
shader_uniforms = {}
shader_sends = {}

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
}
