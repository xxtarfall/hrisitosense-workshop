-- Title: Hit/miss logs
-- Script ID: 158
-- Source: page_158.html
----------------------------------------

local enabled = ui.new_checkbox("RAGE", "Other", "Hit Logs")
local hit_color = ui.new_color_picker("RAGE", "Other", "Hit Color", 47, 202, 159, 255)
local miss_color = ui.new_color_picker("RAGE", "Other", "Miss Color", 255, 100, 100, 255)
local log_duration = ui.new_slider("RAGE", "Other", "\nLog Duration", 1, 10, 4, true, "s")
local console_logs = ui.new_checkbox("RAGE", "Other", "Console Logs")

local hitgroup_names = {
    [0] = "generic",
    [1] = "head",
    [2] = "chest", 
    [3] = "stomach",
    [4] = "left arm",
    [5] = "right arm",
    [6] = "left leg",
    [7] = "right leg",
    [8] = "neck",
    [9] = "?",
    [10] = "gear"
}

local logs = {}
local max_logs = 5

local shot_data = {}

local function get_hitgroup_name(hitgroup)
    return hitgroup_names[hitgroup] or "?"
end

local function on_aim_fire(e)
    shot_data[e.id] = {
        tick = e.tick
    }
end

local function add_log(text, is_hit)
    local log = {
        text = text,
        time = globals.realtime(),
        is_hit = is_hit,
        alpha = 0
    }
    table.insert(logs, log)
    
    if #logs > max_logs then
        table.remove(logs, 1)
    end
end

local function on_aim_hit(e)
    if not ui.get(enabled) then return end
    
    local target_name = entity.get_player_name(e.target)
    local hitgroup = get_hitgroup_name(e.hitgroup)
    local damage = e.damage
    local health_remaining = entity.get_prop(e.target, "m_iHealth")
    
    local backtrack_ticks = 0
    if shot_data[e.id] and shot_data[e.id].tick then
        backtrack_ticks = globals.tickcount() - shot_data[e.id].tick
    end
    
    local body_yaw = entity.get_prop(e.target, "m_flPoseParameter", 11)
    local desync = 0
    
    if body_yaw ~= nil then
        desync = math.floor((body_yaw * 120) - 60)
    end
    
    if health_remaining < 0 then
        health_remaining = 0
    end
    
    local log_data = {
        type = "hit",
        parts = {
            {text = "Hit ", colored = false},
            {text = target_name, colored = true},
            {text = " in the ", colored = false},
            {text = hitgroup, colored = true},
            {text = " for ", colored = false},
            {text = tostring(damage), colored = true},
            {text = " damage (", colored = false},
            {text = tostring(health_remaining), colored = true},
            {text = " health remaining) [bt: ", colored = false},
            {text = tostring(backtrack_ticks), colored = true},
            {text = " | Desync: ", colored = false},
            {text = tostring(desync) .. "°", colored = true},
            {text = "]", colored = false}
        }
    }
    
    add_log(log_data, true)
    
    if ui.get(console_logs) then
        local console_text = string.format("Hit %s in the %s for %d damage (%d health remaining) [bt: %d | Desync: %d°]",
            target_name, hitgroup, damage, health_remaining, backtrack_ticks, desync)
        print(console_text)
    end
    
    shot_data[e.id] = nil
end

local function on_aim_miss(e)
    if not ui.get(enabled) then return end
    
    local target_name = entity.get_player_name(e.target)
    local hitgroup = get_hitgroup_name(e.hitgroup)
    local reason = e.reason
    local hitchance = math.floor(e.hit_chance + 0.5)
    
    local backtrack_ticks = 0
    if shot_data[e.id] and shot_data[e.id].tick then
        backtrack_ticks = globals.tickcount() - shot_data[e.id].tick
    end
    
    local body_yaw = entity.get_prop(e.target, "m_flPoseParameter", 11)
    local desync = 0
    
    if body_yaw ~= nil then
        desync = math.floor((body_yaw * 120) - 60)
    end
    
    local log_data = {
        type = "miss",
        parts = {
            {text = "Missed ", colored = false},
            {text = target_name, colored = true},
            {text = " in the ", colored = false},
            {text = hitgroup, colored = true},
            {text = " due to ", colored = false},
            {text = reason, colored = true},
            {text = " (", colored = false},
            {text = tostring(hitchance) .. "%", colored = true},
            {text = " hitchance) [bt: ", colored = false},
            {text = tostring(backtrack_ticks), colored = true},
            {text = " | Desync: ", colored = false},
            {text = tostring(desync) .. "°", colored = true},
            {text = "]", colored = false}
        }
    }
    
    add_log(log_data, false)
    
    if ui.get(console_logs) then
        local console_text = string.format("Missed %s in the %s due to %s (%d%% hitchance) [bt: %d | Desync: %d°]",
            target_name, hitgroup, reason, hitchance, backtrack_ticks, desync)
        print(console_text)
    end
    
    shot_data[e.id] = nil
end

local function on_paint()
    if not ui.get(enabled) then return end
    
    local screen_x, screen_y = client.screen_size()
    local center_x = screen_x / 2
    local start_y = screen_y / 2 + 250
    
    local current_time = globals.realtime()
    local duration = ui.get(log_duration)
    
    local hit_r, hit_g, hit_b, hit_a = ui.get(hit_color)
    local miss_r, miss_g, miss_b, miss_a = ui.get(miss_color)
    
    local offset = 0
    for i = #logs, 1, -1 do
        local log = logs[i]
        local time_alive = current_time - log.time
        

        if time_alive > duration then
            table.remove(logs, i)
        else
            local alpha = 255
            if time_alive < 0.3 then
                alpha = (time_alive / 0.3) * 255
            elseif time_alive > (duration - 0.5) then
                alpha = ((duration - time_alive) / 0.5) * 255
            end
            
            local r, g, b
            if log.is_hit then
                r, g, b = hit_r, hit_g, hit_b
            else
                r, g, b = miss_r, miss_g, miss_b
            end
            
            local total_width = 0
            for _, part in ipairs(log.text.parts) do
                local w, h = renderer.measure_text(nil, part.text)
                total_width = total_width + w
            end
            
            local current_x = center_x - (total_width / 2)
            local y = start_y + offset
            
            for _, part in ipairs(log.text.parts) do
                local text_r, text_g, text_b
                
                if part.colored then
                    text_r, text_g, text_b = r, g, b
                else
                    text_r, text_g, text_b = 255, 255, 255
                end
                

                renderer.text(current_x + 1, y + 1, 0, 0, 0, alpha, "", 0, part.text)
                renderer.text(current_x, y, text_r, text_g, text_b, alpha, "", 0, part.text)
                
                local w, h = renderer.measure_text(nil, part.text)
                current_x = current_x + w
            end
            
            offset = offset + 15
        end
    end
end

client.set_event_callback("aim_fire", on_aim_fire)
client.set_event_callback("aim_hit", on_aim_hit)
client.set_event_callback("aim_miss", on_aim_miss)
client.set_event_callback("paint", on_paint)-- dumped from hrisito forums by <youtube.com/@subtick> ~ rip hrisito 2025-2026
