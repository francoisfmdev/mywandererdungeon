-- core/hub_screen.lua - Factory scene hub data-driven
local M = {}

local fs = require("core.fs")
local i18n = require("core.i18n")
local input = require("core.input")
local router = require("core.router")
local platform = require("platform.love")
local asset_manager = require("core.asset_manager")

local _layout = nil

local function load_layout()
  if _layout then return _layout end
  local path = "data/ui_layout.lua"
  if not fs.exists(path) then return {} end
  local ok, chunk = pcall(fs.read, path)
  if not ok or not chunk then return {} end
  local fn, err = loadstring(chunk)
  if not fn then return {} end
  local env = {}
  setmetatable(env, { __index = _G })
  setfenv(fn, env)
  local ok2, data = pcall(fn)
  if ok2 and data and data.hub then _layout = data.hub end
  return _layout or {}
end

local function load_data(path)
  if not fs.exists(path) then return nil end
  local ok, chunk = pcall(fs.read, path)
  if not ok or not chunk then return nil end
  local fn, err = loadstring(chunk)
  if not fn then return nil end
  local env = {}
  setmetatable(env, { __index = _G })
  setfenv(fn, env)
  local ok2, data = pcall(fn)
  return ok2 and data or nil
end

function M.create(data_path)
  local data = load_data(data_path)
  if not data then return nil end

  local layout = load_layout()
  local bh = layout.button_height or 50
  local gap = layout.button_gap or 16
  local start_offset = layout.start_y_offset or 90
  local margin_min = layout.margin_min or 60
  local width_ratio = layout.width_ratio or 0.72

  local buttons = data.buttons or {}
  local background_key = data.background or "hub_room"

  local self = {}
  local _selected = 1

  self.enter = function()
    _selected = 1
  end
  self.exit = function() end
  self.pause = function() end
  self.resume = function() end

  self.update = function(dt)
    local w = platform.gfx_width()
    local h = platform.gfx_height()
    local panel_w = math.floor(w * width_ratio)
    local bw = math.min(layout.button_width or 420, panel_w - 96)
    local total_h = #buttons * (bh + gap) - gap
    local box_h = total_h + 140
    local panel_h = box_h + 100
    local panel_y = margin_min
    local start_y = panel_y + start_offset

    local mx, my = platform.mouse_get_position()
    for i = 1, #buttons do
      local bx = (w - bw) / 2
      local by = panel_y + start_offset + (i - 1) * (bh + gap)
      if mx >= bx and mx < bx + bw and my >= by and my < by + bh then
        _selected = i
        if platform.mouse_consume_click(1) then
          local action = buttons[i].action
          if action then router.dispatch(action) end
        end
        return
      end
    end
    if platform.mouse_consume_click(1) then return end

    if input.consume("up") then
      _selected = _selected - 1
      if _selected < 1 then _selected = #buttons end
    elseif input.consume("down") then
      _selected = _selected + 1
      if _selected > #buttons then _selected = 1 end
    elseif input.consume("confirm") then
      local action = buttons[_selected] and buttons[_selected].action
      if action then router.dispatch(action) end
    elseif input.consume("back") then
      router.dispatch("scene:pop")
    end
  end

  self.draw = function()
    local w = platform.gfx_width()
    local h = platform.gfx_height()

    local img = asset_manager.get_image(background_key)
    if img then
      platform.gfx_draw_image(img, 0, 0, w, h)
    else
      platform.gfx_draw_rect("fill", 0, 0, w, h, { 0.08, 0.06, 0.12, 1 })
    end

    local panel_w = math.floor(w * width_ratio)
    local bw = math.min(layout.button_width or 420, panel_w - 96)
    local total_h = #buttons * (bh + gap) - gap
    local box_h = total_h + 140
    local panel_h = math.min(box_h + 100, h - margin_min * 2)
    local panel_x = (w - panel_w) / 2
    local panel_y = margin_min

    local colors = require("core.ui_layout").colors()
    platform.gfx_draw_rect("fill", panel_x, panel_y, panel_w, panel_h, colors.panel or { 0.06, 0.05, 0.14, 0.92 })
    platform.gfx_draw_rect("line", panel_x, panel_y, panel_w, panel_h, colors.panel_border or { 1, 0.55, 0.15, 1 })

    if data.title_key then
      local title = i18n.t(data.title_key)
      local tw = platform.gfx_get_font():getWidth(title)
      platform.gfx_draw_text(title, (w - tw) / 2, panel_y + 24)
    end

    local start_y = panel_y + start_offset
    for i = 1, #buttons do
      local btn = buttons[i]
      local label = i18n.t(btn.label or "hub.unknown")
      local bx = (w - bw) / 2
      local by = start_y + (i - 1) * (bh + gap)

      local is_sel = (i == _selected)
      local colors = require("core.ui_layout").colors()
      local fill = is_sel and (colors.button_sel or { 0.15, 0.3, 0.8, 0.18 }) or (colors.button or { 0.12, 0.22, 0.6, 0.08 })
      platform.gfx_draw_rect("fill", bx, by, bw, bh, fill)
      platform.gfx_draw_rect("line", bx, by, bw, bh, colors.panel_border or { 1, 0.55, 0.15, 1 })

      local font = platform.gfx_get_font()
      local prefix = is_sel and "> " or "  "
      local lw = font:getWidth(prefix .. label)
      local th = font:getHeight()
      platform.gfx_draw_text(prefix .. label, (w - lw) / 2, by + (bh - th) / 2)
    end

    if data.hint_key then
      platform.gfx_draw_text(i18n.t(data.hint_key), 10, h - 28)
    end
  end

  return self
end

return M
