-- Title: Auto Hold this position for bots
-- Script ID: 5
-- Source: page_5.html
----------------------------------------

local bit_band = require("bit").band
local entity_get_prop = entity.get_prop
local entity_get_players = entity.get_players
local entity_is_enemy = entity.is_enemy
local client_exec = client.exec

local function hold_bots()
	local players = entity_get_players()

	if players == nil then
		return
	end

	for i = 1, #players do
		local player = players[i]

		if not entity_is_enemy(player) then
			local is_bot = entity_get_prop(player, "m_fFlags")

			if is_bot and bit_band(is_bot, 512) == 512 then
				client_exec("holdpos")

				return
			end
		end
	end
end

client.set_event_callback("round_freeze_end", hold_bots)-- dumped from hrisito forums by <youtube.com/@subtick> ~ rip hrisito 2025-2026
