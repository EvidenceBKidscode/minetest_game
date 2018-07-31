
local old_is_protected = minetest.is_protected
function minetest.is_protected(pos, name)
	if not areas:canInteract(pos, name) then
		return true
	end
	return old_is_protected(pos, name)
end

minetest.register_on_protection_violation(function(pos, name)
	if not areas:canInteract(pos, name) then
		local owners = areas:getNodeOwners(pos)
		minetest.chat_send_player(name,
			("This area is protected by %s."):format(
				table.concat(owners, ", ")))
	end
end)

-- Place node restriction
minetest.register_on_placenode(function(pos, newnode, placer, oldnode)
	if not placer or not placer:is_player() then return end
	local player_name = placer:get_player_name()
	if not areas:canPlace(pos, player_name) then
		-- Hack to allow place bush with glove
		local wielded = placer:get_wielded_item()
		if wielded == nil or 
		   wielded:get_name() ~= "audioblocks:glove" then
			minetest.swap_node(pos, oldnode)
			local def = minetest.registered_nodes[newnode.name]
			if def.on_destruct then
				def.on_destruct(pos)
			end
			minetest.record_protection_violation(pos, player_name)
			return true
		end
	end
end)

-- Dig node restriction
minetest.register_on_dignode(function(pos, oldnode, digger)
	if not digger or not digger:is_player() then return end
	local player_name = digger:get_player_name()
	if not areas:canDig(pos, player_name) then
		minetest.swap_node(pos, oldnode)
		digger:get_inventory():remove_item("main",
			minetest.registered_nodes[oldnode.name].drop or oldnode.name)
		minetest.record_protection_violation(pos, player_name)
	end
end)

