local suit = Suit.new()

Suit.theme = require 'libs.suit.theme'
local theme = Suit.theme
theme.cornerRadius = 0
theme.textShadow = {
    x = 1,
    y = 1
}
theme.color = {
    normal = {
        bg = {66, 66, 66},
        fg = {225,225,225},
        shadow = {33, 33, 33},
    },
    hovered = {
        bg = {88, 88, 88},
        fg = {255,255,255},
        shadow = {33, 33, 33},
    },
    active = {
        bg = {44, 44, 44},
        fg = {255,255,255},
        shadow = {33, 33, 33},
    }
}
function theme.Button(text, opt, x,y,w,h)
    local c = theme.getColorForState(opt)

    theme.drawBox(x,y,w,h, c, opt.cornerRadius)

    love.graphics.setColor(c.fg)
    love.graphics.setFont(opt.font)

    y = y + theme.getVerticalOffsetForAlign(opt.valign, opt.font, h)
    love.graphics.printf(text, x+2, y, w-4, opt.align or "center")
end
function theme.Label(text, opt, x,y,w,h)
    y = y + theme.getVerticalOffsetForAlign(opt.valign, opt.font, h)

    local color = (opt.color and opt.color.normal or {}).shadow or theme.color.normal.shadow
    local shadowX = (opt.textShadow or {}).x or theme.textShadow.x
    local shadowY = (opt.textShadow or {}).y or theme.textShadow.y
    local r, g, b, a = unpack(color)
    if a == nil then
        a = 255
    end
    love.graphics.setColor(r, g, b, a)
    love.graphics.setFont(opt.font)
    love.graphics.printf(text, x+2+shadowX, y+shadowY, w-4, opt.align or "center")

    local color = (opt.color and opt.color.normal or {}).fg or theme.color.normal.fg
    local r, g, b, a = unpack(color)
    if a == nil then
        a = 255
    end
    love.graphics.setColor(r, g, b, a)
    love.graphics.setFont(opt.font)
    love.graphics.printf(text, x+2, y, w-4, opt.align or "center")
end
function theme.Button(text, opt, x,y,w,h)
    local c = theme.getColorForState(opt)

    theme.drawBox(x,y,w,h, c, opt.cornerRadius)

    y = y + theme.getVerticalOffsetForAlign(opt.valign, opt.font, h)

    local shadow = (opt.color and opt.color.normal or {}).shadow or theme.color.normal.shadow
    local shadowX = (opt.textShadow or {}).x or theme.textShadow.x
    local shadowY = (opt.textShadow or {}).y or theme.textShadow.y
    local r, g, b, a = unpack(shadow)
    if a == nil then
        a = 255
    end
    love.graphics.setColor(r, g, b, a)
    love.graphics.setFont(opt.font)
    love.graphics.printf(text, x+2+shadowX, y+shadowY, w-4, opt.align or "center")

    love.graphics.setColor(c.fg)
    love.graphics.setFont(opt.font)
    love.graphics.printf(text, x+2, y, w-4, opt.align or "center")
end

local gui = {}

gui.Instance = Class{}

function gui.Instance:init(props)

    if props then
        for k, v in pairs(props) do
            self[k] = v
        end
    end
end

function gui.Instance:update(dt)
    self:draw_performance()
end

function gui.Instance:draw()
    local x = 10
    local y = 10
    local padding_x = 5
    local padding_y = 5
    local row_width = 200
    local row_height = 20
    local w = row_width
    local h = (row_height + padding_y) * 9

    love.graphics.setColor(0, 0, 0, 64)
    love.graphics.rectangle('fill', x, y, w, h)
    suit:draw()
end

function gui.Instance:draw_performance()
    local x = 10
    local y = 10
    local padding_x = 5
    local padding_y = 5
    local row_width = 200
    local row_height = 20

    local stats = love.graphics.getStats()
    local unit = "MB"
    local ram = collectgarbage("count") / 1024
    local vram = stats.texturememory / 1024 / 1024
    local info = {
        fps             = "FPS: " .. ("%3d"):format(love.timer.getFPS()),
        delta           = ("Delta: %.3fms"):format(love.timer.getAverageDelta() * 1000),
        ram             = ("RAM: %.2f%s"):format(ram, unit),
        vram            = ("VRAM: %.2f%s"):format(vram, unit),
        draw_calls      = "Draws: " .. stats.drawcalls,
        canvases        = "Canvases: " .. stats.canvases,
        canvas_switches = "Switches: " .. stats.canvasswitches,
        images          = "Images: " .. stats.images,
        shader_switches = "Shader switches: " .. stats.shaderswitches,
    }

    suit.layout:reset(x, y, padding_x, padding_y)

    for i, v in pairs(info) do
        love.graphics.setFont(Fonts.monospace[15])
        suit:Label(v, {align = 'left'}, suit.layout:row(row_width, row_height))
    end
end

return gui
