-- Title: Show viewmodel in scope
-- Script ID: 106
-- Source: page_106.html
----------------------------------------

-- *Show viewmodel in scope
local csgo_weapons = require "gamesense/csgo_weapons"
local table_clear = require "table.clear"
local ui_get = ui.get
local dirty_weaponinfo = {}

local function enable()
	for idx, weapon in pairs(csgo_weapons) do
		if weapon.raw.hide_view_model_zoomed then
			table.insert(dirty_weaponinfo, idx)
			weapon.raw.hide_view_model_zoomed = false
		end
	end
end

local function disable()
	for i=1, #dirty_weaponinfo do
		local idx = dirty_weaponinfo[i]
		csgo_weapons[idx].raw.hide_view_model_zoomed = true
	end
	table_clear(dirty_weaponinfo)
end

local enabled_reference = ui.new_checkbox("VISUALS", "Effects", "Show viewmodel in scope")

ui.set_callback(enabled_reference, function()
	if ui_get(enabled_reference) then
		enable()
	else
		disable()
	end
end)

client.set_event_callback("shutdown", disable)-- dumped from hrisito forums by <youtube.com/@subtick> ~ rip hrisito 2025-2026
