-- core/game_state.lua - Etat du jeu (personnage actif)
local M = {}

local _character = nil

function M.get_character()
  return _character
end

function M.set_character(char)
  _character = char
end

function M.reset()
  local Character = require("core.character")
  local ItemInstance = require("core.equipment.item_instance")
  _character = Character.new()
  if _character and _character.equipmentManager then
    local dagger = ItemInstance.create("dagger", {}, 1)
    if dagger then
      _character.equipmentManager:equip(dagger, "weapon_main")
    end
  end
  return _character
end

function M.applyDeathPenalty()
  local char = _character
  if char then
    char:resetToLevel1()
    local ItemInstance = require("core.equipment.item_instance")
    local dagger = ItemInstance.create("dagger", {}, 1)
    if dagger and char.equipmentManager then
      char.equipmentManager:equip(dagger, "weapon_main")
    end
  end
  local player_data = require("core.player_data")
  player_data.set_gold(0)
  player_data.clear_inventory()
end

return M
