-- core/quest_service.lua - Logique metier quetes (extensible)
local M = {}

function M.get_quests()
  return {}
end

function M.get_rumors()
  return {}
end

function M.handle(action)
  if action == "quests" then return true end
  if action == "rumors" then return true end
  return false
end

return M
