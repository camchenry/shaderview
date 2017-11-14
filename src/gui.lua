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
    self.x = 5
    self.y = 5
    self.padding_x = 10
    self.padding_y = 5
    self.width = love.graphics.getWidth()
    self.height = love.graphics.getHeight() * 0.3
    self.row_width = self.width
    self.row_height = 15

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
    local x = self.x
    local y = self.y
    local padding_x = self.padding_x
    local padding_y = self.padding_y
    local row_width = self.row_width
    local row_height = self.row_height
    local w = row_width
    local h = (row_height + padding_y) * 9

    love.graphics.setColor(0, 0, 0, 128)
    love.graphics.rectangle('fill', x - padding_x, y - padding_y, w + padding_x * 2, h + padding_y * 2)
    suit:draw()
end

local info = {}
function gui.Instance:draw_performance()
    local x = self.x
    local y = self.y
    local padding_x = self.padding_x
    local padding_y = self.padding_y
    local row_width = self.row_width
    local row_height = self.row_height

    local stats = love.graphics.getStats()
    local unit = "MB"
    local ram = collectgarbage("count") / 1024
    local vram = stats.texturememory / 1024 / 1024

    suit.layout:reset(x, y, padding_x, padding_y)
    love.graphics.setFont(Fonts.monospace[15])

    info[1] = "FPS: " .. ("%3d"):format(love.timer.getFPS())
    info[2] = ("Delta: %.3fms"):format(love.timer.getAverageDelta() * 1000)
    info[3] = ("RAM: %.2f%s"):format(ram, unit)
    info[4] = ("VRAM: %.2f%s"):format(vram, unit)
    info[5] = "Draws: " .. stats.drawcalls
    info[6] = "Canvases: " .. stats.canvases
    info[7] = "Switches: " .. stats.canvasswitches
    info[8] = "Images: " .. stats.images
    info[9] = "Shader switches: " .. stats.shaderswitches

    for i, v in ipairs(info) do
        suit:Label(v, {align = 'left'}, suit.layout:row(row_width, row_height))
    end
end

return gui
