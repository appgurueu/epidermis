epidermis = {}
epidermis.conf = modlib.mod.configuration()
local include = modlib.mod.include
include"misc.lua"
include"media_paths.lua"
include"dynamic_add_media.lua"
include"persistence.lua"
include"theme.lua"
include"send_notification.lua"
include"colorpicker_rgb_formspec.lua"
include"colorpicker_hsv_ingame.lua"
local http = assert(minetest.request_http_api(), "add epidermis to secure.http_mods")
assert(loadfile(modlib.mod.get_resource("skindb.lua")))(http)
include"skin.lua"
include"paintable.lua"
include"tools.lua"
include"help.lua"
