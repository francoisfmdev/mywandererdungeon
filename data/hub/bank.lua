-- data/hub/bank.lua
return {
  background = "bank_room",
  buttons = {
    { label = "hub.bank.deposit_gold", action = "hub.bank:deposit_gold" },
    { label = "hub.bank.withdraw_gold", action = "hub.bank:withdraw_gold" },
    { label = "hub.bank.deposit_items", action = "scene:push:hub.bank_deposit" },
    { label = "hub.bank.withdraw_items", action = "scene:push:hub.bank_withdraw" },
    { label = "hub.back", action = "scene:pop" },
  },
}
