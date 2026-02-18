-- core/entities/monster_registry.lua - Definitions monstres et resistances
local M = {}

local _monsters = nil

local function load()
  if _monsters then return _monsters end
  local fs = require("core.fs")
  local path = "data/entities/monsters.lua"
  if not fs.exists(path) then return {} end
  local ok, chunk = pcall(fs.read, path)
  if not ok or not chunk then return {} end
  local fn, err = loadstring(chunk)
  if not fn then return {} end
  local env = {}
  setmetatable(env, { __index = _G })
  setfenv(fn, env)
  local ok2, data = pcall(fn)
  if not ok2 or type(data) ~= "table" then return {} end
  _monsters = {}
  for id, def in pairs(data) do
    if type(def) == "table" and (def.id or id) then
      _monsters[def.id or id] = def
    end
  end
  return _monsters
end

function M.get(monsterId)
  local m = load()
  return m[monsterId]
end

function M.getResistances(monsterId)
  local def = M.get(monsterId)
  return (def and def.resistances) or {}
end

return M
