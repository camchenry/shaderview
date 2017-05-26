local notification = {}

local function get_color_opacity(color, opacity)
    local r, g, b, a = unpack(color)
    return r, g, b, a * opacity
end

notification.Notification = Class{
    init = function(self, props)
        self.text = ""
        self.duration = 2
        self.x = 5
        self.y = 5
        self.dead = false
        self.foreground = {255, 255, 255, 255}
        self.background = {0, 0, 0, 160}
        self.shadow = {0, 0, 0, 255}
        self.opacity = 0
        self.shadow_size = 1
        self.width = nil
        self.height = nil
        self.padding = 5
        self.font = Fonts.default[16]
        self.align = "left"

        self.fade_time_in = 0.15
        self.fade_time_out = 0.15

        props = props or {}
        for k, v in pairs(props) do
            self[k] = v
        end

        if not self.width then
            self.width = self.font:getWidth(self.text)
        end

        if not self.height then
            self.height = self.font:getHeight()
        end

        self.life = self.duration
        self.timer = Timer.new()
        self.timer:script(function(wait)
            self.timer:tween(self.fade_time_in, self, {opacity = 1})
            wait(self.life - self.fade_time_out)
            self.timer:tween(self.fade_time_in, self, {opacity = 0})
        end)
    end,

    update = function(self, dt)
        self.life = self.life - dt

        self.timer:update(dt)

        if self.life < 0 then
            self.dead = true
        end
    end,

    draw = function(self)
        if not self.dead then
            love.graphics.setColor(get_color_opacity(self.background, self.opacity))
            love.graphics.rectangle('fill', self.x, self.y, self.width+self.padding*2, self.height+self.padding*2)
            love.graphics.setFont(self.font)
            local w = self.font:getWidth(self.text) + self.padding*2
            local h = self.font:getHeight() + self.padding*2
            local x = self.x + self.padding
            local y = self.y + self.padding
            love.graphics.setColor(get_color_opacity(self.shadow, self.opacity))
            love.graphics.printf(self.text, x + self.shadow_size, y + self.shadow_size, self.width, self.align)
            love.graphics.setColor(get_color_opacity(self.foreground, self.opacity))
            love.graphics.printf(self.text, x, y, self.width, self.align)
        end
    end,
}

notification.Queue = Class{
    init = function(self, props)
        props = props or {}
        for k, v in pairs(props) do
            self[k] = v
        end

        self.notifications = {}
    end,

    add = function(self, notification)
        table.insert(self.notifications, notification)

        if not self.current_notification then
            self.current_notification = notification
        end
    end,

    update = function(self, dt)
        if self.current_notification and self.current_notification.dead then
            table.remove(self.notifications, 1)
            self.current_notification = self.notifications[1]
        end

        if self.current_notification then
            self.current_notification:update(dt)
        end
    end,

    draw = function(self)
        if self.current_notification then
            self.current_notification:draw()
        end
    end,
}

return notification
