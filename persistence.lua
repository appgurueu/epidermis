local concat_path = modlib.file.concat_path
local auth_handler = minetest.get_auth_handler()

epidermis.paths = {dynamic_textures = {}}
for _, folder in pairs{"skindb", "epidermi"} do
	local path = modlib.file.concat_path({ minetest.get_worldpath(), "data", "epidermis", "textures", folder })
	minetest.mkdir(path)
	epidermis.paths.dynamic_textures[folder] = path
end
epidermis.paths.playerdata = modlib.file.concat_path({ minetest.get_worldpath(), "data", "epidermis", "players" })
minetest.mkdir(epidermis.paths.playerdata)

function epidermis.get_player_data(playername)
	local filepath = concat_path{epidermis.paths.playerdata, playername .. ".lua"}
	local content = modlib.file.read(filepath)
	if not content then return end
	local playerdata = assert(modlib.luon:read_string(content))
	return playerdata
end

function epidermis.set_player_data(playername, data)
	local filepath = concat_path{epidermis.paths.playerdata, playername .. ".lua"}
	assert(modlib.file.write(filepath, modlib.luon:write_string(data)))
end

local function player_exists(name)
	if name == "singleplayer" and minetest.is_singleplayer() then
		return true
	end
	return auth_handler.get_auth(name) ~= nil
end

-- Remove unused player data & mark used textures
local used_textures = {}
for _, filename in ipairs(minetest.get_dir_list(epidermis.paths.playerdata, false)) do
	local playername = filename:match"^(.-)%.lua$"
	if playername then
		local filepath = concat_path{epidermis.paths.playerdata, filename}
		if player_exists(playername) then
			local playerdata = epidermis.get_player_data(playername)
			used_textures[playerdata.epidermis] = true
		else
			assert(os.remove(filepath))
		end
	end
end

-- Remove unused textures & store highest texture ID
local epidermi_texture_path = epidermis.paths.dynamic_textures.epidermi
for _, dirname in ipairs(minetest.get_dir_list(epidermi_texture_path, true)) do
	local highest_number
	local last_filename
	local function remove_if_unused(filename)
		if not used_textures[filename] then
			assert(os.remove(concat_path{epidermi_texture_path, dirname, filename}))
		end
	end
	for _, filename in ipairs(minetest.get_dir_list(concat_path{epidermi_texture_path, dirname}, false)) do
		local number = filename:match("^" .. modlib.text.escape_magic_chars(dirname) .. "_(%d+)%.png$")
		if number then
			number = tonumber(number)
			if last_filename then
				if number > highest_number then
					remove_if_unused(last_filename)
					highest_number = number
					last_filename = filename
				else
					remove_if_unused(filename)
				end
			else
				highest_number = number
				last_filename = filename
			end
		end
	end
end

function epidermis.get_epidermis_path(paintable_id, texture_id)
	local texture_name = ("epidermis_paintable_%d_%d.png"):format(paintable_id, texture_id)
	local path = concat_path{
		epidermi_texture_path,
		("epidermis_paintable_%d"):format(paintable_id),
		texture_name
	}
	return path, texture_name
end

function epidermis.get_epidermis_path_from_texture(dynamic_texture)
	local tex_name, dir_name = dynamic_texture:match"^((epidermis_paintable_%d+)_%d+.png)$"
	if not (tex_name and dir_name) then return end
	return modlib.file.concat_path{epidermi_texture_path, dir_name, tex_name}
end

function epidermis.get_last_epidermis_path(paintable_id)
	local dir_name = ("epidermis_paintable_%d"):format(paintable_id)
	local max_tex_id = -math.huge
	for _, filename in ipairs(minetest.get_dir_list(concat_path{epidermi_texture_path, dir_name}, false)) do
		local number = filename:match("^" .. modlib.text.escape_magic_chars(dir_name) .. "_(%d+)%.png$")
		if number then
			max_tex_id = math.max(max_tex_id, tonumber(number))
		end
	end
	if max_tex_id == -math.huge then return end
	return epidermis.get_epidermis_path(paintable_id, max_tex_id)
end

function epidermis.write_epidermis(paintable_id, texture_id, raw_png_data)
	local path, texture_name = epidermis.get_epidermis_path(paintable_id, texture_id)
	assert(modlib.file.write_binary(path, raw_png_data))
	return path, texture_name
end

-- SkinDB

function epidermis.write_skindb_skin(id, raw_png_data, meta_data)
	local texture_name = ("epidermis_skindb_%d.png"):format(id)
	local path = concat_path{ epidermis.paths.dynamic_textures.skindb, texture_name }
	assert(modlib.file.write_binary(path, raw_png_data))
	assert(modlib.file.write(concat_path{ epidermis.paths.dynamic_textures.skindb, texture_name .. ".json" },
		modlib.json:write_string(meta_data)))
	return path, texture_name
end

function epidermis.remove_skindb_skin(id)
	local texture_name = ("epidermis_skindb_%d.png"):format(id)
	local path = concat_path{ epidermis.paths.dynamic_textures.skindb, texture_name }
	assert(os.remove(path))
	assert(os.remove(path .. ".json"))
end

-- Player-set epidermis persistence
minetest.register_on_joinplayer(function(player)
	local data = epidermis.get_player_data(player:get_player_name())
	if data then
		epidermis.dynamic_add_media(assert(epidermis.get_epidermis_path_from_texture(data.epidermis)), function()
			epidermis.set_skin(player, data.epidermis)
		end, true)
	end
end)