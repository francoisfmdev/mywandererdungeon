-- scenes/hub/equipment.lua - Menu equipement uniquement
local M = {}

local i18n = require("core.i18n")
local item_display = require("core.equipment.item_display")
local input = require("core.input")
local router = require("core.router")
local platform = require("platform.love")
local asset_manager = require("core.asset_manager")
local game_state = require("core.game_state")
local player_data = require("core.player_data")
local inventory_hud = require("core.inventory_hud")
local equipment_slots = require("core.equipment.equipment_slots")

local SLOT_ORDER = { "weapon_main", "weapon_off", "armor", "boots", "helmet", "cape", "necklace", "ring_1", "ring_2" }

function M.new()
  local self = {}
  local _sel = 1
  local _char = nil

  self.enter = function()
    _char = game_state.get_character()
    if not _char then _char = require("core.game_state").reset() end
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

    local equipped = _char and _char.equipmentManager:getAllEquipped() or {}
    local eqList = {}
    for _, slot in ipairs(SLOT_ORDER) do
      local item = equipped[slot]
      if item then table.insert(eqList, { slot = slot, item = item }) end
    end
    local bagEquip = player_data.get_equipment_in_bag()
    for _, be in ipairs(bagEquip) do
      table.insert(eqList, { slot = "bag", item = be.item, invIndex = be.invIndex })
    end

    local n = #eqList
    if input.consume("up") then _sel = _sel - 1 end
    if input.consume("down") then _sel = _sel + 1 end
    if _sel < 1 then _sel = math.max(1, n) end
    if _sel > n then _sel = 1 end

    if input.consume("confirm") and n > 0 then
      local entry = eqList[_sel]
      if entry and _char then
        if entry.slot == "bag" then
          local item = entry.item
          local base = item.base or item
          local targetSlot = (base.slot == "ring") and "ring_1" or base.slot
          if base.slot == "ring" then
            for _, rs in ipairs(equipment_slots.RING_SLOTS) do
              if _char.equipmentManager:canEquip(item, rs) then targetSlot = rs break end
            end
          end
          if _char.equipmentManager:canEquip(item, targetSlot) then
            local inv = player_data.get_inventory()
            local ok, freed = _char.equipmentManager:equip(item, targetSlot)
            if ok then
              if entry.invIndex and entry.invIndex >= 1 and entry.invIndex <= #inv then
                table.remove(inv, entry.invIndex)
              end
              for _, prev in ipairs(freed or {}) do table.insert(inv, prev) end
            end
          end
        else
          local ok, result = _char.equipmentManager:unequip(entry.slot)
          if ok and result then
            local inv = player_data.get_inventory()
            table.insert(inv, result)
          end
          if not ok and result and result.code == "cursed" then
            require("core.game_log.log_manager").add("item", { messageKey = "item.cursed_unequip", params = {} })
          end
        end
      end
    end
  end

  self.draw = function()
    local w = platform.gfx_width()
    local h = platform.gfx_height()
    local img = asset_manager.get_image("house_room")
    if img and platform.gfx_draw_image then platform.gfx_draw_image(img, 0, 0, w, h)
    else platform.gfx_draw_rect("fill", 0, 0, w, h, { 0.08, 0.06, 0.12, 1 }) end

    local layout = inventory_hud.compute_layout()
    local equipped = _char and _char.equipmentManager:getAllEquipped() or {}
    local eqList = {}
    for _, slot in ipairs(SLOT_ORDER) do
      local item = equipped[slot]
      if item then table.insert(eqList, { slot = slot, item = item }) end
    end
    local bagEquip = player_data.get_equipment_in_bag()
    for _, be in ipairs(bagEquip) do
      table.insert(eqList, { slot = "bag", item = be.item, invIndex = be.invIndex })
    end

    local lx = layout.leftX
    local ty = layout.topY
    local pw = layout.panelW
    local ph = layout.panelH
    local lh = layout.lineH

    inventory_hud.draw_panel(lx, ty, pw, ph, "hub.equipment.title")

    local eqY = ty + 45
    for i, entry in ipairs(eqList) do
      local slotLabel = entry.slot == "bag" and i18n.t("hub.equipment.slot_bag") or (i18n.t("hub.equipment.slot_" .. entry.slot) or entry.slot)
      local name = item_display.getDisplayName(entry.item)
      local details = item_display.getWeaponDetails(entry.item)
      local label = slotLabel .. ": " .. name
      if details and details ~= "" then label = label .. " [" .. details .. "]" end
      local iconPath = item_display.getSpritePath(entry.item)
      local slotY = eqY + (i - 1) * (lh + 4)
      local opts = { iconPath = iconPath }
      if i == _sel then
        inventory_hud.draw_item_slot(lx + 10, slotY, pw - 20, lh + 4, label, true, opts)
      else
        inventory_hud.draw_item_slot(lx + 10, slotY, pw - 20, lh + 4, label, false, opts)
      end
    end

    local goldStr = i18n.t("hub.character.gold") .. ": " .. player_data.get_gold()
    platform.gfx_draw_text(goldStr, lx, ty + ph + 15)
    inventory_hud.draw_hint(h - 30, "hub.equipment.hint")
  end

  return self
end

return M
