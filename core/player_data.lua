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
  if not item then return end
  local ConsumableRegistry = require("core.consumables.consumable_registry")
  local def = ConsumableRegistry.get(item.id or (item.base and item.base.id))
  if def and def.type == "ammo" then
    for _, invItem in ipairs(_data.inventory) do
      local id = invItem.id or (invItem.base and invItem.base.id)
      if id == (item.id or item.base.id) then
        invItem.count = (invItem.count or 1) + (item.count or 1)
        return
      end
    end
  end
  table.insert(_data.inventory, item)
end

function M.remove_item(index)
  if index and index >= 1 and index <= #_data.inventory then
    table.remove(_data.inventory, index)
    return true
  end
  return false
end

function M.count_ammo(ammoId)
  if not ammoId then return 0 end
  local n = 0
  for _, item in ipairs(_data.inventory) do
    local id = item.id or (item.base and item.base.id)
    if id == ammoId then
      n = n + (item.count or 1)
    end
  end
  return n
end

function M.consume_one_ammo(ammoId)
  if not ammoId then return false end
  for i, item in ipairs(_data.inventory) do
    local id = item.id or (item.base and item.base.id)
    if id == ammoId then
      if item.count and item.count > 1 then
        item.count = item.count - 1
      else
        table.remove(_data.inventory, i)
      end
      return true
    end
  end
  return false
end

function M.find_item_index_by_id(id)
  for i, item in ipairs(_data.inventory) do
    local itemId = item.id or (item.base and item.base.id)
    if itemId == id then return i end
  end
  return nil
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

function M.toSaveData()
  local ItemInstance = require("core.equipment.item_instance")
  local inv = {}
  for _, item in ipairs(_data.inventory) do
    local d = ItemInstance.toSaveData(item)
    if d then table.insert(inv, d) end
  end
  local bank = {}
  for _, item in ipairs(_data.bank_storage) do
    local d = ItemInstance.toSaveData(item)
    if d then table.insert(bank, d) end
  end
  return {
    gold = _data.gold,
    bank_gold = _data.bank_gold,
    inventory = inv,
    bank_storage = bank,
  }
end

function M.fromSaveData(data)
  if not data then return end
  local ItemInstance = require("core.equipment.item_instance")
  _data.gold = tonumber(data.gold) or 0
  _data.bank_gold = tonumber(data.bank_gold) or 0
  _data.inventory = {}
  for _, d in ipairs(data.inventory or {}) do
    local item = ItemInstance.fromSaveData(d)
    if item then table.insert(_data.inventory, item) end
  end
  _data.bank_storage = {}
  for _, d in ipairs(data.bank_storage or {}) do
    local item = ItemInstance.fromSaveData(d)
    if item then table.insert(_data.bank_storage, item) end
  end
end

return M
