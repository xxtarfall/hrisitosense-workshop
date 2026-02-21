-- Title: better china hat
-- Script ID: 161
-- Source: page_161.html
----------------------------------------

-- Local references for performance
local lp = entity.get_local_player
local floor, ceil, abs = math.floor, math.ceil, math.abs
local sin, cos, sqrt = math.sin, math.cos, math.sqrt
local min, max = math.min, math.max
local band, rshift = bit.band, bit.rshift
local insert, remove = table.insert, table.remove
local unpack = unpack
local TWO_PI = math.pi * 2

-- Notification System (Optimized)
local notifications = {}
do
    local notif_queue = {}
    local max_notifs = 5
    local notif_duration = 4
    local screen_cache = {w = 0, h = 0, last_update = 0}
    
    function notifications.add(text, r, g, b)
        insert(notif_queue, 1, {
            text = text,
            time = globals.realtime(),
            alpha = 0,
            y = 0,
            r = r or 255,
            g = g or 255,
            b = b or 255
        })
        
        while #notif_queue > max_notifs do
            remove(notif_queue)
        end
    end
    
    function notifications.draw()
        if #notif_queue == 0 then return end
        
        local time = globals.realtime()
        
        if time - screen_cache.last_update > 1 then
            screen_cache.w, screen_cache.h = client.screen_size()
            screen_cache.last_update = time
        end
        
        local start_y = screen_cache.h * 0.1
        local spacing = 25
        
        for i = #notif_queue, 1, -1 do
            local n = notif_queue[i]
            local age = time - n.time
            
            if age < 0.3 then
                n.alpha = age * 850
            elseif age > notif_duration - 0.5 then
                n.alpha = (notif_duration - age) * 510
            else
                n.alpha = 255
            end
            
            if age > notif_duration then
                remove(notif_queue, i)
                goto continue
            end
            
            local target_y = start_y + (i - 1) * spacing
            n.y = n.y + (target_y - n.y) * 0.1
            
            local tw, th = renderer.measure_text("", n.text)
            local bw, bh = tw + 20, th + 10
            local bx = screen_cache.w * 0.5 - bw * 0.5
            local alpha = n.alpha
            
            renderer.rectangle(bx, n.y, bw, bh, 20, 20, 20, alpha * 0.9)
            renderer.rectangle(bx, n.y, 3, bh, n.r, n.g, n.b, alpha)
            renderer.rectangle(bx, n.y, bw, 1, 60, 60, 60, alpha * 0.8)
            renderer.rectangle(bx, n.y + bh - 1, bw, 1, 60, 60, 60, alpha * 0.8)
            renderer.rectangle(bx, n.y, 1, bh, 60, 60, 60, alpha * 0.8)
            renderer.rectangle(bx + bw - 1, n.y, 1, bh, 60, 60, 60, alpha * 0.8)
            renderer.text(bx + 10, n.y + 5, 255, 255, 255, alpha, "", 0, n.text)
            
            ::continue::
        end
    end
    
    notifications.success = function(t) notifications.add(t, 100, 255, 100) end
    notifications.error = function(t) notifications.add(t, 255, 100, 100) end
    notifications.info = function(t) notifications.add(t, 100, 150, 255) end
    notifications.warning = function(t) notifications.add(t, 255, 200, 100) end
end

-- Config System (Optimized)
local config_system = {}
do
    local BASE64_KEY = 'bjW9MagJsut5xDz36Hvl74nC8Eoy0GIUVX2NLQepckFfrBYOhRZKAwmSqidP1T+/='
    local db_cache = nil
    local db_dirty = false
    
    local function b64_encode(data)
        local bytes, result = {}, {}
        
        for i = 1, #data do
            bytes[i] = data:byte(i)
        end
        
        for i = 1, #bytes, 3 do
            local b1, b2, b3 = bytes[i], bytes[i+1] or 0, bytes[i+2] or 0
            local n = b1 * 65536 + b2 * 256 + b3
            
            result[#result + 1] = BASE64_KEY:sub(rshift(band(n, 16515072), 18) + 1, rshift(band(n, 16515072), 18) + 1)
            result[#result + 1] = BASE64_KEY:sub(rshift(band(n, 258048), 12) + 1, rshift(band(n, 258048), 12) + 1)
            result[#result + 1] = bytes[i+1] and BASE64_KEY:sub(rshift(band(n, 4032), 6) + 1, rshift(band(n, 4032), 6) + 1) or '='
            result[#result + 1] = bytes[i+2] and BASE64_KEY:sub(band(n, 63) + 1, band(n, 63) + 1) or '='
        end
        
        return table.concat(result)
    end
    
    local function b64_decode(data)
        data = data:gsub('[^'..BASE64_KEY..'=]', '')
        local result = {}
        
        for i = 1, #data, 4 do
            local c1 = BASE64_KEY:find(data:sub(i, i)) - 1
            local c2 = BASE64_KEY:find(data:sub(i+1, i+1)) - 1
            local c3 = data:sub(i+2, i+2) == '=' and 0 or (BASE64_KEY:find(data:sub(i+2, i+2)) - 1)
            local c4 = data:sub(i+3, i+3) == '=' and 0 or (BASE64_KEY:find(data:sub(i+3, i+3)) - 1)
            
            local n = c1 * 262144 + c2 * 4096 + c3 * 64 + c4
            
            result[#result + 1] = string.char(band(rshift(n, 16), 255))
            if data:sub(i+2, i+2) ~= '=' then result[#result + 1] = string.char(band(rshift(n, 8), 255)) end
            if data:sub(i+3, i+3) ~= '=' then result[#result + 1] = string.char(band(n, 255)) end
        end
        
        return table.concat(result)
    end
    
    function config_system.encode(cfg)
        local parts = {}
        for k, v in pairs(cfg) do
            if type(v) == "table" then
                parts[#parts + 1] = k .. ":" .. table.concat(v, ",")
            elseif type(v) == "boolean" then
                parts[#parts + 1] = k .. ":" .. (v and "1" or "0")
            else
                parts[#parts + 1] = k .. ":" .. tostring(v)
            end
        end
        return b64_encode(table.concat(parts, ";"))
    end
    
    function config_system.decode(str)
        if not str or str == "" then return nil end
        
        local ok, decoded = pcall(b64_decode, str)
        if not ok then return nil end
        
        local cfg = {}
        for pair in decoded:gmatch("[^;]+") do
            local k, v = pair:match("([^:]+):(.+)")
            if k and v then
                if v:match(",") then
                    local nums = {}
                    for num in v:gmatch("[^,]+") do
                        nums[#nums + 1] = tonumber(num) or 0
                    end
                    cfg[k] = nums
                elseif v == "1" or v == "0" then
                    cfg[k] = v == "1"
                else
                    cfg[k] = tonumber(v) or v
                end
            end
        end
        return cfg
    end
    
    function config_system.export(cfg)
        local encoded = config_system.encode(cfg)
        local ok = pcall(function()
            require("gamesense/clipboard").set(encoded)
        end)
        
        if ok then
            notifications.success("Config exported to clipboard!")
        else
            notifications.warning("Config printed to console")
            print(encoded)
        end
        return encoded
    end
    
    function config_system.import()
        local encoded
        local ok = pcall(function()
            encoded = require("gamesense/clipboard").get()
        end)
        
        if not ok or not encoded or encoded == "" then
            notifications.error("Failed to get config from clipboard")
            return nil
        end
        
        local cfg = config_system.decode(encoded)
        if cfg then
            notifications.success("Config imported successfully!")
        else
            notifications.error("Invalid config string")
        end
        return cfg
    end
    
    local function get_db()
        if not db_cache then
            db_cache = database.read("chinahat_configs") or {}
        end
        return db_cache
    end
    
    local function save_db()
        if db_dirty then
            database.write("chinahat_configs", db_cache)
            db_dirty = false
        end
    end
    
    function config_system.save(name, cfg)
        get_db()[name] = cfg
        db_dirty = true
        save_db()
    end
    
    function config_system.load(name)
        return get_db()[name]
    end
    
    function config_system.delete(name)
        get_db()[name] = nil
        db_dirty = true
        save_db()
    end
    
    function config_system.list()
        local names = {}
        for k in pairs(get_db()) do
            names[#names + 1] = k
        end
        table.sort(names)
        return names
    end
end

-- UI Elements - China Hat
local enable = ui.new_checkbox("LUA", "A", "Enable China Hat")
local rainbow_mode = ui.new_checkbox("LUA", "A", "Rainbow Mode")
local color = ui.new_color_picker("LUA", "A", "Hat Color", 0, 255, 255, 255)
local rainbow_speed = ui.new_slider("LUA", "A", "Rainbow Speed", 1, 100, 50)
local rainbow_saturation = ui.new_slider("LUA", "A", "Rainbow Saturation", 0, 100, 100)
local alpha_slider = ui.new_slider("LUA", "A", "Hat Opacity", 0, 255, 140)
local segments = ui.new_slider("LUA", "A", "Segments", 8, 64, 32)
local radius = ui.new_slider("LUA", "A", "Radius", 5, 30, 10)
local height_offset = ui.new_slider("LUA", "A", "Height Offset", -20, 30, 8)
local rotate_mode = ui.new_checkbox("LUA", "A", "Rotate Hat")
local rotate_speed = ui.new_slider("LUA", "A", "Rotation Speed", 1, 100, 30)

-- Stroke/Outline settings
local enable_stroke = ui.new_checkbox("LUA", "A", "Enable Outline")
local stroke_color = ui.new_color_picker("LUA", "A", "Outline Color", 0, 0, 0, 255)
local stroke_rainbow = ui.new_checkbox("LUA", "A", "Rainbow Outline")
local stroke_inner = ui.new_checkbox("LUA", "A", "Draw Inner Lines")
local stroke_inner_color = ui.new_color_picker("LUA", "A", "Inner Lines Color", 255, 255, 255, 100)

-- Trail settings
local enable_trail = ui.new_checkbox("LUA", "A", "Enable Head Trails")
local trail_length = ui.new_slider("LUA", "A", "Trail Length", 5, 50, 20)
local trail_rainbow = ui.new_checkbox("LUA", "A", "Rainbow Trails")
local trail_color = ui.new_color_picker("LUA", "A", "Trail Color", 255, 0, 255, 200)
local trail_width = ui.new_slider("LUA", "A", "Trail Width", 1, 10, 3)
local trail_fade = ui.new_checkbox("LUA", "A", "Fade Trails")
local trail_glow = ui.new_checkbox("LUA", "A", "Glow Effect")
local trail_glow_intensity = ui.new_slider("LUA", "A", "Glow Intensity", 1, 10, 5)
local trail_blur = ui.new_checkbox("LUA", "A", "Blur Effect")

-- Leg Trail settings
local enable_leg_trail = ui.new_checkbox("LUA", "A", "Enable Leg Trails")
local leg_trail_both = ui.new_checkbox("LUA", "A", "Both Legs")
local leg_trail_length = ui.new_slider("LUA", "A", "Leg Trail Length", 5, 50, 15)
local leg_trail_rainbow = ui.new_checkbox("LUA", "A", "Rainbow Leg Trails")
local leg_trail_color = ui.new_color_picker("LUA", "A", "Leg Trail Color", 0, 255, 255, 200)
local leg_trail_width = ui.new_slider("LUA", "A", "Leg Trail Width", 1, 20, 3)
local leg_trail_thickness = ui.new_slider("LUA", "A", "Leg Trail Thickness", 1, 15, 5)
local leg_trail_point_size = ui.new_slider("LUA", "A", "Trail Point Size", 0, 10, 2)
local leg_trail_gradient_width = ui.new_checkbox("LUA", "A", "Gradient Width")
local leg_trail_gradient_start = ui.new_slider("LUA", "A", "Start Width %", 10, 100, 100)
local leg_trail_gradient_end = ui.new_slider("LUA", "A", "End Width %", 10, 100, 30)
local leg_trail_smooth = ui.new_checkbox("LUA", "A", "Smooth Trails")
local leg_trail_segments = ui.new_slider("LUA", "A", "Trail Smoothness", 1, 5, 2)
local leg_trail_fade = ui.new_checkbox("LUA", "A", "Fade Leg Trails")
local leg_trail_glow = ui.new_checkbox("LUA", "A", "Leg Glow Effect")
local leg_trail_glow_intensity = ui.new_slider("LUA", "A", "Leg Glow Intensity", 1, 10, 5)

-- Jump Circle settings
local enable_jump_circle = ui.new_checkbox("LUA", "A", "Enable Jump Circle")
local jump_circle_rainbow = ui.new_checkbox("LUA", "A", "Rainbow Jump Circle")
local jump_circle_color = ui.new_color_picker("LUA", "A", "Jump Circle Color", 0, 255, 255, 255)
local jump_circle_duration = ui.new_slider("LUA", "A", "Circle Duration", 5, 30, 15)
local jump_circle_expand = ui.new_checkbox("LUA", "A", "Expanding Circle")
local jump_circle_max_radius = ui.new_slider("LUA", "A", "Max Circle Radius", 20, 200, 80)
local jump_circle_segments = ui.new_slider("LUA", "A", "Circle Quality", 16, 64, 32)
local jump_circle_glow = ui.new_checkbox("LUA", "A", "Circle Glow Effect")
local jump_circle_glow_intensity = ui.new_slider("LUA", "A", "Circle Glow Intensity", 1, 10, 5)
local jump_circle_filled = ui.new_checkbox("LUA", "A", "Filled Circle")

-- Config System UI
ui.new_label("LUA", "A", "———————— Config ————————")
local config_name = ui.new_textbox("LUA", "A", "Config name")
local config_list = ui.new_listbox("LUA", "A", "Configs", {})
local config_load = ui.new_button("LUA", "A", "Load", function() end)
local config_save = ui.new_button("LUA", "A", "Save", function() end)
local config_delete = ui.new_button("LUA", "A", "Delete", function() end)
local config_import = ui.new_button("LUA", "A", "Import from clipboard", function() end)
local config_export = ui.new_button("LUA", "A", "Export to clipboard", function() end)

local thirdperson = {ui.reference("VISUALS", "Effects", "Force third person (alive)")}

-- Storage
local trail_points = {}
local leg_trail_points_left = {}
local leg_trail_points_right = {}
local jump_circles = {}
local last_position = {x = 0, y = 0, z = 0, valid = false}
local last_leg_position_left = {x = 0, y = 0, z = 0, valid = false}
local last_leg_position_right = {x = 0, y = 0, z = 0, valid = false}
local last_on_ground = true
local was_in_thirdperson = false

-- Performance cache
local perf_cache = {
    rainbow_colors = {},
    last_rainbow_update = 0,
    rainbow_step = 0,
    screen_bounds = {x = 0, y = 0, w = 0, h = 0, last_update = 0}
}

-- Update screen bounds
local function update_screen_bounds()
    local time = globals.realtime()
    if time - perf_cache.screen_bounds.last_update > 1 then
        local w, h = client.screen_size()
        perf_cache.screen_bounds = {x = -100, y = -100, w = w + 100, h = h + 100, last_update = time}
    end
end

local function is_on_screen(x, y)
    if not x then return false end
    local b = perf_cache.screen_bounds
    return x >= b.x and x <= b.w and y >= b.y and y <= b.h
end

-- HSV to RGB with LUT
local hsv_lut = {}
local function hsv_to_rgb(h, s, v)
    h = h % 1
    local key = floor(h * 360)
    
    if s == 1 and v == 1 and hsv_lut[key] then
        return unpack(hsv_lut[key])
    end
    
    local i = floor(h * 6)
    local f = h * 6 - i
    local p = v * (1 - s)
    local q = v * (1 - f * s)
    local t = v * (1 - (1 - f) * s)
    
    i = i % 6
    local r, g, b
    if i == 0 then r, g, b = v * 255, t * 255, p * 255
    elseif i == 1 then r, g, b = q * 255, v * 255, p * 255
    elseif i == 2 then r, g, b = p * 255, v * 255, t * 255
    elseif i == 3 then r, g, b = p * 255, q * 255, v * 255
    elseif i == 4 then r, g, b = t * 255, p * 255, v * 255
    else r, g, b = v * 255, p * 255, q * 255 end
    
    if s == 1 and v == 1 then
        hsv_lut[key] = {r, g, b}
    end
    
    return r, g, b
end

local function update_rainbow_cache(count)
    local time = globals.realtime()
    if time - perf_cache.last_rainbow_update < 0.016 then return end
    
    perf_cache.last_rainbow_update = time
    local speed = ui.get(rainbow_speed) * 0.01
    perf_cache.rainbow_step = (time * speed) % 1
    
    perf_cache.rainbow_colors = {}
    for i = 0, count do
        local hue = (perf_cache.rainbow_step + (i / count)) % 1
        perf_cache.rainbow_colors[i] = {hsv_to_rgb(hue, 1, 1)}
    end
end

local function get_rainbow_color_cached(index, total)
    if not perf_cache.rainbow_colors[index] then
        update_rainbow_cache(total)
    end
    return unpack(perf_cache.rainbow_colors[index] or {255, 255, 255})
end

-- Circle cache
local cache = {segments = 0, radius = 0, points = {}}

local function generate_circle_points(seg_count, r)
    if cache.segments == seg_count and cache.radius == r then
        return cache.points
    end
    
    cache.segments = seg_count
    cache.radius = r
    cache.points = {}
    
    local angle_step = TWO_PI / seg_count
    for i = 0, seg_count - 1 do
        local angle = i * angle_step
        cache.points[i + 1] = {cos(angle) * r, sin(angle) * r}
    end
    
    return cache.points
end

local function draw_thick_line_opt(x1, y1, x2, y2, thickness, r, g, b, a)
    local dx = x2 - x1
    local dy = y2 - y1
    local len = sqrt(dx * dx + dy * dy)
    
    if len < 0.1 then return end
    
    local thick_half = thickness * 0.5
    local nx = -dy / len * thick_half
    local ny = dx / len * thick_half
    
    renderer.triangle(x1 + nx, y1 + ny, x2 + nx, y2 + ny, x1 - nx, y1 - ny, r, g, b, a)
    renderer.triangle(x2 + nx, y2 + ny, x2 - nx, y2 - ny, x1 - nx, y1 - ny, r, g, b, a)
end

local circle_cache = {}
local function draw_circle_opt(x, y, radius, r, g, b, a)
    local key = floor(radius * 2)
    if not circle_cache[key] then
        circle_cache[key] = {}
        local segments = max(8, min(16, radius * 2))
        local angle_step = TWO_PI / segments
        
        for i = 0, segments - 1 do
            local angle1 = i * angle_step
            local angle2 = (i + 1) * angle_step
            circle_cache[key][i] = {
                cos(angle1), sin(angle1),
                cos(angle2), sin(angle2)
            }
        end
    end
    
    for i = 0, #circle_cache[key] do
        local t = circle_cache[key][i]
        if t then
            renderer.triangle(x, y, x + t[1] * radius, y + t[2] * radius, x + t[3] * radius, y + t[4] * radius, r, g, b, a)
        end
    end
end

local function draw_china_hat()
    local player = lp()
    if not player or not entity.is_alive(player) then return end
    
    local head_x, head_y, head_z = entity.hitbox_position(player, 0)
    if not head_x then return end
    
    local hat_z = head_z + ui.get(height_offset)
    local seg_count = ui.get(segments)
    local r = ui.get(radius)
    local points = generate_circle_points(seg_count, r)
    
    local rotation_offset = ui.get(rotate_mode) and (globals.realtime() * ui.get(rotate_speed) * 0.01) or 0
    
    local center_screen_x, center_screen_y = renderer.world_to_screen(head_x, head_y, hat_z)
    if not center_screen_x or not is_on_screen(center_screen_x, center_screen_y) then return end
    
    local screen_points = {}
    local angle_step = TWO_PI / seg_count
    
    for i = 1, seg_count do
        local point = points[i]
        local angle = rotation_offset + (i - 1) * angle_step
        local cos_a, sin_a = cos(angle), sin(angle)
        
        local world_x = head_x + point[1] * cos_a - point[2] * sin_a
        local world_y = head_y + point[1] * sin_a + point[2] * cos_a
        
        local screen_x, screen_y = renderer.world_to_screen(world_x, world_y, head_z)
        if screen_x then
            screen_points[i] = {screen_x, screen_y}
        end
    end
    
    local is_rainbow = ui.get(rainbow_mode)
    local base_r, base_g, base_b = ui.get(color)
    local alpha = ui.get(alpha_slider)
    
    if is_rainbow then
        update_rainbow_cache(seg_count)
    end
    
    for i = 1, seg_count do
        local p1 = screen_points[i]
        local p2 = screen_points[i % seg_count + 1]
        
        if p1 and p2 then
            local r, g, b = base_r, base_g, base_b
            if is_rainbow then
                r, g, b = get_rainbow_color_cached(i, seg_count)
            end
            
            renderer.triangle(p1[1], p1[2], p2[1], p2[2], center_screen_x, center_screen_y, r, g, b, alpha)
        end
    end
    
    if ui.get(enable_stroke) then
        if ui.get(stroke_inner) then
            local ir, ig, ib, ia = ui.get(stroke_inner_color)
            for i = 1, seg_count do
                local p1 = screen_points[i]
                if p1 then
                    renderer.line(center_screen_x, center_screen_y, p1[1], p1[2], ir, ig, ib, ia)
                end
            end
        end
        
        local stroke_r, stroke_g, stroke_b, stroke_a = ui.get(stroke_color)
        for i = 1, seg_count do
            local p1 = screen_points[i]
            local p2 = screen_points[i % seg_count + 1]
            
            if p1 and p2 then
                local r, g, b = stroke_r, stroke_g, stroke_b
                if ui.get(stroke_rainbow) then
                    r, g, b = get_rainbow_color_cached(i, seg_count)
                end
                renderer.line(p1[1], p1[2], p2[1], p2[2], r, g, b, stroke_a)
            end
        end
    end
end

local function reset_trail_positions()
    last_position.valid = false
    last_leg_position_left.valid = false
    last_leg_position_right.valid = false
end

local function clear_all_trails()
    trail_points = {}
    leg_trail_points_left = {}
    leg_trail_points_right = {}
end

local function update_trails()
    if not ui.get(enable_trail) then 
        trail_points = {}
        return 
    end
    
    local player = lp()
    if not player or not entity.is_alive(player) then
        trail_points = {}
        reset_trail_positions()
        return
    end
    
    local x, y, z = entity.get_prop(player, "m_vecOrigin")
    if not x then return end
    
    local head_x, head_y, head_z = entity.hitbox_position(player, 0)
    if not head_x then return end
    
    local hat_z = head_z + ui.get(height_offset)
    
    if not last_position.valid then
        last_position.x, last_position.y, last_position.z = x, y, z
        last_position.valid = true
        return
    end
    
    local dx = x - last_position.x
    local dy = y - last_position.y
    
    if dx * dx + dy * dy > 4 then
        trail_points[#trail_points + 1] = {head_x, head_y, hat_z}
        last_position.x, last_position.y, last_position.z = x, y, z
        
        while #trail_points > ui.get(trail_length) do
            remove(trail_points, 1)
        end
    end
end

local function update_leg_trails()
    if not ui.get(enable_leg_trail) then 
        leg_trail_points_left = {}
        leg_trail_points_right = {}
        return 
    end
    
    local player = lp()
    if not player or not entity.is_alive(player) then
        leg_trail_points_left = {}
        leg_trail_points_right = {}
        reset_trail_positions()
        return
    end
    
    local left_x, left_y, left_z = entity.hitbox_position(player, 13)
    if not left_x then return end
    
    if not last_leg_position_left.valid then
        last_leg_position_left.x, last_leg_position_left.y, last_leg_position_left.z = left_x, left_y, left_z
        last_leg_position_left.valid = true
    else
        local dx = left_x - last_leg_position_left.x
        local dy = left_y - last_leg_position_left.y
        
        if dx * dx + dy * dy > 2.25 then
            leg_trail_points_left[#leg_trail_points_left + 1] = {left_x, left_y, left_z}
            last_leg_position_left.x, last_leg_position_left.y, last_leg_position_left.z = left_x, left_y, left_z
            
            while #leg_trail_points_left > ui.get(leg_trail_length) do
                remove(leg_trail_points_left, 1)
            end
        end
    end
    
    if ui.get(leg_trail_both) then
        local right_x, right_y, right_z = entity.hitbox_position(player, 14)
        if right_x then
            if not last_leg_position_right.valid then
                last_leg_position_right.x, last_leg_position_right.y, last_leg_position_right.z = right_x, right_y, right_z
                last_leg_position_right.valid = true
            else
                local dx = right_x - last_leg_position_right.x
                local dy = right_y - last_leg_position_right.y
                
                if dx * dx + dy * dy > 2.25 then
                    leg_trail_points_right[#leg_trail_points_right + 1] = {right_x, right_y, right_z}
                    last_leg_position_right.x, last_leg_position_right.y, last_leg_position_right.z = right_x, right_y, right_z
                    
                    while #leg_trail_points_right > ui.get(leg_trail_length) do
                        remove(leg_trail_points_right, 1)
                    end
                end
            end
        end
    else
        leg_trail_points_right = {}
        last_leg_position_right.valid = false
    end
end

local function draw_trails()
    if not ui.get(enable_trail) or #trail_points < 2 then return end
    
    local base_r, base_g, base_b, base_a = ui.get(trail_color)
    local width = ui.get(trail_width)
    local is_fade = ui.get(trail_fade)
    local is_rainbow = ui.get(trail_rainbow)
    local is_glow = ui.get(trail_glow)
    local glow_intensity = is_glow and ui.get(trail_glow_intensity) or 0
    
    if is_rainbow then
        update_rainbow_cache(#trail_points)
    end
    
    local total = #trail_points
    
    for i = 1, total - 1 do
        local p1 = trail_points[i]
        local p2 = trail_points[i + 1]
        
        local s1_x, s1_y = renderer.world_to_screen(p1[1], p1[2], p1[3])
        local s2_x, s2_y = renderer.world_to_screen(p2[1], p2[2], p2[3])
        
        if s1_x and s2_x and is_on_screen(s1_x, s1_y) then
            local r, g, b, a = base_r, base_g, base_b, base_a
            
            if is_rainbow then
                r, g, b = get_rainbow_color_cached(i, total)
            end
            
            if is_fade then
                a = base_a * (1 - i / total)
            end
            
            if is_glow then
                for layer = glow_intensity, 1, -1 do
                    local glow_alpha = a * (0.1 + 0.1 * (glow_intensity - layer) / glow_intensity)
                    local glow_width = width + layer * 2
                    
                    for w = 0, glow_width - 1 do
                        local offset = w - glow_width * 0.5
                        renderer.line(s1_x + offset, s1_y, s2_x + offset, s2_y, r, g, b, glow_alpha)
                    end
                end
            end
            
            for w = 0, width - 1 do
                local offset = w - width * 0.5
                renderer.line(s1_x + offset, s1_y, s2_x + offset, s2_y, r, g, b, a)
            end
        end
    end
end

local function draw_leg_trails()
    if not ui.get(enable_leg_trail) then return end
    
    local base_r, base_g, base_b, base_a = ui.get(leg_trail_color)
    local width = ui.get(leg_trail_width)
    local thickness = ui.get(leg_trail_thickness)
    local point_size = ui.get(leg_trail_point_size)
    local is_fade = ui.get(leg_trail_fade)
    local is_rainbow = ui.get(leg_trail_rainbow)
    local is_glow = ui.get(leg_trail_glow)
    local glow_intensity = is_glow and ui.get(leg_trail_glow_intensity) or 0
    local gradient = ui.get(leg_trail_gradient_width)
    
    local function draw_single_leg_trail(trail_points)
        if #trail_points < 2 then return end
        
        if is_rainbow then
            update_rainbow_cache(#trail_points)
        end
        
        local total = #trail_points
        local gradient_start = gradient and ui.get(leg_trail_gradient_start) * 0.01 or 1
        local gradient_end = gradient and ui.get(leg_trail_gradient_end) * 0.01 or 1
        
        for i = 1, total - 1 do
            local p1 = trail_points[i]
            local p2 = trail_points[i + 1]
            
            local s1_x, s1_y = renderer.world_to_screen(p1[1], p1[2], p1[3])
            local s2_x, s2_y = renderer.world_to_screen(p2[1], p2[2], p2[3])
            
            if s1_x and s2_x and is_on_screen(s1_x, s1_y) then
                local r, g, b, a = base_r, base_g, base_b, base_a
                
                if is_rainbow then
                    r, g, b = get_rainbow_color_cached(i, total)
                end
                
                if is_fade then
                    a = base_a * (1 - i / total)
                end
                
                local progress = i / total
                local width_mult = gradient and (gradient_start + (gradient_end - gradient_start) * progress) or 1
                local current_width = width * width_mult
                local current_thickness = thickness * width_mult
                
                if is_glow and glow_intensity > 0 then
                    for layer = glow_intensity, 1, -1 do
                        local glow_alpha = a * (0.08 + 0.12 * (glow_intensity - layer) / glow_intensity)
                        draw_thick_line_opt(s1_x, s1_y, s2_x, s2_y, current_thickness + layer * 3, r, g, b, glow_alpha)
                    end
                end
                
                if thickness > 1 then
                    draw_thick_line_opt(s1_x, s1_y, s2_x, s2_y, current_thickness, r, g, b, a)
                end
                
                if width > 1 then
                    for w = 0, current_width - 1 do
                        renderer.line(s1_x + w - current_width * 0.5, s1_y, s2_x + w - current_width * 0.5, s2_y, r, g, b, a)
                    end
                end
                
                if point_size > 0 and i % 2 == 0 then
                    draw_circle_opt(s1_x, s1_y, point_size, r, g, b, a)
                end
            end
        end
    end
    
    draw_single_leg_trail(leg_trail_points_left)
    if ui.get(leg_trail_both) then
        draw_single_leg_trail(leg_trail_points_right)
    end
end

local function check_jump_land()
    if not ui.get(enable_jump_circle) then return end
    
    local player = lp()
    if not player or not entity.is_alive(player) then
        last_on_ground = true
        return
    end
    
    local flags = entity.get_prop(player, "m_fFlags")
    if not flags then return end
    
    local on_ground = band(flags, 1) == 1
    
    if on_ground and not last_on_ground then
        local x, y, z = entity.get_prop(player, "m_vecOrigin")
        if x then
            jump_circles[#jump_circles + 1] = {x, y, z, globals.realtime()}
        end
    end
    
    last_on_ground = on_ground
end

local function draw_jump_circles()
    if not ui.get(enable_jump_circle) then return end
    
    local current_time = globals.realtime()
    local duration = ui.get(jump_circle_duration) * 0.1
    local max_radius = ui.get(jump_circle_max_radius)
    local seg_count = ui.get(jump_circle_segments)
    local expanding = ui.get(jump_circle_expand)
    local is_rainbow = ui.get(jump_circle_rainbow)
    local is_glow = ui.get(jump_circle_glow)
    local glow_intensity = is_glow and ui.get(jump_circle_glow_intensity) or 0
    local filled = ui.get(jump_circle_filled)
    
    for i = #jump_circles, 1, -1 do
        if current_time - jump_circles[i][4] > duration then
            remove(jump_circles, i)
        end
    end
    
    if #jump_circles == 0 then return end
    
    if is_rainbow then
        update_rainbow_cache(seg_count)
    end
    
    local base_r, base_g, base_b = ui.get(jump_circle_color)
    local angle_step = TWO_PI / seg_count
    
    for _, circle in ipairs(jump_circles) do
        local age = current_time - circle[4]
        local progress = age / duration
        
        local radius = expanding and (max_radius * progress) or max_radius
        local alpha = 255 * (1 - progress)
        
        local circle_points = {}
        local center_x, center_y = renderer.world_to_screen(circle[1], circle[2], circle[3])
        
        if not center_x or not is_on_screen(center_x, center_y) then goto continue end
        
        for j = 0, seg_count do
            local angle = j * angle_step
            local world_x = circle[1] + cos(angle) * radius
            local world_y = circle[2] + sin(angle) * radius
            local screen_x, screen_y = renderer.world_to_screen(world_x, world_y, circle[3])
            
            if screen_x then
                circle_points[j + 1] = {screen_x, screen_y}
            end
        end
        
        if filled and center_x then
            for j = 1, #circle_points - 1 do
                local p1 = circle_points[j]
                local p2 = circle_points[j + 1]
                
                if p1 and p2 then
                    local r, g, b = base_r, base_g, base_b
                    if is_rainbow then
                        r, g, b = get_rainbow_color_cached(j, seg_count)
                    end
                    renderer.triangle(p1[1], p1[2], p2[1], p2[2], center_x, center_y, r, g, b, alpha * 0.3)
                end
            end
        end
        
        for j = 1, #circle_points - 1 do
            local p1 = circle_points[j]
            local p2 = circle_points[j + 1]
            
            if p1 and p2 then
                local r, g, b = base_r, base_g, base_b
                if is_rainbow then
                    r, g, b = get_rainbow_color_cached(j, seg_count)
                end
                
                if is_glow then
                    for layer = glow_intensity, 1, -1 do
                        local glow_alpha = alpha * (0.1 + 0.15 * (glow_intensity - layer) / glow_intensity)
                        for offset = -layer, layer do
                            renderer.line(p1[1] + offset, p1[2], p2[1] + offset, p2[2], r, g, b, glow_alpha)
                        end
                    end
                end
                
                renderer.line(p1[1], p1[2], p2[1], p2[2], r, g, b, alpha)
            end
        end
        
        ::continue::
    end
end

-- Update config list
local function update_config_list()
    ui.update(config_list, config_system.list())
end

-- Get current config
local function get_current_config()
    return {
        enable = ui.get(enable),
        rainbow_mode = ui.get(rainbow_mode),
        color = {ui.get(color)},
        rainbow_speed = ui.get(rainbow_speed),
        rainbow_saturation = ui.get(rainbow_saturation),
        alpha_slider = ui.get(alpha_slider),
        segments = ui.get(segments),
        radius = ui.get(radius),
        height_offset = ui.get(height_offset),
        rotate_mode = ui.get(rotate_mode),
        rotate_speed = ui.get(rotate_speed),
        enable_stroke = ui.get(enable_stroke),
        stroke_color = {ui.get(stroke_color)},
        stroke_rainbow = ui.get(stroke_rainbow),
        stroke_inner = ui.get(stroke_inner),
        stroke_inner_color = {ui.get(stroke_inner_color)},
        enable_trail = ui.get(enable_trail),
        trail_length = ui.get(trail_length),
        trail_rainbow = ui.get(trail_rainbow),
        trail_color = {ui.get(trail_color)},
        trail_width = ui.get(trail_width),
        trail_fade = ui.get(trail_fade),
        trail_glow = ui.get(trail_glow),
        trail_glow_intensity = ui.get(trail_glow_intensity),
        trail_blur = ui.get(trail_blur),
        enable_leg_trail = ui.get(enable_leg_trail),
        leg_trail_both = ui.get(leg_trail_both),
        leg_trail_length = ui.get(leg_trail_length),
        leg_trail_rainbow = ui.get(leg_trail_rainbow),
        leg_trail_color = {ui.get(leg_trail_color)},
        leg_trail_width = ui.get(leg_trail_width),
        leg_trail_thickness = ui.get(leg_trail_thickness),
        leg_trail_point_size = ui.get(leg_trail_point_size),
        leg_trail_gradient_width = ui.get(leg_trail_gradient_width),
        leg_trail_gradient_start = ui.get(leg_trail_gradient_start),
        leg_trail_gradient_end = ui.get(leg_trail_gradient_end),
        leg_trail_smooth = ui.get(leg_trail_smooth),
        leg_trail_segments = ui.get(leg_trail_segments),
        leg_trail_fade = ui.get(leg_trail_fade),
        leg_trail_glow = ui.get(leg_trail_glow),
        leg_trail_glow_intensity = ui.get(leg_trail_glow_intensity),
        enable_jump_circle = ui.get(enable_jump_circle),
        jump_circle_rainbow = ui.get(jump_circle_rainbow),
        jump_circle_color = {ui.get(jump_circle_color)},
        jump_circle_duration = ui.get(jump_circle_duration),
        jump_circle_expand = ui.get(jump_circle_expand),
        jump_circle_max_radius = ui.get(jump_circle_max_radius),
        jump_circle_segments = ui.get(jump_circle_segments),
        jump_circle_glow = ui.get(jump_circle_glow),
        jump_circle_glow_intensity = ui.get(jump_circle_glow_intensity),
        jump_circle_filled = ui.get(jump_circle_filled),
    }
end

-- Apply config
local function apply_config(cfg)
    if not cfg then return false end
    
    local function safe_set(elem, val, def)
        pcall(function()
            if val ~= nil then
                if type(val) == "table" then
                    ui.set(elem, unpack(val))
                else
                    ui.set(elem, val)
                end
            elseif def ~= nil then
                ui.set(elem, def)
            end
        end)
    end
    
    safe_set(enable, cfg.enable, false)
    safe_set(rainbow_mode, cfg.rainbow_mode, false)
    safe_set(color, cfg.color)
    safe_set(rainbow_speed, cfg.rainbow_speed, 50)
    safe_set(rainbow_saturation, cfg.rainbow_saturation, 100)
    safe_set(alpha_slider, cfg.alpha_slider, 140)
    safe_set(segments, cfg.segments, 32)
    safe_set(radius, cfg.radius, 10)
    safe_set(height_offset, cfg.height_offset, 8)
    safe_set(rotate_mode, cfg.rotate_mode, false)
    safe_set(rotate_speed, cfg.rotate_speed, 30)
    safe_set(enable_stroke, cfg.enable_stroke, false)
    safe_set(stroke_color, cfg.stroke_color)
    safe_set(stroke_rainbow, cfg.stroke_rainbow, false)
    safe_set(stroke_inner, cfg.stroke_inner, false)
    safe_set(stroke_inner_color, cfg.stroke_inner_color)
    safe_set(enable_trail, cfg.enable_trail, false)
    safe_set(trail_length, cfg.trail_length, 20)
    safe_set(trail_rainbow, cfg.trail_rainbow, false)
    safe_set(trail_color, cfg.trail_color)
    safe_set(trail_width, cfg.trail_width, 3)
    safe_set(trail_fade, cfg.trail_fade, false)
    safe_set(trail_glow, cfg.trail_glow, false)
    safe_set(trail_glow_intensity, cfg.trail_glow_intensity, 5)
    safe_set(trail_blur, cfg.trail_blur, false)
    safe_set(enable_leg_trail, cfg.enable_leg_trail, false)
    safe_set(leg_trail_both, cfg.leg_trail_both, false)
    safe_set(leg_trail_length, cfg.leg_trail_length, 15)
    safe_set(leg_trail_rainbow, cfg.leg_trail_rainbow, false)
    safe_set(leg_trail_color, cfg.leg_trail_color)
    safe_set(leg_trail_width, cfg.leg_trail_width, 3)
    safe_set(leg_trail_thickness, cfg.leg_trail_thickness, 5)
    safe_set(leg_trail_point_size, cfg.leg_trail_point_size, 2)
    safe_set(leg_trail_gradient_width, cfg.leg_trail_gradient_width, false)
    safe_set(leg_trail_gradient_start, cfg.leg_trail_gradient_start, 100)
    safe_set(leg_trail_gradient_end, cfg.leg_trail_gradient_end, 30)
    safe_set(leg_trail_smooth, cfg.leg_trail_smooth, false)
    safe_set(leg_trail_segments, cfg.leg_trail_segments, 2)
    safe_set(leg_trail_fade, cfg.leg_trail_fade, false)
    safe_set(leg_trail_glow, cfg.leg_trail_glow, false)
    safe_set(leg_trail_glow_intensity, cfg.leg_trail_glow_intensity, 5)
    safe_set(enable_jump_circle, cfg.enable_jump_circle, false)
    safe_set(jump_circle_rainbow, cfg.jump_circle_rainbow, false)
    safe_set(jump_circle_color, cfg.jump_circle_color)
    safe_set(jump_circle_duration, cfg.jump_circle_duration, 15)
    safe_set(jump_circle_expand, cfg.jump_circle_expand, false)
    safe_set(jump_circle_max_radius, cfg.jump_circle_max_radius, 80)
    safe_set(jump_circle_segments, cfg.jump_circle_segments, 32)
    safe_set(jump_circle_glow, cfg.jump_circle_glow, false)
    safe_set(jump_circle_glow_intensity, cfg.jump_circle_glow_intensity, 5)
    safe_set(jump_circle_filled, cfg.jump_circle_filled, false)
    
    return true
end

-- Config callbacks
ui.set_callback(config_save, function()
    local name = ui.get(config_name)
    if name == "" then
        notifications.error("Enter a config name")
        return
    end
    
    config_system.save(name, get_current_config())
    update_config_list()
    notifications.success("Saved: " .. name)
end)

ui.set_callback(config_load, function()
    local idx = ui.get(config_list)
    local names = config_system.list()
    
    if names[idx + 1] then
        local name = names[idx + 1]
        local cfg = config_system.load(name)
        if cfg and apply_config(cfg) then
            notifications.success("Loaded: " .. name)
        else
            notifications.error("Failed to load config")
        end
    else
        notifications.warning("Select a config first")
    end
end)

ui.set_callback(config_delete, function()
    local idx = ui.get(config_list)
    local names = config_system.list()
    
    if names[idx + 1] then
        local name = names[idx + 1]
        config_system.delete(name)
        update_config_list()
        notifications.info("Deleted: " .. name)
    else
        notifications.warning("Select a config first")
    end
end)

ui.set_callback(config_export, function()
    config_system.export(get_current_config())
end)

ui.set_callback(config_import, function()
    local cfg = config_system.import()
    if cfg then
        apply_config(cfg)
    end
end)

-- Initialize
update_config_list()

-- UI visibility
local last_ui_state = {}
local function update_ui()
    local enabled = ui.get(enable)
    local rainbow = ui.get(rainbow_mode)
    local rotating = ui.get(rotate_mode)
    local stroke = ui.get(enable_stroke)
    local trail_enabled = ui.get(enable_trail)
    local leg_trail_enabled = ui.get(enable_leg_trail)
    local jump_enabled = ui.get(enable_jump_circle)
    local gradient = ui.get(leg_trail_gradient_width)
    
    local state_key = string.format("%s%s%s%s%s%s%s%s", 
        enabled and "1" or "0", rainbow and "1" or "0", rotating and "1" or "0", stroke and "1" or "0",
        trail_enabled and "1" or "0", leg_trail_enabled and "1" or "0", jump_enabled and "1" or "0", gradient and "1" or "0"
    )
    
    if last_ui_state.key == state_key then return end
    last_ui_state.key = state_key
    
    ui.set_visible(rainbow_mode, enabled)
    ui.set_visible(color, enabled and not rainbow)
    ui.set_visible(rainbow_speed, enabled)
    ui.set_visible(rainbow_saturation, enabled and rainbow)
    ui.set_visible(alpha_slider, enabled)
    ui.set_visible(segments, enabled)
    ui.set_visible(radius, enabled)
    ui.set_visible(height_offset, enabled)
    ui.set_visible(rotate_mode, enabled)
    ui.set_visible(rotate_speed, enabled and rotating)
    ui.set_visible(enable_stroke, enabled)
    ui.set_visible(stroke_color, enabled and stroke)
    ui.set_visible(stroke_rainbow, enabled and stroke)
    ui.set_visible(stroke_inner, enabled and stroke)
    ui.set_visible(stroke_inner_color, enabled and stroke and ui.get(stroke_inner))
    ui.set_visible(enable_trail, enabled)
    ui.set_visible(trail_length, enabled and trail_enabled)
    ui.set_visible(trail_rainbow, enabled and trail_enabled)
    ui.set_visible(trail_color, enabled and trail_enabled)
    ui.set_visible(trail_width, enabled and trail_enabled)
    ui.set_visible(trail_fade, enabled and trail_enabled)
    ui.set_visible(trail_glow, enabled and trail_enabled)
    ui.set_visible(trail_glow_intensity, enabled and trail_enabled and ui.get(trail_glow))
    ui.set_visible(trail_blur, enabled and trail_enabled)
    ui.set_visible(enable_leg_trail, enabled)
    ui.set_visible(leg_trail_both, enabled and leg_trail_enabled)
    ui.set_visible(leg_trail_length, enabled and leg_trail_enabled)
    ui.set_visible(leg_trail_rainbow, enabled and leg_trail_enabled)
    ui.set_visible(leg_trail_color, enabled and leg_trail_enabled)
    ui.set_visible(leg_trail_width, enabled and leg_trail_enabled)
    ui.set_visible(leg_trail_thickness, enabled and leg_trail_enabled)
    ui.set_visible(leg_trail_point_size, enabled and leg_trail_enabled)
    ui.set_visible(leg_trail_gradient_width, enabled and leg_trail_enabled)
    ui.set_visible(leg_trail_gradient_start, enabled and leg_trail_enabled and gradient)
    ui.set_visible(leg_trail_gradient_end, enabled and leg_trail_enabled and gradient)
    ui.set_visible(leg_trail_smooth, enabled and leg_trail_enabled)
    ui.set_visible(leg_trail_segments, enabled and leg_trail_enabled and ui.get(leg_trail_smooth))
    ui.set_visible(leg_trail_fade, enabled and leg_trail_enabled)
    ui.set_visible(leg_trail_glow, enabled and leg_trail_enabled)
    ui.set_visible(leg_trail_glow_intensity, enabled and leg_trail_enabled and ui.get(leg_trail_glow))
    ui.set_visible(enable_jump_circle, enabled)
    ui.set_visible(jump_circle_rainbow, enabled and jump_enabled)
    ui.set_visible(jump_circle_color, enabled and jump_enabled)
    ui.set_visible(jump_circle_duration, enabled and jump_enabled)
    ui.set_visible(jump_circle_expand, enabled and jump_enabled)
    ui.set_visible(jump_circle_max_radius, enabled and jump_enabled)
    ui.set_visible(jump_circle_segments, enabled and jump_enabled)
    ui.set_visible(jump_circle_glow, enabled and jump_enabled)
    ui.set_visible(jump_circle_glow_intensity, enabled and jump_enabled and ui.get(jump_circle_glow))
    ui.set_visible(jump_circle_filled, enabled and jump_enabled)
end

-- Main loop
client.set_event_callback("paint", function()
    if not ui.get(enable) then 
        clear_all_trails()
        jump_circles = {}
        reset_trail_positions()
        was_in_thirdperson = false
        return 
    end
    
    local player = lp()
    if not player or not entity.is_alive(player) then
        clear_all_trails()
        jump_circles = {}
        reset_trail_positions()
        was_in_thirdperson = false
        return
    end
    
    local in_thirdperson = ui.get(thirdperson[1]) and ui.get(thirdperson[2])
    if in_thirdperson ~= was_in_thirdperson then
        reset_trail_positions()
        was_in_thirdperson = in_thirdperson
    end
    
    update_screen_bounds()
    update_trails()
    update_leg_trails()
    check_jump_land()
    
    draw_trails()
    draw_leg_trails()
    draw_jump_circles()
    notifications.draw()
    
    if in_thirdperson then
        draw_china_hat()
    end
end)

client.set_event_callback("paint_ui", update_ui)
update_ui()

notifications.info("China Hat - Optimized Build Loaded!")-- dumped from hrisito forums by <youtube.com/@subtick> ~ rip hrisito 2025-2026
