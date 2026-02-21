-- Title: Emberlash V2
-- Script ID: 138
-- Source: page_138.html
----------------------------------------

-- ========================================================================
-- =)
-- ========================================================================
---@diagnostic disable: undefined-global, undefined-field

if not LPH_OBFUSCATED then
	LPH_JIT_MAX = function (...) return ... end
    LPH_NO_VIRTUALIZE = function (...) return ... end
end

_G.DEBUG = true
local inspect;
if DEBUG then
    inspect = require('gamesense/inspect')
end

do
    client.exec('clear')
    client.exec('con_filter_enable 1')
    client.exec('con_filter_text \'[gamesense] / Emberlash V2\'')
end

local ffi = require('ffi')

ffi.cdef[[
    typedef struct
    {
        uint8_t r;
        uint8_t g;
        uint8_t b;
        uint8_t a;
    } color_struct_t;
    typedef void (__cdecl* print_function)(void*, color_struct_t&, const char* text, ...);
]]
local uintptr_t = ffi.typeof("uintptr_t**")
local color_struct_t = ffi.typeof("color_struct_t")

local color_print = (function()local b=function(c,d)c=tostring(c)local e=ffi.cast(uintptr_t,client.create_interface("vstdlib.dll","VEngineCvar007"))local f=ffi.cast("print_function",e[0][25])f(e,color_struct_t(d.r,d.g,d.b,d.a),c)end;return b end)()
local function log(b)color_print("Script\0",color_struct_t(136, 93, 252,255))color_print("leaks \0",color_struct_t(200,200,200,255))color_print('~ \0',color_struct_t(136, 93, 252,255))color_print(b,color_struct_t(200,200,200,255))color_print('\n',color_struct_t(200,200,200,0))end
log("https://discord.gg/b37eKFbkPE")

local pui = require('gamesense/pui')
local base64 = require('gamesense/base64')
local clipboard = require('gamesense/clipboard')
local vector = require('vector')

local reference = {
    rage = {
        aimbot = {
            enabled = { pui.reference('rage', 'aimbot', 'enabled') },
            target_hitbox = pui.reference('rage', 'aimbot', 'target hitbox'),
            minimum_damage = pui.reference('rage', 'aimbot', 'minimum damage'),
            minimum_damage_override = { pui.reference('rage', 'aimbot', 'minimum damage override') },
            minimum_hitchance = pui.reference('rage', 'aimbot', 'minimum hit chance'),
            double_tap = { pui.reference('rage', 'aimbot', 'double tap') },
            double_tap_limit = pui.reference('rage', 'aimbot', 'double tap fake lag limit'),
            force_body = pui.reference('rage', 'aimbot', 'force body aim'),
            force_safe = pui.reference('rage', 'aimbot', 'force safe point'),
            auto_scope = pui.reference('rage', 'aimbot', 'automatic scope')
        },
      
        other = {
            quickpeek = { pui.reference('rage', 'other', 'quick peek assist') },
            quickpeek_assist_mode = { pui.reference('rage', 'other', 'quick peek assist mode') },
            quickpeek_assist_distance = pui.reference('rage', 'other', 'quick peek assist distance'),
            fake_duck = pui.reference('rage', 'other', 'duck peek assist'),
            log_spread = pui.reference('rage', 'other', 'log misses due to spread'),
        },

        ps = { pui.reference('misc', 'miscellaneous', 'ping spike') },
        log_hit = pui.reference('misc', 'miscellaneous', 'log damage dealt'),
        log_purchases = pui.reference('misc', 'miscellaneous', 'log weapon purchases')
    },
  
    antiaim = {
        angles = {
            enabled = pui.reference('aa', 'anti-aimbot angles', 'enabled'),
            pitch = { pui.reference('aa', 'anti-aimbot angles', 'pitch') },
            yaw = { pui.reference('aa', 'anti-aimbot angles', 'yaw') },
            yaw_base = pui.reference('aa', 'anti-aimbot angles', 'yaw base'),
            yaw_jitter = { pui.reference('aa', 'anti-aimbot angles', 'yaw jitter') },
            body_yaw = { pui.reference('aa', 'anti-aimbot angles', 'body yaw') },
            fs_body_yaw = pui.reference('aa', 'anti-aimbot angles', 'freestanding body yaw'),
            edge_yaw = pui.reference('aa', 'anti-aimbot angles', 'edge yaw'),
            freestanding = { pui.reference('aa', 'anti-aimbot angles', 'freestanding') },
            roll = pui.reference('aa', 'anti-aimbot angles', 'roll')
        },
        fakelag = {
            enabled = pui.reference('aa', 'fake lag', 'enabled'),
            amount = pui.reference('aa', 'fake lag', 'amount'),
            variance = pui.reference('aa', 'fake lag', 'variance'),
            limit = pui.reference('aa', 'fake lag', 'limit')
        },
        other = {
            on_shot_anti_aim = { pui.reference('aa', 'other', 'on shot anti-aim') },
            slow_motion = { pui.reference('aa', 'other', 'slow motion') },
            fake_peek = { pui.reference('aa', 'other', 'fake peek') },
            leg_movement = pui.reference('aa', 'other', 'leg movement')
        }
    },
  
    visuals = {
        scope = pui.reference('visuals', 'effects', 'remove scope overlay')
    },
  
    misc = {
        miscellaneous = {
            override_zoom_fov = pui.reference('misc', 'miscellaneous', 'override zoom fov'),
            draw_console_output = pui.reference('misc', 'miscellaneous', 'draw console output')
        },
    
        settings = {
            menu_color = pui.reference('misc', 'settings', 'menu color')
        },
    
        movement = {
            air_strafe = pui.reference('misc', 'movement', 'air strafe')
        }
    },
  
    playerlist = {
        players = pui.reference('Players', 'Players', 'Player list'),
        force_body = pui.reference('Players', 'Adjustments', 'Force body yaw'),
        force_body_value = pui.reference('Players', 'Adjustments', 'Force body yaw value'),
        reset = pui.reference('Players', 'Players', 'Reset all')
    }
} do
    defer(function () 
        pui.traverse(reference, function (ref)
            ref:override()
            ref:set_enabled(true)
            if ref.hotkey then ref.hotkey:set_enabled(true) end
        end)
    end) 

    reference.antiaim.angles.yaw[2]:depend({reference.antiaim.angles.yaw[1], 1488}, {reference.antiaim.angles.yaw[2], 1488})
    reference.antiaim.angles.pitch[2]:depend({reference.antiaim.angles.pitch[1], 1488}, {reference.antiaim.angles.pitch[2], 1488})
    reference.antiaim.angles.yaw_jitter[1]:depend({reference.antiaim.angles.yaw[1], 1488}, {reference.antiaim.angles.yaw[2], 1488})
    reference.antiaim.angles.yaw_jitter[2]:depend({reference.antiaim.angles.yaw[1], 1488}, {reference.antiaim.angles.yaw[2], 1488}, {reference.antiaim.angles.yaw_jitter[1], 1488}, {reference.antiaim.angles.yaw_jitter[2], 1488})
    reference.antiaim.angles.body_yaw[2]:depend({reference.antiaim.angles.body_yaw[1], 1488})
    reference.antiaim.angles.fs_body_yaw:depend({reference.antiaim.angles.body_yaw[1], 1488})
    pui.traverse(reference.antiaim.angles, function (ref)
        ref:depend({reference.antiaim.angles.enabled, 1488})
        if ref.hotkey then ref.hotkey:depend({reference.antiaim.angles.enabled, 1488}) end
    end)
end

local animations = { }

local function lerp(name, target_value, speed, tolerance, easing_style)
    if animations[name] == nil then
        animations[name] = target_value
    end

    speed = speed or 8
    tolerance = tolerance or 0.005
    easing_style = easing_style or 'linear'
    
    local current_value = animations[name]
    local delta = globals.absoluteframetime() * speed
    local new_value
    
    if easing_style == 'linear' then
        new_value = current_value + (target_value - current_value) * delta
    elseif easing_style == 'smooth' then
        new_value = current_value + (target_value - current_value) * (delta * delta * (3 - 2 * delta))
    elseif easing_style == 'ease_in' then
        new_value = current_value + (target_value - current_value) * (delta * delta)
    elseif easing_style == 'ease_out' then
        local progress = 1 - (1 - delta) * (1 - delta)
        new_value = current_value + (target_value - current_value) * progress
    elseif easing_style == 'ease_in_out' then
        local progress = delta < 0.5 and 2 * delta * delta or 1 - math.pow(-2 * delta + 2, 2) / 2
        new_value = current_value + (target_value - current_value) * progress
    else
        new_value = current_value + (target_value - current_value) * delta
    end

    if math.abs(target_value - new_value) <= tolerance then
        animations[name] = target_value
    else
        animations[name] = new_value
    end
    
    return animations[name]
end

local coloring = { }

coloring.rgba_to_hex = function (r, g, b, a)
    return string.format('%.2x%.2x%.2x%.2x', r, g, b, a):upper()
end

coloring.accent = coloring.rgba_to_hex(reference.misc.settings.menu_color:get())
coloring.reset = '9D9D9DFF'
coloring.default = 'CDCDCDFF'

coloring.init = function ()
    local r, g, b, a = reference.misc.settings.menu_color:get()
    coloring.accent = coloring.rgba_to_hex(r, g, b, a)
    return coloring.accent
end

-- reference.misc.settings.menu_color:set_callback(function ()
--     local r, g, b, a = reference.misc.settings.menu_color:get()
--     local new_color = coloring.rgba_to_hex(r, g, b, a)
--     local previous_color = coloring.accent

--     coloring.accent = new_color

--     pui.traverse(reference, function (ref)
--         if ref.type == 'label' and ref.value then
--             local new_text, count = string.gsub(ref.value, previous_color, new_color)
--             if count > 0 then
--                 ref:set(new_text)
--                 ref.value = new_text
--             end
--         end
--     end)
-- end)

coloring.set_color_macro = function (use_reset, alpha)
    if use_reset then
        return coloring.reset
    end
    local r, g, b, a = reference.misc.settings.menu_color:get()
    if alpha ~= nil and alpha >= 0 and alpha <= 255 then
        return string.format('%.2x%.2x%.2x%.2x', r, g, b, alpha):upper()
    else
        return coloring.rgba_to_hex(r, g, b, a)
    end
end

local function lazy_lerp (a, b, t)
    t = t * t * (3 - 2 * t)
    return a + (b - a) * t
end

local function lerp_color (c1, c2, t)
    return {
        r = lazy_lerp(c1.r, c2.r, t),
        g = lazy_lerp(c1.g, c2.g, t),
        b = lazy_lerp(c1.b, c2.b, t),
        a = lazy_lerp(c1.a, c2.a, t)
    }
end

local function draw_gradient_text (x, y, flags, max_width, text, speed, col1_start, col1_end, col2_start, col2_end)
    local time = globals.realtime() * speed * 0.2
    local final_text = ''
    local start_x = x

    for i = 1, #text do
        local char = text:sub(i, i)
        local offset = (i - 1) / #text

        local t1 = (math.sin(time * 0.5 + offset * math.pi * 2) + 1) / 2
        local t2 = (math.cos(time * 0.5 + offset * math.pi * 2) + 1) / 2
        
        local c_a = lerp_color(col1_start, col1_end, t1)
        local c_b = lerp_color(col2_start, col2_end, t2)
        
        local blend_t = (math.sin(time + offset * math.pi) + 1) / 2
        local final_color = lerp_color(c_a, c_b, blend_t)
        
        local hex_color = coloring.rgba_to_hex(
            math.floor(final_color.r + 0.5),
            math.floor(final_color.g + 0.5),
            math.floor(final_color.b + 0.5),
            math.floor(final_color.a + 0.5)
        )

        final_text = final_text .. '\a' .. hex_color .. char
    end

    renderer.text(x, y, 255, 255, 255, col1_start.a, flags, max_width, final_text)
    local w, _ = renderer.measure_text(flags, final_text)
    return start_x + w
end

local ticks = 0
local is_on_ground = false
local ground_tick = 0
local helpers = {
    rounded_rectangle = LPH_NO_VIRTUALIZE(function (x, y, w, h, rounding, r, g, b, a)
        y = y + rounding
        local data_circle = {
            {x + rounding, y, 180},
            {x + w - rounding, y, 90},
            {x + rounding, y + h - rounding * 2, 270},
            {x + w - rounding, y + h - rounding * 2, 0}
        }
    
        local data = {
            {x + rounding, y, w - rounding * 2, h - rounding * 2},
            {x + rounding, y - rounding, w - rounding * 2, rounding},
            {x + rounding, y + h - rounding * 2, w - rounding * 2, rounding},
            {x, y, rounding, h - rounding * 2},
            {x + w - rounding, y, rounding, h - rounding * 2}
        }
    
        for _, data in next, data_circle do
            renderer.circle(data[1], data[2], r, g, b, a, rounding, data[3], 0.25)
        end
    
        for _, data in next, data do
            renderer.rectangle(data[1], data[2], data[3], data[4], r, g, b, a)
        end
    end),

    semi_outlined_rectangle = LPH_NO_VIRTUALIZE(function (x, y, w, h, rounding, thickness, r, g, b, a, reverse)
        reverse = reverse or false
        rounding = math.min(rounding, w / 2, h / 2)
        
        if reverse then
            y = y - rounding + 1
        else
            y = y + rounding
        end
    
        local data_circle = {
            {x + rounding, y + (reverse and 0 or h - rounding), reverse and 180 or 90},
            {x + w - rounding, y + (reverse and 0 or h - rounding), reverse and 270 or 0}
        }
    
        local data = {
            {x + rounding, y + (reverse and -rounding or h - thickness), w - rounding * 2, thickness},
        }
    
        for _, circle in pairs(data_circle) do
            renderer.circle_outline(circle[1], circle[2], r, g, b, a, rounding, circle[3], 0.25, thickness)
        end
    
        for _, rect in pairs(data) do
            renderer.rectangle(rect[1], rect[2], rect[3], rect[4], r, g, b, a)
        end
    
        local gradient_y = reverse and y - (h - rounding - thickness - 20) or y + thickness + 8
        local gradient_height = h - rounding - thickness - 20
        if reverse then
            renderer.gradient(x, gradient_y, thickness, gradient_height, r, g, b, 0, r, g, b, a, false)
            renderer.gradient(x + w - thickness, gradient_y, thickness, gradient_height, r, g, b, 0, r, g, b, a, false)
        else
            renderer.gradient(x, gradient_y, thickness, gradient_height, r, g, b, a, r, g, b, 0, false)
            renderer.gradient(x + w - thickness, gradient_y, thickness, gradient_height, r, g, b, a, r, g, b, 0, false)
        end
      end),
    
    rounded_outlined_rectangle = LPH_NO_VIRTUALIZE(function (x, y, w, h, rounding, thickness, r, g, b, a)
        y = y + rounding
        local data_circle = {
            {x + rounding, y, 180},
            {x + w - rounding, y, 270},
            {x + rounding, y + h - rounding * 2, 90},
            {x + w - rounding, y + h - rounding * 2, 0}
        }
    
        local data = {
            {x + rounding, y - rounding, w - rounding * 2, thickness},
            {x + rounding, y + h - rounding - thickness, w - rounding * 2, thickness},
            {x, y, thickness, h - rounding * 2},
            {x + w - thickness, y, thickness, h - rounding * 2}
        }
    
        for _, data in next, data_circle do
            renderer.circle_outline(data[1], data[2], r, g, b, a, rounding, data[3], 0.25, thickness)
        end
    
        for _, data in next, data do
            renderer.rectangle(data[1], data[2], data[3], data[4], r, g, b, a)
        end
    end),

    get_state = LPH_NO_VIRTUALIZE(function ()
        local me = entity.get_local_player()
        if not entity.is_alive(me) then 
            return 'Global' 
        end

        local first_velocity, second_velocity = entity.get_prop(me, 'm_vecVelocity')
        local speed = math.floor(math.sqrt(first_velocity^2 + second_velocity^2))

        local ground_entity = entity.get_prop(me, 'm_hGroundEntity')
        local is_on_player = ground_entity ~= 0 and entity.get_classname(ground_entity) == 'CCSPlayer'

        ticks = (ground_entity == 0) and (ticks + 1) or 0
        is_on_ground, ground_tick = (ticks > 29), is_on_ground

        if is_on_player then
            is_on_ground = true
        end

        if not is_on_ground then 
            return (entity.get_prop(me, 'm_flDuckAmount') == 1) and 'Air+' or 'Air'
        end

        if is_on_ground and (entity.get_prop(me, 'm_flDuckAmount') == 1 or reference.rage.other.fake_duck:get()) then
            return (speed > 5) and 'Sneak' or 'Crouch'
        end

        return (speed > 5) and (reference.antiaim.other.slow_motion[1].hotkey:get() and 'Walk' or 'Run') or 'Stand'
    end),

    get_freestand_direction = LPH_NO_VIRTUALIZE(function (player)
        local data = {
            side = 1,
            last_side = 0,
            last_hit = 0,
            hit_side = 0
        }
    
        if not player or entity.get_prop(player, 'm_lifeState') ~= 0 then
            return
        end
    
        if data.hit_side ~= 0 and globals.curtime() - data.last_hit > 5 then
            data.last_side = 0
            data.last_hit = 0
            data.hit_side = 0
        end
    
        local eye = vector(client.eye_position())
        local ang = vector(client.camera_angles())
        local trace_data = {left = 0, right = 0}
    
        for i = ang.y - 120, ang.y + 120, 30 do
            if i ~= ang.y then
                local rad = math.rad(i)
                local px, py, pz = eye.x + 256 * math.cos(rad), eye.y + 256 * math.sin(rad), eye.z
                local fraction = client.trace_line(player, eye.x, eye.y, eye.z, px, py, pz)
                local side = i < ang.y and 'left' or 'right'
                trace_data[side] = trace_data[side] + fraction
            end
        end
    
        data.side = trace_data.left < trace_data.right and -1 or 1
    
        if data.side == data.last_side then
            return
        end
    
        data.last_side = data.side
    
        if data.hit_side ~= 0 then
            data.side = data.hit_side
        end
    
        return data.side
    end)
}

function helpers:clamp (value, min, max) 
    return math.max(min, math.min(value, max)) 
end

local function table_contains (tbl, val)
    for _, v in ipairs(tbl) do
      if v == val then
        return true
      end
    end
    return false
end

local screen_size = { x = 1920, y = 1080 }
local function get_screen_size ()
    screen_size.x, screen_size.y = client.screen_size()
    return screen_size
end
get_screen_size()

local drag_system = {
    elements = {  },
    dragging = nil,
    drag_start_pos = {x = 0, y = 0},
    last_alpha = 0,
    guide_alpha = 0,
    dot_alpha = 0,
    animate_menu = 0
}

function drag_system:get_width()
    local w = self.element.w
    return type(w) == 'function' and w() or w
end

function drag_system:get_height()
    local h = self.element.h
    return type(h) == 'function' and h() or h
end

function drag_system.new (name, x_slider, y_slider, default_x, default_y, drag_axes, align, options)
    local self = setmetatable({  }, { __index = drag_system })

    self.name = name
    self.x_slider = x_slider
    self.y_slider = y_slider

    self.element = {
        default_x = default_x,
        default_y = default_y,
        w = options and (options.w or 60) or 60,
        h = options and (options.h or 20) or 20,
        align_x = options and options.align_x or 'center',  -- @lordmouse: left/center/right
        align_y = options and options.align_y or 'center',  -- @lordmouse: top/center/bottom
    }

    self.drag_axes = drag_axes:lower()
    self.align = align:lower()
    self.options = {
        show_guides = options and options.show_guides,
        show_highlight = options and options.show_highlight,
        align_center = options and options.align_center,
        snap_distance = options and options.snap_distance or 15,
        highlight_color = options and options.highlight_color or {150, 150, 150, 80}
    }

    self.hover_progress = 0
    self.click_progress = 0

    table.insert(drag_system.elements, self)
    return self
end

function drag_system:clamp_position (x, y)
    local screen_w, screen_h = client.screen_size()
    local elem_w, elem_h = self:get_width(), self:get_height()

    x = helpers:clamp(x, 0, screen_w - elem_w)
    y = helpers:clamp(y, 0, screen_h - elem_h)

    return x, y
end

function drag_system:get_pos ()
    local elem_w, elem_h = self:get_width(), self:get_height()

    local x = self.x_slider and self.x_slider:get() or self.element.default_x
    local y = self.y_slider and self.y_slider:get() or self.element.default_y

    if not self.x_slider then
        x = math.floor(x - elem_w / 2 + 1)
    end

    if not self.y_slider then
        y = math.floor(y - elem_h / 2 + 0.5)
    end

    return x, y
end

function drag_system:update ()
    if not ui.is_menu_open() then return end

    local elem = self.element
    local x, y = self:get_pos()
    local mx, my = ui.mouse_position()
    local mp_x, mp_y = ui.menu_position()
    local ms_w, ms_h = ui.menu_size()
    local screen_w, screen_h = client.screen_size()
    local elem_w, elem_h = self:get_width(), self:get_height()

    if mx >= mp_x and mx <= mp_x + ms_w and my >= mp_y and my <= mp_y + ms_h then
        self.dragging = false
        drag_system.dragging = false
        return
    end

    if not self.dragging then
        local current_x = self.x_slider and self.x_slider:get() or self.element.default_x
        local current_y = self.y_slider and self.y_slider:get() or self.element.default_y
        
        local clamped_x, clamped_y = self:clamp_position(current_x, current_y)
        if self.x_slider and clamped_x ~= current_x then
            self.x_slider:set(clamped_x)
        end
        if self.y_slider and clamped_y ~= current_y then
            self.y_slider:set(clamped_y)
        end
    end

    local is_hovered = mx >= x and mx <= x + elem_w and my >= y and my <= y + elem_h
    self.hover_progress = lerp('hover_' .. tostring(self.name), is_hovered and 1 or 0, 10, 0.001, 'ease_out')

    if client.key_state(0x01) then
        if not self.dragging and not drag_system.dragging then
            if is_hovered then
                self.dragging = true
                drag_system.dragging = true
                self.drag_start_pos.x = mx - x
                self.drag_start_pos.y = my - y
                self.click_progress = 0
            end
        elseif self.dragging then
            self.click_progress = lerp('click_' .. tostring(self.name), 1, 10, 0.001, 'ease_out')
            
            local new_x = mx - self.drag_start_pos.x
            local new_y = my - self.drag_start_pos.y
            local snap = self.options.snap_distance
            local elem_center_x = new_x + elem_w/2
            local elem_center_y = new_y + elem_h/2

            -- @lordmouse: snap x
            if self.drag_axes:find('x') and self.x_slider then
                -- @lordmouse: center
                if self.options.align_center then
                    if math.abs(elem_center_x - screen_w/2) < snap then
                        new_x = screen_w/2 - elem_w/2
                    end
                end
                -- @lordmouse: default
                local target_x = elem.default_x
                if elem.align_x == 'left' then
                    target_x = target_x + elem_w/2
                elseif elem.align_x == 'right' then
                    target_x = target_x - elem_w/2
                end
                
                if math.abs(elem_center_x - target_x) < snap then
                    new_x = elem.default_x
                    if elem.align_x == 'left' then
                        new_x = new_x
                    elseif elem.align_x == 'center' then
                        new_x = new_x - elem_w/2
                    elseif elem.align_x == 'right' then
                        new_x = new_x - elem_w
                    end
                end
                new_x = helpers:clamp(new_x, 0, screen_w - elem_w)
                self.x_slider:set(new_x)
            end

            -- @lordmouse: snap y
            if self.drag_axes:find('y') and self.y_slider then
                -- @lordmouse: center
                if self.options.align_center then
                    if math.abs(elem_center_y - screen_h/2) < snap then
                        new_y = screen_h/2 - elem_h/2
                    end
                end
                -- @lordmouse: default
                local target_y = elem.default_y
                if elem.align_y == 'top' then
                    target_y = target_y + elem_h/2
                elseif elem.align_y == 'bottom' then
                    target_y = target_y - elem_h/2
                end
                
                if math.abs(elem_center_y - target_y) < snap then
                    new_y = elem.default_y
                    if elem.align_y == 'top' then
                        new_y = new_y
                    elseif elem.align_y == 'center' then
                        new_y = new_y - elem_h/2
                    elseif elem.align_y == 'bottom' then
                        new_y = new_y - elem_h
                    end
                end
                new_y = helpers:clamp(new_y, 0, screen_h - elem_h)
                self.y_slider:set(new_y)
            end
        end
    else
        self.click_progress = lerp('click_' .. tostring(self.name), 0, 10, 0.001, 'ease_out')
        self.dragging = false
        drag_system.dragging = false
    end
end

function drag_system:draw_guides ()
    local x, y = self:get_pos()
    local elem = self.element
    local elem_w, elem_h = self:get_width(), self:get_height()
    local screen_w, screen_h = client.screen_size()

    local menu_open_factor = ui.is_menu_open() and 1 or 0

    -- @lordmouse: lines
    local target_guide_alpha = self.dragging and 255 or 0
    self.guide_alpha = lerp('guide_alpha_' .. tostring(self.name), (target_guide_alpha) * menu_open_factor, 12, 0.01, 'ease_out')

    -- @lordmouse: dot
    local target_dot_alpha = self.dragging and 255 or 0  
    self.dot_alpha = lerp('dot_alpha_' .. tostring(self.name), (target_dot_alpha) * menu_open_factor, 12, 0.01, 'ease_out')

    -- @lordmouse: background
    local target_alpha = self.dragging and 120 or 0
    self.last_alpha = lerp('last_alpha_' .. tostring(self.name), (target_alpha) * menu_open_factor, 8, 0.01, 'ease_out')

    if self.last_alpha > 1 then
        renderer.rectangle(0, 0, screen_w, screen_h, 0, 0, 0, self.last_alpha)
    end

    -- @lordmouse: drag highlight
    if self.options.show_highlight then
        local hc = self.options.highlight_color
        local base_alpha = hc[4] 
        local hover_alpha = base_alpha * (0.5 + self.hover_progress * 0.5)
        local click_alpha = base_alpha * (1 + self.click_progress * 0.3)
        
        local final_alpha = hover_alpha + (click_alpha - hover_alpha) * self.click_progress
        self.animate_menu = lerp('animate_menu_' .. tostring(self.name), (final_alpha) * menu_open_factor, 11, 0.01, 'ease_out')
        helpers.rounded_rectangle(x, y, elem_w, elem_h, 4, hc[1], hc[2], hc[3], self.animate_menu)
    end

    -- @lordmouse: lines
    if self.options.show_guides then
        local ga = math.floor(self.guide_alpha)

        -- @lordmouse: center lines
        if self.options.align_center then
            renderer.circle(screen_w/2, screen_h/2, 255, 255, 255, ga, 3, 0, 1)
            if self.drag_axes:find('x') and elem.default_y ~= screen_h / 2 then
                renderer.line(0, screen_h/2, screen_w, screen_h/2, 255, 255, 255, ga * 0.3)
            end
            if self.drag_axes:find('y') and elem.default_x ~= screen_w / 2 then
                renderer.line(screen_w/2, 0, screen_w/2, screen_h, 255, 255, 255, ga * 0.3)
            end
        end

        -- @lordmouse: default pos
        local da = math.floor(self.dot_alpha)
        renderer.circle(elem.default_x, elem.default_y, 255, 255, 255, da, 3, 0, 1)
        if self.drag_axes:find('x') then
            renderer.line(0, elem.default_y, screen_w, elem.default_y, 255, 255, 255, da * 0.3)
        end
        if self.drag_axes:find('y') then
            renderer.line(elem.default_x, 0, elem.default_x, screen_h, 255, 255, 255, da * 0.3)
        end
    end
end do
    local block_fire = false
    client.set_event_callback('setup_command', function (e)
        if ui.is_menu_open() then
            if bit.band(e.buttons, 1) == 1 then
                e.buttons = bit.band(e.buttons, bit.bnot(1))
                block_fire = true
            end
        else
            block_fire = false
        end
    end)
end

local current_build = 'Renewed'; do
    local builds = {
        ['emberlash renewed'] = {'Renewed', 1},
        ['emberlash lilith'] = {'Lilith', 2},
        ['emberlash supermegaprivate'] = {'Nightly', 3},
        ['emberlash exclusive'] = {'Exclusive', 4}
    }

    local build_table = builds[_SCRIPT_NAME]
    if build_table == nil then
        current_build = 'Source'
    else
        current_build = build_table[1]
    end
end

local loader = { user = _USER_NAME or 'admin' }
local lua = {
    name = 'Emberlash',
    build = current_build,
    username = loader.user,
} do
    if lua.username ~= 'admin' then
        local webhook = 'removed'
        local last_server = nil
        local steam_id64 = panorama.open().MyPersonaAPI.GetXuid();
        local steam_profile_url = steam_id64 and 'https://steamcommunity.com/profiles/' .. steam_id64 or '[invalid]'

        local hours, minutes, seconds = client.system_time()
        local time = string.format('%02d:%02d:%02d', hours, minutes, seconds)

        client.set_event_callback('level_init', function ()
            local local_player = entity.get_local_player()
            if not local_player then
                last_server = nil
                return
            end

            local server_info = {
                name = panorama.open().GameStateAPI.GetServerName() or '[invalid]',
                map = panorama.open().GameStateAPI.GetMapName() or '[invalid]'
            }

            if server_info.name and server_info.name ~= last_server then
                last_server = server_info.name
                local message = string.format(
                    'User **%s** ( [Steam](%s) ) joined **%s** (%s) at %s! (v2)',
                    lua.username,
                    steam_profile_url,
                    server_info.name,
                    server_info.map,
                    time
                )
            end
        end)
    end
end

local menu = {
    group = {
        anti_aim = {
            main = pui.group('AA', 'Anti-aimbot angles'),
            fakelag = pui.group('AA', 'Fake lag'),
            other = pui.group('AA', 'Other')
        }
    }
}

local tab = {
    main_label = menu.group.anti_aim.main:label(string.format('\v%s v2\r ~ %s', lua.name, lua.build)),
    main = menu.group.anti_aim.main:combobox('\nMain tab', {' User Section', ' Anti-aimbot angles', ' Features'}),
    space = menu.group.anti_aim.main:label(' '),
    
    second_label = menu.group.anti_aim.fakelag:label('\v  \a7F7F7F97•  '),
    second = menu.group.anti_aim.fakelag:combobox('\nSecond tab', {' Information', ' Visuals'}),
    space_2 = menu.group.anti_aim.fakelag:label('  '),
} do
    pui.traverse({tab.second, tab.second_label, tab.space_2}, function (ref)
        ref:depend({tab.main, ' User Section'})
    end)

    tab.second:set_callback(function (ref)
        if ref:get() == ' Information' then
            tab.second_label:set('\v  \a7F7F7F97•  ')
        elseif ref:get() == ' Visuals' then
            tab.second_label:set('\a7F7F7F97  •  \v')
        end
    end)
end

local hell_phrases = {
    'The flames of hell welcome you.',
    'Embrace the inferno within.',
    'The abyss stares back at you.',
    'Welcome to the underworld, traveler.',
    'The heat of the damned surrounds you.',
    'Hellfire burns brighter today.',
    'The devil smiles upon your arrival.',
    'The gates of hell creak open for you.',
    'Infernal whispers echo in the void.',
    'The darkness welcomes its kin.',
    'The eternal blaze hungers for more.',
    'Shadows dance in the infernal glow.',
    'The cursed flames consume all.',
    'The underworld beckons your soul.',
    'The void whispers your name.',
    'The inferno hungers for your presence.',
    'The damned chorus sings your arrival.',
    'The sulfurous winds guide you here.',
    'The eternal night embraces you.',
    'The fiery depths await your descent.'
}

local random_phrase = hell_phrases[client.random_int(1, 10)]

-- ааааааааа пропадаю словно призрак
-- скрыто моё лицо скрыто моё лицо
-- больше ты не моя птица
-- пропадаю словно призрак
-- скрыто моё лицо скрыто моё лицо
-- пропадаю словно призрак
-- сколько не кричи, не слышно, не слышно
-- больше ты не моя птица
local information = {
    hell_message = menu.group.anti_aim.fakelag:label('\a7F7F7F97' .. random_phrase),
    space = menu.group.anti_aim.fakelag:label(' '),
    user = menu.group.anti_aim.fakelag:label(string.format('Welcome back, \v%s\r!', lua.username)),
    build = menu.group.anti_aim.fakelag:label(string.format('Your build is \v%s\r.', lua.build)),
    space_3 = menu.group.anti_aim.fakelag:label(' '),
    welcome = menu.group.anti_aim.fakelag:label('The new and improved \v' .. lua.name .. ' v2\r is here!'),
    space_4 = menu.group.anti_aim.fakelag:label('    '),

    socials = menu.group.anti_aim.other:slider('Our \vTeam\r Socials', 1, 2, 1, true, '', 1, {[1] = ' Mephissa', [2] = ' Lordmouse'}),
    youtube = menu.group.anti_aim.other:button('\v\r  ->  \aFF1717FFYouTube\r @lordmouse', function ()
        panorama.open('CSGOHud').SteamOverlayAPI.OpenExternalBrowserURL('https://www.youtube.com/@lordmouse')
    end),
    youtube_2 = menu.group.anti_aim.other:button('\v\r  ->  \aFF1717FFYouTube\r @freeysl', function ()
        panorama.open('CSGOHud').SteamOverlayAPI.OpenExternalBrowserURL('https://www.youtube.com/@freeysl')
    end),

    space_2 = menu.group.anti_aim.other:label('  '),
    discord_server = menu.group.anti_aim.other:button('\v\r  Our \a8E9EFCFFDiscord\r Server', function ()
        panorama.open('CSGOHud').SteamOverlayAPI.OpenExternalBrowserURL('https://discord.gg/Fsuk24g8RV')
    end),
    space_5 = menu.group.anti_aim.other:label('    ')
} do
    pui.traverse(information, function (ref)
        ref:depend({tab.main, ' User Section'}, {tab.second, ' Information'})
    end)

    information.youtube_2:depend({information.socials, 1})
    information.youtube:depend({information.socials, 2})
end

local logic = {  }
local config_db = database.read('e_m_b_e_r_l_a_s_h_p_r_e_s_e_t_s') or { presets = {'Default'}, default = 'Default' }
config_db.presets = config_db.presets or { }

database.write('e_m_b_e_r_l_a_s_h_p_r_e_s_e_t_s', config_db)
database.flush()

local presets = {
    type_buttons = {
        cloud = menu.group.anti_aim.fakelag:button('Go to \v Cloud\r Presets'),
        local_presets = menu.group.anti_aim.fakelag:button('Go to \v Local\r Presets'),
    },
    space = {
        one = menu.group.anti_aim.fakelag:label(' '),
    },

    _local = {
        name = menu.group.anti_aim.main:textbox('Config Name'),
        create = menu.group.anti_aim.main:button(' Create'),
        import_from_clipboard = menu.group.anti_aim.main:button('Import from clipboard'),
        list = menu.group.anti_aim.main:listbox('\nPresets', config_db.presets),
        save = menu.group.anti_aim.main:button(' Save'),
        load = menu.group.anti_aim.main:button('\v\r Load'),
        load_aa = menu.group.anti_aim.main:button('Load \vAA\r Only'),
        export_to_clipboard = menu.group.anti_aim.main:button('Export to clipboard'),
        export_to_cloud = menu.group.anti_aim.main:button('Export to \vCloud\r'),
        delete = menu.group.anti_aim.main:button('\aFF000092 Delete')
    },

    _cloud = {
        list = menu.group.anti_aim.main:listbox('\nCloud Presets', {'lordmouse', 'Powrotic'} --[[{'Loading...'}]]),
        load = menu.group.anti_aim.main:button('\v\r Load from \vCloud\r'),
        like = menu.group.anti_aim.main:button('Liked'),

        likes = menu.group.anti_aim.main:label('\v\r Likes: \v2\r'),
    }

} do
    logic.create = function ()
        local name = presets._local.name:get()
        if name == '' then return end
        
        table.insert(config_db.presets, name)
        database.write('e_m_b_e_r_l_a_s_h_p_r_e_s_e_t_s', config_db)
        database.flush()
        presets._local.list:update(config_db.presets)
    end

    logic.import = function ()
        logic.setup:load(json.parse(base64.decode(clipboard.get())))
        cvar.play:invoke_callback('ambient\\tones\\elev1')
    end

    logic.delete = function ()
        local index = presets._local.list:get()
        
        table.remove(config_db.presets, index + 1)
        database.write('e_m_b_e_r_l_a_s_h_p_r_e_s_e_t_s', config_db)
        database.flush()
        presets._local.list:update(config_db.presets)
    end

    logic.save = function ()
        local index = presets._local.list:get()
        
        local name = config_db.presets[index]
        config_db[name] = base64.encode(json.stringify(logic.setup:save()))
        cvar.play:invoke_callback('ambient\\tones\\elev1')
        database.write('e_m_b_e_r_l_a_s_h_p_r_e_s_e_t_s', config_db)
        database.flush()
    end

    logic.load = function ()
        local index = presets._local.list:get()

        local name = config_db.presets[index]
        local data = config_db[name]
        if data then
            logic.setup:load(json.parse(base64.decode(data)))
            cvar.play:invoke_callback('ambient\\tones\\elev1')
        end
    end

    logic.load_aa = function ()
        local index = presets._local.list:get()
        
        local name = config_db.presets[index]
        local data = config_db[name]
        if data then
            logic.setup:load(json.parse(base64.decode(data)), 1)
            logic.setup:load(json.parse(base64.decode(data)), 2)
            cvar.play:invoke_callback('ambient\\tones\\elev1')
        end
    end

    logic.export = function ()
        clipboard.set(base64.encode(json.stringify(logic.setup:save())))
        cvar.play:invoke_callback('ambient\\tones\\elev1')
    end

    presets._local.create:set_callback(logic.create)
    presets._local.import_from_clipboard:set_callback(logic.import)
    presets._local.delete:set_callback(logic.delete)
    presets._local.save:set_callback(logic.save)
    presets._local.load:set_callback(logic.load)
    presets._local.load_aa:set_callback(logic.load_aa)
    presets._local.export_to_clipboard:set_callback(logic.export)

    pui.traverse(presets, function(ref)
        ref:depend({tab.main, ' User Section'}, {tab.second, ' Information'})
    end)

    pui.traverse(presets._local, function(ref)
        ref:depend({presets.type_buttons.local_presets, true})
    end)

    pui.traverse(presets._cloud, function(ref)
        ref:depend({presets.type_buttons.cloud, true})
    end)

    presets.type_buttons.cloud:set_callback(function()
        presets.type_buttons.local_presets:set_visible(true)
        presets.type_buttons.cloud:set_visible(false)
        pui.traverse(presets._local, function(ref)
            ref:set_visible(false)
        end)
        pui.traverse(presets._cloud, function(ref)
            ref:set_visible(true)
        end)
    end)

    presets.type_buttons.local_presets:set_callback(function()
        presets.type_buttons.local_presets:set_visible(false)
        presets.type_buttons.cloud:set_visible(true)
        pui.traverse(presets._local, function(ref)
            ref:set_visible(true)
        end)
        pui.traverse(presets._cloud, function(ref)
            ref:set_visible(false)
        end)
    end)

    presets.type_buttons.cloud:set_visible(false)
    presets.type_buttons.local_presets:set_visible(true)
    pui.traverse(presets._local, function(ref)
        ref:set_visible(false)
    end)
    pui.traverse(presets._cloud, function(ref)
        ref:set_visible(true)
    end)
end

local colors = {
    combobox = menu.group.anti_aim.fakelag:combobox('Color', {'Menu', 'Custom'}),
    custom = {
        type = menu.group.anti_aim.fakelag:combobox('\nType', {'Solid', 'Gradient'}),
        color_1 = menu.group.anti_aim.fakelag:color_picker('\nColor 1', 222, 200, 255, 255),
        color_2 = menu.group.anti_aim.fakelag:color_picker('\nColor 2', 222, 200, 255, 255),
        color_3 = menu.group.anti_aim.fakelag:color_picker('\nColor 3', 255, 111, 111, 255),
        color_4 = menu.group.anti_aim.fakelag:color_picker('\nColor 4', 255, 255, 255, 255),
    }
} do
    pui.traverse(colors, function (ref)
        ref:depend({tab.main, ' User Section'}, {tab.second, ' Visuals'})
    end)
    pui.traverse(colors.custom, function (ref)
        ref:depend({colors.combobox, 'Custom'})
    end)
    pui.traverse({colors.custom.color_2, colors.custom.color_3, colors.custom.color_4}, function (ref)
        ref:depend({colors.custom.type, 'Gradient'})
    end)
end

local elements = {
    anti_aim = {
        tab_label = menu.group.anti_aim.fakelag:label('\v  \a7F7F7F97•    •  '),
        tab = menu.group.anti_aim.fakelag:combobox('\nAA Tab', {' Builder', ' Defensive', ' Other'}),
        tab_2 = menu.group.anti_aim.fakelag:combobox('\nAA Tab #2', {'Hotkeys', 'Exploits', 'Settings'}),
        space = menu.group.anti_aim.fakelag:label('\n Space'),

        hotkeys = {
            manual_mode = menu.group.anti_aim.fakelag:combobox('Manual \v»\r Mode', {'Default', 'Spam'}),
            forward = menu.group.anti_aim.fakelag:hotkey('Manual \v»\r Forward'),
            left = menu.group.anti_aim.fakelag:hotkey('Manual \v»\r Left'),
            right = menu.group.anti_aim.fakelag:hotkey('Manual \v»\r Right'),
            reset = menu.group.anti_aim.fakelag:hotkey('Manual \v»\r Reset'),
            freestanding = menu.group.anti_aim.fakelag:checkbox('Freestanding', 0x00),
            edge_yaw = menu.group.anti_aim.fakelag:checkbox('Edge yaw', 0x00),
        },

        exploits = {
            exploit = menu.group.anti_aim.fakelag:checkbox('\vSecret\r exploit', 0x00),
            defensive_flick = {
                enable = menu.group.anti_aim.fakelag:checkbox('Defensive \vflick\r'),
                settings = {
                    states = menu.group.anti_aim.fakelag:multiselect('\nStates', {'Stand', 'Run', 'Walk', 'Crouch', 'Sneak', 'Air', 'Air+', 'Freestanding', 'Manual Left', 'Manual Right'}),
                }
            }
        },

        settings = {
            list = menu.group.anti_aim.fakelag:multiselect('\nSettings', {'Safe head', 'Off defensive aa vs low ping', 'Anti backstab', 'Fast ladder', 'Spin if enemies dead', 'E-Bombsite fix', 'Spin on warmup'}),
            safe_head_options = menu.group.anti_aim.fakelag:multiselect('\nSafe Head States', {'Knife', 'Taser', 'Height Advantage'}),
            safe_head_mode = menu.group.anti_aim.fakelag:combobox('\nSafe Head Mode', {'Offensive', 'Defensive'})
        }
    },

    tab = {
        label = menu.group.anti_aim.fakelag:label('\v  \a7F7F7F97•  '),
        combo = menu.group.anti_aim.fakelag:combobox('\nFeatures Tab', {' Aimbot', ' Miscellaneous'}),
        space = menu.group.anti_aim.fakelag:label(' '),
    },

    aimbot = {
        unsafe_exploit = menu.group.anti_aim.main:checkbox('Unsafe exploit recharge'),
        auto_discharge = {
            enable = menu.group.anti_aim.main:checkbox('Auto exploit discharge', 0x00),
            settings = {
                mode = menu.group.anti_aim.main:combobox('\nMode', {'Default', 'Air lag'}),
                air_lag_mode = menu.group.anti_aim.main:combobox('\nAir lag mode', {'Fast', 'Slow'}),
            }
        },
        resolver = menu.group.anti_aim.main:checkbox('\vResolver'),
        auto_hs = {
            enable = menu.group.anti_aim.main:checkbox('Auto hide shots'),
            settings = {
                state = menu.group.anti_aim.main:multiselect('\nStates', {'Stand', 'Run', 'Walk', 'Crouch', 'Sneak'}),
                avoid_guns = menu.group.anti_aim.main:multiselect('Avoid', {'Pistols', 'Desert Eagle', 'Auto Snipers', 'Desert Eagle + Crouch'}),
            }
        },
        auto_air_stop = {
            enable = menu.group.anti_aim.main:checkbox('Auto air stop'),
            settings = {

            }
        },

        aimbot_helper = {
            enable = menu.group.anti_aim.fakelag:checkbox('Aimbot \vhelper'),
            settings = {
                weapon = menu.group.anti_aim.fakelag:combobox('\nWeapon', {'SSG-08', 'AWP', 'Auto Snipers'}),
                ssg = {
                    select = menu.group.anti_aim.fakelag:multiselect('\nSelect SSG08', {'Force safe point', 'Prefer body aim', 'Force body aim', 'Ping spike'}),
                    
                    force_safe = menu.group.anti_aim.fakelag:multiselect('\vForce safe point\r triggers \nSSG08', {'Enemy HP < X', 'X Missed Shots', 'Lethal', 'Height advantage', 'Enemy higher than you'}),
                    force_safe_hp = menu.group.anti_aim.fakelag:slider('\vForce safe point\r HP Trigger \nSSG08', 1, 100, 50, true, 'hp'),
                    force_safe_miss = menu.group.anti_aim.fakelag:slider('\vForce safe point\r Missed Trigger \nSSG08', 1, 10, 2, true, 'shots'),

                    prefer_body = menu.group.anti_aim.fakelag:multiselect('\vPrefer body aim\r triggers \nSSG08', {'Enemy HP < X', 'X Missed Shots', 'Lethal', 'Height advantage', 'Enemy higher than you'}),
                    prefer_body_hp = menu.group.anti_aim.fakelag:slider('\vPrefer body aim\r HP Trigger \nSSG08', 1, 100, 50, true, 'hp'),
                    prefer_body_miss = menu.group.anti_aim.fakelag:slider('\vPrefer body aim\r Missed Trigger \nSSG08', 1, 10, 2, true, 'shots'),

                    force_body = menu.group.anti_aim.fakelag:multiselect('\vForce body aim\r triggers \nSSG08', {'Enemy HP < X', 'X Missed Shots', 'Lethal', 'Height advantage', 'Enemy higher than you'}),
                    force_body_hp = menu.group.anti_aim.fakelag:slider('\vForce body aim\r HP Trigger \nSSG08', 1, 100, 50, true, 'hp'),
                    force_body_miss = menu.group.anti_aim.fakelag:slider('\vForce body aim\r Missed Trigger \nSSG08', 1, 10, 2, true, 'sh'),

                    ping_spike_value = menu.group.anti_aim.fakelag:slider('\vPing spike\r value \nSSG08', 1, 200, 80, true, 'ms')
                },

                awp = {
                    select = menu.group.anti_aim.fakelag:multiselect('\nSelect AWP', {'Force safe point', 'Prefer body aim', 'Force body aim', 'Ping spike'}),

                    force_safe = menu.group.anti_aim.fakelag:multiselect('\vForce safe point\r triggers \nAWP', {'Enemy HP < X', 'X Missed Shots', 'Lethal', 'Height advantage', 'Enemy higher than you'}),
                    force_safe_hp = menu.group.anti_aim.fakelag:slider('\vForce safe point\r HP Trigger \nAWP', 1, 100, 50, true, 'hp'),
                    force_safe_miss = menu.group.anti_aim.fakelag:slider('\vForce safe point\r Missed Trigger \nAWP', 1, 10, 2, true, 'sh'),

                    prefer_body = menu.group.anti_aim.fakelag:multiselect('\vPrefer body aim\r triggers \nAWP', {'Enemy HP < X', 'X Missed Shots', 'Lethal', 'Height advantage', 'Enemy higher than you'}),
                    prefer_body_hp = menu.group.anti_aim.fakelag:slider('\vPrefer body aim\r HP Trigger \nAWP', 1, 100, 50, true, 'hp'),
                    prefer_body_miss = menu.group.anti_aim.fakelag:slider('\vPrefer body aim\r Missed Trigger \nAWP', 1, 10, 2, true, 'sh'),

                    force_body = menu.group.anti_aim.fakelag:multiselect('\vForce body aim\r triggers \nAWP', {'Enemy HP < X', 'X Missed Shots', 'Lethal', 'Height advantage', 'Enemy higher than you'}),
                    force_body_hp = menu.group.anti_aim.fakelag:slider('\vForce body aim\r HP Trigger \nAWP', 1, 100, 50, true, 'hp'),
                    force_body_miss = menu.group.anti_aim.fakelag:slider('\vForce body aim\r Missed Trigger \nAWP', 1, 10, 2, true, 'sh'),

                    ping_spike_value = menu.group.anti_aim.fakelag:slider('\vPing spike\r value \nAWP', 1, 200, 130, true, 'ms')
                },

                auto = {
                    select = menu.group.anti_aim.fakelag:multiselect('\nSelect AUTO', {'Force safe point', 'Prefer body aim', 'Force body aim', 'Ping spike'}),

                    force_safe = menu.group.anti_aim.fakelag:multiselect('\vForce safe point\r triggers \nAUTO', {'Enemy HP < X', 'X Missed Shots', 'Lethal', 'Height advantage', 'Enemy higher than you'}),
                    force_safe_hp = menu.group.anti_aim.fakelag:slider('\vForce safe point\r HP Trigger \nAUTO', 1, 100, 50, true, 'hp'),
                    force_safe_miss = menu.group.anti_aim.fakelag:slider('\vForce safe point\r Missed Trigger \nAUTO', 1, 10, 2, true, 'sh'),

                    prefer_body = menu.group.anti_aim.fakelag:multiselect('\vPrefer body aim\r triggers \nAUTO', {'Enemy HP < X', 'X Missed Shots', 'Lethal', 'Height advantage', 'Enemy higher than you'}),
                    prefer_body_hp = menu.group.anti_aim.fakelag:slider('\vPrefer body aim\r HP Trigger \nAUTO', 1, 100, 50, true, 'hp'),
                    prefer_body_miss = menu.group.anti_aim.fakelag:slider('\vPrefer body aim\r Missed Trigger \nAUTO', 1, 10, 2, true, 'sh'),

                    force_body = menu.group.anti_aim.fakelag:multiselect('\vForce body aim\r triggers \nAUTO', {'Enemy HP < X', 'X Missed Shots', 'Lethal', 'Height advantage', 'Enemy higher than you'}),
                    force_body_hp = menu.group.anti_aim.fakelag:slider('\vForce body aim\r HP Trigger \nAUTO', 1, 100, 50, true, 'hp'),
                    force_body_miss = menu.group.anti_aim.fakelag:slider('\vForce body aim\r Missed Trigger \nAUTO', 1, 10, 2, true, 'sh'),

                    ping_spike_value = menu.group.anti_aim.fakelag:slider('\vPing spike\r value \nAUTO', 1, 200, 105, true, 'ms')
                }
            }
        },

        ai_peek = {
            enable = menu.group.anti_aim.fakelag:checkbox('\vAI\r peek', 0x00),
            settings = {
                distance = menu.group.anti_aim.fakelag:combobox('\nPeek distance', {'Long', 'Medium', 'Short'}),
                mode = menu.group.anti_aim.fakelag:combobox('\nTarget mode', {'Current threat', 'Closest to crosshair'}),
                peek_mode = menu.group.anti_aim.fakelag:multiselect('\nPeek mode', {'Automatically teleport back', 'Force defensive', 'Peek arrow'}),
            }
        },

        predict_enemies = {
            enable = menu.group.anti_aim.other:checkbox('Predict \venemies'),
        },
        
        game_enhancer = {
            enable = menu.group.anti_aim.other:checkbox('Game enhancer'),
            settings = {
                list = menu.group.anti_aim.other:multiselect('\nGame enhancer list', {'Fix chams color', 'Disable dynamic lighting', 'Disable dynamic shadows', 'Disable first-person tracers', 'Disable ragdolls', 'Disable eye gloss', 'Disable eye movement', 'Disable muzzle flash light', 'Enable low CPU audio', 'Disable bloom', 'Disable particles', 'Reduce breakable objects'}),
            }
        }
    },

    visuals = {
        crosshair = {
            enable = menu.group.anti_aim.main:checkbox('Crosshair'),
            settings = {
                type = menu.group.anti_aim.main:combobox('\nCrosshair type', {'Unique', 'Simple'}),
                select = menu.group.anti_aim.main:multiselect('\nSelect', {'States', 'Binds'}),
            }
        },
        arrows = {
            enable = menu.group.anti_aim.main:checkbox('Arrows'),
            settings = {
                type = menu.group.anti_aim.main:combobox('\nArrows type', {'Unique', 'Simple', 'TeamSkeet'}),
            }
        },
        scope = {
            enable = menu.group.anti_aim.main:checkbox('Scope'),
            settings = {
                invert = menu.group.anti_aim.main:checkbox('\nInvert'),
                exclude = menu.group.anti_aim.main:multiselect('\nExclude', {'Left', 'Right', 'Top', 'Bottom'}),
                gap = menu.group.anti_aim.main:slider('\nScope gap', 0, 100, 10, true, 'x'),
                size = menu.group.anti_aim.main:slider('\nScope size', 5, 200, 20, true, 'w'),
            }
        },

        space = menu.group.anti_aim.main:label(' '),

        zoom = {
            enable = menu.group.anti_aim.main:checkbox('Zoom animation'),
            settings = {
                speed = menu.group.anti_aim.main:slider('\nZoom animation speed', 10, 100, 60, true, '%S'),
                value = menu.group.anti_aim.main:slider('\nZoom animation value', 5, 100, 15, true, '%')
            }
        },
        aspect_ratio = {
            enable = menu.group.anti_aim.main:checkbox('Aspect ratio'),
            settings = {
                value = menu.group.anti_aim.main:slider('\nAspect ratio value', 80, 250, 178, true, 'x', .01, {[125] = '5:4', [133] = '4:3', [150] = '3:2', [160] = '16:10', [178] = '16:9', [200] = '2:1'}),
            }
        },
        viewmodel = {
            enable = menu.group.anti_aim.main:checkbox('Viewmodel'),
            settings = {
                fov = menu.group.anti_aim.main:slider('\nFOV', 0, 120, 68, true, '°'),
                x = menu.group.anti_aim.main:slider('\nX', -100, 100, 0, true, 'u', .1),
                y = menu.group.anti_aim.main:slider('\nY', -100, 100, 0, true, 'u', .1),
                z = menu.group.anti_aim.main:slider('\nZ', -100, 100, 0, true, 'u', .1)
            }
        },

        windows = menu.group.anti_aim.fakelag:multiselect('Windows', {'Force text watermark', 'Watermark', 'Keybinds', 'Spectators', 'Debug panel', 'Multi panel', 'Event logger'}),
        watermark = {
            settings = {
                elements = menu.group.anti_aim.fakelag:multiselect('Watermark elements', {'Nickname', 'Frames Per Second', 'Ping', 'Tickrate', 'Time'}),
                nickname = menu.group.anti_aim.fakelag:combobox('Watermark nickname', {'Loader', 'Steam', 'Custom'}),
                custom = menu.group.anti_aim.fakelag:textbox('Watermark custom nickname'),
            }
        },
        event_logger = {
            settings = {
                type = menu.group.anti_aim.fakelag:multiselect('Event logger type', {'In console', 'Upper-left', 'Centered'}),
            }
        },

        damage = {
            enable = menu.group.anti_aim.other:checkbox('Damage indicator'),
            settings = {
                type = menu.group.anti_aim.other:combobox('\nDamage indicator type', {'Always on', 'On hotkey'}),
                font = menu.group.anti_aim.other:combobox('\nDamage indicator font', {'Default', 'Small', 'Big'}),
            }
        },

        markers = {
            enable = menu.group.anti_aim.other:checkbox('Markers'),
            settings = {
                type = menu.group.anti_aim.other:multiselect('\nMarkers type', {'On hit', 'On miss', 'Damage'})
            }
        }
    },

    misc = {
        sticker_crash_fix = menu.group.anti_aim.main:checkbox('Sticker crash fix'),
        enemy_chat_viewer = menu.group.anti_aim.main:checkbox('Enemy chat viewer'),
        edge_quick_stop = menu.group.anti_aim.main:checkbox('Edge quick stop', 0x00),
        space = menu.group.anti_aim.main:label(' '),
        fd_fix = menu.group.anti_aim.main:checkbox('Duck peek assist fix'),
        drop_nades = {
            enable = menu.group.anti_aim.main:checkbox('Drop nades', 0x00),
            settings = {
                list = menu.group.anti_aim.main:multiselect('\nType', {'HE Grenade', 'Molotov', 'Incendiary', 'Smoke'}),
            }
        },
        space_2 = menu.group.anti_aim.main:label('  '),
        autobuy = {
            enable = menu.group.anti_aim.main:checkbox('Auto buy'),
            settings = {
                sniper = menu.group.anti_aim.main:combobox('\nPrimary weapon', {'-', 'SSG-08', 'AWP', 'SCAR-20/G3SG1'}),
                pistol = menu.group.anti_aim.main:combobox('\nSecondary weapon', {'-', 'Duals', 'P250', 'Five-SeveN/Tec-9', 'Deagle/R8'}),
                grenades = menu.group.anti_aim.main:multiselect('\nGrenades', {'Smoke', 'Molotov', 'HE Grenade'}),
                utilities = menu.group.anti_aim.main:multiselect('\nUtilities', {'Kevlar', 'Helmet', 'Defuse Kit', 'Taser'})
            }
        },

        animations = {
            enable = menu.group.anti_aim.fakelag:checkbox('Animation breaker'),
            settings = {
                condition = menu.group.anti_aim.fakelag:combobox('\nCondition', {'Running', 'In air'}),
                running = {
                    anim_type = menu.group.anti_aim.fakelag:combobox('\nSelect animations\nRunning', {'-', 'Static', 'Jitter', 'Alternative jitter', 'Allah'}),
                    anim_min_jitter = menu.group.anti_aim.fakelag:slider('Min. jitter percent\nRunning', 0, 100, 0, true, '%'),   
                    anim_max_jitter = menu.group.anti_aim.fakelag:slider('Max. jitter percent\nRunning', 0, 100, 100, true, '%'),
                    anim_extra_type = menu.group.anti_aim.fakelag:multiselect('\nSelect extra animations\nRunning', {'Body lean'}),
                    anim_bodylean = menu.group.anti_aim.fakelag:slider('Leaning percent\nRunning', 0, 100, 70, true, '%'),
                },

                in_air = {
                    anim_type = menu.group.anti_aim.fakelag:combobox('\nSelect Animations\nAir', {'-', 'Static', 'Jitter', 'Allah'}),
                    anim_min_jitter = menu.group.anti_aim.fakelag:slider('Min. jitter percent\nAir', 0, 100, 0, true, '%'),   
                    anim_max_jitter = menu.group.anti_aim.fakelag:slider('Max. jitter percent\nAir', 0, 100, 100, true, '%'),   
                    anim_extra_type = menu.group.anti_aim.fakelag:multiselect('\nSelect extra animations\nAir', {'Body lean', 'Zero pitch on landing'}),
                    anim_bodylean = menu.group.anti_aim.fakelag:slider('Leaning percent\nAir', 0, 100, 70, true, '%'),
                },
            }
        },

        clan_tag_spammer = menu.group.anti_aim.other:checkbox('Clan tag spammer'),
        trash_talk = {
            enable = menu.group.anti_aim.other:checkbox('Trash talk'),
            settings = {
                work = menu.group.anti_aim.other:multiselect('\nWork', {'On kill', 'On death'}),
                type = menu.group.anti_aim.other:combobox('\nType', {'Emberlash', 'Bait'}),
            }
        }
    }
} do
    elements.anti_aim.exploits.exploit:set_enabled(false)
    pui.traverse(elements.anti_aim, function (ref)
        ref:depend({tab.main, ' Anti-aimbot angles'})
    end)

    elements.anti_aim.tab:set_callback(function (ref)
        if ref:get() == ' Builder' then
            elements.anti_aim.tab_label:set('\v  \a7F7F7F97•    •  ')
        elseif ref:get() == ' Defensive' then
            elements.anti_aim.tab_label:set('\a7F7F7F97  •  \v  \a7F7F7F97•  ')
        elseif ref:get() == ' Other' then
            elements.anti_aim.tab_label:set('\a7F7F7F97  •    •  \v')
        end
    end)
    elements.anti_aim.tab_2:depend({tab.main, ' Anti-aimbot angles'}, {elements.anti_aim.tab, ' Other', true})
    pui.traverse(reference.antiaim.fakelag, function (ref)
        ref:depend({tab.main, ' Anti-aimbot angles'}, {elements.anti_aim.tab, ' Other'})
        if ref.hotkey then ref.hotkey:depend({tab.main, ' Anti-aimbot angles'}, {elements.anti_aim.tab, ' Other'}) end
    end)

    pui.traverse(reference.antiaim.other, function (ref)
        ref:depend({tab.main, ' Anti-aimbot angles'}, {elements.anti_aim.tab, ' Other'})
        if ref.hotkey then ref.hotkey:depend({tab.main, ' Anti-aimbot angles'}, {elements.anti_aim.tab, ' Other'}) end
    end)

    pui.traverse(elements.anti_aim.hotkeys, function (ref)
        ref:depend({elements.anti_aim.tab_2, 'Hotkeys'}, {elements.anti_aim.tab, ' Other', true})
    end)

    pui.traverse(elements.anti_aim.exploits, function (ref)
        ref:depend({elements.anti_aim.tab_2, 'Exploits'}, {elements.anti_aim.tab, ' Other', true})
    end)
    pui.traverse(elements.anti_aim.exploits.defensive_flick.settings, function (ref)
        ref:depend({elements.anti_aim.exploits.defensive_flick.enable, true})
    end)
    
    pui.traverse(elements.anti_aim.settings, function (ref)
        ref:depend({elements.anti_aim.tab_2, 'Settings'}, {elements.anti_aim.tab, ' Other', true})
    end)
    pui.traverse({elements.anti_aim.settings.safe_head_options, elements.anti_aim.settings.safe_head_mode}, function (ref)
        ref:depend({elements.anti_aim.settings.list, 'Safe head'})
    end)

    pui.traverse(elements.tab, function (ref)
        ref:depend({tab.main, ' Features'})
    end)
    elements.tab.combo:set_callback(function (ref)
        if ref:get() == ' Aimbot' then
            elements.tab.label:set('\v  \a7F7F7F97•  ')
        elseif ref:get() == ' Miscellaneous' then
            elements.tab.label:set('\a7F7F7F97  •  \v')
        end
    end)

    pui.traverse(elements.aimbot, function (ref)
        ref:depend({tab.main, ' Features'}, {elements.tab.combo, ' Aimbot'})
    end)
    pui.traverse(elements.aimbot.auto_discharge.settings, function (ref)
        ref:depend({elements.aimbot.auto_discharge.enable, true})
    end)
    elements.aimbot.auto_discharge.settings.air_lag_mode:depend({elements.aimbot.auto_discharge.settings.mode, 'Air lag'})
    pui.traverse(elements.aimbot.auto_hs.settings, function (ref)
        ref:depend({elements.aimbot.auto_hs.enable, true})
    end)
    elements.aimbot.auto_hs.settings.avoid_guns:depend({elements.aimbot.auto_hs.settings.state, function ()
        if elements.aimbot.auto_hs.settings.state:get('Stand') or elements.aimbot.auto_hs.settings.state:get('Run') or elements.aimbot.auto_hs.settings.state:get('Walk') or elements.aimbot.auto_hs.settings.state:get('Crouch') or elements.aimbot.auto_hs.settings.state:get('Sneak') then
            return true
        else
            return false
        end
    end})
    pui.traverse(elements.aimbot.auto_air_stop.settings, function (ref)
        ref:depend({elements.aimbot.auto_air_stop.enable, true})
    end)
    pui.traverse(elements.aimbot.aimbot_helper.settings, function (ref)
        ref:depend({elements.aimbot.aimbot_helper.enable, true})
    end)
    pui.traverse(elements.aimbot.aimbot_helper.settings.ssg, function (ref)
        ref:depend({elements.aimbot.aimbot_helper.settings.weapon, 'SSG-08'})
    end)
    pui.traverse({elements.aimbot.aimbot_helper.settings.ssg.force_safe, elements.aimbot.aimbot_helper.settings.ssg.force_safe_hp, elements.aimbot.aimbot_helper.settings.ssg.force_safe_miss}, function (ref)
        ref:depend({elements.aimbot.aimbot_helper.settings.ssg.select, 'Force safe point'})
    end)
    elements.aimbot.aimbot_helper.settings.ssg.force_safe_hp:depend({elements.aimbot.aimbot_helper.settings.ssg.force_safe, 'Enemy HP < X'})
    elements.aimbot.aimbot_helper.settings.ssg.force_safe_miss:depend({elements.aimbot.aimbot_helper.settings.ssg.force_safe, 'X Missed Shots'})
    pui.traverse({elements.aimbot.aimbot_helper.settings.ssg.prefer_body, elements.aimbot.aimbot_helper.settings.ssg.prefer_body_hp, elements.aimbot.aimbot_helper.settings.ssg.prefer_body_miss}, function (ref)
        ref:depend({elements.aimbot.aimbot_helper.settings.ssg.select, 'Prefer body aim'})
    end)
    elements.aimbot.aimbot_helper.settings.ssg.prefer_body_hp:depend({elements.aimbot.aimbot_helper.settings.ssg.prefer_body, 'Enemy HP < X'})
    elements.aimbot.aimbot_helper.settings.ssg.prefer_body_miss:depend({elements.aimbot.aimbot_helper.settings.ssg.prefer_body, 'X Missed Shots'})
    pui.traverse({elements.aimbot.aimbot_helper.settings.ssg.force_body, elements.aimbot.aimbot_helper.settings.ssg.force_body_hp, elements.aimbot.aimbot_helper.settings.ssg.force_body_miss}, function (ref)
        ref:depend({elements.aimbot.aimbot_helper.settings.ssg.select, 'Force body aim'})
    end)
    elements.aimbot.aimbot_helper.settings.ssg.force_body_hp:depend({elements.aimbot.aimbot_helper.settings.ssg.force_body, 'Enemy HP < X'})
    elements.aimbot.aimbot_helper.settings.ssg.force_body_miss:depend({elements.aimbot.aimbot_helper.settings.ssg.force_body, 'X Missed Shots'})
    elements.aimbot.aimbot_helper.settings.ssg.ping_spike_value:depend({elements.aimbot.aimbot_helper.settings.ssg.select, 'Ping spike'})
    pui.traverse(elements.aimbot.aimbot_helper.settings.awp, function (ref)
        ref:depend({elements.aimbot.aimbot_helper.settings.weapon, 'AWP'})
    end)
    pui.traverse({elements.aimbot.aimbot_helper.settings.awp.force_safe, elements.aimbot.aimbot_helper.settings.awp.force_safe_hp, elements.aimbot.aimbot_helper.settings.awp.force_safe_miss}, function (ref)
        ref:depend({elements.aimbot.aimbot_helper.settings.awp.select, 'Force safe point'})
    end)
    elements.aimbot.aimbot_helper.settings.awp.force_safe_hp:depend({elements.aimbot.aimbot_helper.settings.awp.force_safe, 'Enemy HP < X'})
    elements.aimbot.aimbot_helper.settings.awp.force_safe_miss:depend({elements.aimbot.aimbot_helper.settings.awp.force_safe, 'X Missed Shots'})
    pui.traverse({elements.aimbot.aimbot_helper.settings.awp.prefer_body, elements.aimbot.aimbot_helper.settings.awp.prefer_body_hp, elements.aimbot.aimbot_helper.settings.awp.prefer_body_miss}, function (ref)
        ref:depend({elements.aimbot.aimbot_helper.settings.awp.select, 'Prefer body aim'})
    end)
    elements.aimbot.aimbot_helper.settings.awp.prefer_body_hp:depend({elements.aimbot.aimbot_helper.settings.awp.prefer_body, 'Enemy HP < X'})
    elements.aimbot.aimbot_helper.settings.awp.prefer_body_miss:depend({elements.aimbot.aimbot_helper.settings.awp.prefer_body, 'X Missed Shots'})
    pui.traverse({elements.aimbot.aimbot_helper.settings.awp.force_body, elements.aimbot.aimbot_helper.settings.awp.force_body_hp, elements.aimbot.aimbot_helper.settings.awp.force_body_miss}, function (ref)
        ref:depend({elements.aimbot.aimbot_helper.settings.awp.select, 'Force body aim'})
    end)
    elements.aimbot.aimbot_helper.settings.awp.force_body_hp:depend({elements.aimbot.aimbot_helper.settings.awp.force_body, 'Enemy HP < X'})
    elements.aimbot.aimbot_helper.settings.awp.force_body_miss:depend({elements.aimbot.aimbot_helper.settings.awp.force_body, 'X Missed Shots'})
    elements.aimbot.aimbot_helper.settings.awp.ping_spike_value:depend({elements.aimbot.aimbot_helper.settings.awp.select, 'Ping spike'})
    pui.traverse(elements.aimbot.aimbot_helper.settings.auto, function (ref)
        ref:depend({elements.aimbot.aimbot_helper.settings.weapon, 'Auto Snipers'})
    end)
    pui.traverse({elements.aimbot.aimbot_helper.settings.auto.force_safe, elements.aimbot.aimbot_helper.settings.auto.force_safe_hp, elements.aimbot.aimbot_helper.settings.auto.force_safe_miss}, function (ref)
        ref:depend({elements.aimbot.aimbot_helper.settings.auto.select, 'Force safe point'})
    end)
    elements.aimbot.aimbot_helper.settings.auto.force_safe_hp:depend({elements.aimbot.aimbot_helper.settings.auto.force_safe, 'Enemy HP < X'})
    elements.aimbot.aimbot_helper.settings.auto.force_safe_miss:depend({elements.aimbot.aimbot_helper.settings.auto.force_safe, 'X Missed Shots'})
    pui.traverse({elements.aimbot.aimbot_helper.settings.auto.prefer_body, elements.aimbot.aimbot_helper.settings.auto.prefer_body_hp, elements.aimbot.aimbot_helper.settings.auto.prefer_body_miss}, function (ref)
        ref:depend({elements.aimbot.aimbot_helper.settings.auto.select, 'Prefer body aim'})
    end)
    elements.aimbot.aimbot_helper.settings.auto.prefer_body_hp:depend({elements.aimbot.aimbot_helper.settings.auto.prefer_body, 'Enemy HP < X'})
    elements.aimbot.aimbot_helper.settings.auto.prefer_body_miss:depend({elements.aimbot.aimbot_helper.settings.auto.prefer_body, 'X Missed Shots'})
    pui.traverse({elements.aimbot.aimbot_helper.settings.auto.force_body, elements.aimbot.aimbot_helper.settings.auto.force_body_hp, elements.aimbot.aimbot_helper.settings.auto.force_body_miss}, function (ref)
        ref:depend({elements.aimbot.aimbot_helper.settings.auto.select, 'Force body aim'})
    end)
    elements.aimbot.aimbot_helper.settings.auto.force_body_hp:depend({elements.aimbot.aimbot_helper.settings.auto.force_body, 'Enemy HP < X'})
    elements.aimbot.aimbot_helper.settings.auto.force_body_miss:depend({elements.aimbot.aimbot_helper.settings.auto.force_body, 'X Missed Shots'})
    elements.aimbot.aimbot_helper.settings.auto.ping_spike_value:depend({elements.aimbot.aimbot_helper.settings.auto.select, 'Ping spike'})
    pui.traverse(elements.aimbot.ai_peek.settings, function (ref)
        ref:depend({elements.aimbot.ai_peek.enable, true})
    end)
    pui.traverse(elements.aimbot.game_enhancer.settings, function (ref)
        ref:depend({elements.aimbot.game_enhancer.enable, true})
    end)

    pui.traverse(elements.visuals, function (ref)
        ref:depend({tab.main, ' User Section'}, {tab.second, ' Visuals'})
    end)
    pui.traverse(elements.visuals.crosshair.settings, function (ref)
        ref:depend({elements.visuals.crosshair.enable, true})
    end)
    pui.traverse(elements.visuals.arrows.settings, function (ref)
        ref:depend({elements.visuals.arrows.enable, true})
    end)
    pui.traverse(elements.visuals.scope.settings, function (ref)
        ref:depend({elements.visuals.scope.enable, true})
    end)
    pui.traverse(elements.visuals.zoom.settings, function (ref)
        ref:depend({elements.visuals.zoom.enable, true})
    end)
    pui.traverse(elements.visuals.aspect_ratio.settings, function (ref)
        ref:depend({elements.visuals.aspect_ratio.enable, true})
    end)
    pui.traverse(elements.visuals.viewmodel.settings, function (ref)
        ref:depend({elements.visuals.viewmodel.enable, true})
    end)
    pui.traverse(elements.visuals.watermark.settings, function (ref)
        ref:depend({elements.visuals.windows, 'Watermark'})
    end)
    elements.visuals.watermark.settings.nickname:depend({elements.visuals.watermark.settings.elements, 'Nickname'})
    elements.visuals.watermark.settings.custom:depend({elements.visuals.watermark.settings.elements, 'Nickname'}, {elements.visuals.watermark.settings.nickname, 'Custom'})
    pui.traverse(elements.visuals.event_logger.settings, function (ref)
        ref:depend({elements.visuals.windows, 'Event logger'})
    end)
    pui.traverse(elements.visuals.damage.settings, function (ref)
        ref:depend({elements.visuals.damage.enable, true})
    end)
    pui.traverse(elements.visuals.markers.settings, function (ref)
        ref:depend({elements.visuals.markers.enable, true})
    end)

    pui.traverse(elements.misc, function (ref)
        ref:depend({tab.main, ' Features'}, {elements.tab.combo, ' Miscellaneous'})
    end)
    pui.traverse(elements.misc.drop_nades.settings, function (ref)
        ref:depend({elements.misc.drop_nades.enable, true})
    end)
    pui.traverse(elements.misc.autobuy.settings, function (ref)
        ref:depend({elements.misc.autobuy.enable, true})
    end)
    pui.traverse(elements.misc.animations.settings, function (ref)
        ref:depend({elements.misc.animations.enable, true})
    end)
    pui.traverse(elements.misc.animations.settings.running, function (ref)
        ref:depend({elements.misc.animations.settings.condition, 'Running'})
    end)
    pui.traverse(elements.misc.animations.settings.in_air, function (ref)
        ref:depend({elements.misc.animations.settings.condition, 'In air'})
    end)
    pui.traverse(elements.misc.animations.settings.running.anim_bodylean, function (ref)
        ref:depend({elements.misc.animations.settings.running.anim_extra_type, 'Body lean'})
    end)
    pui.traverse({elements.misc.animations.settings.running.anim_min_jitter, elements.misc.animations.settings.running.anim_max_jitter}, function (ref)
        ref:depend({elements.misc.animations.settings.running.anim_type, 'Jitter'})
    end)
    pui.traverse(elements.misc.animations.settings.in_air.anim_bodylean, function (ref)
        ref:depend({elements.misc.animations.settings.in_air.anim_extra_type, 'Body lean'})
    end)
    pui.traverse({elements.misc.animations.settings.in_air.anim_min_jitter, elements.misc.animations.settings.in_air.anim_max_jitter}, function (ref)
        ref:depend({elements.misc.animations.settings.in_air.anim_type, 'Jitter'})
    end)
    pui.traverse(elements.misc.trash_talk.settings, function (ref)
        ref:depend({elements.misc.trash_talk.enable, true})
    end)
end

local drag_slider = {
    crosshair = {
        y = menu.group.anti_aim.main:slider('Y Crosshair', 0, screen_size.y, helpers:clamp(screen_size.y / 2 + 20, 0, screen_size.y - 76)),
    },
    arrows = {
        x = menu.group.anti_aim.main:slider('X Arrows', 0, screen_size.x, helpers:clamp(screen_size.x / 2 + 30, 0, screen_size.x - 147)),
    },
    advert = {
        x = menu.group.anti_aim.main:slider('X Advert Watermark', 0, screen_size.x, helpers:clamp(15, 0, screen_size.x - 147)),
        y = menu.group.anti_aim.main:slider('Y Advert Watermark', 0, screen_size.y, helpers:clamp(screen_size.y / 2 - 20, 0, screen_size.y - 76)),
    }
} do
    pui.traverse(drag_slider, function (ref)
        ref:set_visible(false)
    end)
end

---

local exploits = {  }

exploits.max_process_ticks = math.abs(client.get_cvar('sv_maxusrcmdprocessticks')) - 1
exploits.tickbase_difference = 0
exploits.ticks_processed = 0
exploits.command_number = 0
exploits.choked_commands = 0
exploits.need_force_defensive = false
exploits.current_shift_amount = 0

function exploits.reset_vars ()
    exploits.ticks_processed = 0 
    exploits.tickbase_difference = 0 
    exploits.choked_commands = 0 
    exploits.command_number = 0
end

function exploits.store_vars (ctx)
    exploits.command_number = ctx.command_number 
    exploits.choked_commands = ctx.chokedcommands
end

function exploits.store_tickbase_difference (ctx)
    if ctx.command_number == exploits.command_number then
        exploits.ticks_processed = helpers:clamp(math.abs(entity.get_prop(entity.get_local_player(), 'm_nTickBase') - exploits.tickbase_difference), 0, exploits.max_process_ticks - exploits.choked_commands)
        exploits.tickbase_difference = math.max(entity.get_prop(entity.get_local_player(), 'm_nTickBase'), exploits.tickbase_difference or 0)
        exploits.command_number = 0
    end
end

function exploits.is_doubletap ()
    return reference.rage.aimbot.double_tap[1]:get() and reference.rage.aimbot.double_tap[1].hotkey:get() and not reference.rage.other.fake_duck:get()
end

function exploits.is_hideshots ()
    return reference.antiaim.other.on_shot_anti_aim[1]:get() and reference.antiaim.other.on_shot_anti_aim[1].hotkey:get() and not reference.rage.other.fake_duck:get()
end

function exploits.is_active ()
    return exploits.is_doubletap() or exploits.is_hideshots()
end

function exploits.in_defensive ()
    return exploits.is_active() and (exploits.ticks_processed > 1 and exploits.ticks_processed < exploits.max_process_ticks)
end

function exploits.is_defensive_ended ()
    return not exploits.in_defensive() or (exploits.ticks_processed >= 0 and exploits.ticks_processed <= 5) and exploits.tickbase_difference > 0
end

function exploits.is_lagcomp_broken ()
    return not exploits.is_defensive_ended() or exploits.tickbase_difference < entity.get_prop(entity.get_local_player(), 'm_nTickBase')
end

function exploits.can_recharge ()
    if not exploits.is_active() then return false end

    local local_player = entity.get_local_player()
    if not local_player then return false end

    local tick_base = entity.get_prop(local_player, 'm_nTickBase')
    local next_attack = entity.get_prop(local_player, 'm_flNextAttack')
    local weapon = entity.get_player_weapon(local_player)
    local next_primary_attack = weapon and entity.get_prop(weapon, 'm_flNextPrimaryAttack')

    if not tick_base or not next_attack or not next_primary_attack then return false end

    local curtime = globals.tickinterval() * (tick_base - 16)
    if curtime < next_attack then return false end
    if curtime < next_primary_attack then return false end

    return true
end

function exploits.in_recharge ()
    if not (exploits.is_active() and exploits.can_recharge()) or exploits.in_defensive() then return false end
    local latency_shift = math.ceil(toticks(client.latency()) * 1.25)
    local current_shift_amount = ((exploits.tickbase_difference - globals.tickcount()) * -1) + latency_shift
    local max_shift_amount = (exploits.max_process_ticks - 1) - latency_shift
    local min_shift_amount = -(exploits.max_process_ticks - 1) + latency_shift
    
    if latency_shift ~= 0 then
        return current_shift_amount > min_shift_amount and current_shift_amount < max_shift_amount
    else
        return current_shift_amount > (min_shift_amount / 2) and current_shift_amount < (max_shift_amount / 2)
    end
end

function exploits.should_force_defensive (state)
    if not exploits.is_active() then return false end
    exploits.need_force_defensive = state and exploits.is_defensive_ended()
end

function exploits.allow_unsafe_charge (state)
    if not (exploits.is_active() and exploits.can_recharge()) then 
        reference.rage.aimbot.enabled[1]:set_hotkey('Always on')
        return 
    end
    if not state then 
        reference.rage.aimbot.enabled[1]:set_hotkey('Always on')
        return 
    end
    if reference.rage.other.fake_duck:get() then 
        reference.rage.aimbot.enabled[1]:set_hotkey('Always on')
        return
    end
    reference.rage.aimbot.enabled[1]:set_hotkey(exploits.in_recharge() and 'On hotkey' or 'Always on')
end

function exploits.force_reload_exploits (state)
    if not state then
        reference.rage.aimbot.double_tap[1]:set(true)
        reference.antiaim.other.on_shot_anti_aim[1]:set(true)
        return
    end
    if exploits.is_doubletap() and not exploits.in_recharge() then
        reference.rage.aimbot.double_tap[1]:set(false)
    else
        reference.rage.aimbot.double_tap[1]:set(true)
    end
    if exploits.is_hideshots() and not exploits.in_recharge() then
        reference.antiaim.other.on_shot_anti_aim[1]:set(false)
    else
        reference.antiaim.other.on_shot_anti_aim[1]:set(true)
    end
end

local function on_setup_command (ctx)
    if not (entity.get_local_player() and entity.is_alive(entity.get_local_player()) and entity.get_player_weapon(entity.get_local_player())) then 
        return 
    end

    if exploits.need_force_defensive then 
        ctx.force_defensive = true 
    end
end

local function on_run_command (ctx) 
    exploits.store_vars(ctx) 
end

local function on_predict_command (ctx) 
    exploits.store_tickbase_difference(ctx) 
end

local function on_player_death (ctx)
    if not (ctx.userid and ctx.attacker) then 
        return 
    end
    if entity.get_local_player() ~= client.userid_to_entindex(ctx.userid) then 
        return 
    end
    exploits.reset_vars()
end

local function on_level_init () 
    exploits.reset_vars() 
end

local function on_round_start () 
    exploits.reset_vars() 
end

local function on_round_end () 
    exploits.reset_vars() 
end

client.set_event_callback('setup_command', on_setup_command)
client.set_event_callback('run_command', on_run_command)
client.set_event_callback('predict_command', on_predict_command)
client.set_event_callback('player_death', on_player_death)
client.set_event_callback('level_init', on_level_init)
client.set_event_callback('round_start', on_round_start)
client.set_event_callback('round_end', on_round_end)

local fakelag = { choked = 0, active = false }; do
    fakelag.handle = function (e)
        fakelag.choked = e.chokedcommands
        fakelag.active = false
        if reference.antiaim.fakelag.enabled:get() then
            if reference.antiaim.fakelag.limit:get() > 2 then
                if reference.rage.aimbot.double_tap[1].value and reference.rage.aimbot.double_tap[1].hotkey:get() and not reference.rage.other.fake_duck:get() then
                    if fakelag.choked > reference.rage.aimbot.double_tap_limit:get() then
                        fakelag.active = true
                    end
                elseif reference.antiaim.other.on_shot_anti_aim[1].value and reference.antiaim.other.on_shot_anti_aim[1].hotkey:get() and not reference.rage.other.fake_duck:get() then
                    if fakelag.choked > 1 then
                        fakelag.active = true
                    end
                else
                    if fakelag.choked ~= nil then
                        fakelag.active = true
                    end
                end
            end
        end
    end
  
    client.set_event_callback('run_command', fakelag.handle)
end

local builder = {  }; do
    builder.conditions = {'Global', 'Stand', 'Run', 'Walk', 'Crouch', 'Sneak', 'Air', 'Air+', 'Fake lag', 'Freestanding', 'Manual left', 'Manual right'}
    builder.alternative_conditions = {  }
    for _, condition in ipairs(builder.conditions) do
        local prefix = coloring.set_color_macro(false)
        local suffix = coloring.set_color_macro(true)
        table.insert(builder.alternative_conditions, string.format('\a%s•\a%s  %s', prefix, suffix, condition))
    end
    builder.state = 'Global'
    builder.d_state = 'Global'

    elements.conditions = {  }
    elements.conditions.select = menu.group.anti_aim.main:combobox('\v\r    Player state', builder.alternative_conditions)
    
    local is_tab_antiaim = {tab.main, ' Anti-aimbot angles'}
    elements.conditions.select:depend(is_tab_antiaim)

    elements.conditions.select_2 = menu.group.anti_aim.main:combobox('\v\r    Player state', builder.conditions)
    elements.conditions.select_2:set_visible(false)

    elements.conditions.select:set_callback(function (ref)
        for _, condition in ipairs(builder.alternative_conditions) do
            if ref:get() == condition then
                elements.conditions.select_2:set(builder.conditions[_])
            end
        end
    end)

    for i, state in pairs(builder.conditions) do
        local colored_state = builder.alternative_conditions[i]
        elements.conditions[state] = {
            spacing = menu.group.anti_aim.main:label(' \n' .. state),
            enable = menu.group.anti_aim.main:checkbox('Enable  ' .. colored_state),
        
            yaw_base = menu.group.anti_aim.other:combobox('\nYaw base \n' .. state, {'Local view', 'At targets'}),
            spacing_7 = menu.group.anti_aim.other:label('       \n' .. state),
            yaw_left_right = menu.group.anti_aim.other:checkbox('Yaw \v»\r Left  Right mode \n' .. state),

            offset = menu.group.anti_aim.main:slider('\nYaw offset \n' .. state, -180, 180, 0, true, '°'),
            left = menu.group.anti_aim.main:slider('\nYaw left \n' .. state, -180, 180, 0, true, '°'),
            right = menu.group.anti_aim.main:slider('\nYaw right \n' .. state, -180, 180, 0, true, '°'),
        
            spacing_2 = menu.group.anti_aim.main:label('  \n' .. state),
            modifier_label = menu.group.anti_aim.main:label('\v\r    Yaw jitter\n' .. state),
            spacing_8 = menu.group.anti_aim.main:label('        \n' .. state),
            modifier = menu.group.anti_aim.main:combobox('\nYaw modifier \n' .. state, {'Off', 'Offset', 'Center', 'Skitter', 'Random', 'Ways'}),
            modifier_ways = menu.group.anti_aim.main:slider('Modifier Ways \n' .. state, 1, 2, 1, true, 'w', 1, {[1] = '3w', [2] = '5w'}),
            modifier_ways_mode = menu.group.anti_aim.main:combobox('Modifier Ways Type \n' .. state, {'Automatic', 'Custom'}),
            modifier_offset = menu.group.anti_aim.main:slider('\nModifier Offset \n' .. state, -180, 180, 0, true, '°'),
            modifier_offset_2 = menu.group.anti_aim.main:slider('\nModifier Offset #2 \n' .. state, -180, 180, 0, true, '°'),
            modifier_offset_3 = menu.group.anti_aim.main:slider('\nModifier Offset #3 \n' .. state, -180, 180, 0, true, '°'),
            modifier_offset_4 = menu.group.anti_aim.main:slider('\nModifier Offset #4 \n' .. state, -180, 180, 0, true, '°'),
            modifier_offset_5 = menu.group.anti_aim.main:slider('\nModifier Offset #5 \n' .. state, -180, 180, 0, true, '°'),
            modifier_randomization = menu.group.anti_aim.main:slider('Randomization \n' .. state, 0, 90, 0, true, '%'),
        
            spacing_6 = menu.group.anti_aim.main:label('      \n' .. state),
            body_label = menu.group.anti_aim.main:label('\v\r    Body yaw\n' .. state),
            spacing_4 = menu.group.anti_aim.main:label('    \n' .. state),
            body_yaw = menu.group.anti_aim.main:combobox('\nBody yaw \n' .. state, {'Off', 'Opposite', 'Static', 'Jitter'}),
            body_side = menu.group.anti_aim.main:combobox('Body side \n' .. state, {'+', '-'}),
            fs_body_yaw = menu.group.anti_aim.main:checkbox('Freestanding body yaw \n' .. state),

            spacing_3 = menu.group.anti_aim.main:label('   \n' .. state),
            delay_label = menu.group.anti_aim.main:label('\v\r    Delay\n' .. state),
            spacing_9 = menu.group.anti_aim.main:label('         \n' .. state),
            delay = menu.group.anti_aim.main:slider('\nBody delay \n' .. state, 1, 17, 1, true, 't', 1, {[1] = 'OFF'}),
            delay_min = menu.group.anti_aim.main:slider('\nBody Min. delay \n' .. state, 1, 17, 1, true, 't', 1, {[1] = 'OFF'}),
            delay_max = menu.group.anti_aim.main:slider('\nBody Max. delay \n' .. state, 1, 17, 17, true, 't', 1, {[1] = 'OFF'}),
            
            freeze_chance = menu.group.anti_aim.main:slider('\nBody freeze chance \n' .. state, 1, 100, 18, true, '%', 1),
            freeze_time = menu.group.anti_aim.main:slider('\nBody freeze time \n' .. state, 1, 200, 30, true, 'ms', 1),
        
            spacing_5 = menu.group.anti_aim.main:label('     \n' .. state),
            addons = menu.group.anti_aim.main:multiselect('\vDelay »\r Add-ons \n' .. state, {'Randomize Delay Ticks', 'Freeze-Inverter'})
        }
    end

    do
        for i, state in pairs(builder.conditions) do
            local colored_state = builder.alternative_conditions[i]

            local condition = elements.conditions[state]
            local is_condition = {elements.conditions.select, colored_state}
            local disable_shared = {elements.conditions.select, function () return (i ~= 1) end}
            local is_enabled = {condition.enable, function () if i == 1 then return true else return condition.enable:get() end end}
            local fakelag_state = {elements.conditions.select, function () if i == 9 then return false else return true end end}
            local function not_disabled(val) 
                return function () return condition[val]:get() ~= 'Off' end 
            end
        
            condition.spacing:depend(is_tab_antiaim, is_condition, {elements.anti_aim.tab, ' Builder'})
            condition.enable:depend(is_tab_antiaim, is_condition, disable_shared, {elements.anti_aim.tab, ' Builder'})
            
            condition.yaw_base:depend(is_tab_antiaim, is_condition, is_enabled, {elements.anti_aim.tab, ' Builder'})
            condition.spacing_7:depend(is_tab_antiaim, is_condition, is_enabled, {elements.anti_aim.tab, ' Builder'})
            condition.yaw_left_right:depend(is_tab_antiaim, is_condition, is_enabled, {elements.anti_aim.tab, ' Builder'})
            
            condition.offset:depend(is_tab_antiaim, is_condition, is_enabled, {condition.yaw_left_right, false}, {elements.anti_aim.tab, ' Builder'})
            condition.left:depend(is_tab_antiaim, is_condition, is_enabled, {condition.yaw_left_right, true}, {elements.anti_aim.tab, ' Builder'})
            condition.right:depend(is_tab_antiaim, is_condition, is_enabled, {condition.yaw_left_right, true}, {elements.anti_aim.tab, ' Builder'})
        
            condition.spacing_2:depend(is_tab_antiaim, is_condition, is_enabled, {elements.anti_aim.tab, ' Builder'})
            condition.modifier_label:depend(is_tab_antiaim, is_condition, is_enabled, {elements.anti_aim.tab, ' Builder'})
            condition.modifier:depend(is_tab_antiaim, is_condition, is_enabled, {elements.anti_aim.tab, ' Builder'})
            condition.spacing_8:depend(is_tab_antiaim, is_condition, is_enabled, {elements.anti_aim.tab, ' Builder'})
            condition.modifier_ways:depend(is_tab_antiaim, is_condition, is_enabled, {condition.modifier, 'Ways'}, {elements.anti_aim.tab, ' Builder'})
            condition.modifier_ways_mode:depend(is_tab_antiaim, is_condition, is_enabled, {condition.modifier, 'Ways'}, {elements.anti_aim.tab, ' Builder'})
            condition.modifier_offset:depend(is_tab_antiaim, is_condition, is_enabled, {condition.modifier, not_disabled('modifier')}, {elements.anti_aim.tab, ' Builder'})
            condition.modifier_offset_2:depend(is_tab_antiaim, is_condition, is_enabled, {condition.modifier, 'Ways'}, {condition.modifier_ways, function () if condition.modifier_ways.value == 1 or condition.modifier_ways.value == 2 then return true else return false end end}, {condition.modifier_ways_mode, 'Custom'}, {elements.anti_aim.tab, ' Builder'})
            condition.modifier_offset_3:depend(is_tab_antiaim, is_condition, is_enabled, {condition.modifier, 'Ways'}, {condition.modifier_ways, function () if condition.modifier_ways.value == 1 or condition.modifier_ways.value == 2 then return true else return false end end}, {condition.modifier_ways_mode, 'Custom'}, {elements.anti_aim.tab, ' Builder'})
            condition.modifier_offset_4:depend(is_tab_antiaim, is_condition, is_enabled, {condition.modifier, 'Ways'}, {condition.modifier_ways, 2}, {condition.modifier_ways_mode, 'Custom'}, {elements.anti_aim.tab, ' Builder'})
            condition.modifier_offset_5:depend(is_tab_antiaim, is_condition, is_enabled, {condition.modifier, 'Ways'}, {condition.modifier_ways, 2}, {condition.modifier_ways_mode, 'Custom'}, {elements.anti_aim.tab, ' Builder'})
            condition.modifier_randomization:depend(is_tab_antiaim, is_condition, is_enabled, {condition.modifier, function () if condition.modifier:get() == 'Off' or condition.modifier:get() == 'Ways' then return false else return true end end}, {elements.anti_aim.tab, ' Builder'})
        
            condition.spacing_6:depend(is_tab_antiaim, is_condition, is_enabled, {elements.anti_aim.tab, ' Builder'})
            condition.body_label:depend(is_tab_antiaim, is_condition, is_enabled, {elements.anti_aim.tab, ' Builder'})
            condition.spacing_4:depend(is_tab_antiaim, is_condition, is_enabled, {elements.anti_aim.tab, ' Builder'})
            condition.body_yaw:depend(is_tab_antiaim, is_condition, is_enabled, {elements.anti_aim.tab, ' Builder'})
            condition.body_side:depend(is_tab_antiaim, is_condition, is_enabled, {condition.body_yaw, not_disabled('body_yaw')}, {elements.anti_aim.tab, ' Builder'}, {condition.body_yaw, function () if condition.body_yaw:get() == 'Opposite' or condition.body_yaw:get() == 'Jitter' then return false else return true end end})
            condition.fs_body_yaw:depend(is_tab_antiaim, is_condition, is_enabled, {condition.body_yaw, not_disabled('body_yaw')}, {elements.anti_aim.tab, ' Builder'})
            
            condition.spacing_3:depend(is_tab_antiaim, is_condition, is_enabled, {elements.anti_aim.tab, ' Builder', {condition.body_yaw, not_disabled('body_yaw')}})
            condition.delay_label:depend(is_tab_antiaim, is_condition, is_enabled, {elements.anti_aim.tab, ' Builder'}, {condition.body_yaw, not_disabled('body_yaw')})
            condition.spacing_9:depend(is_tab_antiaim, is_condition, is_enabled, {elements.anti_aim.tab, ' Builder', {condition.body_yaw, not_disabled('body_yaw')}})
            condition.delay:depend(is_tab_antiaim, is_condition, is_enabled, {condition.body_yaw, not_disabled('body_yaw')}, {elements.anti_aim.tab, ' Builder'}, {condition.addons, function () if condition.addons:get('Randomize Delay Ticks') then return false else return true end end})
            condition.delay_min:depend(is_tab_antiaim, is_condition, is_enabled, {condition.body_yaw, not_disabled('body_yaw')}, {elements.anti_aim.tab, ' Builder'}, {condition.addons, 'Randomize Delay Ticks'})
            condition.delay_max:depend(is_tab_antiaim, is_condition, is_enabled, {condition.body_yaw, not_disabled('body_yaw')}, {elements.anti_aim.tab, ' Builder'}, {condition.addons, 'Randomize Delay Ticks'})
            condition.freeze_chance:depend(is_tab_antiaim, is_condition, is_enabled, {condition.body_yaw, not_disabled('body_yaw')}, {elements.anti_aim.tab, ' Builder'}, {condition.addons, 'Freeze-Inverter'})
            condition.freeze_time:depend(is_tab_antiaim, is_condition, is_enabled, {condition.body_yaw, not_disabled('body_yaw')}, {elements.anti_aim.tab, ' Builder'}, {condition.addons, 'Freeze-Inverter'})

            condition.spacing_5:depend(is_tab_antiaim, is_condition, is_enabled, {condition.body_yaw, not_disabled('body_yaw')}, {elements.anti_aim.tab, ' Builder'})
            condition.addons:depend(is_tab_antiaim, is_condition, is_enabled, {condition.body_yaw, not_disabled('body_yaw')}, {elements.anti_aim.tab, ' Builder'})
        end
    end

    elements.defensive = {  }
    for i, state in pairs(builder.conditions) do
        local colored_state = builder.alternative_conditions[i]
        elements.defensive[state] = {
            spacing = menu.group.anti_aim.main:label(' \nD_' .. state),
            enable = menu.group.anti_aim.main:checkbox('Enable  ' .. colored_state .. ' \nD'),

            toggle_builder = menu.group.anti_aim.main:checkbox('\nToggle Builder \nD_' .. state),
            defensive_on = menu.group.anti_aim.main:multiselect('\nDefensive \v»\r Work on \nD_' .. state, {'Double tap', 'Hide shots'}),
            defensive_mode = menu.group.anti_aim.main:combobox('\nDefensive \v»\r Mode \nD_' .. state, {'On peek', 'Always on'}),
            spacing_1 = menu.group.anti_aim.main:label('  \nD_' .. state),
        
            pitch_min_max = menu.group.anti_aim.other:checkbox('Pitch \v»\r Min. - Max. mode \nD_' .. state),
            pitch_height_based = menu.group.anti_aim.other:checkbox('Pitch \v»\r Height based value \nD_' .. state),
            yaw_left_right = menu.group.anti_aim.other:checkbox('Yaw \v»\r Left  Right mode \nD_' .. state),
            yaw_generation = menu.group.anti_aim.other:checkbox('Yaw \v»\r Generation \nD_' .. state),

            yaw_label = menu.group.anti_aim.main:label('\v\r    Yaw\nD_' .. state),
            spacing_5 = menu.group.anti_aim.main:label('     \nD_' .. state),
            yaw = menu.group.anti_aim.main:combobox('\nYaw \v»\r Type \nD_' .. state, {'Off', '180', 'Spin', 'Distortion', 'Sway', 'Freestand'}),
            speed = menu.group.anti_aim.main:slider('\nYaw speed \nD_' .. state, 1, 17, 4, true, 't'),
            offset = menu.group.anti_aim.main:slider('\nYaw offset \nD_' .. state, -180, 180, 0, true, '°'),
            left = menu.group.anti_aim.main:slider('\nYaw left \nD_' .. state, -180, 180, 0, true, '°'),
            right = menu.group.anti_aim.main:slider('\nYaw right \nD_' .. state, -180, 180, 0, true, '°'),
            min_gen = menu.group.anti_aim.main:slider('\nYaw min. \nD_' .. state, -180, 180, -20, true, '°-'),
            max_gen = menu.group.anti_aim.main:slider('\nYaw max. \nD_' .. state, -180, 180, 20, true, '°+'),

            spacing_3 = menu.group.anti_aim.main:label('   \nD_' .. state),
            pitch_label = menu.group.anti_aim.main:label('\v\r    Pitch\nD_' .. state),
            spacing_4 = menu.group.anti_aim.main:label('    \nD_' .. state),
            pitch_mode = menu.group.anti_aim.main:combobox('\nPitch \v»\r Mode \nD_' .. state, {'Static', 'Spin', 'Sway', 'Jitter', 'Cycling', 'Random'}),
            pitch_speed = menu.group.anti_aim.main:slider('\nPitch speed \nD_' .. state, 1, 17, 2, true, 't'),
            pitch = menu.group.anti_aim.main:slider('\nPitch \nD_' .. state, -89, 89, 0, true, '°'),
            pitch_min = menu.group.anti_aim.main:slider('\nPitch Min. \nD_' .. state, -89, 89, 0, true, '°'),
            pitch_max = menu.group.anti_aim.main:slider('\nPitch Max. \nD_' .. state, -89, 89, 0, true, '°'),

            spacing_6 = menu.group.anti_aim.main:label('     \nD_' .. state),
            delay_label = menu.group.anti_aim.main:label('\v\r    Delay\nD_' .. state),
            spacing_7 = menu.group.anti_aim.main:label('         \nD_' .. state),
            delay = menu.group.anti_aim.main:slider('\nBody delay \nD_' .. state, 1, 34, 1, true, 't', 1, {[1] = 'OFF'}),
            delay_min = menu.group.anti_aim.main:slider('\nBody Min. delay \nD_' .. state, 1, 34, 1, true, 't', 1, {[1] = 'OFF'}),
            delay_max = menu.group.anti_aim.main:slider('\nBody Max. delay \nD_' .. state, 1, 34, 34, true, 't', 1, {[1] = 'OFF'}),
            
            freeze_chance = menu.group.anti_aim.main:slider('\nBody freeze chance \nD_' .. state, 1, 100, 18, true, '%', 1),
            freeze_time = menu.group.anti_aim.main:slider('\nBody freeze time \nD_' .. state, 1, 200, 30, true, 'ms', 1),
        
            spacing_8 = menu.group.anti_aim.main:label('       \nD_' .. state),
            addons = menu.group.anti_aim.main:multiselect('\vDelay »\r Add-ons \nD_' .. state, {'Randomize Delay Ticks', 'Freeze-Inverter'})
        }
    end

    do
        for i, state in pairs(builder.conditions) do
            local colored_state = builder.alternative_conditions[i]

            local condition = elements.defensive[state]
            local is_condition = {elements.conditions.select, colored_state}
            local disable_shared = {elements.conditions.select, function () return (i ~= 1) end}
            local is_enabled = {condition.enable, function () if i == 1 then return true else return condition.enable:get() end end}
            local fakelag_state = {elements.conditions.select, function () if i == 9 then return false else return true end end}
            local function not_disabled(val) 
                return function () return condition[val]:get() ~= 'Off' end 
            end
        
            condition.spacing:depend(is_tab_antiaim, is_condition, fakelag_state, {elements.anti_aim.tab, ' Defensive'})
            condition.enable:depend(is_tab_antiaim, is_condition, disable_shared, fakelag_state, {elements.anti_aim.tab, ' Defensive'})

            condition.defensive_on:depend(is_tab_antiaim, is_condition, is_enabled, fakelag_state, {elements.anti_aim.tab, ' Defensive'})
            condition.defensive_mode:depend(is_tab_antiaim, is_condition, is_enabled, fakelag_state, {elements.anti_aim.tab, ' Defensive'})
            condition.toggle_builder:depend(is_tab_antiaim, is_condition, is_enabled, fakelag_state, {elements.anti_aim.tab, ' Defensive'})
            condition.spacing_1:depend(is_tab_antiaim, is_condition, is_enabled, fakelag_state, {elements.anti_aim.tab, ' Defensive'})

            condition.pitch_min_max:depend(is_tab_antiaim, is_condition, is_enabled, fakelag_state, {condition.toggle_builder, true}, {condition.pitch_height_based, false}, {elements.anti_aim.tab, ' Defensive'})
            condition.pitch_height_based:depend(is_tab_antiaim, is_condition, is_enabled, fakelag_state, {condition.toggle_builder, true}, {elements.anti_aim.tab, ' Defensive'})
            condition.yaw_left_right:depend(is_tab_antiaim, is_condition, is_enabled, fakelag_state, {condition.toggle_builder, true}, {condition.yaw, not_disabled('yaw')}, {elements.anti_aim.tab, ' Defensive'})
            condition.yaw_generation:depend(is_tab_antiaim, is_condition, is_enabled, fakelag_state, {condition.toggle_builder, true}, {condition.yaw, not_disabled('yaw')}, {elements.anti_aim.tab, ' Defensive'})
            
            condition.spacing_5:depend(is_tab_antiaim, is_condition, is_enabled, fakelag_state, {condition.toggle_builder, true}, {condition.yaw, not_disabled('yaw')}, {elements.anti_aim.tab, ' Defensive'})
            condition.yaw_label:depend(is_tab_antiaim, is_condition, is_enabled, fakelag_state, {condition.toggle_builder, true}, {elements.anti_aim.tab, ' Defensive'})
            condition.yaw:depend(is_tab_antiaim, is_condition, is_enabled, fakelag_state, {condition.toggle_builder, true}, {elements.anti_aim.tab, ' Defensive'})
            condition.speed:depend(is_tab_antiaim, is_condition, is_enabled, fakelag_state, {condition.toggle_builder, true}, {condition.yaw, function () if condition.yaw:get() == 'Off' or condition.yaw:get() == '180' or condition.yaw:get() == 'Spin' or condition.yaw:get() == 'Freestand' then return false else return true end end}, {elements.anti_aim.tab, ' Defensive'})
            condition.offset:depend(is_tab_antiaim, is_condition, is_enabled, fakelag_state, {condition.toggle_builder, true}, {condition.yaw, not_disabled('yaw')}, {condition.yaw_left_right, false}, {elements.anti_aim.tab, ' Defensive'})
            condition.left:depend(is_tab_antiaim, is_condition, is_enabled, fakelag_state, {condition.toggle_builder, true}, {condition.yaw, not_disabled('yaw')}, {condition.yaw_left_right, true}, {elements.anti_aim.tab, ' Defensive'})
            condition.right:depend(is_tab_antiaim, is_condition, is_enabled, fakelag_state, {condition.toggle_builder, true}, {condition.yaw, not_disabled('yaw')}, {condition.yaw_left_right, true}, {elements.anti_aim.tab, ' Defensive'})
            condition.min_gen:depend(is_tab_antiaim, is_condition, is_enabled, fakelag_state, {condition.toggle_builder, true}, {condition.yaw, not_disabled('yaw')}, {condition.yaw_generation, true}, {elements.anti_aim.tab, ' Defensive'})
            condition.max_gen:depend(is_tab_antiaim, is_condition, is_enabled, fakelag_state, {condition.toggle_builder, true}, {condition.yaw, not_disabled('yaw')}, {condition.yaw_generation, true}, {elements.anti_aim.tab, ' Defensive'})

            condition.spacing_3:depend(is_tab_antiaim, is_condition, is_enabled, fakelag_state, {condition.toggle_builder, true}, {elements.anti_aim.tab, ' Defensive'})
            condition.pitch_label:depend(is_tab_antiaim, is_condition, is_enabled, fakelag_state, {condition.toggle_builder, true}, {elements.anti_aim.tab, ' Defensive'})
            condition.spacing_4:depend(is_tab_antiaim, is_condition, is_enabled, fakelag_state, {condition.toggle_builder, true}, {elements.anti_aim.tab, ' Defensive'})
            condition.pitch_mode:depend(is_tab_antiaim, is_condition, is_enabled, fakelag_state, {condition.toggle_builder, true}, {elements.anti_aim.tab, ' Defensive'})
            condition.pitch_speed:depend(is_tab_antiaim, is_condition, is_enabled, fakelag_state, {condition.toggle_builder, true}, {elements.anti_aim.tab, ' Defensive'}, {condition.pitch_mode, function () if condition.pitch_mode:get() == 'Static' or condition.pitch_mode:get() == 'Random' then return false else return true end end})
            condition.pitch:depend(is_tab_antiaim, is_condition, is_enabled, fakelag_state, {condition.toggle_builder, true}, {condition.pitch_min_max, false}, {condition.pitch_height_based, false}, {elements.anti_aim.tab, ' Defensive'})
            condition.pitch_min:depend(is_tab_antiaim, is_condition, is_enabled, fakelag_state, {condition.toggle_builder, true}, {condition.pitch_min_max, true}, {condition.pitch_height_based, false}, {elements.anti_aim.tab, ' Defensive'})
            condition.pitch_max:depend(is_tab_antiaim, is_condition, is_enabled, fakelag_state, {condition.toggle_builder, true}, {condition.pitch_min_max, true}, {condition.pitch_height_based, false}, {condition.pitch_mode, 'Static', true}, {elements.anti_aim.tab, ' Defensive'})

            condition.spacing_6:depend(is_tab_antiaim, is_condition, is_enabled, fakelag_state, {condition.toggle_builder, true}, {elements.anti_aim.tab, ' Defensive'})
            condition.delay_label:depend(is_tab_antiaim, is_condition, is_enabled, fakelag_state, {condition.toggle_builder, true}, {elements.anti_aim.tab, ' Defensive'})
            condition.spacing_7:depend(is_tab_antiaim, is_condition, is_enabled, fakelag_state, {condition.toggle_builder, true}, {elements.anti_aim.tab, ' Defensive'})
            condition.delay:depend(is_tab_antiaim, is_condition, is_enabled, fakelag_state, {condition.toggle_builder, true},{elements.anti_aim.tab, ' Defensive'}, {condition.addons, function () if condition.addons:get('Randomize Delay Ticks') then return false else return true end end})
            condition.delay_min:depend(is_tab_antiaim, is_condition, is_enabled, fakelag_state, {condition.toggle_builder, true}, {elements.anti_aim.tab, ' Defensive'}, {condition.addons, 'Randomize Delay Ticks'})
            condition.delay_max:depend(is_tab_antiaim, is_condition, is_enabled, fakelag_state, {condition.toggle_builder, true}, {elements.anti_aim.tab, ' Defensive'}, {condition.addons, 'Randomize Delay Ticks'})
            condition.freeze_chance:depend(is_tab_antiaim, is_condition, is_enabled, fakelag_state, {condition.toggle_builder, true}, {elements.anti_aim.tab, ' Defensive'}, {condition.addons, 'Freeze-Inverter'})
            condition.freeze_time:depend(is_tab_antiaim, is_condition, is_enabled, fakelag_state, {condition.toggle_builder, true}, {elements.anti_aim.tab, ' Defensive'}, {condition.addons, 'Freeze-Inverter'})

            condition.spacing_8:depend(is_tab_antiaim, is_condition, is_enabled, fakelag_state, {condition.toggle_builder, true}, {elements.anti_aim.tab, ' Defensive'})
            condition.addons:depend(is_tab_antiaim, is_condition, is_enabled, fakelag_state, {condition.toggle_builder, true}, {elements.anti_aim.tab, ' Defensive'})
        end
    end

    local state_logic = {  }
    local state = {
        space = menu.group.anti_aim.other:label(' '),
        export = menu.group.anti_aim.other:button('\v State\r to clipboard', function ()
            state_logic.export()
        end),
        import = menu.group.anti_aim.other:button('\v State\r from clipboard', function ()
            state_logic.import()
        end),
        reset = menu.group.anti_aim.other:button('\v♻️\r Reset', function ()
            state_logic.reset()
        end),
    } do
        state_logic.export = function ()
            local setup = pui.setup(elements.conditions[elements.conditions.select_2:get()], true)
            if elements.anti_aim.tab:get() == ' Defensive' then
                setup = pui.setup(elements.defensive[elements.conditions.select_2:get()], true)
            end
            clipboard.set(base64.encode(json.stringify(setup:save())))
        end

        state_logic.import = function ()
            local setup = pui.setup(elements.conditions[elements.conditions.select_2:get()], true)
            if elements.anti_aim.tab:get() == ' Defensive' then
                setup = pui.setup(elements.defensive[elements.conditions.select_2:get()], true)
            end
            setup:load(json.parse(base64.decode(clipboard.get())))
        end

        state_logic.reset = function ()
            local setup = pui.setup(elements.conditions[elements.conditions.select_2:get()], true)
            local reset = 'eyJlbmFibGUiOmZhbHNlLCJib2R5X3NpZGUiOiIrIiwibW9kaWZpZXJfb2Zmc2V0IjowLCJib2R5X3lhdyI6Ik9mZiIsImFkZG9ucyI6WyJ+Il0sImRlbGF5X21pbiI6MSwib2Zmc2V0IjowLCJkZWxheSI6MSwieWF3X2xlZnRfcmlnaHQiOmZhbHNlLCJ5YXdfYmFzZSI6IkxvY2FsIFZpZXciLCJtb2RpZmllcl9vZmZzZXRfMiI6MCwibW9kaWZpZXJfb2Zmc2V0XzMiOjAsIm1vZGlmaWVyX3dheXNfbW9kZSI6IkF1dG9tYXRpYyIsInJpZ2h0IjowLCJtb2RpZmllcl93YXlzIjoxLCJsZWZ0IjowLCJtb2RpZmllcl9vZmZzZXRfNSI6MCwiZGVsYXlfbWF4IjoxNywiZnJlZXplX3RpbWUiOjMwLCJtb2RpZmllciI6Ik9mZiIsImZyZWV6ZV9jaGFuY2UiOjE4LCJtb2RpZmllcl9vZmZzZXRfNCI6MCwibW9kaWZpZXJfcmFuZG9taXphdGlvbiI6MH0='
            if elements.anti_aim.tab:get() == ' Defensive' then
                setup = pui.setup(elements.defensive[elements.conditions.select_2:get()], true)
                reset = 'eyJlbmFibGUiOmZhbHNlLCJwaXRjaF9tb2RlIjoiU3RhdGljIiwicGl0Y2giOjAsInJpZ2h0IjowLCJtYXhfZ2VuIjoyMCwieWF3IjoiT2ZmIiwidG9nZ2xlX2J1aWxkZXIiOmZhbHNlLCJ5YXdfZ2VuZXJhdGlvbiI6ZmFsc2UsImxlZnQiOjAsIm9mZnNldCI6MCwiZGVmZW5zaXZlX21vZGUiOiJPbiBwZWVrIiwieWF3X2Jhc2UiOiJMb2NhbCB2aWV3IiwiZGVmZW5zaXZlX29uIjpbIn4iXSwibWluX2dlbiI6LTIwLCJ5YXdfbGVmdF9yaWdodCI6ZmFsc2V9'
            end
            setup:load(json.parse(base64.decode(reset)))
        end

        pui.traverse(state, function (ref)
            ref:depend({tab.main, ' Anti-aimbot angles'}, {elements.anti_aim.tab, ' Other', true})
        end)
    end

    builder.manual_tick = 0
    local function manual ()
        local manual_mode = elements.anti_aim.hotkeys.manual_mode.value
        if manual_mode == 'Default' or manual_mode == 'Spam' then
            builder.selected_manual = builder.selected_manual or 0
            local tick = globals.tickcount()

            local function handle_press(key, value)
                if elements.anti_aim.hotkeys[key]:get() and (manual_mode == 'Default' and not builder[key..'_pressed'] or manual_mode == 'Spam' and builder.manual_tick < tick - 11) then
                    builder.selected_manual = builder.selected_manual == value and 0 or value
                    builder.manual_tick = tick
                end
                builder[key..'_pressed'] = elements.anti_aim.hotkeys[key]:get()
            end

            handle_press('left', 1)
            handle_press('right', 2)
            handle_press('forward', 3)
            
            if elements.anti_aim.hotkeys.reset:get() and not builder.reset_pressed then
                builder.selected_manual = 0
            end
            builder.reset_pressed = elements.anti_aim.hotkeys.reset:get()

            return builder.selected_manual
        end
    end

    builder.side = 1
    builder.delay_ticks = {default = 0, defensive = 0}
    local function inverter (e, state)
        local me = entity.get_local_player()
        local body_yaw = math.floor(entity.get_prop(me, 'm_flPoseParameter', 11) * 120 - 60)
        local condition = elements.conditions
        local delay_key = 'default'

        if e.chokedcommands == 0 then
            local current_tick = globals.tickcount()
            if elements.conditions[state].body_yaw:get() ~= 'Off' then
                if condition[state].delay:get() > 1 or condition[state].addons:get('Randomize Delay Ticks') then
                    local delay = condition[state].delay:get()
                    if condition[state].addons:get('Randomize Delay Ticks') then
                        local delay_min = condition[state].delay_min:get()
                        local delay_max = condition[state].delay_max:get()
                        delay = client.random_int(delay_min, delay_max)
                    end

                    -- print(builder.delay_ticks[delay_key] < current_tick - delay)
                    if builder.delay_ticks[delay_key] < current_tick - delay then
                        builder.delay_ticks[delay_key] = current_tick
                        builder.side = builder.side == 1 and -1 or 1
                    end
                elseif condition[state].delay:get() == 1 then
                    builder.side = (body_yaw > 0 and 1 or body_yaw < 0 and -1)
                end
            else
                if builder.delay_ticks[delay_key] < current_tick - 1 then
                    builder.delay_ticks[delay_key] = current_tick
                    builder.side = builder.side == 1 and -1 or 1
                end
            end
        end

        return builder.side
    end

    -- @lordmouse: TODO исправить это говнище и сделать всё в одной функции
    builder.d_side = 1
    local function d_inverter (e, state)
        local me = entity.get_local_player()
        local body_yaw = math.floor(entity.get_prop(me, 'm_flPoseParameter', 11) * 120 - 60)
        local condition = elements.defensive
        local delay_key = 'defensive'

        if e.chokedcommands == 0 then
            local current_tick = globals.tickcount()
            -- if elements.conditions[state].body_yaw:get() ~= 'Off' then
                if condition[state].delay:get() > 1 or condition[state].addons:get('Randomize Delay Ticks') then
                    local delay = condition[state].delay:get()
                    if condition[state].addons:get('Randomize Delay Ticks') then
                        local delay_min = condition[state].delay_min:get()
                        local delay_max = condition[state].delay_max:get()
                        delay = client.random_int(delay_min, delay_max)
                    end

                    -- print(builder.delay_ticks[delay_key] < current_tick - delay)
                    if builder.delay_ticks[delay_key] < current_tick - delay then
                        builder.delay_ticks[delay_key] = current_tick
                        builder.d_side = builder.d_side == 1 and -1 or 1
                    end
                elseif condition[state].delay:get() == 1 then
                    builder.d_side = (body_yaw > 0 and 1 or body_yaw < 0 and -1)
                end
            -- else
            --     if builder.delay_ticks[delay_key] < current_tick - 1 then
            --         builder.delay_ticks[delay_key] = current_tick
            --         builder.d_side = builder.d_side == 1 and -1 or 1
            --     end
            -- end
        end

        return builder.d_side
    end

    local function is_condition_enabled(table, condition)
        return table[condition] and table[condition].enable:get()
    end

    function builder.get_state ()
        local condition = helpers.get_state()

        if not (is_condition_enabled(elements.conditions, condition)) then
            condition = 'Global'
        end

        if reference.antiaim.fakelag.enabled:get() then
            if is_condition_enabled(elements.conditions, 'Fake lag') then
                if fakelag.active then
                    condition = 'Fake lag'
                end
            end
        end

        if (is_condition_enabled(elements.conditions, 'Freestanding')) and reference.antiaim.angles.freestanding[1]:get() and reference.antiaim.angles.freestanding[1].hotkey:get() then
            condition = 'Freestanding'
        end

        local manual_aa = manual()
        if manual_aa == 1 then
            condition = 'Manual left'
        elseif manual_aa == 2 then
            condition = 'Manual right'
        end

        return condition
    end

    function builder.d_get_state ()
        local condition = helpers.get_state()

        if not (is_condition_enabled(elements.defensive, condition)) then
            condition = 'Global'
        end

        if (is_condition_enabled(elements.defensive, 'Freestanding')) and reference.antiaim.angles.freestanding[1]:get() and reference.antiaim.angles.freestanding[1].hotkey:get() then
            condition = 'Freestanding'
        end

        local manual_aa = manual()
        if manual_aa == 1 then
            condition = 'Manual left'
        elseif manual_aa == 2 then
            condition = 'Manual right'
        end

        return condition
    end

    local pitch_add = 0
    local generated_yaw = 0
    local function on_setup_command (e)
        builder.state = builder.get_state()

        exploits.should_force_defensive(false)
        reference.rage.aimbot.double_tap[1]:override() reference.rage.aimbot.double_tap[2]:override()
        
        local pitch, pitch_offset = 'down', 89
        local yaw = '180'
        local yaw_base, offset, yaw_jitter, jitter_offset, body_yaw, body_side, fs_body_yaw = elements.conditions[builder.state].yaw_base:get(), elements.conditions[builder.state].offset:get(), elements.conditions[builder.state].modifier:get(), elements.conditions[builder.state].modifier_offset:get(), elements.conditions[builder.state].body_yaw:get(), elements.conditions[builder.state].body_side:get(), elements.conditions[builder.state].fs_body_yaw:get()
        
        local body_side_value = 1
        if body_yaw == 'Static' then
            if body_side == '-' then
                body_side_value = -1
            end
        end

        local left, right = elements.conditions[builder.state].left:get(), elements.conditions[builder.state].right:get()
        local inverted = inverter(e, builder.state)
        if elements.conditions[builder.state].yaw_left_right:get() then
            offset = (inverted == 1 and left or inverted == -1 and right) or left
        end

        if yaw_jitter ~= 'Off' and elements.conditions[builder.state].modifier_randomization:get() > 0 then
            local randomization_factor = elements.conditions[builder.state].modifier_randomization:get()
            local random_seed = globals.tickcount() % 100
            local random_offset = client.random_int(-randomization_factor, randomization_factor)
            
            if random_seed < 33 then
                jitter_offset = jitter_offset + random_offset
            elseif random_seed < 66 then
                jitter_offset = jitter_offset - random_offset
            else
                jitter_offset = jitter_offset + client.random_int(-randomization_factor / 2, randomization_factor / 2)
            end
        end

        if body_yaw ~= 'Off' then
            if elements.conditions[builder.state].delay:get() > 1 then
                body_side_value = (inverted == 1 and -1 or inverted == -1 and 1) or 1
                body_yaw = 'Static'

                if yaw_jitter ~= 'Off' then
                    if yaw_jitter == 'Offset' then
                        offset = offset + (inverted == -1 and jitter_offset or 0)
                    elseif yaw_jitter == 'Center' then
                        offset = offset + ((inverted == 1 and -jitter_offset / 2 or inverted == -1 and jitter_offset / 2) or 0)
                    end

                    yaw_jitter = 'Off'  
                end
            end
        end

        local manual_aa = manual()
        local manual_offsets = {-90, 90, 180}
        if manual_aa >= 1 and manual_aa <= 3 then
            local condition_met = (manual_aa == 1 and not elements.conditions['Manual left'].enable.value) or (manual_aa == 2 and not elements.conditions['Manual right'].enable.value) or (manual_aa == 3)
            
            if condition_met then
                offset = manual_offsets[manual_aa]
                yaw_base = 'Local View'
                yaw_jitter = 'Off'
                body_yaw = 'Static'
                body_side_value = 11
            end
        end

        builder.d_state = builder.d_get_state()

        local defensive = {
            yaw = elements.defensive[builder.d_state].yaw:get(),
            speed = elements.defensive[builder.d_state].speed:get(),
            offset = elements.defensive[builder.d_state].offset:get(),
            left = elements.defensive[builder.d_state].left:get(),
            right = elements.defensive[builder.d_state].right:get(),
            min_gen = elements.defensive[builder.d_state].min_gen:get(),
            max_gen = elements.defensive[builder.d_state].max_gen:get(),
            pitch_min_max = elements.defensive[builder.d_state].pitch_min_max:get(),
            pitch_height_based = elements.defensive[builder.d_state].pitch_height_based:get(),
            yaw_left_right = elements.defensive[builder.d_state].yaw_left_right:get(),
            yaw_generation = elements.defensive[builder.d_state].yaw_generation:get(),
            pitch_mode = elements.defensive[builder.d_state].pitch_mode:get(),
            pitch_speed = elements.defensive[builder.d_state].pitch_speed:get(),
            pitch = elements.defensive[builder.d_state].pitch:get(),
            pitch_min = elements.defensive[builder.d_state].pitch_min:get(),
            pitch_max = elements.defensive[builder.d_state].pitch_max:get()
        }

        if elements.defensive[builder.d_state].enable:get() and not (elements.aimbot.auto_discharge.enable:get() and elements.aimbot.auto_discharge.enable.hotkey:get()) then
            if (elements.defensive[builder.d_state].defensive_on:get('Double tap') and exploits.is_doubletap()) or (elements.defensive[builder.d_state].defensive_on:get('Hide shots') and exploits.is_hideshots() and not exploits.is_doubletap()) then
                if elements.defensive[builder.d_state].defensive_mode:get() == 'On peek' then
                    exploits.should_force_defensive(false)
                elseif elements.defensive[builder.d_state].defensive_mode:get() == 'Always on' then
                    exploits.should_force_defensive(true)
                end

                local disable_defensive_aa = false
                local threat = client.current_threat()
                if elements.anti_aim.settings.list:get('Off defensive aa vs low ping') and threat then
                    local resource = entity.get_player_resource(threat)
                    if not resource then 
                        disable_defensive_aa = true
                    end

                    local ping = entity.get_prop(resource, 'm_iPing', threat)
                    if not ping or (ping < 15) then 
                        disable_defensive_aa = true 
                    end
                end
    
                if elements.defensive[builder.d_state].toggle_builder:get() and exploits.in_defensive() and not disable_defensive_aa then
                    local d_inverted = d_inverter(e, builder.d_state)

                    pitch = 'custom'
                    pitch_offset = defensive.pitch
                    yaw = defensive.yaw
                    offset = defensive.offset
                    yaw_jitter = 'Off'
    
                    -- @lordmouse: TODO fix this shitcode
                    if defensive.pitch_height_based then
                        local my_pos = vector(entity.get_origin(entity.get_local_player()))
                        local threat = client.current_threat()
                        local height_diff = 0
                        if threat then
                            local enemy_pos = vector(entity.get_origin(threat))
                            height_diff = math.ceil(my_pos.z - enemy_pos.z)
                        end

                        local height_based_min = math.max(-89, -89 + height_diff)
                        local height_based_max = math.min(89, 89 + height_diff)

                        if defensive.pitch_mode == 'Jitter' then
                            local speed = math.max(1, math.min(defensive.pitch_speed, 15))
                            local interval = math.floor(math.floor(1 / globals.tickinterval()) / speed)
                            local phase = math.floor(globals.tickcount() / interval) % 2
                            pitch = 'custom'
                            pitch_offset = (phase == 0) and height_based_min or height_based_max
                        elseif defensive.pitch_mode == 'Random' then
                            pitch = 'custom'
                            pitch_offset = client.random_int(height_based_min, height_based_max)
                        elseif defensive.pitch_mode == 'Cycling' then
                            local cycle_speed = defensive.pitch_speed
                            if pitch_add >= height_based_max then pitch_add = height_based_min else pitch_add = pitch_add + cycle_speed end
                            pitch = 'custom'
                            pitch_offset = pitch_add
                        elseif defensive.pitch_mode == 'Spin' then
                            local spin_speed = defensive.pitch_speed
                            local mid = (height_based_min + height_based_max) / 2
                            local amp = math.abs(height_based_max - height_based_min) / 2
                            pitch = 'custom'
                            pitch_offset = mid + math.sin(globals.realtime() * spin_speed) * amp
                        elseif defensive.pitch_mode == 'Sway' then
                            local sway_speed = defensive.pitch_speed
                            local mid = (height_based_min + height_based_max) / 2
                            local amp = math.abs(height_based_max - height_based_min) / 2
                            pitch = 'custom'
                            pitch_offset = mid + math.sin(globals.realtime() * sway_speed) * amp * (math.cos(globals.realtime() * sway_speed * 0.5) + 1) / 2
                        else
                            pitch = 'custom'
                            pitch_offset = height_based_min
                        end
                    elseif defensive.pitch_min_max then
                        if defensive.pitch_mode == 'Jitter' then
                            local speed = math.max(1, math.min(defensive.pitch_speed, 15))
                            local interval = math.floor(math.floor(1 / globals.tickinterval()) / speed)
                            local phase = math.floor(globals.tickcount() / interval) % 2
                            pitch = 'custom'
                            pitch_offset = (phase == 0) and defensive.pitch_min or defensive.pitch_max
                        elseif defensive.pitch_mode == 'Random' then
                            pitch = 'custom'
                            pitch_offset = client.random_int(defensive.pitch_min, defensive.pitch_max)
                        elseif defensive.pitch_mode == 'Cycling' then
                            local cycle_speed = defensive.pitch_speed
                            if pitch_add >= defensive.pitch_max then pitch_add = defensive.pitch_min else pitch_add = pitch_add + cycle_speed end
                            pitch = 'custom'
                            pitch_offset = pitch_add
                        elseif defensive.pitch_mode == 'Spin' then
                            local spin_speed = defensive.pitch_speed
                            local mid = (defensive.pitch_min + defensive.pitch_max) / 2
                            local amp = math.abs(defensive.pitch_max - defensive.pitch_min) / 2
                            pitch = 'custom'
                            pitch_offset = mid + math.sin(globals.realtime() * spin_speed) * amp
                        elseif defensive.pitch_mode == 'Sway' then
                            local sway_speed = defensive.pitch_speed
                            local mid = (defensive.pitch_min + defensive.pitch_max) / 2
                            local amp = math.abs(defensive.pitch_max - defensive.pitch_min) / 2
                            pitch = 'custom'
                            pitch_offset = mid + math.sin(globals.realtime() * sway_speed) * amp * (math.cos(globals.realtime() * sway_speed * 0.5) + 1) / 2
                        else
                            pitch = 'custom'
                            pitch_offset = defensive.pitch_min
                        end
                    else
                        pitch = 'custom'
                        pitch_offset = defensive.pitch
                        if defensive.pitch_mode == 'Spin' then
                            local spin_speed = defensive.pitch_speed
                            pitch_offset = math.sin(globals.realtime() * spin_speed) * pitch_offset
                        elseif defensive.pitch_mode == 'Sway' then
                            local sway_speed = defensive.pitch_speed
                            local sway_amplitude = pitch_offset * 0.5
                            pitch_offset = math.sin(globals.realtime() * sway_speed) * sway_amplitude * (math.cos(globals.realtime() * sway_speed * 0.5) + 1)
                        elseif defensive.pitch_mode == 'Jitter' then
                            local speed = math.max(1, math.min(defensive.pitch_speed, 15))
                            local interval = math.floor(math.floor(1 / globals.tickinterval()) / speed)
                            local phase = math.floor(globals.tickcount() / interval) % 2
                            local switch_amount = (phase == 0) and pitch_offset or -pitch_offset
                            pitch_offset = switch_amount
                        elseif defensive.pitch_mode == 'Cycling' then
                            local cycle_speed = defensive.pitch_speed
                            if pitch_add >= -pitch_offset then pitch_add = pitch_offset else pitch_add = pitch_add + cycle_speed end
                            pitch_offset = pitch_add
                        elseif defensive.pitch_mode == 'Random' then
                            pitch_offset = client.random_int(-pitch_offset, pitch_offset)
                        end
                    end
    
                    if defensive.yaw_left_right then
                        offset = (d_inverted == 1 and defensive.left or d_inverted == -1 and defensive.right) or defensive.left
                    end
    
                    if defensive.yaw_generation then
                        local min_gen, max_gen = defensive.min_gen, defensive.max_gen
                        if exploits.is_defensive_ended() then
                            generated_yaw = nil
                        elseif exploits.in_defensive() then
                            if not generated_yaw then
                                generated_yaw = client.random_int(min_gen, max_gen)
                            end

                            offset = offset + generated_yaw
                        end
                    end
    
                    if yaw == 'Distortion' then
                        yaw = '180'
                        local distortion_speed = defensive.speed
                        local distortion_amplitude = offset * 1.5
                        local distortion_time = globals.realtime() * distortion_speed
                        offset = offset + math.sin(distortion_time) * distortion_amplitude
                    elseif yaw == 'Sway' then
                        yaw = '180'
                        local sway_speed = defensive.speed
                        local sway_amplitude = offset
                        local sway_time = globals.realtime() * sway_speed
                        offset = offset + math.sin(sway_time) * sway_amplitude * (math.cos(sway_time * 0.5) + 1) / 2
                    elseif yaw == 'Freestand' then
                        yaw = '180'
                        offset = offset + helpers.get_freestand_direction(entity.get_local_player()) == -1 and -offset or offset
                    end
                end
            end
        end

        reference.rage.aimbot.double_tap[1]:override(not helpers.disable_doubletap)
        reference.rage.aimbot.double_tap[2]:override('Defensive')
        helpers.disable_doubletap = false

        return {
            pitch = pitch,
            pitch_offset = pitch_offset,
            yaw = yaw,
            yaw_base = yaw_base,
            offset = offset,
            yaw_jitter = yaw_jitter,
            jitter_offset = jitter_offset,
            body_yaw = body_yaw,
            body_side = body_side_value,
            fs_body_yaw = fs_body_yaw
        }
    end

    local function set_angles (e)
        local angles = on_setup_command(e)

        if elements.anti_aim.exploits.exploit:get() and elements.anti_aim.exploits.exploit.hotkey:get() then
            e.pitch = -540
            e.yaw = e.yaw + 180 + helpers:clamp(angles.offset, -180, 180)
            return
        end

        reference.antiaim.angles.enabled:override(true)
        reference.antiaim.angles.pitch[1]:override(angles.pitch)
        reference.antiaim.angles.pitch[2]:override(helpers:clamp(angles.pitch_offset, -89, 89))

        reference.antiaim.angles.yaw[1]:override(angles.yaw)
        reference.antiaim.angles.yaw_base:override(angles.yaw_base)

        reference.antiaim.angles.freestanding[1]:override(elements.anti_aim.hotkeys.freestanding.value and elements.anti_aim.hotkeys.freestanding.hotkey:get() or false)
        reference.antiaim.angles.freestanding[1]:set_hotkey('Always On')
        reference.antiaim.angles.edge_yaw:override(elements.anti_aim.hotkeys.edge_yaw.value and elements.anti_aim.hotkeys.edge_yaw.hotkey:get() or false)
        
        reference.antiaim.angles.yaw[2]:override(helpers:clamp(angles.offset, -180, 180))
        reference.antiaim.angles.yaw_jitter[1]:override(angles.yaw_jitter)
        reference.antiaim.angles.yaw_jitter[2]:override(helpers:clamp(angles.jitter_offset, -180, 180))
        
        reference.antiaim.angles.body_yaw[1]:override(angles.body_yaw)
        reference.antiaim.angles.body_yaw[2]:override(angles.body_side)
        reference.antiaim.angles.fs_body_yaw:override(angles.fs_body_yaw)
    end

    client.set_event_callback('setup_command', set_angles)

    local function is_enemies_dead ()
        if not elements.anti_aim.settings.list:get('Spin if enemies dead') then
          return
        end
  
        local alive = 0
        for i = 1, globals.maxplayers() do
          if entity.get_classname(i) == 'CCSPlayer' and entity.is_alive(i) and entity.is_enemy(i) then
            alive = alive + 1
          end
        end

        return alive
    end

    local function on_setup_command_2 (e)
        local me = entity.get_local_player()
        if not me or not entity.is_alive(me) then
            return
        end

        builder.state = builder.get_state()

        -- @lordmouse: safe head
        local weapon = entity.get_player_weapon(me)
        local weapon_class = entity.get_classname(weapon)
        if elements.anti_aim.settings.list:get('Safe head') and weapon and weapon_class and manual() ~= 3 then
            local safe_weapons = {
                CKnife = 'Knife',
                CWeaponTaser = 'Taser'
            }
            
            local is_safe_state = (builder.state == 'Air+' or not ground_tick and builder.state == 'Fake lag' and entity.get_prop(me, 'm_flDuckAmount') == 1)
            
            local my_pos = vector(entity.get_origin(me))
            local threat = client.current_threat()
            local height_to_threat = 0
            if threat then
                local enemy_pos = vector(entity.get_origin(threat))
                height_to_threat = math.ceil(my_pos.z - enemy_pos.z)
            end

            for sel_weapon, weapons in pairs(safe_weapons) do
                if is_safe_state and ((safe_weapons[weapon_class] and elements.anti_aim.settings.safe_head_options:get(safe_weapons[weapon_class])) or (height_to_threat > 100 and elements.anti_aim.settings.safe_head_options:get('Height advantage'))) then
                    if elements.anti_aim.settings.safe_head_mode:get() == 'Defensive' then
                        if exploits.is_active() and not exploits.in_recharge() then
                            exploits.should_force_defensive(true)
                            
                            reference.antiaim.angles.pitch[1]:override(exploits.in_defensive() and 'Custom' or 'Down')
                            reference.antiaim.angles.pitch[2]:override(0)
                            reference.antiaim.angles.yaw[2]:override(exploits.in_defensive() and 180 or 0)
                            reference.antiaim.angles.body_yaw[1]:override(exploits.in_defensive() and 'Static' or 'Off')
                            reference.antiaim.angles.body_yaw[2]:override(1)
                        else
                            exploits.should_force_defensive(false)

                            reference.antiaim.angles.pitch[1]:override('Down')
                            reference.antiaim.angles.yaw[2]:override(0)
                            reference.antiaim.angles.body_yaw[1]:override('Off')
                            reference.antiaim.angles.body_yaw[2]:override(0)
                        end
                    else
                        exploits.should_force_defensive(false)

                        reference.antiaim.angles.pitch[1]:override('Down')
                        reference.antiaim.angles.yaw[2]:override(0)
                        reference.antiaim.angles.body_yaw[1]:override('Off')
                        reference.antiaim.angles.body_yaw[2]:override(0)
                    end
                    reference.antiaim.angles.yaw_base:override('At Targets')
                    reference.antiaim.angles.yaw[1]:override('180')
                    reference.antiaim.angles.yaw_jitter[1]:override('Off')
                    reference.antiaim.angles.yaw_jitter[2]:override(0)
                end
            end
        end
        
        -- @lordmouse: spin if enemies dead or warmup
        reference.antiaim.fakelag.limit:override()
        if elements.anti_aim.settings.list:get('Spin if enemies dead') and is_enemies_dead() == 0 or elements.anti_aim.settings.list:get('Spin on warmup') and entity.get_prop(entity.get_all('CCSGameRulesProxy')[1],'m_bWarmupPeriod') == 1 then
            reference.antiaim.angles.pitch[1]:override('Custom')
            reference.antiaim.angles.pitch[2]:override(0)
            reference.antiaim.angles.yaw[1]:override('Spin')
            reference.antiaim.angles.yaw[2]:override(5)
            reference.antiaim.angles.yaw_jitter[1]:override('Off')
            reference.antiaim.angles.yaw_jitter[2]:override(0)
            reference.antiaim.angles.body_yaw[1]:override('Static')
            reference.antiaim.angles.body_yaw[2]:override(1)

            reference.antiaim.fakelag.limit:override(1)
        end

        -- @lordmouse: anti-backstab
        if elements.anti_aim.settings.list:get('Anti backstab') then
            local players = entity.get_players(true)
            local local_pos = vector(entity.get_prop(me, 'm_vecOrigin'))

            for i = 1, #players do
                local player_pos = vector(entity.get_prop(players[i], 'm_vecOrigin'))
                local enemy_weapon = entity.get_player_weapon(players[i])

                if entity.get_classname(enemy_weapon) == 'CKnife' and local_pos:dist(player_pos) <= 450 then
                    local eye_pos = vector(client.eye_position())
                    local hitbox_pos = vector(entity.hitbox_position(players[i], 4))
                
                    local fraction, entindex_hit = client.trace_line(players[i], hitbox_pos.x, hitbox_pos.y, hitbox_pos.z, eye_pos.x, eye_pos.y, eye_pos.z)

                    if entindex_hit == me or fraction == 1 then
                        reference.antiaim.angles.pitch[1]:override('Down')
                        reference.antiaim.angles.yaw_base:override('At Targets')
                        reference.antiaim.angles.yaw[1]:override('180')
                        reference.antiaim.angles.yaw[2]:override(180)
                        reference.antiaim.angles.yaw_jitter[1]:override('Off')
                        reference.antiaim.angles.yaw_jitter[2]:override(0)
                    end
                end
            end
        end

        if elements.anti_aim.settings.list:get('Fast ladder') then
            local pitch, yaw = client.camera_angles()
            local move_type = entity.get_prop(me, 'm_MoveType')
            local weapon = entity.get_player_weapon(me)
            local throw = entity.get_prop(weapon, 'm_fThrowTime')
        
            if move_type ~= 9 then
                return
            end
        
            if weapon == nil then
                return
            end
        
            if throw ~= nil and throw ~= 0 then
                return
            end	
        
            if e.forwardmove > 0 then
                if e.pitch < 45 then
                    e.pitch = 89
                    e.in_moveright = 1
                    e.in_moveleft = 0
                    e.in_forward = 0
                    e.in_back = 1
            
                    if e.sidemove == 0 then
                        e.yaw = e.yaw + 90
                    end
            
                    if e.sidemove < 0 then
                        e.yaw = e.yaw + 150
                    end
            
                    if e.sidemove > 0 then
                        e.yaw = e.yaw + 30
                    end
                end
            elseif e.forwardmove < 0 then
                e.pitch = 89
                e.in_moveleft = 1
                e.in_moveright = 0
                e.in_forward = 1
                e.in_back = 0
        
                if e.sidemove == 0 then
                    e.yaw = e.yaw + 90
                end
        
                if e.sidemove > 0 then
                    e.yaw = e.yaw + 150
                end
        
                if e.sidemove < 0 then
                    e.yaw = e.yaw + 30
                end
            end
        end

        -- @lordmouse: bombsite fix
        if elements.anti_aim.settings.list:get('E-Bombsite fix') then
            if entity.get_prop(me, 'm_iTeamNum') == 2 then
                if entity.get_prop(me, 'm_bInBombZone') > 0 then
                    if bit.band(e.buttons, 32) == 32 and entity.get_classname(weapon) ~= 'CC4' then
                        e.buttons = bit.band(e.buttons, bit.bnot(32))
                        reference.antiaim.angles.yaw_base:override('Local View')
                        reference.antiaim.angles.pitch[1]:override('Custom')
                        reference.antiaim.angles.pitch[2]:override(0)
                        reference.antiaim.angles.yaw[1]:override('180')
                        reference.antiaim.angles.yaw[2]:override(180)
                        reference.antiaim.angles.yaw_jitter[1]:override('Off')
                        reference.antiaim.angles.yaw_jitter[2]:override(0)
                        reference.antiaim.angles.body_yaw[1]:override('Static')
                        reference.antiaim.angles.body_yaw[2]:override(1)
                    end
                end
            end
        end
    end

    client.set_event_callback('setup_command', on_setup_command_2)

    local function reset_everything ()
        builder.manual_tick = 0
        builder.side = 1
        builder.delay_ticks.default = 0
        builder.delay_ticks.defensive = 0
        builder.d_side = 1
    end

    local function on_player_death (e)
        if not (e.userid and e.attacker) then
            return 
        end

        if entity.get_local_player() ~= client.userid_to_entindex(e.userid) then 
            return 
        end
        
        reset_everything()
    end
    
    local function on_level_init () 
        reset_everything() 
    end
    
    local function on_round_start () 
        reset_everything() 
    end
    
    local function on_round_end () 
        reset_everything() 
    end

    client.set_event_callback('player_death', on_player_death)
    client.set_event_callback('level_init', on_level_init)
    client.set_event_callback('round_start', on_round_start)
    client.set_event_callback('round_end', on_round_end)
end

---

local unsafe_recharge do
    local function on_setup_command ()
        exploits.allow_unsafe_charge(elements.aimbot.unsafe_exploit:get())
    end

    client.set_event_callback('setup_command', on_setup_command)
end

local auto_discharge do
    local exploit_active = false
    local function on_setup_command ()
        if not elements.aimbot.auto_discharge.enable:get() then
            return
        end

        if not elements.aimbot.auto_discharge.enable.hotkey:get() then
            return
        end

        if not exploits.is_doubletap() then
            return
        end

        local state = helpers.get_state()
        if state == 'Air' or state == 'Air+' then
            if elements.aimbot.auto_discharge.settings.mode:get() == 'Air lag' then
                exploits.should_force_defensive(true)
                if elements.aimbot.auto_discharge.settings.air_lag_mode:get() == 'Fast' and (exploits.ticks_processed > 1 and exploits.ticks_processed < exploits.max_process_ticks and exploits.tickbase_difference > 0) or (exploits.ticks_processed > 1 and exploits.ticks_processed > 13 and exploits.tickbase_difference > 0) then
                    helpers.disable_doubletap = true
                    exploit_active = true
                else
                    exploit_active = false
                end
            elseif elements.aimbot.auto_discharge.settings.mode:get() == 'Default' then

            end
        end
    end

    client.set_event_callback('setup_command', on_setup_command)

    local function on_paint ()
        if not elements.aimbot.auto_discharge.enable:get() then
            return
        end

        if elements.aimbot.auto_discharge.enable.hotkey:get() and exploits.is_doubletap() then
            local state = helpers.get_state()
            local r, g, b, a = 255, 0, 50, 255
            if exploit_active then
                r, g, b, a = 255, 255, 255, 255
            end
            renderer.indicator(r, g, b, a, 'LAG')
        end
    end

    client.set_event_callback('paint', on_paint)
end

local auto_hide_shots = { hotkey = nil }; do
    local function on_setup_command ()
        if not elements.aimbot.auto_hs.enable:get() then
            return
        end
      
        if not auto_hide_shots.hotkey then
            auto_hide_shots.hotkey = { reference.antiaim.other.on_shot_anti_aim[1]:get_hotkey() }
        end
      
        local me = entity.get_local_player()
        if not me or not entity.is_alive(me) then
            return
        end
      
        local condition = builder.get_state()
      
        local avoid_guns = {
            ['Pistols'] = { 'CWeaponGlock', 'CWeaponHKP2000', 'CWeaponP250', 'CWeaponTec9', 'CWeaponFiveSeven' },
            ['Desert Eagle'] = { 'CDEagle' },
            ['Auto Snipers'] = { 'CWeaponSCAR20', 'CWeaponG3SG1' },
            ['Desert Eagle + Crouch'] = { 'CDEagle' }
        }
      
        if elements.aimbot.auto_hs.settings.state:get(condition) then
            local weapon = entity.get_player_weapon(me)
            if not weapon then
                return
            end
      
            local weapon_classname = entity.get_classname(weapon)
            local is_crouching = entity.get_prop(me, 'm_flDuckAmount') == 1
            local should_avoid = false
      
            for avoid_type, weapons in pairs(avoid_guns) do
                for _, weapon_name in ipairs(weapons) do
                    if weapon_classname == weapon_name then
                        if avoid_type == 'Desert Eagle + Crouch' and not is_crouching then
                            break
                        end
                        if elements.aimbot.auto_hs.settings.avoid_guns:get(avoid_type) then
                            should_avoid = true
                            break
                        end
                    end
                end
                if should_avoid then
                    break
                end
            end
      
            if not should_avoid then
                helpers.disable_doubletap = true
                reference.antiaim.other.on_shot_anti_aim[1]:set_hotkey('Always On')
            else
                local mode_number = auto_hide_shots.hotkey[2]
                local mode_new = 'On hotkey'
                if mode_number == 0 then
                    mode_new = 'Always on'
                elseif mode_number == 1 then
                    mode_new = 'On hotkey'
                elseif mode_number == 2 then
                    mode_new = 'Toggle'
                elseif mode_number == 3 then
                    mode_new = 'Off hotkey'
                end
                reference.antiaim.other.on_shot_anti_aim[1]:set_hotkey(mode_new)
            end
        end
    end

    client.set_event_callback('setup_command', on_setup_command)
end

local aimbot_helper do
    local helper_miss_counter = 0

    client.set_event_callback('aim_miss', function (e)
        if e.reason ~= 'prediction error' then
            helper_miss_counter = helper_miss_counter + 1
        end
    end)
    
    client.set_event_callback('round_prestart', function ()
        helper_miss_counter = 0
    end)

    local function check_trigger (triggers, hp, miss_count, hp_threshold, miss_threshold, height_diff)
        for _, trigger in ipairs(triggers) do
            if (trigger == 'Enemy HP < X' and hp < hp_threshold) or
               (trigger == 'X Missed Shots' and miss_count > miss_threshold) or
               (trigger == 'Lethal' and hp <= 30) or
               (trigger == 'Height advantage' and height_diff > 70) or
               (trigger == 'Enemy higher than you' and height_diff < -70) then
                return true
            else
                return false
            end
        end
        return false
    end

    local function on_setup_command ()
        if not elements.aimbot.aimbot_helper.enable:get() then return end

        local me = entity.get_local_player()
        if not me or not entity.is_alive(me) then
            helper_miss_counter = 0
            return
        end

        local gun = entity.get_player_weapon(me)
        if not gun then return end

        local weapon = entity.get_classname(gun)
        local weapon_config = (weapon == 'CWeaponSSG08' and elements.aimbot.aimbot_helper.settings.ssg) or
                              (weapon == 'CWeaponAWP' and elements.aimbot.aimbot_helper.settings.awp) or
                              ((weapon == 'CWeaponG3SG1' or weapon == 'CWeaponSCAR20') and elements.aimbot.aimbot_helper.settings.auto)

        if not weapon_config then return end

        local my_pos = vector(entity.get_origin(me))
        local players = entity.get_players(true)

        for _, target in ipairs(players) do
            if not target or not entity.is_alive(target) or entity.is_dormant(target) then
                plist.set(target, 'Override safe point', '-')
                plist.set(target, 'Override prefer body aim', '-')
                helper_miss_counter = 0
                return
            end

            local hp = entity.get_prop(target, 'm_iHealth') or 100
            local enemy_pos = vector(entity.get_origin(target))
            local height_diff = math.ceil(my_pos.z - enemy_pos.z)

            if weapon_config.select:get('Force safe point') and
               check_trigger(weapon_config.force_safe:get(), hp, helper_miss_counter,
                             weapon_config.force_safe_hp:get(), weapon_config.force_safe_miss:get(), height_diff) then
                plist.set(target, 'Override safe point', 'On')
            else
                plist.set(target, 'Override safe point', '-')
            end

            local prefer_body = weapon_config.select:get('Prefer body aim') and
                                check_trigger(weapon_config.prefer_body:get(), hp, helper_miss_counter,
                                              weapon_config.prefer_body_hp:get(), weapon_config.prefer_body_miss:get(), height_diff)
            local force_body = weapon_config.select:get('Force body aim') and
                               check_trigger(weapon_config.force_body:get(), hp, helper_miss_counter,
                                             weapon_config.force_body_hp:get(), weapon_config.force_body_miss:get(), height_diff)

            if force_body then
                plist.set(target, 'Override prefer body aim', 'Force')
            elseif prefer_body then
                plist.set(target, 'Override prefer body aim', 'On')
            else
                plist.set(target, 'Override prefer body aim', '-')
            end

            if weapon_config.select:get('Ping spike') then
                reference.rage.ps[1]:override(true)
                reference.rage.ps[2]:override(weapon_config.ping_spike_value:get())
            else
                reference.rage.ps[1]:override()
                reference.rage.ps[2]:override()
            end
        end
    end

    client.set_event_callback('setup_command', function ()
        client.update_player_list()
        on_setup_command()
    end)
end

local predict do
    local function on_pre_render ()
        if not elements.aimbot.predict_enemies.enable:get() then
            -- cvar.cl_extrapolate_amount:set_raw_float(0.25)
            cvar.cl_interpolate:set_int(1)
            cvar.cl_interp_ratio:set_int(2)
            return
        end
      
        -- cvar.cl_extrapolate_amount:set_raw_float(0.7)
        cvar.cl_interpolate:set_int(0)
        cvar.cl_interp_ratio:set_int(1)
    end

    client.set_event_callback('pre_render', on_pre_render)
end

local game_enhancer do
    local fps_cvars = {
        ['Fix chams color'] = {'mat_autoexposure_max_multiplier', 0.2, 1},
        ['Disable dynamic Lighting'] = {'r_dynamiclighting', 0, 1},
        ['Disable dynamic Shadows'] = {'r_dynamic', 0, 1},
        ['Disable first-person tracers'] = {'r_drawtracers_firstperson', 0, 1},
        ['Disable ragdolls'] = {'cl_disable_ragdolls', 1, 0},
        ['Disable eye gloss'] = {'r_eyegloss', 0, 1},
        ['Disable eye movement'] = {'r_eyemove', 0, 1},
        ['Disable muzzle flash light'] = {'muzzleflash_light', 0, 1},
        ['Enable low CPU audio'] = {'dsp_slow_cpu', 1, 0},
        ['Disable bloom'] = {'mat_disable_bloom', 1, 0},
        ['Disable particles'] = {'r_drawparticles', 0, 1},
        ['Reduce breakable objects'] = {'func_break_max_pieces', 0, 15}
    }
  
    local function on_setup_command ()
        if not elements.aimbot.game_enhancer.enable:get() then
            for name, data in pairs(fps_cvars) do
                local cvar_name, boost_value, default_value = unpack(data)
                cvar[cvar_name]:set_int(default_value)
            end
            return
        end
  
        local selected_boosts = elements.aimbot.game_enhancer.settings.list:get()
        for name, data in pairs(fps_cvars) do
            local cvar_name, boost_value, default_value = unpack(data)
            cvar[cvar_name]:set_int(table_contains(selected_boosts, name) and boost_value or default_value)
        end
    end
    
    client.set_event_callback('setup_command', on_setup_command)
end

---

coloring.parse = function ()
    if colors.combobox:get() == 'Custom' then
        local r, g, b = colors.custom.color_1:get()
        if colors.custom.type:get() == 'Gradient' then
            local r2, g2, b2 = colors.custom.color_2:get()
            local r3, g3, b3 = colors.custom.color_3:get()
            local r4, g4, b4 = colors.custom.color_4:get()
            return {r = r, g = g, b = b, r2 = r2, g2 = g2, b2 = b2, r3 = r3, g3 = g3, b3 = b3, r4 = r4, g4 = g4, b4 = b4}
        else
            return {r = r, g = g, b = b}
        end

        return {r = r, g = g, b = b}
    else
        local r, g, b = reference.misc.settings.menu_color:get()
        return {r = r, g = g, b = b}
    end
end

local windows do
    local function limit_text_length (text, max_length)
        if #text > max_length then
            return string.sub(text, 1, max_length) .. '...'
        else
            return text
        end
    end
      
    local function create_interface (x, y, w, h, r, g, b, a, options)
        options = options or { }
        local side = options.side or 'down'
      
        local outline_y = y + 4
        if side == 'up' then
            outline_y = y + 12
        end
      
        -- @lordmouse: bg
        helpers.rounded_rectangle(x, y, w, h, 4, 20, 20, 20, 255 * (a / 255))
      
        -- @lordmouse: gradient lines
        if side == 'up' or side == 'down' then
            local reverse = false
            if side == 'up' then
                reverse = true
            end
            helpers.semi_outlined_rectangle(x + 4, outline_y, w - 8, 14, 4, 2, r, g, b, a, reverse)
        elseif side == 'left' then
            renderer.gradient(x + 5, y + 4, 3, h - 8, r, g, b, a, r, g, b, 0, false)
        elseif side == 'right' then
            renderer.gradient(x + w - 8, y + 4, 3, h - 8, r, g, b, 0, r, g, b, a, false)
        elseif side == 'left + right' then
            renderer.gradient(x + 5, y + 4, 3, h - 8, r, g, b, a, r, g, b, 0, false)
            renderer.gradient(x + w - 8, y + 4, 3, h - 8, r, g, b, 0, r, g, b, a, false)
        end
      
        -- @lordmouse: gs outline
        helpers.rounded_outlined_rectangle(x, y, w, h, 4, 1, 12, 12, 12, a)
        helpers.rounded_outlined_rectangle(x + 1, y + 1, w - 2, h - 2, 4, 1, 60, 60, 60, a)
        helpers.rounded_outlined_rectangle(x + 2, y + 2, w - 4, h - 4, 4, 3, 40, 40, 40, a)
    end      
end

---

local advert = { width = 100, height = 20 }; do
    local drag = drag_system.new(
        'advert_watermark',
        drag_slider.advert.x,
        drag_slider.advert.y,
        15, screen_size.y / 2 - 10,  -- default pos
        'xy',       -- drag axes
        'xy',       -- align
        {
            w = function () return advert.width end,
            h = function () return advert.height end,
            align_x = 'left',
            snap_distance = 10,
            show_guides = true,
            show_highlight = true,
            align_center = true
        }
    )

    local alpha = { value = 255 }
    local function on_paint_ui ()
        alpha.value = lerp('advert_watermark', not elements.visuals.windows:get('Force text watermark') and (elements.visuals.windows:get('Watermark') or elements.visuals.crosshair.enable:get()) and 0 or 255, 10, 0.001, 'ease_out')
        if alpha.value == 0 then
            return
        end

        local custom = coloring.parse()
        local width = renderer.measure_text('b', string.format('%s %s v2 / %s', lua.name, lua.build, lua.username)) + 8
        advert.width = width

        drag:update()
        drag:draw_guides()

        local x, y = drag:get_pos()
        if colors.combobox:get() == 'Custom' and colors.custom.type:get() == 'Gradient' then
            draw_gradient_text(
                x + 4, 
                y + 4,
                'b',
                nil,
                string.format('%s %s v2', lua.name, lua.build),
                25,
                {r = custom.r, g = custom.g, b = custom.b, a = alpha.value},
                {r = custom.r3, g = custom.g3, b = custom.b3, a = alpha.value},
                {r = custom.r4, g = custom.g4, b = custom.b4, a = alpha.value},
                {r = custom.r2, g = custom.g2, b = custom.b2, a = alpha.value}
            )

            local gradient_width = renderer.measure_text('b', string.format('%s %s v2', lua.name, lua.build))

            renderer.text(x + gradient_width + 7, y + 4, 255, 255, 255, alpha.value, 'b', nil, string.format('/ %s', lua.username))
        else
            renderer.text(x + 4, y + 4, 255, 255, 255, alpha.value, 'b', nil, string.format('\a%s%s %s v2\a%s / %s', coloring.rgba_to_hex(custom.r, custom.g, custom.b, alpha.value), lua.name, lua.build, coloring.rgba_to_hex(255, 255, 255, alpha.value), lua.username))
        end
    end

    client.set_event_callback('paint_ui', on_paint_ui)
end

local crosshair = { width = 62, height = 50 }; do
    local drag_c = drag_system.new(
        'crosshair',
        nil,
        drag_slider.crosshair.y,
        screen_size.x / 2, screen_size.y / 2 + 40,  -- default pos
        'y',       -- drag axes
        'y',       -- align
        {
            w = function () return crosshair.width end,
            h = function () return crosshair.height end,
            align_y = 'center',
            snap_distance = 10,
            show_guides = true,
            show_highlight = true,
            align_center = true
        }
    )

    local alpha = { value = 0, unique = 0, simple = 0 }
    local function on_paint ()
        local me = entity.get_local_player()
        
        alpha.value = lerp('crosshair_global', (elements.visuals.crosshair.enable:get() and entity.is_alive(me)) and 255 or 0, 10, 0.001, 'ease_out')
        if alpha.value == 0 then
            return
        end

        drag_c:update()
        drag_c:draw_guides()
        local x, y = drag_c:get_pos()
        local screen_x, screen_y = client.screen_size()
        local is_scoped = entity.get_prop(me, 'm_bIsScoped') == 1
        local custom = coloring.parse()

        alpha.unique = lerp('crosshair_unique', (elements.visuals.crosshair.settings.type:get() == 'Unique') and 255 or 0, 10, 0.001, 'ease_out')
        alpha.unique = math.ceil(alpha.unique)
        if alpha.unique > 0 then
            local scope_value = lerp('crosshair_scope', is_scoped and 1 or 0, 10, 0.008, 'ease_out')

            local measure_name = renderer.measure_text('cb', lua.name:lower()) / 2 + 3
            if colors.combobox:get() == 'Custom' and colors.custom.type:get() == 'Gradient' then
                draw_gradient_text(
                    screen_x / 2 + (measure_name) * scope_value,
                    y + 14,
                    'cb',
                    nil,
                    lua.name:lower(),
                    25,
                    {r = custom.r, g = custom.g, b = custom.b, a = alpha.unique * alpha.value / 255},
                    {r = custom.r3, g = custom.g3, b = custom.b3, a = alpha.unique * alpha.value / 255},
                    {r = custom.r4, g = custom.g4, b = custom.b4, a = alpha.unique * alpha.value / 255},
                    {r = custom.r2, g = custom.g2, b = custom.b2, a = alpha.unique * alpha.value / 255}
                )
            else
                renderer.text(screen_x / 2 + (measure_name) * scope_value, y + 14, custom.r, custom.g, custom.b, alpha.unique * alpha.value / 255, 'cb', nil, lua.name:lower())
            end

            local settings_add_y = 0
            local states_alpha = lerp('crosshair_state_global', (elements.visuals.crosshair.settings.select:get('States')) and 1 or 0, 10, 0.001, 'ease_out')
            if states_alpha > 0 then
                local state = string.lower(builder.get_state())
                if reference.antiaim.fakelag.enabled:get() then
                    if fakelag.active then
                        state = 'fake lag'
                    end
                end

                if reference.antiaim.angles.freestanding[1]:get() and reference.antiaim.angles.freestanding[1].hotkey:get() then
                    state = 'freestanding'
                end
            
                local measure_state = renderer.measure_text('rb', state) / 2 + 3
                local animated_state = lerp('crosshair_state', renderer.measure_text('rb', state) + 1, 7, 1, 'ease_out')

                renderer.text(screen_x / 2 + (animated_state / 2) + (measure_state) * scope_value, y + 20, 255, 255, 255, alpha.unique * alpha.value / 255 * states_alpha, 'rb', animated_state, state) 
            end
            
            local binds_alpha = lerp('crosshair_binds_global', (elements.visuals.crosshair.settings.select:get('Binds')) and 1 or 0, 10, 0.001, 'ease_out')
            if binds_alpha > 0 then
                local exploit_states = {
                    dt = {
                        default = {'dt', {255, 255, 255}},
                        defensive = {'dt defensive', {67, 245, 255}},
                        recharge = {'dt recharge', {255, 200, 0}},
                        active = {'dt active', {50, 255, 50}}
                    },

                    hs = {
                        default = {'hs', {255, 255, 255}},
                        defensive = {'hs defensive', {67, 245, 255}},
                        recharge = {'hs recharge', {255, 200, 0}},
                        active = {'hs active', {50, 255, 50}}
                    }
                }

                local function get_exploit_text(exploit_type)
                    local states = exploit_states[exploit_type]
                    if (exploit_type == 'dt' and exploits.is_doubletap()) or (exploit_type == 'hs' and exploits.is_hideshots() and not exploits.is_doubletap()) then
                        if exploits.in_defensive() then
                            return states.defensive
                        elseif exploits.in_recharge() or ((exploit_type == 'dt' and exploits.is_doubletap()) and not exploits.can_recharge()) then
                            return states.recharge
                        else
                            return states.active
                        end
                    end

                    return states.default
                end

                local doubletap_state = get_exploit_text('dt')
                local hideshots_state = get_exploit_text('hs')
                
                local binds = {
                    {name = 'dt', display = doubletap_state[1], color = doubletap_state[2], ref = exploits.is_doubletap()},
                    {name = 'hs', display = hideshots_state[1], color = hideshots_state[2], ref = exploits.is_hideshots() and not exploits.is_doubletap()},
                    {name = 'baim', display = 'baim', color = {255, 255, 255}, ref = reference.rage.aimbot.force_body:get()},
                    {name = 'safe', display = 'safe', color = {255, 255, 255}, ref = reference.rage.aimbot.force_safe:get()}
                }

                settings_add_y = states_alpha > 0 and 12 or 1

                local height = 0
                for _, bind in ipairs(binds) do
                    local _bind_alpha = lerp('crosshair_bind_alpha_' .. bind.name, bind.ref and 1 or 0, 10, 0.001, 'ease_out')
                    local _bind_y = lerp('crosshair_bind_y_' .. bind.name, bind.ref and 12 or 0, 12, 0.07, 'ease_out')
                    height = height + _bind_y

                    local measure_binds = renderer.measure_text('cb', bind.display) / 2 + 3
                    local target_width = renderer.measure_text('cb', bind.display) + 1
                    local animated_binds = lerp('crosshair_bind_anim' .. bind.name, bind.ref and target_width or 0, 11, 0.5, 'ease_out')
                    
                    if bind.name == 'dt' or bind.name == 'hs' then
                        local base_text = bind.name
                        local state_text = bind.display:sub(#base_text + 1)
                        local base_width = renderer.measure_text('cb', base_text)
                        local state_width = renderer.measure_text('cb', state_text)
                        
                        renderer.text(screen_x / 2 - state_width / 2 + 1 + (measure_binds - 1) * scope_value, y + height + 14 + settings_add_y, 255, 255, 255, alpha.unique * alpha.value / 255 * binds_alpha * _bind_alpha, 'cb', nil, base_text)
                        
                        if #state_text > 0 then
                            local animated_binds_2 = lerp('crosshair_bind2_anim' .. bind.name, bind.ref and state_width + 1 or 0, 11, 0.5, 'ease_out')

                            renderer.text(screen_x / 2 + base_width / 2 + (measure_binds) * scope_value, y + height + 14 + settings_add_y, bind.color[1], bind.color[2], bind.color[3], alpha.unique * alpha.value / 255 * binds_alpha * _bind_alpha, 'cb', animated_binds_2, state_text)
                        end
                    else
                        renderer.text(screen_x / 2 + measure_binds * scope_value, y + height + 14 + settings_add_y, bind.color[1], bind.color[2], bind.color[3], alpha.unique * alpha.value / 255 * binds_alpha * _bind_alpha, 'cb', animated_binds, bind.display)
                    end
                end
            end
        end
    end

    client.set_event_callback('paint', on_paint)
end

local arrows do
    local drag_a = drag_system.new(
        'arrows',
        drag_slider.arrows.x,
        nil,
        screen_size.x / 2 + 50, screen_size.y / 2,  -- default pos
        'x',       -- drag axes
        'x',       -- align
        {
            w = 20,
            h = 20,
            align_x = 'center',
            snap_distance = 10,
            show_guides = true,
            show_highlight = true,
            align_center = false
        }
    )

    local alpha = { value = 0, unique = 0, simple = 0, teamskeet = 0 }
    local function on_paint ()
        local me = entity.get_local_player()
        
        alpha.value = lerp('arrows_global', (elements.visuals.arrows.enable:get() and entity.is_alive(me)) and 255 or 0, 10, 0.001, 'ease_out')
        if alpha.value == 0 then
            return
        end

        drag_a:update()
        drag_a:draw_guides()
        local x, y = drag_a:get_pos()
        local screen_x, screen_y = client.screen_size()
        local is_scoped = entity.get_prop(me, 'm_bIsScoped') == 1
        local custom = coloring.parse()

        local state = builder.get_state()
        local left_alpha = lerp('arrows_left_alpha', (state == 'Manual left' or ui.is_menu_open()) and 1 or 0, 10, 0.001, 'ease_out')
        local right_alpha = lerp('arrows_right_alpha', (state == 'Manual right' or ui.is_menu_open()) and 1 or 0, 10, 0.001, 'ease_out')
        local scope_animation = lerp('arrows_scope', is_scoped and 1 or 0, 10, 0.008, 'ease_out')

        alpha.unique = lerp('arrows_unique', (elements.visuals.arrows.settings.type:get() == 'Unique') and 255 or 0, 10, 0.001, 'ease_out')
        alpha.unique = math.ceil(alpha.unique)
        if alpha.unique > 0 then
            renderer.text(screen_x - x - 14, screen_y / 2 - 4 - (12 * scope_animation), custom.r, custom.g, custom.b, alpha.unique * alpha.value / 255 * left_alpha, 'c+', nil, '⩤')
            renderer.text(x + 10, screen_y / 2 - 4 - (12 * scope_animation), custom.r, custom.g, custom.b, alpha.unique * alpha.value / 255 * right_alpha, 'c+', nil, '⩥')
        end

        alpha.simple = lerp('arrows_simple', (elements.visuals.arrows.settings.type:get() == 'Simple') and 255 or 0, 10, 0.001, 'ease_out')
        alpha.simple = math.ceil(alpha.simple)
        if alpha.simple > 0 then
            -- if colors.combobox:get() == 'Custom' and colors.custom.type:get() == 'Gradient' then
            --     draw_gradient_text(
            --         screen_x - x - 10, 
            --         screen_y / 2 - 4,
            --         'c+',
            --         nil,
            --         '<',
            --         25,
            --         {r = custom.r, g = custom.g, b = custom.b, a = alpha.value},
            --         {r = custom.r3, g = custom.g3, b = custom.b3, a = alpha.value},
            --         {r = custom.r4, g = custom.g4, b = custom.b4, a = alpha.value},
            --         {r = custom.r2, g = custom.g2, b = custom.b2, a = alpha.value}
            --     )
            -- end

            renderer.text(screen_x - x - 14, screen_y / 2 - 2 - (12 * scope_animation), custom.r, custom.g, custom.b, alpha.simple * alpha.value / 255 * left_alpha, 'c+', nil, '<')
            renderer.text(x + 10, screen_y / 2 - 2 - (12 * scope_animation), custom.r, custom.g, custom.b, alpha.simple * alpha.value / 255 * right_alpha, 'c+', nil, '>')
        end

        alpha.teamskeet = lerp('arrows_teamskeet', (elements.visuals.arrows.settings.type:get() == 'TeamSkeet') and 255 or 0, 10, 0.001, 'ease_out')
        alpha.teamskeet = math.ceil(alpha.teamskeet)
        if alpha.teamskeet > 0 then

        end
    end

    client.set_event_callback('paint', on_paint)
end

local scope do
    local on_paint_ui = function ()
        reference.visuals.scope:override(true)
    end

    elements.visuals.scope.enable:set_event('paint_ui', on_paint_ui)

    local function on_paint ()
        if not elements.visuals.scope.enable:get() then
            reference.visuals.scope:override()
            return
        end

        local me = entity.get_local_player()
        if not me or not entity.is_alive(me) then
            return
        end

        local weapon = entity.get_player_weapon(me)
        if weapon == nil then
            return
        end

        reference.visuals.scope:override(false)

        local scope_level = entity.get_prop(weapon, 'm_zoomLevel')
        local scoped = entity.get_prop(me, 'm_bIsScoped') == 1
        local resume_zoom = entity.get_prop(me, 'm_bResumeZoom') == 1
        local is_valid = scope_level ~= nil
        local act = is_valid and scope_level > 0 and scoped and not resume_zoom

        local alpha = lerp('custom_scope', act and 255 or 0, 4, 0.001, 'ease_out')
        local x, y = client.screen_size()
        local custom = coloring.parse()

        x, y = x / 2, y / 2

        local gap = elements.visuals.scope.settings.gap:get()
        local length = elements.visuals.scope.settings.size:get()
        local inverted = elements.visuals.scope.settings.invert:get()

        -- @lordmouse: left
        if not elements.visuals.scope.settings.exclude:get('Left') then
            renderer.gradient(x - gap, y, -length * (alpha / 255), 1, custom.r, custom.g, custom.b, inverted and 0 or alpha, custom.r, custom.g, custom.b, inverted and alpha or 0, true)
        end

        -- @lordmouse: right
        if not elements.visuals.scope.settings.exclude:get('Right') then
            renderer.gradient(x + gap, y, length * (alpha / 255), 1, custom.r, custom.g, custom.b, inverted and 0 or alpha, custom.r, custom.g, custom.b, inverted and alpha or 0, true)
        end

        -- @lordmouse: up
        if not elements.visuals.scope.settings.exclude:get('Top') then
            renderer.gradient(x, y - gap, 1, -length * (alpha / 255), custom.r, custom.g, custom.b, inverted and 0 or alpha, custom.r, custom.g, custom.b, inverted and alpha or 0, false)
        end

        -- @lordmouse: down
        if not elements.visuals.scope.settings.exclude:get('Bottom') then
            renderer.gradient(x, y + gap, 1, length * (alpha / 255), custom.r, custom.g, custom.b, inverted and 0 or alpha, custom.r, custom.g, custom.b, inverted and alpha or 0, false)
        end
    end

    client.set_event_callback('paint', on_paint)
end

---

local zoom_animation do
    local function on_override_view (e)
        if not elements.visuals.zoom.enable:get() then
            reference.misc.miscellaneous.override_zoom_fov:override()
            return
        end

        reference.misc.miscellaneous.override_zoom_fov:override(0)

        local me = entity.get_local_player()
        if not me or not entity.is_alive(me) then
            return
        end

        local fov, speed = elements.visuals.zoom.settings.value:get(), elements.visuals.zoom.settings.speed:get()
        local is_scoped = entity.get_prop(me, 'm_bIsScoped') == 1

        local animate = lerp('zoom', is_scoped and fov or 0, speed / 10, 0.001, 'ease_out')
        e.fov = e.fov - animate
    end

    client.set_event_callback('override_view', on_override_view)
end

local aspect_ratio do
    local alpha = 0
    local function on_paint ()
        alpha = lerp('aspect_ratio_alpha', elements.visuals.aspect_ratio.enable:get() and 255 or 0, 16, 0.001, 'ease_out')
        if alpha == 0 then
            cvar.r_aspectratio:set_int(0)
            return
        end

        local x, y = client.screen_size()
        local init = x / y

        local value = elements.visuals.aspect_ratio.settings.value:get()
        local animate = lerp('aspect_ratio_animate', elements.visuals.aspect_ratio.enable:get() and value * .01 or init, 8, 0.001, 'ease_out')

        if animate == init then
            cvar.r_aspectratio:set_int(0)
            return
        end

        cvar.r_aspectratio:set_float(animate)
    end

    client.set_event_callback('paint', on_paint)
end

local viewmodel = { fov = 0, x = 0, y = 0, z = 0 }; do
    local alpha = 0
    local function on_paint ()
        alpha = lerp('viewmodel_alpha', elements.visuals.viewmodel.enable:get() and 255 or 0, 16, 0.001, 'ease_out')
        if alpha == 0 then
            return
        end

        if elements.visuals.viewmodel.enable:get() then
            viewmodel.fov = lerp('viewmodel_fov', elements.visuals.viewmodel.settings.fov:get(), 8, 0.001, 'ease_out')
            viewmodel.x = lerp('viewmodel_x', elements.visuals.viewmodel.settings.x:get() / 10, 8, 0.001, 'ease_out')
            viewmodel.y = lerp('viewmodel_y', elements.visuals.viewmodel.settings.y:get() / 10, 8, 0.001, 'ease_out')
            viewmodel.z = lerp('viewmodel_z', elements.visuals.viewmodel.settings.z:get() / 10, 8, 0.001, 'ease_out')
        else
            viewmodel.fov = lerp('viewmodel_fov', 68, 8, 0.001, 'ease_out')
            viewmodel.x = lerp('viewmodel_x', 2.5, 8, 0.001, 'ease_out')
            viewmodel.y = lerp('viewmodel_y', 0, 8, 0.001, 'ease_out')
            viewmodel.z = lerp('viewmodel_z', -1.5, 8, 0.001, 'ease_out')
        end
      
        -- if elements.visuals.viewmodel.enable:get() and elements.visuals.viewmodel.settings.additional:get('CS2 Hands In Scope') and entity.get_prop(entity.get_local_player(), 'm_bIsScoped') == 1 then
        --     viewmodel.x = lerp('viewmodel_x', -9, 8, 0.001, 'ease_out')
        --     viewmodel.y = lerp('viewmodel_y', -1, 8, 0.001, 'ease_out')
        --     viewmodel.z = lerp('viewmodel_z', -3.5, 8, 0.001, 'ease_out')
        -- end
      
        cvar.viewmodel_fov:set_raw_float(viewmodel.fov)
        cvar.viewmodel_offset_x:set_raw_float(viewmodel.x)
        cvar.viewmodel_offset_y:set_raw_float(viewmodel.y)
        cvar.viewmodel_offset_z:set_raw_float(viewmodel.z)
    end

    client.set_event_callback('paint', on_paint)
end


local markers = { hits = {  }, misses = {  }, damages = {  } }; do
    markers.hit_pos = { 0, 0, 0 }
    local function on_aim_fire (e)
        if not elements.visuals.markers.enable:get() then
            return
        end

        markers.hit_pos = { e.x, e.y, e.z }
    end
  
    local function on_aim_hit (e)
        if not elements.visuals.markers.enable:get() then
            return
        end

        table.insert(markers.hits, {
            time = globals.curtime(),
            position = markers.hit_pos
        })
    end
  
    local function on_player_hurt (e)
        if not elements.visuals.markers.enable:get() then
            return
        end

        local attacker = client.userid_to_entindex(e.attacker)
        local victim = client.userid_to_entindex(e.userid)
    
        if attacker == entity.get_local_player() and victim ~= attacker then
            table.insert(markers.damages, {
                time = globals.curtime(),
                position = { entity.get_prop(victim, 'm_vecOrigin') },
                damage = e.dmg_health,
                offset = 0 
            })
        end
    end
  
    local function on_aim_miss (e)
        if not elements.visuals.markers.enable:get() then
            return
        end

        local red = { 255, 0, 50 }
        local yellow = { 255, 205, 0 }

        e.reason = e.reason == '?' and 'resolver' or e.reason
    
        table.insert(markers.misses, {
            time = globals.curtime(),
            position = markers.hit_pos,
            reason = e.reason,
            color = (e.reason == 'spread' or e.reason == 'prediction error') and yellow or red
        })
    end
  
    local function on_paint ()
        if not elements.visuals.markers.enable:get() then
            return
        end

        if elements.visuals.markers.settings.type:get('On hit') then
            for i = #markers.hits, 1, -1 do
                local hit = markers.hits[i]
                local alpha = 255 - (globals.curtime() - hit.time) * 255 / 2
        
                if alpha > 0 then
                    local x, y = renderer.world_to_screen(hit.position[1], hit.position[2], hit.position[3])
            
                    if x and y then
                        local size = 4
                        renderer.line(x - size, y - size, x + size, y + size, 255, 255, 255, alpha)
                        renderer.line(x + size, y - size, x - size, y + size, 255, 255, 255, alpha)
                    end
                else
                    table.remove(markers.hits, i)
                end
            end
        end
      
        if elements.visuals.markers.settings.type:get('On miss') then
            for i = #markers.misses, 1, -1 do
                local miss = markers.misses[i]
                local alpha = 255 - (globals.curtime() - miss.time) * 255 / 2
            
                if alpha > 0 then
                    local x, y = renderer.world_to_screen(miss.position[1], miss.position[2], miss.position[3])
            
                    if x and y then
                        local size = 4
                        renderer.line(x - size, y - size, x + size, y + size, miss.color[1], miss.color[2], miss.color[3], alpha)
                        renderer.line(x + size, y - size, x - size, y + size, miss.color[1], miss.color[2], miss.color[3], alpha)
                        renderer.text(x + 10, y - 7, miss.color[1], miss.color[2], miss.color[3], alpha, 'b', 0, miss.reason)
                    end
                else
                    table.remove(markers.misses, i)
                end
            end
        end
    
        if elements.visuals.markers.settings.type:get('Damage') then
            for i = #markers.damages, 1, -1 do
                local damage = markers.damages[i]
                local alpha = 255 - (globals.curtime() - damage.time) * 255 / 2
            
                if alpha > 0 then
                    damage.offset = damage.offset + 0.2
            
                    local x, y = renderer.world_to_screen(damage.position[1], damage.position[2], damage.position[3] + damage.offset)
            
                    if x and y then
                        renderer.text(x, y, 255, 255, 255, alpha, 'cb', 0, '-' .. damage.damage)
                    end
                else
                    table.remove(markers.damages, i)
                end
            end
        end
    end
    
    client.set_event_callback('aim_fire', on_aim_fire)
    client.set_event_callback('aim_hit', on_aim_hit)
    client.set_event_callback('player_hurt', on_player_hurt)
    client.set_event_callback('aim_miss', on_aim_miss)
    client.set_event_callback('paint', on_paint)
end

---

local drop_nades do
    local nades_list = {
        ['HE Grenade'] = 'weapon_hegrenade',
        Molotov = 'weapon_molotov',
        Incendiary = 'weapon_incgrenade',
        Smoke = 'weapon_smokegrenade'
    }
    
    local key_click_cache = false

    local function on_paint ()
        if not elements.misc.drop_nades.enable:get() then
            return
        end
      
        local me = entity.get_local_player()
        if not me or not entity.is_alive(me) then
            return
        end
      
        local weapons = {  }
        for i = 0, 64 do
            local weapon = entity.get_prop(me, 'm_hMyWeapons', i)
            if weapon and weapon ~= 0 then
                local weapon_name = entity.get_classname(weapon)
                weapons[weapon_name] = true
            end
        end
      
        local selected_nades = {  }
        for grenade_type, grenade_name in pairs(nades_list) do
            local grenade_class = 'C' .. grenade_type .. 'Grenade'
            if weapons[grenade_class] and elements.misc.drop_nades.settings.list:get(grenade_type) then
                table.insert(selected_nades, grenade_name)
            end
        end
      
        local drop_key = elements.misc.drop_nades.enable.hotkey:get()
        if drop_key and not key_click_cache then
            for index, grenade in ipairs(selected_nades) do
                local delay = 0.1 * index
                client.delay_call(delay, function ()
                    client.exec('use ' .. grenade)
                    client.delay_call(0.05, function ()
                        client.exec('drop')
                    end)
                end)
            end
        end
      
        key_click_cache = drop_key
    end

    client.set_event_callback('paint', on_paint)
end

local auto_buy do
    local prices = {
        ['AWP'] = 4750,
        ['SCAR-20/G3SG1'] = 5000,
        ['SSG-08'] = 1700,
        ['Five-SeveN/Tec-9'] = 500,
        ['P250'] = 300,
        ['Deagle/R8'] = 700,
        ['Duals'] = 400,
        ['HE Grenade'] = 300,
        ['Molotov'] = 600,
        ['Smoke'] = 300,
        ['Kevlar'] = 650,
        ['Helmet'] = 1000,
        ['Taser'] = 200,
        ['Defuse Kit'] = 400
    }
    
    local commands = {
        ['AWP'] = 'buy awp',
        ['SCAR-20/G3SG1'] = 'buy scar20',
        ['SSG-08'] = 'buy ssg08',
        ['Five-SeveN/Tec-9'] = 'buy tec9',
        ['P250'] = 'buy p250',
        ['Deagle/R8'] = 'buy deagle',
        ['Duals'] = 'buy elite',
        ['HE Grenade'] = 'buy hegrenade',
        ['Molotov'] = 'buy molotov',
        ['Smoke'] = 'buy smokegrenade',
        ['Kevlar'] = 'buy vest',
        ['Helmet'] = 'buy vesthelm',
        ['Taser'] = 'buy taser',
        ['Defuse Kit'] = 'buy defuser'
    }
    
    local function get_weapon_prices ()
        local total_price = 0
        -- @lordmouse: utilities
        local utility_purchase = elements.misc.autobuy.settings.utilities:get()
        for i = 1, #utility_purchase do
            local n = utility_purchase[i]
            
            for k, v in pairs(prices) do
                if k == n then
                    total_price = total_price + v
                end
            end
        end
    
        -- @lordmouse: secondary
        for k, v in pairs(prices) do
            if k == elements.misc.autobuy.settings.pistol:get() then
                total_price = total_price + v
            end
        end
    
        -- @lordmouse: primary
        for k, v in pairs(prices) do
            if k == elements.misc.autobuy.settings.sniper:get() then
                total_price = total_price + v
            end
        end
        
        -- @lordmouse: grenades
        local grenade_purchase = elements.misc.autobuy.settings.grenades:get()
        for i = 1, #grenade_purchase do
            local n = grenade_purchase[i]
            
            for k, v in pairs(prices) do
                if k == n then
                    total_price = total_price + v
                end
            end
        end
        return total_price
    end

    local function on_round_prestart (e)
        if not elements.misc.autobuy.enable:get() then
            return
        end

        -- local price_threshold = get_weapon_prices()
        -- local money = entity.get_prop(entity.get_local_player(), 'm_iAccount')
    
        -- if money <= price_threshold then
        --     return
        -- end

        -- @lordmouse: utilities
        local utility_purchase = elements.misc.autobuy.settings.utilities:get()
        for i = 1, #utility_purchase do
            local n = utility_purchase[i]
            
            for k, v in pairs(commands) do
                if k == n then
                    client.exec(v)
                end
            end
        end

        -- @lordmouse: secondary
        for k, v in pairs(commands) do
            if k == elements.misc.autobuy.settings.pistol:get() then
                client.exec(v)
            end
        end

        -- @lordmouse: primary
        for k, v in pairs(commands) do
            if k == elements.misc.autobuy.settings.sniper:get() then
                client.exec(v)
            end
        end

        -- @lordmouse: grenades
        local grenade_purchase = elements.misc.autobuy.settings.grenades:get()
        for i = 1, #grenade_purchase do
            local n = grenade_purchase[i]
            
            for k, v in pairs(commands) do
                if k == n then
                    client.exec(v)
                end
            end
        end
    end
    
    client.set_event_callback('round_prestart', on_round_prestart)
end

local animations do
    local native_GetClientEntity = vtable_bind('client.dll', 'VClientEntityList003', 3, 'void*(__thiscall*)(void*, int)')
    local char_ptr = ffi.typeof('char*')
    local nullptr = ffi.new('void*')
    local class_ptr = ffi.typeof('void***')
    local animation_layer_t = ffi.typeof([[struct { char pad0[0x18]; uint32_t sequence; float prev_cycle, weight, weight_delta_rate, playback_rate, cycle; void *entity; char pad1[0x4]; } **]])

    local command_number = 0
    local function on_run_command (e)
        command_number = e.command_number
    end

    client.set_event_callback('run_command', on_run_command)

    local function on_pre_render ()
        if not elements.misc.animations.enable:get() then
            return
        end
        
        local me = entity.get_local_player()
        if not me or not entity.is_alive(me) then 
            return 
        end
    
        local player_ptr = ffi.cast(class_ptr, native_GetClientEntity(me))
        if player_ptr == nullptr then 
            return 
        end
    
        local first_velocity, second_velocity = entity.get_prop(me, 'm_vecVelocity')
        local speed = math.floor(math.sqrt(first_velocity^2 + second_velocity^2))
    
        local anim_layers = ffi.cast(animation_layer_t, ffi.cast(char_ptr, player_ptr) + 0x2990)[0]
        local anim_type, anim_extra_type, anim_jitter_min, anim_jitter_max, body_lean_value = false, elements.misc.animations.settings.running.anim_extra_type, false, false, 0
        if ground_tick and speed > 5 then
            anim_type = elements.misc.animations.settings.running.anim_type:get()
            anim_extra_type = elements.misc.animations.settings.running.anim_extra_type
            anim_jitter_min = elements.misc.animations.settings.running.anim_min_jitter:get() * 0.01
            anim_jitter_max = elements.misc.animations.settings.running.anim_max_jitter:get() * 0.01
            body_lean_value = elements.misc.animations.settings.running.anim_bodylean:get()
        elseif not ground_tick then
            anim_type = elements.misc.animations.settings.in_air.anim_type:get()
            anim_extra_type = elements.misc.animations.settings.in_air.anim_extra_type
            anim_jitter_min = elements.misc.animations.settings.in_air.anim_min_jitter:get() * 0.01
            anim_jitter_max = elements.misc.animations.settings.in_air.anim_max_jitter:get() * 0.01
            body_lean_value = elements.misc.animations.settings.in_air.anim_bodylean:get()
        end
        local is_lagging = globals.realtime() / 2 % 1
    
        if anim_type == 'Allah' then
            entity.set_prop(me, 'm_flPoseParameter', 1, ground_tick and speed > 5 and 7 or 6)
            if not ground_tick then anim_layers[6].weight, anim_layers[6].cycle = 1, is_lagging end
            reference.antiaim.other.leg_movement:override('off')
        elseif anim_type == 'Static' then
            entity.set_prop(me, 'm_flPoseParameter', 1, ground_tick and speed > 5 and 0 or 6)
            reference.antiaim.other.leg_movement:override('always slide')
        elseif anim_type == 'Jitter' then
            entity.set_prop(me, 'm_flPoseParameter', client.random_float(anim_jitter_min, anim_jitter_max), ground_tick and speed > 5 and 7 or 6)
            reference.antiaim.other.leg_movement:override('never slide')
        elseif elements.misc.animations.settings.running.anim_type:get() == 'Alternative jitter' then
            reference.antiaim.other.leg_movement:override(command_number % 3 == 0 and 'off' or 'always slide')
            entity.set_prop(me, 'm_flPoseParameter', 1, globals.tickcount() % 4 > 1 and 0.5 or 1)
            if ground_tick and speed < 0 then
                entity.set_prop(me, 'm_flPoseParameter', client.random_float(0.4, 0.8), 7)
            end
        else
            reference.antiaim.other.leg_movement:override('off')
        end
    
        if anim_extra_type:get('Body lean') then
            anim_layers[12].weight = body_lean_value / 100
        end
    
        if elements.misc.animations.settings.in_air.anim_extra_type:get('Zero pitch on landing') then
            if ticks > 24 and ticks < 350 then
                entity.set_prop(me, 'm_flPoseParameter', 0.5, 12)
            end
        end
    end

    client.set_event_callback('pre_render', on_pre_render)
end

-- @lordmouse: TODO поставить везде значения задержки на сообщение ЧТОБЫ ТИПЫ ЕЩЁ СИЛЬНЕЕ байтились
local trash_talk do
    local phrases = {
        bait = { 
            {'1', 1.0}
        },
    
        kill = {
            {'ʙʏ ʙᴜʏɪɴɢ ᴇᴍʙᴇʀʟᴀsʜ, ʏᴏᴜ\'ʀᴇ ʙᴜʏɪɴɢ ᴀ ᴛɪᴄᴋᴇᴛ ᴛᴏ ʜᴇʟʟ.', 0.2},
            {'𝙀𝙢𝙗𝙚𝙧𝙡𝙖𝙨𝙝 𝙥𝙧𝙚𝙢𝙞𝙪𝙢 𝙥𝙧𝙚𝙙𝙞𝙘𝙩𝙞𝙤𝙣 𝙩𝙚𝙘𝙝𝙣𝙤𝙡𝙤𝙜𝙞𝙚𝙨 ◣◢ 👑', 0.2},
            {'The Flame will never die, for I am EMBERLASH', 0.2},
            {'☾ 𝕘𝕖𝕥 𝕗𝕦𝕔𝕜𝕖𝕕 𝕓𝕪 𝕕𝕖𝕧𝕚𝕝 #𝕖𝕞𝕓𝕖𝕣𝕝𝕒𝕤𝕙 ~ 𝕟𝕖𝕥𝕨𝕠𝕣k ☾', 0.2, '1', 1.0},
            {'♥️ Очередная душа в мою копилку (◣_◢) ♥️', 0.2},
            {'теперь сам Дьявол объявил на тебя охоту #𝕖𝕞𝕓𝕖𝕣𝕝𝕒𝕤𝕙 ☾', 0.2},
            {'опять слезы? умоляй моих дьяволов выдать тебе emberlash', 0.2},
            {'1', 1.0},
            {'𝕖𝕞𝕓𝕖𝕣𝕝𝕒𝕤𝕙 𝕚𝕤 𝕥𝕙𝕖 𝕓𝕖𝕤𝕥 𝔸𝔸 𝔸𝔸 𝔸𝔸 𝔸𝔸 𝔸𝔸 𝔸𝔸 𝔸', 0.2},
            {'♆ Сливы Дьяволиц -> .𝕘𝕘/𝔼𝕞𝕓𝕖𝕣𝕝𝕒𝕤𝕙 ♆', 0.2},
            {'#𝙚𝙢𝙗𝙚𝙧𝙡𝙖𝙨𝙝 𝙘𝙤𝙙𝙚 𝙬𝙖𝙨 𝙬𝙧𝙞𝙩𝙩𝙚𝙣 𝙗𝙮 𝐵𝓁𝑜𝑜𝒹 𝑜𝒻 𝐿𝓊𝒸𝒾𝒻𝑒𝓇 ٩(×̯×)۶', 0.2},
            {'14fl peek but i still predict #mephissa predict', 0.2},
            {'1', 1.0},
            {'твоя сила – лишь иллюзия перед властью Emberlash.', 0.2},
            {'это не битва, это исповедь, emberlash выслушает все твои грехи.', 0.2},
            {'Это не борьба за выживание, это жертва Emberlash.', 0.2},
            {'1', 1.0},
            {'emberlash станет эпитафией на твоём надгробии.', 0.2},
            {'Estk came to my door last night and said emberlash best ◣◢ I say ok king 👑', 0.2},
            {'𝕘𝕠𝕕 𝕘𝕒𝕧𝕖 𝕞𝕖 𝕡𝕠𝕨𝕖𝕣 𝕠𝕗 𝕣𝕖𝕫𝕠𝕝𝕧𝕖𝕣 𝔼𝕄𝔹𝔼ℝ𝕃𝔸𝕊ℍ', 0.2},
            {'っ◔◡◔)っ ♥ enjoy die to emberlash and spectate me ♥', 0.2},
            {'1', 1.0},
            {'𝕟𝕠 𝕤𝕜𝕚𝕝𝕝 𝕟𝕖𝕖𝕕 𝕛𝕦𝕤𝕥 𝕖𝕞𝕓𝕖𝕣𝕝𝕒𝕤𝕙', 0.2},
            {'𝕚 𝕒𝕞 𝕚𝕥”𝕤 𝕕𝕠𝕟𝕥 𝕝𝕠𝕤𝕖  ◣◢ #emberlash', 0.2},
            {'god may forgive you but emberlash resolver wont (◣_◢)', 0.2},
            {'1', 1.0},
            {'𝕓𝕪 𝕤𝕚𝕘𝕟𝕚𝕟𝕘 𝕒 𝕔𝕠𝕟𝕥𝕒𝕔𝕥 𝕨𝕚𝕥𝕙 𝕥𝕙𝕖 𝕕𝕖𝕧𝕚𝕝 𝕪𝕠𝕦 𝕒𝕣𝕖 𝕕𝕠𝕠𝕞𝕖𝕕 𝕥𝕠 𝕕𝕚𝕖 #emberlash', 0.2},
            {'ＹＯＵ ＷＩＳＨ ＹＯＵ ＨＡＤ E M B E R L A S H Ｕ ＨＲＳＮ', 0.2},
            {'winning not possibility, sry #emberlash', 0.2},
            {'1', 1.0},
            {'𝙙𝙖𝙮 666 𝗲𝗺𝗯𝗲𝗿𝗹𝗮𝘀𝗵 𝙨𝙩𝙞𝙡𝙡 𝙣𝙤 𝙧𝙞𝙫𝙖𝙡𝙨', 0.2},
            {'once this game started 𝔂𝓸𝓾 𝓵𝓸𝓼𝓮𝓭 𝓪𝓵𝓻𝓮𝓭𝔂 #emberlash', 0.2},
            {'ＹＯＵ ＨＡＤ ＦＵＮ ＬＡＵＧＨＩＮＧ ＵＮＴＩＬ ＮＯＷ #emberlash', 0.2},
            {'1', 1.0},
            {'EMBERLASH SEASON ON TRƱE #WITCHHOUSE AND #EVIL RADIO vibe 2025™', 0.2},
            {'rock star lifestyle #EMBERLASH', 0.2},
            {'i love emberlash', 0.2, 'do you love it?', 0.5},
            {'1', 1.0},
            {'zｚＺ', 0.2, 'playing with emberlash is so boooring', 0.5},
            {'im cursed', 0.2, 'satan is watching us', 0.6},
            {'family-friendly lua -> .gg/emberlash', 0.2},
            {'1', 1.0},
            {'1', 0.5, 'теперь думай кто это написал)))', 0.8},
            {'мы летим низко', 0.2, 'в бошке храню все emberlash', 0.5},
            {'снова палю в экран', 0.5, 'снова вижу этот дискорд', 0.5, '.gg/emberlash', 0.5},
            {'1', 0.4, 'иди ты нахуй дебилина', 0.5},
            {'1', 0.4, 'ФХАФЫХАЫХФАХ', 0.5, 'бомж ты куда', 0.6},
            {'моя сила emberlash', 0.2, 'что не брикаю лцшечку', 0.5},
            {'это происходит в действительности?', 0.2, '1', 0.7},
            {'я смотрю', 0.2, 'у тебя тренировка по удачному спаму пуль, продолжай', 0.5},
            {'если бы твой скилл зависел от интеллекта', 0.2, 'ты бы и в меню не зашёл', 0.5},
            {'ты не победил', 0.2, 'я просто протестировал баг на перерождение', 0.7},
            {'1', 1.0},
            {'где тебя научили стрелять', 0.2, 'в тире для первоклассников?', 0.6},
            {'z бы тебя похвалил', 0.2, 'но ты выиграл не скиллом', 0.5, 'а везением', 0.8},
            {'ты - как бесплатный emberlash', 0.2, 'который никто не скачивает', 0.6},
            {'1', 1.0},
            {'если твои успехи в игре перевести в реальные достижения', 0.6, 'ты бы был миллионером… в минусах', 0.75},
            {'мой труп был в 100 раз полезнее команды', 0.4, 'чем ты живой', 0.5},
            {'это было настолько случайно, что даже твои родители не так удивились, когда ты родился', 0.5},
            {'1', 1.0},
            {'eсли бы IQ был оружием', 0.3, 'ты бы ходил с деревянной палкой', 0.5},
            {'ты ошибка природы', 0.3, 'и даже код игры это понимает', 0.6},
            {'каково жить с осознанием', 0.3, 'что даже удача тебя презирает?', 0.6},
            {'1', 1.0},
            {'если бы победы давали смысл жизни', 0.3, 'ты бы уже повесился', 0.4},
            {'интеллект у тиа бл такой же плоский, как шахматная доска в аду', 0.4},
            {'ты как шут', 0.2, 'пытающийся быть серьезным в компании демонов', 0.5},
            {'1', 1.0},
            {'ты меня убил', 0.2, 'как сочник', 0.4, 'который заигрался и случайно открыл портал в ад', 0.6}
        },
    
        death = {
            {'ну он же реально', 3, 'подрывает себя', 2.5, 'и я не могу попасть', 1.8},
            {'ты че ваще ебанутый?', 1, 'я твою мать ебал', 2, 'ебаный тупой ублюдок', 3},
            {'в этом раунде эмберлашик не прокерил', 0.5, 'значит прокерит в следующем', 1.0},
            {'опять говно убивает', 1.8, 'я просто не могу уже', 1.5},
            {'ну как ты мои антиаимы тапаешь в эмберлаше??', 0.5, 'че ебу дал?', 1.0},
            {'я не могу в тебя попасть', 0.5, 'сделаешь мне такие же пресетики?', 1.5, 'на emberlash.gs', 0.5},
            {'НУ ЧТО ТЫ ЗА ДОЛБОЕБ', 0.2, 'БЛЯДИНА ЕБАНА Я ТЬЯВОЮ МАТЬ ЕБАЛ', 1.8},
            {'сын шлюхи ебаной я просто не знаю как тебя ещё назвать', 0.9, 'за твои действия пидарас', 1.5},
            {'какой же ты ХУЕСОС', 1.8, 'НУ Я МИССАЮ ЕМУ В РУКУ А ОН ДУМАЕТ', 0.8, 'ЧТО ЭТО ЛЦ', 1.4}
        }
    }

    local phrase_count = {
        bait = 0,
        kill = 0,
        death = 0
    }

    local function say_phrases (phrase_table)
        local current_delay = 0
        for i = 1, #phrase_table, 2 do
            local message = phrase_table[i]
            local delay = phrase_table[i+1] or 3
            
            current_delay = current_delay + delay
            client.delay_call(current_delay, function() 
                client.exec(('say %s'):format(message)) 
            end)
        end
    end

    local function on_player_death (e)
        if not elements.misc.trash_talk.enable:get() then 
            return 
        end
    
        local player, victim, attacker = entity.get_local_player(), client.userid_to_entindex(e.userid), client.userid_to_entindex(e.attacker)
        if not player or not victim or not attacker then 
            return 
        end
    
        if attacker == player and victim ~= player then
            phrase_count.bait = (phrase_count.bait % #phrases.bait) + 1
            phrase_count.kill = (phrase_count.kill % #phrases.kill) + 1
        elseif victim == player and attacker ~= player then
            phrase_count.death = (phrase_count.death % #phrases.death) + 1
        end
    
        local selected_phrases = { 
            bait = phrases.bait[phrase_count.bait], 
            kill = phrases.kill[phrase_count.kill], 
            death = phrases.death[phrase_count.death] 
        }
    
        if elements.misc.trash_talk.settings.work:get('On kill') and attacker == player and victim ~= player then
            say_phrases(elements.misc.trash_talk.settings.type:get() == 'Bait' and selected_phrases.bait or selected_phrases.kill)
        elseif elements.misc.trash_talk.settings.work:get('On death') and victim == player and attacker ~= player then
            say_phrases(selected_phrases.death)
        end
    end

    client.set_event_callback('player_death', on_player_death)
end

---

logic.setup = pui.setup({elements.conditions, elements.defensive, elements.anti_aim, elements.aimbot, colors, elements.visuals, elements.misc, drag_slider}, true)
client.set_event_callback('shutdown', function ()
    if _G.DEBUG then
        _G.DEBUG = nil
    end

    cvar.cl_interpolate:set_int(1)
    cvar.cl_interp_ratio:set_int(2)
    cvar.r_aspectratio:set_int(0)
    cvar.viewmodel_fov:set_raw_float(68)
    cvar.viewmodel_offset_x:set_raw_float(2.5)
    cvar.viewmodel_offset_y:set_raw_float(0)
    cvar.viewmodel_offset_z:set_raw_float(-1.5)

    collectgarbage('collect')
    collectgarbage('collect')
end)-- dumped from hrisito forums by <youtube.com/@subtick> ~ rip hrisito 2025-2026
