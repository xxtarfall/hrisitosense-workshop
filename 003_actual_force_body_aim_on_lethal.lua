-- Title: Actual force body aim on lethal
-- Script ID: 3
-- Source: page_3.html
----------------------------------------

local enable = ui.new_checkbox("RAGE", "Other", "Force body aim if lethal")
local weapons = ui.new_multiselect("RAGE", "Other", "Enabled weapons", { "Scout", "Awp", "Auto", "R8 revolver", "Deagle", "Other" })
local csgo_weapons = require("gamesense/csgo_weapons")
local vector = require "vector"

local contains = function(table, value)
	for _, v in ipairs(ui.get(table)) do
		if v == value then return true end
	end
	return false
end

local weapon_is_enabled = function(idx)
	if (idx == 38 or idx == 11) and contains(weapons, "Auto") then
		return true
	elseif (idx == 40) and contains(weapons, "Scout") then
		return true
	elseif (idx == 9) and contains(weapons, "Awp") then
		return true
	elseif (idx == 64) and contains(weapons, "R8 revolver") then
		return true
	elseif (idx == 1) and contains(weapons, "Deagle") then
		return true
	elseif contains(weapons, "Other") then
		return true
	end
	return false
end

local is_lethal = function(player)
    local local_player = entity.get_local_player()
    if local_player == nil or not entity.is_alive(local_player) then return end
    local local_origin = vector(entity.get_prop(local_player, "m_vecAbsOrigin"))
    local distance = local_origin:dist(vector(entity.get_prop(player, "m_vecOrigin")))
    local enemy_health = entity.get_prop(player, "m_iHealth")

	local weapon_ent = entity.get_player_weapon(entity.get_local_player())
	if weapon_ent == nil then return end
	
	local weapon_idx = entity.get_prop(weapon_ent, "m_iItemDefinitionIndex")
	if weapon_idx == nil then return end
	
	local weapon = csgo_weapons[weapon_idx]
	if weapon == nil then return end

	if not weapon_is_enabled(weapon_idx) or not ui.get(enable) then return end

	local dmg_after_range = (weapon.damage * math.pow(weapon.range_modifier, (distance * 0.002))) * 1.25
	local armor = entity.get_prop(player,"m_ArmorValue")
	local newdmg = dmg_after_range * (weapon.armor_ratio * 0.5)
	if dmg_after_range - (dmg_after_range * (weapon.armor_ratio * 0.5)) * 0.5 > armor then
		newdmg = dmg_after_range - (armor / 0.5)
	end
	return newdmg >= enemy_health
end

local on_run_command = function()
	local enemies = entity.get_players(true)
    for i = 1, #enemies do
        if enemies[i] == nil then return end
		local value = is_lethal(enemies[i]) and "Force" or "-"
		plist.set(enemies[i], "Override prefer body aim", value)
	end
end

client["set_event_callback"]("run_command", on_run_command)
client["set_event_callback"]("paint_ui", function() 
	ui.set_visible(weapons, ui.get(enable)) 
end)
client["register_esp_flag"]("BAIM", 255, 20, 20, function(ent)
    return is_lethal(ent)
end)-- dumped from hrisito forums by <youtube.com/@subtick> ~ rip hrisito 2025-2026
