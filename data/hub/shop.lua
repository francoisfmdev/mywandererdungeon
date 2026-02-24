-- data/hub/shop.lua
return {
  background = "shop_room",
  hint_key = "hub.menu_hint",
  buttons = {
    { label = "hub.shop.buy", action = "hub.shop:buy" },
    { label = "hub.shop.sell", action = "hub.shop:sell" },
    { label = "hub.back", action = "scene:pop" },
  },
}
