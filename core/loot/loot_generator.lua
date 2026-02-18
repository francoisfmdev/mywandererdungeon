-- core/loot/loot_generator.lua - Generation procedurale armes, consommables, or
local M = {}

local ItemInstance = require("core.equipment.item_instance")

local function weighted_random(items)
  if not items or #items == 0 then return nil end
  local total = 0
  for _, item in ipairs(items) do
    total = total + (item.weight or 1)
  end
  if total <= 0 then return nil end
  local r = math.random() * total
  for _, item in ipairs(items) do
    r = r - (item.weight or 1)
    if r <= 0 then return item end
  end
  return items[#items]
end

local ConsumableRegistry = require("core.consumables.consumable_registry")
local AffixRegistry = require("core.affixes.affix_registry")

local AFFIX_CHANCE_1 = 0.18
local AFFIX_CHANCE_2 = 0.05
local AFFIX_CHANCE_3 = 0.015
local AFFIX_CHANCE_MONSTER_1 = 0.08
local AFFIX_CHANCE_MONSTER_2 = 0.02
local AFFIX_CHANCE_MONSTER_3 = 0.005

local function get_equipment_slot(itemId)
  local fs = require("core.fs")
  local path = "data/items/base_equipment.lua"
  if not fs.exists(path) then return "weapon_main" end
  local ok, chunk = pcall(fs.read, path)
  if not ok or not chunk then return "weapon_main" end
  local fn, err = loadstring(chunk)
  if not fn then return "weapon_main" end
  local env = {} setmetatable(env, { __index = _G }) setfenv(fn, env)
  local ok2, data = pcall(fn)
  if not ok2 or not data then return "weapon_main" end
  local def = data[itemId]
  if def then
    if def.slot then return def.slot end
    if def.allowedSlots and #def.allowedSlots > 0 then return def.allowedSlots[1] end
  end
  return "weapon_main"
end

local CURSED_CHANCE = 0.06

local function create_item_from_id(itemId, itemType, dungeonConfig, fromMonster)
  if itemType == "equipment" then
    local slot = get_equipment_slot(itemId)
    local affixes = {}
    local cursed = math.random() < CURSED_CHANCE
    local ch1 = fromMonster and AFFIX_CHANCE_MONSTER_1 or AFFIX_CHANCE_1
    local ch2 = fromMonster and AFFIX_CHANCE_MONSTER_2 or AFFIX_CHANCE_2
    local ch3 = fromMonster and AFFIX_CHANCE_MONSTER_3 or AFFIX_CHANCE_3
    if cursed then
      local ca = AffixRegistry.rollCursedAffix(slot)
      if ca then table.insert(affixes, ca) end
    else
      local affixCount = 0
      if math.random() < ch1 then affixCount = 1 end
      if affixCount == 1 and math.random() < ch2 / ch1 then affixCount = 2 end
      if affixCount == 2 and math.random() < ch3 / ch2 then affixCount = 3 end
      if affixCount > 0 then
        local rolled = AffixRegistry.rollAffixesForSlot(slot, affixCount)
        for _, a in ipairs(rolled) do table.insert(affixes, a) end
      end
    end
    local lootCfg = dungeonConfig and dungeonConfig.loot or {}
    local levelMin = tonumber(lootCfg.itemLevelMin) or 1
    local levelMax = tonumber(lootCfg.itemLevelMax) or 3
    local itemLevel = math.max(1, math.min(levelMax, math.random(levelMin, levelMax)))
    local item = ItemInstance.create(itemId, affixes, itemLevel)
    if item then
      item.identified = false
      item.cursed = cursed
    end
    return item
  end
  if itemType == "consumable" then
    local item = { id = itemId, consumable = true }
    local def = ConsumableRegistry.get(itemId)
    if def and def.type == "wand" and def.chargesMax then
      item.charges = def.chargesMax
    end
    if def and def.type == "ammo" then
      item.count = math.random(5, 15)
    end
    return item
  end
  return { id = itemId }
end

--- Cree un drop (equipment avec affixes+level, consumable, ou autre). Utilise par death_handler.
function M.createDropItem(itemId, dungeonConfig)
  local ConsumableReg = require("core.consumables.consumable_registry")
  if ConsumableReg.get(itemId) then
    return create_item_from_id(itemId, "consumable", dungeonConfig, false)
  end
  local fs = require("core.fs")
  local path = "data/items/base_equipment.lua"
  if fs.exists(path) then
    local ok, chunk = pcall(fs.read, path)
    if ok and chunk then
      local fn, err = loadstring(chunk)
      if fn then
        local env = {} setmetatable(env, { __index = _G }) setfenv(fn, env)
        local ok2, data = pcall(fn)
        if ok2 and data and data[itemId] then
          return create_item_from_id(itemId, "equipment", dungeonConfig, true)
        end
      end
    end
  end
  return { id = itemId }
end

--- Genere armes, consommables et or sur la carte selon la config donjon.
function M.generate(map, dungeonConfig, depth, entrance, exit)
  if not map or not dungeonConfig then return end

  local lootCfg = dungeonConfig.loot or {}
  local weaponsCfg = lootCfg.weapons or {}
  local consumablesCfg = lootCfg.consumables or {}
  local goldCfg = lootCfg.gold or {}

  local floorPositions = {}
  for x = 1, map.width do
    for y = 1, map.height do
      if map:isWalkable(x, y) then
        local ex, ey = entrance and entrance.x, entrance and entrance.y
        local sx, sy = exit and exit.x, exit and exit.y
        if (ex and ey and x == ex and y == ey) or (sx and sy and x == sx and y == sy) then
        else
          table.insert(floorPositions, { x, y })
        end
      end
    end
  end

  if #floorPositions == 0 then return end

  for i = #floorPositions, 2, -1 do
    local j = math.random(1, i)
    floorPositions[i], floorPositions[j] = floorPositions[j], floorPositions[i]
  end

  local density = tonumber(weaponsCfg.density) or 0.02
  local weaponCount = math.floor(#floorPositions * density)
  local types = weaponsCfg.types or {}
  if #types > 0 and weaponCount > 0 then
    for i = 1, weaponCount do
      local pos = floorPositions[math.random(1, #floorPositions)]
      local pick = weighted_random(types)
      if pick and pos then
        local item = create_item_from_id(pick.id or pick, "equipment", dungeonConfig, false)
        if item then
          map:addGroundLoot(pos[1], pos[2], 0, { item })
        end
      end
    end
  end

  density = tonumber(consumablesCfg.density) or 0.03
  local consumableCount = math.floor(#floorPositions * density)
  types = consumablesCfg.types or {}
  if #types > 0 and consumableCount > 0 then
    for i = 1, math.min(consumableCount, #floorPositions) do
      local pos = floorPositions[math.random(1, #floorPositions)]
      local pick = weighted_random(types)
      if pick and pos then
        local tile = map:getTile(pos[1], pos[2])
        local g, items = map:getGroundLoot(pos[1], pos[2])
        if #(items or {}) < 2 then
          local item = create_item_from_id(pick.id or pick, "consumable", dungeonConfig, false)
          if item then
            map:addGroundLoot(pos[1], pos[2], 0, { item })
          end
        end
      end
    end
  end

  density = tonumber(goldCfg.density) or 0.04
  local amountMin = tonumber(goldCfg.amountMin) or 2
  local amountMax = tonumber(goldCfg.amountMax) or 12
  local goldCount = math.floor(#floorPositions * density)
  for i = 1, goldCount do
    local pos = floorPositions[math.random(1, #floorPositions)]
    if pos then
      local amt = math.random(amountMin, amountMax)
      if amt > 0 then
        map:addGroundLoot(pos[1], pos[2], amt, nil)
      end
    end
  end
end

return M
