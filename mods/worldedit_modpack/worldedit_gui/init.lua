worldedit = worldedit or {}
local S = minetest.get_translator("worldedit_gui")

--[[
Example:

    worldedit.register_gui_function("worldedit_gui_hollow_cylinder", {
    	name = "Make Hollow Cylinder",
    	privs = {worldedit=true},
    	get_formspec = function(name) return "some formspec here" end,
    	on_select = function(name) print(name .. " clicked the button!") end,
    })

Use `nil` for the `options` parameter to unregister the function associated with the given identifier.

Use `nil` for the `get_formspec` field to denote that the function does not have its own screen.

The `privs` field may not be `nil`.

If the identifier is already registered to another function, it will be replaced by the new one.

The `on_select` function must not call `worldedit.show_page`
]]

worldedit.pages = {} --mapping of identifiers to options
worldedit.items = {}

local identifiers = {} --ordered list of identifiers
local mode = {}

minetest.register_on_joinplayer(function(player)
	local name = player:get_player_name()
	mode[name] = "advanced"
	worldedit.items[name] = {}

	local is_teacher = minetest.check_player_privs(name, "teacher")
	local privs = minetest.get_player_privs(name)
	privs.worldedit = true

	if is_teacher then
		minetest.set_player_privs(name, privs)
	end
end)

worldedit.register_gui_function = function(identifier, options)
	if options.privs == nil or next(options.privs) == nil then
		error("privs unset")
	end

	worldedit.pages[identifier] = options
	table.insert(identifiers, identifier)
end

--[[
Example:

    worldedit.register_gui_handler("worldedit_gui_hollow_cylinder", function(name, fields)
    	print(minetest.serialize(fields))
    end)
]]

worldedit.register_gui_handler = function(identifier, handler)
	local enabled = true
	minetest.register_on_player_receive_fields(function(player, formname, fields)
		local name = player:get_player_name()

		if fields.worldedit_gui then
			-- >> KIDSCODE - Make sfinv aware when worldedit handles menu
			local context = sfinv.get_or_create_context(player)
			context.external_menu = "worldedit"
			sfinv.set_context(player, context)
			-- << KIDSCODE - Make sfinv aware when worldedit handles menu

			worldedit.show_page(name, "worldedit_gui")
			return true
		end

		if not enabled then return false end
		enabled = false
		minetest.after(0.01, function() enabled = true end)

		--ensure the player has permission to perform the action
		local entry = worldedit.pages[identifier]
		if entry and minetest.check_player_privs(name, entry.privs) then
			return handler(name, fields)
		end
		return false
	end)
end

worldedit.get_formspec_header = function(identifier)
	local entry = worldedit.pages[identifier] or {}
	return "button[0,0;2,0.5;worldedit_gui;< " .. S("Back") .. "]" ..
		string.format("label[2,0;%s]", entry.name or "")
end

local get_formspec = function(name, identifier)
	if worldedit.pages[identifier] then
		return worldedit.pages[identifier].get_formspec(name)
	end
	return worldedit.pages["worldedit_gui"].get_formspec(name) --default to showing main page if an unknown page is given
end

--implement worldedit.show_page(name, page) in different ways depending on the available APIs
if rawget(_G, "sfinv") then
	assert(sfinv.enabled)

	for n in pairs(sfinv.pages) do
		local orig_get = sfinv.pages[n].get

		sfinv.override_page(n, {
			get = function(self, player, context)
				local pname = player:get_player_name()
				local can_worldedit = minetest.check_player_privs(pname, "worldedit")
				local fs = orig_get(self, player, context)

				return fs .. (can_worldedit and
					("style[worldedit_gui;noclip=true]" ..
					"image_button[7.2,9.1;1,1;inventory_plus_worldedit_gui.png;worldedit_gui;]" ..
					"tooltip[worldedit_gui;" .. S("World Editor") .. "]") or "")
			end
		})
	end

	--show the form when the button is pressed and hide it when done
	minetest.register_on_player_receive_fields(function(player, formname, fields)
		local player_name = player:get_player_name()

		if fields.worldedit_gui or fields.worldedit_gui_exit_ then --main page
			worldedit.show_page(player_name, "worldedit_gui")
			return true
		elseif fields.worldedit_gui_exit then --return to original page
			-- >> KIDSCODE - Make sfinv aware when worldedit handles menu
			local context = sfinv.get_or_create_context(player)
			context.external_menu = nil
			sfinv.set_context(player, context)
			-- << KIDSCODE - Make sfinv aware when worldedit handles menu

			sfinv.set_player_inventory_formspec(player, sfinv.get_or_create_context(player))
			return true
		end
		return false
	end)

	worldedit.show_page = function(name, page)
		local player = minetest.get_player_by_name(name)
		if player then
			player:set_inventory_formspec(get_formspec(name, page))
		end
	end
end

local function get_formspec_str(main, y, columns, width, buttons, name)
	return string.format(
		"size[%g,%g]", math.max(columns * width, 5),
			       math.max(y + 0.5, (mode[name] == "default" and 4 or 2.5))) ..
		"item_image_button[" .. (columns * (width / 2) - 0.5) ..
			",0.2;1,1;worldedit:hammer;worldedit_hammer;]" ..
		--"image[" .. (columns * (width / 2) - 0.5) .. ",0.2;1,1;worldedit_hammer.png]" ..
		"label[3,1.2;" .. S("Click on the hammer button to get your WorldEdit tool") .. "]" ..
		"button[0,0;2,0.5;worldedit_gui_exit" .. (main and "" or "_") .. ";< " .. S("Back") .. "]" ..
		table.concat(buttons)
		-- .. "button[" .. (math.max(columns * width, 5) - 2) ..
		--	",0;2,0.5;worldedit_gui_advanced;" ..
		--	(mode[name] == "default" and S("Basic") or S("Advanced")) .. "]"
end

worldedit.register_gui_function("worldedit_gui", {
	type = "default",
	name = "WorldEdit GUI",
	privs = {interact=true},
	get_formspec = function(name)
		--create a form with all the buttons arranged in a grid
		local buttons, x, y, index = {}, 0, 2, 0
		local width, height = 3, 0.8
		local columns = mode[name] == "default" and 5 or 4

		for i = 1, #identifiers do
			local identifier = identifiers[i]
			if identifier ~= "worldedit_gui" then
				local entry = worldedit.pages[identifier]
				if (mode[name] == "advanced"  and entry.type == "default") or
				   (mode[name] == "default") and not entry.form then
					buttons[#buttons + 1] =
						string.format((entry.get_formspec and "button" or "button_exit") ..
						"[%g,%g;%g,%g;%s;%s]",
						x, y, width, height, identifier, minetest.formspec_escape(entry.name))

					index, x = index + 1, x + width
					if index == columns then --row is full
						x, y = 0, y + height
						index = 0
					end
				end
			end
		end

		if index == 0 then --empty row
			y = y - height
		end

		return get_formspec_str(true, y, columns, width, buttons, name)
	end,
})

worldedit.register_gui_handler("worldedit_gui", function(name, fields)
	if fields.worldedit_hammer then
		local player = minetest.get_player_by_name(name)
		local inv = player:get_inventory()
		inv:add_item("main", "worldedit:hammer 1")
		worldedit.player_notify(name, "WorldEdit's tool added to your inventory!")
		return true
	end

	if fields.worldedit_gui_advanced then
		mode[name] = mode[name] == "default" and "advanced" or "default"
		worldedit.show_page(name, "worldedit_gui")
		return true
	else
		for identifier, entry in pairs(worldedit.pages) do --check for WorldEdit GUI main formspec button selection
			if fields[identifier] and identifier ~= "worldedit_gui" then
				--ensure player has permission to perform action
				local has_privs, missing_privs = minetest.check_player_privs(name, entry.privs)
				if not has_privs then
					worldedit.player_notify(name,
						S("you are not allowed to use this function (missing privileges: @1)",
						  table.concat(missing_privs, ", ")))
					return false
				end

				if entry.on_select then
					entry.on_select(name)
				end

				if entry.get_formspec then
					worldedit.show_page(name, identifier)
				end

				return true
			end
		end
	end

	return false
end)

worldedit.register_gui_function("worldedit_gui_forms", {
	type = "default",
	name = S("Forms"),
	privs = {worldedit=true},
	get_formspec = function(name)
		--create a form with all the buttons arranged in a grid
		local buttons, x, y, index = {}, 0, 2, 0
		local width, height = 3, 0.8
		local columns = mode[name] == "default" and 5 or 3

		for i = 1, #identifiers do
			local identifier = identifiers[i]
			if identifier ~= "worldedit_gui" then
				local entry = worldedit.pages[identifier]
				if entry.form then
					buttons[#buttons + 1] =
						string.format((entry.get_formspec and "button" or "button_exit") ..
						"[%g,%g;%g,%g;%s;%s]",
						x, y, width, height, identifier, minetest.formspec_escape(entry.name))

					index, x = index + 1, x + width
					if index == columns then --row is full
						x, y = 0, y + height
						index = 0
					end
				end
			end
		end

		if index == 0 then --empty row
			y = y - height
		end

		return get_formspec_str(false, y, columns, width, buttons, name)
	end,
})

worldedit.register_gui_handler("worldedit_gui_forms", function(name, fields)
	for identifier, entry in pairs(worldedit.pages) do --check for WorldEdit GUI main formspec button selection
		if fields[identifier] and identifier ~= "worldedit_gui" then
			--ensure player has permission to perform action
			local has_privs, missing_privs = minetest.check_player_privs(name, entry.privs)
			if not has_privs then
				worldedit.player_notify(name,
					S("you are not allowed to use this function (missing privileges: @1)",
					  table.concat(missing_privs, ", ")))
				return false
			end

			if entry.on_select then
				entry.on_select(name)
			end

			if entry.get_formspec then
				worldedit.show_page(name, identifier)
			end

			return true
		end
	end

	return false
end)

dofile(minetest.get_modpath(minetest.get_current_modname()) .. "/functionality.lua")
