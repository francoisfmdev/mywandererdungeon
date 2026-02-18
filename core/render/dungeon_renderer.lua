-- core/render/dungeon_renderer.lua - Rendu donjon (tuiles, entites) - sprites par config donjon
local M = {}

local platform = require("platform.love")

local _sprite_cache = {}
local _dungeon_config = nil

function M.setDungeonConfig(cfg)
  _dungeon_config = cfg
end

local function get_sprite(path)
  if not path or path == "" then return nil end
  if _sprite_cache[path] == false then return nil end
  if _sprite_cache[path] then return _sprite_cache[path] end
  local img = platform.gfx_load_image and platform.gfx_load_image(path)
  _sprite_cache[path] = img or false
  return img
end

--- Dessine une case (sol/mur). Utilise dungeonConfig.sprites[type] ou tile.sprite, sinon couleur.
function M.draw_tile(tile, screenX, screenY, cellW, cellH)
  local fill = { 0.1, 0.08, 0.12, 1 }
  if tile and tile.type == "floor" then
    fill = { 0.2, 0.15, 0.25, 1 }
  end

  local spritePath = nil
  if tile then
    spritePath = tile.sprite
    if not spritePath and _dungeon_config and _dungeon_config.sprites then
      spritePath = _dungeon_config.sprites[tile.type]
    end
  end
  local img = spritePath and get_sprite(spritePath)

  if img and platform.gfx_draw_image then
    platform.gfx_draw_image(img, screenX, screenY, cellW, cellH)
  else
    platform.gfx_draw_rect("fill", screenX, screenY, cellW, cellH, fill)
    platform.gfx_draw_rect("line", screenX, screenY, cellW, cellH, { 0.3, 0.25, 0.4, 0.8 })
  end
end

--- Dessine le loot au sol (or, objets) sur une case.
function M.draw_ground_loot(tile, screenX, screenY, cellW, cellH)
  if not tile then return end
  local gold = tile.groundGold or 0
  local items = tile.groundItems or {}
  if gold <= 0 and #items == 0 then return end

  local pad = math.max(2, math.floor(cellW * 0.15))
  local size = math.min(cellW - pad * 2, cellH - pad * 2)
  local cx = screenX + cellW / 2
  local cy = screenY + cellH / 2

  if gold > 0 then
    local gx = cx - size / 2 - (items and #items > 0 and size * 0.3 or 0)
    platform.gfx_draw_rect("fill", gx, cy - size / 2, size, size, { 0.9, 0.75, 0.2, 0.95 })
    platform.gfx_draw_rect("line", gx, cy - size / 2, size, size, { 1, 0.9, 0.4, 1 })
  end
  if #items > 0 then
    local ix = cx - size / 2 + (gold > 0 and size * 0.3 or 0)
    platform.gfx_draw_rect("fill", ix, cy - size / 2, size, size, { 0.4, 0.7, 0.9, 0.95 })
    platform.gfx_draw_rect("line", ix, cy - size / 2, size, size, { 0.6, 0.85, 1, 1 })
  end
end

--- Dessine une entite (joueur, monstre). Utilise dungeonConfig.entitySprites[monsterId], entity.sprite, sinon couleur.
function M.draw_entity(entity, screenX, screenY, cellW, cellH, isPlayer)
  local fill = isPlayer and { 0.2, 0.6, 1, 1 } or { 0.8, 0.2, 0.2, 1 }
  local pad = math.max(2, math.floor(cellW * 0.1))

  local spritePath = nil
  if entity then
    spritePath = entity.sprite
    if not spritePath and _dungeon_config and _dungeon_config.entitySprites then
      if isPlayer then
        spritePath = _dungeon_config.entitySprites.player
      else
        spritePath = entity.monsterId and _dungeon_config.entitySprites[entity.monsterId]
      end
    end
    if not spritePath and not isPlayer and entity.monsterId then
      spritePath = "assets/entities/" .. entity.monsterId .. ".png"
    end
  end
  local img = spritePath and get_sprite(spritePath)

  if img and platform.gfx_draw_image then
    platform.gfx_draw_image(img, screenX, screenY, cellW, cellH)
  else
    platform.gfx_draw_rect("fill", screenX + pad, screenY + pad, cellW - pad * 2, cellH - pad * 2, fill)
  end
end

--- Vide le cache des sprites (utile en reload/dev)
function M.clear_sprite_cache()
  _sprite_cache = {}
end

return M
