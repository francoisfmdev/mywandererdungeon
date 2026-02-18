-- data/ui/pause_menu.lua - Menu pause (data-driven)
return {
  items = {
    { label = "ui.pause.resume", action = "scene:pop" },
    { label = "ui.pause.save", action = "pause:save" },
    { label = "ui.pause.options", action = "scene:push:options" },
    { label = "ui.pause.quit_to_hub", action = "pause:quit_to_hub" },
    { label = "ui.pause.quit_game", action = "quit:" },
  },
  layout = {
    box_width = 280,
    line_height = 40,
  },
}
