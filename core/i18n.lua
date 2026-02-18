-- core/i18n.lua - i18n par cles, fallback, interpolation
local M = {}

local log = require("core.log")
local fs = require("core.fs")

local _locales = {}
local _current = "en"
local _fallback = "en"

-- Pluralisation simple : one/other (extension prevee pour n>1)
local function plural_key(base, count)
  if count == 1 then
    return base .. ".one"
  end
  return base .. ".other"
end

function M.set_locale(loc)
  if _locales[loc] then
    _current = loc
    return true
  end
  log.warn("i18n.set_locale: unknown locale", loc)
  return false
end

function M.get_locale()
  return _current
end

function M.set_fallback(loc)
  _fallback = loc
end

function M.load_locale(code, path)
  if not path then path = ("data/locale/%s.lua"):format(code) end
  if not fs.exists(path) then
    log.warn("i18n.load_locale: file not found", path)
    return false
  end
  local ok, chunk = pcall(fs.read, path)
  if not ok or not chunk then return false end
  local fn, err = loadstring(chunk)
  if not fn then
    log.warn("i18n.load_locale parse error:", err)
    return false
  end
  local env = {}
  setmetatable(env, { __index = _G })
  setfenv(fn, env)
  local ok2, data = pcall(fn)
  if not ok2 or not data or type(data) ~= "table" then return false end
  _locales[code] = data
  return true
end

local function resolve(key)
  local cur = _locales[_current]
  local fb = _locales[_fallback]
  if cur and cur[key] ~= nil then return cur[key] end
  if fb and fb[key] ~= nil then return fb[key] end
  return nil
end

local function deep_get(t, keys)
  for i = 1, #keys do
    if type(t) ~= "table" then return nil end
    t = t[keys[i]]
  end
  return t
end

local function resolve_nested(key)
  local keys = {}
  for part in key:gmatch("[^.]+") do table.insert(keys, part) end
  local cur = _locales[_current]
  local fb = _locales[_fallback]
  local v = cur and deep_get(cur, keys) or nil
  if v == nil and fb then v = deep_get(fb, keys) end
  return v
end

-- t(key, params) avec interpolation {name}
function M.t(key, params)
  if not key or key == "" then return "[[missing:key]]" end
  local val = resolve_nested(key)
  if val == nil then return ("[[missing:%s]]"):format(key) end
  if type(val) ~= "string" then return tostring(val) end
  if not params then return val end
  return val:gsub("{(%w+)}", function(k)
    return params[k] ~= nil and tostring(params[k]) or ("{" .. k .. "}")
  end)
end

-- t_plural(base_key, count, params) - one/other
function M.t_plural(base_key, count, params)
  local k = plural_key(base_key, count)
  params = params or {}
  params.count = count
  return M.t(k, params)
end

return M
