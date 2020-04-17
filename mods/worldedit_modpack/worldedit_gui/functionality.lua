local S = minetest.get_translator("worldedit_gui")

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

worldedit.axis_indices = {[S("X axis")]=1, [S("Y axis")]=2, [S("Z axis")]=3, [S("Look direction")]=4}
worldedit.axis_values = {"x", "y", "z", "?"}
setmetatable(worldedit.axis_indices, {__index = function () return 4 end})
setmetatable(worldedit.axis_values, {__index = function () return "?" end})

local axis_indices = worldedit.axis_indices
local axis_values = worldedit.axis_values

worldedit.angle_indices = {[S("90 degrees")]=1, [S("180 degrees")]=2, [S("270 degrees")]=3}
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
	return nodename and string.format("item_image[%s;1,1;%s]", pos, nodename) or
			    string.format("image[%s;1,1;worldedit_gui_unknown.png]", pos)
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

--[[
worldedit.register_gui_function("worldedit_gui_about", {
	type = "advanced",
	name = S("About"),
	privs = {interact=true},
	on_select = function(name)
		minetest.chatcommands["/about"].func(name, "")
	end,
})
]]

worldedit.register_gui_function("worldedit_gui_inspect", {
	type = "advanced",
	name = S("Toggle Inspect"),
	privs = we_privs("inspect"),
	on_select = function(name)
		minetest.chatcommands["/inspect"].func(name, worldedit.inspect[name] and "disable" or "enable")
	end,
})

--[[
worldedit.register_gui_function("worldedit_gui_region", {
	type = "advanced",
	name = S("Get / Set Region"),
	privs = combine_we_privs({"p", "pos1", "pos2", "reset", "mark", "unmark", "volume", "fixedpos"}),
	get_formspec = function(name)
		local pos1, pos2 = worldedit.pos1[name], worldedit.pos2[name]
		return "size[9,7]" .. worldedit.get_formspec_header("worldedit_gui_region") ..
			"button_exit[0,1;3,0.8;worldedit_gui_p_get;" .. S("Get Positions") .. "]" ..
			"button_exit[3,1;3,0.8;worldedit_gui_p_set1;" .. S("Choose Position 1") .. "]" ..
			"button_exit[6,1;3,0.8;worldedit_gui_p_set2;" .. S("Choose Position 2") .. "]" ..
			"button_exit[0,2;3,0.8;worldedit_gui_pos1;" .. S("Position 1 Here") .. "]" ..
			"button_exit[3,2;3,0.8;worldedit_gui_pos2;" .. S("Position 2 Here") .. "]" ..
			"button_exit[6,2;3,0.8;worldedit_gui_reset;" .. S("Reset Region") .. "]" ..
			"button_exit[0,3;3,0.8;worldedit_gui_mark;" .. S("Mark Region") .. "]" ..
			"button_exit[3,3;3,0.8;worldedit_gui_unmark;" .. S("Unmark Region") .. "]" ..
			"button_exit[6,3;3,0.8;worldedit_gui_volume;" .. S("Region Volume") .. "]" ..
			"label[0,4.7;" .. S("Position 1") .. "]" ..
			string.format("field[2,5;1.5,0.8;worldedit_gui_fixedpos_pos1x;X ;%s]",
				pos1 and pos1.x or "") ..
			string.format("field[3.5,5;1.5,0.8;worldedit_gui_fixedpos_pos1y;Y ;%s]",
				pos1 and pos1.y or "") ..
			string.format("field[5,5;1.5,0.8;worldedit_gui_fixedpos_pos1z;Z ;%s]",
				pos1 and pos1.z or "") ..
			"button_exit[6.5,4.68;2.5,0.8;worldedit_gui_fixedpos_pos1_submit;" ..
				S("Set Position 1") .. "]" ..
			"label[0,6.2;" .. S("Position 2") .. "]" ..
			string.format("field[2,6.5;1.5,0.8;worldedit_gui_fixedpos_pos2x;X ;%s]",
				pos2 and pos2.x or "") ..
			string.format("field[3.5,6.5;1.5,0.8;worldedit_gui_fixedpos_pos2y;Y ;%s]",
				pos2 and pos2.y or "") ..
			string.format("field[5,6.5;1.5,0.8;worldedit_gui_fixedpos_pos2z;Z ;%s]",
				pos2 and pos2.z or "") ..
			"button_exit[6.5,6.18;2.5,0.8;worldedit_gui_fixedpos_pos2_submit;" ..
				S("Set Position 2") .. "]"
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
]]

worldedit.register_gui_function("worldedit_gui_set", {
	type = "advanced",
	name = S("Set Nodes"),
	privs = we_privs("set"),
	get_formspec = function(name)
		worldedit.items[name].current_page = "set"
		local node = gui_nodename1[name]
		local nodename = worldedit.normalize_nodename(node)

		local start_i = worldedit.items[name].start_i or 0
		local filter = worldedit.items[name].filter or ""
		local width, height = 9, 3
		local items_list, inv_size = utils.get_items_list(start_i, filter, width, height, 0, 0.2)
		local ipp = width * height

		return "size[8,6]" .. worldedit.get_formspec_header("worldedit_gui_set") ..
			string.format("field[0.3,4.5;4,0.8;!worldedit_gui_set_filter;" ..
				S("Search") .. ";%s]", minetest.formspec_escape(filter)) ..
			string.format("field[0.3,5.82;3,0.8;worldedit_gui_set_node;" ..
				S("Name") .. ";%s]", minetest.formspec_escape(node)) ..
			items_list ..
			"scrollbar[4,4.25;3.6,0.5;horizontal;set_sb_h;" ..
				start_i .. ",0," ..
				(inv_size - (inv_size % ipp)) .. "," ..
				ipp .. "," .. ipp .."," .. ipp ..
				";#999999;#777777;#FFFFFFFF;#808080FF]" ..
			"button_exit[3,5.5;3,0.8;worldedit_gui_set_submit;" .. S("Set Nodes") .. "]"
	end,
})

worldedit.register_gui_handler("worldedit_gui_set", function(name, fields)
	local continue = false
	for field in pairs(fields) do
		if field:find("worldedit") then
			continue = true
		end
	end

	for field in pairs(fields) do
		if continue and field:find(":") then
			local item = field:match("([%w_]+:[%w_]+)_inv")
			gui_nodename1[name] = item

			if worldedit.items[name].current_page then
				worldedit.show_page(name, "worldedit_gui_" .. worldedit.items[name].current_page)
				return true
			end
		end
	end

	if fields.set_sb_h and fields.set_sb_h:sub(1,3) == "CHG" then
		worldedit.items[name].start_i = tonumber(fields.set_sb_h:match(":(%d+)"))
		worldedit.show_page(name, "worldedit_gui_set")
		return true
	end

	if fields.worldedit_gui_set_filter and
	   worldedit.items[name].last_search ~= fields.worldedit_gui_set_filter:lower() then
	   	local filter = fields.worldedit_gui_set_filter:lower()
		worldedit.items[name].start_i = 0
		worldedit.items[name].filter = filter
		worldedit.items[name].last_search = filter
		worldedit.show_page(name, "worldedit_gui_set")
		return true
	end

	if fields.worldedit_gui_set_submit or fields.worldedit_gui_set_node then
		gui_nodename1[name] = tostring(fields.worldedit_gui_set_node)
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
	name = S("Replace Nodes"),
	privs = combine_we_privs({"replace", "replaceinverse"}),
	get_formspec = function(name)
		worldedit.items[name].current_page = "replace"
		local search, replace = gui_nodename1[name], gui_nodename2[name]
		local search_nodename, replace_nodename =
			worldedit.normalize_nodename(search), worldedit.normalize_nodename(replace)

		local start_i = worldedit.items[name].start_i or 0
		local filter = worldedit.items[name].filter or ""
		local width, height = 9, 3
		local items_list, inv_size = utils.get_items_list(start_i, filter, width, height, 0, 0.2)
		local ipp = width * height

		return "size[8,7]" .. worldedit.get_formspec_header("worldedit_gui_replace") ..
			items_list ..
			string.format("field[0.3,4.5;4,0.8;!worldedit_gui_replace_filter;" ..
				S("Search") .. ";%s]", minetest.formspec_escape(filter)) ..
			string.format("field[0.3,5.8;4,0.8;worldedit_gui_replace_node;" ..
				S("Replace") .. ";%s]", minetest.formspec_escape(search)) ..
			"scrollbar[4,4.25;3.6,0.5;horizontal;replace_sb_h;" ..
				start_i .. ",0," ..
				(inv_size - (inv_size % ipp)) .. "," ..
				ipp .. "," .. ipp .."," .. ipp ..
				";#999999;#777777;#FFFFFFFF;#808080FF]" ..
			string.format("field[4.3,5.8;4,0.8;worldedit_gui_replace_replace;" ..
				S("By") .. ";%s]", minetest.formspec_escape(replace)) ..
			"button_exit[1,6.5;3,0.8;worldedit_gui_replace_submit;" ..
				S("Replace Nodes") .. "]" ..
			"button_exit[4,6.5;3,0.8;worldedit_gui_replace_submit_inverse;" ..
				S("Replace Inverse") .. "]"
	end,
})

local replace_last = {}

worldedit.register_gui_handler("worldedit_gui_replace", function(name, fields)
	if utils.tablelen(fields) <= 3 then return end

	local continue = false
	for field in pairs(fields) do
		if field:find("worldedit") then
			continue = true
		end
	end

	for field in pairs(fields) do
		if continue and field:find(":") then
			local item = field:match("([%w_]+:[%w_]+)_inv")
			gui_nodename1[name] = item
			worldedit.show_page(name, "worldedit_gui_" .. worldedit.items[name].current_page)
			return true
		end
	end

	if fields.replace_sb_h and fields.replace_sb_h:sub(1,3) == "CHG" then
		worldedit.items[name].start_i = tonumber(fields.replace_sb_h:match(":(%d+)"))
		worldedit.show_page(name, "worldedit_gui_replace")
		return true
	end

	if fields.worldedit_gui_replace_filter and
	   worldedit.items[name].last_search ~= fields.worldedit_gui_replace_filter:lower() then
	   	local filter = fields.worldedit_gui_replace_filter:lower()
		worldedit.items[name].start_i = 0
		worldedit.items[name].filter = filter
		worldedit.items[name].last_search = filter
		worldedit.show_page(name, "worldedit_gui_replace")
		return true
	end

	if fields.worldedit_gui_replace_submit or fields.worldedit_gui_replace_submit_inverse then
		gui_nodename1[name] = tostring(fields.worldedit_gui_replace_node)
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
	name = S("Sphere / Dome"),
	form = true,
	privs = combine_we_privs({"hollowsphere", "sphere", "hollowdome", "dome"}),
	get_formspec = function(name)
		worldedit.items[name].current_page = "sphere_dome"
		local node, radius = gui_nodename1[name], gui_distance2[name]
		local nodename = worldedit.normalize_nodename(node)

		local start_i = worldedit.items[name].start_i or 0
		local filter = worldedit.items[name].filter or ""
		local width, height = 9, 3
		local items_list, inv_size = utils.get_items_list(start_i, filter, width, height, 0, 0.2)
		local ipp = width * height

		return "size[8,8]" .. worldedit.get_formspec_header("worldedit_gui_sphere_dome") ..
			string.format("field[0.3,4.5;4,0.8;!worldedit_gui_sphere_dome_filter;" ..
				S("Search") .. ";%s]", minetest.formspec_escape(filter)) ..
			items_list ..
			"scrollbar[4,4.25;3.6,0.5;horizontal;sphere_dome_sb_h;" ..
				start_i .. ",0," ..
				(inv_size - (inv_size % ipp)) .. "," ..
				ipp .. "," .. ipp .."," .. ipp ..
				";#999999;#777777;#FFFFFFFF;#808080FF]" ..
			string.format("field[0.3,5.7;3,0.8;worldedit_gui_sphere_dome_node;" ..
				S("Name") .. ";%s]", minetest.formspec_escape(node)) ..
			string.format("field[3.2,5.7;2,0.8;worldedit_gui_sphere_dome_radius;" ..
				S("Radius") .. ";%s]", minetest.formspec_escape(radius)) ..
			"button_exit[0.7,6.5;3,0.8;worldedit_gui_sphere_dome_submit_hollow;" ..
				S("Hollow Sphere") .. "]" ..
			"button_exit[4.2,6.5;3,0.8;worldedit_gui_sphere_dome_submit_solid;" ..
				S("Solid Sphere") .. "]" ..
			"button_exit[0.7,7.5;3,0.8;worldedit_gui_sphere_dome_submit_hollow_dome;" ..
				S("Hollow Dome") .. "]" ..
			"button_exit[4.2,7.5;3,0.8;worldedit_gui_sphere_dome_submit_solid_dome;"..
				S("Solid Dome") .. "]"
	end,
})

worldedit.register_gui_handler("worldedit_gui_sphere_dome", function(name, fields)
	if utils.tablelen(fields) <= 3 then return end

	local continue = false
	for field in pairs(fields) do
		if field:find("worldedit") then
			continue = true
		end
	end

	for field in pairs(fields) do
		if continue and field:find(":") then
			local item = field:match("([%w_]+:[%w_]+)_inv")
			gui_nodename1[name] = item
			worldedit.show_page(name, "worldedit_gui_" .. worldedit.items[name].current_page)
			return true
		end
	end

	if fields.sphere_dome_sb_h and fields.sphere_dome_sb_h:sub(1,3) == "CHG" then
		worldedit.items[name].start_i = tonumber(fields.sphere_dome_sb_h:match(":(%d+)"))
		worldedit.show_page(name, "worldedit_gui_sphere_dome")
		return true

	elseif fields.worldedit_gui_sphere_dome_filter and
	   worldedit.items[name].last_search ~= fields.worldedit_gui_sphere_dome_filter:lower() then
	   	local filter = fields.worldedit_gui_sphere_dome_filter:lower()
		worldedit.items[name].start_i = 0
		worldedit.items[name].filter = filter
		worldedit.items[name].last_search = filter
		worldedit.show_page(name, "worldedit_gui_sphere_dome")
		return true
	end

	if fields.worldedit_gui_sphere_dome_submit_hollow      or
	   fields.worldedit_gui_sphere_dome_submit_solid       or
	   fields.worldedit_gui_sphere_dome_submit_hollow_dome or
	   fields.worldedit_gui_sphere_dome_submit_solid_dome  then
		gui_nodename1[name] = tostring(fields.worldedit_gui_sphere_dome_node)
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
	name = S("Cylinder"),
	form = true,
	privs = combine_we_privs({"hollowcylinder", "cylinder"}),
	get_formspec = function(name)
		worldedit.items[name].current_page = "cylinder"
		local node, axis, length = gui_nodename1[name], gui_axis1[name], gui_distance1[name]
		local radius1, radius2 = gui_distance2[name], gui_distance3[name]
		local nodename = worldedit.normalize_nodename(node)

		local start_i = worldedit.items[name].start_i or 0
		local filter = worldedit.items[name].filter or ""
		local width, height = 9, 3
		local items_list, inv_size = utils.get_items_list(start_i, filter, width, height, 0, 0.2)
		local ipp = width * height

		return "size[8,8]" .. worldedit.get_formspec_header("worldedit_gui_cylinder") ..
			items_list ..
			string.format("field[0.3,4.5;4,0.8;!worldedit_gui_cylinder_filter;" ..
				S("Search") .. ";%s]", minetest.formspec_escape(filter)) ..
			string.format("field[0.3,5.6;4,0.8;worldedit_gui_cylinder_node;" ..
				S("Name") .. ";%s]", minetest.formspec_escape(node)) ..
			"scrollbar[4,4.25;3.6,0.5;horizontal;cylinder_sb_h;" ..
				start_i .. ",0," ..
				(inv_size - (inv_size % ipp)) .. "," ..
				ipp .. "," .. ipp .."," .. ipp ..
				";#999999;#777777;#FFFFFFFF;#808080FF]" ..
			string.format("field[0.3,6.9;2,0.8;worldedit_gui_cylinder_length;" ..
				S("Length") .. ";%s]", minetest.formspec_escape(length)) ..
			string.format("field[2.2,6.9;2,0.8;worldedit_gui_cylinder_radius1;"..
				S("Base Radius") .. ";%s]", minetest.formspec_escape(radius1)) ..
			string.format("field[4.1,6.9;2,0.8;worldedit_gui_cylinder_radius2;" ..
				S("Top Radius") .. ";%s]", minetest.formspec_escape(radius2)) ..
			string.format("dropdown[5.7,6.55;2.4;worldedit_gui_cylinder_axis;" ..
				S("X axis") .. "," .. S("Y axis") .. "," .. S("Z axis") .. "," ..
				S("Look direction") .. ";%d]", axis) ..
			"button_exit[1,7.5;3,0.8;worldedit_gui_cylinder_submit_hollow;" ..
				S("Hollow Cylinder") .. "]" ..
			"button_exit[4,7.5;3,0.8;worldedit_gui_cylinder_submit_solid;" ..
				S("Solid Cylinder") .. "]"
	end,
})

worldedit.register_gui_handler("worldedit_gui_cylinder", function(name, fields)
	if utils.tablelen(fields) <= 3 then return end

	local continue = false
	for field in pairs(fields) do
		if field:find("worldedit") then
			continue = true
		end
	end

	for field in pairs(fields) do
		if continue and field:find(":") then
			local item = field:match("([%w_]+:[%w_]+)_inv")
			gui_nodename1[name] = item
			worldedit.show_page(name, "worldedit_gui_" .. worldedit.items[name].current_page)
			return true
		end
	end

	if fields.cylinder_sb_h and fields.cylinder_sb_h:sub(1,3) == "CHG" then
		worldedit.items[name].start_i = tonumber(fields.cylinder_sb_h:match(":(%d+)"))
		worldedit.show_page(name, "worldedit_gui_cylinder")
		return true
	end

	if fields.worldedit_gui_cylinder_filter and
	   worldedit.items[name].last_search ~= fields.worldedit_gui_cylinder_filter:lower() then
	   	local filter = fields.worldedit_gui_cylinder_filter:lower()
		worldedit.items[name].start_i = 0
		worldedit.items[name].filter = filter
		worldedit.items[name].last_search = filter
		worldedit.show_page(name, "worldedit_gui_cylinder")
		return true
	end

	if fields.worldedit_gui_cylinder_submit_hollow or
	   fields.worldedit_gui_cylinder_submit_solid  then
	   	gui_nodename1[name] = tostring(fields.worldedit_gui_cylinder_node)
		gui_axis1[name] = worldedit.axis_indices[fields.worldedit_gui_cylinder_axis]
		gui_distance1[name] = tostring(fields.worldedit_gui_cylinder_length)
		gui_distance2[name] = tostring(fields.worldedit_gui_cylinder_radius1)
		gui_distance3[name] = tostring(fields.worldedit_gui_cylinder_radius2)

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
	name = S("Pyramid"),
	form = true,
	privs = we_privs("pyramid"),
	get_formspec = function(name)
		worldedit.items[name].current_page = "pyramid"
		local node, axis, length = gui_nodename1[name], gui_axis1[name], gui_distance1[name]
		local nodename = worldedit.normalize_nodename(node)

		local start_i = worldedit.items[name].start_i or 0
		local filter = worldedit.items[name].filter or ""
		local width, height = 9, 3
		local items_list, inv_size = utils.get_items_list(start_i, filter, width, height, 0, 0.2)
		local ipp = width * height

		return "size[8,7]" .. worldedit.get_formspec_header("worldedit_gui_pyramid") ..
			items_list ..
			string.format("field[0.3,4.5;4,0.8;!worldedit_gui_pyramid_filter;" ..
				S("Search") .. ";%s]", minetest.formspec_escape(filter)) ..
			string.format("field[0.3,5.8;3.5,0.8;worldedit_gui_pyramid_node;" ..
				S("Name") .. ";%s]", minetest.formspec_escape(node)) ..
			"scrollbar[4,4.25;3.6,0.5;horizontal;pyramid_sb_h;" ..
				start_i .. ",0," ..
				(inv_size - (inv_size % ipp)) .. "," ..
				ipp .. "," .. ipp .."," .. ipp ..
				";#999999;#777777;#FFFFFFFF;#808080FF]" ..
			string.format("field[3.8,5.8;2,0.8;worldedit_gui_pyramid_length;" ..
				S("Length") .. ";%s]", minetest.formspec_escape(length)) ..
			string.format("dropdown[5.5,5.45;2.5;worldedit_gui_pyramid_axis;" ..
				S("X axis") .. "," .. S("Y axis") .. "," .. S("Z axis") .. "," ..
				S("Look direction") .. ";%d]", axis) ..
			"button_exit[1,6.5;3,0.8;worldedit_gui_pyramid_submit_hollow;" ..
				S("Hollow Pyramid") .. "]" ..
			"button_exit[4,6.5;3,0.8;worldedit_gui_pyramid_submit_solid;" ..
				S("Solid Pyramid") .. "]"
	end,
})

worldedit.register_gui_handler("worldedit_gui_pyramid", function(name, fields)
	if utils.tablelen(fields) <= 3 then return end

	local continue = false
	for field in pairs(fields) do
		if field:find("worldedit") then
			continue = true
		end
	end

	for field in pairs(fields) do
		if continue and field:find(":") then
			local item = field:match("([%w_]+:[%w_]+)_inv")
			gui_nodename1[name] = item
			worldedit.show_page(name, "worldedit_gui_" .. worldedit.items[name].current_page)
			return true
		end
	end

	if fields.pyramid_sb_h and fields.pyramid_sb_h:sub(1,3) == "CHG" then
		worldedit.items[name].start_i = tonumber(fields.pyramid_sb_h:match(":(%d+)"))
		worldedit.show_page(name, "worldedit_gui_pyramid")
		return true
	end

	if fields.worldedit_gui_pyramid_filter and
	   worldedit.items[name].last_search ~= fields.worldedit_gui_pyramid_filter:lower() then
	   	local filter = fields.worldedit_gui_pyramid_filter:lower()
		worldedit.items[name].start_i = 0
		worldedit.items[name].filter = filter
		worldedit.items[name].last_search = filter
		worldedit.show_page(name, "worldedit_gui_pyramid")
		return true
	end

	if fields.worldedit_gui_pyramid_submit_solid  or
	   fields.worldedit_gui_pyramid_submit_hollow or
	   fields.worldedit_gui_pyramid_axis          then
		gui_nodename1[name] = tostring(fields.worldedit_gui_pyramid_node)
		gui_axis1[name] = axis_indices[fields.worldedit_gui_pyramid_axis]
		gui_distance1[name] = tostring(fields.worldedit_gui_pyramid_length)
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
	name = S("Spiral"),
	form = true,
	privs = we_privs("spiral"),
	get_formspec = function(name)
		worldedit.items[name].current_page = "spiral"
		local node, length, height, space =
			gui_nodename1[name], gui_distance1[name], gui_distance2[name], gui_distance3[name]
		local nodename = worldedit.normalize_nodename(node)

		local start_i = worldedit.items[name].start_i or 0
		local filter = worldedit.items[name].filter or ""
		local width, height = 9, 3
		local items_list, inv_size = utils.get_items_list(start_i, filter, width, height, 0, 0.2)
		local ipp = width * height

		return "size[8,8]" .. worldedit.get_formspec_header("worldedit_gui_spiral") ..
			items_list ..
			string.format("field[0.3,4.5;4,0.8;!worldedit_gui_spiral_filter;" ..
				S("Filter") .. ";%s]", minetest.formspec_escape(filter)) ..
			string.format("field[0.3,5.6;3.5,0.8;worldedit_gui_spiral_node;" ..
				S("Name") .. ";%s]", minetest.formspec_escape(node)) ..
			"scrollbar[4,4.25;3.6,0.5;horizontal;spiral_sb_h;" ..
				start_i .. ",0," ..
				(inv_size - (inv_size % ipp)) .. "," ..
				ipp .. "," .. ipp .."," .. ipp ..
				";#999999;#777777;#FFFFFFFF;#808080FF]" ..
			string.format("field[0.3,6.8;2,0.8;worldedit_gui_spiral_length;" ..
				S("Side Length") .. ";%s]", minetest.formspec_escape(length)) ..
			string.format("field[2.3,6.8;2,0.8;worldedit_gui_spiral_height;" ..
				S("Height") .. ";%s]", minetest.formspec_escape(height)) ..
			string.format("field[4.3,6.8;2,0.8;worldedit_gui_spiral_space;" ..
				S("Wall Spacing") .. ";%s]", minetest.formspec_escape(space)) ..
			"button_exit[2.5,7.5;3,0.8;worldedit_gui_spiral_submit;" .. S("Spiral") .. "]"
	end,
})

worldedit.register_gui_handler("worldedit_gui_spiral", function(name, fields)
	if utils.tablelen(fields) <= 3 then return end

	local continue = false
	for field in pairs(fields) do
		if field:find("worldedit") then
			continue = true
		end
	end

	for field in pairs(fields) do
		if continue and field:find(":") then
			local item = field:match("([%w_]+:[%w_]+)_inv")
			gui_nodename1[name] = item
			worldedit.show_page(name, "worldedit_gui_" .. worldedit.items[name].current_page)
			return true
		end
	end

	if fields.spiral_sb_h and fields.spiral_sb_h:sub(1,3) == "CHG" then
		worldedit.items[name].start_i = tonumber(fields.spiral_sb_h:match(":(%d+)"))
		worldedit.show_page(name, "worldedit_gui_spiral")
		return true
	end

	if fields.worldedit_gui_spiral_filter and
	   worldedit.items[name].last_search ~= fields.worldedit_gui_spiral_filter:lower() then
	   	local filter = fields.worldedit_gui_spiral_filter:lower()
		worldedit.items[name].start_i = 0
		worldedit.items[name].filter = filter
		worldedit.items[name].last_search = filter
		worldedit.show_page(name, "worldedit_gui_spiral")
		return true
	end

	if fields.worldedit_gui_spiral_submit then
		gui_nodename1[name] = tostring(fields.worldedit_gui_spiral_node)
		gui_distance1[name] = tostring(fields.worldedit_gui_spiral_length)
		gui_distance2[name] = tostring(fields.worldedit_gui_spiral_height)
		gui_distance3[name] = tostring(fields.worldedit_gui_spiral_space)

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
	name = S("Copy / Move"),
	privs = combine_we_privs({"copy", "move"}),
	get_formspec = function(name)
		local axis = gui_axis1[name] or 4
		local amount = gui_distance1[name] or "10"
		return "size[6.5,3]" .. worldedit.get_formspec_header("worldedit_gui_copy_move") ..
			string.format("field[0.5,1.5;4,0.8;worldedit_gui_copy_move_amount;" ..
				S("Amount") .. ";%s]", minetest.formspec_escape(amount)) ..
			string.format("dropdown[4,1.18;2.5;worldedit_gui_copy_move_axis;" ..
				S("X axis") .. "," .. S("Y axis") .. "," .. S("Z axis") .. "," ..
				S("Look direction") .. ";%d]", axis) ..
			"button_exit[0,2.5;3,0.8;worldedit_gui_copy_move_copy;" ..
				S("Copy Region") .. "]" ..
			"button_exit[3.5,2.5;3,0.8;worldedit_gui_copy_move_move;" ..
				S("Move Region") .. "]"
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
	name = S("Stack"),
	privs = we_privs("stack"),
	get_formspec = function(name)
		local axis, count = gui_axis1[name], gui_count1[name]
		return "size[6.5,3]" .. worldedit.get_formspec_header("worldedit_gui_stack") ..
			string.format("field[0.5,1.5;4,0.8;worldedit_gui_stack_count;" ..
				S("Count") .. ";%s]", minetest.formspec_escape(count)) ..
			string.format("dropdown[4,1.18;2.5;worldedit_gui_stack_axis;" ..
				S("X axis") .. "," .. S("Y axis") .. "," .. S("Z axis") .. "," ..
				S("Look direction") .. ";%d]", axis) ..
			"button_exit[0,2.5;3,0.8;worldedit_gui_stack_submit;" .. S("Stack") .. "]"
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
	name = S("Stretch"),
	privs = we_privs("stretch"),
	get_formspec = function(name)
		local stretchx, stretchy, stretchz = gui_count1[name], gui_count2[name], gui_count3[name]
		return "size[5,5]" .. worldedit.get_formspec_header("worldedit_gui_stretch") ..
			string.format("field[0.5,1.5;4,0.8;worldedit_gui_stretch_x;" ..
				S("Stretch X") .. ";%s]", minetest.formspec_escape(stretchx)) ..
			string.format("field[0.5,2.5;4,0.8;worldedit_gui_stretch_y;" ..
				S("Stretch Y") .. ";%s]", minetest.formspec_escape(stretchy)) ..
			string.format("field[0.5,3.5;4,0.8;worldedit_gui_stretch_z;" ..
				S("Stretch Z") .. ";%s]", minetest.formspec_escape(stretchz)) ..
			"button_exit[0,4.5;3,0.8;worldedit_gui_stretch_submit;" ..
				S("Stretch") .. "]"
	end,
})

worldedit.register_gui_handler("worldedit_gui_stretch", function(name, fields)
	if fields.worldedit_gui_stretch_submit then
		gui_count1[name] = tostring(fields.worldedit_gui_stretch_x)
		gui_count2[name] = tostring(fields.worldedit_gui_stretch_y)
		gui_count3[name] = tostring(fields.worldedit_gui_stretch_z)
		worldedit.show_page(name, "worldedit_gui_stretch")
		minetest.chatcommands["/stretch"].func(name,
			string.format("%s %s %s", gui_count1[name], gui_count2[name], gui_count3[name]))
		return true
	end
	return false
end)

worldedit.register_gui_function("worldedit_gui_transpose", {
	type = "advanced",
	name = S("Transpose"),
	privs = we_privs("transpose"),
	get_formspec = function(name)
		local axis1, axis2 = gui_axis1[name], gui_axis2[name]
		return "size[5.5,3]" .. worldedit.get_formspec_header("worldedit_gui_transpose") ..
			string.format("dropdown[0,1;2.5;worldedit_gui_transpose_axis1;"..
				S("X axis") .. "," .. S("Y axis") .. "," .. S("Z axis") .. "," ..
				S("Look direction") .. ";%d]", axis1) ..
			string.format("dropdown[3,1;2.5;worldedit_gui_transpose_axis2;" ..
				S("X axis") .. "," .. S("Y axis") .. "," .. S("Z axis") .. "," ..
				S("Look direction") .. ";%d]", axis2) ..
			"button_exit[0,2.5;3,0.8;worldedit_gui_transpose_submit;" ..
				S("Transpose") .. "]"
	end,
})

worldedit.register_gui_handler("worldedit_gui_transpose", function(name, fields)
	if fields.worldedit_gui_transpose_submit then
		gui_axis1[name] = axis_indices[fields.worldedit_gui_transpose_axis1]
		worldedit.show_page(name, "worldedit_gui_transpose")
		minetest.chatcommands["/transpose"].func(name, string.format("%s %s",
			axis_values[gui_axis1[name]], axis_values[gui_axis2[name]]))
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
	name = S("Flip"),
	privs = we_privs("flip"),
	get_formspec = function(name)
		local axis = gui_axis1[name]
		return "size[5,3]" .. worldedit.get_formspec_header("worldedit_gui_flip") ..
			string.format("dropdown[0,1;2.5;worldedit_gui_flip_axis;" ..
				S("X axis") .. "," .. S("Y axis") .. "," .. S("Z axis") .. "," ..
				S("Look direction") .. ";%d]", axis) ..
			"button_exit[0,2.5;3,0.8;worldedit_gui_flip_submit;" .. S("Flip") .. "]"
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
	name = S("Rotate"),
	privs = we_privs("rotate"),
	get_formspec = function(name)
		local axis, angle = gui_axis1[name], gui_angle[name]
		return "size[5.5,3]" .. worldedit.get_formspec_header("worldedit_gui_rotate") ..
			string.format("dropdown[0,1;2.5;worldedit_gui_rotate_angle;"..
				S("90 degrees") .. "," .. S("180 degrees") .. "," .. S("270 degrees") ..
				";%s]", angle) ..
			string.format("dropdown[2.5,1;3;worldedit_gui_rotate_axis;" ..
				S("X axis") .. "," .. S("Y axis") .. "," .. S("Z axis") .. "," ..
				S("Look direction") .. ";%d]", axis) ..
			"button_exit[0,2.5;3,0.8;worldedit_gui_rotate_submit;" .. S("Rotate") .. "]"
	end,
})

worldedit.register_gui_handler("worldedit_gui_rotate", function(name, fields)
	if fields.worldedit_gui_rotate_submit then
		gui_axis1[name] = axis_indices[fields.worldedit_gui_rotate_axis]
		gui_angle[name] = angle_indices[fields.worldedit_gui_rotate_angle]

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
	name = S("Orient"),
	privs = we_privs("orient"),
	get_formspec = function(name)
		local angle = gui_angle[name]
		return "size[5,3]" .. worldedit.get_formspec_header("worldedit_gui_orient") ..
			string.format("dropdown[0,1;2.5;worldedit_gui_orient_angle;" ..
				S("90 degrees") .. "," .. S("180 degrees") .. "," .. S("270 degrees") ..
				";%s]", angle) ..
			"button_exit[0,2.5;3,0.8;worldedit_gui_orient_submit;" .. S("Orient") .. "]"
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
	name = S("Fix Lighting"),
	privs = we_privs("fixlight"),
	on_select = function(name)
		minetest.chatcommands["/fixlight"].func(name, "")
	end,
})

worldedit.register_gui_function("worldedit_gui_hide", {
	type = "advanced",
	name = S("Hide Region"),
	privs = we_privs("hide"),
	on_select = function(name)
		minetest.chatcommands["/hide"].func(name, "")
	end,
})

worldedit.register_gui_function("worldedit_gui_suppress", {
	type = "default",
	name = S("Suppress Nodes"),
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
	name = S("Highlight Nodes"),
	privs = we_privs("highlight"),
	get_formspec = function(name)
		local node = gui_nodename1[name]
		local nodename = worldedit.normalize_nodename(node)
		return "size[6.5,3]" .. worldedit.get_formspec_header("worldedit_gui_highlight") ..
			string.format("field[0.5,1.5;4,0.8;worldedit_gui_highlight_node;" ..
				S("Name") .. ";%s]", minetest.formspec_escape(node)) ..
			"button[4,1.18;1.5,0.8;worldedit_gui_highlight_search;" .. S("Search") .. "]" ..
			formspec_node("5.5,1.1", nodename) ..
			"button_exit[0,2.5;3,0.8;worldedit_gui_highlight_submit;" ..
				S("Highlight Nodes") .. "]"
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

local function rm_schem(name)
	local file = io.popen("rm " .. worldpath .. "/schems/" .. name .. ".we")
	file:close()
end

worldedit.register_gui_function("worldedit_gui_save_load", {
	type = "default",
	name = S("Copy / Paste"),
	privs = combine_we_privs({"save", "allocate", "load"}),
	get_formspec = function(name)
		local filename = gui_filename[name]
		local schems = utils.scandir(worldpath .. "/schems", true)

		return "size[6,4]" .. worldedit.get_formspec_header("worldedit_gui_save_load") ..
			string.format("field[0.3,1.5;3,0.8;worldedit_gui_save_filename;" ..
				S("New building") .. ":;%s]", minetest.formspec_escape(filename)) ..
			"label[3,0.7;" .. S("Buildings") .. ":]" ..
			"dropdown[3,1.15;3;worldedit_dd_schems;" .. table.concat(schems, ",") .. ";1]" ..
			"button[0,2.5;3,0.8;worldedit_gui_save_load_submit_save;" .. S("Save") .. "]" ..
			"button_exit[3,2.5;3,0.8;worldedit_gui_save_load_submit_allocate;" ..
				S("Allocate") .. "]" ..
			"button_exit[0,3.5;3,0.8;worldedit_gui_save_load_submit_load;" .. S("Load") .. "]" ..
			"button[3,3.5;3,0.8;worldedit_gui_save_load_submit_delete;" .. S("Delete") .. "]"
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
	name = S("Cuboid"), -- technically the command is misnamed, I know...
	form = true,
	privs = combine_we_privs({"hollowcube", "cube"}),
	get_formspec = function(name)
		worldedit.items[name].current_page = "cube"
		local width, height, length = gui_distance1[name], gui_distance2[name], gui_distance3[name]
		local node = gui_nodename1[name]
		local nodename = worldedit.normalize_nodename(node)

		local start_i = worldedit.items[name].start_i or 0
		local filter = worldedit.items[name].filter or ""
		local width, height = 9, 3
		local items_list, inv_size = utils.get_items_list(start_i, filter, width, height, 0, 0.2)
		local ipp = width * height

		return "size[8,8]" .. worldedit.get_formspec_header("worldedit_gui_cube") ..
			items_list ..
			string.format("field[0.3,4.5;4,0.8;!worldedit_gui_cube_filter;" ..
				S("Filter") .. ";%s]", minetest.formspec_escape(filter)) ..
			string.format("field[0.3,5.7;3.5,0.8;worldedit_gui_cube_node;" ..
				S("Name") .. ";%s]", minetest.formspec_escape(node)) ..
			"scrollbar[4,4.25;3.6,0.5;horizontal;cube_sb_h;" ..
				start_i .. ",0," ..
				(inv_size - (inv_size % ipp)) .. "," ..
				ipp .. "," .. ipp .."," .. ipp ..
				";#999999;#777777;#FFFFFFFF;#808080FF]" ..
			string.format("field[0.3,6.8;2,1;worldedit_gui_cube_width;" ..
				S("Width") .. ";%s]", minetest.formspec_escape(width)) ..
			string.format("field[2.3,6.8;2,1;worldedit_gui_cube_height;" ..
				S("Height") .. ";%s]", minetest.formspec_escape(height)) ..
			string.format("field[4.3,6.8;2,1;worldedit_gui_cube_length;" ..
				S("Length") .. ";%s]", minetest.formspec_escape(length)) ..
			"button_exit[1,7.5;3,1;worldedit_gui_cube_submit_hollow;" ..
				S("Hollow Cuboid") .. "]" ..
			"button_exit[4,7.5;3,1;worldedit_gui_cube_submit_solid;" ..
				S("Solid Cuboid") .. "]"
	end,
})

worldedit.register_gui_handler("worldedit_gui_cube", function(name, fields)
	if utils.tablelen(fields) <= 3 then return end

	local continue = false
	for field in pairs(fields) do
		if field:find("worldedit") then
			continue = true
		end
	end

	for field in pairs(fields) do
		if continue and field:find(":") then
			local item = field:match("([%w_]+:[%w_]+)_inv")
			if gui_nodename1[name] == "" or
					(gui_nodename1[name] ~= "" and gui_nodename2[name] ~= "") then
				gui_nodename1[name] = item
				gui_nodename2[name] = ""
			else
				gui_nodename2[name] = item
			end

			worldedit.show_page(name, "worldedit_gui_" .. worldedit.items[name].current_page)
			return true
		end
	end

	if fields.cube_sb_h and fields.cube_sb_h:sub(1,3) == "CHG" then
		worldedit.items[name].start_i = tonumber(fields.cube_sb_h:match(":(%d+)"))
		worldedit.show_page(name, "worldedit_gui_cube")
		return true
	end

	if fields.worldedit_gui_cube_filter and
	   worldedit.items[name].last_search ~= fields.worldedit_gui_cube_filter:lower() then
	   	local filter = fields.worldedit_gui_cube_filter:lower()
		worldedit.items[name].start_i = 0
		worldedit.items[name].filter = filter
		worldedit.items[name].last_search = filter
		worldedit.show_page(name, "worldedit_gui_cube")
		return true
	end

	if fields.worldedit_gui_cube_submit_hollow or
	   fields.worldedit_gui_cube_submit_solid then
		gui_nodename1[name] = tostring(fields.worldedit_gui_cube_node)
		gui_distance1[name] = tostring(fields.worldedit_gui_cube_width)
		gui_distance2[name] = tostring(fields.worldedit_gui_cube_height)
		gui_distance3[name] = tostring(fields.worldedit_gui_cube_length)

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
				local args = string.format("%s %s %s %s",
					gui_distance1[name], gui_distance2[name], gui_distance3[name], n)
				minetest.chatcommands["/"..submit].func(name, args)
			end
		end

		return true
	end

	return false
end)

--[[
worldedit.register_gui_function("worldedit_gui_clearobjects", {
	type = "advanced",
	name = "Clear Objects",
	privs = we_privs("clearobjects"),
	on_select = function(name)
		minetest.chatcommands["/clearobjects"].func(name, "")
	end,
})
]]

worldedit.register_gui_function("worldedit_gui_undo", {
	type = "default",
	name = S("Cancel Action"),
	privs = we_privs("undo"),
	on_select = function(name)
		minetest.chatcommands["/undo"].func(name, "")
	end,
})

local function area_check_pos(pos1, pos2, name)
	if not pos1 then
		minetest.chat_send_player(name,
			minetest.colorize("#FF0000", S("ERROR: Missing position 1")))
		return false
	end

	if not pos2 then
		minetest.chat_send_player(name,
			minetest.colorize("#FF0000", S("ERROR: Missing position 2")))
		return false
	end

	return true
end

if minetest.get_modpath("areas") then
	local area_data = {}

	local function select_area(name, id)
		local data = area_data[name]
		if areas.areas[id] then
			data.area_id = id
			data.area_name = areas.areas[id].name
			data.name = areas.areas[id].owner
			data.timer = areas.areas[id].timer
			data.can_dig = areas.areas[id].can_dig
			data.can_place =  areas.areas[id].can_place
			data.kidsbot_mode =  areas.areas[id].kidsbot_mode
			data.pos1 = areas.areas[id].pos1
			data.pos2 = areas.areas[id].pos2
		else
			data.area_id = nil
			data.pos1 = nil
			data.pos2 = nil
		end
	end

	worldedit.register_gui_function("worldedit_gui_protect", {
		type = "default",
		name = S("Area Protection"),
		privs = {areas=true},
		get_formspec = function(name)
			area_data[name] = area_data[name] or {}
			local data = area_data[name]
			select_area(name, data.area_id)

			local area_idx
			local x = 1
			local names = S("<new area>")
			for k, v in pairs(areas.areas) do
				x = x + 1
				names = names .. "," .. v.name .. " \\[" .. k .. "\\] (" .. v.owner .. ")"

				if data.area_id == k then
					area_idx = x
				end
			end

			if not area_idx then
				area_idx = 1
				data.area_id = nil
				-- Default owner = me
				data.name = data.name or name
			end

			local area_name = data.area_name or ""
			local player_name = data.name or ""
			local timer = data.timer or ""
			local can_dig = data.can_dig == "true" and 2 or 1
			local can_place = data.can_place == "true" and 2 or 1
			local kidsbot_mode = data.kidsbot_mode == "free" and 2 or 1

			return "size[8,6.5]" .. worldedit.get_formspec_header("worldedit_gui_protect") ..
				string.format("field[0.3,1.4;4,1;worldedit_gui_protect_name;" ..
					S("Area name") .. ";%s]", minetest.formspec_escape(area_name)) ..
				string.format("field[4.3,1.4;4,1;worldedit_gui_protect_player_name;" ..
					S("Add owner") .. ";%s]", minetest.formspec_escape(player_name)) ..
				"label[0,2.1;" .. S("Areas:") .. "]" ..
				"dropdown[0,2.6;4.1;worldedit_gui_protect_areas;" ..
					names .. ";" .. area_idx .. "]" ..
				"field[4.3,2.82;4,1;worldedit_gui_protect_chrono;" ..
					S("Timer (seconds)") .. ";" .. timer .. "]" ..
				"label[0,3.5;" .. S("User actions:") .. "]" ..
				"dropdown[0,4;4.1;worldedit_gui_protect_can_dig;" ..
					S("User can not dig") .. "," .. S("User can dig") ..
					";" .. can_dig .. "]" ..
				"dropdown[0,4.8;4.1;worldedit_gui_protect_can_place;" ..
					S("User can not place") .. "," .. S("User can place") ..
					";" .. can_place .. "]" ..
				"label[4,3.5;" .. S("Kidsbot mode:") .. "]" ..
				"dropdown[4,4;4.1;worldedit_gui_protect_kidsbot_mode;" ..
					S("Free") .. "," .. S("Exercice") ..
					";" .. kidsbot_mode .. "]" ..
				(data.area_id and
					"button_exit[0,6;2.5,1;worldedit_gui_protect_remove;" .. S("Remove area") .. "]" ..
					"button_exit[2.66,6;2.5,1;worldedit_gui_protect_add_owner;" .. S("Confirm owner") .. "]" ..
					"button_exit[5.33,6;2.5,1;worldedit_gui_protect_submit;" .. S("Update Area") .. "]"
				or
					"button_exit[5.33,6;2.5,1;worldedit_gui_protect_submit;" .. S("Protect Area") .. "]"
				)
		end,
	})

	worldedit.register_gui_handler("worldedit_gui_protect", function(name, fields)
		area_data[name] = area_data[name] or {}
		local data = area_data[name]

		data.name = fields.worldedit_gui_protect_player_name
		data.area_name = fields.worldedit_gui_protect_name
		data.timer = fields.worldedit_gui_protect_chrono and
				(fields.worldedit_gui_protect_chrono:find("^%d+$")) and
				tonumber(fields.worldedit_gui_protect_chrono) or ""

		if fields.worldedit_gui_protect_submit then
			local update = data.area_id and areas.areas[data.area_id]

			if not update then
				data.pos1 = worldedit.pos1[name]
				data.pos2 = worldedit.pos2[name]
			end

			if not area_check_pos(data.pos1, data.pos2, name) then
				return false
			end

			if data.area_name == "" then
				minetest.chat_send_player(name,
					minetest.colorize("#FF0000", S("ERROR: Area name required")))
				return false
			end

			-- In case of update, remove old area before creating new one
			if update then
				areas:remove(data.area_id)
			end

			data.area_id = areas:add(table.copy(data))
			areas:save()

			minetest.chat_send_player(name,
					minetest.colorize("#FFFF00", update and
							S("Area '@1' has been updated.", data.area_name) or
							S("Area '@1' has been protected.", data.area_name)
					))
			worldedit.show_page(name, "worldedit_gui_protect")
			return true

		elseif fields.worldedit_gui_protect_add_owner then
			if not area_check_pos(data.pos1, data.pos2, name) then
				return false
			end

			if data.name == "" then
				minetest.chat_send_player(name,
					minetest.colorize("#FF0000", S("ERROR: Player name required")))
				return false
			end

			if not data.area_id or not areas.areas[data.area_id] then
				minetest.chat_send_player(name,
					minetest.colorize("#FF0000", S("ERROR: Select an area first")))
				return false
			end

			if data.name == areas.areas[data.area_id].owner then
				minetest.chat_send_player(name,
					minetest.colorize("#FF0000", S("ERROR: Another player name is required")))
				return false
			end

			data.area_id = areas:add(table.copy(data))
			areas:save()

			minetest.chat_send_player(name,
				minetest.colorize("#FFFF00",
					S("Player '@1' added to ownership of area '@2'",
						data.name, data.area_name)))

			worldedit.show_page(name, "worldedit_gui_protect")
			return true

		elseif fields.worldedit_gui_protect_remove then
			if data.area_id and areas.areas[data.area_id] then
				local area_name = areas.areas[data.area_id].name or ""
				areas:remove(data.area_id)
				areas:save()
				data.area_id = nil
				minetest.chat_send_player(name,
					minetest.colorize("#FFFF00",
						S("The area '@1' has been removed", area_name)))
			else
				minetest.chat_send_player(name,
					minetest.colorize("#FF0000", S("ERROR: Select an area first")))
			end

			worldedit.show_page(name, "worldedit_gui_protect")
			return true

		elseif fields.worldedit_gui_protect_areas then
			select_area(name,
				tonumber(fields.worldedit_gui_protect_areas:match("%[(%d+)%]%s%(")))
			worldedit.show_page(name, "worldedit_gui_protect")
			return true

		elseif fields.worldedit_gui_protect_can_dig then
			data.can_dig =
					fields.worldedit_gui_protect_can_dig == S("User can dig")
					and 'true' or nil
			worldedit.show_page(name, "worldedit_gui_protect")
			return true

		elseif fields.worldedit_gui_protect_can_place then
			data.can_place =
					fields.worldedit_gui_protect_can_place == S("User can place")
					and 'true' or nil
			worldedit.show_page(name, "worldedit_gui_protect")
			return true

		elseif fields.worldedit_gui_protect_kidsbot_mode then
			data.kidsbot_mode =
					fields.worldedit_gui_protect_kidsbot_mode == S("Free")
					and 'free' or 'exercice'
			worldedit.show_page(name, "worldedit_gui_protect")
			return true
		end

		return false
	end)
end
