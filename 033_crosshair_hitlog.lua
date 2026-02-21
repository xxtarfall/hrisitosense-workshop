-- Title: Crosshair hitlog
-- Script ID: 33
-- Source: page_33.html
----------------------------------------

-- local variables for API functions. any changes to the line below will be lost on re-generation
local entity_get_player_name, entity_get_prop, globals_curtime, math_max, renderer_text, renderer_rectangle, renderer_measure_text, table_insert, table_remove, ui_get, ui_set_visible, client_set_event_callback, client_unset_event_callback = 
      entity.get_player_name, entity.get_prop, globals.curtime, math.max, renderer.text, renderer.rectangle, renderer.measure_text, table.insert, table.remove, ui.get, ui.set_visible, client.set_event_callback, client.unset_event_callback

--variables
local w, h = client.screen_size()
local center = { w/2, h/2 }
local offset
local time
local ra, ga, ba, aa
local shots = {}

--callbacks
local function on_paint()
	local removeindex = {}
	for i = 1, #shots do
		local r, g, b, a = 0, 0, 0, (aa*math_max(0, (0 - ((globals_curtime() - shots[i][3]) - time) / time)))
		if a <= 0 or a > 255 then
			removeindex[#removeindex+1] = i
		else
			cur_shot = shots[i]
			local flag = "r"
			if cur_shot[1] == 2 then
				r, g, b = 255, 255, 70
				flag = "rb"
			elseif cur_shot[1] == 1 then
				r, g, b = 0, 255, 0
			else
				r, g, b = 255, 50, 0
			end
			local y = (offset >= 0) and (center[2] - offset - (i * 12)) or (center[2] - offset + (i * 12))
			renderer_text(center[1]-2, y, r, g, b, a, flag, 0, cur_shot[2])
			renderer_text(center[1]+2, y, ra,ga,ba,a, "b", 0, cur_shot[4])
			if cur_shot[5] then 
				renderer_rectangle(center[1]+3, y+7, renderer_measure_text("b", cur_shot[4])+2, 2, 0, 0, 0, a/2)
				renderer_rectangle(center[1]+2, y+6, renderer_measure_text("b", cur_shot[4])+2, 2, 255, 50, 0, a)
			end
		end
	end

	for i = 1, #removeindex do
		table_remove(shots, removeindex[i])
	end
end

local function on_aim_hit(event)
	table_insert(shots, { 
		(event.hitgroup == 1) and 2 or 1, 
		event.damage, 
		globals_curtime(), 
		entity_get_player_name(event.target),
		(entity_get_prop(event.target, "m_iHealth") <= 0)
	})
end

local function on_aim_miss(event)
	table_insert(shots, { 
		0, 
		event.reason, 
		globals_curtime(), 
		entity_get_player_name(event.target),
		false
	})
end

local function on_level_init()
	shots = {}
end

-- menu
local enable, color, s_offset, s_fadetime

local function on_checkbox_toggle(enable)
	local state = ui_get(enable)
	local update_callback = state and client_set_event_callback or client_unset_event_callback
	update_callback("paint", on_paint)
	update_callback("aim_hit", on_aim_hit)
	update_callback("aim_miss", on_aim_miss)
	update_callback("level_init", on_level_init)
	ui_set_visible(color, state)
	ui_set_visible(s_offset, state)
	ui_set_visible(s_fadetime, state)
end

do
	enable = ui.new_checkbox("VISUALS", "Effects", "Simple hitlog")
	color = ui.new_color_picker("VISUALS", "Effects", "Simple hitlog color", 255, 255, 255, 255)
	s_offset = ui.new_slider("VISUALS", "Effects", "\nHitlog offset", -500, 500, 128, true, "px")
	s_fadetime = ui.new_slider("VISUALS", "Effects", "\nHitlog fade time", 1, 15, 4, true, "s")

	ui.set_callback(color, function(self)
	    ra, ga, ba, aa = ui_get(self)
	end)
	ra, ga, ba, aa = ui_get(color)

	ui.set_callback(s_offset, function(self)
	    offset = ui_get(self)
	end)
	offset = ui_get(s_offset)

	ui.set_callback(s_fadetime, function(self)
	    time = ui_get(self)
	end)
	time = ui_get(s_fadetime)

	ui.set_callback(enable, on_checkbox_toggle)
	on_checkbox_toggle(enable)
end-- dumped from hrisito forums by <youtube.com/@subtick> ~ rip hrisito 2025-2026
