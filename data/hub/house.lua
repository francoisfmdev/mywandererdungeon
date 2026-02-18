-- data/hub/house.lua
return {
  background = "house_room",
  buttons = {
    { label = "hub.house.inventory_equipment", action = "scene:push:hub.inventory" },
    { label = "hub.house.view_character", action = "scene:push:hub.character" },
    { label = "hub.house.view_stats", action = "scene:push:hub.stats" },
    { label = "hub.back", action = "scene:pop" },
  },
}
