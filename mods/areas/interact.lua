
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
minetest.register_on_placenode(function(pos, _, placer, oldnode)
	if not placer then return end
	local player_name = placer:get_player_name()
	if not areas:canPlace(pos, player_name) then
		minetest.swap_node(pos, oldnode)
		return true
	end
end)

-- Dig node restriction
minetest.register_on_dignode(function(pos, oldnode, digger)
	if not digger then return end
	local player_name = digger:get_player_name()
	if not areas:canDig(pos, player_name) then
		minetest.swap_node(pos, oldnode)
		return true
	end
end)

