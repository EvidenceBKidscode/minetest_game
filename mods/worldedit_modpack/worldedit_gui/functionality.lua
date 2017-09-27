--saved state for each player
local gui_nodename1 = {} --mapping of player names to node names
local gui_nodename2 = {} --mapping of player names to node names
local gui_axis1 = {} --mapping of player names to axes (one of 1, 2, 3, or 4, representing the axes in the `axis_indices` table below)
local gui_axis2 = {} --mapping of player names to axes (one of 1, 2, 3, or 4, representing the axes in the `axis_indices` table below)
local gui_distance1 = {} --mapping of player names to a distance (arbitrary strings may also appear as values)
local gui_distance2 = {} --mapping of player names to a distance (arbitrary strings may also appear as values)
local gui_distance3 = {} --mapping of player names to a distance (arbitrary strings may also appear as values)
local gui_count1 = {} --mapping of player names to a quantity (arbitrary strings may also appear as values)
local gui_count2 = {} --mapping of player names to a quantity (arbitrary strings may also appear as values)
local gui_count3 = {} --mapping of player names to a quantity (arbitrary strings may also appear as values)
local gui_angle = {} --mapping of player names to an angle (one of 90, 180, 270, representing the angle in degrees clockwise)
local gui_filename = {} --mapping of player names to file names

--set default values
setmetatable(gui_nodename1, {__index = function() return "" end})
setmetatable(gui_nodename2, {__index = function() return "" end})
setmetatable(gui_axis1,     {__index = function() return 4 end})
setmetatable(gui_axis2,     {__index = function() return 1 end})
setmetatable(gui_distance1, {__index = function() return "10" end})
setmetatable(gui_distance2, {__index = function() return "5" end})
setmetatable(gui_distance3, {__index = function() return "2" end})
setmetatable(gui_count1,     {__index = function() return "3" end})
setmetatable(gui_count2,     {__index = function() return "6" end})
setmetatable(gui_count3,     {__index = function() return "4" end})
setmetatable(gui_angle,     {__index = function() return 90 end})
setmetatable(gui_filename,  {__index = function() return "building" end})

worldedit.axis_indices = {["X axis"]=1, ["Y axis"]=2, ["Z axis"]=3, ["Look direction"]=4}
worldedit.axis_values = {"x", "y", "z", "?"}
setmetatable(worldedit.axis_indices, {__index = function () return 4 end})
setmetatable(worldedit.axis_values, {__index = function () return "?" end})

local axis_indices = worldedit.axis_indices
local axis_values = worldedit.axis_values

worldedit.angle_indices = {["90 degrees"]=1, ["180 degrees"]=2, ["270 degrees"]=3}
worldedit.angle_values = {90, 180, 270}
setmetatable(worldedit.angle_indices, {__index = function () return 1 end})
setmetatable(worldedit.angle_values, {__index = function () return 90 end})

local angle_indices = worldedit.angle_indices
local angle_values = worldedit.angle_values

-- given multiple sets of privileges, produces a single set of privs that would have the same effect as requiring all of them at the same time
local combine_privs = function(...)
	local result = {}
	for i, privs in ipairs({...}) do
		for name, value in pairs(privs) do
			if result[name] ~= nil and result[name] ~= value then --the priv must be both true and false, which can never happen
				return {__fake_priv_that_nobody_has__=true} --privilege table that can never be satisfied
			end
			result[name] = value
		end
	end
	return result
end

-- display node (or unknown_node image otherwise) at specified pos in formspec
local formspec_node = function(pos, nodename)
	return nodename and string.format("item_image[%s;1,1;%s]", pos, nodename)
		or string.format("image[%s;1,1;worldedit_gui_unknown.png]", pos)
end

-- two further priv helpers
local function we_privs(command)
	return minetest.chatcommands["/" .. command].privs
end

local function combine_we_privs(list)
	local args = {}
	for _, t in ipairs(list) do
		table.insert(args, we_privs(t))
	end
	return combine_privs(unpack(args))
end

local function get_items_list(filter, pagenum, player_name, identifier)
	local item_list = {}
	for name, def in pairs(minetest.registered_nodes) do
		if not (def.groups.not_in_creative_inventory == 1) and
				def.description and def.description ~= "" and
				(def.name:find(filter, 1, true) or
					def.description:lower():find(filter, 1, true)) then
			item_list[#item_list + 1] = name
		end
	end

	worldedit.items[player_name].inv_size = #item_list
	table.sort(item_list)

	local width, height = 8, 3
	local ipp, str = width * height, ""
	local first_item = (pagenum - 1) * ipp
	worldedit.items[player_name].pagemax = math.ceil(#item_list / ipp)

	for i = first_item, first_item + ipp - 1 do
		local name = item_list[i + 1]
		if not name then break end
		local X = i % width
		local Y = (i % ipp - X) / width + 1

		str = str .. "item_image_button[" ..
			(X) .. "," ..
			(Y - 0.2) .. ";1,1;" ..
			name .. ";worldedit_gui_" .. identifier .. "_" .. name .. "_inv;]"
	end

	return str
end

worldedit.register_gui_function("worldedit_gui_about", {
	type = "advanced",
	name = "About",
	privs = {interact=true},
	on_select = function(name)
		minetest.chatcommands["/about"].func(name, "")
	end,
})

worldedit.register_gui_function("worldedit_gui_inspect", {
	type = "advanced",
	name = "Toggle Inspect",
	privs = we_privs("inspect"),
	on_select = function(name)
		minetest.chatcommands["/inspect"].func(name, worldedit.inspect[name] and "disable" or "enable")
	end,
})

worldedit.register_gui_function("worldedit_gui_region", {
	type = "advanced",
	name = "Get / Set Region",
	privs = combine_we_privs({"p", "pos1", "pos2", "reset", "mark", "unmark", "volume", "fixedpos"}),
	get_formspec = function(name)
		local pos1, pos2 = worldedit.pos1[name], worldedit.pos2[name]
		return "size[9,7]" .. worldedit.get_formspec_header("worldedit_gui_region") ..
			"button_exit[0,1;3,0.8;worldedit_gui_p_get;Get Positions]" ..
			"button_exit[3,1;3,0.8;worldedit_gui_p_set1;Choose Position 1]" ..
			"button_exit[6,1;3,0.8;worldedit_gui_p_set2;Choose Position 2]" ..
			"button_exit[0,2;3,0.8;worldedit_gui_pos1;Position 1 Here]" ..
			"button_exit[3,2;3,0.8;worldedit_gui_pos2;Position 2 Here]" ..
			"button_exit[6,2;3,0.8;worldedit_gui_reset;Reset Region]" ..
			"button_exit[0,3;3,0.8;worldedit_gui_mark;Mark Region]" ..
			"button_exit[3,3;3,0.8;worldedit_gui_unmark;Unmark Region]" ..
			"button_exit[6,3;3,0.8;worldedit_gui_volume;Region Volume]" ..
			"label[0,4.7;Position 1]" ..
			string.format("field[2,5;1.5,0.8;worldedit_gui_fixedpos_pos1x;X ;%s]", pos1 and pos1.x or "") ..
			string.format("field[3.5,5;1.5,0.8;worldedit_gui_fixedpos_pos1y;Y ;%s]", pos1 and pos1.y or "") ..
			string.format("field[5,5;1.5,0.8;worldedit_gui_fixedpos_pos1z;Z ;%s]", pos1 and pos1.z or "") ..
			"button_exit[6.5,4.68;2.5,0.8;worldedit_gui_fixedpos_pos1_submit;Set Position 1]" ..
			"label[0,6.2;Position 2]" ..
			string.format("field[2,6.5;1.5,0.8;worldedit_gui_fixedpos_pos2x;X ;%s]", pos2 and pos2.x or "") ..
			string.format("field[3.5,6.5;1.5,0.8;worldedit_gui_fixedpos_pos2y;Y ;%s]", pos2 and pos2.y or "") ..
			string.format("field[5,6.5;1.5,0.8;worldedit_gui_fixedpos_pos2z;Z ;%s]", pos2 and pos2.z or "") ..
			"button_exit[6.5,6.18;2.5,0.8;worldedit_gui_fixedpos_pos2_submit;Set Position 2]"
	end,
})

worldedit.register_gui_handler("worldedit_gui_region", function(name, fields)
	if fields.worldedit_gui_p_get then
		minetest.chatcommands["/p"].func(name, "get")
		return true
	elseif fields.worldedit_gui_p_set1 then
		minetest.chatcommands["/p"].func(name, "set1")
		return true
	elseif fields.worldedit_gui_p_set2 then
		minetest.chatcommands["/p"].func(name, "set2")
		return true
	elseif fields.worldedit_gui_pos1 then
		minetest.chatcommands["/pos1"].func(name, "")
		worldedit.show_page(name, "worldedit_gui_region")
		return true
	elseif fields.worldedit_gui_pos2 then
		minetest.chatcommands["/pos2"].func(name, "")
		worldedit.show_page(name, "worldedit_gui_region")
		return true
	elseif fields.worldedit_gui_reset then
		minetest.chatcommands["/reset"].func(name, "")
		worldedit.show_page(name, "worldedit_gui_region")
		return true
	elseif fields.worldedit_gui_mark then
		minetest.chatcommands["/mark"].func(name, "")
		worldedit.show_page(name, "worldedit_gui_region")
		return true
	elseif fields.worldedit_gui_unmark then
		minetest.chatcommands["/unmark"].func(name, "")
		worldedit.show_page(name, "worldedit_gui_region")
		return true
	elseif fields.worldedit_gui_volume then
		minetest.chatcommands["/volume"].func(name, "")
		worldedit.show_page(name, "worldedit_gui_region")
		return true
	elseif fields.worldedit_gui_fixedpos_pos1_submit then
		minetest.chatcommands["/fixedpos"].func(name, string.format("set1 %s %s %s",
			tostring(fields.worldedit_gui_fixedpos_pos1x),
			tostring(fields.worldedit_gui_fixedpos_pos1y),
			tostring(fields.worldedit_gui_fixedpos_pos1z)))
		worldedit.show_page(name, "worldedit_gui_region")
		return true
	elseif fields.worldedit_gui_fixedpos_pos2_submit then
		minetest.chatcommands["/fixedpos"].func(name, string.format("set2 %s %s %s",
			tostring(fields.worldedit_gui_fixedpos_pos2x),
			tostring(fields.worldedit_gui_fixedpos_pos2y),
			tostring(fields.worldedit_gui_fixedpos_pos2z)))
		worldedit.show_page(name, "worldedit_gui_region")
		return true
	end
	return false
end)

worldedit.register_gui_function("worldedit_gui_set", {
	type = "advanced",
	name = "Set Nodes",
	privs = we_privs("set"),
	get_formspec = function(name)
		local node = gui_nodename1[name]
		local nodename = worldedit.normalize_nodename(node)
		local pagenum = worldedit.items[name].pagenum or 1
		local filter = worldedit.items[name].filter or ""
		local items_list = get_items_list(filter, pagenum, name, "set")
		local pagemax = worldedit.items[name].pagemax or 1
		
		return "size[8,6]" .. worldedit.get_formspec_header("worldedit_gui_set") ..
			string.format("field[0.3,4.6;3,0.8;worldedit_gui_set_filter;Filter;%s]",
				minetest.formspec_escape(filter)) ..
			string.format("field[0.3,5.82;3,0.8;worldedit_gui_set_node;Name;%s]",
				minetest.formspec_escape(node)) ..
			"button[3,4.28;0.8,0.8;worldedit_gui_set_search;?]" ..
			"button[3.7,4.28;0.8,0.8;worldedit_gui_set_search_clear;X]" ..
			items_list ..
			"field_close_on_enter[worldedit_gui_set_filter;false]" ..
			"button[5.5,4.18;0.8,1;worldedit_gui_set_items_prev;<]" ..
			"label[6.2,4.38;" ..
				minetest.colorize("#FFFF00", pagenum) .. " / " .. pagemax .. "]" ..
			"button[7.2,4.18;0.8,1;worldedit_gui_set_items_next;>]" ..
			"button_exit[3,5.5;3,0.8;worldedit_gui_set_submit;Set Nodes]"
	end,
})

worldedit.register_gui_handler("worldedit_gui_set", function(name, fields)
	for field in pairs(fields) do
		if field:find("worldedit_gui_set_[%w_]+:[%w_]+_inv") then
			local item = field:match("worldedit_gui_set_([%w_]+:[%w_]+)_inv")
			gui_nodename1[name] = item
			worldedit.show_page(name, "worldedit_gui_set")
			return true
		end
	end

	if fields.worldedit_gui_set_search or
	   fields.key_enter_field == "worldedit_gui_set_node" then
		worldedit.items[name].pagenum = 1
		worldedit.show_page(name, "worldedit_gui_set")
		return true

	elseif fields.worldedit_gui_set_search or
	       fields.worldedit_gui_set_submit or
	       fields.worldedit_gui_set_node   or
	       fields.worldedit_gui_set_search_clear then
	   	local pagenum = worldedit.items[name].pagenum or 1
		local pagemax = worldedit.items[name].pagemax or 1

		if fields.worldedit_gui_set_items_next then
			worldedit.items[name].pagenum = pagenum + 1
			if worldedit.items[name].pagenum > pagemax then
				worldedit.items[name].pagenum = 1
			end
		elseif fields.worldedit_gui_set_items_prev then
			worldedit.items[name].pagenum = pagenum - 1
			if worldedit.items[name].pagenum <= 0 then
				worldedit.items[name].pagenum = pagemax
			end
		end

		gui_nodename1[name] = tostring(fields.worldedit_gui_set_node)
		worldedit.items[name].filter = fields.worldedit_gui_set_search_clear and "" or
					       fields.worldedit_gui_set_filter
		worldedit.show_page(name, "worldedit_gui_set")

		if fields.worldedit_gui_set_submit then
			local n = worldedit.normalize_nodename(gui_nodename1[name])
			if n then
				minetest.chatcommands["/set"].func(name, n)
			end
		end

		return true
	end

	return false
end)

worldedit.register_gui_function("worldedit_gui_replace", {
	type = "default",
	name = "Replace Nodes",
	privs = combine_we_privs({"replace", "replaceinverse"}),
	get_formspec = function(name)
		local search, replace = gui_nodename1[name], gui_nodename2[name]
		local search_nodename, replace_nodename =
			worldedit.normalize_nodename(search), worldedit.normalize_nodename(replace)
		local pagenum = worldedit.items[name].pagenum or 1
		local filter = worldedit.items[name].filter or ""
		local items_list = get_items_list(filter, pagenum, name, "replace")
		local pagemax = worldedit.items[name].pagemax or 1

		return "size[8,7]" .. worldedit.get_formspec_header("worldedit_gui_replace") ..
			items_list ..
			string.format("field[0.3,4.5;3,0.8;worldedit_gui_replace_filter;Filter;%s]",
				minetest.formspec_escape(filter)) ..
			string.format("field[0.3,5.8;4,0.8;worldedit_gui_replace_node;Replace;%s]",
				minetest.formspec_escape(search)) ..
			"button[2.9,4.18;0.8,0.8;worldedit_gui_replace_search;?]" ..
			"button[3.6,4.18;0.8,0.8;worldedit_gui_replace_search_clear;X]" ..
			"button[5.5,4.08;0.8,1;worldedit_gui_replace_prev;<]" ..
			"label[6.2,4.28;" ..
				minetest.colorize("#FFFF00", pagenum) .. " / " .. pagemax .. "]" ..
			"button[7.2,4.08;0.8,1;worldedit_gui_replace_next;>]" ..
			string.format("field[4.3,5.8;4,0.8;worldedit_gui_replace_replace;By;%s]",
				minetest.formspec_escape(replace)) ..
			"field_close_on_enter[worldedit_gui_replace_filter;false]" ..
			"button_exit[1,6.5;3,0.8;worldedit_gui_replace_submit;Replace Nodes]" ..
			"button_exit[4,6.5;3,0.8;worldedit_gui_replace_submit_inverse;Replace Inverse]"
	end,
})

local replace_last = {}

worldedit.register_gui_handler("worldedit_gui_replace", function(name, fields)
	for field in pairs(fields) do
		if field:find("worldedit_gui_replace_[%w_]+:[%w_]+_inv") then
			local item = field:match("worldedit_gui_replace_([%w_]+:[%w_]+)_inv")

			replace_last[name] = replace_last[name] or ""
			if replace_last[name] == "" or replace_last[name] == 2 then
				replace_last[name] = 1
				gui_nodename1[name] = item
			elseif replace_last[name] == 1 then
				replace_last[name] = 2
				gui_nodename2[name] = item
			end

			worldedit.show_page(name, "worldedit_gui_replace")
			return true
		end
	end

	if fields.worldedit_gui_replace_search or
	   fields.key_enter_field == "worldedit_gui_replace_filter" then
		worldedit.items[name].pagenum = 1
		worldedit.items[name].filter = fields.worldedit_gui_replace_filter
		worldedit.show_page(name, "worldedit_gui_replace")
		return true

	elseif fields.worldedit_gui_replace_submit         or
	       fields.worldedit_gui_replace_submit_inverse or
	       fields.worldedit_gui_replace_search_clear   or
	       fields.worldedit_gui_replace_next           or
	       fields.worldedit_gui_replace_prev           then
		local pagenum = worldedit.items[name].pagenum or 1
		local pagemax = worldedit.items[name].pagemax or 1

		if fields.worldedit_gui_replace_search_clear then
			worldedit.items[name].pagenum = 1
		end

		if fields.worldedit_gui_replace_next then
			worldedit.items[name].pagenum = pagenum + 1
			if worldedit.items[name].pagenum > pagemax then
				worldedit.items[name].pagenum = 1
			end
		elseif fields.worldedit_gui_replace_prev then
			worldedit.items[name].pagenum = pagenum - 1
			if worldedit.items[name].pagenum <= 0 then
				worldedit.items[name].pagenum = pagemax
			end
		end

		gui_nodename1[name] = tostring(fields.worldedit_gui_replace_node)
		worldedit.items[name].filter = fields.worldedit_gui_replace_search_clear and "" or
					       fields.worldedit_gui_replace_filter
		gui_nodename2[name] = tostring(fields.worldedit_gui_replace_replace)
		worldedit.show_page(name, "worldedit_gui_replace")

		local submit
		if fields.worldedit_gui_replace_submit then
			submit = "replace"
		elseif fields.worldedit_gui_replace_submit_inverse then
			submit = "replaceinverse"
		end

		if submit then
			local n1 = worldedit.normalize_nodename(gui_nodename1[name])
			local n2 = worldedit.normalize_nodename(gui_nodename2[name])
			if n1 and n2 then
				minetest.chatcommands["/"..submit].func(name, string.format("%s %s", n1, n2))
			end
		end

		return true
	end

	return false
end)

worldedit.register_gui_function("worldedit_gui_sphere_dome", {
	type = "advanced",
	name = "Sphere / Dome",
	form = true,
	privs = combine_we_privs({"hollowsphere", "sphere", "hollowdome", "dome"}),
	get_formspec = function(name)
		local node, radius = gui_nodename1[name], gui_distance2[name]
		local nodename = worldedit.normalize_nodename(node)
		local pagenum = worldedit.items[name].pagenum or 1
		local filter = worldedit.items[name].filter or ""
		local items_list = get_items_list(filter, pagenum, name, "sphere_dome")
		local pagemax = worldedit.items[name].pagemax or 1

		return "size[8,8]" .. worldedit.get_formspec_header("worldedit_gui_sphere_dome") ..
			string.format("field[0.3,4.5;3,0.8;worldedit_gui_sphere_dome_filter;Filter;%s]",
				minetest.formspec_escape(filter)) ..
			items_list ..
			"button[2.9,4.18;0.8,0.8;worldedit_gui_sphere_dome_search;?]" ..
			"button[3.6,4.18;0.8,0.8;worldedit_gui_sphere_dome_search_clear;X]" ..
			"button[5.5,4.08;0.8,1;worldedit_gui_sphere_dome_prev;<]" ..
			"label[6.2,4.28;" ..
				minetest.colorize("#FFFF00", pagenum) .. " / " .. pagemax .. "]" ..
			"button[7.2,4.08;0.8,1;worldedit_gui_sphere_dome_next;>]" ..
			string.format("field[0.3,5.7;3,0.8;worldedit_gui_sphere_dome_node;Name;%s]",
				minetest.formspec_escape(node)) ..
			string.format("field[3.2,5.7;2,0.8;worldedit_gui_sphere_dome_radius;Radius;%s]",
				minetest.formspec_escape(radius)) ..
			"field_close_on_enter[worldedit_gui_sphere_dome_filter;false]" ..
			"button_exit[0.7,6.5;3,0.8;worldedit_gui_sphere_dome_submit_hollow;Hollow Sphere]" ..
			"button_exit[4.2,6.5;3,0.8;worldedit_gui_sphere_dome_submit_solid;Solid Sphere]" ..
			"button_exit[0.7,7.5;3,0.8;worldedit_gui_sphere_dome_submit_hollow_dome;Hollow Dome]" ..
			"button_exit[4.2,7.5;3,0.8;worldedit_gui_sphere_dome_submit_solid_dome;Solid Dome]"
	end,
})

worldedit.register_gui_handler("worldedit_gui_sphere_dome", function(name, fields)
	for field in pairs(fields) do
		if field:find("worldedit_gui_sphere_dome_[%w_]+:[%w_]+_inv") then
			local item = field:match("worldedit_gui_sphere_dome_([%w_]+:[%w_]+)_inv")
			gui_nodename1[name] = item
			worldedit.show_page(name, "worldedit_gui_sphere_dome")
			return true
		end
	end

	if fields.worldedit_gui_sphere_dome_search or
	   fields.key_enter_field == "worldedit_gui_sphere_dome_filter" then
		worldedit.items[name].pagenum = 1
		worldedit.items[name].filter = fields.worldedit_gui_sphere_dome_filter
		worldedit.show_page(name, "worldedit_gui_sphere_dome")
		return true

	elseif fields.worldedit_gui_sphere_dome_search             or
	       fields.worldedit_gui_sphere_dome_submit_hollow      or
	       fields.worldedit_gui_sphere_dome_submit_solid       or
	       fields.worldedit_gui_sphere_dome_submit_hollow_dome or
	       fields.worldedit_gui_sphere_dome_submit_solid_dome  or
	       fields.worldedit_gui_sphere_dome_search_clear       or
	       fields.worldedit_gui_sphere_dome_next               or
	       fields.worldedit_gui_sphere_dome_prev               then
	   	local pagenum = worldedit.items[name].pagenum or 1
		local pagemax = worldedit.items[name].pagemax or 1

		if fields.worldedit_gui_sphere_dome_search_clear then
			worldedit.items[name].pagenum = 1
		end

		if fields.worldedit_gui_sphere_dome_next then
			worldedit.items[name].pagenum = pagenum + 1
			if worldedit.items[name].pagenum > pagemax then
				worldedit.items[name].pagenum = 1
			end

		elseif fields.worldedit_gui_sphere_dome_prev then
			worldedit.items[name].pagenum = pagenum - 1
			if worldedit.items[name].pagenum <= 0 then
				worldedit.items[name].pagenum = pagemax
			end
		end

		gui_nodename1[name] = tostring(fields.worldedit_gui_sphere_dome_node)
		worldedit.items[name].filter = fields.worldedit_gui_sphere_dome_search_clear and "" or
					       fields.worldedit_gui_sphere_dome_filter

		gui_distance2[name] = tostring(fields.worldedit_gui_sphere_dome_radius)
		worldedit.show_page(name, "worldedit_gui_sphere_dome")

		local submit
		if fields.worldedit_gui_sphere_dome_submit_hollow then
			submit = "hollowsphere"
		elseif fields.worldedit_gui_sphere_dome_submit_solid then
			submit = "sphere"
		elseif fields.worldedit_gui_sphere_dome_submit_hollow_dome then
			submit = "hollowdome"
		elseif fields.worldedit_gui_sphere_dome_submit_solid_dome then
			submit = "dome"
		end

		if submit then
			local n = worldedit.normalize_nodename(gui_nodename1[name])
			if n then
				minetest.chatcommands["/"..submit].func(name, string.format("%s %s", gui_distance2[name], n))
			end
		end

		return true
	end

	return false
end)

worldedit.register_gui_function("worldedit_gui_cylinder", {
	type = "advanced",
	name = "Cylinder",
	form = true,
	privs = combine_we_privs({"hollowcylinder", "cylinder"}),
	get_formspec = function(name)
		local node, axis, length = gui_nodename1[name], gui_axis1[name], gui_distance1[name]
		local radius1, radius2 = gui_distance2[name], gui_distance3[name]
		local nodename = worldedit.normalize_nodename(node)
		local pagenum = worldedit.items[name].pagenum or 1
		local filter = worldedit.items[name].filter or ""
		local items_list = get_items_list(filter, pagenum, name, "cylinder")
		local pagemax = worldedit.items[name].pagemax or 1

		return "size[8,8]" .. worldedit.get_formspec_header("worldedit_gui_cylinder") ..
			items_list ..
			string.format("field[0.3,4.5;3,0.8;worldedit_gui_cylinder_filter;Filter;%s]",
				minetest.formspec_escape(filter)) ..
			string.format("field[0.3,5.6;4,0.8;worldedit_gui_cylinder_node;Name;%s]",
				minetest.formspec_escape(node)) ..
			"button[2.9,4.18;0.8,0.8;worldedit_gui_cylinder_search;?]" ..
			"button[3.6,4.18;0.8,0.8;worldedit_gui_cylinder_search_clear;X]" ..
			"button[5.5,4.08;0.8,1;worldedit_gui_cylinder_prev;<]" ..
			"label[6.2,4.28;" ..
				minetest.colorize("#FFFF00", pagenum) .. " / " .. pagemax .. "]" ..
			"button[7.2,4.08;0.8,1;worldedit_gui_cylinder_next;>]" ..
			string.format("field[0.3,6.9;2,0.8;worldedit_gui_cylinder_length;Length;%s]",
				minetest.formspec_escape(length)) ..
			string.format("field[2.2,6.9;2,0.8;worldedit_gui_cylinder_radius1;Base Radius;%s]",
				minetest.formspec_escape(radius1)) ..
			string.format("field[4.1,6.9;2,0.8;worldedit_gui_cylinder_radius2;Top Radius;%s]",
				minetest.formspec_escape(radius2)) ..
			string.format("dropdown[5.7,6.55;2.4;worldedit_gui_cylinder_axis;" ..
				"X axis,Y axis,Z axis,Look direction;%d]", axis) ..
			"field_close_on_enter[worldedit_gui_cylinder_filter;false]" ..
			"button_exit[1,7.5;3,0.8;worldedit_gui_cylinder_submit_hollow;Hollow Cylinder]" ..
			"button_exit[4,7.5;3,0.8;worldedit_gui_cylinder_submit_solid;Solid Cylinder]"
	end,
})

worldedit.register_gui_handler("worldedit_gui_cylinder", function(name, fields)
	for field in pairs(fields) do
		if field:find("worldedit_gui_cylinder_[%w_]+:[%w_]+_inv") then
			local item = field:match("worldedit_gui_cylinder_([%w_]+:[%w_]+)_inv")
			gui_nodename1[name] = item
			worldedit.show_page(name, "worldedit_gui_cylinder")
			return true
		end
	end

	if fields.worldedit_gui_cylinder_search or
	   fields.key_enter_field == "worldedit_gui_cylinder_filter" then
		worldedit.items[name].pagenum = 1
		worldedit.items[name].filter = fields.worldedit_gui_cylinder_filter
		worldedit.show_page(name, "worldedit_gui_cylinder")
		return true

	elseif fields.worldedit_gui_cylinder_submit_hollow or
	       fields.worldedit_gui_cylinder_submit_solid  or
	       fields.worldedit_gui_cylinder_search_clear  or
	       fields.worldedit_gui_cylinder_next          or
	       fields.worldedit_gui_cylinder_prev          then
	   	gui_nodename1[name] = tostring(fields.worldedit_gui_cylinder_node)
		worldedit.items[name].filter = fields.worldedit_gui_cylinder_search_clear and "" or
					       fields.worldedit_gui_cylinder_filter

		gui_axis1[name] = worldedit.axis_indices[fields.worldedit_gui_cylinder_axis]
		gui_distance1[name] = tostring(fields.worldedit_gui_cylinder_length)
		gui_distance2[name] = tostring(fields.worldedit_gui_cylinder_radius1)
		gui_distance3[name] = tostring(fields.worldedit_gui_cylinder_radius2)

		local pagenum = worldedit.items[name].pagenum or 1
		local pagemax = worldedit.items[name].pagemax or 1

		if fields.worldedit_gui_cylinder_search_clear then
			worldedit.items[name].pagenum = 1
		end

		if fields.worldedit_gui_cylinder_next then
			worldedit.items[name].pagenum = pagenum + 1
			if worldedit.items[name].pagenum > pagemax then
				worldedit.items[name].pagenum = 1
			end

		elseif fields.worldedit_gui_cylinder_prev then
			worldedit.items[name].pagenum = pagenum - 1
			if worldedit.items[name].pagenum <= 0 then
				worldedit.items[name].pagenum = pagemax
			end
		end

		worldedit.show_page(name, "worldedit_gui_cylinder")

		local submit
		if fields.worldedit_gui_cylinder_submit_hollow then
			submit = "hollowcylinder"
		elseif fields.worldedit_gui_cylinder_submit_solid then
			submit = "cylinder"
		end

		if submit then
			local n = worldedit.normalize_nodename(gui_nodename1[name])
			if n then
				local args = string.format(
					"%s %s %s %s %s",
					axis_values[gui_axis1[name]],
					gui_distance1[name],
					gui_distance2[name],
					gui_distance3[name],
					n)
				minetest.chatcommands["/"..submit].func(name, args)
			end
		end

		return true
	end

	if fields.worldedit_gui_cylinder_axis then
		gui_axis1[name] = worldedit.axis_indices[fields.worldedit_gui_cylinder_axis]
		worldedit.show_page(name, "worldedit_gui_cylinder")
		return true
	end

	return false
end)

worldedit.register_gui_function("worldedit_gui_pyramid", {
	type = "advanced",
	name = "Pyramid",
	form = true,
	privs = we_privs("pyramid"),
	get_formspec = function(name)
		local node, axis, length = gui_nodename1[name], gui_axis1[name], gui_distance1[name]
		local nodename = worldedit.normalize_nodename(node)
		local pagenum = worldedit.items[name].pagenum or 1
		local filter = worldedit.items[name].filter or ""
		local items_list = get_items_list(filter, pagenum, name, "pyramid")
		local pagemax = worldedit.items[name].pagemax or 1

		return "size[8,7]" .. worldedit.get_formspec_header("worldedit_gui_pyramid") ..
			items_list ..
			string.format("field[0.3,4.5;3,0.8;worldedit_gui_pyramid_filter;Filter;%s]",
				minetest.formspec_escape(filter)) ..
			string.format("field[0.3,5.8;3.5,0.8;worldedit_gui_pyramid_node;Name;%s]",
				minetest.formspec_escape(node)) ..
			"button[2.9,4.18;0.8,0.8;worldedit_gui_pyramid_search;?]" ..
			"button[3.6,4.18;0.8,0.8;worldedit_gui_pyramid_search_clear;X]" ..
			"button[5.5,4.08;0.8,1;worldedit_gui_pyramid_prev;<]" ..
			"label[6.2,4.28;" ..
				minetest.colorize("#FFFF00", pagenum) .. " / " .. pagemax .. "]" ..
			"button[7.2,4.08;0.8,1;worldedit_gui_pyramid_next;>]" ..
			string.format("field[3.8,5.8;2,0.8;worldedit_gui_pyramid_length;Length;%s]",
				minetest.formspec_escape(length)) ..
			string.format("dropdown[5.5,5.45;2.5;worldedit_gui_pyramid_axis;" ..
				"X axis,Y axis,Z axis,Look direction;%d]", axis) ..
			"field_close_on_enter[worldedit_gui_pyramid_filter;false]" ..
			"button_exit[1,6.5;3,0.8;worldedit_gui_pyramid_submit_hollow;Hollow Pyramid]" ..
			"button_exit[4,6.5;3,0.8;worldedit_gui_pyramid_submit_solid;Solid Pyramid]"
	end,
})

worldedit.register_gui_handler("worldedit_gui_pyramid", function(name, fields)
	for field in pairs(fields) do
		if field:find("worldedit_gui_pyramid_[%w_]+:[%w_]+_inv") then
			local item = field:match("worldedit_gui_pyramid_([%w_]+:[%w_]+)_inv")
			gui_nodename1[name] = item
			worldedit.show_page(name, "worldedit_gui_pyramid")
			return true
		end
	end

	if fields.worldedit_gui_pyramid_search or
	   fields.key_enter_field == "worldedit_gui_pyramid_filter" then
		worldedit.items[name].pagenum = 1
		worldedit.items[name].filter = fields.worldedit_gui_pyramid_filter
		worldedit.show_page(name, "worldedit_gui_pyramid")
		return true

	elseif fields.worldedit_gui_pyramid_submit_solid  or
	       fields.worldedit_gui_pyramid_submit_hollow or
	       fields.worldedit_gui_pyramid_axis          or
	       fields.worldedit_gui_pyramid_search_clear  or
	       fields.worldedit_gui_pyramid_next          or
	       fields.worldedit_gui_pyramid_prev          then
		gui_nodename1[name] = tostring(fields.worldedit_gui_pyramid_node)
		worldedit.items[name].filter = fields.worldedit_gui_pyramid_search_clear and "" or
					       fields.worldedit_gui_pyramid_filter

		gui_axis1[name] = axis_indices[fields.worldedit_gui_pyramid_axis]
		gui_distance1[name] = tostring(fields.worldedit_gui_pyramid_length)

		local pagenum = worldedit.items[name].pagenum or 1
		local pagemax = worldedit.items[name].pagemax or 1

		if fields.worldedit_gui_pyramid_search_clear then
			worldedit.items[name].pagenum = 1
		end

		if fields.worldedit_gui_pyramid_next then
			worldedit.items[name].pagenum = pagenum + 1
			if worldedit.items[name].pagenum > pagemax then
				worldedit.items[name].pagenum = 1
			end

		elseif fields.worldedit_gui_pyramid_prev then
			worldedit.items[name].pagenum = pagenum - 1
			if worldedit.items[name].pagenum <= 0 then
				worldedit.items[name].pagenum = pagemax
			end
		end

		worldedit.show_page(name, "worldedit_gui_pyramid")

		local submit = nil
		if fields.worldedit_gui_pyramid_submit_solid then
			submit = "pyramid"
		elseif fields.worldedit_gui_pyramid_submit_hollow then
			submit = "hollowpyramid"
		end

		if submit then
			local n = worldedit.normalize_nodename(gui_nodename1[name])
			if n then
				minetest.chatcommands["/"..submit].func(name, string.format("%s %s %s", axis_values[gui_axis1[name]], gui_distance1[name], n))
			end
		end

		return true
	end

	if fields.worldedit_gui_pyramid_axis then
		gui_axis1[name] = axis_indices[fields.worldedit_gui_pyramid_axis]
		worldedit.show_page(name, "worldedit_gui_pyramid")
		return true
	end

	return false
end)

worldedit.register_gui_function("worldedit_gui_spiral", {
	type = "advanced",
	name = "Spiral",
	form = true,
	privs = we_privs("spiral"),
	get_formspec = function(name)
		local node, length, height, space =
			gui_nodename1[name], gui_distance1[name], gui_distance2[name], gui_distance3[name]
		local nodename = worldedit.normalize_nodename(node)
		local pagenum = worldedit.items[name].pagenum or 1
		local filter = worldedit.items[name].filter or ""
		local items_list = get_items_list(filter, pagenum, name, "spiral")
		local pagemax = worldedit.items[name].pagemax or 1

		return "size[8,8]" .. worldedit.get_formspec_header("worldedit_gui_spiral") ..
			items_list ..
			string.format("field[0.3,4.5;3,0.8;worldedit_gui_spiral_filter;Filter;%s]",
				minetest.formspec_escape(filter)) ..
			string.format("field[0.3,5.6;3.5,0.8;worldedit_gui_spiral_node;Name;%s]",
				minetest.formspec_escape(node)) ..
			"button[2.9,4.18;0.8,0.8;worldedit_gui_spiral_search;?]" ..
			"button[3.6,4.18;0.8,0.8;worldedit_gui_spiral_search_clear;X]" ..
			"button[5.5,4.08;0.8,1;worldedit_gui_spiral_prev;<]" ..
			"label[6.2,4.28;" ..
				minetest.colorize("#FFFF00", pagenum) .. " / " .. pagemax .. "]" ..
			"button[7.2,4.08;0.8,1;worldedit_gui_spiral_next;>]" ..
			string.format("field[0.3,6.8;2,0.8;worldedit_gui_spiral_length;Side Length;%s]",
				minetest.formspec_escape(length)) ..
			string.format("field[2.3,6.8;2,0.8;worldedit_gui_spiral_height;Height;%s]",
				minetest.formspec_escape(height)) ..
			string.format("field[4.3,6.8;2,0.8;worldedit_gui_spiral_space;Wall Spacing;%s]",
				minetest.formspec_escape(space)) ..
			"field_close_on_enter[worldedit_gui_spiral_filter;false]" ..
			"button_exit[2.5,7.5;3,0.8;worldedit_gui_spiral_submit;Spiral]"
	end,
})

worldedit.register_gui_handler("worldedit_gui_spiral", function(name, fields)
	for field in pairs(fields) do
		if field:find("worldedit_gui_spiral_[%w_]+:[%w_]+_inv") then
			local item = field:match("worldedit_gui_spiral_([%w_]+:[%w_]+)_inv")
			gui_nodename1[name] = item
			worldedit.show_page(name, "worldedit_gui_spiral")
			return true
		end
	end

	if fields.worldedit_gui_spiral_search or
	   fields.key_enter_field == "worldedit_gui_spiral_filter" then
		worldedit.items[name].pagenum = 1
		worldedit.items[name].filter = fields.worldedit_gui_spiral_filter
		worldedit.show_page(name, "worldedit_gui_spiral")
		return true

	elseif fields.worldedit_gui_spiral_submit        or
	       fields.worldedit_gui_spiral_search_clear  or
	       fields.worldedit_gui_spiral_next          or
	       fields.worldedit_gui_spiral_prev          then
		gui_nodename1[name] = tostring(fields.worldedit_gui_spiral_node)
		worldedit.items[name].filter = fields.worldedit_gui_spiral_search_clear and "" or
					       fields.worldedit_gui_spiral_filter

		gui_distance1[name] = tostring(fields.worldedit_gui_spiral_length)
		gui_distance2[name] = tostring(fields.worldedit_gui_spiral_height)
		gui_distance3[name] = tostring(fields.worldedit_gui_spiral_space)

		local pagenum = worldedit.items[name].pagenum or 1
		local pagemax = worldedit.items[name].pagemax or 1

		if fields.worldedit_gui_spiral_search_clear then
			worldedit.items[name].pagenum = 1
		end

		if fields.worldedit_gui_spiral_next then
			worldedit.items[name].pagenum = pagenum + 1
			if worldedit.items[name].pagenum > pagemax then
				worldedit.items[name].pagenum = 1
			end

		elseif fields.worldedit_gui_spiral_prev then
			worldedit.items[name].pagenum = pagenum - 1
			if worldedit.items[name].pagenum <= 0 then
				worldedit.items[name].pagenum = pagemax
			end
		end

		worldedit.show_page(name, "worldedit_gui_spiral")

		if fields.worldedit_gui_spiral_submit then
			local n = worldedit.normalize_nodename(gui_nodename1[name])
			if n then
				minetest.chatcommands["/spiral"].func(name,
					string.format("%s %s %s %s",
						gui_distance1[name],
						gui_distance2[name],
						gui_distance3[name], n))
			end
		end

		return true
	end

	return false
end)

worldedit.register_gui_function("worldedit_gui_copy_move", {
	type = "advanced",
	name = "Copy / Move",
	privs = combine_we_privs({"copy", "move"}),
	get_formspec = function(name)
		local axis = gui_axis1[name] or 4
		local amount = gui_distance1[name] or "10"
		return "size[6.5,3]" .. worldedit.get_formspec_header("worldedit_gui_copy_move") ..
			string.format("field[0.5,1.5;4,0.8;worldedit_gui_copy_move_amount;Amount;%s]", minetest.formspec_escape(amount)) ..
			string.format("dropdown[4,1.18;2.5;worldedit_gui_copy_move_axis;X axis,Y axis,Z axis,Look direction;%d]", axis) ..
			"button_exit[0,2.5;3,0.8;worldedit_gui_copy_move_copy;Copy Region]" ..
			"button_exit[3.5,2.5;3,0.8;worldedit_gui_copy_move_move;Move Region]"
	end,
})

worldedit.register_gui_handler("worldedit_gui_copy_move", function(name, fields)
	if fields.worldedit_gui_copy_move_copy or fields.worldedit_gui_copy_move_move then
		gui_axis1[name] = axis_indices[fields.worldedit_gui_copy_move_axis] or 4
		gui_distance1[name] = tostring(fields.worldedit_gui_copy_move_amount)
		worldedit.show_page(name, "worldedit_gui_copy_move")
		if fields.worldedit_gui_copy_move_copy then
			minetest.chatcommands["/copy"].func(name, string.format("%s %s", axis_values[gui_axis1[name]], gui_distance1[name]))
		else --fields.worldedit_gui_copy_move_move
			minetest.chatcommands["/move"].func(name, string.format("%s %s", axis_values[gui_axis1[name]], gui_distance1[name]))
		end
		return true
	end
	if fields.worldedit_gui_copy_move_axis then
		gui_axis1[name] = axis_indices[fields.worldedit_gui_copy_move_axis] or 4
		worldedit.show_page(name, "worldedit_gui_copy_move")
		return true
	end
	return false
end)

worldedit.register_gui_function("worldedit_gui_stack", {
	type = "advanced",
	name = "Stack",
	privs = we_privs("stack"),
	get_formspec = function(name)
		local axis, count = gui_axis1[name], gui_count1[name]
		return "size[6.5,3]" .. worldedit.get_formspec_header("worldedit_gui_stack") ..
			string.format("field[0.5,1.5;4,0.8;worldedit_gui_stack_count;Count;%s]", minetest.formspec_escape(count)) ..
			string.format("dropdown[4,1.18;2.5;worldedit_gui_stack_axis;X axis,Y axis,Z axis,Look direction;%d]", axis) ..
			"button_exit[0,2.5;3,0.8;worldedit_gui_stack_submit;Stack]"
	end,
})

worldedit.register_gui_handler("worldedit_gui_stack", function(name, fields)
	if fields.worldedit_gui_stack_submit then
		gui_axis1[name] = axis_indices[fields.worldedit_gui_stack_axis]
		gui_count1[name] = tostring(fields.worldedit_gui_stack_count)
		worldedit.show_page(name, "worldedit_gui_stack")
		minetest.chatcommands["/stack"].func(name, string.format("%s %s", axis_values[gui_axis1[name]], gui_count1[name]))
		return true
	end
	if fields.worldedit_gui_stack_axis then
		gui_axis1[name] = axis_indices[fields.worldedit_gui_stack_axis]
		worldedit.show_page(name, "worldedit_gui_stack")
		return true
	end
	return false
end)

worldedit.register_gui_function("worldedit_gui_stretch", {
	type = "advanced",
	name = "Stretch",
	privs = we_privs("stretch"),
	get_formspec = function(name)
		local stretchx, stretchy, stretchz = gui_count1[name], gui_count2[name], gui_count3[name]
		return "size[5,5]" .. worldedit.get_formspec_header("worldedit_gui_stretch") ..
			string.format("field[0.5,1.5;4,0.8;worldedit_gui_stretch_x;Stretch X;%s]", minetest.formspec_escape(stretchx)) ..
			string.format("field[0.5,2.5;4,0.8;worldedit_gui_stretch_y;Stretch Y;%s]", minetest.formspec_escape(stretchy)) ..
			string.format("field[0.5,3.5;4,0.8;worldedit_gui_stretch_z;Stretch Z;%s]", minetest.formspec_escape(stretchz)) ..
			"button_exit[0,4.5;3,0.8;worldedit_gui_stretch_submit;Stretch]"
	end,
})

worldedit.register_gui_handler("worldedit_gui_stretch", function(name, fields)
	if fields.worldedit_gui_stretch_submit then
		gui_count1[name] = tostring(fields.worldedit_gui_stretch_x)
		gui_count2[name] = tostring(fields.worldedit_gui_stretch_y)
		gui_count3[name] = tostring(fields.worldedit_gui_stretch_z)
		worldedit.show_page(name, "worldedit_gui_stretch")
		minetest.chatcommands["/stretch"].func(name, string.format("%s %s %s", gui_count1[name], gui_count2[name], gui_count3[name]))
		return true
	end
	return false
end)

worldedit.register_gui_function("worldedit_gui_transpose", {
	type = "advanced",
	name = "Transpose",
	privs = we_privs("transpose"),
	get_formspec = function(name)
		local axis1, axis2 = gui_axis1[name], gui_axis2[name]
		return "size[5.5,3]" .. worldedit.get_formspec_header("worldedit_gui_transpose") ..
			string.format("dropdown[0,1;2.5;worldedit_gui_transpose_axis1;X axis,Y axis,Z axis,Look direction;%d]", axis1) ..
			string.format("dropdown[3,1;2.5;worldedit_gui_transpose_axis2;X axis,Y axis,Z axis,Look direction;%d]", axis2) ..
			"button_exit[0,2.5;3,0.8;worldedit_gui_transpose_submit;Transpose]"
	end,
})

worldedit.register_gui_handler("worldedit_gui_transpose", function(name, fields)
	if fields.worldedit_gui_transpose_submit then
		gui_axis1[name] = axis_indices[fields.worldedit_gui_transpose_axis1]
		worldedit.show_page(name, "worldedit_gui_transpose")
		minetest.chatcommands["/transpose"].func(name, string.format("%s %s", axis_values[gui_axis1[name]], axis_values[gui_axis2[name]]))
		return true
	end
	if fields.worldedit_gui_transpose_axis1 then
		gui_axis1[name] = axis_indices[fields.worldedit_gui_transpose_axis1]
		worldedit.show_page(name, "worldedit_gui_transpose")
		return true
	end
	if fields.worldedit_gui_transpose_axis2 then
		gui_axis2[name] = axis_indices[fields.worldedit_gui_transpose_axis2]
		worldedit.show_page(name, "worldedit_gui_transpose")
		return true
	end
	return false
end)

worldedit.register_gui_function("worldedit_gui_flip", {
	type = "advanced",
	name = "Flip",
	privs = we_privs("flip"),
	get_formspec = function(name)
		local axis = gui_axis1[name]
		return "size[5,3]" .. worldedit.get_formspec_header("worldedit_gui_flip") ..
			string.format("dropdown[0,1;2.5;worldedit_gui_flip_axis;X axis,Y axis,Z axis,Look direction;%d]", axis) ..
			"button_exit[0,2.5;3,0.8;worldedit_gui_flip_submit;Flip]"
	end,
})

worldedit.register_gui_handler("worldedit_gui_flip", function(name, fields)
	if fields.worldedit_gui_flip_submit then
		gui_axis1[name] = axis_indices[fields.worldedit_gui_flip_axis]
		worldedit.show_page(name, "worldedit_gui_flip")
		minetest.chatcommands["/flip"].func(name, axis_values[gui_axis1[name]])
		return true
	end
	if fields.worldedit_gui_flip_axis then
		gui_axis1[name] = axis_indices[fields.worldedit_gui_flip_axis]
		worldedit.show_page(name, "worldedit_gui_flip")
		return true
	end
	return false
end)

worldedit.register_gui_function("worldedit_gui_rotate", {
	type = "default",
	name = "Rotate",
	privs = we_privs("rotate"),
	get_formspec = function(name)
		local axis, angle = gui_axis1[name], gui_angle[name]
		return "size[5.5,3]" .. worldedit.get_formspec_header("worldedit_gui_rotate") ..
			string.format("dropdown[0,1;2.5;worldedit_gui_rotate_angle;90 degrees,180 degrees,270 degrees;%s]", angle) ..
			string.format("dropdown[3,1;2.5;worldedit_gui_rotate_axis;X axis,Y axis,Z axis,Look direction;%d]", axis) ..
			"button_exit[0,2.5;3,0.8;worldedit_gui_rotate_submit;Rotate]"
	end,
})

worldedit.register_gui_handler("worldedit_gui_rotate", function(name, fields)
	if fields.worldedit_gui_rotate_submit then
		gui_axis1[name] = axis_indices[fields.worldedit_gui_rotate_axis]
		gui_angle[name] = angle_indices[fields.worldedit_gui_rotate_angle]

		print(axis_values[gui_axis1[name]])
		print(angle_values[gui_angle[name]])

		worldedit.show_page(name, "worldedit_gui_rotate")
		minetest.chatcommands["/rotate"].func(name,
			string.format("%s %s",
				axis_values[gui_axis1[name]],
				angle_values[gui_angle[name]]
			))
		return true
	end
	if fields.worldedit_gui_rotate_axis then
		gui_axis1[name] = axis_indices[fields.worldedit_gui_rotate_axis]
		worldedit.show_page(name, "worldedit_gui_rotate")
		return true
	end
	if fields.worldedit_gui_rotate_angle then
		gui_angle[name] = angle_indices[fields.worldedit_gui_rotate_angle]
		worldedit.show_page(name, "worldedit_gui_rotate")
		return true
	end
	return false
end)

worldedit.register_gui_function("worldedit_gui_orient", {
	type = "advanced",
	name = "Orient",
	privs = we_privs("orient"),
	get_formspec = function(name)
		local angle = gui_angle[name]
		return "size[5,3]" .. worldedit.get_formspec_header("worldedit_gui_orient") ..
			string.format("dropdown[0,1;2.5;worldedit_gui_orient_angle;90 degrees,180 degrees,270 degrees;%s]", angle) ..
			"button_exit[0,2.5;3,0.8;worldedit_gui_orient_submit;Orient]"
	end,
})

worldedit.register_gui_handler("worldedit_gui_orient", function(name, fields)
	if fields.worldedit_gui_orient_submit then
		gui_angle[name] = angle_indices[fields.worldedit_gui_orient_angle]
		worldedit.show_page(name, "worldedit_gui_orient")
		minetest.chatcommands["/orient"].func(name, tostring(angle_values[gui_angle[name]]))
		return true
	end
	if fields.worldedit_gui_orient_angle then
		gui_angle[name] = angle_indices[fields.worldedit_gui_orient_angle]
		worldedit.show_page(name, "worldedit_gui_orient")
		return true
	end
	return false
end)

worldedit.register_gui_function("worldedit_gui_fixlight", {
	type = "advanced",
	name = "Fix Lighting",
	privs = we_privs("fixlight"),
	on_select = function(name)
		minetest.chatcommands["/fixlight"].func(name, "")
	end,
})

worldedit.register_gui_function("worldedit_gui_hide", {
	type = "advanced",
	name = "Hide Region",
	privs = we_privs("hide"),
	on_select = function(name)
		minetest.chatcommands["/hide"].func(name, "")
	end,
})

worldedit.register_gui_function("worldedit_gui_suppress", {
	type = "default",
	name = "Suppress Nodes",
	privs = we_privs("suppress"),
	on_select = function(name)
		minetest.chatcommands["/suppress"].func(name)
	end,
})

worldedit.register_gui_handler("worldedit_gui_suppress", function(name, fields)
	if fields.worldedit_gui_suppress_search or fields.worldedit_gui_suppress_submit then
		gui_nodename1[name] = tostring(fields.worldedit_gui_suppress_node)
		worldedit.show_page(name, "worldedit_gui_suppress")
		if fields.worldedit_gui_suppress_submit then
			minetest.chatcommands["/suppress"].func(name)
		end
		return true
	end
	return false
end)

worldedit.register_gui_function("worldedit_gui_highlight", {
	type = "advanced",
	name = "Highlight Nodes",
	privs = we_privs("highlight"),
	get_formspec = function(name)
		local node = gui_nodename1[name]
		local nodename = worldedit.normalize_nodename(node)
		return "size[6.5,3]" .. worldedit.get_formspec_header("worldedit_gui_highlight") ..
			string.format("field[0.5,1.5;4,0.8;worldedit_gui_highlight_node;Name;%s]", minetest.formspec_escape(node)) ..
			"button[4,1.18;1.5,0.8;worldedit_gui_highlight_search;Search]" ..
			formspec_node("5.5,1.1", nodename) ..
			"button_exit[0,2.5;3,0.8;worldedit_gui_highlight_submit;Highlight Nodes]"
	end,
})

worldedit.register_gui_handler("worldedit_gui_highlight", function(name, fields)
	if fields.worldedit_gui_highlight_search or fields.worldedit_gui_highlight_submit then
		gui_nodename1[name] = tostring(fields.worldedit_gui_highlight_node)
		worldedit.show_page(name, "worldedit_gui_highlight")
		if fields.worldedit_gui_highlight_submit then
			local n = worldedit.normalize_nodename(gui_nodename1[name])
			if n then
				minetest.chatcommands["/highlight"].func(name, n)
			end
		end
		return true
	end
	return false
end)

worldedit.register_gui_function("worldedit_gui_restore", {
	type = "advanced",
	name = "Restore Region",
	privs = we_privs("restore"),
	on_select = function(name)
		minetest.chatcommands["/restore"].func(name, "")
	end,
})

local worldpath = minetest.get_worldpath()

local function scandir()
	local i, t, popen = 0, {}, io.popen
	local pfile = popen("ls -a " .. worldpath .. "/schems")

	for filename in pfile:lines() do
		if filename:find(".we") then
			local name = filename:match("(.*).we")
			i = i + 1
			t[i] = name
		end
	end

	pfile:close()
	return t
end

local function rm_schem(name)
	local file = io.popen("rm " .. worldpath .. "/schems/" .. name .. ".we")
	file:close()
end

worldedit.register_gui_function("worldedit_gui_save_load", {
	type = "default",
	name = "Copy / Paste",
	privs = combine_we_privs({"save", "allocate", "load"}),
	get_formspec = function(name)
		local filename = gui_filename[name]
		local schems = scandir()

		return "size[6,4]" .. worldedit.get_formspec_header("worldedit_gui_save_load") ..
			string.format("field[0.5,1.5;2.5,0.8;worldedit_gui_save_filename;New building:;%s]",
				minetest.formspec_escape(filename)) ..
			"label[3,0.7;Buildings:]" ..
			"dropdown[3,1.15;2.5;worldedit_dd_schems;" .. table.concat(schems, ",") .. ";1]" ..
			"button[0,2.5;3,0.8;worldedit_gui_save_load_submit_save;Save]" ..
			"button_exit[3,2.5;3,0.8;worldedit_gui_save_load_submit_allocate;Allocate]" ..
			"button_exit[0,3.5;3,0.8;worldedit_gui_save_load_submit_load;Load]" ..
			"button[3,3.5;3,0.8;worldedit_gui_save_load_submit_delete;Delete]"
	end,
})

worldedit.register_gui_handler("worldedit_gui_save_load", function(name, fields)
	if fields.worldedit_gui_save_load_submit_save     or
	   fields.worldedit_gui_save_load_submit_allocate or
	   fields.worldedit_gui_save_load_submit_load     or
	   fields.worldedit_gui_save_load_submit_delete   then

		if fields.worldedit_gui_save_load_submit_save then
			gui_filename[name] = tostring(fields.worldedit_gui_save_filename)
			minetest.chatcommands["/save"].func(name, gui_filename[name])
			worldedit.show_page(name, "worldedit_gui_save_load")
		elseif fields.worldedit_gui_save_load_submit_allocate then
			gui_filename[name] = tostring(fields.worldedit_dd_schems)
			minetest.chatcommands["/allocate"].func(name, gui_filename[name])
		elseif fields.worldedit_gui_save_load_submit_load then
			gui_filename[name] = tostring(fields.worldedit_dd_schems)
			minetest.chatcommands["/load"].func(name, gui_filename[name])
		elseif fields.worldedit_gui_save_load_submit_delete then
			gui_filename[name] = tostring(fields.worldedit_dd_schems)
			rm_schem(gui_filename[name])
			worldedit.show_page(name, "worldedit_gui_save_load")
		end

		return true
	end

	return false
end)

worldedit.register_gui_function("worldedit_gui_cube", {
	type = "advanced",
	name = "Cuboid", -- technically the command is misnamed, I know...
	form = true,
	privs = combine_we_privs({"hollowcube", "cube"}),
	get_formspec = function(name)
		local width, height, length = gui_distance1[name], gui_distance2[name], gui_distance3[name]
		local node = gui_nodename1[name]
		local nodename = worldedit.normalize_nodename(node)
		local pagenum = worldedit.items[name].pagenum or 1
		local filter = worldedit.items[name].filter or ""
		local items_list = get_items_list(filter, pagenum, name, "cube")
		local pagemax = worldedit.items[name].pagemax or 1

		return "size[8,8]" .. worldedit.get_formspec_header("worldedit_gui_cube") ..
			items_list ..
			string.format("field[0.3,4.5;3,0.8;worldedit_gui_cube_filter;Filter;%s]",
				minetest.formspec_escape(filter)) ..
			string.format("field[0.3,5.7;3.5,0.8;worldedit_gui_cube_node;Name;%s]",
				minetest.formspec_escape(node)) ..
			"button[2.9,4.18;0.8,0.8;worldedit_gui_cube_search;?]" ..
			"button[3.6,4.18;0.8,0.8;worldedit_gui_cube_search_clear;X]" ..
			"button[5.5,4.08;0.8,1;worldedit_gui_cube_prev;<]" ..
			"label[6.2,4.28;" ..
				minetest.colorize("#FFFF00", pagenum) .. " / " .. pagemax .. "]" ..
			"button[7.2,4.08;0.8,1;worldedit_gui_cube_next;>]" ..
			string.format("field[0.3,6.8;2,1;worldedit_gui_cube_width;Width;%s]",
				minetest.formspec_escape(width)) ..
			string.format("field[2.3,6.8;2,1;worldedit_gui_cube_height;Height;%s]",
				minetest.formspec_escape(height)) ..
			string.format("field[4.3,6.8;2,1;worldedit_gui_cube_length;Length;%s]",
				minetest.formspec_escape(length)) ..
			"field_close_on_enter[worldedit_gui_cube_filter;false]" ..
			"button_exit[1,7.5;3,1;worldedit_gui_cube_submit_hollow;Hollow Cuboid]" ..
			"button_exit[4,7.5;3,1;worldedit_gui_cube_submit_solid;Solid Cuboid]"
	end,
})

worldedit.register_gui_handler("worldedit_gui_cube", function(name, fields)
	for field in pairs(fields) do
		if field:find("worldedit_gui_cube_[%w_]+:[%w_]+_inv") then
			local item = field:match("worldedit_gui_cube_([%w_]+:[%w_]+)_inv")
			gui_nodename1[name] = item
			worldedit.show_page(name, "worldedit_gui_cube")
			return true
		end
	end

	if fields.worldedit_gui_cube_search or
	   fields.key_enter_field == "worldedit_gui_cube_filter" then
		worldedit.items[name].pagenum = 1
		worldedit.items[name].filter = fields.worldedit_gui_cube_filter
		worldedit.show_page(name, "worldedit_gui_cube")
		return true

	elseif fields.worldedit_gui_cube_submit_hollow or
	       fields.worldedit_gui_cube_submit_solid  or
	       fields.worldedit_gui_cube_search_clear  or
	       fields.worldedit_gui_cube_next          or
	       fields.worldedit_gui_cube_prev          then
		gui_nodename1[name] = tostring(fields.worldedit_gui_cube_node)
		worldedit.items[name].filter = fields.worldedit_gui_cube_search_clear and "" or
					       fields.worldedit_gui_cube_filter

		gui_distance1[name] = tostring(fields.worldedit_gui_cube_width)
		gui_distance2[name] = tostring(fields.worldedit_gui_cube_height)
		gui_distance3[name] = tostring(fields.worldedit_gui_cube_length)

		local pagenum = worldedit.items[name].pagenum or 1
		local pagemax = worldedit.items[name].pagemax or 1

		if fields.worldedit_gui_cube_search_clear then
			worldedit.items[name].pagenum = 1
		end

		if fields.worldedit_gui_cube_next then
			worldedit.items[name].pagenum = pagenum + 1
			if worldedit.items[name].pagenum > pagemax then
				worldedit.items[name].pagenum = 1
			end

		elseif fields.worldedit_gui_cube_prev then
			worldedit.items[name].pagenum = pagenum - 1
			if worldedit.items[name].pagenum <= 0 then
				worldedit.items[name].pagenum = pagemax
			end
		end

		worldedit.show_page(name, "worldedit_gui_cube")

		local submit = nil
		if fields.worldedit_gui_cube_submit_hollow then
			submit = "hollowcube"
		elseif fields.worldedit_gui_cube_submit_solid then
			submit = "cube"
		end

		if submit then
			local n = worldedit.normalize_nodename(gui_nodename1[name])
			if n then
				local args = string.format("%s %s %s %s", gui_distance1[name], gui_distance2[name], gui_distance3[name], n)
				minetest.chatcommands["/"..submit].func(name, args)
			end
		end

		return true
	end

	return false
end)

worldedit.register_gui_function("worldedit_gui_clearobjects", {
	type = "advanced",
	name = "Clear Objects",
	privs = we_privs("clearobjects"),
	on_select = function(name)
		minetest.chatcommands["/clearobjects"].func(name, "")
	end,
})

worldedit.register_gui_function("worldedit_gui_undo", {
	type = "default",
	name = "Cancel Action",
	privs = we_privs("undo"),
	on_select = function(name)
		minetest.chatcommands["/undo"].func(name, "")
	end,
})
