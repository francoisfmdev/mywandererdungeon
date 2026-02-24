-- core/log_font.lua - Police du journal (cachee, fallback si fichier absent)
local M = {}

local _font = nil

function M.get()
  if _font then return _font end
  local ui = require("core.ui_layout")
  local cfg = ui.get("log") or {}
  local path = cfg.font_path
  local size = tonumber(cfg.font_size) or 16
  local platform = require("platform.love")
  if platform.gfx_load_font then
    _font = platform.gfx_load_font(path, size)
  end
  return _font
end

function M.clear_cache()
  _font = nil
end

return M
