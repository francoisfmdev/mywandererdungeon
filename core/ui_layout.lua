-- core/ui_layout.lua - Charge et expose le layout UI
local M = {}
local _layout = nil

local function load()
  if _layout then return _layout end
  local fs = require("core.fs")
  local path = "data/ui_layout.lua"
  if not fs.exists(path) then return {} end
  local ok, chunk = pcall(fs.read, path)
  if not ok or not chunk then return {} end
  local fn, err = loadstring(chunk)
  if not fn then return {} end
  local env = {}
  setmetatable(env, { __index = _G })
  setfenv(fn, env)
  local ok2, data = pcall(fn)
  _layout = (ok2 and data) and data or {}
  return _layout
end

function M.get(section)
  local l = load()
  if section then return l[section] or {} end
  return l
end

function M.colors()
  return load().colors or {}
end

return M
