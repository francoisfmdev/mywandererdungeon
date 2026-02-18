-- core/dungeon_run_state.lua - Etat run donjon (delegue a dungeon_run)
local M = {}

local DungeonRun = require("core.game.dungeon_run")
local game_state = require("core.game_state")

local _state = nil
local _gen_count = 0
local _dungeon_config = nil

function M.start(dungeonConfig)
  _dungeon_config = dungeonConfig or require("data.dungeons.ruins")
  _gen_count = _gen_count + 1
  local seed = math.floor((os.time() or 0) * 1000)
  if love and love.timer and love.timer.getTime then
    seed = seed + math.floor(love.timer.getTime() * 1000)
  end
  seed = seed + _gen_count * 7919
  math.randomseed(seed)

  local character = game_state.get_character()
  _state = DungeonRun.start(_dungeon_config, character, 1)
  if not _state then return nil end

  local log_manager = require("core.game_log.log_manager")
  log_manager.clear()
  _state.minimapVisible = true
  return _state
end

--- Passage a l'etage suivant (conserve personnage et inventaire)
function M.nextFloor()
  if not _state or not _dungeon_config then return nil end
  local character = game_state.get_character()
  local currentFloor = _state.currentFloor or 1
  local totalFloors = _state.totalFloors or 1
  local minimapWasVisible = _state.minimapVisible ~= false
  if currentFloor >= totalFloors then return nil end

  local log_manager = require("core.game_log.log_manager")
  log_manager.add("info", { messageKey = "log.info.floor_descend", params = { floor = currentFloor + 1 } })

  _gen_count = _gen_count + 1
  math.randomseed((os.time() or 0) * 1000 + _gen_count * 7919)
  _state = DungeonRun.start(_dungeon_config, character, currentFloor + 1)
  if not _state then return nil end
  _state.minimapVisible = minimapWasVisible
  return _state
end

function M.get()
  return _state
end

function M.get_map()
  return _state and _state.map
end

function M.get_player_pos()
  if not _state then return nil, nil end
  return DungeonRun.getPlayerPos(_state)
end

function M.process_turn(playerAction)
  if not _state then return nil end
  local result = DungeonRun.processTurn(_state, playerAction)
  if result and _state.entityManager and _state.entityManager:getPlayer() then
    local player = _state.entityManager:getPlayer()
    if player._character and player._syncEffectEntityToChar then
      player._character:setHP(player.hp)
      player._character:setMP(player.mp)
    end
  end
  return result
end

function M.set_player_pos(nx, ny)
  if not _state then return end
  local px, py = M.get_player_pos()
  if not px or not py then return end
  local dx = (nx and nx > px) and 1 or ((nx and nx < px) and -1 or 0)
  local dy = (ny and ny > py) and 1 or ((ny and ny < py) and -1 or 0)
  if dx ~= 0 or dy ~= 0 then
    M.process_turn({ type = "move", dx = dx, dy = dy })
  end
end

function M.toggle_minimap()
  if _state then
    _state.minimapVisible = not _state.minimapVisible
    return _state.minimapVisible
  end
  return false
end

function M.is_minimap_visible()
  return _state and _state.minimapVisible
end

local _pending_ground_loot = nil

function M.setPendingGroundLoot(x, y)
  _pending_ground_loot = { x = x, y = y }
end

function M.getPendingGroundLoot()
  return _pending_ground_loot
end

function M.setVictory()
  if _state then _state.victory = true end
end

function M.clearPendingGroundLoot()
  _pending_ground_loot = nil
end

function M.clear()
  _state = nil
  _pending_ground_loot = nil
  local input_state = require("core.input.input_state")
  if input_state and input_state.reset then input_state.reset() end
end

return M
