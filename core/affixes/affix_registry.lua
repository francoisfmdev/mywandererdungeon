-- core/affixes/affix_registry.lua - Registry et tirage aleatoire d'affixes
local M = {}

local _data = nil

local function load()
  if _data then return _data end
  local fs = require("core.fs")
  local path = "data/affixes.lua"
  if not fs.exists(path) then return {} end
  local ok, chunk = pcall(fs.read, path)
  if not ok or not chunk then return {} end
  local fn, err = loadstring(chunk)
  if not fn then return {} end
  local env = {}
  setmetatable(env, { __index = _G })
  setfenv(fn, env)
  local ok2, data = pcall(fn)
  _data = (ok2 and data) or {}
  return _data
end

function M.get(id)
  local d = load()
  return d[id]
end

function M.getAll()
  return load()
end

function M.rollAffixesForSlot(itemSlot, count)
  local all = load()
  if not all or count <= 0 then return {} end

  local function getCandidates()
    local out = {}
    for id, def in pairs(all) do
      if not def.bonuses then goto continue end
      def.id = def.id or id
      local allowed = def.allowedSlots
      if not allowed then
        table.insert(out, def)
      else
        for _, slot in ipairs(allowed) do
          if slot == itemSlot then
            table.insert(out, def)
            break
          end
        end
      end
      ::continue::
    end
    return out
  end

  local result = {}
  local usedIds = {}
  for _ = 1, count do
    local candidates = getCandidates()
    for i = #candidates, 1, -1 do
      if usedIds[candidates[i].id] then table.remove(candidates, i) end
    end
    if #candidates == 0 then break end

    local totalWeight = 0
    for _, c in ipairs(candidates) do totalWeight = totalWeight + (c.weight or 1) end
    if totalWeight <= 0 then break end

    local r = math.random() * totalWeight
    for _, c in ipairs(candidates) do
      r = r - (c.weight or 1)
      if r <= 0 then
        usedIds[c.id] = true
        table.insert(result, c)
        break
      end
    end
  end
  return result
end

local _cursed_data = nil
local function load_cursed()
  if _cursed_data then return _cursed_data end
  local fs = require("core.fs")
  local path = "data/cursed_affixes.lua"
  if not fs.exists(path) then return {} end
  local ok, chunk = pcall(fs.read, path)
  if not ok or not chunk then return {} end
  local fn, err = loadstring(chunk)
  if not fn then return {} end
  local env = {} setmetatable(env, { __index = _G }) setfenv(fn, env)
  local ok2, data = pcall(fn)
  _cursed_data = (ok2 and data) or {}
  return _cursed_data
end

function M.rollCursedAffix(slot)
  local all = load_cursed()
  if not all then return nil end
  local candidates = {}
  for id, def in pairs(all) do
    def.id = def.id or id
    table.insert(candidates, def)
  end
  if #candidates == 0 then return nil end
  local totalWeight = 0
  for _, c in ipairs(candidates) do totalWeight = totalWeight + (c.weight or 1) end
  if totalWeight <= 0 then return nil end
  local r = math.random() * totalWeight
  for _, c in ipairs(candidates) do
    r = r - (c.weight or 1)
    if r <= 0 then return c end
  end
  return candidates[#candidates]
end

return M
