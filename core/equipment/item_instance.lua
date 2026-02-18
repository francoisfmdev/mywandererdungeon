-- core/equipment/item_instance.lua - Instance item equippable (base + affixes)
local M = {}

local _item_base = nil

local function load_base()
  if _item_base then return _item_base end
  local fs = require("core.fs")
  local path = "data/items/base_equipment.lua"
  if not fs.exists(path) then return {} end
  local ok, chunk = pcall(fs.read, path)
  if not ok or not chunk then return {} end
  local fn, err = loadstring(chunk)
  if not fn then return {} end
  local env = {}
  setmetatable(env, { __index = _G })
  setfenv(fn, env)
  local ok2, data = pcall(fn)
  if ok2 and data then _item_base = data end
  return _item_base or {}
end

local function scale_value(val, itemLevel)
  if not val or type(val) ~= "number" then return val end
  if val == 0 or itemLevel <= 1 then return val end
  local scale = 1 + (itemLevel - 1) * 0.3
  local scaled = val * scale
  if val > 0 then
    return math.max(1, math.floor(scaled + 0.5))
  else
    return math.min(-1, math.floor(scaled - 0.5))
  end
end

function M.create(itemId, affixes, itemLevel)
  itemLevel = tonumber(itemLevel) or 1
  local base = load_base()
  local def = base[itemId]
  if not def then return nil end
  local cursed = false
  for _, a in ipairs(affixes or {}) do
    if a.cursed then cursed = true break end
  end
  return {
    id = itemId,
    base = def,
    affixes = affixes or {},
    itemLevel = itemLevel,
    bonuses = M._computeBonuses(def, affixes or {}, itemLevel),
    identified = true,
    cursed = cursed,
  }
end

function M._computeBonuses(base, affixes, itemLevel)
  itemLevel = tonumber(itemLevel) or 1
  local result = {}
  local function merge(src, applyScale)
    if not src then return end
    for k, v in pairs(src) do
      if type(v) == "number" then
        result[k] = (result[k] or 0) + (applyScale and scale_value(v, itemLevel) or v)
      elseif type(v) == "table" and k ~= "effects" then
        result[k] = result[k] or {}
        for k2, v2 in pairs(v) do
          local num = tonumber(v2) or 0
          result[k][k2] = (result[k][k2] or 0) + (applyScale and scale_value(num, itemLevel) or num)
        end
      end
    end
  end
  merge(base.bonuses, false)
  for _, affix in ipairs(affixes) do
    merge(affix.bonuses, true)
  end
  return result
end

function M.toSaveData(item)
  if not item then return nil end
  local id = item.id or (item.base and item.base.id)
  if not id then return nil end
  local d = {
    id = id,
    affixes = item.affixes,
    itemLevel = item.itemLevel,
    identified = item.identified,
    cursed = item.cursed,
    consumable = item.consumable,
    charges = item.charges,
    count = item.count,
  }
  return d
end

function M.fromSaveData(data)
  if not data or not data.id then return nil end
  local item = M.create(data.id, data.affixes, data.itemLevel)
  if item then
    item.identified = data.identified ~= false
    item.cursed = data.cursed or false
    return item
  end
  -- Consommable (pas dans base_equipment)
  local ConsumableRegistry = require("core.consumables.consumable_registry")
  if ConsumableRegistry.get(data.id) then
    local def = ConsumableRegistry.get(data.id)
    local cons = { id = data.id, consumable = true }
    if def and def.type == "wand" and def.chargesMax then
      cons.charges = data.charges or def.chargesMax
    end
    if data.count then cons.count = data.count end
    return cons
  end
  return { id = data.id, consumable = true, charges = data.charges, count = data.count }
end

return M
