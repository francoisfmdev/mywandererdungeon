-- core/game_log/log_entry.lua - Entree de log
local M = {}

function M.new(eventType, messageKey, params, turnNumber)
  return {
    timestamp = turnNumber or 0,
    type = eventType or "info",
    messageKey = messageKey or "log.info.unknown",
    params = params or {},
  }
end

return M
