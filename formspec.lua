-- TODO FS building utils
local formspecs = {}

local id = 1

minetest.register_on_leaveplayer(function(player)
	formspecs[player:get_player_name()] = nil
end)

minetest.register_on_player_receive_fields(function(player, formname, fields)
	local player_name = player:get_player_name()
	local formspec = formspecs[player_name]
	if formname ~= (formspec or {}).name then return end
	if fields.quit then
		formspecs[player_name] = nil
	end
	formspec.handler(fields)
	return true -- don't call remaining functions
end)

function epidermis.show_formspec(player, formspec, handler)
	local player_name = player:get_player_name()
	local formspec_name = "epidermis:" .. id
	formspecs[player_name] = {
		name = formspec_name,
		handler = handler or modlib.func.no_op,
	}
	id = id + 1
	if id > 2^50 then id = 1 end
	minetest.show_formspec(player_name, formspec_name, formspec)
end

function epidermis.close_formspec(player)
	local player_name = player:get_player_name()
	local formspec = assert(formspecs[player_name])
	formspecs[player_name] = nil
	minetest.close_formspec(player_name, formspec.name)
end