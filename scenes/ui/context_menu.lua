-- scenes/ui/context_menu.lua - Menu contextuel donjon (Enter/Space)
local M = {}

local router = require("core.router")
local input = require("core.input")
local platform = require("platform.love")
local menu_renderer = require("core.ui.menu_renderer")
local menu_controller = require("core.ui.menu_controller")
local i18n = require("core.i18n")

local function load_menu_data()
  local fs = require("core.fs")
  local path = "data/ui/context_menu.lua"
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

  self.enter = function()
    _sel = 1
  end
  self.exit = function() end
  self.pause = function() end
  self.resume = function() end

  local useBottomBar = (_layout.position == "bottom")
  self.update = function(dt)
    local function onConfirm(item, _)
      router.dispatch("scene:pop")
      if item and item.action then
        router.dispatch(item.action)
      end
    end
    local function onBack()
      router.dispatch("scene:pop")
    end
    local function getBounds(i)
      if useBottomBar then
        return menu_renderer.get_bottom_menu_bounds(_items, i, _layout)
      end
      return menu_renderer.get_item_bounds(_items, i, _layout)
    end
    _sel = menu_controller.update(_items, _sel, {
      onConfirm = onConfirm,
      onBack = onBack,
      getBoundsForIndex = getBounds,
      orientation = _layout.orientation or (useBottomBar and "horizontal" or "vertical"),
    })
  end

  self.draw = function()
    if useBottomBar then
      local h = platform.gfx_height()
      local barH = #_items * (_layout.line_height or 32) + (_layout.padding or 12) * 2
      menu_renderer.draw_bottom_menu(_items, _sel, _layout)
      platform.gfx_draw_text(i18n.t("ui.context.hint"), 10, h - barH - h * (menu_renderer.BOTTOM_RAISE or 0.10) - 24)
    else
      menu_renderer.draw_centered_menu(_items, _sel, _layout)
      platform.gfx_draw_text(i18n.t("ui.menu.hint_nav"), 10, platform.gfx_height() - 28)
    end
  end

  return self
end

return M
