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
  _character = Character.new()
  return _character
end

function M.applyDeathPenalty()
  local char = _character
  if char then
    char:resetToLevel1()
  end
  local player_data = require("core.player_data")
  player_data.set_gold(0)
  player_data.clear_inventory()
end

return M
