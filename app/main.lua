-- Write your own app code here!
local app = {}

function app:load()
    self.timer = 0
    self.mouse = {love.mouse.getPosition()}

    shaders.seascape:send('iResolution', {love.graphics.getDimensions()})
end

function app:update(dt)
    self.timer = self.timer + dt

    shaders.seascape:send('iGlobalTime', self.timer)
    self.mouse[1], self.mouse[2] = love.mouse.getPosition()
    shaders.seascape:send('iMouse', self.mouse)
end

function app:resize(w, h)
    shaders.seascape:send('iResolution', {w, h})
end

function app:draw()
    love.graphics.clear(love.graphics.getBackgroundColor())
    love.graphics.setBlendMode("alpha", "premultiplied")
    love.graphics.setShader(shaders.seascape)
    love.graphics.setColor(255, 255, 255)
    love.graphics.rectangle('fill', 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    love.graphics.setShader()
end

return app
