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

local function create_item_from_id(itemId, itemType, dungeonConfig)
  if itemType == "equipment" then
    local item = ItemInstance.create(itemId, {}, 1)
    if item then
      item.identified = true
      item.cursed = false
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

--- Cree un drop (equipment, consumable, or). Objets crees a la main (pas d'affixes).
function M.createDropItem(itemId, dungeonConfig)
  local ConsumableReg = require("core.consumables.consumable_registry")
  if ConsumableReg.get(itemId) then
    return create_item_from_id(itemId, "consumable", dungeonConfig)
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
          return create_item_from_id(itemId, "equipment", dungeonConfig)
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
  local armorCfg = lootCfg.armor or {}
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

  local density = tonumber(weaponsCfg.density) or 0.004
  local weaponCount = math.floor(#floorPositions * density)
  local types = weaponsCfg.types or {}
  if #types > 0 and weaponCount > 0 then
    for i = 1, weaponCount do
      local pos = floorPositions[math.random(1, #floorPositions)]
      local pick = weighted_random(types)
      if pick and pos then
        local item = create_item_from_id(pick.id or pick, "equipment", dungeonConfig)
        if item then
          map:addGroundLoot(pos[1], pos[2], 0, { item })
        end
      end
    end
  end

  local armorDensity = tonumber(armorCfg.density) or 0.002
  local armorCount = math.floor(#floorPositions * armorDensity)
  local armorTypes = armorCfg.types or {}
  if #armorTypes > 0 and armorCount > 0 then
    for i = 1, math.min(armorCount, #floorPositions) do
      local pos = floorPositions[math.random(1, #floorPositions)]
      local pick = weighted_random(armorTypes)
      if pick and pos then
        local _, items = map:getGroundLoot(pos[1], pos[2])
        if #(items or {}) < 2 then
          local item = create_item_from_id(pick.id or pick, "equipment", dungeonConfig)
          if item then
            map:addGroundLoot(pos[1], pos[2], 0, { item })
          end
        end
      end
    end
  end

  density = tonumber(consumablesCfg.density) or 0.006
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
          local item = create_item_from_id(pick.id or pick, "consumable", dungeonConfig)
          if item then
            map:addGroundLoot(pos[1], pos[2], 0, { item })
          end
        end
      end
    end
  end

  density = tonumber(goldCfg.density) or 0.015
  local amountMin = tonumber(goldCfg.amountMin) or 1
  local amountMax = tonumber(goldCfg.amountMax) or 8
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

  -- Objets globaux (cartes type graines PMD) : rares, sur n'importe quel etage/donjon
  local globalCfg = require("data.loot_global")
  local globalDensity = tonumber(globalCfg.density) or 0.002
  local globalTypes = globalCfg.types or {}
  local globalCount = math.floor(#floorPositions * globalDensity)
  if #globalTypes > 0 and globalCount > 0 then
    for i = 1, math.min(globalCount, #floorPositions) do
      local pos = floorPositions[math.random(1, #floorPositions)]
      local pick = weighted_random(globalTypes)
      if pick and pos then
        local _, items = map:getGroundLoot(pos[1], pos[2])
        if #(items or {}) < 2 then
          local item = create_item_from_id(pick.id or pick, "consumable", dungeonConfig)
          if item then
            map:addGroundLoot(pos[1], pos[2], 0, { item })
          end
        end
      end
    end
  end
end

return M
