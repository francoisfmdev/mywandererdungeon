-- core/inventory_hud.lua - HUD responsive inventaire/equipement
local M = {}

local platform = require("platform.love")
local i18n = require("core.i18n")

local function scale(w, h, baseW, baseH)
  local sw = w / baseW
  local sh = h / baseH
  return math.min(sw, sh, 2)
end

function M.compute_layout(mode)
  local w = platform.gfx_width()
  local h = platform.gfx_height()
  local s = scale(w, h, 800, 600)
  local layout = require("core.ui_layout").get("inventory")
  local basePad = layout.pad or 32
  local pad = math.floor(basePad * s)
  local lineH = math.floor((layout.line_height or 26) * s)
  local btnH = math.floor(40 * s)
  local minW = layout.panel_min_width or 380
  local minH = layout.panel_min_height or 420
  local panelW = math.floor(math.max(minW * s, math.min(400 * s, w / 2 - pad * 2)))
  local panelH = math.floor(math.max(minH * s, math.min(450 * s, h - pad * 4)))
  return {
    w = w, h = h, s = s, pad = pad,
    lineH = lineH, btnH = btnH,
    panelW = panelW, panelH = panelH,
    leftX = pad,
    rightX = w - pad - panelW,
    topY = pad,
  }
end

function M.draw_panel(x, y, w, h, titleKey)
  local colors = require("core.ui_layout").colors()
  platform.gfx_draw_rect("fill", x, y, w, h, colors.panel or { 0.06, 0.05, 0.14, 0.92 })
  platform.gfx_draw_rect("line", x, y, w, h, colors.panel_border or { 1, 0.55, 0.15, 1 })
  local title = i18n.t(titleKey or "hub.unknown")
  local tw = platform.gfx_get_font():getWidth(title)
  platform.gfx_draw_text(title, x + (w - tw) / 2, y + 14)
end

function M.draw_item_slot(x, y, w, h, label, selected)
  local colors = require("core.ui_layout").colors()
  local fill = selected and (colors.button_sel or { 0.15, 0.35, 0.8, 0.18 }) or (colors.button or { 0.1, 0.15, 0.4, 0.12 })
  platform.gfx_draw_rect("fill", x, y, w, h, fill)
  platform.gfx_draw_rect("line", x, y, w, h, colors.panel_border or { 1, 0.55, 0.15, 0.8 })
  platform.gfx_draw_text(label or "", x + 8, y + (h - platform.gfx_get_font():getHeight()) / 2)
end

function M.draw_hint(y, hintKey)
  local w = platform.gfx_width()
  local h = platform.gfx_height()
  local hint = i18n.t(hintKey or "hub.back_hint")
  platform.gfx_draw_text(hint, 20, h - 30)
end

return M
