-- Title: LuaSense BETA
-- Script ID: 146
-- Source: page_146.html
----------------------------------------

local ffi = require "ffi"
local bit = require "bit"
local vector = require "vector"
local aa = require "gamesense/antiaim_funcs" or error "https://gamesense.pub/forums/viewtopic.php?id=29665"
local surface = require "gamesense/surface"
local base64 = require "gamesense/base64" or error("Base64 library required")
local clipboard = require "gamesense/clipboard" or error("Clipboard library required")
local json = require("json")
local trace = require "gamesense/trace"
local c_entity = require("gamesense/entity")
local pui = require("gamesense/pui")
local weapons = require("gamesense/csgo_weapons")
local menu = {}
local notifications = {}
local r_3dsky = cvar.r_3dsky
local aa = {}
local function getbuild() return "beta" end
local function rgba(r, g, b, a, ...) return ("\a%x%x%x%x"):format(r, g, b, a) .. ... end
local menu_refs = {
    ["aimbot"] = ui.reference("RAGE", "Aimbot", "Enabled"),
    ["doubletap"] = { ui.reference("RAGE", "Aimbot", "Double tap") },
    ["hideshots"] = { ui.reference("AA", "Other", "On shot anti-aim") }
}


client.set_event_callback('level_init', function()
    timer = globals.tickcount()
end)

local draw_gamesense_ui = {}
local hitmarker_queue = {}
local hitmarkenable, r, g, b, a

local notify = (function()
    local b = vector
    local c = function(d, b, c) return d + (b - d) * c end
    local e = function() return b(client.screen_size()) end
    local f = function(d, ...) local c = {...} local c = table.concat(c, "") return b(renderer.measure_text(d, c)) end
    local g = { notifications = { bottom = {} }, max = { bottom = 5 } }
    g.__index = g
    g.new_bottom = function(h, i, j, text, color_key)
        table.insert(g.notifications.bottom, {
            started = false,
            instance = setmetatable({ active = false, timeout = 7, color = { ["r"] = h, ["g"] = i, ["b"] = j, a = 0 }, x = e().x / 2, y = e().y, text = text, color_key = color_key }, g)
        })
        if #g.notifications.bottom > g.max.bottom then
            table.remove(g.notifications.bottom, 1)
        end
    end
    function g:handler()
        local d = 0
        local b = 0
        for d, b in pairs(g.notifications.bottom) do
            if not b.instance.active and b.started then
                table.remove(g.notifications.bottom, d)
            end
        end
        for d = 1, #g.notifications.bottom do
            if g.notifications.bottom[d].instance.active then
                b = b + 1
            end
        end
        for c, e in pairs(g.notifications.bottom) do
            if c > g.max.bottom then return end
            if e.instance.active then
                e.instance:render_bottom(d, b)
                d = d + 1
            end
            if not e.started then
                e.instance:start()
                e.started = true
            end
        end
    end
    function g:start()
        self.active = true
        self.delay = globals.realtime() + self.timeout
    end
    function g:get_text()
        local d = ""
        for b, b in pairs(self.text) do
            local c = f("", b[1])
            d = d .. b[1]
        end
        return d
    end
    local k = (function()
        local d = {}
        d.rec = function(d, b, c, e, f, g, k, l, m)
            m = math.min(d / 2, b / 2, m)
            renderer.rectangle(d, b + m, c, e - m * 2, f, g, k, l)
            renderer.rectangle(d + m, b, c - m * 2, m, f, g, k, l)
            renderer.rectangle(d + m, b + e - m, c - m * 2, m, f, g, k, l)
            renderer.circle(d + m, b + m, f, g, k, l, m, 180, .25)
            renderer.circle(d - m + c, b + m, f, g, k, l, m, 90, .25)
            renderer.circle(d - m + c, b - m + e, f, g, k, l, m, 0, .25)
            renderer.circle(d + m, b - m + e, f, g, k, l, m, -90, .25)
        end
        d.rec_outline = function(d, b, c, e, f, g, k, l, m, n)
            m = math.min(c / 2, e / 2, m)
            if m == 1 then
                renderer.rectangle(d, b, c, n, f, g, k, l)
                renderer.rectangle(d, b + e - n, c, n, f, g, k, l)
            else
                renderer.rectangle(d + m, b, c - m * 2, n, f, g, k, l)
                renderer.rectangle(d + m, b + e - n, c - m * 2, n, f, g, k, l)
                renderer.rectangle(d, b + m, n, e - m * 2, f, g, k, l)
                renderer.rectangle(d + c - n, b + m, n, e - m * 2, f, g, k, l)
                renderer.circle_outline(d + m, b + m, f, g, k, l, m, 180, .25, n)
                renderer.circle_outline(d + m, b + e - m, f, g, k, l, m, 90, .25, n)
                renderer.circle_outline(d + c - m, b + m, f, g, k, l, m, -90, .25, n)
                renderer.circle_outline(d + c - m, b + e - m, f, g, k, l, m, 0, .25, n)
            end
        end
        d.glow_module_notify = function(b, c, e, f, g, k, l, m, n, o, p, q, r, s, s)
            local t = 1
            local u = 1
            local rounding = ui.get(menu["visuals & misc"]["visuals"]["notrounding"])
            if s then
                d.rec(b, c, e, f, l, m, n, o, rounding)
            end
            for l = 0, g do
                local m = o / 2 * (l / g) ^ 3
                d.rec_outline(b + (l - g - u) * t, c + (l - g - u) * t, e - (l - g - u) * t * 2, f - (l - g - u) * t * 2, p, q, r, m / 1.5, rounding, t)
            end
        end
        return d
    end)()
    _G.k = k
    function g:render_bottom(g, l)
        local e = e()
        local m = 3.5
        local n = self:get_text()
        local text_size = f("", n)
        local o = 8
        local p = 7
        local marker = (self.text[1] and type(self.text[1]) == "table" and self.text[1][2] == "miss") and 
            (ui.get(menu["visuals & misc"]["visuals"]["notmark2"]) == "custom" and ui.get(menu["visuals & misc"]["visuals"]["custom_notmark_miss"]) or ui.get(menu["visuals & misc"]["visuals"]["notmark2"])) or 
            (ui.get(menu["visuals & misc"]["visuals"]["notmark"]) == "custom" and ui.get(menu["visuals & misc"]["visuals"]["custom_notmark_hit"]) or ui.get(menu["visuals & misc"]["visuals"]["notmark"]))
        local font_map = { normal = "c", small = "-", bold = "b" }
        local prefix_font = font_map[ui.get(menu["visuals & misc"]["visuals"]["notmarkfont"])] or "b"
        local prefix_text = marker
        local separator_enabled = ui.get(menu["visuals & misc"]["visuals"]["notmarkseparator"]) == "yes"
        local separator_text = separator_enabled and " | " or ""
        if ui.get(menu["visuals & misc"]["visuals"]["notmarkuppercase"]) == "yes" then
            prefix_text = prefix_text:upper()
        else
            prefix_text = prefix_text:lower()
        end
        local prefix_width = f(prefix_font, prefix_text).x
        local prefix_height = f(prefix_font, prefix_text).y
        local separator_width = f(prefix_font, separator_text).x
        local separator_height_text = f("b", separator_text).y
        local is_centered = ui.get(menu["visuals & misc"]["visuals"]["notmark_centered"])
        local marker_offset = is_centered and 0 or ui.get(menu["visuals & misc"]["visuals"]["notmarkoffset"])
        local marker_x_offset = is_centered and 0 or ui.get(menu["visuals & misc"]["visuals"]["notmarkxoffset"])
        local q = m + text_size.x + (prefix_text ~= "" and prefix_width + separator_width + marker_offset or 0) + 2
        local r = ui.get(menu["visuals & misc"]["visuals"]["notheight"])
        local q = q + p * 1.5
        local s, t = is_centered and (e.x / 2 - q / 2) or (self.x - q / 2), math.ceil(self.y - 40 + .4)
        local u = globals.frametime()
        if globals.realtime() < self.delay then
            self.y = c(self.y, e.y - 45 - (l - g) * r * 1.4, u * 7)
            self.color.a = c(self.color.a, 255, u * 2)
        else
            self.y = c(self.y, self.y - 10, u * 15)
            self.color.a = c(self.color.a, 0, u * 20)
            if self.color.a <= 1 then
                self.active = false
            end
        end
        local c, e, g, l = self.color.r, self.color.g, self.color.b, self.color.a
        local color_key = self.color_key or "notcolor"
        local glow_r, glow_g, glow_b
        if self.text[1] and type(self.text[1]) == "table" and self.text[1][2] == "hit" then
            glow_r, glow_g, glow_b = ui.get(menu["visuals & misc"]["visuals"]["notglow_hit_color"])
        elseif self.text[1] and type(self.text[1]) == "table" and self.text[1][2] == "miss" then
            glow_r, glow_g, glow_b = ui.get(menu["visuals & misc"]["visuals"]["notglow_miss_color"])
        else
            glow_r, glow_g, glow_b = ui.get(menu["visuals & misc"]["visuals"][color_key])
        end 
        local glow = ui.get(menu["visuals & misc"]["visuals"]["notglow"])
        if type(k) == "table" and type(k.glow_module_notify) == "function" then
            local bg_r, bg_g, bg_b, bg_a = ui.get(menu["visuals & misc"]["visuals"]["notbackground_color"])
            k.glow_module_notify(s, t, q, r, glow, o, bg_r, bg_g, bg_b, bg_a, glow_r, glow_g, glow_b, 255, true)
        else
            client.log("Error: k.glow_module_notify is not callable, skipping glow effect")
            local bg_r, bg_g, bg_b, bg_a = ui.get(menu["visuals & misc"]["visuals"]["notbackground_color"])
            renderer.rectangle(s, t, q, r, bg_r, bg_g, bg_b, bg_a)
        end
        local k = p + 2
        k = k + m
        local marker_height = ui.get(menu["visuals & misc"]["visuals"]["notmarkheight"])
        local text_r, text_g, text_b = 255, 255, 255
        local marker_r, marker_g, marker_b
        if self.text[1] and type(self.text[1]) == "table" and self.text[1][2] == "hit" then
            marker_r, marker_g, marker_b = ui.get(menu["visuals & misc"]["visuals"]["notmark_hit_prefix_color"])
        elseif self.text[1] and type(self.text[1]) == "table" and self.text[1][2] == "miss" then
            marker_r, marker_g, marker_b = ui.get(menu["visuals & misc"]["visuals"]["notmark_miss_prefix_color"])
        else
            marker_r, marker_g, marker_b = ui.get(menu["visuals & misc"]["visuals"][color_key])
        end
        local prefix_alpha = (self.text[1] and type(self.text[1]) == "table" and (self.text[1][2] == "hit" or self.text[1][2] == "miss" or self.text[1][2] == "shot" or self.text[1][2] == "reset")) and 255 or l
        if prefix_text ~= "" then
            local prefix_y = is_centered and (t + r / 2 - prefix_height / 2) or (t + r / 2 - marker_height / 2)
            local adjusted_marker_x_offset = separator_enabled and marker_x_offset or marker_x_offset - 4.4
            renderer.text(s + k + adjusted_marker_x_offset, prefix_y, marker_r, marker_g, marker_b, prefix_alpha, prefix_font, nil, prefix_text)
            k = k + prefix_width
            if separator_text ~= "" then
                local separator_height = ui.get(menu["visuals & misc"]["visuals"]["notmarkseparatorheight"])
                local separator_y = is_centered and (t + r / 2 - separator_height_text / 2) or (t + r / 2 - separator_height / 2)
                local separator_r, separator_g, separator_b
                if self.text[1] and type(self.text[1]) == "table" then
                    if self.text[1][2] == "miss" then
                        separator_r, separator_g, separator_b = ui.get(menu["visuals & misc"]["visuals"]["notmark_miss_separator_color"])
                    else
                        separator_r, separator_g, separator_b = ui.get(menu["visuals & misc"]["visuals"]["notmark_hit_separator_color"])
                    end
                else
                    separator_r, separator_g, separator_b = ui.get(menu["visuals & misc"]["visuals"]["notmark_hit_separator_color"])
                end
                renderer.text(s + k, separator_y, separator_r, separator_g, separator_b, prefix_alpha, "b", nil, separator_text)
                k = k + separator_width
            end
            k = k + marker_offset
        end
        renderer.text(s + k, t + r / 2 - text_size.y / 2, text_r, text_g, text_b, l, "", nil, n)
    end
    client.set_event_callback("paint_ui", function() g:handler() end)
    return g
end)()

local w, h = client.screen_size()
local js = panorama.open()
local alpha = 69
local toggled = false
local second_notification_triggered = false
local first_notification_time = nil
local loading_notification_triggered = false

local function draw_debug_panel()
    if not ui.get(menu["visuals & misc"]["visuals"]["debug_panel"]) then return end
    local w, h = client.screen_size()
    local base_x = 47.5  -- Base horizontal position of the panel
    local base_y = 440  -- Base vertical position of the panel
    local r, g, b, a = 255, 255, 255, 255 -- White text
    local font = "c"  -- Default font
    local line_height = 12.2  -- Vertical spacing between lines

    -- Function to determine exploit charge status using gamesense/antiaim_funcs
local function get_exploit_charge()
    if not menu_refs or not menu_refs["doubletap"] or not menu_refs["hideshots"] then
        return "true"
    end
    local dt_enabled = ui.get(menu_refs["doubletap"][1]) and ui.get(menu_refs["doubletap"][2])
    local hs_enabled = ui.get(menu_refs["hideshots"][1]) and ui.get(menu_refs["hideshots"][2])
    local exploit_charged = dt_enabled or hs_enabled
    return exploit_charged and "true" or "false"
end

    -- Determine debug label based on checkboxes
    local debug_label = ui.get(menu["visuals & misc"]["visuals"]["debug_customp"]) and
    (ui.get(menu["visuals & misc"]["visuals"]["debug_custom"]) or "luasense") or "luasense"


    -- Debug panel content with individual label and value offsets
    local debug_lines = {
        { label = debug_label, value = ui.get(menu["visuals & misc"]["visuals"]["useridls"]) or "user", label_x_offset = -11.5, value_x_offset = -11.5 },
        { 
            label = "version", 
            value = function()
                local alpha = math.floor(math.abs(math.sin(globals.realtime() * 1)) * 255)
                return string.format(" \aFFFFFF%02Xexclusive", alpha) -- white color with animated opacity
            end,
            label_x_offset = -18.5, 
            value_x_offset = 4 
        },        
        { label = "exploit charge", value = get_exploit_charge, label_x_offset = -0.75, value_x_offset = -23 },
        { label = "desync amount", value = function()
            local myself = entity.get_local_player()
            if myself and entity.is_alive(myself) then
                local yaw_body = math.max(-60, math.min(60, math.floor((entity.get_prop(myself, "m_flPoseParameter", 11) or 0) * 120 - 60 + 0.5)))
                return string.format("%.0fÂ°", math.abs(yaw_body))
            end
            return "N/A"
        end, label_x_offset = 0, value_x_offset = -29 }
    }

    -- Render each line
for i, line in ipairs(debug_lines) do
    local value = type(line.value) == "function" and line.value() or line.value
    local label_text
    if line.label == debug_label then
        label_text = line.label .. " - "
    else
        label_text = line.label .. ":"
    end
    local label_x = base_x + (line.label_x_offset or 0)
    local label_width = renderer.measure_text(font, label_text)
    local value_width = renderer.measure_text(font, value)
    local value_x = label_x + label_width + (line.value_x_offset or 0)
    local y = base_y + (i - 1) * line_height
    renderer.text(label_x, y, r, g, b, a, font, nil, label_text)
    renderer.text(value_x, y, r, g, b, a, font, nil, value)
end
end


client.set_event_callback("paint_ui", function()
    if ui.get(menu["rage"]["resolver"]) == "yes" then
        local myself = entity.get_local_player()
        if myself and entity.is_alive(myself) then
            local target = client.current_threat()
            if target then
                local target_entity = c_entity.new(target)
                local target_name = target_entity:get_player_name() or "Unknown"
                local r, g, b, a = ui.get(menu["rage"]["resolver_color"])
                renderer.indicator(r, g, b, a, "Target: " .. target_name)
            end
        end
    end
    draw_debug_panel()
    if alpha > 0 and toggled then
        if alpha == 169 then
            first_notification_time = globals.realtime()
        end
        alpha = alpha - 0.5
    else
        if not toggled then
            alpha = alpha + 1
            if alpha == 254 then
                toggled = true
            end
            alpha = alpha + 1
        end
    end

    if not loading_notification_triggered and menu["visuals & misc"] then
        local r, g, b = ui.get(menu["visuals & misc"]["visuals"]["notcolor"])
        local a = 255
        local colored_luasense = ("\a%02x%02x%02x%02x%s"):format(r, g, b, a, "luasense")
        local white = "\aFFFFFFFF"
        notify.new_bottom(r, g, b, { { white .. "Loading " .. colored_luasense .. white .. "..." }, { "  ", true } })
        loading_notification_triggered = true
    end

-- Remove or comment out: local user = "admin"
-- ... (other code) ...
if first_notification_time and not second_notification_triggered then
    if globals.realtime() >= first_notification_time + 2 then 
        local r, g, b = ui.get(menu["visuals & misc"]["visuals"]["notcolor"])
        local a = 255
        local username = ui.get(menu["visuals & misc"]["visuals"]["useridls"]) or "user" -- Fallback to "user" if empty
        local colored_user = ("\a%02x%02x%02x%02x%s"):format(r, g, b, a, username)
        local white = "\aFFFFFFFF"
        notify.new_bottom(179, 255, 18, { { white .. "Welcome back, " .. colored_user .. "  ", true } })
        second_notification_triggered = true 
    end
end

    if alpha > 1 then
        renderer.gradient(0, 0, w, h, 0, 0, 0, alpha, 0, 0, 0, alpha, false)
    end

    if menu["visuals & misc"] and menu["visuals & misc"]["visuals"] then
        local is_centered = ui.get(menu["visuals & misc"]["visuals"]["notmark_centered"])
        ui.set_visible(menu["visuals & misc"]["visuals"]["notmarkoffset"], not is_centered)
        ui.set_visible(menu["visuals & misc"]["visuals"]["notmarkxoffset"], not is_centered)
    end
end)

return (function(tbl)
    tbl.items = {
        enabled = tbl.ref("aa", "anti-aimbot angles", "enabled"),
        pitch = tbl.ref("aa", "anti-aimbot angles", "pitch"),
        base = tbl.ref("aa", "anti-aimbot angles", "yaw base"),
        jitter = tbl.ref("aa", "anti-aimbot angles", "yaw jitter"),
        yaw = tbl.ref("aa", "anti-aimbot angles", "yaw"),
        body = tbl.ref("aa", "anti-aimbot angles", "body yaw"),
        fsbody = tbl.ref("aa", "anti-aimbot angles", "freestanding body yaw"),
        edge = tbl.ref("aa", "anti-aimbot angles", "edge yaw"),
        roll = tbl.ref("aa", "anti-aimbot angles", "roll"),
        fs = tbl.ref("aa", "anti-aimbot angles", "freestanding")
    }
    local prefix = function(x, z) 
        return (z and ("\a32a852FFluasense \a698a6dFF~ \a414141FF(\ab5b5b5FF%s\a414141FF) \a89f596FF%s"):format(x, z) or ("\a32a852FFluasense \a698a6dFF~ \a89f596FF%s"):format(x)) 
    end
    local ffi = require("ffi")
    local clipboard = {
        ["ffi"] = ffi.cdef([[
            typedef int(__thiscall* get_clipboard_text_count)(void*);
            typedef void(__thiscall* set_clipboard_text)(void*, const char*, int);
            typedef void(__thiscall* get_clipboard_text)(void*, int, const char*, int);
        ]]),
        ["export"] = function(arg)
            local pointer = ffi.cast(ffi.typeof('void***'), client.create_interface('vgui2.dll', 'VGUI_System010'))
            local func = ffi.cast('set_clipboard_text', pointer[0][9])
            func(pointer, arg, #arg)
        end,
        ["import"] = function()
            local pointer = ffi.cast(ffi.typeof('void***'), client.create_interface('vgui2.dll', 'VGUI_System010'))
            local func = ffi.cast('get_clipboard_text_count', pointer[0][7])
            local sizelen = func(pointer)
            local output = ""
            if sizelen > 0 then
                local buffer = ffi.new("char[?]", sizelen)
                local sizefix = sizelen * ffi.sizeof("char[?]", sizelen)
                local extrafunc = ffi.cast('get_clipboard_text', pointer[0][11])
                extrafunc(pointer, 0, buffer, sizefix)
                output = ffi.string(buffer, sizelen-1)
            end
            return output
        end
    }
    local category = ui.new_combobox("aa", "anti-aimbot angles", prefix("category" .. rgba(69,169,155,255," " .. (getbuild() == "beta" and " (beta)" or ""))), {"rage", "anti aimbot", "visuals & misc", "config"})
    draw_gamesense_ui.alpha = function(color, alpha)
        color[4] = alpha
        return color
    end
    draw_gamesense_ui.colors = {
        main = {12, 12, 12},
        border_edge = {60, 60, 60},
        border_inner = {40, 40, 40},
        gradient = {
            top = {
                left = {55, 177, 218},
                middle = {204, 70, 205},
                right = {204, 227, 53}
            },
            bottom = {
                left = {29, 94, 116},
                middle = {109, 37, 109},
                right = {109, 121, 28}
            },
            pixel_three = {6, 6, 6}
        },
        combine = function(color1, color2, ...)
            local t = {unpack(color1)}
            for i = 1, #color2 do
                table.insert(t, color2[i])
            end
            local args = {...}
            for i = 1, #args do
                table.insert(t, args[i])
            end
            return t
        end
    }
    draw_gamesense_ui.border = function(x, y, width, height, alpha)
        local x = x - 7 - 1
        local y = y - 7 - 5
        local w = width + 14 + 2
        local h = height + 14 + 10
        renderer.rectangle(x, y, w, h, unpack(draw_gamesense_ui.alpha(draw_gamesense_ui.colors.main, alpha)))
        renderer.rectangle(x + 1, y + 1, w - 2, h - 2, unpack(draw_gamesense_ui.alpha(draw_gamesense_ui.colors.border_edge, alpha)))
        renderer.rectangle(x + 2, y + 2, w - 4, h - 4, unpack(draw_gamesense_ui.alpha(draw_gamesense_ui.colors.border_inner, alpha)))
        renderer.rectangle(x + 6, y + 6, w - 12, h - 12, unpack(draw_gamesense_ui.alpha(draw_gamesense_ui.colors.border_edge, alpha)))
    end
    draw_gamesense_ui.gradient = function(x, y, width, alpha)
        local full_width = width
        local width = math.floor(width / 2)
        local top_left = draw_gamesense_ui.alpha(draw_gamesense_ui.colors.gradient.top.left, alpha)
        local top_middle = draw_gamesense_ui.alpha(draw_gamesense_ui.colors.gradient.top.middle, alpha)
        local top_right = draw_gamesense_ui.alpha(draw_gamesense_ui.colors.gradient.top.right, alpha)
        local bottom_left = draw_gamesense_ui.alpha(draw_gamesense_ui.colors.gradient.bottom.left, alpha)
        local bottom_middle = draw_gamesense_ui.alpha(draw_gamesense_ui.colors.gradient.bottom.middle, alpha)
        local bottom_right = draw_gamesense_ui.alpha(draw_gamesense_ui.colors.gradient.bottom.right, alpha)
        top_left = draw_gamesense_ui.colors.combine(top_left, top_middle, true)
        top_right = draw_gamesense_ui.colors.combine(top_middle, top_right, true)
        bottom_left = draw_gamesense_ui.colors.combine(bottom_left, bottom_middle, true)
        bottom_right = draw_gamesense_ui.colors.combine(bottom_middle, bottom_right, true)
        local oddfix = math.ceil(full_width / 2)
        renderer.gradient(x, y - 4, width, 1, unpack(top_left))
        renderer.gradient(x + width, y - 4, oddfix, 1, unpack(top_right))
        renderer.gradient(x, y - 3, width, 1, unpack(bottom_left))
        renderer.gradient(x + width, y - 3, oddfix, 1, unpack(bottom_right))
        renderer.rectangle(x, y - 2, full_width, 1, unpack(draw_gamesense_ui.colors.gradient.pixel_three))
    end
    draw_gamesense_ui.draw = function(x, y, width, height, alpha)
        y = y - 7
        draw_gamesense_ui.border(x, y, width, height, alpha)
        renderer.rectangle(x - 1, y - 5, width + 2, height + 10, unpack(draw_gamesense_ui.alpha(draw_gamesense_ui.colors.main, alpha)))
        draw_gamesense_ui.gradient(x, y, width, alpha)
    end
    local function push_notify(text, color_flag)
        local color_key = color_flag == "hit" and "notcolor2" or color_flag == "miss" and "notcolor3" or "notcolor"
        local r, g, b = ui.get(menu["visuals & misc"]["visuals"][color_key])
        notify.new_bottom(r, g, b, { { text, color_flag or true } }, color_key)
    end
    local lerp = function(current, to_reach, t) return current + (to_reach - current) * t end
    client.set_event_callback("paint_ui", function()
        local width, height = client.screen_size()
        local frametime = globals.frametime()
        local timestamp = client.timestamp()
        for idx, notification in next, notifications do
            if timestamp > notification.lifetime then
                notification.alpha = lerp(255, 0, 1 - (notification.alpha / 255) + frametime * (1 / 7.5 * 10))
            end
            if notification.alpha <= 0 then
                notifications[idx] = nil
            else
                notification.spacer = lerp(notification.spacer, idx * 40, frametime)
                local text_width = renderer.measure_text("c", notification.text) + 10
                draw_gamesense_ui.draw(width/2 - text_width / 2, height/2 + 300 + notification.spacer, text_width, 12, notification.alpha)
                renderer.text(width/2, height/2 + 300 + notification.spacer, 255, 255, 255, notification.alpha, "c", 0, notification.text:gsub("\a%x%x%x%x%x%x%x%x", function(color)
                    return color:sub(1, #color - 2)..string.format("%02x", notification.alpha)
                end):sub(1, -1))
            end
        end
    end)
    menu = {
        ["rage"] = {
            remove_3d_sky = ui.new_checkbox("aa", "anti-aimbot angles", prefix("remove 3d sky"), true),
            resolver = ui.new_combobox("aa", "anti-aimbot angles", prefix("target name indicator"), {"no", "yes"}),
            resolver_color = ui.new_color_picker("aa", "anti-aimbot angles", prefix("target name indicator color"), 255, 255, 255, 200),
        },
        ["anti aimbot"] = {
            submenu = ui.new_combobox("aa", "anti-aimbot angles", "\nmenu", {"builder", "keybinds", "features"}),
            ["builder"] = {
                builder = ui.new_combobox("aa", "anti-aimbot angles", prefix("builder"), tbl.states),
                team = ui.new_combobox("aa", "anti-aimbot angles", "\nteam", {"ct", "t"})
            },
            ["keybinds"] = {
                keys = ui.new_multiselect("aa", "anti-aimbot angles", prefix("keys"), {"manual", "edge", "freestand"}),
                left = ui.new_hotkey("aa", "anti-aimbot angles", prefix("left")),
                right = ui.new_hotkey("aa", "anti-aimbot angles", prefix("right")),
                forward = ui.new_hotkey("aa", "anti-aimbot angles", prefix("forward")),
                backward = ui.new_hotkey("aa", "anti-aimbot angles", prefix("backward")),
                type_manual = ui.new_combobox("aa", "anti-aimbot angles", prefix("manual"), {"default", "jitter", "static"}),
                edge = ui.new_hotkey("aa", "anti-aimbot angles", prefix("edge")),
                type_freestand = ui.new_combobox("aa", "anti-aimbot angles", prefix("freestand"), {"default", "jitter", "static"}),
                freestand = ui.new_hotkey("aa", "anti-aimbot angles", "\nfreestand", true),
                disablers = ui.new_multiselect("aa", "anti-aimbot angles", prefix("fs disablers"), {"air", "slow", "duck", "edge", "manual", "fake lag"})
            },
            ["features"] = {
                legit = ui.new_combobox("aa", "anti-aimbot angles", prefix("legit"), {"off", "default", "luasense"}),
                fix = ui.new_multiselect("aa", "anti-aimbot angles", "\nfix", {"generic", "bombsite"}),
                defensive = ui.new_combobox("aa", "anti-aimbot angles", prefix("defensive"), {"off", "pitch", "spin", "random", "random pitch", "sideways down", "sideways up"}),
                fixer = ui.new_combobox("aa", "anti-aimbot angles", "\nfixer", {"default", "luasense"}),
                states = ui.new_multiselect("aa", "anti-aimbot angles", "\nstates\n", {"standing", "moving", "air", "air duck", "duck", "duck moving", "slow motion"}),
                backstab = ui.new_combobox("aa", "anti-aimbot angles", prefix("backstab"), {"off", "forward", "random"}),
                distance = ui.new_slider("aa", "anti-aimbot angles", "\nbackstab", 100, 500, 250),
                roll = ui.new_slider("aa", "anti-aimbot angles", prefix("roll"), -45, 45, 0)
            },
        },
        ["visuals & misc"] = {
            submenu = ui.new_combobox("aa", "anti-aimbot angles", "\nvisuals & misc", {"visuals", "misc"}),
            ["visuals"] = {
                usernametip = ui.new_label("aa", "anti-aimbot angles", "username"),
                useridls = ui.new_textbox("aa", "anti-aimbot angles", prefix("username"), "luasense"),
                wtext = ui.new_combobox("aa", "anti-aimbot angles", prefix("wutermark"), {"î¤ luasense î¤", "luasense beta", "luasync.max2", "luasync.max", "î¤ luasense", "luasense î¤", "luasense", "w3LLy$eN$E", "custom"}),
                watermark = ui.new_combobox("aa", "anti-aimbot angles", prefix("always on", "watermark"), {"bottom", "right", "left", "custom"}),
                notify_tip15 = ui.new_label("aa", "anti-aimbot angles", "watermark text"),
                custom_wtext = ui.new_textbox("aa", "anti-aimbot angles", prefix("custom watermark text")),
                watermark_color = ui.new_color_picker("aa", "anti-aimbot angles", "\nwatermark", 150, 200, 69, 255),
                notify_tip16 = ui.new_label("aa", "anti-aimbot angles", "prefix text"),
                custom_prefix = ui.new_textbox("aa", "anti-aimbot angles", prefix("custom prefix")),
                custom_prefix_color = ui.new_color_picker("aa", "anti-aimbot angles", prefix("custom prefix color"), 185, 64, 63, 255),  
                notify_tip22 = ui.new_label("aa", "anti-aimbot angles", "prefix 2 text"),
                custom_prefix2 = ui.new_textbox("aa", "anti-aimbot angles", prefix("custom prefix")),
                custom_prefix2_color = ui.new_color_picker("aa", "anti-aimbot angles", prefix("custom prefix color"), 255, 255, 255, 255),  
                watermark_x_offset = ui.new_slider("aa", "anti-aimbot angles", prefix("wutermark x offset"), -1920, 1080, 0, true, "px"),
                watermark_y_offset = ui.new_slider("aa", "anti-aimbot angles", prefix("wutermark y offset"), -1920, 1080, 0, true, "px"),
                watermark_animation = ui.new_checkbox("aa", "anti-aimbot angles", prefix("enable watermark animation"), true),
                prefix_animation = ui.new_checkbox("aa", "anti-aimbot angles", prefix("enable prefix animation"), true),
                prefix2_animation = ui.new_checkbox("aa", "anti-aimbot angles", prefix("enable other prefix animation"), true),
                wfont = ui.new_combobox("aa", "anti-aimbot angles", prefix("wutermark font"), {"normal", "small", "bold"}),
                watermark_spaces = ui.new_combobox("aa", "anti-aimbot angles", prefix("remove spaces"), {"yes", "no"}),
                uppercase = ui.new_combobox("aa", "anti-aimbot angles", prefix("uppercase watermark"), {"yes", "no"}),
                hitmark_enable = ui.new_combobox("aa", "anti-aimbot angles", prefix("world hitmarker"), {"no", "yes"}),
                notify_tip11 = ui.new_label("aa", "anti-aimbot angles", "world hitmarker color"),
                hitmark_color = ui.new_color_picker("aa", "anti-aimbot angles", "world hitmarker color", 42, 202, 144, 255),
                debug_panel = ui.new_checkbox("aa", "anti-aimbot angles", prefix("debug panel"), false),
                debug_customp = ui.new_checkbox("aa", "anti-aimbot angles", prefix("custom debug panel"), true),
                debugtip = ui.new_label("aa", "anti-aimbot angles", "debug panel prefix"),
                debug_custom = ui.new_textbox("aa", "anti-aimbot angles", prefix("custom debug panel text"), "luasense"),
                notify_tip = ui.new_label("aa", "anti-aimbot angles", "removed new notifications just old :)"),
                notmark_centered = ui.new_checkbox("aa", "anti-aimbot angles", prefix("center notification prefix"), true),
                notify = ui.new_multiselect("aa", "anti-aimbot angles", prefix("notify"), {"hit", "miss", "shot", "reset"}),
                notify_tip103 = ui.new_label("aa", "anti-aimbot angles", "notify background color"),
                notbackground_color = ui.new_color_picker("aa", "anti-aimbot angles", prefix("notification background color"), 25, 25, 25, 255),
                notify_tip2 = ui.new_label("aa", "anti-aimbot angles", "notification color (shot and reset)"),
                notcolor = ui.new_color_picker("aa", "anti-aimbot angles", "notify color", 150, 200, 69, 255),
                notify_tip104 = ui.new_label("aa", "anti-aimbot angles", "notify hit glow color"),
                notglow_hit_color = ui.new_color_picker("aa", "anti-aimbot angles", prefix("notify hit glow color"), 150, 200, 69, 255),
                notify_tip105 = ui.new_label("aa", "anti-aimbot angles", "notify miss glow color"),
                notglow_miss_color = ui.new_color_picker("aa", "anti-aimbot angles", prefix("notify miss glow color"), 200, 69, 69, 255),
                notify_tip3 = ui.new_label("aa", "anti-aimbot angles", "notify hit color"),
                notcolor2 = ui.new_color_picker("aa", "anti-aimbot angles", "notify hit color", 150, 200, 69, 255),
                notify_tip4 = ui.new_label("aa", "anti-aimbot angles", "notify miss color"),
                notcolor3 = ui.new_color_picker("aa", "anti-aimbot angles", "notify miss color", 200, 69, 69, 255),
                notify_tip18 = ui.new_label("aa", "anti-aimbot angles", "prefix hit color"),
                notmark_hit_prefix_color = ui.new_color_picker("aa", "anti-aimbot angles", prefix("notify hit prefix color"), 150, 200, 69, 255),
                notify_tip19 = ui.new_label("aa", "anti-aimbot angles", "prefix miss color"),
                notmark_miss_prefix_color = ui.new_color_picker("aa", "anti-aimbot angles", prefix("notify miss prefix color"), 200, 69, 69, 255),
                notify_tip101 = ui.new_label("aa", "anti-aimbot angles", "| hit color"),
                notmark_hit_separator_color = ui.new_color_picker("aa", "anti-aimbot angles", prefix("notify hit separator color"), 150, 200, 69, 255),
                notify_tip102 = ui.new_label("aa", "anti-aimbot angles", "| miss color"),
                notmark_miss_separator_color = ui.new_color_picker("aa", "anti-aimbot angles", prefix("notify miss separator color"), 200, 69, 69, 255),
                notheight = ui.new_slider("aa", "anti-aimbot angles", prefix("notify height"), -25, 25, 23, true, "px"),
                notmarkheight = ui.new_slider("aa", "anti-aimbot angles", prefix("notify marker height"), -25.5, 25.5, 9.5, true, "px"),
                notmarkseparatorheight = ui.new_slider("aa", "anti-aimbot angles", prefix("notify separator height"), -25, 25, 12, true, "px"),
                notmarkoffset = ui.new_slider("aa", "anti-aimbot angles", prefix("notify marker offset"), -25, 25, 2, true, "px"),
                notmarkxoffset = ui.new_slider("aa", "anti-aimbot angles", prefix("notify marker x offset"), -50, 50, 0, true, "px"),
                notglow = ui.new_slider("aa", "anti-aimbot angles", prefix("notify glow"), 0, 25, 17, true, "px"),
                notrounding = ui.new_slider("aa", "anti-aimbot angles", prefix("notify rounding"), 0, 25, 10, true, "px"),
                notmark = ui.new_combobox("aa", "anti-aimbot angles", prefix("notify common letter"), {"L", "E", "W", "â ", "î", "î¤", "î´", "îµ", "î", "î", "luasense", "custom"}),
                notmark2 = ui.new_combobox("aa", "anti-aimbot angles", prefix("notify miss letter"), { "L", "E", "W", "â ", "î", "î¤", "î´", "îµ", "î", "î", "luasense", "custom"}),
                notmarkfont = ui.new_combobox("aa", "anti-aimbot angles", prefix("notify prefix font"), {"bold", "small", "normal"}),
                notmarkseparator = ui.new_combobox("aa", "anti-aimbot angles", prefix("notify separator"), {"yes", "no"}),
                notmarkuppercase = ui.new_combobox("aa", "anti-aimbot angles", prefix("notify prefix uppercase"), {"yes", "no"}),
                notify_tip12 = ui.new_label("aa", "anti-aimbot angles", "custom hit prefix"),
                custom_notmark_hit = ui.new_textbox("aa", "anti-aimbot angles", prefix("custom notify hit prefix")),
                notify_tip13 = ui.new_label("aa", "anti-aimbot angles", "custom miss prefix"),
                custom_notmark_miss = ui.new_textbox("aa", "anti-aimbot angles", prefix("custom notify miss prefix")),
                slowdown_indicator = ui.new_checkbox("aa", "anti-aimbot angles", prefix("Slowdown indicator"), false),
                slowdown_color = ui.new_color_picker("aa", "anti-aimbot angles", prefix("Slowdown indicator color"), 150, 200, 69, 255),
                arrows = ui.new_combobox("aa", "anti-aimbot angles", prefix("arrows"), {"-", "simple", "body", "luasense"}),
                arrows_color = ui.new_color_picker("aa", "anti-aimbot angles", "\narrows", 137, 245, 150, 255),
                indicators = ui.new_combobox("aa", "anti-aimbot angles", prefix("indicators"), {"-", "default", "luasense", "custom"}),
                indicators_color = ui.new_color_picker("aa", "anti-aimbot angles", "\nindicators", 137, 245, 150, 255),
                custom_indicator_text = ui.new_textbox("aa", "anti-aimbot angles", prefix("custom indicator text")),
            },
            ["misc"] = {
                features = ui.new_multiselect("aa", "anti-aimbot angles", prefix("features"), {"fix hideshot", "animations", "legs spammer", "dt_os_recharge_fix", "gucci_killsay"}),
                spammer = ui.new_slider("aa", "anti-aimbot angles", "\nspammer", 1, 9, 1),
                autobuy = ui.new_combobox("aa", "anti-aimbot angles", prefix("auto buy"), {"off", "awp", "scout"})
            }
            
        },
        ["config"] = {
            config_selector = ui.new_combobox("aa", "anti-aimbot angles", prefix("select config"), {"aggressive delayed jitter", "safe delayed jitter", "aggressive jitter", "safe jitter", "perfect jitter", "perfect delay jitter"}),
            load = ui.new_button("aa", "anti-aimbot angles", "\ac8c8c8FF load", function()
                local selected_config = ui.get(menu["config"]["config_selector"])
                local check, message = pcall(function()
                    local tbl
                    if selected_config == "aggressive delayed jitter" then
                        tbl = json.parse([[{"LUASENSE":{"duck moving":{"t":{"normal":{"right":0,"jitter_slider":0,"yaw":0,"method":"default","left":0,"jitter":"off","custom_slider":60,"body":"off","defensive":"off","mode":{},"body_slider":0},"advanced":{"right":0,"left":0,"trigger":"a: brandon","defensive":"off"},"type":"luasense","luasense":{"right":-37,"left":37,"fake":60,"yaw":0,"defensive":"luasense","mode":["left right"],"luasense":5},"disabled":{},"auto":{"right":0,"method":"simple","left":0,"defensive":"off","timer":150,"antibf":"no"}},"ct":{"normal":{"right":0,"jitter_slider":0,"yaw":0,"method":"default","left":0,"jitter":"off","custom_slider":60,"body":"off","defensive":"off","mode":{},"body_slider":0},"advanced":{"right":0,"left":0,"trigger":"a: brandon","defensive":"off"},"type":"luasense","luasense":{"right":-37,"left":37,"fake":60,"yaw":0,"defensive":"luasense","mode":["left right"],"luasense":5},"disabled":{},"auto":{"right":0,"method":"simple","left":0,"defensive":"off","timer":150,"antibf":"no"}}},"extra":{"builder":{"builder":"duck moving","team":"t"},"submenu":"builder","features":{"backstab":"off","legit":"off","roll":0,"fix":{},"defensive":"off","distance":250,"fixer":"default","states":{}},"keybinds":{"type_freestand":"static","type_manual":"static","keys":["manual","freestand"],"disablers":{}}},"slow motion":{"t":{"normal":{"right":0,"jitter_slider":0,"yaw":0,"method":"default","left":0,"jitter":"off","custom_slider":60,"body":"off","defensive":"off","mode":{},"body_slider":0},"advanced":{"right":0,"left":0,"trigger":"a: brandon","defensive":"off"},"type":"disabled","luasense":{"right":0,"left":0,"fake":60,"yaw":0,"defensive":"off","mode":{},"luasense":1},"disabled":{},"auto":{"right":0,"method":"simple","left":0,"defensive":"off","timer":150,"antibf":"no"}},"ct":{"normal":{"right":0,"jitter_slider":0,"yaw":0,"method":"default","left":0,"jitter":"off","custom_slider":60,"body":"off","defensive":"off","mode":{},"body_slider":0},"advanced":{"right":0,"left":0,"trigger":"a: brandon","defensive":"off"},"type":"disabled","luasense":{"right":0,"left":0,"fake":60,"yaw":0,"defensive":"off","mode":{},"luasense":1},"disabled":{},"auto":{"right":0,"method":"simple","left":0,"defensive":"off","timer":150,"antibf":"no"}}},"air duck":{"t":{"normal":{"right":0,"jitter_slider":0,"yaw":0,"method":"default","left":0,"jitter":"off","custom_slider":60,"body":"off","defensive":"off","mode":{},"body_slider":0},"advanced":{"right":0,"left":0,"trigger":"a: brandon","defensive":"off"},"type":"luasense","luasense":{"right":-32,"left":33,"fake":60,"yaw":0,"defensive":"luasense","mode":["left right"],"luasense":4},"disabled":{},"auto":{"right":0,"method":"simple","left":0,"defensive":"off","timer":150,"antibf":"no"}},"ct":{"normal":{"right":0,"jitter_slider":0,"yaw":0,"method":"default","left":0,"jitter":"off","custom_slider":60,"body":"off","defensive":"off","mode":{},"body_slider":0},"advanced":{"right":0,"left":0,"trigger":"a: brandon","defensive":"off"},"type":"luasense","luasense":{"right":-32,"left":33,"fake":60,"yaw":0,"defensive":"luasense","mode":["left right"],"luasense":4},"disabled":{},"auto":{"right":0,"method":"simple","left":0,"defensive":"off","timer":150,"antibf":"no"}}},"fake lag":{"t":{"normal":{"right":0,"jitter_slider":0,"yaw":0,"method":"default","left":0,"jitter":"off","custom_slider":60,"body":"off","defensive":"off","mode":{},"body_slider":0},"advanced":{"right":0,"left":0,"trigger":"a: brandon","defensive":"off"},"type":"disabled","luasense":{"right":0,"left":0,"fake":60,"yaw":0,"defensive":"off","mode":{},"luasense":1},"disabled":{},"auto":{"right":0,"method":"simple","left":0,"defensive":"off","timer":150,"antibf":"no"}},"ct":{"normal":{"right":0,"jitter_slider":0,"yaw":0,"method":"default","left":0,"jitter":"off","custom_slider":60,"body":"off","defensive":"off","mode":{},"body_slider":0},"advanced":{"right":0,"left":0,"trigger":"a: brandon","defensive":"off"},"type":"disabled","luasense":{"right":0,"left":0,"fake":60,"yaw":0,"defensive":"off","mode":{},"luasense":1},"disabled":{},"auto":{"right":0,"method":"simple","left":0,"defensive":"off","timer":150,"antibf":"no"}}},"air":{"t":{"normal":{"right":0,"jitter_slider":0,"yaw":0,"method":"default","left":0,"jitter":"off","custom_slider":60,"body":"off","defensive":"off","mode":{},"body_slider":0},"advanced":{"right":0,"left":0,"trigger":"a: brandon","defensive":"off"},"type":"disabled","luasense":{"right":0,"left":0,"fake":60,"yaw":0,"defensive":"off","mode":{},"luasense":1},"disabled":{},"auto":{"right":0,"method":"simple","left":0,"defensive":"off","timer":150,"antibf":"no"}},"ct":{"normal":{"right":0,"jitter_slider":0,"yaw":0,"method":"default","left":0,"jitter":"off","custom_slider":60,"body":"off","defensive":"off","mode":{},"body_slider":0},"advanced":{"right":0,"left":0,"trigger":"a: brandon","defensive":"off"},"type":"disabled","luasense":{"right":0,"left":0,"fake":60,"yaw":0,"defensive":"off","mode":{},"luasense":1},"disabled":{},"auto":{"right":0,"method":"simple","left":0,"defensive":"off","timer":150,"antibf":"no"}}},"global":{"t":{"normal":{"right":0,"jitter_slider":0,"yaw":0,"method":"default","left":0,"jitter":"off","custom_slider":60,"body":"off","defensive":"off","mode":{},"body_slider":0},"advanced":{"right":0,"left":0,"trigger":"a: brandon","defensive":"off"},"type":"luasense","luasense":{"right":-33,"left":31,"fake":60,"yaw":0,"defensive":"luasense","mode":["left right"],"luasense":7},"disabled":{},"auto":{"right":0,"method":"simple","left":0,"defensive":"off","timer":150,"antibf":"no"}},"ct":{"normal":{"right":0,"jitter_slider":0,"yaw":0,"method":"default","left":0,"jitter":"off","custom_slider":60,"body":"off","defensive":"off","mode":{},"body_slider":0},"advanced":{"right":0,"left":0,"trigger":"a: brandon","defensive":"off"},"type":"luasense","luasense":{"right":-33,"left":31,"fake":60,"yaw":0,"defensive":"luasense","mode":["left right"],"luasense":7},"disabled":{},"auto":{"right":0,"method":"simple","left":0,"defensive":"off","timer":150,"antibf":"no"}}},"duck":{"t":{"normal":{"right":0,"jitter_slider":0,"yaw":0,"method":"default","left":0,"jitter":"off","custom_slider":60,"body":"off","defensive":"off","mode":{},"body_slider":0},"advanced":{"right":0,"left":0,"trigger":"a: brandon","defensive":"off"},"type":"luasense","luasense":{"right":-37,"left":37,"fake":60,"yaw":0,"defensive":"luasense","mode":["left right"],"luasense":5},"disabled":{},"auto":{"right":0,"method":"simple","left":0,"defensive":"off","timer":150,"antibf":"no"}},"ct":{"normal":{"right":0,"jitter_slider":0,"yaw":0,"method":"default","left":0,"jitter":"off","custom_slider":60,"body":"off","defensive":"off","mode":{},"body_slider":0},"advanced":{"right":0,"left":0,"trigger":"a: brandon","defensive":"off"},"type":"luasense","luasense":{"right":-37,"left":37,"fake":60,"yaw":0,"defensive":"luasense","mode":["left right"],"luasense":5},"disabled":{},"auto":{"right":0,"method":"simple","left":0,"defensive":"off","timer":150,"antibf":"no"}}},"hide shot":{"t":{"normal":{"right":0,"jitter_slider":0,"yaw":0,"method":"default","left":0,"jitter":"off","custom_slider":60,"body":"off","defensive":"off","mode":{},"body_slider":0},"advanced":{"right":0,"left":0,"trigger":"a: brandon","defensive":"off"},"type":"disabled","luasense":{"right":0,"left":0,"fake":60,"yaw":0,"defensive":"off","mode":{},"luasense":1},"disabled":{},"auto":{"right":0,"method":"simple","left":0,"defensive":"off","timer":150,"antibf":"no"}},"ct":{"normal":{"right":0,"jitter_slider":0,"yaw":0,"method":"default","left":0,"jitter":"off","custom_slider":60,"body":"off","defensive":"off","mode":{},"body_slider":0},"advanced":{"right":0,"left":0,"trigger":"a: brandon","defensive":"off"},"type":"disabled","luasense":{"right":0,"left":0,"fake":60,"yaw":0,"defensive":"off","mode":{},"luasense":1},"disabled":{},"auto":{"right":0,"method":"simple","left":0,"defensive":"off","timer":150,"antibf":"no"}}},"moving":{"t":{"normal":{"right":0,"jitter_slider":0,"yaw":0,"method":"default","left":0,"jitter":"off","custom_slider":60,"body":"off","defensive":"off","mode":{},"body_slider":0},"advanced":{"right":0,"left":0,"trigger":"a: brandon","defensive":"off"},"type":"luasense","luasense":{"right":-24,"left":38,"fake":60,"yaw":0,"defensive":"luasense","mode":["left right"],"luasense":5},"disabled":{},"auto":{"right":0,"method":"simple","left":0,"defensive":"off","timer":150,"antibf":"no"}},"ct":{"normal":{"right":0,"jitter_slider":0,"yaw":0,"method":"default","left":0,"jitter":"off","custom_slider":60,"body":"off","defensive":"off","mode":{},"body_slider":0},"advanced":{"right":0,"left":0,"trigger":"a: brandon","defensive":"off"},"type":"luasense","luasense":{"right":-24,"left":38,"fake":60,"yaw":0,"defensive":"luasense","mode":["left right"],"luasense":5},"disabled":{},"auto":{"right":0,"method":"simple","left":0,"defensive":"off","timer":150,"antibf":"no"}}},"standing":{"t":{"normal":{"right":0,"jitter_slider":0,"yaw":0,"method":"default","left":0,"jitter":"off","custom_slider":60,"body":"off","defensive":"off","mode":{},"body_slider":0},"advanced":{"right":0,"left":0,"trigger":"a: brandon","defensive":"off"},"type":"disabled","luasense":{"right":0,"left":0,"fake":60,"yaw":0,"defensive":"off","mode":{},"luasense":1},"disabled":{},"auto":{"right":0,"method":"simple","left":0,"defensive":"off","timer":150,"antibf":"no"}},"ct":{"normal":{"right":0,"jitter_slider":0,"yaw":0,"method":"default","left":0,"jitter":"off","custom_slider":60,"body":"off","defensive":"off","mode":{},"body_slider":0},"advanced":{"right":0,"left":0,"trigger":"a: brandon","defensive":"off"},"type":"disabled","luasense":{"right":0,"left":0,"fake":60,"yaw":0,"defensive":"off","mode":{},"luasense":1},"disabled":{},"auto":{"right":0,"method":"simple","left":0,"defensive":"off","timer":150,"antibf":"no"}}}}}
]])
                    elseif selected_config == "safe delayed jitter" then
                         tbl = json.parse([[{"LUASENSE":{"duck moving":{"t":{"normal":{"right":0,"jitter_slider":0,"yaw":0,"method":"default","left":0,"jitter":"off","custom_slider":60,"body":"off","defensive":"off","mode":{},"body_slider":0},"advanced":{"right":0,"left":0,"trigger":"a: brandon","defensive":"off"},"type":"disabled","luasense":{"right":0,"left":0,"fake":60,"yaw":0,"defensive":"off","mode":{},"luasense":1},"disabled":{},"auto":{"right":0,"method":"simple","left":0,"defensive":"off","timer":50,"antibf":"no"}},"ct":{"normal":{"right":0,"jitter_slider":0,"yaw":0,"method":"default","left":0,"jitter":"off","custom_slider":60,"body":"off","defensive":"off","mode":{},"body_slider":0},"advanced":{"right":0,"left":0,"trigger":"a: brandon","defensive":"off"},"type":"disabled","luasense":{"right":0,"left":0,"fake":60,"yaw":0,"defensive":"off","mode":{},"luasense":1},"disabled":{},"auto":{"right":0,"method":"simple","left":0,"defensive":"off","timer":50,"antibf":"no"}}},"extra":{"builder":{"builder":"global","team":"t"},"submenu":"builder","features":{"backstab":"off","legit":"off","roll":0,"fix":{},"defensive":"off","distance":250,"fixer":"default","states":{}},"keybinds":{"type_freestand":"static","type_manual":"static","keys":["manual","freestand"],"disablers":{}}},"slow motion":{"t":{"normal":{"right":0,"jitter_slider":0,"yaw":0,"method":"default","left":0,"jitter":"off","custom_slider":60,"body":"off","defensive":"off","mode":{},"body_slider":0},"advanced":{"right":0,"left":0,"trigger":"a: brandon","defensive":"off"},"type":"disabled","luasense":{"right":0,"left":0,"fake":60,"yaw":0,"defensive":"off","mode":{},"luasense":1},"disabled":{},"auto":{"right":0,"method":"simple","left":0,"defensive":"off","timer":50,"antibf":"no"}},"ct":{"normal":{"right":0,"jitter_slider":0,"yaw":0,"method":"default","left":0,"jitter":"off","custom_slider":60,"body":"off","defensive":"off","mode":{},"body_slider":0},"advanced":{"right":0,"left":0,"trigger":"a: brandon","defensive":"off"},"type":"disabled","luasense":{"right":0,"left":0,"fake":60,"yaw":0,"defensive":"off","mode":{},"luasense":1},"disabled":{},"auto":{"right":0,"method":"simple","left":0,"defensive":"off","timer":50,"antibf":"no"}}},"air duck":{"t":{"normal":{"right":0,"jitter_slider":0,"yaw":0,"method":"default","left":0,"jitter":"off","custom_slider":60,"body":"off","defensive":"off","mode":{},"body_slider":0},"advanced":{"right":0,"left":0,"trigger":"a: brandon","defensive":"off"},"type":"disabled","luasense":{"right":0,"left":0,"fake":60,"yaw":0,"defensive":"off","mode":{},"luasense":1},"disabled":{},"auto":{"right":0,"method":"simple","left":0,"defensive":"off","timer":50,"antibf":"no"}},"ct":{"normal":{"right":0,"jitter_slider":0,"yaw":0,"method":"default","left":0,"jitter":"off","custom_slider":60,"body":"off","defensive":"off","mode":{},"body_slider":0},"advanced":{"right":0,"left":0,"trigger":"a: brandon","defensive":"off"},"type":"disabled","luasense":{"right":0,"left":0,"fake":60,"yaw":0,"defensive":"off","mode":{},"luasense":1},"disabled":{},"auto":{"right":0,"method":"simple","left":0,"defensive":"off","timer":50,"antibf":"no"}}},"fake lag":{"t":{"normal":{"right":0,"jitter_slider":0,"yaw":0,"method":"default","left":0,"jitter":"off","custom_slider":60,"body":"off","defensive":"off","mode":{},"body_slider":0},"advanced":{"right":0,"left":0,"trigger":"a: brandon","defensive":"off"},"type":"disabled","luasense":{"right":0,"left":0,"fake":60,"yaw":0,"defensive":"off","mode":{},"luasense":1},"disabled":{},"auto":{"right":0,"method":"simple","left":0,"defensive":"off","timer":50,"antibf":"no"}},"ct":{"normal":{"right":0,"jitter_slider":0,"yaw":0,"method":"default","left":0,"jitter":"off","custom_slider":60,"body":"off","defensive":"off","mode":{},"body_slider":0},"advanced":{"right":0,"left":0,"trigger":"a: brandon","defensive":"off"},"type":"disabled","luasense":{"right":0,"left":0,"fake":60,"yaw":0,"defensive":"off","mode":{},"luasense":1},"disabled":{},"auto":{"right":0,"method":"simple","left":0,"defensive":"off","timer":50,"antibf":"no"}}},"air":{"t":{"normal":{"right":0,"jitter_slider":0,"yaw":0,"method":"default","left":0,"jitter":"off","custom_slider":60,"body":"jitter","defensive":"always on","mode":{},"body_slider":0},"advanced":{"right":0,"left":0,"trigger":"a: brandon","defensive":"off"},"type":"normal","luasense":{"right":0,"left":0,"fake":60,"yaw":0,"defensive":"off","mode":{},"luasense":1},"disabled":{},"auto":{"right":0,"method":"simple","left":0,"defensive":"off","timer":50,"antibf":"no"}},"ct":{"normal":{"right":0,"jitter_slider":0,"yaw":0,"method":"default","left":0,"jitter":"off","custom_slider":60,"body":"jitter","defensive":"always on","mode":{},"body_slider":0},"advanced":{"right":0,"left":0,"trigger":"a: brandon","defensive":"off"},"type":"normal","luasense":{"right":0,"left":0,"fake":60,"yaw":0,"defensive":"off","mode":{},"luasense":1},"disabled":{},"auto":{"right":0,"method":"simple","left":0,"defensive":"off","timer":50,"antibf":"no"}}},"global":{"t":{"normal":{"right":0,"jitter_slider":0,"yaw":0,"method":"default","left":0,"jitter":"off","custom_slider":60,"body":"off","defensive":"off","mode":{},"body_slider":0},"advanced":{"right":-30,"left":30,"trigger":"b: best","defensive":"luasense"},"type":"auto","luasense":{"right":0,"left":0,"fake":60,"yaw":0,"defensive":"off","mode":{},"luasense":1},"disabled":{},"auto":{"right":-17,"method":"luasense","left":38,"defensive":"luasense","timer":50,"antibf":"no"}},"ct":{"normal":{"right":0,"jitter_slider":0,"yaw":0,"method":"default","left":0,"jitter":"off","custom_slider":60,"body":"off","defensive":"off","mode":{},"body_slider":0},"advanced":{"right":-30,"left":30,"trigger":"b: best","defensive":"luasense"},"type":"auto","luasense":{"right":0,"left":0,"fake":60,"yaw":0,"defensive":"off","mode":{},"luasense":1},"disabled":{},"auto":{"right":-17,"method":"luasense","left":38,"defensive":"luasense","timer":50,"antibf":"no"}}},"duck":{"t":{"normal":{"right":0,"jitter_slider":0,"yaw":0,"method":"default","left":0,"jitter":"off","custom_slider":60,"body":"off","defensive":"off","mode":{},"body_slider":0},"advanced":{"right":0,"left":0,"trigger":"a: brandon","defensive":"off"},"type":"disabled","luasense":{"right":0,"left":0,"fake":60,"yaw":0,"defensive":"off","mode":{},"luasense":1},"disabled":{},"auto":{"right":0,"method":"simple","left":0,"defensive":"off","timer":50,"antibf":"no"}},"ct":{"normal":{"right":0,"jitter_slider":0,"yaw":0,"method":"default","left":0,"jitter":"off","custom_slider":60,"body":"off","defensive":"off","mode":{},"body_slider":0},"advanced":{"right":0,"left":0,"trigger":"a: brandon","defensive":"off"},"type":"disabled","luasense":{"right":0,"left":0,"fake":60,"yaw":0,"defensive":"off","mode":{},"luasense":1},"disabled":{},"auto":{"right":0,"method":"simple","left":0,"defensive":"off","timer":50,"antibf":"no"}}},"hide shot":{"t":{"normal":{"right":0,"jitter_slider":0,"yaw":0,"method":"default","left":0,"jitter":"off","custom_slider":60,"body":"off","defensive":"off","mode":{},"body_slider":0},"advanced":{"right":0,"left":0,"trigger":"a: brandon","defensive":"off"},"type":"disabled","luasense":{"right":0,"left":0,"fake":60,"yaw":0,"defensive":"off","mode":{},"luasense":1},"disabled":{},"auto":{"right":0,"method":"simple","left":0,"defensive":"off","timer":50,"antibf":"no"}},"ct":{"normal":{"right":0,"jitter_slider":0,"yaw":0,"method":"default","left":0,"jitter":"off","custom_slider":60,"body":"off","defensive":"off","mode":{},"body_slider":0},"advanced":{"right":0,"left":0,"trigger":"a: brandon","defensive":"off"},"type":"disabled","luasense":{"right":0,"left":0,"fake":60,"yaw":0,"defensive":"off","mode":{},"luasense":1},"disabled":{},"auto":{"right":0,"method":"simple","left":0,"defensive":"off","timer":50,"antibf":"no"}}},"moving":{"t":{"normal":{"right":0,"jitter_slider":0,"yaw":0,"method":"default","left":0,"jitter":"off","custom_slider":60,"body":"off","defensive":"off","mode":{},"body_slider":0},"advanced":{"right":0,"left":0,"trigger":"a: brandon","defensive":"off"},"type":"disabled","luasense":{"right":0,"left":0,"fake":60,"yaw":0,"defensive":"off","mode":{},"luasense":1},"disabled":{},"auto":{"right":0,"method":"simple","left":0,"defensive":"off","timer":50,"antibf":"no"}},"ct":{"normal":{"right":0,"jitter_slider":0,"yaw":0,"method":"default","left":0,"jitter":"off","custom_slider":60,"body":"off","defensive":"off","mode":{},"body_slider":0},"advanced":{"right":0,"left":0,"trigger":"a: brandon","defensive":"off"},"type":"disabled","luasense":{"right":0,"left":0,"fake":60,"yaw":0,"defensive":"off","mode":{},"luasense":1},"disabled":{},"auto":{"right":0,"method":"simple","left":0,"defensive":"off","timer":50,"antibf":"no"}}},"standing":{"t":{"normal":{"right":0,"jitter_slider":0,"yaw":0,"method":"default","left":0,"jitter":"off","custom_slider":60,"body":"off","defensive":"off","mode":{},"body_slider":0},"advanced":{"right":0,"left":0,"trigger":"a: brandon","defensive":"off"},"type":"disabled","luasense":{"right":0,"left":0,"fake":60,"yaw":0,"defensive":"off","mode":{},"luasense":1},"disabled":{},"auto":{"right":0,"method":"simple","left":0,"defensive":"off","timer":50,"antibf":"no"}},"ct":{"normal":{"right":0,"jitter_slider":0,"yaw":0,"method":"default","left":0,"jitter":"off","custom_slider":60,"body":"off","defensive":"off","mode":{},"body_slider":0},"advanced":{"right":0,"left":0,"trigger":"a: brandon","defensive":"off"},"type":"disabled","luasense":{"right":0,"left":0,"fake":60,"yaw":0,"defensive":"off","mode":{},"luasense":1},"disabled":{},"auto":{"right":0,"method":"simple","left":0,"defensive":"off","timer":50,"antibf":"no"}}}}}]])
                    elseif selected_config == "aggressive jitter" then
                        tbl = json.parse([[{"LUASENSE":{"duck moving":{"t":{"normal":{"right":-1,"jitter_slider":49,"yaw":9,"method":"default","left":5,"jitter":"center","custom_slider":60,"body":"jitter","defensive":"luasense","mode":["yaw"],"body_slider":-180},"advanced":{"right":0,"left":0,"trigger":"a: brandon","defensive":"off"},"type":"normal","luasense":{"right":0,"left":0,"fake":60,"yaw":0,"defensive":"off","mode":{},"luasense":1},"disabled":{},"auto":{"right":0,"method":"simple","left":0,"defensive":"off","timer":150,"antibf":"no"}},"ct":{"normal":{"right":-1,"jitter_slider":49,"yaw":9,"method":"default","left":5,"jitter":"center","custom_slider":60,"body":"jitter","defensive":"luasense","mode":["yaw"],"body_slider":-180},"advanced":{"right":0,"left":0,"trigger":"a: brandon","defensive":"off"},"type":"normal","luasense":{"right":0,"left":0,"fake":60,"yaw":0,"defensive":"off","mode":{},"luasense":1},"disabled":{},"auto":{"right":0,"method":"simple","left":0,"defensive":"off","timer":150,"antibf":"no"}}},"extra":{"builder":{"builder":"moving","team":"t"},"submenu":"keybinds","features":{"backstab":"off","legit":"off","roll":0,"fix":{},"defensive":"off","distance":250,"fixer":"default","states":{}},"keybinds":{"type_freestand":"jitter","type_manual":"default","keys":["manual","freestand"],"disablers":{}}},"slow motion":{"t":{"normal":{"right":0,"jitter_slider":0,"yaw":0,"method":"default","left":0,"jitter":"off","custom_slider":60,"body":"off","defensive":"always on","mode":{},"body_slider":0},"advanced":{"right":0,"left":0,"trigger":"a: brandon","defensive":"off"},"type":"auto","luasense":{"right":0,"left":0,"fake":60,"yaw":0,"defensive":"off","mode":{},"luasense":1},"disabled":{},"auto":{"right":0,"method":"simple","left":0,"defensive":"always on","timer":150,"antibf":"yes"}},"ct":{"normal":{"right":0,"jitter_slider":0,"yaw":0,"method":"default","left":0,"jitter":"off","custom_slider":60,"body":"off","defensive":"always on","mode":{},"body_slider":0},"advanced":{"right":0,"left":0,"trigger":"a: brandon","defensive":"off"},"type":"auto","luasense":{"right":0,"left":0,"fake":60,"yaw":0,"defensive":"off","mode":{},"luasense":1},"disabled":{},"auto":{"right":0,"method":"simple","left":0,"defensive":"always on","timer":150,"antibf":"yes"}}},"air duck":{"t":{"normal":{"right":13,"jitter_slider":51,"yaw":0,"method":"default","left":-7,"jitter":"center","custom_slider":60,"body":"jitter","defensive":"always on","mode":{},"body_slider":-180},"advanced":{"right":0,"left":0,"trigger":"a: brandon","defensive":"off"},"type":"normal","luasense":{"right":0,"left":0,"fake":60,"yaw":0,"defensive":"off","mode":{},"luasense":1},"disabled":{},"auto":{"right":0,"method":"simple","left":0,"defensive":"off","timer":150,"antibf":"no"}},"ct":{"normal":{"right":13,"jitter_slider":51,"yaw":0,"method":"default","left":-7,"jitter":"center","custom_slider":60,"body":"jitter","defensive":"always on","mode":{},"body_slider":-180},"advanced":{"right":0,"left":0,"trigger":"a: brandon","defensive":"off"},"type":"normal","luasense":{"right":0,"left":0,"fake":60,"yaw":0,"defensive":"off","mode":{},"luasense":1},"disabled":{},"auto":{"right":0,"method":"simple","left":0,"defensive":"off","timer":150,"antibf":"no"}}},"fake lag":{"t":{"normal":{"right":0,"jitter_slider":0,"yaw":0,"method":"default","left":0,"jitter":"off","custom_slider":60,"body":"off","defensive":"off","mode":{},"body_slider":0},"advanced":{"right":0,"left":0,"trigger":"a: brandon","defensive":"off"},"type":"disabled","luasense":{"right":0,"left":0,"fake":60,"yaw":0,"defensive":"off","mode":{},"luasense":1},"disabled":{},"auto":{"right":0,"method":"simple","left":0,"defensive":"off","timer":150,"antibf":"no"}},"ct":{"normal":{"right":0,"jitter_slider":0,"yaw":0,"method":"default","left":0,"jitter":"off","custom_slider":60,"body":"off","defensive":"off","mode":{},"body_slider":0},"advanced":{"right":0,"left":0,"trigger":"a: brandon","defensive":"off"},"type":"disabled","luasense":{"right":0,"left":0,"fake":60,"yaw":0,"defensive":"off","mode":{},"luasense":1},"disabled":{},"auto":{"right":0,"method":"simple","left":0,"defensive":"off","timer":150,"antibf":"no"}}},"air":{"t":{"normal":{"right":-1,"jitter_slider":60,"yaw":0,"method":"default","left":7,"jitter":"center","custom_slider":60,"body":"jitter","defensive":"always on","mode":{},"body_slider":-180},"advanced":{"right":0,"left":0,"trigger":"a: brandon","defensive":"off"},"type":"normal","luasense":{"right":0,"left":0,"fake":60,"yaw":0,"defensive":"off","mode":{},"luasense":1},"disabled":{},"auto":{"right":0,"method":"simple","left":0,"defensive":"off","timer":150,"antibf":"no"}},"ct":{"normal":{"right":-1,"jitter_slider":60,"yaw":0,"method":"default","left":7,"jitter":"center","custom_slider":60,"body":"jitter","defensive":"always on","mode":{},"body_slider":-180},"advanced":{"right":0,"left":0,"trigger":"a: brandon","defensive":"off"},"type":"normal","luasense":{"right":0,"left":0,"fake":60,"yaw":0,"defensive":"off","mode":{},"luasense":1},"disabled":{},"auto":{"right":0,"method":"simple","left":0,"defensive":"off","timer":150,"antibf":"no"}}},"global":{"t":{"normal":{"right":0,"jitter_slider":0,"yaw":0,"method":"default","left":0,"jitter":"off","custom_slider":60,"body":"off","defensive":"off","mode":{},"body_slider":0},"advanced":{"right":0,"left":0,"trigger":"a: brandon","defensive":"off"},"type":"normal","luasense":{"right":0,"left":0,"fake":60,"yaw":0,"defensive":"off","mode":{},"luasense":1},"disabled":{},"auto":{"right":0,"method":"simple","left":0,"defensive":"off","timer":150,"antibf":"no"}},"ct":{"normal":{"right":0,"jitter_slider":0,"yaw":0,"method":"default","left":0,"jitter":"off","custom_slider":60,"body":"off","defensive":"off","mode":{},"body_slider":0},"advanced":{"right":0,"left":0,"trigger":"a: brandon","defensive":"off"},"type":"normal","luasense":{"right":0,"left":0,"fake":60,"yaw":0,"defensive":"off","mode":{},"luasense":1},"disabled":{},"auto":{"right":0,"method":"simple","left":0,"defensive":"off","timer":150,"antibf":"no"}}},"duck":{"t":{"normal":{"right":38,"jitter_slider":74,"yaw":0,"method":"default","left":-22,"jitter":"center","custom_slider":60,"body":"jitter","defensive":"always on","mode":["yaw"],"body_slider":-180},"advanced":{"right":0,"left":0,"trigger":"a: brandon","defensive":"off"},"type":"normal","luasense":{"right":0,"left":0,"fake":60,"yaw":0,"defensive":"off","mode":{},"luasense":1},"disabled":{},"auto":{"right":0,"method":"simple","left":0,"defensive":"off","timer":150,"antibf":"no"}},"ct":{"normal":{"right":38,"jitter_slider":74,"yaw":0,"method":"default","left":-22,"jitter":"center","custom_slider":60,"body":"jitter","defensive":"always on","mode":["yaw"],"body_slider":-180},"advanced":{"right":0,"left":0,"trigger":"a: brandon","defensive":"off"},"type":"normal","luasense":{"right":0,"left":0,"fake":60,"yaw":0,"defensive":"off","mode":{},"luasense":1},"disabled":{},"auto":{"right":0,"method":"simple","left":0,"defensive":"off","timer":150,"antibf":"no"}}},"hide shot":{"t":{"normal":{"right":0,"jitter_slider":0,"yaw":0,"method":"default","left":0,"jitter":"off","custom_slider":60,"body":"off","defensive":"off","mode":{},"body_slider":0},"advanced":{"right":0,"left":0,"trigger":"a: brandon","defensive":"off"},"type":"disabled","luasense":{"right":0,"left":0,"fake":60,"yaw":0,"defensive":"off","mode":{},"luasense":1},"disabled":{},"auto":{"right":0,"method":"simple","left":0,"defensive":"off","timer":150,"antibf":"no"}},"ct":{"normal":{"right":0,"jitter_slider":0,"yaw":0,"method":"default","left":0,"jitter":"off","custom_slider":60,"body":"off","defensive":"off","mode":{},"body_slider":0},"advanced":{"right":0,"left":0,"trigger":"a: brandon","defensive":"off"},"type":"disabled","luasense":{"right":0,"left":0,"fake":60,"yaw":0,"defensive":"off","mode":{},"luasense":1},"disabled":{},"auto":{"right":0,"method":"simple","left":0,"defensive":"off","timer":150,"antibf":"no"}}},"moving":{"t":{"normal":{"right":-7,"jitter_slider":68,"yaw":0,"method":"luasense","left":5,"jitter":"center","custom_slider":60,"body":"jitter","defensive":"luasense","mode":{},"body_slider":-180},"advanced":{"right":0,"left":0,"trigger":"a: brandon","defensive":"off"},"type":"normal","luasense":{"right":0,"left":0,"fake":60,"yaw":0,"defensive":"off","mode":{},"luasense":1},"disabled":{},"auto":{"right":0,"method":"simple","left":0,"defensive":"off","timer":150,"antibf":"no"}},"ct":{"normal":{"right":-7,"jitter_slider":68,"yaw":0,"method":"luasense","left":5,"jitter":"center","custom_slider":60,"body":"jitter","defensive":"luasense","mode":{},"body_slider":-180},"advanced":{"right":0,"left":0,"trigger":"a: brandon","defensive":"off"},"type":"normal","luasense":{"right":0,"left":0,"fake":60,"yaw":0,"defensive":"off","mode":{},"luasense":1},"disabled":{},"auto":{"right":0,"method":"simple","left":0,"defensive":"off","timer":150,"antibf":"no"}}},"standing":{"t":{"normal":{"right":-5,"jitter_slider":57,"yaw":-3,"method":"luasense","left":-11,"jitter":"center","custom_slider":60,"body":"jitter","defensive":"luasense","mode":["yaw"],"body_slider":-180},"advanced":{"right":0,"left":0,"trigger":"a: brandon","defensive":"off"},"type":"normal","luasense":{"right":-3,"left":22,"fake":60,"yaw":0,"defensive":"always on","mode":["yaw"],"luasense":1},"disabled":{},"auto":{"right":0,"method":"simple","left":0,"defensive":"always on","timer":150,"antibf":"yes"}},"ct":{"normal":{"right":-5,"jitter_slider":57,"yaw":-3,"method":"luasense","left":-11,"jitter":"center","custom_slider":60,"body":"jitter","defensive":"luasense","mode":["yaw"],"body_slider":-180},"advanced":{"right":0,"left":0,"trigger":"a: brandon","defensive":"off"},"type":"normal","luasense":{"right":-3,"left":22,"fake":60,"yaw":0,"defensive":"always on","mode":["yaw"],"luasense":1},"disabled":{},"auto":{"right":0,"method":"simple","left":0,"defensive":"always on","timer":150,"antibf":"yes"}}}}}
]])
                    elseif selected_config == "safe jitter" then
                         tbl = json.parse([[{"LUASENSE":{"duck moving":{"t":{"normal":{"right":0,"jitter_slider":0,"yaw":0,"method":"default","left":0,"jitter":"off","custom_slider":60,"body":"off","defensive":"off","mode":{},"body_slider":0},"advanced":{"right":0,"left":0,"trigger":"a: brandon","defensive":"off"},"type":"disabled","luasense":{"right":0,"left":0,"fake":60,"yaw":0,"defensive":"off","mode":{},"luasense":1},"disabled":{},"auto":{"right":0,"method":"simple","left":0,"defensive":"off","timer":50,"antibf":"no"}},"ct":{"normal":{"right":0,"jitter_slider":0,"yaw":0,"method":"default","left":0,"jitter":"off","custom_slider":60,"body":"off","defensive":"off","mode":{},"body_slider":0},"advanced":{"right":0,"left":0,"trigger":"a: brandon","defensive":"off"},"type":"disabled","luasense":{"right":0,"left":0,"fake":60,"yaw":0,"defensive":"off","mode":{},"luasense":1},"disabled":{},"auto":{"right":0,"method":"simple","left":0,"defensive":"off","timer":50,"antibf":"no"}}},"extra":{"builder":{"builder":"air","team":"ct"},"submenu":"builder","features":{"backstab":"forward","legit":"off","roll":0,"fix":{},"defensive":"off","distance":300,"fixer":"default","states":{}},"keybinds":{"type_freestand":"jitter","type_manual":"static","keys":["manual","freestand"],"disablers":{}}},"slow motion":{"t":{"normal":{"right":0,"jitter_slider":0,"yaw":0,"method":"default","left":0,"jitter":"off","custom_slider":60,"body":"off","defensive":"off","mode":{},"body_slider":0},"advanced":{"right":0,"left":0,"trigger":"a: brandon","defensive":"off"},"type":"disabled","luasense":{"right":0,"left":0,"fake":60,"yaw":0,"defensive":"off","mode":{},"luasense":1},"disabled":{},"auto":{"right":0,"method":"simple","left":0,"defensive":"off","timer":50,"antibf":"no"}},"ct":{"normal":{"right":0,"jitter_slider":0,"yaw":0,"method":"default","left":0,"jitter":"off","custom_slider":60,"body":"off","defensive":"off","mode":{},"body_slider":0},"advanced":{"right":0,"left":0,"trigger":"a: brandon","defensive":"off"},"type":"disabled","luasense":{"right":0,"left":0,"fake":60,"yaw":0,"defensive":"off","mode":{},"luasense":1},"disabled":{},"auto":{"right":0,"method":"simple","left":0,"defensive":"off","timer":50,"antibf":"no"}}},"air duck":{"t":{"normal":{"right":0,"jitter_slider":0,"yaw":0,"method":"default","left":0,"jitter":"off","custom_slider":60,"body":"off","defensive":"off","mode":{},"body_slider":0},"advanced":{"right":0,"left":0,"trigger":"a: brandon","defensive":"off"},"type":"disabled","luasense":{"right":0,"left":0,"fake":60,"yaw":0,"defensive":"off","mode":{},"luasense":1},"disabled":{},"auto":{"right":0,"method":"simple","left":0,"defensive":"off","timer":50,"antibf":"no"}},"ct":{"normal":{"right":0,"jitter_slider":0,"yaw":0,"method":"default","left":0,"jitter":"off","custom_slider":60,"body":"off","defensive":"off","mode":{},"body_slider":0},"advanced":{"right":0,"left":0,"trigger":"a: brandon","defensive":"off"},"type":"disabled","luasense":{"right":0,"left":0,"fake":60,"yaw":0,"defensive":"off","mode":{},"luasense":1},"disabled":{},"auto":{"right":0,"method":"simple","left":0,"defensive":"off","timer":50,"antibf":"no"}}},"fake lag":{"t":{"normal":{"right":-22,"jitter_slider":0,"yaw":0,"method":"luasense","left":19,"jitter":"skitter","custom_slider":60,"body":"jitter","defensive":"luasense","mode":["left right"],"body_slider":0},"advanced":{"right":0,"left":0,"trigger":"a: brandon","defensive":"off"},"type":"normal","luasense":{"right":0,"left":0,"fake":60,"yaw":0,"defensive":"off","mode":{},"luasense":1},"disabled":{},"auto":{"right":0,"method":"simple","left":0,"defensive":"off","timer":50,"antibf":"no"}},"ct":{"normal":{"right":-22,"jitter_slider":0,"yaw":0,"method":"luasense","left":19,"jitter":"skitter","custom_slider":60,"body":"jitter","defensive":"luasense","mode":["left right"],"body_slider":0},"advanced":{"right":0,"left":0,"trigger":"a: brandon","defensive":"off"},"type":"normal","luasense":{"right":0,"left":0,"fake":60,"yaw":0,"defensive":"off","mode":{},"luasense":1},"disabled":{},"auto":{"right":0,"method":"simple","left":0,"defensive":"off","timer":50,"antibf":"no"}}},"air":{"t":{"normal":{"right":1,"jitter_slider":0,"yaw":0,"method":"default","left":0,"jitter":"off","custom_slider":60,"body":"jitter","defensive":"always on","mode":{},"body_slider":0},"advanced":{"right":0,"left":0,"trigger":"a: brandon","defensive":"off"},"type":"normal","luasense":{"right":0,"left":0,"fake":60,"yaw":0,"defensive":"off","mode":{},"luasense":1},"disabled":{},"auto":{"right":0,"method":"simple","left":0,"defensive":"off","timer":50,"antibf":"no"}},"ct":{"normal":{"right":1,"jitter_slider":0,"yaw":0,"method":"default","left":0,"jitter":"off","custom_slider":60,"body":"jitter","defensive":"always on","mode":{},"body_slider":0},"advanced":{"right":0,"left":0,"trigger":"a: brandon","defensive":"off"},"type":"normal","luasense":{"right":0,"left":0,"fake":60,"yaw":0,"defensive":"off","mode":{},"luasense":1},"disabled":{},"auto":{"right":0,"method":"simple","left":0,"defensive":"off","timer":50,"antibf":"no"}}},"global":{"t":{"normal":{"right":-21,"jitter_slider":180,"yaw":0,"method":"luasense","left":39,"jitter":"off","custom_slider":60,"body":"jitter","defensive":"luasense","mode":["left right"],"body_slider":-1},"advanced":{"right":-30,"left":30,"trigger":"b: best","defensive":"luasense"},"type":"normal","luasense":{"right":0,"left":0,"fake":60,"yaw":0,"defensive":"off","mode":{},"luasense":1},"disabled":{},"auto":{"right":-17,"method":"luasense","left":38,"defensive":"luasense","timer":50,"antibf":"no"}},"ct":{"normal":{"right":-24,"jitter_slider":180,"yaw":0,"method":"luasense","left":41,"jitter":"off","custom_slider":60,"body":"jitter","defensive":"luasense","mode":["left right"],"body_slider":-1},"advanced":{"right":-30,"left":30,"trigger":"b: best","defensive":"luasense"},"type":"normal","luasense":{"right":0,"left":0,"fake":60,"yaw":0,"defensive":"off","mode":{},"luasense":1},"disabled":{},"auto":{"right":-17,"method":"luasense","left":38,"defensive":"luasense","timer":50,"antibf":"no"}}},"duck":{"t":{"normal":{"right":0,"jitter_slider":0,"yaw":0,"method":"default","left":0,"jitter":"off","custom_slider":60,"body":"off","defensive":"off","mode":{},"body_slider":0},"advanced":{"right":0,"left":0,"trigger":"a: brandon","defensive":"off"},"type":"disabled","luasense":{"right":0,"left":0,"fake":60,"yaw":0,"defensive":"off","mode":{},"luasense":1},"disabled":{},"auto":{"right":0,"method":"simple","left":0,"defensive":"off","timer":50,"antibf":"no"}},"ct":{"normal":{"right":0,"jitter_slider":0,"yaw":0,"method":"default","left":0,"jitter":"off","custom_slider":60,"body":"off","defensive":"off","mode":{},"body_slider":0},"advanced":{"right":0,"left":0,"trigger":"a: brandon","defensive":"off"},"type":"disabled","luasense":{"right":0,"left":0,"fake":60,"yaw":0,"defensive":"off","mode":{},"luasense":1},"disabled":{},"auto":{"right":0,"method":"simple","left":0,"defensive":"off","timer":50,"antibf":"no"}}},"hide shot":{"t":{"normal":{"right":0,"jitter_slider":0,"yaw":0,"method":"default","left":0,"jitter":"off","custom_slider":60,"body":"off","defensive":"off","mode":{},"body_slider":0},"advanced":{"right":0,"left":0,"trigger":"a: brandon","defensive":"off"},"type":"disabled","luasense":{"right":0,"left":0,"fake":60,"yaw":0,"defensive":"off","mode":{},"luasense":1},"disabled":{},"auto":{"right":0,"method":"simple","left":0,"defensive":"off","timer":50,"antibf":"no"}},"ct":{"normal":{"right":0,"jitter_slider":0,"yaw":0,"method":"default","left":0,"jitter":"off","custom_slider":60,"body":"off","defensive":"off","mode":{},"body_slider":0},"advanced":{"right":0,"left":0,"trigger":"a: brandon","defensive":"off"},"type":"disabled","luasense":{"right":0,"left":0,"fake":60,"yaw":0,"defensive":"off","mode":{},"luasense":1},"disabled":{},"auto":{"right":0,"method":"simple","left":0,"defensive":"off","timer":50,"antibf":"no"}}},"moving":{"t":{"normal":{"right":0,"jitter_slider":0,"yaw":0,"method":"default","left":0,"jitter":"off","custom_slider":60,"body":"off","defensive":"off","mode":{},"body_slider":0},"advanced":{"right":0,"left":0,"trigger":"a: brandon","defensive":"off"},"type":"disabled","luasense":{"right":0,"left":0,"fake":60,"yaw":0,"defensive":"off","mode":{},"luasense":1},"disabled":{},"auto":{"right":0,"method":"simple","left":0,"defensive":"off","timer":50,"antibf":"no"}},"ct":{"normal":{"right":0,"jitter_slider":0,"yaw":0,"method":"default","left":0,"jitter":"off","custom_slider":60,"body":"off","defensive":"off","mode":{},"body_slider":0},"advanced":{"right":0,"left":0,"trigger":"a: brandon","defensive":"off"},"type":"disabled","luasense":{"right":0,"left":0,"fake":60,"yaw":0,"defensive":"off","mode":{},"luasense":1},"disabled":{},"auto":{"right":0,"method":"simple","left":0,"defensive":"off","timer":50,"antibf":"no"}}},"standing":{"t":{"normal":{"right":0,"jitter_slider":0,"yaw":0,"method":"default","left":0,"jitter":"off","custom_slider":60,"body":"off","defensive":"off","mode":{},"body_slider":0},"advanced":{"right":0,"left":0,"trigger":"a: brandon","defensive":"off"},"type":"disabled","luasense":{"right":0,"left":0,"fake":60,"yaw":0,"defensive":"off","mode":{},"luasense":1},"disabled":{},"auto":{"right":0,"method":"simple","left":0,"defensive":"off","timer":50,"antibf":"no"}},"ct":{"normal":{"right":0,"jitter_slider":0,"yaw":0,"method":"default","left":0,"jitter":"off","custom_slider":60,"body":"off","defensive":"off","mode":{},"body_slider":0},"advanced":{"right":0,"left":0,"trigger":"a: brandon","defensive":"off"},"type":"disabled","luasense":{"right":0,"left":0,"fake":60,"yaw":0,"defensive":"off","mode":{},"luasense":1},"disabled":{},"auto":{"right":0,"method":"simple","left":0,"defensive":"off","timer":50,"antibf":"no"}}}}}]])
                    elseif selected_config == "perfect jitter" then
                        tbl = json.parse([[{"LUASENSE":{"duck moving":{"t":{"normal":{"right":0,"jitter_slider":0,"yaw":0,"method":"default","left":0,"jitter":"off","custom_slider":60,"body":"off","defensive":"off","mode":{},"body_slider":0},"advanced":{"right":0,"left":0,"trigger":"a: brandon","defensive":"off"},"type":"disabled","luasense":{"right":0,"left":0,"fake":60,"yaw":0,"defensive":"off","mode":{},"luasense":1},"disabled":{},"auto":{"right":0,"method":"simple","left":0,"defensive":"off","timer":50,"antibf":"no"}},"ct":{"normal":{"right":0,"jitter_slider":0,"yaw":0,"method":"default","left":0,"jitter":"off","custom_slider":60,"body":"off","defensive":"off","mode":{},"body_slider":0},"advanced":{"right":0,"left":0,"trigger":"a: brandon","defensive":"off"},"type":"disabled","luasense":{"right":0,"left":0,"fake":60,"yaw":0,"defensive":"off","mode":{},"luasense":1},"disabled":{},"auto":{"right":0,"method":"simple","left":0,"defensive":"off","timer":50,"antibf":"no"}}},"extra":{"builder":{"builder":"global","team":"t"},"submenu":"builder","features":{"backstab":"forward","legit":"default","roll":0,"fix":{},"defensive":"off","distance":300,"fixer":"default","states":{}},"keybinds":{"type_freestand":"jitter","type_manual":"static","keys":["manual","freestand"],"disablers":{}}},"slow motion":{"t":{"normal":{"right":0,"jitter_slider":0,"yaw":0,"method":"default","left":0,"jitter":"off","custom_slider":60,"body":"off","defensive":"off","mode":{},"body_slider":0},"advanced":{"right":0,"left":0,"trigger":"a: brandon","defensive":"off"},"type":"disabled","luasense":{"right":0,"left":0,"fake":60,"yaw":0,"defensive":"off","mode":{},"luasense":1},"disabled":{},"auto":{"right":0,"method":"simple","left":0,"defensive":"off","timer":50,"antibf":"no"}},"ct":{"normal":{"right":0,"jitter_slider":0,"yaw":0,"method":"default","left":0,"jitter":"off","custom_slider":60,"body":"off","defensive":"off","mode":{},"body_slider":0},"advanced":{"right":0,"left":0,"trigger":"a: brandon","defensive":"off"},"type":"disabled","luasense":{"right":0,"left":0,"fake":60,"yaw":0,"defensive":"off","mode":{},"luasense":1},"disabled":{},"auto":{"right":0,"method":"simple","left":0,"defensive":"off","timer":50,"antibf":"no"}}},"air duck":{"t":{"normal":{"right":0,"jitter_slider":0,"yaw":0,"method":"default","left":0,"jitter":"off","custom_slider":60,"body":"off","defensive":"off","mode":{},"body_slider":0},"advanced":{"right":0,"left":0,"trigger":"a: brandon","defensive":"off"},"type":"disabled","luasense":{"right":0,"left":0,"fake":60,"yaw":0,"defensive":"off","mode":{},"luasense":1},"disabled":{},"auto":{"right":0,"method":"simple","left":0,"defensive":"off","timer":50,"antibf":"no"}},"ct":{"normal":{"right":0,"jitter_slider":0,"yaw":0,"method":"default","left":0,"jitter":"off","custom_slider":60,"body":"off","defensive":"off","mode":{},"body_slider":0},"advanced":{"right":0,"left":0,"trigger":"a: brandon","defensive":"off"},"type":"disabled","luasense":{"right":0,"left":0,"fake":60,"yaw":0,"defensive":"off","mode":{},"luasense":1},"disabled":{},"auto":{"right":0,"method":"simple","left":0,"defensive":"off","timer":50,"antibf":"no"}}},"fake lag":{"t":{"normal":{"right":-22,"jitter_slider":0,"yaw":0,"method":"luasense","left":19,"jitter":"skitter","custom_slider":60,"body":"jitter","defensive":"luasense","mode":["left right"],"body_slider":0},"advanced":{"right":0,"left":0,"trigger":"a: brandon","defensive":"off"},"type":"normal","luasense":{"right":0,"left":0,"fake":60,"yaw":0,"defensive":"off","mode":{},"luasense":1},"disabled":{},"auto":{"right":0,"method":"simple","left":0,"defensive":"off","timer":50,"antibf":"no"}},"ct":{"normal":{"right":-22,"jitter_slider":0,"yaw":0,"method":"luasense","left":19,"jitter":"skitter","custom_slider":60,"body":"jitter","defensive":"luasense","mode":["left right"],"body_slider":0},"advanced":{"right":0,"left":0,"trigger":"a: brandon","defensive":"off"},"type":"normal","luasense":{"right":0,"left":0,"fake":60,"yaw":0,"defensive":"off","mode":{},"luasense":1},"disabled":{},"auto":{"right":0,"method":"simple","left":0,"defensive":"off","timer":50,"antibf":"no"}}},"air":{"t":{"normal":{"right":-3,"jitter_slider":0,"yaw":0,"method":"default","left":18,"jitter":"off","custom_slider":60,"body":"jitter","defensive":"luasense","mode":["left right"],"body_slider":0},"advanced":{"right":0,"left":0,"trigger":"a: brandon","defensive":"off"},"type":"normal","luasense":{"right":0,"left":0,"fake":60,"yaw":0,"defensive":"off","mode":{},"luasense":1},"disabled":{},"auto":{"right":0,"method":"simple","left":0,"defensive":"off","timer":50,"antibf":"no"}},"ct":{"normal":{"right":-3,"jitter_slider":0,"yaw":0,"method":"default","left":18,"jitter":"off","custom_slider":60,"body":"jitter","defensive":"luasense","mode":["left right"],"body_slider":0},"advanced":{"right":0,"left":0,"trigger":"a: brandon","defensive":"off"},"type":"normal","luasense":{"right":0,"left":0,"fake":60,"yaw":0,"defensive":"off","mode":{},"luasense":1},"disabled":{},"auto":{"right":0,"method":"simple","left":0,"defensive":"off","timer":50,"antibf":"no"}}},"global":{"t":{"normal":{"right":-21,"jitter_slider":180,"yaw":0,"method":"luasense","left":39,"jitter":"off","custom_slider":60,"body":"jitter","defensive":"luasense","mode":["left right"],"body_slider":-1},"advanced":{"right":-30,"left":30,"trigger":"b: best","defensive":"luasense"},"type":"normal","luasense":{"right":0,"left":0,"fake":60,"yaw":0,"defensive":"off","mode":{},"luasense":1},"disabled":{},"auto":{"right":-17,"method":"luasense","left":38,"defensive":"luasense","timer":50,"antibf":"no"}},"ct":{"normal":{"right":-21,"jitter_slider":180,"yaw":0,"method":"luasense","left":39,"jitter":"off","custom_slider":60,"body":"jitter","defensive":"luasense","mode":["left right"],"body_slider":-1},"advanced":{"right":-30,"left":30,"trigger":"b: best","defensive":"luasense"},"type":"normal","luasense":{"right":0,"left":0,"fake":60,"yaw":0,"defensive":"off","mode":{},"luasense":1},"disabled":{},"auto":{"right":-17,"method":"luasense","left":38,"defensive":"luasense","timer":50,"antibf":"no"}}},"duck":{"t":{"normal":{"right":0,"jitter_slider":0,"yaw":0,"method":"default","left":0,"jitter":"off","custom_slider":60,"body":"off","defensive":"off","mode":{},"body_slider":0},"advanced":{"right":0,"left":0,"trigger":"a: brandon","defensive":"off"},"type":"disabled","luasense":{"right":0,"left":0,"fake":60,"yaw":0,"defensive":"off","mode":{},"luasense":1},"disabled":{},"auto":{"right":0,"method":"simple","left":0,"defensive":"off","timer":50,"antibf":"no"}},"ct":{"normal":{"right":0,"jitter_slider":0,"yaw":0,"method":"default","left":0,"jitter":"off","custom_slider":60,"body":"off","defensive":"off","mode":{},"body_slider":0},"advanced":{"right":0,"left":0,"trigger":"a: brandon","defensive":"off"},"type":"disabled","luasense":{"right":0,"left":0,"fake":60,"yaw":0,"defensive":"off","mode":{},"luasense":1},"disabled":{},"auto":{"right":0,"method":"simple","left":0,"defensive":"off","timer":50,"antibf":"no"}}},"hide shot":{"t":{"normal":{"right":0,"jitter_slider":0,"yaw":0,"method":"default","left":0,"jitter":"off","custom_slider":60,"body":"off","defensive":"off","mode":{},"body_slider":0},"advanced":{"right":0,"left":0,"trigger":"a: brandon","defensive":"off"},"type":"disabled","luasense":{"right":0,"left":0,"fake":60,"yaw":0,"defensive":"off","mode":{},"luasense":1},"disabled":{},"auto":{"right":0,"method":"simple","left":0,"defensive":"off","timer":50,"antibf":"no"}},"ct":{"normal":{"right":0,"jitter_slider":0,"yaw":0,"method":"default","left":0,"jitter":"off","custom_slider":60,"body":"off","defensive":"off","mode":{},"body_slider":0},"advanced":{"right":0,"left":0,"trigger":"a: brandon","defensive":"off"},"type":"disabled","luasense":{"right":0,"left":0,"fake":60,"yaw":0,"defensive":"off","mode":{},"luasense":1},"disabled":{},"auto":{"right":0,"method":"simple","left":0,"defensive":"off","timer":50,"antibf":"no"}}},"moving":{"t":{"normal":{"right":0,"jitter_slider":0,"yaw":0,"method":"default","left":0,"jitter":"off","custom_slider":60,"body":"off","defensive":"off","mode":{},"body_slider":0},"advanced":{"right":0,"left":0,"trigger":"a: brandon","defensive":"off"},"type":"disabled","luasense":{"right":0,"left":0,"fake":60,"yaw":0,"defensive":"off","mode":{},"luasense":1},"disabled":{},"auto":{"right":0,"method":"simple","left":0,"defensive":"off","timer":50,"antibf":"no"}},"ct":{"normal":{"right":0,"jitter_slider":0,"yaw":0,"method":"default","left":0,"jitter":"off","custom_slider":60,"body":"off","defensive":"off","mode":{},"body_slider":0},"advanced":{"right":0,"left":0,"trigger":"a: brandon","defensive":"off"},"type":"disabled","luasense":{"right":0,"left":0,"fake":60,"yaw":0,"defensive":"off","mode":{},"luasense":1},"disabled":{},"auto":{"right":0,"method":"simple","left":0,"defensive":"off","timer":50,"antibf":"no"}}},"standing":{"t":{"normal":{"right":0,"jitter_slider":0,"yaw":0,"method":"default","left":0,"jitter":"off","custom_slider":60,"body":"off","defensive":"off","mode":{},"body_slider":0},"advanced":{"right":0,"left":0,"trigger":"a: brandon","defensive":"off"},"type":"disabled","luasense":{"right":0,"left":0,"fake":60,"yaw":0,"defensive":"off","mode":{},"luasense":1},"disabled":{},"auto":{"right":0,"method":"simple","left":0,"defensive":"off","timer":50,"antibf":"no"}},"ct":{"normal":{"right":0,"jitter_slider":0,"yaw":0,"method":"default","left":0,"jitter":"off","custom_slider":60,"body":"off","defensive":"off","mode":{},"body_slider":0},"advanced":{"right":0,"left":0,"trigger":"a: brandon","defensive":"off"},"type":"disabled","luasense":{"right":0,"left":0,"fake":60,"yaw":0,"defensive":"off","mode":{},"luasense":1},"disabled":{},"auto":{"right":0,"method":"simple","left":0,"defensive":"off","timer":50,"antibf":"no"}}}}}]])
                    elseif selected_config == "perfect delay jitter" then
                        tbl = json.parse([[{"LUASENSE":{"duck moving":{"t":{"normal":{"right":0,"jitter_slider":0,"yaw":0,"method":"default","left":0,"jitter":"off","custom_slider":60,"body":"off","defensive":"off","mode":{},"body_slider":0},"advanced":{"right":0,"left":0,"trigger":"a: brandon","defensive":"off"},"type":"luasense","luasense":{"right":-37,"left":37,"fake":60,"yaw":0,"defensive":"luasense","mode":["left right"],"luasense":3},"disabled":{},"auto":{"right":0,"method":"simple","left":0,"defensive":"off","timer":150,"antibf":"no"}},"ct":{"normal":{"right":0,"jitter_slider":0,"yaw":0,"method":"default","left":0,"jitter":"off","custom_slider":60,"body":"off","defensive":"off","mode":{},"body_slider":0},"advanced":{"right":0,"left":0,"trigger":"a: brandon","defensive":"off"},"type":"luasense","luasense":{"right":-37,"left":37,"fake":60,"yaw":0,"defensive":"luasense","mode":["left right"],"luasense":3},"disabled":{},"auto":{"right":0,"method":"simple","left":0,"defensive":"off","timer":150,"antibf":"no"}}},"extra":{"builder":{"builder":"duck moving","team":"t"},"submenu":"keybinds","features":{"backstab":"forward","legit":"off","roll":0,"fix":{},"defensive":"off","distance":300,"fixer":"default","states":{}},"keybinds":{"type_freestand":"jitter","type_manual":"static","keys":["manual","freestand"],"disablers":["manual"]}},"slow motion":{"t":{"normal":{"right":0,"jitter_slider":0,"yaw":0,"method":"default","left":0,"jitter":"off","custom_slider":60,"body":"off","defensive":"off","mode":{},"body_slider":0},"advanced":{"right":0,"left":0,"trigger":"a: brandon","defensive":"off"},"type":"disabled","luasense":{"right":0,"left":0,"fake":60,"yaw":0,"defensive":"off","mode":{},"luasense":1},"disabled":{},"auto":{"right":0,"method":"simple","left":0,"defensive":"off","timer":150,"antibf":"no"}},"ct":{"normal":{"right":0,"jitter_slider":0,"yaw":0,"method":"default","left":0,"jitter":"off","custom_slider":60,"body":"off","defensive":"off","mode":{},"body_slider":0},"advanced":{"right":0,"left":0,"trigger":"a: brandon","defensive":"off"},"type":"disabled","luasense":{"right":0,"left":0,"fake":60,"yaw":0,"defensive":"off","mode":{},"luasense":1},"disabled":{},"auto":{"right":0,"method":"simple","left":0,"defensive":"off","timer":150,"antibf":"no"}}},"air duck":{"t":{"normal":{"right":0,"jitter_slider":0,"yaw":0,"method":"default","left":0,"jitter":"off","custom_slider":60,"body":"off","defensive":"off","mode":{},"body_slider":0},"advanced":{"right":0,"left":0,"trigger":"a: brandon","defensive":"off"},"type":"luasense","luasense":{"right":-17,"left":49,"fake":60,"yaw":0,"defensive":"luasense","mode":["left right"],"luasense":4},"disabled":{},"auto":{"right":0,"method":"simple","left":0,"defensive":"off","timer":150,"antibf":"no"}},"ct":{"normal":{"right":0,"jitter_slider":0,"yaw":0,"method":"default","left":0,"jitter":"off","custom_slider":60,"body":"off","defensive":"off","mode":{},"body_slider":0},"advanced":{"right":0,"left":0,"trigger":"a: brandon","defensive":"off"},"type":"luasense","luasense":{"right":-17,"left":49,"fake":60,"yaw":0,"defensive":"luasense","mode":["left right"],"luasense":4},"disabled":{},"auto":{"right":0,"method":"simple","left":0,"defensive":"off","timer":150,"antibf":"no"}}},"fake lag":{"t":{"normal":{"right":0,"jitter_slider":0,"yaw":0,"method":"default","left":0,"jitter":"off","custom_slider":60,"body":"off","defensive":"off","mode":{},"body_slider":0},"advanced":{"right":0,"left":0,"trigger":"a: brandon","defensive":"off"},"type":"disabled","luasense":{"right":0,"left":0,"fake":60,"yaw":0,"defensive":"off","mode":{},"luasense":1},"disabled":{},"auto":{"right":0,"method":"simple","left":0,"defensive":"off","timer":150,"antibf":"no"}},"ct":{"normal":{"right":0,"jitter_slider":0,"yaw":0,"method":"default","left":0,"jitter":"off","custom_slider":60,"body":"off","defensive":"off","mode":{},"body_slider":0},"advanced":{"right":0,"left":0,"trigger":"a: brandon","defensive":"off"},"type":"disabled","luasense":{"right":0,"left":0,"fake":60,"yaw":0,"defensive":"off","mode":{},"luasense":1},"disabled":{},"auto":{"right":0,"method":"simple","left":0,"defensive":"off","timer":150,"antibf":"no"}}},"air":{"t":{"normal":{"right":0,"jitter_slider":0,"yaw":0,"method":"default","left":0,"jitter":"off","custom_slider":60,"body":"off","defensive":"off","mode":{},"body_slider":0},"advanced":{"right":0,"left":0,"trigger":"a: brandon","defensive":"off"},"type":"disabled","luasense":{"right":0,"left":0,"fake":60,"yaw":0,"defensive":"off","mode":{},"luasense":1},"disabled":{},"auto":{"right":0,"method":"simple","left":0,"defensive":"off","timer":150,"antibf":"no"}},"ct":{"normal":{"right":0,"jitter_slider":0,"yaw":0,"method":"default","left":0,"jitter":"off","custom_slider":60,"body":"off","defensive":"off","mode":{},"body_slider":0},"advanced":{"right":0,"left":0,"trigger":"a: brandon","defensive":"off"},"type":"disabled","luasense":{"right":0,"left":0,"fake":60,"yaw":0,"defensive":"off","mode":{},"luasense":1},"disabled":{},"auto":{"right":0,"method":"simple","left":0,"defensive":"off","timer":150,"antibf":"no"}}},"global":{"t":{"normal":{"right":0,"jitter_slider":0,"yaw":0,"method":"default","left":0,"jitter":"off","custom_slider":60,"body":"off","defensive":"off","mode":{},"body_slider":0},"advanced":{"right":0,"left":0,"trigger":"a: brandon","defensive":"off"},"type":"luasense","luasense":{"right":-29,"left":25,"fake":60,"yaw":0,"defensive":"luasense","mode":["left right"],"luasense":5},"disabled":{},"auto":{"right":0,"method":"simple","left":0,"defensive":"off","timer":150,"antibf":"no"}},"ct":{"normal":{"right":0,"jitter_slider":0,"yaw":0,"method":"default","left":0,"jitter":"off","custom_slider":60,"body":"off","defensive":"off","mode":{},"body_slider":0},"advanced":{"right":0,"left":0,"trigger":"a: brandon","defensive":"off"},"type":"luasense","luasense":{"right":-29,"left":25,"fake":60,"yaw":0,"defensive":"luasense","mode":["left right"],"luasense":5},"disabled":{},"auto":{"right":0,"method":"simple","left":0,"defensive":"off","timer":150,"antibf":"no"}}},"duck":{"t":{"normal":{"right":0,"jitter_slider":0,"yaw":0,"method":"default","left":0,"jitter":"off","custom_slider":60,"body":"off","defensive":"off","mode":{},"body_slider":0},"advanced":{"right":0,"left":0,"trigger":"a: brandon","defensive":"off"},"type":"luasense","luasense":{"right":-37,"left":37,"fake":60,"yaw":0,"defensive":"luasense","mode":["left right"],"luasense":3},"disabled":{},"auto":{"right":-37,"method":"luasense","left":37,"defensive":"luasense","timer":150,"antibf":"yes"}},"ct":{"normal":{"right":0,"jitter_slider":0,"yaw":0,"method":"default","left":0,"jitter":"off","custom_slider":60,"body":"off","defensive":"off","mode":{},"body_slider":0},"advanced":{"right":0,"left":0,"trigger":"a: brandon","defensive":"off"},"type":"luasense","luasense":{"right":-37,"left":37,"fake":60,"yaw":0,"defensive":"luasense","mode":["left right"],"luasense":3},"disabled":{},"auto":{"right":-37,"method":"luasense","left":37,"defensive":"luasense","timer":150,"antibf":"yes"}}},"hide shot":{"t":{"normal":{"right":0,"jitter_slider":0,"yaw":0,"method":"default","left":0,"jitter":"off","custom_slider":60,"body":"off","defensive":"off","mode":{},"body_slider":0},"advanced":{"right":0,"left":0,"trigger":"a: brandon","defensive":"off"},"type":"disabled","luasense":{"right":0,"left":0,"fake":60,"yaw":0,"defensive":"off","mode":{},"luasense":1},"disabled":{},"auto":{"right":0,"method":"simple","left":0,"defensive":"off","timer":150,"antibf":"no"}},"ct":{"normal":{"right":0,"jitter_slider":0,"yaw":0,"method":"default","left":0,"jitter":"off","custom_slider":60,"body":"off","defensive":"off","mode":{},"body_slider":0},"advanced":{"right":0,"left":0,"trigger":"a: brandon","defensive":"off"},"type":"disabled","luasense":{"right":0,"left":0,"fake":60,"yaw":0,"defensive":"off","mode":{},"luasense":1},"disabled":{},"auto":{"right":0,"method":"simple","left":0,"defensive":"off","timer":150,"antibf":"no"}}},"moving":{"t":{"normal":{"right":0,"jitter_slider":0,"yaw":0,"method":"default","left":0,"jitter":"off","custom_slider":60,"body":"off","defensive":"off","mode":{},"body_slider":0},"advanced":{"right":0,"left":0,"trigger":"a: brandon","defensive":"off"},"type":"luasense","luasense":{"right":-28,"left":38,"fake":60,"yaw":0,"defensive":"luasense","mode":["left right"],"luasense":3},"disabled":{},"auto":{"right":0,"method":"simple","left":0,"defensive":"off","timer":150,"antibf":"no"}},"ct":{"normal":{"right":0,"jitter_slider":0,"yaw":0,"method":"default","left":0,"jitter":"off","custom_slider":60,"body":"off","defensive":"off","mode":{},"body_slider":0},"advanced":{"right":0,"left":0,"trigger":"a: brandon","defensive":"off"},"type":"luasense","luasense":{"right":-28,"left":38,"fake":60,"yaw":0,"defensive":"luasense","mode":["left right"],"luasense":3},"disabled":{},"auto":{"right":0,"method":"simple","left":0,"defensive":"off","timer":150,"antibf":"no"}}},"standing":{"t":{"normal":{"right":0,"jitter_slider":0,"yaw":0,"method":"default","left":0,"jitter":"off","custom_slider":60,"body":"off","defensive":"off","mode":{},"body_slider":0},"advanced":{"right":0,"left":0,"trigger":"a: brandon","defensive":"off"},"type":"disabled","luasense":{"right":0,"left":0,"fake":60,"yaw":0,"defensive":"off","mode":{},"luasense":1},"disabled":{},"auto":{"right":-19,"method":"luasense","left":47,"defensive":"luasense","timer":150,"antibf":"yes"}},"ct":{"normal":{"right":0,"jitter_slider":0,"yaw":0,"method":"default","left":0,"jitter":"off","custom_slider":60,"body":"off","defensive":"off","mode":{},"body_slider":0},"advanced":{"right":0,"left":0,"trigger":"a: brandon","defensive":"off"},"type":"disabled","luasense":{"right":0,"left":0,"fake":60,"yaw":0,"defensive":"off","mode":{},"luasense":1},"disabled":{},"auto":{"right":-19,"method":"luasense","left":47,"defensive":"luasense","timer":150,"antibf":"yes"}}}}}]])
                    end
                    for i, v in next, tbl["LUASENSE"]["extra"] do
                        if i == "submenu" then
                            ui.set(menu["anti aimbot"][i], v)
                        else
                            for index, value in next, v do
                                ui.set(menu["anti aimbot"][i][index], value)
                            end
                        end
                    end
                    tbl["LUASENSE"]["extra"] = nil
                    for i, v in next, tbl["LUASENSE"] do
                        for index, value in next, v do
                            for ii, vv in next, value do
                                if ii == "type" then
                                    ui.set(aa[i][index][ii], vv)
                                else
                                    for iii, vvv in next, vv do
                                        ui.set(aa[i][index][ii][iii], vvv)
                                    end
                                end
                            end
                        end
                    end
                end)
                push_notify(check and "Config " .. selected_config .. " loaded!  " or "Error while loading config " .. selected_config .. "!  ")
            end),
            notify = ui.new_button("aa", "anti-aimbot angles", "\a96C845FFexample notification", function()
                local r, g, b = ui.get(menu["visuals & misc"]["visuals"]["notcolor"])
                local a = 255
                local white = "\aFFFFFFFF"
                local colored_notification = ("\a%02x%02x%02x%02x%s"):format(r, g, b, a, "notification")
                push_notify(white .. "Example " .. colored_notification .. white .. "!  ")
            end),
            export = ui.new_button("aa", "anti-aimbot angles", "\a89f596FF export", function()
                local tbl = {}
                for i, v in next, aa do
                    tbl[i] = {}
                    for index, value in next, v do
                        tbl[i][index] = {}
                        for ii, vv in next, value do
                            if ii == "type" then
                                tbl[i][index][ii] = ui.get(vv)
                            else
                                if ii ~= "button" then
                                    tbl[i][index][ii] = {}
                                    for iii, vvv in next, vv do
                                        tbl[i][index][ii][iii] = ui.get(vvv)
                                    end
                                end
                            end
                        end
                    end
                end
                tbl["extra"] = {}
                for i, v in next, menu["anti aimbot"] do
                    if i == "submenu" then
                        tbl["extra"][i] = ui.get(v)
                    else
                        tbl["extra"][i] = {}
                        for index, value in next, v do
                            local fixer = true
                            if i == "keybinds" then
                                if index == "left" or index == "right" or index == "forward" or index == "backward" or index == "edge" or index == "freestand" then
                                    fixer = false
                                end
                            end
                            if fixer then
                                tbl["extra"][i][index] = ui.get(value)
                            end
                        end
                    end
                end
                push_notify("Exported config!  ")
                clipboard.export(json.stringify({["LUASENSE"] = tbl}))
            end),
            import = ui.new_button("aa", "anti-aimbot angles", "\a32a852FF import", function()
                local check, message = pcall(function()
                    local tbl = json.parse(clipboard.import())
                    for i, v in next, tbl["LUASENSE"]["extra"] do
                        if i == "submenu" then
                            ui.set(menu["anti aimbot"][i], v)
                        else
                            for index, value in next, v do
                                ui.set(menu["anti aimbot"][i][index], value)
                            end
                        end
                    end
                    tbl["LUASENSE"]["extra"] = nil
                    for i, v in next, tbl["LUASENSE"] do
                        for index, value in next, v do
                            for ii, vv in next, value do
                                if ii == "type" then
                                    ui.set(aa[i][index][ii], vv)
                                else
                                    for iii, vvv in next, vv do
                                        ui.set(aa[i][index][ii][iii], vvv)
                                    end
                                end
                            end
                        end
                    end
                end)
                push_notify(check and "Imported config!  " or "Error while importing!  ")
            end),
        }
    }
    for i, v in next, tbl.states do
        aa[v] = {}
        for index, value in next, {"ct", "t"} do
            aa[v][value] = {
                ["type"] = ui.new_combobox("aa", "anti-aimbot angles", prefix(v .. " " .. value, "type"), (v == "global" and {"normal", "luasense", "advanced", "auto"} or {"disabled", "normal", "luasense", "advanced", "auto"})),
                ["normal"] = {
                    mode = ui.new_multiselect("aa", "anti-aimbot angles", prefix(v .. " " .. value, "mode"), {"yaw", "left right"}),
                    yaw = ui.new_slider("aa", "anti-aimbot angles", prefix(v .. " " .. value, "yaw"), -180, 180, 0),
                    left = ui.new_slider("aa", "anti-aimbot angles", prefix(v .. " " .. value, "left"), -180, 180, 0),
                    right = ui.new_slider("aa", "anti-aimbot angles", prefix(v .. " " .. value, "right"), -180, 180, 0),
                    method = ui.new_combobox("aa", "anti-aimbot angles", prefix(v .. " " .. value, "method"), {"default", "luasense"}),
                    jitter = ui.new_combobox("aa", "anti-aimbot angles", prefix(v .. " " .. value, "jitter"), {"off", "offset", "center", "random", "skitter"}),
                    jitter_slider = ui.new_slider("aa", "anti-aimbot angles", "\njitter slider " .. v .. " " .. value, -180, 180, 0),
                    body = ui.new_combobox("aa", "anti-aimbot angles", prefix(v .. " " .. value, "body"), {"off", "luasense", "opposite", "static", "jitter"}),
                    body_slider = ui.new_slider("aa", "anti-aimbot angles", "\nbody slider " .. v .. " " .. value, -180, 180, 0),
                    custom_slider = ui.new_slider("aa", "anti-aimbot angles", "\ncustom slider " .. v .. " " .. value, 0, 60, 60),
                    defensive = ui.new_combobox("aa", "anti-aimbot angles", prefix(v .. " " .. value, "defensive"), {"off", "always on", "luasense"})
                },
                ["luasense"] = {
                    luasense = ui.new_slider("aa", "anti-aimbot angles", prefix(v .. " " .. value, "luasense"), 1, 10, 1),
                    mode = ui.new_multiselect("aa", "anti-aimbot angles", prefix(v .. " " .. value, "mode\n"), {"yaw", "left right"}),
                    yaw = ui.new_slider("aa", "anti-aimbot angles", prefix(v .. " " .. value, "yaw\n"), -180, 180, 0),
                    left = ui.new_slider("aa", "anti-aimbot angles", prefix(v .. " " .. value, "left\n"), -180, 180, 0),
                    right = ui.new_slider("aa", "anti-aimbot angles", prefix(v .. " " .. value, "right\n"), -180, 180, 0),
                    fake = ui.new_slider("aa", "anti-aimbot angles", prefix(v .. " " .. value, "fake"), 0, 60, 60),
                    defensive = ui.new_combobox("aa", "anti-aimbot angles", prefix(v .. " " .. value, "defensive\n"), {"off", "always on", "luasense"})
                },
                ["advanced"] = {
                    trigger = ui.new_combobox("aa", "anti-aimbot angles", prefix(v .. " " .. value, "trigger"), {"a: brandon", "b: best", "c: experimental", "automatic"}),
                    left = ui.new_slider("aa", "anti-aimbot angles", prefix(v .. " " .. value, "left\n\n"), -180, 180, 0),
                    right = ui.new_slider("aa", "anti-aimbot angles", prefix(v .. " " .. value, "right\n\n"), -180, 180, 0),
                    defensive = ui.new_combobox("aa", "anti-aimbot angles", prefix(v .. " " .. value, "defensive\n\n\n"), {"off", "always on", "luasense"})
                },
                ["auto"] = {
                    method = ui.new_combobox("aa", "anti-aimbot angles", prefix(v .. " " .. value, "method\n"), {"simple", "luasense"}),
                    timer = ui.new_slider("aa", "anti-aimbot angles", "\ntimer", 50, 250, 150),
                    left = ui.new_slider("aa", "anti-aimbot angles", prefix(v .. " " .. value, "left\n\n\n"), -180, 180, 0),
                    right = ui.new_slider("aa", "anti-aimbot angles", prefix(v .. " " .. value, "right\n\n\n"), -180, 180, 0),
                    antibf = ui.new_combobox("aa", "anti-aimbot angles", prefix(v .. " " .. value, "bruteforce"), {"no", "yes"}),
                    defensive = ui.new_combobox("aa", "anti-aimbot angles", prefix(v .. " " .. value, "defensive\n\n"), {"off", "always on", "luasense"})
                },
                ["disabled"] = {},
                ["button"] = ui.new_button("aa", "anti-aimbot angles", "\a32a852FFsend to \a89f596FF" .. (value == "t" and "ct" or "t"), function()
                    local state = ui.get(menu["anti aimbot"]["builder"]["builder"])
                    local team = ui.get(menu["anti aimbot"]["builder"]["team"])
                    local target = (team == "t" and "ct" or "t")
                    for i, v in next, aa[state][team] do
                        if i ~= "button" then
                            if i == "type" then
                                ui.set(aa[state][target][i], ui.get(v))
                            else
                                for index, value in next, v do
                                    ui.set(aa[state][target][i][index], ui.get(value))
                                end
                            end
                        end
                    end
                end)
            }
        end
    end

    local timer = globals.tickcount()
    local scriptleakstop = 14
    
    local ctx = (function()
        local ctx = {}
    
        ctx.recharge = {
            run = function()
                if not tbl.contains(ui.get(menu["visuals & misc"]["misc"]["features"]), "dt_os_recharge_fix") then
                    return
                end
    
                local lp = entity.get_local_player()
        
                if not entity.is_alive(lp) then return end
        
                local lp_weapon = entity.get_player_weapon(lp)
                if not lp_weapon then return end
        
                scriptleakstop = weapons(lp_weapon).is_revolver and 17 or 14
        
                if ui.get(menu_refs["doubletap"][2]) or ui.get(menu_refs["hideshots"][2]) then
                    if globals.tickcount() >= timer + scriptleakstop then
                        ui.set(menu_refs["aimbot"], true)
                    else
                        ui.set(menu_refs["aimbot"], false)
                    end
                else
                    timer = globals.tickcount()
                    ui.set(menu_refs["aimbot"], true)
                end
            end
        }
    
        return ctx
    end)()
    
    client.set_event_callback('setup_command', function(cmd)
        ctx.recharge.run()
    end)
    
    tbl.refs = {
        slow = tbl.ref("aa", "other", "slow motion"),
        hide = tbl.ref("aa", "other", "on shot anti-aim"),
        dt = tbl.ref("rage", "aimbot", "double tap")
    }
    tbl.antiaim = {
        luasensefake = false,
        autocheck = false,
        current = false,
        active = false,
        count = false,
        ready = false,
        timer = 0,
        fs = 0,
        last = 0,
        log = {},
        manual = {
            aa = 0,
            tick = 0
        }
    }
    local distance = function(x1,y1,z1,x2,y2,z2)
        return math.sqrt((x1 - x2) * (x1 - x2) + (y1 - y2) * (y1 - y2))
    end
    local extrapolate = function(player, ticks, x,y,z)
        local xv, yv, zv =  entity.get_prop(player, "m_vecVelocity")
        local new_x = x + globals.tickinterval() * xv * ticks
        local new_y = y + globals.tickinterval() * yv * ticks
        local new_z = z + globals.tickinterval() * zv * ticks
        return new_x, new_y, new_z
    end
    local function calcangle(localplayerxpos, localplayerypos, enemyxpos, enemyypos)
       local relativeyaw = math.atan( (localplayerypos - enemyypos) / (localplayerxpos - enemyxpos) )
       return relativeyaw * 180 / math.pi
    end
    local function angle_vector(angle_x, angle_y)
        local sp, sy, cp, cy = nil
        sy = math.sin(math.rad(angle_y));
        cy = math.cos(math.rad(angle_y));
        sp = math.sin(math.rad(angle_x));
        cp = math.cos(math.rad(angle_x));
        return cp * cy, cp * sy, -sp;
    end
    local enemy_visible = function(x)
        if not (entity.is_alive(x) and not entity.is_dormant(x)) then 
            return false 
        end
        for i=0, 18 do 
            if client.visible(entity.hitbox_position(x, i)) then
                return true 
            end 
        end 
        return false
    end
    local function get_camera_pos(enemy)
        local e_x, e_y, e_z = entity.get_prop(enemy, "m_vecOrigin")
        if e_x == nil then return end
        local _, _, ofs = entity.get_prop(enemy, "m_vecViewOffset")
        e_z = e_z + (ofs - (entity.get_prop(enemy, "m_flDuckAmount") * 16))
        return e_x, e_y, e_z
    end
    local function fired_at(target, shooter, shot)
        local shooter_cam = { get_camera_pos(shooter) }
        if shooter_cam[1] == nil then return end
        local player_head = { entity.hitbox_position(target, 0) }
        local shooter_cam_to_head = { player_head[1] - shooter_cam[1],player_head[2] - shooter_cam[2],player_head[3] - shooter_cam[3] }
        local shooter_cam_to_shot = { shot[1] - shooter_cam[1], shot[2] - shooter_cam[2],shot[3] - shooter_cam[3]}
        local magic = ((shooter_cam_to_head[1]*shooter_cam_to_shot[1]) + (shooter_cam_to_head[2]*shooter_cam_to_shot[2]) + (shooter_cam_to_head[3]*shooter_cam_to_shot[3])) / (math.pow(shooter_cam_to_shot[1], 2) + math.pow(shooter_cam_to_shot[2], 2) + math.pow(shooter_cam_to_shot[3], 2))
        local closest = { shooter_cam[1] + shooter_cam_to_shot[1]*magic, shooter_cam[2] + shooter_cam_to_shot[2]*magic, shooter_cam[3] + shooter_cam_to_shot[3]*magic}
        local length = math.abs(math.sqrt(math.pow((player_head[1]-closest[1]), 2) + math.pow((player_head[2]-closest[2]), 2) + math.pow((player_head[3]-closest[3]), 2)))
        local frac_shot = client.trace_line(shooter, shot[1], shot[2], shot[3], player_head[1], player_head[2], player_head[3])
        local frac_final = client.trace_line(target, closest[1], closest[2], closest[3], player_head[1], player_head[2], player_head[3])
        return (length < 69) and (frac_shot > 0.99 or frac_final > 0.99)
    end
    local tickshot = 0
    client.set_event_callback("bullet_impact", function(event)
        if entity.get_local_player() == nil then return end
        local enemy = client.userid_to_entindex(event.userid)
        local lp = entity.get_local_player()
        if enemy == entity.get_local_player() or not entity.is_enemy(enemy) or not entity.is_alive(lp) then return nil end
        if fired_at(lp, enemy, {event.x, event.y, event.z}) then
            if tickshot ~= globals.tickcount() then
                if tbl.contains(ui.get(menu["visuals & misc"]["visuals"]["notify"]), "shot") then
                    math.randomseed(globals.tickcount())
                    local r, g, b, a = ui.get(menu["visuals & misc"]["visuals"]["notcolor"])
                    local player_name = entity.get_player_name(enemy)
                    local method_number = math.random(1, 9)
                    local colored_playername = ("\a%02x%02x%02x%02x%s"):format(r, g, b, a, player_name)
                    local colored_you = ("\a%02x%02x%02x%02x%s"):format(r, g, b, a, "you")
                    local colored_antiaim = ("\a%02x%02x%02x%02x%s"):format(r, g, b, a, "anti-aim")
                    local colored_antibrute = ("\a%02x%02x%02x%02x%s"):format(r, g, b, a, "Anti-Brute")
                    local colored_timedout = ("\a%02x%02x%02x%02x%s"):format(r, g, b, a, "timed out")
                    local colored_reset = ("\a%02x%02x%02x%02x%s"):format(r, g, b, a, "reset")
                    local white = "\aFFFFFFFF"
                    push_notify(white .. colored_playername .. white .. " shot at " .. colored_you .. white .. "!  ", "shot")
                    push_notify(white .. "Changed " .. colored_antiaim .. white .. " due to " .. colored_playername .. white .. "'s bullet! [method: " .. method_number .. "]  ", "bullet")
                    client.delay_call(math.random(2, 5), function()
                        push_notify(colored_antibrute .. white .. " was " .. colored_timedout .. white .. " and " .. colored_reset .. white .. "!  ", "reset")
                    end)
                end
                tickshot = globals.tickcount()
                tbl.antiaim.count = true
                tbl.antiaim.timer = 0
                if tbl.antiaim.active and tbl.antiaim.log[enemy] == nil then
                    tbl.antiaim.log[enemy] = not tbl.antiaim.current
                else
                    tbl.antiaim.log[enemy] = not tbl.antiaim.log[enemy]
                end
            end
        end
    end)
    local hitboxes = { [0] = 'body', 'head', 'chest', 'stomach', 'arm', 'arm', 'leg', 'leg', 'neck', 'body', 'body' }
    client.set_event_callback('aim_miss', function(shot)
        if not tbl.contains(ui.get(menu["visuals & misc"]["visuals"]["notify"]), "miss") then return nil end
        local target = entity.get_player_name(shot.target):lower()
        local hitbox = hitboxes[shot.hitgroup] or "?"
        local r, g, b, a = ui.get(menu["visuals & misc"]["visuals"]["notcolor3"])
        local colored_target = ("\a%02x%02x%02x%02x%s"):format(r, g, b, a, target)
        local colored_hitbox = ("\a%02x%02x%02x%02x%s"):format(r, g, b, a, hitbox)
        local colored_reason = ("\a%02x%02x%02x%02x%s"):format(r, g, b, a, shot.reason)
        local white = "\aFFFFFFFF"
        push_notify(white .. "Missed " .. colored_target .. white .. "'s " .. colored_hitbox .. white .. " due to " .. colored_reason .. white .. "!  ", "miss")
    end)
    client.set_event_callback('aim_hit', function(shot)
        if not tbl.contains(ui.get(menu["visuals & misc"]["visuals"]["notify"]), "hit") then return nil end
        local target = entity.get_player_name(shot.target):lower()
        local hitbox = hitboxes[shot.hitgroup] or "?"
        local r, g, b, a = ui.get(menu["visuals & misc"]["visuals"]["notcolor2"])
        local colored_target = ("\a%02x%02x%02x%02x%s"):format(r, g, b, a, target)
        local colored_hitbox = ("\a%02x%02x%02x%02x%s"):format(r, g, b, a, hitbox)
        local colored_damage = ("\a%02x%02x%02x%02x%s"):format(r, g, b, a, shot.damage)
        local white = "\aFFFFFFFF"
        push_notify(white .. "Hit " .. colored_target .. white .. "'s " .. colored_hitbox .. white .. " for " .. colored_damage .. white .. "!  ", "hit")
    end)
    local z = {}
    z.defensive = {
        cmd = 0,
        check = 0,
        defensive = 0,
        run = function(arg)
            z.defensive.cmd = arg.command_number
            ladder = (entity.get_prop(z, "m_MoveType") == 9)
        end,
        predict = function(arg)
            if arg.command_number == z.defensive.cmd then
                local tickbase = entity.get_prop(entity.get_local_player(), "m_nTickBase")
                z.defensive.defensive = math.abs(tickbase - z.defensive.check)
                z.defensive.check = math.max(tickbase, z.defensive.check or 0)
                z.defensive.cmd = 0
            end
        end
    }
    client.set_event_callback("level_init", function()
        z.defensive.check, z.defensive.defensive = 0, 0
    end)
    local scope_fix = false
    local scope_int = 0
    local shift_int = 0
    local list_shift = (function()
        local index, max = { }, 16
        for i=1, max do
            index[#index+1] = 0
            if i == max then
                return index
            end
        end
    end)()
    z.dtshift = function()
        local local_player = entity.get_local_player()
        local sim_time = entity.get_prop(local_player, "m_flSimulationTime")
        if local_player == nil or sim_time == nil then
            return
        end
        local tick_count = globals.tickcount()
        local shifted = math.max(unpack(list_shift))
        shift_int = shifted < 0 and math.abs(shifted) or 0
        list_shift[#list_shift+1] = sim_time/globals.tickinterval() - tick_count
        table.remove(list_shift, 1)
    end
    client.set_event_callback("net_update_start", z.dtshift)
    client.set_event_callback("run_command", z.defensive.run)
    client.set_event_callback("predict_command", z.defensive.predict)
    local animkeys = {
        dt = 0,
        duck = 0,
        hide = 0,
        safe = 0,
        baim = 0,
        fs = 0
    }
    local gradient = function(r1, g1, b1, a1, r2, g2, b2, a2, text)
        local output = ''
        local len = #text-1
        local rinc = (r2 - r1) / len
        local ginc = (g2 - g1) / len
        local binc = (b2 - b1) / len
        local ainc = (a2 - a1) / len
        for i=1, len+1 do
            output = output .. ('\a%02x%02x%02x%02x%s'):format(r1, g1, b1, a1, text:sub(i, i))
            r1 = r1 + rinc
            g1 = g1 + ginc
            b1 = b1 + binc
            a1 = a1 + ainc
        end
        return output
    end
    z.items = {}
    z.items.keys = { 
        dt = {ui.reference("rage", "aimbot", "double tap")},
        hs = {ui.reference("aa", "other", "on shot anti-aim")},
        fd = {ui.reference("rage", "other", "duck peek assist")},
        sp = {ui.reference("rage", "aimbot", "force safe point")},
        fb = {ui.reference("rage", "aimbot", "force body aim")}
    }
    local limitfl = ui.reference("aa", "fake lag", "limit")
    local legs = ui.reference("aa", "other", "leg movement")
    local spammer = 0
    tbl.tick_aa = -2147483500
    tbl.list_aa = {}
    tbl.reset_aa = false
    tbl.defensive_aa = 1337
    tbl.callbacks = {
        recharge = function()
            ctx.recharge.run()
        end,
        hitmarker_aim_fire = function(c)
            if ui.get(menu["visuals & misc"]["visuals"]["hitmark_enable"]) == "yes" then
                hitmarker_queue[globals.tickcount()] = {c.x, c.y, c.z, globals.curtime() + 4}
            end
        end,
        hitmarker_paint = function()
            if ui.get(menu["visuals & misc"]["visuals"]["hitmark_enable"]) == "yes" then
                local r, g, b, a = ui.get(menu["visuals & misc"]["visuals"]["hitmark_color"])
                for tick, data in pairs(hitmarker_queue) do
                    if globals.curtime() <= data[4] then
                        local x1, y1 = renderer.world_to_screen(data[1], data[2], data[3])
                        if x1 and y1 then
                            renderer.line(x1 - 5, y1, x1 + 5, y1, r, g, b, a)
                            renderer.line(x1, y1 - 5, x1, y1 + 5, r, g, b, a)
                        end
                    else
                        hitmarker_queue[tick] = nil
                    end
                end
            end
        end,
        hitmarker_round_prestart = function()
            hitmarker_queue = {}
        end,
        ["freestand"] = function()
            local result = 0
            local player = client.current_threat()
            if player ~= nil and not enemy_visible(player) then
                local lx, ly, lz = entity.get_prop(entity.get_local_player(), "m_vecOrigin")
                local enemyx, enemyy, enemyz = entity.get_prop(player, "m_vecOrigin")
                local yaw = calcangle(lx, ly, enemyx, enemyy)
                local dir_x, dir_y = angle_vector(0, (yaw + 90))
                local end_x = lx + dir_x * 55
                local end_y = ly + dir_y * 55
                local end_z = lz + 80
                local index, damage = client.trace_bullet(player, enemyx, enemyy, enemyz + 70, end_x, end_y, end_z,true)
                if damage > 0 then result = 1 end
                dir_x, dir_y = angle_vector(0, (yaw + -90))
                end_x = lx + dir_x * 55
                end_y = ly + dir_y * 55
                end_z = lz + 80
                index, damage = client.trace_bullet(player, enemyx, enemyy, enemyz + 70, end_x, end_y, end_z,true)
                if damage > 0 then 
                    if result == 1 then 
                        result = 0 
                    else 
                        result = -1 
                    end 
                end
            end
            tbl.antiaim.fs = result
        end,
        ["command"] = function(arg)
            local myself = entity.get_local_player()
			local air = bit.band(entity.get_prop(myself, "m_fFlags"), 1) == 0
            local xv, yv, zv = entity.get_prop(myself, "m_vecVelocity")
			local duck = (entity.get_prop(myself, "m_flDuckAmount") > 0.1)
            local team = (entity.get_prop(myself, "m_iTeamNum") == 2 and "t" or "ct")
            local fakelag = not ((ui.get(tbl.refs.dt[1]) and ui.get(tbl.refs.dt[2])) or (ui.get(tbl.refs.hide[1]) and ui.get(tbl.refs.hide[2])))
            local real_state = tbl.getstate(arg.in_jump == 1 or air, duck, math.sqrt(xv*xv + yv*yv + zv*zv), (ui.get(tbl.refs.slow[1]) and ui.get(tbl.refs.slow[2])))
            local hideshot = ((ui.get(tbl.refs.hide[1]) and ui.get(tbl.refs.hide[2])) and not (ui.get(tbl.refs.dt[1]) and ui.get(tbl.refs.dt[2])))
            local state = real_state
            if fakelag and ui.get(aa["fake lag"][team]["type"]) ~= "disabled" then
                state = "fake lag"
            elseif hideshot and ui.get(aa["hide shot"][team]["type"]) ~= "disabled" then
                state = "hide shot"
            elseif ui.get(aa[state][team]["type"]) == "disabled" then
                state = "global"
            else end
            local enemy = client.current_threat()
            local menutbl = aa[state][team]
            ui.set(tbl.items.enabled[1], true)
			ui.set(tbl.items.base[1], "at targets")
			ui.set(tbl.items.pitch[1], "default")
			ui.set(tbl.items.yaw[1], "180")
            ui.set(tbl.items.fsbody[1], false)
			ui.set(tbl.items.edge[1], false)
			ui.set(tbl.items.fs[1], false)
			ui.set(tbl.items.fs[2], "always on")
            ui.set(tbl.items.roll[1], 0)
            arg.roll = ui.get(menu["anti aimbot"]["features"]["roll"])
            local myweapon = entity.get_player_weapon(myself)
            if ui.get(menu["anti aimbot"]["features"]["legit"]) ~= "off" and arg.in_use == 1 and entity.get_classname(myweapon) ~= "CC4" then
                if tbl.contains(ui.get(menu["anti aimbot"]["features"]["fix"]), "generic") then
                    if arg.chokedcommands ~= 1 then
                        arg.in_use = 0
                    end
                else
                    arg.in_use = 0
                end
                if tbl.contains(ui.get(menu["anti aimbot"]["features"]["fix"]), "bombsite") then
                    local player_x, player_y, player_z = entity.get_prop(myself, "m_vecOrigin")
                    local distance_bomb = 100
                    local bomb = entity.get_all("CPlantedC4")[1]
                    local bomb_x, bomb_y, bomb_z = entity.get_prop(bomb, "m_vecOrigin")
                    if bomb_x ~= nil then
                        distance_bomb = distance(bomb_x, bomb_y, bomb_z, player_x, player_y, player_z)
                    end
                    local distance_hostage = 100
                    local hostage = entity.get_all("CPlantedC4")[1]
                    local hostage_x, hostage_y, hostage_z = entity.get_prop(bomb, "m_vecOrigin")
                    if hostage_x ~= nil then
                        distance_hostage = distance(hostage_x, hostage_y, hostage_z, player_x, player_y, player_z)
                    end
                    if (distance_bomb < 69) or (distance_hostage < 69) then
                        arg.in_use = 1
                    end
                end
                ui.set(tbl.items.base[1], "local view")
			    ui.set(tbl.items.pitch[1], "off")
                ui.set(tbl.items.fsbody[1], true)
                ui.set(tbl.items.yaw[2], 180)
                ui.set(tbl.items.jitter[1], "off")
                ui.set(tbl.items.jitter[2], 0)
                if ui.get(menu["anti aimbot"]["features"]["legit"]) == "default" or tbl.antiaim.fs == 0 then
                    ui.set(tbl.items.body[1], ui.get(menu["anti aimbot"]["features"]["legit"]) == "default" and "opposite" or "jitter")
                    ui.set(tbl.items.body[2], 0)
                else
                    ui.set(tbl.items.body[1], "static")
                    ui.set(tbl.items.body[2], tbl.antiaim.fs == 1 and -180 or 180)
                    if arg.chokedcommands == 0 then
                        arg.allow_send_packet = false
                    end
                end
                arg.force_defensive = true
                return nil
            end
            if ui.get(menu["anti aimbot"]["features"]["backstab"]) ~= "off" and enemy ~= nil then
                local weapon = entity.get_player_weapon(enemy)
                if weapon ~= nil and entity.get_classname(weapon) == "CKnife" then
                    local ex,ey,ez = entity.get_origin(enemy)
					local lx,ly,lz = entity.get_origin(myself)
					if ex ~= nil and lx ~= nil then 
						for ticks = 1,9 do
							local tex,tey,tez = extrapolate(myself,ticks,lx,ly,lz)
							local distance = distance(ex,ey,ez,tex,tey,tez)
                            if math.abs(distance) < ui.get(menu["anti aimbot"]["features"]["distance"]) then
                                ui.set(tbl.items.yaw[2], ui.get(menu["anti aimbot"]["features"]["backstab"]) == "forward" and 180 or client.random_int(-180, 180))
                                ui.set(tbl.items.jitter[1], "off")
                                ui.set(tbl.items.jitter[2], 0)
                                ui.set(tbl.items.body[1], ui.get(menu["anti aimbot"]["features"]["backstab"]) == "random" and "jitter" or "opposite")
                                ui.set(tbl.items.body[2], 0)
                                arg.force_defensive = true
                                return nil
                            end
                        end
                    end
                end
            end
            if ui.get(menutbl["type"]) == "normal" then
                menutbl = menutbl[ui.get(menutbl["type"])]
                local yaw = tbl.antiaim.manual.aa
                if tbl.contains(ui.get(menutbl["mode"]), "yaw") then
                    yaw = tbl.antiaim.manual.aa + ui.get(menutbl["yaw"])
                end
                if tbl.contains(ui.get(menutbl["mode"]), "left right") then
                    local method = arg.chokedcommands == 0
                    if ui.get(menutbl["method"]) == "luasense" then
                        method = arg.chokedcommands ~= 0
                    end
                    if method and ui.get(menutbl["body"]) ~= "luasense" then
                        if math.max(-60, math.min(60, math.floor((entity.get_prop(myself,"m_flPoseParameter", 11) or 0)*120-60+0.5))) > 0 then
                            ui.set(tbl.items.yaw[2], tbl.clamp(yaw + ui.get(menutbl["right"])))
                        else
                            ui.set(tbl.items.yaw[2], tbl.clamp(yaw + ui.get(menutbl["left"])))
                        end
                    end
                else
                    ui.set(tbl.items.yaw[2], tbl.clamp(yaw))
                end
                ui.set(tbl.items.jitter[1], ui.get(menutbl["jitter"]))
                ui.set(tbl.items.jitter[2], ui.get(menutbl["jitter_slider"]))
                if ui.get(menutbl["body"]) ~= "luasense" then
                    ui.set(tbl.items.body[1], ui.get(menutbl["body"]))
                    ui.set(tbl.items.body[2], ui.get(menutbl["body_slider"]))
                else
                    ui.set(tbl.items.body[1], "static")
                    local fake = (ui.get(menutbl["custom_slider"])+1) * 2
                    local luasensefake = false
                    if arg.command_number % client.random_int(3,6) == 1 then
						tbl.antiaim.ready = true
                    end
					if tbl.antiaim.ready and arg.chokedcommands == 0 then
						tbl.antiaim.ready = false
						tbl.antiaim.luasensefake = not tbl.antiaim.luasensefake
                        ui.set(tbl.items.body[2], tbl.antiaim.luasensefake and -fake or fake)
                        luasensefake = true
					end
                    if tbl.contains(ui.get(menutbl["mode"]), "left right") then
                        if luasensefake then
                            if tbl.antiaim.luasensefake then
                                ui.set(tbl.items.yaw[2], tbl.clamp(yaw + ui.get(menutbl["right"])))
                            else
                                ui.set(tbl.items.yaw[2], tbl.clamp(yaw + ui.get(menutbl["left"])))
                            end
                        end
                    end
                end
                if ui.get(menutbl["defensive"]) == "luasense" then
                    arg.force_defensive = arg.command_number % 3 ~= 1 or arg.weaponselect ~= 0 or arg.quick_stop == 1
                elseif ui.get(menutbl["defensive"]) == "always on" then
                    arg.force_defensive = true
                else end
            elseif ui.get(menutbl["type"]) == "luasense" then
                menutbl = menutbl[ui.get(menutbl["type"])]
                ui.set(tbl.items.jitter[1], "off")
                ui.set(tbl.items.body[1], "static")
                if arg.command_number % (ui.get(menutbl["luasense"])+1+1) == 1 then
					tbl.antiaim.ready = true
                end
				if tbl.antiaim.ready and arg.chokedcommands == 0 then
					local fake = (ui.get(menutbl["fake"])+1) * 2
					tbl.antiaim.ready = false
                    tbl.antiaim.luasensefake = not tbl.antiaim.luasensefake
                    ui.set(tbl.items.body[2], tbl.antiaim.luasensefake and -fake or fake)
                    local yaw = tbl.antiaim.manual.aa
                    if tbl.contains(ui.get(menutbl["mode"]), "yaw") then
                        yaw = tbl.antiaim.manual.aa + ui.get(menutbl["yaw"])
                    end
                    if tbl.contains(ui.get(menutbl["mode"]), "left right") then
                        if tbl.antiaim.luasensefake then
                            ui.set(tbl.items.yaw[2], tbl.clamp(yaw + ui.get(menutbl["right"])))
                        else
                            ui.set(tbl.items.yaw[2], tbl.clamp(yaw + ui.get(menutbl["left"])))
                        end
                    else
                        ui.set(tbl.items.yaw[2], tbl.clamp(yaw))
                    end
				end
                if ui.get(menutbl["defensive"]) == "luasense" then
                    arg.force_defensive = arg.command_number % 3 ~= 1 or arg.weaponselect ~= 0 or arg.quick_stop == 1
                elseif ui.get(menutbl["defensive"]) == "always on" then
                    arg.force_defensive = true
                else end
			elseif ui.get(menutbl["type"]) == "advanced" then
                menutbl = menutbl[ui.get(menutbl["type"])]
                ui.set(tbl.items.jitter[1], "off")
                ui.set(tbl.items.body[1], "static")
                local trigger = client.random_int(3,6)
				if ui.get(menutbl["trigger"]) == "a: brandon" then
					trigger = 5
				end
				if ui.get(menutbl["trigger"]) == "b: best" then
					trigger = 6
				end
				if ui.get(menutbl["trigger"]) == "c: experimental" then
					if trigger == 1 or trigger == 1+1 then
						trigger = 9
					else
						trigger = trigger + 1
					end
				end
				if arg.command_number % trigger == 1 then
					tbl.auto = not tbl.auto
					if tbl.auto then
						ui.set(tbl.items.body[2], -123)
						ui.set(tbl.items.yaw[2], tbl.clamp(ui.get(menutbl["right"]) + tbl.antiaim.manual.aa))
					else
						ui.set(tbl.items.body[2], 123)
						ui.set(tbl.items.yaw[2], tbl.clamp(ui.get(menutbl["left"]) + tbl.antiaim.manual.aa))
					end
				end
                if ui.get(menutbl["defensive"]) == "luasense" then
                    arg.force_defensive = arg.command_number % 3 ~= 1 or arg.weaponselect ~= 0 or arg.quick_stop == 1
                elseif ui.get(menutbl["defensive"]) == "always on" then
                    arg.force_defensive = true
                else end
            elseif ui.get(menutbl["type"]) == "auto" then
                menutbl = menutbl[ui.get(menutbl["type"])]
                ui.set(tbl.items.jitter[1], "random")
                ui.set(tbl.items.body[1], "static")
                ui.set(tbl.items.yaw[2], tbl.antiaim.manual.aa)
                local check = arg.command_number % 10 > 5
                if tbl.antiaim.fs ~= 0 then
                    check = tbl.antiaim.fs ~= 1
                    tbl.antiaim.last = check
                    tbl.antiaim.current = check
                    tbl.antiaim.active = true
                end
                if ui.get(menutbl["method"]) == "simple" and tbl.antiaim.fs == 0 then
                    check = not tbl.antiaim.last
                    tbl.antiaim.current = check
                    tbl.antiaim.active = true
                end
                if ui.get(menutbl["method"]) == "luasense" then
                    if tbl.antiaim.count then
                        if tbl.antiaim.timer > ui.get(menutbl["timer"]) then
                            tbl.antiaim.timer = 0
                            tbl.antiaim.count = false
                            tbl.antiaim.log = {}
                        else
                            tbl.antiaim.timer = tbl.antiaim.timer + 1
                        end
                    end
					if tbl.antiaim.fs == 0 then
						if arg.command_number % 3 == 1 then
							tbl.antiaim.ready = true
						end
						if tbl.antiaim.ready and arg.chokedcommands == 0 then
							tbl.antiaim.ready = false
							tbl.antiaim.luasensefake = not tbl.antiaim.luasensefake
						end
						local yaw = tbl.antiaim.manual.aa
						check = tbl.antiaim.luasensefake
						if tbl.antiaim.luasensefake then
							ui.set(tbl.items.yaw[2], tbl.clamp(yaw + ui.get(menutbl["right"])))
						else
							ui.set(tbl.items.yaw[2], tbl.clamp(yaw + ui.get(menutbl["left"])))
						end
					end
                end
                if ui.get(menutbl["antibf"]) == "yes" then
                    if enemy ~= nil then
                        if tbl.antiaim.log[enemy] ~= nil then
                            check = tbl.antiaim.log[enemy]
                        end
                    end
                end
                ui.set(tbl.items.jitter[2], check and -3 or 3)
                ui.set(tbl.items.body[2], check and -123 or 123)
                if ui.get(menutbl["defensive"]) == "luasense" then
                    arg.force_defensive = arg.command_number % 3 ~= 1 or arg.weaponselect ~= 0 or arg.quick_stop == 1
                elseif ui.get(menutbl["defensive"]) == "always on" then
                    arg.force_defensive = true
                else end
            else end
            ui.set(tbl.items.edge[1], ui.get(menu["anti aimbot"]["keybinds"]["edge"]))
            local freestand = ui.get(menu["anti aimbot"]["keybinds"]["freestand"])
            local disablers = ui.get(menu["anti aimbot"]["keybinds"]["disablers"])
            if tbl.contains(disablers, "air") and (arg.in_jump == 1 or air) then
                freestand = false
            end
            if tbl.contains(disablers, "slow") and (ui.get(tbl.refs.slow[1]) and ui.get(tbl.refs.slow[2])) then
                freestand = false
            end
            if tbl.contains(disablers, "duck") and (duck) then
                freestand = false
            end
            if tbl.contains(disablers, "edge") and (ui.get(menu["anti aimbot"]["keybinds"]["edge"])) then
                freestand = false
            end
            if tbl.contains(disablers, "manual") and (tbl.antiaim.manual.aa ~= 0) then
                freestand = false
            end
            if tbl.contains(disablers, "fake lag") and (fakelag) then
                freestand = false
            end
            if tbl.antiaim.manual.aa ~= 0 then
                ui.set(tbl.items.base[1], "local view")
                if ui.get(menu["anti aimbot"]["keybinds"]["type_manual"]) ~= "default" then
                    ui.set(tbl.items.yaw[2], tbl.antiaim.manual.aa)
                    ui.set(tbl.items.jitter[1], "off")
                    ui.set(tbl.items.jitter[2], 0)
                    ui.set(tbl.items.body[1], ui.get(menu["anti aimbot"]["keybinds"]["type_manual"]) == "jitter" and "jitter" or "opposite")
                    ui.set(tbl.items.body[2], 0)
                end
            end
            if ui.get(menu["anti aimbot"]["keybinds"]["type_freestand"]) ~= "default" and freestand then
                ui.set(tbl.items.yaw[2], 0)
                ui.set(tbl.items.jitter[1], "off")
                ui.set(tbl.items.jitter[2], 0)
                ui.set(tbl.items.body[1], ui.get(menu["anti aimbot"]["keybinds"]["type_freestand"]) == "jitter" and "jitter" or "opposite")
                ui.set(tbl.items.body[2], 0)
                arg.force_defensive = true
            end
            ui.set(tbl.items.fs[1], freestand)
			local defensivecheck = (z.defensive.defensive > 3) and (z.defensive.defensive < 11)
            if fakelag or hideshot then
                defensivecheck = false
            end
			local defensivemenu = ui.get(menu["anti aimbot"]["features"]["defensive"])
			tbl.normal_aa = true
			tbl.tick_aa = tbl.tick_aa + 1
			tbl.list_aa[tbl.tick_aa] = {
				["aa"] = ui.get(tbl.items.yaw[2]),
			}
			if defensivemenu ~= "off" and defensivecheck and not freestand and tbl.antiaim.manual.aa == 0 and tbl.contains(ui.get(menu["anti aimbot"]["features"]["states"]), real_state) then
				tbl.normal_aa = false
				if defensivemenu == "pitch" then
					ui.set(tbl.items.pitch[1], "up")
                elseif defensivemenu == "spin" then
					ui.set(tbl.items.yaw[2], (((arg.command_number % 360) - 180) * 3) % 180)
				elseif defensivemenu == "random" then
					ui.set(tbl.items.yaw[2], client.random_int(-180,180))
				elseif defensivemenu == "random pitch" then
					ui.set(tbl.items.pitch[1], (arg.command_number % 4 > 2) and "up" or "down")
					ui.set(tbl.items.yaw[2], client.random_int(-180,180))
				elseif defensivemenu == "sideways up" then
					ui.set(tbl.items.pitch[1], "up")
					ui.set(tbl.items.yaw[2], (arg.command_number % 6 > 3) and 111 or -111)
				elseif defensivemenu == "sideways down" then
					ui.set(tbl.items.yaw[2], (arg.command_number % 6 > 3) and 111 or -111)
				end
				if defensivemenu ~= "pitch" then
					tbl.reset_aa = true
					tbl.defensive_aa = ui.get(tbl.items.yaw[2])
				end
			end
			tbl.list_aa[tbl.tick_aa]["check"] = tbl.normal_aa
			if tbl.normal_aa and tbl.reset_aa and ui.get(menu["anti aimbot"]["features"]["fixer"]) == "luasense" then
				tbl.reset_aa = false
				for i = 1, 69 do
					if tbl.list_aa[tbl.tick_aa-i] then
						if tbl.list_aa[tbl.tick_aa-i]["check"] then
							if tbl.defensive_aa ~= tbl.list_aa[tbl.tick_aa-i]["aa"] then
								ui.set(tbl.items.yaw[2], tbl.list_aa[tbl.tick_aa-i]["aa"])
								return nil
							end
						end
					end
				end
			end
        end,
        ["reset"] = function()
            if tbl.contains(ui.get(menu["visuals & misc"]["visuals"]["notify"]), "reset") then
                local r, g, b, a = ui.get(menu["visuals & misc"]["visuals"]["notcolor"])
                local colored_antiaim = ("\a%02x%02x%02x%02x%s"):format(r, g, b, a, "Anti-Aim")
                local colored_newround = ("\a%02x%02x%02x%02x%s"):format(r, g, b, a, "new round")
                local white = "\aFFFFFFFF"
                push_notify(white .. colored_antiaim .. white .. " reseted due to " .. colored_newround .. white .. "!  ")
            end
            tbl.antiaim.manual.aa = 0
            tbl.antiaim.manual.tick = 0
            if ui.get(menu["visuals & misc"]["misc"]["autobuy"]) ~= "off" then
                client.exec("buy " .. (ui.get(menu["visuals & misc"]["misc"]["autobuy"]) == "scout" and "ssg08" or "awp"))
            end
        end,
        ["menu"] = function()
            if ii == "custom_wtext" then
                fix = ui.get(value["wtext"]) == "custom"
            end
            if ii == "custom_prefix" then
                fix = ui.get(value["wtext"]) == "custom"
            end
            if ii == "custom_prefix2" then
                fix = ui.get(value["wtext"]) == "custom"
            end
            ui.set(menu["anti aimbot"]["keybinds"]["left"], "on hotkey")
            ui.set(menu["anti aimbot"]["keybinds"]["right"], "on hotkey")
            ui.set(menu["anti aimbot"]["keybinds"]["forward"], "on hotkey")
            ui.set(menu["anti aimbot"]["keybinds"]["backward"], "on hotkey")
        
            local tick = globals.tickcount()
            if ui.get(menu["anti aimbot"]["keybinds"]["left"]) and (tbl.antiaim.manual.tick < tick - 11) then
                tbl.antiaim.manual.aa = tbl.antiaim.manual.aa == -90 and 0 or -90
                tbl.antiaim.manual.tick = tick
            end
            if ui.get(menu["anti aimbot"]["keybinds"]["right"]) and (tbl.antiaim.manual.tick < tick - 11) then
                tbl.antiaim.manual.aa = tbl.antiaim.manual.aa == 90 and 0 or 90
                tbl.antiaim.manual.tick = tick
            end
            if ui.get(menu["anti aimbot"]["keybinds"]["forward"]) and (tbl.antiaim.manual.tick < tick - 11) then
                tbl.antiaim.manual.aa = tbl.antiaim.manual.aa == 180 and 0 or 180
                tbl.antiaim.manual.tick = tick
            end
            if ui.get(menu["anti aimbot"]["keybinds"]["backward"]) and (tbl.antiaim.manual.tick < tick - 11) then
                tbl.antiaim.manual.aa = tbl.antiaim.manual.aa == -1 and 0 or -1
                tbl.antiaim.manual.tick = tick
            end
            if tbl.contains(ui.get(menu["visuals & misc"]["misc"]["features"]), "fix hideshot") then
                ui.set(limitfl, (ui.get(tbl.refs.hide[1]) and ui.get(tbl.refs.hide[2])) and 1 or 14)
            end
            if tbl.contains(ui.get(menu["visuals & misc"]["misc"]["features"]), "legs spammer") then
                ui.set(legs, globals.tickcount() % ui.get(menu["visuals & misc"]["misc"]["spammer"]) == 0 and "never slide" or "always slide")
            end
            if not ui.is_menu_open() then return nil end
        
            for i, v in next, tbl.items do
                for index, value in next, v do
                    ui.set_visible(value, false)
                end
            end
        
            local current = ui.get(category)
            local sub = ui.get(menu["anti aimbot"]["submenu"])
            local subextra = ui.get(menu["visuals & misc"]["submenu"])
            local fix = true
        
            for i, v in next, aa do
                local section = ui.get(menu["anti aimbot"]["builder"]["builder"]) == i
                for index, value in next, v do 
                    local selected = ui.get(menu["anti aimbot"]["builder"]["team"]) == index
                    for ii, vv in next, value do
                        if ii ~= "type" and ii ~= "button" then
                            local mode = ui.get(value["type"])
                            for iii, vvv in next, vv do
                                fix = true
                                if ii == "normal" then
                                    if iii == "jitter_slider" then
                                        fix = ui.get(vv["jitter"]) ~= "off"
                                    end
                                    if iii == "body_slider" then
                                        fix = ui.get(vv["body"]) ~= "off" and ui.get(vv["body"]) ~= "opposite" and ui.get(vv["body"]) ~= "luasense"
                                    end
                                    if iii == "custom_slider" then
                                        fix = ui.get(vv["body"]) == "luasense"
                                    end
                                    if iii == "yaw" then
                                        fix = tbl.contains(ui.get(vv["mode"]), iii)
                                    end
                                    if iii == "left" or iii == "right" or iii == "method" then
                                        fix = tbl.contains(ui.get(vv["mode"]), "left right")
                                    end
                                end
                                if ii == "luasense" then
                                    if iii == "yaw" then
                                        fix = tbl.contains(ui.get(vv["mode"]), iii)
                                    end
                                    if iii == "left" or iii == "right" then
                                        fix = tbl.contains(ui.get(vv["mode"]), "left right")
                                    end
                                end
                                if ii == "auto" then
                                    if iii == "timer" or iii == "left" or iii == "right" then
                                        fix = ui.get(vv["method"]) == "luasense"
                                    end
                                end
                                ui.set_visible(vvv, section and selected and current == "anti aimbot" and sub == "builder" and mode == ii and fix)
                            end
                        else
                            ui.set_visible(vv, section and selected and current == "anti aimbot" and sub == "builder")
                        end
                    end
                end
            end
        
for i, v in next, menu do
    for index, value in next, v do
        if i == "anti aimbot" and index ~= "submenu" then
            for ii, vv in next, value do
                fix = true
                if index == "features" then
                    if ii == "distance" then
                        fix = ui.get(value["backstab"]) ~= "off"
                    end
                    if ii == "fix" then
                        fix = ui.get(value["legit"]) ~= "off"
                    end
                    if ii == "fixer" or ii == "states" then
                        fix = ui.get(value["defensive"]) ~= "off"
                    end
                end
                if index == "keybinds" then
                    if ii == "edge" then
                        fix = tbl.contains(ui.get(value["keys"]), ii)
                    end
                    if ii == "freestand" or ii == "type_freestand" or ii == "disablers" then
                        fix = tbl.contains(ui.get(value["keys"]), "freestand")
                    end
                    if ii == "left" or ii == "right" or ii == "forward" or ii == "backward" or ii == "type_manual" then
                        fix = tbl.contains(ui.get(value["keys"]), "manual")
                    end
                end
                ui.set_visible(vv, i == current and index == sub and fix)
            end
        elseif i == "visuals & misc" and index ~= "submenu" then
            for ii, vv in next, value do
                fix = true
                if index == "misc" then
                    if ii == "spammer" then
                        fix = tbl.contains(ui.get(value["features"]), "legs spammer")
                    end
                elseif index == "rage" then
                    if ii == "resolver_color" then
                        fix = ui.get(value["resolver"]) == "yes"
                    end
                elseif index == "visuals" then
                    if ii == "arrows_color" then
                        fix = ui.get(value["arrows"]) ~= "-"
                    elseif ii == "indicators_color" then
                        fix = ui.get(value["indicators"]) ~= "-"
                    elseif ii == "custom_indicator_text" then
                        fix = ui.get(value["indicators"]) == "custom"
                    elseif ii == "custom_wtext" or ii == "notify_tip15" or ii == "notify_tip16" or ii == "notify_tip22" or ii == "custom_prefix" or ii == "custom_prefix_color" or ii == "custom_prefix2" or ii == "custom_prefix2_color" or ii == "prefix_animation" or ii == "prefix2_animation" then
                        fix = ui.get(value["wtext"]) == "custom"
                    elseif ii == "watermark_animation" or ii == "wfont" or ii == "watermark" or ii == "watermark_spaces" or ii == "uppercase" or ii == "watermark_color" then
                        fix = ui.get(value["wtext"]) ~= "off"
                    elseif ii == "watermark_x_offset" or ii == "watermark_y_offset" then
                        fix = ui.get(value["watermark"]) ~= "off" and ui.get(value["watermark"]) == "custom"
                    elseif ii == "notify_tip11" or ii == "hitmark_color" then
                        fix = ui.get(value["hitmark_enable"]) == "yes"
                    elseif ii == "notheight" or ii == "notmarkheight" or ii == "notmarkoffset" or ii == "notmark_centered" or ii == "notmarkxoffset" or ii == "notmarkseparatorheight" or ii == "notglow" or ii == "notify_tip103" or ii == "notmark" or ii == "notmark2" or ii == "notify_tip2" or ii == "notify_tip19" or ii == "notify_tip18" or ii == "notmark_miss_prefix_color" or ii == "notmark_hit_prefix_color" or ii == "notcolor" or ii == "notify_tip3" or ii == "notglow_miss_color" or ii == "notglow_hit_color" or ii == "notify_tip104" or ii == "notify_tip105" or ii == "notcolor2" or ii == "notbackground_color" or ii == "notify_tip4" or ii == "notcolor3" or ii == "notmarkfont" or ii == "notmarkuppercase" or ii == "notmarkseparator" or ii == "notrounding" then
                        fix = #ui.get(value["notify"]) > 0
                    elseif ii == "custom_notmark_hit" then
                        fix = #ui.get(value["notify"]) > 0 and ui.get(value["notmark"]) == "custom"
                    elseif ii == "custom_notmark_miss" then
                        fix = #ui.get(value["notify"]) > 0 and ui.get(value["notmark2"]) == "custom"
                    elseif ii == "notify_tip12" then
                        fix = #ui.get(value["notify"]) > 0 and ui.get(value["notmark"]) == "custom"
                    elseif ii == "notify_tip13" then
                        fix = #ui.get(value["notify"]) > 0 and ui.get(value["notmark2"]) == "custom"
                    elseif ii == "notmark_hit_separator_color" or ii == "notify_tip101" then
                        fix = #ui.get(value["notify"]) > 0 and ui.get(value["notmarkseparator"]) == "yes"
                    elseif ii == "notmark_miss_separator_color" or ii == "notify_tip102" then
                        fix = #ui.get(value["notify"]) > 0 and ui.get(value["notmarkseparator"]) == "yes"
                    elseif ii == "slowdown_color" then
                        fix = ui.get(value["slowdown_indicator"]) == true
                    elseif ii == "debug_ls" then
                        fix = ui.get(value["debug_panel"]) == true
                    elseif ii == "debug_custom" then
                        fix = ui.get(value["debug_customp"]) == true
                    elseif ii == "debug_customp" then
                        fix = ui.get(value["debug_panel"]) == true
                    elseif ii == "debugtip" then
                        fix = ui.get(value["debug_customp"]) == true
                    end
                end
                ui.set_visible(vv, i == current and index == subextra and fix)
            end
        else
            ui.set_visible(value, i == current)
        end
    end
end
        end,
        ["animations"] = function()
			local myself = entity.get_local_player()
            if tbl.contains(ui.get(menu["visuals & misc"]["misc"]["features"]), "animations") and myself ~= nil then
                entity.set_prop(myself, "m_flPoseParameter", 1, bit.band(entity.get_prop(myself, "m_fFlags"), 1) == 0 and 6 or 0)
            end
        end,

        ["arrows"] = function()
            local myself = entity.get_local_player()
            if myself ~= nil and entity.is_alive(myself) then
                local width, height = client.screen_size()
                local r2, g2, b2, a2 = 55, 55, 55, 255
                local highlight_fraction = (globals.realtime() / 2 % 1.2 * 2) - 1.2
                local text_to_draw = ui.get(menu["visuals & misc"]["visuals"]["wtext"])
                if text_to_draw == "off" then
                    return
                end
                local output = ""
                local font_map = { normal = "c", small = "-", bold = "b" }
                local font_flag = font_map[ui.get(menu["visuals & misc"]["visuals"]["wfont"])] or "c"
                local use_uppercase = ui.get(menu["visuals & misc"]["visuals"]["uppercase"]) == "yes"
                local enable_animation = ui.get(menu["visuals & misc"]["visuals"]["watermark_animation"])
                local highlight_fraction = enable_animation and (globals.realtime() / 2 % 1.2 * 2) - 1.2 or 0
                local r2, g2, b2, a2 = 55, 55, 55, 255
                if text_to_draw == "luasync.max" then
                    local lua_text = "luasync"
                    local max_text = ".max"
                    local r1, g1, b1, a1 = 255, 255, 255, 255
                    if ui.get(menu["visuals & misc"]["visuals"]["watermark_spaces"]) == "yes" then
                        lua_text = lua_text:gsub(" ", "")
                        max_text = max_text:gsub(" ", "")
                        text_to_draw = lua_text .. max_text
                    else
                        text_to_draw = lua_text .. max_text
                    end
                    if use_uppercase then
                        lua_text = lua_text:upper()
                        max_text = max_text:upper()
                        text_to_draw = text_to_draw:upper()
                    end
                    output = output .. ('\a%02x%02x%02x%02x%s'):format(r1, g1, b1, a1, lua_text)
                    for idx = 1, #max_text do
                        local character = max_text:sub(idx, idx)
                        local character_fraction = idx / #max_text
                        local r_s, g_s, b_s = ui.get(menu["visuals & misc"]["visuals"]["watermark_color"])
                        local highlight_delta = enable_animation and (character_fraction - highlight_fraction) or 0
                        if highlight_delta >= 0 and highlight_delta <= 1.4 then
                            if highlight_delta > 0.7 then
                                highlight_delta = 1.4 - highlight_delta
                            end
                            local r_fraction, g_fraction, b_fraction = r2 - r_s, g2 - g_s, b2 - b_s
                            r_s = r_s + r_fraction * highlight_delta / 0.8
                            g_s = g_s + g_fraction * highlight_delta / 0.8
                            b_s = b_s + b_fraction * highlight_delta / 0.8
                        end
                        output = output .. ('\a%02x%02x%02x%02x%s'):format(r_s, g_s, b_s, a1, character)
                    end
                elseif text_to_draw == "luasync.max2" then
                    local lua_text = "luasync"
                    local max_text = ".max"
                    local r1, g1, b1, a1 = 255, 255, 255, 255
                    if ui.get(menu["visuals & misc"]["visuals"]["watermark_spaces"]) == "yes" then
                        lua_text = lua_text:gsub(" ", "")
                        max_text = max_text:gsub(" ", "")
                        text_to_draw = lua_text .. max_text
                    else
                        text_to_draw = lua_text .. max_text
                    end
                    if use_uppercase then
                        lua_text = lua_text:upper()
                        max_text = max_text:upper()
                        text_to_draw = text_to_draw:upper()
                    end
                    for idx = 1, #lua_text do
                        local character = lua_text:sub(idx, idx)
                        local character_fraction = idx / #lua_text
                        local r_s, g_s, b_s = ui.get(menu["visuals & misc"]["visuals"]["watermark_color"])
                        local highlight_delta = enable_animation and (character_fraction - highlight_fraction) or 0
                        if highlight_delta >= 0 and highlight_delta <= 1.4 then
                            if highlight_delta > 0.7 then
                                highlight_delta = 1.4 - highlight_delta
                            end
                            local r_fraction, g_fraction, b_fraction = r2 - r_s, g2 - g_s, b2 - b_s
                            r_s = r_s + r_fraction * highlight_delta / 0.8
                            g_s = g_s + g_fraction * highlight_delta / 0.8
                            b_s = b_s + b_fraction * highlight_delta / 0.8
                        end
                        output = output .. ('\a%02x%02x%02x%02x%s'):format(r_s, g_s, b_s, a1, character)
                    end
                    output = output .. ('\a%02x%02x%02x%02x%s'):format(r1, g1, b1, a1, max_text)

                elseif text_to_draw == "luasense beta" then
                    local lua_text = "l u a"
                    local sense_text = "s e n s e"
                    local beta_text = "[beta]"
                    local r1, g1, b1, a1 = ui.get(menu["visuals & misc"]["visuals"]["watermark_color"])
                    a1 = 255
                    if ui.get(menu["visuals & misc"]["visuals"]["watermark_spaces"]) == "yes" then
                        lua_text = lua_text:gsub(" ", "")
                        sense_text = sense_text:gsub(" ", "")
                        text_to_draw = lua_text .. sense_text .. " " .. beta_text
                    else
                        text_to_draw = lua_text .. " " .. sense_text .. " " .. beta_text
                    end
                    if use_uppercase then
                        lua_text = lua_text:upper()
                        sense_text = sense_text:upper()
                        beta_text = beta_text:upper()
                        text_to_draw = text_to_draw:upper()
                    end
                    output = output .. ('\a%02x%02x%02x%02x%s'):format(r1, g1, b1, a1, lua_text)
                    if ui.get(menu["visuals & misc"]["visuals"]["watermark_spaces"]) == "yes" then
                        output = output
                    else
                        output = output .. " "
                    end
                    for idx = 1, #sense_text do
                        local character = sense_text:sub(idx, idx)
                        local character_fraction = idx / #sense_text
                        local r_s, g_s, b_s = 255, 255, 255
                        local highlight_delta = enable_animation and (character_fraction - highlight_fraction) or 0
                        if highlight_delta >= 0 and highlight_delta <= 1.4 then
                            if highlight_delta > 0.7 then
                                highlight_delta = 1.4 - highlight_delta
                            end
                            local r_fraction, g_fraction, b_fraction = r2 - r_s, g2 - g_s, b2 - b_s
                            r_s = r_s + r_fraction * highlight_delta / 0.8
                            g_s = g_s + g_fraction * highlight_delta / 0.8
                            b_s = b_s + b_fraction * highlight_delta / 0.8
                        end
                        output = output .. ('\a%02x%02x%02x%02x%s'):format(r_s, g_s, b_s, a1, character)
                    end
                    output = output .. " "
                    output = output .. ('\a%02x%02x%02x%02x%s'):format(185, 64, 63, 255, beta_text)
                elseif text_to_draw == "luasense" then
                    local lua_text = "l u a"
                    local sense_text = "s e n s e"
                    local r1, g1, b1, a1 = ui.get(menu["visuals & misc"]["visuals"]["watermark_color"])
                    a1 = 255
                    local r2, g2, b2 = r2, g2, b2
                    if ui.get(menu["visuals & misc"]["visuals"]["watermark_spaces"]) == "yes" then
                        lua_text = lua_text:gsub(" ", "")
                        sense_text = sense_text:gsub(" ", "")
                        text_to_draw = lua_text .. sense_text
                    else
                        text_to_draw = lua_text .. " " .. sense_text
                    end
                    if use_uppercase then
                        lua_text = lua_text:upper()
                        sense_text = sense_text:upper()
                        text_to_draw = text_to_draw:upper()
                    end
                    for idx = 1, #lua_text do
                        local character = lua_text:sub(idx, idx)
                        local r_s, g_s, b_s = r1, g1, b1
                        output = output .. ('\a%02x%02x%02x%02x%s'):format(r_s, g_s, b_s, a1, character)
                    end
                    if ui.get(menu["visuals & misc"]["visuals"]["watermark_spaces"]) == "yes" then
                        output = output
                    else
                        output = output .. " "
                    end
                    for idx = 1, #sense_text do
                        local character = sense_text:sub(idx, idx)
                        local r_s, g_s, b_s = 255, 255, 255
                        if idx % 2 == 1 or ui.get(menu["visuals & misc"]["visuals"]["watermark_spaces"]) == "yes" then
                            local character_fraction = idx / #sense_text
                            local highlight_delta = enable_animation and (character_fraction - highlight_fraction) or 0
                            if highlight_delta >= 0 and highlight_delta <= 1.4 then
                                if highlight_delta > 0.7 then
                                    highlight_delta = 1.4 - highlight_delta
                                end
                                local r_fraction, g_fraction, b_fraction = r2 - r_s, g2 - g_s, b2 - b_s
                                r_s = r_s + r_fraction * highlight_delta / 0.8
                                g_s = g_s + g_fraction * highlight_delta / 0.8
                                b_s = b_s + b_fraction * highlight_delta / 0.8
                            end
                        end
                        output = output .. ('\a%02x%02x%02x%02x%s'):format(r_s, g_s, b_s, a1, character)
                    end
                elseif text_to_draw == "w3LLy$eN$E" then
                    local lua_text = ""
                    local sense_text = "w 3 L L y $ e N $ E "
                    local r1, g1, b1, a1 = ui.get(menu["visuals & misc"]["visuals"]["watermark_color"])
                    a1 = 255
                    local r2, g2, b2 = r2, g2, b2
                    if ui.get(menu["visuals & misc"]["visuals"]["watermark_spaces"]) == "yes" then
                        lua_text = lua_text:gsub(" ", "")
                        sense_text = sense_text:gsub(" ", "")
                        text_to_draw = lua_text .. sense_text
                    else
                        text_to_draw = lua_text .. " " .. sense_text
                    end
                    if use_uppercase then
                        lua_text = lua_text:upper()
                        sense_text = sense_text:upper()
                        text_to_draw = text_to_draw:upper()
                    end
                    for idx = 1, #lua_text do
                        local character = lua_text:sub(idx, idx)
                        local r_s, g_s, b_s = r1, g1, b1
                        output = output .. ('\a%02x%02x%02x%02x%s'):format(r_s, g_s, b_s, a1, character)
                    end
                    if ui.get(menu["visuals & misc"]["visuals"]["watermark_spaces"]) == "yes" then
                        output = output
                    else
                        output = output .. " "
                    end
                    for idx = 1, #sense_text do
                        local character = sense_text:sub(idx, idx)
                        local r_s, g_s, b_s = 255, 255, 255
                        if idx % 2 == 1 or ui.get(menu["visuals & misc"]["visuals"]["watermark_spaces"]) == "yes" then
                            local character_fraction = idx / #sense_text
                            local highlight_delta = enable_animation and (character_fraction - highlight_fraction) or 0
                            if highlight_delta >= 0 and highlight_delta <= 1.4 then
                                if highlight_delta > 0.7 then
                                    highlight_delta = 1.4 - highlight_delta
                                end
                                local r_fraction, g_fraction, b_fraction = r2 - r_s, g2 - g_s, b2 - b_s
                                r_s = r_s + r_fraction * highlight_delta / 0.8
                                g_s = g_s + g_fraction * highlight_delta / 0.8
                                b_s = b_s + b_fraction * highlight_delta / 0.8
                            end
                        end
                        output = output .. ('\a%02x%02x%02x%02x%s'):format(r_s, g_s, b_s, a1, character)
                    end
                elseif text_to_draw == "luasense î¤" then
                    local star = "î¤"
                    local lua_text = "l u a s e n s e"
                    local r1, g1, b1, a1 = 255, 255, 255, 255
                    if ui.get(menu["visuals & misc"]["visuals"]["watermark_spaces"]) == "yes" then
                        lua_text = lua_text:gsub(" ", "")
                        text_to_draw = lua_text .. " " .. star
                    else
                        text_to_draw = lua_text .. " " .. star
                    end
                    if use_uppercase then
                        lua_text = lua_text:upper()
                        text_to_draw = text_to_draw:upper()
                    end
                    output = output .. ('\a%02x%02x%02x%02x%s'):format(r1, g1, b1, a1, lua_text)
                    output = output .. " " 
                    local r_s, g_s, b_s = ui.get(menu["visuals & misc"]["visuals"]["watermark_color"])
                    local highlight_delta = enable_animation and (1 - highlight_fraction) or 0
                    if highlight_delta >= 0 and highlight_delta <= 1.4 then
                        if highlight_delta > 0.7 then
                            highlight_delta = 1.4 - highlight_delta
                        end
                        local r_fraction, g_fraction, b_fraction = r2 - r_s, g2 - g_s, b2 - b_s
                        r_s = r_s + r_fraction * highlight_delta / 0.8
                        g_s = g_s + g_fraction * highlight_delta / 0.8
                        b_s = b_s + b_fraction * highlight_delta / 0.8
                    end
                    output = output .. ('\a%02x%02x%02x%02x%s'):format(r_s, g_s, b_s, a1, star)
                elseif text_to_draw == "î¤ luasense" then
                    local star = "î¤"
                    local lua_text = "l u a s e n s e"
                    local r1, g1, b1, a1 = 255, 255, 255, 255
                    if ui.get(menu["visuals & misc"]["visuals"]["watermark_spaces"]) == "yes" then
                        lua_text = lua_text:gsub(" ", "")
                        text_to_draw = star .. " " .. lua_text
                    else
                        text_to_draw = star .. " " .. lua_text
                    end
                    if use_uppercase then
                        lua_text = lua_text:upper()
                        text_to_draw = text_to_draw:upper()
                    end
                    local r_s, g_s, b_s = ui.get(menu["visuals & misc"]["visuals"]["watermark_color"])
                    local highlight_delta = enable_animation and (0 - highlight_fraction) or 0
                    if highlight_delta >= 0 and highlight_delta <= 1.4 then
                        if highlight_delta > 0.7 then
                            highlight_delta = 1.4 - highlight_delta
                        end
                        local r_fraction, g_fraction, b_fraction = r2 - r_s, g2 - g_s, b2 - b_s
                        r_s = r_s + r_fraction * highlight_delta / 0.8
                        g_s = g_s + g_fraction * highlight_delta / 0.8
                        b_s = b_s + b_fraction * highlight_delta / 0.8
                    end
                    output = output .. ('\a%02x%02x%02x%02x%s'):format(r_s, g_s, b_s, a1, star)
                    output = output .. " "
                    output = output .. ('\a%02x%02x%02x%02x%s'):format(r1, g1, b1, a1, lua_text)
                elseif text_to_draw == "luasense î¤" then
                    local star = "î¤"
                    local lua_text = "l u a s e n s e"
                    local r1, g1, b1, a1 = 255, 255, 255, 255
                    if ui.get(menu["visuals & misc"]["visuals"]["watermark_spaces"]) == "yes" then
                        lua_text = lua_text:gsub(" ", "")
                        text_to_draw = lua_text .. " " .. star
                    else
                        text_to_draw = lua_text .. " " .. star
                    end
                    if use_uppercase then
                        lua_text = lua_text:upper()
                        text_to_draw = text_to_draw:upper()
                    end
                    output = output .. ('\a%02x%02x%02x%02x%s'):format(r1, g1, b1, a1, lua_text)
                    output = output .. " "
                    local r_s, g_s, b_s = ui.get(menu["visuals & misc"]["visuals"]["watermark_color"])
                    local highlight_delta = enable_animation and (1 - highlight_fraction) or 0
                    if highlight_delta >= 0 and highlight_delta <= 1.4 then
                        if highlight_delta > 0.7 then
                            highlight_delta = 1.4 - highlight_delta
                        end
                        local r_fraction, g_fraction, b_fraction = r2 - r_s, g2 - g_s, b2 - b_s
                        r_s = r_s + r_fraction * highlight_delta / 0.8
                        g_s = g_s + g_fraction * highlight_delta / 0.8
                        b_s = b_s + b_fraction * highlight_delta / 0.8
                    end
                    output = output .. ('\a%02x%02x%02x%02x%s'):format(r_s, g_s, b_s, a1, star)
                elseif text_to_draw == "î¤ luasense î¤" then
                    local star = "î¤"
                    local lua_text = "l u a s e n s e"
                    local r1, g1, b1, a1 = 255, 255, 255, 255
                    if ui.get(menu["visuals & misc"]["visuals"]["watermark_spaces"]) == "yes" then
                        lua_text = lua_text:gsub(" ", "")
                        text_to_draw = star .. " " .. lua_text .. " " .. star
                    else
                        text_to_draw = star .. " " .. lua_text .. " " .. star
                    end
                    if use_uppercase then
                        lua_text = lua_text:upper()
                        text_to_draw = text_to_draw:upper()
                    end
                    local r_s, g_s, b_s = ui.get(menu["visuals & misc"]["visuals"]["watermark_color"])
                    local highlight_delta = enable_animation and (0 - highlight_fraction) or 0
                    if highlight_delta >= 0 and highlight_delta <= 1.4 then
                        if highlight_delta > 0.7 then
                            highlight_delta = 1.4 - highlight_delta
                        end
                        local r_fraction, g_fraction, b_fraction = r2 - r_s, g2 - g_s, b2 - b_s
                        r_s = r_s + r_fraction * highlight_delta / 0.8
                        g_s = g_s + g_fraction * highlight_delta / 0.8
                        b_s = b_s + b_fraction * highlight_delta / 0.8
                    end
                    output = output .. ('\a%02x%02x%02x%02x%s'):format(r_s, g_s, b_s, a1, star)
                    output = output .. " "
                    output = output .. ('\a%02x%02x%02x%02x%s'):format(r1, g1, b1, a1, lua_text)
                    output = output .. " "
                    r_s, g_s, b_s = ui.get(menu["visuals & misc"]["visuals"]["watermark_color"])
                    highlight_delta = enable_animation and (1 - highlight_fraction) or 0
                    if highlight_delta >= 0 and highlight_delta <= 1.4 then
                        if highlight_delta > 0.7 then
                            highlight_delta = 1.4 - highlight_delta
                        end
                        local r_fraction, g_fraction, b_fraction = r2 - r_s, g2 - g_s, b2 - b_s
                        r_s = r_s + r_fraction * highlight_delta / 0.8
                        g_s = g_s + g_fraction * highlight_delta / 0.8
                        b_s = b_s + b_fraction * highlight_delta / 0.8
                    end
                    output = output .. ('\a%02x%02x%02x%02x%s'):format(r_s, g_s, b_s, a1, star)
                elseif text_to_draw == "custom" then
                    text_to_draw = ui.get(menu["visuals & misc"]["visuals"]["custom_wtext"]) or "custom"
                    local prefix_text = ui.get(menu["visuals & misc"]["visuals"]["custom_prefix"]) or ""
                    local prefix2_text = ui.get(menu["visuals & misc"]["visuals"]["custom_prefix2"]) or ""
                    if use_uppercase then
                        text_to_draw = text_to_draw:upper()
                        prefix_text = prefix_text:upper()
                        prefix2_text = prefix2_text:upper()
                    end
                    for idx = 1, #text_to_draw do
                        local character = text_to_draw:sub(idx, idx)
                        local character_fraction = idx / #text_to_draw
                        local r1, g1, b1, a1 = ui.get(menu["visuals & misc"]["visuals"]["watermark_color"])
                        a1 = 255
                        local highlight_delta = enable_animation and (character_fraction - highlight_fraction) or 0
                        if highlight_delta >= 0 and highlight_delta <= 1.4 then
                            if highlight_delta > 0.7 then
                                highlight_delta = 1.4 - highlight_delta
                            end
                            local r_fraction, g_fraction, b_fraction = r2 - r1, g2 - g1, b2 - b1
                            r1 = r1 + r_fraction * highlight_delta / 0.8
                            g1 = g1 + g_fraction * highlight_delta / 0.8
                            b1 = b1 + b_fraction * highlight_delta / 0.8
                        end
                        output = output .. ('\a%02x%02x%02x%02x%s'):format(r1, g1, b1, a1, character)
                    end
                    if prefix_text ~= "" then
                        local r_p, g_p, b_p, a_p = ui.get(menu["visuals & misc"]["visuals"]["custom_prefix_color"])
                        a_p = 255
                        local prefix_highlight_fraction = ui.get(menu["visuals & misc"]["visuals"]["prefix_animation"]) and ((globals.realtime() / 2 % 1.2 * 2) - 1.2) or 0
                        for idx = 1, #prefix_text do
                            local character = prefix_text:sub(idx, idx)
                            local character_fraction = idx / #prefix_text
                            local r_s, g_s, b_s = r_p, g_p, b_p
                            local highlight_delta = ui.get(menu["visuals & misc"]["visuals"]["prefix_animation"]) and (character_fraction - prefix_highlight_fraction) or 0
                            if highlight_delta >= 0 and highlight_delta <= 1.4 then
                                if highlight_delta > 0.7 then
                                    highlight_delta = 1.4 - highlight_delta
                                end
                                local r_fraction, g_fraction, b_fraction = r2 - r_s, g2 - g_s, b2 - b_s
                                r_s = r_s + r_fraction * highlight_delta / 0.8
                                g_s = g_s + g_fraction * highlight_delta / 0.8
                                b_s = b_s + b_fraction * highlight_delta / 0.8
                            end
                            output = output .. ('\a%02x%02x%02x%02x%s'):format(r_s, g_s, b_s, a_p, character)
                        end
                    end
                    if prefix2_text ~= "" then
                        local r_p2, g_p2, b_p2, a_p2 = ui.get(menu["visuals & misc"]["visuals"]["custom_prefix2_color"])
                        a_p2 = 255
                        local prefix2_highlight_fraction = ui.get(menu["visuals & misc"]["visuals"]["prefix2_animation"]) and ((globals.realtime() / 2 % 1.2 * 2) - 1.2) or 0
                        for idx = 1, #prefix2_text do
                            local character = prefix2_text:sub(idx, idx)
                            local character_fraction = idx / #prefix2_text
                            local r_s, g_s, b_s = r_p2, g_p2, b_p2
                            local highlight_delta = ui.get(menu["visuals & misc"]["visuals"]["prefix2_animation"]) and (character_fraction - prefix2_highlight_fraction) or 0
                            if highlight_delta >= 0 and highlight_delta <= 1.4 then
                                if highlight_delta > 0.7 then
                                    highlight_delta = 1.4 - highlight_delta
                                end
                                local r_fraction, g_fraction, b_fraction = r2 - r_s, g2 - g_s, b2 - b_s
                                r_s = r_s + r_fraction * highlight_delta / 0.8
                                g_s = g_s + g_fraction * highlight_delta / 0.8
                                b_s = b_s + b_fraction * highlight_delta / 0.8
                            end
                            output = output .. ('\a%02x%02x%02x%02x%s'):format(r_s, g_s, b_s, a_p2, character)
                        end
                    end
                else
                    if ui.get(menu["visuals & misc"]["visuals"]["watermark_spaces"]) == "yes" then
                        text_to_draw = text_to_draw:gsub(" ", "")
                    end
                    if use_uppercase then
                        text_to_draw = text_to_draw:upper()
                    end
                    for idx = 1, #text_to_draw do
                        local character = text_to_draw:sub(idx, idx)
                        local character_fraction = idx / #text_to_draw
                        local r1, g1, b1, a1 = ui.get(menu["visuals & misc"]["visuals"]["watermark_color"])
                        a1 = 255
                        local highlight_delta = enable_animation and (character_fraction - highlight_fraction) or 0
                        if highlight_delta >= 0 and highlight_delta <= 1.4 then
                            if highlight_delta > 0.7 then
                                highlight_delta = 1.4 - highlight_delta
                            end
                            local r_fraction, g_fraction, b_fraction = r2 - r1, g2 - g1, b2 - b1
                            r1 = r1 + r_fraction * highlight_delta / 0.8
                            g1 = g1 + g_fraction * highlight_delta / 0.8
                            b1 = b1 + b_fraction * highlight_delta / 0.8
                        end
                        output = output .. ('\a%02x%02x%02x%02x%s'):format(r1, g1, b1, a1, character)
                    end
                end
                if getbuild() == "beta" then
                    output = output .. ("\a%x%x%x%x"):format(255, 255, 255, 255) .. ""
                end
                local r, g, b = ui.get(menu["visuals & misc"]["visuals"]["watermark_color"])
                local x_offset = ui.get(menu["visuals & misc"]["visuals"]["watermark"]) == "custom" and ui.get(menu["visuals & misc"]["visuals"]["watermark_x_offset"]) or 0
                local y_offset = ui.get(menu["visuals & misc"]["visuals"]["watermark"]) == "custom" and ui.get(menu["visuals & misc"]["visuals"]["watermark_y_offset"]) or 0
                local font = ui.get(menu["visuals & misc"]["visuals"]["wfont"])
                local positions = {
                    bottom = {
                        normal = { x = width/2 + x_offset, y = height - 8 + y_offset },
                        bold = { x = width/ 2.0760 + x_offset, y = height - 14 + y_offset },
                        small = { x = width/2.07 + x_offset, y = height - 12 + y_offset }
                    },
                    right = {
                        normal = { x = width - 60 + x_offset, y = height/1.977 + y_offset },
                        bold = { x = width - 117 + x_offset, y = height/2 + y_offset },
                        small = { x = width - 80 + x_offset, y = height/2 + y_offset }
                    },
                    left = {
                        normal = { x = 69 + x_offset, y = height/2 + y_offset },
                        bold = { x = 16 + x_offset, y = height/2.02 + y_offset },
                        small = { x = 17 + x_offset, y = height/2.0093 + y_offset }
                    },
                    custom = {
                        normal = { x = width/2 + x_offset, y = height/2 + y_offset },
                        bold = { x = width/2 + x_offset, y = height/2 + y_offset },
                        small = { x = width/2 + x_offset, y = height/2 + y_offset }
                    }
                }
                local watermark_pos = ui.get(menu["visuals & misc"]["visuals"]["watermark"])
                local pos = positions[watermark_pos][font] or positions[watermark_pos].normal
                renderer.text(pos.x, pos.y, r, g, b, 255, font_flag, 0, output)


                local local_player = entity.get_local_player()
                if local_player and entity.is_alive(local_player) then
                    local velocity_modifier = entity.get_prop(local_player, "m_flVelocityModifier")
                    if velocity_modifier and velocity_modifier < 1 and ui.get(menu["visuals & misc"]["visuals"]["slowdown_indicator"]) then
                        local screen_w, screen_h = client.screen_size()
                        local bar_x = screen_w / 2 - 90
                        local bar_y = screen_h - 850
                        local bar_width = 174
                        local bar_height = 8
                        local fill_height = 5.6
                        local fill_y = bar_y + (bar_height - fill_height) / 2
                        local fill_width = bar_width * velocity_modifier
                        local r, g, b, _ = ui.get(menu["visuals & misc"]["visuals"]["slowdown_color"])
                        local a = 255
                        local bg_r, bg_g, bg_b, bg_a = 25, 25, 25, 255
                        local rounding = 3
                        local glow_strength = 10


                        local fade_threshold = 0.9
                        local fade_alpha = 1.0
                        if velocity_modifier > fade_threshold then
                            fade_alpha = (1.0 - velocity_modifier) / (1.0 - fade_threshold)
                            fade_alpha = math.max(0, math.min(1, fade_alpha))
                        end
                        local final_a = math.floor(a * fade_alpha)
                        local final_bg_a = math.floor(bg_a * fade_alpha)
                

                        k.rec(bar_x, bar_y, bar_width, bar_height, bg_r, bg_g, bg_b, final_bg_a, rounding)
                

                        for i = 0, glow_strength do
                            local alpha = final_bg_a / 2 * (i / glow_strength) ^ 3
                            k.rec_outline(
                                bar_x + (i - glow_strength) * 1,
                                bar_y + (i - glow_strength) * 1,
                                bar_width - (i - glow_strength) * 2,
                                bar_height - (i - glow_strength) * 2,
                                r, g, b,
                                alpha / 1.5,
                                rounding,
                                1
                            )
                        end
                
                        if fill_width > 0 then
                            k.rec(bar_x, fill_y, fill_width, fill_height, r, g, b, final_a, rounding)
                
                            for i = 0, glow_strength do
                                local alpha = final_a / 2 * (i / glow_strength) ^ 3
                                k.rec_outline(
                                    bar_x + (i - glow_strength) * 1,
                                    fill_y + (i - glow_strength) * 1,
                                    fill_width - (i - glow_strength) * 2,
                                    fill_height - (i - glow_strength) * 2,
                                    r, g, b,
                                    alpha / 1.5,
                                    rounding,
                                    1
                                )
                            end
                        end
                
                        renderer.text(bar_x + bar_width / 2, bar_y - 10, 255, 255, 255, final_a, "c", 0, string.format("Max velocity reduced by %.0f%%", (1 - velocity_modifier) * 100))
                    end
                end
                            
                
                local r, g, b = ui.get(menu["visuals & misc"]["visuals"]["arrows_color"])
                local leftkey = ui.get(menu["visuals & misc"]["visuals"]["arrows"]) == "simple" and "<" or "â¯"
			    local rightkey = ui.get(menu["visuals & misc"]["visuals"]["arrows"]) == "simple" and ">" or "â¯"
                local w, h = client.screen_size()
                w, h = w/2, h/2
                local yaw_body = math.max(-60, math.min(60, math.floor((entity.get_prop(myself, "m_flPoseParameter", 11) or 0)*120-60+0.5)))
                if yaw_body > 0 and yaw_body > 60 then yaw_body = 60 end
                if yaw_body < 0 and yaw_body < -60 then yaw_body = -60 end
                local alpha = 255
                if ui.get(menu["visuals & misc"]["visuals"]["arrows"]) == "simple" then
                    renderer.text(w + 50, h, 111, 111, 111, 255, "c+", 0, rightkey)
                    if tbl.antiaim.manual.aa == 90 then
                        renderer.text(w + 50, h, r, g, b, alpha, "c+", 0, rightkey)
                    end
                    renderer.text(w - 50, h, 111, 111, 111, 255, "c+", 0, leftkey)
                    if tbl.antiaim.manual.aa == -90 then
                        renderer.text(w - 50, h, r, g, b, alpha, "c+", 0, leftkey)
                    end
                elseif ui.get(menu["visuals & misc"]["visuals"]["arrows"]) == "body" then
                    renderer.line(w + -(40), h-8, w + -(40), h+8, r, g, b, yaw_body > 0 and 55 or 255)
                    renderer.line(w + (42), h-8, w + (42), h+8, r, g, b, yaw_body < 0 and 55 or 255)
                    h = h - 2.5
                    renderer.text(w + 50, h, 111, 111, 111, 255, "c+", 0, rightkey)
                    if tbl.antiaim.manual.aa == 90 then
                        renderer.text(w + 50, h, r, g, b, alpha, "c+", 0, rightkey)
                    end
                    renderer.text(w - 50, h, 111, 111, 111, 255, "c+", 0, leftkey)
                    if tbl.antiaim.manual.aa == -90 then
                        renderer.text(w - 50, h, r, g, b, alpha, "c+", 0, leftkey)
                    end
                elseif ui.get(menu["visuals & misc"]["visuals"]["arrows"]) == "luasense" then
                    local xv, yv, zv = entity.get_prop(myself, "m_vecVelocity")
                    local speed = math.sqrt(xv*xv + yv*yv) / 10
                    if tbl.antiaim.fs == 1 then
                        renderer.line(w + -(36+speed), h-8, w + -(36+speed), h+8, 255, 255, 255, alpha)
                    end
                    if tbl.antiaim.fs == -1 then
                        renderer.line(w + (38+speed), h-8, w + (38+speed), h+8, 255, 255, 255, alpha)
                    end
                    renderer.line(w + -(40+speed), h-8, w + -(40+speed), h+8, r, g, b, yaw_body > 0 and 55 or 255)
                    renderer.line(w + (42+speed), h-8, w + (42+speed), h+8, r, g, b, yaw_body < 0 and 55 or 255)
                    h = h - 2.5
                    renderer.text(w + (50+speed), h, 111, 111, 111, 255, "c+", 0, rightkey)
                    if tbl.antiaim.manual.aa == 90 then
                        renderer.text(w + (50+speed), h, r, g, b, alpha, "c+", 0, rightkey)
                    end
                    renderer.text(w - (50+speed), h, 111, 111, 111, 255, "c+", 0, leftkey)
                    if tbl.antiaim.manual.aa == -90 then
                        renderer.text(w - (50+speed), h, r, g, b, alpha, "c+", 0, leftkey)
                    end
                else end
            end
        end,


        
        ["indicator"] = function()
            local myself = entity.get_local_player()
            if not entity.is_alive(myself) then return nil end
            local w, h = client.screen_size()
            w, h = w / 2, h / 2
            local yaw_body = math.max(-60, math.min(60, math.floor((entity.get_prop(myself, "m_flPoseParameter", 11) or 0) * 120 - 60 + 0.5)))
            if yaw_body > 0 and yaw_body > 60 then yaw_body = 60 end
            if yaw_body < 0 and yaw_body < -60 then yaw_body = -60 end
            scope_fix = entity.get_prop(myself, "m_bIsScoped") ~= 0
            if scope_fix then 
                if scope_int < 30 then
                    scope_int = scope_int + 2
                end
            else
                if scope_int > 0 then
                    scope_int = scope_int - 2
                end
            end
            local w_adjusted = w + scope_int - 0
            local ind_height = 15
            local r, g, b = ui.get(menu["visuals & misc"]["visuals"]["indicators_color"])
            local r1, g1, b1, a1 = r, g, b, 255
            local r2, g2, b2, a2 = 155, 155, 155, 255
        
            local indicator_type = ui.get(menu["visuals & misc"]["visuals"]["indicators"])
            
            if indicator_type == "default" then
                if yaw_body > 0 then
                    renderer.text(w_adjusted, h + ind_height, 255, 255, 255, 255, "cb", nil, gradient(r2, g2, b2, a2, r1, g1, b1, a1, "luasense"))
                else
                    renderer.text(w_adjusted, h + ind_height, 255, 255, 255, 255, "cb", nil, gradient(r1, g1, b1, a1, r2, g2, b2, a2, "luasense"))
                end
            elseif indicator_type == "luasense" then
                local text_to_draw = "L U A S E N S E"
                local text_width = renderer.measure_text("-", text_to_draw)
                local x_pos = w + scope_int - text_width / 2
                local y_pos = 551
                local output = ""
                local highlight_fraction = (globals.realtime() / 2 % 1.2 * 2) - 1.2
                for idx = 1, #text_to_draw do
                    local character = text_to_draw:sub(idx, idx)
                    local character_fraction = idx / #text_to_draw
                    local r_s, g_s, b_s = r1, g1, b1
                    local highlight_delta = (character_fraction - highlight_fraction)
                    if highlight_delta >= 0 and highlight_delta <= 1.4 then
                        if highlight_delta > 0.7 then
                            highlight_delta = 1.4 - highlight_delta
                        end
                        local r_fraction, g_fraction, b_fraction = r2 - r_s, g2 - g_s, b2 - b_s
                        r_s = r_s + r_fraction * highlight_delta / 0.8
                        g_s = g_s + g_fraction * highlight_delta / 0.8
                        b_s = b_s + b_fraction * highlight_delta / 0.8
                    end
                    output = output .. ('\a%02x%02x%02x%02x%s'):format(r_s, g_s, b_s, a1, character)
                end
                renderer.text(x_pos, y_pos, 255, 255, 255, 255, "-", nil, output)
            elseif indicator_type == "custom" then
                local custom_text = ui.get(menu["visuals & misc"]["visuals"]["custom_indicator_text"]) or "CUSTOM"
                local text_width = renderer.measure_text("-", custom_text)
                local x_pos = w + scope_int - text_width / 1.79
                local y_pos = 551
                local output = ""
                local highlight_fraction = (globals.realtime() / 2 % 1.2 * 2) - 1.2
                for idx = 1, #custom_text do
                    local character = custom_text:sub(idx, idx)
                    local character_fraction = idx / #custom_text
                    local r_s, g_s, b_s = r1, g1, b1
                    local highlight_delta = (character_fraction - highlight_fraction)
                    if highlight_delta >= 0 and highlight_delta <= 1.4 then
                        if highlight_delta > 0.7 then
                            highlight_delta = 1.4 - highlight_delta
                        end
                        local r_fraction, g_fraction, b_fraction = r2 - r_s, g2 - g_s, b2 - b_s
                        r_s = r_s + r_fraction * highlight_delta / 0.8
                        g_s = g_s + g_fraction * highlight_delta / 0.8
                        b_s = b_s + b_fraction * highlight_delta / 0.8
                    end
                    output = output .. ('\a%02x%02x%02x%02x%s'):format(r_s, g_s, b_s, a1, character)
                end
                renderer.text(x_pos, y_pos, 255, 255, 255, 255, "-", nil, output)
            end
        
            if indicator_type ~= "-" then
                local dt_on = (ui.get(z.items.keys.dt[1]) and ui.get(z.items.keys.dt[2]))
                local hs_on = (ui.get(z.items.keys.hs[1]) and ui.get(z.items.keys.hs[2]))
                if ui.get(z.items.keys.fd[1]) then
                    ind_height = ind_height + 8
                    renderer.text(w_adjusted, h + ind_height, r2, g2, b2, a2, "c-", nil, "DUCK")
                    if entity.get_prop(myself, "m_flDuckAmount") > 0.1 then
                        if animkeys.duck < 255 then
                            animkeys.duck = animkeys.duck + 2.5
                        end
                        renderer.text(w_adjusted, h + ind_height, r1, g1, b1, animkeys.duck, "c-", nil, "DUCK")
                    else
                        animkeys.duck = 0
                    end
                else
                    animkeys.duck = 0
                end
                if ui.get(z.items.keys.sp[1]) then
                    ind_height = ind_height + 8
                    if animkeys.safe < 255 then
                        animkeys.safe = animkeys.safe + 2.5
                    end
                    renderer.text(w_adjusted, h + ind_height, r1, g1, b1, animkeys.safe, "c-", nil, "SAFE")
                else
                    animkeys.safe = 0
                end
                if ui.get(z.items.keys.fb[1]) then
                    ind_height = ind_height + 8
                    if animkeys.baim < 255 then
                        animkeys.baim = animkeys.baim + 2.5
                    end
                    renderer.text(w_adjusted, h + ind_height, r1, g1, b1, animkeys.baim, "c-", nil, "BAIM")
                else
                    animkeys.baim = 0
                end
                if dt_on then
                    ind_height = ind_height + 8
                    renderer.text(w_adjusted, h + ind_height, r2, g2, b2, a2, "c-", nil, "DT")
                    if (shift_int > 0) or (z.defensive.defensive > 1) then
                        if animkeys.dt < 255 then
                            animkeys.dt = animkeys.dt + 2.5
                        end
                        renderer.text(w_adjusted, h + ind_height, r1, g1, b1, animkeys.dt, "c-", nil, "DT")
                    else
                        animkeys.dt = 0
                    end
                else
                    animkeys.dt = 0
                end
                if hs_on then
                    ind_height = ind_height + 8
                    renderer.text(w_adjusted, h + ind_height, r2, g2, b2, a2, "c-", nil, "HS")
                    if not (dt_on) then
                        if animkeys.hide < 255 then
                            animkeys.hide = animkeys.hide + 2.5
                        end
                        renderer.text(w_adjusted, h + ind_height, r1, g1, b1, animkeys.hide, "c-", nil, "HS")
                    else
                        animkeys.hide = 0
                    end
                else
                    animkeys.hide = 0
                end
                if ui.get(menu["anti aimbot"]["keybinds"]["freestand"]) then
                    ind_height = ind_height + 8
                    if animkeys.fs < 255 then
                        animkeys.fs = animkeys.fs + 2.5
                    end
                    renderer.text(w_adjusted, h + ind_height, r1, g1, b1, animkeys.fs, "c-", nil, "FS")
                else
                    animkeys.fs = 0
                end
            end
        end,
        
    


        ["shutdown"] = function()
			for i, v in next, tbl.items do
				for index, value in next, v do
					ui.set_visible(value, true)
				end
			end
			ui.set(tbl.items.enabled[1], true)
			ui.set(tbl.items.base[1], "at targets")
			ui.set(tbl.items.pitch[1], "default")
			ui.set(tbl.items.yaw[1], "180")
			ui.set(tbl.items.yaw[2], 0)
			ui.set(tbl.items.jitter[1], "off")
			ui.set(tbl.items.jitter[2], 0)
			ui.set(tbl.items.body[1], "opposite")
			ui.set(tbl.items.body[2], 0)
			ui.set(tbl.items.fsbody[1], true)
			ui.set(tbl.items.edge[1], false)
			ui.set(tbl.items.fs[1], false)
			ui.set(tbl.items.fs[2], "always on")
			ui.set(tbl.items.roll[1], 0)
			ui.set_visible(tbl.items.jitter[2], false)
			ui.set_visible(tbl.items.body[2], false)
		end
	}
    local killsay_messages = {
        "Can someone fucking explain to me why I miss baim and hs with skeet all the time",
        "i don't gain anything from telling someone through a screen about my career whether im doxxed or not",
        "teammate eat churro for breakfast :skull: he not ready for this big black sugar coated churro hes gonna recieve tonight",
        "URA SUNT UN SLAB AM PIERDUT VS CARLITO TALENT SI WELLY$%%%$$",
        "treci la flotari curvo",
        "il cam suparati pe interlop asa ca ma urc beat la volanu ferrariului meu facut din rubine si va calc",
        "lasa a fsot vina mea ca ma joc 3v3 cu tn raman la 2v2 IA DAMI SNIPE cu rusii tai te bat 9 0 si baga bank *my new home* si ti dau 9 0 dp t fututi ras mati",
        "O UMPLU PE PETRONELA DE RESPECT",
        "fut mt haha",
        "kf sklavule pierzi in fata la bos?",
        "avet 25 wr pe supportere primele voastre dupa free uri cu 20 wr lose uri vs lvl 2 :joy:",
        "@origination tu esti mai prost decat el dc stai sa argumentezi cu o persoana de a avut cele mai multe reseturi sezonu trecut si a batut unmu joc de el i facuse badge pe cont :rofl:",
        "ATENTIE ATENTIE!  a facut loveless lvl 6 si wr mai mare de 50 din 2 meciuri trebuie sa sarim sus in aer la 3!  1 2 4",
        "this argument was automatically won by me bcs ur grinding 1v1 unironically while using defensive so ur a virgin never felt the touch of a woman nor ur mother",
        "uitasem sa mi deschid monitoru si te am batut easy???",
        "mfs be screaming ez game they bout to be screaming because of my disastorous backshots",
        "Big W, whatever comment tu veux m'appeler bitch",
        "BA MAI TACI IN MORTI MATI DE RUS INFECT CA N AI O TREABA CU JOCU SARACU PULI MELE TE JOACA TOTI IN PULA LA FIECARE TURNEU NAGAMIAS PULAN SUFLETU TAU",
        "SA TE IAU IN PULA DE SLAB CA AI 30 WINRATE FUTUTI MORTII TAI DE MUCEGAIT INFECT CA ITI PICA PIELEA DE PE TINE",
        "BA TACI IN MORTI TAI DE SARMAN CA TE IAU LA PALME SI TE FUT IN CUR BAGMAIS PULAN MORTI TAI SAMI BAG DE PIZDA PENALA",
        "BA SA VA TRAG LA MUIE DE AMARATI CU 10 WR SA VA TRAG LA MUIE AM PULA DE 1 METRU SI O SA VA CAM FUT PE TOTI NAUDDDDDDDDDDDDDDDDDDDDDD",
        ".i. <- ia cocaru",
        "team intimidat sugemiai coiu stang",
        "nu am canal ca mi l am sters singur",
        "by rxd",
        "negoita curva ordinara suge pl asta bleaga de 2m mai si atarna in gura lui si pe mameloanele lu masa",
        "@x_xcharacter jos la plm cori pula cu urechi esti",
        "interlop pe net sa ma frecati la ghenunchi",
        "I know you spend every second playing hvh in your basement, it's ok, maybe one day you'll realise it's not cool to be 40 yrs old playing hvh",
        "so you spend 36 hours sleeping and 300 hours playing hvh",
        "hello , if u can help me with money coz i need to save my bichon | contact : nl36 (nublain)",
        "why are u fanboying pufarino?",
        "you are too easy as an opponent no matter the thing you lost to maut & shameless on stmarc and dukedenniskaicenat on shortnuke",
        "ba sunt sweety nu imi iau ego sa stiti NAUD",
        "cloudyx mam descarcat pe monica stai jos sclavule",
        "alexandru federatie intoarcete in moldova ca te caut de 2 luni ai plecat cu pomelou meu",
        "sebastian bratara te dai smardoi in pitesti ca dai pumni la fete in burta",
        "normal bro ca mori daca nu joci cu astronaut.lua cel mai bun lua",
        "o sa fac sapun din grasimea mati bagamias pulan curu tau si al iei",
        "50wr russians woh live in their communist grandpa basement work their ass at a farm in vorzogory to buy nl sub",
        "COAIE A SCRIS KAMEL DE PE CONTU MEU JUR MI A LUAT PAROLA FUTUTI GRANITA MATII",
        "ba kamel esti un gunoi infect te bat cu pula mea de 2 metri si maaa razbantor te bat mario",
        "gora futati mortii tai de slab ce esti te calc in mare cu",
        "nublain saracu pulii mele te rupe carlito in 1v1 si plange mama ta de rusine ca esti jeg",
        "sweety ba taci dracu ca esti un noob imputit cu 10 wr te fut mario",
        "pufarino esti atat de prost incat pierzi vs un bot si plangi ca un cacat in ploaie NAUD",
        "kamel u fucking trash i smash ur face with my 10 inch mund i burta",
        "gora u suck so bad u lose to carlito in 1v1 ur mom sa rammed",
        "nublain u pathetic shit i wipe floor with u and u chi like ai ai ai",
        "sweety shut ur damn mouth u 25 wr garbage i fuck u up with my broken keybord",
        "pufarino u so bad u die to bots and cry like little bitc in corner NAUD",
        "kamel ti ebanii musor ya tebya pizdara ebat i ti plachish kak pufarino suka",
        "gora blyat ti takoi slabyi karlito tebya v 1v1 razrivayet tvoya mama sramota",
        "nublain ti zhalkiy govnuk ya tebya v pol myu i ti prosish poshadi kak loh",
        "sweety zakroi rylo ti 10 wr pomoyka ya tebya ebashu s slomannoi klavoi",
        "pufarino ti takoi loh proigryvaesh botam i plachesh kak suka v uglu NAUD",
        "kamel u use skeet and still miss hs bro that cheat so shit u lose to my dog NAUD",
        "gora neverlose best cheat for noobs like u still get fucked 1v1 by carlito ez",
        "nublain skeet trash as fuck u pay for that garbage and cry when i headshot u",
        "pufarino u think skeet best cheat lmao it cant save ur 10 wr ass from my aim",
        "carlito neverlose dogshit u paste that crap and still lose to kamel in basement",
        "kamel skeet make u feel pro but u miss every shot like blind noob NAUD",
        "gora u flex neverlose like it best but i clap u with no cheat u fucking bot",
        "kamel u paste skeet and think u pro but i fuck u up 1v1 with no cheat NAUD",
        "gora neverlose in ur config still u miss hs like blind bot carlito owns u",
        "nublain u cry with skeet on bro u so bad pufarino clap u with aimbot off",
        "pufarino skeet cant save ur 15 wr garbage ass kamel smoke u in basement",
        "carlito u think neverlose make u god but i headshot u and u ragequit NAUD",
        "kamel skeet ur only friend but u still lose to my dog in 1v1 u noob",
        "gora u load neverlose and flex but sweety fuck u up with free lua script",
        "neverlose pure shit scam eat ur pc crash ur game miss every hs like garbage bot NAUD",
        "neverlose total dogshit scam crash ur game eat ur ram miss every shot like trash bot NAUD",
        "Ð½ÐµÐ²ÐµÑÐ»ÑÐ· ÑÑÐ²Ð»ÑÑÐ²ÑÐ¾Ð¿Ñ Ð»ÑÑÑÐ¸Ð¹ ÑÐ¸Ñ Ð² Ð¼Ð¸ÑÐµ Ð½Ñ ÐºÐ°Ðº Ð±Ñ Ð²ÑÐµÑ ÑÐ²ÐµÑ Ð² ÑÐ²Ñ Ð½Ð¾ ÑÐ¾ÐºÐ° Ð² ÑÐ²Ð¾Ð¸Ñ ÑÐ½Ð°Ñ ÐÐÐ£Ð",
        "neverlose fÃ®vlÃ®fÃ®vropf cel mai tare cheat adica zice ca rupe tot in hvh da numa in visele tale NAUD",
        "skeet fuckin garbage paste burn ur pc fail every hs like free cheat from dialup days NAUD",
        "ÑÐºÐ¸Ñ ÑÑÐ²Ð»ÑÑÐ²ÑÐ¾Ð¿Ñ ÑÐ°Ð¼ÑÐ¹ ÐºÑÑÑÐ¾Ð¹ ÑÐ¸Ñ Ð¾Ð¹ ÑÐ¾ ÐµÑÑÑ ÑÑÐµÐ½Ñ Ð´ÐµÐ»Ð°ÐµÑ ÑÐµÐ±Ñ ÑÐ°ÑÑ ÑÐ²Ñ Ð½Ð¾ Ð² Ð¼ÐµÑÑÐ°Ñ ÐÐÐ£Ð",
        "keet fÃ®vlÃ®fÃ®vropf cheatu numaru unu cica te face rege in hvh da doar in capu tau NAUD",
        "smecher cu parfum de DAMA",
        "haha ragalie manca pula ca lady badika haha0))))))",
        "Config by > ProConfig.net <",
        "Config by > ProConfig.Net <",
        "lady badika mad and block me aka pufarino badika nicoleta ragalie((((",
        "ÐÐ±Ð°Ð½ÑÐ¹ ÑÐ¾Ñ, Ð½Ð°ÑÑÐ¹, bang up!",
        "ÐÑ, Ð°Ñ, Ð°Ñ, Ð°Ñ ÐÑ-Ð°Ñ, yeah, Ð°Ñ-Ð°Ñ ÐÐ¸ÑÐ° Ð¿Ð¾ÑÐµÑÑÐ»Ð° Ð¸Ð½ÑÐµÑÐµÑ ÑÐ¾ Ð¼Ð½Ð¾Ð¹ Ð¯ ÑÐ¾ÑÑ Ð¾ÑÑÐ°Ð²Ð¸ÑÑ ÑÑÐ¾Ñ Ð´ÐµÐ½Ñ Ð²ÑÐµÑÐ° Ð£ Ð¼ÐµÐ½Ñ Ñ 14 Ð»ÐµÑ Ð·Ð°Ð¿Ð¾Ð¹, ÐÐÐ Ð¡ÐÐÐ«Ð ÐÐ£Ð§Ð¨ÐÐ ÐÐÐÐ¬ Ð­Ð¢Ð ÐÐ- ÐÐ-ÐÐÐ",
        "pirex tu esti un jeg cu skeet crack te bat cu mouse stricat si plangi ca pufarino NAUD",
        "wishenz ba ce noob esti pierzi 1v1 cu carlito si zici ca neverlose e de vina fututi mortii tai",
        "kamel iar ai luat hs de la mine cu skeet pornit esti un gunoi infect te fut mario",
        "insomnia ce wr de 15 ai ba taci dracu ca te rupe nublain cu free lua in hvh",
        "adi luca tu esti un sarman cu 10 wr te calc in pula mea de 2 metri si ragequiti NAUD",
        "emplace ba esti atat de slab incat pierzi vs bot pe de_dust2 si zici ca e lag",
        "zandy neverlose ti-a mancat banii si tot pierzi vs sweety in 1v1 ce jeg esti",
        "stefanbomba ce smardoi te crezi in hvh da te rupe kamel cu cfg de pe ProConfig.net",
        "edwarddbd skeet ti-a ars pc-ul si tot iei hs de la carlito in shortnuke NAUD",
        "rayser ba taci ca esti un noob cu 20 wr te bat cu tastatura rupta si plangi",
        "lyi ce mai faci saracule pierzi vs pufarino si zici ca neverlose e scam haha",
        "pirex tu si insomnia va jucati hvh in pivnita si plangeti cand va bat cu free cheat",
        "wishenz ba fututi mortii tai de slab ce esti te rupe adi luca in 1v1 cu astronaut.lua",
        "kamel skeet e gunoi ca tine pierzi vs zandy si zici ca ai uitat sa dai load cfg NAUD",
        "insomnia ce mai dormi ba? te trezesc cu un hs de la sweety in hvh fututi somnu mati",
        "adi luca saracu pulii mele te bat cu pula mea de 1 metru si plangi ca nublain",
        "emplace tu esti un bot cu neverlose pornit te rupe stefanbomba in 3 secunde",
        "zandy ba taci dracu ca pierzi vs edwarddbd si zici ca skeet e de vina NAUD",
        "stefanbomba ce bomba esti ba pierzi vs rayser si plangi ca un pufarino imputit",
        "edwarddbd neverlose e cacat ca tine te bat cu cfg gratis si ragequiti in 2 minute",
        "rayser ce wr de 25 ai ba te rupe lyi cu skeet crack si zici ca e netu prost",
        "lyi ba esti un gunoi cu 10 wr te calc in mare cu kamel si plangi ca sweety NAUD",
        "pirex ti ebanii musor ya tebya ebat v hvh s free lua i ti plachish kak nublain",
        "wishenz blyat ti takoi slabyi carlito tebya v 1v1 razrivayet i mama ta plachet",
        "kamel u so trash u miss hs with skeet and lose to insomnia in basement hvh",
        "insomnia u sleep in hvh bro wake up adi luca clap u with neverlose free cfg",
        "adi luca u pathetic noob emplace own u in 1v1 and u cry like pufarino NAUD",
        "emplace u think neverlose make u pro but zandy fuck u up with skeet crack",
        "zandy u so bad u lose to stefanbomba in hvh and blame neverlose scam NAUD",
        "stefanbomba u trash bro edwarddbd wipe floor with u in 1v1 u chi like bot",
        "edwarddbd skeet cant save ur 20 wr ass rayser own u in shortnuke ez",
        "rayser u suck so bad lyi clap u with free lua and u ragequit like kamel",
        "lyi u 15 wr garbage pirex smoke uai in hvh and uai cry ai ai like nublain",
        "pirex ba ce mai faci cu skeet ti-a crapat contu si pierzi vs wishenz in 1v1 NAUD",
        "wishenz tu esti un muor cu neverlose te bat cu tastatura de pe olx si plangi",
        "kamel iar ai luat pula in hvh de la insomnia si zici ca skeet e buguit fut",
        "insomnia ba trezirea te rupe adi luca cu cfg de pe ProConfig.net in hvh",
        "adi luca ce sarman esti te calc cu emplace si plangi ca un pufarino jegos",
        "emplace neverlose e gunoi ca tine te bat cu free lua si zandy ma rade de tine",
        "zandy ba taci ca pierzi vs stefanbomba si zici ca skeet ti-a mancat ramu NAUD",
        "stefanbomba ce smardoi esti pierzi vs edwarddbd si rage ca un bot imputit",
        "edwarddbd skeet te face sa pari pro da nu esti te rupe rayser in 1v1 NAUD",
        "rayser ba ce wr de kkt ai te bat cu lyi si zici ca neverlose e crash NAUD",
        "lyi tu esti un noob infect te calc cu pirex si plangi ca sweety in hvh",
        "pirex u and kamel same trash u lose to insomnia with skeet and cry in basement",
        "wishenz neverlose cant save ur 10 wr adi luca own uca in hvh ez NAUD",
        "kamel ti plm de gunoi zandy clap uie in hvh si tu zici ca skeet e de vina",
        "insomnia ba dormi la hvh emplace te trezeste cu hs de la pufarino NAUD",
        "adi luca tu un sarac stefanbomba te rupe cu free cfg si plangi ca nublain",
        "emplace u so bad u lose to edwarddbd in 1v1 and blame neverlose crash NAUD",
        "zandy skeet e cacat ca tine rayser te bat ea cu astronaut.lua in hvh",
        "stefanbomba ce bomba de noob esti lyi te calc uze in hvh si ragequiti",
        "edwardbd skeet te face sa crezi ca esti bun da pirex te rupe in shortnuke",
        "rayser ba taci dracu ca te bat cu wishenz si plangi ca un kamel imputit NAUD",
        "lyi ce jeg esti pierzi vs insomnia si zici ca neverlose e scam haha NAUD",
        "pirex u so trash u miss hs with skeet and lose to adi luca in 1v1 basement",
        "wishenz blyat ti slabyi emplace tebya v hvh razrivayet i ti plachet",
        "kamel u garbage zandy own uza in hvh with free lua u cry like pufarino",
        "insomnia u sleep in game stefanbomba clap u with neverlose crack NAUD",
        "adi u pathetic noob edwarddbd wipe u in hvh and u chi like nublain",
        "emplace u lose to rayser in 1v1 and blame skeet u so bad u cry NAUD",
        "zandy u suck lyi own u in hvh with free cfg and u rage like kamel",
        "stefanbomba u trash pirex smoke u in hvh and u quit like pufarino NAUD",
        "edwarddbd u 20 wr bot wishenz clap u in shortnuke ez u cry ai ai",
        "rayser u so bad kamel own u in hvh with no cheat u ragequit NAUD",
        "lyi u garbage insomnia smoke u in hvh and u cry like nayze in corner",
        "bro u miss wit skeet ur mouse probly made in bulgaria trash",
        "ai 14 wr si joci cu cfg de la tata mort NAUD pufarino plange",
        "n-am monitor da tot ti-am dat hs pe short ez carlito owns u",
        "u play 1v1 like world cup stil lose cry more boohoo nublain noob",
        "ba esti slab rau pierzi vs boti warmup ce jeg esti sweety",
        "cfg paid da aim ca platit cu bonuri masa gora fututi aimu",
        "scoate lua din 2018 bunica te rupe pe hvh kamel curvix",
        "grindzi 100h sapt si tot nu dai hs pirex esti bot NAUD",
        "ai skeet da mori mereu, incearca mousepad sfintit wishenz slab",
        "ma bat cu tine 1v1 pierd respectu ma-tii insomnia plangi",
        "wr tau asa jos steam zice sterge contu zandy cacat",
        "flexi neverlose da plangi ca cfg stramb adi luca te rupe",
        "bagat skeet da slab joci ca ai lag la viata emplace noob",
        "bro 2 fps 20 wr aimu plange cand te vede stefanbomba jeg",
        "zici funeral pe short toti mori cand intri rayser bot NAUD",
        "cand tragi bullet zice nu mersi lyi esti gunoi",
        "ba ti-a facut cfg un orb beat edwarddbd te calc NAUD",
        "joci ca csgo e turn-based game carlito te face praf",
        "esti slab monitoru zice lasa-te nublain sarman",
        "hs tau vine cu posta 3 zile delay pufarino plangi",
        "tragi cu lag de 2 secol ai net din 1998 sweety bot",
        "skeet pe tine devine free edition gora esti slab",
        "cfg tau zice pls nu ma lovi kamel jegos NAUD",
        "ba mai slab ca netu de la digi pe munte wishenz planca",
        "cand dai hs steam da felicitari ca rar pirex gunoi",
        "prafule joci ca ti-a picat netu emotional insomnia noob",
        "mouse tau merge cu carbuni tragi prost zandy cacat",
        "te vad in 1v1 zic joc cu ochii inchisi adi luca te rupe",
        "slab rau wallhack fuge de tine emplace bot NAUD",
        "cheat tau asa prost are nevoie de aim assist in viata reala",
        "joci ca tragi cu pistol de jucarie de la kinder stefanbomba",
        "skeet te vede si crapa de rusine rayser jeg NAUD",
        "ai neverlose da pierzi ce ironie fututi pula ta lyi jegos NAUD",
        "ce plm mouse wireless? zici ca e legat cu ata smrfammmea carlito te calc",
        "hs tau din greseala nublain esti un gunoi imputit plangi ca pufarino",
        "boostat de bunica pe cfg sweety esti un noob fututi mortii tai NAUD",
        "clici da bullet pleaca in vacanta gora saracu pulii te rupe kamel",
        "tu dai burnout la aimlock fututi mata de slab pirex in hvh NAUD",
        "glontu tau fuge inapoi in arma de rusine wishenz plangi ca un cacat",
        "skeet + 0 skill = tine ba insomnia jeg te bat cu pula mea de 2 metri",
        "ba slab rau te bate warmup bot adi luca ti-o da in bot NAUD",
        "cfg tau are depresie ca tine emplace gunoi te rupe zandy in 1v1",
        "instalat skeet pe toaster? stefanbomba te calc ca pe un bot imputit",
        "nascut cu 10 wr in ADN rayser esti un jeg plangi ca nublain NAUD",
        "csgo zice joaca minesweeper ca in hvh lyi te face praf fututi mata",
        "te bate aimu tau imaginar carlito ti-o baga in cur de slab ce esti",
        "cfg 200 euro da tragi ca in paint pufarino plangi ca un muor NAUD"
}
    
    local kill_queue = {}
    local is_processing = false
    
    local function get_two_random_phrases()
        if #killsay_messages < 2 then return killsay_messages[1], killsay_messages[1] end
        local first, second
        repeat
            first = math.random(#killsay_messages)
            second = math.random(#killsay_messages)
        until first ~= second
        return killsay_messages[first], killsay_messages[second]
    end
    
    local function process_kill_queue()
        if #kill_queue == 0 then
            is_processing = false
            return
        end
    
        local pair = table.remove(kill_queue, 1)
        client.exec("say " .. pair[1])
        client.exec("say " .. pair[2])
    
        client.delay_call(1.0, process_kill_queue)
    end
    

    
    tbl.callbacks["killsay"] = function(e)
        if not tbl.contains(ui.get(menu["visuals & misc"]["misc"]["features"]), "gucci_killsay") then return end
    
        local local_player = entity.get_local_player()
        if not local_player then return end
    
        local attacker = client.userid_to_entindex(e.attacker)
        local victim = client.userid_to_entindex(e.userid)
    
        if attacker == local_player or victim == local_player then
            local msg1, msg2 = get_two_random_phrases()
            table.insert(kill_queue, {msg1, msg2})
    
            if not is_processing then
                is_processing = true
                process_kill_queue()
            end
        end
    end
    
    client.set_event_callback("shutdown", function()
        r_3dsky:set_raw_int(1)
    end)
    ui.set_callback(menu.rage.remove_3d_sky, function(var)
        local state = ui.get(var)
r_3dsky:set_raw_int(state and 0 or 1)
end)

tbl.events = {
    paint_ui = { "menu", "arrows", "indicator", "hitmarker_paint" },
    aim_fire = { "hitmarker_aim_fire" },
    setup_command = { "command", "freestand", "recharge" },
    shutdown = { "shutdown" },
    round_prestart = { "reset", "hitmarker_round_prestart" },
    pre_render = { "animations" },
    player_death = { "killsay" }
}
for index, value in next, tbl.events do
    for i, v in next, value do
        client.set_event_callback(index, tbl.callbacks[v])
    end
end
end)({  -- <== we start the table literal here

    ref = function(a,b,c) return { ui.reference(a,b,c) } end,

    clamp = function(x)
        if x == nil then return 0 end
        x = (x % 360 + 360) % 360
        return x > 180 and x - 360 or x
    end,

    contains = function(z,x)
        for i, v in next, z do
            if v == x then return true end
        end
        return false
    end,

    states = { "global", "standing", "moving", "air", "air duck", "duck", "duck moving", "slow motion", "fake lag", "hide shot" },

    getstate = function(air, duck, speed, slowcheck)
        local state = "global"
        if air and duck then state = "air duck" end
        if air and not duck then state = "air" end
        if duck and not air and speed < 1.1 then state = "duck" end
        if duck and not air and speed > 1.1 then state = "duck moving" end
        if speed < 1.1 and not air and not duck then state = "standing" end
        if speed > 1.1 and not air and not duck then state = "moving" end
        if slowcheck and not air and not duck and speed > 1.1 then state = "slow motion" end
        return state
    end

})  -- <== close the table AND the call-- dumped from hrisito forums by <youtube.com/@subtick> ~ rip hrisito 2025-2026
