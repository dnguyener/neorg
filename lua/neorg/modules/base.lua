--[[
--	BASE FILE FOR MODULES
--	This file contains the base module implementation
--]]

neorg.modules = {}

neorg.modules.module_base = {

    -- Invoked before any initial loading happens
    setup = function()
        return { success = true, requires = {}, replaces = nil, replace_merge = false }
    end,

    -- Invoked after the module has been configured
    load = function() end,

    -- Invoked whenever an event that the module has subscribed to triggers
    on_event = function(event) end,

    -- Invoked after all plugins are loaded
    neorg_post_load = function() end,

    -- The name of the module, note that modules beginning with core are neorg's inbuilt modules
    name = "core.default",

    -- A convenience table to place all of your private variables that you don't want to expose here.
    private = {},

    -- Every module can expose any set of information it sees fit through the public field
    -- All functions and variables declared in this table will be visible to any other module loaded
    public = {

        version = "0.0.1", -- A good practice is to expose version information
    },

    -- Configuration for the module
    config = {

        private = { -- Private module configuration, cannot be changed by other modules or by the user
            --[[
				config_option = false,
				["option_group"] = {
					sub_option = true
				}
			--]]
        },

        public = { -- Public config, can be changed by modules and the user
            --[[
				config_option = false,
				["option_group"] = {
					sub_option = true
				}
			--]]
        },
    },

    -- Event data regarding the current module
    events = {
        subscribed = { -- The events that the module is subscribed to

            --[[
				EXAMPLE DEFINITION:
				[ "core.test" ] = { -- The name of the module that has events bound to it
					[ "test_event" ] = true, -- Subscribes to event core.test.events.test_event
					[ "other_event" ] = true -- Subscribes to event core.test.events.other_event
				}
			--]]
        },
        defined = { -- The events that the module itself has defined

            --[[
				EXAMPLE DEFINITION:
				["my_event"] = { event_data } -- Creates an event of type category.module.events.my_event
			--]]
        },
    },

    -- If you ever require a module through the return value of the setup() function,
    -- All of the modules' public APIs will become available here
    required = {

        --[[

			["core.test"] = {
				-- Their public API here...
			},

			["core.some_other_plugin"] = {
				-- Their public API here...
			}

		--]]
    },
}

-- @Summary Creates a new module
-- @Description Returns a module that derives from neorg.modules.module_base, exposing all the necessary function and variables
-- @Param  name (string) - the name of the new module. Make sure this is unique. The recommended naming convention is category.module_name or category.subcategory.module_name
function neorg.modules.create(name)
    local new_module = vim.deepcopy(neorg.modules.module_base)

    if name then
        new_module.name = name
    end

    neorg.modules.cache[new_module.name] = new_module

    return neorg.modules.cache[new_module.name]
end

--- Extends a module and returns a temporary copy
--- @param name string #The name of the module to extend
--- @return table #A copy of the module
function neorg.modules.extend(name)
    local from_cache = neorg.modules.cache[name] or neorg.modules.create(name)

    local t = {
        merge = function()
            return from_cache
        end,
    }

    return setmetatable(t, {
        __newindex = function(_, key, value)
            neorg.modules.cache[name][key] = vim.tbl_deep_extend("force", from_cache[key] or {}, value)
        end,
        __index = from_cache,
    })
end

--- Imports a new module by merging the original module table
--- @param module table #The module to import new files into
--- @param imports string[] #A list of files to import (relative to the `module.lua` file)
--- @return table #The newly extended module
function neorg.modules.import(module, imports)
    local cache = neorg.modules.cache[module.name]

    for _, file in ipairs(imports or {}) do
        cache = vim.tbl_deep_extend("force", cache, require("neorg.modules." .. module.name .. "." .. file))
    end

    return cache
end

-- @Summary Creates a metamodule
-- @Description Constructs a metamodule from a list of submodules. Metamodules are modules that can autoload batches of modules at once.
-- @Param  name (string) - the name of the new metamodule. Make sure this is unique. The recommended naming convention is category.module_name or category.subcategory.module_name
-- @Param  ... (varargs) - a list of module names to load.
function neorg.modules.create_meta(name, ...)
    local module = neorg.modules.create(name)

    require("neorg.modules")

    module.config.public.enable = { ... }

    module.setup = function()
        return { success = true }
    end

    module.load = function()
        module.config.public.enable = (function()
            -- If we haven't define any modules to disable then just return all enabled modules
            if not module.config.public.disable then
                return module.config.public.enable
            end

            local ret = {}

            -- For every enabled module
            for _, mod in ipairs(module.config.public.enable) do
                -- If that module does not exist in the disable table (ie. it is enabled) then add it to the `ret` table
                if not vim.tbl_contains(module.config.public.disable, mod) then
                    table.insert(ret, mod)
                end
            end

            -- Return the table containing all the modules we would like to enable
            return ret
        end)()

        -- Go through every module that we have defined in the metamodule and load it!
        for _, mod in ipairs(module.config.public.enable) do
            neorg.modules.load_module(mod)
        end
    end

    return module
end
