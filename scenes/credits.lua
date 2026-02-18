-- scenes/credits.lua
local M = {}

local i18n = require("core.i18n")
local input = require("core.input")
local router = require("core.router")
local platform = require("platform.love")

function M.new()
  local self = {}
  self.enter = function() end
  self.exit = function() end
  self.pause = function() end
  self.resume = function() end
  self.update = function(dt)
    if platform.mouse_consume_click(1) then
      router.dispatch("scene:pop")
      return
    end
    if input.consume("back") or input.consume("confirm") then
      router.dispatch("scene:pop")
    end
  end
  self.draw = function()
    local w, h = platform.gfx_width(), platform.gfx_height()
    local layout = require("core.ui_layout").get("credits")
    local pad = layout.panel_padding or 60
    local colors = require("core.ui_layout").colors()

    platform.gfx_draw_rect("fill", 0, 0, w, h, colors.bg_dark or { 0.05, 0.04, 0.10, 1 })
    platform.gfx_draw_rect("fill", pad, pad, w - pad * 2, h - pad * 2, colors.panel or { 0.06, 0.05, 0.14, 0.92 })
    platform.gfx_draw_rect("line", pad, pad, w - pad * 2, h - pad * 2, colors.panel_border or { 1, 0.55, 0.15, 1 })

    local title = i18n.t("ui.credits.title")
    platform.gfx_draw_text(title, pad + 24, layout.title_offset or 80)
    local lines = i18n.t("ui.credits.default_text")
    platform.gfx_draw_text(lines, pad + 24, layout.content_offset or 120)
  end
  return self
end

return M
