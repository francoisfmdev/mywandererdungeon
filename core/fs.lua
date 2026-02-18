-- core/fs.lua - Abstrait lecture fichiers (neutral platform)
local M = {}

local platform = require("platform.love")

function M.exists(path)
  return platform.fs_exists(path)
end

function M.read(path)
  return platform.fs_read(path)
end

function M.write(path, contents)
  return platform.fs_write(path, contents)
end

function M.get_config_path()
  return platform.fs_config_path()
end

return M
