function love.load()
    shaders.color:send('window_width', love.graphics.getWidth())
    shaders.color:send('window_height', love.graphics.getHeight())
    shaders.color:send('vars', 1, 1)
end

function love.update(dt)
    shaders.color:send('vars', math.sin(love.timer.getTime()), math.cos(love.timer.getTime()))
end

function love.draw()
    love.graphics.setShader(shaders.color)
    love.graphics.setColor(255, 255, 255)
    love.graphics.rectangle('fill', 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    love.graphics.setShader()
end
