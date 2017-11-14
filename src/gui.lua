local suit    = require 'libs.suit'

local gui = {}

gui.Instance = Class{}

function gui.Instance:init(props)
    self.style = {}
    self.font_header = Fonts.default[16]

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
    suit.draw()
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
        suit.Label(v, {align = 'left'}, suit.layout:row(row_width, row_height))
    end
end

return gui
