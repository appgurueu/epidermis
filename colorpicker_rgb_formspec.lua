local function get_gradient_texture(component, color)
	local old_value = color[component]
	color[component] = 255
	local texture = ("epxw.png^[multiply:%s^[resize:256x1^[mask:epidermis_gradient_%s.png")
		:format(color:to_string(), component)
	color[component] = old_value
	return texture
end

function epidermis.show_colorpicker_formspec(player, color, callback)
	local function show_colorpicker_formspec()
		local fs = {
			"size[8.5,5.25,false]",
			"real_coordinates[true]",
			"scrollbaroptions[min=0;max=255;smallstep=1;largestep=25;thumbsize=1;arrows=show]",
			"label[0.25,0.5;Pick a color:]",
			("image[3,0.25;0.5,0.5;epxw.png^[multiply:%s]"):format(color:to_string()),
			("field[3.5,0.25;2,0.5;color;;%s]"):format(color:to_string()),
			"field_close_on_enter[color;false]",
			("image_button[5,0.25;0.5,0.5;%s;random;]"):format(minetest.formspec_escape(epidermis.textures.dice)),
			"tooltip[random;Random color]",
			"image_button_exit[7.25,0.25;0.5,0.5;epidermis_check.png;set;]",
			"tooltip[set;Set color]",
			"image_button_exit[7.75,0.25;0.5,0.5;epidermis_cross.png;cancel;]",
			"tooltip[cancel;Cancel]",
		}
		for index, component in ipairs{"Red", "Green", "Blue"} do
			local component_short = component:sub(1, 1):lower()
			local y = 0.25 + index * 1.25
			table.insert(fs, ("scrollbar[0.25,%f;8,0.5;horizontal;%s;%d]"):format(y, component_short, color[component_short]))
			table.insert(fs, ("label[0.25,%f;%s]")
				:format(y + 0.75, minetest.colorize(("#%06X"):format(0xFF * 0x100 ^ (3 - index)), component:sub(1, 1))))
			table.insert(fs, ("image[0.75,%f;6.5,0.5;%s]"):format(y + 0.5, get_gradient_texture(component_short, color)))
			table.insert(fs, ("field[7.25,%f;1,0.5;field_%s;;%s]"):format(y + 0.5, component_short, color[component_short]))
			table.insert(fs, ("field_close_on_enter[field_%s;false]"):format(component_short))
		end
		epidermis.show_formspec(player, table.concat(fs), function(fields)
			if fields.random then
				color = modlib.minetest.colorspec.new{
					r = math.random(0, 255),
					g = math.random(0, 255),
					b = math.random(0, 255)
				}
				show_colorpicker_formspec()
				return
			end
			if fields.quit then
				if fields.set or fields.key_enter then
					callback(color)
					return
				end
				callback()
				return
			end
			local key_enter_field = fields.key_enter_field
			local value = fields[key_enter_field]
			if key_enter_field and value then
				if key_enter_field == "color" then
					local new_color = modlib.minetest.colorspec.from_string(value)
					if not new_color then return end -- invalid colorstring
					new_color = new_color or color
					new_color.a = 255 -- HACK the colorpicker doesn't support alpha
					color = new_color
					show_colorpicker_formspec()
					return
				end
				local short_component = ({field_r = "r", field_g = "g", field_b = "b"})[key_enter_field]
				if not short_component then return end
				if not value:match"^%d+$" then return end
				color[short_component] = math.min(tonumber(value), 255)
				show_colorpicker_formspec()
				return
			end
			for _, short_component in pairs{"r", "g", "b"} do
				if fields[short_component] then
					local field = minetest.explode_scrollbar_event(fields[short_component])
					if field.type == "CHG" then
						color[short_component] = math.max(0, math.min(field.value, 255))
						show_colorpicker_formspec()
						return
					end
				end
			end
		end)
	end
	show_colorpicker_formspec()
end