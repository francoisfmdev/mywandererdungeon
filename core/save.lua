-- core/save.lua - Detection et ecriture sauvegarde
local M = {}
local config = require("core.config")

function M.has_save()
  return config.get("last_save") ~= nil
end

function M.save()
  config.set("last_save", os.time())
  config.save()
end

return M
