local media_paths = epidermis.media_paths
-- TODO keep count of total added media, force-kick players after their RAM is too full, restart after server disk is too full
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
	local to_receive = {}
	for player in modlib.minetest.connected_players() do
		local name = player:get_player_name()
		if minetest.get_player_information(name).protocol_version < 39 then
			minetest.kick_player(name, "Your Minetest client is outdated (< 5.3) and can't receive dynamic media. Rejoin to get the added media.")
		else
			to_receive[name] = true
		end
	end
	local arg = path
	if minetest.features.dynamic_add_media_table then
		arg = {filepath = path}
		if minetest.is_singleplayer() then
			arg.ephemeral = true
		else
			arg.ephemeral = ephemeral
		end
	end
	if not next(to_receive) then
		minetest.dynamic_add_media(arg, error)
		on_all_received()
		return
	end
	minetest.dynamic_add_media(arg, function(name)
		if name == nil then
			on_all_received()
			return
		end
		assert(to_receive[name])
		to_receive[name] = nil
		if not next(to_receive) then
			on_all_received()
		end
	end)
end