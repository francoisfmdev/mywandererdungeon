-- scenes/hub/stats.lua - Affichage stats via Character module
local M = {}

local i18n = require("core.i18n")
local input = require("core.input")
local router = require("core.router")
local platform = require("platform.love")
local asset_manager = require("core.asset_manager")
local character = require("core.character")

local STAT_KEYS = { "strength", "dexterity", "constitution", "intelligence", "wisdom", "charisma" }

function M.new()
  local self = {}
  local _char = nil

  self.enter = function()
    _char = require("core.game_state").get_character()
    if not _char then _char = require("core.game_state").reset() end
  end
  self.exit = function() end
  self.pause = function() end
  self.resume = function() end

  self.update = function(dt)
    if input.consume("back") or input.consume("confirm") then
      router.dispatch("scene:pop")
    end
    if platform.mouse_consume_click(1) then
      router.dispatch("scene:pop")
    end
  end

  self.draw = function()
    local w = platform.gfx_width()
    local h = platform.gfx_height()
    local img = asset_manager.get_image("house_room")
    if img then
      platform.gfx_draw_image(img, 0, 0, w, h)
    else
      platform.gfx_draw_rect("fill", 0, 0, w, h, { 0.08, 0.06, 0.12, 1 })
    end

    local colors = require("core.ui_layout").colors()
    platform.gfx_draw_rect("fill", 48, 48, w - 96, h - 96, colors.panel or { 0.06, 0.05, 0.14, 0.92 })
    platform.gfx_draw_rect("line", 48, 48, w - 96, h - 96, colors.panel_border or { 1, 0.55, 0.15, 1 })

    local title = i18n.t("hub.house.view_stats")
    platform.gfx_draw_text(title, (w - platform.gfx_get_font():getWidth(title)) / 2, 72)

    if _char then
      local y = 130
      for _, stat in ipairs(STAT_KEYS) do
        local label = i18n.t("hub.stats." .. stat)
        local val = _char:getStat(stat)
        local mod = _char:getStatModifier(stat)
        platform.gfx_draw_text(label .. ": " .. val .. " (" .. (mod >= 0 and "+" or "") .. mod .. ")", 72, y)
        y = y + 28
      end
    end

    local hint = i18n.t("hub.back_hint")
    platform.gfx_draw_text(hint, 48, h - 40)
  end

  return self
end

return M
