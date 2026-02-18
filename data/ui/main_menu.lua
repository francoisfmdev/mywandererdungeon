-- data/ui/main_menu.lua - Menu principal data-driven
return {
  title_key = "ui.main_menu.title",
  items = {
    {
      i18n_key = "ui.main_menu.play",
      action = "game:start",
    },
    {
      i18n_key = "ui.main_menu.continue",
      action = "game:continue",
      visible = "has_save",
    },
    {
      i18n_key = "ui.main_menu.options",
      action = "scene:push:options",
    },
    {
      i18n_key = "ui.main_menu.credits",
      action = "scene:push:credits",
    },
    {
      i18n_key = "ui.main_menu.quit",
      action = "quit:",
    },
  },
}
