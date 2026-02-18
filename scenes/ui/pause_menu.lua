-- scenes/ui/pause_menu.lua - Menu pause (ESC)
local M = {}

local router = require("core.router")
local dungeon_run_state = require("core.dungeon_run_state")
local menu_renderer = require("core.ui.menu_renderer")
local menu_controller = require("core.ui.menu_controller")
local platform = require("platform.love")
local i18n = require("core.i18n")

local function load_menu_data()
  local fs = require("core.fs")
  local path = "data/ui/pause_menu.lua"
  if not fs.exists(path) then return { items = {}, layout = {} } end
  local ok, chunk = pcall(fs.read, path)
  if not ok or not chunk then return { items = {}, layout = {} } end
  local fn, err = loadstring(chunk)
  if not fn then return { items = {}, layout = {} } end
  local env = {}
  setmetatable(env, { __index = _G })
  setfenv(fn, env)
  local ok2, data = pcall(fn)
  return (ok2 and data) or { items = {}, layout = {} }
end

function M.new()
  local self = {}
  local _data = load_menu_data()
  local _items = _data.items or {}
  local _layout = _data.layout or {}
  local _sel = 1
  local _savedAt = nil

  local function execute_action(action)
    if not action or type(action) ~= "string" then return end
    if action == "scene:pop" then
      router.dispatch("scene:pop")
      return
    end
    if action == "pause:save" then
      local save = require("core.save")
      if save.save() then
        _savedAt = love and love.timer and love.timer.getTime and love.timer.getTime() or 0
      end
      return
    end
    if action == "scene:push:options" then
      router.dispatch("scene:push:options")
      return
    end
    if action == "pause:quit_to_hub" then
      dungeon_run_state.clear()
      router.dispatch("scene:replace:hub_main")
      return
    end
    if action == "quit:" then
      router.dispatch("quit:")
      return
    end
    router.dispatch(action)
  end

  self.enter = function()
    _sel = 1
    _savedAt = nil
  end
  self.exit = function() end
  self.pause = function() end
  self.resume = function() end

  self.update = function(dt)
    if _savedAt then
      local t = love and love.timer and love.timer.getTime and love.timer.getTime() or 0
      if t - _savedAt > 1.2 then
        _savedAt = nil
        router.dispatch("scene:pop")
      end
      return
    end
    local function onConfirm(item, _)
      if item and item.action then
        execute_action(item.action)
      end
    end
    local function onBack()
      router.dispatch("scene:pop")
    end
    local function getBounds(i)
      return menu_renderer.get_item_bounds(_items, i, _layout)
    end
    _sel = menu_controller.update(_items, _sel, {
      onConfirm = onConfirm,
      onBack = onBack,
      getBoundsForIndex = getBounds,
    })
  end

  self.draw = function()
    menu_renderer.draw_centered_menu(_items, _sel, _layout)
    local hint = i18n.t("ui.menu.hint_nav")
    if _savedAt then
      hint = i18n.t("dungeon.menu.saved")
      platform.gfx_draw_text(hint, 10, platform.gfx_height() - 28)
    else
      platform.gfx_draw_text(hint, 10, platform.gfx_height() - 28)
    end
  end

  return self
end

return M
