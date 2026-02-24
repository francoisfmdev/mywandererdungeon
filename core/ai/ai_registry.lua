-- core/ai/ai_registry.lua - Charge les profils IA depuis data/ai/behaviors.lua
local M = {}

local _behaviors = nil

local function load()
  if _behaviors then return _behaviors end
  local fs = require("core.fs")
  local path = "data/ai/behaviors.lua"
  if not fs.exists(path) then return {} end
  local ok, chunk = pcall(fs.read, path)
  if not ok or not chunk then return {} end
  local fn, err = loadstring(chunk)
  if not fn then return {} end
  local env = {}
  setmetatable(env, { __index = _G })
  setfenv(fn, env)
  local ok2, data = pcall(fn)
  if not ok2 or type(data) ~= "table" then return {} end
  _behaviors = data
  return _behaviors
end

function M.get(profileId)
  local b = load()
  return b[profileId]
end

--- Fusionne profil + overrides inline. Retourne la config effective.
function M.getEffectiveConfig(monsterDef)
  if not monsterDef then return {} end
  local base = {}
  local profileId = monsterDef.aiProfile
  if profileId then
    local prof = M.get(profileId)
    if prof then
      for k, v in pairs(prof) do base[k] = v end
    end
  end
  -- Overrides inline (monsterDef.ai)
  local overrides = monsterDef.ai
  if type(overrides) == "table" then
    for k, v in pairs(overrides) do base[k] = v end
  end
  -- Legacy: detectionRadius au root du monstre
  if monsterDef.detectionRadius ~= nil then
    base.detectionRadius = monsterDef.detectionRadius
  end
  -- Valeurs par defaut
  base.detectionRadius = tonumber(base.detectionRadius) or 4
  base.attackRange = tonumber(base.attackRange) or 1
  base.fleeOnFear = base.fleeOnFear ~= false
  base.fleeOnLowHp = base.fleeOnLowHp == true
  base.hpFleeThreshold = tonumber(base.hpFleeThreshold) or 0.3
  base.chasePlayer = base.chasePlayer ~= false
  base.waitChance = tonumber(base.waitChance) or 0
  base.keepDistance = base.keepDistance == true
  base.idealRange = tonumber(base.idealRange) or 4
  base.idleBehavior = base.idleBehavior or "none"
  base.patrolRadius = tonumber(base.patrolRadius) or 3
  base.wanderChance = tonumber(base.wanderChance) or 0.5
  return base
end

return M
