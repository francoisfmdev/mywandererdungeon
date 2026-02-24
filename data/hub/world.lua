-- data/hub/world.lua - Carte monde, choix donjons
return {
  title_key = "hub.world.title",
  hint_key = "hub.menu_hint",
  background = "hub_room",
  buttons = {
    { label = "hub.world.ruins", action = "scene:push:dungeon_run" },
    { label = "hub.world.back", action = "scene:pop" },
  },
}
