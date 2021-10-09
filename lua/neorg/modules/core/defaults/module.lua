--[[
-- DEFAULTS METAMODULE FOR NEORG
-- Houses all the default modules that an everday user may want for a nice user experience.
--]]

require("neorg.modules.base")

return neorg.modules.create_meta(
    "core.defaults",
    "core.neorgcmd",
    "core.keybinds",
    "core.mode",
    "core.norg.qol.todo_items",
    "core.norg.esupports",
    "core.norg.esupports.metagen",
    "core.norg.esupports.promo",
    "core.integrations.treesitter",
    "core.norg.manoeuvre"
)
