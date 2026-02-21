-- Title: Cinematic black bars
-- Script ID: 24
-- Source: page_24.html
----------------------------------------

---------------------------------------------------------------
-- CINEMATIC BLACK BARS by engineer
---------------------------------------------------------------
-- Change this value depending on where you want the settings ("A" or "B")
local container = "A"

local screen_width, screen_height = client.screen_size()
local default_bar_height = math.floor((5 / 21) * screen_height / 2 + 0.5)

local enabled = ui.new_checkbox("LUA", container, "Cinematic black bars")
local hotkey = ui.new_hotkey("LUA", container, "Cinematic black bars hotkey", true)
local color_picker = ui.new_color_picker("LUA", container, "Cinematic black bars color", 0, 0, 0, 255)
local bar_height_slider = ui.new_slider("LUA", container, "\n Cinematic black bars height", 1, screen_height / 2, default_bar_height, true, "px")

ui.set(hotkey, "Always on")

local default_safezoney = 0
local state = 0

local function reset()
	default_safezoney = tonumber(cvar.safezoney:get_string())
	cvar.safezoney:set_raw_float(default_safezoney)
	ui.set_visible(color_picker, ui.get(enabled))
	ui.set_visible(bar_height_slider, ui.get(enabled))
end

reset()
ui.set_callback(enabled, reset)
client.set_event_callback("shutdown", reset)

client.set_event_callback("paint_ui", function()
	local active = ui.get(enabled) and ui.get(hotkey)
	state = math.max(0, math.min(1, state + 0.02 * (active and 1 or -1)))

	local smooth = (math.sin(state * math.pi - math.pi / 2) + 1) / 2
	
	local bar_height = ui.get(bar_height_slider)
	local color = {ui.get(color_picker)}

	renderer.rectangle(0, 0, screen_width, bar_height * smooth, color[1], color[2], color[3], color[4])
	renderer.rectangle(0, screen_height, screen_width, bar_height * smooth * -1, color[1], color[2], color[3], color[4])

	local safezoney = ((screen_height - bar_height * smooth * 2) / (screen_height)) * default_safezoney
	cvar.safezoney:set_raw_float(safezoney)
end)-- dumped from hrisito forums by <youtube.com/@subtick> ~ rip hrisito 2025-2026
