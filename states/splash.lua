local suit = Suit.new()

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

    self.new_project_name_state = {
        text = ''
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

    local x = 70
    local y = 140
    local padding_x = 10
    local padding_y = 10
    local row_width = love.graphics.getWidth() * 0.3
    local row_height = love.graphics.getHeight() * 0.03

    suit.layout:reset(x, y, padding_x, padding_y)

    love.graphics.setFont(Fonts.bold[24])
    suit.layout:push(suit.layout:col(row_width, row_height))
    suit:Label('Projects', {align = 'left'}, suit.layout:row(row_width, row_height))

    for i, project in ipairs(self.project_list) do
        love.graphics.setFont(Fonts.regular[16])
        if suit:Button(project, {align = 'left', cornerRadius = 6}, suit.layout:row()).hit then
            self.selected_project = project
            self.switch_to_game = true
        end
    end
    suit.layout:pop()

    suit.layout:push(suit.layout:col(row_width, row_height))
    love.graphics.setFont(Fonts.bold[24])
    suit:Label('Create new project', {align = 'left'}, suit.layout:col(row_width, row_height))

    love.graphics.setFont(Fonts.regular[16])
    suit:Input(self.new_project_name_state, {align = 'left'}, suit.layout:row())
    if self.new_project_name_state.text ~= '' then
        if suit:Button('Create project', {align = 'center', cornerRadius = 6}, suit.layout:row()).hit then
            self:create_new_project(self.new_project_name_state.text)
            self.project_list = love.filesystem.getDirectoryItems('save/projects')
            self.new_project_name_state.text = ''
        end
    end
    suit.layout:pop()
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

    love.graphics.setColor(255, 255, 255)
    suit:draw()
end

function splash:keypressed(key, code, isRepeat)
    suit:keypressed(key, code, isRepeat)
end

function splash:textinput(text)
    suit:textinput(text)
end

return splash
