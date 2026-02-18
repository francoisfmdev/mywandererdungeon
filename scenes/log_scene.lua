-- scenes/log_scene.lua - Vue complete du journal de jeu
local M = {}

local i18n = require("core.i18n")
local input = require("core.input")
local router = require("core.router")
local platform = require("platform.love")
local log_manager = require("core.game_log.log_manager")

local _scroll = 0
local _lineHeight = 18
local _pad = 20

local function get_entries()
  return log_manager.get_all()
end

local function format_entry(entry)
  return i18n.t(entry.messageKey or "log.info.unknown", entry.params or {})
end

function M.new()
  local self = {}
  self.id = "log"

  self.enter = function()
    _scroll = 0
  end
  self.exit = function() end
  self.pause = function() end
  self.resume = function() end

  self.update = function(dt)
    if input.consume("back") then
      router.dispatch("scene:pop")
      return
    end

    local entries = get_entries()
    local w = platform.gfx_width()
    local h = platform.gfx_height()
    local visibleLines = math.max(1, math.floor((h - _pad * 3 - 40) / _lineHeight))
    local maxScroll = math.max(0, #entries - visibleLines)

    if input.consume("up") then
      _scroll = _scroll + 1
      if _scroll > maxScroll then _scroll = maxScroll end
    elseif input.consume("down") then
      _scroll = _scroll - 1
      if _scroll < 0 then _scroll = 0 end
    end
  end

  self.draw = function()
    local w = platform.gfx_width()
    local h = platform.gfx_height()

    local colors = require("core.ui_layout").colors()
    platform.gfx_draw_rect("fill", 0, 0, w, h, colors.bg_dark or { 0.05, 0.04, 0.10, 1 })
    platform.gfx_draw_rect("fill", _pad, _pad, w - _pad * 2, h - _pad * 2, colors.panel or { 0.06, 0.05, 0.14, 0.92 })
    platform.gfx_draw_rect("line", _pad, _pad, w - _pad * 2, h - _pad * 2, colors.panel_border or { 1, 0.55, 0.15, 1 })

    local title = i18n.t("log.title")
    platform.gfx_draw_text(title, _pad, _pad)

    local entries = get_entries()
    local startY = _pad + 30
    local visibleLines = math.floor((h - startY - _pad - 30) / _lineHeight)

    if #entries == 0 then
      platform.gfx_draw_text(i18n.t("log.empty"), _pad, startY)
    else
      -- Affichage: plus récent en haut (comme l'aperçu 3 lignes), plus vieux en bas. _scroll=0 = on voit les derniers
      local n = math.min(visibleLines, #entries)
      for i = 1, n do
        local idx = #entries - _scroll - i + 1
        if idx >= 1 then
          local entry = entries[idx]
          local y = startY + (i - 1) * _lineHeight
          local text = format_entry(entry)
          if #text > 120 then
            text = text:sub(1, 117) .. "..."
          end
          platform.gfx_draw_text(text, _pad + 10, y)
        end
      end
    end

    platform.gfx_draw_text(i18n.t("log.hint"), _pad, h - _pad)
  end

  return self
end

return M
