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
    local w, h = 350, 160
    nk.stylePush({
        font = self.font_header
    })
    if nk.windowBegin('Performance', love.graphics.getWidth() - w - 10, love.graphics.getHeight() - h - 10, w, h, 'title', 'movable', 'minimizable', 'scalable', 'scrollbar', 'scroll auto hide') then
        nk.stylePop()
        nk.layoutRow('dynamic', 15, 2)
        nk.label(info.fps)
        nk.label(info.delta)
        nk.layoutRow('dynamic', 15, 2)
        nk.label(info.ram)
        nk.label(info.vram)
        nk.layoutRow('dynamic', 15, 1)
        nk.label(info.draw_calls)
        nk.layoutRow('dynamic', 15, 2)
        nk.label(info.canvases)
        nk.label(info.canvas_switches)
        nk.layoutRow('dynamic', 15, 1)
        nk.label(info.images)
        nk.layoutRow('dynamic', 15, 1)
        nk.label(info.shader_switches)
    else
        nk.stylePop()
    end
    nk.windowEnd()
end

function gui.Instance:draw_uniforms()
    local nk = Nuklear
    local w, h = 350, 400
    nk.stylePush({
        font = self.font_header
    })
    if nk.windowBegin('Shader Uniforms', love.graphics.getWidth() - w - 10, 10, w, h, 'title', 'movable', 'scalable', 'minimizable', 'scrollbar', 'scroll auto hide') then
        nk.stylePop()

        for filename, uniforms in pairs(shader_uniforms) do
            if nk.treePush('tab', filename) then
                for uniform_name, value in pairs(uniforms) do
                    local vartype, components, arrayelements = shaders[filename]:getExternVariable(uniform_name)
                    local sub_components = 1
                    local type_string = "unused"
                    if type(value[1]) == "table" then
                        if type(value[1][1]) == "table" then
                            -- matrix
                            sub_components = #value[1]
                        end
                    end

                    -- @Hack Love doesn't internally what you would expect as the
                    -- variable type, so I'm transforming them again into what
                    -- it should return
                    if vartype == "float" then
                        if sub_components > 1 then
                            -- matrix
                            type_string = "mat" .. sub_components
                            vartype = "matrix"
                        elseif sub_components == 1 then
                            -- vector or float
                            if components > 1 then
                                -- vecN
                                type_string = "vec" .. components
                                vartype = "vector"
                            elseif components == 1 then
                                -- float
                                type_string = "float"
                            end
                        end
                    elseif vartype == "int" then
                        type_string = "int"
                    elseif vartype == "bool" then
                        type_string = "bool"
                    elseif vartype == "image" then
                        type_string = "image"
                    elseif vartype == "matrix" then
                        type_string = "matrix"
                    elseif vartype == "unknown" then
                        type_string = "unknown"
                    elseif vartype == nil then
                        -- unused
                    end

                    if vartype then
                        if arrayelements > 1 then
                            type_string = type_string .. '['..arrayelements..']'
                        end
                    end

                    local doPop = false
                    if nk.treePush('tab', uniform_name .. ' : ' .. type_string) then
                        doPop = true

                        if vartype == "float" then
                            local value = value[1]
                            nk.label(tostring(value))
                        elseif vartype == "int" then
                            local value = value[1]
                            nk.label(tostring(value))
                        elseif vartype == "bool" then
                            local value = value[1]
                            nk.label(tostring(value))
                        elseif vartype == "image" then
                            local image = unpack(value)
                            love.graphics.push("all")
                            local x, y, w, h = nk.widgetBounds()
                            love.graphics.setColor(255, 255, 255)
                            nk.image(image, x, y, image:getWidth(), image:getHeight())
                            nk.layoutRow('dynamic', image:getHeight(), 1)
                            love.graphics.pop()
                        elseif vartype == "matrix" then
                            local matrix = unpack(value)
                            local cols = sub_components
                            local rows = sub_components
                            for row=1, rows do
                                nk.layoutRow('dynamic', 20, cols)
                                for col=1, cols do
                                    nk.label(tostring(matrix[row][col]))
                                end
                            end
                        -- @Hack
                        elseif vartype == "vector" then
                            local vector = unpack(value)
                            for i, v in ipairs(vector) do
                                nk.layoutRow('dynamic', 20, 2)
                                nk.label('['..tostring(i)..']')
                                nk.label(tostring(v))
                            end
                        elseif vartype == "unknown" then
                            nk.label('Unknown type')
                        elseif vartype == nil then
                        end
                    end

                    if doPop then
                        nk.treePop()
                    end
                end
                nk.treePop()
            end
        end
    else
        nk.stylePop()
    end
    nk.windowEnd()
end

return gui
