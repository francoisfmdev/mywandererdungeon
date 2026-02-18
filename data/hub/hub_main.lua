-- data/hub/hub_main.lua
return {
  background = "hub_room",
  hint_key = "hub.log_hint",
  buttons = {
    { label = "hub.main.shop", action = "scene:push:hub.shop" },
    { label = "hub.main.tavern", action = "scene:push:hub.tavern" },
    { label = "hub.main.bank", action = "scene:push:hub.bank" },
    { label = "hub.main.house", action = "scene:push:hub.house" },
    { label = "hub.main.leave", action = "scene:push:world" },
  },
}
