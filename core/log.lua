-- core/log.lua - Logging minimal debug
local M = {}

local LEVELS = { debug = 1, info = 2, warn = 3, error = 4 }
local current = LEVELS.debug

function M.set_level(name)
  current = LEVELS[name] or LEVELS.debug
end

function M._log(level, ...)
  if LEVELS[level] >= current then
    local parts = { "[", level:upper(), "] ", ... }
    print(table.concat(parts))
  end
end

function M.debug(...) M._log("debug", ...) end
function M.info(...)  M._log("info", ...) end
function M.warn(...)  M._log("warn", ...) end
function M.error(...) M._log("error", ...) end

return M
