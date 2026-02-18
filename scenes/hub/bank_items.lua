-- scenes/hub/bank_items.lua - Depot/retrait objets banque, HUD responsive
local M = {}

local i18n = require("core.i18n")
local input = require("core.input")
local router = require("core.router")
local platform = require("platform.love")
local asset_manager = require("core.asset_manager")
local player_data = require("core.player_data")
local bank_service = require("core.bank_service")
local inventory_hud = require("core.inventory_hud")
local item_display = require("core.equipment.item_display")

function M.new(initialMode)
  local self = {}
  local _mode = initialMode or "deposit"
  local _sel = 1

  self.enter = function()
    _sel = 1
  end

  self.exit = function() end
  self.pause = function() end
  self.resume = function() end

  self.update = function(dt)
    if input.consume("back") then
      router.dispatch("scene:pop")
      return
    end

    local list = _mode == "deposit" and player_data.get_inventory() or player_data.get_bank_storage()
    local n = #list

    if input.consume("up") then _sel = _sel - 1 end
    if input.consume("down") then _sel = _sel + 1 end
    if _sel < 1 then _sel = math.max(1, n) end
    if _sel > n then _sel = 1 end

    if input.consume("left") or input.consume("right") then
      _mode = _mode == "deposit" and "withdraw" or "deposit"
      _sel = 1
      return
    end

    if input.consume("confirm") and n > 0 then
      local item = list[_sel]
      if _mode == "deposit" then
        bank_service.deposit_item(_sel)
      else
        bank_service.withdraw_item(_sel)
      end
      _sel = math.min(_sel, #list)
    end
  end

  self.draw = function()
    local w = platform.gfx_width()
    local h = platform.gfx_height()
    local img = asset_manager.get_image("bank_room")
    if img then platform.gfx_draw_image(img, 0, 0, w, h)
    else platform.gfx_draw_rect("fill", 0, 0, w, h, { 0.08, 0.06, 0.12, 1 }) end

    local layout = inventory_hud.compute_layout()
    local inv = player_data.get_inventory()
    local bank = player_data.get_bank_storage()
    local list = _mode == "deposit" and inv or bank
    local lx = layout.leftX
    local rx = layout.rightX
    local ty = layout.topY
    local pw = layout.panelW
    local ph = layout.panelH
    local lh = layout.lineH

    local leftTitle = _mode == "deposit" and "hub.bank.inventory" or "hub.bank.storage"
    local rightTitle = _mode == "deposit" and "hub.bank.storage" or "hub.bank.inventory"
    inventory_hud.draw_panel(lx, ty, pw, ph, leftTitle)
    inventory_hud.draw_panel(rx, ty, pw, ph, rightTitle)

    local invY = ty + 45
    for i, item in ipairs(list) do
      local label = item_display.getDisplayName(item) .. " x1"
      local slotY = invY + (i - 1) * (lh + 4)
      local isSel = (i == _sel)
      inventory_hud.draw_item_slot(lx + 10, slotY, pw - 20, lh + 4, label, isSel)
    end

    platform.gfx_draw_text(i18n.t("hub.character.gold") .. ": " .. player_data.get_gold(), lx, ty + ph + 15)
    platform.gfx_draw_text(i18n.t("hub.bank.gold_stored") .. ": " .. player_data.get_bank_gold(), rx, ty + ph + 15)
    platform.gfx_draw_text(i18n.t("hub.bank.tab_hint"), w / 2 - 100, h - 50)
    inventory_hud.draw_hint(h - 30, "hub.inventory.hint")
  end

  return self
end

return M
