-- core/combat/combat_resolver.lua - Modele simplifie (HitChance, Damage, Crit, Res)
local M = {}

local damage_calculator = require("core.combat.damage_calculator")

local function getEntityHp(entity)
  if not entity then return 0 end
  return tonumber(entity.hp) or 0
end

local function getEntityMaxHp(entity)
  if not entity then return 0 end
  return tonumber(entity.maxHp) or 1
end

local function setEntityHp(entity, value)
  if not entity then return end
  local maxHp = getEntityMaxHp(entity)
  entity.hp = math.max(0, math.min(value, maxHp))
  if entity._character and entity._character.setHP then
    entity._character:setHP(entity.hp)
  end
end

local function getEntityMp(entity)
  if not entity then return 0 end
  return tonumber(entity.mp) or 0
end

local function consumeMp(entity, amount)
  if not entity then return false end
  local current = getEntityMp(entity)
  if current < amount then return false end
  entity.mp = current - amount
  if entity._character and entity._character.setMP then
    entity._character:setMP(entity.mp)
  end
  return true
end

local function getEffectiveMpCost(caster, baseCost)
  if not caster or not baseCost or baseCost <= 0 then return baseCost or 0 end
  local mult = 1
  if caster.effectManager and caster.effectManager.getMpCostMultiplier then
    mult = caster.effectManager:getMpCostMultiplier() or 1
  end
  return math.max(1, math.floor(baseCost * mult))
end

local function ensureDamageType(weapon)
  return (weapon and weapon.damageType) or "slashing"
end

local function ensureSpellDamageType(spell)
  return (spell and spell.damageType) or "fire"
end

function M.resolveAttack(attacker, defender, weapon)
  local result = {
    hit = false,
    critical = false,
    damage = 0,
    healed = 0,
    defenderHp = getEntityHp(defender),
  }

  if not attacker or not defender or not weapon then
    return result
  end

  local hitChance = damage_calculator.computeHitChance(attacker, defender)
  if not damage_calculator.rollHit(hitChance) then
    result.defenderHp = getEntityHp(defender)
    return result
  end

  result.hit = true
  local critChance = damage_calculator.computeCritChance(attacker)
  result.critical = damage_calculator.rollCrit(critChance)

  local rawDamage = damage_calculator.computePhysicalDamage(attacker, defender, weapon)
  rawDamage = damage_calculator.applyCrit(rawDamage, result.critical)
  rawDamage = math.max(1, math.floor(rawDamage))

  local damageType = ensureDamageType(weapon)
  local resist = damage_calculator.applyResistance(rawDamage, damageType, defender)

  if resist.healed > 0 then
    result.healed = resist.healed
    setEntityHp(defender, getEntityHp(defender) + resist.healed)
  end

  if resist.damage > 0 then
    result.damage = math.max(1, math.floor(resist.damage))
    setEntityHp(defender, getEntityHp(defender) - result.damage)
    if defender then defender.shakeFrames = 12 end
  end

  result.defenderHp = getEntityHp(defender)
  return result
end

--- Applique le tremblement a une entite touchee (attaque, sort, piege, effet)
function M.applyShake(entity, frames)
  if entity then entity.shakeFrames = frames or 12 end
end

function M.resolveSpell(caster, target, spell, options)
  local result = {
    hit = false,
    critical = false,
    damage = 0,
    healed = 0,
    defenderHp = target and getEntityHp(target) or 0,
  }

  if not caster or not spell then
    return result
  end

  local skipMp = options and options.skipMpCost
  if not skipMp then
    local baseCost = spell.mpCost or 0
    local mpCost = getEffectiveMpCost(caster, baseCost)
    if getEntityMp(caster) < mpCost then
      return result
    end
    if not consumeMp(caster, mpCost) then
      return result
    end
  end

  local hitChance = damage_calculator.computeHitChance(caster, target or caster)

  if target and not damage_calculator.rollHit(hitChance) then
    result.defenderHp = getEntityHp(target)
    return result
  end

  result.hit = true
  local critChance = damage_calculator.computeCritChance(caster)
  result.critical = damage_calculator.rollCrit(critChance)

  local isHeal = (spell.damageType or "") == "heal"
  local hasDamage = (spell.damageMin and spell.damageMax) or (spell.damageMin or spell.damageMax)
  if not target or (not isHeal and not hasDamage) then
    result.defenderHp = target and getEntityHp(target) or 0
    return result
  end

  local amount = 0
  if isHeal then
    amount = damage_calculator.rollMinMax(spell.damageMin or 0, spell.damageMax or 0)
    if amount > 0 then
      local statMod = damage_calculator.getStatModifier(caster, spell.statMag or "wisdom")
      amount = math.max(1, amount + statMod)
      result.healed = amount
      setEntityHp(target, getEntityHp(target) + amount)
    end
  else
    amount = damage_calculator.rollMinMax(spell.damageMin or 1, spell.damageMax or 1)
    if amount > 0 then
      local statMod = damage_calculator.getStatModifier(caster, spell.statMag or "intelligence")
      amount = amount + statMod
      amount = math.max(1, amount)
      amount = damage_calculator.applyCrit(amount, result.critical)
      amount = math.max(1, math.floor(amount))

      local damageType = ensureSpellDamageType(spell)
      local resist = damage_calculator.applyResistance(amount, damageType, target)

      if resist.healed > 0 then
        result.healed = resist.healed
        setEntityHp(target, getEntityHp(target) + resist.healed)
      end

      if resist.damage > 0 then
        result.damage = math.max(1, math.floor(resist.damage))
        setEntityHp(target, getEntityHp(target) - result.damage)
        if target then target.shakeFrames = 12 end
      end
    end
  end

  result.defenderHp = target and getEntityHp(target) or 0
  return result
end

--- Sort a zone : touche toutes les entites dans le rayon. Chaque cible tremble.
function M.resolveSpellArea(caster, spell, centerX, centerY, entityManager, options)
  local hits = {}
  if not caster or not spell or not entityManager then return hits end

  local radius = tonumber(spell.radius) or 0
  if radius <= 0 then return hits end

  local skipMp = options and options.skipMpCost
  if not skipMp then
    local baseCost = spell.mpCost or 0
    local mpCost = getEffectiveMpCost(caster, baseCost)
    if getEntityMp(caster) < mpCost then return hits end
    if not consumeMp(caster, mpCost) then return hits end
  end

  local isHeal = (spell.damageType or "") == "heal"
  local damageType = ensureSpellDamageType(spell)
  local hasDamage = (spell.damageMin or spell.damageMax)
  if not hasDamage and not isHeal then return hits end

  local entities = entityManager:getEntities() or {}
  for _, entity in pairs(entities) do
    if entity == caster then goto continue end
    if entity.hp and entity.hp <= 0 then goto continue end
    local ex = entity.x or entity.gridX
    local ey = entity.y or entity.gridY
    if not ex or not ey then goto continue end
    local dist = math.max(math.abs(ex - centerX), math.abs(ey - centerY))
    if dist > radius then goto continue end

    local amount = 0
    if isHeal and (entity._character or not entityManager:isEnemy(caster, entity)) then
      amount = damage_calculator.rollMinMax(spell.damageMin or 0, spell.damageMax or 0)
      if amount > 0 then
        local statMod = damage_calculator.getStatModifier(caster, spell.statMag or "wisdom")
        amount = math.max(1, amount + statMod)
        setEntityHp(entity, getEntityHp(entity) + amount)
        table.insert(hits, { target = entity, healed = amount, damage = 0 })
      end
    elseif hasDamage and entityManager:isEnemy(caster, entity) then
      amount = damage_calculator.rollMinMax(spell.damageMin or 1, spell.damageMax or 1)
      if amount > 0 then
        local statMod = damage_calculator.getStatModifier(caster, spell.statMag or "intelligence")
        amount = amount + statMod
        amount = math.max(1, math.floor(amount))
        amount = damage_calculator.applyCrit(amount, damage_calculator.rollCrit(damage_calculator.computeCritChance(caster)))
        local resist = damage_calculator.applyResistance(amount, damageType, entity)
        if resist.damage > 0 then
          local dmg = math.max(1, math.floor(resist.damage))
          setEntityHp(entity, getEntityHp(entity) - dmg)
          if entity then entity.shakeFrames = 12 end
          table.insert(hits, { target = entity, damage = dmg, healed = 0 })
        end
      end
    end
    ::continue::
  end
  return hits
end

return M
