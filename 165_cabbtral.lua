-- Title: cabbtral
-- Script ID: 165
-- Source: page_165.html
----------------------------------------

local panorama_api = panorama.open()

local DEBUG = true

package.preload["surface"] = function()
do
    surface = { }

    local wide = ffi.new 'int[1]'
    local tall = ffi.new 'int[1]'

    -- reuse a single wchar buffer to avoid allocating every draw call
    local shared_wchar_buffer = ffi.new 'wchar_t[2048]'

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

        ilocalize.ansi_to_unicode(text, shared_wchar_buffer, 2048)
        GetTextSize(font, shared_wchar_buffer, wide, tall)

        return wide[0], tall[0]
    end

    function surface.text(font, x, y, r, g, b, a, text)
        local len = #text

        if len <= 0 then
            return
        end

        ilocalize.ansi_to_unicode(text, shared_wchar_buffer, 2048)

        SetTextFont(font)

        SetTextPos(x, y)
        SetTextColor(r, g, b, a)

        DrawPrintText(shared_wchar_buffer, len, 0)
    end

    function surface.fade(x, y, w, h, r0, g0, b0, a0, r1, g1, b1, a1, horizontal)
        SetColor(r0, g0, b0, a0)
        DrawFilledRectFade(x, y, x + w, y + h, 255, 0, horizontal)

        SetColor(r1, g1, b1, a1)
        DrawFilledRectFade(x, y, x + w, y + h, 0, 255, horizontal)
    end
end
end

-- #region : Libraries


local pui = require("gamesense/pui")
local csgo_weapons = require("gamesense/csgo_weapons")
local clipboard = require("gamesense/clipboard")
local base64 = require("gamesense/base64")
local vector = require("vector")
local ffi = require("ffi")
local http = require("gamesense/http")
local vector = require("vector")
local localize = require 'gamesense/localize'
local c_entity = require 'gamesense/entity'
local antiaim_funcs = require'gamesense/antiaim_funcs'
local _renderer = renderer
local _entity = entity
local _client = client
local _globals = globals
local _ui = ui
local _ffi = ffi
local _math = math
local _string = string
local _table = table
local _vector = vector
local _pui = pui

-- #endregion

local sc = vector(client.screen_size())
math.randomseed(globals.realtime() * 1000)

pui.accent = "A6CAFFFF"

-- #region : lua data
local cabbtral = {}
do
    cabbtral.name = "cabbtral"
    cabbtral.user = panorama_api.MyPersonaAPI.GetName() or "Admin"
    cabbtral.version = "3.0"
    cabbtral.last_update = "07.11.2025"
end

local current_build = "beta"

pui.macros.p = "\aCDCDCD40•\r"
pui.macros.accent = "\ad1d1d1ff"
-- #endregion

function table.find(tbl, val)
    for i = 1, #tbl do
        if tbl[i] == val then
            return i
        end
    end
    return nil
end

-- #region : Math
math.clamp = function(x, a, b)
    if a > x then
        return a
    elseif b < x then
        return b
    else
        return x
    end
end
math.lerp = function(a, b, w)
    return a + (b - a) * w
end

math.normalize_yaw = function(yaw)
    return (yaw + 180) % -360 + 180
end
math.normalize_pitch = function(pitch)
    return math.clamp(pitch, -89, 89)
end
local random_counter = 0

function math.randomized(min, max)
    min = min or 0
    max = max or 1

    random_counter = random_counter + 1
    local t = globals.curtime() * 1000000
    local f = globals.frametime() * 1000000
    local seed = t + f + random_counter * 17

    local s = tostring(seed)
    local mixed = 0
    for i = 1, #s do
        mixed = (mixed * 31 + (tonumber(s:sub(i, i)) or 0)) % 1000000
    end

    seed = bit.band(bit.bxor(bit.lshift(mixed, 5), bit.rshift(mixed, 7)), 0xFFFFFFF)
    return (seed % (max - min + 1)) + min
end


-- #endregion

-- #region : glow helpers
local k = (function()
    local d = {}
    d.rec = function(d, b, c, e, f, g, k, l, m)
        m = math.min(d / 2, b / 2, m)
        renderer.rectangle(d, b + m, c, e - m * 2, f, g, k, l)
        renderer.rectangle(d + m, b, c - m * 2, m, f, g, k, l)
        renderer.rectangle(d + m, b + e - m, c - m * 2, m, f, g, k, l)
        renderer.circle(d + m, b + m, f, g, k, l, m, 180, 0.25)
        renderer.circle(d - m + c, b + m, f, g, k, l, m, 90, 0.25)
        renderer.circle(d - m + c, b - m + e, f, g, k, l, m, 0, 0.25)
        renderer.circle(d + m, b - m + e, f, g, k, l, m, -90, 0.25)
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
            renderer.circle_outline(d + m, b + m, f, g, k, l, m, 180, 0.25, n)
            renderer.circle_outline(
                d + m,
                b + e - m,
                f,
                g,
                k,
                l,
                m,
                90,
                0.25,
                n
            )
            renderer.circle_outline(
                d + c - m,
                b + m,
                f,
                g,
                k,
                l,
                m,
                -90,
                0.25,
                n
            )
            renderer.circle_outline(
                d + c - m,
                b + e - m,
                f,
                g,
                k,
                l,
                m,
                0,
                0.25,
                n
            )
        end
    end
    d.glow_module_notify = function(b, c, e, f, g, k, l, m, n, o, p, q, r, s, s)
        local t = 1
        local u = 1
        local rounding = 8
        if s then
            d.rec(b, c, e, f, l, m, n, o, rounding)
        end
        for l = 0, g do
            local m = o / 2 * (l / g) ^ 3
            d.rec_outline(
                b + (l - g - u) * t,
                c + (l - g - u) * t,
                e - (l - g - u) * t * 2,
                f - (l - g - u) * t * 2,
                p,
                q,
                r,
                m / 1.5,
                rounding,
                t
            )
        end
    end
    return d
end)()
-- #endregion

-- #region : render
local rectangles = {
    rect = function(self, x, y, w, h, clr, rounding)
        local r, g, b, a = unpack(clr)

        renderer.circle(
            x + rounding,
            y + rounding,
            r,
            g,
            b,
            a,
            rounding,
            180,
            0.25
        )
        renderer.rectangle(
            x + rounding,
            y,
            w - rounding - rounding,
            rounding,
            r,
            g,
            b,
            a
        )
        renderer.circle(
            x + w - rounding,
            y + rounding,
            r,
            g,
            b,
            a,
            rounding,
            90,
            0.25
        )
        renderer.rectangle(x, y + rounding, w, h - rounding * 2, r, g, b, a)
        renderer.circle(
            x + rounding,
            y + h - rounding,
            r,
            g,
            b,
            a,
            rounding,
            270,
            0.25
        )
        renderer.rectangle(
            x + rounding,
            y + h - rounding,
            w - rounding - rounding,
            rounding,
            r,
            g,
            b,
            a
        )
        renderer.circle(
            x + w - rounding,
            y + h - rounding,
            r,
            g,
            b,
            a,
            rounding,
            0,
            0.25
        )
    end,

    rectv = function(self, x, y, w, h, clr, rounding, clr2, he, notblur)
        local r, g, b, a = unpack(clr)
        local r1, g1, b1, a1

        renderer.circle(
            x + rounding,
            y + rounding,
            r,
            g,
            b,
            a,
            rounding,
            180,
            0.25
        )
        renderer.rectangle(
            x + rounding,
            y,
            w - rounding - rounding,
            rounding,
            r,
            g,
            b,
            a
        )
        renderer.circle(
            x + w - rounding,
            y + rounding,
            r,
            g,
            b,
            a,
            rounding,
            90,
            0.25
        )
        renderer.rectangle(x, y + rounding, w, h - rounding * 2 + 1, r, g, b, a)

        renderer.circle(
            x + rounding,
            y + h - rounding + 1,
            r,
            g,
            b,
            a,
            rounding,
            270,
            0.25
        )
        renderer.rectangle(
            x + rounding,
            y + h - rounding + 1,
            w - rounding - rounding,
            rounding,
            r,
            g,
            b,
            a
        )
        renderer.circle(
            x + w - rounding,
            y + h - rounding + 1,
            r,
            g,
            b,
            a,
            rounding,
            0,
            0.25
        )

        if a > 30 and not notblur then
            renderer.blur(x, y, w, h)
        end

        if clr2 then
            r1, g1, b1, a1 = unpack(clr2)
            local hs = he or 2

            renderer.rectangle(
                x + rounding,
                y,
                w - rounding * 2,
                hs,
                r1,
                g1,
                b1,
                a1
            )

            renderer.gradient(
                x - 1,
                y + rounding,
                hs,
                h - rounding * 2.7,
                r1,
                g1,
                b1,
                a1,
                r1,
                g1,
                b1,
                0,
                false
            )
            renderer.gradient(
                x + w - 1,
                y + rounding,
                hs,
                h - rounding * 2.7,
                r1,
                g1,
                b1,
                a1,
                r1,
                g1,
                b1,
                0,
                false
            )

            renderer.circle_outline(
                x + w - rounding,
                y + rounding,
                r1,
                g1,
                b1,
                a1,
                rounding,
                270,
                0.25,
                hs
            )
            renderer.circle_outline(
                x + rounding,
                y + rounding,
                r1,
                g1,
                b1,
                a1,
                rounding,
                180,
                0.25,
                hs
            )
        end
    end,
}


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

local rendere = {
    anim = {},

    clamp = function(self, value, minimum, maximum)
        if minimum > maximum then
            minimum, maximum = maximum, minimum
        end

        return math.max(minimum, math.min(maximum, value))
    end,

    alphen = function(self, value)
        return math.max(0, math.min(255, value))
    end,

    lerp = function(self, a, b, speed)
        return (b - a) * speed + a
    end,

    math_anim2 = function(self, start, end_pos, speed)
        speed = self:clamp(
            globals.frametime() * ((speed / 100) or 0.08) * 175.0,
            0.01,
            1.0
        )

        local a = self:lerp(start, end_pos, speed)

        return tonumber(string.format("%.3f", a))
    end,

    new_anim = function(self, name, value, speed)
        if self.anim[name] == nil then
            self.anim[name] = value
        end

        local animation = self:math_anim2(self.anim[name], value, speed)

        self.anim[name] = animation

        return self.anim[name]
    end,

    rect = function(self, x, y, w, h, clr, rounding)
        local r, g, b, a = unpack(clr)

        renderer.circle(
            x + rounding,
            y + rounding,
            r,
            g,
            b,
            a,
            rounding,
            180,
            0.25
        )
        renderer.rectangle(
            x + rounding,
            y,
            w - rounding - rounding,
            rounding,
            r,
            g,
            b,
            a
        )
        renderer.circle(
            x + w - rounding,
            y + rounding,
            r,
            g,
            b,
            a,
            rounding,
            90,
            0.25
        )
        renderer.rectangle(x, y + rounding, w, h - rounding * 2, r, g, b, a)
        renderer.circle(
            x + rounding,
            y + h - rounding,
            r,
            g,
            b,
            a,
            rounding,
            270,
            0.25
        )
        renderer.rectangle(
            x + rounding,
            y + h - rounding,
            w - rounding - rounding,
            rounding,
            r,
            g,
            b,
            a
        )
        renderer.circle(
            x + w - rounding,
            y + h - rounding,
            r,
            g,
            b,
            a,
            rounding,
            0,
            0.25
        )
    end,

    rectv = function(self, x, y, w, h, clr, rounding, clr2, he, notblur)
        local r, g, b, a = unpack(clr)
        local r1, g1, b1, a1

        renderer.circle(
            x + rounding,
            y + rounding,
            r,
            g,
            b,
            a,
            rounding,
            180,
            0.25
        )
        renderer.rectangle(
            x + rounding,
            y,
            w - rounding - rounding,
            rounding,
            r,
            g,
            b,
            a
        )
        renderer.circle(
            x + w - rounding,
            y + rounding,
            r,
            g,
            b,
            a,
            rounding,
            90,
            0.25
        )
        renderer.rectangle(x, y + rounding, w, h - rounding * 2 + 1, r, g, b, a)

        renderer.circle(
            x + rounding,
            y + h - rounding + 1,
            r,
            g,
            b,
            a,
            rounding,
            270,
            0.25
        )
        renderer.rectangle(
            x + rounding,
            y + h - rounding + 1,
            w - rounding - rounding,
            rounding,
            r,
            g,
            b,
            a
        )
        renderer.circle(
            x + w - rounding,
            y + h - rounding + 1,
            r,
            g,
            b,
            a,
            rounding,
            0,
            0.25
        )

        if a > 30 and not notblur then
            renderer.blur(x, y, w, h)
        end

        if clr2 then
            r1, g1, b1, a1 = unpack(clr2)
            local hs = he or 2

            renderer.rectangle(
                x + rounding,
                y,
                w - rounding * 2,
                hs,
                r1,
                g1,
                b1,
                a1
            )

            renderer.gradient(
                x - 1,
                y + rounding,
                hs,
                h - rounding * 2.7,
                r1,
                g1,
                b1,
                a1,
                r1,
                g1,
                b1,
                0,
                false
            )
            renderer.gradient(
                x + w - 1,
                y + rounding,
                hs,
                h - rounding * 2.7,
                r1,
                g1,
                b1,
                a1,
                r1,
                g1,
                b1,
                0,
                false
            )

            renderer.circle_outline(
                x + w - rounding,
                y + rounding,
                r1,
                g1,
                b1,
                a1,
                rounding,
                270,
                0.25,
                hs
            )
            renderer.circle_outline(
                x + rounding,
                y + rounding,
                r1,
                g1,
                b1,
                a1,
                rounding,
                180,
                0.25,
                hs
            )
        end
    end,

draw_window = function(self, x, y, w, h, border_width)
    border_width = border_width or 5
    local bw = border_width

    renderer.rectangle(x, y, w, h, 18, 18, 18, 255)
    renderer.rectangle(x + 1, y + 1, w - 2, h - 2, 62, 62, 62, 255)

    renderer.rectangle(
        x + 2,
        y + 4,
        w - 4,
        h - 6,
        44, 44, 44, 255
    )

    renderer.rectangle(
        x + bw + 2,
        y + bw + 2,
        w - (bw + 2) * 2,
        h - (bw + 2) * 2,
        10, 10, 10, 255
    )

        local half = math.floor(w / 2)

        renderer.gradient(
            x + bw + 2,
            y + bw + 2,
            half - bw - 2,
            1,
            59, 175, 222, 255,
            202, 70, 205, 255,
            true
        )

        renderer.gradient(
            x + half,
            y + bw + 2,
            w - half - bw - 2,
            1,
            202, 70, 205, 255,
            201, 227, 58, 255,
            true
        )

        renderer.gradient(
            x + bw + 2,
            y + bw + 3,
            half - bw - 2,
            1,
            29, 87, 111, 255,
            101, 35, 102, 255,
            true
        )

        renderer.gradient(
            x + half,
            y + bw + 3,
            w - half - bw - 2,
            1,
            101, 35, 102, 255,
            100, 113, 29, 255,
            true
        )
    
end

}
-- #endregion

-- #region : drag
local pui_drags = {}

local drag = {
    new = function(name, base_x, base_y)
        return (function()
            local a = {}
            local magnit = {}

            local drag_type__ = {
                b = 0,
                d = 0,
                e = 0,
                f = 0,
                g = 0,
                h = false,
                i = nil,
                j = 0,
                k = 0,
                l = {},
                m = nil,
                n = false,
                o = nil,
                uii = false,
            }

local p = {
    __index = {
        drag = function(self, ...)
            local q, r = self:get()
            local s, t = a.drag(self, q, r, ...)
            if q ~= s or r ~= t then
                self:set(s, t)
            end
            return s, t
        end,

        set = function(self, q, r)
            local j, k = client.screen_size()
            ui.set(self.x_reference, q / j * self.res)
            ui.set(self.y_reference, r / k * self.res)
        end,

        get = function(self, x333, y333)
            local j, k = client.screen_size()
            return
                ui.get(self.x_reference) / self.res * j + (x333 or 0),
                ui.get(self.y_reference) / self.res * k + (y333 or 0)
        end,

        pui_export = function(self)
            local x, y = self:get()
            return {
                name = self.name,
                x = x,
                y = y
            }
        end,

        pui_import = function(self, data)
            if not data then return end
            self:set(data.x, data.y)
        end
    }
}

            function a.new(u, v, w, x)
                x = x or 10000
                local j, k = client.screen_size()
                local y = ui.new_slider(
                    "aa",
                    "anti-aimbot angles",
                    "cabbtral::x:" .. u,
                    0,
                    x,
                    v / j * x
                )
                local z = ui.new_slider(
                    "aa",
                    "anti-aimbot angles",
                    "cabbtral::y:" .. u,
                    0,
                    x,
                    w / k * x
                )
                ui.set_visible(y, false)
                ui.set_visible(z, false)
                return setmetatable({
                    name = u,
                    x_reference = y,
                    y_reference = z,
                    res = x,
                }, p)
            end

            function a.drag(self, x_widget, y_widget, w_w, h_w, alp)
                if globals.framecount() ~= drag_type__.b then
                    drag_type__.uii = ui.is_menu_open()
                    drag_type__.f, drag_type__.g = drag_type__.d, drag_type__.e
                    drag_type__.d, drag_type__.e = ui.mouse_position()
                    drag_type__.i = drag_type__.h
                    drag_type__.h = client.key_state(0x01) == true
                    drag_type__.m = drag_type__.l
                    drag_type__.l = {}
                    drag_type__.o = drag_type__.n
                    magnit[self.name] = { x = false, y = false }
                    drag_type__.j, drag_type__.k = client.screen_size()
                end

                local held = drag_type__.h
                    and drag_type__.f > x_widget
                    and drag_type__.g > y_widget
                    and drag_type__.f < x_widget + w_w
                    and drag_type__.g < y_widget + h_w

                local held_a = rendere:new_anim(
                    "drag.alpha.held." .. self.name,
                    held and 1 or 0,
                    8
                )

                if drag_type__.uii and drag_type__.i ~= nil then
                    rendere:rect(
                        x_widget,
                        y_widget,
                        w_w,
                        h_w,
                        { 100, 100, 100, 40 },
                        6
                    )

                    if held then
                        drag_type__.n = true
                        x_widget = x_widget + drag_type__.d - drag_type__.f
                        y_widget = y_widget + drag_type__.e - drag_type__.g

                        x_widget =
                            rendere:clamp(drag_type__.j - w_w, 0, x_widget)
                        y_widget =
                            rendere:clamp(drag_type__.k - h_w, 0, y_widget)
                    end

                    if held_a > 0.1 then
                        local ax = rendere:new_anim(
                            "drag.alpha.x." .. self.name,
                            held_a * (80 + (magnit[self.name].x and 90 or 0)),
                            8
                        )
                        local ay = rendere:new_anim(
                            "drag.alpha.y." .. self.name,
                            held_a * (80 + (magnit[self.name].y and 90 or 0)),
                            8
                        )
                        local scr_w, scr_h = client.screen_size()

                        local guide_y = scr_h - 40 - (h_w / 2)
                    end
                end

                table.insert(drag_type__.l, { x_widget, y_widget, w_w, h_w })
                return x_widget, y_widget, w_w, h_w
            end

            return a
        end)().new(name, base_x, base_y)
    end,
}
-- #endregion

-- #region : Events
local events
do
    local event_mt = {
        __call = function(self, fn, bool)
            local action = bool and client.set_event_callback
                or client.unset_event_callback
            action(self[1], fn)
        end,
        set = function(self, fn)
            client.set_event_callback(self[1], fn)
        end,
        unset = function(self, fn)
            client.unset_event_callback(self[1], fn)
        end,
        fire = function(self, ...)
            client.fire_event(self[1], ...)
        end,
    }
    event_mt.__index = event_mt

    events = setmetatable({}, {
        __index = function(self, key)
            self[key] = setmetatable({ key }, event_mt)
            return self[key]
        end,
    })
end
-- #endregion




-- #region : Color
local color
do
    local RGBtoHEX = function(col, short)
        return string.format(
            short and "%02X%02X%02X" or "%02X%02X%02X%02X",
            col.r,
            col.g,
            col.b,
            col.a
        )
    end

    local HEXtoRGB = function(hex)
        hex = string.gsub(hex, "^#", "")
        return tonumber(string.sub(hex, 1, 2), 16),
            tonumber(string.sub(hex, 3, 4), 16),
            tonumber(string.sub(hex, 5, 6), 16),
            tonumber(string.sub(hex, 7, 8), 16) or 255
    end

    local create

    local mt = {
        __eq = function(a, b)
            return a.r == b.r and a.g == b.g and a.b == b.b and a.a == b.a
        end,
        lerp = function(self, t, w)
            return create(
                self.r + (t.r - self.r) * w,
                self.g + (t.g - self.g) * w,
                self.b + (t.b - self.b) * w,
                self.a + (t.a - self.a) * w
            )
        end,
        to_hex = RGBtoHEX,
        alpha_modulate = function(self, a, r)
            return create(self.r, self.g, self.b, r and a * self.a or a)
        end,
        unpack = function(self)
            return self.r, self.g, self.b, self.a
        end,
    }
    mt.__index = mt

    create = ffi.metatype(
        ffi.typeof("struct { uint8_t r; uint8_t g; uint8_t b; uint8_t a; }"),
        mt
    )
    color = function(r, g, b, a)
        local col = {}

        if type(r) == "string" then
            local rh, gh, bh, ah = HEXtoRGB(r)

            col = {
                r = rh,
                g = gh,
                b = bh,
                a = ah,
            }
        else
            col = {
                r = r or 255,
                g = b ~= nil and g or r or 255,
                b = b or r or 255,
                a = a or b == nil and g or 255,
            }
        end

        return create(col.r, col.g, col.b, col.a)
    end
end
-- #endregion

-- #region : Render
local render
do
    local astack = {}
    local alpha = 1

    render = setmetatable({
        push_alpha = function(v)
            local len = #astack
            astack[len + 1] = v
            alpha = alpha * astack[len + 1] * (astack[len] or 1)
            if len > 255 then
                error("alpha stack exceeded 255 objects, report to developers")
            end
        end,
        pop_alpha = function()
            local len = #astack
            astack[len], len = nil, len - 1
            alpha = len == 0 and 1 or astack[len] * (astack[len - 1] or 1)
        end,
        get_alpha = function()
            return alpha
        end,

        gradient = function(position, size, c1, c2, dir)
            local x, y = position.x, position.y
            local w, h = size.x, size.y
            renderer.gradient(
                x,
                y,
                w,
                h,
                c1.r,
                c1.g,
                c1.b,
                c1.a * alpha,
                c2.r,
                c2.g,
                c2.b,
                c2.a * alpha,
                dir or false
            )
        end,

        line = function(xa, ya, xb, yb, c)
            renderer.line(xa, ya, xb, yb, c.r, c.g, c.b, c.a * alpha)
        end,
        rectangle = function(x, y, w, h, c, n)
            n = n or 0
            local r, g, b, a = c.r, c.g, c.b, c.a * alpha

            if n == 0 then
                renderer.rectangle(x, y, w, h, r, g, b, a)
            else
                renderer.circle(x + n, y + n, r, g, b, a, n, 180, 0.25)
                renderer.rectangle(x + n, y, w - n - n, n, r, g, b, a)
                renderer.circle(x + w - n, y + n, r, g, b, a, n, 90, 0.25)
                renderer.rectangle(x, y + n, w, h - n - n, r, g, b, a)
                renderer.circle(x + n, y + h - n, r, g, b, a, n, 270, 0.25)
                renderer.rectangle(x + n, y + h - n, w - n - n, n, r, g, b, a)
                renderer.circle(x + w - n, y + h - n, r, g, b, a, n, 0, 0.25)
            end
        end,
        rect_outline = function(x, y, w, h, c, n, t)
            n, t = n or 0, t or 1
            local r, g, b, a = c.r, c.g, c.b, c.a * alpha

            if n == 0 then
                renderer.rectangle(x, y, w - t, t, r, g, b, a)
                renderer.rectangle(x, y + t, t, h - t, r, g, b, a)
                renderer.rectangle(x + w - t, y, t, h - t, r, g, b, a)
                renderer.rectangle(x + t, y + h - t, w - t, t, r, g, b, a)
            else
                renderer.circle_outline(
                    x + n,
                    y + n,
                    r,
                    g,
                    b,
                    a,
                    n,
                    180,
                    0.25,
                    t
                )
                renderer.rectangle(x + n, y, w - n - n, t, r, g, b, a)
                renderer.circle_outline(
                    x + w - n,
                    y + n,
                    r,
                    g,
                    b,
                    a,
                    n,
                    270,
                    0.25,
                    t
                )
                renderer.rectangle(x, y + n, t, h - n - n, r, g, b, a)
                renderer.circle_outline(
                    x + n,
                    y + h - n,
                    r,
                    g,
                    b,
                    a,
                    n,
                    90,
                    0.25,
                    t
                )
                renderer.rectangle(x + n, y + h - t, w - n - n, t, r, g, b, a)
                renderer.circle_outline(
                    x + w - n,
                    y + h - n,
                    r,
                    g,
                    b,
                    a,
                    n,
                    0,
                    0.25,
                    t
                )
                renderer.rectangle(x + w - t, y + n, t, h - n - n, r, g, b, a)
            end
        end,
        triangle = function(x1, y1, x2, y2, x3, y3, c)
            renderer.triangle(
                x1,
                y1,
                x2,
                y2,
                x3,
                y3,
                c.r,
                c.g,
                c.b,
                c.a * alpha
            )
        end,

        circle = function(x, y, c, radius, start, percentage)
            renderer.circle(
                x,
                y,
                c.r,
                c.g,
                c.b,
                c.a * alpha,
                radius,
                start or 0,
                percentage or 1
            )
        end,
        circle_outline = function(
            x,
            y,
            c,
            radius,
            start,
            percentage,
            thickness
        )
            renderer.circle(
                x,
                y,
                c.r,
                c.g,
                c.b,
                c.a * alpha,
                radius,
                start or 0,
                percentage or 1,
                thickness
            )
        end,
        shadow = function(x, y, width, height, radius, glow_size, r, g, b, a)
            for i = glow_size, 1, -1 do
                local alpha = a * (i / glow_size) * 0.6
                if alpha <= 0 then
                    goto continue
                end
                render.rectangle(
                    x - i,
                    y - i,
                    width + i * 2,
                    height + i * 2,
                    color(r, g, b, alpha),
                    0.25
                )
            end

            render.rectangle(x, y, width, height, color(r, g, b, a), 0.25)
            ::continue::
        end,

        colored_text = function(text, clr)
            clr.a = clr.a * alpha

            local hexed = clr:to_hex()
            local default = color(200, clr.a):to_hex()

            text = ("\a%s%s"):format(default, text)

            local tmp = ("\a%s%%1\a%s"):format(hexed, default)
            local result = text:gsub("%${(.-)}", tmp)

            return result
        end,

        text = function(x, y, c, flags, width, ...)
            renderer.text(
                x,
                y,
                c.r,
                c.g,
                c.b,
                c.a * alpha,
                (flags or ""),
                width or 0,
                ...
            )
        end,
        measure_text = function(flags, text)
            if not text or text == "" then
                return vector(0, 0)
            end

            flags = (flags or "")

            return vector(renderer.measure_text(flags, text))
        end,
        to_hex = function(r, g, b, a)
            return string.format("%02x%02x%02x%02x", r, g, b, a)
        end,
        breath = function(x)
            x = x % 2.0

            if x > 1.0 then
                x = 2.0 - x
            end

            return x
        end,
        u8 = function(s)
            return string.gsub(s, "[\128-\191]", "")
        end,
        gradient_text = function(s, clock, r1, g1, b1, a1, r2, g2, b2, a2)
            local buffer = {}

            local len = #render.u8(s)
            local div = 1 / (len - 1)

            local add_r = r2 - r1
            local add_g = g2 - g1
            local add_b = b2 - b1
            local add_a = a2 - a1

            for char in string.gmatch(s, ".[\128-\191]*") do
                local t = render.breath(clock)

                local r = r1 + add_r * t
                local g = g1 + add_g * t
                local b = b1 + add_b * t
                local a = a1 + add_a * t

                buffer[#buffer + 1] = "\a"
                buffer[#buffer + 1] = render.to_hex(r, g, b, a)
                buffer[#buffer + 1] = char

                clock = clock - div
            end

            return table.concat(buffer)
        end,
    }, { __index = renderer })
end
-- #endregion

-- #region : Anim
local anim = {}
do
    anim._list = {}

    anim.lerp = function(start, end_pos, time)
        time = time or 0.095

        if math.abs(start - end_pos) < 1 then
            return end_pos
        end

        time = math.clamp(globals.frametime() * time * 170, 0.01, 1)

        return start + (end_pos - start) * time
    end

    anim.new = function(name, new_value, speed)
        speed = speed or 0.095

        if anim._list[name] == nil then
            anim._list[name] = new_value
        end

        anim._list[name] = anim.lerp(anim._list[name], new_value, speed)

        return anim._list[name]
    end
end
-- #endregion

-- #region : print_raw
local print_raw
do
    print_raw = function(...)
        local out = "  cabbtral · "

        for _, v in ipairs({ ... }) do
            out = out .. tostring(v)
        end

        client.color_log(
            pui.macros.accent.r,
            pui.macros.accent.g,
            pui.macros.accent.b,
            out
        )
    end
end 
-- #endregion


-- #region : utils
local utils = {}

function utils.is_fakeducking(ent)
    if not ent or not entity.is_alive(ent) then
        return false
    end

    local flags = entity.get_prop(ent, "m_fFlags")
    local on_ground = bit.band(flags, 1) == 1

    if not on_ground then
        return false
    end

    local duck = entity.get_prop(ent, "m_flDuckAmount")
    if not duck then
        return false
    end

    if duck < 0.1 or duck > 0.9 then
        return false
    end

    local vx, vy = entity.get_prop(ent, "m_vecVelocity")
    local speed = math.sqrt(vx * vx + vy * vy)

    return speed < 5
end


function utils.random_int(min, max)
    if min > max then
        min, max = max, min
    end
    return client.random_int(min, max)
end

function utils.draw_animated_text(text, block_size)
    -- persistent frame counter
    utils.draw_animated_text.frame =
        (utils.draw_animated_text.frame or 0) + 1

    local len = #text
    local pos = len - (utils.draw_animated_text.frame % len)

    local out = {}

    for i = 1, len do
        local is_block = false

        -- block wrap check
        for b = 0, block_size - 1 do
            if i == ((pos + b - 1) % len) + 1 then
                is_block = true
                break
            end
        end

        out[i] = is_block and "4" or "-"
    end

    return table.concat(out)
end



function utils.from_hex(hex)
        hex = string.gsub(hex, '#', '')

        local r = tonumber(string.sub(hex, 1, 2), 16)
        local g = tonumber(string.sub(hex, 3, 4), 16)
        local b = tonumber(string.sub(hex, 5, 6), 16)
        local a = tonumber(string.sub(hex, 7, 8), 16)

        return r, g, b, a or 255
    end

function utils.random_float(min, max)
    if min > max then
        min, max = max, min
    end
    return min + (max - min) * math.random()
end

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
-- #endregion

-- #region : Entity Helpers
do
    local native_GetClientEntity = vtable_bind(
        "client.dll",
        "VClientEntityList003",
        3,
        "void*(__thiscall*)(void*, int)"
    )
    local native_GetHighestEntityIndex = vtable_bind(
        "client.dll",
        "VClientEntityList003",
        6,
        "int(__thiscall*)(void*)"
    )
    local native_GetClientNetworkable = vtable_bind(
        "client.dll",
        "VClientEntityList003",
        0,
        "void*(__thiscall*)(void*, int)"
    )
    local native_GetClientClass = vtable_thunk(2, "void*(__thiscall*)(void*)")

    entity.get_all = function(optional_classname)
        local entities = {}

        for i = 0, native_GetHighestEntityIndex() do
            local ent = native_GetClientEntity(i)
            if ent == nil then
                goto continue
            end

            local net = native_GetClientNetworkable(i)
            if net == nil then
                goto continue
            end

            local class = native_GetClientClass(net)
            if class == nil then
                goto continue
            end

            local classname = ffi.string(
                ffi.cast("const char**", ffi.cast("char*", class) + 8)[0]
            )
            if optional_classname == nil or classname == optional_classname then
                table.insert(entities, i)
            end

            ::continue::
        end

        return entities
    end

    entity.get_players = function(enemies_only, include_dormant, fn)
        local results = {}
        local players = entity.get_all("CCSPlayer")

        for _, player in pairs(players) do
            if
                (not enemies_only or entity.is_enemy(player))
                and (include_dormant or not entity.is_dormant(player))
            then
                if fn ~= nil then
                    fn(player)
                end

                table.insert(results, player)
            end
        end

        return results
    end

    ffi.cdef([[
typedef struct {
char pad0[0x18];
float anim_update_timer;
char pad1[0xC];
float started_moving_time;
float last_move_time;
char pad2[0x10];
float last_lby_time;
char pad3[0x8];
float run_amount;
char pad4[0x10];
void* entity;
void* active_weapon;
void* last_active_weapon;
float last_client_side_animation_update_time;
int	 last_client_side_animation_update_framecount;
float eye_timer;
float eye_angles_y;
float eye_angles_x;
float goal_feet_yaw;
float current_feet_yaw;
float torso_yaw;
float last_move_yaw;
float lean_amount;
char pad5[0x4];
float feet_cycle;
float feet_yaw_rate;
char pad6[0x4];
float duck_amount;
float landing_duck_amount;
char pad7[0x4];
float current_origin[3];
float last_origin[3];
float velocity_x;
float velocity_y;
char pad8[0x4];
float unknown_float1;
char pad9[0x8];
float unknown_float2;
float unknown_float3;
float unknown;
float m_velocity;
float jump_fall_velocity;
float clamped_velocity;
float feet_speed_forwards_or_sideways;
float feet_speed_unknown_forwards_or_sideways;
float last_time_started_moving;
float last_time_stopped_moving;
bool on_ground;
bool hit_in_ground_animation;
char pad10[0x4];
float time_since_in_air;
float last_origin_z;
float head_from_ground_distance_standing;
float stop_to_full_running_fraction;
char pad11[0x4];
float magic_fraction;
char pad12[0x3C];
float world_force;
char pad13[0x1CA];
float min_yaw;
float max_yaw;
} CAnimationState;

typedef struct {
char  pad_0000[20];
int m_nOrder;
int m_nSequence;
float m_flPrevCycle;
float m_flWeight;
float m_flWeightDeltaRate;
float m_flPlaybackRate;
float m_flCycle;
void *m_pOwner;
char  pad_0038[4];
} CAnimationLayer;
]])

    entity.get_animstate = function(ent)
        local pointer = native_GetClientEntity(ent)
        if pointer then
            return ffi.cast(
                "CAnimationState**",
                ffi.cast("char*", ffi.cast("void***", pointer)) + 0x9960
            )[0]
        end
        return
    end

    entity.get_animlayer = function(ent, layer)
        local pointer = native_GetClientEntity(ent)
        if pointer then
            return ffi.cast(
                "CAnimationLayer**",
                ffi.cast("char*", ffi.cast(ffi.typeof("void***"), pointer))
                    + 0x2990
            )[0][layer]
        end
        return
    end

    entity.get_simtime = function(ent)
        local pointer = native_GetClientEntity(ent)
        if pointer then
            return entity.get_prop(ent, "m_flSimulationTime"),
                ffi.cast("float*", ffi.cast("uintptr_t", pointer) + 0x26C)[0]
        else
            return 0
        end
    end

    entity.get_max_desync = function(animstate)
        local speedfactor =
            math.clamp(animstate.feet_speed_forwards_or_sideways, 0, 1)
        local avg_speedfactor = (
            animstate.stop_to_full_running_fraction * -0.3 - 0.2
        )
                * speedfactor
            + 1

        local duck_amount = animstate.duck_amount
        if duck_amount > 0 then
            local duck_speed = duck_amount * speedfactor

            avg_speedfactor = avg_speedfactor
                + (duck_speed * (0.5 - avg_speedfactor))
        end

        return math.clamp(avg_speedfactor, 0.5, 1)
    end
end
-- #endregion

-- #region : Database
local db = {
    name = ("%s::data"):format(cabbtral.name:lower()),
}
do
    db.data = database.read(db.name)

    if not db.data then
        db.data = {}
    end

    db.read = function(key)
        return db.data[key]
    end

    db.write = function(key, value)
        db.data[key] = value
    end

db.data = database.read(db.name) or {}

db.data.stats = db.data.stats or {
     killed= 0,
    evaded = 0,
    playtime = 0,
    loaded = 0
}

db.data.stats.killed   = db.data.stats.killed   or 0
db.data.stats.evaded   = db.data.stats.evaded   or 0
db.data.stats.playtime = db.data.stats.playtime or 0
db.data.stats.loaded   = (db.data.stats.loaded or 0) + 1

client.set_event_callback("aim_hit", function(shot, e)
    local alive = entity.is_alive(shot.target)

    if not alive then
        db.data.stats.killed   = db.data.stats.killed + 1
    end
end)

end
-- #endregion

-- #region : Refs

local function safe_ref(...)
    local ok, a, b, c = pcall(pui.reference, ...)
    if not ok then
        return nil
    end
    return a, b, c
end

local function safe_pui_ref(...)
    local ok, ref = pcall(pui.reference, ...)
    if ok then return ref end
    return nil
end

local function safe_reference(fn, ...)
    local ok, a, b, c = pcall(fn, ...)
    if not ok then
        return nil
    end
    return a, b, c
end

local refs = {
    antiaim = {
        antiaim_enabled = pui.reference("AA", "Anti-Aimbot angles", "Enabled"),
        pitch = (function()
            local ref = { pui.reference("AA", "Anti-Aimbot angles", "Pitch") }
            return ref[1]
        end)(),
        pitch_offset = (function()
            local ref = { pui.reference("AA", "Anti-Aimbot angles", "Pitch") }
            return ref[2]
        end)(),
        yaw_base = pui.reference("AA", "Anti-Aimbot angles", "Yaw base"),
        yaw = (function()
            local ref = { pui.reference("AA", "Anti-Aimbot angles", "Yaw") }
            return ref[1]
        end)(),
        yaw_offset = (function()
            local ref = { pui.reference("AA", "Anti-Aimbot angles", "Yaw") }
            return ref[2]
        end)(),
        yaw_jitter = (function()
            local ref =
                { pui.reference("AA", "Anti-Aimbot angles", "Yaw jitter") }
            return ref[1]
        end)(),
        yaw_jitter_offset = (function()
            local ref =
                { pui.reference("AA", "Anti-Aimbot angles", "Yaw jitter") }
            return ref[2]
        end)(),
        body_yaw = (function()
            local ref =
                { pui.reference("AA", "Anti-Aimbot angles", "Body yaw") }
            return ref[1]
        end)(),
        body_yaw_offset = (function()
            local ref =
                { pui.reference("AA", "Anti-Aimbot angles", "Body yaw") }
            return ref[2]
        end)(),
        freestanding_body_yaw = pui.reference(
            "AA",
            "Anti-Aimbot angles",
            "Freestanding body yaw"
        ),
        edge_yaw = pui.reference("AA", "Anti-Aimbot angles", "Edge yaw"),
        freestanding = pui.reference(
            "AA",
            "Anti-Aimbot angles",
            "Freestanding"
        ),
        roll = pui.reference("AA", "Anti-Aimbot angles", "Roll"),
        fakelag = pui.reference("AA", "Fake lag", "Enabled"),
        fakelag_amount = pui.reference("AA", "Fake lag", "Amount"),
        fakelag_variance = pui.reference("AA", "Fake lag", "Variance"),
        fakelag_limit = pui.reference("AA", "Fake lag", "Limit"),
        limit = pui.reference("AA", "Fake lag", "Limit"),
        leg_movement = pui.reference("AA", "Other", "Leg movement"),
    },

    other = {
        aimbot = { pui.reference("RAGE", "Aimbot", "Enabled") },
        doubletap = pui.reference("RAGE", "Aimbot", "Double tap"),
        doubletap_fakelag = pui.reference(
            "RAGE",
            "Aimbot",
            "Double tap fake lag limit"
        ),
        hitchance = pui.reference("RAGE", "Aimbot", "Minimum hit chance"),
        fake_peek = pui.reference("AA", "Other", "Fake peek"),
        slow_motion = pui.reference("AA", "Other", "Slow motion"),
        onshot = pui.reference("AA", "Other", "On shot anti-aim"),
        fake_duck = pui.reference("RAGE", "Other", "Duck peek assist"),
        min_damage = pui.reference("RAGE", "Aimbot", "Minimum damage"),
        hit_chance = pui.reference("RAGE", "Aimbot", "Minimum hit chance"),
        force_baim = pui.reference("RAGE", "Aimbot", "Force body aim"),
        force_sp = pui.reference("RAGE", "Aimbot", "Force safe point"),
        min_damage_override = {
            pui.reference("RAGE", "Aimbot", "Minimum damage override"),
        },
        silent_aim = ui.reference("RAGE", "Other", "Silent aim"),
        fakeduck = pui.reference("RAGE", "Other", "Duck peek assist"),
        autopeek = {
            pui.reference("RAGE", "Other", "Quick peek assist")
        },
        remove_scope = pui.reference(
            "VISUALS",
            "Effects",
            "Remove scope overlay"
        ),
        lp_chams = {
            pui.reference("VISUALS", "Colored models", "Local player"),
        },
        weaponview_color = pui.reference("VISUALS", "Colored models", "Weapon viewmodel"),
        thirdperson = pui.reference("VISUALS", "Effects", "Force third person (alive)"),
        hitchance = ui.reference("RAGE", "Aimbot", "Minimum hit chance"),
        ping_spike = pui.reference("MISC", "Miscellaneous", "Ping spike"),
        _, ping_spike_value = pui.reference("MISC", "Miscellaneous", "Ping spike"),
        weapon_type = ui.reference("RAGE", "Weapon type", "Weapon type"),
        hitchanceovr = safe_pui_ref("RAGE", "Other", "Hit chance override"),
    },
}
-- #endregion

-- #region : My
local my = {
    entity = entity.get_local_player(),
    valid = false,

    threat = client.current_threat(),

    scoped = false,
    weapon = nil,

    side = 0,
    origin = vector(),
    velocity = -1,
    movetype = -1,
    jumping = false,

    in_score = false,
    command_number = 0,

    state = -1,
    states = {
        unknown = -1,
        standing = 2,
        running = 3,
        walking = 4,
        crouching = 5,
        sneaking = 6,
        air = 7,
        air_crouch = 8,
        freestanding = 9,
        manual_yaw = 10,
        planting = 11,
    },
}
do

    my.update_netvars = function(cmd)
        my.entity = entity.get_local_player()
        my.valid = my.entity and entity.is_alive(my.entity)
        my.command_number = cmd.command_number
        if my.valid then
            local velocity = vector(entity.get_prop(my.entity, "m_vecVelocity"))
            my.velocity = velocity:length2d()
            my.origin = vector(entity.get_prop(my.entity, "m_vecOrigin"))
            my.scoped = entity.get_prop(my.entity, "m_bIsScoped") == 1
            my.weapon = entity.get_player_weapon(my.entity)
            my.movetype = entity.get_prop(my.entity, "m_MoveType")
            my.threat = client.current_threat()
            my.jumping = cmd.in_jump == 1
            my.in_score = cmd.in_score == 1

            if my.side == 0 then
                my.side = (cmd.sidemove > 0) and 1
                    or (cmd.sidemove < 0) and -1
                    or 0
            end

            if not my.scoped then
                my.side = 0
            end
        end
    end

    my.update_state = function(cmd)
        if not my.valid then
            return
        end

        local flags = entity.get_prop(my.entity, "m_fFlags")

        local on_ground = bit.band(flags, bit.lshift(1, 0)) == 1
        local is_not_moving = my.velocity < 5
        local is_walking = cmd.in_speed == 1
        local is_crouching = cmd.in_duck == 1 or refs.other.fake_duck:get()
        local in_air = not on_ground or cmd.in_jump == 1

        if is_crouching and in_air then
            my.state = my.states.air_crouch
            return
        end

        if in_air then
            my.state = my.states.air
            return
        end

        if not is_crouching and is_not_moving then
            my.state = my.states.standing
            return
        end

        if is_walking then
            my.state = my.states.walking
            return
        end

        if is_crouching and not is_not_moving then
            my.state = my.states.sneaking
            return
        end

        if is_crouching and is_not_moving then
            my.state = my.states.crouching
            return
        end

        if not is_crouching and not is_not_moving and not is_walking then
            my.state = my.states.running
            return
        end

        my.state = my.states.unknown
    end

    events.setup_command:set(function(cmd)
        my.update_netvars(cmd)
        my.update_state(cmd)
    end)
end
-- #endregion

-- #region : Menu
local menu = {
    refs = {},
    depends = {},
    elements = {},
}
do
    menu.global_update_callback = function()
        for k, v in pairs(menu.refs) do
            for name, ref in pairs(v) do
                if menu.depends[k] then
                    if menu.depends[k][name] then
                        ref:set_visible(menu.depends[k][name]())
                    end
                end
            end
        end
    end

    menu.new = function(tab, name, cheat_var, depends)
        if menu.refs[tab] == nil then
            menu.refs[tab] = {}
            menu.elements[tab] = {}
        end

        if menu.elements[tab][name] ~= nil then
            error(("Element already exists: [%s][%s]"):format(tab, name))
        end

        menu.refs[tab][name] = cheat_var

        local update = function()
            if cheat_var.type == "color_picker" then
                menu.elements[tab][name] = color(cheat_var:get())
            elseif cheat_var.type == "multiselect" then
                local value_list = cheat_var.value

                local tmp = {}
                for k, v in pairs(value_list) do
                    tmp[v] = true
                end

                menu.elements[tab][name] = tmp
            else
                menu.elements[tab][name] = cheat_var.value
            end
        end

        if depends ~= nil then
            if type(depends) == "function" then
                if menu.depends[tab] == nil then
                    menu.depends[tab] = {}
                end

                menu.depends[tab][name] = depends
            end
        end

        cheat_var:set_callback(update, true)
        cheat_var:set_callback(menu.global_update_callback, true)

        return cheat_var
    end

    local menu_mt = {
        __index = function(self, index, args)
            return function(...)
                local group = ...

                return function(...)
                    local item = group[index](group, ...)

                    return function(tab, name, ...)
                        menu.new(tab, name, item, ...)

                        return item
                    end
                end
            end
        end,
    }

    menu = setmetatable(menu, menu_mt)
end
-- #endregion

-- #region : groups
local groups = {
    antiaim = pui.group("AA", "Anti-aimbot angles"),
    fakelag = pui.group("AA", "Fake lag"),
    other = pui.group("AA", "Other"),
}
-- #endregion

-- #region : Exploit
local exploit = {
    diff = 0,
    defensive = false,
    shift = false,
    active = false,
}
do
    local last_commandnumber = 0
    local tickbase_max = 0

    events.run_command:set(function(cmd)
        if not my.valid then
            return
        end

        local tickbase = entity.get_prop(my.entity, "m_nTickBase") or 0
        local client_latency = client.latency()

        local shift = math.floor(
            tickbase
                - globals.tickcount()
                - 3
                - toticks(client_latency) * 0.5
                + 0.5 * (client_latency * 10)
        )
        local wanted = -14 + (refs.other.doubletap_fakelag:get() - 1) + 3

        exploit.shift = shift <= wanted

        last_commandnumber = cmd.command_number
    end)

    events.predict_command:set(function(cmd)
        if not my.valid then
            return
        end

        if last_commandnumber ~= cmd.command_number then
            return
        end

        exploit.active = refs.other.doubletap:get()
                and refs.other.doubletap.hotkey:get()
            or refs.other.onshot:get()
                and refs.other.onshot.hotkey:get()

        local tickbase = entity.get_prop(my.entity, "m_nTickBase") or 0

        if tickbase_max ~= nil then
            exploit.diff = tickbase - tickbase_max
            exploit.defensive = exploit.diff <= -3
        end

        tickbase_max = math.max(tickbase, tickbase_max or 0)

        last_commandnumber = nil
    end)

    events.level_init:set(function()
        exploit.diff = 0
        exploit.defensive = false
        exploit.shift = false
        exploit.active = false

        tickbase_max = 0
        last_commandnumber = 0
    end)
end
-- #endregion


--\a373737FF??????????????????????????

-- #region : Tab Selector

local tabs = {
    {
        nil, {
            'Ragebot',
            'Autobuy'
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
        'Other', {
            'Indicators',
            'Visuals',
            'Miscellaneous',
        }
    },

    {
        'Manager', {
            'Configs'
        }
    }
}

local listbox_items = {}
local header_to_first = {}

for _, group in ipairs(tabs) do
    local group_name = group[1]
    local items = group[2]

    local first_item_index

    -- only add header if it exists
    if group_name ~= nil then
        listbox_items[#listbox_items + 1] = "— " .. group_name .. " —"
        local header_index = #listbox_items
        first_item_index = header_index + 1
        header_to_first[header_index] = first_item_index
    else
        first_item_index = #listbox_items + 1
    end

    -- add items
    for _, item in ipairs(items) do
        listbox_items[#listbox_items + 1] = item
    end
end


client.set_event_callback("paint_ui", function()
    local idx = menu.elements["main"]["tab_selector"]

    if idx == 2 then
        menu.refs["main"]["tab_selector"]:set(3)
    elseif idx == 6 then
        menu.refs["main"]["tab_selector"]:set(7)
    elseif idx == 10 then
        menu.refs["main"]["tab_selector"]:set(11)
    end
end)

local ts = {}
do
    menu.label(groups.antiaim)(("\v%s\r \aFFAE99FF[%s]"):format(cabbtral.name, current_build))(
        "main",
        "info_header"
    )

    menu.label(groups.antiaim)("\226\128\142")("main", "blank69420")
	
    --menu.label(groups.antiaim)("\226\128\142")("main", "blank4167")
    
    menu.label(groups.fakelag)(("Welcome back, \v%s\r"):format(cabbtral.user))(
        "main",
        "labelwelcome"
    )

    menu.label(groups.fakelag)(("We hope you a great experience with \v%s\r"):format(cabbtral.name))(
        "main",
        "labelwelcoming"
    )

    menu.label(groups.fakelag)(("stay top, stay \v%s\r"):format(cabbtral.name))(
        "main",
        "labelwelcoming1"
    )

    menu.listbox(groups.fakelag)(
        "\ntab_selector",
        listbox_items,
        nil,
        false)("main", "tab_selector")

    menu.button(groups.other)("Discord", function()
        panorama.open().SteamOverlayAPI.OpenURL("https://discord.gg/JJqxk2Des3")
    end)("main", "discord", function()
            return menu.elements["main"]["tab_selector"] == 11
        end
    )

    menu.checkbox(groups.other)("\vdebug info\r")("main", "debug", function()
            return menu.elements["main"]["tab_selector"] == 11
        end
    )

    menu.button(groups.other)("\vFps fix", function()
        client.exec("clear_anim_chace;clear_bombs;clear_debug_overlays;logaddress_add 1") end)
        ("main", "fpsfix", function()
            return menu.elements["main"]["tab_selector"] == 11
        end
    )

    ts.is_home = function()
        return menu.elements["main"]["tab_selector"] == 11
    end

    ts.is_config = function()
        return menu.elements["main"]["tab_selector"] == 11
    end
    
    ts.is_rage = function()
        return menu.elements["main"]["tab_selector"] == 0
    end
    
    ts.is_buymenu = function()
        return menu.elements["main"]["tab_selector"] == 1
    end

    ts.is_antiaim = function()
        return menu.elements["main"]["tab_selector"] == 4
    end

    ts.is_hotkeys = function()
        return menu.elements["main"]["tab_selector"] == 5
    end

    ts.is_antiaim2 = function()
        return menu.elements["main"]["tab_selector"] == 3
    end

    ts.is_indicators = function()
        return menu.elements["main"]["tab_selector"] == 7
    end

    ts.is_misc = function()
        return menu.elements["main"]["tab_selector"] == 9
    end

    ts.is_other = function()
        return menu.elements["main"]["tab_selector"] == 8
    end
end

-- #endregion

-- #region : Configs
events.paint_ui:set(function()

    if not refs or not refs.antiaim or not refs.other then
        return
    end

    if not menu or not menu.elements or not menu.elements.main then
        return
    end

    pui.traverse(refs.antiaim, function(ref)
        if ref then
            ref:set_visible(false)
        end
    end)

    local main = menu.elements.main

    local enabled =
        main.tab_selector == 5

    if refs.other.onshot then
        refs.other.onshot:set_visible(enabled)
    end
    if refs.other.slow_motion then
        refs.other.slow_motion:set_visible(enabled)
    end
    if refs.other.fake_peek then
        refs.other.fake_peek:set_visible(enabled)
    end
end)




-- #endregion

-- #region : Configs
local configs = {
    db = db.read("configs") or {},
    data = {},
    maximum_count = 10,
}
do
    configs.create_default = function()
        local default_exists = true
        for i = 1, #configs.db do
            if
                configs.db[i].name:lower() == "default"
            then
                default_exists = true
                break
            end
        end

        if not default_exists then
            configs.db[#configs.db + 1] = {
                name = "Default",
                data = "",
            }

            db.write("configs", configs.db)
        end
    end 

    configs.compile = function(data)
        if data == nil then
            print_raw("An error occured with config!")
            client.exec("play resource\\warning.wav")
            return
        end

        success, data = pcall(function()
            return base64.encode(json.stringify(data))
        end)

        if not success then
            print_raw("An error occured with config!")
            client.exec("play resource\\warning.wav")
            return
        end

        return ("%s::gs::%s"):format(
            cabbtral.name:lower(),
            data:gsub("=", "_"):gsub("+", "Z1337Z")
        )
    end

    configs.decompile = function(data)
        if data == nil then
            print_raw("An error occured with config!")
            client.exec("play resource\\warning.wav")
            return
        end

        if not data:find(("%s::gs::"):format(cabbtral.name:lower())) then
            print_raw("An error occured with config!")
            client.exec("play resource\\warning.wav")
            return
        end

        data = data:gsub(("%s::gs::"):format(cabbtral.name:lower()), "")
            :gsub("_", "=")
            :gsub("Z1337Z", "+")

        success, data = pcall(function()
            return json.parse(base64.decode(data))
        end)

        if not success then
            print_raw("An error occured with config!")
            client.exec("play resource\\warning.wav")
            return
        end

        return data
    end

    configs.load = function(id, tab)
        local db_data = configs.db[id]

        if db_data == nil then
            print_raw(
                ("Config not selected or something went wrong with database!"):format(
                    name
                )
            )
            client.exec("play resource\\warning.wav")
            return
        end

        if db_data.data == nil or db_data.data == "" then
            print_raw("An error occured with database!")
            client.exec("play resource\\warning.wav")
            return
        end

        if id > #configs.db then
            print_raw("An error occured with database!")
            client.exec("play resource\\warning.wav")
            return
        end

        local name = db_data.name
        local data = db_data.data

        configs.data:load(data, tab)

        print_raw(("%s successfully loaded!"):format(name))
        client.exec("play ui\\beepclear")
    end

    configs.save = function(id)
        local db_data = configs.db[id]

        if db_data == nil then
            print_raw(
                ("Config not selected or something went wrong with database!"):format(
                    name
                )
            )
            client.exec("play resource\\warning.wav")
            return
        end

        local name = db_data.name

        configs.db[id].data = configs.data:save()
        db.write("configs", configs.db)

        print_raw(("%s successfully saved!"):format(name))
        client.exec("play ui\\beepclear")
    end

    configs.export = function(id)
        local db_data = configs.db[id]

        if db_data == nil then
            print_raw(
                ("Config not selected or something went wrong with database!"):format(
                    name
                )
            )
            client.exec("play resource\\warning.wav")
            return
        end

        local name = db_data.name
        local data = configs.compile(db_data)

        clipboard.set(data)

        print_raw(("%s successfully exported!"):format(name))
        client.exec("play ui\\beepclear")
    end

    configs.remove = function(id)
        local db_data = configs.db[id]

        if db_data == nil then
            print_raw(
                ("Config not selected or something went wrong with database!"):format(
                    name
                )
            )
            client.exec("play resource\\warning.wav")
            return
        end

        local name = db_data.name

        table.remove(configs.db, id)
        db.write("configs", configs.db)

        print_raw(("%s successfully removed!"):format(name))
        client.exec("play ui\\beepclear")
    end

    configs.create = function(name, data)
        if type(name) ~= "string" then
            print_raw("An error occured with config!")
            client.exec("play resource\\warning.wav")
            return
        end

        if name == nil then
            print_raw("Name of config is invalid!")
            client.exec("play resource\\warning.wav")
            return
        end

        if #name == 0 or string.match(name, "%s%s") then
            print_raw("Name of config is empty!")
            client.exec("play resource\\warning.wav")
            return
        end

        if #name > 24 then
            print_raw("Name of config is too long!")
            client.exec("play resource\\warning.wav")
            return
        end

        local already_created = function()
            local val = true

            for i = 1, #configs.db do
                val = val and name ~= configs.db[i].name
            end

            return val
        end

        if not already_created() then
            print_raw(("%s is already created!"):format(name))
            client.exec("play resource\\warning.wav")
            return
        end

        if #configs.db > configs.maximum_count then
            print_raw("Too much configs!")
            client.exec("play resource\\warning.wav")
            return
        end

        table.insert(configs.db, {
            name = name,
            author = author,
            data = data,
        })

        db.write("configs", configs.db)

        print_raw(("%s successfully created!"):format(name))
        client.exec("play ui\\beepclear")
    end

    configs.import = function()
        local clipboard_data = clipboard.get()

        if clipboard_data == nil then
            print_raw("An error occured with config!")
            client.exec("play resource\\warning.wav")
            return
        end

        local decompiled = configs.decompile(clipboard_data)

        if decompiled == nil then
            print_raw("An error occured with config!")
            client.exec("play resource\\warning.wav")
            return
        end

        local name = decompiled.name
        local data = decompiled.data

        if #configs.db > configs.maximum_count then
            print_raw("Too much configs!")
            client.exec("play resource\\warning.wav")
            return
        end

        table.insert(configs.db, {
            name = name,
            data = data,
        })

        db.write("configs", configs.db)

        print_raw(("%s successfully imported!"):format(name))
        client.exec("play ui\\beepclear")
    end

    configs.update_list = function()
        local ref = menu.refs["configs"]["configs_list"]

        local tmp = {}

        for _, configuration in pairs(configs.db) do
            table.insert(
                tmp,
                configuration.name
            )
        end

        ui.update(
            ref.ref,
            #tmp ~= 0 and tmp ~= nil and tmp or { "Empty configs list" }
        )
    end

    menu.listbox(groups.antiaim)("\n", { "Empty configs list" })(
        "configs",
        "configs_list",
        ts.is_config
    )

    menu.textbox(groups.antiaim)("Config Name")(
        "configs",
        "config_name",
        ts.is_config
    )

    menu.button(groups.antiaim)("\v?\r Create New", function()
        configs.create(
            menu.refs["configs"]["config_name"]:get(),
            cabbtral.user,
            configs.data:save()
        )
        configs.update_list()
    end)("configs", "config_create", ts.is_config)

    menu.button(groups.antiaim)("\v?\r Load", function()
        local key = menu.elements["configs"]["configs_list"] + 1

        configs.load(key)
        configs.update_list()
    end)("configs", "config_load", ts.is_config)

    menu.button(groups.antiaim)("\v?\r Load Anti Aim's only", function()
        local key = menu.elements["configs"]["configs_list"] + 1

        configs.load(key, "antiaim")
        configs.update_list()
    end)("configs", "config_antiaim", ts.is_config)

    menu.button(groups.antiaim)("\v?\r Export", function()
        local key = menu.elements["configs"]["configs_list"] + 1

        configs.export(key)
        configs.update_list()
    end)("configs", "config_export", ts.is_config)

    menu.button(groups.antiaim)("\v?\r Import", function()
        configs.import()
        configs.update_list()
    end)("configs", "config_import", ts.is_config)

    menu.button(groups.antiaim)("\v?\r Save", function()
        local key = menu.elements["configs"]["configs_list"] + 1

        configs.save(key)
        configs.update_list()
    end)("configs", "config_save", ts.is_config)

    menu.button(groups.antiaim)("\v?\r Delete", function()
        local key = menu.elements["configs"]["configs_list"] + 1

        configs.remove(key)
        configs.update_list()
    end)("configs", "config_delete", ts.is_config)

    configs.create_default()
    configs.update_list()
end
-- #endregion

local function rgba(r, g, b, a, ...)
    return ("\a%x%x%x%x"):format(r, g, b, a) .. ...
end

local notify = (function()
    local vector = vector

    local function lerp(from, to, factor)
        return from + (to - from) * factor
    end

    local function get_screen_size()
        return vector(client.screen_size())
    end

    local function measure_text(flags, ...)
        local text_parts = { ... }
        local text = table.concat(text_parts, "")
        return vector(renderer.measure_text(flags, text))
    end

    local NotificationSystem = {
        notifications = { bottom = {} },
        max = { bottom = 10 },
        preview_notifications = {},
    }

    NotificationSystem.__index = NotificationSystem

    -- throttle handler to reduce per-frame cost
    local _last_notify_time = 0

    function NotificationSystem.new_preview(r, g, b, ...)
        table.insert(NotificationSystem.preview_notifications, {
            instance = setmetatable({
                active = true,
                color = { r = r, g = g, b = b, a = 0 },
                x = get_screen_size().x / 2,
                y = get_screen_size().y,
                text = ...,
                is_preview = true,
            }, NotificationSystem),
        })
    end

    function NotificationSystem:get_text()
        local result = ""
        for _, text_part in pairs(self.text) do
            local text_content, is_accent = text_part[1], text_part[2]
            local r, g, b = 255, 255, 255
            if is_accent then
                r, g, b = 255, 170, 220
            end
            result = result
                .. ("\a%02x%02x%02x%02x%s"):format(
                    r,
                    g,
                    b,
                    self.color.a,
                    text_content
                )
        end
        return result
    end

    function NotificationSystem.new_bottom(r, g, b, ...)
        table.insert(NotificationSystem.notifications.bottom, {
            started = false,
            instance = setmetatable({
                active = true,
                delay = 0,
                is_preview = false,
                color = { r = r, g = g, b = b, a = 0 },
                text = ...,
            }, NotificationSystem),
        })
    end

    function NotificationSystem:render_bottom(index, total_count)
        local screen_size = get_screen_size()

        local margin = 6
        local padding = 5
        local spacing = 5
        local rounding = 1
        local frame_time = globals.frametime()

        local text_content = self:get_text()
        local text_size = measure_text("", text_content)
        local cabbtral_size = measure_text("", "cabbtral.fun")

        local visual_width =
            math.max(80, margin + cabbtral_size.x + 10 + text_size.x)
        local visual_height = 25

        local x = screen_size.x / 2 - visual_width / 2
        local offset_y = menu.refs.visuals.notify_offset_y
                and menu.refs.visuals.notify_offset_y:get()
            or 0
        local base_offset = 200

        local y = screen_size.y
            - base_offset
            + offset_y
            - (index - 1) * (visual_height + spacing)

        self.anim = self.anim or 0

        local target = (self.color.a > 5) and 1 or 0
        self.anim = lerp(self.anim, target, frame_time * 8)

        local anim_width = visual_width * self.anim
        local anim_x = x + (visual_width - anim_width) / 2

        local menu_open = ui.is_menu_open()
        if self.is_preview then
            self.color.a =
                lerp(self.color.a, menu_open and 255 or 0, frame_time * 7)
        else
            if not self.started then
                self.started = true
                self.delay = globals.realtime() + 5
            end
            if globals.realtime() < self.delay then
                self.color.a = lerp(self.color.a, 255, frame_time * 2)
            else
                self.color.a = lerp(self.color.a, 0, frame_time * 20)
                if self.color.a <= 1 then
                    self.active = false
                end
            end
        end

        local r, g, b, a =
            self.color.r, self.color.g, self.color.b, self.color.a

        renderer.rectangle(
            x + 4 + rounding,
            y,
            visual_width - rounding - rounding,
            rounding,
            10,
            10,
            10,
            240
        )
        renderer.rectangle(
            x + 4,
            y + rounding,
            visual_width,
            visual_height - rounding * 2,
            10,
            10,
            10,
            240
        )
        renderer.rectangle(
            x + 4 + rounding,
            y + visual_height - rounding,
            visual_width - rounding - rounding,
            rounding,
            10,
            10,
            10,
            240
        )
        renderer.gradient(
            x + 3 + rounding,
            y,
            visual_width - rounding - rounding + 2,
            10,
            70,
            70,
            70,
            240,
            10,
            10,
            10,
            240,
            false
        )

        renderer.text(
            x + padding + 5,
            y + visual_height / 2 - cabbtral_size.y / 2,
            150, 150, 204,
            a,
            "",
            nil,
            "cabbtral.fun"
        )
        renderer.text(
            x + padding + cabbtral_size.x + 10,
            y + visual_height / 2 - text_size.y / 2,
            r,
            g,
            b,
            a,
            "",
            nil,
            text_content
        )
    end

    function NotificationSystem:handler()
        local menu_open = ui.is_menu_open()

        -- only run full handler at ~60/ (0.06s) frequency unless menu preview is active
        local now = globals.realtime()
        if not menu_open and #self.preview_notifications == 0 and now - _last_notify_time < 0.06 then
            return
        end
        _last_notify_time = now

        if menu_open and #self.preview_notifications > 0 then
            for i = #self.notifications.bottom, 1, -1 do
                self.notifications.bottom[i].instance.active = false
            end
        end

        for i = #self.notifications.bottom, 1, -1 do
            if not self.notifications.bottom[i].instance.active then
                table.remove(self.notifications.bottom, i)
            end
        end

        local active_count = 0
        for _, data in ipairs(self.notifications.bottom) do
            if data.instance.active then
                active_count = active_count + 1
            end
        end
        for index, data in ipairs(self.notifications.bottom) do
            if index > self.max.bottom then
                break
            end
            if data.instance.active then
                data.instance:render_bottom(index, active_count)
            end
        end

        if menu_open and #self.preview_notifications > 0 then
            for index, data in ipairs(self.preview_notifications) do
                data.instance:render_bottom(index, #self.preview_notifications)
            end
        end
    end

    client.set_event_callback("paint_ui", function()
        NotificationSystem:handler()
    end)

    return NotificationSystem
end)()


events.predict_command:set(function()
    if menu.elements["main"]["debug"] and DEBUG then
        if exploit.defensive then
            print_raw("invalidating ticks: ".. exploit.diff .."")
        end
    end
end)

-- #region : antiaim
local antiaim = {
    data = {
        inverter = false,
        ticks = 0,
        way = 0,
    },
    defensive = {
        ticks = 0,
        switch = 0,
    },
    elements = {},
    state = -1,
    states_names = {
        "Shared",
        "Standing",
        "Running",
        "Walking",
        "Crouching",
        "Sneaking",
        "Air",
        "Air & Crouch",
        "Freestanding",
        "Manual Yaw",
    },
}
do
    antiaim.manuals = {}
    do
        local manuals = antiaim.manuals

        manuals.yaw_offset = 0
        manuals.yaw_list = {
            ["left_bind"] = -90,
            ["right_bind"] = 90,
            ["forward_bind"] = 180,
            ["backwards_bind"] = 0,
        }

        menu.hotkey(groups.antiaim)("\v•\r  Freestanding")(
            "antiaim",
            "freestanding_bind", ts.is_hotkeys)
        menu.hotkey(groups.antiaim)("\v•\r  Edge yaw")(
            "antiaim",
            "edge_yaw_bind", ts.is_hotkeys)

        menu.label(groups.antiaim)("\226\128\142")("main", "blank67", ts.is_hotkeys)

        menu.hotkey(groups.antiaim)("\v•\r  Manual Left")(
            "antiaim",
            "left_bind", ts.is_hotkeys)
        menu.hotkey(groups.antiaim)("\v•\r  Manual Right")(
            "antiaim",
            "right_bind", ts.is_hotkeys)
        menu.hotkey(groups.antiaim)("\v•\r  Manual Forward")(
            "antiaim",
            "forward_bind", ts.is_hotkeys)
        menu.hotkey(groups.antiaim)("\v•\r  Manual Backwards")(
            "antiaim",
            "backwards_bind", ts.is_hotkeys)

        manuals.handle = function(new_config)
manuals.prev_value = manuals.prev_value or {}

manuals.yaw_offset = 0

for dir, yaw in pairs(manuals.yaw_list) do
    local ref = menu.refs["antiaim"][dir]
    if not ref then goto continue end

    local active = ref:get()

    if active then
        manuals.yaw_offset = yaw
        break
    end

    ::continue::
end




            new_config.yaw_base = menu.elements["antiaim"]["yaw_base"]
            new_config.fakelag = menu.elements["antiaim"]["fakelag_master"]
            new_config.fakelag_amount = menu.elements["antiaim"]["fakelag_amount"]
            new_config.fakelag_variance = menu.elements["antiaim"]["fakelag_variance"]
            new_config.fakelag_limit = menu.elements["antiaim"]["fakelag_limit"]
            new_config.yaw_offset =
            math.normalize_yaw(new_config.yaw_offset + manuals.yaw_offset)   
    local fs_checkbox, fs_bind = ui.reference("AA", "Anti-aimbot angles", "Freestanding")
                if manuals.yaw_offset == 0 and menu.refs["antiaim"]["freestanding_bind"]:get() then
        refs.antiaim.freestanding:set(true)
        ui.set(fs_bind, "always on")
    else
        refs.antiaim.freestanding:set(false)
        ui.set(fs_bind, "always on")
    end
            new_config.edge_yaw = manuals.yaw_offset == 0 and menu.refs["antiaim"]["edge_yaw_bind"]:get()
        end

        menu.combobox(groups.antiaim)(
            "\v•\r  Yaw Base",
            { "Local View", "At Targets" }
        )("antiaim", "yaw_base", ts.is_antiaim)
        menu.label(groups.antiaim)("\n")(
            "antiaim",
            "manuals_space",
            ts.is_antiaim
        )
        menu.checkbox(groups.antiaim)("Fakelag")("antiaim", "fakelag_master", ts.is_antiaim)

        menu.combobox(groups.antiaim)(
            "Fakelag Amount",
            {
                "Dynamic",
                "Maximum",
                "Fluctuate",
            }
        )("antiaim", "fakelag_type", function()
            return ts.is_antiaim() and menu.elements["antiaim"]["fakelag_master"]
        end)
        menu.slider(groups.antiaim)("Fakelag variance", 0, 100, 100, true, "%", 1)("antiaim", "fakelag_variance", function()
            return ts.is_antiaim() and menu.elements["antiaim"]["fakelag_master"]
        end)

        menu.slider(groups.antiaim)("Fakelag limit",1, 15, 1, true, "t", 1)("antiaim", "fakelag_limit", function()
            return ts.is_antiaim() and menu.elements["antiaim"]["fakelag_master"]
        end)
    end

--[[    antiaim.antibrute = {}
    do
        local evaded_callbacks = {}
        evaded_callbacks.on_evade = function(data) end

        local distance = function(x1, y1, z1, x2, y2, z2)
            return math.sqrt((x1 - x2) ^ 2 + (y1 - y2) ^ 2 + (z1 - z2) ^ 2)
        end

        local function get_camera_pos(ent)
            local x, y, z = entity.get_origin(ent)
            if not x then
                return
            end
            local _, _, ofs = entity.get_prop(ent, "m_vecViewOffset")
            z = z + (ofs - entity.get_prop(ent, "m_flDuckAmount") * 16)
            return x, y, z
        end

        local function fired_at(target, shooter, shot)
            local cam = { get_camera_pos(shooter) }
            if not cam[1] then
                return
            end

            local head = { entity.hitbox_position(target, 0) }
            if not head[1] then
                return
            end

            local A = {
                head[1] - cam[1],
                head[2] - cam[2],
                head[3] - cam[3],
            }

            local B = {
                shot[1] - cam[1],
                shot[2] - cam[2],
                shot[3] - cam[3],
            }

            local magic = (A[1] * B[1] + A[2] * B[2] + A[3] * B[3])
                / (B[1] ^ 2 + B[2] ^ 2 + B[3] ^ 2)

            local closest = {
                cam[1] + B[1] * magic,
                cam[2] + B[2] * magic,
                cam[3] + B[3] * magic,
            }

            local len = distance(
                head[1],
                head[2],
                head[3],
                closest[1],
                closest[2],
                closest[3]
            )

            local frac1 = client.trace_line(
                shooter,
                shot[1],
                shot[2],
                shot[3],
                head[1],
                head[2],
                head[3]
            )
            local frac2 = client.trace_line(
                target,
                closest[1],
                closest[2],
                closest[3],
                head[1],
                head[2],
                head[3]
            )

            return (len < 69) and (frac1 > 0.99 or frac2 > 0.99)
        end

        local last_tick = -1

        client.set_event_callback("bullet_impact", function(ev)
            if not menu.elements["antiaim"]["antibrute"] then
                return
            end

            local lp = entity.get_local_player()
            if not lp then
                return
            end

            local attacker = client.userid_to_entindex(ev.userid)
            if attacker == nil or attacker == lp then
                return
            end
            if not entity.is_enemy(attacker) then
                return
            end
            if not entity.is_alive(lp) then
                return
            end

            if fired_at(lp, attacker, { ev.x, ev.y, ev.z }) then
                if globals.tickcount() ~= last_tick then
                    last_tick = globals.tickcount()

                    evaded_callbacks.on_evade({
                        shooter = attacker,
                        tick = last_tick,
                        time = globals.curtime(),
                    })
                end
            end
        end)


local function ab_roll()
    return math.randomized(1, 8)
end

local function ab_direction()
    local r = math.randomized(-1, 1)
    if r == 0 then return ab_direction() end
    return r
end

local function ab_apply(value, method)
    if method == "Increase" then
        return value + ab_roll()
    elseif method == "Decrease" then
        return value - ab_roll()
    elseif method == "Randomize" then
        return ab_direction() == 1 and (value + ab_roll()) or (value - ab_roll())
    end
    return value
end

antiaim.antibrute = {
    triggered = false,
    method = nil
}
        evaded_callbacks.on_evade = function(data)
            local attacker_index = data.shooter
            local attacker_name = entity.get_player_name(attacker_index)
                or "Unknown"
            local method = math.randomized(1, 8)
            local ab_message = string.format(
                "antiaim changed due to %s's shot (method: %s)",
                attacker_name,
                method
            )
            notify.new_bottom(255, 255, 255, { { ab_message, false } })

            db.data.stats.evaded = db.data.stats.evaded + 1
        end

        menu.checkbox(groups.other)("Antibrute")(
            "antiaim",
            "antibrute",
            ts.is_antiaim
        )

        menu.combobox(groups.other)("Method", {"Increase", "Decrease", "Randomize"})("antiaim", "abmethods", function() return
            ts.is_antiaim() and menu.elements["antiaim"]["antibrute"]
        end)

        menu.multiselect(groups.other)("To change", {"Offset", "Delay"})("antiaim", "abchangers", function() return
            ts.is_antiaim() and menu.elements["antiaim"]["antibrute"]
        end)

    end --]]

    antiaim.unmatched = {}
    do
        local unmatched = antiaim.unmatched

        unmatched.handle = function()
            if not menu.elements["antiaim"]["unmatched"] then
                return
            end

            if menu.refs["antiaim"]["disabledef"]:get() or menu.elements["antiaim"]["disable"] then
                exploit.defensive = false
            end
        end

        menu.checkbox(groups.antiaim)("\vUnmatched\r Features")("antiaim", "unmatched", ts.is_antiaim)
        menu.checkbox(groups.antiaim)("Disable \vDefensive")("antiaim", "disable", function() return ts.is_antiaim() and menu.elements["antiaim"]["unmatched"] end)
        menu.hotkey(groups.antiaim)("Hotkey")("antiaim", "disabledef", function() return ts.is_antiaim() and menu.elements["antiaim"]["unmatched"] end)

        client.set_event_callback("predict_command", function()
            unmatched.handle()
        end)

    end

    antiaim.on_use = {}
    do
        local on_use = antiaim.on_use

        on_use.start_time = globals.realtime()

        on_use.handle = function(cmd, new_config)
            if not menu.elements["antiaim"]["on_use"] then
                return
            end

            if cmd.in_use == 0 then
                on_use.start_time = globals.realtime()
                return
            end

            local is_ct = entity.get_prop(my.entity, "m_iTeamNum") == 3

            local CPlantedC4 = entity.get_all("CPlantedC4")
            local m_bIsGrabbingHostage =
                entity.get_prop(my.entity, "m_bIsGrabbingHostage")

            if is_ct then
                if #CPlantedC4 > 0 then
                    local bomb = CPlantedC4[#CPlantedC4]
                    local bomb_origin =
                        vector(entity.get_prop(bomb, "m_vecOrigin"))

                    local dist = my.origin:dist(bomb_origin)

                    if dist < 65 then
                        return
                    end
                end
            end

            if m_bIsGrabbingHostage == 1 then
                return
            end

            if cmd.in_use == 1 then
                if globals.realtime() - on_use.start_time < 0.02 then
                    return
                end
            end

            cmd.in_use = 0

            new_config.pitch = "Off"
            new_config.yaw_base = "Local view"
            new_config.yaw_offset = 180
            new_config.freestanding = false
            new_config.edge_yaw = false

            cmd.force_defensive = false
        end

        menu.checkbox(groups.antiaim)("Allow On Use")(
            "antiaim",
            "on_use",
            ts.is_antiaim
        )
    end

    antiaim.avoid_backstab = {}
    do
        local avoid_backstab = antiaim.avoid_backstab

        avoid_backstab.handle = function(cmd, new_config)
            if not menu.elements["antiaim"]["avoid_backstab"] then
                return
            end

            if my.threat == nil then
                return
            end

            local threat_weapon = entity.get_player_weapon(my.threat)

            if threat_weapon == nil then
                return
            end

            local threat_origin =
                vector(entity.get_prop(my.threat, "m_vecOrigin"))

            local dist = my.origin:dist(threat_origin)

            if
                dist < 300
                and entity.get_classname(threat_weapon) == "CKnife"
            then
                new_config.yaw_base = "At targets"
                new_config.yaw_offset =
                    math.normalize_yaw(new_config.yaw_offset + 180)

                cmd.force_defensive = false
            end
        end

        menu.checkbox(groups.antiaim)("Avoid Backstab")(
            "antiaim",
            "avoid_backstab",
            ts.is_antiaim
        )
    end

    antiaim.warmup_modify = {}
    do
        local warmup_modify = antiaim.warmup_modify

        warmup_modify.handle = function(cmd, new_config)
            if not menu.elements["antiaim"]["warmup_modify"] then
                return
            end

            local is_warmup = entity.get_prop(
                entity.get_game_rules(),
                "m_bWarmupPeriod"
            ) == 1
            local is_enemy = false
            entity.get_players(true, true, function(ctx)
                if entity.is_alive(ctx) then
                    is_enemy = true
                end
            end)

            if not is_warmup and is_enemy then
                return
            end
            if menu.refs["antiaim"]["warmup_modify_speed"]:get() == "Fast" then
                new_config.pitch = "Custom"
                new_config.pitch_offset = -15
                new_config.yaw_offset =
                    math.normalize_yaw(globals.tickcount() * 35)
                new_config.body_yaw = "Off"
                new_config.freestanding = false
                new_config.edge_yaw = false
                new_config.fakelag = false

                cmd.force_defensive = false
            elseif
                menu.refs["antiaim"]["warmup_modify_speed"]:get() == "Slow"
            then
                new_config.pitch = "Custom"
                new_config.pitch_offset = -15
                new_config.yaw_offset =
                    math.normalize_yaw(globals.tickcount() * 4)
                new_config.body_yaw = "Off"
                new_config.freestanding = false
                new_config.edge_yaw = false
                new_config.fakelag = false

                cmd.force_defensive = false
            end
        end

        menu.checkbox(groups.antiaim)("Warmup/Enemy Modify")(
            "antiaim",
            "warmup_modify",
            ts.is_antiaim
        )
        menu.combobox(groups.antiaim)("Speed", { "Fast", "Slow" })(
            "antiaim",
            "warmup_modify_speed", function() return 
            ts.is_antiaim() and menu.elements["antiaim"]["warmup_modify"]
            end)
    end

    antiaim.safe_head = {}
    do
        local safe_head = antiaim.safe_head

        safe_head.conditions = {
            ["Standing"] = function()
                return my.state == my.states.standing
            end,
            ["Crouching"] = function()
                return my.state == my.states.crouch
            end,
            ["Sneaking"] = function()
                return my.state == my.states.sneak
            end,
            ["Air"] = function()
                return my.state == my.states.air
            end,
            ["Air & Crouch"] = function()
                return my.state == my.states.air_crouch
            end,
            ["Air Knife"] = function(weapon)
                return my.state == my.states.air_crouch
                    and entity.get_classname(weapon) == "CKnife"
            end,
            ["Air Taser"] = function(weapon)
                return my.state == my.states.air_crouch
                    and entity.get_classname(weapon) == "CWeaponTaser"
            end,
        }

        safe_head.handle = function(cmd, new_config)
            local safe_head_enable = menu.elements["antiaim"]["safe_head"]
            local safe_head_conditions =
                menu.elements["antiaim"]["safe_head_conditions"]
            local safe_head_height =
                menu.elements["antiaim"]["safe_head_height"]
            local safe_head_spam = menu.elements["antiaim"]["safe_head_spam"]

            if not safe_head_enable then
                return
            end

            if my.threat == nil then
                return
            end

            local threat_origin =
                vector(entity.get_prop(my.threat, "m_vecOrigin"))

            local weapon = entity.get_player_weapon(my.entity)

            if weapon == nil then
                return
            end

            local height_difference = my.origin.z - threat_origin.z
                > safe_head_height

            if safe_head_height ~= 0 and not height_difference then
                return
            end

            for state, trigger in pairs(safe_head.conditions) do
                if safe_head_conditions[state] and trigger(weapon) then
                    if safe_head_spam then
                        new_config.pitch = "Custom"
                        new_config.pitch_offset = exploit.defensive and 0 or 89
                        new_config.yaw_base = "At targets"
                        new_config.yaw_offset = exploit.defensive and 180 or 0
                        new_config.body_yaw = "Static"
                        new_config.body_yaw_offset = -1
                        new_config.freestanding = false
                        new_config.edge_yaw = false

                        cmd.force_defensive = true
                    else
                        new_config.pitch = "Minimal"
                        new_config.yaw_base = "At targets"
                        new_config.yaw_offset = 0
                        new_config.body_yaw = "Static"
                        new_config.body_yaw_offset = 0
                        new_config.freestanding = false
                        new_config.edge_yaw = false
                    end
                end
            end
        end

        menu.checkbox(groups.antiaim)("Safe Head")(
            "antiaim",
            "safe_head",
            ts.is_antiaim
        )

        menu.checkbox(groups.antiaim)("\f<p>  E-Spam")(
            "antiaim",
            "safe_head_spam",
            function()
                return ts.is_antiaim() and menu.elements["antiaim"]["safe_head"]
            end
        )

        menu.multiselect(groups.antiaim)("\f<p>  Conditions", {
            "Standing",
            "Crouching",
            "Sneaking",
            "Air",
            "Air & Crouch",
            "Air Knife",
            "Air Taser",
        })("antiaim", "safe_head_conditions", function()
            return ts.is_antiaim() and menu.elements["antiaim"]["safe_head"]
        end)

        menu.slider(groups.antiaim)(
            "\f<p>  Height",
            0,
            100,
            45,
            true,
            "ft",
            1,
            { [0] = "None" }
        )("antiaim", "safe_head_height", function()
            return ts.is_antiaim() and menu.elements["antiaim"]["safe_head"]
        end)
    end

    antiaim.fakeflick = {}
    do
        local fakeflick = antiaim.fakeflick
        fakeflick.get_yaw = function(cmd)
            local me = entity.get_local_player()
            if my.threat == nil then
                return
            end
            local yaw = menu.elements["antiaim"]["fakeflick_yaw"]

            local side = (entity.get_prop(me, "m_nTickBase") % 6) > 2 and 1
                or -1

            local enemy = vector(entity.get_prop(my.threat, "m_vecOrigin"))
            local me = vector(entity.get_prop(my.entity, "m_vecOrigin"))
            if menu.elements["antiaim"]["fakeflick_invert"] then
                return enemy.x - me.x > 0 and yaw
                    or enemy.x - me.x < 0 and -yaw
                    or enemy.x - me.x == 0 and 180
            end

            return yaw * side
        end
        menu.checkbox(groups.antiaim)("Fake Flick")(
            "antiaim",
            "fakeflick",
            ts.is_antiaim
        )
        menu.slider(groups.antiaim)("\f<p>  Yaw", 0, 180, 0, true, "°")(
            "antiaim",
            "fakeflick_yaw",
            function()
                return ts.is_antiaim() and menu.elements["antiaim"]["fakeflick"]
            end
        )
        menu.checkbox(groups.antiaim)("\f<p>  Auto Invert")(
            "antiaim",
            "fakeflick_invert",
            function()
                return ts.is_antiaim() and menu.elements["antiaim"]["fakeflick"]
            end
        )
        fakeflick.handle = function(cmd, new_config)
            if not exploit.defensive then
                return
            end
            if not menu.elements["antiaim"]["fakeflick"] then
                return
            end
            if my.threat == nil then
                return
            end
            new_config.pitch = "Custom"
            new_config.pitch_offset = cmd.command_number % 32 < 16 and -45 or 0
            new_config.yaw_base = "At targets"
            new_config.yaw_offset = (
                fakeflick.get_yaw(cmd)
                + math.random(-20, 20)
                + 180
            )
                    % -360
                + 180
            new_config.body_yaw = "Static"
            new_config.body_yaw_offset = 1
            new_config.freestanding = false
            new_config.edge_yaw = false
            if cmd.command_number % 7 == 0 then
                cmd.force_defensive = true
                cmd.allow_send_packet = false
            end
        end
    end

    menu.combobox(groups.antiaim)(
        "\v•\r  State",
        antiaim.states_names,
        nil,
        false
    )("antiaim", "state", ts.is_antiaim2)
    menu.label(groups.antiaim)("\n")("antiaim", "states_space", ts.is_antiaim2)

    for key, state in pairs(antiaim.states_names) do
        antiaim.elements[key], sd, ds = {}, "\aFFFFFF00_" .. state, "_" .. state

        local ctx = antiaim.elements[key]

        local is_legacy = function()
            return ts.is_antiaim2()
                and (key == 1 or ctx["allow_legacy"].value)
                and menu.elements["antiaim"]["state"] == state
        end

        local is_defensive = function()
            return ts.is_antiaim2()
                and ctx["defensive_switch"].value
                and menu.elements["antiaim"]["state"] == state
        end

        if key ~= 1 then
            ctx.allow_legacy = menu.checkbox(groups.antiaim)(
                ("Allow \v%s"):format(state)
            )("antiaim", "allow_legacy" .. ds, function()
                return ts.is_antiaim2()
                    and menu.elements["antiaim"]["state"] == state
            end)
        end

        ctx.yaw_offset = menu.slider(groups.antiaim)(
            "Yaw Offset" .. sd,
            -180,
            180,
            0,
            true,
            "°"
        )("antiaim", "yaw_offset" .. ds, is_legacy)
        ctx.yaw_add = menu.checkbox(groups.antiaim)("Yaw Add" .. sd)(
            "antiaim",
            "yaw_add" .. ds,
            is_legacy
        )
        ctx.left_offset = menu.slider(groups.antiaim)(
            "\f<p>  Left/Right \aCDCDCD40Offset" .. sd,
            -180,
            180,
            0,
            true,
            "°"
        )("antiaim", "left_offset" .. ds, function()
            return is_legacy() and ctx["yaw_add"].value
        end)
        ctx.right_offset = menu.slider(groups.antiaim)(
            "\n" .. sd,
            -180,
            180,
            0,
            true,
            "°"
        )("antiaim", "right_offset" .. ds, function()
            return is_legacy() and ctx["yaw_add"].value
        end)

        ctx.yaw_modifier = menu.checkbox(groups.antiaim)("Yaw Modifier" .. sd)(
            "antiaim",
            "yaw_modifier" .. ds,
            is_legacy
        )
        ctx.yaw_modifier_mode = menu.combobox(groups.antiaim)(
            "\f<p>  Mode" .. sd .. "_yaw_modifier",
            {
                "Center",
                "Center v2",
                "Random",
                "X-Way",
                "Custom jitter",
                "CABBITBOMBA",
            }
        )("antiaim", "yaw_modifier_mode" .. ds, function()
            return is_legacy() and ctx.yaw_modifier.value
        end)
        ctx.yaw_modifier_ways = menu.slider(groups.antiaim)(
            "\f<p>  Ways" .. sd .. "_yaw_modifier",
            3,
            7,
            3
        )("antiaim", "yaw_modifier_ways" .. ds, function()
            return is_legacy()
                and ctx.yaw_modifier.value
                and ctx.yaw_modifier_mode.value == "X-Way"
        end)
        ctx.yaw_modifier_offset = menu.slider(groups.antiaim)(
            "\f<p>  Offset" .. sd .. "_yaw_modifier",
            -90,
            90,
            0,
            true,
            "°"
        )("antiaim", "yaw_modifier_offset" .. ds, function()
            return is_legacy()
                and ctx.yaw_modifier.value
        end)

        ctx.body_yaw = menu.checkbox(groups.antiaim)("Body Yaw" .. sd)(
            "antiaim",
            "body_yaw" .. ds,
            is_legacy
        )
        ctx.body_yaw_mode = menu.combobox(groups.antiaim)(
            "\f<p>  Mode" .. sd,
            { "Static", "Jitter", "Randomize Jitter" }
        )("antiaim", "body_yaw_mode" .. ds, function()
            return is_legacy() and ctx.body_yaw.value
        end)

        ctx.invert_chance = menu.slider(groups.antiaim)(
            "\f<p>  Invert Chance" .. sd .. "_invert_chance",
            0,
            100,
            100,
            true,
            "%"
        )("antiaim", "invert_chance" .. ds, function()
            return is_legacy()
                    and ctx.body_yaw.value
                    and ctx["body_yaw_mode"].value == "Jitter"
                or is_legacy()
                    and ctx.body_yaw.value
                    and ctx["body_yaw_mode"].value == "Randomize Jitter"
        end)

        ctx.body_yaw_offset = menu.slider(groups.antiaim)(
            "\f<p>  Offset" .. sd .. "_body_yaw",
            -180,
            180,
            0,
            true,
            "°"
        )("antiaim", "body_yaw_offset" .. ds, function()
            return is_legacy()
                and ctx.body_yaw.value
                and ctx["body_yaw_mode"].value == "Static"
        end)

        ctx.delay = menu.slider(groups.antiaim)(
            "\f<p>  Delay" .. sd,
            1,
            14,
            2,
            true,
            "t",
            1,
            { [1] = "Off" }
        )("antiaim", "delay_ticks" .. ds, function()
            return is_legacy()
                and ctx.body_yaw.value
                and ctx["body_yaw_mode"].value == "Jitter"
        end)

        ctx.min_delay = menu.slider(groups.antiaim)(
            "\f<p>  Min. Delay" .. sd,
            1,
            14,
            2,
            true,
            "t"
        )("antiaim", "min_delay" .. ds, function()
            return is_legacy()
                and ctx.body_yaw.value
                and ctx["body_yaw_mode"].value == "Randomize Jitter"
        end)
        ctx.max_delay = menu.slider(groups.antiaim)(
            "\f<p>  Max. Delay" .. sd,
            1,
            14,
            2,
            true,
            "t"
        )("antiaim", "max_delay" .. ds, function()
            return is_legacy()
                and ctx.body_yaw.value
                and ctx["body_yaw_mode"].value == "Randomize Jitter"
        end)

        ctx.defensive_switch = menu.checkbox(groups.antiaim)(
            ("Allow Defensive on \v%s\r"):format(state)
        )("antiaim", "defensive_switch" .. ds, function()
            return ts.is_antiaim2()
                and menu.elements["antiaim"]["state"] == state and (state ~= "Shared" and ctx.allow_legacy.value)
        end)

        ctx.force_defensive = menu.checkbox(groups.antiaim)(
            "Force \vDefensive" .. sd
        )("antiaim", "force_defensive" .. ds, function()
            return ts.is_antiaim2()
                and menu.elements["antiaim"]["state"] == state and (state ~= "Shared" and ctx.allow_legacy.value)
        end)

        ctx.defensive_pitch = menu.combobox(groups.antiaim)(
            "Pitch" .. sd,
            { "Custom", "Random", "Randomize Jitter", "Spin" }
        )("antiaim", "defensive_pitch" .. ds, function()
            return is_defensive() and ctx.defensive_switch.value
        end)

        ctx.defensive_pitch_offset = menu.slider(groups.antiaim)(
            "\f<p>  Offset" .. sd .. "_pitch",
            -89,
            89,
            0,
            true,
            "°"
        )("antiaim", "defensive_pitch_offset" .. ds, function()
            local v = ctx.defensive_pitch:get()
            return is_defensive()
                and ctx.defensive_switch.value
                and (v == "Custom")
        end)

        ctx.defensive_pitch_min = menu.slider(groups.antiaim)(
            "\f<p>  Min. Offset" .. sd .. "_pitch",
            -89,
            89,
            0,
            true,
            "°"
        )("antiaim", "defensive_pitch_min" .. ds, function()
            return is_defensive()
                and ctx.defensive_switch.value
                and (
                    ctx["defensive_pitch"].value == "Jitter"
                    or ctx["defensive_pitch"].value == "Random"
                    or ctx["defensive_pitch"].value == "Randomize Jitter"
                    or ctx["defensive_pitch"].value == "Spin"
                )
        end)
        ctx.defensive_pitch_max = menu.slider(groups.antiaim)(
            "\f<p>  Max. Offset" .. sd .. "_pitch",
            -89,
            89,
            0,
            true,
            "°"
        )("antiaim", "defensive_pitch_max" .. ds, function()
            return is_defensive()
                and ctx.defensive_switch.value
                and (
                    ctx["defensive_pitch"].value == "Jitter"
                    or ctx["defensive_pitch"].value == "Random"
                    or ctx["defensive_pitch"].value == "Randomize Jitter"
                    or ctx["defensive_pitch"].value == "Spin"
                )
        end)

        ctx.defensive_yaw = menu.combobox(groups.antiaim)(
            "Yaw" .. sd,
            { "Custom", "Switch", "Random", "Spin", "Sway", "Left/Right" }
        )("antiaim", "defensive_yaw" .. ds, function()
            return is_defensive() and ctx.defensive_switch.value
        end)

        ctx.defensive_right_offset = menu.slider(groups.antiaim)(
            "\n" .. sd,
            -180,
            180,
            0,
            true,
            "°"
        )("antiaim", "defensive_right_offset" .. ds, function()
            return is_defensive()
                and ctx.defensive_switch.value
                and ctx["defensive_yaw"].value == "Left/Right"
        end)

        ctx.defensive_left_offset = menu.slider(groups.antiaim)(
            "\n" .. sd,
            -180,
            180,
            0,
            true,
            "°"
        )("antiaim", "defensive_left_offset" .. ds, function()
            return is_defensive()
                and ctx.defensive_switch.value
                and ctx["defensive_yaw"].value == "Left/Right"
        end)

        ctx.defensive_yaw_delay = menu.slider(groups.antiaim)(
            "\f<p>  Delay" .. sd .. "_yaw",
            1,
            30,
            2,
            true,
            "t"
        )("antiaim", "defensive_yaw_delay" .. ds, function()
            return is_defensive()
                and ctx.defensive_switch.value
                and ctx["defensive_yaw"].value == "Left/Right"
        end)

        ctx.defensive_yaw_offset = menu.slider(groups.antiaim)(
            "\f<p>  Offset" .. sd .. "_yaw",
            -180,
            180,
            0,
            true,
            "°"
        )("antiaim", "defensive_yaw_offset" .. ds, function()
            return is_defensive()
                and ctx.defensive_switch.value
                and ctx["defensive_yaw"].value == "Custom"
        end)

        ctx.defensive_yaw_speed = menu.slider(groups.antiaim)(
            "\f<p>  Speed" .. sd .. "_yaw",
            0,
            50,
            1,
            true,
            "°"
        )("antiaim", "defensive_yaw_speed" .. ds, function()
            return is_defensive()
                and ctx.defensive_switch.value
                and ctx["defensive_yaw"].value == "Sway"
        end)

        ctx.defensive_yaw_min = menu.slider(groups.antiaim)(
            "\f<p>  Min. Offset" .. sd .. "_yaw",
            -180,
            180,
            0,
            true,
            "°"
        )("antiaim", "defensive_yaw_min" .. ds, function()
            return is_defensive()
                and ctx.defensive_switch.value
                and (
                    ctx["defensive_yaw"].value == "Random"
                    or ctx["defensive_yaw"].value == "Sway"
                )
        end)

        ctx.defensive_yaw_max = menu.slider(groups.antiaim)(
            "\f<p>  Max. Offset" .. sd .. "_yaw",
            -180,
            180,
            0,
            true,
            "°"
        )("antiaim", "defensive_yaw_max" .. ds, function()
            return is_defensive()
                and ctx.defensive_switch.value
                and (
                    ctx["defensive_yaw"].value == "Random"
                    or ctx["defensive_yaw"].value == "Sway"
                )
        end)

        ctx.defensive_360_offset = menu.slider(groups.antiaim)(
            "\f<p>  Offset" .. sd .. "_yaw_360",
            0,
            360,
            180,
            true,
            "°"
        )("antiaim", "defensive_360_offset" .. ds, function()
            return is_defensive()
                and ctx.defensive_switch.value
                and (
                    ctx["defensive_yaw"].value == "Switch"
                    or ctx["defensive_yaw"].value == "Spin"
                )
        end)

        ctx.defensive_delay = menu.slider(groups.antiaim)(
            "\f<p>  Delay" .. sd .. "_delay",
            1,
            30,
            2,
            true,
            "t",
            1,
            { [1] = "Off" }
        )("antiaim", "defensive_delay" .. ds, function()
            return is_defensive()
                and ctx.defensive_switch.value
                and ctx["defensive_yaw"].value == "Switch"
        end)

    end

    antiaim.configs = {}
    do
        local configs = antiaim.configs

        local state_to_number = function(ref)
            local tbl = {}

            for k, v in pairs(antiaim.states_names) do
                tbl[v] = k
            end

            return tbl[ref]
        end

        configs.export = function(id)
            local data = {}

            for k, v in pairs(antiaim.elements[state_to_number(id)]) do
                data[k] = v:get()
            end

            return data
        end

        configs.import = function(id, data)
            for k, v in pairs(antiaim.elements[state_to_number(id)]) do
                if antiaim.elements[state_to_number(id)][k] ~= nil then
                    pcall(function()
                        v:set(data[k])
                    end)
                end
            end
        end

        configs.compile = function(data)
            if data == nil then
                print_raw("An error occured with config!")
                client.exec("play resource\\warning.wav")
                return
            end

            success, data = pcall(function()
                return base64.encode(json.stringify(data))
            end)

            if not success then
                print_raw("An error occured with config!")
                client.exec("play resource\\warning.wav")
                return
            end

            return ("%s::gs::state::%s"):format(
                cabbtral.name:lower(),
                data:gsub("=", "_"):gsub("+", "Z1337Z")
            )
        end

        configs.decompile = function(data)
            if data == nil then
                print_raw("An error occured with config!")
                client.exec("play resource\\warning.wav")
                return
            end

            if
                not data:find(("%s::gs::state::"):format(cabbtral.name:lower()))
            then
                print_raw("An error occured with config!")
                client.exec("play resource\\warning.wav")
                return
            end

            data = data
                :gsub(("%s::gs::state::"):format(cabbtral.name:lower()), "")
                :gsub("_", "=")
                :gsub("Z1337Z", "+")

            success, data = pcall(function()
                return json.parse(base64.decode(data))
            end)

            if not success then
                print_raw("An error occured with config!")
                pclient.exec("play resource\\warning.wav")
                return
            end

            return data
        end

        menu.label(groups.antiaim)("\nconfigs_space")(
            "antiaim",
            "configs_space",
            ts.is_antiaim2
        )

        menu.button(groups.antiaim)("\v?\r Export", function()
            local data = antiaim.configs.compile(
                antiaim.configs.export(menu.elements["antiaim"]["state"])
            )

            clipboard.set(data)

            print_raw(
                ("%s successfuly exported!"):format(
                    menu.elements["antiaim"]["state"]
                )
            )
            client.exec("play ui\\beepclear")
        end)("antiaim", "export", ts.is_antiaim2)

        menu.button(groups.antiaim)("\v?\r Import", function()
            local data = configs.decompile(clipboard.get())

            configs.import(menu.elements["antiaim"]["state"], data)

            print_raw(
                ("Successfuly imported to %s!"):format(
                    menu.elements["antiaim"]["state"]
                )
            )
            client.exec("play ui\\beepclear")
        end)("antiaim", "import", ts.is_antiaim2)
    end


    local toticks = function(time)
        if not time then return 0 end -- @note inshallah fix.
        return math.floor(0.5 + time / globals.tickinterval())
    end

    antiaim.restrict = function(new_config)
        local tmp = {
            ["Jitter"] = function()
                return new_config.delay
            end,
            ["Randomize Jitter"] = function()
                local min = new_config.min_delay
                local max = new_config.max_delay

                if min > max then
                    min, max = max, min
                end

                return math.randomized(min, max)
            end,
        }

        local delay = tmp[new_config.body_yaw_mode]

        if delay == 1 then
            return true
        end

        return antiaim.data.ticks % ((delay and delay()) or 0) == 0
    end

    antiaim.update_side = function(cmd, new_config)
        if cmd.chokedcommands == 0 then
            antiaim.data.ticks = antiaim.data.ticks + 1

            local invert_chance = new_config.invert_chance or 0
            local should_invert = false

            if antiaim.restrict(new_config) then
                if invert_chance > 0 then
                    if math.random(0, 100) <= invert_chance then
                        should_invert = true
                    end
                else
                    should_invert = true
                end
            end

            if should_invert then
                antiaim.data.inverter = not antiaim.data.inverter
            end

            local yaw_left = new_config.left_offset or 0
            local yaw_right = new_config.right_offset or 0
            local yaw_random = new_config.yaw_random or 0

            yaw_left = yaw_left + utils.random_float(-yaw_random, yaw_random)
            yaw_right = yaw_right + utils.random_float(-yaw_random, yaw_random)

            if antiaim.data.inverter then
                new_config.yaw_offset = yaw_right
            else
                new_config.yaw_offset = yaw_left
            end
        end
    end

    antiaim.set_default_yaw_offset = function(new_config)
        if not new_config.yaw_add then
            new_config.left_offset = 0
            new_config.right_offset = 0
        end

        new_config.yaw_offset = math.normalize_yaw(
            new_config.yaw_offset
                + (
                    antiaim.data.inverter and new_config.right_offset
                    or new_config.left_offset
                )
        )
        new_config.body_yaw = new_config.body_yaw and "Static" or "Off"
        new_config.body_yaw_offset = new_config.body_yaw_mode == "Static"
                and new_config.body_yaw_offset
            or (antiaim.data.inverter and 1 or -1)
    end

    antiaim.set_yaw_modifier = function(new_config)
        if not new_config.yaw_modifier then
            return
        end

        antiaim.data.way = antiaim.data.way < (new_config.yaw_modifier_ways - 1)
                and (antiaim.data.way + 1)
            or 0

        local tmp = {
            ["Center"] = antiaim.data.inverter
                    and -(new_config.yaw_modifier_offset * 0.5)
                or (new_config.yaw_modifier_offset * 0.5),
            ["Center v2"] = (
                (new_config.yaw_modifier_offset * 0.5)
                + (math.random() * 1.4 + 0.1)
            ) * (antiaim.data.inverter and -1 or 1),
            ["Random"] = math.random(0, new_config.yaw_modifier_offset),
            ["X-Way"] = math.lerp(
                0,
                new_config.yaw_modifier_offset,
                antiaim.data.way / (new_config.yaw_modifier_ways - 1)
            ),
            ["Custom jitter"] = (
                (
                    (
                        new_config.yaw_modifier_offset
                        * (0.2 + math.random() * 0.6)
                    ) * ((math.random() > 0.5) and -1 or 1)
                ) + ((math.random() - 0.5) * 3.8)
            ) * (antiaim.data.inverter and -1 or 1),
            ["CABBITBOMBA"] = (function()
                local ways = (math.random(0, 1) == 1) and 3 or 5

                local max_way = ways - 1
                local way_index = antiaim.data.way % ways

                local way_offset = math.lerp(
                    0,
                    antiaim.data.inverter and -new_config.yaw_modifier_offset
                        or new_config.yaw_modifier_offset,
                    way_index / max_way
                )

                local minv = new_config.yaw_modifier_min or 0
                local maxv = new_config.yaw_modifier_max or 0
                local rand_add =
                    utils.random_int(math.min(minv, maxv), math.max(minv, maxv))

                return way_offset + rand_add
            end)(),
        }

        new_config.yaw_offset = math.normalize_yaw(
            new_config.yaw_offset + tmp[new_config.yaw_modifier_mode]
        )
    end

    antiaim.defensive_restrict = function(new_config)
        local delay = new_config.defensive_delay

        if delay == 1 then
            return true
        end

        return antiaim.defensive.ticks % (delay or 0) == 0
    end

    antiaim.defensive_switch = function(cmd, new_config)
        if cmd.chokedcommands == 0 then
            antiaim.defensive.ticks = antiaim.defensive.ticks + 1

            if antiaim.defensive_restrict(new_config) then
                antiaim.defensive.switch = not antiaim.defensive.switch
            end
        end
    end

    antiaim.set_defensive_pitch = function(new_config)
        antiaim.data.way = antiaim.data.way < (new_config.yaw_modifier_ways - 1)
                and (antiaim.data.way + 1)
            or 0

        antiaim.data.pitch_step = (antiaim.data.pitch_step or 0) + 1
        if antiaim.data.pitch_step > 2 then
            antiaim.data.pitch_step = 0
        end

        local tmp = {
            ["Custom"] = new_config.defensive_pitch_offset,
            ["Random"] = client.random_float(
                new_config.defensive_pitch_min,
                new_config.defensive_pitch_max
            ),
            ["Randomize Jitter"] = client.random_int(0, 1) == 1
                    and new_config.defensive_pitch_min
                or new_config.defensive_pitch_max,
            ["Spin"] = math.lerp(
                new_config.defensive_pitch_min,
                new_config.defensive_pitch_max,
                globals.curtime() * 6 % 2 - 1
            ),
        }

        new_config.pitch = "Custom"
        new_config.pitch_offset =
            math.normalize_pitch(tmp[new_config.defensive_pitch])
    end

    antiaim.defensive_last_side = antiaim.defensive_last_side or true
    antiaim.defensive_tick_count = antiaim.defensive_tick_count or 0

    antiaim.set_defensive_yaw_offset = function(new_config)
        local tmp = {
            ["Custom"] = new_config.defensive_yaw_offset,
            ["Random"] = client.random_int(
                new_config.defensive_yaw_min,
                new_config.defensive_yaw_max
            ),
            ["Spin"] = 0.5 * math.lerp(
                -new_config.defensive_360_offset,
                new_config.defensive_360_offset,
                globals.curtime() * 3 % 2 - 1
            ),
            ["Switch"] = 0.5
                * (
                    antiaim.defensive.switch
                        and -new_config.defensive_360_offset
                    or new_config.defensive_360_offset
                ),
            ["Sway"] = (function()
                local speed = new_config.defensive_yaw_speed
                local yaw_l = new_config.defensive_yaw_min
                local yaw_r = new_config.defensive_yaw_max
                local t = globals.curtime() * speed * 0.1
                return utils.lerp(yaw_l, yaw_r, t % 1)
            end)(),

            ["Left/Right"] = (function()
                if not new_config.yaw_add then
                    new_config.defensive_left_offset = 0
                    new_config.defensive_right_offset = 0
                end

                local delay = new_config.defensive_yaw_delay or 2
                antiaim.defensive_tick_count = antiaim.defensive_tick_count + 1

                -- flip side only after full delay
                if antiaim.defensive_tick_count >= delay then
                    antiaim.defensive_last_side =
                        not antiaim.defensive_last_side
                    antiaim.defensive_tick_count = 0
                end

                return math.normalize_yaw(
                    antiaim.defensive_last_side
                            and new_config.defensive_left_offset
                        or new_config.defensive_right_offset
                )
            end)(),
        }

        new_config.body_yaw = "Static"
        new_config.body_yaw_offset = 1
        new_config.yaw_offset =
            math.normalize_yaw(tmp[new_config.defensive_yaw])
    end

    antiaim.defensive_config = function(cmd, new_config)
        if not new_config.force_defensive then
            return
        end

        cmd.force_defensive = true
    end

    antiaim.defensive_handle = function(cmd, new_config)
        if not exploit.active then
            return
        end

        antiaim.defensive_switch(cmd, new_config)
        antiaim.defensive_config(cmd, new_config)

        if new_config.defensive_switch and exploit.defensive then
            antiaim.set_defensive_pitch(new_config)
            antiaim.set_defensive_yaw_offset(new_config)
        end
    end

    antiaim.update_player_state = function(cmd)
        if
            menu.elements["antiaim"]["allow_legacy_Manual Yaw"]
            and antiaim.manuals.yaw_offset ~= 0
        then
            antiaim.state = my.states.manual_yaw
            return
        end

        if
            menu.elements["antiaim"]["allow_legacy_Freestanding"]
            and menu.refs["antiaim"]["freestanding_bind"]:get()
            and antiaim.manuals.yaw_offset == 0
        then
            antiaim.state = my.states.freestanding
            return
        end

        antiaim.state = my.state
    end

    antiaim.get_active = function(idx)
        local items = antiaim.elements[idx]

        if items ~= nil then
            if idx ~= 1 and items.allow_legacy:get() then
                return idx
            end
        end

        return 1
    end

    antiaim.get_state_values = function(idx)
        local items = antiaim.elements[idx]

        if items == nil then
            return
        end

        local new_config = {}

        for key, item in pairs(items) do
            new_config[key] = item:get()
        end

        return new_config
    end

    antiaim.set_ui = function(new_config)
        for key, value in pairs(new_config) do
            if refs.antiaim[key] ~= nil then
                refs.antiaim[key]:override(value)
            end
        end
    end

    antiaim.setup = function(new_config)
        new_config.antiaim_enabled = true
        new_config.pitch = "Down"
        new_config.pitch_offset = 89
        new_config.yaw = "180"
        new_config.yaw_jitter = "Off"
        new_config.yaw_jitter_offset = 0
    end

    antiaim.handle = function(cmd)
        if not cmd then return end

        if not my.valid and menu.elements["antiaim"]["update_event"] ~= "create_move" then
            return
        end

        antiaim.update_player_state(cmd)

        local current_condition = antiaim.get_active(antiaim.state)
        local new_config = antiaim.get_state_values(current_condition)

        antiaim.update_side(cmd, new_config)
        antiaim.setup(new_config)
        antiaim.set_default_yaw_offset(new_config)
        antiaim.set_yaw_modifier(new_config)
        antiaim.defensive_handle(cmd, new_config)
        antiaim.manuals.handle(new_config)
        antiaim.safe_head.handle(cmd, new_config)
        antiaim.on_use.handle(cmd, new_config)
        antiaim.avoid_backstab.handle(cmd, new_config)
        antiaim.warmup_modify.handle(cmd, new_config)

        antiaim.fakeflick.handle(cmd, new_config)
        antiaim.set_ui(new_config)
    end

events.setup_command:set(function(cmd)
    antiaim.handle(cmd)
end)

end

--
local widget = {}
do
    local mt
    do
        mt = {
            update = function(self)
                return 1
            end,
            handle = function(self) end,

            __call = function(self)
                self.alpha = self:update()

                render.push_alpha(self.alpha / 255)

                if self.alpha > 0 then
                    self:process(self)
                    self:handle(self)
                end

                render.pop_alpha()
            end,
        }
    end
    mt.__index = mt

    function widget:new(id, default, size, settings)
        drag:new(id, default, size, settings)

        return setmetatable(drag.data[id], mt)
    end
end
--

local rage = {}
do
    
    rage.resolver = {}
    do
        resolver = rage.resolver

        menu.checkbox(groups.antiaim)("\v° ? ? \rResolver")("visuals", "resolver", ts.is_rage)
    end

    rage.unsafe_charge = {}
    do
        local unsafe = rage.unsafe_charge

        unsafe.handle = function()
            local tickbase = entity.get_prop(
                entity.get_local_player(),
                "m_nTickBase"
            ) - globals.tickcount()
            local os_ref = refs.other.onshot.hotkey:get()
                and refs.other.onshot:get()
                and not refs.other.fake_duck:get()
            local doubletap_ref = refs.other.doubletap.hotkey:get()
                and refs.other.doubletap:get()
                and not refs.other.fake_duck:get()
            local active_weapon =
                entity.get_prop(entity.get_local_player(), "m_hActiveWeapon")

            if active_weapon == nil then
                return
            end

            local weapon_idx =
                entity.get_prop(active_weapon, "m_iItemDefinitionIndex")

            if weapon_idx == nil or weapon_idx == 64 then
                return
            end

            local last_shot = entity.get_prop(active_weapon, "m_fLastShotTime")

            local lshot = last_shot
            if last_shot == nil then
                lshot = 1
            end

            local single_fire_weapon = weapon_idx == 40
                or weapon_idx == 9
                or weapon_idx == 64
                or weapon_idx == 27
                or weapon_idx == 29
                or weapon_idx == 35
            local value = single_fire_weapon and 0 or 0.50
            local in_attack = globals.curtime() - lshot <= value

            if tickbase > 0 and os_ref then
                if in_attack then
                    refs.other.aimbot[1]:override(true)
                else
                    refs.other.aimbot[1]:override(false)
                end
            elseif tickbase > 0 and doubletap_ref then
                if in_attack then
                    refs.other.aimbot[1]:override(true)
                else
                    refs.other.aimbot[1]:override(false)
                end
            else
                refs.other.aimbot[1]:override(true)
            end
        end
     
        menu.checkbox(groups.antiaim)("Unsafe charge")(
            "visuals",
            "unsafe_charge",
            ts.is_rage
        )
        menu.refs["visuals"]["unsafe_charge"]:set_callback(function(this)
            local call = this:get() and client.set_event_callback
                or client.unset_event_callback
            call("setup_command", unsafe.handle)
        end)
    end

        rage.predict = {}
    do
    local predict = rage.predict

    --[[menu.checkbox(groups.antiaim)("Ascension of the \vCabbit gods\r")("visuals", "predict", ts.is_rage)
    menu.hotkey(groups.antiaim)("Ascend with \vme\r son")("visuals", "hotkey", function() return ts.is_rage() and menu.elements["visuals"]["predict"] end)
    menu.combobox(groups.antiaim)("Ping variations", { "Low", "High" })("visuals", "pingpos", function() return ts.is_rage() and menu.elements["visuals"]["predict"] end)
    menu.combobox(groups.antiaim)("\n", {"-", "AWP", "SCOUT", "AUTO", "R8"})("visuals", "selectgun", function() return ts.is_rage() and menu.elements["visuals"]["predict"] end)
    menu.combobox(groups.antiaim)("\n", {"Disabled", "Medium", "Maximum", "Extreme"})("visuals", "slideawp", function() return ts.is_rage() and menu.elements["visuals"]["predict"] and menu.elements["visuals"]["selectgun"] == "AWP" end)
    menu.combobox(groups.antiaim)("\n", {"Disabled", "Medium", "Maximum", "Extreme"})("visuals", "slidescout", function() return ts.is_rage() and menu.elements["visuals"]["predict"] and menu.elements["visuals"]["selectgun"] == "SCOUT" end)
    menu.combobox(groups.antiaim)("\n", {"Disabled", "Medium", "Maximum", "Extreme"})("visuals", "slideauto", function() return ts.is_rage() and menu.elements["visuals"]["predict"] and menu.elements["visuals"]["selectgun"] == "AUTO" end)
    menu.combobox(groups.antiaim)("\n", {"Disabled", "Medium", "Maximum", "Extreme"})("visuals", "slider8", function() return ts.is_rage() and menu.elements["visuals"]["predict"] and menu.elements["visuals"]["selectgun"] == "R8" end)
--]]

    menu.checkbox(groups.antiaim)("Better \vPredict \r")("visuals", "predict", ts.is_rage)
    menu.label(groups.antiaim)("\aFF4242FFIMPORTANT\r may \aFF4242FFnot\r work if u have a high ping diffrence ")("visuals", "predictlabel", ts.is_rage)
    menu.label(groups.antiaim)("between u and your enemies")("visuals", "predictlabel1", ts.is_rage)


    client.set_event_callback("setup_command", function(cmd)
        local lp = entity.get_local_player()
        if not lp then
            return
        end

        local gun = entity.get_player_weapon(lp)
        local skeetweapon = ui.get(refs.other.weapon_type)
        local weapon = menu.elements["visuals"]["selectgun"]
        local classname = gun and entity.get_classname(gun) or nil
        local is_crouching = cmd.in_duck == 1 or refs.other.fake_duck:get()
        local threat = client.current_threat()

        if not menu.elements["visuals"]["predict"] or not gun then
            return
        end

        if not threat then
            return
        end

        if not utils.is_fakeducking(threat) then
            return
        end

        if menu.elements["visuals"]["predict"] then
            if utils.is_fakeducking(threat) and is_crouching then
                if classname == "weapon_ssg08" then
                    cvar.cl_interp:set_float(0.029125)
                    cvar.cl_interp_ratio:set_int(0)
                    cvar.cl_interpolate:set_int(1)
                elseif classname == "weapon_awp" then
                    cvar.cl_interp:set_float(0.029125)
                    cvar.cl_interp_ratio:set_int(0)
                    cvar.cl_interpolate:set_int(1)
                elseif classname == "weapon_scar20" or classname == "weapon_g3sg1" then
                    cvar.cl_interp:set_float(0.029125)
                    cvar.cl_interp_ratio:set_int(0)
                    cvar.cl_interpolate:set_int(1)
                elseif classname == "weapon_revolver" then
                    cvar.cl_interp:set_float(0.031000)
                    cvar.cl_interp_ratio:set_int(0)
                    cvar.cl_interpolate:set_int(1)
                else
                    cvar.cl_interp:set_float(0.015625)
                    cvar.cl_interp_ratio:set_int(2)
                    cvar.cl_interpolate:set_int(1)
                end
            end
        end

        if menu.elements["visuals"]["predict"] then
            if is_crouching then
                if classname == "weapon_ssg08" then
                    cvar.cl_interp:set_float(0.029125)
                    cvar.cl_interp_ratio:set_int(0)
                    cvar.cl_interpolate:set_int(1)
                elseif classname == "weapon_awp" then
                    cvar.cl_interp:set_float(0.029125)
                    cvar.cl_interp_ratio:set_int(0)
                    cvar.cl_interpolate:set_int(1)
                elseif classname == "weapon_scar20" or classname == "weapon_g3sg1" then
                    cvar.cl_interp:set_float(0.031000)
                    cvar.cl_interp_ratio:set_int(0)
                    cvar.cl_interpolate:set_int(1)
                elseif classname == "weapon_revolver" then
                    cvar.cl_interp:set_float(0.031000)
                    cvar.cl_interp_ratio:set_int(0)
                    cvar.cl_interpolate:set_int(1)
                else
                    cvar.cl_interp:set_float(0.015625)
                    cvar.cl_interp_ratio:set_int(2)
                    cvar.cl_interpolate:set_int(1)
                end
            end
        end


        --[[if menu.elements["visuals"]["predict"] and menu.refs["visuals"]["hotkey"]:get() then
            if menu.elements["visuals"]["pingpos"] == "Low" then
                cvar.cl_interpolate:set_int(0)
                cvar.cl_interp_ratio:set_int(1)

                if classname == "CWeaponSSG08" then
                    if menu.elements["visuals"]["slidescout"] == "Disabled" then
                        cvar.cl_interp:set_float(0.015625)
                    end
                    if menu.elements["visuals"]["slidescout"] == "Medium" then
                        cvar.cl_interp:set_float(0.028000)
                    end
                    if menu.elements["visuals"]["slidescout"] == "Maximum" then
                        cvar.cl_interp:set_float(0.029125)
                    end
                    if menu.elements["visuals"]["slidescout"] == "Extreme" then
                        cvar.cl_interp:set_float(0.031000)
                    end
                end

                if classname == "CWeaponAWP" then
                    if menu.elements["visuals"]["slideawp"] == "Disabled" then
                        cvar.cl_interp:set_float(0.015625)
                    elseif menu.elements["visuals"]["slideawp"] == "Medium" then
                        cvar.cl_interp:set_float(0.028000)
                    elseif menu.elements["visuals"]["slideawp"] == "Maximum" then
                        cvar.cl_interp:set_float(0.029125)
                    elseif menu.elements["visuals"]["slideawp"] == "Extreme" then
                        cvar.cl_interp:set_float(0.031000)
                    end
                end

                if classname == "CWeaponSCAR20" or classname == "CWeaponG3SG1" then
                    if menu.elements["visuals"]["slideauto"] == "Disabled" then
                        cvar.cl_interp:set_float(0.015625)
                    elseif menu.elements["visuals"]["slideauto"] == "Medium" then
                        cvar.cl_interp:set_float(0.028000)
                    elseif menu.elements["visuals"]["slideauto"] == "Maximum" then
                        cvar.cl_interp:set_float(0.029125)
                    elseif menu.elements["visuals"]["slideauto"] == "Extreme" then
                        cvar.cl_interp:set_float(0.031000)
                    end
                end

                if classname == "CDEagle" then
                    if menu.elements["visuals"]["slider8"] == "Disabled" then
                        cvar.cl_interp:set_float(0.015625)
                    elseif menu.elements["visuals"]["slider8"] == "Medium" then
                        cvar.cl_interp:set_float(0.028000)
                    elseif menu.elements["visuals"]["slider8"] == "Maximum" then
                        cvar.cl_interp:set_float(0.029125)
                    elseif menu.elements["visuals"]["slider8"] == "Extreme" then
                        cvar.cl_interp:set_float(0.031000)
                    end
                end
            elseif menu.elements["visuals"]["pingpos"] == "High" then
                cvar.cl_interp:set_float(0.020000)
                cvar.cl_interp_ratio:set_int(0)
                cvar.cl_interpolate:set_int(0)
            end
        else
            cvar.cl_interp:set_float(0.015625)
            cvar.cl_interp_ratio:set_int(2)
            cvar.cl_interpolate:set_int(1)
        end --]]
        end)

    client.set_event_callback("paint", function()
        local text = "pred1ct"

        local clock = globals.curtime()

        local cooler_text = render.gradient_text(text, clock, 255, 255, 255, 255, 10, 10, 10, 255)

        --if menu.refs["visuals"]["hotkey"]:get() then
            --renderer.indicator(255, 255, 255, 255, cooler_text)
        --end
    end)

end
end

        rage.aim_tools = {}
    do
        local aim_tools = rage.aim_tools
        local miss_counter = 0

        aim_tools.enable = menu.checkbox(groups.antiaim)("cabbitools")(
            "visuals",
            "aim_tools",
            ts.is_rage
        )
        aim_tools.weapon = menu.combobox(groups.antiaim)(
            "weapon",
            { "ssg-08", "awp", "auto snipers" }
        )("visuals", "aimtools_weapon", function() return ts.is_rage() and menu.elements["visuals"]["aim_tools"] end)
        aim_tools.override = menu.combobox(groups.antiaim)(
            "override type",
            { "force baim", "prefer baim", "prefer safepoint" }
        )("visuals", "aimtools_override", function() return ts.is_rage() and menu.elements["visuals"]["aim_tools"] end)
        local weapons_map =
            { ["ssg-08"] = "ssg", ["awp"] = "awp", ["auto snipers"] = "auto" }

        for combo_value, key in pairs(weapons_map) do
            aim_tools[key .. "_force_baim_conditions"] = menu.multiselect(
                groups.antiaim
            )(
                "force baim conditions " .. key,
                { "after x misses", "if hp < x" }
            )("visuals", key .. "_force_baim_conditions", function()
                return ts.is_rage()
                    and menu.elements["visuals"]["aimtools_override"] == "force baim"
                    and menu.elements["visuals"]["aimtools_weapon"]
                        == combo_value
                    and menu.elements["visuals"]["aim_tools"]
            end)

            aim_tools[key .. "_force_baim_miss"] = menu.slider(groups.other)(
                "force baim miss threshold " .. key,
                0,
                10,
                3,
                true
            )("visuals", key .. "_force_baim_miss", function()
                local ms =
                    menu.elements["visuals"][key .. "_force_baim_conditions"]
                return ts.is_rage()
                    and menu.elements["visuals"]["aimtools_override"] == "force baim"
                    and menu.elements["visuals"]["aimtools_weapon"] == combo_value
                    and ms
                    and ms["after x misses"]
                    and menu.elements["visuals"]["aim_tools"]
            end)

            aim_tools[key .. "_force_baim_hp"] = menu.slider(groups.antiaim)(
                "force baim hp threshold " .. key,
                0,
                100,
                30,
                true
            )("visuals", key .. "_force_baim_hp", function()
                local ms =
                    menu.elements["visuals"][key .. "_force_baim_conditions"]
                return ts.is_rage()
                    and menu.elements["visuals"]["aimtools_override"] == "force baim"
                    and menu.elements["visuals"]["aimtools_weapon"] == combo_value
                    and ms
                    and ms["if hp < x"]
                    and menu.elements["visuals"]["aim_tools"]
            end)

            aim_tools[key .. "_prefer_baim_conditions"] = menu.multiselect(
                groups.antiaim
            )(
                "prefer baim conditions " .. key,
                { "after x misses", "if hp < x" }
            )(
                "visuals",
                key .. "_prefer_baim_conditions",
                function()
                    return ts.is_rage()
                        and menu.elements["visuals"]["aimtools_override"] == "prefer baim"
                        and menu.elements["visuals"]["aimtools_weapon"]
                            == combo_value
                        and menu.elements["visuals"]["aim_tools"]
                end
            )

            aim_tools[key .. "_prefer_baim_miss"] = menu.slider(groups.antiaim)(
                "prefer baim miss threshold " .. key,
                0,
                10,
                3,
                true
            )("visuals", key .. "_prefer_baim_miss", function()
                local ms =
                    menu.elements["visuals"][key .. "_prefer_baim_conditions"]
                return ts.is_rage()
                    and menu.elements["visuals"]["aimtools_override"] == "prefer baim"
                    and menu.elements["visuals"]["aimtools_weapon"] == combo_value
                    and ms
                    and ms["after x misses"]
                    and menu.elements["visuals"]["aim_tools"]
            end)

            aim_tools[key .. "_prefer_baim_hp"] = menu.slider(groups.antiaim)(
                "prefer baim hp threshold " .. key,
                0,
                100,
                30,
                true
            )("visuals", key .. "_prefer_baim_hp", function()
                local ms =
                    menu.elements["visuals"][key .. "_prefer_baim_conditions"]
                return ts.is_misc()
                    and menu.elements["visuals"]["aimtools_override"] == "prefer baim"
                    and menu.elements["visuals"]["aimtools_weapon"] == combo_value
                    and ms
                    and ms["if hp < x"]
                    and menu.elements["visuals"]["aim_tools"]
            end)

            aim_tools[key .. "_pref_safe_conditions"] = menu.multiselect(
                groups.antiaim
            )(
                "prefer safepoint conditions " .. key,
                { "after x misses", "if hp < x" }
            )("visuals", key .. "_pref_safe_conditions", function()
                return ts.is_rage()
                    and menu.elements["visuals"]["aimtools_override"] == "prefer safepoint"
                    and menu.elements["visuals"]["aimtools_weapon"]
                        == combo_value
                    and menu.elements["visuals"]["aim_tools"]
            end)

            aim_tools[key .. "_pref_safe_miss"] = menu.slider(groups.antiaim)(
                "prefer safepoint miss threshold " .. key,
                0,
                10,
                3,
                true
            )("visuals", key .. "_pref_safe_miss", function()
                local ms =
                    menu.elements["visuals"][key .. "_pref_safe_conditions"]
                return ts.is_rage()
                    and menu.elements["visuals"]["aimtools_override"] == "prefer safepoint"
                    and menu.elements["visuals"]["aimtools_weapon"] == combo_value
                    and ms
                    and ms["after x misses"]
                    and menu.elements["visuals"]["aim_tools"]
            end)

            aim_tools[key .. "_pref_safe_hp"] = menu.slider(groups.antiaim)(
                "prefer safepoint hp threshold " .. key,
                0,
                100,
                30,
                true
            )("visuals", key .. "_pref_safe_hp", function()
                local ms =
                    menu.elements["visuals"][key .. "_pref_safe_conditions"]
                return ts.is_rage()
                    and menu.elements["visuals"]["aimtools_override"] == "prefer safepoint"
                    and menu.elements["visuals"]["aimtools_weapon"] == combo_value
                    and ms
                    and ms["if hp < x"]
                    and menu.elements["visuals"]["aim_tools"]
            end)
        end

        menu.checkbox(groups.antiaim)("debug panel")(
            "visuals",
            "debug_panel",
            function()
                return ts.is_rage() and menu.elements["visuals"]["aim_tools"]
            end
        )

        client.set_event_callback("aim_miss", function(e)
            if e.reason ~= "prediction error" then
                miss_counter = miss_counter + 1
            end
        end)

        client.set_event_callback("round_prestart", function()
            miss_counter = 0
        end)

        local function check_trigger(
            ms,
            hp,
            hp_slider,
            miss_counter,
            miss_slider
        )
            if not ms then
                return false
            end
            if ms["if hp < x"] and hp < hp_slider then
                return true
            end
            if ms["after x misses"] and miss_counter >= miss_slider then
                return true
            end
            return false
        end

        local function on_setup_command()
            if not aim_tools.enable:get() then
                return
            end

            local me = entity.get_local_player()
            if not me or not entity.is_alive(me) then
                return
            end

            local gun = entity.get_player_weapon(me)
            if not gun then
                return
            end

            local weapon_class = entity.get_classname(gun)
            local weapon_name
            if weapon_class == "CWeaponSSG08" then
                weapon_name = "ssg-08"
            elseif weapon_class == "CWeaponAWP" then
                weapon_name = "awp"
            elseif
                weapon_class == "CWeaponG3SG1"
                or weapon_class == "CWeaponSCAR20"
            then
                weapon_name = "auto snipers"
            else
                return
            end

            local override = aim_tools.override:get()
            local players = entity.get_players(true)

            for _, target in ipairs(players) do
                if
                    not target
                    or not entity.is_alive(target)
                    or entity.is_dormant(target)
                then
                    goto continue
                end

                local hp = entity.get_prop(target, "m_iHealth") or 100
                local ms, hp_slider, miss_slider

                if override == "force baim" then
                    ms =
                        menu.elements["visuals"][weapons_map[weapon_name] .. "_force_baim_conditions"]
                    hp_slider =
                        menu.elements["visuals"][weapons_map[weapon_name] .. "_force_baim_hp"]
                    miss_slider =
                        menu.elements["visuals"][weapons_map[weapon_name] .. "_force_baim_miss"]
                    if
                        check_trigger(
                            ms,
                            hp,
                            hp_slider,
                            miss_counter,
                            miss_slider
                        )
                    then
                        plist.set(target, "Override prefer body aim", "Force")
                    else
                        plist.set(target, "Override prefer body aim", "-")
                    end
                elseif override == "prefer baim" then
                    ms =
                        menu.elements["visuals"][weapons_map[weapon_name] .. "_prefer_baim_conditions"]
                    hp_slider =
                        menu.elements["visuals"][weapons_map[weapon_name] .. "_prefer_baim_hp"]
                    miss_slider =
                        menu.elements["visuals"][weapons_map[weapon_name] .. "_prefer_baim_miss"]
                    if
                        check_trigger(
                            ms,
                            hp,
                            hp_slider,
                            miss_counter,
                            miss_slider
                        )
                    then
                        plist.set(target, "Override prefer body aim", "On")
                    else
                        plist.set(target, "Override prefer body aim", "-")
                    end
                elseif override == "prefer safepoint" then
                    ms =
                        menu.elements["visuals"][weapons_map[weapon_name] .. "_pref_safe_conditions"]
                    hp_slider =
                        menu.elements["visuals"][weapons_map[weapon_name] .. "_pref_safe_hp"]
                    miss_slider =
                        menu.elements["visuals"][weapons_map[weapon_name] .. "_pref_safe_miss"]
                    if
                        check_trigger(
                            ms,
                            hp,
                            hp_slider,
                            miss_counter,
                            miss_slider
                        )
                    then
                        plist.set(target, "Override safe point", "On")
                    else
                        plist.set(target, "Override safe point", "-")
                    end
                end
                ::continue::
            end
        end

        local debug_drag = drag.new("debug_panel", 50, 350)
		pui_drags[#pui_drags + 1] = debug_drag

        local function debug_panel_handle()
            local main_text = "CABBITOOLS.FUN"
            local target = client.current_threat()
            local screen_width, screen_height = client.screen_size()

            local master = menu.elements["visuals"]["debug_panel"]

            if not master then 
                return
            end

            local x, y = debug_drag:drag(90, 52, 200, 60)

            if master then
                local target_name = target and entity.get_player_name(target)
                    or "none"
                local safepoint_text = "Off"
                local baim_text = "Off"
                if target then
                    local safepoint = plist.get(target, "Override safe point")
                    safepoint_text = (safepoint == "-" and "Off") or safepoint
                    local baim = plist.get(target, "Override prefer body aim")
                    baim_text = (baim == "-" and "Off") or baim
                end
                local state = my.state

                local state_text = "GLOBAL"

                if state == 2 then
                    state_text = "STANDING"
                elseif state == 3 then
                    state_text = "RUNNING"
                elseif state == 4 then
                    state_text = "WALKING"
                elseif state == 5 then
                    state_text = "CROUCHING"
                elseif state == 6 then
                    state_text = "SNEAKING"
                elseif state == 7 then
                    state_text = "AIR"
                elseif state == 8 then
                    state_text = "AIR CROUCHING"
                elseif state == -1 then
                    state_text = "GLOBAL"
                end

                local r1, g1, b1, a1 = 30, 30, 30, 255
                local r2, g2, b2, a2 =
                    menu.refs["visuals"]["accent_color"]:get()
                local clock = globals.curtime()
                local grad_text = render.gradient_text(
                    main_text,
                    clock,
                    r1,
                    g1,
                    b1,
                    a1,
                    r2,
                    g2,
                    b2,
                    a2
                )

                local text_width, text_height = renderer.measure_text(grad_text)

                renderer.text(x, y, 255, 255, 255, 255, "-", nil, grad_text)
                renderer.text(
                    x,
                    y + 10,
                    255,
                    255,
                    255,
                    255,
                    "-",
                    nil,
                    string.format("TARGET: %s", target_name)
                )
                renderer.text(
                    x,
                    y + 20,
                    255,
                    255,
                    255,
                    255,
                    "-",
                    nil,
                    string.format("BAIM STATUS: %s", baim_text)
                )
                renderer.text(
                    x,
                    y + 30,
                    255,
                    255,
                    255,
                    255,
                    "-",
                    nil,
                    string.format("SAFEPOINT STATUS: %s", safepoint_text)
                )
                renderer.text(
                    x,
                    y + 40,
                    255,
                    255,
                    255,
                    255,
                    "-",
                    nil,
                    string.format("STATE: %s", state_text)
                )
            end
        end

        client.set_event_callback("setup_command", function()
            client.update_player_list()
            on_setup_command()
        end)

        client.set_event_callback("paint", debug_panel_handle)

        client.set_event_callback("player_death", function(e)
            local died_ent = client.userid_to_entindex(e.userid)
            local threat = client.current_threat()
            if threat and died_ent == threat then
                plist.set(threat, "Override prefer body aim", "-")
                plist.set(threat, "Override safe point", "-")
            end
        end)
    end

local autobuy = {}
do
    autobuy.buy = {}
    do
        local buy = autobuy.buy
        local bought_this_round = false
        
        client.set_event_callback("round_start", function()
            bought_this_round = false
        end)
        
        local primary_opts = { "-", "AWP", "Auto-Sniper", "Scout", "Negev" }
        local secondary_opts = { "-", "R8 Revolver / Deagle", "Dual Berettas", "FN57 / Tec9 / CZ75-Auto" }
        local gear_opts = { "Kevlar", "Helmet", "Defuse Kit", "Grenade", "Molotov", "Smoke", "Taser" }
        
        buy.handle = function(e)
            local userid = e.userid
            if userid ~= nil then
                if client.userid_to_entindex(userid) ~= entity.get_local_player() then
                    return
                end
            end
            
            if bought_this_round then return end
            if not menu.elements["visuals"]["autobuy"] then return end
            
            bought_this_round = true
            
            local cmds = {}
            local main = menu.elements["visuals"]["primary"]
            local sec = menu.elements["visuals"]["secondary"]
            local utility = menu.elements["visuals"]["utility"]
            
            if main ~= "-" then
                if main == "AWP" then
                    table.insert(cmds, "buy awp")
                elseif main == "Auto-Sniper" then
                    table.insert(cmds, "buy scar20; buy g3sg1")
                elseif main == "Scout" then
                    table.insert(cmds, "buy ssg08")
                elseif main == "Negev" then
                    table.insert(cmds, "buy negev")
                end
            end
            
            if sec ~= "-" then
                if sec == "R8 Revolver / Deagle" then
                    table.insert(cmds, "buy deagle")
                elseif sec == "Dual Berettas" then
                    table.insert(cmds, "buy elite")
                elseif sec == "FN57 / Tec9 / CZ75-Auto" then
                    table.insert(cmds, "buy fn57")
                end
            end
            
            if utility["Kevlar"] then table.insert(cmds, "buy vest") end
            if utility["Helmet"] then table.insert(cmds, "buy vesthelm") end
            if utility["Defuse Kit"] then table.insert(cmds, "buy defuser") end
            if utility["Taser"] then table.insert(cmds, "buy taser") end
            if utility["Smoke"] then table.insert(cmds, "buy smokegrenade") end
            if utility["Molotov"] then
                table.insert(cmds, "buy molotov; buy incgrenade")
            end
            if utility["Grenade"] then table.insert(cmds, "buy hegrenade") end
            
            local full_cmd = table.concat(cmds, "; ")
            client.exec(full_cmd)
        end
        
        client.set_event_callback("player_spawn", buy.handle)
        
        menu.checkbox(groups.antiaim)("Auto-Buy")("visuals", "autobuy", ts.is_buymenu)
        menu.combobox(groups.antiaim)("Primary", primary_opts)("visuals", "primary", function() return ts.is_buymenu() and menu.elements["visuals"]["autobuy"] end)
        menu.combobox(groups.antiaim)("Secondary", secondary_opts)("visuals", "secondary", function() return ts.is_buymenu() and menu.elements["visuals"]["autobuy"] end)
        menu.multiselect(groups.antiaim)("Gear", gear_opts)("visuals", "utility", function() return ts.is_buymenu() and menu.elements["visuals"]["autobuy"] end)
    end
end

local indicators = {}
do
    indicators.accent = {}
    do
        local accent = indicators.accent
    
        menu.label(groups.antiaim)("\v•\r  Accent Color")(
            "visuals",
            "accent_color_label", ts.is_indicators)

        menu.color_picker(groups.antiaim)("\naccent_color", color("A6CAFFFF"))(
            "visuals",
            "accent_color", ts.is_indicators)

        menu.refs["visuals"]["accent_color"]:set_callback(function(self)
            pui.macros.accent = color(self:get())
        end, true)

    end

    local window_watermark_drag = drag.new("window_watermark_drag", 10, 40)
	pui_drags[#pui_drags + 1] = window_watermark_drag

    local window_spec_drag = drag.new("window_spec_drag", 10, 40)
	pui_drags[#pui_drags + 1] = window_spec_drag

    local window_key_drag = drag.new("window_key_drag", 10, 40)
	pui_drags[#pui_drags + 1] = window_key_drag
	
	local window_multi_drag = drag.new("window_multi_drag", 10, 40)
	pui_drags[#pui_drags + 1] = window_multi_drag

	local window_debug_drag = drag.new("window_debug_drag", 10, 40)
	pui_drags[#pui_drags + 1] = window_debug_drag

    indicators.windows = {}
    do
        local windows = indicators.windows

        local sc = vector(client.screen_size())

        local master = menu.elements["visuals"]["widgets"]

        windows.watermark_handle = function()
            local master = menu.elements["visuals"]["widgets"]

            if not master["Watermark"] then return end

            local r,g,b,a = menu.refs["visuals"]["accent_color"]:get()

            local hour,minute,second = client.system_time()

            local text = string.format("cabbtral %s - %s - %02d:%02d:%02d", current_build, cabbtral.user, hour, minute, second)

            local text_w, text_h = renderer.measure_text("d", text)

            local x, y = window_watermark_drag:drag(text_w + 18, 20, 10, 40)


            local padding = 12

            local pad_x = 10
            local pad_y = 6

            local rect_w = text_w + pad_x * 2
            local rect_h = text_h + pad_y * 2

            local margin = 12
            local rect_x = x
            local rect_y = y

            local grad_w = rect_w * 0.5
            local grad_h = 1

            local left_w  = math.floor(rect_w / 2)
            local right_w = rect_w - left_w

renderer.gradient(
    rect_x,
    rect_y,
    left_w,
    grad_h,
    0, 0, 0, 150,
    r, g, b, a,
    true
)

renderer.gradient(
    rect_x + left_w,
    rect_y,
    right_w,
    grad_h,
    r, g, b, a,
    0, 0, 0, 150,
    true
)


            renderer.rectangle(
    rect_x,
    rect_y + grad_h,
    rect_w,
    rect_h - 5,
    0, 0, 0, 150
)

            renderer.text(
    rect_x + pad_x  ,
    rect_y + grad_h + pad_y-3.5,
    255, 255, 255, 255,
    "d",
    0,
    text
)

        end


        local function has_spectators()
            for _, data in pairs(m_active) do
                if data.active then
                    return true
                end
            end
            return false
        end


        local get_spectating_players = function()
			local me = entity.get_local_player()

			local players, observing = { }, me
		
			for i = 1, globals.maxplayers() do
				if entity.get_classname(i) == 'CCSPlayer' then
					local m_iObserverMode = entity.get_prop(i, 'm_iObserverMode')
					local m_hObserverTarget = entity.get_prop(i, 'm_hObserverTarget')
		
					if m_hObserverTarget ~= nil and m_hObserverTarget <= 64 and not entity.is_alive(i) and (m_iObserverMode == 4 or m_iObserverMode == 5) then
						if players[m_hObserverTarget] == nil then
							players[m_hObserverTarget] = { }
						end
		
						if i == me then
							observing = m_hObserverTarget
						end
		
						table.insert(players[m_hObserverTarget], i)
					end
				end
			end
		
			return players, observing
		end


        local function get_spectator_names()
    local names = {}

    for _, data in pairs(m_active) do
        if data.active then
            table.insert(names, data.name)
        end
    end

    return names
end

local function update_spectators()
    local spectators, observing = get_spectating_players()
    local me = entity.get_local_player()

    for i = 1, 64 do
        unsorted[i] = { idx = i, active = false }
    end

    if spectators[me] ~= nil then
        for _, spectator in pairs(spectators[me]) do
            if spectator ~= me then
                unsorted[spectator].active = true
            end
        end
    end

    for _, ref in pairs(unsorted) do
        local id = ref.idx

        if ref.active then
            if not m_active[id] then
                m_active[id] = { alpha = 0 }
            end

            m_active[id].active = true
            m_active[id].name = entity.get_player_name(id)
        elseif m_active[id] then
            m_active[id] = nil
        end
    end
end



            unsorted   = {}
            m_active   = {}
            m_contents = {}


windows.spec_handle = function()
    local master = menu.elements["visuals"]["widgets"]

    if not master["Spectators"] then return end
    update_spectators()

    local r,g,b,a = menu.refs["visuals"]["accent_color"]:get()

    local spectators = get_spectator_names()
    if #spectators == 0 then
        spectators = { "Nobody" }
    end

    local padding_x, padding_y = 20, 8
    local padding_xb, padding_yb = 22, 10
    local line_height = 14
    local title = "spectators"
    local title_gap = 15

    local x, y = window_spec_drag:drag(95, 60, 10, 40)

    local title_w, title_h = renderer.measure_text("db", title)

    local max_name_w = 0
    for i = 1, #spectators do
        local w = renderer.measure_text(nil, spectators[i])
        max_name_w = math.max(max_name_w, w)
    end

    local content_w = math.max(title_w, max_name_w)
    local box_w = content_w + padding_x * 2
    local box_wb = content_w + padding_xb * 2

    local box_h =
        padding_y +
        title_h +
        title_gap +
        (#spectators * line_height) +
        padding_y
    local box_hb =
        padding_yb +
        title_h +
        title_gap +
        (#spectators * line_height) +
        padding_yb

    renderer.rectangle(x-2, y-2, box_wb, box_hb, 35, 35, 35, 240)
    renderer.rectangle(x, y, box_w, box_h, 10, 10, 10, 240)
    renderer.gradient(x, y, box_w, title_gap * 1.5, 40, 40, 40, 240, 10, 10, 10, 240, false)

    renderer.gradient(
        x+box_w/2,
        y + title_gap* 1.7,
        box_w/2,
        1,
        r, g, b, a,
        0, 0, 0, 220,
        true
    )
    renderer.gradient(
        x+box_w*0.01,
        y + title_gap* 1.7,
        box_w/2,
        1,
        0, 0, 0, 240,
        r, g, b, a,
        true
    )


    renderer.text(
        x + box_w / 2 - title_w / 2,
        y + padding_y - 2,
        255, 255, 255, 255,
        "db",
        0,
        title
    )

    local start_y = y + padding_y + title_h + title_gap

    for i = 1, #spectators do
        local name = spectators[i]
        local name_w = renderer.measure_text(nil, name)

        renderer.text(
            x + box_w / 2 - name_w / 2,
            start_y + (i - 1) * line_height,
            255, 255, 255, 255,
            "",
            0,
            name
        )
    end

end



windows.keybinds = {}
windows.keybinds.items = {}

windows.keybinds.anim_w = windows.keybinds.anim_w or 0
windows.keybinds.anim_h = windows.keybinds.anim_h or 0

function windows.keybinds:create(name, get)
    table.insert(self.items, {
        name = name,
        get = get,
        alpha = 0
    })
end


windows.keybinds:create(
    "Double tap",
    function()
        return refs.other.doubletap:get_hotkey()
    end
)

windows.keybinds:create(
    "On-shot antiaim",
    function()
        return refs.other.onshot:get() and refs.other.onshot.hotkey:get()
    end
)

windows.keybinds:create(
    "Force body aim",
    function()
        return refs.other.force_baim:get()
    end
)

windows.keybinds:create(
    "Force safepoint",
    function()
        return refs.other.force_sp:get()
    end
)

windows.keybinds:create(
    "Damage override",
    function()
        return refs.other.min_damage_override[1].hotkey:get()
    end
)

if refs.other.hitchance1 then

windows.keybinds:create(
    "Hitchance override",
    function()
        return refs.other.hitchance1:get()
    end
)

end

windows.keybinds:create(
    "Ping spike",
    function()
        return refs.other.ping_spike:get_hotkey()
    end
)

windows.keybinds:create(
    "Freestanding",
    function()
        return menu.refs["antiaim"]["freestanding_bind"]:get()
    end
)

windows.keybinds:create(
    "Yaw base left",
    function()
        return menu.refs["antiaim"]["left_bind"]:get()
    end
)

windows.keybinds:create(
    "Yaw base right",
    function()
        return menu.refs["antiaim"]["right_bind"]:get()
    end
)

windows.keybinds:create(
    "Yaw base forward",
    function()
        return menu.refs["antiaim"]["forward_bind"]:get()
    end
)

windows.keybinds:create(
    "Yaw base backward",
    function()
        return menu.refs["antiaim"]["backwards_bind"]:get()
    end
)

windows.keybinds:create(
    "Fakeduck",
    function()
        return refs.other.fakeduck:get()
    end
)

windows.keybinds:create(
    "Quick peek assist",
    function()
        return refs.other.autopeek[1]:get_hotkey()
    end
)

windows.keybinds:create(
    "Slow motion",
    function()
        return refs.other.slow_motion:get() and refs.other.slow_motion.hotkey:get()
    end
)

windows.keybinds:create(
    "Di$sable defensive",
    function()
        return menu.elements["antiaim"]["unmatched"] and menu.refs["antiaim"]["disabledef"]:get()
    end
)

windows.key_handle = function()
    local master = menu.elements["visuals"]["widgets"]
	local lp = entity.get_local_player()
    if not lp or not entity.is_alive(lp) then
        return
    end
    if not master["Keybinds"] then
        return
    end

    local r,g,b,a = menu.refs["visuals"]["accent_color"]:get()

    local sc = vector(client.screen_size())
    local x, y = window_key_drag:drag(90, 60, 10, 40)

    local line_h = 14
    local title_gap = 10
    local padding_x = 16
    local padding_y = 10

    local total_h = line_h + title_gap
    local max_w = renderer.measure_text("b", "keybinds")

    for _, item in ipairs(windows.keybinds.items) do
        local active = item.get()
        item.alpha = anim.lerp(item.alpha, active and 255 or 0)

        if item.alpha > 1 then
            local text = item.name .. (active and " [on]" or " [off]")
            local tw = renderer.measure_text("", text)

            max_w = math.max(max_w, tw)
            total_h = total_h + line_h * (item.alpha / 255)
        end
    end

    local box_w = max_w + padding_x * 2
    local box_h = total_h + padding_y * 2

    windows.keybinds.anim_w = anim.lerp(windows.keybinds.anim_w, box_w)
    windows.keybinds.anim_h = anim.lerp(windows.keybinds.anim_h, box_h)

    local draw_w = windows.keybinds.anim_w
    local draw_h = windows.keybinds.anim_h


    local box_x = x - draw_w / 2 + 45
    local box_y = y - line_h - padding_y - 4 + 40

    renderer.rectangle(
        box_x-3,
        box_y-3,
        draw_w+6,
        draw_h+6,
        35, 35, 35, 240
    )

    renderer.rectangle(
        box_x,
        box_y,
        draw_w,
        draw_h,
        10, 10, 10, 240
    )

    renderer.gradient(box_x, box_y, draw_w, title_gap*2, 40, 40, 40, 240, 10, 10, 10, 240, false)

    local title = "keybinds"
    local title_w = renderer.measure_text("b", title)

    renderer.text(
        x - title_w / 2 + 45,
        y - line_h*1.4 + 40,
        255, 255, 255, 255,
        "b",
        0,
        title
    )

local grad_y = y + 40
local grad_w = draw_w * 0.5

local grad_left_x  = box_x
local grad_right_x = box_x + grad_w

renderer.gradient(
    grad_left_x,
    grad_y,
    grad_w,
    1,
    0, 0, 0, 240,
    r, g, b, a,
    true
)

renderer.gradient(
    grad_right_x,
    grad_y,
    grad_w,
    1,
    r, g, b, a,
    0, 0, 0, 240,
    true
)


    y = y + title_gap

    for _, item in ipairs(windows.keybinds.items) do
        if item.alpha > 1 then
            local active = item.get()
            local text = item.name .. (active and " [on]" or " [off]")
            local tw = renderer.measure_text("", text)

            renderer.text(
                x - tw / 2 + 45,
                y+ 40,
                255, 255, 255, item.alpha,
                "",
                0,
                text
            )

            y = y + line_h * (item.alpha / 255)
        end
    end
end

local vel_history = {}
local def_history = {}
local def_smooth = 0
local MAX_POINTS = 20

windows.multi_handle = function()
    local master = menu.elements["visuals"]["widgets"]
	local lp = entity.get_local_player()
    if not lp or not entity.is_alive(lp) then
        return
    end
	local value = entity.get_prop(lp, "m_flVelocityModifier") or nil
	local raw = exploit.diff
	if value == nil then return end
    if not master["Multipanel"] then
        return
    end

    local r,g,b,a = menu.refs["visuals"]["accent_color"]:get()

    local sc = vector(client.screen_size())
    local x, y = window_multi_drag:drag(85, 110, 10, 40)
    local panel_w, panel_h = 80, 110

    -- background
	renderer.rectangle(
        x - 5, y - 5,
        panel_w + 10, panel_h + 10,
        40, 40, 40, 240
    )
    renderer.rectangle(
        x - 3, y - 3,
        panel_w + 6, panel_h + 6,
        10, 10, 10, 240
    )
	
	renderer.gradient(
        x - 3, y - 3,
        panel_w + 6, panel_h / 3,
		40, 40, 40, 240,
        10, 10, 10, 240,
		false
    )
    renderer.text(
        x + 20,
        y + 53,
        220, 220, 220, 240,
        "b",
        nil,
        "velocity"
    )
	
	local graph_x = x + 14
    local graph_y = y + 28 + 45
    local graph_ydef = y + 28
    local graph_w = panel_w - 28
    local graph_h = 60
	
	renderer.rectangle(
        x + 11, y + 17 + 52,
        graph_w + 6, graph_h / 2,
        30, 30, 30, 240
    )

    local reduction = 1 - value -- 0 ? 1

    table.insert(vel_history, reduction)
    if #vel_history > MAX_POINTS then
        table.remove(vel_history, 1)
    end

    for i = 2, #vel_history do
        local v1 = math.min(vel_history[i - 1], 1)
		local v2 = math.min(vel_history[i], 1)

        local px1 = graph_x + ((i - 2) / (MAX_POINTS - 1)) * graph_w
        local py1 = graph_y + v1 * graph_h / 2.2

        local px2 = graph_x + ((i - 1) / (MAX_POINTS - 1)) * graph_w
        local py2 = graph_y + v2 * graph_h / 2.2

        renderer.line(
            px1, py1,
            px2, py2,
            r, g, b, 255
        )
    end

if raw == nil then
    raw = 0
end

raw = -raw

local target = raw / 16

if target < 0 then target = 0 end
if target > 1 then target = 1 end

def_smooth = def_smooth + (target - def_smooth) * 0.2

local defensive = def_smooth

table.insert(def_history, defensive)
if #def_history > MAX_POINTS then
    table.remove(def_history, 1)
end

    renderer.text(
        x + 15,
        graph_ydef - 27,
        220, 220, 220, 240,
        "b",
        nil,
        "defensive"
    )

renderer.rectangle(
    x + 11, graph_ydef- 10,
    graph_w + 6, graph_h / 2,
    30, 30, 30, 240
)
for i = 2, #def_history do
    local v1 = def_history[i - 1]
    local v2 = def_history[i]

    local px1 = graph_x + ((i - 2) / (MAX_POINTS - 1)) * graph_w
    local py1 = graph_ydef + v1 * graph_h / 2.2

    local px2 = graph_x + ((i - 1) / (MAX_POINTS - 1)) * graph_w
    local py2 = graph_ydef + v2 * graph_h / 2.2

    renderer.line(
        px1, py1,
        px2, py2,
        r, g, b, 255
    )
end
end

windows.debug_handle = function()
	local master = menu.elements["visuals"]["widgets"]
	if not master["Debug panel"] then
		return
	end
	local lp = entity.get_local_player()
    if not lp or not entity.is_alive(lp) then
        return
    end
	
	local yaw_offset = refs.antiaim.yaw_offset:get()
	local pitch_offset = refs.antiaim.pitch_offset:get()
	local yaw_jitter = refs.antiaim.yaw_jitter:get()
	local yaw_jitter_offset = refs.antiaim.yaw_jitter_offset:get()
	local body_yaw = refs.antiaim.body_yaw:get()
	local body_yaw_offset = refs.antiaim.body_yaw_offset:get()
	local fakelag_limit = refs.antiaim.fakelag_limit:get()
	local side
    if antiaim.data.inverter then
        side = "R"
    else
        side = "L"
    end
	local label = string.format("%s debug panel", cabbtral.name)
	local yaw_text = string.format("yaw: %s", yaw_offset)
	local pitch_text = string.format("pitch: %s", pitch_offset)
	local yaw_jitter_text = string.format("jitter mode: %s", yaw_jitter)
	local yaw_jitter_off_text = string.format("jitter offset: %s", yaw_jitter_offset)
	local body_yaw_text = string.format("body yaw mode: %s", body_yaw)
	local body_yaw_off_text = string.format("body yaw: %s", body_yaw_offset)
	local fakelag_limit_text = string.format("fakelag: %s", fakelag_limit)
	local side_text = string.format("side: %s", side)

	
	local sc = vector(client.screen_size())
	
	local label_w, label_h = renderer.measure_text("b", label)
	
	local x, y = window_debug_drag:drag(label_w,95, 10, 40)
	
	local r,g,b,a = menu.refs["visuals"]["accent_color"]:get()
	
	renderer.text(
		x,y,r,g,b,a,"b",nil,label
	)
	renderer.text(
		x,y+ 13,255,255,255,255,"",nil,pitch_text
	)
	renderer.text(
		x,y+ 26,255,255,255,255,"",nil,yaw_text
	)
	renderer.text(
		x,y+ 39,255,255,255,255,"",nil,body_yaw_text
	)
	renderer.text(
		x,y+ 52,255,255,255,255,"",nil,body_yaw_off_text
	)
	renderer.text(
		x,y+ 65,255,255,255,255,"",nil,side_text
	)
	renderer.text(
		x,y+ 78,255,255,255,255,"",nil,fakelag_limit_text
	)
	
end


        events.paint_ui:set(function()
            windows.watermark_handle()
            windows.spec_handle()
            windows.key_handle()
            windows.multi_handle()
			windows.debug_handle()
        end)

        menu.multiselect(groups.other)("Wigdets", { "Watermark", "Keybinds", "Spectators", "Multipanel", "Debug panel" })("visuals", "widgets", ts.is_indicators)
    end


    local watermark_old_drag = drag.new("watermark_old", 10, 40)
	pui_drags[#pui_drags + 1] = watermark_old_drag

    indicators.watermark = {}
    do
        local watermark = indicators.watermark
        

        watermark.fn = function(str)
            local font_mode = menu.elements["visuals"]["watermark_font"]
            if font_mode == "Pixel" and menu.elements["visuals"]["watermark_style"] == "Old" then
                return string.upper(str)
            else
                return str
            end
        end
        local function get_font_flags()
            local mode = menu.elements["visuals"]["watermark_font"]

            if mode == "Pixel" then
                return "c-d"
            elseif mode == "Bold" then
                return "cdb"
            elseif mode == "Big" then
                return "c+d"
            else
                return "cd"
            end
        end


watermark.handle = function()
    local pos = vector(client.screen_size())
    local colortext = menu.elements["visuals"]["accent_color"]:to_hex()

    local switch = menu.elements["visuals"]["watermarkswitch"]

    local master = menu.elements["visuals"]["widgets"]

    if master["Watermark"] then return end

    local text = string.format(
        "\v\a%s  ? cabbtral %s \\ \aFFFFFFFF? %s \r",
        colortext,
        current_build,
        cabbtral.user
    )

    if switch then 
        return 
    end

    local xnew, ynew = 10, pos.y/2

    renderer.text(
        xnew,
        ynew,
        255, 255, 255, 255,
        "b",
        nil,
        text
    )
end

watermark.old_handle = function()
    local switch = menu.elements["visuals"]["watermarkswitch"]
    local display_text = menu.refs["visuals"]["watermark_old_text"]:get()
    if display_text == "" then
        display_text = "cabbtral.fun"
    end

    if not switch then 
        return 
    end

    local xold, yold = watermark_old_drag:drag(40, 20, 200, 60)

    local r1, g1, b1, a1 =
        menu.refs["visuals"]["accent_color"]:get()
    local r2, g2, b2, a2 =
        menu.refs["visuals"]["watermark_gradient_color"]:get()

    local speed =
        menu.elements["visuals"]["watermark_gradient_speed"]
    local clock = globals.curtime() * speed

    local gradient_text = render.gradient_text(
        display_text,
        clock,
        r1, g1, b1, a1,
        r2, g2, b2, a2
    )

    local font = get_font_flags()

    render.text(
        xold + 20,
        yold + 10,
        color(255),
        font,
        nil,
        watermark.fn(gradient_text)
    )
end

        --menu.label(groups.antiaim)("\v•\r  Watermark")("main", "watermarklabel", ts.is_indicators)

        menu.checkbox(groups.antiaim)("\vCustom\r Watermark")("visuals", "watermarkswitch", ts.is_indicators)

        menu.combobox(groups.antiaim)(
            "\nwatermark_font",
            { "Default", "Pixel", "Bold", "Big" }
        )("visuals", "watermark_font", function()
            return ts.is_indicators() and menu.elements["visuals"]["watermarkswitch"]
        end)
        menu.slider(groups.antiaim)(
            "\nwatermark_gradient_speed",
            1,
            10,
            2,
            true,
            "",
            1
        )("visuals", "watermark_gradient_speed", function()
            return ts.is_indicators()
                and menu.elements["visuals"]["watermarkswitch"]
        end)
        menu.color_picker(groups.antiaim)(
            "\nwatermark_gradient_color",
            color(255, 255)
        )("visuals", "watermark_gradient_color", function()
            return ts.is_indicators()
                 and menu.elements["visuals"]["watermarkswitch"]
        end)
        menu.textbox(groups.antiaim)("\nwatermark_old_text")(
            "visuals",
            "watermark_old_text",
            function()
                return ts.is_indicators()
                    and menu.elements["visuals"]["watermarkswitch"]
            end
        )
        menu.combobox(groups.antiaim)("\nwatermark_old_pos", { "bottom center", "upper right", "upper left", "center left", "center right" } )(
            "visuals",
            "Watermark_old_pos",
            function()
                return ts.is_indicators()
                    and menu.elements["visuals"]["watermarkswitch"]
            end
        )

        events.paint_ui:set(watermark.handle)
        events.paint_ui:set(watermark.old_handle)
    end

    indicators.crosshair = {}
    do
        local crosshair = indicators.crosshair

        crosshair.items = {}

        crosshair.handle = function()
            local height = menu.elements["visuals"]["crosshair_height"]
            local style = menu.elements["visuals"]["crosshair_style"]

            local flags
            if style == "Bold" then
                flags = "db"
            elseif style == "Pixel" then
                flags = "d-"
            else
                flags = "d"
            end
            
            local fn 
            if style == "Pixel" then
                fn = string.upper
            else
                fn = string.lower
            end
            local sc = vector(client.screen_size())
            local position = sc * 0.5 + vector(0, height)
            local side = my.side * 0.5 + 0.5

            for k, item in pairs(crosshair.items) do
                local text = item:paint(position, flags, fn)
                local size = text.size

                item.alpha = anim.lerp(item.alpha, item:get() and 255 or 0)
                item.size = anim.lerp(
                    item.size,
                    my.side ~= 0 and size.x * side + my.side * 8 or size.x * 0.5
                )

                position.y = position.y + size.y * (item.alpha / 255)
            end
        end

        local states = {
            [-1] = "unk",
            "shared",
            "stand",
            "run",
            "walk",
            "crouch",
            "sneak",
            "air",
            "airc",
            "fs",
            "manual",
        }

        function crosshair:create(args)
            table.insert(self.items, {
                get = args.get,
                paint = args.paint,
                size = 0,
                alpha = 0,
            })
        end

        crosshair:create({
            get = function()
                return true
            end,

            paint = function(self, position, flags, fn)
                local rg, gg, bg = menu.refs["visuals"]["crosshairg_color"]:get()
                local r,g,b,a = menu.refs["visuals"]["accent_color"]:get()

                local namem = string.format("%s", current_build)
                --local namem = string.format("%s", cabbtral.name)
                local name = string.lower(namem)

                local text =fn(render.gradient_text(
                        name,
                        globals.realtime(),
                        r,
                        g,
                        b,
                        self.alpha,
                        r,
                        g,
                        b,
                        self.alpha
                    ))
                local size = render.measure_text(flags, text)
                if self.alpha > 0 then
                    render.text(
                        position.x - self.size,
                        position.y,
                        pui.macros.accent:alpha_modulate(self.alpha),
                        flags,
                        nil,
                        text
                    )
                end

                return { size = size }
            end,
        })

        crosshair:create({
            get = function()
                return true
            end,

            paint = function(self, position, flags, fn)
                local rg, gg, bg = menu.refs["visuals"]["crosshairg_color"]:get()

                local namem = string.format("%s.fun", cabbtral.name)
                --local namem = string.format("%s", cabbtral.name)

                local text = fn(
                    render.gradient_text(
                        namem,
                        globals.realtime() * 1.5,
                        pui.macros.accent.r,
                        pui.macros.accent.g,
                        pui.macros.accent.b,
                        self.alpha,
                        rg,
                        gg,
                        bg,
                        self.alpha
                    )
                )
                local size = render.measure_text(flags, text)
                if self.alpha > 0 then
                    render.text(
                        position.x - self.size,
                        position.y,
                        pui.macros.accent:alpha_modulate(self.alpha),
                        flags,
                        nil,
                        text
                    )
                end

                return { size = size }
            end,
        })

        --[[crosshair:create({
            get = function(self)
                return true
            end,

            paint = function(self, position, flags, fn)

            local side
            if antiaim.data.inverter then
                side = "R"
            else
                side = "L"
            end
                local string = string.format("SIDE: %s", side)
                local text = fn(string)
                local size = render.measure_text(flags, text)
                local clr = color(255) or color(255, 0, 0)

                if self.alpha > 0 then
                    --if menu.elements["visuals"]["crosshair_elements"]["Side"] then
                    render.text(
                        position.x - self.size,
                        position.y,
                        clr:alpha_modulate(self.alpha),
                        flags,
                        nil,
                        text
                    )
                --end
            end

                return { size = size }
            end,
        })--]]

        crosshair:create({
            get = function(self)
                return refs.other.doubletap:get()
                    and refs.other.doubletap.hotkey:get()
            end,

            paint = function(self, position, flags, fn)
                local text = exploit.defensive and fn("DT\a0096FFFF DEFENSIVE\r") or exploit.shift and fn("DT \a00FF55FFACTIVE\r") or fn("DT DISABLED")
                local size = render.measure_text(flags, text)
                local clr = exploit.shift and color(255) or color(255, 0, 0)


                local positiony = position.y

                --[[if not menu.elements["visuals"]["crosshair_elements"]["Side"] then
                    positiony = positiony - 12
                else
                    positiony = position.y
                end--]]

                if self.alpha > 0 then
                    --if menu.elements["visuals"]["crosshair_elements"]["Exploits"] then
                    render.text(
                        position.x - self.size,
                        positiony,
                        clr:alpha_modulate(self.alpha),
                        flags,
                        nil,
                        text
                    )
                --end
            end

                return { size = size }
            end,
        })

        crosshair:create({
            get = function(self)
                return refs.other.onshot:get()
                    and refs.other.onshot.hotkey:get()
            end,

            paint = function(self, position, flags, fn)
                local text = not refs.other.doubletap.hotkey:get() and exploit.defensive and fn("HS \a0096FFFFDEFENSIVE\r") or not refs.other.doubletap.hotkey:get() and fn("HS \a00FF55FFACTIVE\r") or refs.other.doubletap.hotkey:get() and fn("HS")
                local size = render.measure_text(flags, text)

                local multiplier = anim.new(
                    "crosshair::osaa:multiplier",
                    refs.other.doubletap:get()
                            and refs.other.doubletap.hotkey:get()
                            and 2.5
                        or 10
                ) * 0.1

                local positiony = position.y

                --[[if not menu.elements["visuals"]["crosshair_elements"]["Side"] then
                    positiony = positiony - 12
                else
                    positiony = position.y
                end--]]

                if self.alpha > 0 then
                    --if menu.elements["visuals"]["crosshair_elements"]["Exploits"] then
                    render.text(
                        position.x - self.size,
                        positiony,
                        color(255, self.alpha * multiplier),
                        flags,
                        nil,
                        text
                    )
                --end
            end

                return { size = size }
            end,
        })

        crosshair:create({
            get = function(self)
                return refs.other.ping_spike:get() and
                    refs.other.ping_spike.hotkey:get()
            end,

            paint = function(self, position, flags, fn)
                local text = fn("PING")
                local size = render.measure_text(flags, text)

                local positiony = position.y

                --[[if not menu.elements["visuals"]["crosshair_elements"]["Side"] then
                    positiony = positiony - 12
                else
                    positiony = position.y
                end--]]

                if self.alpha > 0 then
                    --if menu.elements["visuals"]["crosshair_elements"]["Exploits"] then
                    render.text(
                        position.x - self.size,
                        positiony,
                        color(255, self.alpha),
                        flags,
                        nil,
                        text
                    )
                --end
            end

                return { size = size }
            end,
        })

        crosshair:create({
            get = function(self)
                return refs.other.min_damage_override[1].hotkey:get()
            end,

            paint = function(self, position, flags, fn)
                local text = fn("DMG")
                local size = render.measure_text(flags, text)

                local positiony = position.y

                --[[if not menu.elements["visuals"]["crosshair_elements"]["Side"] then
                    positiony = positiony - 12
                else
                    positiony = position.y
                end--]]

                if self.alpha > 0 then
                    --if menu.elements["visuals"]["crosshair_elements"]["Exploits"] then
                    render.text(
                        position.x - self.size,
                        positiony,
                        color(255, self.alpha),
                        flags,
                        nil,
                        text
                    )
                --end
            end

                return { size = size }
            end,
        })

        crosshair:create({
            get = function(self) end,

            paint = function(self, position, flags, fn)
                local text = fn("HC")
                local size = render.measure_text(flags, text)

                local positiony = position.y

                --[[if not menu.elements["visuals"]["crosshair_elements"]["Side"] then
                    positiony = positiony - 12
                else
                    positiony = position.y
                end--]]

                if self.alpha > 0 then
                    --if menu.elements["visuals"]["crosshair_elements"]["Exploits"] then
                    render.text(
                        position.x - self.size,
                        positiony,
                        color(255, self.alpha),
                        flags,
                        nil,
                        text
                    )
                --end
            end

                return { size = size }
            end,
        })

        crosshair:create({
            get = function(self)
                return refs.other.force_baim:get()
            end,

            paint = function(self, position, flags, fn)
                local text = fn("BA")
                local size = render.measure_text(flags, text)

                local positiony = position.y

                --[[if not menu.elements["visuals"]["crosshair_elements"]["Side"] then
                    positiony = positiony - 12
                else
                    positiony = position.y
                end--]]

                if self.alpha > 0 then
                    --if menu.elements["visuals"]["crosshair_elements"]["Exploits"] then
                    render.text(
                        position.x - self.size,
                        positiony,
                        color(255, self.alpha),
                        flags,
                        nil,
                        text
                    )
                --end
            end

                return { size = size }
            end,
        })

        crosshair:create({
            get = function(self)
                return refs.other.force_sp:get()
            end,

            paint = function(self, position, flags, fn)
                local text = fn("SP")
                local size = render.measure_text(flags, text)

                local positiony = position.y

                --[[if not menu.elements["visuals"]["crosshair_elements"]["Side"] then
                    positiony = positiony - 12
                else
                    positiony = position.y
                end--]]

                if self.alpha > 0 then
                    --if menu.elements["visuals"]["crosshair_elements"]["Exploits"] then
                    render.text(
                        position.x - self.size,
                        positiony,
                        color(255, self.alpha),
                        flags,
                        nil,
                        text
                    )
                --end
            end

                return { size = size }
            end,
        })

        crosshair:create({
            get = function(self)
                return true
            end,

            paint = function(self, position, flags, fn)
                local text = ("/ %s /"):format(fn(states[antiaim.state])) or ""
                local size = render.measure_text(flags, text)

                local positiony = position.y

                --[[if not menu.elements["visuals"]["crosshair_elements"]["Side"] and not menu.elements["visuals"]["crosshair_elements"]["Exploits"] then
                    positiony = positiony - 30
                elseif not menu.elements["visuals"]["crosshair_elements"]["Side"] then
                    positiony = positiony - 12
                elseif not menu.elements["visuals"]["crosshair_elements"]["Exploits"] then
                    positiony = positiony - 12
                end--]]

                if self.alpha > 0 then
                    --if menu.elements["visuals"]["crosshair_elements"]["Condition"] then
                    render.text(
                        position.x - self.size,
                        positiony,
                        color(255, self.alpha * 0.5),
                        flags,
                        nil,
                        text
                    )
                --end
            end

                return { size = size }
            end,
        })

        menu.checkbox(groups.antiaim)("Crosshair")(
            "visuals",
            "crosshair",
            ts.is_indicators
        )
        menu.combobox(groups.antiaim)(
            "\ncrosshair_style",
            { "Default", "Pixel", "Bold" }
        )("visuals", "crosshair_style", function()
            return ts.is_indicators() and menu.elements["visuals"]["crosshair"]
        end)
        --[[menu.multiselect(groups.antiaim)(
            "Elements", { "Side", "Exploits", "Condition" }
        )("visuals", "crosshair_elements", function()
            return ts.is_indicators() and menu.elements["visuals"]["crosshair"]
        end)--]]
        menu.slider(groups.antiaim)("Height", 5, 170, 20, true, "px", 1)(
            "visuals",
            "crosshair_height",
            function()
                return ts.is_indicators()
                    and menu.elements["visuals"]["crosshair"]
            end
        )
        menu.color_picker(groups.antiaim)("\ncrosshairg_color", color(255, 255))(
            "visuals",
            "crosshairg_color",
            function()
                return ts.is_indicators()
                    and menu.elements["visuals"]["crosshair"]
            end
        )
    end
    -- #endregion

    -- #region : Arrows
    indicators.arrows = {}
    do
        local arrows = indicators.arrows

        arrows.handle = function()
            local sc = vector(client.screen_size())
            local position = sc * 0.5

            local style = menu.elements["visuals"]["arrows_style"]
            local distance = menu.elements["visuals"]["arrows_distance"]
            if style == "Style 1" then
                local left = anim.new(
                    "arrows::left",
                    antiaim.manuals.yaw_offset == -90 and 255 or 75
                )
                render.text(
                    position.x - distance,
                    position.y,
                    pui.macros.accent:alpha_modulate(left),
                    "bcd",
                    nil,
                    "?"
                )

                local right = anim.new(
                    "arrows::right",
                    antiaim.manuals.yaw_offset == 90 and 255 or 75
                )
                render.text(
                    position.x + distance,
                    position.y,
                    pui.macros.accent:alpha_modulate(right),
                    "bcd",
                    nil,
                    "?"
                )

                return
            end

            if style == "Style 2" then
                local left = anim.new(
                    "arrows::left",
                    antiaim.manuals.yaw_offset == -90 and 255 or 75
                )
                render.text(
                    position.x - distance,
                    position.y,
                    pui.macros.accent:alpha_modulate(left),
                    "bcd",
                    nil,
                    "?"
                )

                local right = anim.new(
                    "arrows::right",
                    antiaim.manuals.yaw_offset == 90 and 255 or 75
                )
                render.text(
                    position.x + distance,
                    position.y,
                    pui.macros.accent:alpha_modulate(right),
                    "bcd",
                    nil,
                    "?"
                )

                return
            end

            if style == "Style 3" then
                local left = anim.new(
                    "arrows::left",
                    antiaim.manuals.yaw_offset == -90 and 255 or 75
                )
                render.text(
                    position.x - distance,
                    position.y,
                    pui.macros.accent:alpha_modulate(left),
                    "bcd+",
                    nil,
                    "°"
                )
                render.text(
                    position.x - distance - 9,
                    position.y,
                    pui.macros.accent:alpha_modulate(left),
                    "bcd+",
                    nil,
                    "?"
                )


                local right = anim.new(
                    "arrows::right",
                    antiaim.manuals.yaw_offset == 90 and 255 or 75
                )
                render.text(
                    position.x + distance,
                    position.y,
                    pui.macros.accent:alpha_modulate(right),
                    "bcd+",
                    nil,
                    "°"
                )
                render.text(
                    position.x + distance + 9,
                    position.y,
                    pui.macros.accent:alpha_modulate(right),
                    "bcd+",
                    nil,
                    "?"
                )

                return
            end

            if style == "TeamSkeet" then
                local inactive = color(0, 0, 0, 128)
                local active = pui.macros.accent

                local size = 9

                local left
                do
                    left = vector(position.x - 30 - distance, position.y)

                    render.line(
                        left.x + 3,
                        left.y - size,
                        left.x + 3,
                        left.y + size,
                        antiaim.data.inverter and active or inactive
                    )
                    render.triangle(
                        left.x,
                        left.y - size,
                        left.x - size * 1.4,
                        left.y,
                        left.x,
                        left.y + size,
                        antiaim.manuals.yaw_offset == -90 and active or inactive
                    )
                end

                local right
                do
                    right = vector(position.x + 30 + distance, position.y)

                    render.line(
                        right.x - 3,
                        right.y - size,
                        right.x - 3,
                        right.y + size,
                        antiaim.data.inverter and inactive or active
                    )
                    render.triangle(
                        right.x,
                        right.y - size,
                        right.x + size * 1.4,
                        right.y,
                        right.x,
                        right.y + size,
                        antiaim.manuals.yaw_offset == 90 and active or inactive
                    )
                end

                return
            end
        end

        menu.checkbox(groups.antiaim)("Arrows")(
            "visuals",
            "arrows",
            ts.is_indicators
        )
        menu.combobox(groups.antiaim)(
            "\narrows_style",
            { "Style 1", "Style 2", "Style 3", "TeamSkeet" }
        )("visuals", "arrows_style", function()
            return ts.is_indicators() and menu.elements["visuals"]["arrows"]
        end)
        menu.slider(groups.antiaim)("Arrows distance", 0, 150, 0, true, "px", 1)(
            "visuals",
            "arrows_distance",
            function()
                return ts.is_indicators() and menu.elements["visuals"]["arrows"]
            end
        )
    end
    -- #endregion

    -- #region : damage
    indicators.damage = {}
    do
        local damage = indicators.damage

        damage.handle = function()
            local sc = vector(client.screen_size())
            local position = sc * 0.5 + vector(5, -13)
            local is_damage_override =
                refs.other.min_damage_override[1].hotkey:get()
            local general_damage = is_damage_override
                    and refs.other.min_damage_override[2]:get()
                or refs.other.min_damage:get()

            local should = false
            if menu.elements["visuals"]["damage_show"] then
                should = is_damage_override
            else
                should = true
            end
            local text = tostring(general_damage)
            local size = render.measure_text("", text)
            local font = menu.elements["visuals"]["damage_style"] == "Default"
                    and "d"
                or "-d"
            if should then
                render.text(position.x, position.y, color(255), font, nil, text)
            end
        end

        menu.checkbox(groups.antiaim)("Damage")(
            "visuals",
            "damage",
            ts.is_indicators
        )
        menu.combobox(groups.antiaim)("\ndamage_style", { "Default", "Pixel" })(
            "visuals",
            "damage_style",
            function()
                return ts.is_indicators() and menu.elements["visuals"]["damage"]
            end
        )
        menu.checkbox(groups.antiaim)("Show only when toggled")(
            "visuals",
            "damage_show",
            function()
                return ts.is_indicators() and menu.elements["visuals"]["damage"]
            end
        )
    end
    -- #endregion

    indicators.handle = function()
        if not my.valid then
            return
        end

        for key, item in pairs(indicators) do
            if key ~= "handle" then
                if menu.elements["visuals"][key] then
                    item.handle()
                end
            end
        end
    end

    events.paint_ui:set(indicators.handle)
end

local logs = {
    miss_colors = {
        ["spread"] = { 255, 255, 255 },
        ["prediction error"] = { 255, 255, 255 },
        ["death"] = { 255, 255, 255 },
        ["unregistered shot"] = { 255, 255, 255 },
        ["resolver"] = { 255, 255, 255 },
        ["unknown"] = { 255, 255, 255 },
    },
    hitboxes = {
        "generic",
        "head",
        "chest",
        "stomach",
        "left arm",
        "right arm",
        "left leg",
        "right leg",
        "neck",
        "?",
        "gear",
    },
    aim_data = {},
}

do

        local function clear_developer_logs()
            for i = 1, #dev_queue do
                dev_queue[i] = nil
            end
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

        local dev_queue = { }

        local function print_dev(text)
            local should_add = (
                menu.elements["visuals"]["logger"]
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

    local function print_dev1(text)
        local x = 8
        local y = 5
        renderer.text(x, y, 255, 255, 255, 255, "-" , 0 , text)
    end


logs.aim_fire = function(shot)
    local data = {}
    data.backtrack = globals.tickcount() - shot.tick
    data.hitboxfire = logs.hitboxes[shot.hitgroup + 1] or "generic"  -- store fired hitbox
    logs.aim_data[shot.id] = data
end

logs.aim_hit = function(shot, e)
    local alive = entity.is_alive(shot.target)
    local aim_data = logs.aim_data[shot.id] or {}
    local hitboxfire = aim_data.hitboxfire or "generic"
    local name = entity.get_player_name(shot.target)
    local hitboxhit = logs.hitboxes[shot.hitgroup + 1] or "generic"
    local damage = tostring(shot.damage)
    local hp = math.max(0, entity.get_prop(shot.target, "m_iHealth"))
    local bt = globals.tickcount() - shot.tick
    local hc = math.floor(shot.hit_chance)

    local msg = ""
    if not alive then
        msg = string.format(
            "killed %s in %s ( hitchance: %s, history: %s )",
            name,
            hitboxhit,
            hc,
            bt
        )
    elseif hitboxfire ~= hitboxhit then
        msg = string.format(
            "hit %s in %s for %s damage ( remaining hp: %s, hitchance: %s, history: %s mismatch: %s)",
            name,
            hitboxhit,
            damage,
            hp,
            hc,
            bt,
            hitboxfire
        )
    else
        msg = string.format(
            "hit %s in %s for %s damage ( remaining hp: %s, hitchance: %s, history: %s )",
            name,
            hitboxhit,
            damage,
            hp,
            hc,
            bt
        )
    end

        local alive = entity.is_alive(shot.target)
        local aim_data = logs.aim_data[shot.id]
        local hitboxfire = aim_data.hitboxfire or "generic"
        local name = entity.get_player_name(shot.target)
        local hitbox = logs.hitboxes[shot.hitgroup + 1] or "generic"
        local damage = tostring(shot.damage)
        local hp = math.max(0, entity.get_prop(shot.target, "m_iHealth"))
        local bt = globals.tickcount() - shot.tick
        local hc = math.floor(shot.hit_chance)

        local msg_detailed = ""
        if alive then
            msg_detailed = string.format(
                "hit %s in %s for %s damage",
                name,
                hitbox,
                damage
            )
        else
            msg_detailed = string.format("killed %s in %s", name, hitbox)
        end
        if menu.elements["visuals"]["log_type"]["Console"] then
            print_raw("" .. msg)
        end
        if menu.elements["visuals"]["log_type"]["On screen"] then
            notify.new_bottom(255, 255, 255, { { msg_detailed, false } })
        end
    end

    logs.aim_miss = function(shot)
        local aim_data = logs.aim_data[shot.id]
        local name = entity.get_player_name(shot.target)
        local hitbox = logs.hitboxes[shot.hitgroup + 1] or "generic"
        local state = shot.reason or "unknown"
        local bt = globals.tickcount() - shot.tick
        local hc = math.floor(shot.hit_chance or 0)

        if state == "?" and bt < 0 or bt > 30 then
            state = "backtrack failure"
        end

        if state == "?" then
            state = "correction"
        end

        local msg =
            string.format("missed %s in %s due to %s", name, hitbox, state)

        local msg_detailed = string.format(
            "missed %s in %s due to %s ( hitchance: %s, history: %s)",
            name,
            hitbox,
            state,
            hc,
            bt
        )

        local miss_color = { 255, 255, 255 }
        if menu.elements["visuals"]["log_type"]["Console"] then
            print_raw("" .. msg_detailed)
        end
        if menu.elements["visuals"]["log_type"]["On screen"] then
        notify.new_bottom(
            miss_color[1],
            miss_color[2],
            miss_color[3],
            { { msg, false } }
        )
    end
    end

    logs.preview_timer = 0
    logs.preview_visible = false

    logs.show_preview = function()
        local previews = {
            { type = "kill", name = "durwin", hitbox = "generic" },
            { type = "hit", name = "durwin", hitbox = "head", damage = "99" },
            { type = "miss", name = "durwin", hitbox = "chest", reason = "resolver" },
        }

        notify.preview_notifications = {}
        for _, preview in ipairs(previews) do
            local msg, col = "", { 255, 255, 255 }

            if preview.type == "kill" then
                msg = string.format(
                    "killed %s in %s",
                    preview.name,
                    preview.hitbox
                )
            elseif preview.type == "hit" then
                msg = string.format(
                    "hit %s in %s for %s damage",
                    preview.name,
                    preview.hitbox,
                    preview.damage
                )
            elseif preview.type == "miss" then
                msg = string.format(
                    "missed %s in %s due to %s",
                    preview.name,
                    preview.hitbox,
                    preview.reason
                )
                col = logs.miss_colors[preview.reason] or col
            end
        if menu.elements["visuals"]["log_type"]["On screen"] then
            notify.new_preview(col[1], col[2], col[3], { { msg, false } })
        end
        end
    end

    logs.preview_visible = false

    logs.preview_handler = function()
        local menu_open = ui.is_menu_open()
        local logger_enabled = menu.refs["visuals"]["logger"]
            and menu.refs["visuals"]["logger"]:get()
        if not logger_enabled then
            return
        end

        if menu_open and not logs.preview_visible then
            logs.preview_visible = true
            logs.show_preview()
        elseif not menu_open and logs.preview_visible then
            logs.preview_visible = false
            notify.preview_notifications = {}
        end
    end



    client.set_event_callback("paint_ui", function()
        notify:handler()
        logs.preview_handler()
    end)

    menu.checkbox(groups.antiaim)("Log Events")(
        "visuals",
        "logger",
        ts.is_indicators
    )

    menu.multiselect(groups.antiaim)(
            "Logger type",
            { "On screen", "Console" }
        )("visuals", "log_type", function()
                return ts.is_indicators()
                    and menu.elements["visuals"]["logger"]
            end)

    menu.slider(groups.antiaim)("notification offset", -800, 171, 0, true, "px")(
        "visuals",
        "notify_offset_y",
        function() return
        ts.is_indicators() and menu.elements["visuals"]["log_type"]["On screen"]
        end)

    menu.refs["visuals"]["logger"]:set_callback(function(self)
        local enabled = self:get()
        events.aim_fire(logs.aim_fire, enabled)
        events.aim_hit(logs.aim_hit, enabled)
        events.aim_miss(logs.aim_miss, enabled)
    end, true)

            --[[indicators.slowed_down = {}
        do
            local slowed = indicators.slowed_down
            slowed.anim = 0
            slowed.preview_percent = 1
            slowed.increasing = true


            slowed.handle = function()
                local show_preview = ui.is_menu_open()
                    and menu.refs["visuals"]["slowed_down"]:get()
                local value = (
                    my.entity
                    and entity.get_prop(my.entity, "m_flVelocityModifier")
                ) or 1
                local slow = value < 1

                local sw, sh = client.screen_size()

                local visual_width, visual_height = 80, 20
                local center_x = sw * 0.5 - visual_width * 0.5
                local center_y = sh * 0.5 - 325 - visual_height * 0.5

                local x, y = client.screen_size()
                
                local pos_x = x / 2 - visual_width / 2 + 18
                local pos_y = menu.elements["visuals"]["slowed_down_y"]

                if show_preview then
                    if slowed.increasing then
                        slowed.preview_percent = slowed.preview_percent + 1
                        if slowed.preview_percent >= 100 then
                            slowed.increasing = false
                        end
                    else
                        slowed.preview_percent = slowed.preview_percent - 1
                        if slowed.preview_percent <= 1 then
                            slowed.increasing = true
                        end
                    end
                    value = 1 - (slowed.preview_percent / 100)
                end

                slowed.anim = anim.lerp(
                    slowed.anim,
                    (value < 1 or show_preview) and 1 or 0
                )

                if value < 1 or show_preview then
                    local reduction = value * 100
                    if
                        menu.refs["visuals"]["slowed_down_style"]:get()
                        == "Modern"
                    then

                        local max_width = 80 * reduction / 100

                        local gradient_wl = max_width --* reduction / 100

                        renderer.rectangle(
                            pos_x + visual_width * 0.5 - 57,
                            pos_y + visual_height * 0.5 - 2,
                            84, 34,
                            30, 30, 30, 240
                        )
                        renderer.rectangle(
                            pos_x + visual_width * 0.5 - 55,
                            pos_y + visual_height * 0.5,
                            80, 30,
                            10, 10, 10, 240
                        )
                        renderer.gradient(
                            pos_x + visual_width * 0.5 - 55,
                            pos_y + visual_height * 0.5,
                            80, 10,
                            30, 30, 30, 240, 
                            10, 10, 10, 240, false
                        )
                        rendere:rect(
                            pos_x + visual_width * 0.5- 55,
                            pos_y + visual_height * 0.5 + 27,
                            gradient_wl, 3,
                            --70, 70, 70, 240,
                            { 220, 220, 220, 240 },
                            2
                        )

                        local alph = 240 * reduction / 100

                        renderer.text(
                            pos_x + visual_width * 0.5 - 15,
                            pos_y + visual_height * 0.5 + 13,
                            220, 220, 220, 240,
                            "cb",
                            0,
                            "velocity"
                        )
                    elseif
                        menu.refs["visuals"]["slowed_down_style"]:get()
                        == "Simple"
                    then
                        renderer.text(
                            pos_x + visual_width * 0.515 - 17,
                            pos_y + visual_height * 0.5 + 7,
                            200,
                            200,
                            200,
                            255,
                            "c",
                            0,
                            string.format(
                                "velocity reduced ~ %.0f%%",
                                reduction
                            )
                        )
                    end
                end
            end

            menu.checkbox(groups.antiaim)("Slowed down indicator")(
                "visuals",
                "slowed_down",
                ts.is_indicators
            )
            menu.combobox(groups.antiaim)(
                "Indicator style",
                { "Modern", "Simple" }
            )("visuals", "slowed_down_style", function() return ts.is_indicators() and menu.elements["visuals"]["slowed_down"] end)
            
            local x, y = client.screen_size()

            menu.slider(groups.antiaim)("Indicator offset", 0, y, 0, true, "px")(
                "visuals",
                "slowed_down_y",
                function() return ts.is_indicators() and menu.elements["visuals"]["slowed_down"] end
            )
            menu.refs["visuals"]["slowed_down"]:set_callback(function(self)
                events.paint_ui(slowed.handle, self:get())
            end, true)
        end--]]

end

local visuals = {}
do
    visuals.zoom_fov = {}
    do
        local fov = visuals.zoom_fov

        fov.anim = 0

        fov.handle = function(z)
            local me = entity.get_local_player()
            local offset = menu.elements["visuals"]["fov"]
            local wpn = entity.get_player_weapon(me)
            if not wpn then
                return
            end
            local scope_level = entity.get_prop(wpn, "m_zoomLevel")
            local act = 0
            if my.scoped then
                if scope_level == 1 then
                    act = 1
                else
                    act = 2
                end
            else
                act = 0
            end
            fov.anim =
                anim.lerp(fov.anim, (my.scoped and act) and offset * act or 0)

            z.fov = z.fov - fov.anim
        end
        menu.checkbox(groups.antiaim)("Animated zoom fov")(
            "visuals",
            "zoom_fov",
            function()
                return ts.is_other()
            end
        )

        menu.slider(groups.antiaim)("\f<p>  Fov", 0, 60, 0, true, "°")(
            "visuals",
            "fov",
            function()
                return ts.is_other() and menu.elements["visuals"]["zoom_fov"]
            end
        )
        menu.refs["visuals"]["zoom_fov"]:set_callback(function(self)
            events.override_view(fov.handle, self:get())
        end, true)
    end

    visuals.show_viewmodel = {}
    do
        local view = visuals.show_viewmodel
        local match = client.find_signature(
            "client_panorama.dll",
            "\x8B\x35\xCC\xCC\xCC\xCC\xFF\x10\x0F\xB7\xC0"
        )
        local weapon_raw = ffi.cast("void****", ffi.cast("char*", match) + 2)[0]
        local ccsweaponinfo_t =
            [[struct {char __pad_0x0000[0x1cd];bool hide_vm_scope;}]]
        local get_weapon_info = vtable_thunk(
            2,
            ccsweaponinfo_t .. "*(__thiscall*)(void*, unsigned int)"
        )
        local inscope = true
        view.handle = function()
            if not my.entity then
                return
            end
            local weapon = entity.get_player_weapon(my.entity)
            if not weapon then
                return
            end
            local w_id = entity.get_prop(weapon, "m_iItemDefinitionIndex")
            local res = get_weapon_info(weapon_raw, w_id)
            res.hide_vm_scope = inscope
        end
        menu.checkbox(groups.antiaim)("Show viewmodel in scope")(
            "visuals",
            "viewmodel_scope",
            function()
                return ts.is_other()
            end
        )
        menu.refs["visuals"]["viewmodel_scope"]:set_callback(function(self)
            inscope = not self:get()
        end, true)
        events.run_command(view.handle, true)
    end

    visuals.viewmodel = {}
    do
        local viewmodel = visuals.viewmodel

        viewmodel.update = function()
            local viewmodel_fov = menu.elements["visuals"]["viewmodel"]
                    and menu.elements["visuals"]["viewmodel_fov"]
                or 68
            local viewmodel_offset_x = menu.elements["visuals"]["viewmodel"]
                    and menu.elements["visuals"]["viewmodel_x"] / 10
                or 2.5
            local viewmodel_offset_y = menu.elements["visuals"]["viewmodel"]
                    and menu.elements["visuals"]["viewmodel_y"] / 10
                or 0
            local viewmodel_offset_z = menu.elements["visuals"]["viewmodel"]
                    and menu.elements["visuals"]["viewmodel_z"] / 10
                or -1.5

            cvar.viewmodel_fov:set_raw_float(viewmodel_fov)
            cvar.viewmodel_offset_x:set_raw_float(viewmodel_offset_x)
            cvar.viewmodel_offset_y:set_raw_float(viewmodel_offset_y)
            cvar.viewmodel_offset_z:set_raw_float(viewmodel_offset_z)
        end

        viewmodel.reset = function()
            cvar.viewmodel_fov:set_raw_float(68)
            cvar.viewmodel_offset_x:set_raw_float(2.5)
            cvar.viewmodel_offset_y:set_raw_float(0)
            cvar.viewmodel_offset_z:set_raw_float(-1.5)
        end

        menu.checkbox(groups.antiaim)("Viewmodel")(
            "visuals",
            "viewmodel",
            ts.is_other
        )

        menu.slider(groups.antiaim)("\nviewmodel_fov", 0, 100, 68, true)(
            "visuals",
            "viewmodel_fov",
            function()
                return ts.is_other() and menu.elements["visuals"]["viewmodel"]
            end
        )

        menu.slider(groups.antiaim)(
            "\nviewmodel_x",
            -100,
            100,
            22,
            true,
            nil,
            0.1
        )("visuals", "viewmodel_x", function()
            return ts.is_other() and menu.elements["visuals"]["viewmodel"]
        end)

        menu.slider(groups.antiaim)(
            "\nviewmodel_y",
            -100,
            100,
            22,
            true,
            nil,
            0.1
        )("visuals", "viewmodel_y", function()
            return ts.is_other() and menu.elements["visuals"]["viewmodel"]
        end)

        menu.slider(groups.antiaim)(
            "\nviewmodel_z",
            -100,
            100,
            22,
            true,
            nil,
            0.1
        )("visuals", "viewmodel_z", function()
            return ts.is_other() and menu.elements["visuals"]["viewmodel"]
        end)

        client.set_event_callback("shutdown", viewmodel.reset)
        client.set_event_callback("paint", function()
            if menu.elements["visuals"]["viewmodel"] then
                viewmodel.update()
            end
        end)
    end

    visuals.scope = {}
    do
        local scope = visuals.scope

        scope.remove_lines = function()
            refs.other.remove_scope:override(true)
        end

        scope.handle = function()
            local scope_color = menu.elements["visuals"]["scope_accent_color"]
            local scope_inverted = menu.elements["visuals"]["scope_inverted"]
            local scope_size = menu.elements["visuals"]["scope_size"]
            local scope_gap = menu.elements["visuals"]["scope_gap"]

            refs.other.remove_scope:override(false)

            if not my.valid then
                return
            end

            local first_alpha = anim.new(
                "scope::default",
                my.scoped and not scope_inverted and scope_color.a or 0
            )
            local second_alpha = anim.new(
                "scope::inverted",
                my.scoped and scope_inverted and scope_color.a or 0
            )

            local clr = {
                scope_color:alpha_modulate(first_alpha),
                scope_color:alpha_modulate(second_alpha),
            }

            local position = vector(sc.x * 0.5, sc.y * 0.5)

            render.gradient(
                position - vector(0, scope_size + scope_gap),
                vector(1, scope_size),
                clr[2],
                clr[1]
            )

            render.gradient(
                position + vector(0, scope_gap),
                vector(1, scope_size),
                clr[1],
                clr[2]
            )

            render.gradient(
                position + vector(scope_gap, 0),
                vector(scope_size, 1),
                clr[1],
                clr[2],
                true
            )

            render.gradient(
                position - vector(scope_size + scope_gap, 0),
                vector(scope_size, 1),
                clr[2],
                clr[1],
                true
            )
        end

        menu.checkbox(groups.antiaim)("Custom Scope")(
            "visuals",
            "scope",
            ts.is_other
        )
        menu.color_picker(groups.antiaim)("\nscope_color", color(255, 100))(
            "visuals",
            "scope_accent_color",
            function()
                return ts.is_other() and menu.elements["visuals"]["scope"]
            end
        )

        menu.checkbox(groups.antiaim)("\f<p>  Inverted")(
            "visuals",
            "scope_inverted",
            function()
                return ts.is_other() and menu.elements["visuals"]["scope"]
            end
        )

        menu.slider(groups.antiaim)("\f<p>  Size/Gap", 0, 300, 50, true, "px")(
            "visuals",
            "scope_size",
            function()
                return ts.is_other() and menu.elements["visuals"]["scope"]
            end
        )

        menu.slider(groups.antiaim)("\nscope_gap", 0, 300, 5, true, "px")(
            "visuals",
            "scope_gap",
            function()
                return ts.is_other() and menu.elements["visuals"]["scope"]
            end
        )

        menu.refs["visuals"]["scope"]:set_callback(function(self)
            events.paint_ui(scope.remove_lines, self:get())
            events.paint(scope.handle, self:get())
        end, true)
    end

    visuals.aspect_ratio = {}
    do
        local aspect_ratio = visuals.aspect_ratio

        aspect_ratio.update = function()
            local aspect_ratio_value = menu.elements["visuals"]["aspect_ratio"]
                    and (menu.elements["visuals"]["aspect_ratio_value"] / 100)
                or 0

            cvar.r_aspectratio:set_raw_float(aspect_ratio_value)
        end

        aspect_ratio.reset = function()
            cvar.r_aspectratio:set_raw_float(0)
        end

        menu.checkbox(groups.antiaim)("Aspect Ratio")(
            "visuals",
            "aspect_ratio",
            ts.is_other
        )

        menu.slider(groups.antiaim)("\nratio", 80, 240, 177, true, nil, 0.01, {
            [125] = "5:4",
            [133] = "4:3",
            [150] = "3:2",
            [160] = "16:10",
            [177] = "16:9",
        })("visuals", "aspect_ratio_value", function()
            return ts.is_other() and menu.elements["visuals"]["aspect_ratio"]
        end)

        menu.refs["visuals"]["aspect_ratio"]:set_callback(function(self)
            aspect_ratio.update()

            menu.refs["visuals"]["aspect_ratio_value"]:set_callback(
                aspect_ratio.update,
                self:get()
            )

            events.shutdown(aspect_ratio.reset, self:get())
        end, true)
    end

    visuals.thirdperson = {}

    do
        local tp = visuals.thirdperson

        tp.cache = cvar.cam_idealdist:get_int()

        menu.checkbox(groups.antiaim)("Thirdperson")("visuals", "thirdperson", ts.is_other)

        tp.control = menu.slider(groups.antiaim)(
            "Thirdperson distance",
            35,
            175,
            90,
            true,
            ""
        )("visuals", "thirdpersondis", function()
            return ts.is_other() and menu.elements["visuals"]["thirdperson"]
        end)

        events.paint:set(function()
            local value = menu.refs["visuals"]["thirdpersondis"]:get()
            if menu.elements["visuals"]["thirdperson"] then
                cvar.c_mindistance:set_int(value)
                cvar.c_maxdistance:set_int(value)
            end
        end)

        defer(function()
            cvar.cam_idealdist:set_int(tp.cache)
        end)
    end
end

local miscellaneous = {}
do

    miscellaneous.features = {}
    do
        local featurs = miscellaneous.features

        menu.multiselect(groups.antiaim)("Features", { "Clan tag", "Trash talk", "Disable weapon in 3rd person", "Console cleaner", "Console filter", "Taser warning" })("visuals", "features", ts.is_misc)
    end

    miscellaneous.fast_ladder = {}
    do
        local fast_ladder = miscellaneous.fast_ladder

        fast_ladder.handle = function(cmd)
            if not my.valid then
                return
            end

            if entity.get_prop(my.weapon, "m_bPinPulled") == 1 then
                return
            end

            if my.movetype ~= 9 then
                return
            end

            if cmd.forwardmove == 0 then
                return
            end

            local side = cmd.forwardmove < 0

            cmd.pitch = 89
            cmd.yaw = math.normalize_yaw(cmd.move_yaw + 90)
            cmd.in_moveleft = side and 1 or 0
            cmd.in_moveright = side and 0 or 1
            cmd.in_forward = side and 1 or 0
            cmd.in_back = side and 0 or 1
        end

        menu.checkbox(groups.antiaim)("Fast Ladder")(
            "visuals",
            "fast_ladder",
            ts.is_misc
        )

        menu.refs["visuals"]["fast_ladder"]:set_callback(function(self)
            events.setup_command(fast_ladder.handle, self:get())
        end, true)
    end

miscellaneous.weapon_render = {}
do
    local weapon_render = miscellaneous.weapon_render
    
    local cached_color = nil 
    local was_thirdperson = false

    weapon_render.handle = function()
        local master = menu.elements["visuals"]["features"]
        if not master["Disable weapon in 3rd person"] then 
            return 
        end

        local is_thirdperson = refs.other.thirdperson:get_hotkey()

        if is_thirdperson then
            if not was_thirdperson then
                local r, g, b, a = refs.other.weaponview_color:get_color()
                cached_color = {r, g, b, a} 
                was_thirdperson = true
            end

            refs.other.weaponview_color:override(true)
            refs.other.weaponview_color:set_color(255, 255, 255, 0)
        else
            if was_thirdperson then
                refs.other.weaponview_color:override()
                
                if cached_color then
                    refs.other.weaponview_color:set_color(
                        cached_color[1], 
                        cached_color[2], 
                        cached_color[3], 
                        cached_color[4]
                    )
                end
                was_thirdperson = false
            end
        end
    end

    client.set_event_callback("paint", function()
        weapon_render.handle()
    end)

        --menu.checkbox(groups.antiaim)("Disable weapon in 3rd person")("visuals", "render", ts.is_misc)
end
    miscellaneous.clantag = {}
    do
        local clantag = miscellaneous.clantag

        clantag.tag = {
            "               ",
            "#              ",
            "#C             ",
            "#CA            ",
            "#CAB         ",
            "#CABB        ",
            "#CABBT         ",
            "#CABBTR        ",
            "#CABBTRA       ",
            "#CABBTRAL      ",
            "#CABBTRAL      ",
            "#CABBTRAL      ",
            "#CABBTRAL      ",
            "#CABBTRAL      ",
            "#CABBTRAL      ",
            "#CABBTRAL      ",
            "#CABBTRAL      ",
            "#CABBTRAL      ",
            "#CABBTRA       ",
            "#CABBTR        ",
            "#CABBT         ",
            "#CABB        ",
            "#CAB         ",
            "#CA            ",
            "#C             ",
            "#              ",
            "               ",
            "               ",
            "               ",
            "               ",
        }

        clantag.cache = nil
        clantag.set = function(str)
            if str ~= clantag.cache then
                client.set_clan_tag(str or "")
                clantag.cache = str
            end
        end

        clantag.handle = function()
            local iter = math.floor(
                math.fmod(
                    (globals.tickcount() + toticks(client.latency())) / 16,
                    #clantag.tag + 1
                ) + 1
            )
            clantag.set(clantag.tag[iter])
        end

        --[[menu.checkbox(groups.antiaim)("Clan Tag")(
            "visuals",
            "clantag",
            ts.is_misc
        )--]]

        client.set_event_callback("shutdown", function() if menu.elements["visuals"]["features"]["Clan tag"] then clantag.set() end end)
        client.set_event_callback("net_update_end", function() if menu.elements["visuals"]["features"]["Clan tag"] then clantag.handle() end end)

        --events.shutdown(clantag.set, function() return menu.elements["visuals"]["features"]["Clan tag"] end)
        --events.net_update_end(clantag.handle, function() return menu.elements["visuals"]["features"]["Clan tag"] end)
    end

    miscellaneous.trashtalk = {}
    do
        local trashtalk = miscellaneous.trashtalk

        trashtalk = {
            kill = {
                {1, "your strong",  2, "cabbtral just stronger"},
                {2, "why u so bad", 3, "go back to roblox", 4, "or minecraft idk"},
                {1, "dolbaeb", 3, "get lced on"},
                {1, "12", 2, "1`", 3, "mb"},
                {4, "123", 5, "lc fail", 6, "cabbtral save"},
                {1, "relax bro", 2, "crosshair still shaking", 4, "unlucky"},
                {2, "slow reactions", 4, "fast death"},
                {1, "warmup game?", 3, "or just bad"},
                {2, "looked promising", 4, "for half a second"},
                {1, "nice peek", 2, "wrong timing", 4, "sit"},
                {1, "????????N???? N??????R ?????? ? (?_?) ?"},
                {1, "hey guys", 2, "i repent to cabbtral.lua"},
                {3, "hi", 4, "buy cabbtral", 5, "but its private"},
            },
            death = {
                {1, "its ok", 2, "all legends die sometimes"},
                {3, "F[F[F[F[F[F[", 4, "lucky bot"},
                {3, "bro u sooooooo gooooooooddddd", 5, "no wait that was lucky"},
                {1, "chill g", 2, "you just got lucky"},
                {1, "what a great day", 3, "did dad bring vodka already?"},
            }
        }

        local function send_sentence(sent)
    for i = 2, #sent, 2 do
        local delay = sent[i - 1]
        local text  = sent[i]

        client.delay_call(delay, function()
            client.exec("say " .. text)
        end)
    end
end

local function multiselect_has(ms, value)
    for i = 1, #ms do
        if ms[i] == value then
            return true
        end
    end
    return false
end



client.set_event_callback("player_death", function(e)
    local me = entity.get_local_player()
    if not me then return end

    local attacker = client.userid_to_entindex(e.attacker)
    local victim   = client.userid_to_entindex(e.userid)
    if not attacker or not victim then return end

    local modes = menu.elements["visuals"]["trashtalktype"]

    if attacker == me and victim ~= me then
        if menu.elements["visuals"]["features"]["Trash talk"] then
        if menu.elements["visuals"]["trashtalktype"]["Kill"] then
            local list = trashtalk.kill
            local pick = list[client.random_int(1, #list)]
            send_sentence(pick)
        end
    end
        return
    end

    if victim == me and attacker ~= me then
        if menu.elements["visuals"]["features"]["Trash talk"] then
        if menu.elements["visuals"]["trashtalktype"]["Death"] then
            local list = trashtalk.death
            local pick = list[client.random_int(1, #list)]
            send_sentence(pick)
        end
    end
    end
end)

        --[[menu.checkbox(groups.antiaim)("Trashtalk")(
            "visuals",
            "trashtalk",
            ts.is_misc
        )--]]

        menu.multiselect(groups.antiaim)("Trashtalk type", {"Kill", "Death"})("visuals", "trashtalktype", function() return ts.is_misc() and menu.elements["visuals"]["features"]["Trash talk"] end)


    miscellaneous.menu = {}
    do
        local menu = miscellaneous.menu
        menu.anim = 0
        menu.handle = function()
            menu.anim = anim.lerp(menu.anim, pui.menu_open and 155 or 0)
            local screen = vector(client.screen_size())
            --render.rectangle(0, 0, screen.x, screen.y, color(15):alpha_modulate(menu.anim), 0)
        end
        events.paint_ui(menu.handle, true)
    end

    miscellaneous.taser_warn = {}
    do
        local taser_warn = miscellaneous.taser_warn

 local visuals = menu.elements["visuals"]["features"]
local get_weapon = entity.get_player_weapon
local get_classname = entity.get_classname
local w2s = renderer.world_to_screen

taser_warn.handle = function()
    if not visuals["Taser warning"] then return end
    if not my.valid then return end

    local enemy = client.current_threat()
    if not enemy then return end

    local ox, oy, oz = entity.get_origin(enemy)
    local sx, sy = w2s(ox, oy, oz)
    if not sx or not sy then return end

    local weapon = get_weapon(enemy)
    if not weapon then return end
    if get_classname(weapon) ~= "CWeaponTaser" then return end

    local x, y = entity.get_bounding_box(enemy)
    if not x or not y then return end

    renderer.circle_outline(x, y, 204, 51, 0, 255, 13, 5, 5, 13)
    renderer.circle_outline(x, y, 204, 51, 0, 200, 15, 5, 5, 15)
    renderer.circle_outline(x, y, 204, 51, 0, 150, 17, 5, 5, 17)
    renderer.circle_outline(x, y, 204, 51, 0, 100, 20, 5, 5, 20)

    renderer.rectangle(x - 4, y - 13, 4, 20, 128, 0, 0, 255)
    renderer.rectangle(x - 4, y + 10, 4, 4, 128, 0, 0, 255)
end


        client.set_event_callback("paint_ui", function()
            if menu.elements["visuals"]["features"]["Taser warning"] then
                taser_warn.handle()
            end
        end)
    end

    --[[miscellaneous.dzik_pickup = {}
    do

local TARGET_MODEL = "dzik_puszka_v3"
local MAX_DIST = 150 
local IN_USE = 32

client.set_event_callback("setup_command", function(cmd)
    local local_player = entity.get_local_player()
    if not menu.elements["visuals"]["dzik"] then return end
    if not menu.refs["visuals"]["hotkey"]:get() then return end
    if not local_player or not entity.is_alive(local_player) then return end

    local lx, ly, lz = entity.get_prop(local_player, "m_vecOrigin")
    local ox, oy, oz = entity.get_prop(local_player, "m_vecViewOffset")
    local view_pos = {lx + ox, ly + oy, lz + oz}

    local best_target = nil
    local closest_dist = MAX_DIST

    local props = entity.get_all("CPhysicsProp")
    
    for i=1, #props do
        local ent = props[i]
        local model = entity.get_model_name(ent) or ""

        if model:find(TARGET_MODEL) then
            local ex, ey, ez = entity.get_prop(ent, "m_vecOrigin")

            local dx, dy, dz = lx - ex, ly - ey, lz - ez
            local dist = math.sqrt(dx*dx + dy*dy + dz*dz)

            if dist < closest_dist then
                closest_dist = dist
                best_target = ent
            end
        end
    end

    if best_target then
        local tx, ty, tz = entity.get_prop(best_target, "m_vecOrigin")

        local dx, dy, dz = tx - view_pos[1], ty - view_pos[2], tz - view_pos[3]

        local yaw = math.deg(math.atan2(dy, dx))
        local len2d = math.sqrt(dx*dx + dy*dy)
        local pitch = math.deg(math.atan2(-dz, len2d))

        cmd.pitch = pitch
        cmd.yaw = yaw
        cmd.in_use = 1
    end
end)

    --menu.checkbox(groups.antiaim)("Auto use \vdziks\r on \vuwujka\r")("visuals", "dzik", ts.is_misc)
    --menu.hotkey(groups.antiaim)("Hotkey")("visuals", "hotkey", function() return ts.is_misc() and menu.elements["visuals"]["dzik"] end)

    end--]]

    miscellaneous.bullet_tracer = {}
    do
        local tracer = miscellaneous.bullet_tracer
        tracer.table = {}
        tracer.impact = function(e)
            if client.userid_to_entindex(e.userid) ~= my.entity then
                return
            end
            local lx, ly, lz = client.eye_position()
            tracer.table[globals.tickcount()] =
                { lx, ly, lz, e.x, e.y, e.z, globals.curtime() + 2 }
        end
        tracer.handle = function()
            local r, g, b, a = menu.refs["visuals"]["bullet_tracer_color"]:get()
            for tick, data in pairs(tracer.table) do
                if globals.curtime() <= data[7] then
                    local x1, y1 =
                        renderer.world_to_screen(data[1], data[2], data[3])
                    local x2, y2 =
                        renderer.world_to_screen(data[4], data[5], data[6])
                    if x1 ~= nil and x2 ~= nil and y1 ~= nil and y2 ~= nil then
                        renderer.line(x1, y1, x2, y2, r, g, b, a)
                    end
                end
            end
        end
        tracer.clear = function()
            tracer.table = {}
        end

        menu.checkbox(groups.antiaim)("Bullet tracer")(
            "visuals",
            "bullet_tracer",
            ts.is_misc
        )
        menu.color_picker(groups.antiaim)("\ntracer_color", color(255, 100))(
            "visuals",
            "bullet_tracer_color",
            function()
                return ts.is_misc()
                    and menu.elements["visuals"]["bullet_tracer"]
            end
        )
        menu.refs["visuals"]["bullet_tracer"]:set_callback(function(self)
            events.bullet_impact(tracer.impact, self:get())
            events.paint(tracer.handle, self:get())
            events.round_prestart(tracer.clear, self:get())
        end, true)
    end

    miscellaneous.console = {}
    do
        local console = miscellaneous.console
        console.handle = function()
            cvar.clear:invoke_callback()
        end
        --menu.checkbox(groups.antiaim)("Console cleaner")(
           -- "visuals",
           -- "console",
           -- ts.is_misc
        --)
        --[[menu.refs["visuals"]["console"]:set_callback(function(self)
            events.round_prestart(console.handle, self:get())
        end, true)--]]

        client.set_event_callback("round_prestart", function() if menu.elements["visuals"]["features"]["Console cleaner"] then console.handle() end end)
    end
    miscellaneous.filter = {}
    do
        local filter = miscellaneous.filter

        filter.enable = function()
            client.exec("con_filter_enable 1")
            client.exec("con_filter_text '[gamesense] / cabbtral '")
        end

        filter.disable = function()
            client.exec("con_filter_enable 0")
        end

        --menu.checkbox(groups.antiaim)("Console filter")(
        --    "visuals",
         --   "filter",
         --   ts.is_misc
        --)
        --[[menu.refs["visuals"]["features"]["Console filter"]:set_callback(function(self)
            if self then
                filter.enable()
            else
                filter.disable()
            end
        end, true)--]]

        client.set_event_callback("paint", function() if menu.elements["visuals"]["features"]["Console filter"] then filter.enable() else filter.disable() end end)

        events.shutdown(filter.disable)
    end
end

    miscellaneous.animations = {}
    do
        local animations = miscellaneous.animations

        animations.on_ground = {
            ["Static"] = function(ent)
                entity.set_prop(ent, "m_flPoseParameter", 1, 0)
                refs.antiaim.leg_movement:override("Always slide")
            end,
            ["Walking"] = function(ent)
                entity.set_prop(ent, "m_flPoseParameter", 0, 7)
                refs.antiaim.leg_movement:override("Never slide")
            end,
            ["Jitter"] = function(ent)
                entity.set_prop(
                    ent,
                    "m_flPoseParameter",
                    0,
                    globals.tickcount() % 4 > 1 and 0.5 or 1
                )
                refs.antiaim.leg_movement:override(
                    my.command_number % 3 == 0 and "Off" or "Always slide"
                )
            end,
        }

        animations.in_air = {
            ["Static"] = function(ent)
                entity.set_prop(ent, "m_flPoseParameter", 1, 6)
            end,
            ["Walking"] = function(ent)
                local animlayer = entity.get_animlayer(ent, 6)

                if animlayer == nil then
                    return
                end

                if
                    my.state == my.states.air
                    or my.state == my.states.air_crouch
                then
                    animlayer.m_flWeight = 1
                end
            end,
            ["Jitter"] = function(ent)
                entity.set_prop(
                    ent,
                    "m_flPoseParameter",
                    client.random_float(0.0, 1.0),
                    5
                )
                entity.set_prop(
                    ent,
                    "m_flPoseParameter",
                    client.random_float(0.0, 1.0),
                    6
                )
            end,
        }

        animations.handle = function()
            if not my.valid then
                return
            end

            local animstate = entity.get_animstate(my.entity)

            if animstate == nil then
                return
            end

            local on_ground =
                animations.on_ground[menu.elements["visuals"]["animations_on_ground"]]
            local in_air =
                animations.in_air[menu.elements["visuals"]["animations_in_air"]]

            if on_ground then
                on_ground(my.entity)
            end

            if in_air then
                in_air(my.entity)
            end

            if menu.elements["visuals"]["animations_pitch_on_land"] then
                if animstate.hit_in_ground_animation and not my.jumping then
                    entity.set_prop(my.entity, "m_flPoseParameter", 0.5, 12)
                end
            end

            if menu.elements["visuals"]["animations_sliding_slowwalk"] then
                entity.set_prop(my.entity, "m_flPoseParameter", 0, 9)
            end

            if menu.elements["visuals"]["animations_sliding_crouch"] then
                entity.set_prop(my.entity, "m_flPoseParameter", 0, 8)
            end

            if menu.elements["visuals"]["animations_earthquake"] then
                entity.get_animlayer(my.entity, 12).m_flWeight =
                    client.random_float(0.0, 1.0)
            elseif
                menu.elements["visuals"]["animations_move_lean"] > 0
                and my.velocity > 2
            then
                entity.get_animlayer(my.entity, 12).m_flWeight = menu.elements["visuals"]["animations_move_lean"]
                    * 0.01
            end
        end

        menu.checkbox(groups.antiaim)("Anim. Breaker")(
            "visuals",
            "animations",
            ts.is_other
        )
        menu.checkbox(groups.antiaim)("\f<p>  Pitch 0 on Land")(
            "visuals",
            "animations_pitch_on_land",
            function()
                return ts.is_other() and menu.elements["visuals"]["animations"]
            end
        )
        menu.checkbox(groups.antiaim)("\f<p>  Sliding Slow Walk")(
            "visuals",
            "animations_sliding_slowwalk",
            function()
                return ts.is_other() and menu.elements["visuals"]["animations"]
            end
        )
        menu.checkbox(groups.antiaim)("\f<p>  Sliding Crouch")(
            "visuals",
            "animations_sliding_crouch",
            function()
                return ts.is_other() and menu.elements["visuals"]["animations"]
            end
        )
        menu.checkbox(groups.antiaim)("\f<p>  Earthquake")(
            "visuals",
            "animations_earthquake",
            function()
                return ts.is_other() and menu.elements["visuals"]["animations"]
            end
        )
        menu.combobox(groups.antiaim)(
            "\f<p>  On Ground",
            { "Disabled", "Static", "Walking", "Jitter" }
        )("visuals", "animations_on_ground", function()
            return ts.is_other() and menu.elements["visuals"]["animations"]
        end)
        menu.combobox(groups.antiaim)(
            "\f<p>  In Air",
            { "Disabled", "Static", "Walking", "Jitter" }
        )("visuals", "animations_in_air", function()
            return ts.is_other() and menu.elements["visuals"]["animations"]
        end)
        menu.slider(groups.antiaim)(
            "\f<p>  Move Lean",
            0,
            100,
            100,
            true,
            "%",
            1,
            { [0] = "Default" }
        )("visuals", "animations_move_lean", function()
            return ts.is_other() and menu.elements["visuals"]["animations"]
        end)

        menu.refs["visuals"]["animations"]:set_callback(function(self)
            events.pre_render(animations.handle, self:get())
        end, true)
    end
end


local dragstosave = function()
    local t = {}

    for _, d in ipairs(pui_drags) do
        t[d.name] = {
            x = ui.get(ui.reference(
                "aa", "anti-aimbot angles", "cabbtral::x:" .. d.name
            )),
            y = ui.get(ui.reference(
                "aa", "anti-aimbot angles", "cabbtral::y:" .. d.name
            ))
        }
    end

    return t
end

-- #region : Update pui.setup
configs.data = pui.setup(
    {
        antiaim = menu.refs["antiaim"],
        visuals = menu.refs["visuals"],
    },
    true
)


local function save_drags_to_pui()
    local out = {}

    for _, d in ipairs(pui_drags) do
        local x_ref = ui.reference(
            "aa",
            "anti-aimbot angles",
            "cabbtral::x:" .. d.name
        )

        local y_ref = ui.reference(
            "aa",
            "anti-aimbot angles",
            "cabbtral::y:" .. d.name
        )

        out[#out + 1] = {
            name = d.name,
            x = ui.get(x_ref),
            y = ui.get(y_ref)
        }
    end

    configs.data.drag = out
end

client.set_event_callback("paint_ui", save_drags_to_pui)



-- #endregion

-- #region : Update Database
events.shutdown:set(function()
    database.write(db.name, db.data)
end)
-- #endregion-- dumped from hrisito forums by <youtube.com/@subtick> ~ rip hrisito 2025-2026
