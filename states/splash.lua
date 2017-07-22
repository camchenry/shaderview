local splash = {}

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

function splash:enter()
    self.project_list = love.filesystem.getDirectoryItems('save/projects')
    self.selected_project = ""
    self.switch_to_game = false

    self.font_header = Fonts.default[18]
    self.style = {
        font = Fonts.default[16],
        text = {
            color = '#eeeeee'
        },
    }

    self.show_new_project_popup = false
    self.new_project_name_field = {
        value = ''
    }
end

function splash:create_new_project(name)
    copy_directory('templates/new_project', 'save/projects', name)
end

function splash:update(dt)
    if self.switch_to_game and self.selected_project then
        State.switch(States.game, self.selected_project)
        return
    end
    local nk = Nuklear
    nk.frameBegin()
    nk.stylePush(self.style)

    local w, h = 300, love.graphics.getHeight() - 300
    nk.stylePush{font = self.font_header}
    if nk.windowBegin('Projects', 70, 140, w, h, 'title', 'scrollbar') then
        nk.stylePop()
        nk.layoutRow('dynamic', 30, 1)
        if nk.button('New project') then
            self.show_new_project_popup = true
        end
        for i, project in ipairs(self.project_list) do
            nk.layoutRow('dynamic', 25, {0.75, 0.25})
            if nk.selectable(project, self.selected_project == project) then
                self.selected_project = project

                if self.selected_project and nk.button('Open') then
                    self.switch_to_game = true
                end
            end
        end

        if self.show_new_project_popup then
            local w, h = 300, 200
            local x = love.graphics.getWidth()/2 - w/2
            local y = love.graphics.getHeight()/2 - h/2
            x, y = nk.layoutSpaceToLocal(x, y)
            if nk.popupBegin('dynamic', 'New project', x, y, w, h, 'title', 'closable') then
                nk.layoutRow('dynamic', 20, 1)
                nk.label('Name')
                nk.layoutRow('dynamic', 30, 1)
                nk.edit('field', self.new_project_name_field)
                nk.spacing(1)
                if nk.button('OK') and self.new_project_name_field.value ~= '' then
                    self:create_new_project(self.new_project_name_field.value)
                    self.show_new_project_popup = false
                    self.new_project_name_field.value = ''
                    nk.popupClose()
                    self.project_list = love.filesystem.getDirectoryItems('save/projects')
                end
            else
                self.show_new_project_popup = false
            end
            nk.popupEnd()
        end
    else
        nk.stylePop()
    end
    nk.windowEnd()

    nk.stylePop()
    nk.frameEnd()
end

function splash:draw()
    love.graphics.setBackgroundColor(22, 22, 22)

    local x, y = 70, 70
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
end

-- set stub functions for any unused handlers
for handler, fn in pairs(love.handlers) do
    if not splash[handler] then
        splash[handler] = function(...) end
    end
end

return splash
