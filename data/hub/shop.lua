-- data/hub/shop.lua
return {
  background = "shop_room",
  buttons = {
    { label = "hub.shop.buy", action = "hub.shop:buy" },
    { label = "hub.shop.sell", action = "hub.shop:sell" },
    { label = "hub.back", action = "scene:pop" },
  },
}
