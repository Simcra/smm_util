---@diagnostic disable:undefined-global
local MOD_NAME = minetest.get_current_modname()
local MOD_PATH = minetest.get_modpath(MOD_NAME)

smm_util = {}
function smm_util.create_lookup_table(table)
    local lookup_table = {}
    for key, value in ipairs(table) do
        lookup_table[value] = key
    end
    return lookup_table
end

dofile(MOD_PATH .. "/network.lua")
