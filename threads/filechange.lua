require 'love.timer'

local xxhash = require 'libs.xxhash'

local channel_filechange = love.thread.getChannel(select(1, ...))
local channel_config     = love.thread.getChannel(select(2, ...))
local channel_files      = love.thread.getChannel(select(3, ...))

local config = channel_config:demand()

local time_start = love.timer.getTime()
local current_time

local files = {}

local interval_modified = 1
local timer_modified = 0
local last_modified = {}

local interval_hash = 1
local timer_hash = 0
local hashes = {}

local function config_load(config)
    interval_modified = config.file_hotswap_modified_interval
    interval_hash = config.file_hotswap_hash_interval
end

local function update_file_info(filepath)
    if love.filesystem.exists(filepath) then
        last_modified[filepath] = love.filesystem.getLastModified(filepath)
        hashes[filepath] = xxhash(love.filesystem.read(filepath))
    end
end

local function check_file_modified()
    -- Scan for file changes
    for i, filepath in ipairs(files) do
        if love.filesystem.exists(filepath) then
            local changed = false

            local lastmod = love.filesystem.getLastModified(filepath)

            if not last_modified[filepath] then
                last_modified[filepath] = lastmod
            end

            if lastmod and lastmod > last_modified[filepath] then
                changed = true
            end

            if changed then
                update_file_info(filepath)
                channel_filechange:push(filepath)
            end
        end
    end
end

local function check_file_hashes()
    -- Scan for file changes
    for i, filepath in ipairs(files) do
        if love.filesystem.exists(filepath) then
            local changed = false
            local contents, bytes = love.filesystem.read(filepath)
            local hash = xxhash(contents)

            if not hashes[filepath] then
                hashes[filepath] = hash
            end

            if hash ~= hashes[filepath] then
                changed = true
            end

            if changed then
                update_file_info(filepath)
                channel_filechange:push(filepath)
            end
        end
    end
end

config_load(config)

while 1 do
    current_time = love.timer.getTime()
    local elapsed = current_time - time_start

    if timer_hash < elapsed then
        timer_hash = timer_hash + interval_hash
        check_file_hashes()
    end

    if timer_modified < elapsed then
        timer_modified = timer_modified + interval_modified
        --print('Checking file modified')
        check_file_modified()
    end

    if channel_config:peek() then
        local config = channel_config:pop()
        config_load(config)
    end

    if channel_files:peek() then
        local t = channel_files:pop()
        files = t
    end
end
