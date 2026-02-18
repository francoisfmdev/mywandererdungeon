-- scenes/main_menu.lua
local M = {}

local fs = require("core.fs")
local i18n = require("core.i18n")
local input = require("core.input")
local router = require("core.router")
local platform = require("platform.love")

local _data = nil
local _selected = 1
local _items = {}

local function load_menu_data()
  if _data then return _data end
  local path = "data/ui/main_menu.lua"
  if not fs.exists(path) then return nil end
  local ok, chunk = pcall(fs.read, path)
  if not ok or not chunk then return nil end
  local fn, err = loadstring(chunk)
  if not fn then return nil end
  local env = {}
  setmetatable(env, { __index = _G })
  setfenv(fn, env)
  local ok2, data = pcall(fn)
  if ok2 and data then _data = data end
  return _data
end

local function build_items()
  _items = {}
  local data = load_menu_data()
  if not data or not data.items then return end
  local save = require("core.save")
  for i, item in ipairs(data.items) do
    local show = true
    if item.visible == false then show = false
    elseif item.visible == "has_save" then show = save.has_save()
    end
    if show then table.insert(_items, item) end
  end
  if _selected > #_items then _selected = math.max(1, #_items) end
end

function M.new()
  local self = {}
  self.enter = function()
    build_items()
    _selected = 1
  end
  self.exit = function() end
  self.pause = function() end
  self.resume = function() end
  self.update = function(dt)
    local w, h = platform.gfx_width(), platform.gfx_height()
    local layout = require("core.ui_layout").get("main_menu")
    local bw, bh = layout.button_width or 380, layout.button_height or 52
    local gap = layout.button_gap or 18
    local total_h = #_items * (bh + gap) - gap
    local box_h = total_h + 180
    local cy = (h - box_h) / 2
    local start_y = cy + (layout.start_offset or 80)

    local mx, my = platform.mouse_get_position()
    for i = 1, #_items do
      local bx = (w - bw) / 2
      local by = start_y + (i - 1) * (bh + gap)
      if mx >= bx and mx < bx + bw and my >= by and my < by + bh then
        _selected = i
        if platform.mouse_consume_click(1) then
          local item = _items[i]
          if item and item.action then router.dispatch(item.action) end
        end
        return
      end
    end
    if platform.mouse_consume_click(1) then return end

    if input.consume("up") then
      _selected = _selected - 1
      if _selected < 1 then _selected = #_items end
    elseif input.consume("down") then
      _selected = _selected + 1
      if _selected > #_items then _selected = 1 end
    elseif input.consume("confirm") then
      local item = _items[_selected]
      if item and item.action then
        router.dispatch(item.action)
      end
    elseif input.consume("back") then
      router.dispatch("quit:")
    end
  end
  self.draw = function()
    local w = platform.gfx_width()
    local h = platform.gfx_height()
    local layout = require("core.ui_layout").get("main_menu")
    local bw = layout.button_width or 380
    local bh = layout.button_height or 52
    local gap = layout.button_gap or 18
    local pad = layout.panel_padding or 48
    local total_h = #_items * (bh + gap) - gap
    local box_w = bw + pad * 2
    local box_h = total_h + 180
    local cx = (w - box_w) / 2
    local cy = (h - box_h) / 2
    local titleOff = layout.title_offset or 60
    local colors = require("core.ui_layout").colors()

    platform.gfx_draw_rect("fill", cx - pad, cy - titleOff, box_w + pad * 2, box_h + pad, colors.panel or { 0.06, 0.05, 0.14, 0.92 })
    platform.gfx_draw_rect("line", cx - pad, cy - titleOff, box_w + pad * 2, box_h + pad, colors.panel_border or { 1, 0.55, 0.15, 1 })
    platform.gfx_draw_rect("line", cx - pad + 2, cy - titleOff + 2, box_w + pad * 2 - 4, box_h + pad - 4, { 0.3, 0.2, 0.5, 0.4 })

    local data = load_menu_data()
    local title_key = data and data.title_key or "ui.main_menu.title"
    local title = i18n.t(title_key)
    local tw = platform.gfx_get_font():getWidth(title)
    platform.gfx_draw_text(title, (w - tw) / 2, cy - titleOff + 24)

    local start_y = cy + (layout.start_offset or 80)
    for i, item in ipairs(_items) do
      local label = i18n.t(item.i18n_key or "ui.main_menu.unknown")
      local bx = (w - bw) / 2
      local by = start_y + (i - 1) * (bh + gap)

      local is_sel = (i == _selected)
      local fill = is_sel and (colors.button_sel or { 0.15, 0.3, 0.8, 0.18 }) or (colors.button or { 0.12, 0.22, 0.6, 0.08 })

      platform.gfx_draw_rect("fill", bx, by, bw, bh, fill)
      platform.gfx_draw_rect("line", bx, by, bw, bh, colors.panel_border or { 1, 0.55, 0.15, 1 })

      local prefix = is_sel and "> " or "  "
      local font = platform.gfx_get_font()
      local lw = font:getWidth(prefix .. label)
      local th = font:getHeight()
      platform.gfx_draw_text(prefix .. label, (w - lw) / 2, by + (bh - th) / 2)
    end
  end
  return self
end

return M
