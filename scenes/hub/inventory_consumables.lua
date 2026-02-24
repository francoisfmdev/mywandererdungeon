-- scenes/hub/inventory_consumables.lua - Menu consommables uniquement
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
local dungeon_run_state = require("core.dungeon_run_state")
local ConsumableRegistry = require("core.consumables.consumable_registry")
local pending_dungeon_action = require("core.pending_dungeon_action")

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

    local consumables = player_data.get_consumables()
    local n = #consumables
    if input.consume("up") then _sel = _sel - 1 end
    if input.consume("down") then _sel = _sel + 1 end
    if _sel < 1 then _sel = math.max(1, n) end
    if _sel > n then _sel = 1 end

    if input.consume("confirm") and n > 0 then
      local entry = consumables[_sel]
      if not entry then return end
      local item = entry.item
      local invIndex = entry.invIndex
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
            player_data.remove_item(invIndex)
            _sel = math.min(_sel, #player_data.get_consumables())
          end
          return
        end
        if inDungeon then
          if ConsumableRegistry.needsTarget(item) then
            pending_dungeon_action.set({ type = "use_item", itemIndex = invIndex, needsTarget = true })
            router.dispatch("scene:pop")
          else
            dungeon_run_state.process_turn({ type = "use_item", itemIndex = invIndex })
            router.dispatch("scene:pop")
          end
          return
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
    local consumables = player_data.get_consumables()
    local lx = layout.leftX
    local ty = layout.topY
    local pw = layout.panelW
    local ph = layout.panelH
    local lh = layout.lineH

    inventory_hud.draw_panel(lx, ty, pw, ph, "hub.inventory.title")

    local invY = ty + 45
    local maxConsumables = 20
    for i = 1, math.min(#consumables, maxConsumables) do
      local entry = consumables[i]
      local item = entry and entry.item
      if not item then break end
      local def = ConsumableRegistry.get(item.id or (item.base and item.base.id))
      local name = item_display.getDisplayName(item)
      local label = name
      if def and def.type == "wand" and item.charges then
        label = name .. " (" .. item.charges .. "/" .. (def.chargesMax or "?") .. ")"
      elseif item.count and item.count > 1 then
        label = name .. " x" .. item.count
      end
      local iconPath = item_display.getSpritePath(item)
      local slotY = invY + (i - 1) * (lh + 4)
      local opts = { iconPath = iconPath }
      if i == _sel then
        inventory_hud.draw_item_slot(lx + 10, slotY, pw - 20, lh + 4, label, true, opts)
      else
        inventory_hud.draw_item_slot(lx + 10, slotY, pw - 20, lh + 4, label, false, opts)
      end
    end

    if #consumables > 0 and _sel >= 1 and _sel <= #consumables then
      local entry = consumables[_sel]
      local item = entry and entry.item
      if item then
        local effectText = item_display.getConsumableEffectText(item)
        if effectText and effectText ~= "" then
          platform.gfx_draw_text(effectText, lx + 10, invY + math.min(#consumables, maxConsumables) * (lh + 4) + 8)
        end
      end
    end

    local goldStr = i18n.t("hub.character.gold") .. ": " .. player_data.get_gold()
    platform.gfx_draw_text(goldStr, lx, ty + ph + 15)
    inventory_hud.draw_hint(h - 30, "hub.inventory.hint")
  end

  return self
end

return M
