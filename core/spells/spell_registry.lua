-- core/spells/spell_registry.lua - Registry des sorts (data-driven)
local M = {}

local _spells = nil

local function load()
  if _spells then return _spells end
  local fs = require("core.fs")
  local path = "data/spells.lua"
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
  _spells = {}
  for id, def in pairs(data) do
    if type(def) == "table" then
      _spells[id] = def
    end
  end
  return _spells
end

function M.get(spellId)
  local s = load()
  return s[spellId]
end

return M
