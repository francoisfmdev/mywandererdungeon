-- platform/love.lua - Adaptation Love2D, interface neutre
local M = {}

function M.fs_exists(path)
  return love.filesystem.getInfo(path) ~= nil
end

function M.fs_read(path)
  local info = love.filesystem.getInfo(path)
  if not info or info.type ~= "file" then return nil end
  local data, err = love.filesystem.read(path)
  return data
end

function M.fs_write(path, contents)
  return love.filesystem.write(path, contents)
end

-- Chemin du fichier config (dans le save directory Love2D)
function M.fs_config_path()
  return "config.lua"
end

function M.log(msg)
  print(msg)
end

function M.quit()
  love.event.quit()
end

function M.gfx_clear()
  love.graphics.clear(0.1, 0.1, 0.15, 1)
end

function M.gfx_present()
  -- Love2D presente automatiquement en love.draw
end

function M.gfx_width()
  return love.graphics.getWidth()
end

function M.gfx_height()
  return love.graphics.getHeight()
end

function M.gfx_draw_text(text, x, y, color)
  love.graphics.setColor(color or { 1, 1, 1, 1 })
  love.graphics.print(text, x, y)
end

function M.gfx_draw_rect(mode, x, y, w, h, color)
  love.graphics.setColor(color or { 1, 1, 1, 1 })
  if mode == "fill" then
    love.graphics.rectangle("fill", x, y, w, h)
  else
    love.graphics.rectangle("line", x, y, w, h)
  end
end

function M.gfx_get_font()
  return love.graphics.getFont()
end

--- Charge une police : path nil ou absent = police par defaut a la taille size.
--- Retourne la police ou nil en cas d'erreur.
function M.gfx_load_font(path, size)
  size = tonumber(size) or 12
  if not path or path == "" then
    local ok, font = pcall(love.graphics.newFont, size)
    return ok and font or nil
  end
  local fs = love.filesystem
  if not fs.getInfo or not fs.getInfo(path) then return nil end
  local ok, font = pcall(love.graphics.newFont, path, size)
  return ok and font or nil
end

--- Definit la police courante. Retourne la police precedente.
function M.gfx_set_font(font)
  local prev = love.graphics.getFont()
  if font then love.graphics.setFont(font) end
  return prev
end

--- Charge une image. Noir pur (0,0,0) = transparent pour permettre teintes ambiance.
function M.gfx_load_image(path)
  local ok, data = pcall(love.image.newImageData, path)
  if not ok or not data then return nil end
  -- Noir (0,0,0) -> transparent pour teinter les donjons
  data:mapPixel(function(x, y, r, g, b, a)
    if r <= 1/255 and g <= 1/255 and b <= 1/255 then
      return r, g, b, 0
    end
    return r, g, b, a
  end)
  local img = love.graphics.newImage(data)
  if img then
    img:setFilter("nearest", "nearest")
  end
  return img
end

function M.gfx_draw_image(img, x, y, w, h, sx, sy, sw, sh)
  if not img then return end
  love.graphics.setColor(1, 1, 1, 1)
  if sx and sy and sw and sh then
    local iw, ih = img:getDimensions()
    local quad = love.graphics.newQuad(sx, sy, sw, sh, iw, ih)
    local scaleX = w and (w / sw) or 1
    local scaleY = h and (h / sh) or 1
    love.graphics.draw(img, quad, x, y, 0, scaleX, scaleY)
  elseif w and h then
    love.graphics.draw(img, x, y, 0, w / img:getWidth(), h / img:getHeight())
  else
    love.graphics.draw(img, x, y)
  end
end

--- Retourne le temps en secondes (pour animation idle).
function M.gfx_get_time()
  return love.timer and love.timer.getTime and love.timer.getTime() or 0
end

function M.input_register(on_key, on_key_release)
  M._on_key = on_key
  M._on_key_release = on_key_release
end

function M.input_poll()
  -- Les touches sont traitees dans love.keypressed
  -- On ne fait rien ici, le polling est gere par love
end

function M.keypressed(key, scancode, isrepeat)
  if M._raw_key_listener then
    M._raw_key_listener(key)
    return
  end
  if M._on_key then M._on_key(key) end
end

function M.set_raw_key_listener(fn)
  M._raw_key_listener = fn
end

function M.keyreleased(key, scancode)
  if M._on_key_release then M._on_key_release(key) end
end

function M.window_set_mode(w, h, fullscreen)
  love.window.setMode(w, h, { fullscreen = fullscreen })
end

function M.audio_set_volume(v)
  love.audio.setVolume(math.max(0, math.min(1, v)))
end

function M.mouse_get_position()
  return love.mouse.getPosition()
end

function M.mousepressed(x, y, button)
  M._mouse_clicks = M._mouse_clicks or {}
  M._mouse_clicks[button] = { x = x, y = y }
end

function M.mouse_peek_click(button)
  local c = M._mouse_clicks and M._mouse_clicks[button]
  if c then return c.x, c.y end
  return nil
end

function M.mouse_consume_click(button)
  local c = M._mouse_clicks and M._mouse_clicks[button]
  if c then
    M._mouse_clicks[button] = nil
    return c.x, c.y
  end
  return nil
end

function M.mouse_end_frame()
  M._mouse_clicks = {}
end

return M
