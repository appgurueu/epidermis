local function get_textures(player)
	local anim = player_api.get_animation(player)
	return anim.textures or player_api.registered_models[anim.model].textures
end

function epidermis.get_skin(player)
	return get_textures(player)[1]
end

function epidermis.set_skin(player, skin)
	local textures = modlib.table.copy(get_textures(player))
	textures[1] = skin
	player_api.set_textures(player, textures)
end