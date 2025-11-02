--- Resvg module entry point (for submodule usage)
--- This file allows the library to be used as a standard Lua module when added as a git submodule
---
--- When this library is added as a submodule at lib/resvg/, you can use:
---   require("lib.resvg")           -- Loads this file
---   require("lib.resvg.lua.init")  -- Direct access to main implementation
---
--- This file sets up the module path and loads the actual implementation from lua/init.lua

-- Determine the base path of this module
local module_name = ...
local base_path = module_name:gsub("%.", "/") .. "/"

-- Update package.path to include the lua/ subdirectory
local lua_path = base_path .. "lua/"
package.path = package.path .. ";" .. lua_path .. "?.lua;" .. lua_path .. "?/init.lua"

-- Load the actual implementation from lua/init.lua
-- We need to construct the module path for lua/init.lua
local impl_module = module_name .. ".lua.init"
return require(impl_module)
