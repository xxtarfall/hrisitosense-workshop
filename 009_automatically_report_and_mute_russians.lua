-- Title: Automatically report and mute russians
-- Script ID: 9
-- Source: page_9.html
----------------------------------------

local js = panorama.open()
local GameStateAPI = js.GameStateAPI
local FriendsListAPI = js.FriendsListAPI
local alphabet = { "А", "Б", "В", "Г", "Д", "Е", "Ё", "Ж", "З", "И", "Й", "К", "Л", "М", "Н", "О", "П", "Р", "С", "Т", "У", "Ф", "Х", "Ц", "Ч", "Ш", "Щ", "Ъ", "Ы", "Ь", "Э", "Ю", "Я", "а", "б", "в", "г", "д", "е", "ё", "ж", "з", "и", "й", "к", "л", "м", "н", "о", "п", "р", "с", "т", "ф", "х", "ц", "ч", "ш", "щ", "ъ", "ы", "ь", "э", "ю", "я" }
local type = ui.new_multiselect("lua", "a", "If cyrillic is found:", "Mute", "Report")
local function multifix(multi, position)
	for i = 1, #multi do
		if multi[i] == position then
			return true
		end
	end
	return false
end
local function reportenemy(enemy, name)
	if multifix(ui.get(type), "Report") then
		GameStateAPI.SubmitPlayerReport(enemy, "textabuse, voiceabuse")
		print("Enemy reported, " .. name .. " " .. enemy)
	elseif multifix(ui.get(type), "Mute") then
		FriendsListAPI.ToggleMute(enemy)
		print("Enemy muted, " .. name .. " " .. enemy)
	end
end
client.set_event_callback("player_chat", function(e)
	if e.entity == entity.get_local_player() then return end
	for i, v in pairs(alphabet) do
		if string.find(e.text, alphabet[i]) then
			local xuid = GameStateAPI.GetPlayerXuidStringFromEntIndex(e.entity)
			reportenemy(xuid, e.name)
		end
	end
end)-- dumped from hrisito forums by <youtube.com/@subtick> ~ rip hrisito 2025-2026
