-- Title: Old School
-- Script ID: 156
-- Source: page_156.html
----------------------------------------

local pui = require("gamesense/pui")
local ffi = require("ffi")
local group = pui.group("AA", "Anti-aimbot angles")
local vector = require("vector")
local c_entity = require("gamesense/entity")
local aa_funcs = require("gamesense/antiaim_funcs")

local client_latency, client_log, client_draw_rectangle, client_draw_circle_outline, client_userid_to_entindex, client_draw_indicator, client_draw_gradient, client_set_event_callback, client_screen_size, client_eye_position, client_current_threat = client.latency, client.log, client.draw_rectangle, client.draw_circle_outline, client.userid_to_entindex, client.draw_indicator, client.draw_gradient, client.set_event_callback, client.screen_size, client.eye_position, client.current_threat
local renderer_gradient, renderer_world_to_screen, renderer_line, renderer_text, renderer_indicator = renderer.gradient, renderer.world_to_screen, renderer.line, renderer.text, renderer.indicator
local client_draw_circle, client_color_log, client_delay_call, client_draw_text, client_visible, client_exec, client_trace_line, client_set_cvar = client.draw_circle, client.color_log, client.delay_call, client.draw_text, client.visible, client.exec, client.trace_line, client.set_cvar 
local client_draw_hitboxes, client_get_cvar, client_draw_line, client_camera_angles, client_draw_debug_text, client_random_int, client_random_float = client.draw_hitboxes, client.get_cvar, client.draw_line, client.camera_angles, client.draw_debug_text, client.random_int, client.random_float 
local entity_get_local_player, entity_is_enemy, entity_hitbox_position, entity_get_player_name, entity_get_steam64, entity_get_bounding_box, entity_get_all, entity_set_prop = entity.get_local_player, entity.is_enemy, entity.hitbox_position, entity.get_player_name, entity.get_steam64, entity.get_bounding_box, entity.get_all, entity.set_prop 
local entity_is_alive, entity_get_player_weapon, entity_get_prop, entity_get_players, entity_get_classname, entity_get_game_rules = entity.is_alive, entity.get_player_weapon, entity.get_prop, entity.get_players, entity.get_classname, entity.get_game_rules 
local globals_realtime, globals_absoluteframetime, globals_tickcount, globals_curtime, globals_mapname, globals_tickinterval, globals_framecount, globals_frametime, globals_maxplayers = globals.realtime, globals.absoluteframetime, globals.tickcount, globals.curtime, globals.mapname, globals.tickinterval, globals.framecount, globals.frametime, globals.maxplayers 
local ui_new_slider, ui_new_combobox, ui_reference, ui_set_visible, ui_is_menu_open, ui_new_color_picker, ui_set_callback, ui_set, ui_new_checkbox, ui_new_hotkey, ui_new_button, ui_new_multiselect, ui_get = ui.new_slider, ui.new_combobox, ui.reference, ui.set_visible, ui.is_menu_open, ui.new_color_picker, ui.set_callback, ui.set, ui.new_checkbox, ui.new_hotkey, ui.new_button, ui.new_multiselect, ui.get 
local math_ceil, math_tan, math_log10, math_randomseed, math_cos, math_sinh, math_random, math_huge, math_pi, math_max, math_atan2, math_ldexp, math_floor, math_sqrt, math_deg, math_atan, math_fmod = math.ceil, math.tan, math.log10, math.randomseed, math.cos, math.sinh, math.random, math.huge, math.pi, math.max, math.atan2, math.ldexp, math.floor, math.sqrt, math.deg, math.atan, math.fmod 
local math_acos, math_pow, math_abs, math_min, math_sin, math_frexp, math_log, math_tanh, math_exp, math_modf, math_cosh, math_asin, math_rad = math.acos, math.pow, math.abs, math.min, math.sin, math.frexp, math.log, math.tanh, math.exp, math.modf, math.cosh, math.asin, math.rad 
local table_maxn, table_foreach, table_sort, table_remove, table_foreachi, table_move, table_getn, table_concat, table_insert = table.maxn, table.foreach, table.sort, table.remove, table.foreachi, table.move, table.getn, table.concat, table.insert
local table_find = function(t, val) for i=1, #t do if t[i] == val then return i end end return nil end 
local string_find, string_format, string_rep, string_gsub, string_len, string_gmatch, string_dump, string_match, string_reverse, string_byte, string_char, string_upper, string_lower, string_sub = string.find, string.format, string.rep, string.gsub, string.len, string.gmatch, string.dump, string.match, string.reverse, string.byte, string.char, string.upper, string.lower, string.sub
local client_create_interface, client_find_signature, client_userid_to_entindex, client_reload_active_scripts, client_set_event_callback, client_unset_event_callback = client.create_interface, client.find_signature, client.userid_to_entindex, client.reload_active_scripts, client.set_event_callback, client.unset_event_callback
local ffi_cast, ffi_typeof, ffi_string, ffi_sizeof, ffi_new, ffi_copy, ffi_fill = ffi.cast, ffi.typeof, ffi.string, ffi.sizeof, ffi.new, ffi.copy, ffi.fill
local materialsystem_find_materials, bit_band, bit_bor, entity_get_origin = materialsystem.find_materials, bit.band, bit.bor, entity.get_origin
ffi.cdef[[
    typedef struct {
        int layer_order_preset;
        bool first_run_since_init;
        bool first_foot_plant_since_init;
        int last_update_tick;
        float eye_position_smooth_lerp;
        float strafe_change_weight_smooth_fall_off;
        float stand_walk_duration_state_has_been_valid;
        float stand_walk_duration_state_has_been_invalid;
        float stand_walk_how_long_to_wait_until_transition_can_blend_in;
        float stand_walk_how_long_to_wait_until_transition_can_blend_out;
        float stand_walk_blend_value;
        float stand_run_duration_state_has_been_valid;
        float stand_run_duration_state_has_been_invalid;
        float stand_run_how_long_to_wait_until_transition_can_blend_in;
        float stand_run_how_long_to_wait_until_transition_can_blend_out;
        float stand_run_blend_value;
        float crouch_walk_duration_state_has_been_valid;
        float crouch_walk_duration_state_has_been_invalid;
        float crouch_walk_how_long_to_wait_until_transition_can_blend_in;
        float crouch_walk_how_long_to_wait_until_transition_can_blend_out;
        float crouch_walk_blend_value;
        int cached_model_index;
        float step_height_left;
        float step_height_right;
        void* weapon_last_bone_setup;
        void* player;
        void* weapon;
        void* weapon_last;
        float last_update_time;
        int last_update_frame;
        float last_update_increment;
        float eye_yaw;
        float eye_pitch;
        float abs_yaw;
        float abs_yaw_last;
        float move_yaw;
        float move_yaw_ideal;
        float move_yaw_current_to_ideal;
        char pad1[4];
        float primary_cycle;
        float move_weight;
        float move_weight_smoothed;
        float anim_duck_amount;
        float duck_additional;
        float recrouch_weight;
        float position_current[3];
        float position_last[3];
        float velocity[3];
        float velocity_normalized[3];
        float velocity_normalized_non_zero[3];
        float velocity_length_xy;
        float velocity_length_z;
        float speed_as_portion_of_run_top_speed;
        float speed_as_portion_of_walk_top_speed;
        float speed_as_portion_of_crouch_top_speed;
        float duration_moving;
        float duration_still;
        bool on_ground;
        bool landing;  
        float jump_to_fall;
        float duration_in_air;
        float left_ground_height;
        float land_anim_multiplier;
        float walk_run_transition;
        bool landed_on_ground_this_frame;
        bool left_the_ground_this_frame;
        float in_air_smooth_value;
        bool on_ladder;
        float ladder_weight;
        float ladder_speed;
        bool walk_to_run_transition_state;
        bool defuse_started;
        bool plant_anim_started;
        bool twitch_anim_started;
        bool adjust_started;
        char activity_modifiers_server[20];
        float next_twitch_time;
        float time_of_last_known_injury;
        float last_velocity_test_time;
        float velocity_last[3];
        float target_acceleration[3];
        float acceleration[3];
        float acceleration_weight;
        float aim_matrix_transition;
        float aim_matrix_transition_delay;
        bool flashed;
        float strafe_change_weight;
        float strafe_change_target_weight;
        float strafe_change_cycle;
        int strafe_sequence;
        bool strafe_changing;
        float duration_strafing;
        float foot_lerp;
        bool feet_crossed;
        bool player_is_accelerating;
        char pad2[24];
        float duration_move_weight_is_too_high;
        float static_approach_speed;
        int previous_move_state;
        float stutter_step;
        float action_weight_bias_remainder;
        char pad3[112];
        float camera_smooth_height;
        bool smooth_height_valid;
        float last_time_velocity_over_ten;
        float unk;
        float aim_yaw_min;
        float aim_yaw_max;
        float aim_pitch_min;
        float aim_pitch_max;
        int animstate_model_version;
    } anim_state_t;

    typedef void* (__thiscall* get_client_entity)(void*, int);
]]

local get_client_entity = vtable_bind("client.dll", "VClientEntityList003", 3, "void*(__thiscall*)(void*, int)")

local tab_manager = {
    tabs = {},
    current = nil,
    combobox = nil
}

function tab_manager:create(name)
    self.tabs[name] = {}
    return self.tabs[name]
end

function tab_manager:add(tab_name, element)
    table.insert(self.tabs[tab_name], element)
    return element
end

function tab_manager:update()
    local current = self.combobox:get()
    
    for tab_name, elements in pairs(self.tabs) do
        local visible = (tab_name == current)
        for _, element in ipairs(elements) do
            element:set_visible(visible)
        end
    end
end

function angle_diff_deg(a, b)
    local diff = a - b
    while diff < -180 do
        diff = diff + 360
    end
    while diff > 180 do
        diff = diff - 360
    end
    return diff
end

function clamp(v, min, max)
    if v > max then return max end
    if v < min then return min end
    return v
end

local refs = {
    aa_enabled = pui.reference("AA", "Anti-aimbot angles", "Enabled"),
    edge_yaw = pui.reference("AA", "Anti-aimbot angles", "Edge yaw"),
    freestanding = {pui.reference("AA", "Anti-aimbot angles", "Freestanding")},
    roll = pui.reference("AA", "Anti-aimbot angles", "Roll"),
    yaw_jitter = {pui.reference("AA", "Anti-aimbot angles", "Yaw jitter")},
    
    bodyyaw = {pui.reference("AA", "Anti-aimbot angles", "Body yaw")},
    pitch = {pui.reference("AA", "Anti-aimbot angles", "Pitch")},
    yaw_base = pui.reference("AA", "Anti-aimbot angles", "Yaw base"),
    yaw = {pui.reference("AA", "Anti-aimbot angles", "Yaw")},
    fd_enabled = pui.reference("RAGE", "Other", "Duck peek assist"),
    fl_enabled = pui.reference("AA", "Fake lag", "Enabled"),
    fl_limit = pui.reference("AA", "Fake lag", "Limit"),
    dt_fl_limit = pui.reference("RAGE", "Aimbot", "Double tap fake lag limit"),
    dt_enabled = {pui.reference("RAGE", "Aimbot", "Double tap")},
    hs_enabled = {pui.reference("AA", "Other", "On shot anti-aim")},
}

local gui = {
    anti_aim = {
        init = function (self)
            refs.bodyyaw[1]:override()
            refs.yaw_base:override()
            refs.yaw[1]:override()
            refs.roll:override()
            refs.edge_yaw:override()
            refs.freestanding[1]:override()
            refs.yaw_jitter[1]:override()
            refs.aa_enabled:override()
            refs.pitch[1]:override()
            
            refs.bodyyaw[1]:set_visible(false)
            if refs.bodyyaw[2] then refs.bodyyaw[2]:set_visible(false) end
            
            refs.yaw_base:set_visible(false)
            
            refs.yaw[1]:set_visible(false)
            if refs.yaw[2] then refs.yaw[2]:set_visible(false) end
            
            refs.roll:set_visible(false)
            refs.edge_yaw:set_visible(false)
            
            refs.freestanding[1]:set_visible(false)
            if refs.freestanding[2] then refs.freestanding[2]:set_visible(false) end
            
            refs.yaw_jitter[1]:set_visible(false)
            if refs.yaw_jitter[2] then refs.yaw_jitter[2]:set_visible(false) end

            refs.aa_enabled:set_visible(false)

            refs.pitch[1]:set_visible(false)
            if refs.pitch[2] then refs.pitch[2]:set_visible(false) end
            
            self.aa = {
                pitch = tab_manager:add("Anti-Aim", pui.combobox(group, "Pitch", {"Down", "Up", "Default"})),
                yaw_base = tab_manager:add("Anti-Aim", pui.combobox(group, "Yaw base", {"At targets", "Local view"})),
                yaw = tab_manager:add("Anti-Aim", pui.combobox(group, "Yaw", {"Off", "180°"})),
                yaw_offset = tab_manager:add("Anti-Aim", pui.slider(group, "Yaw offset", -180, 180, 0, true, "°")),
                desync_type = tab_manager:add("Anti-Aim", pui.combobox(group, "Desync type", {"Off", "Static", "Opposite", "Opposite 2"})),
                desync_degree = tab_manager:add("Anti-Aim", pui.slider(group, "Desync degree", 0, 58, 0, true,"°")),
                inverter = tab_manager:add("Anti-Aim", pui.hotkey(group, "Inverter")),
                lby_delta = tab_manager:add("Anti-Aim", pui.slider(group, "LBY delta", 0, 180, 180, true, "°")),
                lby_update_time = tab_manager:add("Anti-Aim", pui.slider(group, "LBY update time", 55, 500, 150, true, "ms")),

                fakelag = tab_manager:add("Anti-Aim", pui.checkbox(group, "FakeLag")),
                fakelag_type = tab_manager:add("Anti-Aim", pui.combobox(group, "FakeLag type", {"Maximum", "Dynamic", "Fluctuate"})),
                fakelag_limit = tab_manager:add("Anti-Aim", pui.slider(group, "FakeLag Limit", 1, 15, 14, true, "t")),
            }
        end,
        setup_dependencies = function (self)
            self.aa.yaw_offset:depend({self.aa.yaw, "180"})
            self.aa.desync_degree:depend({self.aa.desync_type, "Static", "Opposite", "Opposite 2"})
            self.aa.lby_delta:depend({self.aa.desync_type, "Opposite"})
            self.aa.lby_update_time:depend({self.aa.desync_type, "Opposite"})

            self.aa.fakelag_type:depend({self.aa.fakelag, true})
            self.aa.fakelag_limit:depend({self.aa.fakelag, true})
        end,

        setup_tab_dependencies = function (self)
            for _, element in pairs(self.aa) do
                element:depend({tab_manager.combobox, "Anti-Aim"})
            end
        end,
        restore = function (self)
            refs.bodyyaw[1]:set_visible(true)
            if refs.bodyyaw[2] then refs.bodyyaw[2]:set_visible(true) end
            
            refs.yaw_base:set_visible(true)
            
            refs.yaw[1]:set_visible(true)
            if refs.yaw[2] then refs.yaw[2]:set_visible(true) end
            
            refs.roll:set_visible(true)
            refs.edge_yaw:set_visible(true)
            
            refs.freestanding[1]:set_visible(true)
            if refs.freestanding[2] then refs.freestanding[2]:set_visible(true) end
            
            refs.yaw_jitter[1]:set_visible(true)
            if refs.yaw_jitter[2] then refs.yaw_jitter[2]:set_visible(true) end

            refs.aa_enabled:set_visible(true)

            refs.pitch[1]:set_visible(true)
            if refs.pitch[2] then refs.pitch[2]:set_visible(true) end
        end,
    },

    visuals = {
        init = function (self)
            self.indicators = {
                enabled = tab_manager:add("Visuals", pui.checkbox(group, "Enable indicators")),
                desync_angle = tab_manager:add("Visuals", pui.checkbox(group, "Desync angle")),
                lby_timer = tab_manager:add("Visuals", pui.checkbox(group, "LBY timer")),
                body_yaw_side = tab_manager:add("Visuals", pui.checkbox(group, "Desync side")),
                fakelag = tab_manager:add("Visuals", pui.checkbox(group, "FakeLag indicator")),       
            }
        end,
        setup_dependencies = function (self)
            self.indicators.desync_angle:depend({self.indicators.enabled, true})
            self.indicators.lby_timer:depend({self.indicators.enabled, true})
            self.indicators.body_yaw_side:depend({self.indicators.enabled, true})
            self.indicators.fakelag:depend({self.indicators.enabled, true})
        end,
        setup_tab_dependencies = function (self)
            for _, element in pairs(self.indicators) do
                element:depend({tab_manager.combobox, "Visuals"})
            end
        end
    }
}

local anti_aim = {
    nades = 0,
    lby_update_time = 0.0,
    lby_force_choke = false,

    next_lby_update = 0.0,
    switch = false,
    fast_lby = 0.0,

    broke_lby = false,

    last_inverter = nil,
    flip_tick = -1,
    flip_extend_until = -1,

    fluctuate_phase = 0,
    fluctuate_direction = 1,
    fluctuate_current = 1,

    fl_history = {},
    last_choked = 0,
    fl_last_update = 0,
    fl_update_delay = 0.5,
    fl_pending_value = 0,
    fl_display_text = "FL: ",
}

anti_aim.micromove = function (cmd)
    local me = entity_get_local_player()
    if not me then return end
    
    local speed = 1.1
    local velocity = vector(entity_get_prop(me, "m_vecVelocity")):length2d()

    if bit_band(entity_get_prop(me, "m_fFlags"), 4) == 4 or refs.fd_enabled:get() then
        speed = speed * 3
    end
    if velocity < 3 then
        if anti_aim.switch then
            cmd.sidemove = cmd.sidemove + speed
        else
            cmd.sidemove = cmd.sidemove - speed
        end
        anti_aim.switch = not anti_aim.switch
    end
end

anti_aim.micromove_with_lby = function (cmd)
    local me = entity_get_local_player()
    if not me then return end
    
    local speed = 1.1
    local velocity = vector(entity_get_prop(me, "m_vecVelocity")):length2d()

    if bit_band(entity_get_prop(me, "m_fFlags"), 4) == 4 or refs.fd_enabled:get() then
        speed = speed * 3
    end
    if velocity < 3 and globals_curtime() < anti_aim.fast_lby then
        if anti_aim.switch then
            cmd.sidemove = cmd.sidemove + speed
        else
            cmd.sidemove = cmd.sidemove - speed
        end
        anti_aim.switch = not anti_aim.switch
    end
end

anti_aim.get_custom_fl_limit = function(cmd)
    if not gui.anti_aim.aa.fakelag:get() then return nil end

    local me = entity_get_local_player()
    if not me then return nil end

    local base = gui.anti_aim.aa.fakelag_limit:get() or 1
    base = clamp(base, 1, 15)

    local mode = gui.anti_aim.aa.fakelag_type:get() or "Maximum"


    if refs.fd_enabled:get() then
        return math.min(base, 13)
    end
    
    local dt_active = (refs.dt_enabled[1] and refs.dt_enabled[1].hotkey and refs.dt_enabled[1].hotkey:get() and refs.dt_enabled[1]:get()) or false
    local hs_active = (refs.hs_enabled[1] and refs.hs_enabled[1].hotkey and refs.hs_enabled[1].hotkey:get() and refs.hs_enabled[1]:get()) or false
    if dt_active or hs_active then
        return 1
    end

    local vel2d = vector(entity_get_prop(me, "m_vecVelocity")):length2d()
    local speed_frac = clamp(vel2d / 250.0, 0.0, 1.0)

    local chosen = base
    if mode == "Maximum" then
        chosen = base
    elseif mode == "Dynamic" then
        local half = math.max(1, math.floor(base * 0.5 + 0.5))
        chosen = math.floor(half + (base - half) * speed_frac)
    elseif mode == "Fluctuate" then

        local min_value = math.max(1, math.floor(base * 0.5))
        local max_value = base
        local range = max_value - min_value
        
        anti_aim.fluctuate_phase = anti_aim.fluctuate_phase + 0.1
        if anti_aim.fluctuate_phase > math.pi * 2 then
            anti_aim.fluctuate_phase = anti_aim.fluctuate_phase - math.pi * 2
        end
        
        local sine = (math.sin(anti_aim.fluctuate_phase) + 1) * 0.5
        chosen = math.floor(min_value + range * sine)
        
        --[[
        local step = 1
        anti_aim.fluctuate_current = anti_aim.fluctuate_current + step * anti_aim.fluctuate_direction
        
        if anti_aim.fluctuate_current >= max_value then
            anti_aim.fluctuate_current = max_value
            anti_aim.fluctuate_direction = -1
        elseif anti_aim.fluctuate_current <= min_value then
            anti_aim.fluctuate_current = min_value
            anti_aim.fluctuate_direction = 1
        end
        
        chosen = math.floor(anti_aim.fluctuate_current)
        --]]
    end

    local weapon = entity_get_player_weapon(me)
    if weapon then
        local weapon_name = entity_get_classname(weapon)
        if weapon_name == "CC4" then
            chosen = math.min(chosen, 13)
        end
    end

    return clamp(chosen, 1, 15)
end

anti_aim.manage_fl_history = function ()
    local current_time = globals_curtime()
    if current_time - anti_aim.fl_last_update >= anti_aim.fl_update_delay then
        if anti_aim.fl_pending_value > 0 then
            table.insert(anti_aim.fl_history, 1, anti_aim.fl_pending_value)
            if #anti_aim.fl_history > 4 then
                table.remove(anti_aim.fl_history, #anti_aim.fl_history)
            end
            anti_aim.fl_pending_value = 0
        end
        
        local fl_text = "FL: "
        for i, value in ipairs(anti_aim.fl_history) do
            fl_text = fl_text .. value
            if i < #anti_aim.fl_history then
                fl_text = fl_text .. "-"
            end
        end
        anti_aim.fl_display_text = fl_text
        anti_aim.fl_last_update = current_time
    end
end

anti_aim.manage_choke = function(cmd)
    if not gui.anti_aim.aa.fakelag:get() then 
        anti_aim.fl_display_text = "FL: "
        return 

    end

    if refs.fl_enabled then
        refs.fl_enabled:set(false)
    end

    local limit = anti_aim.get_custom_fl_limit(cmd)
    if not limit then return end
    
    if cmd.in_attack == 1 then
        cmd.allow_send_packet = true
        anti_aim.fl_pending_value = math.max(anti_aim.fl_pending_value, cmd.chokedcommands)
        anti_aim.last_choked = 0
        return
    end

    if refs.fd_enabled:get() then
        cmd.allow_send_packet = (cmd.chokedcommands >= 13)
        if cmd.allow_send_packet then
            anti_aim.fl_pending_value = math.max(anti_aim.fl_pending_value, cmd.chokedcommands)
            anti_aim.last_choked = 0
        else
            anti_aim.last_choked = cmd.chokedcommands
        end
        return
    end


    if cmd.chokedcommands < limit then
        cmd.allow_send_packet = false
        anti_aim.last_choked = cmd.chokedcommands
    else
        cmd.allow_send_packet = true
        anti_aim.fl_pending_value = math.max(anti_aim.fl_pending_value, cmd.chokedcommands)
        anti_aim.last_choked = 0
    end

    anti_aim.manage_fl_history()
end


anti_aim.desync_check = function (cmd)
    local me = entity_get_local_player()
    if not me then return false end

    if cmd.in_use == 1 then
        return false
    end
    
    local weapon = entity_get_player_weapon(me)
    if not weapon then return false end

    if cmd.in_attack == 1 then
        local weapon_name = entity_get_classname(weapon)

        if weapon_name == nil then
            return false
        end

        if weapon_name:find("Grenade") or weapon_name:find("Flashbang") then
            anti_aim.nades = globals_tickcount() 
        else
            local next_primary = entity_get_prop(weapon, "m_flNextPrimaryAttack")
            local next_attack = entity_get_prop(me, "m_flNextAttack")

            if next_primary and next_attack then
                if math.max(next_primary, next_attack) - globals_tickinterval() - globals_curtime() < 0 then
                    return false
                end
            end
        end
    end

    local throw = entity_get_prop(weapon, "m_fThrowTime")

    if anti_aim.nades + 15 == globals_tickcount() or (throw ~= nil and throw ~= 0) then
        return false
    end

    local game_rules = entity_get_game_rules()
    if game_rules and entity_get_prop(game_rules, "m_bFreezePeriod") == 1 then
        return false
    end

    local move_type = entity_get_prop(me, "m_MoveType")
    if move_type == 9 or move_type == 10 then
        return false
    end

    return true
end

anti_aim.calculate_pitch = function ()
    local mode = gui.anti_aim.aa.pitch:get()
    if mode == "Off" then
        return 0
    elseif mode == "Up" then
        return -89
    elseif mode == "Down" then
        return 89
    end
    return 0
end

anti_aim.get_yaw_base = function()
    local me = entity_get_local_player()
    if not me then return 0 end
    
    local _, cam_yaw = client_camera_angles()
    local yaw_base = gui.anti_aim.aa.yaw_base:get()
    
    if yaw_base == "At targets" then
        local threat = client_current_threat()
        if threat then
            local x1, y1, z1 = entity_get_origin(me)
            local x2, y2, z2 = entity_get_origin(threat)
            
            if x1 and x2 then
                local dx = x2 - x1
                local dy = y2 - y1
                cam_yaw = math.deg(math.atan2(dy, dx))
            end
        end
    end
    
    return cam_yaw
end

anti_aim.calculate_yaw = function()
    local yaw_base = anti_aim.get_yaw_base()
    local yaw = gui.anti_aim.aa.yaw:get()
    local yaw_offset = gui.anti_aim.aa.yaw_offset:get()

    local result = 0

    if yaw == "180°" then
        result = 180
    end

    result = result + yaw_base + yaw_offset
    return result
end

anti_aim.ticks_to_time = function (ticks)
    return globals_tickinterval() * ticks
end

anti_aim.normalize_yaw = function(yaw)
    while yaw > 180 do
        yaw = yaw - 360
    end
    while yaw < -180 do
        yaw = yaw + 360
    end
    return yaw
end

anti_aim.get_animstate = function (index)
    if not index or index == 0 then return nil end

    local client_entity = get_client_entity( index )
    if client_entity == nil or client_entity == ffi.NULL then return nil end

    local base_ptr = ffi.cast( "uintptr_t", client_entity )
    local anim_state_ptr = ffi.cast( "anim_state_t**", base_ptr + 0x9960 )
    if anim_state_ptr == nil or anim_state_ptr[ 0 ] == nil then return nil end

    return anim_state_ptr[ 0 ]
end

anti_aim.get_current_desync = function (mod_yaw)
    local me = entity_get_local_player()
    if not me then return 0 end
    local animstate = anti_aim.get_animstate(me)
    if not animstate then return 0 end
    local cur = anti_aim.normalize_yaw(animstate.eye_yaw - animstate.abs_yaw)
    return math.abs(mod_yaw - math.abs(cur))
end

anti_aim.get_lby_breaker_time = function ()
    local custom_time = gui.anti_aim.aa.lby_update_time:get() / 1000
    return refs.fd_enabled:get() and 0.4 or custom_time
end

anti_aim.break_lby = function (cmd)
    local is_fakeducking = refs.fd_enabled:get()
    if cmd.chokedcommands >= 13 and is_fakeducking then return 0 end

    local lby_delta = gui.anti_aim.aa.lby_delta:get()
    
    if globals_curtime() >= anti_aim.lby_update_time then
        cmd.allow_send_packet = false
        anti_aim.lby_update_time = globals_curtime() + anti_aim.get_lby_breaker_time()
        anti_aim.micromove(cmd)
        return lby_delta
    end
    if anti_aim.lby_force_choke then
        anti_aim.lby_force_choke = false
        cmd.allow_send_packet = false
    end
    return 0
end

anti_aim.get_max_desync = function()
    local me = entity_get_local_player()
    if not me then return 0 end
    
    local animstate = anti_aim.get_animstate(me)
    if not animstate then return 0 end

    local duck_amount = animstate.anim_duck_amount

    local speed_fraction = clamp(animstate.speed_as_portion_of_walk_top_speed, 0.0, 1.0);
    local speed_factor = clamp(animstate.speed_as_portion_of_crouch_top_speed, 0.0, 1.0);
    local modifier = (animstate.walk_run_transition * -0.30000001 - 0.19999999) * speed_fraction + 1.0;

    if duck_amount > 0.0 then
        modifier = modifier + duck_amount * speed_factor * (0.5 - modifier);
    end
    return animstate.aim_yaw_max * modifier;
end

anti_aim.should_break = function ()
    local me = entity_get_local_player()
    if not me then return end
    if not entity_is_alive(me) then return end

    local animstate = anti_aim.get_animstate(me)
    if not animstate then return end
    if not animstate.on_ground then return end

    local velocity = vector(entity_get_prop(me, "m_vecVelocity")):length2d()

    if velocity > 0.1 or math.abs(animstate.velocity_length_z) > 100.0 then
        anti_aim.next_lby_update = globals_curtime() + 0.22
    elseif globals_curtime() > anti_aim.next_lby_update then
        anti_aim.next_lby_update = globals_curtime() + 1.1
        return true
    end
    return false
end

anti_aim.update_inverter = function()
    local inv = gui.anti_aim.aa.inverter:get()
    if anti_aim.last_inverter == nil then
        anti_aim.last_inverter = inv
        return false
    end
    if inv ~= anti_aim.last_inverter then
        anti_aim.last_inverter = inv
        anti_aim.flip_tick = globals_tickcount()

        local me = entity_get_local_player()
        if me then
            local vel2d = vector(entity_get_prop(me, "m_vecVelocity")):length2d()
            if vel2d > 120 then
                anti_aim.flip_extend_until = anti_aim.flip_tick + 1
            else
                anti_aim.flip_extend_until = anti_aim.flip_tick
            end
        end
        return true
    end
    return false
end

anti_aim.apply_flip_microstop = function(cmd)
    local now = globals_tickcount()
    if now ~= anti_aim.flip_tick and now > anti_aim.flip_extend_until then
        return
    end

    cmd.allow_send_packet = false

    cmd.forwardmove = 0
    cmd.sidemove = 0
end

anti_aim.run = function(cmd)
    local me = entity_get_local_player()
    if not me or not entity_is_alive(me) then return end

    local pitch = anti_aim.calculate_pitch()
    local yaw = anti_aim.calculate_yaw()
    local is_inverted = gui.anti_aim.aa.inverter:get()

    if gui.anti_aim.aa.fakelag:get() then
        anti_aim.manage_choke(cmd)
    end

    anti_aim.update_inverter()
    anti_aim.apply_flip_microstop(cmd)

    local desync_side = is_inverted and 1 or -1
    local desync_type = gui.anti_aim.aa.desync_type:get()
    local desync_angle = gui.anti_aim.aa.desync_degree:get()
    refs.bodyyaw[1]:set("Off")

    local is_flipped = (anti_aim.flip_tick == globals_tickcount())
    
    if desync_type == "Opposite" then
        if anti_aim.desync_check(cmd) then
            local actual_desync = desync_angle * desync_side
            local is_standing = vector(entity_get_prop(me, "m_vecVelocity")):length2d() < 4
            
            local cur_desync = anti_aim.get_current_desync(anti_aim.get_yaw_base() - yaw)

            if not is_standing and cur_desync < math.abs(actual_desync) then
                actual_desync = (actual_desync / math.abs(actual_desync)) * 120
            end
            
            local final_yaw = yaw
            
            if is_standing then
                local lby_offset = anti_aim.break_lby(cmd)
                if lby_offset > 0 and not is_flipped then
                    final_yaw = yaw + lby_offset
                    actual_desync = actual_desync * 2
                    cmd.allow_send_packet = false
                    anti_aim.broke_lby = true
                else
                    anti_aim.broke_lby = false
                end
            else
                anti_aim.broke_lby = false
            end

            if not cmd.allow_send_packet and not anti_aim.broke_lby then 
                final_yaw = final_yaw - actual_desync 
            end

            cmd.yaw = anti_aim.normalize_yaw(final_yaw)
            cmd.pitch = pitch
        end
    elseif desync_type == "Opposite 2" then
        if anti_aim.desync_check(cmd) then
            local final_yaw = yaw
            
            if anti_aim.should_break() then
                final_yaw = yaw + 120 * desync_side
                cmd.allow_send_packet = false
            elseif not cmd.allow_send_packet then
                final_yaw = yaw - 120 * desync_side
            end
            
            cmd.yaw = anti_aim.normalize_yaw(final_yaw)
            cmd.pitch = pitch
        end
    elseif desync_type == "Static" then
        if anti_aim.desync_check(cmd) then
            local vel2d = vector(entity_get_prop(me, "m_vecVelocity")):length2d()
            local moving = vel2d > 3

            if anti_aim.flip_tick == globals_tickcount() then
                cmd.allow_send_packet = false
                if moving then
                    cmd.forwardmove = 0
                    cmd.sidemove = 0
                end
            end

            if not moving then
                anti_aim.micromove_with_lby(cmd)
            end

            if cmd.allow_send_packet then
                cmd.yaw = yaw
            else
                if not moving and globals_curtime() >= anti_aim.fast_lby and not is_flipped then
                    cmd.yaw = yaw
                    anti_aim.fast_lby = globals_curtime() + 0.22
                else
                    local target = desync_angle * desync_side
                    if not moving then
                        if desync_angle > 50 then
                            target = target * 2
                        end
                    end
                    cmd.yaw = yaw - target
                end
            end
            cmd.pitch = pitch
        end
    elseif desync_type == "Off" then
        if anti_aim.desync_check(cmd) then
            cmd.yaw = yaw
            cmd.pitch = pitch
        end
    end
end


local indicators = {
    draw = function()
        if not gui.visuals.indicators.enabled:get() then return end
        
        local me = entity_get_local_player()
        if not me or not entity_is_alive(me) then return end
        
        local screen_w, screen_h = client_screen_size()
        local center_x = screen_w / 2
        local center_y = screen_h / 2
        
        local r, g, b, a = 254, 254, 254, 254
        
        if gui.visuals.indicators.body_yaw_side:get() then
            local is_inverted = gui.anti_aim.aa.inverter:get()
            
            local triangle_size = 10
            local triangle_distance = 35
            
            local active_r, active_g, active_b = r, g, b
            local inactive_r, inactive_g, inactive_b = 50, 50, 50
            local inactive_alpha = 100
            
            if is_inverted then
                local x = center_x + triangle_distance
                local y = center_y
                
                renderer.triangle(
                    x, y - triangle_size,
                    x, y + triangle_size,
                    x + triangle_size, y,
                    active_r, active_g, active_b, a
                )
                
                local x2 = center_x - triangle_distance
                renderer.triangle(
                    x2, y - triangle_size,
                    x2, y + triangle_size,
                    x2 - triangle_size, y,
                    inactive_r, inactive_g, inactive_b, inactive_alpha
                )
            else
                local x = center_x - triangle_distance
                local y = center_y
                
                renderer.triangle(
                    x, y - triangle_size,
                    x, y + triangle_size,
                    x - triangle_size, y,
                    active_r, active_g, active_b, a
                )
                
                local x2 = center_x + triangle_distance
                renderer.triangle(
                    x2, y - triangle_size,
                    x2, y + triangle_size,
                    x2 + triangle_size, y,
                    inactive_r, inactive_g, inactive_b, inactive_alpha
                )
            end
        end
        
        
        if gui.visuals.indicators.desync_angle:get() then
            local real_desync = aa_funcs.get_desync(1)  

            renderer_indicator(255, 255, 255, 255, string.format("Desync: %.0f°", real_desync))
        end

        if gui.visuals.indicators.fakelag:get() and gui.anti_aim.aa.fakelag:get() then
            local mode = gui.anti_aim.aa.fakelag_type:get()
            local fl_r, fl_g, fl_b = 255, 255, 255
            
            if mode == "Maximum" then
                fl_r, fl_g, fl_b = 100, 200, 255 
            elseif mode == "Dynamic" then
                fl_r, fl_g, fl_b = 255, 200, 100
            elseif mode == "Fluctuate" then
                fl_r, fl_g, fl_b = 200, 255, 100 
            end
            
            local dt_active = (refs.dt_enabled[1] and refs.dt_enabled[1].hotkey and refs.dt_enabled[1].hotkey:get() and refs.dt_enabled[1]:get()) or false
            local hs_active = (refs.hs_enabled[1] and refs.hs_enabled[1].hotkey and refs.hs_enabled[1].hotkey:get() and refs.hs_enabled[1]:get()) or false
            
            if dt_active or hs_active then
                fl_r, fl_g, fl_b = 255, 100, 100
            end
            
            renderer_indicator(fl_r, fl_g, fl_b, a, anti_aim.fl_display_text)
        end

        if gui.visuals.indicators.lby_timer:get() then
            local desync_type = gui.anti_aim.aa.desync_type:get()
            if desync_type == "Opposite" then
                local lby_time_left = math.max(0, anti_aim.lby_update_time - globals_curtime())
                local lby_ready = lby_time_left <= 0.05
                
                
                local lby_color_r = lby_ready and 255 or 10
                local lby_color_g = lby_ready and 10 or 255
                
                renderer_indicator(lby_color_r, lby_color_g, b, a, string.format("LBY: %.2fs", lby_time_left))
            elseif desync_type == "Opposite 2" then
                local lby_time_left = math.max(0, anti_aim.next_lby_update - globals_curtime())
                local lby_ready = lby_time_left <= 0.05
                
                
                local lby_color_r = lby_ready and 255 or 10
                local lby_color_g = lby_ready and 10 or 255
                
                renderer_indicator(lby_color_r, lby_color_g, b, a, string.format("LBY: %.2fs", lby_time_left))
            end
        end
    end
}

local function setup()
    group:label("\v O L D  S C H O O L\r")
    
    local tab_names = {"Anti-Aim", "Visuals"}
    tab_manager.combobox = pui.combobox(group, "Tabs", tab_names)


    for _, name in ipairs(tab_names) do
        tab_manager:create(name)
    end

    gui.anti_aim:init()
    gui.anti_aim:setup_dependencies()
    gui.anti_aim:setup_tab_dependencies()
    
    gui.visuals:init()
    gui.visuals:setup_dependencies()
    gui.visuals:setup_tab_dependencies()
    
end

setup()

client_set_event_callback("setup_command", function (cmd)
    anti_aim.run(cmd)
end)

client_set_event_callback("paint", function ()
    indicators.draw()
end)

client_set_event_callback("shutdown", function ()
    gui.anti_aim:restore()
end)

client_set_event_callback("round_prestart", function ()
    anti_aim.lby_update_time = anti_aim.get_lby_breaker_time()
    anti_aim.next_lby_update = 0.0
    anti_aim.fast_lby = 0.0
end)-- dumped from hrisito forums by <youtube.com/@subtick> ~ rip hrisito 2025-2026
