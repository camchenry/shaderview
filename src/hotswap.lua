local hotswap = {
    timer = 0,
    interval = 0,
    hooks = {},
    last_modified = {},
}

function hotswap:load_config_data(config)
    self.interval = config.file_hotswap_interval
end

function hotswap:hook(filepath, fn)
    if not self.hooks[filepath] then
        self.hooks[filepath] = {}
    end

    table.insert(self.hooks[filepath], fn)

    if not self.last_modified[filepath] then
        self.last_modified[filepath] = love.filesystem.getLastModified(filepath)
    end
end

function hotswap:update(dt)
    self.timer = self.timer + dt

    if self.timer > self.interval then
        self.timer = self.timer - self.interval

        -- Scan for file changes
        for filepath, hooks in pairs(self.hooks) do
            local last_modified = love.filesystem.getLastModified(filepath)

            if not self.last_modified[filepath] then
                self.last_modified[filepath] = love.filesystem.getLastModified(filepath)
            end

            -- Has the file changed?
            if last_modified and last_modified > self.last_modified[filepath] then
                print('File changed: ' .. filepath)
                for i, fn in ipairs(hooks) do
                    fn(filepath)
                end
            end

            self.last_modified[filepath] = last_modified
        end
    end
end

return hotswap
