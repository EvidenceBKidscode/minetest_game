local ipp = 8*8
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
	local player_name = player:get_player_name()
	player_inventory[player_name] = {
		size = 0,
		filter = "",
		start_i = 0,
		old_filter = nil, -- use only for caching in update_creative_inventory
		old_content = nil
	}

	minetest.create_detached_inventory("creative_" .. player_name, {
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
				minetest.log("action", player_name .. " takes " .. stack:get_name().. " from creative inventory")
			end
		end,
	}, player_name)

	return player_inventory[player_name]
end

local function match(s, filter)
	if filter == "" then
		return 0
	end
	if s:lower():find(filter, 1, true) then
		return #s - #filter
	end
	return nil
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

function creative.update_creative_inventory(player_name, tab_content,
		drawtype, group) -- KIDSCODE filter on drawtype and/or groups

	-- >> KIDSCODE - Search on translated string
	local lang_code = minetest.get_player_information(player_name).lang_code
	-- << KIDSCODE - Search on translated string

	local inv = player_inventory[player_name] or
		creative.init_creative_inventory(minetest.get_player_by_name(player_name))

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

	local creative_list = {}
	local order = {}
	for name, def in pairs(items) do
		local description = minetest.get_translated_string(
			lang_code, def.description) -- KIDSCODE - Search on translated string
		local m = match(def.description, inv.filter) or match(def.name, inv.filter)
			or match(description, inv.filter) -- KIDSCODE - Search on translated string

		-->> KIDSCODE filter on drawtype and/or groups
		if m and (not drawtype or def.drawtype == drawtype) and
				(not group or def.groups[group]) then
		-- if m then
		--<< KIDSCODE filter on drawtype and/or groups
			creative_list[#creative_list+1] = name
			-- Sort by description length first so closer matches appear earlier
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

function creative.register_tab(name, image, title, items, drawtype, group)
	sfinv.register_page("creative:" .. name, {
		image = image,
		title = title,
		dir = "top",
		is_in_nav = function(self, player, context)
			local pname = player:get_player_name()

			return minetest.settings:get_bool("allow_building") or
				minetest.check_player_privs(pname, "teacher")
		end,

		get = function(self, player, context)
			local player_name = player:get_player_name()
			creative.update_creative_inventory(player_name, items, drawtype, group)
			local inv = player_inventory[player_name]

			local formspec =
				"label[0,-0.1;" .. title .. "]" .. [[
				listcolors[#00000069;#c0d3e1;#141318;#30434C;#FFF]
				list[current_player;main;0,7.8;7,1;0;0.2,0.0;1.0]
				image[7.06,7.9;0.8,0.8;creative_trash_icon.png]
				list[detached:creative_trash;main;7,7.8;1,1;]
				listring[]
				listring[current_player;main]
			]]

			if name == "storage" then
				formspec = formspec .. [[
					image[0.3,0.8;9,3;kidscode_logo.png]
					list[current_player;main;0,4.5;8,3;8]
				]] ..
				"button[5,3.5;3,1;trash_all;" .. S("Trash All") .. ";#88acc5]"
			else
				ipp = name == "search" and 8*7 or 8*8
				local start_i = inv.start_i or 0

				formspec = formspec ..
					"scrollbaroptions[min=0;max=" ..
						(inv.size - (inv.size % ipp)) ..
						";smallstep=" .. ipp .. ";largestep=" .. ipp .. "]" ..
					"scrollbar[7.23,0.4;0.6,7.18;vertical;sb_v;" ..
						inv.start_i .. ";#c0d3e1;#88acc5;#FFFFFFFF;#808080FF]"
				
				local first_item = inv.start_i
				local last_item = (inv.start_i + ipp) - 1
				print("first_item", first_item)
				print("last_item", last_item)
				print()

				for i = first_item, last_item do
					local item = inv.items[i + 1]
					print(item)
					if not item then break end

					local cuttable_nodes = workbench and workbench.nodes[item]
					local O = 0

					if cuttable_nodes then
						for _, it in ipairs(workbench.nodes[item]) do
							if minetest.registered_items[it] then
								O = O + 1
							end
						end
					end

					local more_items =
						(item ~= inv.items[i] and cuttable_nodes and O > 1) and
						"\n\n\t\t\t\t\t" or ""

					if more_items ~= "" then
						if workbench.nodes[item].state then
							more_items = more_items .. "-"
						else
							more_items = more_items .. "+"
						end
					end

					local X, Y = i % 8

					if name == "search" then
						Y = (i % ipp - X) / 7 + 1
					else
						Y = (i % ipp - X) / 8 + 1
					end

					formspec = formspec ..
						"item_image_button[" ..
							(X - (X * 0.12)) .. "," ..
							((Y - (name == "search" and 0.4 or 0.5)) -
							 (Y * (name == "search" and 0.2 or 0.1))) ..
							";1,1;" ..
							item .. ";" .. item .. "_inv#" .. (i + 1) ..
							";" .. more_items .. ";#c0d3e1]"
				end
			end

			if name == "search" then
				formspec = formspec ..
					"field[0.3,7.15;7.17,1;!creative_filter;;" ..
						minetest.formspec_escape(inv.filter) .. "]"
			end

			return sfinv.make_formspec(player, context, formspec, false)
			--<< KIDSCODE - Specific inventory
		end,

		on_enter = function(self, player, context)
			local player_name = player:get_player_name()
			local inv = player_inventory[player_name]
			if inv then
				inv.start_i = 0
			end
		end,

		on_player_receive_fields = function(self, player, context, fields)
			if self.name ~= "creative:" .. name then return end
			--print(dump(fields))

			ipp = name == "search" and 8*7 or 8*8
			local player_name = player:get_player_name()
			local inv = player_inventory[player_name]
			local player_inv = player:get_inventory()
			local is_teacher = minetest.check_player_privs(player_name, "teacher")
			assert(inv)

			if self.name ~= "creative:search" then
				inv.filter = ""
				creative.update_creative_inventory(player_name, items, drawtype, group)
				sfinv.set_player_inventory_formspec(player, context)
			end

			-->> KIDSCODE - Search on every key press
			if fields.creative_filter and
					fields.creative_filter ~= (inv.last_search or "") then
				inv.start_i = 0
				inv.filter = fields.creative_filter:lower()
				inv.last_search = inv.filter
				creative.update_creative_inventory(player_name, items, drawtype, group)
				sfinv.set_player_inventory_formspec(player, context)
			--<< KIDSCODE - Search on every key press

			-->> KIDSCODE - Manage scrollbar instead of buttons
			elseif fields.sb_v and fields.sb_v:sub(1,3) == "CHG" then
				local start_i = tonumber(fields.sb_v:match(":(%d+)"))
				if math.floor(start_i / ipp + 1) ~= math.floor(inv.start_i / ipp + 1) then
					inv.start_i = start_i
					sfinv.set_player_inventory_formspec(player, context)
				end
			--<< KIDSCODE - Manage scrollbar instead of buttons

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
							       minetest.chat_send_player(player_name,
									minetest.colorize("#FF0000",
										S("ERROR: You cannot use any other item " ..
										"on this map except the kidsbot")))
							else
								minetest.chat_send_player(player_name,
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
								print()
								print("clicked:", idx)
								workbench.nodes[item].state = true

								local i = 1
								for _, add_item in pairs(workbench.nodes[item]) do
									if minetest.registered_items[add_item] then
										print("insert to:", idx + i)
										table.insert(inv.items, idx + i, add_item)
										i = i + 1
									end
								end

								if idx + #workbench.nodes[item] > inv.start_i + ipp then
									inv.start_i = inv.start_i + #workbench.nodes[item]
								end
							else
								workbench.nodes[item].state = false
								inv.start_i = inv.start_i - #workbench.nodes[item]

								for i = 13, 1, -1 do
									table.remove(inv.items, idx + i)
								end
							end

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
creative.register_tab("all", S("All"), minetest.registered_items)
creative.register_tab("nodes", S("Nodes"), minetest.registered_nodes)
creative.register_tab("tools", S("Tools"), minetest.registered_tools)
creative.register_tab("craftitems", S("Items"), minetest.registered_craftitems)
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
