-- scenes/dungeon_run.lua - Donjon, minimap, mouvement 8 dirs
local M = {}

local i18n = require("core.i18n")
local input = require("core.input")
local input_state = require("core.input.input_state")
local router = require("core.router")
local platform = require("platform.love")
local dungeon_run_state = require("core.dungeon_run_state")
local game_state = require("core.game_state")
local player_data = require("core.player_data")
local octo = require("core.grid.octo_dirs")
local dungeon_renderer = require("core.render.dungeon_renderer")
local MonsterRegistry = require("core.entities.monster_registry")

local CELL_W, CELL_H = 32, 32
local MINIMAP_W, MINIMAP_H = 160, 160
local MINIMAP_PAD = 8
local STATS_PANEL_H = 92
local BAR_H = 14
local BAR_W = 140
local HINT_ZONE = 36
local BOTTOM_RAISE = 0.10  -- 10% de hauteur pour éviter débordement texte / chevauchement menu
local LOG_PANEL_W = 340
local LOG_PREVIEW_LINES = 3
local LOG_LINE_H = 16

local function get_minimap_y()
  local h = platform.gfx_height()
  return h - h * BOTTOM_RAISE - HINT_ZONE - MINIMAP_H - MINIMAP_PAD
end

local function draw_stat_bar(x, y, current, maxVal, barColor)
  if maxVal <= 0 then maxVal = 1 end
  local ratio = math.max(0, math.min(1, current / maxVal))
  platform.gfx_draw_rect("fill", x, y, BAR_W, BAR_H, { 0.12, 0.1, 0.15, 1 })
  if ratio > 0 then
    platform.gfx_draw_rect("fill", x + 1, y + 1, (BAR_W - 2) * ratio, BAR_H - 2, barColor or { 0.2, 0.7, 0.25, 1 })
  end
  platform.gfx_draw_rect("line", x, y, BAR_W, BAR_H, { 0.4, 0.35, 0.5, 1 })
  local label = tostring(current) .. " / " .. tostring(maxVal)
  platform.gfx_draw_text(label, x + 4, y + 2)
end

local function draw_stats_panel()
  local w = platform.gfx_width()
  local panelW = MINIMAP_W + 10
  local px = w - panelW - MINIMAP_PAD
  local py = MINIMAP_PAD

  platform.gfx_draw_rect("fill", px - 2, py - 2, panelW + 4, STATS_PANEL_H + 4, { 0.05, 0.05, 0.15, 0.9 })
  platform.gfx_draw_rect("line", px - 2, py - 2, panelW + 4, STATS_PANEL_H + 4, { 1, 0.55, 0.15, 1 })

  local char = game_state.get_character()
  if not char then return end

  local x = px + 8
  local y = py + 6
  platform.gfx_draw_text(i18n.t("hub.character.level") .. " " .. char:getLevel(), x, y)
  y = y + 18
  platform.gfx_draw_text(i18n.t("hub.character.hp"), x, y - 2)
  draw_stat_bar(x, y + 2, char:getHP(), char:getMaxHP(), { 0.55, 0.15, 0.15, 1 })
  y = y + BAR_H + 8
  platform.gfx_draw_text(i18n.t("hub.character.mp"), x, y - 2)
  draw_stat_bar(x, y + 2, char:getMP(), char:getMaxMP(), { 0.2, 0.4, 0.7, 1 })
  y = y + BAR_H + 6
  platform.gfx_draw_text(i18n.t("hub.character.gold") .. " " .. player_data.get_gold(), x, y)
end

local function draw_minimap(map, playerX, playerY)
  local w = platform.gfx_width()
  local mx = w - MINIMAP_W - MINIMAP_PAD
  local my = get_minimap_y()

  local COLORS = { bg = { 0.05, 0.05, 0.15, 0.9 }, border = { 1, 0.55, 0.15, 1 } }
  platform.gfx_draw_rect("fill", mx - 2, my - 2, MINIMAP_W + 4, MINIMAP_H + 4, COLORS.bg)
  platform.gfx_draw_rect("line", mx - 2, my - 2, MINIMAP_W + 4, MINIMAP_H + 4, COLORS.border)

  local scaleX = MINIMAP_W / map.width
  local scaleY = MINIMAP_H / map.height

  for gx = 1, map.width do
    for gy = 1, map.height do
      if map:isExplored(gx, gy) then
        local tile = map:getTile(gx, gy)
        local rx = mx + (gx - 1) * scaleX
        local ry = my + (gy - 1) * scaleY
        local fill = { 0.2, 0.15, 0.1, 0.9 }
        if tile and tile.type == "floor" then
          fill = { 0.25, 0.2, 0.35, 0.95 }
        end
        platform.gfx_draw_rect("fill", rx, ry, math.ceil(scaleX) + 1, math.ceil(scaleY) + 1, fill)
      end
    end
  end

  local px = mx + (playerX - 0.5) * scaleX
  local py = my + (playerY - 0.5) * scaleY
  platform.gfx_draw_rect("fill", px - 2, py - 2, 4, 4, { 1, 0.9, 0.2, 1 })
end

local COLORS = {
  fill = { 0.15, 0.3, 0.8, 0.12 },
  border = { 1, 0.55, 0.15, 1 },
}

local function compute_danger_level(playerChar, monsterDef, entityHp)
  if not playerChar or not monsterDef then return "low" end
  local pHp = playerChar:getMaxHP()
  local pStr = playerChar:getEffectiveStat("strength") or 0
  local pDex = playerChar:getEffectiveStat("dexterity") or 0
  local pCon = playerChar:getEffectiveStat("constitution") or 0
  local playerPower = pHp + (pStr + pDex + pCon) * 2

  local mHp = entityHp or monsterDef.hp or 10
  local mStats = monsterDef.stats or {}
  local mStr = mStats.strength or 0
  local mDex = mStats.dexterity or 0
  local mCon = mStats.constitution or 0
  local monsterPower = mHp + (mStr + mDex + mCon) * 2

  local ratio = monsterPower / math.max(1, playerPower)
  if ratio < 0.6 then return "low" end
  if ratio < 1.0 then return "medium" end
  if ratio < 1.5 then return "high" end
  return "deadly"
end

local function draw_observer_hud(monsterDef, entity, dangerKey)
  local w = platform.gfx_width()
  local panelW = 220
  local panelX = 12
  local panelY = 12
  local lineH = 18
  local pad = 8

  platform.gfx_draw_rect("fill", panelX - 2, panelY - 2, panelW + 4, 120, { 0.06, 0.05, 0.12, 0.95 })
  platform.gfx_draw_rect("line", panelX - 2, panelY - 2, panelW + 4, 120, { 1, 0.55, 0.15, 1 })

  local name = monsterDef.nameKey and i18n.t(monsterDef.nameKey) or (monsterDef.id or "?")
  local desc = monsterDef.descriptionKey and i18n.t(monsterDef.descriptionKey) or ""
  local dangerT = i18n.t("ui.observer.danger_" .. dangerKey)

  platform.gfx_draw_text(name, panelX + pad, panelY + pad)
  platform.gfx_draw_text(desc, panelX + pad, panelY + pad + lineH)
  platform.gfx_draw_text(i18n.t("hub.character.hp") .. " " .. (entity.hp or 0) .. "/" .. (entity.maxHp or monsterDef.hp or 0), panelX + pad, panelY + pad + lineH * 2)
  platform.gfx_draw_text(dangerT, panelX + pad, panelY + pad + lineH * 3)
end

local function draw_loot_hud(gold, items)
  if (not gold or gold <= 0) and (not items or #items == 0) then return end
  local item_display = require("core.equipment.item_display")
  local w = platform.gfx_width()
  local panelW = 240
  local panelX = 12
  local panelY = 12
  local lineH = 18
  local pad = 8
  local lines = 1
  if gold and gold > 0 then lines = lines + 1 end
  if items then lines = lines + #items end
  local panelH = math.max(80, lines * lineH + pad * 2)

  platform.gfx_draw_rect("fill", panelX - 2, panelY - 2, panelW + 4, panelH + 4, { 0.06, 0.05, 0.12, 0.95 })
  platform.gfx_draw_rect("line", panelX - 2, panelY - 2, panelW + 4, panelH + 4, { 0.55, 0.85, 1, 1 })

  platform.gfx_draw_text(i18n.t("dungeon.loot.title"), panelX + pad, panelY + pad)
  local y = panelY + pad + lineH
  if gold and gold > 0 then
    platform.gfx_draw_text(i18n.t("hub.character.gold") .. ": " .. gold, panelX + pad, y)
    y = y + lineH
  end
  for _, it in ipairs(items or {}) do
    local name = item_display.getDisplayName(it)
    platform.gfx_draw_text(name, panelX + pad, y)
    y = y + lineH
  end
end

local function draw_minimap_toggle_button(visible)
  local w = platform.gfx_width()
  local btnW, btnH = 60, 22
  local bx = w - MINIMAP_W - MINIMAP_PAD - 2
  local by = get_minimap_y() - btnH - 4
  platform.gfx_draw_rect("fill", bx, by, btnW, btnH, COLORS.fill)
  platform.gfx_draw_rect("line", bx, by, btnW, btnH, COLORS.border)
  local label = visible and "dungeon.minimap.hide" or "dungeon.minimap.show"
  local text = i18n.t(label)
  local fw = platform.gfx_get_font():getWidth(text)
  platform.gfx_draw_text(text, bx + (btnW - fw) / 2, by + 4)
  return bx, by, btnW, btnH
end

function M.new()
  local self = {}

  self.enter = function()
    if not dungeon_run_state.get() then
      dungeon_run_state.start(require("data.dungeons.ruins"))
    end
  end
  self.exit = function() end
  self.pause = function() end
  self.resume = function() end

  self.update = function(dt)
    local state = dungeon_run_state.get()
    if not state then return end

    if state.death or state.gameOver then
      game_state.applyDeathPenalty()
      dungeon_run_state.clear()
      router.dispatch("scene:replace:hub_main")
      return
    end

    local pending = require("core.pending_dungeon_action").get()
    if pending and pending.type == "use_item" then
      if pending.needsTarget then
        input_state.setMode("use_item_target")
        input_state.setUseItemIndex(pending.itemIndex)
        local opx, opy = dungeon_run_state.get_player_pos()
        if opx and opy then
          input_state.setObserverCursor(opx, opy)
        end
      else
        dungeon_run_state.process_turn({
          type = "use_item",
          itemIndex = pending.itemIndex,
        })
      end
    end

    if input_state.isUseItemTarget() then
      local opx, opy = dungeon_run_state.get_player_pos()
      opx, opy = opx or 1, opy or 1
      local ogx, ogy = input_state.getObserverCursor()
      if not ogx or not ogy then
        input_state.setObserverCursor(opx, opy)
        ogx, ogy = opx, opy
      end
      local dx, dy = 0, 0
      if input.consume("up_left") then dx, dy = -1, -1
      elseif input.consume("up_right") then dx, dy = 1, -1
      elseif input.consume("down_left") then dx, dy = -1, 1
      elseif input.consume("down_right") then dx, dy = 1, 1
      elseif input.consume("left") then dx, dy = -1, 0
      elseif input.consume("right") then dx, dy = 1, 0
      elseif input.consume("up") then dx, dy = 0, -1
      elseif input.consume("down") then dx, dy = 0, 1
      end
      if dx ~= 0 or dy ~= 0 then
        local nx, ny = ogx + dx, ogy + dy
        if state.map:inBounds(nx, ny) and state.map:isExplored(nx, ny) then
          input_state.setObserverCursor(nx, ny)
        end
      end
      if input.consume("confirm") then
        local cgx, cgy = input_state.getObserverCursor()
        local itemIndex = input_state.getUseItemIndex()
        local entity = cgx and cgy and state.entityManager:getEntityAt(cgx, cgy)
        local player = state.entityManager:getPlayer()
        local targetEntity = nil
        if entity and entity ~= player and not entity.isPlayer and (entity.hp == nil or entity.hp > 0) then
          targetEntity = entity
        end
        dungeon_run_state.process_turn({
          type = "use_item",
          itemIndex = itemIndex,
          targetEntity = targetEntity,
          targetGx = cgx,
          targetGy = cgy,
        })
        input_state.setMode("normal")
      elseif input.consume("back") then
        input_state.setMode("normal")
      elseif input.consume("context") then
        router.dispatch("scene:push:ui_context_menu")
      end
      return
    end

    if input_state.isObserver() then
      local opx, opy = dungeon_run_state.get_player_pos()
      opx, opy = opx or 1, opy or 1
      local ogx, ogy = input_state.getObserverCursor()
      if not ogx or not ogy then
        input_state.setObserverCursor(opx, opy)
        ogx, ogy = opx, opy
      end
      local dx, dy = 0, 0
      if input.consume("up_left") then dx, dy = -1, -1
      elseif input.consume("up_right") then dx, dy = 1, -1
      elseif input.consume("down_left") then dx, dy = -1, 1
      elseif input.consume("down_right") then dx, dy = 1, 1
      elseif input.consume("left") then dx, dy = -1, 0
      elseif input.consume("right") then dx, dy = 1, 0
      elseif input.consume("up") then dx, dy = 0, -1
      elseif input.consume("down") then dx, dy = 0, 1
      end
      if dx ~= 0 or dy ~= 0 then
        local nx, ny = ogx + dx, ogy + dy
        if state.map:inBounds(nx, ny) and state.map:isExplored(nx, ny) then
          input_state.setObserverCursor(nx, ny)
        end
      end
      if input.consume("back") then
        input_state.setMode("normal")
      elseif input.consume("context") then
        router.dispatch("scene:push:ui_context_menu")
      end
      return
    end

    if input_state.isDirectionTarget() then
      local dx, dy = 0, 0
      if input.consume("up_left") then dx, dy = -1, -1
      elseif input.consume("up_right") then dx, dy = 1, -1
      elseif input.consume("down_left") then dx, dy = -1, 1
      elseif input.consume("down_right") then dx, dy = 1, 1
      elseif input.consume("left") then dx, dy = -1, 0
      elseif input.consume("right") then dx, dy = 1, 0
      elseif input.consume("up") then dx, dy = 0, -1
      elseif input.consume("down") then dx, dy = 0, 1
      end
      if dx ~= 0 or dy ~= 0 then
        input_state.setSelectedDirection(dx, dy)
      end
      if input.consume("confirm") then
        local sdx, sdy = input_state.getSelectedDirection()
        if sdx ~= 0 or sdy ~= 0 then
          local player = state.entityManager:getPlayer()
          local weapon = player and player._character and player._character.equipmentManager and player._character.equipmentManager:getEquipped("weapon_main")
          weapon = weapon and (weapon.base or weapon)
          local range = (weapon and weapon.range) or 1
          local target_selector = require("core.targeting.target_selector")
          local target = target_selector.findTargetInDirection(
            player.x or player.gridX, player.y or player.gridY,
            sdx, sdy, range, state.map, state.entityManager, player
          )
          input_state.setMode("normal")
          input_state.clearPending()
          if target then
            dungeon_run_state.process_turn({ type = "attack", targetId = target.id, weapon = weapon })
          else
            local log_mgr = require("core.game_log.log_manager")
            log_mgr.add("attack", { messageKey = "log.player.invalid_target", params = {} })
          end
        end
      elseif input.consume("back") then
        input_state.setMode("normal")
        input_state.clearPending()
      end
      return
    end

    if input.consume("pause") then
      input.consume("back")
      router.dispatch("scene:push:ui_pause_menu")
      return
    end
    if input.consume("context") then
      input.consume("confirm")
      router.dispatch("scene:push:ui_context_menu")
      return
    end

    if input.consume("minimap_toggle") then
      dungeon_run_state.toggle_minimap()
      return
    end

    if platform.mouse_peek_click then
      local mx, my = platform.mouse_peek_click(1)
      if mx and my then
        local w = platform.gfx_width()
        local log_mgr = require("core.game_log.log_manager")
        local nEntries = #log_mgr.get_recent(LOG_PREVIEW_LINES)
        local logClickH = (nEntries > 0 and (nEntries * LOG_LINE_H + 24) or 0)
        if logClickH > 0 and mx >= MINIMAP_PAD and mx < MINIMAP_PAD + LOG_PANEL_W and my >= MINIMAP_PAD + 28 and my < MINIMAP_PAD + 30 + logClickH then
          platform.mouse_consume_click(1)
          router.dispatch("scene:push:log")
          return
        end
        local bx, by, bw, bh
        if dungeon_run_state.is_minimap_visible() then
          bx = w - MINIMAP_W - MINIMAP_PAD - 2
          by = get_minimap_y() - 26
          bw, bh = 60, 22
        else
          bx = w - 72
          by = get_minimap_y()
          bw, bh = 64, 24
        end
        if mx >= bx and mx < bx + bw and my >= by and my < by + bh then
          platform.mouse_consume_click(1)
          dungeon_run_state.toggle_minimap()
        end
      end
    end

    local px, py = dungeon_run_state.get_player_pos()
    local dx, dy = 0, 0
    if input.consume("up_left") then dx, dy = -1, -1
    elseif input.consume("up_right") then dx, dy = 1, -1
    elseif input.consume("down_left") then dx, dy = -1, 1
    elseif input.consume("down_right") then dx, dy = 1, 1
    elseif input.consume("left") then dx, dy = -1, 0
    elseif input.consume("right") then dx, dy = 1, 0
    elseif input.consume("up") then dx, dy = 0, -1
    elseif input.consume("down") then dx, dy = 0, 1
    end
    if dx ~= 0 or dy ~= 0 then
      local nx, ny = (px or 0) + dx, (py or 0) + dy
      if state.map:inBounds(nx, ny) and state.map:isWalkable(nx, ny) then
        dungeon_run_state.process_turn({ type = "move", dx = dx, dy = dy })
        if dungeon_run_state.getPendingGroundLoot() then
          router.dispatch("scene:push:dungeon_ground_loot")
        end
      end
    end

    if input.consume("back") then
      router.dispatch("scene:replace:hub_main")
      dungeon_run_state.clear()
    end
  end

  self.draw = function()
    local w = platform.gfx_width()
    local h = platform.gfx_height()
    local state = dungeon_run_state.get()
    if not state then return end

    local map = state.map
    local px, py = dungeon_run_state.get_player_pos()
    if px and py then
      map:setExplored(px, py)
    end
    if not px or not py then px, py = state.playerX or 1, state.playerY or 1 end

    platform.gfx_draw_rect("fill", 0, 0, w, h, { 0.05, 0.03, 0.08, 1 })

    dungeon_renderer.setDungeonConfig(state.dungeonConfig)

    local viewW = math.floor(w / CELL_W)
    local viewH = math.floor(h / CELL_H)
    local offX = math.floor(px - viewW / 2)
    local offY = math.floor(py - viewH / 2)

    for vx = 0, viewW do
      for vy = 0, viewH do
        local gx = offX + vx
        local gy = offY + vy
        if map:inBounds(gx, gy) and map:isExplored(gx, gy) then
          local tile = map:getTile(gx, gy)
          dungeon_renderer.draw_tile(tile, vx * CELL_W, vy * CELL_H, CELL_W, CELL_H)
          dungeon_renderer.draw_ground_loot(tile, vx * CELL_W, vy * CELL_H, CELL_W, CELL_H)
        end
      end
    end

    local player = state.entityManager:getPlayer()
    for _, entity in pairs(state.entityManager and state.entityManager:getEntities() or {}) do
      local ex, ey = entity.x or entity.gridX, entity.y or entity.gridY
      if ex and ey and map:isExplored(ex, ey) and (entity.hp == nil or entity.hp > 0) then
        local evx = (ex - offX) * CELL_W
        local evy = (ey - offY) * CELL_H
        local shakeX, shakeY = 0, 0
        if entity.shakeFrames and entity.shakeFrames > 0 then
          shakeX = (math.random() - 0.5) * 10
          shakeY = (math.random() - 0.5) * 10
          entity.shakeFrames = entity.shakeFrames - 1
        end
        local isPlayer = entity.isPlayer or entity == player
        dungeon_renderer.draw_entity(entity, evx + shakeX, evy + shakeY, CELL_W, CELL_H, isPlayer)
      end
    end

    -- Surbrillance case selectionnee (mode ciblage direction)
    if input_state.isDirectionTarget() then
      local sdx, sdy = input_state.getSelectedDirection()
      if sdx ~= 0 or sdy ~= 0 then
        local tx, ty = (px or 1) + sdx, (py or 1) + sdy
        if map:inBounds(tx, ty) and map:isExplored(tx, ty) then
          local tvx = (tx - offX) * CELL_W
          local tvy = (ty - offY) * CELL_H
          platform.gfx_draw_rect("line", tvx, tvy, CELL_W, CELL_H, { 1, 0.9, 0.1, 1 })
          platform.gfx_draw_rect("line", tvx + 1, tvy + 1, CELL_W - 2, CELL_H - 2, { 1, 0.9, 0.1, 0.7 })
        end
      end
    end

    -- Mode use_item_target (carte ciblage) : curseur comme observateur
    if input_state.isUseItemTarget() then
      local cgx, cgy = input_state.getObserverCursor()
      if cgx and cgy and map:inBounds(cgx, cgy) and map:isExplored(cgx, cgy) then
        local cvx = (cgx - offX) * CELL_W
        local cvy = (cgy - offY) * CELL_H
        platform.gfx_draw_rect("line", cvx, cvy, CELL_W, CELL_H, { 1, 0.5, 0.2, 1 })
        platform.gfx_draw_rect("line", cvx + 1, cvy + 1, CELL_W - 2, CELL_H - 2, { 1, 0.5, 0.2, 0.5 })
      end
    end

    -- Mode observateur: curseur libre + HUD monstre
    if input_state.isObserver() then
      local cgx, cgy = input_state.getObserverCursor()
      if cgx and cgy and map:inBounds(cgx, cgy) and map:isExplored(cgx, cgy) then
        local cvx = (cgx - offX) * CELL_W
        local cvy = (cgy - offY) * CELL_H
        platform.gfx_draw_rect("line", cvx, cvy, CELL_W, CELL_H, { 0.2, 0.8, 1, 1 })
        platform.gfx_draw_rect("line", cvx + 1, cvy + 1, CELL_W - 2, CELL_H - 2, { 0.2, 0.8, 1, 0.5 })
        local entity = state.entityManager:getEntityAt(cgx, cgy)
        if entity and not entity.isPlayer and (entity.hp == nil or entity.hp > 0) and entity.monsterId then
          local def = MonsterRegistry.get(entity.monsterId)
          if def then
            local char = game_state.get_character()
            local danger = compute_danger_level(char, def, entity.hp)
            draw_observer_hud(def, entity, danger)
          end
        else
          local tile = map:getTile(cgx, cgy)
          if tile then
            local gold = tile.groundGold or 0
            local items = tile.groundItems or {}
            if gold > 0 or #items > 0 then
              draw_loot_hud(gold, items)
            end
          end
        end
      end
    end

    draw_stats_panel()

    -- Journal unifie (3 dernieres phrases, clic = 200 details), sans cadre
    local log_mgr = require("core.game_log.log_manager")
    local log_entries = log_mgr.get_recent(LOG_PREVIEW_LINES)
    local logX = MINIMAP_PAD
    local logY = MINIMAP_PAD + 30
    if #log_entries > 0 then
      for i, entry in ipairs(log_entries) do
        local text = i18n.t(entry.messageKey, entry.params or {})
        if #text > 55 then text = text:sub(1, 52) .. "..." end
        platform.gfx_draw_text(text, logX, logY + (i - 1) * LOG_LINE_H)
      end
      platform.gfx_draw_text(i18n.t("log.click_hint"), logX, logY + #log_entries * LOG_LINE_H)
    end

    if dungeon_run_state.is_minimap_visible() then
      draw_minimap(map, px, py)
      draw_minimap_toggle_button(true)
    else
      local w = platform.gfx_width()
      local bx, by, bw, bh = w - 72, get_minimap_y(), 64, 24
      platform.gfx_draw_rect("fill", bx, by, bw, bh, COLORS.fill)
      platform.gfx_draw_rect("line", bx, by, bw, bh, COLORS.border)
      platform.gfx_draw_text(i18n.t("dungeon.minimap.show"), bx + 8, by + 4)
    end

    if input_state.isDirectionTarget() then
      local sdx, sdy = input_state.getSelectedDirection()
      local targetInfo = i18n.t("ui.targeting.cell_empty")
      if sdx ~= 0 or sdy ~= 0 then
        local player = state.entityManager:getPlayer()
        local weapon = player and player._character and player._character.equipmentManager and player._character.equipmentManager:getEquipped("weapon_main")
        weapon = weapon and (weapon.base or weapon)
        local range = (weapon and weapon.range) or 1
        local target_selector = require("core.targeting.target_selector")
        local target = target_selector.findTargetInDirection(
          px or 1, py or 1, sdx, sdy, range, map, state.entityManager, player
        )
        if target then
          targetInfo = i18n.t("ui.targeting.cell_enemy") .. ": " .. (target.nameKey and i18n.t(target.nameKey) or target.name or "?")
        end
      end
      local hintBase = h - h * BOTTOM_RAISE - HINT_ZONE
      platform.gfx_draw_text(i18n.t("ui.targeting.hint"), 10, hintBase + 8)
      platform.gfx_draw_text(">> " .. targetInfo, 10, hintBase + 28)
    elseif input_state.isObserver() then
      platform.gfx_draw_text(i18n.t("ui.observer.hint"), 10, h - h * BOTTOM_RAISE - HINT_ZONE + 8)
    elseif input_state.isUseItemTarget() then
      platform.gfx_draw_text(i18n.t("ui.use_item_target.hint"), 10, h - h * BOTTOM_RAISE - HINT_ZONE + 8)
    else
      platform.gfx_draw_text(i18n.t("dungeon.hint"), 10, h - h * BOTTOM_RAISE - HINT_ZONE + 8)
    end
  end

  return self
end

return M
