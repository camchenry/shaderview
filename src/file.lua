file_last_modified = {}
file_hotswap_timer = 0
file_hotswap_hooks = {}

function file_hook_on_change(path, fn)
    if not file_hotswap_hooks[path] then
        file_hotswap_hooks[path] = {}
    end

    table.insert(file_hotswap_hooks[path], fn)

    if not file_last_modified[path] then
        file_last_modified[path] = love.filesystem.getLastModified(path)
    end
end

function file_hook_check_changes(dt)
    file_hotswap_timer = file_hotswap_timer + dt

    if file_hotswap_timer > config.file_hotswap_interval then
        file_hotswap_timer = file_hotswap_timer - config.file_hotswap_interval

        -- Scan for file changes
        for filepath, hooks in pairs(file_hotswap_hooks) do
            local last_modified = love.filesystem.getLastModified(filepath)

            -- Has the file changed?
            if last_modified == nil or last_modified > file_last_modified[filepath] then
                print('File changed: ' .. filepath)
                for i, fn in ipairs(hooks) do
                    fn(filepath)
                end
            end

            file_last_modified[filepath] = last_modified
        end
    end
end

function file_get_basename(path)
    return path:gsub("(.*/)(.*)", "%2")
end

function file_remove_extension(filename)
    return (filename:gsub('%..-$', ''))
end

