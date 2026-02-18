-- scenes/hub/character.lua - Feuille de personnage complete (stats, resistances, XP, etc.)
local M = {}

local i18n = require("core.i18n")
local input = require("core.input")
local router = require("core.router")
local platform = require("platform.love")
local asset_manager = require("core.asset_manager")

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

  local function draw_line(x, y, label, val)
    platform.gfx_draw_text(label .. ": " .. val, x, y)
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

    local title = i18n.t("hub.house.view_character")
    platform.gfx_draw_text(title, (w - platform.gfx_get_font():getWidth(title)) / 2, 72)

    if not _char then return self end

    local line_h = 22
    local pad = 72
    local y = 110

    -- Base
    draw_line(pad, y, i18n.t("hub.character.level"), tostring(_char:getLevel()))
    y = y + line_h
    draw_line(pad, y, i18n.t("hub.character.hp"), _char:getHP() .. "/" .. _char:getMaxHP())
    y = y + line_h
    draw_line(pad, y, i18n.t("hub.character.mp"), _char:getMP() .. "/" .. _char:getMaxMP())
    y = y + line_h
    draw_line(pad, y, i18n.t("hub.character.gold"), tostring(require("core.player_data").get_gold()))
    y = y + line_h + 4

    -- Experience
    local xpNext = _char:xpToNextLevel()
    if xpNext ~= nil then
      draw_line(pad, y, i18n.t("hub.character.xp"), tostring(_char:getXP()))
      y = y + line_h
      draw_line(pad, y, i18n.t("hub.character.xp_next"), tostring(xpNext))
    else
      draw_line(pad, y, i18n.t("hub.character.xp"), tostring(_char:getXP()) .. " (" .. i18n.t("hub.character.xp_max") .. ")")
    end
    y = y + line_h + 4

    -- Points de stats
    local pts = _char:getStatPoints()
    if pts > 0 then
      draw_line(pad, y, i18n.t("hub.character.stat_points"), tostring(pts))
      y = y + line_h + 4
    end

    -- Stats (2 colonnes)
    local RESISTANCE_ORDER = { "slashing", "piercing", "blunt", "fire", "ice", "lightning", "water", "earth", "vegetal", "poison", "light", "dark", "physical" }
    local yStats = y
    local col2 = math.floor(w / 2) + 20
    for i, stat in ipairs(STAT_KEYS) do
      local label = i18n.t("hub.stats." .. stat)
      local val = _char:getStat(stat)
      local mod = _char:getStatModifier(stat)
      local modStr = (mod >= 0 and "+" or "") .. mod
      local col, row = (i <= 3) and pad or col2, (i <= 3) and (i - 1) or (i - 4)
      draw_line(col, yStats + row * line_h, label, val .. " (" .. modStr .. ")")
    end
    y = yStats + 3 * line_h + 4

    -- Resistances (equipement)
    local res = _char:getEffectiveResistances()
    if res and next(res) then
      platform.gfx_draw_text(i18n.t("hub.character.resistances") .. ":", pad, y)
      y = y + line_h
      for _, rtype in ipairs(RESISTANCE_ORDER) do
        local val = res[rtype]
        if val ~= nil then
          local label = i18n.t("hub.resistances." .. rtype) or rtype
          draw_line(pad + 20, y, label, (val >= 0 and "+" or "") .. val .. "%")
          y = y + line_h
        end
      end
    end

    local hint = i18n.t("hub.back_hint")
    platform.gfx_draw_text(hint, 48, h - 40)
  end

  return self
end

return M
