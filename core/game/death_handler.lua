-- core/game/death_handler.lua - Resolution morts, drop loot, suppression entites
local M = {}

local log_manager = require("core.game_log.log_manager")
local i18n = require("core.i18n")
local item_display = require("core.equipment.item_display")
local LootGenerator = require("core.loot.loot_generator")

local function get_entity_name(entity)
  if not entity then return "?" end
  if entity._character then return i18n.t("log.trap.you") end
  if entity.nameKey then return i18n.t(entity.nameKey) end
  return entity.name or "?"
end

local function create_drop_item(lootDef, dungeonConfig)
  local id = lootDef.itemId or lootDef.id
  if not id then return nil end
  if id == "gold" then
    local lo = tonumber(lootDef.amountMin) or 1
    local hi = tonumber(lootDef.amountMax) or 5
    return { type = "gold", amount = math.random(lo, hi) }
  end
  local item = LootGenerator.createDropItem(id, dungeonConfig)
  if item and (item.base or item.id) then
    return { type = "item", item = item, name = item_display.getDisplayName(item) }
  end
  return { type = "item", item = { id = id, consumable = true }, name = item_display.getDisplayName({ id = id, consumable = true }) }
end

function M.processDeaths(entityManager, events, gameState)
  events = events or {}
  if not entityManager or not entityManager.getEntities then return events end

  local player = entityManager:getPlayer()
  local player_data = require("core.player_data")

  local toRemove = {}
  for _, entity in pairs(entityManager:getEntities()) do
    if entity.hp ~= nil and entity.hp <= 0 then
      table.insert(toRemove, entity)
    end
  end

  for _, entity in ipairs(toRemove) do
    local name = get_entity_name(entity)
    table.insert(events, {
      type = "death",
      messageKey = "log.death.killed",
      params = { defender = name },
    })
    log_manager.add("death", { messageKey = "log.death.killed", params = { defender = name } })

    -- Victoire si boss du donjon tue
    if entity.isBoss and gameState and entity.monsterId == gameState.bossId then
      gameState.victory = true
      log_manager.add("info", { messageKey = "log.info.victory", params = {} })
    end

    if not entity.isPlayer and entity.monsterId and player then
      local loot = M.rollLoot(entity, gameState and gameState.dungeonConfig)
      for _, drop in ipairs(loot) do
        if drop.type == "gold" and drop.amount and drop.amount > 0 then
          player_data.add_gold(drop.amount)
          table.insert(events, { type = "loot", messageKey = "log.loot.gold", params = { amount = drop.amount } })
          log_manager.add("loot", { messageKey = "log.loot.gold", params = { amount = drop.amount } })
        elseif drop.type == "item" and drop.item then
          player_data.add_item(drop.item)
          table.insert(events, { type = "loot", messageKey = "log.loot.found", params = { item = drop.name or "?" } })
          log_manager.add("loot", { messageKey = "log.loot.found", params = { item = drop.name or "?" } })
        end
      end
    end

    entityManager:removeEntity(entity)
  end

  return events
end

function M.rollLoot(monster, dungeonConfig)
  local out = {}
  if not monster or not monster.monsterId then return out end
  local def = require("core.entities.monster_registry").get(monster.monsterId)
  if not def or not def.loot then return out end
  for _, lootDef in ipairs(def.loot) do
    local chance = lootDef.chance or 0.5
    if math.random() <= chance then
      local drop = create_drop_item(lootDef, dungeonConfig)
      if drop then table.insert(out, drop) end
    end
  end
  return out
end

return M
