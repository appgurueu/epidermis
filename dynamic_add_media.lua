local media_paths = epidermis.media_paths
-- TODO keep count of total added media:
-- Force-kick players after their RAM is too full
-- Restart after server disk is too full
function epidermis.dynamic_add_media(path, on_all_received, ephemeral)
	local filename = modlib.file.get_name(path)
	local existing_path = media_paths[filename]
	if existing_path == path then
		-- May occur when players & epidermi share a texture or when an epidermis is activated multiple times
		-- Also occurs when SkinDB deletions happen and is required for expected behavior
		on_all_received()
		return
	end
	assert(not existing_path)
	assert(modlib.file.exists(path))

	local arg = path
	if minetest.features.dynamic_add_media_table then
		arg = {filepath = path}
		if not minetest.is_singleplayer() then
			arg.ephemeral = ephemeral
		else
			arg.ephemeral = false
		end
	end

	local to_receive = {}
	for player in modlib.minetest.connected_players() do
		local name = player:get_player_name()
		if minetest.get_player_information(name).protocol_version < 39 then
			minetest.kick_player(name,
				"Your Minetest client is outdated (< 5.3) and can't receive dynamic media. Rejoin to get the added media.")
		else
			to_receive[name] = true
		end
	end

	if not next(to_receive) then
		minetest.dynamic_add_media(arg, function(name)
			minetest.log("warning", ("%s received media %s despite not being connected"):format(name, filename))
		end)
		on_all_received()
		return
	end

	minetest.dynamic_add_media(arg, function(name)
		if name == nil then
			on_all_received()
			return
		end
		if not to_receive[name] then
			minetest.log("warning", ("%s received media %s despite not being connected"):format(name, filename))
			return
		end
		to_receive[name] = nil
		if not next(to_receive) then
			on_all_received()
		end
	end)
end