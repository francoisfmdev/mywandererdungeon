-- core/traps/trap_registry.lua - Registry des definitions de pieges
local M = {}

local _traps = nil

local function load_traps()
  if _traps then return _traps end
  local fs = require("core.fs")
  local path = "data/traps/traps.lua"
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
  _traps = {}
  for _, def in ipairs(data) do
    if def and def.id then
      _traps[def.id] = def
    end
  end
  return _traps
end

function M.get(trapId)
  local traps = load_traps()
  return traps[trapId]
end

function M.getAll()
  return load_traps()
end

return M
