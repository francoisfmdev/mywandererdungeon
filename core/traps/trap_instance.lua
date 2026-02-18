-- core/traps/trap_instance.lua - Instance d'un piege sur la carte
local M = {}

--- Cree une instance de piege.
--- state: "armed" | "triggered" | "disabled" (disabled non implemente)
function M.new(trapId, x, y, def)
  if not def then
    local registry = require("core.traps.trap_registry")
    def = registry.get(trapId)
  end
  if not def then return nil end
  local oneShot = def.oneShot == true
  return {
    id = trapId,
    x = x,
    y = y,
    oneShot = oneShot,
    triggered = false,
    effect = def.effect or {},
    state = "armed",
    _def = def,
  }
end

return M
