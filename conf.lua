-- conf.lua - Configuration Love2D
function love.conf(t)
  t.identity = "thewanderereternal"
  t.console = false  -- Evite la fenetre console qui s'affiche brievement sous Windows
  t.window.title = "The Wanderer Eternal"
  t.window.width = 800
  t.window.height = 600
end
