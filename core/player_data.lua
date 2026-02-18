-- core/player_data.lua - Donnees joueur (gold, banque, inventaire)
local M = {}

local _data = {
  gold = 0,
  bank_gold = 0,
  inventory = {},
  bank_storage = {},
}

function M.get_gold()
  return _data.gold
end

function M.set_gold(v)
  _data.gold = math.max(0, v)
end

function M.add_gold(amount)
  if amount and amount > 0 then
    _data.gold = _data.gold + amount
  end
end

function M.add_item(item)
  if item then
    table.insert(_data.inventory, item)
  end
end

function M.remove_item(index)
  if index and index >= 1 and index <= #_data.inventory then
    table.remove(_data.inventory, index)
    return true
  end
  return false
end

function M.get_bank_gold()
  return _data.bank_gold
end

function M.set_bank_gold(v)
  _data.bank_gold = math.max(0, v)
end

function M.get_inventory()
  return _data.inventory
end

function M.clear_inventory()
  _data.inventory = {}
end

function M.get_bank_storage()
  return _data.bank_storage
end

function M.reset()
  _data.gold = 100
  _data.bank_gold = 0
  _data.inventory = {}
  _data.bank_storage = {}
end

return M
