-- Write your own app code here!
local app = {}

function app:load()

end

function app:update(dt)

end

function app:resize(w, h)

end

function app:draw()
    love.graphics.clear(love.graphics.getBackgroundColor())
    love.graphics.setBlendMode("alpha", "premultiplied")
    love.graphics.setShader(shaders.default)
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle('fill', 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    love.graphics.setShader()
end

return app
