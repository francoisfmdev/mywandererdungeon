-- core/equipment/item_display.lua - Nom affiche des items (base + affixes)
local M = {}

local i18n = require("core.i18n")
local ConsumableRegistry = require("core.consumables.consumable_registry")

function M.getDisplayName(item, forceReveal)
  if not item then return "?" end
  local baseId = item.id or (item.base and item.base.id)
  if not baseId then return "?" end

  local identified = forceReveal or (item.identified ~= false)
  if not identified and item.base then
    return i18n.t("item.unknown_equipment") or "Objet inconnu"
  end

  local baseName
  if item.base then
    baseName = i18n.t("item.equipment." .. baseId)
  else
    local def = ConsumableRegistry.get(baseId)
    baseName = (def and def.nameKey and i18n.t(def.nameKey)) or i18n.t("item." .. baseId)
  end
  if not baseName or baseName:find("^%[%[missing") then baseName = baseId end

  local affixes = item.affixes
  if not affixes or #affixes == 0 then return baseName end

  local parts = { baseName }
  for _, a in ipairs(affixes) do
    local an = a.nameKey and i18n.t(a.nameKey) or (a.id and i18n.t("affix." .. a.id))
    if not an or an:find("^%[%[missing") then an = a.id or "?" end
    table.insert(parts, an)
  end
  return table.concat(parts, " ")
end

return M
