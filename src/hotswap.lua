local hotswap = {
    timer = 0,
    interval = 0,
    hooks = {},
    last_modified = {},
    hashes = {},
    timer = Timer.new(),
}

function hotswap:load_config_data(config)
    if self.modifiedTimer then
        self.timer:cancel(self.modifiedTimer)
    end
    self.modifiedInterval = config.file_hotswap_modified_interval
    self.modifiedTimer = self.timer:every(self.modifiedInterval, function()
        self:check_file_modified()
    end)

    if self.hashTimer then
        self.timer:cancel(self.hashTimer)
    end
    self.hashInterval = config.file_hotswap_hash_interval
    self.hashTimer = self.timer:every(self.hashInterval, function()
        self:check_file_hashes()
    end)
end

function hotswap:hook(filepath, fn)
    if not self.hooks[filepath] then
        self.hooks[filepath] = {}
    end

    table.insert(self.hooks[filepath], fn)

    if not self.last_modified[filepath] then
        self.last_modified[filepath] = love.filesystem.getLastModified(filepath)
    end

    local hash = xxhash(love.filesystem.read(filepath))

    if not self.hashes[filepath] then
        self.hashes[filepath] = hash
    end
end

function hotswap:check_file_modified()
    -- Scan for file changes
    for filepath, hooks in pairs(self.hooks) do
        if love.filesystem.exists(filepath) then
            local changed = false

            local last_modified = love.filesystem.getLastModified(filepath)

            if last_modified and last_modified > self.last_modified[filepath] then
                changed = true
                self.last_modified[filepath] = last_modified
            end

            if changed then
                print('File changed: ' .. filepath)
                for i, fn in ipairs(hooks) do
                    fn(filepath)
                end
            end
        end
    end
end

function hotswap:check_file_hashes()
    -- Scan for file changes
    for filepath, hooks in pairs(self.hooks) do
        if love.filesystem.exists(filepath) then
            local changed = false
            local contents, bytes = love.filesystem.read(filepath)
            local new_hash = xxhash(contents)

            if new_hash ~= self.hashes[filepath] then
                changed = true
                self.hashes[filepath] = new_hash
            end

            if changed then
                print('File changed: ' .. filepath)
                for i, fn in ipairs(hooks) do
                    fn(filepath)
                end
            end
        end
    end
end

function hotswap:update(dt)
    self.timer:update(dt)
end

return hotswap
