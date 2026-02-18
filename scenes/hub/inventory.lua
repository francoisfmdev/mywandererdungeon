-- scenes/hub/inventory.lua - Inventaire + equipement, HUD responsive
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
local dungeon_run_state = require("core.dungeon_run_state")
local ConsumableRegistry = require("core.consumables.consumable_registry")
local pending_dungeon_action = require("core.pending_dungeon_action")

function M.new()
  local self = {}
  local _tab = "inventory"
  local _invSel = 1
  local _equipSel = 1
  local _char = nil

  self.enter = function()
    _char = game_state.get_character()
    if not _char then _char = require("core.game_state").reset() end
    _tab = "inventory"
    _invSel = 1
    _equipSel = 1
  end
  self.exit = function() end
  self.pause = function() end
  self.resume = function() end

  self.update = function(dt)
    if input.consume("back") then
      router.dispatch("scene:pop")
      return
    end

    if input.consume("left") or input.consume("right") then
      _tab = _tab == "inventory" and "equipment" or "inventory"
      return
    end

    local inv = player_data.get_inventory()
    local equipped = _char and _char.equipmentManager:getAllEquipped() or {}
    local eqList = {}
    for slot, item in pairs(equipped) do
      table.insert(eqList, { slot = slot, item = item })
    end

    if _tab == "inventory" then
      local n = #inv
      if input.consume("up") then _invSel = _invSel - 1 end
      if input.consume("down") then _invSel = _invSel + 1 end
      if _invSel < 1 then _invSel = math.max(1, n) end
      if _invSel > n then _invSel = 1 end
      if input.consume("confirm") and n > 0 then
        local item = inv[_invSel]
        if not item then return end
        local def = ConsumableRegistry.get(item.id or (item.base and item.base.id))
        local inDungeon = dungeon_run_state.get()
        if ConsumableRegistry.isConsumable(item) then
          if def and (def.type == "scroll" or def.type == "card") then
            local ConsumableEffects = require("core.consumables.consumable_effects")
            local events = {}
            local applied = false
            if def.effect == "identify" then
              applied = ConsumableEffects.applyIdentify(item, { _character = _char }, events, {})
            elseif def.effect == "purify" then
              applied = ConsumableEffects.applyPurify(item, { _character = _char }, events, {})
            end
            if applied then
              player_data.remove_item(_invSel)
              _invSel = math.min(_invSel, #player_data.get_inventory())
            end
            return
          end
          if inDungeon then
            if ConsumableRegistry.needsTarget(item) then
              pending_dungeon_action.set({ type = "use_item", itemIndex = _invSel, needsTarget = true })
              router.dispatch("scene:pop")
            else
              dungeon_run_state.process_turn({ type = "use_item", itemIndex = _invSel })
              router.dispatch("scene:pop")
            end
            return
          end
        end
        if item and _char then
          local base = item.base or item
          local slot = base.slot
          if slot and _char.equipmentManager:canEquip(item, slot == "ring" and "ring_1" or slot) then
            local targetSlot = (slot == "ring") and "ring_1" or slot
            if slot == "ring" then
              for _, rs in ipairs(equipment_slots.RING_SLOTS) do
                if _char.equipmentManager:canEquip(item, rs) then targetSlot = rs break end
              end
            end
            local ok, freed = _char.equipmentManager:equip(item, targetSlot)
            if ok then
              for _, prev in ipairs(freed or {}) do
                table.insert(inv, prev)
              end
              table.remove(inv, _invSel)
              _invSel = math.min(_invSel, #inv)
            end
          end
        end
      end
    else
      local n = #eqList
      if input.consume("up") then _equipSel = _equipSel - 1 end
      if input.consume("down") then _equipSel = _equipSel + 1 end
      if _equipSel < 1 then _equipSel = math.max(1, n) end
      if _equipSel > n then _equipSel = 1 end
      if input.consume("confirm") and n > 0 then
        local entry = eqList[_equipSel]
        if entry and _char then
          local ok, result = _char.equipmentManager:unequip(entry.slot)
          if ok and result then table.insert(inv, result) end
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
    if img then platform.gfx_draw_image(img, 0, 0, w, h)
    else platform.gfx_draw_rect("fill", 0, 0, w, h, { 0.08, 0.06, 0.12, 1 }) end

    local layout = inventory_hud.compute_layout()
    local inv = player_data.get_inventory()
    local equipped = _char and _char.equipmentManager:getAllEquipped() or {}
    local eqList = {}
    for slot, item in pairs(equipped) do
      table.insert(eqList, { slot = slot, item = item })
    end

    local lx = layout.leftX
    local rx = layout.rightX
    local ty = layout.topY
    local pw = layout.panelW
    local ph = layout.panelH
    local lh = layout.lineH

    inventory_hud.draw_panel(lx, ty, pw, ph, "hub.inventory.title")
    inventory_hud.draw_panel(rx, ty, pw, ph, "hub.equipment.title")

    local invY = ty + 45
    for i, item in ipairs(inv) do
      local def = ConsumableRegistry.get(item.id or (item.base and item.base.id))
      local name = item_display.getDisplayName(item)
      local label = name
      if def and def.type == "wand" and item.charges then
        label = name .. " (" .. item.charges .. "/" .. (def.chargesMax or "?") .. ")"
      elseif item.count and item.count > 1 then
        label = name .. " x" .. item.count
      else
        label = name .. " x1"
      end
      local slotY = invY + (i - 1) * (lh + 4)
      if _tab == "inventory" and i == _invSel then
        inventory_hud.draw_item_slot(lx + 10, slotY, pw - 20, lh + 4, label, true)
      else
        inventory_hud.draw_item_slot(lx + 10, slotY, pw - 20, lh + 4, label, false)
      end
    end

    local eqY = ty + 45
    for i, entry in ipairs(eqList) do
      local label = (entry.slot or "?") .. ": " .. item_display.getDisplayName(entry.item)
      local slotY = eqY + (i - 1) * (lh + 4)
      if _tab == "equipment" and i == _equipSel then
        inventory_hud.draw_item_slot(rx + 10, slotY, pw - 20, lh + 4, label, true)
      else
        inventory_hud.draw_item_slot(rx + 10, slotY, pw - 20, lh + 4, label, false)
      end
    end

    local goldStr = i18n.t("hub.character.gold") .. ": " .. player_data.get_gold()
    platform.gfx_draw_text(goldStr, lx, ty + ph + 15)

    local tabHint = _tab == "inventory" and "hub.inventory.tab_equip" or "hub.equipment.tab_inv"
    platform.gfx_draw_text(i18n.t("hub.inventory.tab_hint"), w / 2 - 80, h - 50)
    inventory_hud.draw_hint(h - 30, "hub.inventory.hint")
  end

  return self
end

return M
