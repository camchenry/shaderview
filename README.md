shaderview
==========

A shader viewer tool for the LÖVE game framework.

## How to use

Shaderview creates and loads projects from a save directory, which can be found using [love.filesystem.getSaveDirectory](https://love2d.org/wiki/love.filesystem.getSaveDirectory). In this document, the save directory will be referred to as `save/`.

When you create a project it is placed inside of `save/projects/`. For example, if you make a project called "my_shader" then the associated project folder will be `save/projects/my_shader`. The structure of a project folder looks like this:

* `project/`
  * `app/` 
    * `main.lua`
  * `shaders/`

The `app/main.lua` is the core of your application, where you can send variables to shaders, create canvases, and set the active shader. It is much like a normal LÖVE main.lua file, except it defines functions in a module rather than in the global table. The normal LÖVE callbacks can be easily translated to this format. For example, `love.keypressed` becomes `app:keypressed`, `love.update` becomes `app:update` and so on. The arguments remain the same and are simply passed into your application code as they would be normally. When this file changes, it will be reloaded automatically.

The `shaders/` directory is where you place all of your shader files. Shaders inside of this directory will be loaded into a global table called `shaders` where the key is the name of the file (without the extension) and the value is the created Shader. For example, `shaders/my_shader.frag` becomes `shaders.my_shader` or `shaders['my_shader']`. Whenever you change a shader, it will be reloaded automatically.

## Configuration

The default configuration file for Shaderview is `save/config/default.lua` and the user configuration file is `save/config/user.lua`. The user configuration file will overwrite any properties set in the default file. When either the default or user configuration is modified, it will be reloaded.