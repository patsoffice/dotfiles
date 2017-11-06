hs.logger.defaultLogLevel="info"

hyper = {"ctrl", "alt", "cmd"}
hypershift = {"ctrl", "alt", "cmd", "shift"}

hs.loadSpoon("SpoonInstall")

spoon.SpoonInstall.use_syncinstall = true

Install=spoon.SpoonInstall

-- http://www.hammerspoon.org/Spoons/WindowGrid.html
Install:andUse("WindowGrid",
               {
                  config = { gridGeometries = { { "8x4" } } },
                  hotkeys = {show_grid = {hyper, "g"}},
                  start = true
               }
)

-- http://www.hammerspoon.org/Spoons/ReloadConfiguration.html
Install:andUse("ReloadConfiguration",
               {
                    config = { watch_paths = { os.getenv("HOME") .. "/.hammerspoon/" } },
                    hotkeys = { reloadConfiguration = {hyper, "r" } },
                    start = true
               }
)

