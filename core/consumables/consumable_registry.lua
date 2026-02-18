-- core/consumables/consumable_registry.lua
local M = {}

local _data = nil

local function load()
  if _data then return _data end
  local fs = require("core.fs")
  local path = "data/consumables.lua"
  if not fs.exists(path) then return {} end
  local ok, chunk = pcall(fs.read, path)
  if not ok or not chunk then return {} end
  local fn, err = loadstring(chunk)
  if not fn then return {} end
  local env = {}
  setmetatable(env, { __index = _G })
  setfenv(fn, env)
  local ok2, data = pcall(fn)
  _data = (ok2 and data) or {}
  return _data
end

function M.get(id)
  local d = load()
  return d[id]
end

function M.isConsumable(item)
  if not item then return false end
  local id = item.id or (item.base and item.base.id)
  if not id then return false end
  if item.consumable then return true end
  return M.get(id) ~= nil
end

function M.needsTarget(item)
  local def = M.get(item and (item.id or (item.base and item.base.id)))
  if not def then return false end
  return def.canTargetMonster or def.canTargetSelf
end

return M
