-- This is inspired by the landrush mod by Bremaweb

areas.hud = {}
areas.hud_text = {}
areas.hud_timer = {}
areas.hud_timeout = {}

local code_colors = {
	white  = 0xFFFFFF,
	black  = 0x000000,
	red    = 0xFF0000,
	yellow = 0xFFFF00,
	blue   = 0x0000FF,
	green  = 0x00FF00,
	purple = 0x800080,
	pink   = 0xFF69B4,
}

local LANG = minetest.settings:get("language")
LANG = LANG ~= "" and LANG or "en"

local t = {}

minetest.register_globalstep(function(dtime)
	local players = minetest.get_connected_players()
	for i = 1, #players do
		local player = players[i]
		local name = player:get_player_name()
		local pos = vector.round(player:get_pos())

		if minetest.check_player_privs(name, "mapmaker") then
			local areaStrings = {}
			for id, area in pairs(areas:getAreasAtPos(pos)) do
				table.insert(areaStrings, ("%s [%u] (%s%s)")
						:format(area.name, id, area.owner,
						area.open and ":open" or ""))
			end

			for i, area in pairs(areas:getExternalHudEntries(pos)) do
				local str = ""
				if area.name then
					str = area.name .. " "
				end

				if area.id then
					str = str .. "[" .. area.id .. "] "
				end

				if area.owner then
					str = str .. "(" .. area.owner .. ")"
				end

				table.insert(areaStrings, str)
			end

			local areaString = "Areas:"
			if #areaStrings > 0 then
				areaString = areaString .. "\n" .. table.concat(areaStrings, "\n")
			end

			local hud = areas.hud[name]
			if not hud then
				hud = {}
				areas.hud[name] = hud

				hud.areasId = player:hud_add({
					hud_elem_type = "text",
					name      = "Areas",
					number    = 0xFFFFFF,
					position  = {x = 0,   y =  1},
					offset    = {x = 8,   y = -8},
					scale     = {x = 200, y = 60},
					alignment = {x = 1,   y = -1},
					text      = areaString,
				})

				hud.oldAreas = areaString
				--return
			elseif hud.oldAreas ~= areaString then
				player:hud_change(hud.areasId, "text", areaString)
				hud.oldAreas = areaString
			end
		end

		local area_name, text, color, font_size, timer = "", "", 0xFFFFFF, 22, ""
		for _, area in pairs(areas:getAreasAtPos(pos)) do
			area_name = area.name
			text  = area.text and area.text[LANG] or ""
			color = code_colors[(area.color and area.color or "white")]
			font_size = area.font_size and area.font_size or 22
			timer = area.timer
			break
		end

		local hud_text = areas.hud_text[name]
		local hud_timer = areas.hud_timer[name]

		if not hud_timer then
			hud_timer = {}
			areas.hud_timer[name] = hud_timer

			hud_timer.areasTimer = player:hud_add({
				hud_elem_type = "text",
				name      = "Area Timer",
				number    = 0xFFFFFF,
				position  = {x = 0.8,  y = 0.2},
				offset    = {x = 8,    y = -8},
				alignment = {x = 1,    y =  1},
				scale     = {x = 200,  y = 60},
				text      = timer and "Time remaining: " .. timer .. "s" or "",
			})

			hud_timer.oldTimer = area_name
			areas.hud_timeout[name] = {
				[area_name] = timer
			}
			return
		elseif not hud_text then
			hud_text = {}
			areas.hud_text[name] = hud_text

			hud_text.areasText = player:hud_add({
				hud_elem_type = "text",
				name      = "Area Text",
				number    = color,
				position  = {x = 0.1,  y = 0.34},
				offset    = {x = 8,    y = -8},
				alignment = {x = 1,    y =  1},
				scale     = {x = 200,  y = 60},
				text      = text,
				font_size = font_size,
			})

			hud_text.oldText = text
			hud_text.oldColor = color
			hud_text.oldFontSize = font_size
			return
		elseif hud_text.oldText ~= text then
			player:hud_change(hud_text.areasText, "text", text or "")
			hud_text.oldText = text
		elseif hud_text.oldColor ~= color then
			player:hud_change(hud_text.areasText, "number", color or 0xFFFFFF)
			hud_text.oldColor = color
		elseif hud_text.oldFontSize ~= font_size then
			player:hud_change(hud_text.areasText, "font_size", font_size or 22)
			hud_text.oldFontSize = font_size
		elseif hud_timer.oldTimer ~= area_name then
			if timer and timer ~= "" then
				areas.hud_timeout[name][area_name] =
					areas.hud_timeout[name][area_name] and
					areas.hud_timeout[name][area_name] or tonumber(timer)
			end

			if areas.hud_timeout[name][area_name] then
				player:hud_change(hud_timer.areasTimer, "text",
					"Time remaining: " .. areas.hud_timeout[name][area_name] .. "s")
			end

			hud_timer.oldTimer = area_name
		end

		t[name] = (t[name] or 0) + dtime

		local number = areas.hud_timeout[name][area_name]
		if number and timer ~= "" then
			if t[name] >= 1 and number > 0 then
				areas.hud_timeout[name][area_name] = number - 1
				t[name] = 0
			end

			player:hud_change(hud_timer.areasTimer, "text",
				"Time remaining: " .. areas.hud_timeout[name][area_name] .. "s")
		else
			player:hud_change(hud_timer.areasTimer, "text",  "")
		end
	end
end)

minetest.register_on_leaveplayer(function(player)
	local name = player:get_player_name()
	if areas.hud[name] then
		areas.hud[name] = nil
	end
end)
