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

function hotswap:update_file_info(filepath)
    if love.filesystem.exists(filepath) then
        self.last_modified[filepath] = love.filesystem.getLastModified(filepath)
        self.hashes[filepath] = xxhash(love.filesystem.read(filepath))
    end
end

function hotswap:on_file_changed(filepath)
    print('File changed: ' .. filepath)
    for i, fn in ipairs(self.hooks[filepath]) do
        fn(filepath)
    end
    self:update_file_info(filepath)
end

function hotswap:check_file_modified()
    -- Scan for file changes
    for filepath, hooks in pairs(self.hooks) do
        if love.filesystem.exists(filepath) then
            local changed = false

            local last_modified = love.filesystem.getLastModified(filepath)

            if last_modified and last_modified > self.last_modified[filepath] then
                changed = true
            end

            if changed then
                self:on_file_changed(filepath)
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
            end

            if changed then
                self:on_file_changed(filepath)
            end
        end
    end
end

function hotswap:update(dt)
    self.timer:update(dt)
end

return hotswap
