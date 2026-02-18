-- core/weapons/weapon_registry.lua - Registry des armes (data-driven)
local M = {}

local _weapons = nil

local function load()
  if _weapons then return _weapons end
  local fs = require("core.fs")
  local path = "data/weapons.lua"
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
  _weapons = {}
  for id, def in pairs(data) do
    if type(def) == "table" then
      _weapons[id] = def
    end
  end
  return _weapons
end

function M.get(weaponId)
  local w = load()
  return w[weaponId]
end

return M
