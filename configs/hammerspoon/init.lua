hs.logger.defaultLogLevel="info"

hyper = {"ctrl", "alt", "cmd"}
hypershift = {"ctrl", "alt", "cmd", "shift"}
cmdctrlshift = {"cmd", "ctrl", "shift"}

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

-- http://www.hammerspoon.org/Spoons/WindowHalfsAndThirds.html
Install:andUse("WindowHalfsAndThirds",
               {
                  config = {
                     use_frame_correctness = true
                  },
                  hotkeys = 'default'
               }
)

-- http://www.hammerspoon.org/Spoons/WindowScreenLeftAndRight.html
Install:andUse("WindowScreenLeftAndRight",
               {
                   hotkeys = {
                      screen_left = { cmdctrlshift, "Left" },
                      screen_right= { cmdctrlshift, "Right" },
                   }
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
