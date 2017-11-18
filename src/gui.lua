local suit = Suit.new()

Suit.theme = require 'libs.suit.theme'
local theme = Suit.theme
theme.cornerRadius = 0
theme.textShadow = {
    x = 1,
    y = 1
}
theme.text_padding_x = 4
theme.text_padding_y = 2
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

    x = math.floor(x + 0.5)
    y = math.floor(y + 0.5)

    theme.drawBox(x,y,w,h, c, opt.cornerRadius)

    if opt.border then
        love.graphics.push()
        if opt.border.right then
            love.graphics.setColor(opt.border.right.color or {})
            local width = opt.border.right.width or 1
            love.graphics.setLineWidth(width)
            love.graphics.setLineStyle(opt.border.right.style or 'rough')
            love.graphics.line(x + w, y, x + w, y + h)
        end
        if opt.border.left then
            love.graphics.setColor(opt.border.left.color or {})
            local width = opt.border.left.width or 1
            love.graphics.setLineWidth(width)
            love.graphics.setLineStyle(opt.border.left.style or 'rough')
            love.graphics.line(x + width, y, x + width/2, y + h)
        end
        if opt.border.bottom then
            love.graphics.setColor(opt.border.bottom.color or {})
            local width = opt.border.bottom.width or 1
            love.graphics.setLineWidth(width)
            love.graphics.setLineStyle(opt.border.bottom.style or 'rough')
            love.graphics.line(x, y + h - width / 2, x + w, y + h - width / 2)
        end
        if opt.border.top then
            love.graphics.setColor(opt.border.top.color or {})
            local width = opt.border.top.width or 1
            love.graphics.setLineWidth(width)
            love.graphics.setLineStyle(opt.border.top.style or 'rough')
            love.graphics.line(x, y + width / 2, x + w, y + width / 2)
        end
        love.graphics.pop()
    end

    local padx = opt.text_padding_x or theme.text_padding_x
    local pady = opt.text_padding_x or theme.text_padding_y
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
    love.graphics.printf(text, x+padx+shadowX, y+shadowY, w - padx*2, opt.align or "center")

    love.graphics.setColor(c.fg)
    love.graphics.setFont(opt.font)
    love.graphics.printf(text, x+padx, y, w - padx*2, opt.align or "center")
end

local gui = {}

gui.Instance = Class{}

function gui.Instance:init(props)
    self.x = 0
    self.y = 0
    self.padding_x = 10
    self.padding_y = 5
    self.width = love.graphics.getWidth()
    self.height = love.graphics.getHeight() * 0.3
    self.row_width = 200
    self.row_height = 15
    self.top_row_width = 200
    self.top_row_height = 30
    self.top_row_padding_x = 0
    self.top_row_padding_y = 10
    self.main_layout = suit.layout:rows{
        pos = {self.x, self.y},
        padding = {self.top_row_padding_x, self.top_row_padding_y},
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

function gui.Instance:resize(new_width, new_height)
    self.width = new_width
    self.height = new_height * 0.3
    self.main_layout = suit.layout:rows{
        pos = {self.x, self.y},
        padding = {self.padding_x, self.padding_y * 2},
        min_height = self.height,
        min_width = self.width,

        {self.width, self.top_row_height},
        {'fill', 'fill'},
    }
end

function gui.Instance:update(dt)
    suit.layout:reset(self.x, self.y, self.padding_x, self.padding_y)

    local tabs = {
        {
            id = 'general',
            label = 'General',
        },
        {
            id = 'performance',
            label = 'Performance',
        },
        {
            id = 'textures',
            label = 'Textures',
        },
    }

    suit.layout:push(self.main_layout:cell(1))
    suit.layout:padding(0, 0)
    for i, tab in ipairs(tabs) do
        local opt = {
            align = 'left',
            text_padding_x = 10,
            border = {
                left = {
                    color = {255, 255, 255, 64},
                    width = 1,
                },
                right = {
                    color = {0, 0, 0, 96},
                    width = 1,
                },
                bottom = {
                    color = {0, 0, 0, 128},
                    width = 2,
                },
                top = {
                    color = {255, 255, 255, 64},
                    width = 1,
                },
            }
        }
        if self.current_tab == tab.id then
            opt.font = Fonts.bold[18]

            local top_color = Lume.clone(opt.border.top.color)
            opt.border.top.color = opt.border.bottom.color
            opt.border.left.color = opt.border.bottom.color
            opt.border.bottom.color = top_color
            opt.border.bottom.width = 0
        else
            opt.font = Fonts.regular[18]
        end

        -- Hide borders on far left and right tabs
        if i == 1 then opt.border.left = nil end
        if i == #tabs then opt.border.right = nil end

        if suit:Button(tab.label, opt, suit.layout:col(self.top_row_width, self.top_row_height + self.top_row_padding_y / 2)).hit then
            self.current_tab = tab.id
        end
    end
    suit.layout:pop()

    if self.current_tab == 'general' then
        self:draw_general()
    elseif self.current_tab == 'performance' then
        self:draw_performance()
    elseif self.current_tab == 'textures' then
        self:draw_textures()
    end
end

function gui.Instance:draw()
    local _, _, cell_width, cell_height = self.main_layout.cell(2)
    local padding_x = self.padding_x
    local padding_y = self.padding_y
    local x = self.x - padding_x
    local y = self.y - padding_y
    local w = cell_width + padding_x * 2
    local h = cell_height + padding_y * 2
    love.graphics.setColor(0, 0, 0, 128)
    love.graphics.rectangle('fill', x, y, w, h)

    local x = x
    local y = y
    local w = self.width          + self.padding_x * 2
    local h = self.top_row_height + self.padding_y * 2
    love.graphics.setColor(0, 0, 0, 180)
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

function gui.Instance:draw_general()
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

    love.graphics.setFont(Fonts.monospace[16])

    local save_directory = love.filesystem.getSaveDirectory() .. '/save/projects/' .. Active_Project.name

    local info = {
        "Project: " .. Active_Project.name,
        "Save directory: " .. save_directory
    }

    local x, y = self.main_layout.cell(2)
    self.tab_layout = suit.layout:cols{
        pos = {x + 5, y + 5},
        padding = {padding_x, padding_y},
        min_width = self.width,
        min_height = self.height,

        {self.width, self.height}
    }

    suit.layout:push(self.tab_layout.cell(1))
    for i, text in ipairs(info) do
        suit:Label(text, {align = 'left'}, suit.layout:row(self.width, row_height))
    end

    if suit:Button('Open in file explorer', {align = 'left', font = Fonts.regular[16]}, suit.layout:row(200, 30)).hit then
        love.system.openURL('file://' .. save_directory)
    end

    suit.layout:pop()
end

function gui.Instance:draw_textures()
    love.graphics.setFont(Fonts.monospace[16])

    local row_width = self.width / 6 - 10

    local x, y = self.main_layout.cell(2)
    self.tab_layout = suit.layout:cols{
        pos = {x + 5, y + 5},
        padding = {self.padding_x, self.padding_y},
        min_width = self.width,
        min_height = self.height,

        {row_width, self.height},
        {row_width, self.height},
        {row_width, self.height},
        {row_width, self.height},
        {row_width, self.height},
        {row_width, self.height},
    }

    local num_textures = Lume.count(textures)
    local i = 0
    for name, texture in pairs(textures) do
        i = i + 2
        suit.layout:push(self.tab_layout.cell(i - 1))
        local _, _, cell_w, cell_h = self.tab_layout.cell(i)
        local texture_w, texture_h = texture:getDimensions()
        local aspect_ratio = texture_w / texture_h
        local thumbnail_height = cell_h - self.top_row_height - 60
        local thumbnail_x, thumbnail_y = suit.layout:row(self.row_width, thumbnail_height)
        local thumbnail_width = thumbnail_height * aspect_ratio
        thumbnail_width = math.min(row_width, thumbnail_width)
        table.insert(self.textures_to_draw, {
            texture = textures[name],
            x = thumbnail_x + (row_width - thumbnail_width)/2,
            y = thumbnail_y,
            rotation = 0,
            scale_x = thumbnail_width / texture_w,
            scale_y = thumbnail_height / texture_h,
        })
        local filter = texture:getFilter()
        local wrap_x, wrap_y = texture:getWrap()
        suit.layout:push(self.tab_layout.cell(i))
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

    love.graphics.setFont(Fonts.monospace[16])

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

    local x, y = self.main_layout.cell(2)
    self.tab_layout = suit.layout:cols{
        pos = {x + 5, y + 5},
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
