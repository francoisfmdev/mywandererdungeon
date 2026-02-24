-- core/game/entity.lua - Factory entites joueur et monstres (combat-ready)
local M = {}

local EntityAdapter = require("core.combat.entity_adapter")
local EffectManager = require("core.effects.effect_manager")
local MonsterRegistry = require("core.entities.monster_registry")

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
  local resistances = def.resistances or {}

  local gx, gy = x or 0, y or 0
  local entity = {
    id = next_id(),
    monsterId = monsterId,
    isPlayer = false,
    isBoss = def.isBoss or false,
    nameKey = def.nameKey or ("entity." .. monsterId),
    hp = hp,
    maxHp = hp,
    resistances = resistances,
    x = gx,
    y = gy,
    gridX = gx,
    gridY = gy,
    spawnX = gx,
    spawnY = gy,
    _character = nil,
    aiState = "idle",
  }

  -- Monstres : precision via arme (hitBonus/critBonus), pas de stats
  entity.getEffectiveStat = function() return 0 end
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
