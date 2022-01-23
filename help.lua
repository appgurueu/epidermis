local tags = setmetatable({}, {
	__index = function(_, tag_name)
		return function(table)
			table[true] = tag_name
			return table
		end
	end,
})
local function item_(name, title, ...)
	return {
		tags.itemtitle{
			tags.item{
				name = name,
				float = "left",
				width = 64,
				height = 64,
			},
			title,
		},
		"\n",
		table.concat({ ... }, "\n"), -- description
		"\n",
	}
end
local help = {
	tags.tag{ name = "itemtitle", size = 18 },
	tags.tag{ name = "code", font = "mono", color = "lightgreen" },
	{
		tags.itemtitle{
			tags.item{
				name = "epidermis:guide",
				float = "left",
				width = 64,
				height = 64,
			},
			"Guide",
		},
		"\n",
		"This guide. Can also be opened using ", -- description
		tags.code{"/epidermis_guide"}, ".",
		"\n",
	},
	item_(
		"epidermis:spawner_paintable",
		"Epidermis Spawner",
		"Spawns a paintable epidermis that copies your skin. Use your bare hands on the paintable:",
		"- Left-click (punch) to swap skins",
		"- Right-click (interact) to open the control panel, which allows " .. table.concat({
			"toggling backface culling",
			"changing rotation",
			"previewing the texture",
			"playing the animation",
			"picking a texture from and uploading to SkinDB"
		}, ", ") .. "."
	),
	item_(
		"epidermis:spawner_colorpicker",
		"HSV Colorpicker Spawner",
		"Spawns a HSV color picker if a node is pointed. The colorpicker is oriented as if it were wallmounted.",
		"Punch the colorpicker's hue bar to select a hue."
	),
	item_(
		"epidermis:undo_redo",
		"Undo / redo",
		"Left-click to undo the last action, right-click to redo undone actions. "
		.. "Only a limited amount of actions can be undone / redone."
	),
	item_(
		"epidermis:eraser",
		"Eraser",
		"Left-click to mark a pixel as transparent, "
		.. "right-click to restore opacity of the first transparent pixel above the pointed pixel."
	),
	tags.b({
		"The painting tools below support right-clicking an epidermis or HSV color picker to choose a color. ",
		"If nothing is pointed, you will be shown a RGB color picker.",
	}),
	"\n",
	item_("epidermis:pen", "Pen", "Left-click to set a single pixel."),
	item_("epidermis:filling_bucket", "Filling Bucket",
		"Left-click to fill pixels of (exactly) the same color on the texture."),
	item_("epidermis:line", "Line", "Drag to draw a line. The line is drawn on the texture, not the model."),
	item_(
		"epidermis:rectangle",
		"Rectangle",
		"Drag to draw a rectangle. The rectangle is drawn on the texture, not the model."
	),
}
local rope = {}
local function write(text)
	return table.insert(rope, text)
end
local function write_element(element)
	local tag_name = element[true]
	if tag_name then
		write("<")
		write(tag_name)
		for k, v in pairs(element) do
			if type(k) == "string" then
				write(" ")
				write(k)
				write("=")
				write(v)
			end
		end
		write(">")
	end
	if tag_name == "item" or tag_name == "img" or tag_name == "tag" then
		assert(#element == 0)
		-- Self-enclosing tags
		return
	end
	for _, child in ipairs(element) do
		if type(child) == "string" then
			write(child:gsub(".", { ["\\"] = [[\\]], ["<"] = [[\<]] }))
		else
			write_element(child)
		end
	end
	if tag_name then
		write("</")
		write(tag_name)
		write(">")
	end
end
write_element(help)
local text = minetest.formspec_escape(table.concat(rope))
local formspec = ([[
size[8.5,5.25,false]
real_coordinates[true]
image_button_exit[7.75,0.25;0.5,0.5;epidermis_cross.png;close;]
tooltip[close;Close]
hypertext[0.25,0.25;7.5,4.75;help;<big><b>Epidermis Guide</b></big>]
hypertext[0.25,0.75;8,4.25;help;%s]
]]):format(text)

function epidermis.show_guide_formspec(player)
	minetest.show_formspec(player:get_player_name(), "epidermis:guide", formspec)
end

minetest.register_chatcommand("epidermis_guide", {
	description = "Open the Epidermis Guide",
	params = "",
	func = function(name)
		local player = minetest.get_player_by_name(name)
		if not player then
			return false, "Command only available to players"
		end
		epidermis.show_guide_formspec(player)
	end
})

epidermis.register_tool("epidermis:guide", {
	description = "Epidermis Guide",
	inventory_image = "epidermis_book.png",
	on_use = function(_, user)
		epidermis.show_guide_formspec(user)
	end,
})


