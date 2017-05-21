local app = {}

function app:load()
    self.timer = 0
    self.frame = 0

    local w, h = love.graphics.getDimensions()
    shaders.shadertoy:send('iResolution', {w, h, 0})
end

function app:update(dt)
    self.timer = self.timer + dt
    self.frame = self.frame + 1

    shaders.shadertoy:send('iGlobalTime', self.timer)
    local mx, my = love.mouse.getPosition()
    shaders.shadertoy:send('iMouse', {mx, my, 0, 0})
end

function app:draw()
    love.graphics.setShader(shaders.shadertoy)
    love.graphics.setColor(255, 255, 255)
    love.graphics.rectangle('fill', 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    love.graphics.setShader()
end

return app
