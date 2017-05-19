local hotswap = {
    timer = 0,
    hooks = {},
    last_modified = {},
}

function hotswap.hook(path, fn)
    if not hotswap.hooks[path] then
        hotswap.hooks[path] = {}
    end

    table.insert(hotswap.hooks[path], fn)

    if not hotswap.last_modified[path] then
        hotswap.last_modified[path] = love.filesystem.getLastModified(path)
    end
end

function hotswap.update(dt)
    hotswap.timer = hotswap.timer + dt

    if hotswap.timer > config.file_hotswap_interval then
        hotswap.timer = hotswap.timer - config.file_hotswap_interval

        -- Scan for file changes
        for filepath, hooks in pairs(hotswap.hooks) do
            local last_modified = love.filesystem.getLastModified(filepath)

            if not hotswap.last_modified[filepath] then
                hotswap.last_modified[filepath] = love.filesystem.getLastModified(filepath)
            end

            -- Has the file changed?
            if last_modified and last_modified > hotswap.last_modified[filepath] then
                print('File changed: ' .. filepath)
                for i, fn in ipairs(hooks) do
                    fn(filepath)
                end
            end

            hotswap.last_modified[filepath] = last_modified
        end
    end
end

return hotswap
