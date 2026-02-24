-- data/hub/hub_main.lua
return {
  background = "hub_room",
  title_key = "hub.title",
  hint_key = "hub.menu_hint",
  buttons = {
    { label = "hub.main.shop", action = "scene:push:hub.shop" },
    { label = "hub.main.tavern", action = "scene:push:hub.tavern" },
    { label = "hub.main.bank", action = "scene:push:hub.bank" },
    { label = "hub.main.house", action = "scene:push:hub.house" },
    { label = "hub.main.leave", action = "scene:push:world" },
  },
}
