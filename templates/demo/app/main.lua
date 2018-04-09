-- Write your own app code here!
local app = {}

function app:load()
    self.timer = 0
    self.mouse = {love.mouse.getPosition()}

    shaders.seascape:send('iResolution', {love.graphics.getDimensions()})

    shaders.seascape:send('NUM_STEPS', 8)
    shaders.seascape:send('ITER_GEOMETRY', 3)
    shaders.seascape:send('ITER_FRAGMENT', 5)
    shaders.seascape:send('SEA_HEIGHT', 0.6)
    shaders.seascape:send('SEA_CHOPPY', 4.0)
    shaders.seascape:send('SEA_SPEED', 0.8)
    shaders.seascape:send('SEA_FREQ', 0.16)
    shaders.seascape:send('SEA_BASE', {0.1, 0.19, 0.22})
    shaders.seascape:send('SEA_WATER_COLOR', {0.8, 0.9, 0.6})
    shaders.seascape:send('octave_m', {
        {1.6, -1.2},
        {1.2, 1.6},
    })
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
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle('fill', 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    love.graphics.setShader()
end

return app
