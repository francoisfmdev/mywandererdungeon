-- core/ui/menu_renderer.lua - Rendu menu generique centre ou barre integratee (Shiren/PMD)
local M = {}

local platform = require("platform.love")
local i18n = require("core.i18n")

local function get_colors()
  local layout = require("core.ui_layout")
  return layout and layout.colors and layout.colors() or {
    panel = { 0.06, 0.05, 0.14, 0.92 },
    panel_border = { 1, 0.55, 0.15, 1 },
    button = { 0.12, 0.22, 0.6, 0.08 },
    button_sel = { 0.15, 0.3, 0.8, 0.18 },
    bg_overlay = { 0.02, 0.02, 0.08, 0.85 },
  }
end

M.BOTTOM_RAISE = 0.10  -- 10% hauteur pour éviter chevauchement avec texte donjon
local BOTTOM_RAISE = M.BOTTOM_RAISE

--- Menu integre en barre en bas (donjon reste visible, style Shiren/PMD)
function M.draw_bottom_menu(items, selectedIndex, layout)
  layout = layout or {}
  local w = platform.gfx_width()
  local h = platform.gfx_height()
  local lineH = layout.line_height or 32
  local pad = layout.padding or 12
  local barH = #items * lineH + pad * 2
  local barY = h - barH - h * BOTTOM_RAISE

  local colors = get_colors()
  platform.gfx_draw_rect("fill", 0, barY, w, barH, { 0.08, 0.06, 0.18, 0.95 })
  platform.gfx_draw_rect("line", 0, barY, w, barH, colors.panel_border)

  local itemW = math.floor((w - pad * 2) / #items)
  for i, item in ipairs(items) do
    local label = type(item.label) == "string" and i18n.t(item.label) or tostring(item.label)
    local ix = pad + (i - 1) * itemW
    local iy = barY + pad
    local isSel = (i == selectedIndex)
    local fill = isSel and colors.button_sel or colors.button
    platform.gfx_draw_rect("fill", ix, iy, itemW - 4, lineH - 2, fill)
    platform.gfx_draw_rect("line", ix, iy, itemW - 4, lineH - 2, colors.panel_border)
    local tw = platform.gfx_get_font():getWidth(label)
    platform.gfx_draw_text(label, ix + (itemW - 4 - tw) / 2, iy + (lineH - 2) / 2 - 8)
  end
end

function M.draw_centered_menu(items, selectedIndex, layout)
  layout = layout or {}
  local w = platform.gfx_width()
  local h = platform.gfx_height()
  local boxW = layout.box_width or 280
  local boxH = layout.box_height or (#items * (layout.line_height or 36))
  local lineH = layout.line_height or 36
  local pad = layout.padding or 16

  local cx = (w - boxW) / 2
  local cy = (h - boxH) / 2
  local colors = get_colors()

  platform.gfx_draw_rect("fill", 0, 0, w, h, colors.bg_overlay or { 0.02, 0.02, 0.08, 0.85 })
  platform.gfx_draw_rect("fill", cx - 4, cy - 4, boxW + 8, boxH + 8, colors.panel)
  platform.gfx_draw_rect("line", cx - 4, cy - 4, boxW + 8, boxH + 8, colors.panel_border)

  for i, item in ipairs(items) do
    local label = type(item.label) == "string" and i18n.t(item.label) or tostring(item.label)
    local by = cy + (i - 1) * lineH
    local isSel = (i == selectedIndex)
    local fill = isSel and colors.button_sel or colors.button
    platform.gfx_draw_rect("fill", cx, by, boxW, lineH - 2, fill)
    platform.gfx_draw_rect("line", cx, by, boxW, lineH - 2, colors.panel_border)
    platform.gfx_draw_text((isSel and "> " or "  ") .. label, cx + pad, by + (lineH - 2) / 2 - 8)
  end
end

function M.get_item_bounds(items, itemIndex, layout)
  layout = layout or {}
  local w = platform.gfx_width()
  local h = platform.gfx_height()
  local boxW = layout.box_width or 280
  local lineH = layout.line_height or 36
  local boxH = #items * lineH
  local cx = (w - boxW) / 2
  local cy = (h - boxH) / 2
  local by = cy + (itemIndex - 1) * lineH
  return cx, by, boxW, lineH - 2
end

function M.get_bottom_menu_bounds(items, itemIndex, layout)
  layout = layout or {}
  local w = platform.gfx_width()
  local h = platform.gfx_height()
  local lineH = layout.line_height or 32
  local pad = layout.padding or 12
  local barH = #items * lineH + pad * 2
  local barY = h - barH - h * BOTTOM_RAISE
  local itemW = math.floor((w - pad * 2) / #items)
  local ix = pad + (itemIndex - 1) * itemW
  local iy = barY + pad
  return ix, iy, itemW - 4, lineH - 2
end

return M
