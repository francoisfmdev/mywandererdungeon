-- core/save.lua - Sauvegarde complete (personnage, or, inventaire, banque)
local M = {}
local config = require("core.config")
local fs = require("core.fs")
local log = require("core.log")

local SAVE_PATH = "savegame.lua"

local function get_save_path()
  -- Meme repertoire que config (save directory Love2D)
  return SAVE_PATH
end

function M.has_save()
  return fs.exists(get_save_path())
end

local function serialize_value(v, indent)
  indent = indent or 0
  if type(v) == "number" or type(v) == "boolean" then
    return tostring(v)
  end
  if type(v) == "string" then
    return ("%q"):format(v:gsub("\\", "\\\\"):gsub('"', '\\"'))
  end
  if type(v) == "table" then
    local parts = { "{" }
    for k, val in pairs(v) do
      local key = type(k) == "string" and ("%q"):format(k) or ("[%s]"):format(k)
      table.insert(parts, ("  "):rep(indent + 1) .. key .. " = " .. serialize_value(val, indent + 1) .. ",")
    end
    table.insert(parts, ("  "):rep(indent) .. "}")
    return table.concat(parts, "\n")
  end
  return "nil"
end

function M.save()
  local game_state = require("core.game_state")
  local player_data = require("core.player_data")
  local Character = require("core.character")

  local char = game_state.get_character()
  if not char then return false end

  local charData = Character.toSaveData(char)
  local pdData = player_data.toSaveData()
  if not charData or not pdData then return false end

  local data = {
    last_save = os.time(),
    character = charData,
    player_data = pdData,
  }

  local content = "return " .. serialize_value(data, 0)
  local ok, err = pcall(fs.write, get_save_path(), content)
  if not ok then
    log.warn("save.save error:", err)
    return false
  end
  config.set("last_save", data.last_save)
  config.save()
  return true
end

function M.load()
  if not M.has_save() then return false end
  local ok, chunk = pcall(fs.read, get_save_path())
  if not ok or not chunk then return false end
  local fn, err = loadstring(chunk)
  if not fn then
    log.warn("save.load parse error:", err)
    return false
  end
  local ok2, data = pcall(fn)
  if not ok2 or not data or type(data) ~= "table" then return false end

  local Character = require("core.character")
  local game_state = require("core.game_state")
  local player_data = require("core.player_data")

  local char = Character.fromSaveData(data.character)
  if not char then return false end

  game_state.set_character(char)
  player_data.fromSaveData(data.player_data)
  return true
end

return M
