-- scenes/options.lua
local M = {}

local fs = require("core.fs")
local i18n = require("core.i18n")
local input = require("core.input")
local router = require("core.router")
local config = require("core.config")
local platform = require("platform.love")

local _selected = 1
local _locales = { "en", "fr" }
local _total_rows = 5
local _options_data = nil

local function load_options_data()
  if _options_data then return _options_data end
  local path = "data/ui/options.lua"
  if not fs.exists(path) then return {} end
  local ok, chunk = pcall(fs.read, path)
  if not ok or not chunk then return {} end
  local fn, err = loadstring(chunk)
  if not fn then return {} end
  local env = {}
  setmetatable(env, { __index = _G })
  setfenv(fn, env)
  local ok2, data = pcall(fn)
  if ok2 and data then _options_data = data end
  return _options_data or {}
end

local function get_resolution_index()
  local data = load_options_data()
  local ress = data.resolutions or { { 800, 600 } }
  local w = config.get("width") or 800
  local h = config.get("height") or 600
  for i, r in ipairs(ress) do
    if r[1] == w and r[2] == h then return i end
  end
  return 1
end

function M.new()
  local self = {}
  local res_idx = 1

  self.enter = function()
    res_idx = get_resolution_index()
  end
  self.exit = function() end
  self.pause = function() end
  self.resume = function()
    res_idx = get_resolution_index()
  end
  self.update = function(dt)
    local w, h = platform.gfx_width(), platform.gfx_height()
    local layout = require("core.ui_layout").get("options")
    local bw = layout.button_width or 400
    local bh = layout.button_height or 48
    local gap = layout.button_gap or 14
    local box_h = _total_rows * (bh + gap) - gap + 140
    local cy = (h - box_h) / 2
    local start_y = cy + (layout.start_offset or 70)

    local dir = nil
    local mx, my = platform.mouse_get_position()
    for i = 1, _total_rows do
      local bx = (w - bw) / 2
      local by = start_y + (i - 1) * (bh + gap)
      if mx >= bx and mx < bx + bw and my >= by and my < by + bh then
        _selected = i
        if platform.mouse_consume_click(1) then
          if i == 5 then
            router.dispatch("scene:push:bindings")
            return
          else
            dir = 1
          end
        end
        break
      end
    end
    if not dir and platform.mouse_consume_click(1) then return end

    if input.consume("back") then
      router.dispatch("scene:pop")
      return
    end
    local data = load_options_data()
    local ress = data.resolutions or { { 800, 600 } }
    local vol_min = data.volume_min or 0
    local vol_max = data.volume_max or 100
    local vol_step = data.volume_step or 5
    local vol = config.get("volume") or 100

    if input.consume("up") then
      _selected = _selected - 1
      if _selected < 1 then _selected = _total_rows end
    elseif input.consume("down") then
      _selected = _selected + 1
      if _selected > _total_rows then _selected = 1 end
    elseif _selected == 5 and input.consume("confirm") then
      router.dispatch("scene:push:bindings")
    else
      if not dir then
        if input.consume("right") then dir = 1
        elseif input.consume("left") then dir = -1
        end
      end
      if dir and _selected <= 4 then
        if _selected == 1 then -- locale
          local cur = 1
          for i, l in ipairs(_locales) do
            if l == config.get("locale") then cur = i break end
          end
          cur = cur + dir
          if cur < 1 then cur = #_locales end
          if cur > #_locales then cur = 1 end
          config.set("locale", _locales[cur])
          config.save()
          i18n.set_locale(_locales[cur])
        elseif _selected == 2 then
          res_idx = res_idx + dir
          if res_idx < 1 then res_idx = #ress end
          if res_idx > #ress then res_idx = 1 end
          config.set("width", ress[res_idx][1])
          config.set("height", ress[res_idx][2])
          config.save()
          platform.window_set_mode(ress[res_idx][1], ress[res_idx][2], config.get("fullscreen"))
        elseif _selected == 3 then
          config.set("fullscreen", not config.get("fullscreen"))
          config.save()
          platform.window_set_mode(config.get("width"), config.get("height"), config.get("fullscreen"))
        elseif _selected == 4 then -- volume
          vol = vol + dir * vol_step
          if vol < vol_min then vol = vol_min end
          if vol > vol_max then vol = vol_max end
          config.set("volume", vol)
          config.save()
          platform.audio_set_volume(vol / 100)
        end
      end
    end
  end
  self.draw = function()
    local w = platform.gfx_width()
    local h = platform.gfx_height()
    local layout = require("core.ui_layout").get("options")
    local bw = layout.button_width or 400
    local bh = layout.button_height or 48
    local gap = layout.button_gap or 14
    local pad = layout.panel_padding or 48
    local box_h = _total_rows * (bh + gap) - gap + 140
    local cx = w / 2
    local cy = (h - box_h) / 2
    local colors = require("core.ui_layout").colors()

    platform.gfx_draw_rect("fill", 0, 0, w, h, colors.bg_dark or { 0.05, 0.04, 0.10, 1 })
    platform.gfx_draw_rect("fill", cx - bw/2 - pad, cy - (layout.title_offset or 50), bw + pad * 2, box_h, colors.panel or { 0.06, 0.05, 0.14, 0.92 })
    platform.gfx_draw_rect("line", cx - bw/2 - pad, cy - (layout.title_offset or 50), bw + pad * 2, box_h, colors.panel_border or { 1, 0.55, 0.15, 1 })

    local title = i18n.t("ui.options.title")
    local tw = platform.gfx_get_font():getWidth(title)
    platform.gfx_draw_text(title, (w - tw) / 2, cy - (layout.title_offset or 50) + 20)

    local start_y = cy + (layout.start_offset or 70)
    local labels = {
      i18n.t("ui.options.locale_label") .. ": " .. i18n.t("ui.options.locale_" .. (config.get("locale") or "en")),
      i18n.t("ui.options.resolution_label") .. ": " .. (config.get("width") or 800) .. "x" .. (config.get("height") or 600),
      i18n.t("ui.options.fullscreen_label") .. ": " .. i18n.t(config.get("fullscreen") and "ui.options.on" or "ui.options.off"),
      i18n.t("ui.options.volume_label") .. ": " .. (config.get("volume") or 100) .. "%",
      i18n.t("ui.options.bindings_label"),
    }
    for i = 1, _total_rows do
      local by = start_y + (i - 1) * (bh + gap)
      local is_sel = (i == _selected)
      local fill = is_sel and (colors.button_sel or { 0.15, 0.3, 0.8, 0.18 }) or (colors.button or { 0.12, 0.22, 0.6, 0.08 })
      platform.gfx_draw_rect("fill", (w - bw) / 2, by, bw, bh, fill)
      platform.gfx_draw_rect("line", (w - bw) / 2, by, bw, bh, colors.panel_border or { 1, 0.55, 0.15, 1 })
      local lw = platform.gfx_get_font():getWidth(labels[i])
      platform.gfx_draw_text(labels[i], (w - lw) / 2, by + (bh - platform.gfx_get_font():getHeight()) / 2)
    end
    local hint = i18n.t("ui.options.hint")
    platform.gfx_draw_text(hint, pad, h - 32)
  end
  return self
end

return M
