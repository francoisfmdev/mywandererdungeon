return {
  background = "house_room",
  hint_key = "hub.menu_hint",
  buttons = {
    { label = "hub.house.consumables", action = "scene:push:hub.inventory_consumables" },
    { label = "hub.house.equipment", action = "scene:push:hub.equipment" },
    { label = "hub.house.view_character", action = "scene:push:hub.character" },
    { label = "hub.house.view_stats", action = "scene:push:hub.stats" },
    { label = "hub.back", action = "scene:pop" },
  },
}
