local hotswap = {
    hooks = {},
}

function hotswap:hook(filepath, fn)
    if not self.hooks[filepath] then
        self.hooks[filepath] = {}
    end

    table.insert(self.hooks[filepath], fn)

    local files = {}
    for file, _ in pairs(self.hooks) do
        table.insert(files, file)
    end
    local channel = love.thread.getChannel("channel_filechange_files")
    channel:push(files)
end

function hotswap:on_file_changed(filepath)
    for i, fn in ipairs(self.hooks[filepath]) do
        fn(filepath)
    end
end

return hotswap
