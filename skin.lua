local player_api = rawget(_G, "player_api")

local function get_textures(player)
	if player_api then
		local anim = player_api.get_animation(player)
		return anim.textures or player_api.registered_models[anim.model].textures
	end
	return player:get_properties().textures
end

local function get_texture(player, index)
	return assert(get_textures(player)[index])
end

local function set_textures(player, textures)
	if player_api then
		player_api.set_textures(player, textures)
		return
	end
	player:set_properties{textures = textures}
end

local function set_texture(player, index, texture)
	local textures = modlib.table.copy(get_textures(player))
	textures[index] = texture
	set_textures(player, textures)
end

local skin_texture_index = 1

function epidermis.get_skin(player)
	return get_texture(player, skin_texture_index)
end

function epidermis.set_skin(player, skin)
	set_texture(player, skin_texture_index, skin)
end