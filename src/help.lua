local help = {}

local function print_with_shadow(text, x, y, r, sx, sy, ox, oy, skx, sky)
    local shadow_size = 2

    love.graphics.setColor(0, 0, 0)
    love.graphics.print(text, x + shadow_size, y + shadow_size, sx, sy, ox, oy, skx, sky)

    love.graphics.setColor(255, 255, 255)
    love.graphics.print(text, x, y, sx, sy, ox, oy, skx, sky)
end

local function printf_with_shadow(text, x, y, width, align, ...)
    local shadow_size = 2

    love.graphics.setColor(0, 0, 0)
    love.graphics.printf(text, x + shadow_size, y + shadow_size, width, align)

    love.graphics.setColor(255, 255, 255)
    love.graphics.printf(text, x, y, width, align)
end

help.Panel = Class{
    init = function(self, props)
        self.padding = love.graphics.getWidth() * 0.05
        self.visible = true
        self.visible_toggle_key = 'escape'
        props = props or {}
        for k, v in pairs(props) do
            self[k] = v
        end

        Keybinds[self.visible_toggle_key] = "Toggle help menu"
        self.input = Input()
        self.input:bind(self.visible_toggle_key, function()
            self.visible = not self.visible
        end)

        self.save_directory = love.filesystem.getSaveDirectory()
        self.save_directory = self.save_directory .. '/save'

        self.width = love.graphics.getWidth()
        self.height = love.graphics.getHeight()

        self.width_inner = self.width - self.padding*2
        self.height_inner = self.height - self.padding*2
    end,

    update = function(self, dt)
        self.width = love.graphics.getWidth()
        self.height = love.graphics.getHeight()

        self.width_inner = self.width - self.padding*2
        self.height_inner = self.height - self.padding*2
    end,

    draw = function(self)
        if self.visible then
            love.graphics.push()
            love.graphics.setColor(0, 0, 0, 160)
            local x = (love.graphics.getWidth() - self.width)/2
            local y = (love.graphics.getHeight() - self.height)/2
            love.graphics.rectangle('fill', x, y, self.width, self.height)

            love.graphics.translate(self.padding, self.padding)
            love.graphics.setColor(255, 255, 255)

            local title_text = 'Shaderview'
            local title_font = Fonts.bold[40]
            local title_baseline = y + title_font:getBaseline()
            love.graphics.setFont(title_font)
            print_with_shadow(title_text, x, y)

            local version_font = Fonts.light[18]
            local version_x = x + title_font:getWidth(title_text) + 15
            local version_y = title_baseline - version_font:getBaseline()
            love.graphics.setFont(version_font)
            print_with_shadow(Shaderview.version, version_x, version_y)

            y = y + title_font:getHeight()

            local regular_font = Fonts.regular[20]
            local monospace_font = Fonts.monospace[20]
            love.graphics.setFont(regular_font)

            y = y + 20

            print_with_shadow('Project: ' .. Active_Project.name, x, y)
            y = y + regular_font:getHeight()

            local text = 'Save directory: '
            local text_width = regular_font:getWidth(text)
            print_with_shadow(text, x, y)
            love.graphics.setFont(monospace_font)
            print_with_shadow(self.save_directory .. '/' .. Active_Project.name, x + text_width, y)
            y = y + 20

            for key, description in pairs(Keybinds) do
                love.graphics.setFont(regular_font)
                y = y + regular_font:getHeight()
                printf_with_shadow(description, x, y, self.width_inner/2, "left")
                love.graphics.setFont(monospace_font)
                printf_with_shadow(string.upper(key), x, y, self.width_inner/2, "right")
            end

            y = y + 50

            love.graphics.setFont(Fonts.bold[20])
            print_with_shadow('Press ' .. string.upper(self.visible_toggle_key) .. ' to close this menu', x, y)

            love.graphics.pop()
        end
    end,
}

return help
