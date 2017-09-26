worldedit = worldedit or {}

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
			worldedit.show_page(name, "worldedit_gui")
			return true
		end

		if not enabled then return false end
		enabled = false
		minetest.after(0.2, function() enabled = true end)

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
	return "button[0,0;2,0.5;worldedit_gui;< Back]" ..
		string.format("label[2,0;WorldEdit GUI > %s]", entry.name or "")
end

local get_formspec = function(name, identifier)
	if worldedit.pages[identifier] then
		return worldedit.pages[identifier].get_formspec(name)
	end
	return worldedit.pages["worldedit_gui"].get_formspec(name) --default to showing main page if an unknown page is given
end

--implement worldedit.show_page(name, page) in different ways depending on the available APIs
if rawget(_G, "sfinv") and minetest.get_modpath("teacher_menu") then
	assert(sfinv.enabled)
	local orig_get = sfinv.pages["teacher_menu"].get
	sfinv.override_page("teacher_menu", {
		get = function(self, player, context)
			local can_worldedit = minetest.check_player_privs(player, {worldedit=true})
			local fs = orig_get(self, player, context)

			if teachers[player:get_player_name()].current_tab == "world" then	
				return fs .. (can_worldedit and
					("image_button[3.3,6.7;1.5,1.5;inventory_plus_worldedit_gui.png;worldedit_gui;]" ..
					 "label[3.15,8.15;World Editor]" ..
					 "box[2.95,6.4;2,2.3;#888888]") or
					 "")
			end

			return fs
		end
	})

	--show the form when the button is pressed and hide it when done
	minetest.register_on_player_receive_fields(function(player, formname, fields)
		local player_name = player:get_player_name()

		if fields.worldedit_gui or fields.worldedit_gui_exit_ then --main page
			worldedit.show_page(player_name, "worldedit_gui")
			return true
		elseif fields.worldedit_gui_exit then --return to original page
			if not teachers[player_name] then
				teachers[player_name] = {}
			end

			teachers[player_name].current_tab = "world"
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
elseif rawget(_G, "teacher_menu") then --fallback button
	-- FIXME: this is a huge clusterfuck and the back button is broken
	local player_formspecs = {}

	local update_main_formspec = function(name)
		local formspec = player_formspecs[name]
		if not formspec then
			return
		end
		local player = minetest.get_player_by_name(name)
		if not player then --this is in case the player signs off while the media is loading
			return
		end
		if (minetest.check_player_privs(name, {creative=true}) or
				minetest.setting_getbool("creative_mode")) and
				creative then --creative is active, add button to modified formspec
			local creative_formspec = player:get_inventory_formspec()
			local tab_id = tonumber(creative_formspec:match("tabheader%[.-;(%d+)%;"))

			if tab_id == 1 then
				formspec = creative_formspec ..
					"image_button[0,1;1,1;inventory_plus_worldedit_gui.png;worldedit_gui;]"
			elseif not tab_id then
				formspec = creative_formspec ..
					"image_button[6,0;1,1;inventory_plus_worldedit_gui.png;worldedit_gui;]"
			else
				return
			end
		else
			formspec = formspec .. "image_button[0,0;1,1;inventory_plus_worldedit_gui.png;worldedit_gui;]"
		end
		player:set_inventory_formspec(formspec)
	end

	minetest.register_on_joinplayer(function(player)
		local name = player:get_player_name()
		minetest.after(1, function()
			if minetest.get_player_by_name(name) then --ensure the player is still signed in
				player_formspecs[name] = player:get_inventory_formspec()
				minetest.after(0.01, function()
					update_main_formspec(name)
				end)
			end
		end)
	end)

	minetest.register_on_leaveplayer(function(player)
		player_formspecs[player:get_player_name()] = nil
	end)

	local gui_player_formspecs = {}
	minetest.register_on_player_receive_fields(function(player, formname, fields)
		local name = player:get_player_name()
		if fields.worldedit_gui then --main page
			gui_player_formspecs[name] = player:get_inventory_formspec()
			worldedit.show_page(name, "worldedit_gui")
			return true
		elseif fields.worldedit_gui_exit then --return to original page
			if gui_player_formspecs[name] then
				player:set_inventory_formspec(gui_player_formspecs[name])
			end
			return true
		else --deal with creative_inventory setting the formspec on every single message
			minetest.after(0.01,function()
				update_main_formspec(name)
			end)
			return false --continue processing in creative inventory
		end
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
		"image[" .. (columns * (width / 2) - 0.5) .. ",0.2;1,1;worldedit_hammer.png]" ..
		"label[" .. (columns * (width / 2) - 3) .. ",1;" ..
			minetest.wrap_text(
			"Use the hammer from your inventory to select an area,"..
			" then choose one of these functionalities...", 50, false) .. "]" ..
		"button[0,0;2,0.5;worldedit_gui_exit" .. (main and "" or "_") .. ";< Back]" ..
		"label[2,0;WorldEdit GUI]" ..
		table.concat(buttons) ..
		"button[" .. (math.max(columns * width, 5) - 2) ..
			",0;2,0.5;worldedit_gui_advanced;" ..
			(mode[name] == "default" and "Basic" or "Advanced") .. "]"
end

worldedit.register_gui_function("worldedit_gui", {
	type = "default",
	name = "WorldEdit GUI",
	privs = {interact=true},
	get_formspec = function(name)
		--create a form with all the buttons arranged in a grid
		local buttons, x, y, index = {}, 0, 2, 0
		local width, height = 3, 0.8
		local columns = mode[name] == "default" and 5 or 3

		for i = 1, #identifiers do
			local identifier = identifiers[i]
			if identifier ~= "worldedit_gui" then
				local entry = worldedit.pages[identifier]
				if entry.type ~= mode[name] and not entry.form then
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
						"you are not allowed to use this function (missing privileges: " ..
						table.concat(missing_privs, ", ") .. ")")
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
	name = "Forms",
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
					"you are not allowed to use this function (missing privileges: " ..
					table.concat(missing_privs, ", ") .. ")")
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