-- core/config.lua - Config data-driven chargee/sauvegardee
local M = {}
local fs = require("core.fs")
local log = require("core.log")

local DEFAULTS = {
  locale = "en",
  fullscreen = false,
  width = 800,
  height = 600,
  volume = 100,
}

local _config = {}
local _path = nil

local function serialize_table(t, indent)
  indent = indent or 0
  local lines = {}
  for k, v in pairs(t) do
    local key = type(k) == "string" and ("[\"%s\"]"):format(k) or ("[%s]"):format(k)
    if type(v) == "table" and not (v._serialize) then
      table.insert(lines, ("  "):rep(indent) .. key .. " = {")
      table.insert(lines, serialize_table(v, indent + 1))
      table.insert(lines, ("  "):rep(indent) .. "},")
    elseif type(v) == "string" then
      table.insert(lines, ("  "):rep(indent) .. key .. " = \"" .. v:gsub("\\", "\\\\"):gsub('"', '\\"') .. "\",")
    elseif type(v) == "number" or type(v) == "boolean" then
      table.insert(lines, ("  "):rep(indent) .. key .. " = " .. tostring(v) .. ",")
    end
  end
  return table.concat(lines, "\n")
end

function M.init()
  _path = fs.get_config_path()
  for k, v in pairs(DEFAULTS) do
    _config[k] = v
  end
  M.load()
end

function M.load()
  if not _path or not fs.exists(_path) then return end
  local ok, chunk = pcall(fs.read, _path)
  if not ok or not chunk then return end
  local fn, err = loadstring(chunk)
  if not fn then
    log.warn("config.load parse error:", err)
    return
  end
  local ok2, data = pcall(fn)
  if ok2 and data and type(data) == "table" then
    for k, v in pairs(data) do
      _config[k] = v
    end
  end
end

function M.save()
  if not _path then return end
  local content = "return {\n" .. serialize_table(_config, 1) .. "\n}"
  local ok, err = pcall(fs.write, _path, content)
  if not ok then log.warn("config.save error:", err) end
end

function M.get(key)
  return _config[key]
end

function M.set(key, value)
  _config[key] = value
end

return M
