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
    self.row_width = 200
    self.row_height = 15
    self.top_row_width = 200
    self.top_row_height = 30
    self.main_layout = suit.layout:rows{
        pos = {self.x, self.y},
        padding = {self.padding_x, self.padding_y},
        min_height = self.height,
        min_width = self.width,

        {self.width, self.top_row_height},
        {'fill', 'fill'},
    }
    self.tab_layout = suit.layout:cols{
        pos = {self.main_layout.cell(2)},
        padding = {self.padding_x, self.padding_y},
        min_height = self.height,

        {'fill', self.height},
    }
    self.current_tab = 'general'
    self.textures_to_draw = {}

    if props then
        for k, v in pairs(props) do
            self[k] = v
        end
    end
end

function gui.Instance:update(dt)
    suit.layout:reset(self.x, self.y, self.padding_x, self.padding_y)

    suit.layout:push(self.main_layout:cell(1))
    love.graphics.setFont(Fonts.regular[16])
    if suit:Button('General', {align = 'left'}, suit.layout:col(125, self.top_row_height)).hit then
        self.current_tab = 'general'
    end
    if suit:Button('Performance', {align = 'left'}, suit.layout:col()).hit then
        self.current_tab = 'performance'
    end
    if suit:Button('Textures', {align = 'left'}, suit.layout:col()).hit then
        self.current_tab = 'textures'
    end
    suit.layout:pop()

    if self.current_tab == 'general' then
        -- @TODO
    elseif self.current_tab == 'performance' then
        self:draw_performance()
    elseif self.current_tab == 'textures' then
        self:draw_textures()
    end
end

function gui.Instance:draw()
    local x = self.x
    local y = self.y
    local padding_x = self.padding_x
    local padding_y = self.padding_y
    local row_width = self.row_width
    local row_height = self.row_height
    local w, h = self.tab_layout.size()
    w = self.width

    local x = x - padding_x
    local y = y - padding_y
    local w = w + padding_x * 2
    local h = h + padding_y * 2
    love.graphics.setColor(0, 0, 0, 128)
    love.graphics.rectangle('fill', x, y, w, h)
    suit:draw()

    for i, data in ipairs(self.textures_to_draw) do
        love.graphics.push()
        love.graphics.setColor(255, 255, 255)
        love.graphics.draw(data.texture, data.x, data.y, data.rotation, data.scale_x, data.scale_y)
        love.graphics.pop()
    end
    self.textures_to_draw = {}
end

function gui.Instance:draw_textures()
    love.graphics.setFont(Fonts.monospace[15])

    local row_width = self.width / 5

    self.tab_layout = suit.layout:cols{
        pos = {self.main_layout.cell(2)},
        padding = {self.padding_x, self.padding_y},
        min_width = self.width,
        min_height = self.height,

        {row_width, self.height},
        {row_width, self.height},
        {row_width, self.height},
        {row_width, self.height},
        {row_width, self.height},
    }

    local num_textures = Lume.count(textures)
    local i = 0
    for name, texture in pairs(textures) do
        i = i + 1
        suit.layout:push(self.tab_layout.cell(i))
        local _, _, cell_w, cell_h = self.tab_layout.cell(i)
        local texture_w, texture_h = texture:getDimensions()
        local thumbnail_height = cell_h - self.row_height * 10
        local thumbnail_x, thumbnail_y, _w, _h = suit.layout:row(row_width, thumbnail_height)
        local thumbnail_width = thumbnail_height
        table.insert(self.textures_to_draw, {
            texture = textures[name],
            x = thumbnail_x,
            y = thumbnail_y,
            rotation = 0,
            scale_x = thumbnail_width / texture_w,
            scale_y = thumbnail_height / texture_h,
        })

        local filter = texture:getFilter()
        local wrap_x, wrap_y = texture:getWrap()
        suit:Label(name, {align = 'left'}, suit.layout:row(row_width, self.row_height))
        local size_text = ("%d x %d"):format(texture_w, texture_h)
        suit:Label(size_text, {align = 'left'}, suit.layout:row(row_width, self.row_height))
        local filter_text = ("filter: '%s'"):format(filter)
        suit:Label(filter_text, {align = 'left'}, suit.layout:row(row_width, self.row_height))
        local wrap_text_x = ("wrap_x: '%s'"):format(wrap_x)
        local wrap_text_y = ("wrap_y: '%s'"):format(wrap_y)
        suit:Label(wrap_text_x, {align = 'left'}, suit.layout:row(row_width, self.row_height))
        suit:Label(wrap_text_y, {align = 'left'}, suit.layout:row(row_width, self.row_height))
        if i >= 5 then
            break
        end

        suit.layout:pop()
    end
    if num_textures == 0 then
        suit.layout:push(self.tab_layout.cell(1))
        suit:Label('No textures loaded.', {align = 'left'}, suit.layout:row(self.row_width, self.row_height))
        suit.layout:pop()
    end
end


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

    love.graphics.setFont(Fonts.monospace[15])

    local info = {
        "FPS: " .. ("%3d"):format(love.timer.getFPS()),
        ("Delta: %.3fms"):format(love.timer.getAverageDelta() * 1000),
        ("RAM: %.2f%s"):format(ram, unit),
        ("VRAM: %.2f%s"):format(vram, unit),
        "Draws: " .. stats.drawcalls,
        "Canvases: " .. stats.canvases,
        "Canvas switches: " .. stats.canvasswitches,
        "Images: " .. stats.images,
        "Shader switches: " .. stats.shaderswitches,
    }

    self.tab_layout = suit.layout:cols{
        pos = {self.main_layout.cell(2)},
        padding = {padding_x, padding_y},
        min_width = self.width,
        min_height = self.height,

        {self.row_width, self.height},
        {self.row_width},
    }

    suit.layout:push(self.tab_layout.cell(1))
    for i=1, 5 do
        local text = info[i]
        suit:Label(text, {align = 'left'}, suit.layout:row(row_width, row_height))
    end
    suit.layout:pop()

    suit.layout:push(self.tab_layout.cell(2))
    for i=6, 9 do
        local text = info[i]
        suit:Label(text, {align = 'left'}, suit.layout:row(row_width, row_height))
    end
    suit.layout:pop()
end

return gui
