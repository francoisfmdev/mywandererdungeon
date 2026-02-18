-- core/character.lua - Systeme personnage roguelike, data-driven
local M = {}

local fs = require("core.fs")
local log = require("core.log")

local _config = nil
local _xp_table = nil

local function load_config()
  if _config then return _config end
  local path = "data/character_config.lua"
  if not fs.exists(path) then
    log.error("character: config not found", path)
    return nil
  end
  local ok, chunk = pcall(fs.read, path)
  if not ok or not chunk then return nil end
  local fn, err = loadstring(chunk)
  if not fn then
    log.error("character: config parse error", err)
    return nil
  end
  local env = {}
  setmetatable(env, { __index = _G })
  setfenv(fn, env)
  local ok2, data = pcall(fn)
  if ok2 and data then _config = data end
  return _config
end

local function load_xp_table()
  if _xp_table then return _xp_table end
  local path = "data/xp_table.lua"
  if not fs.exists(path) then return nil end
  local ok, chunk = pcall(fs.read, path)
  if not ok or not chunk then return nil end
  local fn, err = loadstring(chunk)
  if not fn then return nil end
  local env = {}
  setmetatable(env, { __index = _G })
  setfenv(fn, env)
  local ok2, data = pcall(fn)
  if ok2 and data then _xp_table = data end
  return _xp_table
end

local function init_stats(cfg)
  local stats = {}
  local list = cfg.stats or {}
  local initial = cfg.stats_initial or 1
  for _, name in ipairs(list) do
    stats[name] = initial
  end
  return stats
end

local function get_stat_modifier_divisor(cfg)
  return cfg.stat_modifier_divisor or 5
end

function M.new()
  local cfg = load_config()
  if not cfg then return nil end

  local self = {}
  local max_level = cfg.max_level or 100
  local stat_pts_per = cfg.stat_points_per_level or 1

  self._config = cfg
  self._xp = 0
  self._level = 1
  self._stat_points = 0
  self._stats = init_stats(cfg)
  self._hp = 0
  self._mp = 0

  local EquipmentManager = require("core.equipment.equipment_manager")
  self.equipmentManager = EquipmentManager.new(self)

  local effectEntity = {
    _character = self,
  }
  local function syncEffectEntityFromChar()
    effectEntity.hp = self:getHP()
    effectEntity.maxHp = self:getMaxHP()
    effectEntity.mp = self:getMP()
    effectEntity.maxMp = self:getMaxMP()
  end
  local function syncEffectEntityToChar()
    if effectEntity.hp ~= nil then self:setHP(effectEntity.hp) end
    if effectEntity.mp ~= nil then self:setMP(effectEntity.mp) end
  end
  self.effectManager = require("core.effects.effect_manager").new(effectEntity)
  self._syncEffectEntityFromChar = syncEffectEntityFromChar
  self._syncEffectEntityToChar = syncEffectEntityToChar

  local function getEquipmentBonuses()
    return self.equipmentManager:getBonuses()
  end

  function self:getEffectiveStats()
    local bonus = getEquipmentBonuses()
    local result = {}
    for k, v in pairs(self._stats) do
      result[k] = v + (bonus.stats[k] or 0)
    end
    for k, v in pairs(bonus.stats or {}) do
      if result[k] == nil then result[k] = v end
    end
    return result
  end

  function self:getEffectiveStat(statName)
    local eff = self:getEffectiveStats()
    return eff[statName] or 0
  end

  function self:getEffectiveResistances()
    local bonus = getEquipmentBonuses()
    return bonus.resistances or {}
  end

  function self:getEffectiveAC()
    local baseAC = 10
    local bonus = getEquipmentBonuses()
    return baseAC + (bonus.ac or 0)
  end

  function self:getArmorValue()
    local bonus = getEquipmentBonuses()
    return 0
  end

  function self:getEquipmentDefenseBonus()
    local bonus = getEquipmentBonuses()
    return (bonus.ac or 0) + (bonus.defenseBonus or 0)
  end

  function self:getEquipmentAttackBonus()
    local bonus = getEquipmentBonuses()
    return bonus.attackBonus or 0
  end

  local function apply_level_up()
    self._stat_points = self._stat_points + stat_pts_per
  end

  function self:addXP(amount)
    if not amount or amount < 0 then return end
    self._xp = self._xp + amount
    local xt = load_xp_table()
    if not xt then return end
    while self._level < max_level do
      local needed = xt[self._level + 1]
      if needed == nil or self._xp < needed then break end
      self._level = self._level + 1
      apply_level_up()
    end
  end

  function self:levelUp()
    if self._level >= max_level then return false end
    self._level = self._level + 1
    apply_level_up()
    return true
  end

  function self:addStatPoint(statName)
    if not statName or self._stat_points < 1 then return false end
    local cfg = self._config
    if not cfg.stats then return false end
    for _, s in ipairs(cfg.stats) do
      if s == statName then
        self._stats[statName] = (self._stats[statName] or 0) + 1
        self._stat_points = self._stat_points - 1
        return true
      end
    end
    return false
  end

  function self:getStatModifier(statName)
    if not statName then return 0 end
    local val = self._stats[statName]
    if val == nil then return 0 end
    local div = get_stat_modifier_divisor(self._config)
    return math.floor(val / div)
  end

  function self:getStat(statName)
    return self._stats[statName] or 0
  end

  function self:getMaxHP()
    local cfg = self._config
    local con = self:getEffectiveStat("constitution")
    local base = (cfg.baseHP or 0)
      + con * (cfg.hpPerCon or 0)
      + self._level * (cfg.hpPerLevel or 0)
    local bonus = getEquipmentBonuses()
    return base + (bonus.bonusMaxHp or 0)
  end

  function self:getMaxMP()
    local cfg = self._config
    local int = self:getEffectiveStat("intelligence")
    local div = cfg.mpPerLevelDiv or 3
    local base = (cfg.baseMP or 0)
      + int * (cfg.mpPerInt or 0)
      + math.floor((self._level - 1) / div)
    local bonus = getEquipmentBonuses()
    return base + (bonus.bonusMaxMp or 0)
  end

  function self:getXP()
    return self._xp
  end

  function self:getLevel()
    return self._level
  end

  function self:getStatPoints()
    return self._stat_points
  end

  function self:getHP()
    return self._hp
  end

  function self:setHP(v)
    self._hp = math.max(0, math.min(v, self:getMaxHP()))
  end

  function self:getMP()
    return self._mp
  end

  function self:setMP(v)
    self._mp = math.max(0, math.min(v, self:getMaxMP()))
  end

  function self:xpToNextLevel()
    if self._level >= max_level then return nil end
    local xt = load_xp_table()
    if not xt then return nil end
    local needed = xt[self._level + 1]
    if needed == nil then return nil end
    return math.max(0, needed - self._xp)
  end

  function self:reset()
    self._hp = self:getMaxHP()
    self._mp = self:getMaxMP()
  end

  function self:resetToLevel1()
    self._level = 1
    self._xp = 0
    self._stat_points = 0
    self._stats = init_stats(self._config)
    local slots = require("core.equipment.equipment_slots")
    for _, slot in ipairs(slots.SLOTS) do
      self.equipmentManager:unequip(slot)
    end
    self:reset()
  end

  self:reset()
  syncEffectEntityFromChar()
  return self
end

function M.toSaveData(char)
  if not char then return nil end
  return {
    level = char:getLevel(),
    xp = char:getXP(),
    stat_points = char:getStatPoints(),
    stats = char._stats and (function()
      local t = {}
      for k, v in pairs(char._stats) do t[k] = v end
      return t
    end)(),
    hp = char:getHP(),
    mp = char:getMP(),
    equipment = char.equipmentManager and char.equipmentManager:toSaveData(),
  }
end

function M.fromSaveData(data)
  if not data then return nil end
  local char = M.new()
  if not char then return nil end
  if data.level then char._level = data.level end
  if data.xp then char._xp = data.xp end
  if data.stat_points then char._stat_points = data.stat_points end
  if data.stats and type(data.stats) == "table" then
    for k, v in pairs(data.stats) do char._stats[k] = v end
  end
  if data.equipment and char.equipmentManager then
    char.equipmentManager:fromSaveData(data.equipment)
  end
  char:reset()
  if data.hp then char:setHP(data.hp) end
  if data.mp then char:setMP(data.mp) end
  if char._syncEffectEntityFromChar then char:_syncEffectEntityFromChar() end
  return char
end

M.isNaturalOne = function(roll)
  return roll == 1
end

return M
