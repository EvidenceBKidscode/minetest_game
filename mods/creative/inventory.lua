local S = utils.gettext
local player_inventory = {}
local ipp = 8*8

function creative.init_creative_inventory(player_name)
	player_inventory[player_name] = {
		size = 0,
		filter = "",
		start_i = 0,
		last_search = "",
	}

	return player_inventory[player_name]
end

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

function creative.update_creative_inventory(player_name, tab_content, drawtype, group)
	local creative_list = {}
	local inv = player_inventory[player_name] or
		creative.init_creative_inventory(player_name)

	if tab_content and #tab_content > 1 then
		tab_content = table_concat(unpack(tab_content))
	end

	local filter = inv.filter:lower()

	for name, def in pairs(tab_content or {}) do
		if not (def.groups.not_in_creative_inventory == 1)      and
		   def.description and def.description ~= ""	        and
		  ((not drawtype and true or def.drawtype == drawtype)) and
		  ((not group    and true or def.groups[group]))        and
		  (def.name:find(filter, 1, true)                       or
		   def.description:lower():find(filter, 1, true))       then
			creative_list[#creative_list + 1] = name
		end
	end

	inv.size = #creative_list
	table.sort(creative_list)
	return creative_list
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

function creative.register_tab(name, image, title, items, drawtype, group)
	sfinv.register_page("creative:" .. name, {
		image = image,
		title = title,
		dir = "top",
		is_in_nav = function(self, player, context)
			return creative.is_enabled_for(player:get_player_name())
		end,

		get = function(self, player, context)
			local player_name = player:get_player_name()
			local inv_items =
				creative.update_creative_inventory(player_name, items, drawtype, group)
			local inv = player_inventory[player_name] or
				creative.init_creative_inventory(player_name)

			local formspec =
				"label[0,-0.1;" .. title .. "]" .. [[
				listcolors[#00000069;#c0d3e1;#141318;#30434C;#FFF]
				list[current_player;main;0,7.8;8,1;0;0.2,0.0;1.0]
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
				local start_i = inv.start_i or 0
				local pagenum = math.floor(start_i / ipp + 1)

				formspec = formspec ..
					"scrollbaroptions[min=0,max=" ..
					(inv.size - (inv.size % ipp)) ..
					",smallstep=" .. ipp .. ",largestep=" .. ipp .."]"
					"scrollbar[7.23,0.4;0.6,7.18;vertical;sb_v;" ..
						inv.start_i .. ";#c0d3e1;#88acc5;#FFFFFFFF;#808080FF]"

				if name == "search" then
					ipp = 8*7
				else
					ipp = 8*8
				end

				local first_item = (pagenum - 1) * ipp
				for i = first_item, first_item + ipp - 1 do
					local item_name = inv_items[i + 1]
					if not item_name then break end
					local X = i % 8
					local Y

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
							item_name .. ";" .. item_name .. "_inv;;#c0d3e1]"
				end
			end

			if name == "search" then
				formspec = formspec ..
					"field[0.3,7.15;7.17,1;!creative_filter;;" ..
						minetest.formspec_escape(inv.filter) .. "]"
			end

			return sfinv.make_formspec(player, context, formspec, false)
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
			local player_name = player:get_player_name()
			local inv = player_inventory[player_name]
			local player_inv = player:get_inventory()
			local is_mapmaker = minetest.check_player_privs(player_name, "mapmaker")
			local is_teacher = minetest.check_player_privs(player_name, "teacher")
			assert(inv)

			if self.name ~= "creative:search" then
				inv.filter = ""
				creative.update_creative_inventory(player_name, items, drawtype, group)
				sfinv.set_player_inventory_formspec(player, context)
			end

			if fields.creative_filter and
					player_inventory[player_name].last_search ~=
			   		fields.creative_filter then
				inv.start_i = 0
				inv.filter = fields.creative_filter
				player_inventory[player_name].last_search = inv.filter

				creative.update_creative_inventory(player_name, items, drawtype, group)
				sfinv.set_player_inventory_formspec(player, context)

			elseif fields.sb_v and fields.sb_v:sub(1,3) == "CHG" then
				inv.start_i = tonumber(fields.sb_v:match(":(%d+)"))
				sfinv.set_player_inventory_formspec(player, context)

			elseif fields.trash_all then
				player_inv:set_list("main", {})

			else for item in pairs(fields) do
				  if item:find(":") then
				  	local utils_installed = minetest.get_modpath("utils")
				  	local sandbox = utils_installed and
				  			utils.worldname:sub(1,6) == "build_"

				  	if not is_mapmaker and not is_teacher and
				  	  (utils_installed and not sandbox) then
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

					if item:sub(-4) == "_inv" then
						item = item:sub(1,-5)
					end

					local stack = ItemStack(item)
					player_inv:add_item("main",
						item .. " " .. stack:get_stack_max())
				  end
			     end
			end
		end
	})
end

minetest.register_on_joinplayer(function(player)
	creative.update_creative_inventory(
		player:get_player_name(), minetest.registered_items)
end)

creative.register_tab("storage",
	"tab_storage.png@0.8",
	S("Storage")
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
	{minetest.registered_tools, minetest.registered_craftitems}
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

local old_homepage_name = sfinv.get_homepage_name
function sfinv.get_homepage_name(player)
	if creative.is_enabled_for(player:get_player_name()) then
		return "creative:nodes"
	else
		return old_homepage_name(player)
	end
end
