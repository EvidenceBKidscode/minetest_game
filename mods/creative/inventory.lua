local fmt = string.format
-- creative/inventory.lua

-- support for MT game translation.
local S = creative.get_translator

local player_inventory = {}
local inventory_cache = {}

local function init_creative_cache(items)
	inventory_cache[items] = {}
	local i_cache = inventory_cache[items]

	for name, def in pairs(items) do
		if def.groups.not_in_creative_inventory ~= 1 and
				def.description and def.description ~= "" then
			i_cache[name] = def
		end
	end

	table.sort(i_cache)
	return i_cache
end

function creative.init_creative_inventory(player)
	local pname = player:get_player_name()
	player_inventory[pname] = {
		size = 0,
		filter = "",
		start_i = 0,
		old_filter = nil, -- use only for caching in update_creative_inventory
		old_content = nil
	}

	minetest.create_detached_inventory("creative_" .. pname, {
		allow_move = function(inv, from_list, from_index, to_list, to_index, count, player2)
			local name = player2 and player2:get_player_name() or ""
			if not creative.is_enabled_for(name) or
					to_list == "main" then
				return 0
			end
			return count
		end,
		allow_put = function(inv, listname, index, stack, player2)
			return 0
		end,
		allow_take = function(inv, listname, index, stack, player2)
			local name = player2 and player2:get_player_name() or ""
			if not creative.is_enabled_for(name) then
				return 0
			end
			return -1
		end,
		on_move = function(inv, from_list, from_index, to_list, to_index, count, player2)
		end,
		on_take = function(inv, listname, index, stack, player2)
			if stack and stack:get_count() > 0 then
				minetest.log("action", pname .. " takes " .. stack:get_name().. " from creative inventory")
			end
		end,
	}, pname)

	return player_inventory[pname]
end

local NO_MATCH = 999
local function match(s, filter)
	if filter == "" then
		return 0
	end
	if s:lower():find(filter, 1, true) then
		return #s - #filter
	end
	return NO_MATCH
end

local function description(def, lang_code)
	local s = def.description
	if lang_code then
		s = minetest.get_translated_string(lang_code, s)
	end
	return s:gsub("\n.*", "") -- First line only
end

-->> KIDSCODE - Allow to merge lists of content
local function table_concat(...)
	local args = {...}
	local t1 = args[1]

	for i = 2, #args do
		local T = args[i]
		for k, v in pairs(T) do
			t1[k] = v
		end
	end

	return t1
end
--<< KIDSCODE - Allow to merge lists of content

function creative.update_creative_inventory(pname, tab_content,
		drawtype, group) -- KIDSCODE filter on drawtype and/or groups

	-- >> KIDSCODE - Search on translated string
	local lang_code = minetest.get_player_information(pname).lang_code
	-- << KIDSCODE - Search on translated string

	local inv = player_inventory[pname] or
		creative.init_creative_inventory(minetest.get_player_by_name(pname))

	-- >> KIDSCODE - Allow to merge lists of content
	if tab_content and #tab_content > 1 then
		tab_content = table_concat(unpack(tab_content))
	end
	-- << KIDSCODE - Allow to merge lists of content

	if inv.filter == inv.old_filter and tab_content == inv.old_content
		and inv.old_drawtype == drawtype and inv.old_group == group then -- KIDSCODE filter on drawtype and/or groups
		return
	end
	inv.old_filter = inv.filter
	inv.old_content = tab_content
	inv.old_drawtype = drawtype -- KIDSCODE filter on drawtype and/or groups
	inv.old_group = group -- KIDSCODE filter on drawtype and/or groups

	local items = inventory_cache[tab_content] or init_creative_cache(tab_content)

	local lang
	local player_info = minetest.get_player_information(pname)
	if player_info and player_info.lang_code ~= "" then
		lang = player_info.lang_code
	end

	local creative_list = {}
	local order = {}
	for name, def in pairs(items) do
		local m = match(description(def), inv.filter)
		if m > 0 then
			m = math.min(m, match(description(def, lang), inv.filter))
		end
		if m > 0 then
			m = math.min(m, match(name, inv.filter))
		end

		-->> KIDSCODE filter on drawtype and/or groups
		if  m < NO_MATCH and (not drawtype or def.drawtype == drawtype) and
				(not group or def.groups[group]) then
		-- if m < NO_MATCH then
		--<< KIDSCODE filter on drawtype and/or groups
			creative_list[#creative_list+1] = name
			-- Sort by match value first so closer matches appear earlier
			order[name] = string.format("%02d", m) .. name
		end
	end

	table.sort(creative_list, function(a, b) return order[a] < order[b] end)

	inv.items = creative_list
	inv.size = #creative_list
end

-- Create the trash field
local trash = minetest.create_detached_inventory("creative_trash", {
	-- Allow the stack to be placed and remove it in on_put()
	-- This allows the creative inventory to restore the stack
	allow_put = function(_, _, _, stack)
		return stack:get_count()
	end,
	on_put = function(inv, listname)
		inv:set_list(listname, {})
	end,
})
trash:set_size("main", 1)

creative.formspec_add = ""

function creative.register_tab(tabname, image, title, items, drawtype, group)
	sfinv.register_page("creative:" .. tabname, {
		image = image,
		title = title,
		dir = "top",
		is_in_nav = function(self, player, context)
			local pname = player:get_player_name()

			return minetest.settings:get_bool("allow_building") or
				minetest.check_player_privs(pname, "teacher")
		end,

		get = function(self, player, context)
			local pname = player:get_player_name()
			creative.update_creative_inventory(pname, items, drawtype, group)
			local inv = player_inventory[pname]
			local fs = {}

			 fs[#fs + 1] =
				"label[0,-0.1;" .. title .. "]" .. [[
				listcolors[#00000069;#c0d3e1;#141318;#30434C;#FFF]
				list[current_player;main;0,7.8;7,1;0;0.2,0.0;1.0]
				image[7.06,7.9;0.8,0.8;creative_trash_icon.png]
				list[detached:creative_trash;main;7,7.8;1,1;]
				listring[]
				listring[current_player;main]
			]]

			if tabname == "storage" then
				 fs[#fs + 1] = [[
					image[0.3,0.8;9,3;kidscode_logo.png]
					list[current_player;main;0,4.5;8,3;8]
				]] ..
				"button[5,3.5;3,1;trash_all;" .. S("Trash All") .. ";#88acc5]"
			else
				local start_i = inv.start_i or 0

				 fs[#fs + 1] =
				 	"style_type[item_image_button;border=false;bgimg_hovered=creative_selected.png;bgimg_pressed=creative_selected.png]" ..
					"scroll_container[0,0.8;9.2," ..
						(tabname == "search" and 7.4 or 8.4) .. ";sb_v;vertical]" ..
					"scrollbaroptions[max=" .. ((#inv.items / 7) * 10 - 60) .. "]"

				for i = 0, #inv.items do
					local item = inv.items[i + 1]
					if not item then break end

					local cuttable_nodes = workbench and workbench.nodes[item]
					local O = 0

					if cuttable_nodes then
						for j = 1, #workbench.nodes[item] do
							local it = workbench.nodes[item][j]
							if minetest.registered_items[it] then
								O = O + 1
							end
						end
					end

					local more_items =
						(item ~= inv.items[i] and cuttable_nodes and O > 1) and
						"\n\n\t\t\t\t\t" or ""

					if more_items ~= "" then
						more_items = more_items ..
							(workbench.nodes[item].state and "-" or "+")
					end

					local X = i % 8
					local Y = (i - X) / 8
					X = X - (X * 0.12)
					Y = Y - (Y * 0.02)

					 fs[#fs + 1] =
						fmt("item_image_button[%f,%f;1,1;%s;%s_inv#%u;%s]",
							X, Y, item, item, i + 1, more_items)
				end

				 fs[#fs + 1] =
					"scroll_container_end[]" ..
					fmt("scrollbar[7.23,0.4;0.6,7.18;vertical;sb_v;%u]", start_i)
			end

			if tabname == "search" then
				 fs[#fs + 1] =
					"field[0.3,7.15;7.17,1;!creative_filter;;" ..
						minetest.formspec_escape(inv.filter) .. "]"
			end

			return sfinv.make_formspec(player, context, table.concat(fs), false)
			--<< KIDSCODE - Specific inventory
		end,

		on_enter = function(self, player, context)
			local pname = player:get_player_name()
			local inv = player_inventory[pname]
			if inv then
				inv.start_i = 0
			end
		end,

		on_player_receive_fields = function(self, player, context, fields)
			if self.name ~= "creative:" .. tabname then return end
		--	print(dump(fields))

			local pname = player:get_player_name()
			local inv = player_inventory[pname]
			local player_inv = player:get_inventory()
			local is_teacher = minetest.check_player_privs(pname, "teacher")
			assert(inv)

			if fields.sfinv_nav_tabs and workbench then
				for _, item in ipairs(inv.items) do
					if workbench.nodes[item] and workbench.nodes[item].state then
						workbench.nodes[item].state = nil
					end
				end
			end

			if self.name ~= "creative:search" then
				inv.filter = ""
				creative.update_creative_inventory(pname, items, drawtype, group)
				sfinv.set_player_inventory_formspec(player, context)
			end

			-->> KIDSCODE - Search on every key press
			if fields.creative_filter and
					fields.creative_filter ~= (inv.last_search or "") then
				inv.start_i = 0
				inv.filter = fields.creative_filter:lower()
				inv.last_search = inv.filter
				creative.update_creative_inventory(pname, items, drawtype, group)
				sfinv.set_player_inventory_formspec(player, context)
			--<< KIDSCODE - Search on every key press

			elseif fields.trash_all then
				player_inv:set_list("main", {})

			else
				for item in pairs(fields) do
					if item:find(":") then
						local utils_installed = minetest.get_modpath("utils")
						local sandbox = utils_installed and
								utils.worldname:sub(1,6) == "build_"

						if not is_teacher and (utils_installed and not sandbox) then
							if utils_installed and
							  (utils.worldname == "coding_schools" or
							   utils.worldname == "science_factory") then
							       minetest.chat_send_player(pname,
									minetest.colorize("#FF0000",
										S("ERROR: You cannot use any other item " ..
										"on this map except the kidsbot")))
							else
								minetest.chat_send_player(pname,
									minetest.colorize("#FF0000",
										S("ERROR: Privilege 'mapmaker' or 'teacher'" ..
										" required to get this item")))
							end

							return
						end

						local idx = tonumber(item:match("#(%d+)"))
						local expand = fields[item]:find"%+"
						local sign = fields[item]:find"\9"

						if item:find("_inv#%d+") then
							item = item:match("(.*)_inv")
						end

						if not sign then
							local stack = ItemStack(item)
							player_inv:add_item("main", item .. " " .. stack:get_stack_max())
						end

						if workbench and workbench.nodes[item] and sign then
							if expand then
								workbench.nodes[item].state = true

								local i = 1
								for _, add_item in pairs(workbench.nodes[item]) do
									if minetest.registered_items[add_item] then
										table.insert(inv.items, idx + i, add_item)
										i = i + 1
									end
								end
							else
								workbench.nodes[item].state = false

								for i = 13, 1, -1 do
									table.remove(inv.items, idx + i)
								end
							end

							inv.start_i = tonumber(string.match(fields.sb_v, "%d+"))
							sfinv.set_player_inventory_formspec(player, context)
						end
					end
				end
			end
		end
	})
end

-->> KIDSCODE - Specific inventory

creative.register_tab("storage",
	"tab_storage.png@0.8",
	S("Storage"),
	{}
)

creative.register_tab("nodes",
	"tab_building.png@0.8",
	S("Building Blocks"),
	minetest.registered_nodes,
	nil,
	"building"
)

creative.register_tab("decoration",
	"allium.png@0.8",
	S("Decoration Blocks"),
	minetest.registered_nodes,
	nil,
	"decoration"
)

creative.register_tab("items",
	"screwdriver.png@0.8",
	S("Items & Tools"),
	{ minetest.registered_tools, minetest.registered_craftitems }
)

creative.register_tab("interactive",
	"tab_mods.png@0.8",
	S("Interactive"),
	minetest.registered_items,
	nil,
	"interactive"
)

creative.register_tab("search",
	"tab_shelf.png@0.8",
	S("Search Items"),
	minetest.registered_items
)
--[[
-- Sort registered items
local registered_nodes = {}
local registered_tools = {}
local registered_craftitems = {}

minetest.register_on_mods_loaded(function()
	for name, def in pairs(minetest.registered_items) do
		local group = def.groups or {}

		local nogroup = not (group.node or group.tool or group.craftitem)
		if group.node or (nogroup and minetest.registered_nodes[name]) then
			registered_nodes[name] = def
		elseif group.tool or (nogroup and minetest.registered_tools[name]) then
			registered_tools[name] = def
		elseif group.craftitem or (nogroup and minetest.registered_craftitems[name]) then
			registered_craftitems[name] = def
		end
	end
end)

creative.register_tab("all", S("All"), minetest.registered_items)
creative.register_tab("nodes", S("Nodes"), registered_nodes)
creative.register_tab("tools", S("Tools"), registered_tools)
creative.register_tab("craftitems", S("Items"), registered_craftitems)
--]]

--<< KIDSCODE - Specific inventory

--[[ TODO:CHECK
local old_homepage_name = sfinv.get_homepage_name
function sfinv.get_homepage_name(player)
	if creative.is_enabled_for(player:get_player_name()) then
		return "creative:storage" -- KIDSCODE - Specific inventory
		-- return "creative:all"
	else
		return old_homepage_name(player)
	end
end
]]
