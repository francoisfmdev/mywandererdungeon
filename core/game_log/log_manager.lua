-- core/game_log/log_manager.lua - Buffer log 200 lignes, i18n
local M = {}

local LogEntry = require("core.game_log.log_entry")

local _entries = {}
local _maxEntries = 200
local _turnNumber = 0

function M.set_turn(n)
  _turnNumber = tonumber(n) or 0
end

function M.get_turn()
  return _turnNumber
end

function M.add(eventType, payload)
  if not payload or type(payload) ~= "table" then return end
  local messageKey = payload.messageKey or "log.info.unknown"
  local params = payload.params or {}
  local entry = LogEntry.new(eventType, messageKey, params, _turnNumber)
  table.insert(_entries, entry)
  while #_entries > _maxEntries do
    table.remove(_entries, 1)
  end
end

function M.get_recent(count)
  local n = math.min(tonumber(count) or 10, #_entries)
  local out = {}
  for i = #_entries - n + 1, #_entries do
    if i >= 1 then table.insert(out, _entries[i]) end
  end
  return out
end

function M.get_all()
  local out = {}
  for _, e in ipairs(_entries) do table.insert(out, e) end
  return out
end

function M.clear()
  _entries = {}
end

function M.get_max_entries()
  return _maxEntries
end

function M.set_max_entries(n)
  _maxEntries = math.max(1, tonumber(n) or 200)
  while #_entries > _maxEntries do
    table.remove(_entries, 1)
  end
end

return M
