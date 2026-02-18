-- scenes/bindings.lua - Personnalisation des touches
local M = {}

local fs = require("core.fs")
local i18n = require("core.i18n")
local input = require("core.input")
local router = require("core.router")
local config = require("core.config")
local platform = require("platform.love")

local _selected = 1
local _waiting_action = nil
local _actions_order = { "up", "down", "left", "right", "confirm", "back" }
local _bindings_data = nil

local function load_bindings_data()
  if _bindings_data then return _bindings_data end
  local path = "data/ui/bindings.lua"
  if not fs.exists(path) then return { actions = _actions_order } end
  local ok, chunk = pcall(fs.read, path)
  if not ok or not chunk then return { actions = _actions_order } end
  local fn, err = loadstring(chunk)
  if not fn then return { actions = _actions_order } end
  local env = {}
  setmetatable(env, { __index = _G })
  setfenv(fn, env)
  local ok2, data = pcall(fn)
  if ok2 and data then _bindings_data = data end
  return _bindings_data or { actions = _actions_order }
end

local function on_raw_key(key)
  if key == "escape" then
    platform.set_raw_key_listener(nil)
    _waiting_action = nil
    return
  end
  if _waiting_action then
    input.set_binding(_waiting_action, { key })
    config.set("bindings", input.get_bindings_copy())
    config.save()
    platform.set_raw_key_listener(nil)
    _waiting_action = nil
  end
end

local function format_key_display(key)
  local map = {
    ["return"] = "Enter", kpenter = "Num Enter",
    up = "Up", down = "Down", left = "Left", right = "Right",
    escape = "Esc", space = "Space",
  }
  return map[key] or key
end

function M.new()
  local self = {}
  local data = load_bindings_data()
  local actions = data.actions or _actions_order

  self.enter = function()
    _selected = 1
    _waiting_action = nil
  end
  self.exit = function()
    platform.set_raw_key_listener(nil)
    _waiting_action = nil
  end
  self.pause = function() end
  self.resume = function() end
  self.update = function(dt)
    if _waiting_action then return end
    local w, h = platform.gfx_width(), platform.gfx_height()
    local layout = require("core.ui_layout").get("bindings")
    local bw = layout.button_width or 420
    local bh = layout.button_height or 48
    local gap = layout.button_gap or 14
    local box_h = #actions * (bh + gap) - gap + 120
    local cy = (h - box_h) / 2
    local start_y = cy + (layout.start_offset or 70)
    local mx, my = platform.mouse_get_position()
    for i = 1, #actions do
      local bx = (w - bw) / 2
      local by = start_y + (i - 1) * (bh + gap)
      if mx >= bx and mx < bx + bw and my >= by and my < by + bh then
        _selected = i
        if platform.mouse_consume_click(1) then
          _waiting_action = actions[i]
          platform.set_raw_key_listener(on_raw_key)
        end
        break
      end
    end
    if platform.mouse_consume_click(1) then return end

    if input.consume("back") then
      router.dispatch("scene:pop")
      return
    end
    if input.consume("up") then
      _selected = _selected - 1
      if _selected < 1 then _selected = #actions end
    elseif input.consume("down") then
      _selected = _selected + 1
      if _selected > #actions then _selected = 1 end
    elseif input.consume("confirm") then
      _waiting_action = actions[_selected]
      platform.set_raw_key_listener(on_raw_key)
    end
  end
  self.draw = function()
    local w = platform.gfx_width()
    local h = platform.gfx_height()
    local layout = require("core.ui_layout").get("bindings")
    local bw = layout.button_width or 420
    local bh = layout.button_height or 48
    local gap = layout.button_gap or 14
    local pad = layout.panel_padding or 48
    local box_h = #actions * (bh + gap) - gap + 120
    local cx = w / 2
    local cy = (h - box_h) / 2
    local colors = require("core.ui_layout").colors()

    platform.gfx_draw_rect("fill", 0, 0, w, h, colors.bg_dark or { 0.05, 0.04, 0.10, 1 })
    platform.gfx_draw_rect("fill", cx - bw/2 - pad, cy - (layout.title_offset or 50), bw + pad * 2, box_h, colors.panel or { 0.06, 0.05, 0.14, 0.92 })
    platform.gfx_draw_rect("line", cx - bw/2 - pad, cy - (layout.title_offset or 50), bw + pad * 2, box_h, colors.panel_border or { 1, 0.55, 0.15, 1 })

    local title = i18n.t("ui.bindings.title")
    local tw = platform.gfx_get_font():getWidth(title)
    platform.gfx_draw_text(title, (w - tw) / 2, cy - (layout.title_offset or 50) + 20)

    local bindings = input.get_bindings()
    local start_y = cy + (layout.start_offset or 70)
    for i, action in ipairs(actions) do
      local keys = bindings[action] or {}
      local parts = {}
      for _, k in ipairs(keys) do parts[#parts + 1] = format_key_display(k) end
      local key_str = #parts > 0 and table.concat(parts, ", ") or "?"
      local label = i18n.t("ui.bindings.action_" .. action) .. ": " .. key_str
      if _waiting_action == action then
        label = i18n.t("ui.bindings.press_key")
      end
      local by = start_y + (i - 1) * (bh + gap)
      local is_sel = (i == _selected)
      local fill = is_sel and (colors.button_sel or { 0.15, 0.3, 0.8, 0.18 }) or (colors.button or { 0.12, 0.22, 0.6, 0.08 })
      platform.gfx_draw_rect("fill", (w - bw) / 2, by, bw, bh, fill)
      platform.gfx_draw_rect("line", (w - bw) / 2, by, bw, bh, colors.panel_border or { 1, 0.55, 0.15, 1 })
      local lw = platform.gfx_get_font():getWidth(label)
      platform.gfx_draw_text(label, (w - lw) / 2, by + (bh - platform.gfx_get_font():getHeight()) / 2)
    end
    local hint = i18n.t("ui.bindings.hint")
    platform.gfx_draw_text(hint, pad, h - 32)
  end
  return self
end

return M
