-- core/game/dungeon_run.lua - Orchestration run donjon (map, entities, tours)
local M = {}

local DungeonGenerator = require("core.dungeon_generator")
local TrapGenerator = require("core.traps.trap_generator")
local LootGenerator = require("core.loot.loot_generator")
local EntityFactory = require("core.game.entity")
local EntityManager = require("core.game.entity_manager")
local TurnManager = require("core.turn.turn_manager")
local WeaponRegistry = require("core.weapons.weapon_registry")

function M.start(dungeonConfig, character)
  dungeonConfig = dungeonConfig or require("data.dungeons.ruins")
  local result = DungeonGenerator.generate(dungeonConfig, 1)
  if not result then return nil end

  local map = result.map
  TrapGenerator.generate(map, dungeonConfig, 1, result.entrance, result.exit)
  LootGenerator.generate(map, dungeonConfig, 1, result.entrance, result.exit)

  local defaultWeapon = WeaponRegistry.get("dagger") or { damageMin = 1, damageMax = 4, damageType = "slashing", statUsed = "strength" }
  local entityManager = EntityManager.new(map, defaultWeapon)

  EntityFactory.reset_id()
  local player = EntityFactory.createPlayer(character)
  if not player then return nil end

  entityManager:addEntity(player, result.entrance.x, result.entrance.y)
  map:exploreAround(result.entrance.x, result.entrance.y, 6)

  for x = 1, map.width do
    for y = 1, map.height do
      local tile = map:getTile(x, y)
      if tile and tile.entities then
        for _, monsterId in ipairs(tile.entities) do
          local monster = EntityFactory.createMonster(monsterId, x, y)
          if monster then
            entityManager:addEntity(monster, x, y)
          end
        end
        tile.entities = {}
      end
    end
  end

  if player._syncEffectEntityFromChar then
    player:_syncEffectEntityFromChar()
  end

  return {
    map = map,
    entityManager = entityManager,
    turnNumber = 0,
    playerX = result.entrance.x,
    playerY = result.entrance.y,
    entrance = result.entrance,
    exit = result.exit,
    rooms = result.rooms or {},
    dungeonConfig = dungeonConfig,
    defaultWeapon = defaultWeapon,
    defaultWeaponId = "dagger",
    gameOver = false,
    death = false,
  }
end

function M.processTurn(gameState, playerAction)
  if not gameState then return nil end
  local result = TurnManager.update(playerAction, gameState)
  if result and gameState.entityManager then
    local player = gameState.entityManager:getPlayer()
    if player then
      gameState.playerX = player.x
      gameState.playerY = player.y
    end
  end
  return result
end

function M.getPlayerPos(gameState)
  if not gameState or not gameState.entityManager then return nil, nil end
  local player = gameState.entityManager:getPlayer()
  if not player then return nil, nil end
  return player.x, player.y
end

return M
