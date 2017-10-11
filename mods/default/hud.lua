local hud, timer = {}, {}
local timeout = 2

local function add_text(player)
	local player_name = player:get_player_name()
	hud[player_name] = player:hud_add({
		hud_elem_type = "text",
		position = {x = 0.5, y = 1},
		offset = {x = 0, y = -75},
		alignment = {x = 0, y = 0},
		number = 0xFFFFFF,
		text = "",
	})
end

minetest.register_on_joinplayer(function(player)
	minetest.after(0, add_text, player)

	local is_mapmaker = minetest.check_player_privs(player, "mapmaker")
	local is_teacher = minetest.check_player_privs(player, "teacher")

	if is_teacher or is_mapmaker then
		player:hud_set_hotbar_itemcount(16)
	end
end)

minetest.register_globalstep(function(dtime)
	local players = minetest.get_connected_players()
	for i = 1, #players do
		local player = players[i]
		local player_name = player:get_player_name()
		local wielded_item = player:get_wielded_item()
		local wielded_item_name = wielded_item:get_name()

		if timer[player_name] and timer[player_name] < timeout then
			timer[player_name] = timer[player_name] + dtime
			if timer[player_name] > timeout and hud[player_name] then
				player:hud_change(hud[player_name], "text", "")
			end
		end

		timer[player_name] = 0

		if hud[player_name] then
			local def = minetest.registered_items[wielded_item_name]
			local meta = wielded_item:get_meta()
			local meta_desc = meta:get_string("description")
			meta_desc = meta_desc:gsub("\27", ""):gsub("%(c@#%w%w%w%w%w%w%)", "")
			local description = meta_desc ~= "" and meta_desc or (def and def.description or "")

			player:hud_change(hud[player_name], "text", description)
		end
	end
end)
