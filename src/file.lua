local file = {}

function file.get_basename(path)
    return path:gsub("(.*/)(.*)", "%2")
end

function file.remove_extension(filename)
    return (filename:gsub('%..-$', ''))
end

return file
