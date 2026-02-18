-- core/app.lua - Point central, orchestration
local M = {}

local config = require("core.config")
local fs = require("core.fs")
local log = require("core.log")
local i18n = require("core.i18n")
local input = require("core.input")
local scene_manager = require("core.scene_manager")
local router = require("core.router")

local platform = nil

function M.init(plat)
  platform = plat
  if not platform then
    log.error("app.init: no platform")
    return false
  end
  config.init()
  if platform.window_set_mode then
    local w = config.get("width") or 800
    local h = config.get("height") or 600
    local fullscreen = config.get("fullscreen") or false
    platform.window_set_mode(w, h, fullscreen)
  end
  if platform.audio_set_volume then
    local vol = (config.get("volume") or 100) / 100
    platform.audio_set_volume(vol)
  end
  i18n.set_fallback("en")
  i18n.load_locale("en")
  i18n.load_locale("fr")
  local loc = config.get("locale") or "en"
  i18n.set_locale(loc)
  input.init()
  router.init(scene_manager, platform)
  M._register_scenes()
  scene_manager.replace("main_menu")
  return true
end

function M._register_scenes()
  local main_menu = require("scenes.main_menu")
  local options = require("scenes.options")
  local credits = require("scenes.credits")
  local bindings = require("scenes.bindings")
  local hub_main = require("scenes.hub.hub_main")
  local hub_shop = require("scenes.hub.shop")
  local hub_tavern = require("scenes.hub.tavern")
  local hub_bank = require("scenes.hub.bank")
  local hub_house = require("scenes.hub.house")
  local hub_character = require("scenes.hub.character")
  local hub_stats = require("scenes.hub.stats")
  local hub_world = require("scenes.hub.world")
  local hub_inventory = require("scenes.hub.inventory")
  local hub_bank_deposit = require("scenes.hub.bank_deposit")
  local hub_bank_withdraw = require("scenes.hub.bank_withdraw")
  local log_scene = require("scenes.log_scene")
  local dungeon_run = require("scenes.dungeon_run")
  local dungeon_ground_loot = require("scenes.dungeon_ground_loot")
  local context_menu = require("scenes.ui.context_menu")
  local pause_menu = require("scenes.ui.pause_menu")
  scene_manager.register("main_menu", function() return main_menu.new() end)
  scene_manager.register("options", function() return options.new() end)
  scene_manager.register("credits", function() return credits.new() end)
  scene_manager.register("bindings", function() return bindings.new() end)
  scene_manager.register("hub_main", function() return hub_main.new() end)
  scene_manager.register("hub.shop", function() return hub_shop.new() end)
  scene_manager.register("hub.tavern", function() return hub_tavern.new() end)
  scene_manager.register("hub.bank", function() return hub_bank.new() end)
  scene_manager.register("hub.house", function() return hub_house.new() end)
  scene_manager.register("hub.character", function() return hub_character.new() end)
  scene_manager.register("hub.stats", function() return hub_stats.new() end)
  scene_manager.register("world", function() return hub_world.new() end)
  scene_manager.register("hub.inventory", function() return hub_inventory.new() end)
  scene_manager.register("hub.bank_deposit", function() return hub_bank_deposit.new() end)
  scene_manager.register("hub.bank_withdraw", function() return hub_bank_withdraw.new() end)
  scene_manager.register("log", function() return log_scene.new() end)
  scene_manager.register("dungeon_run", function() return dungeon_run.new() end)
  scene_manager.register("dungeon_ground_loot", function() return dungeon_ground_loot.new() end)
  scene_manager.register("ui_context_menu", function() return context_menu.new() end)
  scene_manager.register("ui_pause_menu", function() return pause_menu.new() end)
end

function M.update(dt)
  platform.input_poll()
  if input.consume("log") then
    local cur = scene_manager.current()
    if not cur or cur.id ~= "log" then
      scene_manager.push("log")
    end
  end
  scene_manager.update(dt)
  input.end_frame()
  if platform.mouse_end_frame then platform.mouse_end_frame() end
end

function M.draw()
  platform.gfx_clear()
  scene_manager.draw()
  platform.gfx_present()
end

return M
