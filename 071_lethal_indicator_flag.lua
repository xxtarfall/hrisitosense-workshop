-- Title: LETHAL indicator flag
-- Script ID: 71
-- Source: page_71.html
----------------------------------------

local client_register_esp_flag, client_trace_bullet, entity_get_local_player, entity_get_prop, entity_hitbox_position, entity_is_alive, entity_is_enemy = client.register_esp_flag, client.trace_bullet, entity.get_local_player, entity.get_prop, entity.hitbox_position, entity.is_alive, entity.is_enemy

client_register_esp_flag("LETHAL", 255, 0, 0, function(c)
	if entity_is_alive(entity_get_local_player()) and entity_is_enemy(c) then
		local pelvis = { entity_hitbox_position(c, "pelvis") }
		if #pelvis == 3 then
			local _, dmg = client_trace_bullet(entity_get_local_player(), pelvis[1]-1, pelvis[2]-1, pelvis[3]-1, pelvis[1], pelvis[2], pelvis[3], true)
			return (entity_get_prop(c, "m_iHealth") <= dmg)
		end
	end
end)-- dumped from hrisito forums by <youtube.com/@subtick> ~ rip hrisito 2025-2026
