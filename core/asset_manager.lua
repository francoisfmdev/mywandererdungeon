-- core/asset_manager.lua - Chargement et cache des assets
local M = {}

local fs = require("core.fs")
local platform = require("platform.love")

local _cache = {}
local _assets_config = nil

local function load_assets_config()
  if _assets_config then return _assets_config end
  local path = "data/assets.lua"
  if not fs.exists(path) then return {} end
  local ok, chunk = pcall(fs.read, path)
  if not ok or not chunk then return {} end
  local fn, err = loadstring(chunk)
  if not fn then return {} end
  local env = {}
  setmetatable(env, { __index = _G })
  setfenv(fn, env)
  local ok2, data = pcall(fn)
  if ok2 and data then _assets_config = data end
  return _assets_config or {}
end

function M.get_image(key)
  if _cache[key] then return _cache[key] end
  local cfg = load_assets_config()
  local path = cfg[key]
  if not path then return nil end
  if not platform.gfx_load_image then return nil end
  local img = platform.gfx_load_image(path)
  if img then _cache[key] = img end
  return img
end

return M
