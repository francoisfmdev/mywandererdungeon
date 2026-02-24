-- core/equipment/item_display.lua - Nom affiche, effet, sprite des items
local M = {}

local i18n = require("core.i18n")
local ConsumableRegistry = require("core.consumables.consumable_registry")

local _item_sprites = nil
local function get_item_sprites()
  if _item_sprites then return _item_sprites end
  local ok, sp = pcall(require, "data.items.item_sprites")
  _item_sprites = (ok and sp) or {}
  return _item_sprites
end

function M.getSpritePath(item)
  if not item then return nil end
  local id = item.id or (item.base and item.base.id)
  if not id then return nil end
  local sp = get_item_sprites()
  return sp[id]
end

--- Description courte de l'effet pour tooltip (consommables)
function M.getConsumableEffectText(item)
  if not item then return "" end
  local def = ConsumableRegistry.get(item.id or (item.base and item.base.id))
  if not def then return "" end
  local effect = def.effect
  if effect == "heal_hp" and def.amount then
    return i18n.t("item.effect.heal_hp_amount", { amount = def.amount })
  end
  if effect == "cure_effect" and def.cureEffect then
    local effName = i18n.t("log.effect." .. def.cureEffect) or def.cureEffect
    return i18n.t("item.effect.cure", { effect = effName })
  end
  local key = "item.effect." .. (def.id or effect or "")
  local t = i18n.t(key)
  if t and not t:find("^%[%[missing") then return t end
  return ""
end

--- Details arme (degats, effet) ou armure (AC, hitBonus) pour panneau equipement
function M.getWeaponDetails(item)
  if not item then return "" end
  local base = item.base or item
  local bonuses = item.bonuses or base.bonuses or {}
  if not base.slot then return "" end
  if base.slot == "armor" then
    local parts = {}
    local ac = bonuses.ac or 0
    if ac ~= 0 then table.insert(parts, "AC +" .. ac) end
    local hb = bonuses.hitBonus or 0
    if hb ~= 0 then table.insert(parts, (hb > 0 and "+" or "") .. hb .. "% precision") end
    return table.concat(parts, " | ")
  end
  if base.slot ~= "weapon_main" and base.slot ~= "weapon_off" then return "" end
  local parts = {}
  local dmg = base.damageMin and base.damageMax and (base.damageMin .. "-" .. base.damageMax) or "?"
  table.insert(parts, dmg .. " " .. (base.damageType or "physique"))
  if base.baseHitChance then
    table.insert(parts, base.baseHitChance .. "% precision")
  elseif base.hitBonus and base.hitBonus ~= 0 then
    table.insert(parts, (base.hitBonus > 0 and "+" or "") .. base.hitBonus .. " precision")
  end
  if base.applyEffect then
    local effName = i18n.t("log.effect." .. base.applyEffect) or base.applyEffect
    local ch = base.applyEffectChance and (math.floor((base.applyEffectChance or 0) * 100) .. "%") or ""
    table.insert(parts, (ch ~= "" and ch .. " " or "") .. effName)
  end
  return table.concat(parts, " | ")
end

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
