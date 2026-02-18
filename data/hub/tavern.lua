-- data/hub/tavern.lua
return {
  background = "tavern_room",
  buttons = {
    { label = "hub.tavern.quests", action = "hub.tavern:quests" },
    { label = "hub.tavern.rumors", action = "hub.tavern:rumors" },
    { label = "hub.back", action = "scene:pop" },
  },
}
