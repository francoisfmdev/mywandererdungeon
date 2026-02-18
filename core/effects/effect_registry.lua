-- core/effects/effect_registry.lua - Registry des effets (data-driven)
local M = {}

local _effects = nil

local function load_effects()
  if _effects then return _effects end
  local fs = require("core.fs")
  local path = "data/effects/effects.lua"
  if not fs.exists(path) then
    return {}
  end
  local ok, chunk = pcall(fs.read, path)
  if not ok or not chunk then return {} end
  local fn, err = loadstring(chunk)
  if not fn then return {} end
  local env = {}
  setmetatable(env, { __index = _G })
  setfenv(fn, env)
  local ok2, data = pcall(fn)
  _effects = (ok2 and data and type(data) == "table") and data or {}
  return _effects
end

function M.get(effectId)
  local effects = load_effects()
  return effects[effectId]
end

function M.get_all()
  return load_effects()
end

function M.register(effectId, def)
  load_effects()
  _effects = _effects or {}
  def = def or {}
  def.id = effectId
  _effects[effectId] = def
end

return M
