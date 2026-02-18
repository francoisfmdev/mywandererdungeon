-- core/router.lua - Interprete actions data-driven
local M = {}

local scene_manager = nil
local platform = nil
local _handlers = {}

function M.init(sm, plat)
  scene_manager = sm
  platform = plat
  local bank = require("core.bank_service")
  local shop = require("core.shop_service")
  local quest = require("core.quest_service")
  M.register_handler("hub.bank", function(sub) return bank.handle(sub) end)
  M.register_handler("hub.shop", function(sub) return shop.handle(sub) end)
  M.register_handler("hub.tavern", function(sub) return quest.handle(sub) end)
  M.register_handler("player", function(sub)
    local state = require("core.dungeon_run_state").get()
    if not state then return end
    if sub == "attack" then
      local input_state = require("core.input.input_state")
      local target_selector = require("core.targeting.target_selector")
      input_state.setMode("direction_target")
      input_state.setPendingAction("attack")
      local player = state.entityManager:getPlayer()
      local weapon = player and player._character and player._character.equipmentManager
        and player._character.equipmentManager:getEquipped("weapon_main")
      weapon = weapon and (weapon.base or weapon)
      local range = (weapon and weapon.range) or 1
      local px, py = player and (player.x or player.gridX), player and (player.y or player.gridY)
      local _, dx, dy = target_selector.findNearestEnemyInRange(
        px, py, range, state.map, state.entityManager, player
      )
      input_state.setSelectedDirection(dx, dy)
    elseif sub == "cast" then
      local spell_registry = require("core.spells.spell_registry")
      local spellId = "fireball"
      local spell = spell_registry.get(spellId)
      if spell and (spell.targetType or "projectile") == "buff" then
        local player = state.entityManager:getPlayer()
        require("core.dungeon_run_state").process_turn({ type = "cast", spellId = spellId, targetId = player and player.id })
      else
        local input_state = require("core.input.input_state")
        local target_selector = require("core.targeting.target_selector")
        input_state.setMode("direction_target")
        input_state.setPendingAction("cast")
        input_state.setPendingSpellId(spellId)
        local player = state.entityManager:getPlayer()
        local range = (spell and spell.range) or 8
        local px, py = player and (player.x or player.gridX), player and (player.y or player.gridY)
        local _, dx, dy = target_selector.findNearestEnemyInRange(
          px, py, range, state.map, state.entityManager, player
        )
        input_state.setSelectedDirection(dx, dy)
      end
    elseif sub == "inventory" then
      scene_manager.push("hub.inventory")
    elseif sub == "wait" then
      require("core.dungeon_run_state").process_turn({ type = "wait" })
    elseif sub == "observer" then
      local input_state = require("core.input.input_state")
      local state = require("core.dungeon_run_state").get()
      if state then
        local px, py = require("core.dungeon_run_state").get_player_pos()
        if px and py then
          input_state.setMode("observer")
          input_state.setObserverCursor(px, py)
        end
      end
    end
  end)
end

function M.register_handler(domain, fn)
  _handlers[domain] = fn
end

function M.dispatch(action_str)
  if not action_str or type(action_str) ~= "string" then return false end
  local parts = {}
  for p in action_str:gmatch("[^:]+") do table.insert(parts, p) end
  if #parts < 2 then return false end
  local domain = parts[1]
  if domain == "scene" then
    local cmd = parts[2]
    local target = parts[3]
    if cmd == "push" and target then
      scene_manager.push(target)
      return true
    elseif cmd == "pop" then
      scene_manager.pop()
      return true
    elseif cmd == "replace" and target then
      scene_manager.replace(target)
      return true
    end
  elseif domain == "game" then
    local cmd = parts[2]
    if cmd == "start" then
      require("core.player_data").reset()
      require("core.game_state").reset()
      local log_mgr = require("core.game_log.log_manager")
      log_mgr.add("info", { messageKey = "log.info.welcome", params = {} })
      scene_manager.replace("hub_main")
      return true
    end
    if cmd == "continue" then
      local save = require("core.save")
      if save.has_save() and save.load() then
        scene_manager.replace("hub_main")
        return true
      end
      return false
    end
  elseif domain == "quit" then
    if platform and platform.quit then
      platform.quit()
      return true
    end
  elseif domain == "pause" then
    if parts[2] == "quit_to_hub" then
      require("core.dungeon_run_state").clear()
      scene_manager.replace("hub_main")
      return true
    end
  elseif domain == "player" then
    local sub = parts[2]
    local handler = _handlers["player"]
    if handler and sub then return handler(sub) end
  else
    local fn = _handlers[domain]
    if fn and parts[2] then
      return fn(parts[2]) or true
    end
  end
  return false
end

return M
