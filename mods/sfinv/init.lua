-- sfinv/init.lua

dofile(minetest.get_modpath("sfinv") .. "/api.lua")

-- Load support for MT game translation.
local S = minetest.get_translator("sfinv")

-->> KIDSCODE
if minetest.settings:get_bool("creative_mode") == false then
	sfinv.register_page("sfinv:crafting", {
		title = "Crafting",
		get = function(self, player, context)
			return sfinv.make_formspec(player, context, [[
					list[current_player;craft;1.75,0.5;3,3;]
					list[current_player;craftpreview;5.75,1.5;1,1;]
					image[4.75,1.5;1,1;gui_furnace_arrow_bg.png^[transformR270]
					listring[current_player;main]
					listring[current_player;craft]
					image[0,4.5;1,1;gui_hb_bg.png]
					image[1,4.5;1,1;gui_hb_bg.png]
					image[2,4.5;1,1;gui_hb_bg.png]
					image[3,4.5;1,1;gui_hb_bg.png]
					image[4,4.5;1,1;gui_hb_bg.png]
					image[5,4.5;1,1;gui_hb_bg.png]
					image[6,4.5;1,1;gui_hb_bg.png]
					image[7,4.5;1,1;gui_hb_bg.png]
				]], true)
		end
	})
end
--[=[
sfinv.register_page("sfinv:crafting", {
	title = S("Crafting"),
	get = function(self, player, context)
		return sfinv.make_formspec(player, context, [[
				list[current_player;craft;1.75,0.5;3,3;]
				list[current_player;craftpreview;5.75,1.5;1,1;]
				image[4.75,1.5;1,1;sfinv_crafting_arrow.png]
				listring[current_player;main]
				listring[current_player;craft]
			]], true)
	end
})
]=]
--<< KIDSCODE
