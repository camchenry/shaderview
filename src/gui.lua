local gui = {}

gui.Instance = Class{}

function gui.Instance:init(props)
    self.style = {}
    self.font_header = Fonts.default[16]

    if props then
        for k, v in pairs(props) do
            self[k] = v
        end
    end
end

function gui.Instance:update(dt)
    local nk = Nuklear
    nk.frameBegin()
    nk.stylePush(self.style)

    self:draw_performance()
    self:draw_uniforms()

    nk.stylePop()
    nk.frameEnd()
end

function gui.Instance:draw_performance()
    local nk = Nuklear
    local x, y = CONFIG.debug.stats.position.x, CONFIG.debug.stats.position.y
    local dy = CONFIG.debug.stats.lineHeight
    local stats = love.graphics.getStats()
    local unit = "KB"
    local ram = collectgarbage("count")
    local vram = stats.texturememory / 1024
    if not CONFIG.debug.stats.kilobytes then
        ram = ram / 1024
        vram = vram / 1024
        unit = "MB"
    end
    local info = {
        fps = "FPS: " .. ("%3d"):format(love.timer.getFPS()),
        delta = ("ΔT %.3fms"):format(love.timer.getAverageDelta() * 1000),
        ram = ("RAM: %.2f%s"):format(ram, unit),
        vram = ("VRAM: %.2f%s"):format(vram, unit),
        draw_calls = "Draws: " .. stats.drawcalls,
        canvases = "Canvases: " .. stats.canvases,
        canvas_switches = "Switches: " .. stats.canvasswitches,
        images = "Images: " .. stats.images,
        shader_switches = "Shader switches: " .. stats.shaderswitches,
    }
    local w, h = 350, 200
    nk.stylePush({
        font = self.font_header
    })
    if nk.windowBegin('Performance', love.graphics.getWidth() - w - 20, love.graphics.getHeight() - h - 20, w, h, 'title', 'movable', 'minimizable') then
        nk.stylePop()
        nk.layoutRow('dynamic', 20, 2)
        nk.label(info.fps)
        nk.label(info.delta)
        nk.layoutRow('dynamic', 20, 2)
        nk.label(info.ram)
        nk.label(info.vram)
        nk.layoutRow('dynamic', 20, 1)
        nk.label(info.draw_calls)
        nk.layoutRow('dynamic', 20, 2)
        nk.label(info.canvases)
        nk.label(info.canvas_switches)
        nk.layoutRow('dynamic', 20, 1)
        nk.label(info.images)
        nk.layoutRow('dynamic', 20, 1)
        nk.label(info.shader_switches)
    else
        nk.stylePop()
    end
    nk.windowEnd()
end

local function uniform_tree_create(vars)
    local nk = Nuklear
    for key, value in pairs(vars) do
        value = value[1]
        if type(value) == "string" or type(value) == "number" then
            nk.layoutRow('dynamic', 30, {0.4, 0.6})
            nk.label(key)
            nk.edit('simple', {value=Inspect(value)})
        elseif type(value) == "table" then
            local table = value[1]
            if nk.treePush('node', key) then
                for key, value in pairs(value) do
                    nk.layoutRow('dynamic', 30, {0.4, 0.6})
                    nk.label(key)
                    nk.edit('simple', {value=Inspect(value)})
                end
                nk.treePop()
            end
        end
    end
end

function gui.Instance:draw_uniforms()
    local nk = Nuklear
    local w, h = 350, 400
    nk.stylePush({
        font = self.font_header
    })
    if nk.windowBegin('Shader Uniforms', love.graphics.getWidth() - w - 20, love.graphics.getHeight() - h - 240, w, h, 'title', 'movable', 'minimizable') then
        nk.stylePop()

        for filename, vars in pairs(shader_uniforms) do
            if nk.treePush('tab', filename) then
                uniform_tree_create(vars)
                nk.treePop()
            end
        end
    else
        nk.stylePop()
    end
    nk.windowEnd()
end

return gui
