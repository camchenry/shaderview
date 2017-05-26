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
        props = props or {}
        for k, v in pairs(props) do
            self[k] = v
        end

        Keybinds['f1'] = "Toggle help menu"
        self.input = Input()
        self.input:bind('f1', function()
            self.visible = not self.visible
        end)
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

            local title_text = Shaderview._NAME
            local title_font = Fonts.bold[40]
            local title_baseline = y + title_font:getBaseline()
            love.graphics.setFont(title_font)
            print_with_shadow(title_text, x, y)

            local version_font = Fonts.light[18]
            local version_x = x + title_font:getWidth(title_text) + 15
            local version_y = title_baseline - version_font:getBaseline()
            love.graphics.setFont(version_font)
            print_with_shadow(Shaderview._VERSION, version_x, version_y)

            y = y + title_font:getHeight()

            for key, description in pairs(Keybinds) do
                love.graphics.setFont(Fonts.regular[20])
                y = y + love.graphics.getFont():getHeight()
                printf_with_shadow(description, x, y, self.width_inner/2, "left")
                love.graphics.setFont(Fonts.monospace[20])
                printf_with_shadow(string.upper(key), x, y, self.width_inner/2, "right")
            end

            love.graphics.pop()
        end
    end,
}

return help
