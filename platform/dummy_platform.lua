-- platform/dummy_platform.lua - Stub pour exec sans Love2D
local M = {}

function M.fs_exists(path) return false end
function M.fs_read(path) return nil end
function M.fs_write(path, contents) return false end
function M.fs_config_path() return "config.lua" end
function M.log(msg) print(msg) end
function M.quit() os.exit(0) end
function M.window_set_mode(w, h, fs) end
function M.audio_set_volume(v) end
function M.set_raw_key_listener(fn) end
function M.mouse_get_position() return 0, 0 end
function M.mousepressed(x, y, btn) end
function M.mouse_peek_click(btn) return nil end
function M.mouse_consume_click(btn) return nil end
function M.mouse_end_frame() end
function M.gfx_clear() end
function M.gfx_present() end
function M.gfx_width() return 800 end
function M.gfx_height() return 600 end
function M.gfx_draw_text(t, x, y, c) end
function M.gfx_draw_rect(m, x, y, w, h, c) end
function M.gfx_load_image(path) return nil end
function M.gfx_draw_image(img, x, y, w, h) end
function M.gfx_get_font() return nil end
function M.input_register() end
function M.input_poll() end
function M.keypressed() end
function M.keyreleased() end

return M
