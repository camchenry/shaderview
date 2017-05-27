shaderview
----------

A shader viewer tool for the LÖVE game framework.

# How to use

You can write your app code and shaders inside of the `app` folder. Shaders
inside of the `app/shaders` folder are automatically loaded into the `shaders`
global table (for now). When you update either the `main.lua` file or any
shader files, they will be reloaded automatically.

# Configuration

The default configuration file is `config/default.lua` and the user
configuration is `user_config.lua` in the local save directory. The location of
your save directory can be found using [love.filesystem.getSaveDirectory](https://love2d.org/wiki/love.filesystem.getSaveDirectory).
