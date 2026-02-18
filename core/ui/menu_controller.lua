-- core/ui/menu_controller.lua - Navigation menu generique (up/down, confirm, back)
local M = {}

local input = require("core.input")
local platform = require("platform.love")

function M.update(items, selectedIndex, options)
  options = options or {}
  local onConfirm = options.onConfirm
  local onBack = options.onBack
  local horizontal = options.orientation == "horizontal"

  local function movePrev()
    selectedIndex = selectedIndex - 1
    if selectedIndex < 1 then selectedIndex = #items end
  end
  local function moveNext()
    selectedIndex = selectedIndex + 1
    if selectedIndex > #items then selectedIndex = 1 end
  end

  if input.consume(horizontal and "left" or "up") then
    movePrev()
    return selectedIndex
  end
  if input.consume(horizontal and "right" or "down") then
    moveNext()
    return selectedIndex
  end
  if input.consume("confirm") then
    if onConfirm then
      onConfirm(items[selectedIndex], selectedIndex)
    end
    return selectedIndex
  end
  if input.consume("back") then
    if onBack then onBack() end
    return selectedIndex
  end

  if platform.mouse_peek_click and options.getBoundsForIndex then
    local mx, my = platform.mouse_peek_click(1)
    if mx and my then
      for i = 1, #items do
        local x, y, bw, bh = options.getBoundsForIndex(i)
        if mx >= x and mx < x + bw and my >= y and my < y + bh then
          platform.mouse_consume_click(1)
          if onConfirm then onConfirm(items[i], i) end
          break
        end
      end
    end
  end

  return selectedIndex
end

return M
