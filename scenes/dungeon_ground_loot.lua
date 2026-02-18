-- scenes/dungeon_ground_loot.lua - Interface loot au sol (Équiper / Ramasser)
local M = {}

local router = require("core.router")
local input = require("core.input")
local platform = require("platform.love")
local i18n = require("core.i18n")
local dungeon_run_state = require("core.dungeon_run_state")
local player_data = require("core.player_data")
local item_display = require("core.equipment.item_display")
local log_manager = require("core.game_log.log_manager")
local equipment_slots = require("core.equipment.equipment_slots")

function M.new()
  local self = {}
  local _sel = 1
  local _items = {}
  local _gx, _gy = nil, nil

  self.enter = function()
    _sel = 1
    local pending = dungeon_run_state.getPendingGroundLoot()
    _gx, _gy = pending and pending.x, pending and pending.y
    _items = {}
    if _gx and _gy then
      local state = dungeon_run_state.get()
      if state and state.map then
        local _, items = state.map:getGroundLoot(_gx, _gy)
        _items = items or {}
      end
    end
  end

  self.exit = function()
    dungeon_run_state.clearPendingGroundLoot()
  end

  self.pause = function() end
  self.resume = function() end

  self.update = function(dt)
    if input.consume("back") then
      router.dispatch("scene:pop")
      return
    end

    local state = dungeon_run_state.get()
    if not state or not _gx or not _gy then
      router.dispatch("scene:pop")
      return
    end

    local n = #_items
    if n == 0 then
      router.dispatch("scene:pop")
      return
    end

    if input.consume("up") then _sel = _sel - 1 end
    if input.consume("down") then _sel = _sel + 1 end
    if _sel < 1 then _sel = n end
    if _sel > n then _sel = 1 end

    if input.consume("left") or input.consume("right") then
      local item = _items[_sel]
      if not item then return end
      local isEquip = item.base and item.base.slot
      if not isEquip then return end

      local player = state.entityManager:getPlayer()
      local char = player and player._character
      if not char or not char.equipmentManager then return end

      local slot = item.base.slot
      local targetSlot = (slot == "ring") and "ring_1" or slot
      if slot == "ring" then
        for _, rs in ipairs(equipment_slots.RING_SLOTS) do
          if char.equipmentManager:canEquip(item, rs) then
            targetSlot = rs
            break
          end
        end
      end

      if char.equipmentManager:canEquip(item, targetSlot) then
        local ok, freed = char.equipmentManager:equip(item, targetSlot)
        if ok then
          for _, prev in ipairs(freed or {}) do
            player_data.add_item(prev)
          end
          local itemName = item_display.getDisplayName(item)
          log_manager.add("loot", { messageKey = "log.loot.equipped", params = { item = itemName } })
          table.remove(_items, _sel)
          _sel = math.max(1, math.min(_sel, #_items))
        end
      end
      return
    end

    if input.consume("confirm") then
      local item = _items[_sel]
      if item then
        local itemName = item_display.getDisplayName(item)
        log_manager.add("loot", { messageKey = "log.loot.picked", params = { item = itemName } })
        player_data.add_item(item)
        table.remove(_items, _sel)
        _sel = math.max(1, math.min(_sel, #_items))
      end
    end
  end

  self.draw = function()
    local w = platform.gfx_width()
    local h = platform.gfx_height()
    local n = #_items
    if n == 0 then return end

    local lh = 18
    local pad = 8
    local panelW = math.min(360, w - 40)
    local panelH = 40 + n * lh + 24
    local panelX = (w - panelW) / 2
    local panelY = h - panelH - 50 - math.floor(h * 0.10)

    platform.gfx_draw_rect("fill", panelX - 2, panelY - 2, panelW + 4, panelH + 4, { 0.08, 0.06, 0.12, 0.92 })
    platform.gfx_draw_rect("line", panelX - 2, panelY - 2, panelW + 4, panelH + 4, { 0.5, 0.4, 0.65, 1 })

    local title = i18n.t("dungeon.loot.title") or "Au sol"
    platform.gfx_draw_text(title, panelX + pad, panelY + pad)

    local y = panelY + pad + 22
    for i, item in ipairs(_items) do
      local name = item_display.getDisplayName(item)
      local isEquip = item.base and item.base.slot
      local suffix = isEquip and " [A/D]" or ""
      local label = name .. suffix
      if i == _sel then
        platform.gfx_draw_rect("fill", panelX + pad - 2, y - 2, panelW - pad * 2 + 4, lh + 2, { 0.2, 0.15, 0.3, 0.6 })
      end
      platform.gfx_draw_text(label, panelX + pad, y)
      y = y + lh
    end

    platform.gfx_draw_text(i18n.t("dungeon.loot.hint"), panelX + pad, panelY + panelH - 20)
  end

  return self
end

return M
