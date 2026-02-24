-- core/render/dungeon_renderer.lua - Rendu donjon (tuiles, entites) - sprites par config donjon
local M = {}

local platform = require("platform.love")

local _sprite_cache = {}
local _dungeon_config = nil
local _show_grid = false

function M.setDungeonConfig(cfg)
  _dungeon_config = cfg
end

function M.setShowGrid(show)
  _show_grid = show
end

function M.toggleGrid()
  _show_grid = not _show_grid
  return _show_grid
end

function M.isShowGrid()
  return _show_grid
end

local function get_sprite(path, no_cache_fail)
  if not path or path == "" then return nil end
  if _sprite_cache[path] then return _sprite_cache[path] end
  if not no_cache_fail and _sprite_cache[path] == false then return nil end
  local img = platform.gfx_load_image and platform.gfx_load_image(path)
  if img then
    _sprite_cache[path] = img
  elseif not no_cache_fail then
    _sprite_cache[path] = false
  end
  return img
end

--- Retourne true si la case (x,y) est un mur.
local function is_wall(map, gx, gy)
  if not map or not map:inBounds(gx, gy) then return false end
  local t = map:getTile(gx, gy)
  return t and t.type == "wall"
end

--- Retourne true si la case (x,y) est du sol (floor).
local function is_floor(map, gx, gy)
  if not map or not map:inBounds(gx, gy) then return false end
  local t = map:getTile(gx, gy)
  return t and t.type == "floor"
end

--- Selectionne le sprite mur selon les voisins (autotiling haut/bas/gauche/droite + 4 angles).
--- top/bottom = meme image (horizontal). left/right = meme image (vertical).
--- variation = affichee 10% du temps (deterministe par gx,gy).
local WALL_VARIATION_CHANCE = 0.10
local FLOOR_VARIATION_CHANCE = 0.10

--- Selectionne floor ou floor_variant 10% du temps (deterministe par gx, gy).
local function pick_floor_sprite(floorConfig, gx, gy)
  if type(floorConfig) ~= "table" then return floorConfig end
  local base = floorConfig.base or floorConfig
  local variant = floorConfig.variant
  if not variant then return base end
  local seed = (gx or 0) * 31337 + (gy or 0) * 7919
  return ((seed % 100) / 100) < FLOOR_VARIATION_CHANCE and variant or base
end

--- Base horizontal (top/bottom) et vertical (left/right). 10% variation deterministe par (gx,gy).
local function pick_base_with_variant(sprites, horizontal, gx, gy)
  local base = horizontal and (sprites.top or sprites.bottom or sprites.haut or sprites.bas)
    or (sprites.left or sprites.right or sprites.gauche or sprites.droite)
  local variant = horizontal and (sprites.topVariant or sprites.bottomVariant)
    or (sprites.leftVariant or sprites.rightVariant)
  if not variant then return base end
  local seed = (gx or 0) * 31337 + (gy or 0) * 7919
  return ((seed % 100) / 100) < WALL_VARIATION_CHANCE and variant or base
end

--- Pillar si intersection (*) ou virage de couloir. Angle si coin de piece (peu de sol autour).
local function use_pillar_for_corner(map, gx, gy)
  if not map then return false end
  local floor_count = 0
  for dx = -1, 1 do
    for dy = -1, 1 do
      if (dx ~= 0 or dy ~= 0) and is_floor(map, gx + dx, gy + dy) then
        floor_count = floor_count + 1
      end
    end
  end
  return floor_count >= 4
end

--- Autotiling mur : coherence logique pour alcoves, piliers, couloirs.
local function pick_wall_sprite(sprites, floorN, floorS, floorW, floorE, gx, gy, map)
  if not sprites or type(sprites) ~= "table" then return nil end
  local n, s, w, e = floorN and 1 or 0, floorS and 1 or 0, floorW and 1 or 0, floorE and 1 or 0
  -- 4 coins (sol sur 2 cotes adjacents) : intersection -> pillar, angle de piece -> corner
  if (s == 1 and e == 1) or (s == 1 and w == 1) or (n == 1 and e == 1) or (n == 1 and w == 1) then
    if use_pillar_for_corner(map, gx, gy) and sprites.pillar then
      return sprites.pillar
    end
    if s == 1 and e == 1 and n == 0 and w == 0 then return sprites.cornerTL or sprites.corner_tl end
    if s == 1 and w == 1 and n == 0 and e == 0 then return sprites.cornerTR or sprites.corner_tr end
    if n == 1 and e == 1 and s == 0 and w == 0 then return sprites.cornerBL or sprites.corner_bl end
    if n == 1 and w == 1 and s == 0 and e == 0 then return sprites.cornerBR or sprites.corner_br end
  end
  -- Pillar : sol sur les 4 cotes (mur au centre d'une intersection)
  if n == 1 and s == 1 and w == 1 and e == 1 then
    return sprites.pillar or sprites.default
  end
  -- Sol sur 1 seul cote
  if s == 1 and n == 0 and w == 0 and e == 0 then return pick_base_with_variant(sprites, true, gx, gy) end
  if n == 1 and s == 0 and w == 0 and e == 0 then return pick_base_with_variant(sprites, true, gx, gy) end
  if e == 1 and w == 0 and n == 0 and s == 0 then return pick_base_with_variant(sprites, false, gx, gy) end
  if w == 1 and e == 0 and n == 0 and s == 0 then return pick_base_with_variant(sprites, false, gx, gy) end
  -- Sol sur 3 cotes (coin interieur L) : utiliser angle pour eviter "manque angle"
  if n == 0 and s == 1 and w == 1 and e == 1 then return sprites.cornerTL or sprites.corner_tl end
  if n == 1 and s == 0 and w == 1 and e == 1 then return sprites.cornerBL or sprites.corner_bl end
  if e == 0 and w == 1 and n == 1 and s == 1 then return sprites.cornerTR or sprites.corner_tr end
  if e == 1 and w == 0 and n == 1 and s == 1 then return sprites.cornerBR or sprites.corner_br end
  -- Sol sur 2 cotes opposes (couloir) : N+S = segment vertical, E+W = segment horizontal
  if n == 1 and s == 1 and w == 0 and e == 0 then return pick_base_with_variant(sprites, false, gx, gy) end
  if w == 1 and e == 1 and n == 0 and s == 0 then return pick_base_with_variant(sprites, true, gx, gy) end
  return sprites.top or sprites.bottom or sprites.haut or sprites.bas or sprites.default
end

--- Retourne true si la case (x,y) est void ou hors limite ou non exploree (bord sombre).
--- Si void adjacent a un mur : on le dessine en sprite mur, donc pas considere comme bord sombre.
local function is_dark_edge(map, gx, gy)
  if not map or not map:inBounds(gx, gy) then return true end
  if not map:isExplored(gx, gy) then return true end
  local t = map:getTile(gx, gy)
  if not t then return true end
  if t.type == "void" and (is_wall(map, gx-1, gy) or is_wall(map, gx+1, gy) or is_wall(map, gx, gy-1) or is_wall(map, gx, gy+1)) then
    return false
  end
  return t.type == "void"
end

--- Dessine une case (sol/mur/void). Utilise dungeonConfig.sprites[type] ou tile.sprite.
--- Si map, gx, gy fournis : dessine des bords sombres sur les murs adjacents au void/brouillard.
function M.draw_tile(tile, screenX, screenY, cellW, cellH, map, gx, gy)
  local fill = { 0.1, 0.08, 0.12, 1 }
  if tile then
    if tile.type == "floor" then
      fill = { 0.2, 0.15, 0.25, 1 }
    elseif tile.type == "void" then
      fill = { 20/255, 20/255, 20/255, 1 }
    end
  end

  local spritePath = nil
  if tile then
    spritePath = tile.sprite
    if not spritePath and _dungeon_config and _dungeon_config.sprites then
      if tile.isExit then
        spritePath = _dungeon_config.sprites.exit
      elseif tile.type == "wall" and map and gx and gy then
        local wallSprites = _dungeon_config.sprites.wall
        if type(wallSprites) == "table" then
          local floorN = is_floor(map, gx, gy - 1)
          local floorS = is_floor(map, gx, gy + 1)
          local floorW = is_floor(map, gx - 1, gy)
          local floorE = is_floor(map, gx + 1, gy)
          spritePath = pick_wall_sprite(wallSprites, floorN, floorS, floorW, floorE, gx, gy, map)
        else
          spritePath = wallSprites
        end
      elseif tile.type == "floor" and _dungeon_config.sprites.floor then
        spritePath = pick_floor_sprite(_dungeon_config.sprites.floor, gx, gy)
      -- void : toujours simple case noire, jamais de sprites (autour des salles et couloirs)
      elseif tile.type == "void" then
        -- pas de spritePath, on garde le fill noir
      else
        if tile.type ~= "void" then
          spritePath = _dungeon_config.sprites[tile.type]
        end
      end
    end
  end
  local img = spritePath and get_sprite(spritePath)

  if img and platform.gfx_draw_image then
    platform.gfx_draw_image(img, screenX, screenY, cellW, cellH)
  else
    platform.gfx_draw_rect("fill", screenX, screenY, cellW, cellH, fill)
    if _show_grid then
      platform.gfx_draw_rect("line", screenX, screenY, cellW, cellH, { 0.3, 0.25, 0.4, 0.8 })
    end
  end

  -- Bords sombres sur les murs adjacents au void ou au brouillard (transition propre)
  if tile and tile.type == "wall" and map and gx and gy then
    local edgeColor = { 0, 0, 0, 0.9 }
    local edgeW = math.max(1, math.floor(math.min(cellW, cellH) * 0.1))
    if is_dark_edge(map, gx, gy - 1) then
      platform.gfx_draw_rect("fill", screenX, screenY, cellW, edgeW, edgeColor)
    end
    if is_dark_edge(map, gx, gy + 1) then
      platform.gfx_draw_rect("fill", screenX, screenY + cellH - edgeW, cellW, edgeW, edgeColor)
    end
    if is_dark_edge(map, gx - 1, gy) then
      platform.gfx_draw_rect("fill", screenX, screenY, edgeW, cellH, edgeColor)
    end
    if is_dark_edge(map, gx + 1, gy) then
      platform.gfx_draw_rect("fill", screenX + cellW - edgeW, screenY, edgeW, cellH, edgeColor)
    end
  end

  if not img and tile and tile.isExit then
    local pad = math.floor(cellW * 0.25)
    platform.gfx_draw_rect("fill", screenX + pad, screenY + pad, cellW - pad * 2, cellH - pad * 2, { 0.4, 0.85, 0.5, 0.9 })
    platform.gfx_draw_rect("line", screenX + pad, screenY + pad, cellW - pad * 2, cellH - pad * 2, { 0.6, 1, 0.7, 1 })
  end

  -- Piege multi-activation revele : affiche apres premiere activation
  if tile and tile.trap and tile.trap.revealed and not tile.trap.oneShot then
    local pad = math.floor(cellW * 0.25)
    platform.gfx_draw_rect("fill", screenX + pad, screenY + pad, cellW - pad * 2, cellH - pad * 2, { 0.6, 0.25, 0.2, 0.85 })
    platform.gfx_draw_rect("line", screenX + pad, screenY + pad, cellW - pad * 2, cellH - pad * 2, { 0.9, 0.4, 0.2, 1 })
  end
end

--- Dessine le loot au sol (or, objets) sur une case.
--- Taille proportionnelle a la cellule pour etre bien visible.
function M.draw_ground_loot(tile, screenX, screenY, cellW, cellH)
  if not tile then return end
  local gold = tile.groundGold or 0
  local items = tile.groundItems or {}
  if gold <= 0 and #items == 0 then return end

  local size = math.floor(math.min(cellW, cellH) * 0.55)
  local cx = screenX + cellW / 2
  local cy = screenY + cellH / 2

  if gold > 0 then
    local gx = cx - size / 2 - (items and #items > 0 and size * 0.3 or 0)
    local goldSprite = (_dungeon_config and _dungeon_config.sprites and _dungeon_config.sprites.gold)
      or "assets/generals/gold.png"
    local img = get_sprite(goldSprite)
    if img and platform.gfx_draw_image then
      platform.gfx_draw_image(img, gx, cy - size / 2, size, size)
    else
      platform.gfx_draw_rect("fill", gx, cy - size / 2, size, size, { 0.9, 0.75, 0.2, 0.95 })
      platform.gfx_draw_rect("line", gx, cy - size / 2, size, size, { 1, 0.9, 0.4, 1 })
    end
  end
  if #items > 0 then
    local ix = cx - size / 2 + (gold > 0 and size * 0.3 or 0)
    platform.gfx_draw_rect("fill", ix, cy - size / 2, size, size, { 0.4, 0.7, 0.9, 0.95 })
    platform.gfx_draw_rect("line", ix, cy - size / 2, size, size, { 0.6, 0.85, 1, 1 })
  end
end

--- Dessine une entite (joueur, monstre). Utilise dungeonConfig.entitySprites[monsterId], entity.sprite.
--- entitySprites: paths = plusieurs images (hero, rat) | path + frames = sprite sheet decoupe.
--- paths prioritaire sur path pour animation 2 poses (hero.png, hero_2.png).
local IDLE_FRAME_DURATION = 0.35

local function draw_entity_sprite(img, screenX, screenY, cellW, cellH, frameIndex, totalFrames, scale)
  if not img or not platform.gfx_draw_image then return false end
  scale = scale or 1
  local drawW, drawH = cellW * scale, cellH * scale
  local offsetX, offsetY = (cellW - drawW) / 2, (cellH - drawH) / 2
  local x, y = screenX + offsetX, screenY + offsetY
  if totalFrames <= 1 then
    platform.gfx_draw_image(img, x, y, drawW, drawH)
    return true
  end
  local iw, ih = img:getWidth(), img:getHeight()
  if not iw or not ih then return false end
  local vertical = ih >= iw
  local fw, fh
  if vertical then
    fw, fh = iw, math.floor(ih / totalFrames)
  else
    fw, fh = math.floor(iw / totalFrames), ih
  end
  local idx = math.max(0, math.min(frameIndex, totalFrames - 1))
  local sx = vertical and 0 or (idx * fw)
  local sy = vertical and (idx * fh) or 0
  platform.gfx_draw_image(img, x, y, drawW, drawH, sx, sy, fw, fh)
  return true
end

local function draw_entity_sprite_multi(imgs, screenX, screenY, cellW, cellH, frameIndex, scale)
  if not imgs or #imgs == 0 or not platform.gfx_draw_image then return false end
  scale = scale or 1
  local drawW, drawH = cellW * scale, cellH * scale
  local offsetX, offsetY = (cellW - drawW) / 2, (cellH - drawH) / 2
  local x, y = screenX + offsetX, screenY + offsetY
  local idx = math.max(1, math.min(frameIndex + 1, #imgs))
  local img = imgs[idx]
  if not img then return false end
  platform.gfx_draw_image(img, x, y, drawW, drawH)
  return true
end

function M.draw_entity(entity, screenX, screenY, cellW, cellH, isPlayer)
  local fill = isPlayer and { 0.2, 0.6, 1, 1 } or { 0.8, 0.2, 0.2, 1 }
  local pad = math.max(2, math.floor(cellW * 0.1))
  local scale = (_dungeon_config and _dungeon_config.entitySpriteScale) or 1.0

  local spriteRef = nil
  if entity then
    spriteRef = entity.sprite
    if not spriteRef and _dungeon_config and _dungeon_config.entitySprites then
      if isPlayer then
        spriteRef = _dungeon_config.entitySprites.player
      else
        spriteRef = entity.monsterId and _dungeon_config.entitySprites[entity.monsterId]
      end
    end
    if not spriteRef and not isPlayer and entity.monsterId then
      spriteRef = "assets/entities/" .. entity.monsterId .. ".png"
    end
  end

  local img, frames, paths = nil, 1, nil
  if type(spriteRef) == "table" then
    if spriteRef.paths then
      paths = {}
      for _, p in ipairs(spriteRef.paths) do
        local sp = get_sprite(p, true)  -- no_cache_fail: retry rat_2 etc. si chargement echoue
        if sp then table.insert(paths, sp) end
      end
      frames = math.max(1, #paths)
    elseif spriteRef.path then
      img = get_sprite(spriteRef.path)
      frames = tonumber(spriteRef.frames) or 2
    end
  elseif type(spriteRef) == "string" then
    img = get_sprite(spriteRef)
  end

  if paths and #paths > 0 then
    local t = platform.gfx_get_time and platform.gfx_get_time() or 0
    local phase = 0
    if entity and entity.id then
      for i = 1, math.min(#entity.id, 4) do phase = phase + (entity.id:byte(i) or 0) end
    end
    local idx = math.floor((t + phase * 0.05) / IDLE_FRAME_DURATION) % frames
    if draw_entity_sprite_multi(paths, screenX, screenY, cellW, cellH, idx, scale) then
      return
    end
  elseif img then
    local t = platform.gfx_get_time and platform.gfx_get_time() or 0
    local phase = 0
    if entity and entity.id then
      for i = 1, math.min(#entity.id, 4) do phase = phase + (entity.id:byte(i) or 0) end
    end
    local idx = math.floor((t + phase * 0.05) / IDLE_FRAME_DURATION) % frames
    if draw_entity_sprite(img, screenX, screenY, cellW, cellH, idx, frames, scale) then
      return
    end
  end

  platform.gfx_draw_rect("fill", screenX + pad, screenY + pad, cellW - pad * 2, cellH - pad * 2, fill)
end

--- Vide le cache des sprites (utile en reload/dev)
function M.clear_sprite_cache()
  _sprite_cache = {}
end

return M
