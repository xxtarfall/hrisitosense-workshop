-- Title: Skybox changer
-- Script ID: 107
-- Source: page_107.html
----------------------------------------

-- local variables for API functions. any changes to the line below will be lost on re-generation
local client_delay_call, client_set_event_callback, client_userid_to_entindex, entity_get_local_player, materialsystem_find_materials, pairs, table_insert, table_sort, ui_get, ui_new_checkbox, ui_new_color_picker, ui_new_listbox, ui_set_callback, ui_set_visible, type = client.delay_call, client.set_event_callback, client.userid_to_entindex, entity.get_local_player, materialsystem.find_materials, pairs, table.insert, table.sort, ui.get, ui.new_checkbox, ui.new_color_picker, ui.new_listbox, ui.set_callback, ui.set_visible, type

local package_searchpath = package.searchpath
local function file_exists(filename)
	return package_searchpath("", filename) == filename
end

local function skybox_exists(skybox_name)
	return file_exists("./csgo/materials/skybox/" .. skybox_name .. "up.vmt")
end

local sv_skyname = cvar.sv_skyname
local skyboxes = {
	["Tibet"]="cs_tibet",
	["Baggage"]="cs_baggage_skybox_",
	["Monastery"]="embassy",
	["Italy"]="italy",
	["Aztec"]="jungle",
	["Vertigo"]="office",
	["Daylight"]="sky_cs15_daylight01_hdr",
	["Daylight (2)"]="vertigoblue_hdr",
	["Clouds"]="sky_cs15_daylight02_hdr",
	["Clouds (2)"]="vertigo",
	["Gray"]="sky_day02_05_hdr",
	["Clear"]="nukeblank",
	["Canals"]="sky_venice",
	["Cobblestone"]="sky_cs15_daylight03_hdr",
	["Assault"]="sky_cs15_daylight04_hdr",
	["Clouds (Dark)"]="sky_csgo_cloudy01",
	["Night"]="sky_csgo_night02",
	["Night (2)"]="sky_csgo_night02b",
	["Night (Flat)"]="sky_csgo_night_flat",
	["Dusty"]="sky_dust",
	["Rainy"]="vietnam",
	["Custom: Sunrise"]="amethyst",
	["Custom: Galaxy"]="sky_descent",
	["Custom: Galaxy (2)"]="clear_night_sky",
	["Custom: Galaxy (3)"]="otherworld",
	["Custom: Galaxy (4)"]="mpa112",
	["Custom: Clouds (Night)"]="cloudynight",
	["Custom: Ocean"]="dreamyocean",
	["Custom: Grimm Night"]="grimmnight",
	["Custom: Heaven"]="sky051",
	["Custom: Heaven (2)"]="sky081",
	["Custom: Clouds"]="sky091",
	["Custom: Night (Blue)"]="sky561",
}

local skybox_names = {}
for k,v in pairs(skyboxes) do
	if k:sub(0, 8) ~= "Custom: " or skybox_exists(v) then
	  table_insert(skybox_names, k)
	end
end
table_sort(skybox_names)

local enabled_reference = ui_new_checkbox("VISUALS", "Effects", "Override skybox")
local color_reference = ui_new_color_picker("VISUALS", "Effects", "Override skybox", 255, 255, 255, 255)
local skybox_reference = ui_new_listbox("VISUALS", "Effects", "Override skybox name", skybox_names)

local enabled_prev, skyname_default = false, nil

local function on_color_changed()
	local enabled = ui_get(enabled_reference)
	if enabled or enabled_prev then
		local r, g, b, a = ui_get(color_reference)
		if not enabled then
			r, g, b, a = 255, 255, 255, 255
		end
		local materials = materialsystem_find_materials("skybox/")
		for i=1, #materials do
			materials[i]:color_modulate(r, g, b)
			materials[i]:alpha_modulate(a)
		end
	end
end
ui_set_callback(color_reference, on_color_changed)

local function on_skybox_changed()
	local enabled = ui_get(enabled_reference)

	ui_set_visible(skybox_reference, enabled)
	if enabled then
		local skybox = ui_get(skybox_reference)
		if type(skybox) == "number" then
			skybox = skybox_names[skybox+1]
		end

		if skyname_default == nil then
			skyname_default = sv_skyname:get_string()
		end

		sv_skyname:set_string(skyboxes[skybox])
		--check if new skybox is loaded, if not delay color update
		if #(materialsystem_find_materials("skybox/" .. skybox)) == 0 then
			client_delay_call(0.2, on_color_changed)
		else
			on_color_changed()
		end
	elseif enabled_prev then
		if skyname_default ~= nil then
			sv_skyname:set_string(skyname_default)
		end
	end
	on_color_changed()
	enabled_prev = enabled
end
ui_set_callback(enabled_reference, on_skybox_changed)
ui_set_callback(skybox_reference, on_skybox_changed)
on_skybox_changed()

local function on_player_connect_full(e)
	if client_userid_to_entindex(e.userid) == entity_get_local_player() then
		skyname_default = nil
		on_skybox_changed()
		on_color_changed()
	end
end
client_set_event_callback("player_connect_full", on_player_connect_full)

local function on_shutdown()
	if skyname_default ~= nil and ui_get(enabled_reference) then
		sv_skyname:set_string(skyname_default)
	end
end
client_set_event_callback("shutdown", on_shutdown)-- dumped from hrisito forums by <youtube.com/@subtick> ~ rip hrisito 2025-2026
