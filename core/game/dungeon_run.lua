-- core/game/dungeon_run.lua - Orchestration run donjon (map, entities, tours)
local M = {}

local DungeonGenerator = require("core.dungeon_generator")
local TrapGenerator = require("core.traps.trap_generator")
local LootGenerator = require("core.loot.loot_generator")
local EntityFactory = require("core.game.entity")
local EntityManager = require("core.game.entity_manager")
local TurnManager = require("core.turn.turn_manager")
local WeaponRegistry = require("core.weapons.weapon_registry")

local function is_in_room(gx, gy, room)
  if not room then return false end
  return gx >= room.x and gx < room.x + room.w and gy >= room.y and gy < room.y + room.h
end

function M.start(dungeonConfig, character, depth)
  dungeonConfig = dungeonConfig or require("data.dungeons.ruins")
  depth = depth or 1
  local result = DungeonGenerator.generate(dungeonConfig, depth)
  if not result then return nil end

  local totalFloors = dungeonConfig.totalFloors or 1
  local winCondition = dungeonConfig.winCondition or "boss"
  local bossId = dungeonConfig.bossId
  local winObjectId = dungeonConfig.winObjectId
  local isLastFloor = (depth >= totalFloors)
  local exitRoom = result.rooms and result.rooms[#result.rooms]

  local map = result.map
  TrapGenerator.generate(map, dungeonConfig, depth, result.entrance, result.exit)
  LootGenerator.generate(map, dungeonConfig, depth, result.entrance, result.exit)

  -- Mode objet : placer l'objet de victoire sur la case sortie (dernier etage)
  if isLastFloor and winCondition == "object" and winObjectId then
    local ex, ey = result.exit.x, result.exit.y
    map:addGroundLoot(ex, ey, 0, { { id = winObjectId, consumable = true } })
  end

  local defaultWeapon = WeaponRegistry.get("dagger") or { damageMin = 1, damageMax = 4, damageType = "slashing", statUsed = "strength" }
  local entityManager = EntityManager.new(map, defaultWeapon)

  EntityFactory.reset_id()
  local player = EntityFactory.createPlayer(character)
  if not player then return nil end

  entityManager:addEntity(player, result.entrance.x, result.entrance.y)
  map:exploreAround(result.entrance.x, result.entrance.y, 6)

  -- Ajouter monstres ; au dernier etage en mode boss : pas de monstres dans la salle sortie, boss a la place
  for x = 1, map.width do
    for y = 1, map.height do
      local tile = map:getTile(x, y)
      if tile and tile.entities then
        local skip = false
        if isLastFloor and winCondition == "boss" and bossId and exitRoom and is_in_room(x, y, exitRoom) then
          skip = true
        end
        if not skip then
          for _, monsterId in ipairs(tile.entities) do
            local monster = EntityFactory.createMonster(monsterId, x, y)
            if monster then
              entityManager:addEntity(monster, x, y)
            end
          end
        end
        tile.entities = {}
      end
    end
  end

  -- Mode boss : spawn du boss sur la case sortie
  if isLastFloor and winCondition == "boss" and bossId then
    local boss = EntityFactory.createMonster(bossId, result.exit.x, result.exit.y)
    if boss then
      entityManager:addEntity(boss, result.exit.x, result.exit.y)
    end
  end

  if player._syncEffectEntityFromChar then
    player:_syncEffectEntityFromChar()
  end

  -- Marquer la tuile sortie pour le rendu (escalier/portail)
  local exitTile = map:getTile(result.exit.x, result.exit.y)
  if exitTile then exitTile.isExit = true end

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
    victory = false,
    currentFloor = depth,
    totalFloors = totalFloors,
    winCondition = winCondition,
    bossId = bossId,
    winObjectId = winObjectId,
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
