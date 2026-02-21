-- Title: Aesthetic
-- Script ID: 133
-- Source: page_133.html
----------------------------------------

local ffi = require 'ffi'
local vector = require 'vector'

local inspect = require 'gamesense/inspect'

local base64 = require 'gamesense/base64'
local clipboard = require 'gamesense/clipboard'

local chat = require 'gamesense/chat'
local localize = require 'gamesense/localize'

local images = require 'gamesense/images'
local c_entity = require 'gamesense/entity'
local csgo_weapons = require 'gamesense/csgo_weapons'

local function DUMMY(...)
    return ...
end

local function contains(list, value)
    for i = 1, #list do
        if list[i] == value then
            return i
        end
    end

    return nil
end

local function round(x)
    return math.floor(x + 0.5)
end

local script do
    script = { }

    script.name = 'Aesthetic'
    script.build = 'gs'

    script.user = _USER_NAME or 'nicpronichev'
end

local color do
    color = ffi.typeof [[
        struct {
            unsigned char r;
            unsigned char g;
            unsigned char b;
            unsigned char a;
        }
    ]]

    local M = { } do
        M.__index = M

        function M:__tostring()
            return string.format(
                '%i, %i, %i, %i',
                self:unpack()
            )
        end

        function M.lerp(a, b, t)
            return color(
                a.r + t * (b.r - a.r),
                a.g + t * (b.g - a.g),
                a.b + t * (b.b - a.b),
                a.a + t * (b.a - a.a)
            )
        end

        function M:unpack()
            return self.r, self.g, self.b, self.a
        end

        function M:clone()
            return color(self:unpack())
        end

        function M:to_hex()
            return string.format(
                '%02x%02x%02x%02x',
                self:unpack()
            )
        end

        function M:hsv(h, s, v)
            local r, g, b

            h = (h % 1.0) * 360
            s = math.max(0, math.min(s, 1))
            v = math.max(0, math.min(v, 1))

            local c = v * s
            local x = c * (1 - math.abs((h / 60) % 2 - 1))
            local m = v - c

            if h < 60 then
                r, g, b = c, x, 0
            elseif h < 120 then
                r, g, b = x, c, 0
            elseif h < 180 then
                r, g, b = 0, c, x
            elseif h < 240 then
                r, g, b = 0, x, c
            elseif h < 300 then
                r, g, b = x, 0, c
            else
                r, g, b = c, 0, x
            end

            self.r = (r + m) * 255
            self.g = (g + m) * 255
            self.b = (b + m) * 255
            self.a = 255

            return self
        end
    end

    ffi.metatype(color, M)
end

local motion do
    motion = { }

    local function linear(t, b, c, d)
        return c * t / d + b
    end

    local function get_deltatime()
        return globals.frametime()
    end

    local function solve(easing_fn, prev, new, clock, duration)
        if clock <= 0 then return new end
        if clock >= duration then return new end

        prev = easing_fn(clock, prev, new - prev, duration)

        if type(prev) == 'number' then
            if math.abs(new - prev) < 0.001 then
                return new
            end

            local remainder = prev % 1.0

            if remainder < 0.001 then
                return math.floor(prev)
            end

            if remainder > 0.999 then
                return math.ceil(prev)
            end
        end

        return prev
    end

    function motion.interp(a, b, t, easing_fn)
        easing_fn = easing_fn or linear

        if type(b) == 'boolean' then
            b = b and 1 or 0
        end

        return solve(easing_fn, a, b, get_deltatime(), t)
    end
end

local utils do
    utils = { }

    function utils.clamp(x, min, max)
        return math.max(min, math.min(x, max))
    end

    function utils.lerp(a, b, t)
        return a + t * (b - a)
    end

    function utils.inverse_lerp(a, b, x)
        return (x - a) / (b - a)
    end

    function utils.map(x, in_min, in_max, out_min, out_max, should_clamp)
        if should_clamp then
            x = utils.clamp(x, in_min, in_max)
        end

        local rel = utils.inverse_lerp(in_min, in_max, x)
        local value = utils.lerp(out_min, out_max, rel)

        return value
    end

    function utils.normalize(x, min, max)
        local d = max - min

        while x < min do
            x = x + d
        end

        while x > max do
            x = x - d
        end

        return x
    end

    function utils.trim(str)
        return str
    end

    function utils.from_hex(hex)
        hex = string.gsub(hex, '#', '')

        local r = tonumber(string.sub(hex, 1, 2), 16)
        local g = tonumber(string.sub(hex, 3, 4), 16)
        local b = tonumber(string.sub(hex, 5, 6), 16)
        local a = tonumber(string.sub(hex, 7, 8), 16)

        return r, g, b, a or 255
    end

    function utils.to_hex(r, g, b, a)
        return string.format('%02x%02x%02x%02x', r, g, b, a)
    end

    function utils.event_callback(event_name, callback, value)
        local fn = value == false
            and client.unset_event_callback
            or client.set_event_callback

        fn(event_name, callback)
    end

    function utils.get_eye_position(ent)
        local origin_x, origin_y, origin_z = entity.get_origin(ent)
        local offset_x, offset_y, offset_z = entity.get_prop(ent, 'm_vecViewOffset')

        if origin_x == nil or offset_x == nil then
            return nil
        end

        local eye_pos_x = origin_x + offset_x
        local eye_pos_y = origin_y + offset_y
        local eye_pos_z = origin_z + offset_z

        return eye_pos_x, eye_pos_y, eye_pos_z
    end

    function utils.get_player_weapons(ent)
        local weapons = { }

        for i = 0, 63 do
            local weapon = entity.get_prop(
                ent, 'm_hMyWeapons', i
            )

            if weapon == nil then
                goto continue
            end

            table.insert(weapons, weapon)
            ::continue::
        end

        return weapons
    end

    function utils.get_player_kd(player)
        if player == nil then
            return nil
        end

        local player_resource = entity.get_player_resource()

        if player_resource == nil then
            return nil
        end

        local kills = entity.get_prop(player_resource, 'm_iKills', player)
        local deaths = entity.get_prop(player_resource, 'm_iDeaths', player)

        if deaths > 0 then
            return kills / deaths
        end

        return kills
    end

    function utils.closest_ray_point(a, b, p, should_clamp)
        local ray_delta = p - a
        local line_delta = b - a

        local lengthsqr = line_delta.x * line_delta.x + line_delta.y * line_delta.y
        local dot_product = ray_delta.x * line_delta.x + ray_delta.y * line_delta.y

        local t = dot_product / lengthsqr

        if should_clamp then
            if t <= 0.0 then
                return a
            end

            if t >= 1.0 then
                return b
            end
        end

        return a + t * line_delta
    end

    function utils.extrapolate(pos, vel, ticks)
        return pos + vel * (ticks * globals.tickinterval())
    end

    function utils.random_int(min, max)
        if min > max then
            min, max = max, min
        end

        return client.random_int(min, max)
    end

    function utils.random_float(min, max)
        if min > max then
            min, max = max, min
        end

        return client.random_float(min, max)
    end

    function utils.find_signature(module_name, pattern, offset)
        local match = client.find_signature(module_name, pattern)

        if match == nil then
            return nil
        end

        if offset ~= nil then
            local address = ffi.cast('char*', match)
            address = address + offset

            return address
        end

        return match
    end
end

local globalvars do
    globalvars = { }

    local globalvars_t = ffi.typeof [[
        struct {
            float   realtime;                     // 0x0000
            int     framecount;                   // 0x0004
            float   absoluteframetime;            // 0x0008
            float   absoluteframestarttimestddev; // 0x000C
            float   curtime;                      // 0x0010
            float   frametime;                    // 0x0014
            int     max_clients;                  // 0x0018
            int     tickcount;                    // 0x001C
            float   interval_per_tick;            // 0x0020
            float   interpolation_amount;         // 0x0024
            int     simTicksThisFrame;            // 0x0028
            int     network_protocol;             // 0x002C
            void*   pSaveData;                    // 0x0030
            bool    m_bClient;                    // 0x0031
            bool    m_bRemoteClient;              // 0x0032
        } ***
    ]]

    local globalvars_ptr = utils.find_signature(
        'client.dll', '\xA1\xCC\xCC\xCC\xCC\x5E\x8B\x40\x10', 0x1
    )

    if globalvars_ptr == nil then
        error 'Unable to find CGlobalVarsBase'
    end

    globalvars = ffi.cast(globalvars_t, globalvars_ptr)[0][0]
end

local ilocalize do
    ilocalize = { }

    local ConvertAnsiToUnicode = vtable_bind(
        'localize.dll', 'Localize_001', 15, 'int(__thiscall*)(void*, const char *ansi, wchar_t *unicode, int buffer_size)'
    )

    function ilocalize.ansi_to_unicode(ansi, unicode, buffer_size)
        return ConvertAnsiToUnicode(ansi, unicode, buffer_size)
    end
end

local ifilesystem do
    ifilesystem = { }

    local AddSearchPath = vtable_bind('filesystem_stdio.dll', 'VFileSystem017', 11, ffi.typeof [[
        void(__thiscall*)(void*, const char *pPath, const char *pathID, int addType)
    ]])

    local RemoveSearchPath = vtable_bind('filesystem_stdio.dll', 'VFileSystem017', 12, ffi.typeof [[
        bool(__thiscall*)(void*, const char *pPath, const char *pathID)
    ]])

    local CurrentDirectory = vtable_bind('filesystem_stdio.dll', 'VFileSystem017', 40, ffi.typeof [[
        bool(__thiscall*)(void*, char* pDirectory, int maxlen)
    ]])

    local FindFirst = vtable_bind('filesystem_stdio.dll', 'VFileSystem017', 32, ffi.typeof [[
        const char*(__thiscall*)(void*, const char *pWildCard, int *pHandle)
    ]])

    local FindNext = vtable_bind('filesystem_stdio.dll', 'VFileSystem017', 33, ffi.typeof [[
        const char*(__thiscall*)(void*, int handle)
    ]])

    local FindIsDirectory = vtable_bind('filesystem_stdio.dll', 'VFileSystem017', 34, ffi.typeof [[
        bool(__thiscall*)(void*, int handle)
    ]])

    local FindClose = vtable_bind('filesystem_stdio.dll', 'VFileSystem017', 35, ffi.typeof [[
        void(__thiscall*)(void*, int handle)
    ]])

    local FindFirstEx = vtable_bind('filesystem_stdio.dll', 'VFileSystem017', 36, ffi.typeof [[
        const char*(__thiscall*)(void*, const char *pWildCard, const char *pathID, int *pHandle)
    ]])

    function ifilesystem.add_search_path(path, path_id, add_type)
        AddSearchPath(path, path_id, add_type)
    end

    function ifilesystem.remove_search_path(path, path_id)
        return RemoveSearchPath(path, path_id)
    end

    function ifilesystem.current_directory(buffer, maxlen)
        return CurrentDirectory(buffer, maxlen)
    end

    function ifilesystem.find_first(wild_card, handle)
        return FindFirst(wild_card, handle)
    end

    function ifilesystem.find_next(handle)
        return FindNext(handle)
    end

    function ifilesystem.find_is_directory(handle)
        return FindIsDirectory(handle)
    end

    function ifilesystem.find_close(handle)
        FindClose(handle)
    end

    function ifilesystem.find_first_ex(wild_card, path_id, handle)
        return FindFirstEx(wild_card, path_id, handle)
    end
end

local surface do
    surface = { }

    local wide = ffi.new 'int[1]'
    local tall = ffi.new 'int[1]'

    local SetColor = vtable_bind('vguimatsurface.dll', 'VGUI_Surface031', 15, 'void(__thiscall*)(void* thisptr, int r, int g, int b, int a)')

    local SetTextFont = vtable_bind('vguimatsurface.dll', 'VGUI_Surface031', 23, 'void(__thiscall*)(void*, unsigned int font_id)')
    local SetTextColor = vtable_bind('vguimatsurface.dll', 'VGUI_Surface031', 25, 'void(__thiscall*)(void*, int r, int g, int b, int a)')
    local SetTextPos = vtable_bind('vguimatsurface.dll', 'VGUI_Surface031', 26, 'void(__thiscall*)(void*, int x, int y)')
    local DrawPrintText = vtable_bind('vguimatsurface.dll', 'VGUI_Surface031', 28, 'void(__thiscall*)(void*, const wchar_t *text, int maxlen, int draw_type)')

    local GetFontTall = vtable_bind('vguimatsurface.dll', 'VGUI_Surface031', 74, 'int(__thiscall*)(void*, unsigned int font)')
    local GetTextSize = vtable_bind('vguimatsurface.dll', 'VGUI_Surface031', 79, 'void(__thiscall*)(void*, unsigned int font, const wchar_t *text, int &wide, int &tall)')

    local DrawFilledRectFade = vtable_bind('vguimatsurface.dll', 'VGUI_Surface031', 123, 'void(__thiscall*)(void*, int x0, int y0, int x1, int y1, unsigned int alpha0, unsigned int alpha1, bool bHorizontal)')

    function surface.text_tall(font)
        return GetFontTall(font)
    end

    function surface.measure_text(font, text)
        local buffer = ffi.new 'wchar_t[2048]'

        ilocalize.ansi_to_unicode(text, buffer, 2048)
        GetTextSize(font, buffer, wide, tall)

        return wide[0], tall[0]
    end

    function surface.text(font, x, y, r, g, b, a, text)
        local len = #text

        if len <= 0 then
            return
        end

        local buffer = ffi.new 'wchar_t[2048]'

        ilocalize.ansi_to_unicode(text, buffer, 2048)

        SetTextFont(font)

        SetTextPos(x, y)
        SetTextColor(r, g, b, a)

        DrawPrintText(buffer, len, 0)
    end

    function surface.fade(x, y, w, h, r0, g0, b0, a0, r1, g1, b1, a1, horizontal)
        SetColor(r0, g0, b0, a0)
        DrawFilledRectFade(x, y, x + w, y + h, 255, 0, horizontal)

        SetColor(r1, g1, b1, a1)
        DrawFilledRectFade(x, y, x + w, y + h, 0, 255, horizontal)
    end
end

local software do
    software = { }

    software.ragebot = {
        weapon_type = ui.reference(
            'Rage', 'Weapon type', 'Weapon type'
        ),

        aimbot = {
            enabled = {
                ui.reference('Rage', 'Aimbot', 'Enabled')
            },

            double_tap = {
                ui.reference('Rage', 'Aimbot', 'Double tap')
            },

            force_body_aim = ui.reference(
                'Rage', 'Aimbot', 'Force body aim'
            ),

            minimum_hit_chance = ui.reference(
                'Rage', 'Aimbot', 'Minimum hit chance'
            ),

            minimum_damage = ui.reference(
                'Rage', 'Aimbot', 'Minimum damage'
            ),

            minimum_damage_override = {
                ui.reference('Rage', 'Aimbot', 'Minimum damage override')
            }
        },

        other = {
            quick_peek_assist = {
                ui.reference('Rage', 'Other', 'Quick peek assist')
            },

            duck_peek_assist = ui.reference(
                'Rage', 'Other', 'Duck peek assist'
            )
        }
    }

    software.antiaimbot = {
        angles = {
            enabled = ui.reference(
                'AA', 'Anti-aimbot angles', 'Enabled'
            ),

            pitch = {
                ui.reference('AA', 'Anti-aimbot angles', 'Pitch')
            },

            yaw_base = ui.reference(
                'AA', 'Anti-aimbot angles', 'Yaw base'
            ),

            yaw = {
                ui.reference('AA', 'Anti-aimbot angles', 'Yaw')
            },

            yaw_jitter = {
                ui.reference('AA', 'Anti-aimbot angles', 'Yaw jitter')
            },

            body_yaw = {
                ui.reference('AA', 'Anti-aimbot angles', 'Body yaw')
            },

            freestanding_body_yaw = ui.reference(
                'AA', 'Anti-aimbot angles', 'Freestanding body yaw'
            ),

            edge_yaw = ui.reference(
                'AA', 'Anti-aimbot angles', 'Edge yaw'
            ),

            freestanding = {
                ui.reference('AA', 'Anti-aimbot angles', 'Freestanding')
            },

            roll = ui.reference(
                'AA', 'Anti-aimbot angles', 'Roll'
            )
        },

        fake_lag = {
            enabled = {
                ui.reference('AA', 'Fake lag', 'Enabled')
            },

            amount = ui.reference(
                'AA', 'Fake lag', 'Amount'
            ),

            variance = ui.reference(
                'AA', 'Fake lag', 'Variance'
            ),

            limit = ui.reference(
                'AA', 'Fake lag', 'Limit'
            ),
        },

        other = {
            slow_motion = {
                ui.reference('AA', 'Other', 'Slow motion')
            },

            on_shot_antiaim = {
                ui.reference('AA', 'Other', 'On shot anti-aim')
            },

            leg_movement = ui.reference(
                'AA', 'Other', 'Leg movement'
            ),

            fake_peek = {
                ui.reference('AA', 'Other', 'Fake peek')
            }
        }
    }

    software.visuals = {
        effects = {
            remove_scope_overlay = ui.reference(
                'Visuals', 'Effects', 'Remove scope overlay'
            )
        }
    }

    software.misc = {
        miscellaneous = {
            draw_console_output = ui.reference(
                'Misc', 'Miscellaneous', 'Draw console output'
            )
        },

        settings = {
            menu_color = ui.reference(
                'Misc', 'Settings', 'Menu color'
            ),

            dpi_scale = ui.reference(
                'Misc', 'Settings', 'DPI scale'
            )
        }
    }

    function software.get_dpi()
        local matched = string.match(
            ui.get(software.misc.settings.dpi_scale), '(%d+)%%'
        )

        if not matched then
            return 0
        end

        return matched * 0.01
    end

    function software.get_color(to_hex)
        if to_hex then
            return utils.to_hex(ui.get(software.misc.settings.menu_color))
        end

        return ui.get(software.misc.settings.menu_color)
    end

    function software.get_override_damage()
        return ui.get(software.ragebot.aimbot.minimum_damage_override[3])
    end

    function software.get_minimum_damage()
        return ui.get(software.ragebot.aimbot.minimum_damage)
    end

    function software.is_freestanding()
        return ui.get(software.antiaimbot.angles.freestanding[1])
            and ui.get(software.antiaimbot.angles.freestanding[2])
    end

    function software.is_slow_motion()
        return ui.get(software.antiaimbot.other.slow_motion[1])
            and ui.get(software.antiaimbot.other.slow_motion[2])
    end

    function software.is_double_tap_active()
        return ui.get(software.ragebot.aimbot.double_tap[1])
            and ui.get(software.ragebot.aimbot.double_tap[2])
    end

    function software.is_override_minimum_damage()
        return ui.get(software.ragebot.aimbot.minimum_damage_override[1])
            and ui.get(software.ragebot.aimbot.minimum_damage_override[2])
    end

    function software.is_on_shot_antiaim_active()
        return ui.get(software.antiaimbot.other.on_shot_antiaim[1])
            and ui.get(software.antiaimbot.other.on_shot_antiaim[2])
    end

    function software.is_duck_peek_assist()
        return ui.get(software.ragebot.other.duck_peek_assist)
    end

    function software.is_quick_peek_assist()
        return ui.get(software.ragebot.other.quick_peek_assist[1])
            and ui.get(software.ragebot.other.quick_peek_assist[2])
    end
end

local event_system do
    event_system = { }

    local function find(list, value)
        for i = 1, #list do
            if value == list[i] then
                return i
            end
        end

        return nil
    end

    local EventList = { } do
        EventList.__index = EventList

        function EventList:new()
            return setmetatable({
                list = { },
                count = 0
            }, self)
        end

        function EventList:__len()
            return self.count
        end

        function EventList:set(callback)
            if not find(self.list, callback) then
                self.count = self.count + 1
                table.insert(self.list, callback)
            end

            return self
        end

        function EventList:unset(callback)
            local index = find(self.list, callback)

            if index ~= nil then
                self.count = self.count - 1
                table.remove(self.list, index)
            end

            return self
        end

        function EventList:fire(...)
            local list = self.list

            for i = 1, #list do
                list[i](...)
            end

            return self
        end
    end

    local EventBus = { } do
        local function __index(list, k)
            local value = rawget(list, k)

            if value == nil then
                value = EventList:new()
                rawset(list, k, value)
            end

            return value
        end

        function EventBus:new()
            return setmetatable({ }, {
                __index = __index
            })
        end
    end

    function event_system:new()
        return EventBus:new()
    end
end

local ui_callback do
    ui_callback = { }

    local lookup = { }

    function ui_callback.set(item, callback, force_call)
        if lookup[item] == nil then
            local list = { }

            -- wtf is that
            ui.set_callback(item, function()
                for i = 1, #list do
                    list[i](item)
                end
            end)

            lookup[item] = list
        end

        local index = contains(lookup[item])

        if index == nil then
            table.insert(lookup[item], callback)
        end

        if force_call then
            callback(item)
        end

        return item
    end

    function ui_callback.unset(item, callback)
        local list = lookup[item]

        if list == nil then
            return
        end

        local index = contains(list, callback)

        if index ~= nil then
            table.remove(list, index)
        end

        return item
    end
end

local ragebot do
    ragebot = { }

    local item_data = { }

    local ref_weapon_type = ui.reference(
        'Rage', 'Weapon type', 'Weapon type'
    )

    local e_hotkey_mode = {
        [0] = 'Always on',
        [1] = 'On hotkey',
        [2] = 'Toggle',
        [3] = 'Off hotkey'
    }

    local function get_value(item)
        local type = ui.type(item)
        local value = { ui.get(item) }

        if type == 'hotkey' then
            local mode = e_hotkey_mode[value[2]]
            local keycode = value[3] or 0

            return { mode, keycode }
        end

        return value
    end

    function ragebot.set(item, ...)
        local weapon_type = ui.get(ref_weapon_type)

        if item_data[item] == nil then
            item_data[item] = { }
        end

        local data = item_data[item]

        if data[weapon_type] == nil then
            data[weapon_type] = {
                type = weapon_type,
                value = get_value(item)
            }
        end

        ui.set(item, ...)
    end

    function ragebot.unset(item)
        local data = item_data[item]

        if data == nil then
            return
        end

        local weapon_type = ui.get(ref_weapon_type)

        for k, v in pairs(data) do
            ui.set(ref_weapon_type, v.type)
            ui.set(item, unpack(v.value))

            data[k] = nil
        end

        ui.set(ref_weapon_type, weapon_type)
        item_data[item] = nil
    end
end

local override do
    override = { }

    local item_data = { }

    local e_hotkey_mode = {
        [0] = 'Always on',
        [1] = 'On hotkey',
        [2] = 'Toggle',
        [3] = 'Off hotkey'
    }

    local function get_value(item)
        local type = ui.type(item)
        local value = { ui.get(item) }

        if type == 'hotkey' then
            local mode = e_hotkey_mode[value[2]]
            local keycode = value[3] or 0

            return { mode, keycode }
        end

        return value
    end

    function override.get(item)
        local value = item_data[item]

        if value == nil then
            return nil
        end

        return unpack(value)
    end

    function override.set(item, ...)
        if item_data[item] == nil then
            item_data[item] = get_value(item)
        end

        ui.set(item, ...)
    end

    function override.unset(item)
        local value = item_data[item]

        if value == nil then
            return
        end

        ui.set(item, unpack(value))
        item_data[item] = nil
    end
end

local logging do
    logging = { }

    local SCRIPT_NAME = script.name:lower()

    local SOUND_SUCCESS = 'ui\\beepclear.wav'
    local SOUND_FAILURE = 'resource\\warning.wav'

    local play = cvar.play

    local function display_tag(r, g, b)
        client.color_log(r, g, b, '[', SCRIPT_NAME, '] \0')
    end

    function logging.log(msg)
        display_tag(240, 240, 240)
        client.color_log(255, 255, 255, msg)
    end

    function logging.success(msg)
        display_tag(software.get_color())

        client.color_log(255, 255, 255, msg)
        play:invoke_callback(SOUND_SUCCESS)
    end

    function logging.error(msg)
        display_tag(250, 50, 75)

        client.color_log(255, 255, 255, msg)
        play:invoke_callback(SOUND_FAILURE)
    end
end

local localdb do
    localdb = { }

    local BASE64_KEY = 'BqvbCHsU5NwhxAzGKjFgytIT0oXlurekOdS8ZiPVaEnR7219Q6mM3DfLW4YpcJ+/='

    local PATH = '.'
    local FILE = PATH .. '\\aesthetic_new.dat'

    local store = { }

    local function read_file()
        return readfile(FILE)
    end

    local function write_file(str)
        writefile(FILE, str)
    end

    local function encode_data(data)
        local ok, result = pcall(
            json.stringify, data
        )

        if not ok then
            return false, result
        end

        ok, result = pcall(
            base64.encode, result, BASE64_KEY
        )

        if not ok then
            return false, result
        end

        return true, result
    end

    local function decode_data(data)
        local ok, result = pcall(
            base64.decode, data, BASE64_KEY
        )

        if not ok then
            return false, result
        end

        ok, result = pcall(
            json.parse, result
        )

        if not ok then
            return false, result
        end

        return true, result
    end

    local function write_storage(data)
        local ok, result = encode_data(data)

        if not ok then
            logging.error(
                'Unable to encode data'
            )

            return false
        end

        write_file(result)

        return true
    end

    local function parse_storage()
        local content = read_file()

        -- if can't read file, create
        -- new one with empty database
        if content == nil then
            if not write_storage { } then
                logging.log 'Unable to create db'
            end

            return { }
        end

        local ok, result = decode_data(content)

        if not ok then
            logging.error 'Unable to decode db'
            logging.log 'Trying to flush db'

            if not write_storage { } then
                logging.error 'Unable to flush db'
            end

            return { }
        end

        return result
    end

    local M = { } do
        function M:__index(key)
            return store[key]
        end

        function M:__newindex(key, value)
            store[key] = value
            write_storage(store)
        end
    end

    store = parse_storage()
    setmetatable(localdb, M)
end

local config_system do
    config_system = { }

    local BASE64_KEY = 'bjW9MagJsut5xDz36Hvl74nC8Eoy0GIUVX2NLQepckFfrBYOhRZKAwmSqidP1T+/='

	local HOTKEY_MODE = {
        [0] = 'Always on',
        [1] = 'On hotkey',
        [2] = 'Toggle',
        [3] = 'Off hotkey'
    }

    local item_list = { }
    local item_data = { }

    local function get_item_value(item)
        if item.type == 'hotkey' then
            local _, mode, key = item:get()

            return { HOTKEY_MODE[mode], key or 0 }
        end

        return { item:get() }
    end

    local function get_key_values(arr)
        local list = { }

        if arr ~= nil then
            for i = 1, #arr do
                list[arr[i]] = i
            end
        end

        return list
    end

    function config_system.push(tab, name, item)
        if item_data[tab] == nil then
            item_data[tab] = { }
        end

        local data = {
            tab = tab,
            name = name,
            item = item
        }

        if item_data[tab][name] ~= nil then
            client.error_log(string.format(
                'config collision: [ %s, %s ]',
                tab, name
            ))
        end

        item_data[tab][name] = item
        table.insert(item_list, data)

        return item
    end

    function config_system.encode(data)
        local ok, result = pcall(
            json.stringify, data
        )

        if not ok then
            return false, result
        end

        ok, result = pcall(
            base64.encode,
            result,
            BASE64_KEY
        )

        if not ok then
            return false, result
        end

        return true, string.format(
            '[aesthetic] %s_', result
        )
    end

    function config_system.decode(str)
        local data = str:match(
            '%[aesthetic%] (.-)_'
        )

        if data == nil then
            return false, 'Invalid config'
        end

        local ok, result = pcall(
            base64.decode,
            data,
            BASE64_KEY
        )

        if not ok then
            return false, result
        end

        ok, result = pcall(
            json.parse, result
        )

        if not ok then
            return false, result
        end

        return true, result
    end

    function config_system.import(data, categories)
        if data == nil then
            return false, 'config is empty'
        end

        local keys = get_key_values(categories)

        for k, v in pairs(data) do
            if categories ~= nil and keys[k] == nil then
                goto continue
            end

            local items = item_data[k]

            if items == nil then
                goto continue
            end

            for m, n in pairs(v) do
                local item = items[m]

                if item ~= nil then
                    pcall(item.set, item, unpack(n))
                end
            end

            ::continue::
        end

        return true, nil
    end

    function config_system.export(categories)
        local list = { }

        local keys = get_key_values(categories)

        for k, v in pairs(item_data) do
            if categories ~= nil and keys[k] == nil then
                goto continue
            end

            local values = { }

            for m, n in pairs(v) do
                values[m] = get_item_value(n)
            end

            list[k] = values

            ::continue::
        end

        return list
    end
end

local menu do
    menu = { }

    local event_bus = event_system:new()

    local Item = { } do
        Item.__index = Item

        local function pack(ok, ...)
            if not ok then
                return nil
            end

            return ...
        end

        local function get_value_array(ref)
            return { pack(pcall(ui.get, ref)) }
        end

        local function get_key_values(arr)
            local list = { }

            for i = 1, #arr do
                list[arr[i]] = i
            end

            return list
        end

        local function update_item_values(item, initial)
            local value = get_value_array(item.ref)

            item.value = value

            if initial then
                item.default = value
            end

            if item.type == 'multiselect' then
                item.key_values = get_key_values(unpack(value))
            end
        end

        function Item:new(ref)
            return setmetatable({
                ref = ref,
                type = nil,

                list = { },
                value = { },
                default = { },
                key_values = { },

                callbacks = { }
            }, self)
        end

        function Item:init(...)
            local function callback()
                update_item_values(self, false)
                self:fire_events()

                event_bus.item_changed:fire(self)
            end

            self.type = ui.type(self.ref)

            local can_have_callback = (
                self.type ~= 'label' and
                self.type ~= 'unknown'
            )

            if can_have_callback then
                update_item_values(self, true)
                pcall(ui.set_callback, self.ref, callback)
            end

            if self.type == 'multiselect' or self.type == 'list' then
                self.list = select(4, ...)
            end

            if self.type == 'button' then
                local fn = select(4, ...)

                if fn ~= nil then
                    self:set_callback(fn)
                end
            end

            event_bus.item_init:fire(self)
        end

        function Item:get(key)
            local have_update_callback = (
                self.type ~= 'hotkey' and
                self.type ~= 'textbox' and
                self.type ~= 'unknown'
            )

            if not have_update_callback then
                return ui.get(self.ref)
            end

            if key ~= nil then
                return self.key_values[key] ~= nil
            end

            return unpack(self.value)
        end

        function Item:set(...)
            ui.set(self.ref, ...)
            update_item_values(self, false)
        end

        function Item:update(...)
            ui.update(self.ref, ...)
        end

        function Item:reset()
            pcall(ui.set, self.ref, unpack(self.default))
        end

        function Item:set_enabled(value)
            return ui.set_enabled(self.ref, value)
        end

        function Item:set_visible(value)
            return ui.set_visible(self.ref, value)
        end

        function Item:set_callback(callback, force_call)
            local index = contains(self.callbacks, callback)

            if index == nil then
                table.insert(self.callbacks, callback)
            end

            if force_call then
                callback(self)
            end

            return self
        end

        function Item:unset_callback(callback)
            local index = contains(self.callbacks, callback)

            if index ~= nil then
                table.remove(self.callbacks, index)
            end

            return self
        end

        function Item:fire_events()
            local list = self.callbacks

            for i = 1, #list do
                list[i](self)
            end
        end
    end

    function menu.new(fn, ...)
        local argv, argc = { }, select('#', ...)

        for i = 1, argc do
            argv[i] = select(i, ...)
        end

        if fn == ui.new_button and type(argv[4]) ~= 'function' then
            argv[4] = DUMMY
        end

        local ref = fn(unpack(argv, 1, argc))

        local item = Item:new(ref) do
            item:init(...)
        end

        return item
    end

    function menu.get_event_bus()
        return event_bus
    end
end

local menu_logic do
    menu_logic = { }

    local item_data = { }
    local item_list = { }

    local logic_events = event_system:new()

    function menu_logic.get_event_bus()
        return logic_events
    end

    function menu_logic.set(item, value)
        if item == nil or item.ref == nil then
            return
        end

        item_data[item.ref] = value
    end

    function menu_logic.force_update()
        for i = 1, #item_list do
            local item = item_list[i]

            if item == nil then
                goto continue
            end

            local ref = item.ref

            if ref == nil then
                goto continue
            end

            local value = item_data[ref]

            if value == nil then
                goto continue
            end

            item:set_visible(value)
            item_data[ref] = false

            ::continue::
        end
    end

    local menu_events = menu.get_event_bus() do
        local function on_item_init(item)
            item_data[item.ref] = false
            item:set_visible(false)

            table.insert(item_list, item)
        end

        local function on_item_changed(...)
            logic_events.update:fire(...)
            menu_logic.force_update()
        end

        menu_events.item_init:set(on_item_init)
        menu_events.item_changed:set(on_item_changed)
    end
end

local text_anims do
    text_anims = { }

    local function u8(str)
        local chars = { }
        local count = 0

        for c in string.gmatch(str, '.[\128-\191]*') do
            count = count + 1
            chars[count] = c
        end

        return chars, count
    end

    function text_anims.gradient(str, time, r1, g1, b1, a1, r2, g2, b2, a2)
        local list = { }

        local strbuf, strlen = u8(str)
        local div = 1 / (strlen - 1)

        local delta_r = r2 - r1
        local delta_g = g2 - g1
        local delta_b = b2 - b1
        local delta_a = a2 - a1

        for i = 1, strlen do
            local char = strbuf[i]

            local t = time do
                t = t % 2

                if t > 1 then
                    t = 2 - t
                end
            end

            local r = r1 + t * delta_r
            local g = g1 + t * delta_g
            local b = b1 + t * delta_b
            local a = a1 + t * delta_a

            local hex = utils.to_hex(r, g, b, a)

            table.insert(list, '\a')
            table.insert(list, hex)
            table.insert(list, char)

            time = time + div
        end

        return table.concat(list)
    end

    function text_anims.astolfo(str, time, h, s, v, scale)
        local list = { }

        local strbuf, strlen = u8(str)
        local div = 1 / (strlen - 1)

        local col = color()

        for i = 1, strlen do
            local char = strbuf[i]

            local angle = (time - math.floor(time)) % 1.0

            if angle > 0.5 then
                angle = 1.0 - angle
            end

            col:hsv(h + angle, s, v)

            local hex = col:to_hex()

            table.insert(list, '\a')
            table.insert(list, hex)
            table.insert(list, char)

            time = time + div * scale
        end

        return table.concat(list)
    end
end

local text_fmt do
    text_fmt = { }

    local function decompose(str)
        local result, len = { }, #str

        local i, j = str:find('\a', 1)

        if i == nil then
            table.insert(result, {
                str, nil
            })
        end

        if i ~= nil and i > 1 then
            table.insert(result, {
                str:sub(1, i - 1), nil
            })
        end

        while i ~= nil do
            local hex = nil

            if str:sub(j + 1, j + 7) == 'DEFAULT' then
                j = j + 8
            else
                hex = str:sub(j + 1, j + 8)
                j = j + 9
            end

            local m, n = str:find('\a', j)

            if m == nil then
                if j <= len then
                    table.insert(result, {
                        str:sub(j), hex
                    })
                end

                break
            end

            table.insert(result, {
                str:sub(j, m - 1), hex
            })

            i, j = m, n
        end

        return result
    end

    function text_fmt.color(str)
        local list = decompose(str)
        local len = #list

        return list, len
    end
end

local const do
    const = { }

    const.teams = {
        'Terrorist',
        'Counter-Terrorist'
    }

    const.crouch_dirs = {
        'Forward',
        'Forward-Left',
        'Forward-Right',
        'Backward',
        'Backward-Left',
        'Backward-Right',
        'Left',
        'Right'
    }

    const.states = {
        'Default',
        'Standing',
        'Moving',
        'Slow Walk',
        'Air',
        'Air-Crouch',
        'Crouch',
        'Move-Crouch',
        'Legit AA',
        'Manual AA',
        'Freestanding',
        'Roll AA',
    }
end

local session do
    session = { }

    session.hitchance = {
        updated_hotkey = false,
        updated_this_tick = false
    }

    session.force_lethal = {
        updated_division = false,
        updated_this_tick = false
    }
end

local localplayer do
    localplayer = { }

    local pre_flags = 0
    local post_flags = 0

    localplayer.is_moving = false
    localplayer.is_onground = false
    localplayer.is_crouched = false

    localplayer.body_yaw = 0
    localplayer.sent_packets = 0

    localplayer.duck_amount = 0.0

    localplayer.velocity = vector()
    localplayer.velocity2d_sqr = 0

    localplayer.move_dir = vector()

    -- from @enq
    local function is_peeking(player)
        local should, vulnerable = false, false
        local velocity = vector(entity.get_prop(player, 'm_vecVelocity'))

        local eye = vector(client.eye_position())
        local peye = utils.extrapolate(eye, velocity, 14)

        local enemies = entity.get_players(true)

        for i = 1, #enemies do
            local enemy = enemies[i]

            local esp_data = entity.get_esp_data(enemy)

            if esp_data == nil then
                goto continue
            end

            if bit.band(esp_data.flags, bit.lshift(1, 11)) ~= 0 then
                vulnerable = true
                goto continue
            end

            local head = vector(entity.hitbox_position(enemy, 0))
            local phead = utils.extrapolate(head, velocity, 4)

            local entindex, damage = client.trace_bullet(player, peye.x, peye.y, peye.z, phead.x, phead.y, phead.z)

            if damage ~= nil and damage > 0 then
                should = true
                break
            end

            ::continue::
        end

        return should, vulnerable
    end

    local function get_body_yaw(player)
        local entity_info = c_entity(player)

        if entity_info == nil then
            return
        end

        local anim_state = entity_info:get_anim_state()

        if anim_state == nil then
            return
        end

        local eye_angles_y = anim_state.eye_angles_y
        local goal_feet_yaw = anim_state.goal_feet_yaw

        return utils.normalize(
            eye_angles_y - goal_feet_yaw, -180, 180
        )
    end

    local function on_pre_predict_command(cmd)
        local me = entity.get_local_player()

        if me == nil then
            return
        end

        pre_flags = entity.get_prop(me, 'm_fFlags')
    end

    local function on_predict_command(cmd)
        local me = entity.get_local_player()

        if me == nil then
            return
        end

        post_flags = entity.get_prop(me, 'm_fFlags')
    end

    local function on_setup_command(cmd)
        local me = entity.get_local_player()

        if me == nil then
            return
        end

        local peeking, vulnerable = is_peeking(me)

        local is_onground = bit.band(pre_flags, 1) ~= 0
            and bit.band(post_flags, 1) ~= 0

        local velocity = vector(entity.get_prop(me, 'm_vecVelocity'))
        local duck_amount = entity.get_prop(me, 'm_flDuckAmount')

        local velocity2d_sqr = velocity:length2dsqr()

        localplayer.is_moving = velocity2d_sqr > 5 * 5
        localplayer.is_onground = is_onground

        localplayer.is_peeking = peeking
        localplayer.is_vulnerable = vulnerable

        if cmd.chokedcommands == 0 then
            localplayer.body_yaw = get_body_yaw(me)

            localplayer.sent_packets = (
                localplayer.sent_packets + 1
            )

            localplayer.is_crouched = duck_amount > 0.5
            localplayer.duck_amount = duck_amount
        end

        localplayer.velocity = velocity
        localplayer.velocity2d_sqr = velocity2d_sqr

        localplayer.move_dir = vector(
            cmd.forwardmove, cmd.sidemove, 0
        )
    end

    client.set_event_callback('pre_predict_command', on_pre_predict_command)
    client.set_event_callback('predict_command', on_predict_command)
    client.set_event_callback('setup_command', on_setup_command)
end

local exploit do
    exploit = { }

    local BREAK_LAG_COMPENSATION_DISTANCE_SQR = 64 * 64

    local max_tickbase = 0
    local run_command_number = 0

    local data = {
        old_origin = vector(),
        old_simtime = 0.0,

        shift = false,
        breaking_lc = false,

        defensive = {
            force = false,
            left = 0,
            max = 0,
        },

        lagcompensation = {
            distance = 0.0,
            teleport = false
        }
    }

    local function update_tickbase(me)
        data.shift = globals.tickcount() > entity.get_prop(me, 'm_nTickBase')
    end

    local function update_teleport(old_origin, new_origin)
        local delta = new_origin - old_origin
        local distance = delta:lengthsqr()

        local is_teleport = distance > BREAK_LAG_COMPENSATION_DISTANCE_SQR

        data.breaking_lc = is_teleport

        data.lagcompensation.distance = distance
        data.lagcompensation.teleport = is_teleport
    end

    local function update_lagcompensation(me)
        local old_origin = data.old_origin
        local old_simtime = data.old_simtime

        local origin = vector(entity.get_origin(me))
        local simtime = toticks(entity.get_prop(me, 'm_flSimulationTime'))

        if old_simtime ~= nil then
            local delta = simtime - old_simtime

            if delta < 0 or delta > 0 and delta <= 64 then
                update_teleport(old_origin, origin)
            end
        end

        data.old_origin = origin
        data.old_simtime = simtime
    end

    local function update_defensive_tick(me)
        local tickbase = entity.get_prop(me, 'm_nTickBase')

        if math.abs(tickbase - max_tickbase) > 64 then
            -- nullify highest tickbase if the difference is too big
            max_tickbase = 0
        end

        local defensive_ticks_left = 0

        -- defensive effect can be achieved because the lag compensation is made so that
        -- it doesn't write records if the current simulation time is less than/equals highest acknowledged simulation time
        -- https://gitlab.com/KittenPopo/csgo-2018-source/-/blame/main/game/server/player_lagcompensation.cpp#L723

        if tickbase > max_tickbase then
            max_tickbase = tickbase
        elseif max_tickbase > tickbase then
            defensive_ticks_left = math.min(14, math.max(0, max_tickbase - tickbase - 1))
        end

        if defensive_ticks_left > 0 then
            data.breaking_lc = true
            data.defensive.left = defensive_ticks_left

            if data.defensive.max == 0 then
                data.defensive.max = defensive_ticks_left
            end
        else
            data.defensive.left = 0
            data.defensive.max = 0
        end
    end

    function exploit.get()
        return data
    end

    local function on_predict_command(cmd)
        local me = entity.get_local_player()

        if me == nil then
            return
        end

        if cmd.command_number == run_command_number then
            update_defensive_tick(me)
            run_command_number = nil
        end
    end

    local function on_setup_command(cmd)

    end

    local function on_run_command(e)
        local me = entity.get_local_player()

        if me == nil then
            return
        end

        update_tickbase(me)

        run_command_number = e.command_number
    end

    local function on_net_update_start()
        local me = entity.get_local_player()

        if me == nil then
            return
        end

        update_lagcompensation(me)
    end

    client.set_event_callback('predict_command', on_predict_command)
    client.set_event_callback('setup_command', on_setup_command)
    client.set_event_callback('run_command', on_run_command)

    client.set_event_callback('net_update_start', on_net_update_start)
end

local statement do
    statement = { }

    local list = { }
    local count = 0

    local function add(state)
        count = count + 1
        list[count] = state
    end

    local function clear_list()
        for i = 1, count do
            list[i] = nil
        end

        count = 0
    end

    local function update_onground()
        if not localplayer.is_onground then
            return
        end

        if localplayer.is_moving then
            add 'Moving'

            if localplayer.is_crouched then
                return
            end

            if software.is_slow_motion() then
                add 'Slow Walk'
            end

            return
        end

        add 'Standing'
    end

    local function update_crouched()
        if not localplayer.is_crouched then
            return
        end

        add 'Crouch'

        if localplayer.is_moving then
            add 'Move-Crouch'
        end
    end

    local function update_in_air()
        if localplayer.is_onground then
            return
        end

        add 'Air'

        if localplayer.is_crouched then
            add 'Air-Crouch'
        end
    end

    function statement.get()
        return list
    end

    local function on_setup_command()
        clear_list()

        update_onground()
        update_crouched()
        update_in_air()
    end

    client.set_event_callback(
        'setup_command',
        on_setup_command
    )
end

local resource do
    resource = { }

    local function new_key(str, key)
        if str:find '\n' == nil then
            str = str .. '\n'
        end

        return str .. key
    end

    local function lock_unselection(item, default_value)
        local old_value = item:get()

        if #old_value == 0 then
            if default_value == nil then
                if item.type == 'multiselect' then
                    default_value = item.list
                elseif item.type == 'list' then
                    default_value = { }

                    for i = 1, #item.list do
                        default_value[i] = i
                    end
                end
            end

            old_value = default_value
            item:set(default_value)
        end

        item:set_callback(function()
            local value = item:get()

            if #value > 0 then
                old_value = value
            else
                item:set(old_value)
            end
        end)
    end

    local function new_category_item(tab, container, name, list)
        local ref_menu_color = ui.reference(
            'Misc', 'Settings', 'Menu color'
        )

        local lookup = { } do
            local count = 0

            for i = 1, #list do
                local value = list[i]

                local title = value[1]
                local array = value[2]

                local index = count

                if title ~= nil then
                    index = index + 1
                end

                lookup[count] = index
                count = index + #array
            end
        end

        local function get_hex_color(r, g, b, a)
            return string.format(
                '%02x%02x%02x%02x',
                r, g, b, a
            )
        end

        local function get_render_list(r, g, b, a)
            local result = { }

            local hex = get_hex_color(
                r, g, b, a
            )

            for i = 1, #list do
                local value = list[i]

                local title = value[1]
                local array = value[2]

                if title ~= nil then
                    table.insert(result, string.format(
                        '\a%s%s', hex, title
                    ))
                end

                for j = 1, #array do
                    local str = array[j]

                    table.insert(result, string.format(
                        ' -  %s', str
                    ))
                end
            end

            return result
        end

        local render_list = get_render_list(
            ui.get(ref_menu_color)
        )

        local category_item = menu.new(
            ui.new_listbox,
            tab, container, name,
            render_list
        )

        local callbacks do
            local function on_menu_color(item)
                category_item:update(
                    get_render_list(
                        ui.get(item)
                    )
                )
            end

            local function on_category(item)
                local value = item:get()
                local new_value = lookup[value]

                if new_value == nil then
                    return
                end

                item:set(new_value)
            end

            ui_callback.set(
                ref_menu_color,
                on_menu_color
            )

            category_item:set_callback(
                on_category
            )
        end

        return category_item
    end

    local function new_selector_item(tab, container, name, list)
        local lookup = { } do
            for i = 1, #list do
                local value = list[i]

                local title = value[1]
                local array = value[2]

                lookup[title] = true
            end
        end

        local function get_render_list()
            local result = { }

            for i = 1, #list do
                local value = list[i]

                local title = value[1]
                local array = value[2]

                table.insert(result, title)

                for j = 1, #array do
                    local str = array[j]

                    table.insert(result, string.format(
                        ' -  %s', str
                    ))
                end
            end

            return result
        end

        local selector_item = menu.new(
            ui.new_multiselect,
            tab, container, name,
            get_render_list()
        )

        local callbacks do
            local function on_category(item)
                local value = item:get()

                local new_value = { }

                for i = 1, #value do
                    local str = value[i]

                    if not lookup[str] then
                        table.insert(new_value, str)
                    end
                end

                item:set(new_value)
            end

            selector_item:set_callback(
                on_category
            )
        end

        return selector_item
    end

    local general = { } do
        local function get_script_name_label()
            return string.format('Script: \a%s%s [%s]', software.get_color(true), script.name, script.build)
        end

        local function get_script_username_label()
            return string.format('Username: \a%s%s', software.get_color(true), script.user)
        end

        general.script_name = menu.new(
            ui.new_label, 'AA', 'Fake lag', get_script_name_label()
        )

        general.script_user = menu.new(
            ui.new_label, 'AA', 'Fake lag', get_script_username_label()
        )

        general.category = new_category_item(
            'AA', 'Fake lag', new_key('\n', 'category'), {
                {
                    nil, {
                        'Ragebot',
                        'Miscellaneous',
                        'Animations',
                        'Logging system',
                        'Automatic purchase'
                    }
                },

                {
                    'Anti-Aim', {
                        'Builder',
                        'Features',
                        'Hotkeys'
                    }
                },

                {
                    'Render', {
                        'Changers',
                        'User interface',
                        'Hit markers'
                    }
                },

                {
                    'Manager', {
                        'Configurations'
                    }
                }
            }
        )

        local callbacks do
            local ref_menu_color = ui.reference(
                'Misc', 'Settings', 'Menu color'
            )

            local function on_menu_color(item)
                general.script_name:set(get_script_name_label())
                general.script_user:set(get_script_username_label())
            end

            ui_callback.set(
                ref_menu_color,
                on_menu_color
            )
        end

        resource.general = general
    end

    local main = { } do
        local ragebot = { } do
            local force_body_conditions = { } do
                local weapon_list = {
                    'Auto Snipers',
                    'Desert Eagle',
                    'Revolver R8',
                    'Pistols',
                    'Scout',
                    'AWP'
                }

                local condition_list = {
                    'Enemy lethal',
                    'Max misses'
                }

                local scout_damage_tooltips = { } do
                    scout_damage_tooltips[0] = 'Def.'

                    for i = 101, 126 do
                        scout_damage_tooltips[i] = string.format('HP+%d', i - 100)
                    end
                end

                force_body_conditions.enabled = config_system.push(
                    'Ragebot', 'force_body_conditions.enabled', menu.new(
                        ui.new_checkbox, 'AA', 'Anti-aimbot angles', new_key('Force body condition', 'force_body_conditions')
                    )
                )

                force_body_conditions.weapons = config_system.push(
                    'Ragebot', 'force_body_conditions.weapons', menu.new(
                        ui.new_multiselect, 'AA', 'Anti-aimbot angles', new_key('Weapons', 'force_body_conditions'), weapon_list
                    )
                )

                force_body_conditions.conditions = config_system.push(
                    'Ragebot', 'force_body_conditions.conditions', menu.new(
                        ui.new_multiselect, 'AA', 'Anti-aimbot angles', new_key('Conditions', 'force_body_conditions'), condition_list
                    )
                )

                force_body_conditions.max_misses = config_system.push(
                    'Ragebot', 'force_body_conditions.max_misses', menu.new(
                        ui.new_slider, 'AA', 'Anti-aimbot angles', new_key('Max misses', 'force_body_conditions'), 1, 5, 2
                    )
                )

                force_body_conditions.scout_damage = config_system.push(
                    'Ragebot', 'force_body_conditions.scout_damage', menu.new(
                        ui.new_slider, 'AA', 'Anti-aimbot angles', new_key('Scout damage', 'force_body_conditions'), 0, 126, 0, true, '', 1, scout_damage_tooltips
                    )
                )

                force_body_conditions.disabler = config_system.push(
                    'Ragebot', 'force_body_conditions.disabler', menu.new(
                        ui.new_hotkey, 'AA', 'Anti-aimbot angles', new_key('Disabler', 'force_body_conditions')
                    )
                )

                force_body_conditions.separator = menu.new(
                    ui.new_label, 'AA', 'Anti-aimbot angles', '\n'
                )

                lock_unselection(force_body_conditions.conditions)
                lock_unselection(force_body_conditions.weapons)

                ragebot.force_body_conditions = force_body_conditions
            end

            local force_lethal = { } do
                local weapon_list = {
                    'Auto Snipers',
                    'Desert Eagle'
                }

                force_lethal.enabled = config_system.push(
                    'Ragebot', 'force_lethal.enabled', menu.new(
                        ui.new_checkbox, 'AA', 'Anti-aimbot angles', new_key('Force lethal', 'force_lethal')
                    )
                )

                force_lethal.weapons = config_system.push(
                    'Ragebot', 'force_lethal.weapons', menu.new(
                        ui.new_multiselect, 'AA', 'Anti-aimbot angles', new_key('Weapons', 'force_lethal'), weapon_list
                    )
                )

                force_lethal.mode = config_system.push(
                    'Ragebot', 'force_lethal.mode', menu.new(
                        ui.new_combobox, 'AA', 'Anti-aimbot angles', new_key('Mode', 'force_lethal'), {
                            'Default',
                            'Damage = HP/2'
                        }
                    )
                )

                for i = 1, #weapon_list do
                    local weapon = weapon_list[i]

                    local list = { }

                    list.hitchance = config_system.push(
                        'Ragebot', 'force_lethal.hitchance.' .. weapon, menu.new(
                            ui.new_slider, 'AA', 'Anti-aimbot angles', new_key(weapon .. ' hitchance', 'force_lethal'), -1, 100, -1, true, '%', 1, {
                                [-1] = 'Off'
                            }
                        )
                    )

                    force_lethal[weapon] = list
                end

                force_lethal.separator = menu.new(
                    ui.new_label, 'AA', 'Anti-aimbot angles', '\n'
                )

                lock_unselection(force_lethal.weapons)
                force_lethal.weapon_list = weapon_list

                ragebot.force_lethal = force_lethal
            end

            local auto_hide_shots = { } do
                local weapon_list = {
                    'Auto Snipers',
                    'AWP',
                    'Scout',
                    'Desert Eagle',
                    'Pistols',
                    'SMG',
                    'Rifles'
                }

                local state_list = {
                    'Standing',
                    'Moving',
                    'Slow Walk',
                    'Air',
                    'Air-Crouch',
                    'Crouch',
                    'Move-Crouch',
                }

                auto_hide_shots.enabled = config_system.push(
                    'Ragebot', 'auto_hide_shots.enabled', menu.new(
                        ui.new_checkbox, 'AA', 'Anti-aimbot angles', new_key('Auto hide shots', 'auto_hide_shots')
                    )
                )

                auto_hide_shots.weapons = config_system.push(
                    'Ragebot', 'auto_hide_shots.weapons', menu.new(
                        ui.new_multiselect, 'AA', 'Anti-aimbot angles', new_key('Weapons', 'auto_hide_shots'), weapon_list
                    )
                )

                auto_hide_shots.states = config_system.push(
                    'Ragebot', 'auto_hide_shots.states', menu.new(
                        ui.new_multiselect, 'AA', 'Anti-aimbot angles', new_key('States', 'auto_hide_shots'), state_list
                    )
                )

                auto_hide_shots.separator = menu.new(
                    ui.new_label, 'AA', 'Anti-aimbot angles', '\n'
                )

                lock_unselection(auto_hide_shots.weapons)

                lock_unselection(auto_hide_shots.states, {
                    'Slow Walk',
                    'Crouch',
                    'Move-Crouch'
                })

                ragebot.auto_hide_shots = auto_hide_shots
            end

            local allow_duck_on_fd = { } do
                allow_duck_on_fd.enabled = config_system.push(
                    'Ragebot', 'allow_duck_on_fd.enabled', menu.new(
                        ui.new_checkbox, 'AA', 'Anti-aimbot angles', new_key('Allow duck on fd', 'allow_duck_on_fd')
                    )
                )

                ragebot.allow_duck_on_fd = allow_duck_on_fd
            end

            local unsafe_recharge = { } do
                unsafe_recharge.enabled = config_system.push(
                    'Ragebot', 'unsafe_recharge.enabled', menu.new(
                        ui.new_checkbox, 'AA', 'Anti-aimbot angles', new_key('Unsafe recharge', 'unsafe_recharge')
                    )
                )

                ragebot.unsafe_recharge = unsafe_recharge
            end

            local hideshots_fix = { } do
                hideshots_fix.enabled = config_system.push(
                    'Ragebot', 'hideshots_fix.enabled', menu.new(
                        ui.new_checkbox, 'AA', 'Anti-aimbot angles', new_key('Hideshots fix', 'hideshots_fix')
                    )
                )

                ragebot.hideshots_fix = hideshots_fix
            end

            local hitchance = { } do
                local option_list = {
                    'In Air',
                    'No Scope',
                    'Hotkey',
                    'Crouch',
                    'Peek Assist'
                }

                local weapon_list = {
                    'Auto Snipers',
                    'Desert Eagle',
                    'Revolver R8',
                    'Pistols',
                    'Scout',
                    'AWP'
                }

                hitchance.enabled = config_system.push(
                    'Ragebot', 'hitchance.enabled', menu.new(
                        ui.new_checkbox, 'AA', 'Other', new_key('Hitchance override', 'hitchance')
                    )
                )

                hitchance.weapon = menu.new(
                    ui.new_combobox, 'AA', 'Other', new_key('Weapon', 'hitchance'), weapon_list
                )

                for i = 1, #weapon_list do
                    local weapon = weapon_list[i]

                    local should_has_scope = (
                        weapon == 'Auto Snipers' or
                        weapon == 'Scout' or
                        weapon == 'AWP'
                    )

                    local new_option_list = {
                        unpack(option_list)
                    }

                    if not should_has_scope then
                        local index = contains(
                            new_option_list, 'No Scope'
                        )

                        if index ~= nil then
                            table.remove(new_option_list, index)
                        end
                    end

                    local function hash(name)
                        return string.format(
                            'hitchance.%s[%s]',
                            name, weapon
                        )
                    end

                    local items = { }

                    items.options = config_system.push(
                        'Ragebot', hash 'options', menu.new(
                            ui.new_multiselect, 'AA', 'Other', new_key('Options', hash 'options'), new_option_list
                        )
                    )

                    for j = 1, #new_option_list do
                        local option = new_option_list[j]

                        local function hash_option(name)
                            return hash(string.format(
                                '%s[%s]', option, name
                            ))
                        end

                        local option_items = { }

                        option_items.value = config_system.push(
                            'Ragebot', hash_option 'value', menu.new(
                                ui.new_slider, 'AA', 'Other', new_key(option, hash_option 'value'), 0, 100, 0, true, '%'
                            )
                        )

                        if option == 'No Scope' then
                            option_items.distance = config_system.push(
                                'Ragebot', hash_option 'distance', menu.new(
                                    ui.new_slider, 'AA', 'Other', new_key('Distance', hash_option 'distance'), 5, 101, 35, true, 'u', 1, {
                                        [101] = 'Inf'
                                    }
                                )
                            )
                        end

                        items[option] = option_items
                    end

                    hitchance[weapon] = items
                end

                hitchance.hotkey = config_system.push(
                    'Ragebot', 'hitchance.hotkey', menu.new(
                        ui.new_hotkey, 'AA', 'Other', 'Override hitchance'
                    )
                )

                hitchance.indicator_text = config_system.push(
                    'Ragebot', 'hitchance.indicator_text', menu.new(
                        ui.new_combobox, 'AA', 'Other', new_key('Indicator text', 'hitchance'), {
                            'Off',
                            'HC',
                            'HITCHANCE',
                            'HITCHANCE OVR'
                        }
                    )
                )

                hitchance.separator = menu.new(
                    ui.new_label, 'AA', 'Other', '\n'
                )

                hitchance.option_list = option_list

                ragebot.hitchance = hitchance
            end

            local quick_peek_auto_stop = { } do
                local weapon_list = {
                    'Auto Snipers',
                    'Desert Eagle',
                    'Revolver R8',
                    'Pistols',
                    'Scout',
                    'AWP'
                }

                quick_peek_auto_stop.enabled = config_system.push(
                    'Ragebot', 'quick_peek_auto_stop.enabled', menu.new(
                        ui.new_checkbox, 'AA', 'Other', new_key('Quick peek auto stop', 'quick_peek_auto_stop')
                    )
                )

                quick_peek_auto_stop.weapon = menu.new(
                    ui.new_combobox, 'AA', 'Other', new_key('Weapon', 'quick_peek_auto_stop'), weapon_list
                )

                for i = 1, #weapon_list do
                    local weapon = weapon_list[i]

                    local function hash(name)
                        return string.format(
                            'quick_peek_auto_stop.%s[%s]',
                            name, weapon
                        )
                    end

                    local items = { }

                    items.enabled = config_system.push(
                        'Ragebot', hash 'enabled', menu.new(
                            ui.new_checkbox, 'AA', 'Other', new_key('Enable', hash 'enabled')
                        )
                    )

                    items.auto_stop = config_system.push(
                        'Ragebot', hash 'auto_stop', menu.new(
                            ui.new_multiselect, 'AA', 'Other', new_key('Auto stop', hash 'auto_stop'), {
                                'Early',
                                'Slow motion',
                                'Duck',
                                'Fake duck',
                                'Move between shots',
                                'Ignore molotov',
                                'Taser',
                                'Jump scout'
                            }
                        )
                    )

                    quick_peek_auto_stop[weapon] = items
                end

                quick_peek_auto_stop.separator = menu.new(
                    ui.new_label, 'AA', 'Other', '\n'
                )

                ragebot.quick_peek_auto_stop = quick_peek_auto_stop
            end

            main.ragebot = ragebot
        end

        local miscellaneous = { } do
            local drop_nades = { } do
                drop_nades.enabled = config_system.push(
                    'Miscellaneous', 'drop_nades.enabled', menu.new(
                        ui.new_checkbox, 'AA', 'Anti-aimbot angles', new_key('Drop nades', 'drop_nades')
                    )
                )

                drop_nades.hotkey = config_system.push(
                    'Miscellaneous', 'drop_nades.hotkey', menu.new(
                        ui.new_hotkey, 'AA', 'Anti-aimbot angles', new_key('Drop nades hotkey', 'drop_nades'), true
                    )
                )

                drop_nades.select = config_system.push(
                    'Miscellaneous', 'drop_nades.select', menu.new(
                        ui.new_multiselect, 'AA', 'Anti-aimbot angles', new_key('Select', 'drop_nades'), {
                            'HE',
                            'Smoke',
                            'Molotov'
                        }
                    )
                )

                drop_nades.separator = menu.new(
                    ui.new_label, 'AA', 'Anti-aimbot angles', '\n'
                )

                lock_unselection(drop_nades.select)

                miscellaneous.drop_nades = drop_nades
            end

            local enhance_grenade_release = { } do
                enhance_grenade_release.enabled = config_system.push(
                    'Miscellaneous', 'enhance_grenade_release.enabled', menu.new(
                        ui.new_checkbox, 'AA', 'Anti-aimbot angles', new_key('Enhance grenade release', 'enhance_grenade_release')
                    )
                )

                enhance_grenade_release.disablers = config_system.push(
                    'Miscellaneous', 'enhance_grenade_release.disablers', menu.new(
                        ui.new_multiselect, 'AA', 'Anti-aimbot angles', new_key('Disablers', 'enhance_grenade_release'), {
                            'Molotov',
                            'HE Grenade',
                            'Smoke Grenade'
                        }
                    )
                )

                enhance_grenade_release.only_with_dt = config_system.push(
                    'Miscellaneous', 'enhance_grenade_release.only_with_dt', menu.new(
                        ui.new_checkbox, 'AA', 'Anti-aimbot angles', new_key('Only with dt', 'enhance_grenade_release')
                    )
                )

                enhance_grenade_release.separator = menu.new(
                    ui.new_label, 'AA', 'Anti-aimbot angles', '\n'
                )

                miscellaneous.enhance_grenade_release = enhance_grenade_release
            end

            local fps_optimize = { } do
                fps_optimize.enabled = config_system.push(
                    'Miscellaneous', 'fps_optimize.enabled', menu.new(
                        ui.new_checkbox, 'AA', 'Anti-aimbot angles', new_key('Fps optimize', 'fps_optimize')
                    )
                )

                fps_optimize.always_on = config_system.push(
                    'Miscellaneous', 'fps_optimize.always_on', menu.new(
                        ui.new_checkbox, 'AA', 'Anti-aimbot angles', new_key('Always on', 'fps_optimize')
                    )
                )

                fps_optimize.detections = config_system.push(
                    'Miscellaneous', 'fps_optimize.detections', menu.new(
                        ui.new_multiselect, 'AA', 'Anti-aimbot angles', new_key('Detections', 'fps_optimize'), {
                            'Peeking',
                            'Hit flag'
                        }
                    )
                )

                fps_optimize.list = config_system.push(
                    'Miscellaneous', 'fps_optimize.list', menu.new(
                        ui.new_multiselect, 'AA', 'Anti-aimbot angles', new_key('Optimizations', 'fps_optimize'), {
                            'Blood',
                            'Bloom',
                            'Decals',
                            'Shadows',
                            'Sprites',
                            'Particles',
                            'Ropes',
                            'Dynamic lights',
                            'Map details',
                            'Weapon effects'
                        }
                    )
                )

                fps_optimize.separator = menu.new(
                    ui.new_label, 'AA', 'Anti-aimbot angles', '\n'
                )

                lock_unselection(fps_optimize.detections)

                lock_unselection(fps_optimize.list, {
                    'Blood',
                    'Decals',
                    'Sprites',
                    'Ropes',
                    'Dynamic lights',
                    'Weapon effects'
                })

                miscellaneous.fps_optimize = fps_optimize
            end

            local trash_talk = { } do
                trash_talk.enabled = config_system.push(
                    'Miscellaneous', 'trash_talk.enabled', menu.new(
                        ui.new_checkbox, 'AA', 'Anti-aimbot angles', new_key('Trash talk', 'trash_talk')
                    )
                )

                trash_talk.disable_on_warmup = config_system.push(
                    'Miscellaneous', 'trash_talk.disable_on_warmup', menu.new(
                        ui.new_checkbox, 'AA', 'Anti-aimbot angles', new_key('Disable on warmup', 'trash_talk')
                    )
                )

                trash_talk.triggers = config_system.push(
                    'Miscellaneous', 'trash_talk.triggers', menu.new(
                        ui.new_multiselect, 'AA', 'Anti-aimbot angles', new_key('Triggers', 'trash_talk'), {
                            'On Kill',
                            'On Death'
                        }
                    )
                )

                trash_talk.tooltip = menu.new(
                    ui.new_label, 'AA', 'Anti-aimbot angles', 'Works only, when your K/D is above 1.0'
                )

                trash_talk.separator = menu.new(
                    ui.new_label, 'AA', 'Anti-aimbot angles', '\n'
                )

                lock_unselection(trash_talk.triggers)

                miscellaneous.trash_talk = trash_talk
            end

            local clantag = { } do
                clantag.enabled = config_system.push(
                    'Miscellaneous', 'clantag.enabled', menu.new(
                        ui.new_checkbox, 'AA', 'Anti-aimbot angles', new_key('Clantag', 'clantag')
                    )
                )

                clantag.text = config_system.push(
                    'Miscellaneous', 'clantag.text', menu.new(
                        ui.new_combobox, 'AA', 'Anti-aimbot angles', new_key('Text', 'clantag'), {
                            'Aesthetic',
                            'Custom'
                        }
                    )
                )

                clantag.mode = config_system.push(
                    'Miscellaneous', 'clantag.mode', menu.new(
                        ui.new_combobox, 'AA', 'Anti-aimbot angles', new_key('Mode', 'clantag'), {
                            'Static',
                            'Reversed',
                            'Animated'
                        }
                    )
                )

                clantag.input = config_system.push(
                    'Miscellaneous', 'clantag.input', menu.new(
                        ui.new_textbox, 'AA', 'Anti-aimbot angles', new_key('Input', 'clantag')
                    )
                )

                clantag.speed = config_system.push(
                    'Miscellaneous', 'clantag.speed', menu.new(
                        ui.new_slider, 'AA', 'Anti-aimbot angles', new_key('Speed', 'clantag'), 3, 20, 5, true, 's', 0.1
                    )
                )

                clantag.tooltip = menu.new(
                    ui.new_label, 'AA', 'Anti-aimbot angles', 'Works only, when your K/D is above 1.0'
                )

                miscellaneous.clantag = clantag
            end

            local fast_ladder = { } do
                fast_ladder.enabled = config_system.push(
                    'Miscellaneous', 'fast_ladder.enabled', menu.new(
                        ui.new_checkbox, 'AA', 'Other', new_key('Fast ladder', 'fast_ladder')
                    )
                )

                miscellaneous.fast_ladder = fast_ladder
            end

            local console_filter = { } do
                console_filter.enabled = config_system.push(
                    'Miscellaneous', 'console_filter.enabled', menu.new(
                        ui.new_checkbox, 'AA', 'Other', new_key('Console filter', 'console_filter')
                    )
                )

                miscellaneous.console_filter = console_filter
            end

            local sync_ragebot_hotkeys = { } do
                sync_ragebot_hotkeys.enabled = config_system.push(
                    'Miscellaneous', 'sync_ragebot_hotkeys.enabled', menu.new(
                        ui.new_checkbox, 'AA', 'Other', new_key('Sync ragebot hotkeys', 'sync_ragebot_hotkeys')
                    )
                )

                miscellaneous.sync_ragebot_hotkeys = sync_ragebot_hotkeys
            end

            local reveal_enemy_team_chat = { } do
                reveal_enemy_team_chat.enabled = config_system.push(
                    'Miscellaneous', 'reveal_enemy_team_chat.enabled', menu.new(
                        ui.new_checkbox, 'AA', 'Other', new_key('Reveal enemy team chat', 'reveal_enemy_team_chat')
                    )
                )

                miscellaneous.reveal_enemy_team_chat = reveal_enemy_team_chat
            end

            main.miscellaneous = miscellaneous
        end

        local animations = { } do
            animations.air_legs = config_system.push(
                'Animations', 'anim_breaker.air_legs', menu.new(
                    ui.new_combobox, 'AA', 'Anti-aimbot angles', new_key('Air legs', 'animations'), {
                        'Off',
                        'Static',
                        'Moonwalk',
                        'Kangaroo'
                    }
                )
            )

            animations.air_legs_weight = config_system.push(
                'Animations', 'anim_breaker.air_legs_weight', menu.new(
                    ui.new_slider, 'AA', 'Anti-aimbot angles', new_key('Weight', 'animations'), 0, 100, 100, true, '%'
                )
            )

            animations.ground_legs = config_system.push(
                'Animations', 'anim_breaker.ground_legs', menu.new(
                    ui.new_combobox, 'AA', 'Anti-aimbot angles', new_key('Ground legs', 'animations'), {
                        'Off',
                        'Static',
                        'Jitter',
                        'Moonwalk',
                        'Kangaroo',
                        'Pacan4ik'
                    }
                )
            )

            animations.legs_offset_1 = config_system.push(
                'Animations', 'anim_breaker.legs_offset_1', menu.new(
                    ui.new_slider, 'AA', 'Anti-aimbot angles', new_key('Offset 1', 'animations'), 0, 100, 100
                )
            )

            animations.legs_offset_2 = config_system.push(
                'Animations', 'anim_breaker.legs_offset_2', menu.new(
                    ui.new_slider, 'AA', 'Anti-aimbot angles', new_key('Offset 2', 'animations'), 0, 100, 100
                )
            )

            animations.legs_jitter_time = config_system.push(
                'Animations', 'anim_breaker.legs_jitter_time', menu.new(
                    ui.new_slider, 'AA', 'Anti-aimbot angles', new_key('Jitter time', 'animations'), 1, 8, 2, true, 't'
                )
            )

            animations.options = config_system.push(
                'Animations', 'anim_breaker.options', menu.new(
                    ui.new_multiselect, 'AA', 'Anti-aimbot angles', new_key('Options', 'animations'), {
                        'Move lean',
                        'Smooth animfix',
                        'Pitch zero on land'
                    }
                )
            )

            animations.move_lean = config_system.push(
                'Animations', 'anim_breaker.move_lean', menu.new(
                    ui.new_slider, 'AA', 'Anti-aimbot angles', new_key('Move lean', 'animations'), -1, 100, -1, true, '', 1, {
                        [-1] = 'Off'
                    }
                )
            )

            main.animations = animations
        end

        local logging_system = { } do
            local main_color_list = {
                { 'Target', color(127, 180, 95, 255) },
                { 'Other', color(132, 163, 209, 255) }
            }

            local miss_color_list = {
                { 'Death', color(189, 75, 75, 255) },
                { 'Spread', color(189, 75, 75, 255) },
                { 'Resolver', color(189, 75, 75, 255) },
                { 'Prediction error', color(189, 75, 75, 255) },
                { 'Unregistered shot', color(189, 75, 75, 255) }
            }

            logging_system.enabled = config_system.push(
                'Logging system', 'logging_system.enabled', menu.new(
                    ui.new_checkbox, 'AA', 'Anti-aimbot angles', new_key('Logging system', 'logging_system')
                )
            )

            logging_system.events = config_system.push(
                'Logging system', 'logging_system.events', menu.new(
                    ui.new_multiselect, 'AA', 'Anti-aimbot angles', new_key('Events', 'logging_system'), {
                        'Aimbot',
                        'Purchase'
                    }
                )
            )

            logging_system.output = config_system.push(
                'Logging system', 'logging_system.output', menu.new(
                    ui.new_multiselect, 'AA', 'Anti-aimbot angles', new_key('Output', 'logging_system'), {
                        'Console',
                        'Events',
                        'Under crosshair'
                    }
                )
            )

            logging_system.events_font = config_system.push(
                'Logging system', 'logging_system.events_font', menu.new(
                    ui.new_combobox, 'AA', 'Anti-aimbot angles', new_key('Events font', 'logging_system'), {
                        'Bold',
                        'Old'
                    }
                )
            )

            logging_system.offset_y = config_system.push(
                'Logging system', 'logging_system.offset_y', menu.new(
                    ui.new_slider, 'AA', 'Anti-aimbot angles', new_key('Offset Y', 'logging_system'), 0, 100, 100, true, '%'
                )
            )

            logging_system.duration = config_system.push(
                'Logging system', 'logging_system.duration', menu.new(
                    ui.new_slider, 'AA', 'Anti-aimbot angles', new_key('Duration', 'logging_system'), 5, 40, 100, true, 's.', 0.1
                )
            )

            logging_system.console_text_style = config_system.push(
                'Logging system', 'logging_system.console_text_style', menu.new(
                    ui.new_combobox, 'AA', 'Anti-aimbot angles', new_key('Console text style', 'logging_system'), {
                        'Aesthetic',
                        'Gamesense'
                    }
                )
            )

            logging_system.crosshair_text_style = config_system.push(
                'Logging system', 'logging_system.crosshair_text_style', menu.new(
                    ui.new_combobox, 'AA', 'Anti-aimbot angles', new_key('Crosshair text style', 'logging_system'), {
                        'Aesthetic',
                        'Gamesense'
                    }
                )
            )

            for i = 1, #main_color_list do
                local values = main_color_list[i]

                local name = values[1]
                local col = values[2]

                local items = { }

                local color_key = string.format('%s_color', name:lower())

                local label_name = string.format('%s color', name)
                local picker_name = string.format('%s color picker', name)

                items.label = menu.new(
                    ui.new_label, 'AA', 'Other', new_key(label_name, 'logging_system')
                )

                items.color = config_system.push(
                    'Logging system', string.format('logging_system.%s', color_key), menu.new(
                        ui.new_color_picker, 'AA', 'Other', new_key(picker_name, 'logging_system'), col:unpack()
                    )
                )

                logging_system[name] = items
            end

            logging_system.color_separator = menu.new(
                ui.new_label, 'AA', 'Other', '\n'
            )

            for i = 1, #miss_color_list do
                local values = miss_color_list[i]

                local name = values[1]
                local col = values[2]

                local items = { }

                local color_key = string.format('%s_color', name:lower())

                local label_name = string.format('%s color', name)
                local picker_name = string.format('%s color picker', name)

                items.label = menu.new(
                    ui.new_label, 'AA', 'Other', new_key(label_name, 'logging_system')
                )

                items.color = config_system.push(
                    'Logging system', string.format('logging_system.%s', color_key), menu.new(
                        ui.new_color_picker, 'AA', 'Other', new_key(picker_name, 'logging_system'), col:unpack()
                    )
                )

                logging_system[name] = items
            end

            lock_unselection(logging_system.output)
            lock_unselection(logging_system.events)

            logging_system.main_color_list = main_color_list
            logging_system.miss_color_list = miss_color_list

            main.logging_system = logging_system
        end

        local automatic_purchase = { } do
            automatic_purchase.enabled = config_system.push(
                'Automatic purchase', 'buy_bot.enabled', menu.new(
                    ui.new_checkbox, 'AA', 'Anti-aimbot angles', new_key('Enabled', 'buy_bot')
                )
            )

            automatic_purchase.primary = config_system.push(
                'Automatic purchase', 'buy_bot.primary', menu.new(
                    ui.new_combobox, 'AA', 'Anti-aimbot angles', new_key('Primary', 'buy_bot'), {
                        'Off',
                        'AWP',
                        'Scout',
                        'G3SG1 / SCAR-20'
                    }
                )
            )

            automatic_purchase.alternative = config_system.push(
                'Automatic purchase', 'buy_bot.alternative', menu.new(
                    ui.new_combobox, 'AA', 'Anti-aimbot angles', new_key('Alternative', 'buy_bot'), {
                        'Off',
                        'Scout',
                        'G3SG1 / SCAR-20'
                    }
                )
            )

            automatic_purchase.secondary = config_system.push(
                'Automatic purchase', 'buy_bot.secondary', menu.new(
                    ui.new_combobox, 'AA', 'Anti-aimbot angles', new_key('Secondary', 'buy_bot'), {
                        'Off',
                        'P250',
                        'Elites',
                        'Five-seven / Tec-9 / CZ75',
                        'Deagle / Revolver'
                    }
                )
            )

            automatic_purchase.equipment = config_system.push(
                'Automatic purchase', 'buy_bot.equipment', menu.new(
                    ui.new_multiselect, 'AA', 'Anti-aimbot angles', new_key('Equipment', 'buy_bot'), {
                        'Kevlar',
                        'Kevlar + Helmet',
                        'Defuse kit',
                        'HE',
                        'Smoke',
                        'Molotov',
                        'Taser'
                    }
                )
            )

            automatic_purchase.ignore_pistol_round = config_system.push(
                'Automatic purchase', 'buy_bot.ignore_pistol_round', menu.new(
                    ui.new_checkbox, 'AA', 'Anti-aimbot angles', new_key('Ignore pistol round', 'buy_bot')
                )
            )

            automatic_purchase.only_16k = config_system.push(
                'Automatic purchase', 'buy_bot.only_16k', menu.new(
                    ui.new_checkbox, 'AA', 'Anti-aimbot angles', new_key('Only $16k', 'buy_bot')
                )
            )

            main.automatic_purchase = automatic_purchase
        end

        resource.main = main
    end

    local antiaim = { } do
        local builder = { } do
            local function create_defensive_items(state, team)
                local items = { }

                local function hash(key)
                    return state .. ':' .. team .. ':defensive_' .. key
                end

                items.force_defensive = config_system.push(
                    'Builder', hash 'force_defensive', menu.new(
                        ui.new_checkbox, 'AA', 'Other', new_key(
                            'Force defensive', hash 'force_defensive'
                        )
                    )
                )

                items.enabled = config_system.push(
                    'Builder', hash 'enabled', menu.new(
                        ui.new_checkbox, 'AA', 'Other', new_key(
                            'Defensive anti-aim', hash 'enabled'
                        )
                    )
                )

                items.pitch = config_system.push(
                    'Builder', hash 'pitch', menu.new(
                        ui.new_combobox, 'AA', 'Other', new_key('Pitch', hash 'pitch'), {
                            'Off',
                            'Static',
                            'Sway',
                            'Switch',
                            'Random',
                            'Static Random'
                        }
                    )
                )

                items.pitch_label_1 = menu.new(
                    ui.new_label, 'AA', 'Other', 'From'
                )

                items.pitch_offset_1 = config_system.push(
                    'Builder', hash 'pitch_offset_1', menu.new(
                        ui.new_slider, 'AA', 'Other', new_key('\n', hash 'pitch_offset_1'), -89, 89, 0, true, '°'
                    )
                )

                items.pitch_label_2 = menu.new(
                    ui.new_label, 'AA', 'Other', 'To'
                )

                items.pitch_offset_2 = config_system.push(
                    'Builder', hash 'pitch_offset_2', menu.new(
                        ui.new_slider, 'AA', 'Other', new_key('\n', hash 'pitch_offset_2'), -89, 89, 0, true, '°'
                    )
                )

                items.pitch_speed = config_system.push(
                    'Builder', hash 'pitch_speed', menu.new(
                        ui.new_slider, 'AA', 'Other', new_key('Speed', hash 'pitch_speed'), -75, 75, 20, true, nil, 0.1
                    )
                )

                items.yaw = config_system.push(
                    'Builder', hash 'yaw', menu.new(
                        ui.new_combobox, 'AA', 'Other', new_key('Yaw', hash 'yaw'), {
                            'Off',
                            'Side Based',
                            'Opposite',
                            'Spin',
                            'Sway',
                            'X-Way',
                            'Random',
                            'Left/Right',
                            'Static Random'
                        }
                    )
                )

                items.ways_count = config_system.push(
                    'Builder', hash 'ways_count', menu.new(
                        ui.new_slider, 'AA', 'Other', new_key('\n', hash 'ways_count'), 3, 7, 3, true, ''
                    )
                )

                items.ways_custom = config_system.push(
                    'Builder', hash 'ways_custom', menu.new(
                        ui.new_checkbox, 'AA', 'Other', new_key('Custom ways', hash 'ways_custom')
                    )
                )

                for i = 1, 7 do
                    items['way_' .. i] = config_system.push(
                        'Builder', hash('way_' .. i), menu.new(
                            ui.new_slider, 'AA', 'Other', new_key('\n', hash('way_' .. i)), -180, 180, 0, true, '°'
                        )
                    )
                end

                items.yaw_offset = config_system.push(
                    'Builder', hash 'yaw_offset', menu.new(
                        ui.new_slider, 'AA', 'Other', new_key('\n', hash 'yaw_offset'), -180, 180, 0, true, '°'
                    )
                )

                items.yaw_left = config_system.push(
                    'Builder', hash 'yaw_left', menu.new(
                        ui.new_slider, 'AA', 'Other', new_key('Yaw left', hash 'yaw_left'), -180, 180, 0, true, '°'
                    )
                )

                items.yaw_right = config_system.push(
                    'Builder', hash 'yaw_right', menu.new(
                        ui.new_slider, 'AA', 'Other', new_key('Yaw right', hash 'yaw_right'), -180, 180, 0, true, '°'
                    )
                )

                items.yaw_speed = config_system.push(
                    'Builder', hash 'yaw_speed', menu.new(
                        ui.new_slider, 'AA', 'Other', new_key('Speed', hash 'yaw_speed'), -75, 75, 20, true, '', 0.1
                    )
                )

                items.ways_auto_body_yaw = config_system.push(
                    'Builder', hash 'ways_auto_body_yaw', menu.new(
                        ui.new_checkbox, 'AA', 'Other', new_key('Automatic body yaw', hash 'ways_auto_body_yaw')
                    )
                )

                items.body_yaw = config_system.push(
                    'Builder', hash 'body_yaw', menu.new(
                        ui.new_combobox, 'AA', 'Other', new_key('Body yaw', hash 'body_yaw'), {
                            'Off',
                            'Opposite',
                            'Static',
                            'Jitter'
                        }
                    )
                )

                items.body_yaw_offset = config_system.push(
                    'Builder', hash 'body_yaw_offset', menu.new(
                        ui.new_slider, 'AA', 'Other', new_key('\n', hash 'body_yaw_offset'), -180, 180, 0, true, '°'
                    )
                )

                items.freestanding_body_yaw = config_system.push(
                    'Builder', hash 'freestanding_body_yaw', menu.new(
                        ui.new_checkbox, 'AA', 'Other', new_key(
                            'Freestanding body yaw', hash 'freestanding_body_yaw'
                        )
                    )
                )

                items.delay_from = config_system.push(
                    'Builder', hash 'delay_from', menu.new(
                        ui.new_slider, 'AA', 'Other', new_key('Delay from', hash 'delay_from'), 1, 8, 1, true, 't', 1, {
                            [1] = 'Off'
                        }
                    )
                )

                items.delay_to = config_system.push(
                    'Builder', hash 'delay_to', menu.new(
                        ui.new_slider, 'AA', 'Other', new_key('Delay to', hash 'delay_to'), 1, 8, 1, true, 't', 1, {
                            [1] = 'Off'
                        }
                    )
                )

                return items
            end

            local function create_builder_items(state, team, std_key)
                local items = { }

                local is_default = state == 'Default'
                local is_legit_aa = state == 'Legit AA'

                local is_freestanding = state == 'Freestanding'

                local function hash(key)
                    return team .. ':' .. state .. ':' .. key
                end

                if std_key ~= nil then
                    function hash(key)
                        return state .. ':' .. team .. ':' .. key .. ':' .. std_key
                    end
                end

                if not is_default then
                    local enabled_name = string.format(
                        'Override %s', state
                    )

                    items.enabled = config_system.push(
                        'Builder', hash 'enabled', menu.new(
                            ui.new_checkbox, 'AA', 'Anti-aimbot angles', new_key(
                                enabled_name, hash 'enabled'
                            )
                        )
                    )
                end

                if is_legit_aa then
                    items.bomb_e_fix = config_system.push(
                        'Builder', hash 'bomb_e_fix', menu.new(
                            ui.new_checkbox, 'AA', 'Anti-aimbot angles', new_key(
                                'Bomb E fix', hash 'bomb_e_fix'
                            )
                        )
                    )
                end

                if is_legit_aa then
                    items.yaw_base = config_system.push(
                        'Builder', hash 'yaw_base', menu.new(
                            ui.new_combobox, 'AA', 'Anti-aimbot angles', new_key('Yaw base', hash 'yaw_base'), {
                                'Local view',
                                'At targets'
                            }
                        )
                    )
                end

                if not is_freestanding then
                    if state == 'Move-Crouch' then
                        items.yaw_direction = config_system.push(
                            'Builder', hash 'yaw_direction', menu.new(
                                ui.new_combobox, 'AA', 'Anti-aimbot angles', new_key('Yaw direction', hash 'yaw_direction'), {
                                    'General', unpack(const.crouch_dirs)
                                }
                            )
                        )
                    end

                    items.yaw_left = config_system.push(
                        'Builder', hash 'yaw_left', menu.new(
                            ui.new_slider, 'AA', 'Anti-aimbot angles', new_key('Yaw left', hash 'yaw_left'), -180, 180, 0, true, '°'
                        )
                    )

                    items.yaw_right = config_system.push(
                        'Builder', hash 'yaw_right', menu.new(
                            ui.new_slider, 'AA', 'Anti-aimbot angles', new_key('Yaw right', hash 'yaw_right'), -180, 180, 0, true, '°'
                        )
                    )

                    if state == 'Move-Crouch' then
                        for i = 1, #const.crouch_dirs do
                            local dir = const.crouch_dirs[i]

                            items['enabled_dir_' .. dir] = config_system.push(
                                'Builder', hash('enabled_dir_' .. dir), menu.new(
                                    ui.new_checkbox, 'AA', 'Anti-aimbot angles', new_key('Enable ' .. dir, hash('enabled_dir_' .. dir))
                                )
                            )

                            items['yaw_left_dir_' .. dir] = config_system.push(
                                'Builder', hash('yaw_left_dir_' .. dir), menu.new(
                                    ui.new_slider, 'AA', 'Anti-aimbot angles', new_key('Yaw left', hash('yaw_left_dir_' .. dir)), -180, 180, 0, true, '°'
                                )
                            )

                            items['yaw_right_dir_' .. dir] = config_system.push(
                                'Builder', hash('yaw_right_dir_' .. dir), menu.new(
                                    ui.new_slider, 'AA', 'Anti-aimbot angles', new_key('Yaw left', hash('yaw_right_dir_' .. dir)), -180, 180, 0, true, '°'
                                )
                            )
                        end
                    end

                    items.yaw_random = config_system.push(
                        'Builder', hash 'yaw_random', menu.new(
                            ui.new_slider, 'AA', 'Anti-aimbot angles', new_key('Random', hash 'yaw_random'), 0, 30, 0, true, '%'
                        )
                    )

                    items.yaw_jitter = config_system.push(
                        'Builder', hash 'yaw_jitter', menu.new(
                            ui.new_combobox, 'AA', 'Anti-aimbot angles', new_key('Yaw jitter', hash 'yaw_jitter'), {
                                'Off',
                                'Offset',
                                'Center',
                                'Random',
                                'Skitter'
                            }
                        )
                    )

                    items.jitter_offset = config_system.push(
                        'Builder', hash 'jitter_offset', menu.new(
                            ui.new_slider, 'AA', 'Anti-aimbot angles', new_key('\n', hash 'jitter_offset'), -180, 180, 0, true, '°'
                        )
                    )

                    items.jitter_random = config_system.push(
                        'Builder', hash 'jitter_random', menu.new(
                            ui.new_slider, 'AA', 'Anti-aimbot angles', new_key('Randomization', hash 'jitter_random'), 0, 30, 0, true, '%'
                        )
                    )
                end

                items.body_yaw = config_system.push(
                    'Builder', hash 'body_yaw', menu.new(
                        ui.new_combobox, 'AA', 'Anti-aimbot angles', new_key('Body yaw', hash 'body_yaw'), {
                            'Off',
                            'Opposite',
                            'Static',
                            'Jitter',
                            'Jitter Random'
                        }
                    )
                )

                items.body_yaw_offset = config_system.push(
                    'Builder', hash 'body_yaw_offset', menu.new(
                        ui.new_slider, 'AA', 'Anti-aimbot angles', new_key('\n', hash 'body_yaw_offset'), -180, 180, 0, true, '°'
                    )
                )

                items.freestanding_body_yaw = config_system.push(
                    'Builder', hash 'freestanding_body_yaw', menu.new(
                        ui.new_checkbox, 'AA', 'Anti-aimbot angles', new_key(
                            'Freestanding body yaw', hash 'freestanding_body_yaw'
                        )
                    )
                )

                if state ~= 'Fakelag' then
                    items.delay_from = config_system.push(
                        'Builder', hash 'delay_from', menu.new(
                            ui.new_slider, 'AA', 'Anti-aimbot angles', new_key('Delay from', hash 'delay_from'), 1, 8, 1, true, 't', 1, {
                                [1] = 'Off'
                            }
                        )
                    )

                    items.delay_to = config_system.push(
                        'Builder', hash 'delay_to', menu.new(
                            ui.new_slider, 'AA', 'Anti-aimbot angles', new_key('Delay to', hash 'delay_to'), 1, 8, 1, true, 't', 1, {
                                [1] = 'Off'
                            }
                        )
                    )
                end

                return items
            end

            local function get_items(state, team)
                local items = builder[state]

                if items == nil then
                    return nil
                end

                return items[team]
            end

            local function get_values(items)
                local data = { }

                if items.angles ~= nil then
                    data.angles = { enabled = { true } }

                    for k, v in pairs(items.angles) do
                        data.angles[k] = { v:get() }
                    end
                end

                if items.defensive ~= nil then
                    data.defensive = { }

                    for k, v in pairs(items.defensive) do
                        data.defensive[k] = { v:get() }
                    end
                end

                return data
            end

            local function set_values(items, data)
                if items.angles ~= nil and data.angles ~= nil then
                    for k, v in pairs(data.angles) do
                        local item = items.angles[k]

                        if item == nil then
                            goto continue
                        end

                        if item.type == 'label' then
                            goto continue
                        end

                        item:set(unpack(v))

                        ::continue::
                    end
                end

                if items.defensive ~= nil and data.defensive ~= nil then
                    for k, v in pairs(data.defensive) do
                        local item = items.defensive[k]

                        if item == nil then
                            goto continue
                        end

                        if item.type == 'label' then
                            goto continue
                        end

                        item:set(unpack(v))

                        ::continue::
                    end
                end
            end

            builder.state = menu.new(
                ui.new_combobox, 'AA', 'Anti-aimbot angles', new_key('State', 'builder'), const.states
            )

            for i = 1, #const.states do
                local state = const.states[i]

                local items = { }

                items.team = menu.new(
                    ui.new_combobox, 'AA', 'Anti-aimbot angles', new_key('Team', 'builder'), const.teams
                )

                for j = 1, #const.teams do
                    local team = const.teams[j]

                    local team_items = { }

                    team_items.angles = create_builder_items(
                        state, team, nil
                    )

                    if state ~= 'Fakelag' then
                        team_items.defensive = create_defensive_items(state, team)
                    end

                    team_items.separator = menu.new(
                        ui.new_label, 'AA', 'Anti-aimbot angles', new_key('\n', 'separator')
                    )

                    team_items.send_to_another_team = menu.new(
                        ui.new_button, 'AA', 'Anti-aimbot angles', 'Send to another team', function()
                            local new_team = team == 'Counter-Terrorist'
                                and 'Terrorist' or 'Counter-Terrorist'

                            local target = get_items(
                                state, new_team
                            )

                            if target == nil then
                                return
                            end

                            set_values(target, get_values(team_items))
                            logging.success('sent to another team')
                        end
                    )

                    items[team] = team_items
                end

                builder[state] = items
            end

            antiaim.builder = builder
        end

        local features = { } do
            local avoid_backstab = { } do
                avoid_backstab.enabled = config_system.push(
                    'Features', 'avoid_backstab.enabled', menu.new(
                        ui.new_checkbox, 'AA', 'Anti-aimbot angles', 'Avoid backstab'
                    )
                )

                avoid_backstab.distance = config_system.push(
                    'Features', 'avoid_backstab.distance', menu.new(
                        ui.new_slider, 'AA', 'Anti-aimbot angles', new_key('Distance', 'avoid_backstab'), 150, 320, 240, true, 'u'
                    )
                )

                avoid_backstab.separator = menu.new(
                    ui.new_label, 'AA', 'Anti-aimbot angles', '\n'
                )

                features.avoid_backstab = avoid_backstab
            end

            local break_lc_triggers = { } do
                break_lc_triggers.enabled = config_system.push(
                    'Features', 'break_lc_triggers.enabled', menu.new(
                        ui.new_checkbox, 'AA', 'Anti-aimbot angles', 'Break LC triggers'
                    )
                )

                break_lc_triggers.states = config_system.push(
                    'Features', 'break_lc_triggers.states', menu.new(
                        ui.new_multiselect, 'AA', 'Anti-aimbot angles', new_key('States', 'force_break_lc_triggers'), {
                            'Flashed',
                            'Reloading',
                            'Taking damage'
                        }
                    )
                )

                break_lc_triggers.separator = menu.new(
                    ui.new_label, 'AA', 'Anti-aimbot angles', '\n'
                )

                lock_unselection(break_lc_triggers.states)

                features.break_lc_triggers = break_lc_triggers
            end

            local safe_head = { } do
                safe_head.enabled = config_system.push(
                    'Features', 'safe_head.enabled', menu.new(
                        ui.new_checkbox, 'AA', 'Anti-aimbot angles', new_key('Safe head', 'safe_head')
                    )
                )

                safe_head.conditions = config_system.push(
                    'Features', 'safe_head.conditions', menu.new(
                        ui.new_multiselect, 'AA', 'Anti-aimbot angles', new_key('Conditions', 'safe_head'), {
                            'Standing',
                            'Crouch',
                            'Air crouch',
                            'Air crouch knife',
                            'Air crouch taser',
                            'Distance'
                        }
                    )
                )

                safe_head.e_spam_while_active = config_system.push(
                    'Features', 'safe_head.e_spam_while_active', menu.new(
                        ui.new_checkbox, 'AA', 'Anti-aimbot angles', new_key('E Spam while active', 'safe_head')
                    )
                )

                safe_head.separator = menu.new(
                    ui.new_label, 'AA', 'Anti-aimbot angles', '\n'
                )

                lock_unselection(safe_head.conditions)

                features.safe_head = safe_head
            end

            local warmup_round_end = { } do
                warmup_round_end.enabled = config_system.push(
                    'Features', 'warmup_round_end.enabled', menu.new(
                        ui.new_checkbox, 'AA', 'Anti-aimbot angles', new_key('Warmup / Round end AA', 'warmup_round_end')
                    )
                )

                features.warmup_round_end = warmup_round_end
            end

            local flick_exploit = { } do
                flick_exploit.enabled = config_system.push(
                    'Features', 'flick_exploit.enabled', menu.new(
                        ui.new_checkbox, 'AA', 'Anti-aimbot angles', new_key('Flick exploit', 'flick_exploit')
                    )
                )

                flick_exploit.states = config_system.push(
                    'Features', 'flick_exploit.states', menu.new(
                        ui.new_multiselect, 'AA', 'Anti-aimbot angles', new_key('States', 'flick_exploit'), {
                            'Standing',
                            'Slow Walk',
                            'Air',
                            'Air-Crouch',
                            'Crouch',
                            'Move-Crouch'
                        }
                    )
                )

                flick_exploit.pitch = config_system.push(
                    'Features', 'flick_pitch', menu.new(
                        ui.new_combobox, 'AA', 'Anti-aimbot angles', new_key('Pitch', 'flick_pitch'), {
                            'Off',
                            'Static',
                            'Sway',
                            'Switch',
                            'Random',
                            'Static Random'
                        }
                    )
                )

                flick_exploit.pitch_label_1 = menu.new(
                    ui.new_label, 'AA', 'Anti-aimbot angles', 'From'
                )

                flick_exploit.pitch_offset_1 = config_system.push(
                    'Features', 'flick_pitch_offset_1', menu.new(
                        ui.new_slider, 'AA', 'Anti-aimbot angles', new_key('\n', 'flick_pitch_offset_1'), -89, 89, 0, true, '°'
                    )
                )

                flick_exploit.pitch_label_2 = menu.new(
                    ui.new_label, 'AA', 'Anti-aimbot angles', 'To'
                )

                flick_exploit.pitch_offset_2 = config_system.push(
                    'Features', 'flick_pitch_offset_2', menu.new(
                        ui.new_slider, 'AA', 'Anti-aimbot angles', new_key('\n', 'flick_pitch_offset_2'), -89, 89, 0, true, '°'
                    )
                )

                flick_exploit.pitch_speed = config_system.push(
                    'Features', 'flick_pitch_speed', menu.new(
                        ui.new_slider, 'AA', 'Anti-aimbot angles', new_key('Speed', 'flick_pitch_speed'), -75, 75, 20, true, nil, 0.1
                    )
                )

                flick_exploit.separator = menu.new(
                    ui.new_label, 'AA', 'Anti-aimbot angles', '\n'
                )

                lock_unselection(flick_exploit.states, {
                    'Slow Walk',
                    'Crouch',
                    'Move-Crouch'
                })

                features.flick_exploit = flick_exploit
            end

            antiaim.features = features
        end

        local hotkeys = { } do
            local edge_yaw = { } do
                edge_yaw.enabled = config_system.push(
                    'Hotkeys', 'edge_yaw.enabled', menu.new(
                        ui.new_checkbox, 'AA', 'Anti-aimbot angles', new_key('Edge yaw', 'edge_yaw')
                    )
                )

                edge_yaw.hotkey = config_system.push(
                    'Hotkeys', 'edge_yaw.hotkey', menu.new(
                        ui.new_hotkey, 'AA', 'Anti-aimbot angles', new_key('Hotkey', 'edge_yaw'), true
                    )
                )

                edge_yaw.disablers = config_system.push(
                    'Hotkeys', 'edge_yaw.disablers', menu.new(
                        ui.new_multiselect, 'AA', 'Anti-aimbot angles', new_key('Disablers', 'edge_yaw'), {
                            'Standing',
                            'Moving',
                            'Slow Walk',
                            'Air',
                            'Crouched'
                        }
                    )
                )

                hotkeys.edge_yaw = edge_yaw
            end

            local freestanding = { } do
                freestanding.enabled = config_system.push(
                    'Hotkeys', 'freestanding.enabled', menu.new(
                        ui.new_checkbox, 'AA', 'Anti-aimbot angles', new_key('Freestanding', 'freestanding')
                    )
                )

                freestanding.hotkey = config_system.push(
                    'Hotkeys', 'freestanding.hotkey', menu.new(
                        ui.new_hotkey, 'AA', 'Anti-aimbot angles', new_key('Hotkey', 'freestanding'), true
                    )
                )

                freestanding.disablers = config_system.push(
                    'Hotkeys', 'freestanding.disablers', menu.new(
                        ui.new_multiselect, 'AA', 'Anti-aimbot angles', new_key('Disablers', 'freestanding'), {
                            'Standing',
                            'Moving',
                            'Slow Walk',
                            'Air',
                            'Crouched'
                        }
                    )
                )

                freestanding.separator = menu.new(
                    ui.new_label, 'AA', 'Anti-aimbot angles', '\n'
                )

                hotkeys.freestanding = freestanding
            end

            local manual_yaw = { } do
                manual_yaw.enabled = config_system.push(
                    'Hotkeys', 'manual_yaw.enabled', menu.new(
                        ui.new_checkbox, 'AA', 'Anti-aimbot angles', new_key('Manual Yaw', 'manual_yaw')
                    )
                )

                manual_yaw.options = config_system.push(
                    'Hotkeys', 'manual_yaw.options', menu.new(
                        ui.new_multiselect, 'AA', 'Anti-aimbot angles', new_key('Options', 'manual_yaw'), {
                            'Disable yaw modifiers',
                            'Freestanding body',
                        }
                    )
                )

                manual_yaw.reset_hotkey = config_system.push(
                    'Hotkeys', 'manual_yaw.reset_hotkey', menu.new(
                        ui.new_hotkey, 'AA', 'Anti-aimbot angles', new_key(
                            'Reset', 'manual_yaw'
                        )
                    )
                )

                manual_yaw.left_hotkey = config_system.push(
                    'Hotkeys', 'manual_yaw.left_hotkey', menu.new(
                        ui.new_hotkey, 'AA', 'Anti-aimbot angles', new_key(
                            'Left', 'manual_yaw'
                        )
                    )
                )

                manual_yaw.right_hotkey = config_system.push(
                    'Hotkeys', 'manual_yaw.right_hotkey', menu.new(
                        ui.new_hotkey, 'AA', 'Anti-aimbot angles', new_key(
                            'Right', 'manual_yaw'
                        )
                    )
                )

                manual_yaw.forward_hotkey = config_system.push(
                    'Hotkeys', 'manual_yaw.forward_hotkey', menu.new(
                        ui.new_hotkey, 'AA', 'Anti-aimbot angles', new_key(
                            'Forward', 'manual_yaw'
                        )
                    )
                )

                manual_yaw.backward_hotkey = config_system.push(
                    'Hotkeys', 'manual_yaw.backward_hotkey', menu.new(
                        ui.new_hotkey, 'AA', 'Anti-aimbot angles', new_key(
                            'Backward', 'manual_yaw'
                        )
                    )
                )

                manual_yaw.manual_arrows = config_system.push(
                    'Hotkeys', 'manual_yaw.manual_arrows', menu.new(
                        ui.new_combobox, 'AA', 'Anti-aimbot angles', new_key('Manual arrows', 'manual_yaw'), {
                            'Off',
                            'Classic',
                            'Modern',
                            'Teamskeet'
                        }
                    )
                )

                manual_yaw.arrows_offset = config_system.push(
                    'Hotkeys', 'manual_yaw.arrows_offset', menu.new(
                        ui.new_slider, 'AA', 'Anti-aimbot angles', new_key('Arrows offset', 'manual_yaw'), 8, 128, 40, true, 'px'
                    )
                )

                manual_yaw.arrows_color = config_system.push(
                    'Hotkeys', 'manual_yaw.arrows_color', menu.new(
                        ui.new_color_picker, 'AA', 'Anti-aimbot angles', new_key('Arrows color', 'manual_yaw'), 175, 255, 55, 255
                    )
                )

                manual_yaw.desync_color = config_system.push(
                    'Hotkeys', 'manual_yaw.desync_color', menu.new(
                        ui.new_color_picker, 'AA', 'Anti-aimbot angles', new_key('Desync color', 'manual_yaw'), 35, 128, 255, 255
                    )
                )

                manual_yaw.separator = menu.new(
                    ui.new_label, 'AA', 'Anti-aimbot angles', '\n'
                )

                manual_yaw.reset_hotkey:set 'On hotkey'

                manual_yaw.left_hotkey:set 'Toggle'
                manual_yaw.right_hotkey:set 'Toggle'
                manual_yaw.forward_hotkey:set 'Toggle'
                manual_yaw.backward_hotkey:set 'Toggle'

                hotkeys.manual_yaw = manual_yaw
            end

            local roll_aa = { } do
                roll_aa.enabled = config_system.push(
                    'Hotkeys', 'roll_aa.enabled', menu.new(
                        ui.new_checkbox, 'AA', 'Anti-aimbot angles', new_key('Roll AA', 'roll_aa')
                    )
                )

                roll_aa.hotkey = config_system.push(
                    'Hotkeys', 'roll_aa.hotkey', menu.new(
                        ui.new_hotkey, 'AA', 'Anti-aimbot angles', new_key('Hotkey', 'roll_aa'), true
                    )
                )

                roll_aa.value = config_system.push(
                    'Hotkeys', 'roll_aa.value', menu.new(
                        ui.new_slider, 'AA', 'Anti-aimbot angles', new_key('Value', 'roll_aa'), -50, 50, 0, true, '°'
                    )
                )

                roll_aa.on_manual_yaw = config_system.push(
                    'Hotkeys', 'roll_aa.on_manual_yaw', menu.new(
                        ui.new_checkbox, 'AA', 'Anti-aimbot angles', new_key('On manual yaw', 'roll_aa')
                    )
                )

                roll_aa.separator = menu.new(
                    ui.new_label, 'AA', 'Anti-aimbot angles', '\n'
                )

                hotkeys.roll_aa = roll_aa
            end

            antiaim.hotkeys = hotkeys
        end

        local fakelag = { } do
            local HOTKEY_MODE = {
                [0] = 'Always on',
                [1] = 'On hotkey',
                [2] = 'Toggle',
                [3] = 'Off hotkey'
            }

            local function get_hotkey_value(_, mode, key)
                return HOTKEY_MODE[mode], key or 0
            end

            fakelag.enabled = menu.new(
                ui.new_checkbox, 'AA', 'Other', new_key('Enabled', 'fakelag')
            )

            fakelag.hotkey = menu.new(
                ui.new_hotkey, 'AA', 'Other', new_key('Hotkey', 'fakelag'), true
            )

            fakelag.amount = menu.new(
                ui.new_combobox, 'AA', 'Other', new_key('Amount', 'fakelag'), {
                    'Dynamic',
                    'Maximum',
                    'Fluctuate'
                }
            )

            fakelag.variance = menu.new(
                ui.new_slider, 'AA', 'Other', new_key('Variance', 'fakelag'), 0, 100, 0, true, '%'
            )

            fakelag.limit = menu.new(
                ui.new_slider, 'AA', 'Other', new_key('Limit', 'fakelag'), 1, 15, 1, true, 't'
            )

            fakelag.enabled:set(ui.get(software.antiaimbot.fake_lag.enabled[1]))
            fakelag.hotkey:set(get_hotkey_value(ui.get(software.antiaimbot.fake_lag.enabled[2])))

            fakelag.amount:set(ui.get(software.antiaimbot.fake_lag.amount))

            fakelag.variance:set(ui.get(software.antiaimbot.fake_lag.variance))
            fakelag.limit:set(ui.get(software.antiaimbot.fake_lag.limit))

            antiaim.fakelag = fakelag
        end

        resource.antiaim = antiaim
    end

    local render = { } do
        local changers = { } do
            local aspect_ratio = { } do
                local tooltips = {
                    [125] = '5:4',
                    [133] = '4:3',
                    [160] = '16:10',
                    [177] = '16:9'
                }

                aspect_ratio.enabled = config_system.push(
                    'Changers', 'aspect_ratio.enabled', menu.new(
                        ui.new_checkbox, 'AA', 'Anti-aimbot angles', new_key('Aspect ratio', 'aspect_ratio')
                    )
                )

                aspect_ratio.value = config_system.push(
                    'Changers', 'aspect_ratio.value', menu.new(
                        ui.new_slider, 'AA', 'Anti-aimbot angles', new_key('\n', 'aspect_ratio'), 0, 200, 133, true, '', 0.01, tooltips
                    )
                )

                aspect_ratio.separator = menu.new(
                    ui.new_label, 'AA', 'Anti-aimbot angles', '\n'
                )

                changers.aspect_ratio = aspect_ratio
            end

            local third_person = { } do
                third_person.enabled = config_system.push(
                    'Changers', 'third_person.enabled', menu.new(
                        ui.new_checkbox, 'AA', 'Anti-aimbot angles', new_key('Third person', 'third_person')
                    )
                )

                third_person.distance = config_system.push(
                    'Changers', 'third_person.distance', menu.new(
                        ui.new_slider, 'AA', 'Anti-aimbot angles', new_key('Distance', 'third_person'), 0, 180, 100
                    )
                )

                third_person.zoom_speed = config_system.push(
                    'Changers', 'third_person.zoom_speed', menu.new(
                        ui.new_slider, 'AA', 'Anti-aimbot angles', new_key('Zoom speed', 'third_person'), 1, 100, 25, true, '%', 1, {
                            [1] = 'None'
                        }
                    )
                )

                third_person.separator = menu.new(
                    ui.new_label, 'AA', 'Anti-aimbot angles', '\n'
                )

                changers.third_person = third_person
            end

            local viewmodel = { } do
                viewmodel.enabled = config_system.push(
                    'Changers', 'viewmodel.enabled', menu.new(
                        ui.new_checkbox, 'AA', 'Anti-aimbot angles', new_key('Viewmodel', 'viewmodel')
                    )
                )

                viewmodel.fov = config_system.push(
                    'Changers', 'viewmodel.fov', menu.new(
                        ui.new_slider, 'AA', 'Anti-aimbot angles', new_key('Field of fov', 'viewmodel'), 0, 1000, 680, true, '°', 0.1
                    )
                )

                viewmodel.offset_x = config_system.push(
                    'Changers', 'viewmodel.offset_x', menu.new(
                        ui.new_slider, 'AA', 'Anti-aimbot angles', new_key('Offset X', 'viewmodel'), -100, 100, 25, true, '', 0.1
                    )
                )

                viewmodel.offset_y = config_system.push(
                    'Changers', 'viewmodel.offset_y', menu.new(
                        ui.new_slider, 'AA', 'Anti-aimbot angles', new_key('Offset Y', 'viewmodel'), -100, 100, 25, true, '', 0.1
                    )
                )

                viewmodel.offset_z = config_system.push(
                    'Changers', 'viewmodel.offset_z', menu.new(
                        ui.new_slider, 'AA', 'Anti-aimbot angles', new_key('Offset Z', 'viewmodel'), -100, 100, 25, true, '', 0.1
                    )
                )

                viewmodel.options = config_system.push(
                    'Changers', 'viewmodel.options', menu.new(
                        ui.new_multiselect, 'AA', 'Anti-aimbot angles', new_key('Options', 'viewmodel'), {
                            'Legacy animation',
                            'Scope down sight',
                            'Viewmodel in scope',
                            'Opposite knife hand'
                        }
                    )
                )

                viewmodel.separator = menu.new(
                    ui.new_label, 'AA', 'Anti-aimbot angles', '\n'
                )

                changers.viewmodel = viewmodel
            end

            local custom_scope = { } do
                custom_scope.enabled = config_system.push(
                    'User interface', 'custom_scope.enabled', menu.new(
                        ui.new_checkbox, 'AA', 'Anti-aimbot angles', new_key('Custom scope', 'custom_scope')
                    )
                )

                custom_scope.color = config_system.push(
                    'User interface', 'custom_scope.color', menu.new(
                        ui.new_color_picker, 'AA', 'Anti-aimbot angles', new_key('Custom scope color', 'custom_scope'), 255, 255, 255, 200
                    )
                )

                custom_scope.style = config_system.push(
                    'User interface', 'custom_scope.style', menu.new(
                        ui.new_combobox, 'AA', 'Anti-aimbot angles', new_key('Style', 'custom_scope'), {
                            'Default',
                            'New'
                        }
                    )
                )

                custom_scope.exclude = config_system.push(
                    'User interface', 'custom_scope.exclude', menu.new(
                        ui.new_multiselect, 'AA', 'Anti-aimbot angles', new_key('Exclude', 'custom_scope'), {
                            'Left',
                            'Right',
                            'Top',
                            'Bottom'
                        }
                    )
                )

                custom_scope.position = config_system.push(
                    'User interface', 'custom_scope.position', menu.new(
                        ui.new_slider, 'AA', 'Anti-aimbot angles', new_key('Position', 'custom_scope'), 0, 500, 105
                    )
                )

                custom_scope.offset = config_system.push(
                    'User interface', 'custom_scope.offset', menu.new(
                        ui.new_slider, 'AA', 'Anti-aimbot angles', new_key('Offset', 'custom_scope'), 0, 500, 10
                    )
                )

                custom_scope.start_fade = config_system.push(
                    'User interface', 'custom_scope.start_fade', menu.new(
                        ui.new_slider, 'AA', 'Anti-aimbot angles', new_key('Start fade', 'custom_scope'), 5, 50, 50, true, '%'
                    )
                )

                custom_scope.animation_speed = config_system.push(
                    'User interface', 'custom_scope.animation_speed', menu.new(
                        ui.new_slider, 'AA', 'Anti-aimbot angles', new_key('Animation speed', 'custom_scope'), 1, 50, 20
                    )
                )

                custom_scope.separator = menu.new(
                    ui.new_label, 'AA', 'Anti-aimbot angles', '\n'
                )

                changers.custom_scope = custom_scope
            end

            local force_second_zoom = { } do
                force_second_zoom.enabled = config_system.push(
                    'Changers', 'force_second_zoom.enabled', menu.new(
                        ui.new_checkbox, 'AA', 'Anti-aimbot angles', new_key('Force second zoom', 'force_second_zoom')
                    )
                )

                force_second_zoom.value = config_system.push(
                    'Changers', 'force_second_zoom.value', menu.new(
                        ui.new_slider, 'AA', 'Anti-aimbot angles', new_key('Second zoom fov', 'force_second_zoom'), 0, 100, 0, true, '%'
                    )
                )

                force_second_zoom.separator = menu.new(
                    ui.new_label, 'AA', 'Anti-aimbot angles', '\n'
                )

                changers.force_second_zoom = force_second_zoom
            end

            local world_modulation = { } do
                world_modulation.enabled = config_system.push(
                    'Changers', 'world_modulation.enabled', menu.new(
                        ui.new_checkbox, 'AA', 'Other', new_key('World modulation', 'world_modulation')
                    )
                )

                world_modulation.wall_color = config_system.push(
                    'Changers', 'world_modulation.wall_color', menu.new(
                        ui.new_checkbox, 'AA', 'Other', new_key('Wall color', 'world_modulation')
                    )
                )

                world_modulation.wall_color_picker = config_system.push(
                    'Changers', 'world_modulation.wall_color_picker', menu.new(
                        ui.new_color_picker, 'AA', 'Other', new_key('Wall color picker', 'world_modulation'), 255, 0, 0, 128
                    )
                )

                world_modulation.bloom = config_system.push(
                    'Changers', 'world_modulation.bloom', menu.new(
                        ui.new_slider, 'AA', 'Other', new_key('Bloom scale', 'world_modulation'), -1, 500, -1, true, nil, 0.01, {
                            [-1] = 'Off'
                        }
                    )
                )

                world_modulation.exposure = config_system.push(
                    'Changers', 'world_modulation.exposure', menu.new(
                        ui.new_slider, 'AA', 'Other', new_key('Auto exposure', 'world_modulation'), -1, 2000, -1, true, nil, 0.001, {
                            [-1] = 'Off'
                        }
                    )
                )

                world_modulation.model_ambient = config_system.push(
                    'Changers', 'world_modulation.model_ambient', menu.new(
                        ui.new_slider, 'AA', 'Other', new_key('Minimum model brightness', 'world_modulation'), 0, 1000, -1, true, nil, 0.01
                    )
                )

                world_modulation.separator = menu.new(
                    ui.new_label, 'AA', 'Other', '\n'
                )

                changers.world_modulation = world_modulation
            end

            local light_modulation = { } do
                light_modulation.enabled = config_system.push(
                    'Changers', 'light_modulation.enabled', menu.new(
                        ui.new_checkbox, 'AA', 'Other', new_key('Light modulation', 'light_modulation')
                    )
                )

                light_modulation.offset_x = config_system.push(
                    'Changers', 'light_modulation.offset_x', menu.new(
                        ui.new_slider, 'AA', 'Other', new_key('Offset X', 'light_modulation'), -180, 180, 2
                    )
                )

                light_modulation.offset_y = config_system.push(
                    'Changers', 'light_modulation.offset_y', menu.new(
                        ui.new_slider, 'AA', 'Other', new_key('Offset Y', 'light_modulation'), -180, 180, 0
                    )
                )

                light_modulation.offset_z = config_system.push(
                    'Changers', 'light_modulation.offset_z', menu.new(
                        ui.new_slider, 'AA', 'Other', new_key('Offset Z', 'light_modulation'), -180, 180, 0
                    )
                )

                light_modulation.separator = menu.new(
                    ui.new_label, 'AA', 'Other', '\n'
                )

                changers.light_modulation = light_modulation
            end

            render.changers = changers
        end

        local user_interface = { } do
            local watermark = { } do
                watermark.select = config_system.push(
                    'User interface', 'watermark.select', menu.new(
                        ui.new_multiselect, 'AA', 'Other', new_key('Watermark', 'watermark'), {
                            'Default',
                            'Simple',
                            'Alternative'
                        }
                    )
                )

                watermark.accent_color = config_system.push(
                    'User interface', 'watermark.accent_color', menu.new(
                        ui.new_color_picker, 'AA', 'Other', new_key('Watermark accent color', 'watermark'), 255, 255, 255, 255
                    )
                )

                watermark.secondary_color = config_system.push(
                    'User interface', 'watermark.secondary_color', menu.new(
                        ui.new_color_picker, 'AA', 'Other', new_key('Watermark secondary color', 'watermark'), 50, 50, 50, 255
                    )
                )

                watermark.font = config_system.push(
                    'User interface', 'watermark.font', menu.new(
                        ui.new_combobox, 'AA', 'Other', new_key('Font', 'watermark'), {
                            'Default',
                            'Small',
                            'Bold'
                        }
                    )
                )

                watermark.removals = config_system.push(
                    'User interface', 'watermark.removals', menu.new(
                        ui.new_multiselect, 'AA', 'Other', new_key('Removals', 'watermark'), {
                            'Animation',
                            'Arrows'
                        }
                    )
                )

                watermark.text_input = config_system.push(
                    'User interface', 'watermark.text_input', menu.new(
                        ui.new_textbox, 'AA', 'Other', new_key('Custom text', 'watermark')
                    )
                )

                watermark.display = config_system.push(
                    'User interface', 'watermark.display', menu.new(
                        ui.new_multiselect, 'AA', 'Other', new_key('Display', 'watermark'), {
                            'Logo',
                            'Username',
                            'FPS',
                            'Frametime variance',
                            'Ping',
                            'Speed',
                            'K/D ratio',
                            'Clock'
                        }
                    )
                )

                watermark.position = config_system.push(
                    'User interface', 'watermark.position', menu.new(
                        ui.new_combobox, 'AA', 'Other', new_key('Position', 'watermark'), {
                            'Top-right',
                            'Bottom-center'
                        }
                    )
                )

                watermark.separator = menu.new(
                    ui.new_label, 'AA', 'Other', '\n'
                )

                lock_unselection(watermark.select, {
                    'Default'
                })

                lock_unselection(watermark.display, {
                    'Logo',
                    'FPS',
                    'Frametime variance',
                    'Ping'
                })

                user_interface.watermark = watermark
            end

            local keybinds = { } do
                keybinds.enabled = config_system.push(
                    'User interface', 'keybinds.enabled', menu.new(
                        ui.new_checkbox, 'AA', 'Other', new_key('Keybinds', 'keybinds')
                    )
                )

                keybinds.style = config_system.push(
                    'User interface', 'keybinds.style', menu.new(
                        ui.new_combobox, 'AA', 'Other', new_key('Style', 'keybinds'), {
                            'Fade',
                            'Astolfo'
                        }
                    )
                )

                keybinds.select = config_system.push(
                    'User interface', 'keybinds.select', menu.new(
                        ui.new_multiselect, 'AA', 'Other', new_key('Select', 'keybinds'), {
                            'Auto peek',
                            'Fake duck',
                            'Double tap',
                            'Hide shots',
                            'Force body aim',
                            'Force safe points',
                            'Damage override',
                            'Hitchance override'
                        }
                    )
                )

                keybinds.accent_label = menu.new(
                    ui.new_label, 'AA', 'Other', new_key('Accent color', 'keybinds')
                )

                keybinds.accent_color = config_system.push(
                    'User interface', 'keybinds.accent_color', menu.new(
                        ui.new_color_picker, 'AA', 'Other', new_key('Accent color picker', 'keybinds'), 140, 240, 240, 255
                    )
                )

                keybinds.secondary_label = menu.new(
                    ui.new_label, 'AA', 'Other', new_key('Secondary color', 'keybinds')
                )

                keybinds.secondary_color = config_system.push(
                    'User interface', 'keybinds.color', menu.new(
                        ui.new_color_picker, 'AA', 'Other', new_key('Secondary color picker', 'keybinds'), 140, 240, 240, 200
                    )
                )

                keybinds.separator = menu.new(
                    ui.new_label, 'AA', 'Other', '\n'
                )

                lock_unselection(keybinds.select)

                user_interface.keybinds = keybinds
            end

            local flags_indicator = { } do
                flags_indicator.enabled = config_system.push(
                    'User interface', 'flags_indicator.enabled', menu.new(
                        ui.new_checkbox, 'AA', 'Other', new_key('Flags indicator', 'flags_indicator')
                    )
                )

                flags_indicator.style = config_system.push(
                    'User interface', 'flags_indicator.style', menu.new(
                        ui.new_combobox, 'AA', 'Other', new_key('Style', 'flags_indicator'), {
                            'Fade',
                            'Astolfo'
                        }
                    )
                )

                flags_indicator.select = config_system.push(
                    'User interface', 'flags_indicator.select', menu.new(
                        ui.new_multiselect, 'AA', 'Other', new_key('Select', 'flags_indicator'), {
                            'Fake yaw',
                            'Fakelag',
                            'Exploits',
                            'Inaccuracy',
                            'Stand height'
                        }
                    )
                )

                flags_indicator.accent_label = menu.new(
                    ui.new_label, 'AA', 'Other', new_key('Accent color', 'flags_indicator')
                )

                flags_indicator.accent_color = config_system.push(
                    'User interface', 'flags_indicator.accent_color', menu.new(
                        ui.new_color_picker, 'AA', 'Other', new_key('Accent color picker', 'flags_indicator'), 140, 240, 240, 255
                    )
                )

                flags_indicator.secondary_label = menu.new(
                    ui.new_label, 'AA', 'Other', new_key('Secondary color', 'flags_indicator')
                )

                flags_indicator.secondary_color = config_system.push(
                    'User interface', 'flags_indicator.color', menu.new(
                        ui.new_color_picker, 'AA', 'Other', new_key('Secondary color picker', 'flags_indicator'), 140, 240, 240, 200
                    )
                )

                flags_indicator.separator = menu.new(
                    ui.new_label, 'AA', 'Other', '\n'
                )

                lock_unselection(flags_indicator.select)

                user_interface.flags_indicator = flags_indicator
            end

            local indicators = { } do
                indicators.enabled = config_system.push(
                    'User interface', 'indicators.enabled', menu.new(
                        ui.new_checkbox, 'AA', 'Anti-aimbot angles', new_key('Indicators', 'indicators')
                    )
                )

                indicators.style = config_system.push(
                    'User interface', 'indicators.style', menu.new(
                        ui.new_combobox, 'AA', 'Anti-aimbot angles', new_key('Style', 'indicators'), {
                            'Default',
                            'Astolfo'
                        }
                    )
                )

                indicators.select = config_system.push(
                    'User interface', 'indicators.select', menu.new(
                        ui.new_multiselect, 'AA', 'Anti-aimbot angles', new_key('Select', 'indicators'), {
                            'Stars',
                            'State',
                            'Double tap',
                            'Hide shots',
                            'Body aim',
                            'Hitchance'
                        }
                    )
                )

                indicators.offset = config_system.push(
                    'User interface', 'indicators.offset', menu.new(
                        ui.new_slider, 'AA', 'Anti-aimbot angles', new_key('Offset', 'indicators'), 5, 60, 25, true, 'px'
                    )
                )

                indicators.accent_label = menu.new(
                    ui.new_label, 'AA', 'Anti-aimbot angles', new_key('Accent color', 'indicators')
                )

                indicators.accent_color = config_system.push(
                    'User interface', 'indicators.accent_color', menu.new(
                        ui.new_color_picker, 'AA', 'Anti-aimbot angles', new_key('Accent color picker', 'indicators'), 255, 255, 255, 255
                    )
                )

                indicators.secondary_label = menu.new(
                    ui.new_label, 'AA', 'Anti-aimbot angles', new_key('Secondary color', 'indicators')
                )

                indicators.secondary_color = config_system.push(
                    'User interface', 'indicators.secondary_color', menu.new(
                        ui.new_color_picker, 'AA', 'Anti-aimbot angles', new_key('Secondary color picker', 'indicators'), 50, 50, 50, 255
                    )
                )

                indicators.separator = menu.new(
                    ui.new_label, 'AA', 'Anti-aimbot angles', '\n'
                )

                user_interface.indicators = indicators
            end

            local net_graphic = { } do
                net_graphic.enabled = config_system.push(
                    'User interface', 'net_graphic.enabled', menu.new(
                        ui.new_checkbox, 'AA', 'Anti-aimbot angles', new_key('Net graphic', 'net_graphic')
                    )
                )

                net_graphic.color = config_system.push(
                    'User interface', 'net_graphic.color', menu.new(
                        ui.new_color_picker, 'AA', 'Anti-aimbot angles', new_key('Net graphic color', 'net_graphic'), 0.9 * 255, 0.9 * 255, 0.7 * 255, 255
                    )
                )

                net_graphic.font = config_system.push(
                    'User interface', 'net_graphic.font', menu.new(
                        ui.new_combobox, 'AA', 'Anti-aimbot angles', new_key('Font', 'net_graphic'), {
                            'Default',
                            'Small',
                            'Bold'
                        }
                    )
                )

                net_graphic.display = config_system.push(
                    'User interface', 'net_graphic.display', menu.new(
                        ui.new_multiselect, 'AA', 'Anti-aimbot angles', new_key('Display', 'net_graphic'), {
                            'Framerate',
                            'Connection',
                            'Server response'
                        }
                    )
                )

                net_graphic.offset = config_system.push(
                    'User interface', 'net_graphic.offset', menu.new(
                        ui.new_slider, 'AA', 'Anti-aimbot angles', new_key('Offset', 'net_graphic'), 0, 100, 66, true, '%'
                    )
                )

                net_graphic.separator = menu.new(
                    ui.new_label, 'AA', 'Anti-aimbot angles', '\n'
                )

                lock_unselection(net_graphic.display)

                user_interface.net_graphic = net_graphic
            end

            local console_color = { } do
                console_color.enabled = config_system.push(
                    'visuals', 'console_color.enabled', menu.new(
                        ui.new_checkbox, 'AA', 'Anti-aimbot angles', new_key('Console color', 'console_color')
                    )
                )

                console_color.color = config_system.push(
                    'visuals', 'console_color.color', menu.new(
                        ui.new_color_picker, 'AA', 'Anti-aimbot angles', new_key('Console color picker', 'console_color'), 170, 170, 170, 200
                    )
                )

                user_interface.console_color = console_color
            end

            local damage_indicator = { } do
                damage_indicator.enabled = config_system.push(
                    'User interface', 'damage_indicator.enabled', menu.new(
                        ui.new_checkbox, 'AA', 'Anti-aimbot angles', new_key('Damage indicator', 'damage_indicator')
                    )
                )

                damage_indicator.only_if_active = config_system.push(
                    'User interface', 'damage_indicator.only_if_active', menu.new(
                        ui.new_checkbox, 'AA', 'Anti-aimbot angles', new_key('Only if active', 'damage_indicator')
                    )
                )

                damage_indicator.font = config_system.push(
                    'User interface', 'damage_indicator.font', menu.new(
                        ui.new_combobox, 'AA', 'Anti-aimbot angles', new_key('Font', 'damage_indicator'), {
                            'Default',
                            'Small',
                            'Bold'
                        }
                    )
                )

                damage_indicator.offset = config_system.push(
                    'User interface', 'damage_indicator.offset', menu.new(
                        ui.new_slider, 'AA', 'Anti-aimbot angles', new_key('Offset', 'damage_indicator'), 1, 24, 8, true, 'px'
                    )
                )

                damage_indicator.active_label = menu.new(
                    ui.new_label, 'AA', 'Anti-aimbot angles', new_key('Active color', 'damage_indicator')
                )

                damage_indicator.active_color = config_system.push(
                    'User interface', 'damage_indicator.active_color', menu.new(
                        ui.new_color_picker, 'AA', 'Anti-aimbot angles', new_key('Active color picker', 'damage_indicator'), 255, 255, 255, 255
                    )
                )

                damage_indicator.inactive_label = menu.new(
                    ui.new_label, 'AA', 'Anti-aimbot angles', new_key('Inactive color', 'damage_indicator')
                )

                damage_indicator.inactive_color = config_system.push(
                    'User interface', 'damage_indicator.inactive_color', menu.new(
                        ui.new_color_picker, 'AA', 'Anti-aimbot angles', new_key('Inactive color picker', 'damage_indicator'), 255, 255, 255, 150
                    )
                )

                damage_indicator.separator = menu.new(
                    ui.new_label, 'AA', 'Anti-aimbot angles', '\n'
                )

                user_interface.damage_indicator = damage_indicator
            end

            render.user_interface = user_interface
        end

        local hit_markers = { } do
            local damage_marker = { } do
                damage_marker.enabled = config_system.push(
                    'Hit markers', 'damage_marker.enabled', menu.new(
                        ui.new_checkbox, 'AA', 'Anti-aimbot angles', new_key('Damage marker', 'damage_marker')
                    )
                )

                damage_marker.font = config_system.push(
                    'Hit markers', 'damage_marker.font', menu.new(
                        ui.new_combobox, 'AA', 'Anti-aimbot angles', new_key('Font', 'damage_marker'), {
                            'Default',
                            'Bold'
                        }
                    )
                )

                damage_marker.body_label = menu.new(
                    ui.new_label, 'AA', 'Anti-aimbot angles', new_key('Body color', 'damage_marker')
                )

                damage_marker.body_color = config_system.push(
                    'Hit markers', 'damage_marker.body_color', menu.new(
                        ui.new_color_picker, 'AA', 'Anti-aimbot angles', new_key('Body color picker', 'damage_marker'), 255, 255, 255, 255
                    )
                )

                damage_marker.head_label = menu.new(
                    ui.new_label, 'AA', 'Anti-aimbot angles', new_key('Head color', 'damage_marker')
                )

                damage_marker.head_color = config_system.push(
                    'Hit markers', 'damage_marker.head_color', menu.new(
                        ui.new_color_picker, 'AA', 'Anti-aimbot angles', new_key('Head color picker', 'damage_marker'), 150, 185, 5, 255
                    )
                )

                damage_marker.mismatch_label = menu.new(
                    ui.new_label, 'AA', 'Anti-aimbot angles', new_key('Mismatch color', 'damage_marker')
                )

                damage_marker.mismatch_color = config_system.push(
                    'Hit markers', 'damage_marker.mismatch_color', menu.new(
                        ui.new_color_picker, 'AA', 'Anti-aimbot angles', new_key('Mismatch color picker', 'damage_marker'), 255, 0, 0, 255
                    )
                )

                damage_marker.speed = config_system.push(
                    'Hit markers', 'damage_marker.speed', menu.new(
                        ui.new_slider, 'AA', 'Anti-aimbot angles', new_key('Speed', 'damage_marker'), 0, 128, 58, true, ''
                    )
                )

                damage_marker.duration = config_system.push(
                    'Hit markers', 'damage_marker.duration', menu.new(
                        ui.new_slider, 'AA', 'Anti-aimbot angles', new_key('Duration', 'damage_marker'), 1, 8, 4, true, 's'
                    )
                )

                hit_markers.damage_marker = damage_marker
            end

            local screen_marker = { } do
                screen_marker.enabled = config_system.push(
                    'Hit markers', 'screen_marker.enabled', menu.new(
                        ui.new_checkbox, 'AA', 'Anti-aimbot angles', new_key('Screen marker', 'screen_marker')
                    )
                )

                screen_marker.color = config_system.push(
                    'Hit markers', 'screen_marker.color', menu.new(
                        ui.new_color_picker, 'AA', 'Anti-aimbot angles', new_key('Screen marker color', 'screen_marker'), 255, 255, 255, 200
                    )
                )

                hit_markers.screen_marker = screen_marker
            end

            local world_marker = { } do
                world_marker.enabled = config_system.push(
                    'Hit markers', 'world_marker.enabled', menu.new(
                        ui.new_checkbox, 'AA', 'Anti-aimbot angles', new_key('World marker', 'world_marker')
                    )
                )

                world_marker.horizontal_label = menu.new(
                    ui.new_label, 'AA', 'Anti-aimbot angles', new_key('Horizontal color', 'world_marker')
                )

                world_marker.horizontal_color = config_system.push(
                    'Hit markers', 'world_marker.horizontal_color', menu.new(
                        ui.new_color_picker, 'AA', 'Anti-aimbot angles', new_key('Horizontal color picker', 'world_marker'), 0, 255, 0, 255
                    )
                )

                world_marker.vertical_label = menu.new(
                    ui.new_label, 'AA', 'Anti-aimbot angles', new_key('Vertical color', 'world_marker')
                )

                world_marker.vertical_color = config_system.push(
                    'Hit markers', 'world_marker.vertical_color', menu.new(
                        ui.new_color_picker, 'AA', 'Anti-aimbot angles', new_key('Vertical color picker', 'world_marker'), 0, 255, 255, 255
                    )
                )

                world_marker.size = config_system.push(
                    'Hit markers', 'world_marker.size', menu.new(
                        ui.new_slider, 'AA', 'Anti-aimbot angles', new_key('Size', 'world_marker'), 2, 5, 4, true, 'px'
                    )
                )

                world_marker.thickness = config_system.push(
                    'Hit markers', 'world_marker.thickness', menu.new(
                        ui.new_slider, 'AA', 'Anti-aimbot angles', new_key('Thickness', 'world_marker'), 1, 5, 2, true, 'px'
                    )
                )

                hit_markers.world_marker = world_marker
            end

            local hitsound = { } do
                local sound_list do
                    sound_list = {
                        'Arena switch',
                        'Wood stop',
                        'Wood plank',
                        'Wood strain'
                    }

                    local new_int_array = ffi.typeof 'int[?]'
                    local new_char_array = ffi.typeof 'char[?]'

                    local function get_sound_directory()
                        local buffer = new_char_array(128)
                        ifilesystem.current_directory(buffer, 128)

                        local dir = ffi.string(buffer)
                        return string.format('%s\\csgo\\sound', dir)
                    end

                    local function add_sounds_to_list(path_id, list)
                        local handle = new_int_array(1)

                        local file = ifilesystem.find_first_ex('*', path_id, handle)

                        while file ~= nil do
                            local filename = ffi.string(file)

                            local is_file_sound = (
                                not ifilesystem.find_is_directory(handle[0])
                                and filename:sub(-4) == '.wav'
                            )

                            if is_file_sound then
                                table.insert(sound_list, filename:sub(1, -5))
                            end

                            file = ifilesystem.find_next(handle[0])
                        end

                        ifilesystem.find_close(handle[0])
                    end

                    local path_id = 'HITSSOUND'
                    local path_dir = get_sound_directory()

                    ifilesystem.add_search_path(path_dir, path_id, 0)
                    add_sounds_to_list(path_id, sound_list)

                    ifilesystem.remove_search_path(path_dir, path_id)
                end

                hitsound.enabled = config_system.push(
                    'Miscellaneous', 'hitsound.enabled', menu.new(
                        ui.new_checkbox, 'AA', 'Other', new_key('Hitsound', 'hitsound')
                    )
                )

                hitsound.body_sound = config_system.push(
                    'Miscellaneous', 'hitsound.body_sound', menu.new(
                        ui.new_combobox, 'AA', 'Other', new_key('Body sound', 'hitsound'), {
                            'Off', unpack(sound_list)
                        }
                    )
                )

                hitsound.head_sound = config_system.push(
                    'Miscellaneous', 'hitsound.head_sound', menu.new(
                        ui.new_combobox, 'AA', 'Other', new_key('Head sound', 'hitsound'), {
                            'Off', unpack(sound_list)
                        }
                    )
                )

                hitsound.volume = config_system.push(
                    'Miscellaneous', 'hitsound.volume', menu.new(
                        ui.new_slider, 'AA', 'Other', new_key('Volume', 'hitsound'), 1, 100, 100, true, '%'
                    )
                )

                hit_markers.hitsound = hitsound
            end

            render.hit_markers = hit_markers
        end

        resource.render = render
    end

    local config = { } do
        config.categories = new_selector_item(
            'AA', 'Anti-aimbot angles', '\n config.categories', {
                {
                    'Main', {
                        'Ragebot',
                        'Miscellaneous',
                        'Animations',
                        'Logging system',
                        'Automatic purchase'
                    }
                },

                {
                    'Anti-Aim', {
                        'Builder',
                        'Features',
                        'Hotkeys'
                    }
                },

                {
                    'Render', {
                        'Changers',
                        'User interface',
                        'Hit markers'
                    }
                }
            }
        )

        config.list = menu.new(
            ui.new_listbox, 'AA', 'Anti-aimbot angles', '\n config.list', { }
        )

        config.input = menu.new(
            ui.new_textbox, 'AA', 'Anti-aimbot angles', '\n config.input', ''
        )

        config.load_button = menu.new(
            ui.new_button, 'AA', 'Anti-aimbot angles', 'Load', nil
        )

        config.save_button = menu.new(
            ui.new_button, 'AA', 'Anti-aimbot angles', 'Save', nil
        )

        config.delete_button = menu.new(
            ui.new_button, 'AA', 'Anti-aimbot angles', 'Delete', nil
        )

        config.export_button = menu.new(
            ui.new_button, 'AA', 'Anti-aimbot angles', 'Export to clipboard', nil
        )

        config.import_button = menu.new(
            ui.new_button, 'AA', 'Anti-aimbot angles', 'Import from clipboard', nil
        )

        lock_unselection(config.categories)

        resource.config = config
    end

    local scene do
        local function set_antiaimbot_display(value)
            local items = software.antiaimbot.angles

            local pitch_value = ui.get(items.pitch[1])
            local yaw_value = ui.get(items.yaw[1])
            local body_yaw_value = ui.get(items.body_yaw[1])

            local force = not value

            ui.set_visible(items.enabled, value)
            ui.set_visible(items.pitch[1], value)

            if pitch_value == 'Custom' or force then
                ui.set_visible(items.pitch[2], value)
            end

            ui.set_visible(items.yaw_base, value)
            ui.set_visible(items.yaw[1], value)

            if yaw_value ~= 'Off' or force then
                local yaw_jitter_value = ui.get(items.yaw_jitter[1])

                ui.set_visible(items.yaw[2], value)
                ui.set_visible(items.yaw_jitter[1], value)

                if yaw_jitter_value ~= 'Off' or force then
                    ui.set_visible(items.yaw_jitter[2], value)
                end
            end

            ui.set_visible(items.body_yaw[1], value)

            if body_yaw_value ~= 'Off' or force then
                if body_yaw_value ~= 'Opposite' or force then
                    ui.set_visible(items.body_yaw[2], value)
                end

                ui.set_visible(items.freestanding_body_yaw, value)
            end

            ui.set_visible(items.edge_yaw, value)

            ui.set_visible(items.freestanding[1], value)
            ui.set_visible(items.freestanding[2], value)

            ui.set_visible(items.roll, value)
        end

        local function set_fakelag_display(value)
            local items = software.antiaimbot.fake_lag

            ui.set_visible(items.enabled[1], value)
            ui.set_visible(items.enabled[2], value)

            ui.set_visible(items.amount, value)
            ui.set_visible(items.limit, value)
            ui.set_visible(items.variance, value)
        end

        local function set_other_display(value)
            local items = software.antiaimbot.other

            ui.set_visible(items.slow_motion[1], value)
            ui.set_visible(items.slow_motion[2], value)

            ui.set_visible(items.leg_movement, value)

            ui.set_visible(items.on_shot_antiaim[1], value)
            ui.set_visible(items.on_shot_antiaim[2], value)

            ui.set_visible(items.fake_peek[1], value)
            ui.set_visible(items.fake_peek[2], value)
        end

        local function update_builder_items(items)
            local angles = items.angles
            local defensive = items.defensive

            if items.separator ~= nil then
                menu_logic.set(items.separator, true)
            end

            if items.send_to_another_team ~= nil then
                menu_logic.set(items.send_to_another_team, true)
            end

            if angles ~= nil then
                if angles.enabled ~= nil then
                    menu_logic.set(angles.enabled, true)

                    if not angles.enabled:get() then
                        return
                    end
                end

                if angles.bomb_e_fix ~= nil then
                    menu_logic.set(angles.bomb_e_fix, true)
                end

                if angles.yaw_base ~= nil then
                    menu_logic.set(angles.yaw_base, true)
                end

                if angles.yaw_left ~= nil and angles.yaw_right ~= nil then
                    local is_general_yaw = true

                    if angles.yaw_direction ~= nil then
                        local dir = angles.yaw_direction:get()
                        menu_logic.set(angles.yaw_direction, true)

                        if dir ~= 'General' then
                            is_general_yaw = false
                        end

                        local item_enable = angles['enabled_dir_' .. dir]

                        if item_enable == nil then
                            goto continue
                        end

                        menu_logic.set(item_enable, true)

                        if not item_enable:get() then
                            goto continue
                        end

                        local item_left = angles['yaw_left_dir_' .. dir]
                        local item_right = angles['yaw_right_dir_' .. dir]

                        if item_left ~= nil then
                            menu_logic.set(item_left, true)
                        end

                        if item_right ~= nil then
                            menu_logic.set(item_right, true)
                        end

                        ::continue::
                    end

                    if is_general_yaw then
                        menu_logic.set(angles.yaw_left, true)
                        menu_logic.set(angles.yaw_right, true)
                        menu_logic.set(angles.yaw_random, true)
                    end

                    menu_logic.set(angles.yaw_jitter, true)

                    if angles.yaw_jitter:get() ~= 'Off' then
                        menu_logic.set(angles.jitter_offset, true)
                        menu_logic.set(angles.jitter_random, true)
                    end
                end

                menu_logic.set(angles.body_yaw, true)

                if angles.body_yaw:get() ~= 'Off' then
                    if angles.body_yaw:get() ~= 'Opposite' then
                        menu_logic.set(angles.body_yaw_offset, true)
                    end

                    local is_jitter = (
                        angles.body_yaw:get() == 'Jitter'
                        or angles.body_yaw:get() == 'Jitter Random'
                    )

                    if is_jitter then
                        menu_logic.set(angles.delay_from, true)
                        menu_logic.set(angles.delay_to, true)
                    else
                        menu_logic.set(angles.freestanding_body_yaw, true)
                    end
                end
            end

            if items.separator_1 ~= nil then
                menu_logic.set(items.separator_1, true)
            end

            if defensive ~= nil then
                if defensive.force_defensive ~= nil then
                    menu_logic.set(defensive.force_defensive, true)
                end

                menu_logic.set(defensive.enabled, true)

                if defensive.enabled:get() then
                    menu_logic.set(defensive.pitch, true)

                    if defensive.pitch:get() ~= 'Off' then
                        menu_logic.set(defensive.pitch_offset_1, true)

                        if defensive.pitch:get() ~= 'Static' then
                            menu_logic.set(defensive.pitch_label_1, true)
                            menu_logic.set(defensive.pitch_label_2, true)

                            menu_logic.set(defensive.pitch_offset_2, true)
                        end

                        if defensive.pitch:get() == 'Sway' then
                            menu_logic.set(defensive.pitch_speed, true)
                        end
                    end

                    menu_logic.set(defensive.yaw, true)

                    if defensive.yaw:get() ~= 'Off' then
                        local yaw = defensive.yaw:get()

                        local have_limits = (
                            yaw == 'Sway' or
                            yaw == 'Left/Right' or
                            yaw == 'Static Random'
                        )

                        local have_speed = (
                            yaw == 'Sway'
                        )

                        if yaw == 'X-Way' then
                            menu_logic.set(defensive.ways_count, true)
                            menu_logic.set(defensive.ways_custom, true)

                            if defensive.ways_custom:get() then
                                local ways_count = defensive.ways_count:get()
                                menu_logic.set(defensive.ways_count, true)

                                for i = 1, ways_count do
                                    menu_logic.set(defensive['way_' .. i], true)
                                end
                            else
                                menu_logic.set(defensive.yaw_offset, true)
                            end

                            menu_logic.set(defensive.ways_auto_body_yaw, true)
                        else
                            if have_limits then
                                menu_logic.set(defensive.yaw_left, true)
                                menu_logic.set(defensive.yaw_right, true)
                            else
                                menu_logic.set(defensive.yaw_offset, true)
                            end

                            if have_speed then
                                menu_logic.set(defensive.yaw_speed, true)
                            end
                        end
                    end

                    menu_logic.set(defensive.body_yaw, true)

                    if defensive.body_yaw:get() ~= 'Off' then
                        if defensive.body_yaw:get() ~= 'Opposite' then
                            menu_logic.set(defensive.body_yaw_offset, true)
                        end

                        local is_jitter = (
                            defensive.body_yaw:get() == 'Jitter'
                            or defensive.body_yaw:get() == 'Jitter Random'
                        )

                        if is_jitter then
                            menu_logic.set(defensive.delay_from, true)
                            menu_logic.set(defensive.delay_to, true)
                        else
                            menu_logic.set(defensive.freestanding_body_yaw, true)
                        end
                    end
                end
            end
        end

        local function force_update_scene()
            menu_logic.set(general.script_name, true)
            menu_logic.set(general.script_user, true)

            local category = general.category:get()
            menu_logic.set(general.category, true)

            -- Ragebot
            if category == 0 then
                local ref = resource.main.ragebot

                local is_force_body_conditions = ref.force_body_conditions.enabled:get() do
                    menu_logic.set(ref.force_body_conditions.enabled, true)

                    if not is_force_body_conditions then
                        goto continue
                    end

                    menu_logic.set(ref.force_body_conditions.separator, true)

                    menu_logic.set(ref.force_body_conditions.weapons, true)
                    menu_logic.set(ref.force_body_conditions.conditions, true)

                    if ref.force_body_conditions.conditions:get 'Max misses' then
                        menu_logic.set(ref.force_body_conditions.max_misses, true)

                        if ref.force_body_conditions.weapons:get 'Scout' then
                            menu_logic.set(ref.force_body_conditions.scout_damage, true)
                        end
                    end

                    menu_logic.set(ref.force_body_conditions.disabler, true)

                    ::continue::
                end

                local is_force_lethal = ref.force_lethal.enabled:get() do
                    menu_logic.set(ref.force_lethal.enabled, true)

                    if not is_force_lethal then
                        goto continue
                    end

                    menu_logic.set(ref.force_lethal.mode, true)

                    local weapons = ref.force_lethal.weapons:get()
                    menu_logic.set(ref.force_lethal.weapons, true)

                    for i = 1, #weapons do
                        local weapon = weapons[i]

                        local items = ref.force_lethal[weapon]

                        if items ~= nil then
                            menu_logic.set(items.hitchance, true)
                        end
                    end

                    menu_logic.set(ref.force_lethal.separator, true)

                    ::continue::
                end

                local is_auto_hide_shots = ref.auto_hide_shots.enabled:get() do
                    menu_logic.set(ref.auto_hide_shots.enabled, true)

                    if not is_auto_hide_shots then
                        goto continue
                    end

                    menu_logic.set(ref.auto_hide_shots.weapons, true)
                    menu_logic.set(ref.auto_hide_shots.states, true)

                    menu_logic.set(ref.auto_hide_shots.separator, true)

                    ::continue::
                end

                local is_hitchance = ref.hitchance.enabled:get() do
                    menu_logic.set(ref.hitchance.enabled, true)

                    if not is_hitchance then
                        goto continue
                    end

                    menu_logic.set(ref.hitchance.separator, true)

                    local weapon = ref.hitchance.weapon:get()
                    menu_logic.set(ref.hitchance.weapon, true)

                    local items = ref.hitchance[weapon]

                    if items == nil then
                        goto continue
                    end

                    local options = items.options:get()
                    menu_logic.set(items.options, true)

                    for i = 1, #options do
                        local option = options[i]
                        local option_items = items[option]

                        if option_items ~= nil then
                            menu_logic.set(option_items.value, true)

                            if option_items.distance ~= nil then
                                menu_logic.set(option_items.distance, true)
                            end
                        end
                    end

                    if items.options:get 'Hotkey' then
                        menu_logic.set(ref.hitchance.hotkey, true)
                        menu_logic.set(ref.hitchance.indicator_text, true)
                    end

                    ::continue::
                end

                local is_quick_peek_auto_stop = ref.quick_peek_auto_stop.enabled:get() do
                    menu_logic.set(ref.quick_peek_auto_stop.enabled, true)

                    if not is_quick_peek_auto_stop then
                        goto continue
                    end

                    menu_logic.set(ref.quick_peek_auto_stop.separator, true)

                    local weapon = ref.quick_peek_auto_stop.weapon:get()
                    menu_logic.set(ref.quick_peek_auto_stop.weapon, true)

                    local items = ref.quick_peek_auto_stop[weapon]

                    if items == nil then
                        goto continue
                    end

                    menu_logic.set(items.enabled, true)

                    if not items.enabled:get() then
                        goto continue
                    end

                    menu_logic.set(items.auto_stop, true)

                    ::continue::
                end

                menu_logic.set(ref.allow_duck_on_fd.enabled, true)
                menu_logic.set(ref.unsafe_recharge.enabled, true)
                menu_logic.set(ref.hideshots_fix.enabled, true)
            end

            -- Miscellaneous
            if category == 1 then
                local ref = resource.main.miscellaneous

                local is_drop_nades = ref.drop_nades.enabled:get() do
                    menu_logic.set(ref.drop_nades.enabled, true)
                    menu_logic.set(ref.drop_nades.hotkey, true)

                    if not is_drop_nades then
                        goto continue
                    end

                    menu_logic.set(ref.drop_nades.select, true)

                    menu_logic.set(ref.drop_nades.separator, true)

                    ::continue::
                end

                local is_enhance_grenade_release = ref.enhance_grenade_release.enabled:get() do
                    menu_logic.set(ref.enhance_grenade_release.enabled, true)

                    if not is_enhance_grenade_release then
                        goto continue
                    end

                    menu_logic.set(ref.enhance_grenade_release.disablers, true)
                    menu_logic.set(ref.enhance_grenade_release.only_with_dt, true)

                    menu_logic.set(ref.enhance_grenade_release.separator, true)

                    ::continue::
                end

                local is_fps_optimize = ref.fps_optimize.enabled:get() do
                    menu_logic.set(ref.fps_optimize.enabled, true)

                    if not is_fps_optimize then
                        goto continue
                    end

                    menu_logic.set(ref.fps_optimize.always_on, true)

                    if not ref.fps_optimize.always_on:get() then
                        menu_logic.set(ref.fps_optimize.detections, true)
                    end

                    menu_logic.set(ref.fps_optimize.list, true)

                    menu_logic.set(ref.fps_optimize.separator, true)

                    ::continue::
                end

                local is_trashtalk = ref.trash_talk.enabled:get() do
                    menu_logic.set(ref.trash_talk.enabled, true)

                    if not is_trashtalk then
                        goto continue
                    end

                    menu_logic.set(ref.trash_talk.disable_on_warmup, true)
                    menu_logic.set(ref.trash_talk.triggers, true)

                    menu_logic.set(ref.trash_talk.tooltip, true)
                    menu_logic.set(ref.trash_talk.separator, true)

                    ::continue::
                end

                local is_clantag = ref.clantag.enabled:get() do
                    menu_logic.set(ref.clantag.enabled, true)

                    if not is_clantag then
                        goto continue
                    end

                    menu_logic.set(ref.clantag.text, true)

                    if ref.clantag.text:get() == 'Aesthetic' then
                        menu_logic.set(ref.clantag.tooltip, true)
                    end

                    if ref.clantag.text:get() == 'Custom' then
                        menu_logic.set(ref.clantag.mode, true)

                        if ref.clantag.mode:get() ~= 'Reversed' then
                            menu_logic.set(ref.clantag.input, true)
                        end

                        if ref.clantag.mode:get() == 'Animated' then
                            menu_logic.set(ref.clantag.speed, true)
                        end
                    end

                    ::continue::
                end

                menu_logic.set(ref.fast_ladder.enabled, true)
                menu_logic.set(ref.console_filter.enabled, true)
                menu_logic.set(ref.sync_ragebot_hotkeys.enabled, true)
                menu_logic.set(ref.reveal_enemy_team_chat.enabled, true)
            end

            -- Animations
            if category == 2 then
                local ref = resource.main.animations

                menu_logic.set(ref.air_legs, true)

                if ref.air_legs:get() == 'Static' then
                    menu_logic.set(ref.air_legs_weight, true)
                end

                menu_logic.set(ref.ground_legs, true)

                local has_offset = (
                    ref.ground_legs:get() == 'Jitter'
                    or ref.ground_legs:get() == 'Pacan4ik'
                )

                if has_offset then
                    menu_logic.set(ref.legs_offset_1, true)
                    menu_logic.set(ref.legs_offset_2, true)

                    if ref.ground_legs:get() == 'Jitter' then
                        menu_logic.set(ref.legs_jitter_time, true)
                    end
                end

                menu_logic.set(ref.options, true)

                if ref.options:get 'Move lean' then
                    menu_logic.set(ref.move_lean, true)
                end
            end

            -- Logging system
            if category == 3 then
                local ref = resource.main.logging_system

                menu_logic.set(ref.enabled, true)

                if not ref.enabled:get() then
                    goto continue
                end

                menu_logic.set(ref.events, true)
                menu_logic.set(ref.output, true)

                if ref.output:get 'Events' then
                    menu_logic.set(ref.events_font, true)
                end

                if ref.output:get 'Under crosshair' then
                    menu_logic.set(ref.offset_y, true)
                    menu_logic.set(ref.duration, true)
                end

                menu_logic.set(ref.console_text_style, true)
                menu_logic.set(ref.crosshair_text_style, true)

                local is_colors_visible = (
                    ref.console_text_style:get() == 'Aesthetic' or
                    ref.crosshair_text_style:get() == 'Aesthetic'
                )

                if is_colors_visible then
                    for i = 1, #ref.main_color_list do
                        local name = ref.main_color_list[i][1]

                        menu_logic.set(ref[name].label, true)
                        menu_logic.set(ref[name].color, true)
                    end

                    menu_logic.set(ref.color_separator, true)

                    for i = 1, #ref.miss_color_list do
                        local name = ref.miss_color_list[i][1]

                        menu_logic.set(ref[name].label, true)
                        menu_logic.set(ref[name].color, true)
                    end
                end

                ::continue::
            end

            -- Automatic purchase
            if category == 4 then
                local ref = resource.main.automatic_purchase

                menu_logic.set(ref.enabled, true)

                if not ref.enabled:get() then
                    goto continue
                end

                menu_logic.set(ref.primary, true)

                if ref.primary:get() == 'AWP' then
                    menu_logic.set(ref.alternative, true)
                end

                menu_logic.set(ref.secondary, true)
                menu_logic.set(ref.equipment, true)

                menu_logic.set(ref.ignore_pistol_round, true)
                menu_logic.set(ref.only_16k, true)

                ::continue::
            end

            -- Builder
            if category == 6 then
                local builder do
                    local ref = resource.antiaim.builder

                    local state = ref.state:get()
                    menu_logic.set(ref.state, true)

                    local items = ref[state]

                    if items == nil then
                        goto continue
                    end

                    local team = items.team:get()
                    menu_logic.set(items.team, true)

                    local team_items = items[team]

                    if team_items == nil then
                        goto continue
                    end

                    update_builder_items(team_items)

                    ::continue::
                end
            end

            -- Features
            if category == 7 then
                local ref = resource.antiaim.features

                local is_avoid_backstab = ref.avoid_backstab.enabled:get() do
                    menu_logic.set(ref.avoid_backstab.enabled, true)

                    if not is_avoid_backstab then
                        goto continue
                    end

                    menu_logic.set(ref.avoid_backstab.distance, true)
                    menu_logic.set(ref.avoid_backstab.separator, true)

                    ::continue::
                end

                local is_break_lc_triggers = ref.break_lc_triggers.enabled:get() do
                    menu_logic.set(ref.break_lc_triggers.enabled, true)

                    if not is_break_lc_triggers then
                        goto continue
                    end

                    menu_logic.set(ref.break_lc_triggers.states, true)
                    menu_logic.set(ref.break_lc_triggers.separator, true)

                    ::continue::
                end

                local is_safe_head = ref.safe_head.enabled:get() do
                    menu_logic.set(ref.safe_head.enabled, true)

                    if not is_safe_head then
                        goto continue
                    end

                    menu_logic.set(ref.safe_head.conditions, true)
                    menu_logic.set(ref.safe_head.e_spam_while_active, true)

                    menu_logic.set(ref.safe_head.separator, true)

                    ::continue::
                end

                menu_logic.set(ref.warmup_round_end.enabled, true)

                local is_flick_exploit = ref.flick_exploit.enabled:get() do
                    menu_logic.set(ref.flick_exploit.enabled, true)

                    if not is_flick_exploit then
                        goto continue
                    end

                    menu_logic.set(ref.flick_exploit.states, true)
                    menu_logic.set(ref.flick_exploit.pitch, true)

                    if ref.flick_exploit.pitch:get() ~= 'Off' then
                        menu_logic.set(ref.flick_exploit.pitch_offset_1, true)

                        if ref.flick_exploit.pitch:get() ~= 'Static' then
                            menu_logic.set(ref.flick_exploit.pitch_label_1, true)
                            menu_logic.set(ref.flick_exploit.pitch_label_2, true)

                            menu_logic.set(ref.flick_exploit.pitch_offset_2, true)
                        end

                        if ref.flick_exploit.pitch:get() == 'Sway' then
                            menu_logic.set(ref.flick_exploit.pitch_speed, true)
                        end
                    end

                    menu_logic.set(ref.flick_exploit.separator, true)

                    ::continue::
                end

                local fakelag do
                    local ref = resource.antiaim.fakelag

                    menu_logic.set(ref.enabled, true)
                    menu_logic.set(ref.hotkey, true)

                    menu_logic.set(ref.amount, true)

                    menu_logic.set(ref.variance, true)
                    menu_logic.set(ref.limit, true)
                end
            end

            -- Hotkeys
            if category == 8 then
                local ref = resource.antiaim.hotkeys

                local is_edge_yaw = ref.edge_yaw.enabled:get() do
                    menu_logic.set(ref.edge_yaw.enabled, true)
                    menu_logic.set(ref.edge_yaw.hotkey, true)

                    if not is_edge_yaw then
                        goto continue
                    end

                    menu_logic.set(ref.edge_yaw.disablers, true)

                    ::continue::
                end

                local is_freestanding = ref.freestanding.enabled:get() do
                    menu_logic.set(ref.freestanding.enabled, true)
                    menu_logic.set(ref.freestanding.hotkey, true)

                    if not is_freestanding then
                        goto continue
                    end

                    menu_logic.set(ref.freestanding.options, true)
                    menu_logic.set(ref.freestanding.disablers, true)

                    menu_logic.set(ref.freestanding.separator, true)

                    ::continue::
                end

                local is_manual_yaw = ref.manual_yaw.enabled:get() do
                    menu_logic.set(ref.manual_yaw.enabled, true)

                    if not is_manual_yaw then
                        goto continue
                    end

                    menu_logic.set(ref.manual_yaw.options, true)

                    menu_logic.set(ref.manual_yaw.left_hotkey, true)
                    menu_logic.set(ref.manual_yaw.right_hotkey, true)
                    menu_logic.set(ref.manual_yaw.forward_hotkey, true)
                    menu_logic.set(ref.manual_yaw.backward_hotkey, true)
                    menu_logic.set(ref.manual_yaw.reset_hotkey, true)

                    menu_logic.set(ref.manual_yaw.manual_arrows, true)

                    if ref.manual_yaw.manual_arrows:get() ~= 'Off' then
                        menu_logic.set(ref.manual_yaw.arrows_color, true)
                        menu_logic.set(ref.manual_yaw.arrows_offset, true)
                    end

                    if ref.manual_yaw.manual_arrows:get() == 'Teamskeet' then
                        menu_logic.set(ref.manual_yaw.desync_color, true)
                    end

                    menu_logic.set(ref.manual_yaw.separator, true)

                    ::continue::
                end

                local is_roll_aa = ref.roll_aa.enabled:get() do
                    menu_logic.set(ref.roll_aa.enabled, true)
                    menu_logic.set(ref.roll_aa.hotkey, true)

                    if not is_roll_aa then
                        goto continue
                    end

                    menu_logic.set(ref.roll_aa.value, true)
                    menu_logic.set(ref.roll_aa.on_manual_yaw, true)

                    menu_logic.set(ref.roll_aa.separator, true)

                    ::continue::
                end
            end

            -- Changers
            if category == 10 then
                local ref = resource.render.changers

                local is_aspect_ratio = ref.aspect_ratio.enabled:get() do
                    menu_logic.set(ref.aspect_ratio.enabled, true)

                    if not is_aspect_ratio then
                        goto continue
                    end

                    menu_logic.set(ref.aspect_ratio.value, true)
                    menu_logic.set(ref.aspect_ratio.separator, true)

                    ::continue::
                end

                local is_third_person = ref.third_person.enabled:get() do
                    menu_logic.set(ref.third_person.enabled, true)

                    if not is_third_person then
                        goto continue
                    end

                    menu_logic.set(ref.third_person.distance, true)
                    menu_logic.set(ref.third_person.zoom_speed, true)

                    menu_logic.set(ref.third_person.separator, true)

                    ::continue::
                end

                local is_viewmodel = ref.viewmodel.enabled:get() do
                    menu_logic.set(ref.viewmodel.enabled, true)

                    if not is_viewmodel then
                        goto continue
                    end

                    menu_logic.set(ref.viewmodel.fov, true)

                    menu_logic.set(ref.viewmodel.offset_x, true)
                    menu_logic.set(ref.viewmodel.offset_y, true)
                    menu_logic.set(ref.viewmodel.offset_z, true)

                    menu_logic.set(ref.viewmodel.options, true)

                    menu_logic.set(ref.viewmodel.separator, true)

                    ::continue::
                end

                local is_custom_scope = ref.custom_scope.enabled:get() do
                    menu_logic.set(ref.custom_scope.enabled, true)
                    menu_logic.set(ref.custom_scope.color, true)

                    if not is_custom_scope then
                        goto continue
                    end

                    menu_logic.set(ref.custom_scope.style, true)
                    menu_logic.set(ref.custom_scope.exclude, true)

                    menu_logic.set(ref.custom_scope.position, true)
                    menu_logic.set(ref.custom_scope.offset, true)

                    if ref.custom_scope.style:get() ~= 'Default' then
                        menu_logic.set(ref.custom_scope.start_fade, true)
                    end

                    menu_logic.set(ref.custom_scope.animation_speed, true)

                    menu_logic.set(ref.custom_scope.separator, true)

                    ::continue::
                end

                local is_force_second_zoom = ref.force_second_zoom.enabled:get() do
                    menu_logic.set(ref.force_second_zoom.enabled, true)

                    if not is_force_second_zoom then
                        goto continue
                    end

                    menu_logic.set(ref.force_second_zoom.value, true)

                    menu_logic.set(ref.force_second_zoom.separator, true)

                    ::continue::
                end

                local is_world_modulation = ref.world_modulation.enabled:get() do
                    menu_logic.set(ref.world_modulation.enabled, true)

                    if not is_world_modulation then
                        goto continue
                    end

                    menu_logic.set(ref.world_modulation.wall_color, true)
                    menu_logic.set(ref.world_modulation.wall_color_picker, true)

                    menu_logic.set(ref.world_modulation.bloom, true)
                    menu_logic.set(ref.world_modulation.exposure, true)
                    menu_logic.set(ref.world_modulation.model_ambient, true)

                    menu_logic.set(ref.world_modulation.separator, true)

                    ::continue::
                end

                local is_light_modulation = ref.light_modulation.enabled:get() do
                    menu_logic.set(ref.light_modulation.enabled, true)

                    if not is_light_modulation then
                        goto continue
                    end

                    menu_logic.set(ref.light_modulation.offset_x, true)
                    menu_logic.set(ref.light_modulation.offset_y, true)
                    menu_logic.set(ref.light_modulation.offset_z, true)

                    menu_logic.set(ref.light_modulation.separator, true)

                    ::continue::
                end
            end

            -- User interface
            if category == 11 then
                local ref = resource.render.user_interface

                local watermark do
                    menu_logic.set(ref.watermark.select, true)

                    menu_logic.set(ref.watermark.accent_color, true)

                    if ref.watermark.select:get 'Default' then
                        menu_logic.set(ref.watermark.secondary_color, true)

                        menu_logic.set(ref.watermark.font, true)
                        menu_logic.set(ref.watermark.removals, true)

                        menu_logic.set(ref.watermark.text_input, true)
                    end

                    if ref.watermark.select:get 'Alternative' then
                        menu_logic.set(ref.watermark.display, true)
                        menu_logic.set(ref.watermark.position, true)
                    end

                    menu_logic.set(ref.watermark.separator, true)
                end

                local is_keybinds = ref.keybinds.enabled:get() do
                    menu_logic.set(ref.keybinds.enabled, true)
                    menu_logic.set(ref.keybinds.color, true)

                    if not is_keybinds then
                        goto continue
                    end

                    menu_logic.set(ref.keybinds.style, true)
                    menu_logic.set(ref.keybinds.select, true)

                    if ref.keybinds.style:get() == 'Fade' then
                        menu_logic.set(ref.keybinds.accent_label, true)
                        menu_logic.set(ref.keybinds.accent_color, true)

                        menu_logic.set(ref.keybinds.secondary_label, true)
                        menu_logic.set(ref.keybinds.secondary_color, true)
                    end

                    menu_logic.set(ref.keybinds.separator, true)

                    ::continue::
                end

                local is_flags_indicator = ref.flags_indicator.enabled:get() do
                    menu_logic.set(ref.flags_indicator.enabled, true)
                    menu_logic.set(ref.flags_indicator.color, true)

                    if not is_flags_indicator then
                        goto continue
                    end

                    menu_logic.set(ref.flags_indicator.style, true)
                    menu_logic.set(ref.flags_indicator.select, true)

                    if ref.flags_indicator.style:get() == 'Fade' then
                        menu_logic.set(ref.flags_indicator.accent_label, true)
                        menu_logic.set(ref.flags_indicator.accent_color, true)

                        menu_logic.set(ref.flags_indicator.secondary_label, true)
                        menu_logic.set(ref.flags_indicator.secondary_color, true)
                    end

                    menu_logic.set(ref.flags_indicator.separator, true)

                    ::continue::
                end

                local is_indicators = ref.indicators.enabled:get() do
                    menu_logic.set(ref.indicators.enabled, true)

                    if not is_indicators then
                        goto continue
                    end

                    menu_logic.set(ref.indicators.style, true)
                    menu_logic.set(ref.indicators.select, true)

                    menu_logic.set(ref.indicators.offset, true)

                    if ref.indicators.style:get() == 'Default' then
                        menu_logic.set(ref.indicators.accent_label, true)
                        menu_logic.set(ref.indicators.accent_color, true)

                        menu_logic.set(ref.indicators.secondary_label, true)
                        menu_logic.set(ref.indicators.secondary_color, true)
                    end

                    menu_logic.set(ref.indicators.separator, true)

                    ::continue::
                end

                local is_net_graphic = ref.net_graphic.enabled:get() do
                    menu_logic.set(ref.net_graphic.enabled, true)
                    menu_logic.set(ref.net_graphic.color, true)

                    if not is_net_graphic then
                        goto continue
                    end

                    menu_logic.set(ref.net_graphic.font, true)
                    menu_logic.set(ref.net_graphic.display, true)
                    menu_logic.set(ref.net_graphic.offset, true)

                    menu_logic.set(ref.net_graphic.separator, true)

                    ::continue::
                end

                menu_logic.set(ref.console_color.enabled, true)
                menu_logic.set(ref.console_color.color, true)

                local is_damage_indicator = ref.damage_indicator.enabled:get() do
                    menu_logic.set(ref.damage_indicator.enabled, true)

                    if not is_damage_indicator then
                        goto continue
                    end

                    menu_logic.set(ref.damage_indicator.only_if_active, true)

                    menu_logic.set(ref.damage_indicator.font, true)
                    menu_logic.set(ref.damage_indicator.offset, true)

                    menu_logic.set(ref.damage_indicator.active_label, true)
                    menu_logic.set(ref.damage_indicator.active_color, true)

                    if not ref.damage_indicator.only_if_active:get() then
                        menu_logic.set(ref.damage_indicator.inactive_label, true)
                        menu_logic.set(ref.damage_indicator.inactive_color, true)
                    end

                    menu_logic.set(ref.damage_indicator.separator, true)

                    ::continue::
                end
            end

            -- Hit markers
            if category == 12 then
                local ref = resource.render.hit_markers

                local is_damage_marker = ref.damage_marker.enabled:get() do
                    menu_logic.set(ref.damage_marker.enabled, true)

                    if not is_damage_marker then
                        goto continue
                    end

                    menu_logic.set(ref.damage_marker.font, true)

                    menu_logic.set(ref.damage_marker.body_label, true)
                    menu_logic.set(ref.damage_marker.body_color, true)

                    menu_logic.set(ref.damage_marker.head_label, true)
                    menu_logic.set(ref.damage_marker.head_color, true)

                    menu_logic.set(ref.damage_marker.mismatch_label, true)
                    menu_logic.set(ref.damage_marker.mismatch_color, true)

                    menu_logic.set(ref.damage_marker.speed, true)
                    menu_logic.set(ref.damage_marker.duration, true)

                    ::continue::
                end

                menu_logic.set(ref.screen_marker.enabled, true)
                menu_logic.set(ref.screen_marker.color, true)

                local is_world_marker = ref.world_marker.enabled:get() do
                    menu_logic.set(ref.world_marker.enabled, true)

                    if not is_world_marker then
                        goto continue
                    end

                    menu_logic.set(ref.world_marker.vertical_label, true)
                    menu_logic.set(ref.world_marker.vertical_color, true)

                    menu_logic.set(ref.world_marker.horizontal_label, true)
                    menu_logic.set(ref.world_marker.horizontal_color, true)

                    menu_logic.set(ref.world_marker.size, true)
                    menu_logic.set(ref.world_marker.thickness, true)

                    ::continue::
                end

                local is_hitsound = ref.hitsound.enabled:get() do
                    menu_logic.set(ref.hitsound.enabled, true)

                    if not is_hitsound then
                        goto continue
                    end

                    menu_logic.set(ref.hitsound.body_sound, true)
                    menu_logic.set(ref.hitsound.head_sound, true)

                    menu_logic.set(ref.hitsound.volume, true)

                    ::continue::
                end
            end

            -- Configurations
            if category == 14 then
                menu_logic.set(config.categories, true)

                menu_logic.set(config.list, true)
                menu_logic.set(config.input, true)

                menu_logic.set(config.load_button, true)
                menu_logic.set(config.save_button, true)
                menu_logic.set(config.delete_button, true)
                menu_logic.set(config.import_button, true)
                menu_logic.set(config.export_button, true)
            end
        end

        local function on_shutdown()
            set_antiaimbot_display(true)
            set_fakelag_display(true)
            set_other_display(true)
        end

        local function on_paint_ui()
            local category = resource.general.category:get()
            local is_hotkeys = category == 8

            set_antiaimbot_display(false)
            set_fakelag_display(false)
            set_other_display(is_hotkeys)
        end

        local logic_events = menu_logic.get_event_bus() do
            logic_events.update:set(
                force_update_scene
            )

            force_update_scene()
            menu_logic.force_update()
        end

        client.set_event_callback('shutdown', on_shutdown)
        client.set_event_callback('paint_ui', on_paint_ui)
    end
end

local windows do
    windows = { }

    local data = { }
    local queue = { }

    local mouse_pos = vector()
    local mouse_pos_prev = vector()

    local mouse_down = false
    local mouse_clicked = false

    local mouse_down_duration = 0

    local mouse_delta = vector()
    local mouse_clicked_pos = vector()

    local hovered_window
    local foreground_window

    local c_window = { } do
        function c_window:new(name)
            local window = { }

            window.name = name

            window.pos = vector()
            window.size = vector()

            window.anchor = vector(0.0, 0.0)

            window.updated = false
            window.dragging = false

            window.item_x = menu.new(ui.new_string, string.format('%s_x', name))
            window.item_y = menu.new(ui.new_string, string.format('%s_y', name))

            data[name] = window
            queue[#queue + 1] = window

            return setmetatable(
                window, self
            )
        end

        function c_window:set_pos(pos)
            local screen = vector(
                client.screen_size()
            )

            local is_screen_invalid = (
                screen.x == 0 and
                screen.y == 0
            )

            if is_screen_invalid then
                return
            end

            local new_pos = pos:clone()

            new_pos.x = utils.clamp(new_pos.x, 0, screen.x - self.size.x)
            new_pos.y = utils.clamp(new_pos.y, 0, screen.y - self.size.y)

            self.pos = new_pos
        end

        function c_window:set_size(size)
            local screen = vector(
                client.screen_size()
            )

            local is_screen_invalid = (
                screen.x == 0 and
                screen.y == 0
            )

            if is_screen_invalid then
                return
            end

            local size_delta = size - self.size

            self.size = size
            self:set_pos(self.pos - size_delta * self.anchor)
        end

        function c_window:set_anchor(anchor)
            self.anchor = anchor
        end

        function c_window:is_hovering()
            return self.hovering
        end

        function c_window:is_dragging()
            return self.dragging
        end

        function c_window:update()
            self.updated = true
        end

        c_window.__index = c_window
    end

    local function is_collided(point, a, b)
        return point.x >= a.x and point.y >= a.y
            and point.x <= b.x and point.y <= b.y
    end

    local function update_mouse_inputs()
        local cursor = vector(ui.mouse_position())
        local is_down = client.key_state(0x01)

        local delta_time = globals.frametime()

        mouse_pos = cursor
        mouse_delta = mouse_pos - mouse_pos_prev

        mouse_pos_prev = mouse_pos

        mouse_down = is_down
        mouse_clicked = is_down and mouse_down_duration < 0

        mouse_down_duration = is_down and (mouse_down_duration < 0 and 0 or mouse_down_duration + delta_time) or -1

        if mouse_clicked then
            mouse_clicked_pos = mouse_pos
        end
    end

    local function appear_all_windows()
        for i = 1, #queue do
            local window = queue[i]

            local pos = window.pos
            local size = window.size

            local r, g, b, a = 0, 0, 0, 255

            renderer.rectangle(pos.x, pos.y, size.x, size.y, r, g, b, a)
        end
    end

    local function find_hovered_window()
        local found_window = nil

        if ui.is_menu_open() then
            for i = 1, #queue do
                local window = queue[i]

                local pos = window.pos
                local size = window.size

                if not window.updated then
                    goto continue
                end

                if not is_collided(mouse_pos, pos, pos + size) then
                    goto continue
                end

                found_window = window

                ::continue::
            end
        end

        hovered_window = found_window
    end

    local function find_foreground_window()
        if mouse_down then
            if mouse_clicked and hovered_window ~= nil then
                for i = 1, #queue do
                    local window = queue[i]

                    if window == hovered_window then
                        table.remove(queue, i)
                        table.insert(queue, window)

                        break
                    end
                end

                foreground_window = hovered_window
                return
            end

            return
        end

        foreground_window = nil
    end

    local function update_all_windows()
        for i = 1, #queue do
            local window = queue[i]

            window.updated = false

            window.hovering = false
            window.dragging = false
        end
    end

    local function update_hovered_window()
        if hovered_window == nil then
            return
        end

        hovered_window.hovering = true
    end

    local function update_foreground_window()
        if foreground_window == nil then
            return
        end

        local new_position = foreground_window.pos + mouse_delta

        foreground_window:set_pos(new_position)
        foreground_window.dragging = true
    end

    local function save_windows_settings()
        local screen = vector(
            client.screen_size()
        )

        for i = 1, #queue do
            local window = queue[i]

            local x = window.pos.x / screen.x
            local y = window.pos.y / screen.y

            window.item_x:set(tostring(x))
            window.item_y:set(tostring(y))
        end
    end

    local function load_windows_settings()
        local screen = vector(
            client.screen_size()
        )

        for i = 1, #queue do
            local window = queue[i]

            local x = tonumber(window.item_x:get())
            local y = tonumber(window.item_y:get())

            if x ~= nil and y ~= nil then
                window:set_pos(screen * vector(x, y))
            end
        end
    end

    local function on_paint_ui()
        -- appear_all_windows()
        update_mouse_inputs()

        find_hovered_window()
        find_foreground_window()

        update_all_windows()

        update_hovered_window()
        update_foreground_window()
    end

    local function on_setup_command(cmd)
        local should_update = (
            hovered_window ~= nil or
            foreground_window ~= nil
        )

        if should_update then
            cmd.in_attack = 0
            cmd.in_attack2 = 0
        end
    end

    function windows.new(name, x, y)
        local window = data[name]
            or c_window:new(name)

        local screen = vector(client.screen_size())
        window:set_pos(screen * vector(x, y))

        return window
    end

    function windows.save_settings()
        save_windows_settings()
    end

    function windows.load_settings()
        load_windows_settings()
    end

    client.delay_call(0, function()
        client.set_event_callback(
            'paint_ui', on_paint_ui
        )

        client.set_event_callback(
            'setup_command',
            on_setup_command
        )

        client.set_event_callback(
            'pre_config_save',
            save_windows_settings
        )

        client.set_event_callback(
            'post_config_load',
            load_windows_settings
        )
    end)
end

local config do
    local ref = resource.config

    local DB_NAME = '##AESTHETIC_DB'
    local DB_DEFAULT = { }

    local db_data = (
        localdb['config']
        or database.read(DB_NAME)
        or DB_DEFAULT
    )

    local config_data = { }
    local config_list = { }

    local config_defaults = {
        [1] = {
            name = 'Defensive',
            data = '[aesthetic] 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y2iS8nRrCmDOygTZsNkyEear0m4G5WuronGcGaTBymHwygaAonTY5e4Y8nurEn62zQBe8nRKE4ArspGO0eRLCmwOEJ4r8CHkymqYEniX8eRQEWsdnmEXyJDQCvh2EeTZ8m4U0m4NymiLCSkOymAYEniX8eRQEWsdnSHZGn4G5Wumon4SynTLEnhYymEe0m4ACSc2zQrRxaArseaK0g4NGaTZ8CHkyZim8nRwEvsdnKMZD4ArseRkEmXACmwOEJ4r8CHkymqYymEe0m4ACSL2zQrBDNDG5WuSySurEaTBymHwygaAonTY5ewOEg4rCmaB8eQQyp62zQrhCvh2GmTZygHUynTLGnRXGgQOy2iQIJjO0S4ZEvsdnK8hz4ArseRkEmXACmwOEJ4r8CHkymqYymEe0m4ACSc2zQrBDljG5Wumon4SynTLEnhYySjAonTY0Zsdnwr2lSjhySDkGg7VomikEe7VogaYEWuGCCArsLROEmGkye0V0SQKGg4BsNkPseROEmGkyeGU0SQKGg4B5pjZEnHk8SHkymqVECuZySuU8mTrySs2zQrRDK7rxlxw59MKDvhZDl4G5WurymGponipCSDi0SHQyviOGgXQ0QTNymRO02sdnKMSDvhRxK7rxlxw59swD4ArseROEmGkyeGU0SQKGg4B5eTwGJjwGWsdnwr26mTY0mTrEvsrsQ4YEg4ZsgDZySDKogak02uGCvh2ygTpEmQYEwTKICDAEnAYGgaZEm4ACmDOygTZsNkyxl0w59MKDvhRxK7rxN7wCvh2ygTpEmQYEwTKICDAEnAY8mTY0mTrE4TAECXACSDAInRQsNkysLaQ0SHcECHk8ZuG5WurymGponipCSDi0SHQyviZECDOyJEQ0QTNymRO02sdnKMSDvhRxK7rxlxw59swD4ArseROEmGkyeGU0SQKGg4B5eDZySDKogak0QTAECXACSDAInRQsNkysLaQ0SHcECHk8ZuG5WurymGponipCSDi0SHQyviLGCuXGgQOy2sdnKMSCvh2ygTpEmQYEwTKICDAEnAYEniX8eRQEWsdnSHZGn4G5WurymGponipCSDi0SHQyviLEnaAoaTNymRO02sdnKMSDvhRxK7rxlxw59swD4ArseROEmGkyeGU0SQKGg4B5eTeEpDQGaTisNkyxKjG5WurymGponipCSDi0SHQyviQGe4YGJDUEeTYGWsdnZu3yg62Cvh2ygTpEmQYEwTKICDAEnAYGniZEnGk0SHQ0e4LsJDcySHU8mTrySs2zQrRDK7rxlxw59MKDvhZDl4G5WurymGponipCSDi0SHQyviK0JuQ8nHU8mTrySs2zQrRDK7rxlxw59MKDvhZDl4G5WurymGponipCSDi0SHQyviQGe4YGJx2zQBysLakynuOGWuGCCArsLXOGgBQICx2zpr2EnHpE4Ti8C0YEniX8eRQEWsdnmEXyJDQCvh2ynaYGnarCSQXGZirEnEACmXOGgBQIvsdnZu7ymGpyg7259LhCvh2ynaYGnarCSQXGZiQyea2yg4LsNkyGJuwE4ArspuOygRU8nMYEniX8eRQEWsdnmEXyJDQCvh2EpuQECDA8niLonip5e4Y8nurEn62zQBA0p4QCvh2ynaYGnarCSQXGZiZECDQGaTcySHfECL2zQr2lmqVogTAom4is2hhCvh2EnHpE4Ti8C0YEgQK8nurECuKsNkyISwG5Wue0e4Q0SHXyeHkye0YEgQK8nurECuKsNkynZulygTSsaGXygr25WujoCs25Wu90eTw8mXQEWuGCvh2ynaYGnarCSQXGZiO0JHkymiKsNkyISwG5WuB8niw8nRUInaS5eaZ0eTS0wTNymRO02sdnKMSDvhRxK7rxlxw59swD4ArspuOygRU8nMYogTAom4isNkysLTYsgXOGgBQIvsrxaArseEZEn4KGgaYEgQYEZicySHfECL2zQr2lmqVogTAom4is2hRzaArse4LEm4UInaS5eXOGgBQIvsdnZu3y2jcySHfECL259jG5WuB8niw8nRUInaS5ewXyp4XyaTX0puOGSx2zQr26mRX0SDk8ZuG5WuB8niw8nRUInaS5eHQ0SQY8wTNymRO02sdnKxw59MZzWhZDl7rxN7wCvh2ynaYGnarCSQXGZi28nDfGmaZEaTcySHfECL2zQr24gTpEmRQs2hhCvh20eTryaTX8vim8nRwEvsdnKjG5WuZymRrCmaX5eTYCmwXyp4XyaTi8C02zQBe8nRKE4ArsewXyp4XyaTi8C0Y0eQpoJHUogTAom4isNkysQHOEmGrEvsrDNGG5WuB8niw8nRUInaS5eEO0pGX0eHUogTAom4isNkysQHOEmGrEvsrxawT5WusoC6VynaZom4Z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_'
        },
        [2] = {
            name = 'Unmatched undetect (Defensive)',
            data = '[aesthetic] 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y2iS8nRrCmDOygTZsNkyEear0m4G5WuronGcGaTBymHwygaAonTY5e4Y8nurEn62zQBe8nRKE4ArspGO0eRLCmwOEJ4r8CHkymqYEniX8eRQEWsdnmEXyJDQCvh2EeTZ8m4U0m4NymiLCSkOymAYEniX8eRQEWsdnSHZGn4G5Wumon4SynTLEnhYymEe0m4ACSc2zQrRxaArseaK0g4NGaTZ8CHkyZim8nRwEvsdnKMZD4ArseRkEmXACmwOEJ4r8CHkymqYymEe0m4ACSL2zQrBDNDG5WuSySurEaTBymHwygaAonTY5ewOEg4rCmaB8eQQyp62zQrhCvh2GmTZygHUynTLGnRXGgQOy2iQIJjO0S4ZEvsdnK8hz4ArseRkEmXACmwOEJ4r8CHkymqYymEe0m4ACSc2zQrBDljG5Wumon4SynTLEnhYySjAonTY0Zsdnwr2lSjhySDkGg7VomikEe7VogaYEWuGCCArsLROEmGkye0V0SQKGg4BsNkPseROEmGkyeGU0SQKGg4B5pjZEnHk8SHkymqVECuZySuU8mTrySs2zQrRDK7rxlxw59MKDvhZDl4G5WurymGponipCSDi0SHQyviOGgXQ0QTNymRO02sdnKMSDvhRxK7rxlxw59swD4ArseROEmGkyeGU0SQKGg4B5eTwGJjwGWsdnwr26mTY0mTrEvsrsQ4YEg4ZsgDZySDKogak02uGCvh2ygTpEmQYEwTKICDAEnAYGgaZEm4ACmDOygTZsNkyxl0w59MKDvhRxK7rxN7wCvh2ygTpEmQYEwTKICDAEnAY8mTY0mTrE4TAECXACSDAInRQsNkysLaQ0SHcECHk8ZuG5WurymGponipCSDi0SHQyviZECDOyJEQ0QTNymRO02sdnKMSDvhRxK7rxlxw59swD4ArseROEmGkyeGU0SQKGg4B5eDZySDKogak0QTAECXACSDAInRQsNkysLaQ0SHcECHk8ZuG5WurymGponipCSDi0SHQyviLGCuXGgQOy2sdnKMSCvh2ygTpEmQYEwTKICDAEnAYEniX8eRQEWsdnSHZGn4G5WurymGponipCSDi0SHQyviLEnaAoaTNymRO02sdnKMSDvhRxK7rxlxw59swD4ArseROEmGkyeGU0SQKGg4B5eTeEpDQGaTisNkyxKjG5WurymGponipCSDi0SHQyviQGe4YGJDUEeTYGWsdnZu3yg62Cvh2ygTpEmQYEwTKICDAEnAYGniZEnGk0SHQ0e4LsJDcySHU8mTrySs2zQrRDK7rxlxw59MKDvhZDl4G5WurymGponipCSDi0SHQyviK0JuQ8nHU8mTrySs2zQrRDK7rxlxw59MKDvhZDl4G5WurymGponipCSDi0SHQyviQGe4YGJx2zQBysLakynuOGWuGCCArsLXOGgBQICx2zpr2EnHpE4Ti8C0YEniX8eRQEWsdnmEXyJDQCvh2ynaYGnarCSQXGZirEnEACmXOGgBQIvsdnZu7ymGpyg7259LhCvh2ynaYGnarCSQXGZiQyea2yg4LsNkyGJuwE4ArspuOygRU8nMYEniX8eRQEWsdnmEXyJDQCvh2EpuQECDA8niLonip5e4Y8nurEn62zQBA0p4QCvh2ynaYGnarCSQXGZiZECDQGaTcySHfECL2zQr2lmqVogTAom4is2hhCvh2EnHpE4Ti8C0YEgQK8nurECuKsNkyISwG5Wue0e4Q0SHXyeHkye0YEgQK8nurECuKsNkynZulygTSsaGXygr25WujoCs25Wu90eTw8mXQEWuGCvh2ynaYGnarCSQXGZiO0JHkymiKsNkyISwG5WuB8niw8nRUInaS5eaZ0eTS0wTNymRO02sdnKMSDvhRxK7rxlxw59swD4ArspuOygRU8nMYogTAom4isNkysLTYsgXOGgBQIvsrxaArseEZEn4KGgaYEgQYEZicySHfECL2zQr2lmqVogTAom4is2hRzaArse4LEm4UInaS5eXOGgBQIvsdnZu3y2jcySHfECL259jG5WuB8niw8nRUInaS5ewXyp4XyaTX0puOGSx2zQr26mRX0SDk8ZuG5WuB8niw8nRUInaS5eHQ0SQY8wTNymRO02sdnKxw59MZzWhZDl7rxN7wCvh2ynaYGnarCSQXGZi28nDfGmaZEaTcySHfECL2zQr24gTpEmRQs2hhCvh20eTryaTX8vim8nRwEvsdnKjG5WuZymRrCmaX5eTYCmwXyp4XyaTi8C02zQBe8nRKE4ArsewXyp4XyaTi8C0Y0eQpoJHUogTAom4isNkysQHOEmGrEvsrDNGG5WuB8niw8nRUInaS5eEO0pGX0eHUogTAom4isNkysQHOEmGrEvsrxawT5WusoC6VynaZom4Z0ZsdIZuSySurEaTB8CufECsYGgXk8mBYECDKsNkyx4ArspGO0eRLCmwX0eBQ02icySukIeTYGgarCmDOygTZsNkyxWhZDl7rxWhZDl4G5WuL8nwXEm4UynaZom4Z5euOEJQU8mTrySs2zQrZDl7rxN7w59swDvhZDl4G5WuSySurEaTB8CufECsYEniX8eRQEWsdnSHZGn4G5WuSySurEaTB8CufECsY0mQdEvsdnKHG5WuSySurEaTB8CufECsYGe4ZGgQN8nRU8mTrySs2zQrh59swDvhZDl7rxN7wCvh2EgaB8nGQCmwX0eBQ02icEnaLCmDOygTZsNkyxl7h59MqDvhw59swD4ArspDN0e4QyQTB8CufECsYEniX8eRQEWsdnmEXyJDQCvh2EgaB8nGQCmwX0eBQ02iLGCuXGgQOy2sdnKHG5WuK8SuQEniUynaZom4Z5eDOygTZsNkyxN7w59swDvhZDl7rxNbhCvh2EgaB8nGQCmwX0eBQ02ieymiAsNkysLHQEeawyJ62Cvh2EgaB8nGQCmwX0eBQ02iBoCDB8CHNoaTNymRO02sdnKswDvhh59brxN7wCvh2EgaB8nGQCmwX0eBQ02iQyea2yg4LsNkyGJuwE4ArseHXynapE4TB8CufECsY0SjQEn62zQrwzawT5WujyeQB8CHkymiKsNkPseaYonwU8puQ8nBQ02irEnGKCmTeEpDQGa1ZsNkyDlaG5WuXyeQBCmuZEnafECsYyg4p0wTFoCHAECuUGgQBEvsdnKaG5WuXyeQBCmuZEnafECsY8nQZCmRQESDUGm4kEmXAsNkyDNjG5WuXyeQBCmuZEnafECsYESuOGniLCmRQESx2zQr2lmEesQArseaYonwU8puQ8nBQ02iBySEQCmRQ8nq2zQrRx9jG5WuXyeQBCmuZEnafECsYyg4p0wTOEeEKECHUxvsdnKMACvh28niky4T20e4Xom4Z5eak0QTrEnGKsNkysLTeE2uG5WuXyeQBCmuZEnafECsYySjAonTY0Zsdnwr2lnTmEvjrEnaYs2h27mwOySHcsgaYonweoCV2C4wT5Wu40m4ZsgQYGg4ZEeaNEvsdIZuNGCDAymwU0mDO0g7YEniX8eRQEWsdnSHZGn4G5WuL8nwXEm4UoniLonDXGgTZ5eaNGgQmE4TNymRO02sdnKswDvhZDl7rxN7w59swD4ArseHXynapE4TkyeHk8maAySsYEeTYGWsdnZulynaryWuG5WukyeHk8maAySuK5eTeEpDQGWsdnKMwCvh2om4i8eQYEJxYGmQYEgTSCSL2zQr2xWqKDvuG5Wueygap0wTkyeHk8maAySsY0SHiyg72zQr2HeaLEvuG5WuL8nwXEm4UoniLonDXGgTZ5e4Y8nurEn62zQBA0p4QCvh28S4KGgTBCSDNySjQ5eTeEpDQGWsdnKuG5WufECQ2oniL0ZiNymRO02sdnKVZ59Vm59MhxZhZDl4G5WuS8CHQ0ewX0erYEeTYGWsdnZulynaryWuG5Wueygap0wTkyeHk8maAySsYEniX8eRQEWsdnmEXyJDQCvh28S4KGgTBCSDNySjQ5eaYonwXGgQOyQTK0g4QEWsdnKxwCvh2EeRXESDUoniLonDXGgTZ5eaN8m4YGaTNymRO02sdnKMAxWhZD9brxN6h59swD4ArseHXynapE4TkyeHk8maAySsYymirI4TkEQTX8SHkGe72zQBe8nRKE4ArseEr8nGKCmQYEgQN8CHO02iNymRO02sdnKMAxWhZD9brxN6h59shxaArseDw0SHOy4TK8mThEviNymRO02sdnKswDvhZDl7rxN7w59LSCvh2EgaB8nGQCmQYEgQN8CHO02ikyeaNGgQmE4TNymRO02sdnKswDvhZDl7rxN7w59MKzaArseBQInukyeHK5pDQyg4NGWsdnwr2vgQLEvjKogTA0ZsrsLEO0eDQsguOEJLV8nQBs2h2HeTZ8m7V0maeEvjhymQYGJx25WuM8nwXEm7VySEQ0pukEg72C4ArspGXGg4ZynaZoZiZEnwOGear0Zsdnwr26nikynaAonTYsQwG5WueygapCmQYEgQN8CHO02iSoniLySGUIvsdnZsh5NswsQArseQYEgQN8CHO0pxY0m4NymiL8CuiCmDOygTZsNkyxlsi59VA59VA59swD4ArseEr8nGKCmQYEgQN8CHO02iKEnRQ8S62zQBysLEXom7VInaSsQwG5WufECQ2oniL0ZiQyea2yg4LsNkyEear0m4G5WueygapCmQYEgQN8CHO02iSoniLySGUIWsdnZsh5NbSDvuG5WukyeHk8maAySuK5pDAInRQsNkysLHQEeawyJ62Cvh2om4i8eQYEJxYGmQY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_'
        },
        [3] = {
            name = 'Fast Delay Jitter',
            data = '[aesthetic] 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y2iS8nRrCmDOygTZsNkyEear0m4G5WuronGcGaTBymHwygaAonTY5e4Y8nurEn62zQBe8nRKE4ArspGO0eRLCmwOEJ4r8CHkymqYEniX8eRQEWsdnmEXyJDQCvh2EeTZ8m4U0m4NymiLCSkOymAYEniX8eRQEWsdnSHZGn4G5Wumon4SynTLEnhYymEe0m4ACSc2zQrRxaArseaK0g4NGaTZ8CHkyZim8nRwEvsdnKMZD4ArseRkEmXACmwOEJ4r8CHkymqYymEe0m4ACSL2zQrBDNDG5WuSySurEaTBymHwygaAonTY5ewOEg4rCmaB8eQQyp62zQrhCvh2GmTZygHUynTLGnRXGgQOy2iQIJjO0S4ZEvsdnK8hz4ArseRkEmXACmwOEJ4r8CHkymqYymEe0m4ACSc2zQrBDljG5Wumon4SynTLEnhYySjAonTY0Zsdnwr2lSjhySDkGg7VomikEe7VogaYEWuGCCArsLROEmGkye0V0SQKGg4BsNkPseROEmGkyeGU0SQKGg4B5pjZEnHk8SHkymqVECuZySuU8mTrySs2zQrRDK7rxlxw59MKDvhZDl4G5WurymGponipCSDi0SHQyviOGgXQ0QTNymRO02sdnKMSDvhRxK7rxlxw59swD4ArseROEmGkyeGU0SQKGg4B5eTwGJjwGWsdnwr26mTY0mTrEvsrsQ4YEg4ZsgDZySDKogak02uGCvh2ygTpEmQYEwTKICDAEnAYGgaZEm4ACmDOygTZsNkyxl0w59MKDvhRxK7rxN7wCvh2ygTpEmQYEwTKICDAEnAY8mTY0mTrE4TAECXACSDAInRQsNkysLaQ0SHcECHk8ZuG5WurymGponipCSDi0SHQyviZECDOyJEQ0QTNymRO02sdnKMSDvhRxK7rxlxw59swD4ArseROEmGkyeGU0SQKGg4B5eDZySDKogak0QTAECXACSDAInRQsNkysLaQ0SHcECHk8ZuG5WurymGponipCSDi0SHQyviLGCuXGgQOy2sdnKMSCvh2ygTpEmQYEwTKICDAEnAYEniX8eRQEWsdnSHZGn4G5WurymGponipCSDi0SHQyviLEnaAoaTNymRO02sdnKMSDvhRxK7rxlxw59swD4ArseROEmGkyeGU0SQKGg4B5eTeEpDQGaTisNkyxKjG5WurymGponipCSDi0SHQyviQGe4YGJDUEeTYGWsdnZu3yg62Cvh2ygTpEmQYEwTKICDAEnAYGniZEnGk0SHQ0e4LsJDcySHU8mTrySs2zQrRDK7rxlxw59MKDvhZDl4G5WurymGponipCSDi0SHQyviK0JuQ8nHU8mTrySs2zQrRDK7rxlxw59MKDvhZDl4G5WurymGponipCSDi0SHQyviQGe4YGJx2zQBysLakynuOGWuGCCArsLXOGgBQICx2zpr2EnHpE4Ti8C0YEniX8eRQEWsdnmEXyJDQCvh2ynaYGnarCSQXGZirEnEACmXOGgBQIvsdnZu7ymGpyg7259LhCvh2ynaYGnarCSQXGZiQyea2yg4LsNkyGJuwE4ArspuOygRU8nMYEniX8eRQEWsdnmEXyJDQCvh2EpuQECDA8niLonip5e4Y8nurEn62zQBA0p4QCvh2ynaYGnarCSQXGZiZECDQGaTcySHfECL2zQr2lmqVogTAom4is2hhCvh2EnHpE4Ti8C0YEgQK8nurECuKsNkyISwG5Wue0e4Q0SHXyeHkye0YEgQK8nurECuKsNkynZulygTSsaGXygr25WujoCs25Wu90eTw8mXQEWuGCvh2ynaYGnarCSQXGZiO0JHkymiKsNkyISwG5WuB8niw8nRUInaS5eaZ0eTS0wTNymRO02sdnKMSDvhRxK7rxlxw59swD4ArspuOygRU8nMYogTAom4isNkysLTYsgXOGgBQIvsrxaArseEZEn4KGgaYEgQYEZicySHfECL2zQr2lmqVogTAom4is2hRzaArse4LEm4UInaS5eXOGgBQIvsdnZu3y2jcySHfECL259jG5WuB8niw8nRUInaS5ewXyp4XyaTX0puOGSx2zQr26mRX0SDk8ZuG5WuB8niw8nRUInaS5eHQ0SQY8wTNymRO02sdnKxw59MZzWhZDl7rxN7wCvh2ynaYGnarCSQXGZi28nDfGmaZEaTcySHfECL2zQr24gTpEmRQs2hhCvh20eTryaTX8vim8nRwEvsdnKjG5WuZymRrCmaX5eTYCmwXyp4XyaTi8C02zQBe8nRKE4ArsewXyp4XyaTi8C0Y0eQpoJHUogTAom4isNkysQHOEmGrEvsrDNGG5WuB8niw8nRUInaS5eEO0pGX0eHUogTAom4isNkysQHOEmGrEvsrxawT5WusoC6VynaZom4Z0ZsdIZuSySurEaTB8CufECsYGgXk8mBYECDKsNkyx4ArspGO0eRLCmwX0eBQ02icySukIeTYGgarCmDOygTZsNkyxWhZDl7rxWhZDl4G5WuL8nwXEm4UynaZom4Z5euOEJQU8mTrySs2zQrZDl7rxN7w59swDvhZDl4G5WuSySurEaTB8CufECsYEniX8eRQEWsdnSHZGn4G5WuSySurEaTB8CufECsY0mQdEvsdnKHG5WuSySurEaTB8CufECsYGe4ZGgQN8nRU8mTrySs2zQrh59swDvhZDl7rxN7wCvh2EgaB8nGQCmwX0eBQ02icEnaLCmDOygTZsNkyxl7h59MqDvhw59swD4ArspDN0e4QyQTB8CufECsYEniX8eRQEWsdnmEXyJDQCvh2EgaB8nGQCmwX0eBQ02iLGCuXGgQOy2sdnKHG5WuK8SuQEniUynaZom4Z5eDOygTZsNkyxN7w59swDvhZDl7rxNbhCvh2EgaB8nGQCmwX0eBQ02ieymiAsNkysLHQEeawyJ62Cvh2EgaB8nGQCmwX0eBQ02iBoCDB8CHNoaTNymRO02sdnKswDvhh59brxN7wCvh2EgaB8nGQCmwX0eBQ02iQyea2yg4LsNkyGJuwE4ArseHXynapE4TB8CufECsY0SjQEn62zQrwzawT5WujyeQB8CHkymiKsNkPseaYonwU8puQ8nBQ02irEnGKCmTeEpDQGa1ZsNkyDlaG5WuXyeQBCmuZEnafECsYyg4p0wTFoCHAECuUGgQBEvsdnKaG5WuXyeQBCmuZEnafECsY8nQZCmRQESDUGm4kEmXAsNkyDNjG5WuXyeQBCmuZEnafECsYESuOGniLCmRQESx2zQr2lmEesQArseaYonwU8puQ8nBQ02iBySEQCmRQ8nq2zQrRx9jG5WuXyeQBCmuZEnafECsYyg4p0wTOEeEKECHUxvsdnKMACvh28niky4T20e4Xom4Z5eak0QTrEnGKsNkysLTeE2uG5WuXyeQBCmuZEnafECsYySjAonTY0Zsdnwr2lnTmEvjrEnaYs2h27mwOySHcsgaYonweoCV2C4wT5Wu40m4ZsgQYGg4ZEeaNEvsdIZuNGCDAymwU0mDO0g7YEniX8eRQEWsdnSHZGn4G5WuL8nwXEm4UoniLonDXGgTZ5eaNGgQmE4TNymRO02sdnKswDvhZDl7rxN7w59swD4ArseHXynapE4TkyeHk8maAySsYEeTYGWsdnZulynaryWuG5WukyeHk8maAySuK5eTeEpDQGWsdnKMwCvh2om4i8eQYEJxYGmQYEgTSCSL2zQr2xWqKDvuG5Wueygap0wTkyeHk8maAySsY0SHiyg72zQr2HeaLEvuG5WuL8nwXEm4UoniLonDXGgTZ5e4Y8nurEn62zQBA0p4QCvh28S4KGgTBCSDNySjQ5eTeEpDQGWsdnKuG5WufECQ2oniL0ZiNymRO02sdnKVZ59Vm59MhxZhZDl4G5WuS8CHQ0ewX0erYEeTYGWsdnZulynaryWuG5Wueygap0wTkyeHk8maAySsYEniX8eRQEWsdnmEXyJDQCvh28S4KGgTBCSDNySjQ5eaYonwXGgQOyQTK0g4QEWsdnKxwCvh2EeRXESDUoniLonDXGgTZ5eaN8m4YGaTNymRO02sdnKMAxWhZD9brxN6h59swD4ArseHXynapE4TkyeHk8maAySsYymirI4TkEQTX8SHkGe72zQBe8nRKE4ArseEr8nGKCmQYEgQN8CHO02iNymRO02sdnKMAxWhZD9brxN6h59shxaArseDw0SHOy4TK8mThEviNymRO02sdnKswDvhZDl7rxN7w59LSCvh2EgaB8nGQCmQYEgQN8CHO02ikyeaNGgQmE4TNymRO02sdnKswDvhZDl7rxN7w59MKzaArseBQInukyeHK5pDQyg4NGWsdnwr2vgQLEvjKogTA0ZsrsLEO0eDQsguOEJLV8nQBs2h2HeTZ8m7V0maeEvjhymQYGJx25WuM8nwXEm7VySEQ0pukEg72C4ArspGXGg4ZynaZoZiZEnwOGear0Zsdnwr26nikynaAonTYsQwG5WueygapCmQYEgQN8CHO02iSoniLySGUIvsdnZsh5NswsQArseQYEgQN8CHO0pxY0m4NymiL8CuiCmDOygTZsNkyxlsi59VA59VA59swD4ArseEr8nGKCmQYEgQN8CHO02iKEnRQ8S62zQBysLEXom7VInaSsQwG5WufECQ2oniL0ZiQyea2yg4LsNkyEear0m4G5WueygapCmQYEgQN8CHO02iSoniLySGUIWsdnZsh5NbSDvuG5WukyeHk8maAySuK5pDAInRQsNkysLHQEeawyJ62Cvh2om4i8eQYEJxYGmQY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_'
        }
    }

    for i = 1, #db_data do
        config_data[i] = db_data[i]
    end

    for i = #config_defaults, 1, -1 do
        local list = config_defaults[i]

        if list.data == nil then
            goto continue
        end

        local ok, result = config_system.decode(list.data)

        if not ok then
            -- config is not valid, delete it
            table.remove(config_defaults, i)

            goto continue
        end

        list.data = result

        ::continue::
    end

    local function get_categories()
        local result = { }

        local list = ref.categories:get()

        for i = 1, #list do
            local value = list[i]

            local new_value = value:match(
                ' -  (.+)'
            )

            table.insert(result, new_value)
        end

        return result
    end

    local function create_config(name, data, is_default)
        local list = { }

        list.name = name
        list.data = data
        list.default = is_default

        return list
    end

    local function find_config(name)
        for i = 1, #config_list do
            local data = config_list[i]

            if data.name == name then
                return data, i
            end
        end

        return nil, -1
    end

    local function save_config_data()
        localdb['config'] = config_data
    end

    local function update_config_list()
        for i = 1, #config_list do
            config_list[i] = nil
        end

        for i = 1, #config_defaults do
            local list = config_defaults[i]

            local cell = create_config(
                list.name, list.data, true
            )

            table.insert(config_list, cell)
        end

        for i = 1, #config_data do
            local list = config_data[i]

            local cell = create_config(
                list.name, list.data, false
            )

            cell.data_index = i

            table.insert(config_list, cell)
        end
    end

    local function get_render_list()
        local result = { }

        for i = 1, #config_list do
            local list = config_list[i]

            local name = list.name

            if list.default then
                name = string.format(
                    '%s*', name
                )
            end

            table.insert(result, name)
        end

        return result
    end

    local function load_config(name, categories)
        local list, idx = find_config(name)

        if list == nil or idx == -1 then
            return
        end

        local ok, result = config_system.import(
            list.data, categories
        )

        if not ok then
            logging.error(string.format(
                'failed to import %s config: %s', name, result
            ))

            return
        end

        logging.success(string.format(
            'loaded %s config', name
        ))

        windows.load_settings()
    end

    local function save_config(name)
        windows.save_settings()

        local cfg_data = config_system.export()

        local list, idx = find_config(name)

        if list == nil or idx == -1 then
            table.insert(config_data, create_config(
                name, cfg_data, false
            ))

            save_config_data()
            update_config_list()

            ref.list:update(
                get_render_list()
            )

            logging.success(string.format(
                'created %s config', name
            ))

            return
        end

        if list.default then
            logging.error(string.format(
                'you can\'t edit %s config', name
            ))

            return
        end

        list.data = cfg_data

        if list.data_index ~= nil then
            local data_cell = config_data[
                list.data_index
            ]

            if data_cell ~= nil then
                data_cell.data = cfg_data
            end
        end

        save_config_data()
        update_config_list()

        logging.success(string.format(
            'saved %s config', name
        ))
    end

    local function delete_config(name)
        local list, idx = find_config(name)

        if list == nil or idx == -1 then
            return
        end

        if list.default then
            logging.error(string.format(
                'you can\'t delete %s config', name
            ))

            return
        end

        local data_index = list.data_index

        if data_index == nil then
            return
        end

        table.remove(config_data, data_index)

        save_config_data()
        update_config_list()

        ref.list:update(
            get_render_list()
        )

        local next_input = ''

        local index = math.min(
            ref.list:get() + 1,
            #config_list
        )

        local data = config_list[index]

        if data ~= nil then
            next_input = data.name
        end

        ref.input:set(next_input)

        logging.success(string.format(
            'deleted %s config', name
        ))
    end

    local callbacks do
        local function on_list(item)
            local index = item:get()

            if index == nil then
                return
            end

            local list = config_list[index + 1]

            if list == nil then
                return
            end

            ref.input:set(list.name)
        end

        local function on_load()
            local name = utils.trim(
                ref.input:get()
            )

            if name == '' then
                return
            end

            load_config(name, get_categories())
        end

        local function on_save()
            local name = utils.trim(
                ref.input:get()
            )

            if name == '' then
                return
            end

            save_config(name)
        end

        local function on_delete()
            local name = utils.trim(
                ref.input:get()
            )

            if name == '' then
                return
            end

            delete_config(name)
        end

        local function on_export()
            windows.save_settings()

            local ok, result = config_system.encode(
                config_system.export()
            )

            if not ok then
                return
            end

            clipboard.set(result)

            logging.success(
                'exported config'
            )
        end

        local function on_import()
            local str = clipboard.get()

            if str == nil then
                return
            end

            local ok, result = config_system.decode(str)

            if not ok then
                return
            end

            config_system.import(result, get_categories())

            windows.load_settings()

            logging.success(
                'imported config'
            )
        end

        ref.list:set_callback(on_list)

        ref.load_button:set_callback(on_load)
        ref.save_button:set_callback(on_save)
        ref.delete_button:set_callback(on_delete)

        ref.export_button:set_callback(on_export)
        ref.import_button:set_callback(on_import)
    end

    update_config_list()
    ref.list:update(get_render_list())
end

local ex_render do
    ex_render = { }

    local function sign(x)
        if x > 0 then
            return 1
        end

        if x < 0 then
            return -1
        end

        return 0
    end

    function ex_render.blur(x, y, w, h)
        if globals.mapname() == nil then
            return
        end

        renderer.blur(x, y, w, h)
    end

    function ex_render.rectangle_outline(x, y, w, h, r, g, b, a, thickness, radius)
        if thickness == nil or thickness == 0 then
            thickness = 1
        end

        if radius == nil then
            radius = 0
        end

        local wt = sign(w) * thickness
        local ht = sign(h) * thickness

        local pad = radius == 1 and 1 or 0

        local pad_2 = pad * 2
        local radius_2 = radius * 2

        renderer.circle_outline(x + radius, y + radius, r, g, b, a, radius, 180, 0.25, thickness)
        renderer.circle_outline(x + radius, y + h - radius, r, g, b, a, radius, 90, 0.25, thickness)
        renderer.circle_outline(x + w - radius, y + radius, r, g, b, a, radius, 270, 0.25, thickness)
        renderer.circle_outline(x + w - radius, y + h - radius, r, g, b, a, radius, 0, 0.25, thickness)

        renderer.rectangle(x, y + radius, wt, h - radius_2, r, g, b, a)
        renderer.rectangle(x + w, y + radius, -wt, h - radius_2, r, g, b, a)

        renderer.rectangle(x + pad + radius, y, w - pad_2 - radius_2, ht, r, g, b, a)
        renderer.rectangle(x + pad + radius, y + h, w - pad_2 - radius_2, -ht, r, g, b, a)
    end
end

local main do
    local rage do
        local force_body_conditions do
            local ref = resource.main.ragebot.force_body_conditions

            local HITGROUP_HEAD = 1
            local HITGROUP_STOMACH = 3
            local HITGROUP_LEFTLEG = 6
            local HITGROUP_RIGHTLEG = 7

            local ref_minimum_damage = ui.reference(
                'Rage', 'Aimbot', 'Minimum damage'
            )

            local manipulation do
                manipulation = { }

                local item_data = { }

                function manipulation.set(entindex, item_name, ...)
                    if item_data[entindex] == nil then
                        item_data[entindex] = { }
                    end

                    if item_data[entindex][item_name] == nil then
                        item_data[entindex][item_name] = {
                            plist.get(entindex, item_name)
                        }
                    end

                    plist.set(entindex, item_name, ...)
                end

                function manipulation.unset(entindex, item_name)
                    local entity_data = item_data[entindex]

                    if entity_data == nil then
                        return
                    end

                    local item_values = entity_data[item_name]

                    if item_values == nil then
                        return
                    end

                    plist.set(entindex, item_name, unpack(item_values))

                    entity_data[item_name] = nil
                end

                function manipulation.override(entindex, item_name, ...)
                    if ... ~= nil then
                        manipulation.set(entindex, item_name, ...)
                    else
                        manipulation.unset(entindex, item_name)
                    end
                end
            end

            local player_data = { }

            local function create_player_data()
                local data = {
                    misses = 0,

                    body_aim = false
                }

                return data
            end

            local function get_player_data(index)
                return player_data[index]
            end

            local function get_or_create_player_data(index)
                local data = get_player_data(index)

                if data == nil then
                    data = create_player_data()
                    player_data[index] = data
                end

                return data
            end

            local function delete_player_data(index)
                player_data[index] = nil
            end

            local function clear_player_data()
                for k in pairs(player_data) do
                    delete_player_data(k)
                end
            end

            local function restore_player_list()
                local enemies = entity.get_players(true)

                for i = 1, #enemies do
                    manipulation.unset(enemies[i], 'Override prefer body aim')
                end
            end

            local function restore_ragebot_values()
                ragebot.unset(ref_minimum_damage)
            end

            local function get_hitbox_damage_mult(hitgroup)
                if hitgroup == HITGROUP_HEAD then
                    return 4.0
                end

                if hitgroup == HITGROUP_STOMACH then
                    return 1.25
                end

                if hitgroup == HITGROUP_LEFTLEG then
                    return 0.75
                end

                if hitgroup == HITGROUP_RIGHTLEG then
                    return 0.75
                end

                return 1.0
            end

            local function scale_damage(enemy, damage, hitgroup, weapon_armor_ratio)
                damage = damage * get_hitbox_damage_mult(hitgroup)

                local m_ArmorValue = entity.get_prop(enemy, 'm_ArmorValue')
                local m_bHasHelmet = entity.get_prop(enemy, 'm_bHasHelmet')

                if m_ArmorValue > 0 then
                    if hitgroup == HITGROUP_HEAD then
                        if m_bHasHelmet ~= 0 then
                            damage = damage * (weapon_armor_ratio * 0.5)
                        end
                    else
                        damage = damage * (weapon_armor_ratio * 0.5)
                    end
                end

                return damage
            end

            local function simulate_damage(start_pos, end_pos, enemy, hitgroup, weapon)
                local data = csgo_weapons(weapon)
                local delta = end_pos - start_pos

                local damage = data.damage
                local armor_ratio = data.armor_ratio

                local range = data.range
                local range_modifier = data.range_modifier

                local length = math.min(range, delta:length())

                damage = damage * math.pow(range_modifier, length * 0.002)
                damage = scale_damage(enemy, damage, hitgroup, armor_ratio)

                return damage
            end

            local function is_lethal(start_pos, end_pos, enemy, hitgroup, weapon)
                local damage = simulate_damage(start_pos, end_pos, enemy, hitgroup, weapon)
                local health = entity.get_prop(enemy, 'm_iHealth')

                return damage >= health
            end

            local function get_weapon_type(weapon)
                local weapon_info = csgo_weapons(weapon)

                if weapon_info == nil then
                    return nil
                end

                local weapon_type = weapon_info.type
                local weapon_index = weapon_info.idx

                if weapon_type == 'pistol' then
                    if weapon_index == 1 then
                        return 'Desert Eagle'
                    end

                    if weapon_index == 64 then
                        return 'Revolver R8'
                    end

                    return 'Pistols'
                end

                if weapon_type == 'sniperrifle' then
                    if weapon_index == 40 then
                        return 'Scout'
                    end

                    if weapon_index == 9 then
                        return 'AWP'
                    end

                    return 'Auto Snipers'
                end

                return nil
            end

            local function on_shutdown()
                clear_player_data()
                restore_player_list()
            end

            local function on_run_command(cmd)
                if ref.disabler:get() then
                    return
                end

                local me = entity.get_local_player()

                if me == nil then
                    return
                end

                local weapon = entity.get_player_weapon(me)

                if weapon == nil then
                    return
                end

                local weapon_type = get_weapon_type(weapon)

                if weapon_type == nil or not ref.weapons:get(weapon_type) then
                    return
                end

                local max_misses = ref.max_misses:get()

                local eye_pos = vector(client.eye_position())
                local my_health = entity.get_prop(me, 'm_iHealth')

                local is_max_misses = ref.conditions:get 'Max misses'
                local is_enemy_lethal = ref.conditions:get 'Enemy lethal'

                local enemies = entity.get_players(true)

                for i = 1, #enemies do
                    local enemy = enemies[i]

                    local player_data = get_or_create_player_data(enemy)

                    local stomach = vector(
                        entity.hitbox_position(enemy, 5)
                    )

                    local was_max_misses = is_max_misses
                        and player_data.misses >= max_misses

                    local was_is_enemy_lethal = is_enemy_lethal
                        and is_lethal(eye_pos, stomach, enemy, 3, weapon)

                    local is_force_body = (
                        was_max_misses or
                        was_is_enemy_lethal
                    )

                    if is_force_body then
                        manipulation.set(enemy, 'Override prefer body aim', 'Force')

                        if was_max_misses and weapon_type == 'Scout' then
                            local damage = ref.scout_damage:get()

                            local should_change_min_damage = (
                                my_health == 100 and damage > 0
                            )

                            if should_change_min_damage then
                                ragebot.set(ref_minimum_damage, damage)
                            end
                        end
                    end

                    player_data.body_aim = is_force_body
                end
            end

            local function on_finish_command(cmd)
                restore_player_list()
                restore_ragebot_values()
            end

            local function on_aim_miss(e)
                local target = e.target

                if target == nil then
                    return
                end

                local target_data = get_or_create_player_data(target) do
                    target_data.misses = target_data.misses + 1
                end
            end

            local function on_player_death(e)
                local me = entity.get_local_player()

                local userid = client.userid_to_entindex(e.userid)
                local attacker = client.userid_to_entindex(e.attacker)

                if me ~= attacker or me == userid then
                    return
                end

                delete_player_data(userid)
            end

            local function on_player_spawn(e)
                local userid = client.userid_to_entindex(e.userid)

                if userid == nil then
                    return
                end

                delete_player_data(userid)
            end

            local callbacks do
                local function on_enabled(item)
                    local value = item:get()

                    if not value then
                        clear_player_data()

                        restore_player_list()
                        restore_ragebot_values()
                    end

                    utils.event_callback(
                        'shutdown',
                        on_shutdown,
                        value
                    )

                    utils.event_callback(
                        'run_command',
                        on_run_command,
                        value
                    )

                    utils.event_callback(
                        'finish_command',
                        on_finish_command,
                        value
                    )

                    utils.event_callback(
                        'aim_miss',
                        on_aim_miss,
                        value
                    )

                    utils.event_callback(
                        'player_death',
                        on_player_death,
                        value
                    )

                    utils.event_callback(
                        'player_spawn',
                        on_player_spawn,
                        value
                    )
                end

                ref.enabled:set_callback(
                    on_enabled, true
                )
            end
        end

        local force_lethal do
            local ref = resource.main.ragebot.force_lethal
            local ref_hitchance = resource.main.ragebot.hitchance

            local shared = session.force_lethal

            local ref_force_body_aim = ui.reference(
                'Rage', 'Aimbot', 'Force body aim'
            )

            local ref_hit_chance = ui.reference(
                'Rage', 'Aimbot', 'Minimum hit chance'
            )

            local ref_minimum_damage = ui.reference(
                'Rage', 'Aimbot', 'Minimum damage'
            )

            local function get_weapon_type(weapon)
                local weapon_info = csgo_weapons(weapon)

                if weapon_info == nil then
                    return nil
                end

                local weapon_index = weapon_info.idx

                if weapon_index == 1 then
                    return 'Desert Eagle'
                end

                if weapon_index == 11 or weapon_index == 38 then
                    return 'Auto Snipers'
                end

                return nil
            end

            local function update_force_lethal()
                local me = entity.get_local_player()

                if me == nil then
                    return
                end

                local weapon = entity.get_player_weapon(me)

                if weapon == nil then
                    return
                end

                local weapon_type = get_weapon_type(weapon)

                if weapon_type == nil then
                    return
                end

                if not ref.weapons:get(weapon_type) then
                    return
                end

                local mode = ref.mode:get()

                local is_double_tap = (
                    software.is_double_tap_active()
                    and exploit.get().shift
                )

                local should_hp_damage = (
                    not is_double_tap and
                    not ui.get(ref_force_body_aim)
                )

                if should_hp_damage then
                    ragebot.set(ref_minimum_damage, 100)

                    if not ref_hitchance.enabled:get() then
                        local items = ref[weapon_type]

                        if items ~= nil and items.hitchance ~= nil then
                            local value = items.hitchance:get()

                            if value ~= -1 then
                                ragebot.set(ref_hit_chance, value)
                            end
                        end
                    end

                    shared.updated_division = false
                    shared.updated_this_tick = true

                    return
                end

                if mode == 'Damage = HP/2' then
                    local threat = client.current_threat()

                    if threat == nil then
                        return
                    end

                    local health = entity.get_prop(
                        threat, 'm_iHealth'
                    )

                    ragebot.set(ref_minimum_damage, math.ceil(health / 2))

                    shared.updated_division = true
                    shared.updated_this_tick = true

                    return
                end
            end

            local function on_shutdown()
                ragebot.unset(ref_minimum_damage)
            end

            local function on_run_command()
                shared.updated_division = false
                shared.updated_this_tick = false

                update_force_lethal()
            end

            local function on_finish_command()
                if not ref_hitchance.enabled:get() then
                    ragebot.unset(ref_hit_chance)
                end

                ragebot.unset(ref_minimum_damage)
            end

            local function on_paint()
                if software.is_override_minimum_damage() then
                    return
                end

                local me = entity.get_local_player()

                if me == nil or not entity.is_alive(me) then
                    return
                end

                if shared.updated_this_tick then
                    local r, g, b, a = 255, 0, 50, 255

                    if shared.updated_division then
                        r, g, b, a = 255, 255, 255, 200
                    end

                    renderer.indicator(r, g, b, a, 'FL')
                end
            end

            local callbacks do
                local function on_enabled(item)
                    local value = item:get()

                    if not value then
                        ragebot.unset(ref_minimum_damage)
                    end

                    utils.event_callback(
                        'shutdown',
                        on_shutdown,
                        value
                    )

                    utils.event_callback(
                        'run_command',
                        on_run_command,
                        value
                    )

                    utils.event_callback(
                        'finish_command',
                        on_finish_command,
                        value
                    )

                    utils.event_callback(
                        'paint',
                        on_paint,
                        value
                    )
                end

                ref.enabled:set_callback(
                    on_enabled, true
                )
            end
        end

        local auto_hide_shots do
            local ref = resource.main.ragebot.auto_hide_shots

            local ref_duck_peek_assist = ui.reference(
                'Rage', 'Other', 'Duck peek assist'
            )

            local ref_quick_peek_assist = {
                ui.reference('Rage', 'Other', 'Quick peek assist')
            }

            local ref_double_tap = {
                ui.reference('Rage', 'Aimbot', 'Double tap')
            }

            local ref_on_shot_antiaim = {
                ui.reference('AA', 'Other', 'On shot anti-aim')
            }

            local function get_state()
                if not localplayer.is_onground then
                    if localplayer.is_crouched then
                        return 'Air-Crouch'
                    end

                    return 'Air'
                end

                if localplayer.is_crouched then
                    if localplayer.is_moving then
                        return 'Move-Crouch'
                    end

                    return 'Crouch'
                end

                if localplayer.is_moving then
                    if software.is_slow_motion() then
                        return 'Slow Walk'
                    end

                    return 'Moving'
                end

                return 'Standing'
            end

            local function get_weapon_type(weapon)
                local weapon_info = csgo_weapons(weapon)

                if weapon_info == nil then
                    return nil
                end

                local weapon_type = weapon_info.type
                local weapon_index = weapon_info.idx

                if weapon_type == 'smg' then
                    return 'SMG'
                end

                if weapon_type == 'rifle' then
                    return 'Rifles'
                end

                if weapon_type == 'pistol' then
                    if weapon_index == 1 then
                        return 'Desert Eagle'
                    end

                    if weapon_index == 64 then
                        return 'Revolver R8'
                    end

                    return 'Pistols'
                end

                if weapon_type == 'sniperrifle' then
                    if weapon_index == 40 then
                        return 'Scout'
                    end

                    if weapon_index == 9 then
                        return 'AWP'
                    end

                    return 'Auto Snipers'
                end

                return nil
            end

            local function restore_values()
                ragebot.unset(ref_double_tap[1])

                override.unset(ref_on_shot_antiaim[1])
                override.unset(ref_on_shot_antiaim[2])
            end

            local function update_values()
                ragebot.set(ref_double_tap[1], false)

                override.set(ref_on_shot_antiaim[1], true)
                override.set(ref_on_shot_antiaim[2], 'Always on')
            end

            local function should_update()
                if ui.get(ref_duck_peek_assist) then
                    return false
                end

                local is_quick_peek_assist = (
                    ui.get(ref_quick_peek_assist[1]) and
                    ui.get(ref_quick_peek_assist[2])
                )

                if is_quick_peek_assist then
                    return false
                end

                if not ui.get(ref_double_tap[2]) then
                    return false
                end

                local me = entity.get_local_player()

                if me == nil then
                    return false
                end

                local weapon = entity.get_player_weapon(me)

                if weapon == nil then
                    return false
                end

                local weapon_type = get_weapon_type(weapon)

                if weapon_type == nil or not ref.weapons:get(weapon_type) then
                    return false
                end

                local state = get_state()

                if not ref.states:get(state) then
                    return false
                end

                return true
            end

            local function on_shutdown()
                restore_values()
            end

            local function on_setup_command()
                if should_update() then
                    update_values()
                else
                    restore_values()
                end
            end

            local callbacks do
                local function on_enabled(item)
                    local value = item:get()

                    if not value then
                        restore_values()
                    end

                    utils.event_callback(
                        'shutdown',
                        on_shutdown,
                        value
                    )

                    utils.event_callback(
                        'setup_command',
                        on_setup_command,
                        value
                    )
                end

                ref.enabled:set_callback(
                    on_enabled, true
                )
            end
        end

        local allow_duck_on_fd do
            local ref = resource.main.ragebot.allow_duck_on_fd

            local ref_duck_peek_assist = ui.reference(
                'Rage', 'Other', 'Duck peek assist'
            )

            local should_override = false

            local function on_shutdown()
                override.unset(ref_duck_peek_assist)
            end

            local function on_setup_command(cmd)
                local me = entity.get_local_player()

                if me == nil then
                    return
                end

                local duck_amount = entity.get_prop(
                    me, 'm_flDuckAmount'
                )

                local should_unoverride = (
                    ui.is_menu_open() or
                    cmd.in_duck == 0 or
                    not localplayer.is_onground
                )

                if should_unoverride then
                    should_override = false
                elseif duck_amount > 0.75 then
                    should_override = true
                end

                if should_override then
                    override.set(ref_duck_peek_assist, 'On hotkey', 0)
                else
                    override.unset(ref_duck_peek_assist)
                end
            end

            local callbacks do
                local function on_enabled(item)
                    local value = item:get()

                    if not value then
                        override.unset(ref_duck_peek_assist)
                    end

                    utils.event_callback(
                        'shutdown',
                        on_shutdown,
                        value
                    )

                    utils.event_callback(
                        'setup_command',
                        on_setup_command,
                        value
                    )
                end

                ref.enabled:set_callback(
                    on_enabled, true
                )
            end
        end

        local unsafe_recharge do
            local ref = resource.main.ragebot.unsafe_recharge

            local prev_state = false

            local ref_enabled = {
                ui.reference('Rage', 'Aimbot', 'Enabled')
            }

            local ref_double_tap = {
                ui.reference('Rage', 'Aimbot', 'Double tap')
            }

            local ref_on_shot_antiaim = {
                ui.reference('AA', 'Other', 'On shot anti-aim')
            }

            local ref_duck_peek_assist = ui.reference(
                'Rage', 'Other', 'Duck peek assist'
            )

            local function is_double_tap_active()
                return ui.get(ref_double_tap[1])
                    and ui.get(ref_double_tap[2])
            end

            local function is_on_shot_antiaim_active()
                return ui.get(ref_on_shot_antiaim[1])
                    and ui.get(ref_on_shot_antiaim[2])
            end

            local function is_tickbase_changed(player)
                return (globals.tickcount() - entity.get_prop(player, 'm_nTickBase')) > 0
            end

            local function should_change(me, weapon)
                local weapon_info = csgo_weapons(weapon)

                if weapon_info == nil then
                    return false
                end

                local threat = client.current_threat()

                if threat == nil then
                    return false
                end

                local esp_data = entity.get_esp_data(threat)

                if esp_data == nil then
                    return false
                end

                local esp_flags = esp_data.flags

                if esp_flags == nil then
                    return false
                end

                if bit.band(esp_flags, 2048) == 0 then
                    return false
                end

                if ui.get(ref_duck_peek_assist) then
                    return false
                end

                local state = is_double_tap_active()
                local charged = exploit.get().shift

                if prev_state ~= state then
                    if state and not charged then
                        return true
                    end

                    prev_state = state
                end

                if is_on_shot_antiaim_active() then
                    return not is_tickbase_changed(me)
                end

                return false
            end

            local function update_values()
                ragebot.set(ref_enabled[1], false)
            end

            local function restore_values()
                ragebot.unset(ref_enabled[1])
            end

            local function on_shutdown()
                restore_values()
            end

            local function on_setup_command()
                local me = entity.get_local_player()

                if me == nil then
                    return false
                end

                local weapon = entity.get_player_weapon(me)

                if weapon == nil then
                    return false
                end

                if should_change(me, weapon) then
                    update_values()
                else
                    restore_values()
                end
            end

            local function update_event_callbacks(value)
                if not value then
                    restore_values()
                end

                utils.event_callback(
                    'shutdown',
                    on_shutdown,
                    value
                )

                utils.event_callback(
                    'setup_command',
                    on_setup_command,
                    value
                )
            end

            local callbacks do
                local function on_enabled(item)
                    update_event_callbacks(item:get())
                end

                ref.enabled:set_callback(
                    on_enabled, true
                )
            end
        end

        local hideshots_fix do
            local ref = resource.main.ragebot.hideshots_fix

            local ref_fake_lag_enabled = {
                ui.reference('AA', 'Fake lag', 'Enabled')
            }

            local function restore_values()
                override.unset(ref_fake_lag_enabled[1])
            end

            local function update_values()
                override.set(ref_fake_lag_enabled[1], false)
            end

            local function on_shutdown()
                restore_values()
            end

            local function on_paint_ui()
                restore_values()
            end

            local function on_setup_command()
                local is_fake_duck = software.is_duck_peek_assist()
                local is_double_tap = software.is_double_tap_active()
                local is_on_shot_antiaim = software.is_on_shot_antiaim_active()

                local should_update = (
                    is_on_shot_antiaim
                    and not is_double_tap
                    and not is_fake_duck
                )

                if should_update then
                    update_values()
                else
                    restore_values()
                end
            end

            local function update_event_callbacks(value)
                if not value then
                    restore_values()
                end

                utils.event_callback(
                    'shutdown',
                    on_shutdown,
                    value
                )

                utils.event_callback(
                    'paint_ui',
                    on_paint_ui,
                    value
                )

                utils.event_callback(
                    'setup_command',
                    on_setup_command,
                    value
                )
            end

            local callbacks do
                local function on_enabled(item)
                    update_event_callbacks(item:get())
                end

                ref.enabled:set_callback(
                    on_enabled, true
                )
            end
        end

        local hitchance do
            local ref = resource.main.ragebot.hitchance
            local ref_force_lethal = resource.main.ragebot.force_lethal

            local shared = session.hitchance

            local UNITS_TO_FOOT = 0.0254 * 3.28084

            local ref_hit_chance = ui.reference(
                'Rage', 'Aimbot', 'Minimum hit chance'
            )

            local function get_distance(player, target)
                if player == nil or target == nil then
                    return nil
                end

                local player_origin = vector(entity.get_origin(player))
                local target_origin = vector(entity.get_origin(target))

                return (target_origin - player_origin):length()
            end

            local function get_value(me, weapon_type, items)
                local threat = client.current_threat()

                local force_lethal_value = nil do
                    local is_double_tap = (
                        software.is_double_tap_active()
                        and exploit.get().shift
                    )

                    if ref_force_lethal.enabled:get() and not is_double_tap then
                        local items = ref_force_lethal[weapon_type]

                        if items ~= nil and items.hitchance ~= nil then
                            local value = items.hitchance:get()

                            if value ~= -1 then
                                force_lethal_value = value
                            end
                        end
                    end
                end

                if items.options:get 'Hotkey' and ref.hotkey:get() then
                    shared.updated_hotkey = true
                    return items['Hotkey'].value:get()
                end

                if items.options:get 'Crouch' then
                    local is_crouched = (
                        localplayer.is_onground and
                        localplayer.is_crouched and
                        not software.is_duck_peek_assist()
                    )

                    if is_crouched then
                        return items['Crouch'].value:get()
                    end
                end

                if items.options:get 'Peek Assist' and software.is_quick_peek_assist() then
                    return items['Peek Assist'].value:get()
                end

                if items.options:get 'No Scope' then
                    local goal_distance = items['No Scope'].distance:get()
                    local hitchance_value = items['No Scope'].value:get()

                    if goal_distance == 101 then
                        return hitchance_value
                    end

                    local distance = get_distance(me, threat)

                    if distance ~= nil and (distance * UNITS_TO_FOOT) <= goal_distance then
                        return hitchance_value
                    end
                end

                if items.options:get 'In Air' and not localplayer.is_onground then
                    return items['In Air'].value:get()
                end

                if force_lethal_value ~= nil then
                    return force_lethal_value
                end
            end

            local function get_weapon_type(weapon)
                local weapon_info = csgo_weapons(weapon)

                if weapon_info == nil then
                    return nil
                end

                local weapon_type = weapon_info.type
                local weapon_index = weapon_info.idx

                if weapon_type == 'pistol' then
                    if weapon_index == 1 then
                        return 'Desert Eagle'
                    end

                    if weapon_index == 64 then
                        return 'Revolver R8'
                    end

                    return 'Pistols'
                end

                if weapon_type == 'sniperrifle' then
                    if weapon_index == 40 then
                        return 'Scout'
                    end

                    if weapon_index == 9 then
                        return 'AWP'
                    end

                    return 'Auto Snipers'
                end

                return nil
            end

            local function update_hitchance()
                local me = entity.get_local_player()

                if me == nil then
                    return
                end

                local weapon = entity.get_player_weapon(me)

                if weapon == nil then
                    return
                end

                local weapon_type = get_weapon_type(weapon)

                if weapon_type == nil then
                    return
                end

                local items = ref[weapon_type]

                if items == nil then
                    return
                end

                local value = get_value(
                    me, weapon_type, items
                )

                if value == nil then
                    return
                end

                ragebot.set(ref_hit_chance, value)
                shared.updated_this_tick = true
            end

            local function on_shutdown()
                ragebot.unset(ref_hit_chance)
            end

            local function on_run_command()
                shared.updated_hotkey = false
                shared.updated_this_tick = false

                update_hitchance()
            end

            local function on_finish_command()
                ragebot.unset(ref_hit_chance)
            end

            local function on_paint()
                local me = entity.get_local_player()

                if me == nil or not entity.is_alive(me) then
                    return
                end

                local should_render = (
                    shared.updated_hotkey and
                    shared.updated_this_tick
                )

                if not should_render then
                    return
                end

                local text = ref.indicator_text:get()

                if text == 'Off' then
                    return
                end

                renderer.indicator(255, 255, 255, 200, text)
            end

            local function on_pre_config_save()
                ragebot.unset(ref_hit_chance)
            end

            local callbacks do
                local function on_enabled(item)
                    local value = item:get()

                    if not value then
                        ragebot.unset(ref_hit_chance)
                    end

                    utils.event_callback(
                        'shutdown',
                        on_shutdown,
                        value
                    )

                    utils.event_callback(
                        'run_command',
                        on_run_command,
                        value
                    )

                    utils.event_callback(
                        'finish_command',
                        on_finish_command,
                        value
                    )

                    utils.event_callback(
                        'paint',
                        on_paint,
                        value
                    )

                    utils.event_callback(
                        'pre_config_save',
                        on_pre_config_save,
                        value
                    )
                end

                ref.enabled:set_callback(
                    on_enabled, true
                )
            end
        end

        local quick_peek_auto_stop do
            local ref = resource.main.ragebot.quick_peek_auto_stop

            local ref_quick_stop = {
                ui.reference('Rage', 'Aimbot', 'Quick stop')
            }

            local function get_weapon_type(weapon)
                local weapon_info = csgo_weapons(weapon)

                if weapon_info == nil then
                    return nil
                end

                local weapon_type = weapon_info.type
                local weapon_index = weapon_info.idx

                if weapon_type == 'pistol' then
                    if weapon_index == 1 then
                        return 'Desert Eagle'
                    end

                    if weapon_index == 64 then
                        return 'Revolver R8'
                    end

                    return 'Pistols'
                end

                if weapon_type == 'sniperrifle' then
                    if weapon_index == 40 then
                        return 'Scout'
                    end

                    if weapon_index == 9 then
                        return 'AWP'
                    end

                    return 'Auto Snipers'
                end

                return nil
            end

            local function on_shutdown()
                ragebot.unset(ref_quick_stop[3])
            end

            local function on_setup_command()
                local me = entity.get_local_player()

                if me == nil then
                    return
                end

                local weapon = entity.get_player_weapon(me)

                if weapon == nil then
                    return
                end

                local weapon_type = get_weapon_type(weapon)

                if weapon_type == nil then
                    return
                end

                local items = ref[weapon_type]

                if items == nil or not items.enabled:get() then
                    return
                end

                if software.is_quick_peek_assist() then
                    ragebot.set(ref_quick_stop[3], items.auto_stop:get())
                end
            end

            local function on_finish_command()
                ragebot.unset(ref_quick_stop[3])
            end

            local function on_pre_config_save()
                ragebot.unset(ref_quick_stop[3])
            end

            local callbacks do
                local function on_enabled(item)
                    local value = item:get()

                    if not value then
                        ragebot.unset(ref_quick_stop[3])
                    end

                    utils.event_callback(
                        'shutdown',
                        on_shutdown,
                        value
                    )

                    utils.event_callback(
                        'setup_command',
                        on_setup_command,
                        value
                    )

                    utils.event_callback(
                        'finish_command',
                        on_finish_command,
                        value
                    )

                    utils.event_callback(
                        'pre_config_save',
                        on_pre_config_save,
                        value
                    )
                end

                ref.enabled:set_callback(
                    on_enabled, true
                )
            end
        end
    end

    local anim_breaker do
        local ref = resource.main.animations

        local ANIMATION_LAYER_MOVEMENT_MOVE = 6
        local ANIMATION_LAYER_LEAN = 12

        local anim_data = {
            layers = {
                [0] = { cycle = 0, weight = 0 }, -- aim_matrix
                [1] = { cycle = 0, weight = 0 }, -- weapon_action
                [2] = { cycle = 0, weight = 0 }, -- weapon_action_recrouch
                [3] = { cycle = 0, weight = 0 }, -- adjust
                [4] = { cycle = 0, weight = 0 }, -- movement_move
                [5] = { cycle = 0, weight = 0 }, -- movement_strafe
                [6] = { cycle = 0, weight = 0 }, -- movement_strafechange
                [7] = { cycle = 0, weight = 0 }, -- whole_body
                [8] = { cycle = 0, weight = 0 }, -- flashed
                [9] = { cycle = 0, weight = 0 }, -- flinch
                [10] = { cycle = 0, weight = 0 }, -- aliveloop
                [11] = { cycle = 0, weight = 0 }, -- jump
                [12] = { cycle = 0, weight = 0 }, -- land
                [13] = { cycle = 0, weight = 0 }, -- move_blend_walk
                [14] = { cycle = 0, weight = 0 }, -- move_blend_run
                [15] = { cycle = 0, weight = 0 }, -- move_blend_crouch
            },

            server_anim_states = { },

            last_sim_time = 0,
            last_velocity = 0,
            last_duck_amount = 0,
            last_weapon = nil,
        }

        local function update_air_legs(player, layer)
            if player == nil or layer == nil then
                return
            end

            local value = ref.air_legs:get()

            if value == 'Static' then
                local weight = ref.air_legs_weight:get()
                entity.set_prop(player, 'm_flPoseParameter', weight * 0.01, 6)

                return
            end

            if value == 'Moonwalk' then
                layer.weight = 1.0
                layer.cycle = (globals.curtime() * 0.55) % 1

                return
            end

            if value == 'Kangaroo' then
                entity.set_prop(player, 'm_flPoseParameter', math.random(), 3)
                entity.set_prop(player, 'm_flPoseParameter', math.random(), 7)
                entity.set_prop(player, 'm_flPoseParameter', math.random(), 6)

                return
            end
        end

        local function update_ground_legs(player)
            local value = ref.ground_legs:get()

            if value == 'Static' then
                entity.set_prop(player, 'm_flPoseParameter', 1.0, 0)
                override.set(software.antiaimbot.other.leg_movement, 'Always slide')

                return
            end

            if value == 'Jitter' then
                local tickcount = globals.tickcount()

                local offset_1 = ref.legs_offset_1:get()
                local offset_2 = ref.legs_offset_2:get()

                local speed = ref.legs_jitter_time:get()

                local mul = 1.0 / (tickcount % (speed * 4) >= (speed * 2) and 200 or 400)
                local offset = tickcount % (speed * 2) >= (speed) and offset_1 or offset_2

                entity.set_prop(player, 'm_flPoseParameter', offset * mul, 0)
                override.set(software.antiaimbot.other.leg_movement, 'Always slide')

                return
            end

            if value == 'Moonwalk' then
                entity.set_prop(player, 'm_flPoseParameter', 0.0, 7)
                override.set(software.antiaimbot.other.leg_movement, 'Never slide')

                return
            end

            if value == 'Kangaroo' then
                entity.set_prop(player, 'm_flPoseParameter', math.random(), 3)
                entity.set_prop(player, 'm_flPoseParameter', math.random(), 7)
                entity.set_prop(player, 'm_flPoseParameter', math.random(), 6)

                override.unset(software.antiaimbot.other.leg_movement)

                return
            end

            if value == 'Pacan4ik' then
                local offset_1 = ref.legs_offset_1:get() * 0.01
                local offset_2 = ref.legs_offset_2:get() * 0.01

                local leg_movement = utils.random_int(0, 1) == 0
                    and 'Off' or 'Always slide'

                entity.set_prop(player, 'm_flPoseParameter', utils.random_float(offset_1, offset_2), 0)
                override.set(software.antiaimbot.other.leg_movement, leg_movement)

                return
            end

            override.unset(software.antiaimbot.other.leg_movement)
        end

        local function update_pitch_on_land(player, animstate)
            if not ref.options:get 'Pitch zero on land' then
                return
            end

            if animstate.hit_in_ground_animation then
                entity.set_prop(player, 'm_flPoseParameter', 0.5, 12)
            end
        end

        local function update_move_lean(layer)
            if not ref.options:get 'Move lean' then
                return
            end

            local value = ref.move_lean:get()

            if value == -1 or not localplayer.is_moving then
                return
            end

            layer.weight = value
        end

        local function update_animfix_data(cmd)
            local me = entity.get_local_player()

            if me == nil then
                return
            end

            local entity_info = c_entity(me)

            if entity_info == nil then
                return
            end

            local anim_state = entity_info:get_anim_state()

            if anim_state == nil then
                return
            end

            local layer_move = entity_info:get_anim_overlay(ANIMATION_LAYER_MOVEMENT_MOVE)
            local layer_lean = entity_info:get_anim_overlay(ANIMATION_LAYER_LEAN)

            if localplayer.is_onground then
                update_ground_legs(me)
                update_pitch_on_land(me, anim_state)
            else
                update_air_legs(me, layer_move)
            end

            update_move_lean(layer_lean)

            local sim_time = globals.servertickcount()
            local vel_x, vel_y = entity.get_prop(me, 'm_vecVelocity')
            local velocity = math.sqrt(vel_x * vel_x + vel_y * vel_y)
            local duck_amount = entity.get_prop(me, 'm_flDuckAmount')
            local ducking = entity.get_prop(me, 'm_bDucking') == 1
            local on_ground = bit.band(entity.get_prop(me, 'm_fFlags'), 1) == 1
            local current_weapon = entity.get_player_weapon(me)

            if velocity < 0.1 then
                velocity = 0
            end

            local server_state = {
                layers = { },
                time = sim_time,
                ducking = ducking,
                on_ground = on_ground,
                velocity = velocity,
                duck_amount = duck_amount,
                weapon = current_weapon
            }

            for layer_idx, _ in pairs(anim_data.layers) do
                local layer = entity_info:get_anim_overlay(layer_idx)

                if layer ~= nil then
                    server_state.layers[layer_idx] = {
                        cycle = layer.cycle,
                        weight = layer.weight
                    }
                end
            end

            table.insert(anim_data.server_anim_states, server_state)

            if #anim_data.server_anim_states > 60 then
                table.remove(anim_data.server_anim_states, 1)
            end
        end

        local function update_animfix_render()
            if not ref.options:get 'Smooth animfix' then
                return
            end

            local me = entity.get_local_player()

            if me == nil then
                return
            end

            local entity_info = c_entity(me)

            if entity_info == nil then
                return
            end

            local anim_state = entity_info:get_anim_state()

            if anim_state == nil then
                return
            end

            local current_time = globals.realtime()
            local server_states = anim_data.server_anim_states

            if #server_states < 2 then
                return
            end

            local state1, state2

            for i = #server_states - 1, 1, -1 do
                if server_states[i].time <= current_time and server_states[i + 1].time >= current_time then
                    state1 = server_states[i]
                    state2 = server_states[i + 1]

                    break
                end
            end

            if not state1 or not state2 then
                state1 = server_states[#server_states - 1]
                state2 = server_states[#server_states]
            end

            local t = (current_time - state1.time) / (state2.time - state1.time)
            t = math.max(0, math.min(t, 1))

            for layer_idx, _ in pairs(anim_data.layers) do
                local layer = entity_info:get_anim_overlay(layer_idx)

                if layer and state1.layers[layer_idx] and state2.layers[layer_idx] then
                    local cycle1 = state1.layers[layer_idx].cycle
                    local cycle2 = state2.layers[layer_idx].cycle
                    local weight1 = state1.layers[layer_idx].weight
                    local weight2 = state2.layers[layer_idx].weight

                    if (layer_idx == 1 or layer_idx == 2) and state1.weapon ~= state2.weapon then
                        layer.cycle = cycle2
                        layer.weight = weight2
                    else
                        layer.cycle = utils.lerp(cycle1, cycle2, t)
                        layer.weight = utils.lerp(weight1, weight2, t)
                    end
                end
            end

            local velocity = utils.lerp(state1.velocity, state2.velocity, t)
            local duck_amount = utils.lerp(state1.duck_amount, state2.duck_amount, t)

            local current_weapon = state1.weapon

            anim_data.last_velocity = velocity
            anim_data.last_duck_amount = duck_amount
            anim_data.last_weapon = current_weapon
        end

        local function restore_values()
            override.unset(software.antiaimbot.other.leg_movement)
        end

        local function on_shutdown()
            restore_values()
        end

        local function on_pre_render()
            local me = entity.get_local_player()

            if me == nil or not entity.is_alive(me) then
                return
            end

            local entity_info = c_entity(me)

            if entity_info == nil then
                return
            end

            local animstate = entity_info:get_anim_state()

            if animstate == nil then
                return
            end

            local layer_move = entity_info:get_anim_overlay(ANIMATION_LAYER_MOVEMENT_MOVE)
            local layer_lean = entity_info:get_anim_overlay(ANIMATION_LAYER_LEAN)

            update_animfix_render()

            if localplayer.is_onground then
                update_ground_legs(me)
                update_pitch_on_land(me, animstate)
            else
                update_air_legs(me, layer_move)
            end

            update_move_lean(layer_lean)
        end

        local function update_event_callbacks(value)
            if not value then
                restore_values()

                utils.event_callback(
                    'setup_command',
                    update_animfix_data,
                    false
                )
            end

            utils.event_callback(
                'shutdown',
                on_shutdown,
                value
            )

            utils.event_callback(
                'pre_render',
                on_pre_render,
                value
            )
        end

        local callbacks do
            local function on_options(item)
                local value = item:get 'Smooth animfix'

                utils.event_callback(
                    'setup_command',
                    update_animfix_data,
                    value
                )
            end

            ref.options:set_callback(
                on_options, true
            )

            update_event_callbacks(true)
        end
    end

    local miscellaneous do
        local drop_nades do
            local ref = resource.main.miscellaneous.drop_nades

            local queue = { }

            local throwing = false
            local old_state = nil

            local function is_allowed_class(item_class)
                if item_class == 'weapon_hegrenade' then
                    return ref.select:get 'HE'
                end

                if item_class == 'weapon_smokegrenade' then
                    return ref.select:get 'Smoke'
                end

                if item_class == 'weapon_incgrenade' or item_class == 'weapon_molotov' then
                    return ref.select:get 'Molotov'
                end

                return false
            end

            local function is_weapon_allowed(weapon)
                local info = csgo_weapons(weapon)

                if info.weapon_type_int ~= 9 then
                    return false
                end

                if not is_allowed_class(info.item_class) then
                    return false
                end

                return true
            end

            local function clear_queue()
                for i = 1, #queue do
                    queue[i] = nil
                end
            end

            local function update_queue(ent)
                local weapons = utils.get_player_weapons(ent)

                for i = 1, #weapons do
                    local weapon = weapons[i]

                    if not is_weapon_allowed(weapon) then
                        goto continue
                    end

                    table.insert(queue, weapon)
                    ::continue::
                end
            end

            local function on_setup_command(cmd)
                local me = entity.get_local_player()

                if me == nil then
                    return
                end

                local weapon = entity.get_player_weapon(me)

                if weapon == nil then
                    return
                end

                local state = ref.hotkey:get()

                if old_state ~= state then
                    old_state = state

                    if state and not throwing then
                        clear_queue()
                        update_queue(me)

                        throwing = next(queue) ~= nil
                    end
                end

                local latency = client.latency() + totime(4)

                for i = 1, #queue do
                    local grenade = queue[i]

                    if grenade == nil then
                        goto continue
                    end

                    local weapon_info = csgo_weapons(grenade)

                    if weapon_info == nil then
                        goto continue
                    end

                    local last = i == #queue

                    client.delay_call(latency * i, function()
                        client.exec(string.format(
                            'use %s; drop', weapon_info.item_class
                        ))

                        if last then
                            client.delay_call(0.1, function()
                                throwing = false
                            end)
                        end
                    end)

                    ::continue::
                end

                clear_queue()

                if throwing then
                    local pitch, yaw = client.camera_angles()

                    local offset = 0.0001

                    if pitch > 0 then
                        offset = -offset
                    end

                    cmd.yaw = yaw
                    cmd.pitch = pitch + offset

                    cmd.no_choke = true
                    cmd.allow_send_packet = true
                end
            end

            local function update_event_callbacks(value)
                if not value then
                    clear_queue()
                end

                utils.event_callback(
                    'setup_command',
                    on_setup_command,
                    value
                )
            end

            local callbacks do
                local function on_enabled(item)
                    update_event_callbacks(item:get())
                end

                ref.enabled:set_callback(
                    on_enabled, true
                )
            end
        end

        local enhance_grenade_release do
            local ref = resource.main.miscellaneous.enhance_grenade_release

            local ref_grenade_release = {
                ui.reference('Misc', 'Miscellaneous', 'Automatic grenade release')
            }

            local function get_weapon_type(weapon)
                local weapon_info = csgo_weapons(weapon)

                if weapon_info == nil then
                    return nil
                end

                local weapon_index = weapon_info.idx

                if weapon_index == 44 then
                    return 'HE Grenade'
                end

                if weapon_index == 45 then
                    return 'Smoke Grenade'
                end

                if weapon_index == 48 then
                    return 'Molotov'
                end

                return nil
            end

            local function is_double_tap_active()
                return software.is_double_tap_active()
                    and not software.is_duck_peek_assist()
            end

            local function should_disable(weapon)
                if ref.only_with_dt:get() then
                    local is_double_tap = (
                        is_double_tap_active()
                        and exploit.get().shift
                    )

                    if not is_double_tap then
                        return true
                    end
                end

                local weapon_type = get_weapon_type(weapon)

                if weapon_type == nil then
                    return false
                end

                return ref.disablers:get(
                    weapon_type
                )
            end

            local function on_shutdown()
                override.unset(ref_grenade_release[1])
            end

            local function on_paint_ui()
                override.unset(ref_grenade_release[1])
            end

            local function on_setup_command(cmd)
                local me = entity.get_local_player()

                if me == nil then
                    return
                end

                local weapon = entity.get_player_weapon(me)

                if weapon == nil then
                    return
                end

                if should_disable(weapon) then
                    override.set(ref_grenade_release[1], false)
                end
            end

            local function update_event_callbacks(value)
                if not value then
                    override.unset(ref_grenade_release[1])
                end

                utils.event_callback(
                    'shutdown',
                    on_shutdown,
                    value
                )

                utils.event_callback(
                    'paint_ui',
                    on_paint_ui,
                    value
                )

                utils.event_callback(
                    'setup_command',
                    on_setup_command,
                    value
                )
            end

            local callbacks do
                local function on_enabled(item)
                    update_event_callbacks(item:get())
                end

                ref.enabled:set_callback(
                    on_enabled, true
                )
            end
        end

        local fps_optimize do
            local ref = resource.main.miscellaneous.fps_optimize

            local changed = false

            local tree = { } do
                local function wrap(convar, value)
                    local item = { }

                    item.convar = convar
                    item.old_value = nil
                    item.new_value = value

                    return item
                end

                tree['Blood'] = {
                    wrap(cvar.violence_hblood, 0)
                }

                tree['Bloom'] = {
                    wrap(cvar.mat_disable_bloom, 1)
                }

                tree['Decals'] = {
                    wrap(cvar.r_drawdecals, 0)
                }

                tree['Shadows'] = {
                    wrap(cvar.r_shadows, 0),
                    wrap(cvar.cl_csm_static_prop_shadows, 0),
                    wrap(cvar.cl_csm_shadows, 0),
                    wrap(cvar.cl_csm_world_shadows, 0),
                    wrap(cvar.cl_foot_contact_shadows, 0),
                    wrap(cvar.cl_csm_viewmodel_shadows, 0),
                    wrap(cvar.cl_csm_rope_shadows, 0),
                    wrap(cvar.cl_csm_sprite_shadows, 0),
                    wrap(cvar.cl_csm_translucent_shadows, 0),
                    wrap(cvar.cl_csm_entity_shadows, 0),
                    wrap(cvar.cl_csm_world_shadows_in_viewmodelcascad, 0)
                }

                tree['Sprites'] = {
                    wrap(cvar.r_drawsprites, 0)
                }

                tree['Particles'] = {
                    wrap(cvar.r_drawparticles, 0)
                }

                tree['Ropes'] = {
                    wrap(cvar.r_drawropes, 0)
                }

                tree['Dynamic lights'] = {
                    wrap(cvar.mat_disable_fancy_blending, 1)
                }

                tree['Map details'] = {
                    wrap(cvar.func_break_max_pieces, 0),
                    wrap(cvar.props_break_max_pieces, 0)
                }

                tree['Weapon effects'] = {
                    wrap(cvar.muzzleflash_light, 0),
                    wrap(cvar.r_drawtracers_firstperson, 0)
                }
            end

            local function should_update()
                if ref.always_on:get() then
                    return true
                end

                if ref.detections:get 'Peeking' and localplayer.is_peeking then
                    return true
                end

                if ref.detections:get 'Hit flag' then
                    local enemies = entity.get_players(true)

                    for i = 1, #enemies do
                        local enemy = enemies[i]

                        local esp_data = entity.get_esp_data(enemy)

                        if esp_data == nil then
                            goto continue
                        end

                        -- if flag HIT is present
                        if bit.band(esp_data.flags, bit.lshift(1, 11)) ~= 0 then
                            return true
                        end

                        ::continue::
                    end
                end

                return false
            end

            local function restore_convars()
                if not changed then
                    return
                end

                for _, v in pairs(tree) do
                    for i = 1, #v do
                        local item = v[i]
                        local convar = item.convar

                        if item.old_value == nil then
                            goto continue
                        end

                        convar:set_int(item.old_value)
                        item.old_value = nil

                        ::continue::
                    end
                end

                changed = false
            end

            local function update_convars()
                if changed then
                    return
                end

                local values = ref.list:get()

                for i = 1, #values do
                    local value = values[i]
                    local items = tree[value]

                    for j = 1, #items do
                        local item = items[j]
                        local convar = item.convar

                        if convar == nil or item.old_value ~= nil then
                            goto continue
                        end

                        item.old_value = convar:get_int()
                        convar:set_int(item.new_value)

                        ::continue::
                    end
                end

                changed = true
            end

            local function on_shutdown()
                restore_convars()
            end

            local function on_net_update_end()
                if not should_update() then
                    return restore_convars()
                end

                update_convars()
            end

            local callbacks do
                local function on_list(item)
                    restore_convars()
                    update_convars()
                end

                local function on_enabled(item)
                    local value = item:get()

                    if value then
                        ref.list:set_callback(on_list, true)
                    else
                        ref.list:unset_callback(on_list)
                    end

                    if not value then
                        restore_convars()
                    end

                    utils.event_callback(
                        'shutdown',
                        on_shutdown,
                        value
                    )

                    utils.event_callback(
                        'net_update_end',
                        on_net_update_end,
                        value
                    )
                end

                ref.enabled:set_callback(
                    on_enabled, true
                )
            end
        end

        local trash_talk do
            local ref = resource.main.miscellaneous.trash_talk

            local MESSAGES = {
                ['On Kill'] = {
                    {
                        { 'SHAMELESS достает из кейса: ★ Мать этого бомжа', 2.50 },
                    },

                    {
                        { '1', 0.70 },
                        { 'желейка хуевая)', 1.7 },
                    },

                    {
                        { 'ахахахха', 1.20 },
                        { 'позорище еба', 2.1 },
                        { 'ебаное', 1.4 },
                    },

                    {
                        { 'слоумо позорное', 1.60 },
                        { 'очень медленный', 2.0 },
                    },

                    {
                        { '1', 1.2 },
                    },

                    {
                        { 'зря ты умер', 1.8 },
                        { 'команду подвел', 1 },
                    },


                    {
                        { '[etdfz gbljhfcbyf', 2.1 },
                        { 'хуевая пидорасина', 2.1 },
                    },

                    {
                        { 'спокойной ночи', 2.1 },
                        { 'в сон отпрвил аххах', 2.6 },
                    },

                    {
                        { 'куда пикнул засранец', 2.1 },
                        { 'лучше бы по-другому сыграл', 2.9 },
                    },

                    {
                        { 'ᴨоᴄᴛᴀʙиᴧ ᴛʙою чоᴛᴋоᴄᴛь ᴨод ᴄоʍнᴇниᴇ', 2.8 }
                    },

                    {
                        { 'иди сюда', 1 },
                        { 'к папочке', 1.9 }
                    },

                    {
                        { 'THIS IS LCCCCCCC (◣_◢)', 2.3 },
                    },

                    {
                        { 'ты точно человек?', 1.9 },
                        { 'а то играешь как животное хуевое', 2.6 }
                    },

                    {
                        { 'Shameless. Подписаться', 2 },
                        { 'Maut. Отписаться', 2.5 }
                    },

                    {
                        { 'сосал?', 1.2 },
                        { 'соври', 1.8 },
                        { 'не ври', 2 }
                    },

                    {
                        { 'первый', 1.8 },
                        { 'не', 1.8 },
                        { 'последний день на хвх', 1.8 },
                        { 'зашел таких как ты поубивать', 1.9 }
                    },

                    {
                        { 'бля как так-то', 2.0 },
                        { 'не получилось забайтить', 2.4 },
                        { 'да?', 1.4 }
                    },

                    {
                        { 'чот я тебя тапаю все время', 2.3 },
                        { 'луасенс или что ты используешь', 2.8 }
                    },

                    {
                        { 'нормально я тебя забайтил', 2.4 }
                    },

                    {
                        { 'ты умер по какой причине???', 2.2 }
                    },

                    {
                        { 'сорян', 1.6 },
                        { 'просто чит сегодня бодрый', 2.3 }
                    },

                    {
                        { 'зря пикнул братан', 1.9 }
                    },

                    {
                        { 'какой же все таки хуевый у тебя чит', 3 }
                    },

                    {
                        { 'повезло', 1 },
                        { 'мне', 1 }
                    },

                    {
                        { 'новая приватная настройка у мя', 2.1 }
                    },

                    {
                        { 'легчайший килл', 2.0 },
                        { 'для сильнейшего игрока', 2.4 }
                    },

                    {
                        { 'переигран пидорас', 2.1 }
                    },

                    {
                        { 'прошу', 1.7 },
                        { 'не ливай с сервера', 2.3 }
                    },

                    {
                        { '1', 1 },
                        { 'negjq ,jv;', 2 },
                        { 'тупой бомж*', 2 },
                    },

                    {
                        { 'ахахаха', 2 },
                        { 'и ты себя игроком считаешь?', 2.5 },
                    },

                    {
                        { 'ой долбаеб', 2 },
                        { 'лучше ливай с сервера', 2 },
                        { '!admin', 2 },

                    },

                    {
                        { 'отпиздил хаченка', 2 },
                        { 'SMERT XA4AM LUA', 2 }
                    },

                    {
                        { 'пархай как папочка', 2 },
                        { 'жаль что я тебя тапнул', 2.5 }
                    },

                    {
                        { 'ты куда пикнул', 2 },
                        { 'догодяга ебаная', 2.5 }
                    },

                    {
                        { 'слабачок нищий', 2 },
                        { 'без аккаунта нормального', 2.5 }
                    },

                    {
                        { 'спи чмо', 2 }
                    },

                    {
                        { 'welcome to hell пидорас', 2.3 }
                    },

                    {
                        { '12', 1 },
                        { '1', 1 }
                    },

                    {
                        { 'упала шлюха', 2 },
                        { 'зря пикаешь такое', 2.5 }
                    },

                    {
                        { 'Создатель LUA MonixLITE ◣_◢', 2 }
                    },

                    {
                        { 'by filev', 2 }
                    },

                    {
                        { 'все это ты до и после хуй те в рот', 3 }
                    },

                    {
                        { 'на пенисяку говори', 2 },
                        { 'уебище', 1.6 }
                    },
                    {
                        { 'чистое лц', 1.20 },
                        { 'но я не брикал', 1.9 },
                    },

                    {
                        { 'откисай нубяра', 1.20 },
                        { 'в мой aesthetic попасть невозможно', 1.6 },
                    },

                    {
                        { 'пошел по комнате дымок╭∩╮(⋋‿⋌ )ᕗ✧', 1.20 },
                        { 'соснул ты бичик мой хуек (Ψ▼▼)Ψ', 1.20 },
                    },

                    {
                        { 'а это вам чаевые за беспокойство', 1.50 },
                    },

                    {
                        { 'тупой человек спросит, что лучше? GAMESENSE или NEVERLOSE???', 1.60 },
                        { 'а умный, AESTHETIC GS или AESTHETIC NL', 1.8 },
                    },

                    {
                        { 'ты думал будет брик? наебал', 1.50 },
                        { 'я с aesthetic, подпишись на канал @shamelesshvh', 1.7 },
                    },

                    {
                        { 'курт кобейн похоже не играл с эстетиком', 1.20 },
                    },

                    {
                        { 'даже моя аквариумная рыбка стала играть лучше брендона, когда релизнулся эстетик на скит', 1.20 },
                    },

                    {
                        { 'ебаная моча козлиная, куда собралась', 1.6 },
                    },

                    {
                        { 'умер на пабе дурачок', 1.2 },
                        { 'пердяй ебаный кабачок', 1.3 },
                    },

                    {
                        { 'абрыгажник ебаный куда полетел со своими криптовалютами', 1.5 },
                    },

                    {
                        { 'лысый напряг бровь, поэтому ты миснул, а я убил', 1.2 },
                    },

                    {
                        { 'с луашкой лысыго играть приятнее, чем с луа прыщявого', 1.1 },
                    },

                    {
                        { 'ну нормально, это я еще с коляски инвалидной не упал', 1.4 },
                    },

                    {
                        { 'да блять шнырь ебаный, даже хердай убил бы', 1.3 },
                    },

                    {
                        { 'ты куда собрался таблеточный', 1.4 },
                    },

                    {
                        { 'Бог простит, но 𝔸𝔼𝕊𝕋ℍ𝔼𝕋𝕀ℂ нет.', 1.3 },
                    },

                    {
                        { 'А если по совершенно невероятной случайности, по исключительному редкому стечению обстоятельств, по крайней неудачливости, по абсолютной не предсказуемости, по полной катострофичносте ты меня когда-то убьешь?', 3 },
                    },

                    {
                        { 'с дороги нахуй, равшан на колесах ебать', 1.4 },
                    },

                    {
                        { 'придушил пидора как гуся своего', 1.3 },
                    },

                    {
                        { 'Маяковский, почему ваш бентли цвета какашек?', 1.4 },
                    },

                    {
                        { 'червь ебаный замкадный куда летиш', 1.6 },
                    },

                    {
                        { 'скажи бате', 1 },
                        { 'передай маме', 1.01 },
                        { 'пошел нахуй', 1.9 },
                    },

                    {
                        { 'фраер сколько ходок', 1.1 },
                        { 'где чалился', 2.1 },
                        { 'передай отцу', 1 },
                    },

                    {
                        { 'жеско ты проебал мне', 1.50 },
                        { 'щас на твое убийство дрочу если что', 2.50 },
                    },

                    {
                        { 'тебя хотят убить? не звони в полицию!', 1.5 },
                        { 'лучше купи aesthetic на скит и разберись с этими бичами(◣_◢)', 2 },
                    },

                    {
                        { '𝔸𝔼𝕊𝕋ℍ𝔼𝕋𝕀ℂ 𝕣𝕖𝕝𝕖𝕒𝕤𝕖𝕕... 𝕓𝕖 𝕤𝕔𝕒𝕣𝕖..(◣_◢)', 2 },
                    },

                    {
                        { '𝕞𝕪 𝕣𝕖𝕝𝕚𝕘𝕚𝕠𝕟... 𝕒𝕖𝕤𝕥𝕙𝕖𝕥𝕚𝕔~𝕘𝕤', 1.5 },
                        { '𝔸𝕤-𝕊𝕒𝕝𝕒𝕞𝕦 𝔸𝕝𝕒𝕚𝕜𝕦𝕞 𝕨𝕒 ℝ𝕒𝕙𝕞𝕒𝕥𝕦𝕝𝕝𝕒𝕙', 1.5 },
                    },

                    {
                        { 'щеманул ебало клопу', 1.4 },
                    },

                    {
                        { 'отскрябил хуесоса топором', 1.2 },
                    },

                    {
                        { 'ЙОУ ЙОУ ЙОУ БИЧИ, на колени.', 1.1 },
                    },

                    {
                        { 'у россии 3 пути, пиво, водка, две пизды', 1.5 },
                    }
                },

                ['On Death'] = {
                    {
                        { 'сука', 2.1 },
                        { 'лаки ебаное', 2.4 },
                    },

                    {
                        { 'зачем ты так со мной?(', 3 }
                    },

                    {
                        { 'ну не повезло мне', 3 },
                        { 'с кем не бывает?', 3 }
                    },

                    {
                        { 'я хуевый', 2.8 },
                        { 'простите команда', 3 }
                    },

                    {
                        { 'анлак', 2.5 },
                        { 'в очередной раз', 3 }
                    },

                    {
                        { 'бля ты совсем долбаеб', 2.9 },
                        { 'куда ты пикаешь пидорасина', 3 }
                    },

                    {
                        { 'ну ПИДОРАС ебаный', 2 },
                        { 'КУДА Я МИССНУЛ', 2.3 },
                    },

                    {
                        { 'ну конечно', 2.3 },
                        { 'опять запредиктили', 2.5 },
                        { 'и опять в отжатие', 2 }
                    },

                    {
                        { 'ДА КАК ТЫ МЕНЯ УБИЛ', 3 },
                        { 'я же с читами', 2 }
                    },

                    {
                        { 'хуйня тапнула', 3 },
                        { 'красава доминик', 2 }
                    },

                    {
                        { 'ndfhm t,fyfz ujhb d fle', 4 }
                    },

                    {
                        { 'как я опять умер???', 3 },
                        { 'вроде стараюсь как могу', 3.4 }
                    },

                    {
                        { 'да ебаная клавиатура', 3 },
                        { 'у меня с пробелом хуйня какая то', 4 }
                    },

                    {
                        { 'не', 2 },
                        { 'сегодня вообще нихуя не стреляет чит', 4 }
                    },

                    {
                        { 'нормально у меня аипик забайтился', 4 },
                        { 'а не', 2 },
                        { 'чит не стрельнул прост', 3 }
                    },

                    {
                        { 'ага', 2 },
                        { 'ты типа не лаки', 3 },
                        { 'да?', 2 }
                    },

                    {
                        { 'ах ты ', 1.20 },
                        { 'нахлебник ебучий', 1.2},
                    },

                    {
                        { 'блять опять бабка с полотенцем в комнату забежала ', 1.40 },
                    },

                    {
                        { 'тебе повезло я хуем кабель интернета задел', 1.40 },
                    },

                    {
                        { 'блять подушка по комнате пролетела отвечаю', 1.20 },
                    },

                    {
                        { 'блять кнопка даблтапа отвалилась', 1.20 },
                        { 'так и знал что ардор брать не стоило', 1.2},
                    },

                    {
                        { 'я лечу в австралию', 1.20 },
                        { 'чистить эзотерику ебало', 1.2},
                    },

                    {
                        { 'я брикнул', 1.20 },
                        { 'не помогло', 1.2},
                    },

                    {
                        { 'на самом деле я без читов ', 1.20 },
                    },

                    {
                        { 'так и знал что стоило эстетик покупать', 1.20 },
                        { 'вместо луасенса ебаного', 1.2},
                    },

                    {
                        { 'у меня кошка провод интернета перегрызла', 1.20 },
                    },

                    {
                        { 'монитор выключился', 1.20 },
                    },

                    {
                        { 'я же реснусь?', 1.20 },
                    },

                    {
                        { 'тут читеры играют что-ли?', 1.20 },
                    },

                    {
                        { 'где крутилку такую зачетную скачал?', 1.20 },
                    },

                    {
                        { 'тебе повезло сука', 1.20 },
                        { 'на меня метеорит свалился', 1.2 },
                    },

                    {
                        { 'извинись', 1.20 },
                        { 'немедленно', 1.2 },
                    },

                    {
                        { 'я тебя услышал', 1.20 },
                        { 'жди спортиков под дверью', 1.2 },
                    },

                    {
                        { 'меня это заебало', 1.20 },
                        { 'я пошел покупать эстетик', 1.2 },
                    },

                    {
                        { 'на самом деле я играю лучше всех на планете', 1.20 },
                        { 'ты похоже на луне', 1.2 },
                    },

                    {
                        { 'признаю неплохо ты меня жахнул', 1.20 },
                        { 'сынец шлюхи', 1.2 },
                    },

                    {
                        { 'не ну с таким везением', 1.20 },
                        { 'я бы только три семерки в казино выбивал', 1.2 },
                    },

                    {
                        { 'да как это возможно блять', 1.20 },
                        { 'ты бог чтоли??', 1.2 },
                    },

                    {
                        { 'не ну это уже наглость', 1.20 },
                        { '1х1 рн?', 1.2 },
                    },

                    {
                        { 'хуесос ебаный', 1.20 },
                        { 'пиши адрес', 1.2 },
                        { 'я выдвигаюсь', 1.2 },
                    },

                    {
                        { 'я стол сломал из-за тебя', 1.20 },
                        { 'покупай мне новый', 1.2 },
                        { 'или заяву напишу', 1.2 },
                    },

                    {
                        { 'еще раз такое будет', 1.20 },
                        { 'проверю выдержит ли моя мышка падение с 9 этажа', 1.2 },
                    },

                    {
                        { 'админы проверьте его на читы', 1.20 },
                    },

                    {
                        { 'хватит бога за бороду хватать', 1.20 },
                        { 'говно везучее', 1.2 },
                    },

                    {
                        { 'эстетик не загрузился', 1.20 },
                    },

                    {
                        { 'в этом раунде я проверял что будет если играть ногой', 1.60 },
                        { 'результат на лицо', 1.2 },
                    },

                    {
                        { 'блять скример на весь экран выскочил', 1.20 },
                    },

                    {
                        { 'я прислушивался', 1.20 },
                        { 'я думал у меня в доме грабители', 1.2 },
                    },

                    {
                        { 'ну легит в этом конфиге такой себе', 1.20 },
                    },

                    {
                        { 'у меня кресло развалилось', 1.20 },
                    },

                    {
                        { 'короче я прогоняю твою мамку из под стола', 1.50 },
                        { 'пизда тебе в следующем раунде', 1.3 },
                    },

                    {
                        { 'да ну нахуй', 1.20 },
                        { 'лил пип за окном выступает', 1.2 },
                    },

                    {
                        { 'я не верю в то что происходит', 1.20 },
                        { 'я что в ад попал?', 1.2 },
                    },

                    {
                        { 'и как после этого можно не верить в существование зомби?', 1.20 },
                    },

                    {
                        { 'ты допизделся', 1.20 },
                        { '/admin', 1.2 },
                    },

                    {
                        { 'я щас твой хуй в пропеллер видеокарты засуну', 1.20 },
                        { 'далбаеб', 1.2 },
                    },

                    {
                        { 'ко мне зомби через окно лезут', 1.20 },
                    },

                    {
                        { 'чистейший лагкомп', 1.20 },
                        { 'ай сука', 1.2 },
                    },

                    {
                        { 'как ты попал', 1.20 },
                        { 'у меня же хорошо голова крутилась', 1.2 },
                    },

                    {
                        { 'админы сбор', 1.20 },
                        { 'у него гм', 1.2 },
                        { 'мать ставлю', 1.2 },
                    },

                    {
                        { 'ну ебаная яндекс музыка', 1.20 },
                        { 'опять чит сломала', 1.2 },
                    },

                    {
                        { 'я не верю в то что ты на такое способен', 1.20 },
                        { 'скажи еще что ты египетские пирамиды строил', 1.5 },
                        { 'я поверю', 1.2 },
                    },

                    {
                        { 'ооо', 1.20 },
                        { 'хату на красное хуесос', 1.2 },
                    },

                    {
                        { 'я вроде брикнул', 1.20 },
                        { 'как ты меня убил?', 1.2 },
                    },

                    {
                        { 'ноулав в своем гайде точно так же делал', 1.40 },
                        { 'ах он хуесос напиздел', 1.2 },
                    },

                    {
                        { 'я на блокноте кс запустил', 1.20 },
                    },

                    {
                        { 'ясно', 1.20 },
                        { 'мой чит на командных блоках в майнкрафте делался', 1.2 },
                    },

                    {
                        { 'владивосток и москва разве не близко?', 1.20 },
                        { 'или почему у меня пинг 150', 1.2 },
                    },

                    {
                        { 'я загружаю другой конфиг', 1.20 },
                        { 'в следующем раунде точно попаду', 1.2 },
                    },

                    {
                        { 'как думаешь', 1.20 },
                        { 'у литвина правда м4 спиздили?', 1.2 },
                    },

                    {
                        { 'сукаааа ебаная сетевая карта', 1.20 },
                        { 'надо новую покупать', 1.2 },
                    },

                    {
                        { 'звуки есть в игре?', 1.20 },
                        { 'я твои шаги не услышал', 1.2 },
                    },

                    {
                        { 'хуесос с предиктом', 1.20 },
                    },

                    {
                        { 'а где скит кряк без вирусов скачать?', 1.20 },
                        { 'как у тебя', 1.2 },
                    },

                    {
                        { 'можешь свой кфг дать?', 1.20 },
                    },

                    {
                        { 'можешь свои аа дать?', 1.20 },
                        { 'а ты с эстетиком? тогда понятно почему я по тебе не попал', 1.6 },
                    },

                    {
                        { 'ну блять', 1.20 },
                        { 'клавиатура своей жизнью живет', 1.2 },
                    },

                    {
                        { 'плесень в банке день 30', 1.20 },
                    },

                    {
                        { 'так там же не простреливается', 1.30 },
                    },

                    {
                        { 'у тебя голова вверх смотрит на бога', 1.20 },
                        { 'в следующем раунде к нему и отправишься', 1.3 },
                    },

                    {
                        { 'у меня винлокер', 1.20 },
                        { '5к просят', 1.2 },
                    },

                    {
                        { 'коврик закончился', 1.20 },
                    },

                    {
                        { 'сенсу сорвало', 1.20 },
                    },

                    {
                        { 'поцаны сенса как у симпла норм?', 1.20 },
                    },

                    {
                        { 'нихуя у тебя раскидка от монеси', 1.20 },
                    },

                    {
                        { 'я пулю зубами сьел', 1.20 },
                        { 'а бон апетит никто не сказал', 1.2 },
                    },

                    {
                        { 'артефакты на мониторе', 1.20 },
                    },

                    {
                        { 'как ты попал', 1.20 },
                        { 'у меня же хорошо голова крутилась', 1.2},
                    },

                    {
                        { 'мы щас порнуху снимаем', 1.20 },
                        { 'я типо парень геймер', 1.2 },
                        { 'мою девушку сзади ебут', 1.2 },
                    },

                    {
                        { 'ты 001?', 1.20 },
                        { 'я 456 не трогай в следующем раунде', 1.2 },
                    },

                    {
                        { 'игра в рака с твоей мамкой в следующий раз будет хуесос', 1.50 },
                        { 'не дай бог еще раз', 1.2 },
                    },

                    {
                        { 'ну да все луахи на скит хуйня', 1.20 },
                        { 'ток эстетик нормальный', 1.2 },
                    },

                    {
                        { 'ты знаешь что нибудь про пробив через стим?', 1.40 },
                        { 'щас узнаешь', 1.2 },
                    },

                    {
                        { 'ого брат круто меня убил', 1.20 },
                        { 'поставь статрек на нож прикол будет', 1.4 },
                    },

                    {
                        { 'чел увидел у меня клантег эстетик', 1.20 },
                        { 'и убил случайно трясущемися руками', 1.2 },
                    },

                    {
                        { 'проклинаю все твое семейное древо хуесос', 1.20 },
                    },

                    {
                        { 'я вызываю спортиков', 1.20 },
                        { 'как мага сиять будешь хуесос', 1.2 },
                    },

                    {
                        { 'на сколько миллиардов казино уже ограбил?', 1.20 },
                    },

                    {
                        { 'поделись везеньем ', 1.20 },
                        { 'по братски', 1.2 },
                    },

                    {
                        { 'ты с эстетиком что-ли?', 1.20 },
                        { 'тогда простительно', 1.2 },
                    },

                    {
                        { 'о боги', 1.20 },
                    },

                    {
                        { 'ты не хуже брендона!', 1.20 },
                        { 'по везению', 2.0 },
                    },

                    {
                        { 'сигма сигма бой', 1.20 },
                        { 'словил в ебло с первой ', 1.2 },
                    },

                    {
                        { 'почему ты не выигрываешь турики с таким везеньем?', 1.20 },
                    },

                    {
                        { 'не дай бог покинешь сервер', 1.20 },
                        { 'я вычислю и начищу морду тебе на другом', 1.2 },
                    },

                    {
                        { 'щас мой братуха санчез подлетит', 1.20 },
                        { 'шансов тебе не оставит', 1.2 },
                    },

                    {
                        { 'слово пацана даю', 1.20 },
                        { 'еще одна такая выходка и тебе пиздец', 1.2 },
                    },

                    {
                        { 'бляя надо кфг шамлеса прикупить', 1.20 },
                        { 'эта поебень вообще не попадает', 1.2 },
                    },

                    {
                        { 'ну да, бездумно отжать я тож могу', 1.3 },
                    },

                    {
                        { 'о господи нищий пидор, ну ниче некст раунд посмотрим)', 1.1 },
                    },

                    {
                        { 'да даже лысый блять не настолько везучий', 1.6 },
                    },

                    {
                        { 'мать твою ебал сын шлюхи, че ты делаешь?', 1.1 },
                    },

                    {
                        { 'ДА СУКА Я ЖЕ С AESTHETIC КАК ТАК?', 1.3 },
                    },

                    {
                        { 'блять ебаный абрыгажник снова тапнул бичпакет ебучий', 1.6 },
                    },

                    {
                        { 'я бы тебе залупой зубы выбил бы хуесос дегенеративный', 1.4 },
                    },

                    {
                        { 'да ты посмотри что нищий с рейвтрипом делает', 1.1 },
                    },

                    {
                        { 'пидор без аестетика убил, pzdc)))', 1.3 },
                    },

                    {
                        { '[gamesense] missed shot due to лысая бошка', 1.5 },
                    },

                    {
                        { 'ТАКИМИ ТЕМПАМИ МОНИК НОГАМИ РАЗЪЕБАШУ', 1.3 },
                    },

                    {
                        { 'бля придется моник врубать', 1.2 },
                    },

                    {
                        { 'ах да забыл предикт врубить в aesthetic, ну щас пизды дам', 1.6 },
                    },

                    {
                        { 'МИСМАЧНУЛ', 1.2 },
                    },

                    {
                        { 'ОГО Я ДОРМАНТ ВЫРУБИТЬ ЗАБЫЛ', 1.1 },
                    },

                    {
                        { 'никнейм хердай(((', 1.1 },
                    },

                    {
                        { 'как ты со своим фри скитом убил мой платный aesthetic?', 1.3 },
                    },

                    {
                        { 'магия меня подвела...', 1.3 },
                    },

                    {
                        { 'Хорошие убийцы не умирают, а уходят в тень.', 1.2 },
                    },

                    {
                        { 'блять свет в ванной вырубился, секунду', 1.4 },
                    },

                    {
                        { 'хуйня ебаная подзалупная зубы бы тебе повыбивал яйцами большими уебище отсталое', 1.5 },
                    },

                    {
                        { 'блять у тебя везения больше чем у брендона сын шлюхи', 1.6 },
                    },

                    {
                        { 'А23ХЗАД32ХЗАДЗХЦВЙ ТЫ ЧО ДОЛБАЕБ? я убивать должен был', 1.2 },
                    },

                    {
                        { 'я не умер, просто ты хуесос ебаный везучий', 1.3 },
                    },
                }
            }

            local query = { }
            local msg_index = 0

            local function clear_query()
                for i = 1, #query do
                    query[i] = nil
                end
            end

            local function in_warmup_period()
                local game_rules = entity.get_game_rules()

                if game_rules == nil then
                    return false
                end

                local warmup_period = entity.get_prop(
                    game_rules, 'm_bWarmupPeriod'
                )

                return warmup_period == 1
            end

            local function find_random_msg(type)
                local msg_list = MESSAGES[type]

                if msg_list == nil then
                    return nil
                end

                msg_index = msg_index + 1
                msg_index = msg_index % #msg_list

                return msg_list[msg_index + 1]
            end

            local function send_to_queue(type)
                if not ref.triggers:get(type) then
                    return
                end

                local msg = find_random_msg(type)

                if msg == nil then
                    return
                end

                for i = 1, #msg do
                    local data = msg[i]

                    table.insert(query, {
                        data[1],
                        data[2]
                    })
                end
            end

            local function say_to_chat(text)
                client.exec('say ' .. text)
            end

            local function on_player_death(e)
                local me = entity.get_local_player()
                local kd = utils.get_player_kd(me)

                if kd ~= nil and kd <= 1.0 then
                    clear_query()

                    return
                end

                local userid = client.userid_to_entindex(e.userid)
                local attacker = client.userid_to_entindex(e.attacker)

                if me == userid and me ~= attacker then
                    send_to_queue 'On Death'

                    return
                end

                if me ~= userid and me == attacker then
                    send_to_queue 'On Kill'

                    return
                end
            end

            local function on_net_update_start()
                if ref.disable_on_warmup:get() and in_warmup_period() then
                    clear_query()

                    return
                end

                local msg = query[1]

                if msg == nil then
                    return
                end

                msg[2] = msg[2] - globals.frametime()

                if msg[2] > 0 then
                    return
                end

                say_to_chat(msg[1])
                table.remove(query, 1)
            end

            local function update_event_callbacks(value)
                if not value then
                    clear_query()
                end

                utils.event_callback(
                    'player_death',
                    on_player_death,
                    value
                )

                utils.event_callback(
                    'net_update_start',
                    on_net_update_start,
                    value
                )
            end

            local callbacks do
                local function on_enabled(item)
                    update_event_callbacks(item:get())
                end

                ref.enabled:set_callback(
                    on_enabled, true
                )
            end
        end

        local clantag do
            local ref = resource.main.miscellaneous.clantag

            local AESTHETIC = {
                '/',
                '/\\',
                'a',
                'a3',
                'ae',
                'ae5',
                'aes',
                'aes7',
                'aest',
                'aest#',
                'aesth',
                'aesth3',
                'aesthe',
                'aesthe7',
                'aesthet',
                'aesthet1',
                'aestheti',
                'aestheti<',
                'aesthetic',
                'aesthetic',
                'aesthetic',
                'aesthetic',
                'aesthetic',
                'aestheti<',
                'aestheti',
                'aesthet1',
                'aesthet',
                'aesthe7',
                'aesthe',
                'aesth3',
                'aesth',
                'aest#',
                'aest',
                'aes7',
                'aes',
                'ae5',
                'ae',
                'a3',
                'a',
                '/\\',
                '/',
            }

            local old_text = nil

            local function set_clan_tag(text)
                if old_text ~= text then
                    old_text = text

                    client.set_clan_tag(text)
                end
            end

            local function unset_clan_tag()
                client.set_clan_tag('')

                client.delay_call(
                    0.3, client.set_clan_tag, ''
                )
            end

            local function update_aesthetic_clantag()
                local kd = utils.get_player_kd(
                    entity.get_local_player()
                )

                if kd ~= nil and kd <= 1.0 then
                    set_clan_tag ''

                    return
                end

                local time = math.floor(
                    globals.curtime() * 3.0
                )

                local index = time % #AESTHETIC
                local text = AESTHETIC[index + 1]

                set_clan_tag(text)
            end

            local function update_custom_clantag()
                local mode = ref.mode:get()
                local text = ref.input:get()

                if mode == 'Static' then
                    set_clan_tag(text)
                end

                if mode == 'Reversed' then
                    set_clan_tag('\u{202E}')
                end

                if mode == 'Animated' and text ~= '' then
                    local speed = ref.speed:get() * 0.1

                    local time = math.floor(
                        globals.curtime() / speed
                    )

                    local length = #text

                    local count = math.floor(
                        0.5 + time % (length * 2)
                    )

                    count = math.abs(count - length)
                    set_clan_tag(text:sub(1, count))
                end
            end

            local function on_shutdown()
                unset_clan_tag()
            end

            local function on_net_update_start()
                local text_mode = ref.text:get()

                if text_mode == 'Aesthetic' then
                    update_aesthetic_clantag()
                end

                if text_mode == 'Custom' then
                    update_custom_clantag()
                end
            end

            local callbacks do
                local function on_enabled(item)
                    local value = item:get()

                    if not value then
                        unset_clan_tag()
                    end

                    utils.event_callback(
                        'shutdown',
                        on_shutdown,
                        value
                    )

                    utils.event_callback(
                        'net_update_start',
                        on_net_update_start,
                        value
                    )
                end

                ref.enabled:set_callback(
                    on_enabled, true
                )
            end
        end

        local fast_ladder do
            local ref = resource.main.miscellaneous.fast_ladder

            local MOVETYPE_LADDER = 9

            local function on_setup_command(cmd)
                local me = entity.get_local_player()

                if me == nil then
                    return
                end

                local movetype = entity.get_prop(
                    me, 'm_movetype'
                )

                if movetype ~= MOVETYPE_LADDER then
                    return
                end

                local pitch = client.camera_angles()

                cmd.yaw = math.floor(0.5 + cmd.yaw)
                cmd.roll = 0

                if cmd.forwardmove > 0 and pitch < 45 then
                    cmd.pitch = 89

                    cmd.in_moveleft = 0
                    cmd.in_moveright = 1

                    cmd.in_back = 1
                    cmd.in_forward = 0

                    if cmd.sidemove == 0 then
                        cmd.yaw = cmd.yaw + 90
                    end

                    if cmd.sidemove < 0 then
                        cmd.yaw = cmd.yaw + 150
                    end

                    if cmd.sidemove > 0 then
                        cmd.yaw = cmd.yaw + 30
                    end
                elseif cmd.forwardmove < 0 and pitch < 45 then
                    cmd.pitch = 89

                    cmd.in_moveleft = 1
                    cmd.in_moveright = 0

                    cmd.in_back = 0
                    cmd.in_forward = 1

                    if cmd.sidemove == 0 then
                        cmd.yaw = cmd.yaw + 90
                    end

                    if cmd.sidemove > 0 then
                        cmd.yaw = cmd.yaw + 150
                    end

                    if cmd.sidemove < 0 then
                        cmd.yaw = cmd.yaw + 30
                    end
                end
            end

            local function update_event_callbacks(value)
                utils.event_callback(
                    'setup_command',
                    on_setup_command,
                    value
                )
            end

            local callbacks do
                local function on_enabled(item)
                    update_event_callbacks(item:get())
                end

                ref.enabled:set_callback(
                    on_enabled, true
                )
            end
        end

        local console_filter do
            local ref = resource.main.miscellaneous.console_filter

            local con_filter_enable = cvar.con_filter_enable
            local con_filter_text = cvar.con_filter_text

            local function restore_values()
                con_filter_enable:set_int(tonumber(con_filter_enable:get_string()))
                con_filter_text:set_string('')
            end

            local function update_values()
                con_filter_enable:set_raw_int(1)
                con_filter_text:set_string('[gamesense]')
            end

            local function update_loop()
                if not ref.enabled:get() then
                    return
                end

                update_values()

                client.delay_call(
                    1, update_loop
                )
            end

            local function update_event_callbacks(value)
                if value then
                    update_loop()
                else
                    restore_values()
                end
            end

            local callbacks do
                local function on_enabled(item)
                    update_event_callbacks(item:get())
                end

                ref.enabled:set_callback(
                    on_enabled, true
                )
            end
        end

        local sync_ragebot_hotkeys do
            local ref = resource.main.miscellaneous.sync_ragebot_hotkeys

            local weapons = {
                'Global',
                'G3SG1 / SCAR-20',
                'SSG 08',
                'AWP',
                'R8 Revolver',
                'Desert Eagle',
                'Pistol',
                'Zeus',
                'Rifle',
                'Shotgun',
                'SMG',
                'Machine gun'
            }

            local ref_weapon_type = ui.reference(
                'Rage', 'Weapon type', 'Weapon type'
            )

            local ref_enabled = {
                ui.reference('Rage', 'Aimbot', 'Enabled')
            }

            local ref_multipoint = {
                ui.reference('Rage', 'Aimbot', 'Multi-point')
            }

            local ref_minimum_damage_override = {
                ui.reference('Rage', 'Aimbot', 'Minimum damage override')
            }

            local ref_force_safe_point = ui.reference(
                'Rage', 'Aimbot', 'Force safe point'
            )

            local ref_force_body_aim = ui.reference(
                'Rage', 'Aimbot', 'Force body aim'
            )

            local ref_quick_stop = {
                ui.reference('Rage', 'Aimbot', 'Quick stop')
            }

            local ref_double_tap = {
                ui.reference('Rage', 'Aimbot', 'Double tap')
            }

            local function set_callback(item, callback, value)
                if value ~= false then
                    ui_callback.set(item, callback)
                else
                    ui_callback.unset(item, callback)
                end
            end

            local callbacks do
                local function on_hotkey(item)
                    local _, _, key = ui.get(item)

                    local old_weapon = ui.get(ref_weapon_type)

                    for i = 1, #weapons do
                        local weapon = weapons[i]
                        ui.set(ref_weapon_type, weapon)

                        local _, state = ui.get(item)
                        ui.set(item, state, key or 0)
                    end

                    ui.set(ref_weapon_type, old_weapon)
                end

                local function on_enabled(item)
                    local value = item:get()

                    set_callback(ref_enabled[2], on_hotkey, value)
                    set_callback(ref_multipoint[2], on_hotkey, value)
                    set_callback(ref_minimum_damage_override[2], on_hotkey, value)

                    set_callback(ref_force_safe_point, on_hotkey, value)
                    set_callback(ref_force_body_aim, on_hotkey, value)

                    set_callback(ref_quick_stop[2], on_hotkey, value)
                    set_callback(ref_double_tap[2], on_hotkey, value)
                end

                ref.enabled:set_callback(
                    on_enabled, true
                )
            end
        end

        local reveal_enemy_team_chat do
            local ref = resource.main.miscellaneous.reveal_enemy_team_chat

            local game_state_api = panorama.open().GameStateAPI

            local cl_mute_enemy_team = cvar.cl_mute_enemy_team
            local cl_mute_all_but_friends_and_party = cvar.cl_mute_all_but_friends_and_party

            local chat_data = { }

            local function on_player_say(e)
                local entindex = client.userid_to_entindex(e.userid)

                if not entity.is_enemy(entindex) then
                    return
                end

                local xuid = game_state_api.GetPlayerXuidStringFromEntIndex(entindex)

                if game_state_api.IsSelectedPlayerMuted(xuid) then
                    return
                end

                if cl_mute_enemy_team:get_int() == 1 then
                    return
                end

                if cl_mute_all_but_friends_and_party:get_int() == 1 then
                    return
                end

                client.delay_call(0.2, function()
                    if chat_data[entindex] ~= nil and math.abs(globals.realtime() - chat_data[entindex]) < 0.4 then
                        return
                    end

                    local player_resource = entity.get_player_resource()

                    local last_place_name = entity.get_prop(entindex, 'm_szLastPlaceName')
                    local player_name = entity.get_player_name(entindex)

                    local team_literal = entity.get_prop(player_resource, 'm_iTeam', entindex) == 2 and "T" or "CT"
                    local state_literal = entity.is_alive(entindex) and 'Loc' or 'Dead'

                    local text = string.format(
                        'Cstrike_Chat_%s_%s',
                        team_literal,
                        state_literal
                    )

                    local localized_text = localize(text, {
                        s1 = player_name,
                        s2 = e.text,
                        s3 = localize(last_place_name ~= "" and last_place_name or 'UI_Unknown')
                    })

                    chat.print_player(entindex, localized_text)
                end)
            end

            local function on_player_chat(e)
                if not entity.is_enemy(e.entity) then
                    return
                end

                chat_data[e.entity] = globals.realtime()
            end

            local callbacks do
                local function on_enabled(item)
                    local value = item:get()

                    utils.event_callback(
                        'player_say',
                        on_player_say,
                        value
                    )

                    utils.event_callback(
                        'player_chat',
                        on_player_chat,
                        value
                    )
                end

                ref.enabled:set_callback(
                    on_enabled, true
                )
            end
        end
    end

    local logging_system do
        local ref = resource.main.logging_system

        local PADDING_H = 5
        local PADDING_V = 5

        local HITGROUP = {
            [0]  = 'generic',
            [1]  = 'head',
            [2]  = 'chest',
            [3]  = 'stomach',
            [4]  = 'left arm',
            [5]  = 'right arm',
            [6]  = 'left leg',
            [7]  = 'right leg',
            [8]  = 'neck',
            [10] = 'gear'
        }

        local HURT_ACTS = {
            ['knife'] = 'Knifed',
            ['inferno'] = 'Burned',
            ['hegrenade'] = 'Naded'
        }

        local dev_queue = { }
        local log_queue = { }

        local aimbot_data = { }
        local preview_alpha = 0.0

        local ref_draw_console_output = ui.reference(
            'Misc', 'Miscellaneous', 'Draw console output'
        )

        local ref_log_misses_due_to_spread = ui.reference(
            'Rage', 'Other', 'Log misses due to spread'
        )

        local function wrap_color(text, hex)
            return string.format(
                '\a%s%s\aDEFAULT',
                hex, text
            )
        end

        local function create_log_data(text)
            local list, count = text_fmt.color(text)

            for i = 1, #list do
                local data = list[i]

                local hex = data[2] or 'ffffffc8'
                local col = color(utils.from_hex(hex))

                data[2] = col
            end

            return { list = list, count = count }
        end

        local function print_dev(text)
            local should_add = (
                ref.output:get 'Events' and
                ref.events_font:get() == 'Old'
            )

            if not should_add then
                return
            end

            local data = create_log_data(text)
            data.liferemaining = 8

            table.insert(dev_queue, data)

            if #dev_queue > 6 then
                table.remove(dev_queue, 1)
            end
        end

        local function clear_developer_logs()
            for i = 1, #dev_queue do
                dev_queue[i] = nil
            end
        end

        local function add_crosshair_log(text)
            local data = create_log_data(text)
            local duration = ref.duration:get() * 0.1

            data.alpha = 0.0
            data.liferemaining = duration

            table.insert(log_queue, 1, data)

            if #log_queue > 6 then
                table.remove(log_queue, 1)
            end
        end

        local function print_raw(text)
            local list, count = text_fmt.color(text)

            for i = 1, count do
                local data = list[i]

                local str = data[1]
                local hex = data[2]

                local col = color(utils.from_hex(hex or 'ffffffc8'))

                if i ~= count then
                    str = str .. '\0'
                end

                client.color_log(col.r, col.g, col.b, str)
            end
        end

        local function prefixf(str)
            local hex = software.get_color(true)

            return '\a'.. hex .. '[aesthetic] '..
                   '\aDEFAULT' .. str
        end

        local function colorf(fmt, repl)
            local count = 0

            local result = fmt:gsub('%${(.-)}', function(str)
                count = count + 1

                return string.format(
                    '\a%s%s\aDEFAULT', repl[count], str
                )
            end)

            return result
        end

        local function get_hitgroup(id)
            return HITGROUP[id] or '?'
        end

        local function get_reason_items(reason)
            if reason == '?' then
                reason = 'resolver'
            end

            reason = string.format(
                '%s%s',
                reason:sub(1, 1):upper(),
                reason:sub(2)
            )

            return ref[reason]
        end

        local function draw_shadow(x, y, w, h, alpha)
            local center = math.floor(0.5 + w * 0.5)

            local col_begin  = color(0, 0, 0, 0)
            local col_finish = color(0, 0, 0, 100 * alpha)

            renderer.gradient(
                x, y, center, h,
                col_begin.r, col_begin.g, col_begin.b, col_begin.a,
                col_finish.r, col_finish.g, col_finish.b, col_finish.a,
                true
            )

            renderer.gradient(
                x + center, y, center, h,
                col_finish.r, col_finish.g, col_finish.b, col_finish.a,
                col_begin.r, col_begin.g, col_begin.b, col_begin.a,
                true
            )
        end

        local function draw_outline(x, y, w, h, alpha)
            local thickness = 1

            local center = math.floor(0.5 + w * 0.5)

            local col_center = color(0, 0, 0, 50 * alpha)
            local col_edge   = color(0, 0, 0, 0)

            renderer.gradient(
                x, y, center, thickness,
                col_edge.r, col_edge.g, col_edge.b, col_edge.a,
                col_center.r, col_center.g, col_center.b, col_center.a,
                true
            )

            renderer.gradient(
                x + center, y, center, thickness,
                col_center.r, col_center.g, col_center.b, col_center.a,
                col_edge.r, col_edge.g, col_edge.b, col_edge.a,
                true
            )

            renderer.gradient(
                x, y + h - thickness, center, thickness,
                col_edge.r, col_edge.g, col_edge.b, col_edge.a,
                col_center.r, col_center.g, col_center.b, col_center.a,
                true
            )

            renderer.gradient(
                x + center, y + h - thickness, center, thickness,
                col_center.r, col_center.g, col_center.b, col_center.a,
                col_edge.r, col_edge.g, col_edge.b, col_edge.a,
                true
            )
        end

        local function update_developer_logs()
            local dt = globals.frametime()

            for i = #dev_queue, 1, -1 do
                local data = dev_queue[i]

                data.liferemaining = data.liferemaining - dt

                if data.liferemaining <= 0 then
                    table.remove(dev_queue, i)
                end
            end
        end

        local function draw_developer_logs()
            local x = 8
            local y = 5

            local font_tall = surface.text_tall(63) + 1

            for i = 1, #dev_queue do
                local data = dev_queue[i]

                local alpha = 1.0
                local timeleft = data.liferemaining

                if timeleft < 0.5 then
                    local f = utils.clamp(timeleft, 0.0, 0.5) / 0.5

                    if i == 1 and f < 0.2 then
                        y = y - font_tall * (1.0 - f / 0.2)
                    end

                    alpha = f
                end

                local text_x = x

                local max_width = 0
                local width_arr = { }

                for j = 1, data.count do
                    local buffer = data.list[j]

                    local text_size = vector(
                        surface.measure_text(63, buffer[1])
                    )

                    width_arr[j] = text_size
                    max_width = max_width + text_size.x
                end

                local half_width = math.floor(0.5 * max_width)

                surface.fade(text_x, y, half_width, font_tall, 0, 0, 0, 0, 0, 0, 0, 50 * alpha, true)
                surface.fade(text_x + half_width, y, half_width, font_tall, 0, 0, 0, 50 * alpha, 0, 0, 0, 0, true)

                for j = 1, data.count do
                    local buffer = data.list[j]

                    local text = buffer[1]
                    local col = buffer[2]

                    surface.text(63, text_x, y, col.r, col.g, col.b, col.a * alpha, text)

                    text_x = text_x + width_arr[j].x
                end

                y = y + font_tall
            end
        end

        local function update_crosshair_logs()
            local dt = globals.frametime()

            for i = #log_queue, 1, -1 do
                local data = log_queue[i]

                data.liferemaining = data.liferemaining - dt

                if data.liferemaining > 0 then
                    data.alpha = motion.interp(
                        data.alpha, 1, 0.05
                    )

                    goto continue
                end

                data.alpha = motion.interp(
                    data.alpha, 0, 0.05
                )

                if data.alpha <= 0.0 then
                    table.remove(log_queue, i)
                end

                ::continue::
            end
        end

        local function draw_crosshair_logs()
            local flags = ''

            local screen_size = vector(
                client.screen_size()
            )

            local position = vector(
                screen_size.x * 0.5,

                utils.lerp(
                    screen_size.y * 0.5 + 50,
                    screen_size.y - 200,
                    ref.offset_y:get() * 0.01
                )
            )

            local queue_list = {
                unpack(log_queue)
            }

            local should_preview = (
                next(queue_list) == nil
                and ui.is_menu_open()
            )

            preview_alpha = motion.interp(
                preview_alpha, should_preview, 0.05
            )

            if preview_alpha > 0.01 then
                local style = ref.crosshair_text_style:get()

                local preview_logs = { }

                if style == 'Gamesense' then
                    local hex = software.get_color(true)

                    table.insert(preview_logs, string.format(
                        'Hit %s in the %s for %s damage (%s health remaining)',
                        wrap_color(script.user, hex),
                        wrap_color('stomach', hex),
                        wrap_color('93', hex),
                        wrap_color('7', hex)
                    ))

                    table.insert(preview_logs, string.format(
                        'Missed shot due to %s',
                        wrap_color('spread', hex)
                    ))
                end

                if style == 'Aesthetic' then
                    local reason_items = get_reason_items 'Spread'

                    local target_color = color(ref['Target'].color:get())
                    local other_color = color(ref['Other'].color:get())

                    local miss_color = reason_items ~= nil
                        and color(reason_items.color:get())
                        or color(255, 32, 32, 255)

                    local target_hex = target_color:to_hex()
                    local other_hex = other_color:to_hex()
                    local miss_hex = miss_color:to_hex()

                    table.insert(preview_logs, string.format(
                        'Hit %s ~ group: %s ~ damage: %s hp',
                        wrap_color(script.user, target_hex),
                        wrap_color('stomach', other_hex),
                        wrap_color('93', other_hex)
                    ))

                    table.insert(preview_logs, string.format(
                        'Missed %s ~ group: %s ~ reason: %s',
                        wrap_color(script.user, target_hex),
                        wrap_color('stomach', other_hex),
                        wrap_color('spread', miss_hex)
                    ))
                end

                for i = 1, #preview_logs do
                    local data = create_log_data(
                        preview_logs[i]
                    )

                    data.alpha = preview_alpha
                    data.liferemaining = 0.0

                    table.insert(queue_list, data)
                end
            end

            for i = 1, #queue_list do
                local data = queue_list[i]

                local alpha = data.alpha

                local size_arr = { }
                local text_size = vector()

                for j = 1, data.count do
                    local buffer = data.list[j]

                    local measure = vector(
                        renderer.measure_text(flags, buffer[1])
                    )

                    size_arr[j] = measure

                    text_size.x = text_size.x + measure.x
                    text_size.y = math.max(text_size.y, measure.y)
                end

                local box_size = text_size + vector(
                    PADDING_H * 2, PADDING_V * 2
                )

                local height = box_size.y + 3

                local rect_pos = position:clone()
                rect_pos.x = rect_pos.x - box_size.x / 2

                draw_shadow(rect_pos.x, rect_pos.y, box_size.x, box_size.y, alpha)
                draw_outline(rect_pos.x, rect_pos.y, box_size.x, box_size.y, alpha)

                local text_pos = vector(
                    rect_pos.x + PADDING_H,
                    rect_pos.y + PADDING_V
                )

                for j = 1, data.count do
                    local buffer = data.list[j]

                    local text = buffer[1]
                    local col = buffer[2]

                    renderer.text(
                        text_pos.x, text_pos.y,
                        col.r, col.g, col.b, col.a * alpha,
                        flags, nil, text
                    )

                    text_pos.x = text_pos.x + size_arr[j].x
                end

                position.y = position.y + height * alpha
            end
        end

        local function on_paint_developer_logs()
            update_developer_logs()
            draw_developer_logs()
        end

        local function on_paint_crosshair_logs()
            update_crosshair_logs()
            draw_crosshair_logs()
        end

        local function on_aim_fire(e)
            local me = entity.get_local_player()

            if me == nil then
                return
            end

            local history = globals.tickcount() - e.tick
            local server_tick = globals.servertickcount()

            aimbot_data[e.id] = {
                original = e,

                history = history,
                server_tick = server_tick
            }
        end

        local function on_aim_hit(e)
            local target = e.target

            if target == nil then
                return
            end

            local aim_data = aimbot_data[e.id]

            if aim_data == nil then
                return
            end

            local console_style = ref.console_text_style:get()
            local crosshair_style = ref.crosshair_text_style:get()

            local elapsed = math.max(globals.servertickcount() - aim_data.server_tick - 1, 0)

            local health = entity.get_prop(target, 'm_iHealth')
            local target_name = entity.get_player_name(target)

            local damage = e.damage or 0
            local hitgroup = e.hitgroup

            local wanted_damage = aim_data.original.damage
            local wanted_hitgroup = aim_data.original.hitgroup

            local backtrack = aim_data.history or 0
            local hit_chance = aim_data.original.hit_chance or 0

            local gamesense_text do
                local hex = software.get_color(true)

                gamesense_text = string.format(
                    'Hit %s in the %s for %s damage (%s health remaining)',
                    wrap_color(target_name, hex),
                    wrap_color(get_hitgroup(e.hitgroup), hex),
                    wrap_color(damage, hex),
                    wrap_color(health, hex)
                )
            end

            local aesthetic_text do
                local target_color = color(ref['Target'].color:get())
                local other_color = color(ref['Other'].color:get())

                local target_hex = target_color:to_hex()
                local other_hex = other_color:to_hex()

                local details = { } do
                    local sep = '\aABABABFF · \aDEFAULT'

                    table.insert(details, string.format('hc: \a%s%d%%\aDEFAULT', other_hex, hit_chance))
                    table.insert(details, string.format('bt: \a%s%dt\aDEFAULT', other_hex, backtrack))

                    details.dev = table.concat(details, sep)

                    table.insert(details, string.format('reg: \a%s%dt\aDEFAULT', other_hex, elapsed))
                    details.raw = table.concat(details, sep)
                end

                local text = { } do
                    local damage_text = string.format('\a%s%d\aDEFAULT', other_hex, damage)
                    local hitgroup_text = string.format('\a%s%s\aDEFAULT', other_hex, get_hitgroup(hitgroup))

                    if damage ~= wanted_damage then
                        damage_text = damage_text .. string.format('(\a%s%d\aDEFAULT)', other_hex, wanted_damage)
                    end

                    if hitgroup ~= wanted_hitgroup then
                        hitgroup_text = hitgroup_text .. string.format('(\a%s%s\aDEFAULT)', other_hex, get_hitgroup(wanted_hitgroup))
                    end

                    local palette = { target_hex }

                    local fmt_dev = string.format('Hit ${%s} ~ group: %s ~ damage: %s hp [%s]', target_name, hitgroup_text, damage_text, details.dev)
                    local fmt_raw = string.format('Hit ${%s} ~ group: %s ~ damage: %s hp [%s]', target_name, hitgroup_text, damage_text, details.raw)
                    local fmt_log = string.format('Hit ${%s} ~ group: %s ~ damage: %s hp', target_name, hitgroup_text, damage_text)

                    text.dev = colorf(fmt_dev, palette)
                    text.raw = colorf(fmt_raw, palette)
                    text.log = colorf(fmt_log, palette)
                end

                aesthetic_text = text
            end

            if console_style == 'Gamesense' then
                print_raw(prefixf(gamesense_text))
                print_dev(gamesense_text)
            elseif console_style == 'Aesthetic' then
                print_raw(prefixf(aesthetic_text.raw))
                print_dev(aesthetic_text.dev)
            end

            if crosshair_style == 'Gamesense' then
                add_crosshair_log(gamesense_text)
            elseif crosshair_style == 'Aesthetic' then
                add_crosshair_log(aesthetic_text.log)
            end
        end

        local function on_aim_miss(e)
            local me = entity.get_local_player()

            if me == nil then
                return
            end

            local target = e.target

            if target == nil then
                return
            end

            local aim_data = aimbot_data[e.id]

            if aim_data == nil then
                return
            end

            local reason = e.reason

            local target_name = entity.get_player_name(target)
            local wanted_hitgroup = aim_data.original.hitgroup

            local backtrack = aim_data.history or 0
            local hit_chance = aim_data.original.hit_chance or 0

            if reason == '?' then
                reason = 'resolver'
            end

            local console_style = ref.console_text_style:get()
            local crosshair_style = ref.crosshair_text_style:get()

            local gamesense_text = string.format(
                'Missed shot due to %s', reason
            )

            local aesthetic_text do
                local reason_items = get_reason_items(reason)

                local target_color = color(ref['Target'].color:get())
                local other_color = color(ref['Other'].color:get())

                local miss_color = reason_items ~= nil
                    and color(reason_items.color:get())
                    or color(255, 32, 32, 255)

                local target_hex = target_color:to_hex()
                local other_hex = other_color:to_hex()
                local miss_hex = miss_color:to_hex()

                local details do
                    local list = { }

                    table.insert(list, string.format('hc: \a%s%d%%\aDEFAULT', other_hex, hit_chance))
                    table.insert(list, string.format('bt: \a%s%dt\aDEFAULT', other_hex, backtrack))

                    details = table.concat(list, '\aABABABFF · \aDEFAULT')
                end

                local text = { } do
                    local palette = { target_hex, other_hex, miss_hex }
                    local hitgroup_text = get_hitgroup(wanted_hitgroup)

                    local fmt_dev = string.format('Missed ${%s} ~ group: ${%s} ~ reason: ${%s} [%s]', target_name, hitgroup_text, reason, details)
                    local fmt_raw = string.format('Missed ${%s} ~ group: ${%s} ~ reason: ${%s} [%s]', target_name, hitgroup_text, reason, details)
                    local fmt_log = string.format('Missed ${%s} ~ group: ${%s} ~ reason: ${%s}', target_name, hitgroup_text, reason)

                    text.dev = colorf(fmt_dev, palette)
                    text.raw = colorf(fmt_raw, palette)
                    text.log = colorf(fmt_log, palette)
                end

                aesthetic_text = text
            end

            if console_style == 'Gamesense' then
                print_raw(prefixf(gamesense_text))
                print_dev(gamesense_text)
            elseif console_style == 'Aesthetic' then
                print_raw(prefixf(aesthetic_text.raw))
                print_dev(aesthetic_text.dev)
            end

            if crosshair_style == 'Gamesense' then
                add_crosshair_log(gamesense_text)
            elseif crosshair_style == 'Aesthetic' then
                add_crosshair_log(aesthetic_text.log)
            end
        end

        local function on_player_hurt(e)
            local me = entity.get_local_player()

            local userid = client.userid_to_entindex(e.userid)
            local attacker = client.userid_to_entindex(e.attacker)

            if me == userid or me ~= attacker then
                return
            end

            local act = HURT_ACTS[e.weapon]

            if act == nil then
                return
            end

            local name = entity.get_player_name(userid)

            local health = e.health
            local damage = e.dmg_health

            local console_style = ref.console_text_style:get()
            local crosshair_style = ref.crosshair_text_style:get()

            local gamesense_text do
                local hex = software.get_color(true)

                gamesense_text = string.format(
                    '%s %s for %s damage',
                    act,
                    wrap_color(name, hex),
                    wrap_color(damage, hex)
                )
            end

            local aesthetic_text do
                local target_color = color(ref['Target'].color:get())
                local other_color = color(ref['Other'].color:get())

                local target_hex = target_color:to_hex()
                local other_hex = other_color:to_hex()

                local text = string.format('%s ${%s} for ${%d} damage (${%d} health remaining)', act, name, damage, health) do
                    text = colorf(text, { target_hex, other_hex, other_hex })
                end

                aesthetic_text = text
            end

            if console_style == 'Gamesense' then
                print_raw(prefixf(gamesense_text))
                print_dev(gamesense_text)
            elseif console_style == 'Aesthetic' then
                print_raw(prefixf(aesthetic_text))
                print_dev(aesthetic_text)
            end

            if crosshair_style == 'Gamesense' then
                add_crosshair_log(gamesense_text)
            elseif crosshair_style == 'Aesthetic' then
                add_crosshair_log(aesthetic_text)
            end
        end

        local function on_item_purchase(e)
            local userid = client.userid_to_entindex(e.userid)

            if userid == nil or not entity.is_enemy(userid) then
                return
            end

            local weapon = e.weapon

            if weapon == 'weapon_unknown' then
                return
            end

            local name = entity.get_player_name(userid)

            local console_style = ref.console_text_style:get()
            local crosshair_style = ref.crosshair_text_style:get()

            local gamesense_text do
                local hex = software.get_color(true)

                gamesense_text = string.format(
                    '%s bought %s',
                    wrap_color(name, hex),
                    wrap_color(weapon, hex)
                )
            end

            local aesthetic_text do
                local target_color = color(ref['Target'].color:get())
                local other_color = color(ref['Other'].color:get())

                local target_hex = target_color:to_hex()
                local other_hex = other_color:to_hex()

                aesthetic_text = string.format(
                    '%s bought %s',
                    wrap_color(name, target_hex),
                    wrap_color(weapon, other_hex)
                )
            end

            if console_style == 'Gamesense' then
                print_raw(prefixf(gamesense_text))
                print_dev(gamesense_text)
            elseif console_style == 'Aesthetic' then
                print_raw(prefixf(aesthetic_text))
                print_dev(aesthetic_text)
            end

            if crosshair_style == 'Gamesense' then
                add_crosshair_log(gamesense_text)
            elseif crosshair_style == 'Aesthetic' then
                add_crosshair_log(aesthetic_text)
            end
        end

        local function update_event_callbacks(value)
            if not value then
                utils.event_callback('paint_ui', on_paint_developer_logs, false)
                utils.event_callback('paint_ui', on_paint_crosshair_logs, false)

                utils.event_callback('aim_fire', on_aim_fire, false)
                utils.event_callback('aim_hit', on_aim_hit, false)
                utils.event_callback('aim_miss', on_aim_miss, false)

                utils.event_callback('player_hurt', on_player_hurt, false)
                utils.event_callback('item_purchase', on_item_purchase, false)
            end
        end

        local callbacks do
            local function on_events_font(item)
                local is_old = item:get() == 'Old'
                local is_bold = item:get() == 'Bold'

                if not is_old then
                    clear_developer_logs()
                end

                utils.event_callback(
                    'paint_ui',
                    on_paint_developer_logs,
                    is_old
                )

                override.unset(ref_draw_console_output)

                if is_old then
                    override.set(ref_draw_console_output, false)
                end

                if is_bold then
                    override.set(ref_draw_console_output, true)
                end
            end

            local function on_events(item)
                local is_aimbot = item:get 'Aimbot'
                local is_purchase = item:get 'Purchase'

                utils.event_callback(
                    'aim_fire',
                    on_aim_fire,
                    is_aimbot
                )

                utils.event_callback(
                    'aim_hit',
                    on_aim_hit,
                    is_aimbot
                )

                utils.event_callback(
                    'aim_miss',
                    on_aim_miss,
                    is_aimbot
                )

                utils.event_callback(
                    'player_hurt',
                    on_player_hurt,
                    is_aimbot
                )

                utils.event_callback(
                    'item_purchase',
                    on_item_purchase,
                    is_purchase
                )
            end

            local function on_output(item)
                local is_events = item:get 'Events'

                if not is_events then
                    utils.event_callback(
                        'paint_ui',
                        on_paint_developer_logs,
                        false
                    )

                    override.unset(ref_draw_console_output)

                    clear_developer_logs()
                end

                if is_events then
                    ref.events_font:set_callback(on_events_font, true)
                else
                    ref.events_font:unset_callback(on_events_font)
                end

                utils.event_callback(
                    'paint_ui',
                    on_paint_crosshair_logs,
                    item:get 'Under crosshair'
                )
            end

            local function on_enabled(item)
                local value = item:get()

                if not value then
                    clear_developer_logs()

                    override.unset(ref_draw_console_output)
                    ref.events:unset_callback(on_events_font)
                end

                if value then
                    override.set(ref_log_misses_due_to_spread, false)
                else
                    override.unset(ref_log_misses_due_to_spread)
                end

                if value then
                    ref.output:set_callback(on_output, true)
                    ref.events:set_callback(on_events, true)
                else
                    ref.events:unset_callback(on_events)
                    ref.output:unset_callback(on_output)
                end

                update_event_callbacks(value)
            end

            ref.enabled:set_callback(
                on_enabled, true
            )
        end
    end

    local automatic_purchase do
        local ref = resource.main.automatic_purchase

        local mp_afterroundmoney = cvar.mp_afterroundmoney

        local primary_items = {
            ['AWP'] = 'awp',
            ['Scout'] = 'ssg08',
            ['G3SG1 / SCAR-20'] = 'scar20'
        }

        local secondary_items = {
            ['P250'] = 'p250',
            ['Elites'] = 'elite',
            ['Five-seven / Tec-9 / CZ75'] = 'fn57',
            ['Deagle / Revolver'] = 'deagle'
        }

        local equipment_items = {
            ['Kevlar'] = 'vest',
            ['Kevlar + Helmet'] = 'vesthelm',
            ['Defuse kit'] = 'defuser',
            ['HE'] = 'hegrenade',
            ['Smoke'] = 'smokegrenade',
            ['Molotov'] = 'molotov',
            ['Taser'] = 'taser'
        }

        local function should_buy()
            local me = entity.get_local_player()

            if me == nil then
                return
            end

            local account = entity.get_prop(
                me, 'm_iAccount'
            )

            if ref.ignore_pistol_round:get() then
                if account <= 1000 then
                    return false
                end
            end

            if ref.only_16k:get() then
                local after_round_money = mp_afterroundmoney:get_int()

                return account >= 16000
                    or after_round_money >= 16000
            end

            return true
        end

        local function should_buy_reserved()
            local me = entity.get_local_player()

            if me == nil then
                return false
            end

            local weapons = utils.get_player_weapons(me)

            for i = 1, #weapons do
                local weapon = weapons[i]

                local weapon_info = csgo_weapons(weapon)

                if weapon_info == nil then
                    goto continue
                end

                local weapon_idx = weapon_info.idx

                if weapon_idx == 9 then
                    return false
                end

                ::continue::
            end

            return true
        end

        local function buy_primary(list)
            local item = primary_items[
                ref.primary:get()
            ]

            if item == nil then
                return
            end

            if item == 'awp' then
                local function on_awp()
                    if not should_buy_reserved() then
                        return
                    end

                    local reserv = primary_items[
                        ref.alternative:get()
                    ]

                    if reserv == nil then
                        return
                    end

                    client.exec('buy ' .. reserv)
                end

                local duration = client.latency() + 0.15

                client.delay_call(duration, on_awp)
            end

            table.insert(list, item)
        end

        local function buy_secondary(list)
            local item = secondary_items[
                ref.secondary:get()
            ]

            if item ~= nil then
                table.insert(list, item)
            end
        end

        local function buy_equipment(list)
            local values = ref.equipment:get()

            for i = 1, #values do
                local value = equipment_items[
                    values[i]
                ]

                if value ~= nil then
                    table.insert(list, value)
                end
            end
        end

        local function process_buy()
            if not should_buy() then
                return
            end

            local list = { }

            buy_primary(list)
            buy_secondary(list)
            buy_equipment(list)

            local command = ''

            for i = 1, #list do
                local item = list[i]

                command = command .. string.format(
                    'buy %s;', item
                )
            end

            if command ~= '' then
                client.exec(command)
            end
        end

        local function on_round_prestart()
            client.delay_call(client.latency() + totime(8), process_buy)
        end

        local callbacks do
            local function on_enabled(item)
                utils.event_callback(
                    'round_prestart',
                    on_round_prestart,
                    item:get()
                )
            end

            ref.enabled:set_callback(
                on_enabled, true
            )
        end
    end
end

local antiaim = { } do
    local inverts = 0
    local inverted = false

    local delay_ticks = 0

    local skitter = {
        -1, 1, 0,
        -1, 1, 0,
        -1, 0, 1,
        -1, 0, 1
    }

    local buffer = { } do
        local ref = software.antiaimbot.angles

        local function override_value(item, ...)
            if ... == nil then
                return
            end

            override.set(item, ...)
        end

        local Buffer = { } do
            Buffer.__index = Buffer

            function Buffer:clear()
                for k in pairs(self) do
                    self[k] = nil
                end
            end

            function Buffer:copy(target)
                for k, v in pairs(target) do
                    self[k] = v
                end
            end

            function Buffer:unset()
                override.unset(ref.roll)

                override.unset(ref.freestanding[2])
                override.unset(ref.freestanding[1])

                override.unset(ref.edge_yaw)

                override.unset(ref.freestanding_body_yaw)

                override.unset(ref.body_yaw[2])
                override.unset(ref.body_yaw[1])

                override.unset(ref.yaw[2])
                override.unset(ref.yaw[1])

                override.unset(ref.yaw_jitter[2])
                override.unset(ref.yaw_jitter[1])

                override.unset(ref.yaw_base)

                override.unset(ref.pitch[2])
                override.unset(ref.pitch[1])

                override.unset(ref.enabled)
            end

            function Buffer:set()
                if self.pitch_offset ~= nil then
                    self.pitch_offset = utils.clamp(
                        self.pitch_offset, -89, 89
                    )
                end

                if self.yaw_offset ~= nil then
                    self.yaw_offset = utils.normalize(
                        self.yaw_offset, -180, 180
                    )
                end

                if self.jitter_offset ~= nil then
                    self.jitter_offset = utils.normalize(
                        self.jitter_offset, -180, 180
                    )
                end

                if self.body_yaw_offset ~= nil then
                    self.body_yaw_offset = utils.clamp(
                        self.body_yaw_offset, -180, 180
                    )
                end

                override_value(ref.enabled, self.enabled)

                override_value(ref.pitch[1], self.pitch)
                override_value(ref.pitch[2], self.pitch_offset)

                override_value(ref.yaw_base, self.yaw_base)

                override_value(ref.yaw[1], self.yaw)
                override_value(ref.yaw[2], self.yaw_offset)

                override_value(ref.yaw_jitter[1], self.yaw_jitter)
                override_value(ref.yaw_jitter[2], self.jitter_offset)

                override_value(ref.body_yaw[1], self.body_yaw)
                override_value(ref.body_yaw[2], self.body_yaw_offset)

                override_value(ref.freestanding_body_yaw, self.freestanding_body_yaw)

                override_value(ref.edge_yaw, self.edge_yaw)

                if self.freestanding == true then
                    override_value(ref.freestanding[1], true)
                    override_value(ref.freestanding[2], 'Always on')
                elseif self.freestanding == false then
                    override_value(ref.freestanding[1], false)
                    override_value(ref.freestanding[2], 'On hotkey')
                end

                override_value(ref.roll, self.roll)
            end
        end

        setmetatable(buffer, Buffer)
        antiaim.buffer = buffer
    end

    local safe_head = { } do
        local ref = resource.antiaim.features.safe_head

        local function should_update()
            return ref.enabled:get()
        end

        local function get_condition(me, threat)
            local weapon = entity.get_player_weapon(me)

            if weapon == nil then
                return nil
            end

            local weapon_info = csgo_weapons(weapon)

            if weapon_info == nil then
                return nil
            end

            local weapon_type = weapon_info.type
            local weapon_index = weapon_info.idx

            -- fun fact: taser is also a knife type of weapon
            local is_knife = weapon_type == 'knife'
            local is_taser = weapon_index == 31

            local my_origin = vector(entity.get_origin(me))
            local threat_origin = vector(entity.get_origin(threat))

            local delta = threat_origin - my_origin

            local height = -delta.z
            local distancesqr = delta:length2dsqr()

            if localplayer.is_onground then
                local is_distance_state = not localplayer.is_moving
                    or localplayer.is_crouched

                if is_distance_state and height >= 10 and distancesqr > 1000 * 1000 then
                    return 'Distance'
                end

                if localplayer.is_crouched then
                    if height >= 48 then
                        return 'Crouch'
                    end
                else
                    if not localplayer.is_moving and height >= 24 then
                        return 'Standing'
                    end
                end

                return nil
            end

            if localplayer.is_crouched then
                if is_taser and height > -20 and distancesqr < 500 * 500 then
                    return 'Air crouch taser'
                end

                if is_knife  then
                    return 'Air crouch knife'
                end

                if height > 160 then
                    return 'Air crouch'
                end
            end

            return nil
        end

        local function update_buffer(condition)
            if condition == 'Air crouch knife' then
                buffer.pitch = 'Default'
                buffer.yaw_base = 'At targets'

                buffer.yaw = '180'
                buffer.yaw_offset = 37

                buffer.yaw_left = 0
                buffer.yaw_right = 0

                buffer.yaw_jitter = 'Off'
                buffer.jitter_offset = 0

                buffer.body_yaw = 'Static'
                buffer.body_yaw_offset = 1

                buffer.freestanding_body_yaw = false

                buffer.roll = 0
                buffer.defensive = nil

                return
            end

            buffer.pitch = 'Default'
            buffer.yaw_base = 'At targets'

            buffer.yaw = '180'
            buffer.yaw_offset = 0

            buffer.yaw_left = 0
            buffer.yaw_right = 0

            buffer.yaw_jitter = 'Off'
            buffer.jitter_offset = 0

            buffer.body_yaw = 'Static'
            buffer.body_yaw_offset = 0

            buffer.freestanding_body_yaw = false

            buffer.roll = 0
            buffer.defensive = nil
        end

        local function update_spam(cmd, condition)
            if not ref.e_spam_while_active:get() then
                return
            end

            local buffer_ctx = { }

            buffer_ctx.pitch = 'Custom'
            buffer_ctx.pitch_offset = 0

            buffer_ctx.yaw = '180'
            buffer_ctx.yaw_offset = 180

            buffer_ctx.yaw_jitter = 'Off'
            buffer_ctx.jitter_offset = 0

            buffer_ctx.body_yaw = 'Static'
            buffer_ctx.body_yaw_offset = 180
            buffer_ctx.freestanding_body_yaw = false

            cmd.force_defensive = true

            buffer.defensive = buffer_ctx
        end

        function safe_head:update(cmd)
            if not should_update() then
                return false
            end

            local me = entity.get_local_player()

            if me == nil then
                return false
            end

            local threat = client.current_threat()

            if threat == nil  then
                return false
            end

            local condition = get_condition(me, threat)

            if condition == nil then
                return false
            end

            local is_enabled = ref.conditions:get(condition)

            if not is_enabled then
                return false
            end

            update_buffer(condition)
            update_spam(cmd, condition)

            return true
        end
    end

    local edge_yaw = { } do
        local ref = resource.antiaim.hotkeys.edge_yaw

        local function get_state()
            if not localplayer.is_onground then
                return 'Air'
            end

            if localplayer.is_crouched then
                return 'Crouched'
            end

            if localplayer.is_moving then
                if software.is_slow_motion() then
                    return 'Slow Walk'
                end

                return 'Moving'
            end

            return 'Standing'
        end

        local function is_disabled()
            return ref.disablers:get(
                get_state()
            )
        end

        local function is_enabled()
            if not ref.enabled:get() then
                return false
            end

            if not ref.hotkey:get() then
                return false
            end

            return not is_disabled()
        end

        function edge_yaw:update(cmd)
            if not is_enabled() then
                buffer.edge_yaw = false

                return
            end

            buffer.edge_yaw = true
        end
    end

    local defensive = { } do
        local generated_pitch = 0
        local generated_yaw = 0

        local pitch_inverted = false
        local modifier_delay_ticks = 0

        local function is_exploit_active()
            if software.is_double_tap_active() then
                return true
            end

            if software.is_on_shot_antiaim_active() then
                return true
            end

            return false
        end

        local function update_pitch_inverter()
            pitch_inverted = not pitch_inverted
        end

        local function update_modifier_inverter()
            modifier_delay_ticks = modifier_delay_ticks + 1
        end

        local function update_pitch(buffer, items)
            local value = items.pitch:get()

            local pitch_offset_1 = items.pitch_offset_1:get()
            local pitch_offset_2 = items.pitch_offset_2:get()

            local speed = items.pitch_speed:get()

            if value == 'Off' then
                return
            end

            if value == 'Static' then
                buffer.pitch = 'Custom'
                buffer.pitch_offset = pitch_offset_1

                return
            end

            if value == 'Sway' then
                local time = globals.curtime() * speed * 0.1

                local offset = utils.lerp(
                    pitch_offset_1,
                    pitch_offset_2,
                    time % 1
                )

                buffer.pitch = 'Custom'
                buffer.pitch_offset = offset
            end

            if value == 'Switch' then
                local offset = pitch_inverted
                    and pitch_offset_2
                    or pitch_offset_1

                buffer.pitch = 'Custom'
                buffer.pitch_offset = offset

                return
            end

            if value == 'Random' then
                buffer.pitch = 'Custom'

                buffer.pitch_offset = utils.random_int(
                    pitch_offset_1, pitch_offset_2
                )

                return
            end

            if value == 'Static Random' then
                local exp_data = exploit.get()
                local def_data = exp_data.defensive

                if def_data.left == def_data.max then
                    generated_pitch = utils.random_int(
                        pitch_offset_1, pitch_offset_2
                    )
                end

                buffer.pitch = 'Custom'
                buffer.pitch_offset = generated_pitch
            end
        end

        local function update_yaw(buffer, items)
            local value = items.yaw:get()

            local offset = items.yaw_offset:get()

            if value == 'Off' then
                return
            end

            buffer.freestanding = false

            buffer.yaw_left = 0
            buffer.yaw_right = 0

            buffer.yaw_offset = 0

            buffer.yaw_jitter = 'Off'
            buffer.jitter_offset = 0

            if value == 'Side Based' then
                buffer.yaw = '180'
                buffer.yaw_offset = 0

                buffer.yaw_left = -offset
                buffer.yaw_right = offset
            end

            if value == 'Opposite' then
                buffer.yaw = '180'
                buffer.yaw_offset = -180 + offset
            end

            if value == 'Spin' then
                buffer.yaw = '180'
                buffer.yaw_offset = globals.curtime() * (offset * 12) % 360
            end

            if value == 'Sway' then
                local speed = items.yaw_speed:get()

                local yaw_offset_1 = items.yaw_left:get()
                local yaw_offset_2 = items.yaw_right:get()

                local time = globals.curtime() * speed * 0.1

                local add = utils.lerp(
                    yaw_offset_1,
                    yaw_offset_2,
                    time % 1
                )

                buffer.yaw = '180'
                buffer.yaw_offset = add
            end

            if value == 'Random' then
                local add = utils.random_int(
                    -offset, offset
                )

                buffer.yaw = '180'
                buffer.yaw_offset = add
            end

            if value == 'Left/Right' then
                buffer.yaw = '180'
                buffer.yaw_offset = 0

                buffer.yaw_left = items.yaw_left:get()
                buffer.yaw_right = items.yaw_right:get()
            end

            if value == 'Static Random' then
                local exp_data = exploit.get()
                local def_data = exp_data.defensive

                if def_data.left == def_data.max then
                    local yaw_offset_1 = items.yaw_left:get()
                    local yaw_offset_2 = items.yaw_right:get()

                    generated_yaw = utils.random_int(
                        yaw_offset_1, yaw_offset_2
                    )
                end

                buffer.yaw = '180'
                buffer.yaw_offset = generated_yaw
            end

            if value == 'X-Way' then
                local ways_count = items.ways_count:get()
                local ways_custom = items.ways_custom:get()

                local stage = localplayer.sent_packets % ways_count

                if ways_custom then
                    local item_value = items['way_' .. stage + 1]

                    if item_value ~= nil then
                        local add = item_value:get()

                        buffer.yaw = '180'
                        buffer.yaw_offset = add
                    end
                else
                    local progress = stage / (ways_count - 1)
                    local add = utils.lerp(-offset, offset, progress)

                    buffer.yaw = '180'
                    buffer.yaw_offset = add
                end

                if items.ways_auto_body_yaw:get() then
                    local body_yaw_offset = 0

                    if buffer.yaw_offset < 0 then
                        body_yaw_offset = -1
                    end

                    if buffer.yaw_offset > 0 then
                        body_yaw_offset = 1
                    end

                    buffer.body_yaw = 'Static'
                    buffer.body_yaw_offset = body_yaw_offset
                end
            end

            if value == '3-Way' then
                local pattern = { -1.0, 0.0, 1.0 }
                local index = localplayer.sent_packets % #pattern

                local add = pattern[index + 1] * offset

                buffer.yaw = '180'
                buffer.yaw_offset = add
            end

            if value == '5-Way' then
                local pattern = { -1.0, -0.5, 0.0, 0.5, 1.0 }
                local index = localplayer.sent_packets % #pattern

                local add = pattern[index + 1] * offset

                buffer.yaw = '180'
                buffer.yaw_offset = add
            end
        end

        local function update_body_yaw(buffer, items)
            if items.body_yaw == nil then
                return
            end

            local body_yaw = items.body_yaw:get()
            local body_yaw_offset = items.body_yaw_offset:get()

            local freestanding_body_yaw = false

            if body_yaw ~= 'Jitter' and body_yaw ~= 'Jitter Random' then
                freestanding_body_yaw = items.freestanding_body_yaw:get()
            end

            buffer.body_yaw = body_yaw
            buffer.body_yaw_offset = body_yaw_offset

            buffer.freestanding_body_yaw = freestanding_body_yaw

            if items.delay_from ~= nil and items.delay_to ~= nil then
                buffer.delay = utils.random_int(
                    items.delay_from:get(),
                    items.delay_to:get()
                )
            end
        end

        function defensive:update(cmd)
            if cmd.chokedcommands == 0 then
                update_pitch_inverter()
                update_modifier_inverter()
            end
        end

        function defensive:apply(cmd, items)
            if items.force_defensive ~= nil and items.force_defensive:get() then
                cmd.force_defensive = true
            end

            local is_duck_peek_active = software.is_duck_peek_assist()

            if not is_exploit_active() or is_duck_peek_active then
                return false
            end

            local exploit_data = exploit.get()
            local defensive_data = exploit_data.defensive

            if defensive_data.left <= 0 then
                return
            end

            if not items.enabled:get() then
                return false
            end

            local buffer_ctx = { }

            update_body_yaw(buffer_ctx, items)
            update_pitch(buffer_ctx, items)
            update_yaw(buffer_ctx, items)

            buffer.defensive = buffer_ctx

            return true
        end
    end

    local fakelag_clone = { } do
        local ref = resource.antiaim.fakelag

        local HOTKEY_MODE = {
            [0] = 'Always on',
            [1] = 'On hotkey',
            [2] = 'Toggle',
            [3] = 'Off hotkey'
        }

        local function get_hotkey_value(_, mode, key)
            return HOTKEY_MODE[mode], key or 0
        end

        function fakelag_clone:update()
            override.set(software.antiaimbot.fake_lag.enabled[1], ref.enabled:get())
            override.set(software.antiaimbot.fake_lag.enabled[2], get_hotkey_value(ref.hotkey:get()))

            override.set(software.antiaimbot.fake_lag.amount, ref.amount:get())

            override.set(software.antiaimbot.fake_lag.variance, ref.variance:get())
            override.set(software.antiaimbot.fake_lag.limit, ref.limit:get())
        end

        function fakelag_clone:shutdown()
            override.unset(software.antiaimbot.fake_lag.enabled[1])
            override.unset(software.antiaimbot.fake_lag.enabled[2])

            override.unset(software.antiaimbot.fake_lag.amount)

            override.unset(software.antiaimbot.fake_lag.variance)
            override.unset(software.antiaimbot.fake_lag.limit)
        end
    end

    local builder = { } do
        local ref = resource.antiaim.builder

        local TEAM_T  = 2
        local TEAM_CT = 3

        local function get_move_direction(move_dir)
            local list = { }

            if move_dir.x > 0 then
                table.insert(list, 'Forward')
            end

            if move_dir.x < 0 then
                table.insert(list, 'Backward')
            end

            if move_dir.y > 0 then
                table.insert(list, 'Right')
            end

            if move_dir.y < 0 then
                table.insert(list, 'Left')
            end

            return table.concat(list, '-')
        end

        local function update_pitch(items)
            buffer.pitch = 'Default'
        end

        local function update_yaw_base(items)
            if items.yaw_base == nil then
                buffer.yaw_base = 'At targets'
            else
                buffer.yaw_base = items.yaw_base:get()
            end
        end

        local function update_yaw(items)
            local is_valid = (
                items.yaw_left ~= nil
                and items.yaw_right ~= nil
            )

            if not is_valid then
                return
            end

            local yaw_left = items.yaw_left:get()
            local yaw_right = items.yaw_right:get()

            local yaw_random = items.yaw_random:get()

            local random_left = yaw_left * yaw_random * 0.01
            local random_right = yaw_right * yaw_random * 0.01

            yaw_left = yaw_left + utils.random_int(-random_left, random_left)
            yaw_right = yaw_right + utils.random_int(-random_right, random_right)

            buffer.yaw = '180'
            buffer.yaw_offset = 0

            buffer.yaw_left = yaw_left
            buffer.yaw_right = yaw_right

            if items.yaw_direction ~= nil then
                local dir = get_move_direction(
                    localplayer.move_dir
                )

                local item_yaw_left = items['yaw_left_dir_' .. dir]
                local item_yaw_right = items['yaw_right_dir_' .. dir]

                if item_yaw_left ~= nil and item_yaw_right ~= nil then
                    buffer.yaw_left = item_yaw_left:get()
                    buffer.yaw_right = item_yaw_right:get()
                end
            end
        end

        local function update_jitter(items)
            if items.yaw_jitter == nil then
                return
            end

            local yaw_jitter = items.yaw_jitter:get()
            local jitter_offset = items.jitter_offset:get()

            if yaw_jitter ~= 'Off' then
                local random = items.jitter_random:get() * 0.01
                local random_offset = jitter_offset * random

                jitter_offset = jitter_offset + utils.random_int(
                    -random_offset, random_offset
                )
            end

            buffer.yaw_jitter = yaw_jitter
            buffer.jitter_offset = jitter_offset
        end

        local function update_body_yaw(items)
            if items.body_yaw == nil then
                return
            end

            local body_yaw = items.body_yaw:get()
            local body_yaw_offset = items.body_yaw_offset:get()

            local freestanding_body_yaw = false

            if body_yaw ~= 'Jitter' and body_yaw ~= 'Jitter Random' then
                freestanding_body_yaw = items.freestanding_body_yaw:get()
            end

            buffer.body_yaw = body_yaw
            buffer.body_yaw_offset = body_yaw_offset

            buffer.freestanding_body_yaw = freestanding_body_yaw

            if items.delay_from ~= nil and items.delay_to ~= nil then
                buffer.delay = utils.random_int(
                    items.delay_from:get(),
                    items.delay_to:get()
                )
            end
        end

        function builder:get(state, team)
            local items = ref[state]

            if items == nil then
                return nil
            end

            return items[team]
        end

        function builder.get_team(player)
            local team = entity.get_prop(
                player, 'm_iTeamNum'
            )

            if team == TEAM_T then
                return 'Terrorist'
            end

            if team == TEAM_CT then
                return 'Counter-Terrorist'
            end

            return nil
        end

        function builder:is_active_ex(items)
            local angles = items.angles

            if angles == nil then
                return false
            end

            return angles.enabled == nil
                or angles.enabled:get()
        end

        function builder:is_active(state)
            local items = self:get(state)

            if items == nil then
                return false
            end

            return self:is_active_ex(items)
        end

        function builder:apply_ex(items)
            if items == nil then
                return false
            end

            local angles = items.angles

            if angles == nil then
                return false
            end

            buffer.enabled = true

            update_pitch(angles)
            update_yaw_base(angles)
            update_yaw(angles)
            update_jitter(angles)
            update_body_yaw(angles)

            return true
        end

        function builder:apply(state, team)
            local items = self:get(
                state, team
            )

            if items == nil then
                return false, nil
            end

            if not self:is_active_ex(items) then
                return false, items
            end

            local angles = items.angles

            if angles == nil then
                return false
            end

            self:apply_ex(items)
            return true, items
        end

        function builder:update(cmd, team)
            local states = statement.get()
            local state = states[#states]

            if state == nil then
                return false, nil, nil
            end

            local active, items = self:apply(
                state, team
            )

            if not active or items == nil then
                local _, new_items = self:apply(
                    'Default', team
                )

                if new_items ~= nil then
                    items = new_items
                    state = 'Default'
                end
            end

            return true, items, state
        end
    end

    local freestanding = { } do
        local ref = resource.antiaim.hotkeys.freestanding

        local last_ack_defensive_side = nil
        local freestanding_side = nil

        local function is_value_near(value, target)
            return math.abs(target - value) <= 2.0
        end

        local function get_target_yaw(player)
            local threat = client.current_threat()

            if threat == nil then
                return nil
            end

            local player_origin = vector(
                entity.get_origin(player)
            )

            local threat_origin = vector(
                entity.get_origin(threat)
            )

            local delta = threat_origin - player_origin
            local _, yaw = delta:angles()

            return yaw - 180
        end

        local function get_approximated_side(yaw)
            if is_value_near(yaw, -90) then
                return -90
            end

            if is_value_near(yaw, 90) then
                return 90
            end

            return nil
        end

        local function get_side()
            local me = entity.get_local_player()

            if me == nil then
                return nil
            end

            local entity_data = c_entity(me)

            if entity_data == nil then
                return nil
            end

            local animstate = entity_data:get_anim_state()

            if animstate == nil then
                return nil
            end

            local target_yaw = get_target_yaw(me)

            if target_yaw == nil then
                return nil
            end

            return get_approximated_side(
                utils.normalize(animstate.eye_angles_y - target_yaw, -180, 180)
            )
        end

        local function get_state()
            if not localplayer.is_onground then
                return 'Air'
            end

            if localplayer.is_crouched then
                return 'Crouched'
            end

            if localplayer.is_moving then
                if software.is_slow_motion() then
                    return 'Slow Walk'
                end

                return 'Moving'
            end

            return 'Standing'
        end

        local function is_disabled()
            return ref.disablers:get(
                get_state()
            )
        end

        local function is_enabled()
            if ui.is_menu_open() then
                return false
            end

            if not ref.enabled:get() then
                return false
            end

            if not ref.hotkey:get() then
                return false
            end

            return not is_disabled()
        end

        local function update_freestanding_options(cmd, team)
            local items = builder:get(
                'Freestanding', team
            )

            if items ~= nil and items.override ~= nil and not items.override:get() then
                items = nil
            end

            if freestanding_side ~= nil then
                buffer.pitch = 'Default'

                if items ~= nil then
                    builder:apply_ex(items)
                end
            end

            if localplayer.is_vulnerable then
                if items ~= nil and items.defensive ~= nil then
                    if defensive:apply(cmd, items.defensive) then
                        local yaw_offset = buffer.defensive.yaw_offset

                        if yaw_offset ~= nil and last_ack_defensive_side ~= nil then
                            buffer.defensive.yaw_offset = yaw_offset + last_ack_defensive_side
                        end
                    else
                        if freestanding_side ~= nil then
                            last_ack_defensive_side = freestanding_side
                        end
                    end
                end
            end
        end

        function freestanding:update(cmd, team)
            if not is_enabled() then
                freestanding_side = nil
                return
            end

            if cmd.chokedcommands == 0 then
                freestanding_side = get_side()
            end

            buffer.freestanding = true
            update_freestanding_options(cmd, team)
        end
    end

    local antiaim_on_use = { } do
        local is_interact_traced = false

        local function should_update(cmd, items)
            local me = entity.get_local_player()

            if me == nil then
                return false
            end

            local weapon = entity.get_player_weapon(me)

            if weapon == nil then
                return false
            end

            local weapon_info = csgo_weapons(weapon)

            if weapon_info == nil then
                return false
            end

            local team = entity.get_prop(me, 'm_iTeamNum')
            local my_origin = vector(entity.get_origin(me))

            local is_weapon_bomb = weapon_info.idx == 49

            local is_defusing = entity.get_prop(me, 'm_bIsDefusing') == 1
            local is_rescuing = entity.get_prop(me, 'm_bIsGrabbingHostage') == 1

            local in_bomb_site = entity.get_prop(me, 'm_bInBombZone') == 1

            if is_defusing or is_rescuing then
                return false
            end

            if in_bomb_site then
                local angles = items.angles

                if not angles.bomb_e_fix:get() or is_weapon_bomb then
                    return false
                end
            end

            if team == 3 and cmd.pitch > 15 then
                local bombs = entity.get_all 'CPlantedC4'

                for i = 1, #bombs do
                    local bomb = bombs[i]

                    local origin = vector(
                        entity.get_origin(bomb)
                    )

                    local delta = origin - my_origin
                    local distancesqr = delta:lengthsqr()

                    if distancesqr < (62 * 62) then
                        return false
                    end
                end
            end

            local camera = vector(client.camera_angles())
            local forward = vector():init_from_angles(camera:unpack())

            local eye_pos = vector(client.eye_position())
            local end_pos = eye_pos + forward * 128

            local fraction, entindex = client.trace_line(
                me, eye_pos.x, eye_pos.y, eye_pos.z, end_pos.x, end_pos.y, end_pos.z
            )

            if fraction ~= 1 then
                if entindex == -1 then
                    return true
                end

                local classname = entity.get_classname(entindex)

                if classname == 'CWorld' then
                    return true
                end

                if classname == 'CFuncBrush' then
                    return true
                end

                if classname == 'CCSPlayer' then
                    return true
                end

                if classname == 'CHostage' then
                    local origin = vector(entity.get_origin(entindex))
                    local distance = eye_pos:distsqr(origin)

                    if distance < (84 * 84) then
                        return false
                    end
                end

                if not is_interact_traced then
                    is_interact_traced = true
                    return false
                end
            end

            return true
        end

        function antiaim_on_use:update(cmd, team)
            if cmd.in_use == 0 then
                is_interact_traced = false

                return false
            end

            local items = builder:get(
                'Legit AA', team
            )

            if items == nil then
                return false
            end

            local angles = items.angles

            if angles == nil then
                return false
            end

            if angles.enabled ~= nil and not angles.enabled:get() then
                return false
            end

            if not should_update(cmd, items) then
                return false
            end

            buffer.yaw_base = 'Local view'

            builder:apply_ex(items)

            buffer.pitch = 'Custom'
            buffer.pitch_offset = cmd.pitch

            if items ~= nil and items.defensive ~= nil then
                defensive:apply(cmd, items.defensive)
            end

            buffer.yaw_offset = buffer.yaw_offset + 180
            buffer.freestanding = false

            cmd.in_use = 0

            return true
        end
    end

    local roll_aa = { } do
        local ref = resource.antiaim.hotkeys.roll_aa

        function roll_aa:apply(cmd)
            if not ref.enabled:get() then
                return false
            end

            cmd.roll = ref.value:get()

            return true
        end

        function roll_aa:update(cmd, team)
            if not ref.enabled:get() then
                return false
            end

            if not ref.hotkey:get() then
                return
            end

            cmd.roll = ref.value:get()

            builder:apply('Roll AA', team)
        end
    end

    local manual_yaw = { } do
        local ref = resource.antiaim.hotkeys.manual_yaw

        local current_dir = nil
        local hotkey_data = { }

        local dir_rotations = {
            ['left'] = -90,
            ['right'] = 90,
            ['forward'] = 180,
            ['backward'] = 0
        }

        local function get_hotkey_state(old_state, state, mode)
            if mode == 1 or mode == 2 then
                return old_state ~= state
            end

            return false
        end

        local function update_hotkey_state(data, state, mode)
            local active = get_hotkey_state(
                data.state, state, mode
            )

            data.state = state

            return active
        end

        local function update_hotkey_data(id, dir)
            local state, mode = ui.get(id)

            if hotkey_data[id] == nil then
                hotkey_data[id] = {
                    state = state
                }
            end

            local changed = update_hotkey_state(
                hotkey_data[id], state, mode
            )

            if not changed then
                return
            end

            if current_dir == dir then
                current_dir = nil
            else
                current_dir = dir
            end
        end

        local function on_paint_ui()
            update_hotkey_data(ref.left_hotkey.ref, 'left')
            update_hotkey_data(ref.right_hotkey.ref, 'right')
            update_hotkey_data(ref.forward_hotkey.ref, 'forward')
            update_hotkey_data(ref.backward_hotkey.ref, 'backward')

            update_hotkey_data(ref.reset_hotkey.ref, nil)
        end

        function manual_yaw:get()
            return current_dir
        end

        function manual_yaw:update(cmd, team)
            local angle = dir_rotations[
                current_dir
            ]

            if angle == nil then
                return false
            end

            local yaw = buffer.yaw_offset or 0

            buffer.enabled = true

            buffer.yaw_offset = yaw + angle

            buffer.edge_yaw = false
            buffer.freestanding = false

            buffer.roll = 0

            buffer.defensive = nil

            if ref.options:get 'Disable yaw modifiers' then
                buffer.yaw_offset = yaw + angle

                buffer.yaw_left = 0
                buffer.yaw_right = 0

                buffer.yaw_jitter = 'Off'
                buffer.jitter_offset = 0
            end

            if ref.options:get 'Freestanding body' then
                buffer.body_yaw = 'Static'
                buffer.body_yaw_offset = 180
                buffer.freestanding_body_yaw = true
            end

            local state, items = builder:apply(
                'Manual AA', team
            )

            roll_aa:apply(cmd)

            if state and items ~= nil then
                if items.defensive ~= nil then
                    local applied = defensive:apply(
                        cmd, items.defensive
                    )

                    if not applied then
                        goto continue
                    end

                    local defensive_buffer = buffer.defensive

                    if defensive_buffer ~= nil and defensive_buffer.yaw_offset ~= nil then
                        defensive_buffer.yaw_offset = defensive_buffer.yaw_offset + angle
                    end

                    ::continue::
                end

                buffer.yaw_offset = buffer.yaw_offset + angle
            end

            buffer.yaw_base = 'Local view'

            return true
        end

        local callbacks do
            local function update_event_callbacks(value)
                if not value then
                    current_dir = nil
                end

                utils.event_callback(
                    'paint_ui',
                    on_paint_ui,
                    value
                )
            end

            local function on_enabled(item)
                update_event_callbacks(item:get())
            end

            ref.enabled:set_callback(
                on_enabled, true
            )
        end

        antiaim.manual_yaw = manual_yaw
    end

    local avoid_backstab = { } do
        local ref = resource.antiaim.features.avoid_backstab

        local function is_weapon_knife(weapon)
            local weapon_info = csgo_weapons(weapon)

            if weapon_info == nil then
                return false
            end

            -- is weapon taser
            if weapon_info.idx == 31 then
                return false
            end

            if weapon_info.type ~= 'knife' then
                return false
            end

            return true
        end

        local function is_player_weapon_knife(player)
            local weapon = entity.get_player_weapon(player)

            if weapon == nil then
                return false
            end

            return is_weapon_knife(weapon)
        end

        local function get_targets(player)
            local targets = { }

            local player_team = entity.get_prop(player, 'm_iTeamNum')
            local player_resource = entity.get_player_resource()

            for i = 1, globals.maxplayers() do
                local is_connected = entity.get_prop(
                    player_resource, 'm_bConnected', i
                )

                if is_connected ~= 1 then
                    goto continue
                end

                local team = entity.get_prop(
                    player_resource, 'm_iTeam', i
                )

                if player == i or player_team == team then
                    goto continue
                end

                local is_alive = entity.get_prop(
                    player_resource, 'm_bAlive', i
                )

                if is_alive then
                    table.insert(targets, i)
                end

                ::continue::
            end

            return targets
        end

        local function get_backstab_angle(player)
            local best_delta = nil
            local best_target = nil
            local best_distancesqr = math.huge

            local origin = vector(
                entity.get_origin(player)
            )

            local me = entity.get_local_player()

            if me == nil then
                return false
            end

            local enemies = get_targets(me)

            for i = 1, #enemies do
                local enemy = enemies[i]

                if not is_player_weapon_knife(enemy) then
                    goto continue
                end

                local enemy_origin = vector(
                    entity.get_origin(enemy)
                )

                local delta = enemy_origin - origin
                local distancesqr = delta:lengthsqr()

                if distancesqr < best_distancesqr then
                    best_distancesqr = distancesqr

                    best_delta = delta
                    best_target = enemy
                end

                ::continue::
            end

            return best_target, best_distancesqr, best_delta
        end

        function avoid_backstab:update()
            if not ref.enabled:get() then
                return
            end

            local me = entity.get_local_player()

            if me == nil then
                return false
            end

            local target, distancesqr, delta = get_backstab_angle(me)

            local max_distance = ref.distance:get()
            local max_distance_sqr = max_distance * max_distance

            if target == nil or distancesqr > max_distance_sqr then
                return false
            end

            local angle = vector(
                delta:angles()
            )

            buffer.enabled = true
            buffer.yaw_base = 'Local view'

            buffer.yaw = 'Static'
            buffer.yaw_offset = angle.y

            buffer.freestanding_body_yaw = false

            buffer.edge_yaw = false
            buffer.freestanding = false

            buffer.roll = 0

            return true
        end
    end

    local break_lc_triggers = { } do
        local ref = resource.antiaim.features.break_lc_triggers

        local ACT_CSGO_RELOAD = 967

        local GetClientEntity = vtable_bind(
            'client.dll', 'VClientEntityList003',
            3, 'uint32_t(__thiscall*)(void*, int)'
        )

        local m_flFlashDuration = 0x10470 -- dumped nervar
        local m_flFlashBangTime = m_flFlashDuration - 0x10

        local function get_flashbang_time(player)
            if player == nil then
                return nil
            end

            local address = GetClientEntity(player)

            if address == nil then
                return nil
            end

            return ffi.cast('float*', address + m_flFlashBangTime)[0]
        end

        local function get_reload_time(player)
            if player == nil then
                return nil
            end

            local player_info = c_entity(player)

            if player_info == nil then
                return nil
            end

            local anim_layer = player_info:get_anim_overlay(1)

            if anim_layer == nil or anim_layer.entity == nil then
                return nil
            end

            local activity = player_info:get_sequence_activity(
                anim_layer.sequence
            )

            if activity ~= ACT_CSGO_RELOAD then
                return nil
            end

            if anim_layer.weight == 0 then
                return nil
            end

            return anim_layer.cycle
        end

        local function get_flinch(player)
            if player == nil then
                return nil
            end

            local player_info = c_entity(player)

            if player_info == nil then
                return nil
            end

            local anim_layer = player_info:get_anim_overlay(10)

            if anim_layer == nil then
                return nil
            end

            return anim_layer.weight
        end

        local function is_flashed(player)
            local flash_time = get_flashbang_time(player)

            return flash_time ~= nil
                and flash_time > 0
        end

        local function is_reloading(player)
            return get_reload_time(player) ~= nil
        end

        local function is_taking_damage(player)
            local flinch = get_flinch(player)

            return flinch ~= nil
                and flinch ~= 0
        end

        local function should_update()
            if not ref.enabled:get() then
                return false
            end

            local me = entity.get_local_player()

            if me == nil then
                return false
            end

            if ref.states:get 'Flashed' and is_flashed(me) then
                return true
            end

            if ref.states:get 'Reloading' and is_reloading(me) then
                return true
            end

            if ref.states:get 'Taking damage' and is_taking_damage(me) then
                return true
            end

            return false
        end

        function break_lc_triggers:update(cmd)
            if not should_update() then
                return
            end

            cmd.force_defensive = 1
        end
    end

    local warmup_round_end = { } do
        local ref = resource.antiaim.features.warmup_round_end

        local function are_enemies_dead()
            local me = entity.get_local_player()

            if me == nil then
                return false
            end

            local my_team = entity.get_prop(me, 'm_iTeamNum')
            local player_resource = entity.get_player_resource()

            for i = 1, globals.maxplayers() do
                local is_connected = entity.get_prop(
                    player_resource, 'm_bConnected', i
                )

                if is_connected ~= 1 then
                    goto continue
                end

                local player_team = entity.get_prop(
                    player_resource, 'm_iTeam', i
                )

                if me == i or player_team == my_team then
                    goto continue
                end

                local is_alive = entity.get_prop(
                    player_resource, 'm_bAlive', i
                )

                if is_alive == 1 then
                    return false
                end

                ::continue::
            end

            return true
        end

        local function should_update()
            local game_rules = entity.get_game_rules()

            if game_rules == nil then
                return false
            end

            local warmup_period = entity.get_prop(
                game_rules, 'm_bWarmupPeriod'
            )

            if warmup_period == 1 then
                return true
            end

            if are_enemies_dead() then
                return true
            end

            return false
        end

        function warmup_round_end:update()
            if not ref.enabled:get() then
                return false
            end

            if not should_update() then
                return false
            end

            buffer.enabled = true

            buffer.pitch = 'Custom'
            buffer.pitch_offset = 0

            buffer.yaw = 'Spin'
            buffer.yaw_offset = 100

            buffer.yaw_jitter = 'Off'
            buffer.jitter_offset = 0

            buffer.body_yaw = 'Static'
            buffer.body_yaw_offset = 1

            buffer.freestanding_body_yaw = false

            buffer.defensive = nil

            buffer.edge_yaw = false
            buffer.freestanding = false

            return true
        end
    end

    local flick_exploit = { } do
        local ref = resource.antiaim.features.flick_exploit

        local pitch_inverted = false
        local generated_pitch = 0

        local freestand_side = -1

        local function get_state()
            if not localplayer.is_onground then
                if localplayer.is_crouched then
                    return 'Air-Crouch'
                end

                return 'Air'
            end

            if localplayer.is_crouched then
                if localplayer.is_moving then
                    return 'Move-Crouch'
                end

                return 'Crouch'
            end

            if localplayer.is_moving then
                if software.is_slow_motion() then
                    return 'Slow Walk'
                end

                return 'Moving'
            end

            return 'Standing'
        end

        local function should_update()
            local exp_data = exploit.get()

            if not exp_data.shift then
                return false
            end

            local me = entity.get_local_player()

            if me == nil then
                return false
            end

            local weapon = entity.get_player_weapon(me)

            if weapon == nil then
                return false
            end

            local weapon_info = csgo_weapons(weapon)

            if weapon_info == nil or weapon_info.is_revolver then
                return false
            end

            local state = get_state()

            if state == nil then
                return false
            end

            return ref.states:get(state)
        end

        local function get_angles(player, target)
            local player_origin = vector(entity.get_origin(player))
            local target_origin = vector(entity.get_origin(target))

            return vector((target_origin - player_origin):angles())
        end

        local function update_freestand(cmd)
            local me = entity.get_local_player()

            if me == nil then
                return
            end

            local threat = client.current_threat()

            if threat == nil then
                return
            end

            local angles = get_angles(me, threat)

            local eye_pos = vector(utils.get_eye_position(me))
            local stomach = vector(entity.hitbox_position(threat, 3))

            local forward_left = vector():init_from_angles(0, angles.y + 90)
            local forward_right = vector():init_from_angles(0, angles.y - 90)

            local point_left = eye_pos + forward_left * 31
            local point_right = eye_pos + forward_right * 31

            local ent_left, damage_left = client.trace_bullet(
                me, point_left.x, point_left.y, point_left.z,
                stomach.x, stomach.y, stomach.z, false
            )

            local ent_right, damage_right = client.trace_bullet(
                me, point_right.x, point_right.y, point_right.z,
                stomach.x, stomach.y, stomach.z, false
            )

            if ent_left ~= threat then
                damage_left = 0
            end

            if ent_right ~= threat then
                damage_right = 0
            end

            local should_update = (
                (damage_left > 0 or damage_right > 0)
                and damage_left ~= damage_right
            )

            if should_update then
                freestand_side = (damage_left > damage_right) and -1 or 1
            end
        end

        local function update_pitch(buffer, items)
            local value = items.pitch:get()

            local pitch_offset_1 = items.pitch_offset_1:get()
            local pitch_offset_2 = items.pitch_offset_2:get()

            local speed = items.pitch_speed:get()

            if value == 'Off' then
                return
            end

            if value == 'Static' then
                buffer.pitch = 'Custom'
                buffer.pitch_offset = pitch_offset_1

                return
            end

            if value == 'Sway' then
                local time = globals.curtime() * speed * 0.1

                local offset = utils.lerp(
                    pitch_offset_1,
                    pitch_offset_2,
                    time % 1
                )

                buffer.pitch = 'Custom'
                buffer.pitch_offset = offset
            end

            if value == 'Switch' then
                local offset = pitch_inverted
                    and pitch_offset_2
                    or pitch_offset_1

                buffer.pitch = 'Custom'
                buffer.pitch_offset = offset

                return
            end

            if value == 'Random' then
                buffer.pitch = 'Custom'

                buffer.pitch_offset = utils.random_int(
                    pitch_offset_1, pitch_offset_2
                )

                return
            end

            if value == 'Static Random' then
                local exp_data = exploit.get()
                local def_data = exp_data.defensive

                if def_data.left == def_data.max then
                    generated_pitch = utils.random_int(
                        pitch_offset_1, pitch_offset_2
                    )
                end

                buffer.pitch = 'Custom'
                buffer.pitch_offset = generated_pitch
            end
        end

        function flick_exploit:update(cmd)
            if not ref.enabled:get() then
                return false
            end

            if not should_update() then
                return false
            end

            update_freestand(cmd)

            local inverter = freestand_side == -1
            local defensive = exploit.get().defensive

            local is_defensive_active = defensive.left ~= 0
            cmd.force_defensive = cmd.command_number % 7 == 0

            local buffer_ctx = { }

            buffer_ctx.pitch = is_defensive_active and 'Custom' or 'Default'
            buffer_ctx.pitch_offset = 0

            buffer_ctx.yaw_base = 'At targets'

            buffer_ctx.yaw = '180'
            buffer_ctx.yaw_offset = is_defensive_active and 90 or 0

            buffer_ctx.yaw_left = 0
            buffer_ctx.yaw_right = 0

            buffer_ctx.yaw_jitter = 'Off'
            buffer_ctx.jitter_offset = 0

            buffer_ctx.body_yaw = 'Static'
            buffer_ctx.body_yaw_offset = is_defensive_active and -1 or 1

            buffer_ctx.freestanding_body_yaw = false

            buffer_ctx.edge_yaw = false
            buffer_ctx.freestanding = false

            buffer_ctx.roll = 0

            if cmd.chokedcommands == 0 then
                pitch_inverted = not pitch_inverted
            end

            update_pitch(buffer_ctx, ref)

            if inverter then
                buffer_ctx.yaw_offset = -buffer_ctx.yaw_offset
                -- buffer_ctx.body_yaw_offset = -buffer_ctx.body_yaw_offset
            end

            buffer.defensive = buffer_ctx
        end
    end

    local function update_antiaims(cmd)
        fakelag_clone:update()

        local me = entity.get_local_player()

        if me == nil then
            return
        end

        local team = builder.get_team(me)

        if team == nil then
            return
        end

        local active, items, state = builder:update(cmd, team)

        defensive:update(cmd)
        break_lc_triggers:update(cmd)

        if antiaim_on_use:update(cmd, team) then
            return
        end

        if manual_yaw:update(cmd, team) then
            return
        end

        if avoid_backstab:update() then
            return
        end

        roll_aa:update(cmd, team)

        if active and items ~= nil and items.defensive ~= nil then
            defensive:apply(cmd, items.defensive)
        end

        edge_yaw:update(cmd)
        freestanding:update(cmd, team)

        if not safe_head:update(cmd) then
            flick_exploit:update(cmd)
        end

        warmup_round_end:update()
    end

    local function update_defensive(cmd)
        local list = buffer.defensive

        local is_exploit_active = (
            software.is_double_tap_active()
            or software.is_on_shot_antiaim_active()
        )

        if software.is_duck_peek_assist() then
            is_exploit_active = false
        end

        if not is_exploit_active then
            return false
        end

        local exp_data = exploit.get()
        local defensive = exp_data.defensive

        local is_valid = (
            list ~= nil and
            defensive.left > 0
        )

        if not is_valid then
            return
        end

        buffer:copy(list)
    end

    local function update_inverter()
        if exploit.get().shift then
            local delay = math.max(
                1, buffer.delay or 1
            )

            delay_ticks = delay_ticks + 1

            if delay_ticks < delay then
                return
            end
        end

        local should_invert = true

        if buffer.body_yaw == 'Jitter Random' then
            should_invert = utils.random_int(0, 1) == 0
        end

        inverts = inverts + 1

        if should_invert then
            inverted = not inverted
        end

        delay_ticks = 0
    end

    local function update_yaw_offset()
        if buffer.body_yaw_offset == nil then
            return
        end

        if buffer.yaw_left ~= nil and buffer.yaw_right ~= nil then
            local yaw = buffer.yaw_offset or 0

            if buffer.body_yaw_offset < 0 then
                buffer.yaw_offset = yaw + buffer.yaw_left
            end

            if buffer.body_yaw_offset > 0 then
                buffer.yaw_offset = yaw + buffer.yaw_right
            end

            return
        end
    end

    local function update_yaw_jitter()
        if buffer.yaw_jitter == 'Offset' then
            local yaw = buffer.yaw_offset or 0
            local offset = buffer.jitter_offset

            buffer.yaw_jitter = 'Off'
            buffer.jitter_offset = 0

            buffer.yaw_offset = yaw + (inverted and offset or 0)

            return
        end

        if buffer.yaw_jitter == 'Center' then
            local yaw = buffer.yaw_offset or 0
            local offset = buffer.jitter_offset

            if not inverted then
                offset = -offset
            end

            buffer.yaw_jitter = 'Off'
            buffer.jitter_offset = 0

            buffer.yaw_offset = yaw + offset / 2

            return
        end

        if buffer.yaw_jitter == 'Skitter' then
            local index = inverts % #skitter
            local multiplier = skitter[index + 1]

            local yaw = buffer.yaw_offset or 0
            local offset = buffer.jitter_offset

            buffer.yaw_jitter = 'Off'
            buffer.jitter_offset = 0

            buffer.yaw_offset = yaw + (offset * multiplier)

            return
        end

        if buffer.yaw_jitter == 'Spin' then
            local time = globals.curtime() * 3

            local yaw = buffer.yaw_offset or 0
            local offset = buffer.jitter_offset

            buffer.yaw_jitter = 'Off'
            buffer.jitter_offset = 0

            buffer.yaw_offset = yaw + utils.lerp(
                -offset, offset, time % 1
            )

            return
        end
    end

    local function update_body_yaw()
        if buffer.body_yaw == 'Jitter' then
            local offset = buffer.body_yaw_offset

            if offset == 0 then
                offset = 1
            end

            if not inverted then
                offset = -offset
            end

            buffer.body_yaw = 'Static'
            buffer.body_yaw_offset = offset
        end

        if buffer.body_yaw == 'Jitter Random' then
            local offset = buffer.body_yaw_offset

            if offset == 0 then
                offset = 1
            end

            buffer.body_yaw = 'Static'
            buffer.body_yaw_offset = inverted and offset or -offset
        end
    end

    local function update_buffer(cmd)
        update_defensive(cmd)

        if cmd.chokedcommands == 0 then
            update_inverter()
        end

        update_body_yaw()
        update_yaw_jitter()
        update_yaw_offset()
    end

    local function on_shutdown()
        fakelag_clone:shutdown()
        buffer:unset()
    end

    local function on_pre_config_save()
        fakelag_clone:shutdown()
        buffer:unset()
    end

    local function on_setup_command(cmd)
        buffer:clear()
        buffer:unset()

        update_antiaims(cmd)
        update_buffer(cmd)

        buffer:set()
    end

    utils.event_callback(
        'shutdown',
        on_shutdown
    )

    utils.event_callback(
        'pre_config_save',
        on_pre_config_save
    )

    utils.event_callback(
        'setup_command',
        on_setup_command
    )
end

local render do
    local changers do
        local aspect_ratio do
            local ref = resource.render.changers.aspect_ratio

            local r_aspectratio = cvar.r_aspectratio

            local function shutdown_aspect_ratio()
                r_aspectratio:set_raw_float(
                    tostring(r_aspectratio:get_string())
                )
            end

            local function on_shutdown()
                shutdown_aspect_ratio()
            end

            local function update_event_callbacks(value)
                if not value then
                    shutdown_aspect_ratio()
                end

                utils.event_callback(
                    'shutdown',
                    on_shutdown,
                    value
                )
            end

            local callbacks do
                local function on_value(item)
                    r_aspectratio:set_raw_float(
                        item:get() * 0.01
                    )
                end

                local function on_enabled(item)
                    local value = item:get()

                    if value then
                        ref.value:set_callback(on_value, true)
                    else
                        ref.value:unset_callback(on_value)
                    end

                    update_event_callbacks(value)
                end

                ref.enabled:set_callback(
                    on_enabled, true
                )
            end
        end

        local third_person do
            local ref = resource.render.changers.third_person

            local cam_idealdist = cvar.cam_idealdist

            local ref_third_person = {
                ui.reference('Visuals', 'Effects', 'Force third person (alive)')
            }

            local dist_value = 15

            local function restore_values()
                cam_idealdist:set_float(tonumber(cam_idealdist:get_string()))
            end

            local function update_values(value)
                cam_idealdist:set_raw_float(value)
            end

            local function on_shutdown()
                cam_idealdist:set_raw_float(dist_value)
            end

            local function on_paint_ui()
                local me = entity.get_local_player()

                local should_update = (
                    entity.is_alive(me)
                    and ui.get(ref_third_person[1])
                    and ui.get(ref_third_person[2])
                )

                if not should_update then
                    dist_value = 15
                    return
                end

                local distance = ref.distance:get()
                local zoom_speed = ref.zoom_speed:get()

                local offset = (distance - dist_value) / zoom_speed

                dist_value = dist_value + (distance > dist_value and offset or -offset)
                dist_value = distance < dist_value and distance or dist_value

                update_values(dist_value)
            end

            local callbacks do
                local function on_enabled(item)
                    local value = item:get()

                    if not value then
                        restore_values()
                    end

                    utils.event_callback(
                        'shutdown',
                        on_shutdown,
                        value
                    )

                    utils.event_callback(
                        'paint_ui',
                        on_paint_ui,
                        value
                    )
                end

                ref.enabled:set_callback(
                    on_enabled, true
                )
            end
        end

        local viewmodel do
            local ref = resource.render.changers.viewmodel

            local cl_bobup = cvar.cl_bobup
            local cl_bobamt_lat = cvar.cl_bobamt_lat
            local cl_bobamt_vert = cvar.cl_bobamt_vert

            local cl_righthand = cvar.cl_righthand

            local viewmodel_fov = cvar.viewmodel_fov

            local viewmodel_offset_x = cvar.viewmodel_offset_x
            local viewmodel_offset_y = cvar.viewmodel_offset_y
            local viewmodel_offset_z = cvar.viewmodel_offset_z

            local scope_value = 0.0
            local viewmodel_scope_cache = { }

            local function restore_viewmodel_scope()
                for i = 1, #viewmodel_scope_cache do
                    local weapon_idx = viewmodel_scope_cache[i]
                    local weapon_info = csgo_weapons[weapon_idx]

                    weapon_info.raw.hide_view_model_zoomed = true
                end
            end

            local function update_viewmodel_scope(weapon_info)
                if not weapon_info.raw.hide_view_model_zoomed then
                    return
                end

                weapon_info.raw.hide_view_model_zoomed = false
                table.insert(viewmodel_scope_cache, weapon_info.idx)
            end

            local function get_weapon_info()
                local me = entity.get_local_player()

                if me == nil then
                    return nil
                end

                local weapon = entity.get_player_weapon(me)

                if weapon == nil then
                    return nil
                end

                return csgo_weapons(weapon)
            end

            local function get_viewmodel_offset()
                local me = entity.get_local_player()

                if me == nil or not entity.is_alive(me) then
                    return nil, nil, nil
                end

                local weapon = entity.get_player_weapon(me)

                if weapon == nil then
                    return nil, nil, nil
                end

                local weapon_info = csgo_weapons(weapon)

                if weapon_info == nil then
                    return nil, nil, nil
                end

                local x = ref.offset_x:get() * 0.1
                local y = ref.offset_y:get() * 0.1
                local z = ref.offset_z:get() * 0.1

                local is_viewmodel_in_scope = (
                    ref.options:get 'Scope down sight'
                    or ref.options:get 'Viewmodel in scope'
                )

                if ref.options:get 'Legacy animation' then
                    local velocity = vector(
                        entity.get_prop(me, 'm_vecVelocity')
                    )

                    local modifier = math.min(
                        1.0, velocity:length() / 300
                    )

                    cl_bobup:set_raw_int(0)
                    cl_bobamt_lat:set_raw_float(0)
                    cl_bobamt_vert:set_raw_float(0)

                    viewmodel_offset_y:set_raw_float(y)
                    viewmodel_offset_z:set_raw_float(z)

                    y = y + math.sin(globals.realtime() * 6) * modifier * 0.8
                    z = z + math.sin(globals.realtime() * 3) * modifier * 0.2
                end

                if ref.options:get 'Scope down sight' then
                    local is_scoped = entity.get_prop(
                        me, 'm_bIsScoped'
                    )

                    scope_value = motion.interp(
                        scope_value, is_scoped == 1, 0.05
                    )

                    x = utils.lerp(x, -4.75, scope_value)
                    y = utils.lerp(y, -5, scope_value)
                    z = utils.lerp(z, -2, scope_value)
                else
                    scope_value = 0
                end

                if is_viewmodel_in_scope then
                    update_viewmodel_scope(weapon_info)
                else
                    restore_viewmodel_scope()
                end

                return x, y, z
            end

            local function update_knife_hand(is_knife)
                local is_right = cl_righthand:get_string() == '1'

                if is_right then
                    cl_righthand:set_raw_int(is_knife and 0 or 1)
                else
                    cl_righthand:set_raw_int(is_knife and 1 or 0)
                end
            end

            local function shutdown_viewmodel()
                restore_viewmodel_scope()

                cl_bobup:set_float(tonumber(cl_bobup:get_string()))
                cl_bobamt_lat:set_float(tonumber(cl_bobamt_lat:get_string()))
                cl_bobamt_vert:set_float(tonumber(cl_bobamt_vert:get_string()))

                viewmodel_fov:set_float(tonumber(viewmodel_fov:get_string()))

                viewmodel_offset_x:set_float(tonumber(viewmodel_offset_x:get_string()))
                viewmodel_offset_y:set_float(tonumber(viewmodel_offset_y:get_string()))
                viewmodel_offset_z:set_float(tonumber(viewmodel_offset_z:get_string()))

                cl_righthand:set_int(cl_righthand:get_string() == '1' and 1 or 0)
            end

            local function on_shutdown()
                shutdown_viewmodel()
            end

            local function on_pre_render()
                local x, y, z = get_viewmodel_offset()

                if x == nil or y == nil or z == nil then
                    return
                end

                viewmodel_offset_x:set_raw_float(x)
                viewmodel_offset_y:set_raw_float(y)
                viewmodel_offset_z:set_raw_float(z)
            end

            local function on_pre_render_knife(cmd)
                local weapon_info = get_weapon_info()

                if weapon_info == nil then
                    return
                end

                local weapon_index = weapon_info.idx

                if old_weaponindex ~= weapon_index then
                    weapon_index = old_weaponindex

                    -- update opposite knife in hand
                    update_knife_hand(weapon_info.type == 'knife')
                end
            end

            local function update_event_callbacks(value)
                if not value then
                    shutdown_viewmodel()

                    utils.event_callback(
                        'pre_render',
                        on_pre_render_knife,
                        false
                    )
                end

                utils.event_callback(
                    'shutdown',
                    on_shutdown,
                    value
                )

                utils.event_callback(
                    'pre_render',
                    on_pre_render,
                    value
                )
            end

            local callbacks do
                local function on_fov(item)
                    viewmodel_fov:set_raw_float(
                        item:get() * 0.1
                    )
                end

                local function on_options(item)
                    local value = item:get 'Opposite knife hand'

                    if value then
                        local weapon_info = get_weapon_info()

                        if weapon_info ~= nil then
                            update_knife_hand(weapon_info.type == 'knife')
                        end
                    else
                        cl_righthand:set_raw_int(cl_righthand:get_string() == '1' and 1 or 0)
                    end

                    utils.event_callback(
                        'pre_render',
                        on_pre_render_knife,
                        value
                    )
                end

                local function on_enabled(item)
                    local value = item:get()

                    if not value then
                        shutdown_viewmodel()
                    end

                    if value then
                        ref.fov:set_callback(on_fov, true)
                        ref.options:set_callback(on_options, true)
                    else
                        ref.fov:unset_callback(on_fov)
                        ref.options:unset_callback(on_options)
                    end

                    update_event_callbacks(value)
                end

                ref.enabled:set_callback(
                    on_enabled, true
                )
            end
        end

        local custom_scope do
            local ref = resource.render.changers.custom_scope

            local RESOLUTION = 1 / 1080

            local alpha = 0.0

            local function draw_gradient(x, y, w, h, r1, g1, b1, a1, r2, g2, b2, a2, horizontal)
                local fade = ref.start_fade:get() * 0.01 * 2

                if horizontal then
                    local half_w = math.floor(w * fade * 0.5)

                    renderer.gradient(x, y, half_w, h, r2, g2, b2, a2, r1, g1, b1, a1, true)
                    renderer.gradient(x + half_w, y, w - half_w, h, r1, g1, b1, a1, r2, g2, b2, a2, true)
                else
                    local half_h = math.floor(h * fade * 0.5)

                    renderer.gradient(x, y, w, half_h, r2, g2, b2, a2, r1, g1, b1, a1, false)
                    renderer.gradient(x, y + half_h, w, h - half_h, r1, g1, b1, a1, r2, g2, b2, a2, false)
                end
            end

            local function on_paint()
                override.set(software.visuals.effects.remove_scope_overlay, false)
            end

            local function on_paint_ui()
                local me = entity.get_local_player()

                if me == nil or not entity.is_alive(me) then
                    return
                end

                override.set(software.visuals.effects.remove_scope_overlay, true)

                local is_scoped = entity.get_prop(
                    me, 'm_bIsScoped'
                )

                alpha = motion.interp(alpha, is_scoped == 1, 1 / ref.animation_speed:get())

                if alpha == 0.0 then
                    return
                end

                local screen = vector(
                    client.screen_size()
                )

                local center = screen * 0.5

                local col = color(ref.color:get())

                local offset = ref.offset:get() * screen.y * RESOLUTION
                local position = ref.position:get() * screen.y * RESOLUTION

                offset = math.floor(offset)
                position = math.floor(position)

                local delta = position - offset

                local color_a = col:clone()
                local color_b = col:clone()

                color_a.a = color_a.a * alpha
                color_b.a = 0

                local render_fn = ref.style:get() == 'New'
                    and draw_gradient or renderer.gradient

                if not ref.exclude:get 'Top' then
                    render_fn(
                        center.x, center.y - offset + 1, 1, -delta,
                        color_a.r, color_a.g, color_a.b, color_a.a,
                        color_b.r, color_b.g, color_b.b, color_b.a,
                        false
                    )
                end

                if not ref.exclude:get 'Bottom' then
                    render_fn(
                        center.x, center.y + offset, 1, delta,
                        color_a.r, color_a.g, color_a.b, color_a.a,
                        color_b.r, color_b.g, color_b.b, color_b.a,
                        false
                    )
                end

                if not ref.exclude:get 'Left' then
                    render_fn(
                        center.x - offset + 1, center.y, -delta, 1,
                        color_a.r, color_a.g, color_a.b, color_a.a,
                        color_b.r, color_b.g, color_b.b, color_b.a,
                        true
                    )
                end

                if not ref.exclude:get 'Right' then
                    render_fn(
                        center.x + offset, center.y, delta, 1,
                        color_a.r, color_a.g, color_a.b, color_a.a,
                        color_b.r, color_b.g, color_b.b, color_b.a,
                        true
                    )
                end
            end

            local function update_event_callbacks(value)
                if not value then
                    override.unset(software.visuals.effects.remove_scope_overlay)
                end

                utils.event_callback(
                    'paint',
                    on_paint,
                    value
                )

                utils.event_callback(
                    'paint_ui',
                    on_paint_ui,
                    value
                )
            end

            local callbacks do
                local function on_enabled(item)
                    update_event_callbacks(item:get())
                end

                ref.enabled:set_callback(
                    on_enabled, true
                )
            end
        end

        local force_second_zoom do
            local ref = resource.render.changers.force_second_zoom

            local ref_override_zoom_fov = ui.reference(
                'Misc', 'Miscellaneous', 'Override zoom FOV'
            )

            local function restore_values()
                override.unset(ref_override_zoom_fov)
            end

            local function update_values()
                override.set(ref_override_zoom_fov, ref.value:get())
            end

            local function on_shutdown()
                restore_values()
            end

            local function on_paint_ui()
                restore_values()
            end

            local function on_pre_render()
                local me = entity.get_local_player()

                if me == nil then
                    return
                end

                local weapon = entity.get_player_weapon(me)

                if weapon == nil then
                    return
                end

                local zoom_level = entity.get_prop(
                    weapon, 'm_zoomLevel'
                )

                if zoom_level == 2 then
                    update_values()
                else
                    restore_values()
                end
            end

            local callbacks do
                local function on_enabled(item)
                    local value = item:get()

                    utils.event_callback(
                        'shutdown',
                        on_shutdown,
                        value
                    )

                    utils.event_callback(
                        'paint_ui',
                        on_paint_ui,
                        value
                    )

                    utils.event_callback(
                        'pre_render',
                        on_pre_render,
                        value
                    )
                end

                ref.enabled:set_callback(
                    on_enabled, true
                )
            end
        end

        local world_modulation do
            local ref = resource.render.changers.world_modulation

            local mat_ambient_light_r = cvar.mat_ambient_light_r
            local mat_ambient_light_g = cvar.mat_ambient_light_g
            local mat_ambient_light_b = cvar.mat_ambient_light_b

            local r_modelAmbientMin = cvar.r_modelAmbientMin

            local bloom_default, exposure_min_default, exposure_max_default
            local bloom_prev, exposure_prev, model_ambient_min_prev, wallcolor_prev

            local function reset_wall_color()
                mat_ambient_light_r:set_raw_float(0)
                mat_ambient_light_g:set_raw_float(0)
                mat_ambient_light_b:set_raw_float(0)
            end

            local function reset_bloom(tone_map_controller)
                if bloom_default == -1 then
                    entity.set_prop(tone_map_controller, 'm_bUseCustomBloomScale', 0)
                    entity.set_prop(tone_map_controller, 'm_flCustomBloomScale', 0)
                else
                    entity.set_prop(tone_map_controller, 'm_bUseCustomBloomScale', 1)
                    entity.set_prop(tone_map_controller, 'm_flCustomBloomScale', bloom_default)
                end
            end

            local function reset_exposure(tone_map_controller)
                if exposure_min_default == -1 then
                    entity.set_prop(tone_map_controller, 'm_bUseCustomAutoExposureMin', 0)
                    entity.set_prop(tone_map_controller, 'm_flCustomAutoExposureMin', 0)
                else
                    entity.set_prop(tone_map_controller, 'm_bUseCustomAutoExposureMin', 1)
                    entity.set_prop(tone_map_controller, 'm_flCustomAutoExposureMin', exposure_min_default)
                end

                if exposure_max_default == -1 then
                    entity.set_prop(tone_map_controller, 'm_bUseCustomAutoExposureMax', 0)
                    entity.set_prop(tone_map_controller, 'm_flCustomAutoExposureMax', 0)
                else
                    entity.set_prop(tone_map_controller, 'm_bUseCustomAutoExposureMax', 1)
                    entity.set_prop(tone_map_controller, 'm_flCustomAutoExposureMax', exposure_max_default)
                end
            end

            local function reset_model_ambient()
                r_modelAmbientMin:set_raw_float(0)
            end

            local function reset_all()
                local controllers = entity.get_all 'CEnvTonemapController'

                for i = 1, #controllers do
                    local controller = controllers[i]

                    if bloom_prev ~= -1 and bloom_default ~= nil then
                        reset_bloom(controller)
                    end

                    if exposure_prev ~= -1 and exposure_min_default ~= nil then
                        reset_exposure(controller)
                    end
                end

                reset_wall_color()
                reset_model_ambient()

                bloom_default = nil

                exposure_min_default = nil
                exposure_max_default = nil

                model_ambient_min_prev = nil
            end

            local function update_wall_color()
                local value = ref.wall_color:get()

                if not value then
                    if wallcolor_prev then
                        reset_wall_color()
                        wallcolor_prev = false
                    end

                    return
                end

                local r, g, b, a = ref.wall_color_picker:get()

                r = r / 255
                g = g / 255
                b = b / 255

                local r_res = nil
                local g_res = nil
                local b_res = nil

                local a_temp = a / 128 - 1

                if a_temp > 0 then
                    local multiplier = 900 ^ (a_temp) - 1

                    a_temp = a_temp * multiplier

                    r_res = r * a_temp
                    g_res = g * a_temp
                    b_res = b * a_temp
                else
                    r_res = (1 - r) * a_temp
                    g_res = (1 - g) * a_temp
                    b_res = (1 - b) * a_temp
                end

                if mat_ambient_light_r:get_float() ~= r_res then
                    mat_ambient_light_r:set_raw_float(r_res)
                end

                if mat_ambient_light_g:get_float() ~= g_res then
                    mat_ambient_light_g:set_raw_float(g_res)
                end

                if mat_ambient_light_b:get_float() ~= b_res then
                    mat_ambient_light_b:set_raw_float(b_res)
                end

                wallcolor_prev = true
            end

            local function update_model_ambient()
                local value = ref.model_ambient:get()

                if model_ambient_min_prev ~= value then
                    model_ambient_min_prev = value

                    if r_modelAmbientMin:get_float() ~= value * 0.01 then
                        r_modelAmbientMin:set_raw_float(value * 0.01)
                    end
                end
            end

            local function update_bloom(controllers)
                local value = ref.bloom:get()

                for i = 1, #controllers do
                    local controller = controllers[i]

                    if value == -1 then
                        reset_bloom(controller)

                        goto continue
                    end

                    if bloom_default == nil then
                        bloom_default = -1

                        if entity.get_prop(controller, 'm_bUseCustomBloomScale') == 1 then
                            bloom_default = entity.get_prop(controller, 'm_flCustomBloomScale')
                        end
                    end

                    entity.set_prop(controller, 'm_bUseCustomBloomScale', 1)
                    entity.set_prop(controller, 'm_flCustomBloomScale', value * 0.01)

                    ::continue::
                end
            end

            local function update_exposure(controllers)
                local value = ref.exposure:get()

                for i = 1, #controllers do
                    local controller = controllers[i]

                    if value == -1 then
                        reset_exposure(controller)

                        goto continue
                    end

                    if exposure_min_default == nil then
                        exposure_min_default = -1
                        exposure_max_default = -1

                        if entity.get_prop(controller, 'm_bUseCustomAutoExposureMin') == 1 then
                            exposure_min_default = entity.get_prop(controller, 'm_flCustomAutoExposureMin')
                        end

                        if entity.get_prop(controller, 'm_bUseCustomAutoExposureMax') == 1 then
                            exposure_max_default = entity.get_prop(controller, 'm_flCustomAutoExposureMax')
                        end
                    end

                    entity.set_prop(controller, 'm_bUseCustomAutoExposureMin', 1)
                    entity.set_prop(controller, 'm_bUseCustomAutoExposureMax', 1)

                    entity.set_prop(controller, 'm_flCustomAutoExposureMin', math.max(0.0000, value * 0.001))
                    entity.set_prop(controller, 'm_flCustomAutoExposureMax', math.max(0.0000, value * 0.001))

                    ::continue::
                end
            end

            local function on_shutdown()
                reset_all()
            end

            local function on_level_init()
                bloom_default = nil

                exposure_min_default = nil
                exposure_max_default = nil
            end

            local function on_pre_render()
                local controllers = entity.get_all 'CEnvTonemapController'

                update_wall_color()

                update_bloom(controllers)
                update_exposure(controllers)

                update_model_ambient()
            end

            local callbacks do
                local function on_enabled(item)
                    local value = item:get()

                    if not value then
                        reset_all()
                    end

                    utils.event_callback(
                        'shutdown',
                        on_shutdown,
                        value
                    )

                    utils.event_callback(
                        'level_init',
                        on_level_init,
                        value
                    )

                    utils.event_callback(
                        'pre_render',
                        on_pre_render,
                        value
                    )
                end

                ref.enabled:set_callback(
                    on_enabled, true
                )
            end
        end

        local light_modulation do
            local ref = resource.render.changers.light_modulation

            local prop_cache = { }

            local light_shadow_dir = vector()
            local light_shadow_angle = vector()

            local function unset_props()
                for ent, props in pairs(prop_cache) do
                    for propname, value in pairs(props) do
                        entity.set_prop(ent, propname, unpack(value))
                    end
                end
            end

            local function set_prop(ent, propname, ...)
                if prop_cache[ent] == nil then
                    prop_cache[ent] = { }
                end

                if prop_cache[ent][propname] == nil then
                    prop_cache[ent][propname] = {
                        entity.get_prop(ent, propname)
                    }
                end

                entity.set_prop(ent, propname, ...)
            end

            local function on_shutdown()
                unset_props()
            end

            local function on_pre_render()
                local controllers = entity.get_all 'CCascadeLight'

                local x = ref.offset_x:get()
                local y = ref.offset_y:get()
                local z = ref.offset_z:get()

                for i = 1, #controllers do
                    local controller = controllers[i]

                    set_prop(controller, 'm_envLightShadowDirection', x, y, z)
                end
            end

            local function on_post_render()
                unset_props()
            end

            local callbacks do
                local function on_enabled(item)
                    local value = item:get()

                    if not value then
                        unset_props()
                    end

                    utils.event_callback(
                        'shutdown',
                        on_shutdown,
                        value
                    )

                    utils.event_callback(
                        'pre_render',
                        on_pre_render,
                        value
                    )

                    utils.event_callback(
                        'post_render',
                        on_post_render,
                        value
                    )
                end

                ref.enabled:set_callback(
                    on_enabled, true
                )
            end
        end
    end

    local user_interface do
        local watermark do
            local ref = resource.render.user_interface.watermark

            local font_map = {
                ['Default'] = '',
                ['Small'] = '-',
                ['Bold'] = 'b'
            }

            local default = { } do
                local TEXT = string.lower(script.name)

                local function get_text_array(text)
                    local arr = { }
                    local size = #text

                    for i = 1, size do
                        arr[i] = text:sub(i, i)
                    end

                    return arr, size
                end

                local function get_caps_animation(text, time)
                    local arr, size = get_text_array(text)

                    local index = math.floor(time % size) + 1
                    arr[index] = string.upper(arr[index])

                    return table.concat(arr, nil, 1, size)
                end

                local function get_text()
                    local result = ref.text_input:get()

                    if result == '' then
                        result = TEXT
                    end

                    if not ref.removals:get 'Animation' then
                        result = get_caps_animation(
                            result, globals.realtime() * 5.0
                        )
                    end

                    if not ref.removals:get 'Arrows' then
                        result = '-› ' .. result .. ' ‹-'
                    end

                    return result
                end

                function default.paint_ui()
                    local screen = vector(
                        client.screen_size()
                    )

                    local position = vector(
                        screen.x * 0.5,
                        screen.y - 5
                    )

                    local flags = font_map[
                        ref.font:get()
                    ]

                    if flags == nil then
                        return
                    end

                    local text = get_text()

                    if flags:find '-' then
                        text = text:upper()
                    end

                    local color_a = color(ref.accent_color:get())
                    local color_b = color(ref.secondary_color:get())

                    text = text_anims.gradient(
                        text, globals.realtime(),
                        color_a.r, color_a.g, color_a.b, color_a.a,
                        color_b.r, color_b.g, color_b.b, color_b.a
                    )

                    local text_size = vector(
                        renderer.measure_text(flags, text)
                    )

                    position.x = position.x - text_size.x * 0.5 + 0.5
                    position.y = position.y - text_size.y

                    renderer.text(
                        position.x, position.y,
                        255, 255, 255, 255,
                        flags, nil, text
                    )
                end
            end

            local simple = { } do
                local NAME = string.upper(script.name)
                local BUILD = string.upper(script.build)

                local IMAGE_SIZE = 32

                local panorama_api = panorama.open()

                local function get_local_player_xuid()
                    local my_persona_api = panorama_api.MyPersonaAPI

                    if my_persona_api == nil then
                        return 0ULL
                    end

                    return my_persona_api.GetXuid()
                end

                local avatar = images.get_steam_avatar(
                    get_local_player_xuid(), IMAGE_SIZE
                )

                function simple.paint_ui()
                    local screen_size = vector(
                        client.screen_size()
                    )

                    local position = vector(
                        5, screen_size.y / 2
                    )

                    local flags, text = '-', '' do
                        local list = {
                            string.format('%s.LUA', NAME),
                            string.format('[%s]', BUILD)
                        }

                        text = table.concat(list, '\n')
                    end

                    local text_size = vector(
                        renderer.measure_text(flags, text)
                    )

                    if avatar ~= nil then
                        position.y = position.y - IMAGE_SIZE / 2

                        avatar:draw(
                            position.x, position.y,
                            IMAGE_SIZE, IMAGE_SIZE,
                            255, 255, 255, 255, 'f'
                        )

                        position.x = position.x + IMAGE_SIZE + 5
                        position.y = position.y + (IMAGE_SIZE - text_size.y) / 2
                    else
                        position.y = position.y - text_size.y / 2
                    end

                    renderer.text(
                        position.x, position.y,
                        255, 255, 255, 255,
                        flags, nil, text
                    )
                end
            end

            local alt = { } do
                local SCRIPT_NAME = script.name:lower()
                local SCRIPT_BUILD = script.build:lower()

                local colors = {
                    red = color(139, 31, 31, 255),
                    green = color(146, 183, 51, 255),
                    orange = color(183, 121, 51, 255)
                }

                local smoothed_fps = 0
                local smoothed_var = 0
                local smoothed_ping = 0

                local last_update_time = 0

                local function create_section(col, flags, text, shift_x, shift_y)
                    local section = { }

                    section.color = col
                    section.flags = flags
                    section.text = text

                    section.shift_x = shift_x or 0
                    section.shift_y = shift_y or 0

                    return section
                end

                local function get_fps_color(fps)
                    if fps < 60 then
                        return colors.red
                    end

                    if fps < 120 then
                        return colors.orange
                    end

                    return colors.green
                end

                local function get_var_color(var)
                    if var < 2 then
                        return colors.green
                    end

                    if var < 3 then
                        return colors.orange
                    end

                    return colors.red
                end

                local function get_ping_color(ping)
                    if ping < 40 then
                        return colors.green
                    end

                    if ping < 100 then
                        return colors.orange
                    end

                    return colors.red
                end

                local function get_kd_color(kd)
                    if kd > 2 then
                        return colors.green
                    end

                    if kd > 0 and kd < 1 then
                        return colors.red
                    end

                    return colors.orange
                end

                local function draw_shadow(x, y, w, h)
                    local center = math.floor(0.5 + w * 0.5)

                    local col_begin  = color(0, 0, 0, 0)
                    local col_finish = color(0, 0, 0, 100)

                    renderer.gradient(
                        x, y, center, h,
                        col_begin.r, col_begin.g, col_begin.b, col_begin.a,
                        col_finish.r, col_finish.g, col_finish.b, col_finish.a,
                        true
                    )

                    renderer.gradient(
                        x + center, y, center, h,
                        col_finish.r, col_finish.g, col_finish.b, col_finish.a,
                        col_begin.r, col_begin.g, col_begin.b, col_begin.a,
                        true
                    )
                end

                local function draw_outline(x, y, width, height)
                    local thickness = 1

                    local center = math.floor(0.5 + width * 0.5)

                    local col_center = color(0, 0, 0, 50)
                    local col_edge   = color(0, 0, 0, 0)

                    renderer.gradient(
                        x, y, center, thickness,
                        col_edge.r, col_edge.g, col_edge.b, col_edge.a,
                        col_center.r, col_center.g, col_center.b, col_center.a,
                        true
                    )

                    renderer.gradient(
                        x + center, y, center, thickness,
                        col_center.r, col_center.g, col_center.b, col_center.a,
                        col_edge.r, col_edge.g, col_edge.b, col_edge.a,
                        true
                    )

                    renderer.gradient(
                        x, y + height - thickness, center, thickness,
                        col_edge.r, col_edge.g, col_edge.b, col_edge.a,
                        col_center.r, col_center.g, col_center.b, col_center.a,
                        true
                    )

                    renderer.gradient(
                        x + center, y + height - thickness, center, thickness,
                        col_center.r, col_center.g, col_center.b, col_center.a,
                        col_edge.r, col_edge.g, col_edge.b, col_edge.a,
                        true
                    )
                end

                function alt.paint_ui()
                    local time = globals.realtime()

                    if time - last_update_time > 0.5 then
                        smoothed_fps  = math.floor(0.5 + 1 / globals.frametime())
                        smoothed_var  = math.floor(0.5 + globalvars.absoluteframestarttimestddev * 1000)
                        smoothed_ping = math.floor(0.5 + client.latency() * 1000)

                        last_update_time = time
                    end

                    local col_white = color(194, 194, 194, 255)
                    local col_accent = color(ref.accent_color:get())

                    local list, count = { }, 0 do
                        if ref.display:get 'Logo' then
                            table.insert(list, {
                                create_section(col_white, '', SCRIPT_NAME .. '.'),
                                create_section(col_accent, '', SCRIPT_BUILD)
                            })
                        end

                        if ref.display:get 'Username' then
                            table.insert(list, {
                                create_section(col_white, '', script.user)
                            })
                        end

                        if ref.display:get 'FPS' then
                            table.insert(list, {
                                create_section(get_fps_color(smoothed_fps), '', tostring(smoothed_fps)),
                                create_section(col_white, '-', 'FPS', 1, 2)
                            })
                        end

                        if ref.display:get 'Frametime variance' then
                            table.insert(list, {
                                create_section(get_var_color(smoothed_var), '', tostring(smoothed_var)),
                                create_section(col_white, '-', 'VAR', 1, 2)
                            })
                        end

                        if ref.display:get 'Ping' then
                            table.insert(list, {
                                create_section(get_ping_color(smoothed_ping), '', tostring(smoothed_ping)),
                                create_section(col_white, '-', 'PING', 1, 2)
                            })
                        end

                        if ref.display:get 'Speed' then
                            table.insert(list, {
                                create_section(col_white, '', math.floor(localplayer.velocity:length())),
                                create_section(col_white, '-', 'SPEED', 1, 2)
                            })
                        end

                        if ref.display:get 'K/D ratio' then
                            local kd = utils.get_player_kd(
                                entity.get_local_player()
                            )

                            if kd ~= nil then
                                table.insert(list, {
                                    create_section(get_kd_color(kd), '', string.format('%.1f', kd)),
                                    create_section(col_white, '-', 'K/D', 1, 2)
                                })
                            end
                        end

                        if ref.display:get 'Clock' then
                            table.insert(list, {
                                create_section(col_white, '', string.format(
                                    '%02d:%02d:%02d', client.system_time()
                                ))
                            })
                        end

                        count = #list
                    end

                    local measures = { }

                    local max_width = 0
                    local max_height = 0

                    for i = 1, count do
                        local data = list[i]

                        local sizes = { }

                        for j = 1, #data do
                            local section = data[j]

                            local text_size = vector(
                                renderer.measure_text(
                                    section.flags,
                                    section.text
                                )
                            )

                            max_width = max_width + text_size.x + section.shift_x
                            max_height = math.max(max_height, text_size.y)

                            sizes[j] = text_size
                        end

                        if i ~= count then
                            max_width = max_width + 12
                        end

                        measures[i] = sizes
                    end

                    local pos_variant = ref.position:get()

                    local total_width = max_width

                    local extra_margin  = 15
                    local height        = 20
                    local width         = total_width + extra_margin
                    local screen_size   = vector(client.screen_size())
                    local offset_border = 5

                    local x_pos = offset_border
                    local y_pos = offset_border

                    if pos_variant == 'Top-right' then
                        x_pos = screen_size.x - width - offset_border
                        y_pos = offset_border
                    end

                    if pos_variant == 'Bottom-center' then
                        x_pos = (screen_size.x - width) / 2
                        y_pos = screen_size.y - height - offset_border

                        if ref.select:get 'Default' then
                            y_pos = y_pos - 15
                        end
                    end

                    local gradient_offset = 10

                    local grad_left     = x_pos - gradient_offset
                    local grad_right    = x_pos + width + gradient_offset

                    local grad_width    = grad_right - grad_left

                    draw_shadow(grad_left, y_pos, grad_width, height)
                    draw_outline(grad_left, y_pos, grad_width, height)

                    local draw_x = x_pos + 5
                    local draw_y = y_pos + (height / 2)

                    local offset = 0

                    for i = 1, count do
                        local data = list[i]

                        local sizes = measures[i]

                        for j = 1, #data do
                            local section = data[j]

                            local text_size = sizes[j]
                            local text_color = section.color

                            renderer.text(
                                draw_x + offset + section.shift_x, draw_y - 6 + section.shift_y,
                                text_color.r, text_color.g, text_color.b, text_color.a,
                                section.flags, nil, section.text
                            )

                            offset = offset + text_size.x
                        end

                        offset = offset + 12
                    end
                end
            end

            local callbacks do
                local function on_select(item)
                    utils.event_callback('paint_ui', default.paint_ui, item:get 'Default')
                    utils.event_callback('paint_ui', simple.paint_ui, item:get 'Simple')
                    utils.event_callback('paint_ui', alt.paint_ui, item:get 'Alternative')
                end

                ref.select:set_callback(
                    on_select, true
                )
            end
        end

        local keybinds do
            local ref = resource.render.user_interface.keybinds

            local ROW_SIZE = 15

            local BIND_MODES = {
                [1] = 'ENABLED',
                [2] = 'HELD',
                [3] = 'TOGGLED',
                [4] = 'ENABLED'
            }

            local window = windows.new('##KEYBINDS', 0.075, 0.35) do
                config_system.push('User interface', 'keybinds.window_x', window.item_x)
                config_system.push('User interface', 'keybinds.window_y', window.item_y)
            end

            local ref_double_tap = {
                ui.reference('Rage', 'Aimbot', 'Double tap')
            }

            local ref_force_body_aim = ui.reference(
                'Rage', 'Aimbot', 'Force body aim'
            )

            local ref_force_safe_point = ui.reference(
                'Rage', 'Aimbot', 'Force safe point'
            )

            local ref_quick_peek_assist = {
                ui.reference('Rage', 'Other', 'Quick peek assist')
            }

            local ref_duck_peek_assist = ui.reference(
                'Rage', 'Other', 'Duck peek assist'
            )

            local ref_on_shot_antiaim = {
                ui.reference('AA', 'Other', 'On shot anti-aim')
            }

            local ref_minimum_damage_override = {
                ui.reference('Rage', 'Aimbot', 'Minimum damage override')
            }

            local function update_bind(list, name, item)
                local state, mode = ui.get(item)

                if not state then
                    return
                end

                table.insert(list, {
                    name, BIND_MODES[mode + 1]
                })
            end

            local function get_binds()
                local list = { }

                if ref.select:get 'Auto peek' and ui.get(ref_quick_peek_assist[1]) then
                    update_bind(list, 'AUTO PEEK', ref_quick_peek_assist[2])
                end

                if ref.select:get 'Fake duck' then
                    update_bind(list, 'FAKE DUCK', ref_duck_peek_assist)
                end

                if ref.select:get 'Double tap' and ui.get(ref_double_tap[1]) then
                    update_bind(list, 'DOUBLE TAP', ref_double_tap[2])
                end

                if ref.select:get 'Hide shots' and ui.get(ref_on_shot_antiaim[1]) then
                    update_bind(list, 'HIDE SHOTS', ref_on_shot_antiaim[2])
                end

                if ref.select:get 'Force body aim' then
                    update_bind(list, 'FORCE BODY', ref_force_body_aim)
                end

                if ref.select:get 'Force safe points' then
                    update_bind(list, 'FORCE SAFE', ref_force_safe_point)
                end

                if ref.select:get 'Damage override' and ui.get(ref_minimum_damage_override[1]) then
                    update_bind(list, 'DAMAGE OVERRIDE', ref_minimum_damage_override[2])
                end

                if ref.select:get 'Hitchance override' and (session.hitchance.updated_hotkey and session.hitchance.updated_this_tick) then
                    update_bind(list, 'HITCHANCE OVERRIDE', resource.main.ragebot.hitchance.hotkey.ref)
                end

                return list, #list
            end

            local function on_paint_ui()
                local position = window.pos:clone()

                local width = 200
                local height = 16

                local style = ref.style:get()

                local col_accent = color(
                    ref.accent_color:get()
                )

                local col_secondary = color(
                    ref.secondary_color:get()
                )

                local binds, binds_count = get_binds()

                local should_render = (
                    binds_count > 0 or
                    ui.is_menu_open()
                )

                if not should_render then
                    return
                end

                local background_render do
                    local rect_pos = vector(
                        position.x, position.y + height
                    )

                    local rect_size = vector(
                        width, ROW_SIZE * binds_count
                    )

                    renderer.rectangle(
                        rect_pos.x, rect_pos.y,
                        rect_size.x, rect_size.y,
                        0, 0, 0, 100
                    )
                end

                local header_render do
                    local flags, text = '-', 'KEYBINDS'

                    local text_size = vector(
                        renderer.measure_text(
                            flags, text
                        )
                    )

                    local text_pos = vector(
                        position.x + (width - text_size.x) / 2,
                        position.y + (height - text_size.y) / 2
                    )

                    renderer.rectangle(position.x, position.y, width, height, 0, 0, 0, 150)

                    if style == 'Fade' then
                        renderer.gradient(
                            position.x + 1, position.y + 1, width - 2, 1,
                            col_accent.r, col_accent.g, col_accent.b, col_accent.a,
                            col_secondary.r, col_secondary.g, col_secondary.b, col_secondary.a,
                            true
                        )
                    end

                    if style == 'Astolfo' then
                        renderer.gradient(
                            position.x + 1, position.y + 1, width - 2, 1,
                            250, 80, 130, 255, 25, 158, 255, 255, true
                        )
                    end

                    renderer.text(
                        text_pos.x, text_pos.y,
                        255, 255, 255, 255,
                        flags, nil, text
                    )
                end

                local binds_render do
                    local text_flags = '-'

                    local row_pos = vector(
                        position.x, position.y + height
                    )

                    for i = 1, binds_count do
                        local bind = binds[i]

                        local name = bind[1]
                        local mode = bind[2]

                        local name_size = vector(
                            renderer.measure_text(
                                text_flags, name
                            )
                        )

                        local mode_size = vector(
                            renderer.measure_text(
                                text_flags, mode
                            )
                        )

                        local name_pos = vector(
                            row_pos.x + 4,
                            row_pos.y + (ROW_SIZE - name_size.y) / 2
                        )

                        local mode_pos = vector(
                            row_pos.x + width - mode_size.x - 4 - 4,
                            row_pos.y + (ROW_SIZE - mode_size.y) / 2
                        )

                        renderer.text(
                            name_pos.x, name_pos.y,
                            255, 255, 255, 255,
                            text_flags, nil, name
                        )

                        renderer.text(
                            mode_pos.x, mode_pos.y,
                            255, 255, 255, 255,
                            text_flags, nil, mode
                        )

                        row_pos.y = row_pos.y + ROW_SIZE
                    end
                end

                height = height + (ROW_SIZE * binds_count)

                ex_render.blur(position.x, position.y, width, height)
                ex_render.rectangle_outline(position.x, position.y, width, height, 0, 0, 0, 255, 1)

                window:set_size(vector(width, height))
                window:update()
            end

            local callbacks do
                local function on_enabled(item)
                    local value = item:get()

                    utils.event_callback(
                        'paint_ui',
                        on_paint_ui,
                        value
                    )
                end

                ref.enabled:set_callback(
                    on_enabled, true
                )
            end
        end

        local flags_indicator do
            local ref = resource.render.user_interface.flags_indicator

            local ROW_SIZE = 15

            local GetClientEntity = vtable_bind('client.dll', 'VClientEntityList003', 3, 'void*(__thiscall*)(void*,int)')

            local IsWeapon = vtable_thunk(166, 'bool(__thiscall*)(void*)')
            local GetInaccuracy = vtable_thunk(483, 'float(__thiscall*)(void*)')

            local charge_value = 0.0

            local window = windows.new('##FLAGS_INDICATOR', 0.075, 0.25) do
                config_system.push('User interface', 'flag_indicator.window_x', window.item_x)
                config_system.push('User interface', 'flag_indicator.window_y', window.item_y)
            end

            local function get_inaccuracy(weapon)
                local weapon_info = csgo_weapons(weapon)

                if weapon_info == nil then
                    return 0
                end

                local addr = GetClientEntity(weapon)

                if addr == nil then
                    return 0
                end

                if not IsWeapon(addr) then
                    return 0
                end

                local inaccuracy = GetInaccuracy(addr)

                if inaccuracy < weapon_info.inaccuracy_stand then
                    return 0
                end

                return utils.clamp(inaccuracy / weapon_info.inaccuracy_move, 0, 1)
            end

            local function update_flags(player, flags)
                local weapon = entity.get_player_weapon(player)

                if ref.select:get 'Fake yaw' then
                    local value = math.abs(localplayer.body_yaw) / 60
                    value = math.max(0.0, math.min(value, 1.0))

                    table.insert(flags, {
                        'FAKE YAW', value
                    })
                end

                if ref.select:get 'Fakelag' then
                    local value = utils.clamp(globals.chokedcommands(), 0, 15) / 15

                    table.insert(flags, {
                        'FAKELAG', value
                    })
                end

                if ref.select:get 'Exploits' then
                    local is_shifting = exploit.get().shift

                    if is_shifting then
                        local dt = globals.frametime()

                        charge_value = utils.clamp(
                            charge_value + dt * 14, 0.0, 1.0
                        )
                    else
                        charge_value = 0.0
                    end

                    table.insert(flags, {
                        'EXPLOITS',
                        charge_value
                    })
                end

                if ref.select:get 'Inaccuracy' and weapon ~= nil then
                    local inaccuracy = get_inaccuracy(weapon)

                    if inaccuracy ~= nil then
                        table.insert(flags, {
                            'INACCURACY',
                            inaccuracy
                        })
                    end
                end

                if ref.select:get 'Stand height' then
                    local value = entity.get_prop(
                        player, 'm_flDuckAmount'
                    )

                    table.insert(flags, {
                        'STAND HEIGHT',
                        1 - value
                    })
                end
            end

            local function on_paint_ui()
                local me = entity.get_local_player()
                local is_alive = entity.is_alive(me)

                local position = window.pos:clone()

                local width = 200
                local height = 16

                local style = ref.style:get()

                local col_accent = color(
                    ref.accent_color:get()
                )

                local col_secondary = color(
                    ref.secondary_color:get()
                )

                local flags_count = 0

                local flags = { } do
                    if is_alive then
                        update_flags(me, flags)
                    end

                    flags_count = #flags
                end

                local should_render = (
                    flags_count > 0 or
                    ui.is_menu_open()
                )

                if not should_render then
                    return
                end

                local background_render do
                    local rect_pos = vector(
                        position.x, position.y + height
                    )

                    local rect_size = vector(
                        width, (ROW_SIZE * flags_count)
                    )

                    renderer.rectangle(
                        rect_pos.x, rect_pos.y,
                        rect_size.x, rect_size.y,
                        0, 0, 0, 100
                    )
                end

                local header_render do
                    local flags, text = '-', 'INDICATORS'

                    local text_size = vector(
                        renderer.measure_text(
                            flags, text
                        )
                    )

                    local text_pos = vector(
                        position.x + (width - text_size.x) / 2,
                        position.y + (height - text_size.y) / 2
                    )

                    renderer.rectangle(position.x, position.y, width, height, 0, 0, 0, 150)

                    if style == 'Fade' then
                        renderer.gradient(
                            position.x + 1, position.y + 1, width - 2, 1,
                            col_accent.r, col_accent.g, col_accent.b, col_accent.a,
                            col_secondary.r, col_secondary.g, col_secondary.b, col_secondary.a,
                            true
                        )
                    end

                    if style == 'Astolfo' then
                        renderer.gradient(
                            position.x + 1, position.y + 1, width - 2, 1,
                            250, 80, 130, 255, 25, 158, 255, 255, true
                        )
                    end

                    renderer.text(
                        text_pos.x, text_pos.y,
                        255, 255, 255, 255,
                        flags, nil, text
                    )
                end

                local flags_render do
                    local text_flags = '-'

                    local flag_pos = vector(
                        position.x, position.y + height
                    )

                    for i = 1, flags_count do
                        local flag = flags[i]

                        local text = flag[1]
                        local pct = flag[2]

                        local text_size = vector(
                            renderer.measure_text(
                                text_flags, text
                            )
                        )

                        local rect_size = vector(115, 6)

                        local text_pos = vector(
                            flag_pos.x + 4,
                            flag_pos.y + (ROW_SIZE - text_size.y) / 2
                        )

                        local rect_pos = vector(
                            flag_pos.x + 80,
                            flag_pos.y + (ROW_SIZE - rect_size.y) / 2
                        )

                        renderer.text(
                            text_pos.x, text_pos.y,
                            255, 255, 255, 255,
                            text_flags, nil, text
                        )

                        renderer.rectangle(
                            rect_pos.x, rect_pos.y,
                            rect_size.x, rect_size.y,
                            0, 0, 0, 75
                        )

                        if style == 'Fade' then
                            renderer.gradient(
                                rect_pos.x, rect_pos.y,
                                rect_size.x * pct, rect_size.y,
                                col_secondary.r, col_secondary.g, col_secondary.b, col_secondary.a,
                                col_accent.r, col_accent.g, col_accent.b, col_accent.a, true
                            )
                        end

                        if style == 'Astolfo' then
                            renderer.gradient(
                                rect_pos.x, rect_pos.y,
                                rect_size.x * pct, rect_size.y,
                                250, 80, 130, 255, 25, 158, 255, 255, true
                            )
                        end

                        flag_pos.y = flag_pos.y + ROW_SIZE
                    end
                end

                height = height + (ROW_SIZE * flags_count)

                ex_render.blur(position.x, position.y, width, height)
                ex_render.rectangle_outline(position.x, position.y, width, height, 0, 0, 0, 255, 1)

                window:set_size(vector(width, height))
                window:update()
            end

            local callbacks do
                local function on_enabled(item)
                    local value = item:get()

                    utils.event_callback(
                        'paint_ui',
                        on_paint_ui,
                        value
                    )
                end

                ref.enabled:set_callback(
                    on_enabled, true
                )
            end
        end

        local indicators do
            local ref = resource.render.user_interface.indicators

            local on_paint_ui do
                local TITLE_NAME = string.format(
                    '%s.%s',
                    script.name:upper(),
                    script.build:upper()
                )

                local stars = {
                    { '-', '✨', 0, 0, 0.1 },
                    { '-', '✨', -3, 5, 1.3 },
                    { '+', '⋆', -9, -16, 0.4 },
                    { '-', '✨', -1, -1, 0.2 },
                    { '+', '⋆', -3, -10, 1.5 },
                    { '+', '⋆', -6, -15, 0.7 },
                }

                local alpha_value = 0.0
                local align_value = 0.0

                local baim_value = 0.0
                local hc_value = 0.0

                local dt_value = 0.0
                local osaa_value = 0.0

                local charge_value = 0.0

                local function is_grenade(weapon)
                    local weapon_info = csgo_weapons(weapon)

                    if weapon_info == nil then
                        return false
                    end

                    return weapon_info.type == 'grenade'
                end

                local function get_state()
                    local manual_yaw = antiaim.manual_yaw:get()

                    if manual_yaw ~= nil then
                        local str = manual_yaw:upper()

                        return string.format(
                            'MANUAL %s', str
                        )
                    end

                    if software.is_freestanding() then
                        return 'FREESTAND'
                    end

                    if not localplayer.is_onground then
                        if localplayer.is_crouched then
                            return 'AIR-CROUCH'
                        end

                        return 'AIR'
                    end

                    if localplayer.is_crouched then
                        if localplayer.is_moving then
                            return 'CROUCH-MOVE'
                        end

                        return 'CROUCH'
                    end

                    if localplayer.is_moving then
                        if software.is_slow_motion() then
                            return 'SLOWING'
                        end

                        return 'MOVING'
                    end

                    return 'STANDING'
                end

                local function draw_stars(position, r1, g1, b1, a1, r2, g2, b2, a2)
                    local time = -globals.realtime()
                    local x, y = position.x + 4, position.y

                    local sizes, len = { }, #stars
                    local width, height = 0, 0

                    for i = 1, len do
                        local data = stars[i]

                        local measure = vector(
                            renderer.measure_text(data[1], data[2])
                        )

                        width = width + (measure.x + data[3])
                        height = math.max(height, measure.y + data[4])

                        sizes[i] = measure
                    end

                    x = round(x - (width * 0.5) * (1 - align_value))

                    local pct = 0.0
                    local div = 1 / (len - 1)

                    local style = ref.style:get()

                    for i = 1, len do
                        local star = stars[i]
                        local size = sizes[i]

                        local flags = star[1]
                        local text = star[2]

                        local offset_x = star[3]
                        local offset_y = star[4]

                        local phase = star[5]

                        local phase_value = math.sin(time * phase) do
                            phase_value = phase_value * 0.5 + 0.5
                            phase_value = phase_value * 0.5 + 0.3
                        end

                        if style == 'Default' then
                            text = text_anims.gradient(
                                text, (time + pct) * 1.25,
                                r1, g1, b1, a1,
                                r2, g2, b2, a2
                            )
                        end

                        if style == 'Astolfo' then
                            text = text_anims.astolfo(
                                text, (time + pct) * 0.5,
                                0.5, 0.4, 1.0, 0.5
                            )
                        end

                        renderer.text(
                            x + offset_x, y + offset_y,
                            200, 200, 200, a1 * phase_value,
                            flags, nil, text
                        )

                        x = x + size.x + offset_x

                        pct = pct + div
                    end

                    position.y = position.y + height * 0.5
                end

                local function draw_state(position, r, g, b, a, alpha)
                    local text, flags = get_state(), '-'

                    local measure = vector(
                        renderer.measure_text(flags, text)
                    )

                    local x, y = position.x, position.y do
                        x = round(x - (measure.x * 0.5) * (1 - align_value))
                    end

                    renderer.text(x, y, r, g, b, a * alpha, flags, nil, text)

                    position.y = position.y + round(measure.y)
                end

                local function draw_title(position, r1, g1, b1, a1, r2, g2, b2, a2)
                    local text, flags = TITLE_NAME, '-'

                    local measure = vector(
                        renderer.measure_text(flags, text)
                    )

                    local time = -globals.realtime()
                    local style = ref.style:get()

                    if style == 'Default' then
                        text = text_anims.gradient(
                            text, time * 1.25,
                            r1, g1, b1, a1,
                            r2, g2, b2, a2
                        )
                    end

                    if style == 'Astolfo' then
                        text = text_anims.astolfo(
                            text, time * 0.5,
                            0.5, 0.4, 1.0, 0.5
                        )
                    end

                    local x, y = position.x, position.y do
                        x = round(x - (measure.x * 0.5) * (1 - align_value))
                    end

                    renderer.text(x, y, r1, g1, b1, a1, flags, nil, text)

                    position.y = position.y + measure.y
                end

                local function draw_double_tap(position, r, g, b, a, value, alpha)
                    local text, flags = 'DT', '-'

                    local measure = vector(
                        renderer.measure_text(flags, text)
                    )

                    local x, y = position.x, position.y do
                        x = round(x - (measure.x * 0.5) * (1 - align_value))
                    end

                    r = utils.lerp(255, r, charge_value)
                    g = utils.lerp(0, g, charge_value)
                    b = utils.lerp(50, b, charge_value)

                    a = a * value * alpha

                    renderer.text(x, y, r, g, b, a, flags, nil, text)

                    position.y = position.y + round(measure.y * value)
                end

                local function draw_onshot_antiaim(position, r, g, b, a, value, alpha)
                    local text, flags = 'OSAA', '-'

                    local measure = vector(
                        renderer.measure_text(flags, text)
                    )

                    local x, y = position.x, position.y do
                        x = round(x - (measure.x * 0.5) * (1 - align_value))
                    end

                    a = a * value * alpha

                    renderer.text(x, y, r, g, b, a, flags, nil, text)

                    position.y = position.y + round(measure.y * value)
                end

                local function draw_body_aim(position, r, g, b, a, value, alpha)
                    local text, flags = 'BODY', '-'

                    local measure = vector(
                        renderer.measure_text(flags, text)
                    )

                    local x, y = position.x, position.y do
                        x = round(x - (measure.x * 0.5) * (1 - align_value))
                    end

                    a = a * value * alpha

                    renderer.text(x, y, r, g, b, a, flags, nil, text)

                    position.y = position.y + round(measure.y * value)
                end

                local function draw_hitchance(position, r, g, b, a, value, alpha)
                    local text, flags = 'HC', '-'

                    local measure = vector(
                        renderer.measure_text(flags, text)
                    )

                    local x, y = position.x, position.y do
                        x = round(x - (measure.x * 0.5) * (1 - align_value))
                    end

                    a = a * value * alpha

                    renderer.text(x, y, r, g, b, a, flags, nil, text)

                    position.y = position.y + round(measure.y * value)
                end

                local function update_values(me)
                    local is_alive = entity.is_alive(me)
                    local is_scoped = entity.get_prop(me, 'm_bIsScoped') == 1

                    local is_shifting = exploit.get().shift

                    local is_double_tap = software.is_double_tap_active()
                    local is_onshot_aa = software.is_on_shot_antiaim_active()

                    local is_hitchance_override = (
                        session.hitchance.updated_hotkey and
                        session.hitchance.updated_this_tick
                    )

                    local is_force_baim_override = ui.get(
                        software.ragebot.aimbot.force_body_aim
                    )

                    local alpha_target = 0.0

                    if is_alive then
                        alpha_target = 1.0

                        local weapon = entity.get_player_weapon(me)

                        if is_scoped or (weapon ~= nil and is_grenade(weapon)) then
                            alpha_target = 0.5
                        end
                    end

                    alpha_value = motion.interp(alpha_value, alpha_target, 0.05)
                    align_value = motion.interp(align_value, is_scoped, 0.05)

                    baim_value = motion.interp(baim_value, is_force_baim_override, 0.05)
                    hc_value = motion.interp(hc_value, is_hitchance_override, 0.05)

                    dt_value = motion.interp(dt_value, is_double_tap, 0.05)
                    osaa_value = motion.interp(osaa_value, is_onshot_aa, 0.05)

                    charge_value = motion.interp(charge_value, is_shifting, 0.05)
                end

                local function draw_indicators()
                    local screen = vector(
                        client.screen_size()
                    )

                    local position = screen * 0.5

                    local r1, g1, b1, a1 = ref.accent_color:get()
                    local r2, g2, b2, a2 = ref.secondary_color:get()

                    position.x = position.x - 1

                    position.x = position.x + math.floor(0.5 + 10 * align_value)
                    position.y = position.y + ref.offset:get()

                    a1 = a1 * alpha_value
                    a2 = a2 * alpha_value

                    if ref.select:get 'Stars' then
                        draw_stars(position, r1, g1, b1, a1, r2, g2, b2, a2)
                    end

                    draw_title(position, r1, g1, b1, a1, r2, g2, b2, a2)

                    if ref.select:get 'State' then
                        draw_state(position, 250, 250, 250, 125, alpha_value)
                    end

                    if ref.select:get 'Double tap' then
                        draw_double_tap(position, 250, 250, 250, 175, dt_value, alpha_value)
                    end

                    if ref.select:get 'Hide shots' then
                        draw_onshot_antiaim(position, 250, 250, 250, 175, osaa_value, alpha_value)
                    end

                    if ref.select:get 'Body aim' then
                        draw_body_aim(position, 250, 250, 250, 175, baim_value, alpha_value)
                    end

                    if ref.select:get 'Hitchance' then
                        draw_hitchance(position, 250, 250, 250, 175, hc_value, alpha_value)
                    end
                end

                function on_paint_ui()
                    local me = entity.get_local_player()

                    if me == nil then
                        return
                    end

                    update_values(me)

                    if alpha_value > 0 then
                        draw_indicators()
                    end
                end
            end

            local callbacks do
                local function on_enabled(item)
                    local value = item:get()

                    utils.event_callback(
                        'paint_ui',
                        on_paint_ui,
                        value
                    )
                end

                ref.enabled:set_callback(
                    on_enabled, true
                )
            end
        end

        local manual_arrows do
            local ref = resource.antiaim.hotkeys.manual_yaw

            local COLOR_DISABLED = color(0, 0, 0, 127)

            local function on_draw_classic()
                local me = entity.get_local_player()

                if me == nil or not entity.is_alive(me) then
                    return
                end

                local screen_size = vector(
                    client.screen_size()
                )

                local center = screen_size * 0.5

                local col = color(ref.arrows_color:get())
                local manual = antiaim.manual_yaw:get()

                local padding = ref.arrows_offset:get()

                if manual == 'left' then
                    local text = ''

                    local text_size = vector(
                        renderer.measure_text('+', text)
                    )

                    local text_pos = vector(
                        center.x - text_size.x - padding + 1,
                        center.y - text_size.y * 0.5 - 4.5
                    )

                    renderer.text(text_pos.x, text_pos.y, col.r, col.g, col.b, col.a, '+', nil, text)
                end

                if manual == 'right' then
                    local text = ''

                    local text_size = vector(
                        renderer.measure_text('+', text)
                    )

                    local text_pos = vector(
                        center.x + padding,
                        center.y - text_size.y * 0.5 - 4.5
                    )

                    renderer.text(text_pos.x, text_pos.y, col.r, col.g, col.b, col.a, '+', nil, text)
                end
            end

            local function on_draw_modern()
                local me = entity.get_local_player()

                if me == nil or not entity.is_alive(me) then
                    return
                end

                local screen_size = vector(
                    client.screen_size()
                )

                local center = screen_size * 0.5

                local col = color(ref.arrows_color:get())
                local manual = antiaim.manual_yaw:get()

                local padding = ref.arrows_offset:get()

                if manual == 'left' then
                    local text = '⮜'

                    local text_size = vector(
                        renderer.measure_text('+', text)
                    )

                    local text_pos = vector(
                        center.x - text_size.x - padding + 1,
                        center.y - text_size.y * 0.5 - 1
                    )

                    renderer.text(text_pos.x, text_pos.y, col.r, col.g, col.b, col.a, '+', nil, text)
                end

                if manual == 'right' then
                    local text = '⮞'

                    local text_size = vector(
                        renderer.measure_text('+', text)
                    )

                    local text_pos = vector(
                        center.x + padding,
                        center.y - text_size.y * 0.5 - 1
                    )

                    renderer.text(text_pos.x, text_pos.y, col.r, col.g, col.b, col.a, '+', nil, text)
                end
            end

            local function on_draw_teamskeet()
                local me = entity.get_local_player()

                if me == nil or not entity.is_alive(me) then
                    return
                end

                local screen_size = vector(
                    client.screen_size()
                )

                local center = screen_size * 0.5

                local width = 2
                local height = 18

                local gap = 2

                local peak = math.floor(height * 0.75)
                local padding = ref.arrows_offset:get()

                local manual = antiaim.manual_yaw:get()
                local body_yaw = antiaim.buffer.body_yaw_offset or 0

                local is_left_desync = body_yaw < 0
                local is_right_desync = body_yaw > 0

                local color_arrows = color(ref.arrows_color:get())
                local color_desync = color(ref.desync_color:get())

                -- left
                do
                    local position = center - vector(padding, 0)

                    local rect_size = vector(width, height)
                    local rect_pos = position - vector(rect_size.x, rect_size.y * 0.5)

                    local rect_color = is_left_desync and color_desync or COLOR_DISABLED
                    local poly_color = manual == 'left' and color_arrows or COLOR_DISABLED

                    renderer.rectangle(rect_pos.x, rect_pos.y, rect_size.x, rect_size.y, rect_color:unpack())
                    position.x = position.x - (rect_size.x + gap)

                    local point_0 = vector(position.x, position.y - height * 0.5)
                    local point_1 = vector(position.x, position.y + height * 0.5)
                    local point_2 = vector(position.x - peak, position.y)

                    renderer.triangle(
                        point_0.x, point_0.y,
                        point_1.x, point_1.y,
                        point_2.x, point_2.y,
                        poly_color:unpack()
                    )
                end

                do
                    local position = center + vector(padding + 1, 0)

                    local rect_size = vector(width, height)
                    local rect_pos = position - vector(0, rect_size.y * 0.5)

                    local rect_color = is_right_desync and color_desync or COLOR_DISABLED
                    local poly_color = manual == 'right' and color_arrows or COLOR_DISABLED

                    renderer.rectangle(rect_pos.x, rect_pos.y, rect_size.x, rect_size.y, rect_color:unpack())
                    position.x = position.x + (rect_size.x + gap)

                    local point_0 = vector(position.x, position.y - height * 0.5)
                    local point_1 = vector(position.x, position.y + height * 0.5)
                    local point_2 = vector(position.x + peak, position.y)

                    renderer.triangle(
                        point_0.x, point_0.y,
                        point_1.x, point_1.y,
                        point_2.x, point_2.y,
                        poly_color:unpack()
                    )
                end
            end

            local function update_event_callbacks(value)
                utils.event_callback(
                    'paint_ui',
                    on_draw_classic,
                    value == 'Classic'
                )

                utils.event_callback(
                    'paint_ui',
                    on_draw_modern,
                    value == 'Modern'
                )

                utils.event_callback(
                    'paint_ui',
                    on_draw_teamskeet,
                    value == 'Teamskeet'
                )
            end

            local callbacks do
                local function on_manual_arrows(item)
                    update_event_callbacks(item:get())
                end

                local function on_enabled(item)
                    local value = item:get()

                    if not value then
                        update_event_callbacks(nil)
                    end

                    if value then
                        ref.manual_arrows:set_callback(on_manual_arrows, true)
                    else
                        ref.manual_arrows:unset_callback(on_manual_arrows)
                    end
                end

                ref.enabled:set_callback(
                    on_enabled, true
                )
            end
        end

        local net_graphic do
            local ref = resource.render.user_interface.net_graphic

            local FRAMERATE_AVG_FRAC = 0.9

            local netchannel_t = ffi.typeof [[
                struct {
                    char        pad_0000[24];                    //0x0000
                    int         m_nOutSequenceNr;                //0x0018
                    int         m_nInSequenceNr;                 //0x001C
                    int         m_nOutSequenceNrAck;             //0x0020
                    int         m_nOutReliableState;             //0x0024
                    int         m_nInReliableState;              //0x0028
                    int         m_nChokedPackets;                //0x002C
                    char        pad_0030[108];                   //0x0030
                    int         m_Socket;                        //0x009C
                    int         m_StreamSocket;                  //0x00A0
                    int         m_MaxReliablePayloadSize;        //0x00A4
                    char        pad_00A8[100];                   //0x00A8
                    float       last_received;                   //0x010C
                    float       connect_time;                    //0x0110
                    char        pad_0114[4];                     //0x0114
                    int         m_Rate;                          //0x0118
                    char        pad_011C[4];                     //0x011C
                    float       m_fClearTime;                    //0x0120
                    char        pad_0124[16688];                 //0x0124
                    char        m_Name[32];                      //0x4254
                    size_t      m_ChallengeNr;                   //0x4274
                    float       m_flTimeout;                     //0x4278
                    char        pad_427C[32];                    //0x427C
                    float       m_flInterpolationAmount;         //0x429C
                    float       m_flRemoteFrameTime;             //0x42A0
                    float       m_flRemoteFrameTimeStdDeviation; //0x42A4
                    int         m_nMaxRoutablePayloadSize;       //0x42A8
                    int         m_nSplitPacketSequence;          //0x42AC
                    char        pad_42B0[40];                    //0x42B0
                    bool        m_bIsValveDS;                    //0x42D8
                    char        pad_42D9[65];                    //0x42D9
                }
            ]]

            local GetNetChannelInfo = vtable_bind(
                'engine.dll', 'VEngineClient014', 78, '$*(__thiscall*)(void*)', netchannel_t
            )

            local GetAvgLatency = vtable_thunk(10, 'float(__thiscall*)(void*, int flow)')
            local GetAvgLoss = vtable_thunk(11, 'float(__thiscall*)(void*, int flow)')
            local GetAvgChoke = vtable_thunk(12, 'float(__thiscall*)(void*, int flow)')
            local GetRemoteFramerate = vtable_thunk(25, 'void(__thiscall*)(void*, float *pflFrameTime, float *pflFrameTimeStdDeviation, float *pflFrameStartTimeStdDeviation)')

            local cl_updaterate = cvar.cl_updaterate
            local net_graphholdsvframerate = cvar.net_graphholdsvframerate

            local framerate = 0.0
            local avg_latency = 0.0

            local avg_packet_loss = 0.0
            local avg_packet_choke = 0.0

            local m_flServerFrameComputationTime = ffi.new 'float[1]'
            local m_flServerFramerateStdDeviation = ffi.new 'float[1]'
            local m_flServerFrameStartTimeStdDeviation = ffi.new 'float[1]'

            local font_flags = {
                ['Default'] = '',
                ['Small'] = '-',
                ['Bold'] = 'b'
            }

            local function update_framerate_data()
                framerate = FRAMERATE_AVG_FRAC * framerate + ( 1.0 - FRAMERATE_AVG_FRAC ) * globals.absoluteframetime()

                if framerate <= 0.0 then
                    framerate = 1.0
                end
            end

            local function update_networking_data(nci)
                if nci == nil then
                    return
                end

                GetRemoteFramerate(nci, m_flServerFrameComputationTime, m_flServerFramerateStdDeviation, m_flServerFrameStartTimeStdDeviation)

                avg_latency = GetAvgLatency(nci, 0)

                avg_packet_loss = GetAvgLoss(nci, 1)
                avg_packet_choke = GetAvgChoke(nci, 1)

                if cl_updaterate:get_float() > 0.001 then
                    avg_latency = avg_latency - (0.5 / cl_updaterate:get_float())
                end

                avg_latency = math.max(0.0, avg_latency)
            end

            local function render_net_graphic(nci)
                local offset = ref.offset:get() * 0.01

                local text_font = ref.font:get()
                local text_col = color(ref.color:get())

                local screen = vector(
                    client.screen_size()
                )

                local position = vector(
                    0, screen.y - 59
                )

                -- average net graphic width is 200
                position.x = utils.lerp(60, screen.x - 200 - 60, offset)

                local flags = font_flags[text_font]

                if flags == nil then
                    return
                end

                local list = { } do
                    if ref.display:get 'Framerate' then
                        table.insert(list, string.format(
                            'fps: %5i  var: %4.1f ms  ping: %i ms',
                            1 / framerate,
                            globalvars.absoluteframestarttimestddev * 1000,
                            avg_latency * 1000
                        ))
                    end

                    if nci ~= nil then
                        if ref.display:get 'Connection' then
                            table.insert(list, string.format(
                                'loss: %3i%%  choke: %2i%%',
                                avg_packet_loss * 100,
                                avg_packet_choke * 100
                            ))
                        end

                        if ref.display:get 'Server response' then
                            table.insert(list, string.format(
                                'sv:%5.1f %s%4.1f ms   var: %6.3f ms',
                                m_flServerFrameComputationTime[0] * 1000,
                                net_graphholdsvframerate:get_int() == 1 and '~/' or '+-',
                                m_flServerFramerateStdDeviation[0] * 1000,
                                m_flServerFrameStartTimeStdDeviation[0] * 1000
                            ))
                        end
                    end
                end

                local text = table.concat(list, '\n')

                if flags:find '-' then
                    text = text:upper()
                end

                local text_size = vector(
                    renderer.measure_text(flags, text)
                )

                local text_pos = position - vector(
                    0, text_size.y
                )

                renderer.text(
                    text_pos.x, text_pos.y,
                    text_col.r, text_col.g, text_col.b, text_col.a,
                    flags, nil, text
                )
            end

            local function on_paint()
                local nci = GetNetChannelInfo()

                update_framerate_data()
                update_networking_data(nci)

                render_net_graphic(nci)
            end

            local function update_event_callbacks(value)
                utils.event_callback(
                    'paint',
                    on_paint,
                    value
                )
            end

            local callbacks do
                local function on_enabled(item)
                    update_event_callbacks(item:get())
                end

                ref.enabled:set_callback(
                    on_enabled, true
                )
            end
        end

        local console_color do
            local ref = resource.render.user_interface.console_color

            local ConsoleIsVisible = vtable_bind(
                'engine.dll', 'VEngineClient014', 11, 'bool(__thiscall*)(void*)'
            )

            local materials do
                materials = { }

                local list = {
                    'vgui_white',
                    'vgui/hud/800corner1',
                    'vgui/hud/800corner2',
                    'vgui/hud/800corner3',
                    'vgui/hud/800corner4'
                }

                for i = 1, #list do
                    materials[i] = materialsystem.find_material(list[i])
                end
            end

            local function update(r, g, b, a)
                for i = 1, #materials do
                    local material = materials[i]

                    material:alpha_modulate(a)
                    material:color_modulate(r, g, b)
                end
            end

            local function on_shutdown()
                update(255, 255, 255, 255)
            end

            local function on_pre_render()
                if not ConsoleIsVisible() then
                    update(255, 255, 255, 255)
                else
                    update(ref.color:get())
                end
            end

            local function update_event_callbacks(value)
                if not value then
                    update(255, 255, 255, 255)
                end

                utils.event_callback(
                    'shutdown',
                    on_shutdown,
                    value
                )

                utils.event_callback(
                    'paint_ui',
                    on_pre_render,
                    value
                )
            end

            local callbacks do
                local function on_enabled(item)
                    update_event_callbacks(item:get())
                end

                ref.enabled:set_callback(
                    on_enabled, true
                )
            end
        end

        local damage_indicator do
            local ref = resource.render.user_interface.damage_indicator

            local ref_minimum_damage = ui.reference(
                'Rage', 'Aimbot', 'Minimum damage'
            )

            local ref_override_damage = {
                ui.reference('Rage', 'Aimbot', 'Minimum damage override')
            }

            local font_flags = {
                ['Default'] = '',
                ['Small'] = '-',
                ['Bold'] = 'b'
            }

            local function is_minimum_damage_override()
                return ui.get(ref_override_damage[1])
                    and ui.get(ref_override_damage[2])
            end

            local function get_flags()
                return font_flags[ref.font:get()] or ''
            end

            local function get_aimbot_damage(override)
                if override then
                    return ui.get(ref_override_damage[3])
                end

                return ui.get(ref_minimum_damage)
            end

            local function get_render_damage(override)
                if not override and session.force_lethal.updated_this_tick then
                    return 'FL'
                end

                local damage = get_aimbot_damage(override)

                if damage == 0 then
                    return 'AUTO'
                end

                if damage > 100 then
                    return string.format(
                        '+%d', damage - 100
                    )
                end

                return tostring(damage)
            end

            local function on_paint_ui()
                local me = entity.get_local_player()

                if me == nil or not entity.is_alive(me) then
                    return
                end

                local screen_size = vector(
                    client.screen_size()
                )

                local position = screen_size * 0.5
                local offset = ref.offset:get()

                position.x = position.x + offset
                position.y = position.y - offset

                local r, g, b, a = ref.inactive_color:get()

                local is_override = is_minimum_damage_override()
                local flags, text = get_flags(), get_render_damage(is_override)

                if ref.only_if_active:get() and not is_override then
                    return
                end

                if is_override then
                    r, g, b, a = ref.active_color:get()
                end

                if a <= 0 then
                    return
                end

                local text_size = vector(
                    renderer.measure_text(flags, text)
                )

                position.y = position.y - text_size.y

                renderer.text(
                    position.x,
                    position.y,
                    r, g, b, a,
                    flags, nil, text
                )
            end

            local function update_event_callbacks(value)
                utils.event_callback(
                    'paint_ui',
                    on_paint_ui,
                    value
                )
            end

            local callbacks do
                local function on_enabled(item)
                    update_event_callbacks(item:get())
                end

                ref.enabled:set_callback(
                    on_enabled, true
                )
            end
        end
    end

    local hit_markers do
        local damage_marker do
            local ref = resource.render.hit_markers.damage_marker

            local STATE_BODY = 0
            local STATE_HEAD = 1
            local STATE_MISMATCH = 2

            local list = { }
            local damages = { }

            local font_map = {
                ['Default'] = '',
                ['Bold'] = 'b'
            }

            local function get_id(id)
                return (id % 15) + 1
            end

            local function reset_data()
                for i = 1, #list do
                    list[i] = nil
                end
            end

            local function get_color(state)
                if state == STATE_BODY then
                    return color(ref.body_color:get())
                end

                if state == STATE_HEAD then
                    return color(ref.head_color:get())
                end

                if state == STATE_MISMATCH then
                    return color(ref.mismatch_color:get())
                end

                return color(255, 255, 255, 255)
            end

            local function on_aim_fire(e)
                damages[get_id(e.id)] = e.damage
            end

            local function on_aim_hit(e)
                local data = list[#list]

                if data == nil then
                    return
                end

                local aim_damage = damages[get_id(e.id)]

                if aim_damage == nil then
                    return
                end

                if data.damage < aim_damage then
                    data.state = STATE_MISMATCH
                end
            end

            local function on_player_hurt(e)
                local me = entity.get_local_player()

                local userid = client.userid_to_entindex(e.userid)
                local attacker = client.userid_to_entindex(e.attacker)

                if userid == me or attacker ~= me then
                    return
                end

                local pos = vector(utils.get_eye_position(userid))

                local state = e.hitgroup == 1
                    and STATE_HEAD or STATE_BODY

                local duration = ref.duration:get()

                local damage = e.dmg_health
                local remaining = globals.realtime() + duration

                table.insert(list, {
                    pos = pos,
                    state = state,
                    damage = damage,
                    remaining = remaining
                })
            end

            local function on_paint()
                local dt = globals.frametime()
                local time = globals.realtime()

                local font = ref.font:get()
                local speed = ref.speed:get()

                local flags = font_map[font]

                if flags == nil then
                    flags = ''
                end

                flags = flags .. 'c'

                for i = #list, 1, -1 do
                    local data = list[i]

                    if time > data.remaining then
                        table.remove(list, i)
                        goto continue
                    end

                    data.pos.z = data.pos.z + speed * dt
                    ::continue::
                end

                for i = 1, #list do
                    local data = list[i]

                    local alpha = 1.0

                    local text = data.damage
                    local state = data.state

                    local col = get_color(state)

                    local liferemaining = data.remaining - time

                    if liferemaining < 0.7 then
                        alpha = liferemaining / 0.7
                    end

                    local x, y = renderer.world_to_screen(data.pos:unpack())

                    if x == nil or y == nil then
                        goto continue
                    end

                    col = col:clone()
                    col.a = col.a * alpha

                    renderer.text(x, y, col.r, col.g, col.b, col.a, flags, nil, text)
                    ::continue::
                end
            end

            local function update_event_callbacks(value)
                if not value then
                    reset_data()
                end

                utils.event_callback(
                    'aim_fire',
                    on_aim_fire,
                    value
                )

                utils.event_callback(
                    'aim_hit',
                    on_aim_hit,
                    value
                )

                utils.event_callback(
                    'player_hurt',
                    on_player_hurt,
                    value
                )

                utils.event_callback(
                    'paint',
                    on_paint,
                    value
                )
            end

            local callbacks do
                local function on_enabled(item)
                    update_event_callbacks(item:get())
                end

                ref.enabled:set_callback(
                    on_enabled, true
                )
            end
        end

        local screen_marker do
            local ref = resource.render.hit_markers.screen_marker

            local hurt_time = 0.0

            local function reset_data()
                hurt_time = 0.0
            end

            local function on_player_hurt(e)
                local me = entity.get_local_player()

                local userid = client.userid_to_entindex(e.userid)
                local attacker = client.userid_to_entindex(e.attacker)

                if userid == me or attacker ~= me then
                    return
                end

                hurt_time = 0.5
            end

            local function on_paint()
                local alpha = 1.0

                if hurt_time < 0.25 then
                    alpha = hurt_time / 0.25
                end

                local center = 0.5 * vector(
                    client.screen_size()
                )

                local col = color(ref.color:get())

                col.a = col.a * alpha

                renderer.line(center.x - 10, center.y - 10, center.x - 5, center.y - 5, col:unpack())
                renderer.line(center.x + 10, center.y - 10, center.x + 5, center.y - 5, col:unpack())
                renderer.line(center.x + 10, center.y + 10, center.x + 5, center.y + 5, col:unpack())
                renderer.line(center.x - 10, center.y + 10, center.x - 5, center.y + 5, col:unpack())

                hurt_time = math.max(hurt_time - globals.frametime(), 0.0)
            end

            local function update_event_callbacks(value)
                if not value then
                    reset_data()
                end

                utils.event_callback(
                    'player_hurt',
                    on_player_hurt,
                    value
                )

                utils.event_callback(
                    'paint',
                    on_paint,
                    value
                )
            end

            local callbacks do
                local function on_enabled(item)
                    update_event_callbacks(item:get())
                end

                ref.enabled:set_callback(
                    on_enabled, true
                )
            end
        end

        local world_marker do
            local ref = resource.render.hit_markers.world_marker

            local list = { }
            local coords = { }

            local function get_id(id)
                return (id % 15) + 1
            end

            local function clear_list()
                for i = 1, #list do
                    list[i] = nil
                end
            end

            local function on_aim_fire(e)
                coords[get_id(e.id)] = vector(e.x, e.y, e.z)
            end

            local function on_aim_hit(e)
                local time = globals.realtime() + 3.0
                local point = coords[get_id(e.id)]

                if point == nil then
                    return
                end

                table.insert(list, {
                    time = time,
                    point = point
                })
            end

            local function on_paint()
                local time = globals.realtime()

                for i = #list, 1, -1 do
                    local data = list[i]

                    if time > data.time then
                        table.remove(list, i)
                    end
                end

                for i = 1, #list do
                    local data = list[i]

                    local alpha = 1.0

                    local liferemaining = data.time - time

                    if liferemaining < 0.7 then
                        alpha = liferemaining / 0.7
                    end

                    local x, y = renderer.world_to_screen(
                        data.point:unpack()
                    )

                    if x == nil or y == nil then
                        goto continue
                    end

                    local thickness = ref.thickness:get() * 0.5
                    local size = ref.size:get() + thickness

                    local color_h = color(ref.horizontal_color:get())
                    local color_v = color(ref.vertical_color:get())

                    color_h.a = color_h.a * alpha
                    color_v.a = color_v.a * alpha

                    renderer.rectangle(x - size, y - thickness, size * 2, thickness * 2, color_h:unpack())
                    renderer.rectangle(x - thickness, y - size, thickness * 2, size * 2, color_v:unpack())

                    ::continue::
                end
            end

            local function update_event_callbacks(value)
                if not value then
                    clear_list()
                end

                utils.event_callback(
                    'aim_fire',
                    on_aim_fire,
                    value
                )

                utils.event_callback(
                    'aim_hit',
                    on_aim_hit,
                    value
                )

                utils.event_callback(
                    'paint',
                    on_paint,
                    value
                )
            end

            local callbacks do
                local function on_enabled(item)
                    update_event_callbacks(item:get())
                end

                ref.enabled:set_callback(
                    on_enabled, true
                )
            end
        end

        local hitsound do
            local ref = resource.render.hit_markers.hitsound

            local playvol = cvar.playvol

            local sounds = {
                ['Arena switch'] = 'buttons\\arena_switch_press_02.wav',
                ['Wood stop'] = 'doors\\wood_stop1.wav',
                ['Wood plank'] = 'physics\\wood\\wood_plank_impact_hard4.wav',
                ['Wood strain'] = 'physics\\wood\\wood_strain7.wav'
            }

            local ref_hit_marker_sound = ui.reference(
                'Visuals', 'Player ESP', 'Hit marker sound'
            )

            local function get_sound(is_headshot)
                local value = is_headshot
                    and ref.head_sound:get()
                    or ref.body_sound:get()

                if value == 'Off' then
                    return nil
                end

                return sounds[value]
                    or value .. '.wav'
            end

            local function on_shutdown()
                override.unset(ref_hit_marker_sound)
            end

            local function on_player_hurt(e)
                local me = entity.get_local_player()

                local userid = client.userid_to_entindex(e.userid)
                local attacker = client.userid_to_entindex(e.attacker)

                if me == userid or me ~= attacker then
                    return
                end

                local sound = get_sound(e.hitgroup == 1)

                if sound == nil then
                    return
                end

                playvol:invoke_callback(sound, ref.volume:get() / 100)
            end

            local function update_event_callbacks(value)
                if not value then
                    override.unset(ref_hit_marker_sound)
                end

                if value then
                    override.set(ref_hit_marker_sound, false)
                end

                utils.event_callback(
                    'shutdown',
                    on_shutdown,
                    value
                )

                utils.event_callback(
                    'player_hurt',
                    on_player_hurt,
                    value
                )
            end

            local callbacks do
                local function on_enabled(item)
                    update_event_callbacks(item:get())
                end

                ref.enabled:set_callback(
                    on_enabled, true
                )
            end
        end
    end
end-- dumped from hrisito forums by <youtube.com/@subtick> ~ rip hrisito 2025-2026
