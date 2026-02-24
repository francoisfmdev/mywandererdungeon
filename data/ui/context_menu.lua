-- data/ui/context_menu.lua - Menu contextuel donjon integre (style Shiren/PMD)
return {
  items = {
    { label = "ui.context.attack", action = "player:attack" },
    { label = "ui.context.observer", action = "player:observer" },
    { label = "ui.context.character", action = "scene:push:hub.character" },
    { label = "ui.context.consumables", action = "player:consumables" },
    { label = "ui.context.equipment", action = "player:equipment" },
    { label = "ui.context.wait", action = "player:wait" },
  },
  layout = {
    position = "bottom",
    orientation = "horizontal",
    line_height = 32,
    padding = 12,
  },
}
