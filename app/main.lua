local app = {}

function app:load()
    self.timer = 0
    self.frame = 0

    self.canvas = love.graphics.newCanvas()

    local w, h = love.graphics.getDimensions()
    shaders.distancefield:send('input_resolution', {w, h, 0})
end

function app:update(dt)
    self.timer = self.timer + dt
    self.frame = self.frame + 1

    shaders.distancefield:send('input_timer', self.timer)
    shaders.distancefield:send('input_mouse', {love.mouse.getPosition()})
    local mx, my = love.mouse.getPosition()
end

function app:draw()
    love.graphics.setCanvas(self.canvas)
    love.graphics.clear(love.graphics.getBackgroundColor())
    love.graphics.setBlendMode("alpha", "premultiplied")
    love.graphics.setShader(shaders.distancefield)
    love.graphics.setColor(255, 255, 255)
    love.graphics.rectangle('fill', 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    love.graphics.setShader()
    love.graphics.setCanvas()

    love.graphics.draw(self.canvas, 0, 0)
end

return app
