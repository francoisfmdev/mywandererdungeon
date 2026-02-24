-- core/combat/damage_calculator.lua - HitChance, Damage, Crit, Resistances
local M = {}

local MOD_DIVISOR = 5
local HIT_BASE = 90
local HIT_PER_MOD = 3
local HIT_MIN = 70
local HIT_MAX = 97
local CRIT_BASE = 5
local CRIT_PER_DEX = 1
local CRIT_MAX = 25
local CRIT_MULT = 2
local DAMAGE_VAR_MIN = 0.9
local DAMAGE_VAR_MAX = 1.1

function M.getStatModifier(entity, statName)
  if not entity or not statName then return 0 end
  local val
  if entity.getEffectiveStat then
    val = entity:getEffectiveStat(statName)
  elseif entity.getStat then
    val = entity:getStat(statName)
  elseif entity.stats and type(entity.stats) == "table" then
    val = entity.stats[statName]
  end
  if val == nil then return 0 end
  return math.floor((tonumber(val) or 0) / MOD_DIVISOR)
end

--- Precision : arme ou baguette peut donner hitBonus. Equipement (armure) peut aussi.
--- Si baseHitChance est defini sur l'arme, il remplace le calcul (ex: 50 pour 50 %).
function M.computeHitChance(attacker, defender, weapon)
  if weapon then
    local w = weapon.base or weapon
    local baseChance = tonumber(w.baseHitChance)
    if baseChance then
      local eqBonus = 0
      if attacker._character and attacker._character.equipmentManager then
        local bonuses = attacker._character.equipmentManager:getBonuses()
        eqBonus = bonuses.hitBonus or 0
      end
      return math.max(1, math.min(100, baseChance + eqBonus))
    end
  end
  local attMod = M.getStatModifier(attacker, "dexterity")
  local defMod = defender and M.getStatModifier(defender, "dexterity") or 0
  local hitBonus = 0
  if weapon then
    local w = weapon.base or weapon
    hitBonus = tonumber(w.hitBonus) or 0
  end
  if attacker._character and attacker._character.equipmentManager then
    local bonuses = attacker._character.equipmentManager:getBonuses()
    hitBonus = hitBonus + (bonuses.hitBonus or 0)
  end
  local hitChance = HIT_BASE + (attMod - defMod) * HIT_PER_MOD + hitBonus
  return math.max(HIT_MIN, math.min(HIT_MAX, hitChance))
end

function M.rollHit(hitChance)
  return math.random(1, 100) <= hitChance
end

--- Crit : peut venir de l'arme (critBonus).
function M.computeCritChance(attacker, weapon)
  local dexMod = M.getStatModifier(attacker, "dexterity")
  local critBonus = 0
  if weapon then
    local w = weapon.base or weapon
    critBonus = tonumber(w.critBonus) or 0
  end
  return math.min(CRIT_MAX, CRIT_BASE + dexMod * CRIT_PER_DEX + critBonus)
end

function M.rollCrit(critChance)
  if critChance <= 0 then return false end
  return math.random(1, 100) <= critChance
end

--- Retourne une valeur aleatoire entre min et max (inclus).
function M.rollMinMax(minVal, maxVal)
  local minD = tonumber(minVal) or 0
  local maxD = tonumber(maxVal) or 0
  if maxD < minD then maxD = minD end
  return math.random(minD, maxD)
end

function M.computePhysicalDamage(attacker, defender, weapon)
  local weaponDamage = 0
  if weapon then
    local minDmg = tonumber(weapon.damageMin) or 1
    local maxDmg = tonumber(weapon.damageMax) or 1
    if maxDmg < minDmg then maxDmg = minDmg end
    weaponDamage = math.random(minDmg, maxDmg)
  end
  local modStr = M.getStatModifier(attacker, weapon and weapon.statUsed or "strength")
  local equipAttack = 0
  if attacker.getEquipmentAttackBonus then
    equipAttack = attacker:getEquipmentAttackBonus() or 0
  end
  local attackPower = weaponDamage + modStr + equipAttack

  local armorValue = 0
  local equipDefense = 0
  if defender.getArmorValue then
    armorValue = defender:getArmorValue() or 0
  end
  if defender.getEquipmentDefenseBonus then
    equipDefense = defender:getEquipmentDefenseBonus() or 0
  end
  if equipDefense == 0 and defender.getEffectiveAC then
    equipDefense = math.max(0, (defender:getEffectiveAC() or 0) - 10)
  end
  local defensePower = armorValue + equipDefense

  local rawDamage = math.max(1, attackPower - defensePower)
  local roll = DAMAGE_VAR_MIN + math.random() * (DAMAGE_VAR_MAX - DAMAGE_VAR_MIN)
  return rawDamage * roll
end

function M.applyCrit(damage, isCrit)
  if not isCrit then return damage end
  return damage * CRIT_MULT
end

local PHYSICAL_TYPES = { slashing = true, piercing = true, blunt = true }
local function is_physical_type(t) return t and PHYSICAL_TYPES[t] end

--- Types physiques : slashing, piercing, blunt
--- Types elementaires : fire, ice, lightning, poison, light, dark
function M.applyResistance(damage, damageType, defender)
  if not defender or damage <= 0 then return { damage = 0, healed = 0 } end

  -- Effet ethéré : physiques = 0, magiques = x2
  if defender.effectManager and defender.effectManager.hasEffect and defender.effectManager:hasEffect("ethereal") then
    if is_physical_type(damageType) then
      return { damage = 0, healed = 0 }
    end
    if damageType and damageType ~= "heal" then
      return { damage = damage * 2, healed = 0 }
    end
  end

  local res
  if defender.getEffectiveResistances then
    res = defender:getEffectiveResistances() or {}
  else
    res = defender.resistances or {}
  end
  local resVal = 0
  if type(res) == "table" and damageType then
    resVal = res[damageType] or res["all"] or 0
  end
  resVal = tonumber(resVal) or 0

  if resVal >= 100 then
    local excess = resVal - 100
    local healed = 0
    if excess > 0 then
      healed = math.floor(damage * (excess / 100))
    end
    return { damage = 0, healed = healed }
  end

  if resVal <= 0 then
    return { damage = damage, healed = 0 }
  end

  local reduced = damage * (1 - resVal / 100)
  return { damage = reduced, healed = 0 }
end

return M
