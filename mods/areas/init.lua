-- Areas mod by ShadowNinja
-- Based on node_ownership
-- License: LGPLv2+

local version = "1.0"
local modname = minetest.get_current_modname()
minetest.log("action", "[" .. modname .. "] version " .. version .. " loaded.")

areas = {}

areas.adminPrivs = {areas=true}
areas.startTime = os.clock()

areas.modpath = minetest.get_modpath("areas")
dofile(areas.modpath.."/settings.lua")
dofile(areas.modpath.."/api.lua")
dofile(areas.modpath.."/internal.lua")
dofile(areas.modpath.."/chatcommands.lua")
dofile(areas.modpath.."/pos.lua")
dofile(areas.modpath.."/interact.lua")
dofile(areas.modpath.."/legacy.lua")
dofile(areas.modpath.."/hud.lua")

areas:load()

minetest.register_privilege("areas", {
	description = "Can administer areas."
})

minetest.register_privilege("areas_high_limit", {
	description = "Can can more, bigger areas."
})

if not minetest.registered_privileges[areas.config.self_protection_privilege] then
	minetest.register_privilege(areas.config.self_protection_privilege, {
		description = "Can protect areas.",
	})
end

if minetest.settings:get_bool("log_mod") then
	local diffTime = os.clock() - areas.startTime
	minetest.log("action", "areas loaded in "..diffTime.."s.")
end

minetest.register_on_joinplayer(function(player)
	local player_name = player:get_player_name()
	local privs = minetest.get_player_privs(player_name)
	local is_mapmaker = minetest.check_player_privs(player, "mapmaker")
	local is_teacher  = minetest.check_player_privs(player, "teacher")

	if is_mapmaker or is_teacher then
		privs.areas = true
		privs.areas_high_limit = true
		minetest.set_player_privs(player_name, privs)
	end
end)

