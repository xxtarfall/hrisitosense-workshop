-- Title: World Enhancer
-- Script ID: 136
-- Source: page_136.html
----------------------------------------

local ffi = require("ffi")
local weapons = require("gamesense/csgo_weapons")
local pui = require("gamesense/pui")
local easing = require("gamesense/easing")
local group = pui.group("LUA", "A")

local client_latency, client_log, client_draw_rectangle, client_draw_circle_outline, client_userid_to_entindex, client_draw_indicator, client_draw_gradient, client_set_event_callback, client_screen_size, client_eye_position = client.latency, client.log, client.draw_rectangle, client.draw_circle_outline, client.userid_to_entindex, client.draw_indicator, client.draw_gradient, client.set_event_callback, client.screen_size, client.eye_position 
local renderer_gradient, renderer_world_to_screen, renderer_line = renderer.gradient, renderer.world_to_screen, renderer.line
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

ffi.cdef([[
    typedef struct c_con_command_base {
        void *vtable;
        void *next;
        bool registered;
        const char *name;
        const char *help_string;
        int flags;
        void *s_cmd_base;
        void *accessor;
    } c_con_command_base;

    typedef struct {
        float x, y, z;
    } Vector;

    typedef void*(*CreateClass)(int, int);
    typedef void*(*CreateEvent)();
    
    typedef struct {
        CreateClass create_class;
        CreateEvent create_event;
        char* network_name;
        void* recv_table;
        void* next;
        int class_id;
    } ClientClass;
]])

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

-- ============================================
-- VARIABLES
-- ============================================

local vars = {

    aspect_ratio = {
        old_aspect_ratio = client_get_cvar("r_aspectratio"),
    },
    
    weapon_skybox_chams = {
        materials = {},
        material_names = {"Off"},
        current_material = nil,
        available_materials = {
            "RetroSun", "Space 1", "Space 4", "Space 5", "Space 6", "Space 7",
            "Space 8", "Space 9", "Space 10", "Space 13", "Space 14", "Space 16",
            "Space 17", "Space 18", "Space 19", "Steve"
        },
    },

    thirdperson = {
        old_distance = client_get_cvar("cam_idealdist"),
    },

    skybox = {
        old_skybox = client_get_cvar("sv_skyname"),
        skyboxes = {
            "cs_tibet",
            "cs_baggage_skybox_",
            "embassy",
            "italy",
            "jungle",
            "office",
            "sky_cs15_daylight01_hdr",
            "vertigoblue_hdr",
            "sky_cs15_daylight02_hdr",
            "vertigo",
            "sky_day02_05_hdr",
            "nukeblank",
            "sky_venice",
            "sky_cs15_daylight03_hdr",
            "sky_cs15_daylight04_hdr",
            "sky_csgo_cloudy01",
            "sky_csgo_night02",
            "sky_csgo_night02b",
            "sky_csgo_night_flat",
            "sky_dust",
            "vietnam",
        },
    },

    hidden_cvars = {
        v_engine_cvar = client_create_interface('vstdlib.dll', 'VEngineCvar007'),
        cvars = {},
    },

    viewmodel = {
        old_fov = client_get_cvar("viewmodel_fov"),
        old_x = client_get_cvar("viewmodel_offset_x"),
        old_y = client_get_cvar("viewmodel_offset_y"),
        old_z = client_get_cvar("viewmodel_offset_z"),
    },

    autobuy = {
        primary = {
            "-",
            "SSG 08",
            "AWP",
            "SCAR-20/G3SG1",
        },
        
        secondary = {
            "-",
            "Deagle/R8",
            "CZ-75/Tec-9/Five-Seven",
            "Dual Berretas",
            "P250",
        },
        
        grenades = {
            "HE Grenade",
            "Molotov",
            "Smoke",
            "Flash",
            "Flash",
        },
        
        utilities = {
            "Armor",
            "Helmet",
            "Zeus",
            "Defuser",
        },
        commands = {
            ["-"] = "",
            ["AWP"] = "buy awp",
            ["SSG 08"] = "buy ssg08",
            ["SCAR-20/G3SG1"] = "buy scar20",
            ["Deagle/R8"] = "buy deagle",
            ["CZ-75/Tec-9/Five-Seven"] = "buy tec9",
            ["P250"] = "buy p250",
            ["Dual Berretas"] = "buy elite",
            ["HE Grenade"] = "buy hegrenade",
            ["Molotov"] = "buy molotov",
            ["Smoke"] = "buy smokegrenade",
            ["Flash"] = "buy flashbang",
            ["Armor"] = "buy vest",
            ["Helmet"] = "buy vesthelm",
            ["Zeus"] = "buy taser 34",
            ["Defuser"] = "buy defuser",
        }
    },

    effects = {
        bloom_old = nil,
        exposure_min_old = nil,
        exposure_max_old = nil,
        bloom_prev = nil,
        exposure_prev = nil,
        model_ambient_prev = nil,
    },

    weather = {
        enabled = false,
        weather_style = 0,
        precipitation_class = nil,
        precipitation_entity_idx = nil,
        created = false,
        need_bounds_update = false,
        precipitation_types = {
            ["Rain 1"] = 0,
            ["Rain 2"] = 1
        },
        snow_cvars = {
            particles = 300,
            fall_speed = 1.5,
            wind_scale = 0.0035,
        },
    },

    sleeves = {
        materials = {},
        original_alpha = {},
    },

    custom_scope = {
        scope_overlay = ui_reference('VISUALS', 'Effects', 'Remove scope overlay'),
        m_alpha = 0,
        clamp = function(v, min, max)
            local num = v
            num = num < min and min or num
            num = num > max and max or num
            return num
        end,
    },

    bullet_tracers = {
        to_draw = {},
    },
    
    hitbox_data = {
        to_draw = {},
    },
}

-- ============================================
-- UTILS
-- ============================================

local utils = {
    bind_signature = function(module, interface, signature, typestring)
        local iface = client_create_interface(module, interface) or error("invalid interface", 2)
        local instance = client_find_signature(module, signature) or error("invalid signature", 2)
        local success, typeof = pcall(ffi_typeof, typestring)
        if not success then
            error(typeof, 2)
        end
        local fnptr = ffi_cast(typeof, instance) or error("invalid typecast", 2)
        return function(...)
            return fnptr(iface, ...)
        end
    end,

    int_ptr = ffi_typeof("int[1]"),
    char_buffer = ffi_typeof("char[?]"),

    table_diff = function(t1, t2)
        local diff = {}
        for k, v in pairs(t1) do
            if t2[k] ~= v then
                diff[k] = v
            end
        end
        for k, v in pairs(t2) do
            if t1[k] ~= v then
                diff[k] = v
            end
        end
        return next(diff) ~= nil
    end,

    reset_bloom = function(tone_map_controller)
        if vars.effects.bloom_default == -1 then
            entity_set_prop(tone_map_controller, "m_bUseCustomBloomScale", 0)
            entity_set_prop(tone_map_controller, "m_flCustomBloomScale", 0)
        elseif vars.effects.bloom_default and vars.effects.bloom_default ~= -1 then
            entity_set_prop(tone_map_controller, "m_bUseCustomBloomScale", 1)
            entity_set_prop(tone_map_controller, "m_flCustomBloomScale", vars.effects.bloom_default)
        end
    end,

    reset_exposure = function(tone_map_controller)
        -- Min exposure
        if vars.effects.exposure_min_default == -1 then
            entity_set_prop(tone_map_controller, "m_bUseCustomAutoExposureMin", 0)
            entity_set_prop(tone_map_controller, "m_flCustomAutoExposureMin", 0)
        elseif vars.effects.exposure_min_default and vars.effects.exposure_min_default ~= -1 then
            entity_set_prop(tone_map_controller, "m_bUseCustomAutoExposureMin", 1)
            entity_set_prop(tone_map_controller, "m_flCustomAutoExposureMin", vars.effects.exposure_min_default)
        end
        
        -- Max exposure
        if vars.effects.exposure_max_default == -1 then
            entity_set_prop(tone_map_controller, "m_bUseCustomAutoExposureMax", 0)
            entity_set_prop(tone_map_controller, "m_flCustomAutoExposureMax", 0)
        elseif vars.effects.exposure_max_default and vars.effects.exposure_max_default ~= -1 then
            entity_set_prop(tone_map_controller, "m_bUseCustomAutoExposureMax", 1)
            entity_set_prop(tone_map_controller, "m_flCustomAutoExposureMax", vars.effects.exposure_max_default)
        end
    end,

    get_all_client_classes = function()
        local interface_ptr = ffi_typeof('void***')
        local raw_client = client_create_interface("client.dll", "VClient018")
        if not raw_client then 
            return nil 
        end
        
        local client_interface = ffi_cast(interface_ptr, raw_client)
        local client_vtbl = client_interface[0]
        local get_all_classes = ffi_cast("ClientClass*(__thiscall*)(void*)", client_vtbl[8])
        return get_all_classes(client_interface)
    end,

    get_client_networkable = function(entindex)
        local interface_ptr = ffi_typeof('void***')
        local raw_entity_list = client_create_interface("client.dll", "VClientEntityList003")
        if not raw_entity_list then 
            return nil 
        end
        
        local entity_list = ffi_cast(interface_ptr, raw_entity_list)
        local entity_list_vtbl = entity_list[0]
        local get_networkable = ffi_cast("void*(__thiscall*)(void*, int)", entity_list_vtbl[0])
        return get_networkable(entity_list, entindex)
    end,

    find_precipitation_class = nil,

    update_precipitation_bounds = nil,

    create_precipitation = nil,

    release_precipitation = nil,

    restore_sleeves = function()
        if #vars.sleeves.materials == 0 then
            return
        end

        for i, mat in ipairs(vars.sleeves.materials) do
            local orig_alpha = vars.sleeves.original_alpha[i]
            if orig_alpha then
                pcall(function()
                    mat:alpha_modulate(orig_alpha)
                end)
            end
        end
    end,

    find_sleeve_materials = function()
        if #vars.sleeves.materials > 0 then
            return vars.sleeves.materials
        end

        local success, all_materials = pcall(materialsystem_find_materials, "models/weapons/v_models/arms")
        if success and all_materials and #all_materials > 0 then
            local sleeve_materials = {}

            for i, mat in ipairs(all_materials) do
                local mat_name = mat:get_name()
                if mat_name and string_find(string_lower(mat_name), "sleeve") then
                    table_insert(sleeve_materials, mat)

                    if not vars.sleeves.original_alpha[#sleeve_materials] then
                        vars.sleeves.original_alpha[#sleeve_materials] = 255
                    end
                end
            end

            vars.sleeves.materials = sleeve_materials
        else
            vars.sleeves.materials = {}
        end

        return vars.sleeves.materials
    end,

    apply_sleeves_visibility = nil,
}


utils.apply_sleeves_visibility = function(visible)
    local materials = utils.find_sleeve_materials()
    if #materials == 0 then
        return
    end

    local alpha = visible and 255 or 0

    for _, mat in ipairs(materials) do
        pcall(function()
            mat:alpha_modulate(alpha)
        end)
    end
end

utils.find_precipitation_class = function()
    local cur_class = utils.get_all_client_classes()
    if not cur_class then
        return nil
    end

    while cur_class and cur_class ~= ffi.NULL do
        if cur_class.class_id == 138 then -- CPrecipitation class ID
            return cur_class
        end

        if not cur_class.next or cur_class.next == ffi.NULL then
            break
        end
        cur_class = ffi_cast("ClientClass*", cur_class.next)
    end

    return nil
end

utils.update_precipitation_bounds = function()
    if not vars.weather.precipitation_entity_idx then
        return
    end

    local networkable = utils.get_client_networkable(vars.weather.precipitation_entity_idx)
    if not networkable or networkable == ffi.NULL then
        return
    end

    pcall(function()
        local networkable_vtable = ffi_cast("void***", networkable)
        local entity_ptr = ffi_cast("void***", networkable)

        local client_unknown = ffi_cast("void***(__thiscall*)(void*)", networkable_vtable[0][0])(networkable)
        if not client_unknown or client_unknown == ffi.NULL then
            return
        end

        ffi_cast("void(__thiscall*)(void*, int)", networkable_vtable[0][6])(networkable, 0)

        ffi_cast("void(__thiscall*)(void*, int)", networkable_vtable[0][4])(networkable, 0)

        local collideable = ffi_cast("void***(__thiscall*)(void*)", client_unknown[0][3])(client_unknown)
        if collideable and collideable ~= ffi.NULL then
            local mins = ffi_cast("Vector*(__thiscall*)(void*)", collideable[0][1])(collideable)
            local maxs = ffi_cast("Vector*(__thiscall*)(void*)", collideable[0][2])(collideable)

            if mins and maxs and mins ~= ffi.NULL and maxs ~= ffi.NULL then
                mins.x, mins.y, mins.z = -16384, -16384, -16384
                maxs.x, maxs.y, maxs.z = 16384, 16384, 16384
            end
        end

        if vars.weather.weather_style > 2 and vars.weather.precipitation_raw_addr and vars.weather.precipitation_raw_addr > 0 then
            local base_addr = ffi_cast("uintptr_t", vars.weather.precipitation_raw_addr)
            local bounds_offset = base_addr + 800
            local mins_ptr = ffi_cast("Vector*", bounds_offset + 8)
            local maxs_ptr = ffi_cast("Vector*", bounds_offset + 20)
            if mins_ptr and maxs_ptr then
                mins_ptr[0].x, mins_ptr[0].y, mins_ptr[0].z = -16384, -16384, -16384
                maxs_ptr[0].x, maxs_ptr[0].y, maxs_ptr[0].z = 16384, 16384, 16384
            end
        end

        ffi_cast("void(__thiscall*)(void*, int)", networkable_vtable[0][5])(networkable, 0)

        ffi_cast("void(__thiscall*)(void*, int)", networkable_vtable[0][7])(networkable, 0)
    end)
end

utils.create_precipitation = function()
    if vars.weather.created then
        return
    end

    local local_player = entity_get_local_player()
    if not local_player then
        return
    end

    if not vars.weather.precipitation_class then
        vars.weather.precipitation_class = utils.find_precipitation_class()
        if not vars.weather.precipitation_class then
            return
        end
    end

    if vars.weather.precipitation_class and vars.weather.precipitation_class.create_class then
        local raw_ptr = nil
        local success = false
        local test_indices = {2047, 2046, 2045, 1024}

        for _, idx in ipairs(test_indices) do
            success = pcall(function()
                raw_ptr = vars.weather.precipitation_class.create_class(idx, 0)
            end)

            if success and raw_ptr and raw_ptr ~= ffi.NULL then
                break
            end
        end

        if not success or not raw_ptr or raw_ptr == ffi.NULL then
            return
        end



        local created_idx = nil
        for i = 2047, 2045, -1 do
            local success_check, classname = pcall(entity_get_classname, i)
            if success_check and classname and (classname == "CPrecipitation" or classname == "env_precipitation") then
                created_idx = i
                break
            end
        end

        if created_idx then
            vars.weather.precipitation_entity_idx = created_idx

            local init_success = pcall(function()
                local networkable = utils.get_client_networkable(created_idx)
                if not networkable or networkable == ffi.NULL then
                    return
                end

                local networkable_vtable = ffi_cast("void***", networkable)
                local entity_ptr = ffi_cast("void***", networkable)

                ffi_cast("void(__thiscall*)(void*, int)", networkable_vtable[0][6])(networkable, 0)
                ffi_cast("void(__thiscall*)(void*, int)", networkable_vtable[0][4])(networkable, 0)

                entity_set_prop(created_idx, "m_nPrecipType", vars.weather.weather_style)

                local client_unknown = ffi_cast("void***(__thiscall*)(void*)", networkable_vtable[0][0])(networkable)
                if client_unknown and client_unknown ~= ffi.NULL then
                    local collideable = ffi_cast("void***(__thiscall*)(void*)", client_unknown[0][3])(client_unknown)
                    if collideable and collideable ~= ffi.NULL then
                        local mins = ffi_cast("Vector*(__thiscall*)(void*)", collideable[0][1])(collideable)
                        local maxs = ffi_cast("Vector*(__thiscall*)(void*)", collideable[0][2])(collideable)

                        if mins and maxs and mins ~= ffi.NULL and maxs ~= ffi.NULL then
                            mins.x, mins.y, mins.z = -2048, -2048, -2048
                            maxs.x, maxs.y, maxs.z = 2048, 2048, 2048
                        end
                    end
                end

                local px, py, pz = entity_get_origin(local_player)
                if px then
                    entity_set_prop(created_idx, "m_vecOrigin", px, py, pz + 500)
                else
                    entity_set_prop(created_idx, "m_vecOrigin", 0, 0, 500)
                end

                ffi_cast("void(__thiscall*)(void*, int)", networkable_vtable[0][5])(networkable, 0)
                ffi_cast("void(__thiscall*)(void*, int)", networkable_vtable[0][7])(networkable, 0)
            end)

            if init_success then
                vars.weather.created = true
            else
                vars.weather.precipitation_entity_idx = nil
            end
        end
    end
end

utils.release_precipitation = function()
    if vars.weather.precipitation_entity_idx then
        local success = pcall(function()
            local classname = entity_get_classname(vars.weather.precipitation_entity_idx)
            if classname and (classname == "CPrecipitation" or classname == "env_precipitation") then
                entity_set_prop(vars.weather.precipitation_entity_idx, "m_nPrecipType", 3)

                local networkable = utils.get_client_networkable(vars.weather.precipitation_entity_idx)
                if networkable and networkable ~= ffi.NULL then
                    local networkable_vtable = ffi_cast("void***", networkable)
                    local client_unknown = ffi_cast("void***(__thiscall*)(void*)", networkable_vtable[0][0])(networkable)
                    if client_unknown and client_unknown ~= ffi.NULL then
                        local client_thinkable = ffi_cast("void***(__thiscall*)(void*)", client_unknown[0][8])(client_unknown)
                        if client_thinkable and client_thinkable ~= ffi.NULL then
                            ffi_cast("void(__thiscall*)(void*)", client_thinkable[0][4])(client_thinkable)
                        end
                    end
                end

                entity_set_prop(vars.weather.precipitation_entity_idx, "m_bDormant", 1)
                entity_set_prop(vars.weather.precipitation_entity_idx, "m_nRenderMode", 10)
                entity_set_prop(vars.weather.precipitation_entity_idx, "m_clrRender", 0)
                entity_set_prop(vars.weather.precipitation_entity_idx, "m_vecOrigin", 999999, 999999, 999999)
            end
        end)
    end

    vars.weather.created = false
    vars.weather.precipitation_entity_idx = nil
    vars.weather.precipitation_raw = nil
    vars.weather.precipitation_raw_addr = nil
end

utils.find_first        = utils.bind_signature("filesystem_stdio.dll", "VFileSystem017", "\x55\x8B\xEC\x6A\x00\xFF\x75\x10\xFF\x75\x0C\xFF\x75\x08\xE8\xCC\xCC\xCC\xCC\x5D", "const char*(__thiscall*)(void*, const char*, const char*, int*)")
utils.find_next         = utils.bind_signature("filesystem_stdio.dll", "VFileSystem017", "\x55\x8B\xEC\x83\xEC\x0C\x53\x8B\xD9\x8B\x0D\xCC\xCC\xCC\xCC", "const char*(__thiscall*)(void*, int)")
utils.find_close        = utils.bind_signature("filesystem_stdio.dll", "VFileSystem017", "\x55\x8B\xEC\x53\x8B\x5D\x08\x85", "void(__thiscall*)(void*, int)")

utils.current_directory = utils.bind_signature("filesystem_stdio.dll", "VFileSystem017", "\x55\x8B\xEC\x56\x8B\x75\x08\x56\xFF\x75\x0C", "bool(__thiscall*)(void*, char*, int)")
utils.add_to_searchpath = utils.bind_signature("filesystem_stdio.dll", "VFileSystem017", "\x55\x8B\xEC\x81\xEC\xCC\xCC\xCC\xCC\x8B\x55\x08\x53\x56\x57", "void(__thiscall*)(void*, const char*, const char*, int)")
utils.find_is_directory = utils.bind_signature("filesystem_stdio.dll", "VFileSystem017", "\x55\x8B\xEC\x0F\xB7\x45\x08", "bool(__thiscall*)(void*, int)")



-- ============================================
-- WORLD TAB
-- ============================================
local world_tab = {
    init = function(self)
        self.fog = {
            override = tab_manager:add("World", pui.checkbox(group, "Fog override", {120, 160, 80, 255})),
            start = tab_manager:add("World", pui.slider(group, "Fog start", 0, 5000, 100)),
            end_ = tab_manager:add("World", pui.slider(group, "Fog end", 0, 10000, 1000)),
            density = tab_manager:add("World", pui.slider(group, "Fog density", 0, 100, 50)),
        }

        self.sunset = {
            override = tab_manager:add("World", pui.checkbox(group, "SunSet override")),
            azimuth = tab_manager:add("World", pui.slider(group, "Azimuth", -180, 180, 0)),
            elevation = tab_manager:add("World", pui.slider(group, "Elevation", -180, 180, 0)),
        }
        
        self.skybox = {
            override = tab_manager:add("World", pui.checkbox(group, "SkyBox override",  {255, 255, 255, 255})),
            list = tab_manager:add("World", pui.combobox(group, "SkyBox", vars.skybox.skyboxes)),
            remove_3d_sky = tab_manager:add("World", pui.checkbox(group, "Remove 3D Sky")),
        }

        self.bloom = {
            enable = tab_manager:add("World", pui.checkbox(group, "Bloom")),
            scale = tab_manager:add("World", pui.slider(group, "Bloom scale", -1, 500, -1, 0.01)),
        }
        self.exposure = {
            enable = tab_manager:add("World", pui.checkbox(group, "Exposure")),
            value = tab_manager:add("World", pui.slider(group, "Auto Exposure", -1, 1000, -1, 0.001)),
        }
        self.model_ambient = {
            enable = tab_manager:add("World", pui.checkbox(group, "Model ambient")),
            brightness = tab_manager:add("World", pui.slider(group, "Model brightness", 0, 1000, 0, 0.05))
        }
        
        self.weather = {
            enable = tab_manager:add("World", pui.checkbox(group, "Weather")),
            style = tab_manager:add("World", pui.combobox(group, "Weather type", {"Rain 1", "Rain 2"})),
            radius = tab_manager:add("World", pui.slider(group, "Weather Radius", 0, 1500, 600)),
            width = tab_manager:add("World", pui.slider(group, "Weather Width", 0, 100, 50)),
            modulate = tab_manager:add("World", pui.slider(group, "Weather Modulate", 0, 100, 50)),

            snow_particles = tab_manager:add("World", pui.slider(group, "Rain 2 Particles", 100, 1000, 300)),
            snow_fall_speed = tab_manager:add("World", pui.slider(group, "Rain 2 Fall Speed", 0.1, 10, 1.5)),
            snow_wind_scale = tab_manager:add("World", pui.slider(group, "Rain 2 Wind Scale", 0, 100, 35)),
            wind_enable = tab_manager:add("World", pui.checkbox(group, "Custom Wind")),

            wind_direction = tab_manager:add("World", pui.slider(group, "Wind Direction", 0, 360, 0)),
            wind_speed = tab_manager:add("World", pui.slider(group, "Wind Speed", 0, 500, 0)),
        }

        self.bullet_tracers = {
            enable = tab_manager:add("World", pui.checkbox(group, "Bullet tracers", {255, 255, 255, 255})),
            timer = tab_manager:add("World", pui.slider(group, "Bullet tracers timer", 1, 10, 2)),
        }
        self.hitbox_on_hit = {
            enable = tab_manager:add("World", pui.checkbox(group, "Draw hitboxes on hit", {255, 255, 255, 255})),
            timer = tab_manager:add("World", pui.slider(group, "Draw hitboxes timer", 1, 10, 2)),
        }
    end,

    setup_dependencies = function(self)
        self.fog.start:depend({self.fog.override, true})
        self.fog.end_:depend({self.fog.override, true})
        self.fog.density:depend({self.fog.override, true})

        self.sunset.azimuth:depend({self.sunset.override, true})
        self.sunset.elevation:depend({self.sunset.override, true})

        self.skybox.list:depend({self.skybox.override, true})
        self.skybox.remove_3d_sky:depend({self.skybox.override, true})

        self.bloom.scale:depend({self.bloom.enable, true})

        self.exposure.value:depend({self.exposure.enable, true})

        self.model_ambient.brightness:depend({self.model_ambient.enable, true})
        
        self.weather.style:depend({self.weather.enable, true})
        self.weather.radius:depend({self.weather.enable, true})
        self.weather.width:depend({self.weather.enable, true})
        self.weather.modulate:depend({self.weather.enable, true})
        

        self.weather.snow_particles:depend({self.weather.enable, true})
        self.weather.snow_fall_speed:depend({self.weather.enable, true})
        self.weather.snow_wind_scale:depend({self.weather.enable, true})
       

        self.weather.wind_enable:depend({self.weather.enable, true})
        self.weather.wind_direction:depend({self.weather.wind_enable, true})
        self.weather.wind_speed:depend({self.weather.wind_enable, true})

        self.bullet_tracers.timer:depend({self.bullet_tracers.enable, true})
        self.hitbox_on_hit.timer:depend({self.hitbox_on_hit.enable, true})
    end,
    
    setup_tab_dependencies = function(self)

        for _, element in pairs(self.fog) do
            element:depend({tab_manager.combobox, "World"})
        end
        for _, element in pairs(self.sunset) do
            element:depend({tab_manager.combobox, "World"})
        end
        for _, element in pairs(self.skybox) do
            element:depend({tab_manager.combobox, "World"})
        end
        for _, element in pairs(self.bloom) do
            element:depend({tab_manager.combobox, "World"})
        end
        for _, element in pairs(self.exposure) do
            element:depend({tab_manager.combobox, "World"})
        end
        for _, element in pairs(self.model_ambient) do
            element:depend({tab_manager.combobox, "World"})
        end
        for _, element in pairs(self.weather) do      
            element:depend({tab_manager.combobox, "World"})
        end
        for _, element in pairs(self.bullet_tracers) do
            element:depend({tab_manager.combobox, "World"})
        end
        for _, element in pairs(self.hitbox_on_hit) do
            element:depend({tab_manager.combobox, "World"})
        end
    end,

    restore = function()
        client_set_cvar('fog_override', 0)
        client_set_cvar('cl_csm_rot_override', 0)

        if entity_get_local_player() ~= nil then 
            vars.skybox.load_name_sky(vars.skybox.old_skybox)
            local materials = materialsystem_find_materials("skybox/")
            for i = 1, #materials do
                materials[i]:color_modulate(255, 255, 255)
                materials[i]:alpha_modulate(255)
            end
        end

        local tone_map_controllers = entity_get_all("CEnvTonemapController")
        for i = 1, #tone_map_controllers do
            local controller = tone_map_controllers[i]
            
            if vars.effects.bloom_default ~= nil then
                utils.reset_bloom(controller)
            end
            
            if vars.effects.exposure_min_default ~= nil then
                utils.reset_exposure(controller)
            end
        end
    
        cvar.r_modelAmbientMin:set_raw_float(0)
        
        client_set_cvar("mat_ambient_light_r", 0)
        client_set_cvar("mat_ambient_light_g", 0)
        client_set_cvar("mat_ambient_light_b", 0)
        
        utils.release_precipitation()


        client_set_cvar("r_SnowEnable", "1")
        client_set_cvar("r_SnowParticles", "300")
        client_set_cvar("r_SnowFallSpeed", "1.5")
        client_set_cvar("r_SnowWindScale", "0.0035")
        client_set_cvar("cl_winddir", "0")
        client_set_cvar("cl_windspeed", "0")
    end,
}

-- ============================================
-- MISC TAB
-- ============================================
local misc_tab = {
    init = function(self)
        self.unlock_hidden_cvars = tab_manager:add("Misc", pui.button(group, "Unlock Hidden ConVars"))

        self.thirdperson = {
            override = tab_manager:add("Misc", pui.checkbox(group, "ThirdPerson distance")),
            distance = tab_manager:add("Misc", pui.slider(group, "Distance", 0, 300, 150)),
        }
        
        self.aspect_ratio = {
            override = tab_manager:add("Misc", pui.checkbox(group, "Aspect Ratio override")),
            value = tab_manager:add("Misc", pui.slider(group, "Aspect Ratio", 0, 200, 100, 0.01)),
        }
        self.viewmodel_in_scope = tab_manager:add("Misc", pui.checkbox(group, "Viewmodel in scope"))
        
        self.remove_sleeves = tab_manager:add("Misc", pui.checkbox(group, "Remove sleeves"))

        self.viewmodel_changer = {
            override = tab_manager:add("Misc", pui.checkbox(group, "Viewmodel changer")),
            fov = tab_manager:add("Misc", pui.slider(group, "FOV", -60, 100, vars.viewmodel.old_fov, 0.1)),
            x = tab_manager:add("Misc", pui.slider(group, "Offset X", -30, 30, vars.viewmodel.old_x, 0.1)),
            y = tab_manager:add("Misc", pui.slider(group, "Offset Y", -100, 100, vars.viewmodel.old_y,  0.1)),
            z = tab_manager:add("Misc", pui.slider(group, "Offset Z", -30, 30, vars.viewmodel.old_z, 0.1)),
       
        }

        self.autobuy = {
            enable = tab_manager:add("Misc", pui.checkbox(group, "AutoBuy")),
            disable_on_pistol = tab_manager:add("Misc", pui.checkbox(group, "Disable on pistol round")),
            primary = tab_manager:add("Misc", pui.combobox(group, "Primary weapon", vars.autobuy.primary)),
            secondary = tab_manager:add("Misc", pui.combobox(group, "Secondary weapon", vars.autobuy.secondary)),
            grenades = tab_manager:add("Misc", pui.multiselect(group, "Grenades", vars.autobuy.grenades)),
            utilities = tab_manager:add("Misc", pui.multiselect(group, "Other", vars.autobuy.utilities)),
        }


        self.custom_scope = {
            enable = tab_manager:add("Misc", pui.checkbox(group, "Custom scope lines", {0, 0, 0, 255})),
            scope_size = tab_manager:add("Misc", pui.slider(group, "Scope size", 0, 500, 190)),
            offset = tab_manager:add("Misc", pui.slider(group, "Scope offset", 0, 500, 15)),
            fade_time = tab_manager:add("Misc", pui.slider(group, "Animation speed", 3, 15, 9)),
        }

        self.console_filter = tab_manager:add("Misc", pui.checkbox(group, "Console filter"))
        
        
    end,

    setup_dependencies = function(self)
        self.thirdperson.distance:depend({self.thirdperson.override, true})
        self.aspect_ratio.value:depend({self.aspect_ratio.override, true})

        self.viewmodel_changer.fov:depend({self.viewmodel_changer.override, true})
        self.viewmodel_changer.x:depend({self.viewmodel_changer.override, true})
        self.viewmodel_changer.y:depend({self.viewmodel_changer.override, true})
        self.viewmodel_changer.z:depend({self.viewmodel_changer.override, true})

        self.autobuy.disable_on_pistol:depend({self.autobuy.enable, true})
        self.autobuy.primary:depend({self.autobuy.enable, true})
        self.autobuy.secondary:depend({self.autobuy.enable, true})
        self.autobuy.grenades:depend({self.autobuy.enable, true})
        self.autobuy.utilities:depend({self.autobuy.enable, true})

        self.custom_scope.scope_size:depend({self.custom_scope.enable, true})
        self.custom_scope.offset:depend({self.custom_scope.enable, true})
        self.custom_scope.fade_time:depend({self.custom_scope.enable, true})
        
        
    end,

    setup_tab_dependencies = function(self)

        for _, element in pairs(self.thirdperson) do
            element:depend({tab_manager.combobox, "Misc"})
        end
        for _, element in pairs(self.aspect_ratio) do
            element:depend({tab_manager.combobox, "Misc"})
        end
        for _, element in pairs(self.viewmodel_changer) do
            element:depend({tab_manager.combobox, "Misc"})
        end

        for _, element in pairs(self.autobuy) do
            element:depend({tab_manager.combobox, "Misc"})
        end

        self.unlock_hidden_cvars:depend({tab_manager.combobox, "Misc"})
        self.viewmodel_in_scope:depend({tab_manager.combobox, "Misc"})
        self.remove_sleeves:depend({tab_manager.combobox, "Misc"})
        self.console_filter:depend({tab_manager.combobox, "Misc"})

        for _, element in pairs(self.custom_scope) do
            element:depend({tab_manager.combobox, "Misc"})
        end

    end,

    restore = function()
        client_set_cvar('cam_idealdist', vars.thirdperson.old_distance)
        client_set_cvar('fov_cs_debug', 0)
        client_set_cvar('r_aspectratio', 0)


        client_set_cvar("viewmodel_fov", vars.viewmodel.old_fov)
        client_set_cvar("viewmodel_offset_x", vars.viewmodel.old_x)
        client_set_cvar("viewmodel_offset_y", vars.viewmodel.old_y)
        client_set_cvar("viewmodel_offset_z", vars.viewmodel.old_z)
        client_set_cvar("con_filter_enable", 0)
        client_set_cvar("con_filter_text", "")

        utils.restore_sleeves()

        ui_set(vars.custom_scope.scope_overlay, true)
    end
}

-- ============================================
-- CALLBACKS
-- ============================================
local callbacks = {
    fog_override = function()
        if not world_tab.fog.override:get() then
            client_set_cvar('fog_override', '0')
            return
        end
        
        client_set_cvar('fog_override', '1')
        
        local r, g, b, a = world_tab.fog.override:get_color()
        
        client_set_cvar('fog_color', string_format('%d %d %d', r, g, b))
        client_set_cvar('fog_start', world_tab.fog.start:get())
        client_set_cvar('fog_end', world_tab.fog.end_:get())
        client_set_cvar('fog_maxdensity', world_tab.fog.density:get() / 100)
    end,

    sunset_override = function()
        if not world_tab.sunset.override:get() then
            client_set_cvar('cl_csm_rot_override', 0)
            return
        end

        client_set_cvar('cl_csm_rot_override', 1)

        client_set_cvar("cl_csm_rot_x", world_tab.sunset.azimuth:get())
        client_set_cvar("cl_csm_rot_y", world_tab.sunset.elevation:get())
        
    end,

    skybox_override = function()
        if not world_tab.skybox.override then return end
        local r, g, b, a = 255, 255, 255, 255

        if entity_get_local_player() ~= nil then 
            if not world_tab.skybox.override:get() then
                vars.skybox.load_name_sky(vars.skybox.old_skybox)
                local materials = materialsystem_find_materials("skybox/")
                for i = 1, #materials do
                    materials[i]:color_modulate(r, g, b)
                    materials[i]:alpha_modulate(a)
                end
                return
            end
            
            local skybox = world_tab.skybox.list:get()
            
            vars.skybox.load_name_sky(skybox)

            local materials = materialsystem_find_materials("skybox/")

            r, g, b, a = world_tab.skybox.override:get_color()
            for i = 1, #materials do
                materials[i]:color_modulate(r, g, b)
                materials[i]:alpha_modulate(a)
            end
        end
        if world_tab.skybox.remove_3d_sky:get() then
            client_set_cvar("r_3dsky", 0)
        else
            client_set_cvar("r_3dsky", 1)
        end
    end,

    thirdperson_override = function()
        if not misc_tab.thirdperson.override:get() then
            client_set_cvar('cam_idealdist', vars.thirdperson.old_distance)
            return
        end

        local distance = misc_tab.thirdperson.distance:get()
        client_set_cvar('cam_idealdist', distance)
    end,

    aspect_ratio_override = function()
        if not misc_tab.aspect_ratio.override:get() then
            --client_set_cvar('r_aspectratio', vars.aspect_ratio.old_aspect_ratio)
            return
        end

        local value = 2 - misc_tab.aspect_ratio.value:get() / 100
        local screen_width, screen_height = client_screen_size()

        value = (screen_width * value) / screen_height

        client_set_cvar("r_aspectratio", tostring(value))
    end,

    viewmodel_in_scope = function()
        if not misc_tab.viewmodel_in_scope:get() then
            client_set_cvar('fov_cs_debug', 0)
            return
        end
        client_set_cvar('fov_cs_debug', 90)
    end,

    viewmodel_changer = function()
        if not misc_tab.viewmodel_changer.override:get() then
            client_set_cvar("viewmodel_fov", vars.viewmodel.old_fov)
            client_set_cvar("viewmodel_offset_x", vars.viewmodel.old_x)
            client_set_cvar("viewmodel_offset_y", vars.viewmodel.old_y)
            client_set_cvar("viewmodel_offset_z", vars.viewmodel.old_z)
            return
        end

        local fov = misc_tab.viewmodel_changer.fov:get()
        local x = misc_tab.viewmodel_changer.x:get() / 10
        local y = misc_tab.viewmodel_changer.y:get() / 10
        local z = misc_tab.viewmodel_changer.z:get() / 10

        client_set_cvar("viewmodel_fov", fov)
        client_set_cvar("viewmodel_offset_x", x)
        client_set_cvar("viewmodel_offset_y", y)
        client_set_cvar("viewmodel_offset_z", z)

    end,

    autobuy = function()
        
        if not misc_tab.autobuy.enable:get() then return end

        if misc_tab.autobuy.disable_on_pistol:get() then
            local game_rules = entity_get_game_rules()
            if game_rules then
                local round_number = entity_get_prop(game_rules, "m_totalRoundsPlayed")
                
                if round_number == 0 or (round_number == 15) then
                    return
                end
            end
        end

        client_exec(vars.autobuy.commands[misc_tab.autobuy.primary:get()])
        client_exec(vars.autobuy.commands[misc_tab.autobuy.secondary:get()])

        local grenades = misc_tab.autobuy.grenades:get()
        local utilities = misc_tab.autobuy.utilities:get()

        for i = 1, #grenades do
			local grenade = grenades[i]
			client_exec(vars.autobuy.commands[grenade])
		end

        for i = 1, #utilities do
			local utility = utilities[i]
			client_exec(vars.autobuy.commands[utility])
		end
    end,

    remove_sleeves = function()
        if not misc_tab.remove_sleeves:get() then
            utils.restore_sleeves()
            return
        end

        utils.apply_sleeves_visibility(false)
    end,

    draw_custom_scope_ui = function()
        if not misc_tab.custom_scope.enable:get() then
            return
        end
        ui_set(vars.custom_scope.scope_overlay, true)
    end,

    draw_custom_scope = function()
        if not misc_tab.custom_scope.enable:get() then
            ui_set(vars.custom_scope.scope_overlay, true)
            return
        end
        ui_set(vars.custom_scope.scope_overlay, false)

        local width, height = client_screen_size()
        local offset = misc_tab.custom_scope.offset:get() * height / 1080
        local initial_position = misc_tab.custom_scope.scope_size:get() * height / 1080
        local speed = misc_tab.custom_scope.fade_time:get()
        local r, g, b, a = misc_tab.custom_scope.enable:get_color()

        local me = entity_get_local_player()
        if not me then return end

        local wpn = entity_get_player_weapon(me)
        if not wpn then return end

        local scope_level = entity_get_prop(wpn, 'm_zoomLevel')
        local scoped = entity_get_prop(me, 'm_bIsScoped') == 1
        local resume_zoom = entity_get_prop(me, 'm_bResumeZoom') == 1

        local is_valid = entity_is_alive(me) and wpn ~= nil and scope_level ~= nil
        local act = is_valid and scope_level > 0 and scoped and not resume_zoom

        local FT = speed > 3 and globals_frametime() * speed or 1
        local alpha = easing.linear(vars.custom_scope.m_alpha, 0, 1, 1)

        renderer_gradient(width/2 - initial_position + 2, height / 2, initial_position - offset, 1, r, g, b, 0, r, g, b, alpha * a, true)
        renderer_gradient(width/2 + offset, height / 2, initial_position - offset, 1, r, g, b, alpha*a, r, g, b, 0, true)

        renderer_gradient(width / 2, height/2 - initial_position + 2, 1, initial_position - offset, r, g, b, 0, r, g, b, alpha * a, false)
        renderer_gradient(width / 2, height/2 + offset, 1, initial_position - offset, r, g, b, alpha*a, r, g, b, 0, false)

        vars.custom_scope.m_alpha = vars.custom_scope.clamp(vars.custom_scope.m_alpha + (act and FT or -FT), 0, 1)
    end,
    
    effects_update = function()
        if world_tab.model_ambient.enable:get() then
            local model_ambient = world_tab.model_ambient.brightness:get()
            local value = model_ambient * 0.05
            
            if cvar.r_modelAmbientMin:get_float() ~= value then
                cvar.r_modelAmbientMin:set_raw_float(value)
            end
        else
            cvar.r_modelAmbientMin:set_raw_float(0)
        end
    
        local tone_map_controllers = entity_get_all("CEnvTonemapController")
        
        for i = 1, #tone_map_controllers do
            local controller = tone_map_controllers[i]
            
            -- === BLOOM ===
            if world_tab.bloom.enable:get() then
                local bloom = world_tab.bloom.scale:get()
                
                if vars.effects.bloom_default == nil then
                    if entity_get_prop(controller, "m_bUseCustomBloomScale") == 1 then
                        vars.effects.bloom_default = entity_get_prop(controller, "m_flCustomBloomScale")
                    else
                        vars.effects.bloom_default = -1
                    end
                end
                
                entity_set_prop(controller, "m_bUseCustomBloomScale", 1)
                entity_set_prop(controller, "m_flCustomBloomScale", bloom * 0.01)
                vars.effects.bloom_prev = bloom
            else
                if vars.effects.bloom_prev ~= nil and vars.effects.bloom_default ~= nil then
                    utils.reset_bloom(controller)
                    vars.effects.bloom_prev = nil
                end
            end
            
            -- === EXPOSURE ===
            if world_tab.exposure.enable:get() then
                local exposure = world_tab.exposure.value:get()
                
                if vars.effects.exposure_min_default == nil then
                    if entity_get_prop(controller, "m_bUseCustomAutoExposureMin") == 1 then
                        vars.effects.exposure_min_default = entity_get_prop(controller, "m_flCustomAutoExposureMin")
                    else
                        vars.effects.exposure_min_default = -1
                    end
                    
                    if entity_get_prop(controller, "m_bUseCustomAutoExposureMax") == 1 then
                        vars.effects.exposure_max_default = entity_get_prop(controller, "m_flCustomAutoExposureMax")
                    else
                        vars.effects.exposure_max_default = -1
                    end
                end
                
                local exp_value = math_max(0.0000, exposure * 0.001)
                entity_set_prop(controller, "m_bUseCustomAutoExposureMin", 1)
                entity_set_prop(controller, "m_bUseCustomAutoExposureMax", 1)
                entity_set_prop(controller, "m_flCustomAutoExposureMin", exp_value)
                entity_set_prop(controller, "m_flCustomAutoExposureMax", exp_value)
                vars.effects.exposure_prev = exposure
            else
                if vars.effects.exposure_prev ~= nil and vars.effects.exposure_min_default ~= nil then
                    utils.reset_exposure(controller)
                    vars.effects.exposure_prev = nil
                end
            end
        end
    end,

    update_weather_modulate = function()
        if not world_tab or not world_tab.weather then
            return
        end

        local style = world_tab.weather.style:get()
        vars.weather.weather_style = vars.weather.precipitation_types[style] or 0


        if not world_tab.weather.enable:get() then
            utils.release_precipitation()
            vars.weather.created = false
            vars.weather.precipitation_entity_idx = nil
            vars.weather.last_player_pos = nil
        else
            if vars.weather.precipitation_entity_idx then
                pcall(function()
                    local classname = entity_get_classname(vars.weather.precipitation_entity_idx)
                    if classname and (classname == "CPrecipitation" or classname == "env_precipitation") then
                        entity_set_prop(vars.weather.precipitation_entity_idx, "m_nPrecipType", vars.weather.weather_style)
                    else
                        vars.weather.created = false
                        vars.weather.precipitation_entity_idx = nil
                        vars.weather.last_player_pos = nil
                    end
                end)
            end
        end

        client_set_cvar("r_rainradius", world_tab.weather.radius:get())
        client_set_cvar("r_rainwidth", world_tab.weather.width:get() / 100)
        client_set_cvar("r_rainalpha", world_tab.weather.modulate:get() / 100)

        local is_snow_type = vars.weather.weather_style == 1
        if is_snow_type then
            client_set_cvar("r_SnowParticles", world_tab.weather.snow_particles:get())
            client_set_cvar("r_SnowFallSpeed", world_tab.weather.snow_fall_speed:get())
            client_set_cvar("r_SnowWindScale", world_tab.weather.snow_wind_scale:get() / 10000)
            client_set_cvar("r_SnowEnable", "1")
        else
            client_set_cvar("r_SnowEnable", "0")
        end

        world_tab.weather.snow_particles:set_visible(is_snow_type and world_tab.weather.enable:get())
        world_tab.weather.snow_fall_speed:set_visible(is_snow_type and world_tab.weather.enable:get())
        world_tab.weather.snow_wind_scale:set_visible(is_snow_type and world_tab.weather.enable:get())

        world_tab.weather.wind_enable:set_visible(world_tab.weather.enable:get())
        world_tab.weather.wind_direction:set_visible(world_tab.weather.enable:get() and world_tab.weather.wind_enable:get())
        world_tab.weather.wind_speed:set_visible(world_tab.weather.enable:get() and world_tab.weather.wind_enable:get())

        if world_tab.weather.wind_enable:get() then
            client_set_cvar("cl_winddir", world_tab.weather.wind_direction:get())
            client_set_cvar("cl_windspeed", world_tab.weather.wind_speed:get())
        else
            client_set_cvar("cl_winddir", "0")
            client_set_cvar("cl_windspeed", "0")
        end
    end,

    draw_weather = function()
        if not world_tab or not world_tab.weather then
            return
        end

        local mapname = globals_mapname()
        if not mapname or mapname == "" then
            if vars.weather.created then
                utils.release_precipitation()
                vars.weather.created = false
                vars.weather.precipitation_entity_idx = nil
            end
            return
        end

        if not world_tab.weather.enable:get() then
            if vars.weather.created then
                utils.release_precipitation()
            end
            return
        end
        
        local local_player = entity_get_local_player()
        if not local_player then
            return
        end
        
        if vars.weather.precipitation_entity_idx then
            local success, classname = pcall(entity_get_classname, vars.weather.precipitation_entity_idx)
            if not success or not classname or (classname ~= "CPrecipitation" and classname ~= "env_precipitation") then
                vars.weather.created = false
                vars.weather.precipitation_entity_idx = nil
            end
        end
        
        if not vars.weather.created then
            utils.create_precipitation()
        end
        
        if vars.weather.precipitation_entity_idx then
            if vars.weather.need_bounds_update then
                utils.update_precipitation_bounds()
                vars.weather.need_bounds_update = false
            end
            
            -- pcall(function()
            --     entity_set_prop(vars.weather.precipitation_entity_idx, "m_nPrecipType", vars.weather.weather_style)

            --     local cam_x, cam_y, cam_z = client_eye_position()
            --     if cam_x then
            --         entity_set_prop(vars.weather.precipitation_entity_idx, "m_vecOrigin", cam_x, cam_y, cam_z)
            --     end
            -- end)
        end
    end,

    console_filter = function()
        if not misc_tab.console_filter:get() then
            client_set_cvar("con_filter_enable", 0)
            client_set_cvar("con_filter_text", "")
            return
        end
        client_set_cvar("con_filter_enable", 1)
        client_set_cvar("con_filter_text", "IrWL5106TZZKNFPz4P4Gl3pSN?J370f5hi373ZjPg%VOVh6lN")
    end,

    update_bullet_tracers = function(e)
        if not world_tab.bullet_tracers.enable:get() then return end
        if client_userid_to_entindex(e.userid) ~= entity_get_local_player() then return end

        local x, y, z = client_eye_position()
        vars.bullet_tracers.to_draw[globals_tickcount()] = {x, y, z, e.x, e.y, e.z, globals_curtime() + world_tab.bullet_tracers.timer:get()}
    end,

    draw_bullet_tracers = function()
        if not world_tab.bullet_tracers.enable:get() then return end

        local current_time = globals_curtime()
        
        for tick, pos in pairs(vars.bullet_tracers.to_draw) do
            local end_time = pos[7]
            
            if current_time <= end_time then
                local time_remaining = end_time - current_time
                local total_time = world_tab.bullet_tracers.timer:get()
                local fade_time = 0.3
                
                local alpha = 255
                if time_remaining < fade_time then
                    alpha = math_floor((time_remaining / fade_time) * 255)
                end
                
                local r, g, b, original_a = world_tab.bullet_tracers.enable:get_color()
                local x1, y1 = renderer_world_to_screen(pos[1], pos[2], pos[3])
                local x2, y2 = renderer_world_to_screen(pos[4], pos[5], pos[6])
                if x1 ~= nil and x2 ~= nil and y1 ~= nil and y2 ~= nil then
                    renderer_line(x1, y1, x2, y2, r, g, b, alpha)
                end
            end
        end
    end,

    draw_hitboxes = function(e)
        if not world_tab.hitbox_on_hit.enable:get() then return end

        if e.interpolated or e.extrapolated then
            return
        end
        
        local r, g, b = world_tab.hitbox_on_hit.enable:get_color()
        local end_time = globals_curtime() + world_tab.hitbox_on_hit.timer:get()
        
        vars.hitbox_data.to_draw[e.id] = {
            target = e.target,
            tick = e.tick,
            end_time = end_time,
            r = r,
            g = g,
            b = b,
        }
    end,
    
    draw_hitboxes_overlay = function()
        if not world_tab.hitbox_on_hit.enable:get() then
            vars.hitbox_data.to_draw = {}
            return
        end
        
        local current_time = globals_curtime()
        local current_tick = globals_framecount()
        local fade_time = 0.3
        local to_remove = {}
        
        for id, data in pairs(vars.hitbox_data.to_draw) do
            if current_time > data.end_time then
                table_insert(to_remove, id)
            elseif current_time <= data.end_time then
                local time_remaining = data.end_time - current_time
                local alpha = 30
                
                if time_remaining < fade_time then
                    alpha = math_floor((time_remaining / fade_time) * 30)
                end
                
                client_draw_hitboxes(data.target, 0.1, 19, data.r, data.g, data.b, alpha, current_tick)
            end
        end
        
        for _, id in ipairs(to_remove) do
            vars.hitbox_data.to_draw[id] = nil
        end
    end,
}

local function setup_callbacks()
    -- World tab
    world_tab.fog.override:set_callback(callbacks.fog_override)
    world_tab.fog.start:set_callback(callbacks.fog_override)
    world_tab.fog.end_:set_callback(callbacks.fog_override)
    world_tab.fog.density:set_callback(callbacks.fog_override)

    if world_tab.fog.override.color then
        world_tab.fog.override.color:set_callback(callbacks.fog_override)
    end

    world_tab.sunset.override:set_callback(callbacks.sunset_override)
    world_tab.sunset.azimuth:set_callback(callbacks.sunset_override)
    world_tab.sunset.elevation:set_callback(callbacks.sunset_override)

    world_tab.skybox.override:set_callback(callbacks.skybox_override)
    world_tab.skybox.list:set_callback(callbacks.skybox_override)
    world_tab.skybox.remove_3d_sky:set_callback(callbacks.skybox_override)

    if world_tab.skybox.override.color then
        world_tab.skybox.override.color:set_callback(callbacks.skybox_override)
    end

    world_tab.bloom.enable:set_callback(callbacks.effects_update)
    world_tab.bloom.scale:set_callback(callbacks.effects_update)
    world_tab.exposure.enable:set_callback(callbacks.effects_update)
    world_tab.exposure.value:set_callback(callbacks.effects_update)
    world_tab.model_ambient.enable:set_callback(callbacks.effects_update)
    world_tab.model_ambient.brightness:set_callback(callbacks.effects_update)

    world_tab.weather.enable:set_callback(function()
        callbacks.update_weather_modulate()
        if world_tab.weather.enable:get() then
            vars.weather.need_bounds_update = true
        end
    end)
    world_tab.weather.style:set_callback(callbacks.update_weather_modulate)
    world_tab.weather.radius:set_callback(callbacks.update_weather_modulate)
    world_tab.weather.width:set_callback(callbacks.update_weather_modulate)
    world_tab.weather.modulate:set_callback(callbacks.update_weather_modulate)
    world_tab.weather.wind_enable:set_callback(callbacks.update_weather_modulate)
    world_tab.weather.wind_direction:set_callback(callbacks.update_weather_modulate)
    world_tab.weather.wind_speed:set_callback(callbacks.update_weather_modulate)

    -- Misc tab
    misc_tab.thirdperson.override:set_callback(callbacks.thirdperson_override)
    misc_tab.thirdperson.distance:set_callback(callbacks.thirdperson_override)

    misc_tab.aspect_ratio.override:set_callback(callbacks.aspect_ratio_override)
    misc_tab.aspect_ratio.value:set_callback(callbacks.aspect_ratio_override)


    misc_tab.viewmodel_in_scope:set_callback(callbacks.viewmodel_in_scope)

    misc_tab.viewmodel_changer.override:set_callback(callbacks.viewmodel_changer)
    misc_tab.viewmodel_changer.fov:set_callback(callbacks.viewmodel_changer)
    misc_tab.viewmodel_changer.x:set_callback(callbacks.viewmodel_changer)
    misc_tab.viewmodel_changer.y:set_callback(callbacks.viewmodel_changer)
    misc_tab.viewmodel_changer.z:set_callback(callbacks.viewmodel_changer)

    misc_tab.unlock_hidden_cvars:set_callback(function()
        if not vars.hidden_cvars.cvars then return end
        for i = 1, #vars.hidden_cvars.cvars do
            vars.hidden_cvars.cvars[i].flags = bit_band(vars.hidden_cvars.cvars[i].flags, bit.bnot(18))
        end
        client_log("Unlocked hidden ConVars!")
    end)
    
    misc_tab.remove_sleeves:set_callback(callbacks.remove_sleeves)
    misc_tab.console_filter:set_callback(callbacks.console_filter)

    misc_tab.custom_scope.enable:set_callback(function()
        local enabled = misc_tab.custom_scope.enable:get()

        if not enabled then
            vars.custom_scope.m_alpha = 0
            client_unset_event_callback('paint_ui', callbacks.draw_custom_scope_ui)
            client_unset_event_callback('paint', callbacks.draw_custom_scope)
            ui_set(vars.custom_scope.scope_overlay, false)
        else
            client_set_event_callback('paint_ui', callbacks.draw_custom_scope_ui)
            client_set_event_callback('paint', callbacks.draw_custom_scope)
        end
    end)
end

-- ============================================
-- SETUP
-- ============================================
local function setup()
    group:label("------\v World enhancer!\r ------")
    
    local tab_names = {"Home", "World", "Misc"}
    tab_manager.combobox = pui.combobox(group, "Tabs", tab_names)

    for _, name in ipairs(tab_names) do
        tab_manager:create(name)
    end


    local load_name_sky_address = client_find_signature("engine.dll", "\x55\x8B\xEC\x81\xEC\xCC\xCC\xCC\xCC\x56\x57\x8B\xF9\xC7\x45") or error("signature for load_name_sky is outdated")
    vars.skybox.load_name_sky = ffi_cast(ffi_typeof("void(__fastcall*)(const char*)"), load_name_sky_address)

    vars.hidden_cvars.con_command_base = ffi_cast('c_con_command_base ***', ffi_cast('uint32_t', vars.hidden_cvars.v_engine_cvar) + 0x34)[0][0]
    vars.hidden_cvars.cmd = ffi_cast('c_con_command_base *', vars.hidden_cvars.con_command_base.next)

    while ffi_cast('uint32_t', vars.hidden_cvars.cmd) ~= 0 do
        if bit_band(vars.hidden_cvars.cmd.flags, 18) then
            table_insert(vars.hidden_cvars.cvars, vars.hidden_cvars.cmd)
        end
        vars.hidden_cvars.cmd = ffi_cast('c_con_command_base *', vars.hidden_cvars.cmd.next)
    end


    world_tab:init()
    misc_tab:init()

    world_tab:setup_dependencies()
    misc_tab:setup_dependencies()

    world_tab:setup_tab_dependencies()
    misc_tab:setup_tab_dependencies()

    setup_callbacks()
    


    callbacks.skybox_override()
    callbacks.viewmodel_changer()
    
    pcall(callbacks.update_skybox_materials_from_disk)


    group:label("\a4d5368------ mioxive, 2025")
end


local success, error = pcall(setup)
if success then
    client_log("[World Enhancer] Script loaded successfully!")
else
    client.error_log("[World Enhancer] Failed to load: " .. tostring(error))
end


-- ============================================
-- EVENT CALLBACKS
-- ============================================

client_set_event_callback("player_connect_full", function(event)
    if client_userid_to_entindex(event.userid) == entity_get_local_player() then
        vars.skybox.old_skybox = client_get_cvar("sv_skyname")
        callbacks.skybox_override()
    end
    if globals_mapname() == nil then
        vars.effects.bloom_default = nil
        vars.effects.exposure_min_default = nil
        vars.effects.exposure_max_default = nil
        vars.effects.bloom_prev = nil
        vars.effects.exposure_prev = nil
    end
end)

client_set_event_callback("cs_intermission", function()
    utils.release_precipitation()
end)

client_set_event_callback("player_disconnect", function(event)
    if client_userid_to_entindex(event.userid) == entity_get_local_player() then
        utils.release_precipitation()
        vars.weather.created = false
        vars.weather.precipitation_entity_idx = nil
        vars.weather.precipitation_class = nil
    end
    vars.bullet_tracers.to_draw = {}
    vars.hitbox_data.to_draw = {}
end)

client_set_event_callback("paint", function()
    callbacks.effects_update()
    callbacks.draw_weather()
    callbacks.draw_bullet_tracers()
    callbacks.draw_custom_scope()
    callbacks.draw_hitboxes_overlay()
end)

client_set_event_callback("paint_ui", callbacks.draw_custom_scope_ui)

client_set_event_callback("level_init", function()
    callbacks.fog_override()
    callbacks.sunset_override()

    utils.release_precipitation()
    vars.weather.created = false
    vars.weather.precipitation_entity_idx = nil
    vars.weather.precipitation_raw = nil
    vars.weather.precipitation_raw_addr = nil
    vars.weather.precipitation_class = nil
    vars.weather.last_player_pos = nil

    if world_tab.weather.enable:get() then
        callbacks.update_weather_modulate()
    end

    vars.bullet_tracers.to_draw = {}
    vars.hitbox_data.to_draw = {}
end)

client_set_event_callback("round_prestart", function()
	callbacks.autobuy()
    vars.bullet_tracers.to_draw = {}
    vars.hitbox_data.to_draw = {}
    vars.weather.need_bounds_update = true
end)


client_set_event_callback("shutdown", function()
    world_tab:restore()
    misc_tab:restore()
end)

client_set_event_callback("bullet_impact", function(e)
    callbacks.update_bullet_tracers(e)
end)

client_set_event_callback("aim_fire", function(e)
    callbacks.draw_hitboxes(e)
end)

client_set_event_callback("game_newmap", function()
    if globals_mapname() == nil then
        vars.effects.bloom_default = nil
        vars.effects.exposure_min_default = nil
        vars.effects.exposure_max_default = nil
        vars.effects.bloom_prev = nil
        vars.effects.exposure_prev = nil
    end
    callbacks.fog_override()
    callbacks.sunset_override()
    utils.release_precipitation()
    vars.weather.created = false
    vars.weather.precipitation_entity_idx = nil
    vars.weather.precipitation_raw = nil
    vars.weather.precipitation_raw_addr = nil
    vars.weather.precipitation_class = nil
    vars.weather.last_player_pos = nil

    vars.bullet_tracers.to_draw = {}
    vars.hitbox_data.to_draw = {}
end)-- dumped from hrisito forums by <youtube.com/@subtick> ~ rip hrisito 2025-2026
