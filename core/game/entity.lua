-- core/game/entity.lua - Factory entites joueur et monstres (combat-ready)
local M = {}

local EntityAdapter = require("core.combat.entity_adapter")
local EffectManager = require("core.effects.effect_manager")
local MonsterRegistry = require("core.entities.monster_registry")
local WeaponRegistry = require("core.weapons.weapon_registry")

local _entity_id = 0
local function next_id()
  _entity_id = _entity_id + 1
  return "e_" .. _entity_id
end

function M.createPlayer(character)
  if not character then return nil end
  local entity = EntityAdapter.fromCharacter(character)
  if not entity then return nil end
  entity.id = next_id()
  entity.isPlayer = true
  entity._character = character
  entity.nameKey = "log.trap.you"
  entity.x = 0
  entity.y = 0
  entity.gridX = 0
  entity.gridY = 0
  return entity
end

function M.createMonster(monsterId, x, y)
  local def = MonsterRegistry.get(monsterId)
  if not def then return nil end

  local hp = def.hp or 10
  local stats = def.stats or {}
  local statList = { "strength", "dexterity", "constitution", "intelligence", "wisdom", "charisma" }
  for _, s in ipairs(statList) do
    if stats[s] == nil then stats[s] = 10 end
  end

  local weaponDef = nil
  if def.weapon then
    weaponDef = WeaponRegistry.get(def.weapon) or { damageMin = 1, damageMax = 4, damageType = "slashing", statUsed = "strength" }
  else
    weaponDef = { damageMin = 1, damageMax = 4, damageType = "slashing", statUsed = "strength" }
  end

  local resistances = def.resistances or {}

  local entity = {
    id = next_id(),
    monsterId = monsterId,
    isPlayer = false,
    nameKey = def.nameKey or ("entity." .. monsterId),
    hp = hp,
    maxHp = hp,
    mp = 0,
    maxMp = 0,
    stats = stats,
    resistances = resistances,
    weapon = weaponDef,
    x = x or 0,
    y = y or 0,
    gridX = x or 0,
    gridY = y or 0,
    _character = nil,
  }

  entity.getEffectiveStat = function(_, statName)
    return entity.stats[statName] or 0
  end
  entity.getEffectiveAC = function() return 10 end
  entity.getArmorValue = function() return 0 end
  entity.getEquipmentDefenseBonus = function() return 0 end
  entity.getEquipmentAttackBonus = function() return 0 end
  entity.getEffectiveResistances = function() return entity.resistances or {} end

  entity.effectManager = EffectManager.new(entity)
  return entity
end

function M.reset_id()
  _entity_id = 0
end

return M
