-- main.lua - Bootstrap Love2D
local app, platform

function love.load()
  package.path = package.path .. ";?.lua;?/init.lua;"
  platform = require("platform.love")
  app = require("core.app")
  if not app.init(platform) then
    error("App init failed")
  end
end

function love.update(dt)
  if app then app.update(dt) end
end

function love.draw()
  if app then app.draw() end
end

function love.keypressed(key, scancode, isrepeat)
  if platform then platform.keypressed(key, scancode, isrepeat) end
end

function love.keyreleased(key, scancode)
  if platform then platform.keyreleased(key, scancode) end
end

function love.mousepressed(x, y, button, istouch, presses)
  if platform and platform.mousepressed then platform.mousepressed(x, y, button) end
end

function love.wheelmoved(x, y)
  local input = require("core.input")
  if input and input.inject_wheel and y ~= 0 then
    input.inject_wheel(y)
  end
end
