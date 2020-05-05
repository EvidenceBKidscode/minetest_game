-- TODO: Missing new translations

local S = default.get_translator

local additional_nodes = {
	{S("Cobblestone"), "cobble", "cracky"},
	{S("Glowstone"), "glowstone", "cracky"},
	{S("Gravel"), "gravel", "crumbly"},
	{S("Acacia Tree Leaves"), "leaves_acacia", "crumbly"},
	{S("Opaque Acacia Tree Leaves"), "leaves_acacia_opaque", "crumbly"},
	{S("Big Oak Leaves"), "leaves_big_oak", "crumbly"},
	{S("Opaque Big Oak Leaves"), "leaves_big_oak_opaque", "crumbly"},
	{S("Birch Leaves"), "leaves_birch", "crumbly"},
	{S("Opaque Birch Leaves"), "leaves_birch_opaque", "crumbly"},
	{S("Jungle Tree Leaves"), "leaves_jungle", "crumbly"},
	{S("Opaque Jungle Tree Leaves"), "leaves_jungle_opaque", "crumbly"},
	{S("Oak Leaves"), "leaves_oak", "crumbly"},
	{S("Opaque Oak Leaves"), "leaves_oak_opaque", "crumbly"},
	{S("Spurce Leaves"), "leaves_spruce", "crumbly"},
	{S("Opaque Spurce Leaves"), "leaves_spruce_opaque", "crumbly"},
	{S("Nether Brick"), "nether_brick", "cracky"},
	{S("Prismarine Bricks"), "prismarine_bricks", "cracky"},
	{S("Prismaring Dark Bricks"), "prismarine_dark", "cracky"},
	{S("Purpur Block"), "purpur_block", "cracky"},
	{S("Quartz Ore"), "quartz_ore", "cracky"},
	{S("Red Sandstone Bottom"), "red_sandstone_bottom", "cracky"},
	{S("Carved Red Sandstone"), "red_sandstone_carved", "cracky"},
	{S("Red Sandstone"), "red_sandstone_normal", "cracky"},
	{S("Smooth Red Sandstone"), "red_sandstone_smooth", "cracky"},
	{S("Sandstone Top"), "sandstone_top", "cracky"},
	{S("Sandstone Bottom"), "sandstone_bottom", "cracky"},
	{S("Carved Sandstone"), "sandstone_carved", "cracky"},
	{S("Sandstone"), "sandstone_normal", "cracky"},
	{S("Smooth Sandstone"), "sandstone_smooth", "cracky"},
	{S("Stone"), "stone", "cracky"},
	{S("Smooth Andesite"), "stone_andesite_smooth", "cracky"},
	{S("Diorite"), "stone_diorite", "cracky"},
	{S("Smooth Diorite"), "stone_diorite_smooth", "cracky"},
	{S("Granite"), "stone_granite", "cracky"},
	{S("Smooth Granite"), "stone_granite_smooth", "cracky"},
	{S("Stone Brick"), "stonebrick", "cracky"},
	{S("Cracked Stone Brick"), "stonebrick_cracked", "cracky"},

	{S("Aerated Concrete"), "aerated_concrete", "cracky"},
	{S("Asphalt"), "asphalt", "cracky"},
	{S("Brick Wall type 2"), "brick_wall_2", "cracky"},
	{S("Gray Brick Wall"), "brick_wall_gray", "cracky"},
	{S("Light brick wall"), "brick_wall_light", "cracky"},
	{S("Cinder"), "cinder_block", "cracky"},
	{S("Concrete Bare"), "concrete_bare", "cracky"},
	{S("Concrete Bunker"), "concrete_bunker", "cracky"},
	{S("Concrete Plates"), "concrete_plates", "cracky"},
	{S("Fancy Wooden Floor"), "fancy_wood_floor", "cracky"},
	{S("Reinforced Wood"), "reinforced_wood", "cracky"},
	{S("Rock Wall"), "rock_wall", "cracky"},
	{S("Rock Wall Sculpted"), "rock_wall_sculpted", "cracky"},
	{S("Strong Wood Crate"), "strong_wood_crate", "cracky"},
	{S("White brick wall"), "white_brick_wall", "cracky"},
	{S("Wooden Crate"), "wood_crate", "cracky"},
	{S("Wooden Crate type 2"), "wood_crate_2", "cracky"},
	{S("Wooden Floor"), "wooden_floor", "cracky"},
	{S("Glass Brick"), "glass_brick", "cracky"},
}

for i = 1, #additional_nodes do
	local desc, name, groupname = unpack(additional_nodes[i])
	local groups = {}
	groups[groupname] = 1

	minetest.register_node("default:" .. name .. "_2", {
		description = desc,
		paramtype = "light",
		paramtype2 = "facedir",
		tiles = {"default_" .. name .. "_2.png"},
		groups = groups,
	})
end
