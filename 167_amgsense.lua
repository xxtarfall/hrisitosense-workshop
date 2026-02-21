-- Title: Amgsense
-- Script ID: 167
-- Source: page_167.html
----------------------------------------

local base64 = require("gamesense/base64")
local clipboard = require("gamesense/clipboard")
local json = require("json")
local csgo_weapons = require("gamesense/csgo_weapons")
local trace = require("gamesense/trace")
local entity_lib = require("gamesense/entity")
local pui = require("gamesense/pui")
local vector = require("vector")
local ffi = require("ffi")
local utils = {}
function utils.clamp(val, min, max)
    if max < min then min, max = max, min end
    return math.max(min, math.min(max, val))
end

function utils.normalize_angle(ang)
    ang = ang % 360
    if ang > 180 then ang = ang - 360 end
    return ang
end

function utils.utf8_chars(str)
    local chars, i = {}, 1
    while i <= #str do
        local byte = string.byte(str, i)
        local char_len = byte >= 0xF0 and 4 or byte >= 0xE0 and 3 or byte >= 0xC0 and 2 or 1
        table.insert(chars, string.sub(str, i, i + char_len - 1))
        i = i + char_len
    end
    return chars
end

function utils.draw_rounded_rect(x, y, w, h, r, bg_r, bg_g, bg_b, bg_a, outline_r, outline_g, outline_b, outline_a)
    if w < 1 or h < 1 then return end
    r = math.min(r, math.floor(w / 2), math.floor(h / 2))
    if bg_a > 0 then
        renderer.rectangle(x + r, y, w - r * 2, h, bg_r, bg_g, bg_b, bg_a)
        renderer.rectangle(x, y + r, r, h - r * 2, bg_r, bg_g, bg_b, bg_a)
        renderer.rectangle(x + w - r, y + r, r, h - r * 2, bg_r, bg_g, bg_b, bg_a)
        for i = 0, r - 1 do
            local arc_w = math.floor(math.sqrt(r * r - (r - i) * (r - i)))
            renderer.rectangle(x + r - arc_w, y + i, arc_w, 1, bg_r, bg_g, bg_b, bg_a)
            renderer.rectangle(x + w - r, y + i, arc_w, 1, bg_r, bg_g, bg_b, bg_a)
            renderer.rectangle(x + r - arc_w, y + h - 1 - i, arc_w, 1, bg_r, bg_g, bg_b, bg_a)
            renderer.rectangle(x + w - r, y + h - 1 - i, arc_w, 1, bg_r, bg_g, bg_b, bg_a)
        end
    end
    if outline_a > 0 then
        local cx1, cx2 = x + r, x + w - r
        local cy1, cy2 = y + r, y + h - r
        renderer.rectangle(cx1, y, cx2 - cx1, 1, outline_r, outline_g, outline_b, outline_a)
        renderer.rectangle(cx1, y + h - 1, cx2 - cx1, 1, outline_r, outline_g, outline_b, outline_a)
        renderer.rectangle(x, cy1, 1, cy2 - cy1, outline_r, outline_g, outline_b, outline_a)
        renderer.rectangle(x + w - 1, cy1, 1, cy2 - cy1, outline_r, outline_g, outline_b, outline_a)
        renderer.circle_outline(cx1, cy1, outline_r, outline_g, outline_b, outline_a, r, 180, 0.25, 1)
        renderer.circle_outline(cx2, cy1, outline_r, outline_g, outline_b, outline_a, r, 270, 0.25, 1)
        renderer.circle_outline(cx1, cy2, outline_r, outline_g, outline_b, outline_a, r, 90, 0.25, 1)
        renderer.circle_outline(cx2, cy2, outline_r, outline_g, outline_b, outline_a, r, 0, 0.25, 1)
    end
end

function utils.distance_3d(x1, y1, z1, x2, y2, z2)
    local dx, dy, dz = x2-x1, y2-y1, z2-z1
    return math.sqrt(dx*dx + dy*dy + dz*dz)
end

function utils.table_contains(tbl, val)
    if type(tbl) ~= "table" then return false end
    for _, v in pairs(tbl) do
        if v == val then return true end
    end
    return false
end

local cvar = {
    cam_collision = cvar.cam_collision,
    c_mindistance = cvar.c_mindistance,
    c_maxdistance = cvar.c_maxdistance,
    cl_righthand = cvar.cl_righthand,
    viewmodel_fov = cvar.viewmodel_fov,
    viewmodel_offset_x = cvar.viewmodel_offset_x,
    viewmodel_offset_y = cvar.viewmodel_offset_y,
    viewmodel_offset_z = cvar.viewmodel_offset_z,
    mp_freezetime = cvar.mp_freezetime,
    sv_maxunlag = cvar.sv_maxunlag,
    sv_accelerate = cvar.sv_accelerate,
    cl_updaterate = cvar.cl_updaterate,
    sv_minupdaterate = cvar.sv_minupdaterate,
    sv_maxupdaterate = cvar.sv_maxupdaterate,
    cl_interp_ratio = cvar.cl_interp_ratio,
    cl_interp = cvar.cl_interp,
    sv_client_min_interp_ratio = cvar.sv_client_min_interp_ratio,
    sv_client_max_interp_ratio = cvar.sv_client_max_interp_ratio,
}
local function vtable_bind(module, interface, index, typedef)
    local iface = client.create_interface(module, interface) or error("invalid interface: " .. interface)
    local vtbl = ffi.cast("void***", iface)
    local fn_type = ffi.typeof(typedef)
    return function(...)
        return ffi.cast(fn_type, vtbl[0][index])(iface, ...)
    end
end
local function vtable_thunk(index, typedef)
    local fn_type = ffi.typeof(typedef)
    return function(self, ...)
        return ffi.cast(fn_type, ffi.cast("void***", self)[0][index])(self, ...)
    end
end
ffi.cdef([[
    typedef struct {
        float x;
        float y;
        float z;
    } vector_t;
    typedef struct {
        void     *vfptr;
        int      command_number;
        int      tickcount;
        vector_t viewangles;
        vector_t aimdirection;
        float    forwardmove;
        float    sidemove;
        float    upmove;
        int      buttons;
        uint8_t  impulse;
        int      weaponselect;
        int      weaponsubtype;
        int      random_seed;
        short    mousedx;
        short    mousedy;
        bool     hasbeenpredicted;
        vector_t headangles;
        vector_t headoffset;
    } cusercmd_t;
]])
local native = {
    GetClientEntity = vtable_bind("client_panorama.dll", "VClientEntityList003", 3, "void*(__thiscall*)(void*, int)"),
    get_client_entity = vtable_bind("client_panorama.dll", "VClientEntityList003", 3, "void*(__thiscall*)(void***, int)"),
}
native.animstate = {}
if not pcall(ffi.typeof, "bt_animstate_t") then
    ffi.cdef([[
        typedef struct {
            char __0x108[0x108];
            bool on_ground;
            bool hit_in_ground_animation;
        } bt_animstate_t, *pbt_animstate_t;
    ]])
end
native.animstate.offset = 39264
function native.animstate.get(self, entity_index)
    local ent = native.get_client_entity(entity_index)
    if not ent then return nil end
    return ffi.cast("pbt_animstate_t*", ffi.cast("uintptr_t", ent) + native.animstate.offset)[0]
end
native.user_input = {}
if not pcall(ffi.typeof, "bt_cusercmd_t") then
    ffi.cdef([[
        typedef struct {
            struct bt_cusercmd_t (*cusercmd)();
            int     command_number;
            int     tick_count;
            float   view[3];
            float   aim[3];
            float   move[3];
            int     buttons;
        } bt_cusercmd_t;
        typedef bt_cusercmd_t*(__thiscall* bt_get_usercmd)(void* input, int, int command_number);
    ]])
end
local user_input_sig = client.find_signature("client.dll", "\xB9\xCC\xCC\xCC\xCC\x8B\x40\x38\xFF\xD0\x84\xC0\x0F\x85")
if user_input_sig then
    native.user_input.vtbl = ffi.cast("void***", ffi.cast("void**", ffi.cast("uintptr_t", user_input_sig) + 1)[0])
    native.user_input.location = ffi.cast("bt_get_usercmd", native.user_input.vtbl[0][8])
    function native.user_input.get_command(command_number)
        return native.user_input.location(native.user_input.vtbl, 0, command_number)
    end
end
client.exec("play ui/beep07")
client.exec("clear")
steam_name = panorama.open("CSGOHud").MyPersonaAPI.GetName()
local aa_ref = {
    enabled = ui.reference('AA', 'Anti-aimbot angles', 'Enabled'),
    pitch = (function()
        local ref1, ref2 = ui.reference('AA', 'Anti-aimbot angles', 'pitch')
        return {ref1, ref2}
    end)(),
    yaw_base = ui.reference('AA', 'Anti-aimbot angles', 'Yaw base'),
    yaw = (function()
        local ref1, ref2 = ui.reference('AA', 'Anti-aimbot angles', 'Yaw')
        return {ref1, ref2}
    end)(),
    yaw_jitter = (function()
        local ref1, ref2 = ui.reference('AA', 'Anti-aimbot angles', 'Yaw jitter')
        return {ref1, ref2}
    end)(),
    body_yaw = (function()
        local ref1, ref2 = ui.reference('AA', 'Anti-aimbot angles', 'Body yaw')
        return {ref1, ref2}
    end)(),
    freestanding_body_yaw = ui.reference('AA', 'Anti-aimbot angles', 'Freestanding body yaw'),
    freestanding = (function()
        local ref1, ref2 = ui.reference('AA', 'Anti-aimbot angles', 'Freestanding')
        return {ref1, ref2}
    end)(),
    edge_yaw = ui.reference('AA', 'Anti-aimbot angles', 'Edge yaw'),
    roll = (function()
        local ref1, ref2 = ui.reference('AA', 'Anti-aimbot angles', 'Roll')
        return {ref1, ref2}
    end)(),
}
local function hide_aa(show)
    for _, ref in pairs(aa_ref) do
        if type(ref) == "table" then
            for _, r in pairs(ref) do
                ui.set_visible(r, show)
            end
        else
            ui.set_visible(ref, show)
        end
    end
end
local state_list = {
    "Global",
    "Stand",
    "Move",
    "Crouch",
    "C-Move",
    "Air",
    "C-Air",
    "Slow",
    "Safe",
    "Fakelag",
    "Freestand",
    "Manual",
    "Use"
}
local pui_group = pui.group("AA", "anti-aimbot angles")
local show_tab
local menu = {}

menu.welcome_label = pui_group:label("Welcome to AMGSENSE")

menu.tab = pui_group:combobox("\n\aFFFFFF00 ", {
    "\u{E148} Info",
    "\u{E149} Ragebot",
    string.char(0xEE, 0x87, 0xA0) .. "  Anti-Aim",
    "\u{E2B1} Visual",
    string.char(0xEE, 0x87, 0xAC) .. " Misc",
    string.char(0xEE, 0x87, 0x81) .. " Config"
})
menu.info = {
    title = pui_group:label("═══════════════════════════════"),
    welcome = pui_group:label("User: " .. steam_name),
    spacer1 = pui_group:label(" "),
    script_name = pui_group:label("Script: AMGSENSE"),
    version = pui_group:label("Version: RECODE"),
    spacer2 = pui_group:label(" "),
    updated = pui_group:label("Updated: 2025.01.12"),
    spacer3 = pui_group:label(" "),
    features = pui_group:label("Features: Advanced Anti-Aim | Ragebot | Visuals"),
    spacer4 = pui_group:label(" "),
    footer = pui_group:label("═══════════════════════════════"),
}
local hideshots_weapon_list = { 'Auto Snipers', 'AWP', 'Scout', 'Desert Eagle', 'Pistols', 'SMG', 'Rifles' }
local hideshots_state_list = { 'Stand', 'Move', 'Crouch', 'C-Move', 'Air', 'C-Air', 'Slow' }
menu.ragebot = {
    dormant_aimbot = pui_group:checkbox("Dormant Aimbot"),
    unsafe_charge = pui_group:checkbox("Unsafe Charge"),
    hideshots_enabled = pui_group:checkbox("Auto Hide Shots"),
    hideshots_weapons = pui_group:multiselect("  Weapons", hideshots_weapon_list),
    hideshots_states = pui_group:multiselect("  States", hideshots_state_list),
    air_stop_enabled = pui_group:checkbox("Air Stop"),
    air_stop_multi_hitbox = pui_group:checkbox("  Multi Hitbox"),
    air_stop_range = pui_group:slider("  Stop Range", 0, 500, 400, true, "u"),
    peekbot_enabled = pui_group:hotkey("Peek Bot"),
    peekbot_teleport = pui_group:hotkey("  Teleport Bot"),
    peekbot_range = pui_group:slider("  Peek Range", 0, 80, 45, true, "u", 1),
}
local rage_refs = {
    rage_enabled = pui.reference("RAGE", "Aimbot", "Enabled"),
    double_tap = {ui.reference("Rage", "Aimbot", "Double tap")},
    duck_peek_assist = pui.reference("Rage", "Other", "Duck peek assist"),
}
local onshot_antiaim_ref = {ui.reference("AA", "Other", "On shot anti-aim")}
local slowmotion_checkbox_ref, slowmotion_hotkey_ref = ui.reference("AA", "Other", "Slow motion")
local slowmotion_limit_ref = ui.new_slider("AA", "Other", "Slow motion limit", 1, 57, 50, true, "", 1, {[57] = "Max"})
local math_sqrt = math.sqrt
local air_stop = {}
air_stop.last_speed = 0
air_stop.stop_frames = 0
air_stop.normalize_angle = utils.normalize_angle  
air_stop.get_distance = utils.distance_3d  
function air_stop.is_weapon_enabled(me)
    local weapon = entity.get_prop(me, "m_hActiveWeapon")
    if not weapon then return false end
    local classname = entity.get_classname(weapon)
    return classname == "CWeaponSSG08"
end
function air_stop.will_be_visible_soon(me)
    local enemies = entity.get_players(true)
    if not enemies then return false end
    local eye_x, eye_y, eye_z = client.eye_position()
    local vx = entity.get_prop(me, "m_vecVelocity[0]")
    local vy = entity.get_prop(me, "m_vecVelocity[1]")
    local vz = entity.get_prop(me, "m_vecVelocity[2]")
    if not vx or not vy or not vz then return false end
    local tickrate = globals.tickinterval()
    if tickrate == 0 then tickrate = 0.015625 end
    local hitboxes = menu.ragebot.air_stop_multi_hitbox:get() and {2, 0} or {2}
    local max_range = menu.ragebot.air_stop_range:get()
    local vx_tick = vx * tickrate
    local vy_tick = vy * tickrate
    local vz_tick = vz * tickrate
    for i = 1, #enemies do
        local e = enemies[i]
        if entity.is_alive(e) and not entity.is_dormant(e) then
            local e_x, e_y, e_z = entity.get_prop(e, "m_vecOrigin")
            local dist = air_stop.get_distance(eye_x, eye_y, eye_z, e_x, e_y, e_z)
            if dist <= max_range then
                for _, hb_id in ipairs(hitboxes) do
                    local hx, hy, hz = entity.hitbox_position(e, hb_id)
                    if hx then
                        local fraction, entindex = client.trace_line(me, eye_x, eye_y, eye_z, hx, hy, hz)
                        if fraction == 1 or entindex == e then return true end
                        local pred_x = eye_x + vx_tick
                        local pred_y = eye_y + vy_tick
                        local pred_z = eye_z + vz_tick
                        local frac, ent = client.trace_line(me, pred_x, pred_y, pred_z, hx, hy, hz)
                        if frac == 1 or ent == e then return true end
                    end
                end
            end
        end
    end
    return false
end
function air_stop.process(cmd)
    if not menu.ragebot.air_stop_enabled:get() then return end
    local me = entity.get_local_player()
    if not me or not entity.is_alive(me) then return end
    if not air_stop.is_weapon_enabled(me) then return end
    local flags = entity.get_prop(me, "m_fFlags")
    if not flags or bit.band(flags, 1) == 1 then 
        air_stop.stop_frames = 0
        return 
    end
    if not air_stop.will_be_visible_soon(me) then 
        air_stop.stop_frames = 0
        return 
    end
    local vx = entity.get_prop(me, "m_vecVelocity[0]")
    local vy = entity.get_prop(me, "m_vecVelocity[1]")
    local speed = math_sqrt(vx * vx + vy * vy)
    if speed <= 0 then 
        air_stop.stop_frames = 0
        return 
    end
    local _, yaw = client.camera_angles()
    local vel_yaw = math.deg(math.atan2(vy, vx))
    local diff = air_stop.normalize_angle(yaw - vel_yaw)
    local move_yaw = math.rad(diff)
    local base_force = 600
    local force_limit = -base_force
    local speed_multiplier = 1 + (speed / 500) * 0.2
    air_stop.stop_frames = air_stop.stop_frames + 1
    if air_stop.stop_frames > 3 then air_stop.stop_frames = 3 end
    local frame_multiplier = 1 + (air_stop.stop_frames - 1) * 0.05
    local accel_multiplier = 1
    if speed > air_stop.last_speed then
        accel_multiplier = 1.1
    end
    air_stop.last_speed = speed
    force_limit = force_limit * speed_multiplier * frame_multiplier * accel_multiplier
    if force_limit < -650 then force_limit = -650 end
    local cos_yaw = math.cos(move_yaw)
    local sin_yaw = math.sin(move_yaw)
    cmd.forwardmove = cos_yaw * force_limit
    cmd.sidemove = sin_yaw * force_limit
    local boost = force_limit * 0.05
    cmd.forwardmove = cmd.forwardmove + cos_yaw * boost
    cmd.sidemove = cmd.sidemove + sin_yaw * boost
    local block_mask = bit.bnot(bit.bor(8, 16, 512, 1024))
    cmd.buttons = bit.band(cmd.buttons, block_mask)
    cmd.in_duck = 1  
    cmd.in_speed = 1 
end
local peekbot = {
    last_tick = 0,
    active = false,
    last_point = vector(),
    origin = vector(),
    renderpoints = vector(),
    debug_info = {},
    stuck_check = {
        last_pos = vector(),
        stuck_ticks = 0,
        last_check_tick = 0
    }
}
local HITBOX = {
    HEAD = 0, NECK = 1, PELVIS = 2, STOMACH = 3, LOWER_CHEST = 4, CHEST = 5, UPPER_CHEST = 6,
    RIGHT_THIGH = 7, LEFT_THIGH = 8, RIGHT_CALF = 9, LEFT_CALF = 10, RIGHT_FOOT = 11, LEFT_FOOT = 12,
    RIGHT_HAND = 13, LEFT_HAND = 14, RIGHT_UPPER_ARM = 15, LEFT_UPPER_ARM = 16, RIGHT_FOREARM = 17, LEFT_FOREARM = 18
}
local HITGROUP = {
    GENERIC = 0, HEAD = 1, CHEST = 2, STOMACH = 3, LEFTARM = 4, RIGHTARM = 5, LEFTLEG = 6, RIGHTLEG = 7, GEAR = 10
}
local hitbox_to_hitgroup = {
    [HITBOX.HEAD] = HITGROUP.HEAD, [HITBOX.NECK] = HITGROUP.HEAD, [HITBOX.PELVIS] = HITGROUP.STOMACH,
    [HITBOX.STOMACH] = HITGROUP.STOMACH, [HITBOX.LOWER_CHEST] = HITGROUP.CHEST, [HITBOX.CHEST] = HITGROUP.CHEST,
    [HITBOX.UPPER_CHEST] = HITGROUP.CHEST, [HITBOX.RIGHT_THIGH] = HITGROUP.RIGHTLEG, [HITBOX.LEFT_THIGH] = HITGROUP.LEFTLEG,
    [HITBOX.RIGHT_CALF] = HITGROUP.RIGHTLEG, [HITBOX.LEFT_CALF] = HITGROUP.LEFTLEG, [HITBOX.RIGHT_FOOT] = HITGROUP.RIGHTLEG,
    [HITBOX.LEFT_FOOT] = HITGROUP.LEFTLEG, [HITBOX.RIGHT_HAND] = HITGROUP.RIGHTARM, [HITBOX.LEFT_HAND] = HITGROUP.LEFTARM,
    [HITBOX.RIGHT_UPPER_ARM] = HITGROUP.RIGHTARM, [HITBOX.LEFT_UPPER_ARM] = HITGROUP.LEFTARM,
    [HITBOX.RIGHT_FOREARM] = HITGROUP.RIGHTARM, [HITBOX.LEFT_FOREARM] = HITGROUP.LEFTARM
}
local priority_hitboxes = {HITBOX.HEAD, HITBOX.UPPER_CHEST, HITBOX.STOMACH}
local pb_clamp = utils.clamp 
local function pb_get_damage()
    local mindmg_ref = ui.reference("rage", "aimbot", "minimum damage")
    local ovr_ref = {ui.reference("rage", "aimbot", "minimum damage override")}
    local base_dmg = ui.get(mindmg_ref)
    if ui.get(ovr_ref[1]) and ui.get(ovr_ref[2]) then return ui.get(ovr_ref[3]) end
    return base_dmg
end
local function pb_get_lerp_time()
    local updaterate = cvar.cl_updaterate:get_int()
    local min_updaterate = cvar.sv_minupdaterate:get_int()
    local max_updaterate = cvar.sv_maxupdaterate:get_int()
    if min_updaterate and max_updaterate then updaterate = max_updaterate end
    local ratio = cvar.cl_interp_ratio:get_float()
    if ratio == 0 then ratio = 1 end
    local interp = cvar.cl_interp:get_float()
    local min_ratio = cvar.sv_client_min_interp_ratio:get_float()
    local max_ratio = cvar.sv_client_max_interp_ratio:get_float()
    if min_ratio and max_ratio and min_ratio ~= 1 then ratio = pb_clamp(ratio, min_ratio, max_ratio) end
    return math.max(interp, ratio / updaterate)
end
local pb_native = {
    GetNetChannelInfo = vtable_bind("engine.dll", "VEngineClient014", 78, "void* (__thiscall*)(void* ecx)"),
    GetLatency = vtable_thunk(9, "float(__thiscall*)(void*, int)")
}
local function pb_get_max_backtrack_ticks()
    local netchan = pb_native.GetNetChannelInfo()
    if not netchan then return 0 end
    local maxunlag = cvar.sv_maxunlag:get_float()
    local curtime_delta = globals.curtime() - math.floor(entity.get_prop(entity.get_local_player(), "m_nTickBase") * globals.tickinterval() - maxunlag)
    local latency_in = pb_native.GetLatency(netchan, 0)
    local latency_out = pb_native.GetLatency(netchan, 1)
    local lerp = pb_clamp(latency_in + latency_out + pb_get_lerp_time(), 0, maxunlag)
    return pb_clamp(maxunlag + lerp * 2, 0, curtime_delta) / globals.tickinterval()
end
local function pb_can_fire()
    local lp = entity.get_local_player()
    local weapon = entity.get_player_weapon(lp)
    if not weapon then return false end
    local wpn_data = csgo_weapons(weapon)
    if not wpn_data then return false end
    if wpn_data.type == "knife" or wpn_data.type == "grenade" or wpn_data.type == "c4" or wpn_data.type == "taser" then return false end
    if math.max(entity.get_prop(weapon, "m_flNextPrimaryAttack"), entity.get_prop(lp, "m_flNextAttack")) - globals.tickinterval() - globals.curtime() >= 0 then return false end
    if entity.get_prop(weapon, "m_zoomLevel") ~= nil and entity.get_prop(weapon, "m_zoomLevel") == 0 and (wpn_data.type == "sniper" or wpn_data.type == "sniperrifle") then return false end
    return true
end
local function pb_get_threat_info()
    local lp = entity.get_local_player()
    local threat = client.current_threat()
    if not threat or entity.is_dormant(threat) then return nil end
    local hitboxes = {}
    for i = 0, 18 do
        local hx, hy, hz = entity.hitbox_position(threat, i)
        if hx then hitboxes[i] = vector(hx, hy, hz) end
    end
    local lp_origin = vector(entity.get_origin(lp))
    local threat_origin = vector(entity.get_origin(threat))
    local _, angle = lp_origin:to(threat_origin):angles()
    return {ent = threat, pos = threat_origin, hitboxes = hitboxes, angle = angle, health = entity.get_prop(threat, "m_iHealth") or 100}
end
local function pb_accelerate(wish_dir, wish_speed, velocity)
    local current_speed = wish_dir.x * velocity.x + wish_dir.y * velocity.y + wish_dir.z * velocity.z
    local add_speed = wish_speed - current_speed
    if add_speed > 0 then
        local accel_speed = cvar.sv_accelerate:get_float() * globals.tickinterval() * math.max(250, wish_speed)
        if add_speed < accel_speed then accel_speed = add_speed end
        velocity = velocity + accel_speed * wish_dir
    end
    return velocity
end
local function pb_simulate_move(wish_dir, velocity)
    local lp = entity.get_local_player()
    local max_speed = entity.get_prop(lp, "m_flMaxspeed")
    velocity = pb_accelerate(wish_dir, 450, velocity)
    if velocity:lengthsqr() > max_speed^2 then velocity = velocity / velocity:length() * max_speed end
    return velocity
end
local function pb_predict_path(origin, ticks, lp, wish_dir)
    local velocity = vector(entity.get_prop(lp, "m_vecVelocity"))
    local points = {}
    for i = 1, ticks do
        velocity = pb_simulate_move(wish_dir, velocity)
        origin = origin + velocity * globals.tickinterval()
        points[i] = origin
    end
    return points
end
local function pb_generate_side_points(threat_info, max_ticks, offset_ticks)
    local lp = entity.get_local_player()
    local all_points = {}
    local user_range = menu.ragebot.peekbot_range:get()
    local max_speed = entity.get_prop(lp, "m_flMaxspeed") or 250
    local tick_interval = globals.tickinterval()
    local required_ticks = math.floor(user_range / (max_speed * tick_interval))
    local reduced_ticks = math.min(required_ticks, max_ticks - offset_ticks, 24)
    for _, side_angle in ipairs({90, -90}) do
        local wish_dir = vector():init_from_angles(0, threat_info.angle + side_angle, 0)
        local path_points = pb_predict_path(peekbot.origin, reduced_ticks, lp, wish_dir)
        for _, point in ipairs(path_points) do table.insert(all_points, point) end
    end
    return all_points
end
local function pb_calculate_hitbox_damage(lp, eye_pos, target, hitbox_idx, hitbox_pos)
    if not hitbox_pos then return 0, nil end
    local hitgroup = hitbox_to_hitgroup[hitbox_idx] or HITGROUP.CHEST
    local hit_ent, raw_dmg = client.trace_bullet(lp, eye_pos.x, eye_pos.y, eye_pos.z, hitbox_pos.x, hitbox_pos.y, hitbox_pos.z)
    if hit_ent == target and raw_dmg and raw_dmg > 0 then
        local scaled_dmg = client.scale_damage(target, hitgroup, raw_dmg)
        return scaled_dmg, hitbox_pos
    end
    return 0, nil
end
local function pb_scan_all_hitboxes(lp, eye_pos, threat_info)
    local best_result = {damage = 0, hitbox_idx = -1, point = nil}
    for _, hitbox_idx in ipairs(priority_hitboxes) do
        local hitbox_pos = threat_info.hitboxes[hitbox_idx]
        if hitbox_pos then
            local dmg, point = pb_calculate_hitbox_damage(lp, eye_pos, threat_info.ent, hitbox_idx, hitbox_pos)
            if dmg > best_result.damage then
                best_result.damage = dmg
                best_result.point = point
                best_result.hitbox_idx = hitbox_idx
            end
        end
    end
    return best_result
end
local function pb_find_best_peek_point(threat_info, points, sample_count)
    local lp = entity.get_local_player()
    local lp_origin = vector(entity.get_origin(lp))
    local total_points = #points
    local best = {damage = 0, ticks = 0, point = nil, hitbox = nil}
    if total_points == 0 then return nil end
    local view_offset = entity.get_prop(lp, "m_vecViewOffset[2]") or 64
    local step = math.max(2, math.floor(total_points / sample_count))
    local teammates = {}
    for _, player in ipairs(entity.get_players()) do
        if not entity.is_enemy(player) then teammates[#teammates + 1] = player end
    end
    local mins = vector(entity.get_prop(lp, "m_vecMins"))
    local maxs = vector(entity.get_prop(lp, "m_vecMaxs"))
    local center_offset = vector((mins.x + maxs.x) / 2, (mins.y + maxs.y) / 2, (mins.z + maxs.z) / 2 + 10)
    for i = 1, total_points, step do
        local idx = pb_clamp(i, 1, total_points)
        local start_pos = lp_origin + center_offset
        local end_pos = points[idx] + center_offset
        local result = trace.hull(start_pos, end_pos, mins, maxs, {type = "TRACE_EVERYTHING", mask = "MASK_SHOT", skip = teammates})
        local test_point = result.end_pos - center_offset
        peekbot.renderpoints = test_point
        local eye_pos = test_point + vector(0, 0, view_offset)
        local scan_result = pb_scan_all_hitboxes(lp, eye_pos, threat_info)
        if scan_result.damage >= threat_info.health then
            return {damage = scan_result.damage, point = test_point, hitbox = scan_result.point, hitbox_idx = scan_result.hitbox_idx, ticks = idx > total_points / 2 and (idx - total_points / 2) or idx}
        end
        if scan_result.damage > best.damage then
            best.damage = scan_result.damage
            best.point = test_point
            best.hitbox = scan_result.point
            best.hitbox_idx = scan_result.hitbox_idx
            best.ticks = idx
        end
    end
    if best.ticks > total_points / 2 then best.ticks = best.ticks - total_points / 2 end
    if not best.point or best.damage <= 0 then return nil end
    return best
end
local function pb_calculate_peek(threat_info)
    if not threat_info then 
        return nil 
    end
    if not pb_can_fire() then 
        return nil 
    end
    local lp = entity.get_local_player()
    local lp_pos = vector(entity.get_origin(lp))
    local distance_to_target = lp_pos:dist(threat_info.pos)
    if distance_to_target > 2000 then 
        return nil 
    end
    local max_ticks = pb_get_max_backtrack_ticks()
    if max_ticks <= 0 then 
        return nil 
    end
    local offset_ticks = max_ticks > 24 and 12 or 6
    local side_points = pb_generate_side_points(threat_info, max_ticks, offset_ticks)
    if #side_points == 0 then 
        return nil 
    end
    peekbot.available_points = side_points
    local sample_count = 4
    local best_peek = pb_find_best_peek_point(threat_info, side_points, sample_count)
    if not best_peek then 
        return nil 
    end
    local min_damage = pb_get_damage()
    local target_health = threat_info.health
    if best_peek.damage <= 0 then 
        return nil 
    end
    if best_peek.damage < min_damage * 0.3 then
        return nil
    end
    peekbot.debug_info = {
        damage = best_peek.damage, 
        hitbox_idx = best_peek.hitbox_idx, 
        min_damage = min_damage, 
        target_health = target_health,
        distance = distance_to_target
    }
    return {
        tick_time = best_peek.ticks, 
        tick = max_ticks - offset_ticks, 
        point = best_peek.point, 
        hitbox = best_peek.hitbox, 
        target = threat_info.ent,
        damage = best_peek.damage
    }
end
local function pb_move_to_point(cmd, target_point)
    local lp = entity.get_local_player()
    local lp_pos = vector(entity.get_origin(lp))
    local distance = lp_pos:dist(target_point)
    if distance < 5 then
        peekbot.active = false
        return
    end
    local _, yaw = lp_pos:to(target_point):angles()
    cmd.in_forward = 1
    cmd.in_back = 0
    cmd.in_moveleft = 0
    cmd.in_moveright = 0
    cmd.in_speed = 0
    cmd.forwardmove = 800
    cmd.sidemove = 0
    cmd.move_yaw = yaw
end

function peekbot.is_enemy_visible(lp, threat_ent)
    if not threat_ent or not entity.is_alive(threat_ent) then return false end
    local eye_x, eye_y, eye_z = client.eye_position()
    for _, hb_id in ipairs(priority_hitboxes) do
        local hx, hy, hz = entity.hitbox_position(threat_ent, hb_id)
        if hx then
            local fraction, entindex = client.trace_line(lp, eye_x, eye_y, eye_z, hx, hy, hz)
            if fraction == 1 or entindex == threat_ent then
                return true
            end
        end
    end
    return false
end

function peekbot.stop_movement(cmd)
    cmd.forwardmove = 0
    cmd.sidemove = 0
    cmd.in_forward = 0
    cmd.in_back = 0
    cmd.in_moveleft = 0
    cmd.in_moveright = 0
    cmd.in_speed = 0
end
local function pb_is_on_ground()
    local lp = entity.get_local_player()
    local flags = entity.get_prop(lp, "m_fFlags")
    return bit.band(flags, 1) ~= 0
end
local last_calc_tick = 0
local peekbot_last_target_pos = nil
local peekbot_movement_start_tick = 0
local function pb_validate_target(lp, threat_info)
    if not threat_info or not threat_info.ent then return false end
    if not entity.is_alive(threat_info.ent) or entity.is_dormant(threat_info.ent) then return false end
    if peekbot_last_target_pos then
        local current_pos = threat_info.pos
        local distance_moved = peekbot_last_target_pos:dist(current_pos)
        if distance_moved > 150 then
            return false
        end
    end
    return true
end
local function pb_should_abort_movement(lp, threat_info, target_point)
    if not threat_info or not threat_info.ent then return true end
    local current_tick = globals.tickcount()
    if current_tick - peekbot_movement_start_tick > 256 then
        return true
    end
    local lp_pos = vector(entity.get_origin(lp))
    if current_tick - peekbot.stuck_check.last_check_tick >= 16 then
        local distance_moved = lp_pos:dist(peekbot.stuck_check.last_pos)
        if distance_moved < 3 then
            peekbot.stuck_check.stuck_ticks = peekbot.stuck_check.stuck_ticks + 1
            if peekbot.stuck_check.stuck_ticks >= 5 then
                peekbot.stuck_check.stuck_ticks = 0
                return true
            end
        else
            peekbot.stuck_check.stuck_ticks = 0
        end
        peekbot.stuck_check.last_pos = lp_pos
        peekbot.stuck_check.last_check_tick = current_tick
    end
    local distance_to_target = lp_pos:dist(target_point)
    local user_range = menu.ragebot.peekbot_range:get()
    if distance_to_target > user_range * 2 then
        return true
    end
    return false
end
function peekbot.run(cmd)
    if not menu.ragebot.peekbot_enabled:get() then
        peekbot.active = false
        peekbot_last_target_pos = nil
        return
    end
    local lp = entity.get_local_player()
    if not lp or not entity.is_alive(lp) then 
        peekbot.active = false
        peekbot_last_target_pos = nil
        return 
    end
    if not pb_is_on_ground() then return end
    peekbot.origin = vector(entity.get_origin(lp))
    local threat_info = pb_get_threat_info()
    
    if threat_info and threat_info.ent and peekbot.is_enemy_visible(lp, threat_info.ent) then
        peekbot.stop_movement(cmd)
        peekbot.active = false
        peekbot_last_target_pos = nil
        return
    end
    
    if peekbot.active then
        local should_abort = pb_should_abort_movement(lp, threat_info, peekbot.last_point)
        if should_abort then
            peekbot.stop_movement(cmd)
            peekbot.active = false
            peekbot_last_target_pos = nil
            return
        end
        if not pb_validate_target(lp, threat_info) then
            peekbot.active = false
            peekbot_last_target_pos = nil
            return
        end
        if peekbot.last_tick - globals.tickcount() < 0 then
            peekbot.active = false
            peekbot_last_target_pos = nil
            return
        end
        
        if threat_info and threat_info.ent and peekbot.is_enemy_visible(lp, threat_info.ent) then
            peekbot.stop_movement(cmd)
            peekbot.active = false
            peekbot_last_target_pos = nil
            return
        end
        
        pb_move_to_point(cmd, peekbot.last_point)
        local velocity = vector(entity.get_prop(lp, "m_vecVelocity")):length2d()
        if velocity > 5 and menu.ragebot.peekbot_teleport:get() then 
            cmd.discharge_pending = true 
        end
    else
        local current_tick = globals.tickcount()
        if current_tick - last_calc_tick >= 2 then
            last_calc_tick = current_tick
            local peek_data = pb_calculate_peek(threat_info)
            if peek_data then
                peekbot.tick_time = peek_data.tick_time
                peekbot.last_tick = peek_data.tick + current_tick
                peekbot.last_target = threat_info.ent
                peekbot.last_point = peek_data.point
                peekbot.last_hitbox = peek_data.hitbox
                peekbot.active = true
                peekbot_last_target_pos = threat_info.pos
                peekbot_movement_start_tick = current_tick
            end
        end
    end
end
local function modify_velocity(cmd, goalspeed)
    if goalspeed <= 0 then
        return
    end
    local minimalspeed = math_sqrt((cmd.forwardmove * cmd.forwardmove) + (cmd.sidemove * cmd.sidemove))
    if minimalspeed <= 0 then
        return
    end
    if cmd.in_duck == 1 then
        goalspeed = goalspeed * 2.94117647
    end
    if minimalspeed <= goalspeed then
        return
    end
    local speedfactor = goalspeed / minimalspeed
    cmd.forwardmove = cmd.forwardmove * speedfactor
    cmd.sidemove = cmd.sidemove * speedfactor
end
menu.visual = {
    visual_category = pui_group:combobox("Category", {"HUD", "Logs", "World", "Effects"}),
    watermark_enabled = pui_group:checkbox("Watermark"),
    watermark_color = pui_group:color_picker("  Color", 164, 178, 241, 255),
    spectators_enabled = pui_group:checkbox("Spectator List"),
    spectators_color = pui_group:color_picker("  Color", 164, 178, 241, 255),
    hotkeys_enabled = pui_group:checkbox("Hotkeys Display"),
    hotkeys_color = pui_group:color_picker("  Color", 164, 178, 241, 255),
    crosshair_enabled = pui_group:checkbox("Crosshair Indicators"),
    crosshair_text_color = pui_group:color_picker("  Text Color", 255, 255, 255, 255),
    crosshair_glow_color = pui_group:color_picker("  Glow Color", 164, 178, 241, 255),
    damage_indicator = pui_group:checkbox("Damage Indicator"),
    logs_enabled = pui_group:checkbox("Aimbot Logs"),
    logs_select = pui_group:multiselect("  Output", {"Notify", "Screen", "Console"}),
    logs_color_hit = pui_group:color_picker("  Hit Color", 164, 178, 241, 255),
    logs_color_miss = pui_group:color_picker("  Miss Color", 255, 125, 150, 255),
    logs_offset = pui_group:slider("Offset", 30, 1000, 200, true, "px", 2),
    logs_duration = pui_group:slider("Duration", 30, 80, 40, true, "s.", 0.1),
    aspect_ratio_enabled = pui_group:checkbox("Aspect Ratio"),
    aspect_ratio = pui_group:slider("  Ratio", 0, 199, 100, true, "%"),
    thirdperson_collision = pui_group:checkbox("Thirdperson Collision"),
    thirdperson_distance = pui_group:slider("  Distance", 30, 200, 125, true, "u"),
    viewmodel_enabled = pui_group:checkbox("Viewmodel Override"),
    viewmodel_fov = pui_group:slider("  FOV", -10000, 10000, 0, true, "", 0.01),
    viewmodel_x = pui_group:slider("  Offset X", -10000, 10000, 0, true, "", 0.01),
    viewmodel_y = pui_group:slider("  Offset Y", -10000, 10000, 0, true, "", 0.01),
    viewmodel_z = pui_group:slider("  Offset Z", -10000, 10000, 0, true, "", 0.01),
    viewmodel_roll = pui_group:slider("  Roll", -180, 180, 0, true, "°"),
    knife_positioning = pui_group:combobox("  Knife Hand", {"-", "Left hand", "Right hand"}),
    scope_lines = pui_group:checkbox("Custom Scope Lines"),
    scope_lines_color = pui_group:color_picker("  Scope Color", 255, 255, 255, 255),
    scope_lines_offset = pui_group:slider("Scope Offset", 0, 500, 130, true, "px"),
    zeus_warning = pui_group:checkbox("Zeus Warning"),
    grenade_radius = pui_group:checkbox("Grenade Radius"),
    grenade_radius_display = pui_group:multiselect("  Display", {"Bar", "Text"}),
    grenade_molotov = pui_group:checkbox("  Molotov"),
    grenade_molotov_color = pui_group:color_picker("    Color", 255, 100, 50, 50),
    grenade_smoke = pui_group:checkbox("  Smoke"),
    grenade_smoke_color = pui_group:color_picker("    Color", 221, 219, 219, 50),
}
local function update_visual_visibility()
    local current_tab = menu.tab:get()
    if not current_tab or not string.find(current_tab, "Visual", 1, true) then
        return
    end
    local category = menu.visual.visual_category:get()
    local is_hud = category == "HUD"
    local is_logs = category == "Logs"
    local is_world = category == "World"
    local is_effects = category == "Effects"
    menu.visual.watermark_enabled:set_visible(is_hud)
    local watermark_enabled = is_hud and menu.visual.watermark_enabled:get()
    menu.visual.watermark_color:set_visible(watermark_enabled)
    menu.visual.spectators_enabled:set_visible(is_hud)
    local spectators_enabled = is_hud and menu.visual.spectators_enabled:get()
    menu.visual.spectators_color:set_visible(spectators_enabled)
    menu.visual.hotkeys_enabled:set_visible(is_hud)
    local hotkeys_enabled = is_hud and menu.visual.hotkeys_enabled:get()
    menu.visual.hotkeys_color:set_visible(hotkeys_enabled)
    menu.visual.crosshair_enabled:set_visible(is_hud)
    local crosshair_enabled = is_hud and menu.visual.crosshair_enabled:get()
    menu.visual.crosshair_text_color:set_visible(crosshair_enabled)
    menu.visual.crosshair_glow_color:set_visible(crosshair_enabled)
    menu.visual.damage_indicator:set_visible(is_hud)
    menu.visual.logs_enabled:set_visible(is_logs)
    local logs_enabled = is_logs and menu.visual.logs_enabled:get()
    menu.visual.logs_select:set_visible(logs_enabled)
    menu.visual.logs_color_hit:set_visible(logs_enabled)
    menu.visual.logs_color_miss:set_visible(logs_enabled)
    menu.visual.logs_offset:set_visible(logs_enabled)
    menu.visual.logs_duration:set_visible(logs_enabled)
    menu.visual.aspect_ratio_enabled:set_visible(is_world)
    local aspect_enabled = is_world and menu.visual.aspect_ratio_enabled:get()
    menu.visual.aspect_ratio:set_visible(aspect_enabled)
    menu.visual.thirdperson_collision:set_visible(is_world)
    local thirdperson_enabled = is_world and menu.visual.thirdperson_collision:get()
    menu.visual.thirdperson_distance:set_visible(thirdperson_enabled)
    menu.visual.viewmodel_enabled:set_visible(is_world)
    local viewmodel_enabled = is_world and menu.visual.viewmodel_enabled:get()
    menu.visual.viewmodel_fov:set_visible(viewmodel_enabled)
    menu.visual.viewmodel_x:set_visible(viewmodel_enabled)
    menu.visual.viewmodel_y:set_visible(viewmodel_enabled)
    menu.visual.viewmodel_z:set_visible(viewmodel_enabled)
    menu.visual.viewmodel_roll:set_visible(viewmodel_enabled)
    menu.visual.knife_positioning:set_visible(viewmodel_enabled)
    menu.visual.scope_lines:set_visible(is_world)
    local scope_enabled = is_world and menu.visual.scope_lines:get()
    menu.visual.scope_lines_color:set_visible(scope_enabled)
    menu.visual.scope_lines_offset:set_visible(scope_enabled)
    menu.visual.zeus_warning:set_visible(is_effects)
    menu.visual.grenade_radius:set_visible(is_effects)
    local grenade_enabled = is_effects and menu.visual.grenade_radius:get()
    menu.visual.grenade_radius_display:set_visible(grenade_enabled)
    menu.visual.grenade_molotov:set_visible(grenade_enabled)
    menu.visual.grenade_smoke:set_visible(grenade_enabled)
    local molotov_enabled = grenade_enabled and menu.visual.grenade_molotov:get()
    menu.visual.grenade_molotov_color:set_visible(molotov_enabled)
    local smoke_enabled = grenade_enabled and menu.visual.grenade_smoke:get()
    menu.visual.grenade_smoke_color:set_visible(smoke_enabled)
end
ui.set_callback(menu.visual.visual_category.ref, update_visual_visibility)
ui.set_callback(menu.visual.watermark_enabled.ref, update_visual_visibility)
ui.set_callback(menu.visual.spectators_enabled.ref, update_visual_visibility)
ui.set_callback(menu.visual.hotkeys_enabled.ref, update_visual_visibility)
ui.set_callback(menu.visual.crosshair_enabled.ref, update_visual_visibility)
ui.set_callback(menu.visual.logs_enabled.ref, update_visual_visibility)
ui.set_callback(menu.visual.aspect_ratio_enabled.ref, update_visual_visibility)
ui.set_callback(menu.visual.thirdperson_collision.ref, update_visual_visibility)
ui.set_callback(menu.visual.viewmodel_enabled.ref, update_visual_visibility)
ui.set_callback(menu.visual.scope_lines.ref, update_visual_visibility)
ui.set_callback(menu.visual.grenade_radius.ref, update_visual_visibility)
ui.set_callback(menu.visual.grenade_molotov.ref, update_visual_visibility)
ui.set_callback(menu.visual.grenade_smoke.ref, update_visual_visibility)
update_visual_visibility()
menu.misc = {
    chat_spammer = pui_group:checkbox("Chat Spammer"),
    clantag = pui_group:checkbox("Clantag"),
    clantag_text = pui_group:textbox("  Custom Text"),
    animation_breaker = pui_group:checkbox("Animation Breaker"),
    animation_ground = pui_group:combobox("  Ground", {"Off", "Static", "Jitter", "Moonwalk"}),
    animation_air = pui_group:combobox("  Air", {"Off", "Static", "Jitter", "Moonwalk"}),
    body_lean = pui_group:slider("Body Lean", 0, 100, 0, true, "%", 1, {[0] = "Off"}),
    pitch_on_land = pui_group:checkbox("  Pitch On Land"),
    earthquake = pui_group:checkbox("  Earthquake"),
    earthquake_intensity = pui_group:slider("Earthquake Intensity", 1, 100, 100, true, "%"),
    autobuy_enabled = pui_group:checkbox("Autobuy"),
    autobuy_primary = pui_group:combobox("  Primary", {"Off", "AWP", "SCAR20/G3SG1", "Scout", "M4/AK47", "Famas/Galil", "Aug/SG553", "M249", "Negev", "Mag7/SawedOff", "Nova", "XM1014", "MP9/Mac10", "UMP45", "PPBizon", "MP7"}),
    autobuy_secondary = pui_group:combobox("  Secondary", {"Off", "CZ75/Tec9/FiveSeven", "P250", "Deagle/Revolver", "Dualies"}),
    autobuy_grenades = pui_group:multiselect("  Grenades", {"HE Grenade", "Molotov", "Smoke", "Flash", "Decoy"}),
    autobuy_utilities = pui_group:multiselect("  Utilities", {"Armor", "Helmet", "Zeus", "Defuser"}),
}
menu.config = {
    list = pui_group:listbox("Configs", {}),
    name = pui_group:textbox("Name"),
    load = pui_group:button("Load", function() end),
    save = pui_group:button("Save", function() end),
    delete = pui_group:button("Delete", function() end),
    import = pui_group:button("Import", function() end),
    export = pui_group:button("Export", function() end),
}
menu.antiaim = {
    aa_mode = pui_group:combobox("AA Mode", {"Builder", "Presets", "Defensive"}),
    condition = pui_group:combobox("Condition", state_list),
    freestanding = pui_group:hotkey("Freestanding"),
    edge_yaw = pui_group:hotkey("Edge Yaw"),
    manual_left = pui_group:hotkey(" Left"),
    manual_right = pui_group:hotkey(" Right"),
    manual_back = pui_group:hotkey(" Back"),
    manual_forward = pui_group:hotkey(" Forward"),
    safe_head = pui_group:checkbox("Safe Head"),
    safe_head_triggers = pui_group:multiselect("  Triggers", {"Knife", "Zeus"}),
    utilities = pui_group:multiselect("Utilities", {
        "Avoid Backstab", "Anti-Aim On Use", "Auto Duck in Air", "Fakeduck Edge", "Fast Ladder"
    }),
}
menu.manual_aa_hotkey = {
    manual_left = menu.antiaim.manual_left,
    manual_right = menu.antiaim.manual_right,
    manual_back = menu.antiaim.manual_back,
    manual_forward = menu.antiaim.manual_forward,
}
for _, hotkey in pairs(menu.manual_aa_hotkey) do
    ui.set(hotkey.ref, "Toggle")
end

menu.defensive = {}
menu.defensive.condition = pui_group:combobox("Defensive Condition", state_list)

for _, state_name in ipairs(state_list) do
    menu.defensive[state_name] = {}
    local def_config = menu.defensive[state_name]
    local ds = "\n" .. state_name

    if state_name ~= "Global" then
        def_config.enable = pui_group:checkbox("Override" .. ds, false)
    end

    def_config.def_force = pui_group:checkbox("Force Defensive" .. ds, false)
    def_config.def_enable = pui_group:checkbox("Enable Defensive AA" .. ds, false)

    def_config.def_tick_mode = pui_group:combobox("Tick Mode" .. ds, {"Custom", "Adaptive"})
    def_config.def_tick_speed = pui_group:slider("  Tick Delay" .. ds, 0, 14, 0, true, "t", 1)

    def_config.def_pitch_mode = pui_group:combobox("Pitch" .. ds, {"Off", "Static", "Sway", "Switch", "Random"})
    def_config.def_pitch_1 = pui_group:slider("  Pitch 1" .. ds, -89, 89, 0, true, "°", 1)
    def_config.def_pitch_2 = pui_group:slider("  Pitch 2" .. ds, -89, 89, 0, true, "°", 1)
    def_config.def_pitch_speed = pui_group:slider("  Pitch Speed" .. ds, -75, 75, 20, true, "", 0.1)

    def_config.def_yaw_mode = pui_group:combobox("Yaw" .. ds, {"Off", "Static", "Spin", "Sway", "Jitter", "3-Way", "Random"})
    def_config.def_yaw_offset = pui_group:slider("  Yaw Offset" .. ds, -180, 180, 0, true, "°", 1)
    def_config.def_yaw_left = pui_group:slider("  Yaw Left" .. ds, -180, 180, 0, true, "°", 1)
    def_config.def_yaw_right = pui_group:slider("  Yaw Right" .. ds, -180, 180, 0, true, "°", 1)
    def_config.def_yaw_speed = pui_group:slider("  Yaw Speed" .. ds, -75, 75, 20, true, "", 0.1)

    def_config.def_jitter_delay_min = pui_group:slider("  Jitter Min" .. ds, 1, 8, 1, true, "t")
    def_config.def_jitter_delay_max = pui_group:slider("  Jitter Max" .. ds, 1, 8, 3, true, "t")

    def_config.def_3way_angle1 = pui_group:slider("  3-Way 1" .. ds, -180, 180, -60, true, "°", 1)
    def_config.def_3way_angle2 = pui_group:slider("  3-Way 2" .. ds, -180, 180, 0, true, "°", 1)
    def_config.def_3way_angle3 = pui_group:slider("  3-Way 3" .. ds, -180, 180, 60, true, "°", 1)
    def_config.def_3way_delay = pui_group:slider("  3-Way Delay" .. ds, 1, 8, 2, true, "t")
end

menu.configs_da = pui.setup(menu)

local DEFAULT_CONFIG = "eyJidWlsZGVyIjp7IkNyb3VjaCI6eyJlbmFibGUiOnRydWUsImRlc3luY194d2F5X3N0ZXBzIjpbMCwwLDAsMCwwLDAsMCwwXSwiZGVzeW5jX3h3YXlfdmFyaWFuY2UiOjIsImRlc3luY190eXBlIjoiTFwvUiIsInlhd19iYXNlX2RlZ3JlZXMiOjMsImRlc3luY194d2F5X2NvdW50IjozLCJkZXN5bmNfcmFuZG9taXphdGlvbiI6NSwiYm9keV95YXdfdmFyaWFuY2VfZGVsYXkiOjIsInRpbWluZ190aWNrX2RlbGF5IjoyLCJkZXN5bmNfeHdheV9kZWxheSI6MywieWF3X2Jhc2VfcmFuZG9taXplIjo0LCJib2R5X3lhd19qaXR0ZXJfcmlnaHQiOjQ3LCJib2R5X3lhd19qaXR0ZXJfbGVmdCI6NTYsImJvZHlfeWF3X2ppdHRlcl92YXJpYW5jZSI6MjAsImJvZHlfeWF3X21vZGUiOiJKaXR0ZXIiLCJ0aW1pbmdfdGlja192YXJpYW5jZSI6MSwiYm9keV95YXdfZGVncmVlcyI6MCwiZGVzeW5jX2xlZnRfbGltaXQiOi0zMCwiZGVzeW5jX3JpZ2h0X2xpbWl0IjozNSwiYm9keV95YXdfZGVsYXlfdmFyaWFuY2UiOjV9LCJVc2UiOnsiZW5hYmxlIjp0cnVlLCJkZXN5bmNfeHdheV9zdGVwcyI6WzAsMCwwLDAsMCwwLDAsMF0sImRlc3luY194d2F5X3ZhcmlhbmNlIjoyLCJkZXN5bmNfdHlwZSI6IkxcL1IiLCJ5YXdfYmFzZV9kZWdyZWVzIjowLCJkZXN5bmNfeHdheV9jb3VudCI6MywiZGVzeW5jX3JhbmRvbWl6YXRpb24iOjQsImJvZHlfeWF3X3ZhcmlhbmNlX2RlbGF5IjozLCJ0aW1pbmdfdGlja19kZWxheSI6NCwiZGVzeW5jX3h3YXlfZGVsYXkiOjMsInlhd19iYXNlX3JhbmRvbWl6ZSI6MCwiYm9keV95YXdfaml0dGVyX3JpZ2h0Ijo0OCwiYm9keV95YXdfaml0dGVyX2xlZnQiOjUxLCJib2R5X3lhd19qaXR0ZXJfdmFyaWFuY2UiOjAsImJvZHlfeWF3X21vZGUiOiJKaXR0ZXIiLCJ0aW1pbmdfdGlja192YXJpYW5jZSI6MCwiYm9keV95YXdfZGVncmVlcyI6MCwiZGVzeW5jX2xlZnRfbGltaXQiOi0zMiwiZGVzeW5jX3JpZ2h0X2xpbWl0IjozNiwiYm9keV95YXdfZGVsYXlfdmFyaWFuY2UiOjB9LCJTdGFuZCI6eyJlbmFibGUiOnRydWUsImRlc3luY194d2F5X3N0ZXBzIjpbMCwwLDAsMCwwLDAsMCwwXSwiZGVzeW5jX3h3YXlfdmFyaWFuY2UiOjIsImRlc3luY190eXBlIjoiTFwvUiIsInlhd19iYXNlX2RlZ3JlZXMiOjEsImRlc3luY194d2F5X2NvdW50IjozLCJkZXN5bmNfcmFuZG9taXphdGlvbiI6NSwiYm9keV95YXdfdmFyaWFuY2VfZGVsYXkiOjIsInRpbWluZ190aWNrX2RlbGF5IjoyLCJkZXN5bmNfeHdheV9kZWxheSI6MywieWF3X2Jhc2VfcmFuZG9taXplIjozLCJib2R5X3lhd19qaXR0ZXJfcmlnaHQiOjU2LCJib2R5X3lhd19qaXR0ZXJfbGVmdCI6NTIsImJvZHlfeWF3X2ppdHRlcl92YXJpYW5jZSI6MTIsImJvZHlfeWF3X21vZGUiOiJKaXR0ZXIiLCJ0aW1pbmdfdGlja192YXJpYW5jZSI6MiwiYm9keV95YXdfZGVncmVlcyI6MCwiZGVzeW5jX2xlZnRfbGltaXQiOi0zMSwiZGVzeW5jX3JpZ2h0X2xpbWl0IjozMCwiYm9keV95YXdfZGVsYXlfdmFyaWFuY2UiOjB9LCJGcmVlc3RhbmQiOnsiZW5hYmxlIjp0cnVlLCJkZXN5bmNfeHdheV9zdGVwcyI6WzAsMCwwLDAsMCwwLDAsMF0sImRlc3luY194d2F5X3ZhcmlhbmNlIjoyLCJkZXN5bmNfdHlwZSI6IkxcL1IiLCJ5YXdfYmFzZV9kZWdyZWVzIjowLCJkZXN5bmNfeHdheV9jb3VudCI6MywiZGVzeW5jX3JhbmRvbWl6YXRpb24iOjMsImJvZHlfeWF3X3ZhcmlhbmNlX2RlbGF5IjoyLCJ0aW1pbmdfdGlja19kZWxheSI6MiwiZGVzeW5jX3h3YXlfZGVsYXkiOjMsInlhd19iYXNlX3JhbmRvbWl6ZSI6NSwiYm9keV95YXdfaml0dGVyX3JpZ2h0Ijo1OSwiYm9keV95YXdfaml0dGVyX2xlZnQiOjAsImJvZHlfeWF3X2ppdHRlcl92YXJpYW5jZSI6MCwiYm9keV95YXdfbW9kZSI6IkppdHRlciIsInRpbWluZ190aWNrX3ZhcmlhbmNlIjoxLCJib2R5X3lhd19kZWdyZWVzIjowLCJkZXN5bmNfbGVmdF9saW1pdCI6LTEwLCJkZXN5bmNfcmlnaHRfbGltaXQiOjgsImJvZHlfeWF3X2RlbGF5X3ZhcmlhbmNlIjoxfSwiRmFrZWxhZyI6eyJlbmFibGUiOnRydWUsImRlc3luY194d2F5X3N0ZXBzIjpbMCwwLDAsMCwwLDAsMCwwXSwiZGVzeW5jX3h3YXlfdmFyaWFuY2UiOjIsImRlc3luY190eXBlIjoiTFwvUiIsInlhd19iYXNlX2RlZ3JlZXMiOjAsImRlc3luY194d2F5X2NvdW50IjozLCJkZXN5bmNfcmFuZG9taXphdGlvbiI6NywiYm9keV95YXdfdmFyaWFuY2VfZGVsYXkiOjMsInRpbWluZ190aWNrX2RlbGF5IjoyLCJkZXN5bmNfeHdheV9kZWxheSI6MywieWF3X2Jhc2VfcmFuZG9taXplIjozLCJib2R5X3lhd19qaXR0ZXJfcmlnaHQiOjMwLCJib2R5X3lhd19qaXR0ZXJfbGVmdCI6MzAsImJvZHlfeWF3X2ppdHRlcl92YXJpYW5jZSI6MCwiYm9keV95YXdfbW9kZSI6IlN0YXRpYyIsInRpbWluZ190aWNrX3ZhcmlhbmNlIjowLCJib2R5X3lhd19kZWdyZWVzIjotMTAsImRlc3luY19sZWZ0X2xpbWl0IjotMiwiZGVzeW5jX3JpZ2h0X2xpbWl0IjoxLCJib2R5X3lhd19kZWxheV92YXJpYW5jZSI6MH0sIlNhZmUiOnsiZW5hYmxlIjp0cnVlLCJkZXN5bmNfeHdheV9zdGVwcyI6WzAsMCwwLDAsMCwwLDAsMF0sImRlc3luY194d2F5X3ZhcmlhbmNlIjoyLCJkZXN5bmNfdHlwZSI6IkxcL1IiLCJ5YXdfYmFzZV9kZWdyZWVzIjozLCJkZXN5bmNfeHdheV9jb3VudCI6MywiZGVzeW5jX3JhbmRvbWl6YXRpb24iOjUsImJvZHlfeWF3X3ZhcmlhbmNlX2RlbGF5IjoxLCJ0aW1pbmdfdGlja19kZWxheSI6MiwiZGVzeW5jX3h3YXlfZGVsYXkiOjMsInlhd19iYXNlX3JhbmRvbWl6ZSI6MywiYm9keV95YXdfaml0dGVyX3JpZ2h0Ijo1NCwiYm9keV95YXdfaml0dGVyX2xlZnQiOjQ3LCJib2R5X3lhd19qaXR0ZXJfdmFyaWFuY2UiOjIwLCJib2R5X3lhd19tb2RlIjoiSml0dGVyIiwidGltaW5nX3RpY2tfdmFyaWFuY2UiOjAsImJvZHlfeWF3X2RlZ3JlZXMiOjAsImRlc3luY19sZWZ0X2xpbWl0IjotMjksImRlc3luY19yaWdodF9saW1pdCI6MzEsImJvZHlfeWF3X2RlbGF5X3ZhcmlhbmNlIjo0fSwiTWFudWFsIjp7ImVuYWJsZSI6dHJ1ZSwiZGVzeW5jX3h3YXlfc3RlcHMiOlswLDAsMCwwLDAsMCwwLDBdLCJkZXN5bmNfeHdheV92YXJpYW5jZSI6MiwiZGVzeW5jX3R5cGUiOiJMXC9SIiwieWF3X2Jhc2VfZGVncmVlcyI6MCwiZGVzeW5jX3h3YXlfY291bnQiOjMsImRlc3luY19yYW5kb21pemF0aW9uIjo0LCJib2R5X3lhd192YXJpYW5jZV9kZWxheSI6MywidGltaW5nX3RpY2tfZGVsYXkiOjMsImRlc3luY194d2F5X2RlbGF5IjozLCJ5YXdfYmFzZV9yYW5kb21pemUiOjUsImJvZHlfeWF3X2ppdHRlcl9yaWdodCI6NTYsImJvZHlfeWF3X2ppdHRlcl9sZWZ0Ijo0OSwiYm9keV95YXdfaml0dGVyX3ZhcmlhbmNlIjo1LCJib2R5X3lhd19tb2RlIjoiSml0dGVyIiwidGltaW5nX3RpY2tfdmFyaWFuY2UiOjAsImJvZHlfeWF3X2RlZ3JlZXMiOjAsImRlc3luY19sZWZ0X2xpbWl0IjotMzEsImRlc3luY19yaWdodF9saW1pdCI6MzEsImJvZHlfeWF3X2RlbGF5X3ZhcmlhbmNlIjo1fSwiR2xvYmFsIjp7ImJvZHlfeWF3X2RlZ3JlZXMiOjAsImRlc3luY194d2F5X3N0ZXBzIjpbMCwwLDAsMCwwLDAsMCwwXSwiZGVzeW5jX3h3YXlfdmFyaWFuY2UiOjIsImRlc3luY190eXBlIjoiRGlzYWJsZWQiLCJ5YXdfYmFzZV9kZWdyZWVzIjowLCJkZXN5bmNfeHdheV9jb3VudCI6MywiZGVzeW5jX3JhbmRvbWl6YXRpb24iOjAsImJvZHlfeWF3X3ZhcmlhbmNlX2RlbGF5IjozLCJ0aW1pbmdfdGlja19kZWxheSI6MywiZGVzeW5jX3h3YXlfZGVsYXkiOjMsInlhd19iYXNlX3JhbmRvbWl6ZSI6MCwiYm9keV95YXdfaml0dGVyX3JpZ2h0IjozMCwiYm9keV95YXdfaml0dGVyX2xlZnQiOjMwLCJib2R5X3lhd19qaXR0ZXJfdmFyaWFuY2UiOjAsImJvZHlfeWF3X21vZGUiOiJEaXNhYmxlZCIsInRpbWluZ190aWNrX3ZhcmlhbmNlIjowLCJkZXN5bmNfbGVmdF9saW1pdCI6MCwiZGVzeW5jX3JpZ2h0X2xpbWl0IjowLCJib2R5X3lhd19kZWxheV92YXJpYW5jZSI6MH0sIk1vdmUiOnsiZW5hYmxlIjp0cnVlLCJkZXN5bmNfeHdheV9zdGVwcyI6WzAsMCwwLDAsMCwwLDAsMF0sImRlc3luY194d2F5X3ZhcmlhbmNlIjoyLCJkZXN5bmNfdHlwZSI6IkxcL1IiLCJ5YXdfYmFzZV9kZWdyZWVzIjowLCJkZXN5bmNfeHdheV9jb3VudCI6MywiZGVzeW5jX3JhbmRvbWl6YXRpb24iOjQsImJvZHlfeWF3X3ZhcmlhbmNlX2RlbGF5IjoyLCJ0aW1pbmdfdGlja19kZWxheSI6MiwiZGVzeW5jX3h3YXlfZGVsYXkiOjMsInlhd19iYXNlX3JhbmRvbWl6ZSI6MSwiYm9keV95YXdfaml0dGVyX3JpZ2h0Ijo1NiwiYm9keV95YXdfaml0dGVyX2xlZnQiOjQ4LCJib2R5X3lhd19qaXR0ZXJfdmFyaWFuY2UiOjE4LCJib2R5X3lhd19tb2RlIjoiSml0dGVyIiwidGltaW5nX3RpY2tfdmFyaWFuY2UiOjMsImJvZHlfeWF3X2RlZ3JlZXMiOjAsImRlc3luY19sZWZ0X2xpbWl0IjotMzQsImRlc3luY19yaWdodF9saW1pdCI6MzYsImJvZHlfeWF3X2RlbGF5X3ZhcmlhbmNlIjoyfSwiQWlyIjp7ImVuYWJsZSI6dHJ1ZSwiZGVzeW5jX3h3YXlfc3RlcHMiOlswLDAsMCwwLDAsMCwwLDBdLCJkZXN5bmNfeHdheV92YXJpYW5jZSI6MiwiZGVzeW5jX3R5cGUiOiJMXC9SIiwieWF3X2Jhc2VfZGVncmVlcyI6MSwiZGVzeW5jX3h3YXlfY291bnQiOjMsImRlc3luY19yYW5kb21pemF0aW9uIjo1LCJib2R5X3lhd192YXJpYW5jZV9kZWxheSI6MiwidGltaW5nX3RpY2tfZGVsYXkiOjIsImRlc3luY194d2F5X2RlbGF5IjozLCJ5YXdfYmFzZV9yYW5kb21pemUiOjMsImJvZHlfeWF3X2ppdHRlcl9yaWdodCI6NTQsImJvZHlfeWF3X2ppdHRlcl9sZWZ0Ijo0OSwiYm9keV95YXdfaml0dGVyX3ZhcmlhbmNlIjoxNSwiYm9keV95YXdfbW9kZSI6IkppdHRlciIsInRpbWluZ190aWNrX3ZhcmlhbmNlIjo0LCJib2R5X3lhd19kZWdyZWVzIjowLCJkZXN5bmNfbGVmdF9saW1pdCI6LTM0LCJkZXN5bmNfcmlnaHRfbGltaXQiOjM5LCJib2R5X3lhd19kZWxheV92YXJpYW5jZSI6MX0sIkMtQWlyIjp7ImVuYWJsZSI6dHJ1ZSwiZGVzeW5jX3h3YXlfc3RlcHMiOlswLDAsMCwwLDAsMCwwLDBdLCJkZXN5bmNfeHdheV92YXJpYW5jZSI6MiwiZGVzeW5jX3R5cGUiOiJMXC9SIiwieWF3X2Jhc2VfZGVncmVlcyI6MywiZGVzeW5jX3h3YXlfY291bnQiOjMsImRlc3luY19yYW5kb21pemF0aW9uIjo1LCJib2R5X3lhd192YXJpYW5jZV9kZWxheSI6MywidGltaW5nX3RpY2tfZGVsYXkiOjIsImRlc3luY194d2F5X2RlbGF5IjozLCJ5YXdfYmFzZV9yYW5kb21pemUiOjQsImJvZHlfeWF3X2ppdHRlcl9yaWdodCI6NTQsImJvZHlfeWF3X2ppdHRlcl9sZWZ0Ijo0OSwiYm9keV95YXdfaml0dGVyX3ZhcmlhbmNlIjo0LCJib2R5X3lhd19tb2RlIjoiSml0dGVyIiwidGltaW5nX3RpY2tfdmFyaWFuY2UiOjAsImJvZHlfeWF3X2RlZ3JlZXMiOjAsImRlc3luY19sZWZ0X2xpbWl0IjotMjksImRlc3luY19yaWdodF9saW1pdCI6MzEsImJvZHlfeWF3X2RlbGF5X3ZhcmlhbmNlIjowfSwiQy1Nb3ZlIjp7ImVuYWJsZSI6dHJ1ZSwiZGVzeW5jX3h3YXlfc3RlcHMiOlswLDAsMCwwLDAsMCwwLDBdLCJkZXN5bmNfeHdheV92YXJpYW5jZSI6MiwiZGVzeW5jX3R5cGUiOiJMXC9SIiwieWF3X2Jhc2VfZGVncmVlcyI6MSwiZGVzeW5jX3h3YXlfY291bnQiOjMsImRlc3luY19yYW5kb21pemF0aW9uIjo1LCJib2R5X3lhd192YXJpYW5jZV9kZWxheSI6MSwidGltaW5nX3RpY2tfZGVsYXkiOjIsImRlc3luY194d2F5X2RlbGF5IjozLCJ5YXdfYmFzZV9yYW5kb21pemUiOjEsImJvZHlfeWF3X2ppdHRlcl9yaWdodCI6NTUsImJvZHlfeWF3X2ppdHRlcl9sZWZ0Ijo0NywiYm9keV95YXdfaml0dGVyX3ZhcmlhbmNlIjoxNiwiYm9keV95YXdfbW9kZSI6IkppdHRlciIsInRpbWluZ190aWNrX3ZhcmlhbmNlIjowLCJib2R5X3lhd19kZWdyZWVzIjowLCJkZXN5bmNfbGVmdF9saW1pdCI6LTI5LCJkZXN5bmNfcmlnaHRfbGltaXQiOjMxLCJib2R5X3lhd19kZWxheV92YXJpYW5jZSI6Nn0sIlNsb3ciOnsiZW5hYmxlIjp0cnVlLCJkZXN5bmNfeHdheV9zdGVwcyI6WzAsMCwwLDAsMCwwLDAsMF0sImRlc3luY194d2F5X3ZhcmlhbmNlIjoyLCJkZXN5bmNfdHlwZSI6IkxcL1IiLCJ5YXdfYmFzZV9kZWdyZWVzIjowLCJkZXN5bmNfeHdheV9jb3VudCI6MywiZGVzeW5jX3JhbmRvbWl6YXRpb24iOjYsImJvZHlfeWF3X3ZhcmlhbmNlX2RlbGF5IjozLCJ0aW1pbmdfdGlja19kZWxheSI6MSwiZGVzeW5jX3h3YXlfZGVsYXkiOjMsInlhd19iYXNlX3JhbmRvbWl6ZSI6MiwiYm9keV95YXdfaml0dGVyX3JpZ2h0IjozMCwiYm9keV95YXdfaml0dGVyX2xlZnQiOjMwLCJib2R5X3lhd19qaXR0ZXJfdmFyaWFuY2UiOjAsImJvZHlfeWF3X21vZGUiOiJTdGF0aWMiLCJ0aW1pbmdfdGlja192YXJpYW5jZSI6MywiYm9keV95YXdfZGVncmVlcyI6LTEwLCJkZXN5bmNfbGVmdF9saW1pdCI6LTEsImRlc3luY19yaWdodF9saW1pdCI6MSwiYm9keV95YXdfZGVsYXlfdmFyaWFuY2UiOjB9fSwiY29uZmlnIjp7Im1pc2MiOnsiZWFydGhxdWFrZV9pbnRlbnNpdHkiOjEwMCwiYXV0b2J1eV9zZWNvbmRhcnkiOiJDWjc1XC9UZWM5XC9GaXZlU2V2ZW4iLCJhbmltYXRpb25fYWlyIjoiU3RhdGljIiwiYW5pbWF0aW9uX2JyZWFrZXIiOnRydWUsImNoYXRfc3BhbW1lciI6ZmFsc2UsImF1dG9idXlfdXRpbGl0aWVzIjpbIkFybW9yIiwiSGVsbWV0IiwiWmV1cyIsIkRlZnVzZXIiLCJ+Il0sImJvZHlfbGVhbiI6MCwiYXV0b2J1eV9wcmltYXJ5IjoiU2NvdXQiLCJwaXRjaF9vbl9sYW5kIjpmYWxzZSwiYXV0b2J1eV9ncmVuYWRlcyI6WyJNb2xvdG92IiwiU21va2UiLCJGbGFzaCIsIn4iXSwiZWFydGhxdWFrZSI6ZmFsc2UsImFuaW1hdGlvbl9ncm91bmQiOiJNb29ud2FsayIsImNsYW50YWdfdGV4dCI6IiIsImF1dG9idXlfZW5hYmxlZCI6dHJ1ZSwiY2xhbnRhZyI6ZmFsc2V9LCJ0YWIiOiLuh4EgQ29uZmlnIiwidmlzdWFsIjp7ImdyZW5hZGVfbW9sb3RvdiI6dHJ1ZSwiemV1c193YXJuaW5nIjp0cnVlLCJob3RrZXlzX2VuYWJsZWQiOnRydWUsImRhbWFnZV9pbmRpY2F0b3IiOnRydWUsImFzcGVjdF9yYXRpb19lbmFibGVkIjp0cnVlLCJrbmlmZV9wb3NpdGlvbmluZyI6Ii0iLCJjcm9zc2hhaXJfZW5hYmxlZCI6dHJ1ZSwid2F0ZXJtYXJrX2NvbG9yIjoiIzQyQjhGRkZGIiwidmlld21vZGVsX3giOjc2MSwibG9nc19lbmFibGVkIjp0cnVlLCJjcm9zc2hhaXJfZ2xvd19jb2xvciI6IiNBNEIyRjFGRiIsInNwZWN0YXRvcnNfZW5hYmxlZCI6ZmFsc2UsInZpZXdtb2RlbF9lbmFibGVkIjp0cnVlLCJncmVuYWRlX21vbG90b3ZfY29sb3IiOiIjQzFDMUMxMzIiLCJ2aWV3bW9kZWxfcm9sbCI6MCwidmlld21vZGVsX3oiOi0xNTczLCJjcm9zc2hhaXJfdGV4dF9jb2xvciI6IiNGRkZGRkZGRiIsImxvZ3Nfb2Zmc2V0Ijo1MDAsImxvZ3NfY29sb3JfbWlzcyI6IiNGRjdEOTZGRiIsImxvZ3NfZHVyYXRpb24iOjMwLCJsb2dzX3NlbGVjdCI6WyJOb3RpZnkiLCJTY3JlZW4iLCJDb25zb2xlIiwifiJdLCJ3YXRlcm1hcmtfZW5hYmxlZCI6dHJ1ZSwiZ3JlbmFkZV9yYWRpdXMiOnRydWUsImdyZW5hZGVfc21va2UiOnRydWUsImxvZ3NfY29sb3JfaGl0IjoiI0E0QjJGMUZGIiwiZ3JlbmFkZV9yYWRpdXNfZGlzcGxheSI6WyJUZXh0IiwifiJdLCJzcGVjdGF0b3JzX2NvbG9yIjoiIzQyQjhGRkZGIiwiaG90a2V5c19jb2xvciI6IiM0MkI4RkZGRiIsImdyZW5hZGVfc21va2VfY29sb3IiOiIjQzFDMUMxMzIiLCJzY29wZV9saW5lc19jb2xvciI6IiNBN0I5QzBGRiIsInZpc3VhbF9jYXRlZ29yeSI6IkxvZ3MiLCJ0aGlyZHBlcnNvbl9jb2xsaXNpb24iOnRydWUsInZpZXdtb2RlbF9mb3YiOi0xODc4LCJhc3BlY3RfcmF0aW8iOjEzNiwic2NvcGVfbGluZXNfb2Zmc2V0IjoxNDMsInZpZXdtb2RlbF95IjotMTM3MCwidGhpcmRwZXJzb25fZGlzdGFuY2UiOjUwLCJzY29wZV9saW5lcyI6dHJ1ZX0sIm1hbnVhbF9hYV9ob3RrZXkiOnsibWFudWFsX2JhY2siOlsyLDg4LCJ+Il0sIm1hbnVhbF9sZWZ0IjpbMiw5MCwifiJdLCJtYW51YWxfcmlnaHQiOlsyLDY3LCJ+Il0sIm1hbnVhbF9mb3J3YXJkIjpbMiwwLCJ+Il19LCJhbnRpYWltIjp7Im1hbnVhbF9iYWNrIjpbMiw4OCwifiJdLCJtYW51YWxfbGVmdCI6WzIsOTAsIn4iXSwiYWFfbW9kZSI6IkJ1aWxkZXIiLCJzYWZlX2hlYWRfdHJpZ2dlcnMiOlsiS25pZmUiLCJaZXVzIiwifiJdLCJtYW51YWxfcmlnaHQiOlsyLDY3LCJ+Il0sIm1hbnVhbF9mb3J3YXJkIjpbMiwwLCJ+Il0sImNvbmRpdGlvbiI6IkNyb3VjaCIsImZyZWVzdGFuZGluZyI6WzEsNSwifiJdLCJ1dGlsaXRpZXMiOlsiQXZvaWQgQmFja3N0YWIiLCJBbnRpLUFpbSBPbiBVc2UiLCJBdXRvIER1Y2sgaW4gQWlyIiwiRmFrZWR1Y2sgRWRnZSIsIkZhc3QgTGFkZGVyIiwifiJdLCJzYWZlX2hlYWQiOnRydWUsImVkZ2VfeWF3IjpbMSwwLCJ+Il19LCJyYWdlYm90Ijp7ImRvcm1hbnRfYWltYm90Ijp0cnVlLCJ1bnNhZmVfY2hhcmdlIjp0cnVlLCJoaWRlc2hvdHNfc3RhdGVzIjpbIkNyb3VjaCIsIkMtTW92ZSIsIlNsb3ciLCJ+Il0sImFpcl9zdG9wX2VuYWJsZWQiOnRydWUsImhpZGVzaG90c19lbmFibGVkIjp0cnVlLCJwZWVrYm90X3JhbmdlIjo2MSwicGVla2JvdF90ZWxlcG9ydCI6WzEsMCwifiJdLCJhaXJfc3RvcF9tdWx0aV9oaXRib3giOnRydWUsInBlZWtib3RfZW5hYmxlZCI6WzEsNSwifiJdLCJoaWRlc2hvdHNfd2VhcG9ucyI6WyJBV1AiLCJTY291dCIsIn4iXSwiYWlyX3N0b3BfcmFuZ2UiOjQwMH0sImRlZmVuc2l2ZSI6eyJNb3ZlIjp7ImVuYWJsZSI6dHJ1ZSwiZGVmXzN3YXlfYW5nbGUyIjowLCJkZWZfcGl0Y2hfMiI6MCwiZGVmX2ppdHRlcl9kZWxheV9tYXgiOjMsImRlZl8zd2F5X2FuZ2xlMSI6LTYwLCJkZWZfcGl0Y2hfbW9kZSI6Ik9mZiIsImRlZl95YXdfbW9kZSI6Ik9mZiIsImRlZl90aWNrX21vZGUiOiJDdXN0b20iLCJkZWZfeWF3X3NwZWVkIjoyMCwiZGVmX2ZvcmNlIjp0cnVlLCJkZWZfeWF3X2xlZnQiOjAsImRlZl9qaXR0ZXJfZGVsYXlfbWluIjoxLCJkZWZfcGl0Y2hfc3BlZWQiOjIwLCJkZWZfM3dheV9kZWxheSI6MiwiZGVmX3lhd19vZmZzZXQiOjAsImRlZl8zd2F5X2FuZ2xlMyI6NjAsImRlZl9waXRjaF8xIjowLCJkZWZfeWF3X3JpZ2h0IjowLCJkZWZfdGlja19zcGVlZCI6MCwiZGVmX2VuYWJsZSI6ZmFsc2V9LCJVc2UiOnsiZW5hYmxlIjp0cnVlLCJkZWZfM3dheV9hbmdsZTIiOjAsImRlZl9waXRjaF8yIjowLCJkZWZfaml0dGVyX2RlbGF5X21heCI6MywiZGVmXzN3YXlfYW5nbGUxIjotNjAsImRlZl9waXRjaF9tb2RlIjoiT2ZmIiwiZGVmX3lhd19tb2RlIjoiT2ZmIiwiZGVmX3RpY2tfbW9kZSI6IkN1c3RvbSIsImRlZl95YXdfc3BlZWQiOjIwLCJkZWZfZm9yY2UiOnRydWUsImRlZl95YXdfbGVmdCI6MCwiZGVmX2ppdHRlcl9kZWxheV9taW4iOjEsImRlZl9waXRjaF9zcGVlZCI6MjAsImRlZl8zd2F5X2RlbGF5IjoyLCJkZWZfeWF3X29mZnNldCI6MCwiZGVmXzN3YXlfYW5nbGUzIjo2MCwiZGVmX3BpdGNoXzEiOjAsImRlZl95YXdfcmlnaHQiOjAsImRlZl90aWNrX3NwZWVkIjowLCJkZWZfZW5hYmxlIjpmYWxzZX0sIlN0YW5kIjp7ImVuYWJsZSI6dHJ1ZSwiZGVmXzN3YXlfYW5nbGUyIjowLCJkZWZfcGl0Y2hfMiI6MCwiZGVmX2ppdHRlcl9kZWxheV9tYXgiOjMsImRlZl8zd2F5X2FuZ2xlMSI6LTYwLCJkZWZfcGl0Y2hfbW9kZSI6Ik9mZiIsImRlZl95YXdfbW9kZSI6Ik9mZiIsImRlZl90aWNrX21vZGUiOiJDdXN0b20iLCJkZWZfeWF3X3NwZWVkIjoyMCwiZGVmX2ZvcmNlIjp0cnVlLCJkZWZfeWF3X2xlZnQiOjAsImRlZl9qaXR0ZXJfZGVsYXlfbWluIjoxLCJkZWZfcGl0Y2hfc3BlZWQiOjIwLCJkZWZfM3dheV9kZWxheSI6MiwiZGVmX3lhd19vZmZzZXQiOjAsImRlZl8zd2F5X2FuZ2xlMyI6NjAsImRlZl9waXRjaF8xIjowLCJkZWZfeWF3X3JpZ2h0IjowLCJkZWZfdGlja19zcGVlZCI6MCwiZGVmX2VuYWJsZSI6ZmFsc2V9LCJNYW51YWwiOnsiZW5hYmxlIjp0cnVlLCJkZWZfM3dheV9hbmdsZTIiOjAsImRlZl9waXRjaF8yIjowLCJkZWZfaml0dGVyX2RlbGF5X21heCI6MywiZGVmXzN3YXlfYW5nbGUxIjotNjAsImRlZl9waXRjaF9tb2RlIjoiT2ZmIiwiZGVmX3lhd19tb2RlIjoiT2ZmIiwiZGVmX3RpY2tfbW9kZSI6IkN1c3RvbSIsImRlZl95YXdfc3BlZWQiOjIwLCJkZWZfZm9yY2UiOnRydWUsImRlZl95YXdfbGVmdCI6MCwiZGVmX2ppdHRlcl9kZWxheV9taW4iOjEsImRlZl9waXRjaF9zcGVlZCI6MjAsImRlZl8zd2F5X2RlbGF5IjoyLCJkZWZfeWF3X29mZnNldCI6MCwiZGVmXzN3YXlfYW5nbGUzIjo2MCwiZGVmX3BpdGNoXzEiOjAsImRlZl95YXdfcmlnaHQiOjAsImRlZl90aWNrX3NwZWVkIjowLCJkZWZfZW5hYmxlIjpmYWxzZX0sIkdsb2JhbCI6eyJkZWZfM3dheV9hbmdsZTIiOjAsImRlZl9waXRjaF8yIjowLCJkZWZfaml0dGVyX2RlbGF5X21pbiI6MSwiZGVmXzN3YXlfYW5nbGUxIjotNjAsImRlZl9waXRjaF9tb2RlIjoiT2ZmIiwiZGVmX3lhd19tb2RlIjoiT2ZmIiwiZGVmX3lhd19yaWdodCI6MCwiZGVmX3lhd19zcGVlZCI6MjAsImRlZl9mb3JjZSI6ZmFsc2UsImRlZl9lbmFibGUiOmZhbHNlLCJkZWZfdGlja19tb2RlIjoiQ3VzdG9tIiwiZGVmX3BpdGNoX3NwZWVkIjoyMCwiZGVmXzN3YXlfZGVsYXkiOjIsImRlZl95YXdfb2Zmc2V0IjowLCJkZWZfM3dheV9hbmdsZTMiOjYwLCJkZWZfcGl0Y2hfMSI6MCwiZGVmX2ppdHRlcl9kZWxheV9tYXgiOjMsImRlZl90aWNrX3NwZWVkIjowLCJkZWZfeWF3X2xlZnQiOjB9LCJGYWtlbGFnIjp7ImVuYWJsZSI6dHJ1ZSwiZGVmXzN3YXlfYW5nbGUyIjowLCJkZWZfcGl0Y2hfMiI6MCwiZGVmX2ppdHRlcl9kZWxheV9tYXgiOjMsImRlZl8zd2F5X2FuZ2xlMSI6LTYwLCJkZWZfcGl0Y2hfbW9kZSI6Ik9mZiIsImRlZl95YXdfbW9kZSI6Ik9mZiIsImRlZl90aWNrX21vZGUiOiJDdXN0b20iLCJkZWZfeWF3X3NwZWVkIjoyMCwiZGVmX2ZvcmNlIjp0cnVlLCJkZWZfeWF3X2xlZnQiOjAsImRlZl9qaXR0ZXJfZGVsYXlfbWluIjoxLCJkZWZfcGl0Y2hfc3BlZWQiOjIwLCJkZWZfM3dheV9kZWxheSI6MiwiZGVmX3lhd19vZmZzZXQiOjAsImRlZl8zd2F5X2FuZ2xlMyI6NjAsImRlZl9waXRjaF8xIjowLCJkZWZfeWF3X3JpZ2h0IjowLCJkZWZfdGlja19zcGVlZCI6MCwiZGVmX2VuYWJsZSI6ZmFsc2V9LCJTYWZlIjp7ImVuYWJsZSI6dHJ1ZSwiZGVmXzN3YXlfYW5nbGUyIjowLCJkZWZfcGl0Y2hfMiI6MCwiZGVmX2ppdHRlcl9kZWxheV9tYXgiOjMsImRlZl8zd2F5X2FuZ2xlMSI6LTYwLCJkZWZfcGl0Y2hfbW9kZSI6Ik9mZiIsImRlZl95YXdfbW9kZSI6Ik9mZiIsImRlZl90aWNrX21vZGUiOiJDdXN0b20iLCJkZWZfeWF3X3NwZWVkIjoyMCwiZGVmX2ZvcmNlIjp0cnVlLCJkZWZfeWF3X2xlZnQiOjAsImRlZl9qaXR0ZXJfZGVsYXlfbWluIjoxLCJkZWZfcGl0Y2hfc3BlZWQiOjIwLCJkZWZfM3dheV9kZWxheSI6MiwiZGVmX3lhd19vZmZzZXQiOjAsImRlZl8zd2F5X2FuZ2xlMyI6NjAsImRlZl9waXRjaF8xIjowLCJkZWZfeWF3X3JpZ2h0IjowLCJkZWZfdGlja19zcGVlZCI6MCwiZGVmX2VuYWJsZSI6ZmFsc2V9LCJjb25kaXRpb24iOiJBaXIiLCJBaXIiOnsiZW5hYmxlIjp0cnVlLCJkZWZfM3dheV9hbmdsZTIiOjAsImRlZl9waXRjaF8yIjowLCJkZWZfaml0dGVyX2RlbGF5X21heCI6MywiZGVmXzN3YXlfYW5nbGUxIjotNjAsImRlZl9waXRjaF9tb2RlIjoiT2ZmIiwiZGVmX3lhd19tb2RlIjoiT2ZmIiwiZGVmX3RpY2tfbW9kZSI6IkN1c3RvbSIsImRlZl95YXdfc3BlZWQiOjIwLCJkZWZfZm9yY2UiOnRydWUsImRlZl95YXdfbGVmdCI6MCwiZGVmX2ppdHRlcl9kZWxheV9taW4iOjEsImRlZl9waXRjaF9zcGVlZCI6MjAsImRlZl8zd2F5X2RlbGF5IjoyLCJkZWZfeWF3X29mZnNldCI6MCwiZGVmXzN3YXlfYW5nbGUzIjo2MCwiZGVmX3BpdGNoXzEiOjAsImRlZl95YXdfcmlnaHQiOjAsImRlZl90aWNrX3NwZWVkIjowLCJkZWZfZW5hYmxlIjpmYWxzZX0sIlNsb3ciOnsiZW5hYmxlIjp0cnVlLCJkZWZfM3dheV9hbmdsZTIiOjAsImRlZl9waXRjaF8yIjo1OSwiZGVmX2ppdHRlcl9kZWxheV9tYXgiOjMsImRlZl8zd2F5X2FuZ2xlMSI6LTYwLCJkZWZfcGl0Y2hfbW9kZSI6IlN3YXkiLCJkZWZfeWF3X21vZGUiOiJTd2F5IiwiZGVmX3RpY2tfbW9kZSI6IkFkYXB0aXZlIiwiZGVmX3lhd19zcGVlZCI6MTMsImRlZl9mb3JjZSI6dHJ1ZSwiZGVmX3lhd19sZWZ0IjoxMDQsImRlZl9qaXR0ZXJfZGVsYXlfbWluIjoxLCJkZWZfcGl0Y2hfc3BlZWQiOjksImRlZl8zd2F5X2RlbGF5IjoyLCJkZWZfeWF3X29mZnNldCI6MCwiZGVmXzN3YXlfYW5nbGUzIjo2MCwiZGVmX3BpdGNoXzEiOi00NCwiZGVmX3lhd19yaWdodCI6OTgsImRlZl90aWNrX3NwZWVkIjoyLCJkZWZfZW5hYmxlIjp0cnVlfSwiQ3JvdWNoIjp7ImVuYWJsZSI6dHJ1ZSwiZGVmXzN3YXlfYW5nbGUyIjowLCJkZWZfcGl0Y2hfMiI6MCwiZGVmX2ppdHRlcl9kZWxheV9tYXgiOjMsImRlZl8zd2F5X2FuZ2xlMSI6LTYwLCJkZWZfcGl0Y2hfbW9kZSI6Ik9mZiIsImRlZl95YXdfbW9kZSI6Ik9mZiIsImRlZl90aWNrX21vZGUiOiJDdXN0b20iLCJkZWZfeWF3X3NwZWVkIjoyMCwiZGVmX2ZvcmNlIjp0cnVlLCJkZWZfeWF3X2xlZnQiOjAsImRlZl9qaXR0ZXJfZGVsYXlfbWluIjoxLCJkZWZfcGl0Y2hfc3BlZWQiOjIwLCJkZWZfM3dheV9kZWxheSI6MiwiZGVmX3lhd19vZmZzZXQiOjAsImRlZl8zd2F5X2FuZ2xlMyI6NjAsImRlZl9waXRjaF8xIjowLCJkZWZfeWF3X3JpZ2h0IjowLCJkZWZfdGlja19zcGVlZCI6MCwiZGVmX2VuYWJsZSI6ZmFsc2V9LCJDLUFpciI6eyJlbmFibGUiOnRydWUsImRlZl8zd2F5X2FuZ2xlMiI6MCwiZGVmX3BpdGNoXzIiOjAsImRlZl9qaXR0ZXJfZGVsYXlfbWF4IjozLCJkZWZfM3dheV9hbmdsZTEiOi02MCwiZGVmX3BpdGNoX21vZGUiOiJPZmYiLCJkZWZfeWF3X21vZGUiOiJPZmYiLCJkZWZfdGlja19tb2RlIjoiQ3VzdG9tIiwiZGVmX3lhd19zcGVlZCI6MjAsImRlZl9mb3JjZSI6dHJ1ZSwiZGVmX3lhd19sZWZ0IjowLCJkZWZfaml0dGVyX2RlbGF5X21pbiI6MSwiZGVmX3BpdGNoX3NwZWVkIjoyMCwiZGVmXzN3YXlfZGVsYXkiOjIsImRlZl95YXdfb2Zmc2V0IjowLCJkZWZfM3dheV9hbmdsZTMiOjYwLCJkZWZfcGl0Y2hfMSI6MCwiZGVmX3lhd19yaWdodCI6MCwiZGVmX3RpY2tfc3BlZWQiOjAsImRlZl9lbmFibGUiOmZhbHNlfSwiQy1Nb3ZlIjp7ImVuYWJsZSI6dHJ1ZSwiZGVmXzN3YXlfYW5nbGUyIjowLCJkZWZfcGl0Y2hfMiI6MCwiZGVmX2ppdHRlcl9kZWxheV9tYXgiOjMsImRlZl8zd2F5X2FuZ2xlMSI6LTYwLCJkZWZfcGl0Y2hfbW9kZSI6Ik9mZiIsImRlZl95YXdfbW9kZSI6Ik9mZiIsImRlZl90aWNrX21vZGUiOiJDdXN0b20iLCJkZWZfeWF3X3NwZWVkIjoyMCwiZGVmX2ZvcmNlIjp0cnVlLCJkZWZfeWF3X2xlZnQiOjAsImRlZl9qaXR0ZXJfZGVsYXlfbWluIjoxLCJkZWZfcGl0Y2hfc3BlZWQiOjIwLCJkZWZfM3dheV9kZWxheSI6MiwiZGVmX3lhd19vZmZzZXQiOjAsImRlZl8zd2F5X2FuZ2xlMyI6NjAsImRlZl9waXRjaF8xIjowLCJkZWZfeWF3X3JpZ2h0IjowLCJkZWZfdGlja19zcGVlZCI6MCwiZGVmX2VuYWJsZSI6ZmFsc2V9LCJGcmVlc3RhbmQiOnsiZW5hYmxlIjp0cnVlLCJkZWZfM3dheV9hbmdsZTIiOjAsImRlZl9waXRjaF8yIjowLCJkZWZfaml0dGVyX2RlbGF5X21heCI6MywiZGVmXzN3YXlfYW5nbGUxIjotNjAsImRlZl9waXRjaF9tb2RlIjoiT2ZmIiwiZGVmX3lhd19tb2RlIjoiT2ZmIiwiZGVmX3RpY2tfbW9kZSI6IkN1c3RvbSIsImRlZl95YXdfc3BlZWQiOjIwLCJkZWZfZm9yY2UiOnRydWUsImRlZl95YXdfbGVmdCI6MCwiZGVmX2ppdHRlcl9kZWxheV9taW4iOjEsImRlZl9waXRjaF9zcGVlZCI6MjAsImRlZl8zd2F5X2RlbGF5IjoyLCJkZWZfeWF3X29mZnNldCI6MCwiZGVmXzN3YXlfYW5nbGUzIjo2MCwiZGVmX3BpdGNoXzEiOjAsImRlZl95YXdfcmlnaHQiOjAsImRlZl90aWNrX3NwZWVkIjowLCJkZWZfZW5hYmxlIjpmYWxzZX19LCJjb25maWciOnsibGlzdCI6MSwibmFtZSI6IjExMTEifX19"

local config_system = {}
local protected_db = {
    configs = ':testaa::configs:'
}
config_system.get = function(name)
    local db = database.read(protected_db.configs) or {}
    for i, v in pairs(db) do
        if v.name == name then
            return {
                config = v.config,
                builder = v.builder,
                index = i
            }
        end
    end
    return false
end
config_system.save = function(name)
    if name == "default" then
        print('[AMGSENSE] Cannot overwrite default config')
        return false
    end
    
    local db = database.read(protected_db.configs) or {}
    if name:match('[^%w]') ~= nil then
        return false
    end
    local config_data = base64.encode(json.stringify(menu.configs_da:save()))
    local builder_data = base64.encode(json.stringify(menu.builder_package:save()))
    local cfg = config_system.get(name)
    if not cfg then
        table.insert(db, { name = name, config = config_data, builder = builder_data })
    else
        db[cfg.index].config = config_data
        db[cfg.index].builder = builder_data
    end
    database.write(protected_db.configs, db)
    return true
end
config_system.delete = function(name)
    if name == "default" then
        print('[AMGSENSE] Cannot delete default config')
        return false
    end
    
    local db = database.read(protected_db.configs) or {}
    for i, v in pairs(db) do
        if v.name == name then
            table.remove(db, i)
            database.write(protected_db.configs, db)
            return true
        end
    end
    return false
end
config_system.config_list = function()
    local db = database.read(protected_db.configs) or {}
    local configs = {"default"} 
    for i, v in pairs(db) do
        table.insert(configs, v.name)
    end
    return configs
end
config_system.load = function(name)
    if name == "default" then
        local config_data = json.parse(base64.decode(DEFAULT_CONFIG))
        if config_data then
            if config_data.config then
                menu.configs_da:load(config_data.config)
            end
            if config_data.builder then
                menu.builder_package:load(config_data.builder)
            end
            return true
        end
        return false
    end
    
    local fromDB = config_system.get(name)
    if fromDB then
        local decoded = json.parse(base64.decode(fromDB.config))
        menu.configs_da:load(decoded)
        if fromDB.builder then
            local builder_decoded = json.parse(base64.decode(fromDB.builder))
            menu.builder_package:load(builder_decoded)
        end
        return true
    end
    return false
end
config_system.import_settings = function()
    local frombuffer = clipboard.get()
    if frombuffer and frombuffer ~= "" then
        local success, config_data = pcall(function()
            return json.parse(base64.decode(frombuffer))
        end)
        if success and config_data then
            if config_data.config then
                menu.configs_da:load(config_data.config)
            end
            if config_data.builder then
                menu.builder_package:load(config_data.builder)
            end
            return true
        end
    end
    return false
end
config_system.export_settings = function()
    local config_data = {
        config = menu.configs_da:save(),
        builder = menu.builder_package:save()
    }
    local toExport = base64.encode(json.stringify(config_data))
    clipboard.set(toExport)
    return true
end
menu.config.list:set_callback(function(value)
    if value == nil then return end
    local configs = config_system.config_list()
    if configs == nil or #configs == 0 then return end
    local idx = value:get()
    if idx ~= nil and configs[idx + 1] then
        menu.config.name:set(configs[idx + 1])
    end
end)
menu.config.load:set_callback(function()
    local name = menu.config.name:get()
    if name == '' or name == nil then return end
    client.exec("play buttons/button17")
    local success = pcall(config_system.load, name)
    if success then
        print('[AMGSENSE] Loaded: ' .. name)
        client.delay_call(0.05, function()
            local current_tab = menu.tab:get()
            if current_tab then show_tab(current_tab) end
        end)
    else
        print('[AMGSENSE] Failed to load: ' .. name)
    end
end)
menu.config.save:set_callback(function()
    local name = menu.config.name:get()
    if name == '' or name == nil then return end
    if name:match('[^%w]') ~= nil then
        print('[AMGSENSE] Invalid name (alphanumeric only)')
        return
    end
    local success = pcall(function()
        config_system.save(name)
        menu.config.list:update(config_system.config_list())
    end)
    if success then
        print('[AMGSENSE] Saved: ' .. name)
        client.exec("play buttons/button17")
    end
end)
menu.config.delete:set_callback(function()
    local name = menu.config.name:get()
    if name == '' or name == nil then return end
    local success = config_system.delete(name)
    if success then
        menu.config.list:update(config_system.config_list())
        local configs = config_system.config_list()
        menu.config.name:set(#configs > 0 and configs[1] or "")
        print('[AMGSENSE] Deleted: ' .. name)
        client.exec("play buttons/button17")
    end
end)
menu.config.import:set_callback(function()
    local success = pcall(config_system.import_settings)
    if success then
        print('[AMGSENSE] Imported from clipboard')
        client.exec("play buttons/button17")
        client.delay_call(0.05, function()
            local current_tab = menu.tab:get()
            if current_tab then show_tab(current_tab) end
        end)
    else
        print('[AMGSENSE] Import failed')
    end
end)
menu.config.export:set_callback(function()
    local success = pcall(config_system.export_settings)
    if success then
        print('[AMGSENSE] Exported to clipboard')
        client.exec("play buttons/button17")
    end
end)
client.delay_call(0.1, function()
    if database.read(protected_db.configs) == nil then
        database.write(protected_db.configs, {})
    end
    menu.config.list:update(config_system.config_list())
end)
local color_db_key = ":testaa_colors:"
local color_pickers = {
    watermark_color = menu.visual.watermark_color,
    spectators_color = menu.visual.spectators_color,
    hotkeys_color = menu.visual.hotkeys_color,
    crosshair_text_color = menu.visual.crosshair_text_color,
    crosshair_glow_color = menu.visual.crosshair_glow_color,
    logs_color_hit = menu.visual.logs_color_hit,
    logs_color_miss = menu.visual.logs_color_miss,
    grenade_molotov_color = menu.visual.grenade_molotov_color,
    grenade_smoke_color = menu.visual.grenade_smoke_color,
}
local function load_colors()
    local saved_colors = database.read(color_db_key) or {}
    for name, picker in pairs(color_pickers) do
        if saved_colors[name] and picker.ref then
            local c = saved_colors[name]
            if type(c) == "table" and #c == 4 then
                ui.set(picker.ref, c[1], c[2], c[3], c[4])
            end
        end
    end
end
local function save_colors()
    local colors_to_save = {}
    for name, picker in pairs(color_pickers) do
        if picker.ref then
            local r, g, b, a = ui.get(picker.ref)
            colors_to_save[name] = {r, g, b, a}
        end
    end
    database.write(color_db_key, colors_to_save)
end
load_colors()
client.delay_call(0.5, function()
    load_colors()
end)
for name, picker in pairs(color_pickers) do
    if picker.ref then
        ui.set_callback(picker.ref, save_colors)
    end
end

local function get_menu_value(element)
    if element.get then
        return element:get()
    elseif type(element) == "number" then
        return ui.get(element)
    end
    return nil
end
local function get_color_value(element)
    if element and element.get then
        local r, g, b, a = element:get()
        return r or 255, g or 255, b or 255, a or 255
    elseif element and element.ref then
        local r, g, b, a = ui.get(element.ref)
        return r or 255, g or 255, b or 255, a or 255
    elseif type(element) == "number" then
        local r, g, b, a = ui.get(element)
        return r or 255, g or 255, b or 255, a or 255
    end
    return 255, 255, 255, 255
end
local function set_menu_visible(element, visible)
    if element.set_visible then
        element:set_visible(visible)
    elseif type(element) == "number" then
        ui.set_visible(element, visible)
    end
end
menu.builder = {}
for _, state_name in ipairs(state_list) do
    menu.builder[state_name] = {}
    local state_config = menu.builder[state_name]
    local suffix = "\n" .. state_name
    if state_name ~= "Global" then
        state_config.enable = pui_group:checkbox("Override" .. suffix, false)
    end
    state_config.yaw_base_degrees = pui_group:slider("Base Yaw" .. suffix, -180, 180, 0, true, "°", 1)
    state_config.yaw_base_randomize = pui_group:slider("Yaw Random" .. suffix, 0, 5, 0, true, "°", 1)
    state_config.yaw_offset_label = pui_group:label(" " .. suffix)
    state_config.desync_type = pui_group:combobox("Desync" .. suffix, {"Disabled", "L/R", "Multi-Way"})
    state_config.desync_left_limit = pui_group:slider("Left" .. suffix, -60, 60, 0, true, "°", 1)
    state_config.desync_right_limit = pui_group:slider("Right" .. suffix, -60, 60, 0, true, "°", 1)
    state_config.desync_randomization = pui_group:slider("Randomize" .. suffix, 0, 20, 0, true, "°", 1)
    state_config.timing_tick_delay = pui_group:slider("Switch Speed" .. suffix, 1, 10, 3, true, "t", 1)
    state_config.timing_tick_variance = pui_group:slider("Speed Random" .. suffix, 0, 8, 0, true, "t", 0.5)
    state_config.desync_xway_count = pui_group:slider("Ways" .. suffix, 2, 8, 3, true, "", 1)
    state_config.desync_xway_steps = {}
    for i = 1, 8 do
        state_config.desync_xway_steps[i] = pui_group:slider("  " .. i .. suffix, -60, 60, 0, true, "°", 1)
    end
    state_config.desync_xway_delay = pui_group:slider("Cycle Speed" .. suffix, 1, 10, 3, true, "t", 1)
    state_config.desync_xway_variance = pui_group:slider("Cycle Chaos" .. suffix, 0, 8, 2, true, "t", 0.1)
    state_config.body_yaw_label = pui_group:label(" " .. suffix)
    state_config.body_yaw_mode = pui_group:combobox("Body Yaw" .. suffix, {"Disabled", "Static", "Jitter"})
    state_config.body_yaw_degrees = pui_group:slider("Offset" .. suffix, -60, 60, 0, true, "°", 1)
    state_config.body_yaw_jitter_left = pui_group:slider("Jitter Left" .. suffix, 0, 60, 60, true, "°", 1)
    state_config.body_yaw_jitter_right = pui_group:slider("Jitter Right" .. suffix, 0, 60, 60, true, "°", 1)
    state_config.body_yaw_jitter_variance = pui_group:slider("BY Randomize" .. suffix, 0, 20, 0, true, "°", 1)
    state_config.body_yaw_variance_delay = pui_group:slider("Jitter Speed" .. suffix, 1, 10, 3, true, "t", 1)
    state_config.body_yaw_delay_variance = pui_group:slider("BY Speed Chaos" .. suffix, 0, 8, 0, true, "t", 0.1)
end
menu.builder_package = pui.setup(menu.builder)
local function init_ui_visibility()
    menu.antiaim.condition:set_visible(false)
    menu.antiaim.freestanding:set_visible(false)
    menu.antiaim.edge_yaw:set_visible(false)
    menu.antiaim.manual_left:set_visible(false)
    menu.antiaim.manual_right:set_visible(false)
    menu.antiaim.manual_back:set_visible(false)
    menu.antiaim.manual_forward:set_visible(false)
    menu.antiaim.safe_head:set_visible(false)
    menu.antiaim.safe_head_triggers:set_visible(false)
    menu.antiaim.utilities:set_visible(false)
end
init_ui_visibility()
local function hide_all()
    for _, element in pairs(menu.info) do
        if element.set_visible then element:set_visible(false) end
    end
    for _, element in pairs(menu.ragebot) do
        if element.set_visible then element:set_visible(false) end
    end
    for _, element in pairs(menu.visual) do
        if element.set_visible then element:set_visible(false) end
    end
    for _, element in pairs(menu.misc) do
        if element.set_visible then element:set_visible(false) end
    end
    for _, element in pairs(menu.config) do
        if element.set_visible then element:set_visible(false) end
    end
    menu.antiaim.aa_mode:set_visible(false)
    menu.antiaim.condition:set_visible(false)
    menu.antiaim.freestanding:set_visible(false)
    menu.antiaim.edge_yaw:set_visible(false)
    menu.antiaim.manual_left:set_visible(false)
    menu.antiaim.manual_right:set_visible(false)
    menu.antiaim.manual_back:set_visible(false)
    menu.antiaim.manual_forward:set_visible(false)
    menu.antiaim.safe_head:set_visible(false)
    menu.antiaim.safe_head_triggers:set_visible(false)
    menu.antiaim.utilities:set_visible(false)
    if menu.builder then
        for _, state_name in ipairs(state_list) do
            local state_config = menu.builder[state_name]
            if state_config then
                if state_config.enable then state_config.enable:set_visible(false) end
                state_config.yaw_base_degrees:set_visible(false)
                if state_config.yaw_base_randomize then state_config.yaw_base_randomize:set_visible(false) end
                state_config.yaw_offset_label:set_visible(false)
                state_config.desync_type:set_visible(false)
                state_config.desync_left_limit:set_visible(false)
                state_config.desync_right_limit:set_visible(false)
                state_config.desync_randomization:set_visible(false)
                state_config.timing_tick_delay:set_visible(false)
                state_config.timing_tick_variance:set_visible(false)
                state_config.desync_xway_count:set_visible(false)
                state_config.desync_xway_delay:set_visible(false)
                state_config.desync_xway_variance:set_visible(false)
                for i = 1, 8 do
                    state_config.desync_xway_steps[i]:set_visible(false)
                end
                state_config.body_yaw_label:set_visible(false)
                state_config.body_yaw_mode:set_visible(false)
                state_config.body_yaw_degrees:set_visible(false)
                state_config.body_yaw_jitter_left:set_visible(false)
                state_config.body_yaw_jitter_right:set_visible(false)
                state_config.body_yaw_jitter_variance:set_visible(false)
                state_config.body_yaw_variance_delay:set_visible(false)
                state_config.body_yaw_variance_delay:set_visible(false)
                state_config.body_yaw_delay_variance:set_visible(false)
            end
        end
    end
    if menu.defensive then
        if menu.defensive.condition then menu.defensive.condition:set_visible(false) end
        for _, state_name in ipairs(state_list) do
            local def_config = menu.defensive[state_name]
            if def_config then
                if def_config.enable then def_config.enable:set_visible(false) end
                if def_config.def_force then def_config.def_force:set_visible(false) end
                if def_config.def_enable then def_config.def_enable:set_visible(false) end
                if def_config.def_tick_mode then def_config.def_tick_mode:set_visible(false) end
                if def_config.def_tick_speed then def_config.def_tick_speed:set_visible(false) end
                if def_config.def_pitch_mode then def_config.def_pitch_mode:set_visible(false) end
                if def_config.def_pitch_1 then def_config.def_pitch_1:set_visible(false) end
                if def_config.def_pitch_2 then def_config.def_pitch_2:set_visible(false) end
                if def_config.def_pitch_speed then def_config.def_pitch_speed:set_visible(false) end
                if def_config.def_yaw_mode then def_config.def_yaw_mode:set_visible(false) end
                if def_config.def_yaw_offset then def_config.def_yaw_offset:set_visible(false) end
                if def_config.def_yaw_left then def_config.def_yaw_left:set_visible(false) end
                if def_config.def_yaw_right then def_config.def_yaw_right:set_visible(false) end
                if def_config.def_yaw_speed then def_config.def_yaw_speed:set_visible(false) end
                if def_config.def_jitter_delay_min then def_config.def_jitter_delay_min:set_visible(false) end
                if def_config.def_jitter_delay_max then def_config.def_jitter_delay_max:set_visible(false) end
                if def_config.def_3way_angle1 then def_config.def_3way_angle1:set_visible(false) end
                if def_config.def_3way_angle2 then def_config.def_3way_angle2:set_visible(false) end
                if def_config.def_3way_angle3 then def_config.def_3way_angle3:set_visible(false) end
                if def_config.def_3way_delay then def_config.def_3way_delay:set_visible(false) end
            end
        end
    end
end
show_tab = function(tab_name)
    hide_all()
    local tab_map = {
        ["Info"] = "info", ["Ragebot"] = "ragebot", ["Anti-Aim"] = "antiaim",
        ["Visual"] = "visual", ["Misc"] = "misc", ["Config"] = "config"
    }
    local selected = nil
    for key, value in pairs(tab_map) do
        if string.find(tab_name, key, 1, true) then selected = value break end
    end
    if selected and menu[selected] and selected ~= "antiaim" then
        for _, element in pairs(menu[selected]) do
            if element.set_visible then
                element:set_visible(true)
            end
        end
        if selected == "visual" then
            update_visual_visibility()
        end
        if selected == "ragebot" then
            menu.ragebot.dormant_aimbot:set_visible(true)
            menu.ragebot.unsafe_charge:set_visible(true)
            menu.ragebot.hideshots_enabled:set_visible(true)
            local hideshots_enabled = get_menu_value(menu.ragebot.hideshots_enabled)
            menu.ragebot.hideshots_weapons:set_visible(hideshots_enabled)
            menu.ragebot.hideshots_states:set_visible(hideshots_enabled)
            menu.ragebot.air_stop_enabled:set_visible(true)
            local air_stop_enabled = get_menu_value(menu.ragebot.air_stop_enabled)
            menu.ragebot.air_stop_multi_hitbox:set_visible(air_stop_enabled)
            menu.ragebot.air_stop_range:set_visible(air_stop_enabled)
            menu.ragebot.peekbot_enabled:set_visible(true)
            menu.ragebot.peekbot_teleport:set_visible(true)
            menu.ragebot.peekbot_range:set_visible(true)
        end
        if selected == "misc" then
            menu.misc.chat_spammer:set_visible(true)
            menu.misc.clantag:set_visible(true)
            local clantag_enabled = get_menu_value(menu.misc.clantag)
            menu.misc.clantag_text:set_visible(clantag_enabled)
            menu.misc.animation_breaker:set_visible(true)
            local anim_enabled = get_menu_value(menu.misc.animation_breaker)
            menu.misc.animation_ground:set_visible(anim_enabled)
            menu.misc.animation_air:set_visible(anim_enabled)
            menu.misc.body_lean:set_visible(anim_enabled)
            menu.misc.pitch_on_land:set_visible(anim_enabled)
            menu.misc.earthquake:set_visible(anim_enabled)
            local earthquake_enabled = anim_enabled and get_menu_value(menu.misc.earthquake)
            menu.misc.earthquake_intensity:set_visible(earthquake_enabled)
            menu.misc.autobuy_enabled:set_visible(true)
            local autobuy_enabled = get_menu_value(menu.misc.autobuy_enabled)
            menu.misc.autobuy_primary:set_visible(autobuy_enabled)
            menu.misc.autobuy_secondary:set_visible(autobuy_enabled)
            menu.misc.autobuy_grenades:set_visible(autobuy_enabled)
            menu.misc.autobuy_utilities:set_visible(autobuy_enabled)
        end
        if selected == "config" then
            menu.config.list:set_visible(true)
            menu.config.name:set_visible(true)
            menu.config.load:set_visible(true)
            menu.config.save:set_visible(true)
            menu.config.delete:set_visible(true)
            menu.config.import:set_visible(true)
            menu.config.export:set_visible(true)
        end
    end
    if selected == "antiaim" then
        menu.antiaim.aa_mode:set_visible(true)
        local aa_mode = menu.antiaim.aa_mode:get()
        if aa_mode == "Builder" then
            menu.antiaim.condition:set_visible(true)
            local current_state = menu.antiaim.condition:get()
            local state_config = menu.builder[current_state]
            if state_config then
                if state_config.enable then
                    state_config.enable:set_visible(true)
                end
                local should_show = (current_state == "Global") or (state_config.enable and state_config.enable:get())
                if should_show then
                    state_config.yaw_base_degrees:set_visible(true)
                    if state_config.yaw_base_randomize then
                        state_config.yaw_base_randomize:set_visible(true)
                    end
                    state_config.yaw_offset_label:set_visible(true)
                    state_config.desync_type:set_visible(true)
                    state_config.body_yaw_label:set_visible(true)
                    state_config.body_yaw_mode:set_visible(true)
                    local desync_type = state_config.desync_type:get()
                    if type(desync_type) == "number" then
                        local modes = {"Disabled", "L/R", "Multi-Way"}
                        desync_type = modes[desync_type + 1] or "Disabled"
                    end
                    if desync_type == "L/R" then
                        state_config.desync_left_limit:set_visible(true)
                        state_config.desync_right_limit:set_visible(true)
                        state_config.desync_randomization:set_visible(true)
                        state_config.timing_tick_delay:set_visible(true)
                        state_config.timing_tick_variance:set_visible(true)
                    elseif desync_type == "Multi-Way" then
                        state_config.desync_xway_count:set_visible(true)
                        state_config.desync_xway_delay:set_visible(true)
                        state_config.desync_xway_variance:set_visible(true)
                        local way_count = state_config.desync_xway_count:get()
                        for i = 1, way_count do
                            state_config.desync_xway_steps[i]:set_visible(true)
                        end
                    end
                    local body_yaw_mode = state_config.body_yaw_mode:get()
                    if type(body_yaw_mode) == "number" then
                        local modes = {"Disabled", "Static", "Jitter"}
                        body_yaw_mode = modes[body_yaw_mode + 1] or "Disabled"
                    end
                    if body_yaw_mode == "Static" then
                        state_config.body_yaw_degrees:set_visible(true)
                    elseif body_yaw_mode == "Jitter" then
                        state_config.body_yaw_jitter_left:set_visible(true)
                        state_config.body_yaw_jitter_right:set_visible(true)
                        state_config.body_yaw_jitter_variance:set_visible(true)
                        state_config.body_yaw_variance_delay:set_visible(true)
                        state_config.body_yaw_delay_variance:set_visible(true)
                    end
                end
            end
        elseif aa_mode == "Presets" then
            menu.antiaim.freestanding:set_visible(true)
            menu.antiaim.edge_yaw:set_visible(true)
            menu.antiaim.manual_left:set_visible(true)
            menu.antiaim.manual_right:set_visible(true)
            menu.antiaim.manual_back:set_visible(true)
            menu.antiaim.manual_forward:set_visible(true)
            menu.antiaim.safe_head:set_visible(true)
            menu.antiaim.utilities:set_visible(true)
            local safe_head_enabled = menu.antiaim.safe_head:get()
            menu.antiaim.safe_head_triggers:set_visible(safe_head_enabled)
        elseif aa_mode == "Defensive" then
            menu.defensive.condition:set_visible(true)
            local current_state = menu.defensive.condition:get()
            local def_config = menu.defensive[current_state]
            if def_config then
                if def_config.enable then
                    def_config.enable:set_visible(true)
                end
                local should_show = (current_state == "Global") or (def_config.enable and def_config.enable:get())
                if should_show then
                    def_config.def_force:set_visible(true)
                    def_config.def_enable:set_visible(true)

                    local def_enabled = def_config.def_enable:get()
                    if def_enabled then
                        def_config.def_tick_mode:set_visible(true)
                        local tick_mode = def_config.def_tick_mode:get()
                        if tick_mode == "Custom" then
                            def_config.def_tick_speed:set_visible(true)
                        end

                        def_config.def_pitch_mode:set_visible(true)
                        local pitch_mode = def_config.def_pitch_mode:get()
                        if pitch_mode ~= "Off" then
                            def_config.def_pitch_1:set_visible(true)
                            if pitch_mode ~= "Static" then
                                def_config.def_pitch_2:set_visible(true)
                            end
                            if pitch_mode == "Sway" then
                                def_config.def_pitch_speed:set_visible(true)
                            end
                        end

                        def_config.def_yaw_mode:set_visible(true)
                        local yaw_mode = def_config.def_yaw_mode:get()
                        if yaw_mode ~= "Off" then
                            if yaw_mode == "Static" or yaw_mode == "Spin" or yaw_mode == "Random" then
                                def_config.def_yaw_offset:set_visible(true)
                            end
                            if yaw_mode == "Sway" or yaw_mode == "Jitter" then
                                def_config.def_yaw_left:set_visible(true)
                                def_config.def_yaw_right:set_visible(true)
                            end
                            if yaw_mode == "Spin" or yaw_mode == "Sway" then
                                def_config.def_yaw_speed:set_visible(true)
                            end
                            if yaw_mode == "Jitter" then
                                def_config.def_jitter_delay_min:set_visible(true)
                                def_config.def_jitter_delay_max:set_visible(true)
                            end
                            if yaw_mode == "3-Way" then
                                def_config.def_3way_angle1:set_visible(true)
                                def_config.def_3way_angle2:set_visible(true)
                                def_config.def_3way_angle3:set_visible(true)
                                def_config.def_3way_delay:set_visible(true)
                            end
                        end
                    end
                end
            end
        end
    end
end
ui.set_callback(menu.tab.ref, function() show_tab(menu.tab:get()) end)
ui.set_callback(menu.antiaim.condition.ref, function()
    local current_tab = menu.tab:get()
    if string.find(current_tab, "Anti-Aim", 1, true) then
        show_tab(current_tab)
    end
end)
ui.set_callback(menu.antiaim.aa_mode.ref, function()
    show_tab(menu.tab:get())
end)
for _, state_name in ipairs(state_list) do
    local state_config = menu.builder[state_name]
    ui.set_callback(state_config.desync_type.ref, function()
        local current_tab = menu.tab:get()
        if string.find(current_tab, "Anti-Aim", 1, true) then
            show_tab(current_tab)
        end
    end)
    ui.set_callback(state_config.desync_xway_count.ref, function()
        local current_tab = menu.tab:get()
        if string.find(current_tab, "Anti-Aim", 1, true) then
            show_tab(current_tab)
        end
    end)
    ui.set_callback(state_config.body_yaw_mode.ref, function()
        local current_tab = menu.tab:get()
        if string.find(current_tab, "Anti-Aim", 1, true) then
            show_tab(current_tab)
        end
    end)
    if state_config.enable then
        ui.set_callback(state_config.enable.ref, function()
            local current_tab = menu.tab:get()
            if string.find(current_tab, "Anti-Aim", 1, true) then
                show_tab(current_tab)
            end
        end)
    end
end

ui.set_callback(menu.defensive.condition.ref, function()
    local current_tab = menu.tab:get()
    if string.find(current_tab, "Anti-Aim", 1, true) then
        show_tab(current_tab)
    end
end)

for _, state_name in ipairs(state_list) do
    local def_config = menu.defensive[state_name]
    if def_config then
        if def_config.enable then
            ui.set_callback(def_config.enable.ref, function()
                local current_tab = menu.tab:get()
                if string.find(current_tab, "Anti-Aim", 1, true) then
                    show_tab(current_tab)
                end
            end)
        end
        if def_config.def_enable then
            ui.set_callback(def_config.def_enable.ref, function()
                local current_tab = menu.tab:get()
                if string.find(current_tab, "Anti-Aim", 1, true) then
                    show_tab(current_tab)
                end
            end)
        end
        if def_config.def_tick_mode then
            ui.set_callback(def_config.def_tick_mode.ref, function()
                local current_tab = menu.tab:get()
                if string.find(current_tab, "Anti-Aim", 1, true) then
                    show_tab(current_tab)
                end
            end)
        end
        if def_config.def_pitch_mode then
            ui.set_callback(def_config.def_pitch_mode.ref, function()
                local current_tab = menu.tab:get()
                if string.find(current_tab, "Anti-Aim", 1, true) then
                    show_tab(current_tab)
                end
            end)
        end
        if def_config.def_yaw_mode then
            ui.set_callback(def_config.def_yaw_mode.ref, function()
                local current_tab = menu.tab:get()
                if string.find(current_tab, "Anti-Aim", 1, true) then
                    show_tab(current_tab)
                end
            end)
        end
    end
end

hide_all()
show_tab("\u{E148} Info")
ui.set_callback(menu.antiaim.safe_head.ref, function()
    local aa_mode = menu.antiaim.aa_mode:get()
    if aa_mode == "Presets" then
        local safe_head_enabled = menu.antiaim.safe_head:get()
        menu.antiaim.safe_head_triggers:set_visible(safe_head_enabled)
    end
end)
ui.set_callback(menu.ragebot.hideshots_enabled.ref, function()
    local current_tab = menu.tab:get()
    if string.find(current_tab, "Ragebot", 1, true) then
        show_tab(current_tab)
    end
end)
ui.set_callback(menu.ragebot.air_stop_enabled.ref, function()
    local current_tab = menu.tab:get()
    if string.find(current_tab, "Ragebot", 1, true) then
        show_tab(current_tab)
    end
end)
ui.set_callback(menu.ragebot.peekbot_enabled.ref, function()
    local current_tab = menu.tab:get()
    if string.find(current_tab, "Ragebot", 1, true) then
        show_tab(current_tab)
    end
end)
ui.set_callback(menu.misc.animation_breaker.ref, function()
    local current_tab = menu.tab:get()
    if string.find(current_tab, "Misc", 1, true) then
        show_tab(current_tab)
    end
end)
ui.set_callback(menu.misc.earthquake.ref, function()
    local current_tab = menu.tab:get()
    if string.find(current_tab, "Misc", 1, true) then
        show_tab(current_tab)
    end
end)
ui.set_callback(menu.misc.autobuy_enabled.ref, function()
    local current_tab = menu.tab:get()
    if string.find(current_tab, "Misc", 1, true) then
        show_tab(current_tab)
    end
end)
ui.set_callback(menu.misc.clantag.ref, function()
    local current_tab = menu.tab:get()
    if string.find(current_tab, "Misc", 1, true) then
        show_tab(current_tab)
    end
end)
local table_contains = utils.table_contains  
on_use = {
    enabled = false,
    start_time = globals.realtime()
}
local manual_dir = 0
local helpers = {}
function helpers.air(player_entity)
    local player_flags = entity.get_prop(player_entity, "m_fFlags")
    if not player_flags then return false end
    return bit.band(player_flags, 1) == 0
end
function helpers.in_duck(player_entity)
    local player_flags = entity.get_prop(player_entity, "m_fFlags")
    if not player_flags then return false end
    return bit.band(player_flags, 4) == 4
end
local was_airborne = false
local last_state_tick = 0
local slow_motion_ref = {}
slow_motion_ref[1], slow_motion_ref[2] = ui.reference('AA', 'Other', 'Slow motion')
local duck_peek_assist_ref = ui.reference("RAGE", "Other", "Duck peek assist")
local dt_hotkey_ref = select(2, ui.reference("RAGE", "Aimbot", "Double tap"))
local os_hotkey_ref = select(2, ui.reference("AA", "Other", "On shot anti-aim"))
local function get_basic_state(cmd)
    local me = entity.get_local_player()
    if not me or not entity.is_alive(me) then return "Stand" end
    local vx, vy, vz = entity.get_prop(me, "m_vecVelocity")
    local velocity = vx and math.sqrt(vx * vx + vy * vy) or 0
    local is_ducking = helpers.in_duck(me) or (duck_peek_assist_ref and ui.get(duck_peek_assist_ref))
    local current_state = velocity > 1.5 and "Move" or "Stand"
    local in_jump = cmd and cmd.in_jump or 0
    if (helpers.air(me) and in_jump == 1) or was_airborne then
        current_state = is_ducking and "C-Air" or "Air"
    elseif velocity > 1.5 and is_ducking then
        current_state = "C-Move"
    elseif slow_motion_ref[1] and slow_motion_ref[2] and ui.get(slow_motion_ref[1]) and ui.get(slow_motion_ref[2]) then
        current_state = "Slow"
    elseif is_ducking then
        current_state = "Crouch"
    end
    if globals.tickcount() ~= last_state_tick then
        was_airborne = helpers.air(me) or false
        last_state_tick = globals.tickcount()
    end
    return current_state
end
local function get_player_state(cmd)
    local me = entity.get_local_player()
    if not me or not entity.is_alive(me) then return "Global" end
    local current_state = get_basic_state(cmd or {})
    local current_manual_dir = manual_dir or 0
    local is_freestanding = false
    if menu.antiaim.freestanding and menu.antiaim.freestanding:get() then
        is_freestanding = true
        if current_manual_dir ~= 0 then
            is_freestanding = false
        end
    end
    local weapon = entity.get_player_weapon(me)
    local is_knife = weapon and entity.get_classname(weapon) == "CKnife"
    local is_taser = weapon and entity.get_classname(weapon) == "CWeaponTaser"
    local safe_head_knife = menu.antiaim.safe_head_triggers:get("Knife") and is_knife
    local safe_head_taser = menu.antiaim.safe_head_triggers:get("Zeus") and is_taser
    if menu.antiaim.safe_head:get() and (safe_head_knife or safe_head_taser) and (current_state == "C-Air" or current_state == "Air") then
        current_state = "Safe"
        if menu.antiaim.utilities:get("Auto Duck in Air") and cmd then
            cmd.in_duck = 1
        end
    end
    local freestand_config = menu.builder["Freestand"]
    if freestand_config and freestand_config.enable and freestand_config.enable:get() and is_freestanding then
        current_state = "Freestand"
    end
    local manual_config = menu.builder["Manual"]
    if current_manual_dir ~= 0 and manual_config and manual_config.enable and manual_config.enable:get() then
        current_state = "Manual"
    end
    local use_config = menu.builder["Use"]
    if on_use.enabled and use_config.enable and use_config.enable:get() then
        current_state = "Use"
    end
    local dt_active = dt_hotkey_ref and ui.get(dt_hotkey_ref)
    local onshot_active = os_hotkey_ref and ui.get(os_hotkey_ref)
    local duck_peek_active = duck_peek_assist_ref and ui.get(duck_peek_assist_ref)
    local fakelag_config = menu.builder["Fakelag"]
    if fakelag_config.enable and fakelag_config.enable:get() and globals.chokedcommands() > 0 and not onshot_active and not dt_active and not duck_peek_active then
        return "Fakelag"
    end
    return current_state
end
local current_cmd = {}
local function get_base_offset()
    local state = get_player_state(current_cmd)
    local vals = menu.builder_values[state]
    if state ~= "Global" and not vals.enable then
        vals = menu.builder_values["Global"]
    end
    return vals.yaw_base_degrees or 0
end
local global_anti_prediction = {
    cache = {
        chaos_values = {},
        last_update_tick = 0,
        cache_duration = 2,
        entropy_pool = {},
        entropy_pool_size = 32,
        entropy_pool_idx = 1
    },
    coordination = {
        desync_phase = 0,
        body_yaw_phase = 0,
        sync_mode = 1,
        last_sync_change = 0,
        global_entropy_seed = 0
    },
    memory = {
        max_state_profiles = 8,
        state_access_order = {},
        cleanup_interval = 256
    }
}
local function inject_true_entropy()
    local me = entity.get_local_player()
    if not me then return math.random(0, 10000) end
    local pitch, yaw = client.camera_angles()
    local mouse_entropy = math.floor((pitch * 1000 + yaw * 1000) % 10000)
    local latency = client.latency()
    local latency_entropy = math.floor((latency * 1000000) % 10000)
    local vx, vy, vz = entity.get_prop(me, "m_vecVelocity")
    local velocity_entropy = 0
    if vx then
        velocity_entropy = math.floor((math.abs(vx) * 137 + math.abs(vy) * 239 + math.abs(vz) * 419) % 10000)
    end
    local enemy_entropy = 0
    local enemies = entity.get_players(true)
    if #enemies > 0 then
        local ex, ey, ez = entity.get_origin(enemies[1])
        if ex then
            enemy_entropy = math.floor((ex * 17 + ey * 31 + ez * 47) % 10000)
        end
    end
    return bit.bxor(bit.bxor(bit.bxor(mouse_entropy, latency_entropy), velocity_entropy), enemy_entropy)
end
local function get_cached_entropy()
    local cache = global_anti_prediction.cache
    cache.entropy_pool_idx = (cache.entropy_pool_idx % cache.entropy_pool_size) + 1
    if cache.entropy_pool_idx % 4 == 0 then
        cache.entropy_pool[cache.entropy_pool_idx] = inject_true_entropy()
    end
    return cache.entropy_pool[cache.entropy_pool_idx]
end
local function get_cached_chaos(chaos_type, force_update)
    local cache = global_anti_prediction.cache
    local current_tick = globals.tickcount()
    if not force_update and (current_tick - cache.last_update_tick) < cache.cache_duration then
        if cache.chaos_values[chaos_type] then
            return cache.chaos_values[chaos_type]
        end
    end
    if (current_tick - cache.last_update_tick) >= cache.cache_duration then
        cache.last_update_tick = current_tick
        cache.chaos_values = {}
    end
    return nil
end
local function update_chaos_cache(chaos_type, value)
    global_anti_prediction.cache.chaos_values[chaos_type] = value
end
local function manage_state_profiles(state_profiles, current_state)
    local memory = global_anti_prediction.memory
    local access_order = memory.state_access_order
    for i = #access_order, 1, -1 do
        if access_order[i] == current_state then
            table.remove(access_order, i)
            break
        end
    end
    table.insert(access_order, current_state)
    if #access_order > memory.max_state_profiles then
        local oldest_state = table.remove(access_order, 1)
        state_profiles[oldest_state] = nil
    end
end
global_anti_prediction.yaw_offset_state = {
    lr_cycle = 1,
    lr_side = 1,
    lr_current_delay = 3,
    lr_seed = 0,
    lr_variance_seed = 0,
    lr_offset_left = 0,
    lr_offset_right = 0,
    xway_cycle = 1,
    xway_current_step = 1,
    xway_current_delay = 1,
    xway_seed = 0
}
global_anti_prediction.body_yaw_state = {
    last_yaw_offset = 0,
    jitter_cycle = 1,
    jitter_side = 1,
    jitter_offset_left = 0,
    jitter_offset_right = 0,
    jitter_current_delay = 3,
    jitter_seed = 0,
    jitter_variance_seed = 0,
    jitter_momentum = 0,
    jitter_direction_bias = 0,
    jitter_rhythm_counter = 0,
    jitter_anti_resolver_mode = 0,
    jitter_last_switch_tick = 0,
    jitter_switch_pattern = {},
    jitter_entropy_pool = {},
    jitter_neural_weight = 0.5,
    by_chaos_accumulator = 0,
    by_pattern_history = {},
    by_pattern_history_size = 8,
    by_burst_active = false,
    by_burst_cooldown = 0,
    by_burst_intensity = 0,
    by_micro_offset_left = 0,
    by_micro_offset_right = 0,
    by_velocity_entropy = 0,
    by_adaptive_scale = 1.0,
    by_last_output_left = 0,
    by_last_output_right = 0,
    by_oscillation_phase = 0,
    by_spike_counter = 0,
    by_spike_cooldown = 0,
    by_quantum_state = 0,
    by_quantum_history = {},
    by_quantum_collapse_tick = 0,
    by_markov_chain = {0, 0, 0, 0},
    by_markov_index = 1,
    by_fractal_seed = 12345,
    by_fractal_depth = 0,
    by_neural_weights = {0.5, 0.3, 0.2, 0.4, 0.6},
    by_neural_bias = 0,
    by_chaos_attractor = {x = 0.1, y = 0.1, z = 0.1},
    by_lorenz_dt = 0.01,
    by_frequency_hopping = 0,
    by_frequency_table = {3, 5, 7, 11, 13, 17, 19, 23},
    by_frequency_index = 1,
    by_anti_ml_counter = 0,
    by_anti_ml_mode = 0,
    by_temporal_shift = 0,
    by_temporal_history = {},
    by_entropy_accumulator = 0,
    by_prime_sequence_idx = 1,
    by_fibonacci_a = 1,
    by_fibonacci_b = 1,
    by_golden_ratio_phase = 0,
    by_noise_octaves = {},
    by_perlin_offset = 0,
    by_prediction_detector = {
        history = {},
        detected_pattern = false,
        counter_mode = 0,
        last_detection_tick = 0
    },
    by_enemy_aim_tracking = {
        last_enemy_angles = {},
        aim_lock_detected = false,
        aim_lock_counter = 0
    },
    by_last_health = 100,
    by_hit_response_active = false,
    by_hit_response_duration = 0,
    by_enemy_angle_history = {},
    by_quantum_superposition = {},
    by_rossler_attractor = {x = 0.1, y = 0.1, z = 0.1},
    by_henon_x = 0.1,
    by_henon_y = 0.1,
    by_logistic_r = 3.9,
    by_logistic_x = 0.5,
    by_tent_x = 0.5,
    by_sinai_phase = 0,
    by_arnold_cat = {x = 0.3, y = 0.7},
    by_cellular_automata = {},
    by_ca_rule = 110,
    by_lfsr_state = 0xACE1,
    by_lfsr_poly = 0xB400,
    by_game_theory_history = {},
    by_game_theory_strategy = 1,
    by_neural_layer1 = {0, 0, 0, 0},
    by_neural_layer2 = {0, 0},
    by_learning_rate = 0.1,
    by_momentum_buffer = {},
    by_gradient_history = {},
    by_adversarial_noise = 0,
    by_entropy_pool_v3 = {},
    by_entropy_pool_idx = 1,
    by_brownian_x = 0,
    by_brownian_y = 0,
    by_levy_flight_step = 0,
    by_pink_noise_state = {0, 0, 0, 0, 0, 0, 0},
    by_blue_noise_last = 0,
    by_halton_idx = 1,
    by_sobol_state = 0,
    by_weyl_sequence = 0,
    by_reaction_diffusion = {u = 0.5, v = 0.25},
    by_strange_attractor_mode = 0,
    by_duffing_x = 0.1,
    by_duffing_v = 0,
    by_ikeda_x = 0.1,
    by_ikeda_y = 0.1,
    by_tinkerbell_x = -0.72,
    by_tinkerbell_y = -0.64,
    by_gingerbread_x = 0.1,
    by_gingerbread_y = 0.1,
    by_resolver_bait_mode = 0,
    by_resolver_bait_cooldown = 0,
    by_fake_pattern_inject = false,
    by_fake_pattern_length = 0,
    by_fake_pattern_data = {},
    by_entropy_mixing_counter = 0,
    by_cipher_state = {0, 0, 0, 0},
    by_cipher_round = 0,
    by_sbox = {},
    by_diffusion_matrix = {},
    by_chua_x = 0.1,
    by_chua_y = 0.1,
    by_chua_z = 0.1,
    by_sprott_x = 0.1,
    by_sprott_y = 0.1,
    by_sprott_z = 0.1,
    by_chen_x = 0.1,
    by_chen_y = 0.1,
    by_chen_z = 0.1,
    by_aizawa_x = 0.1,
    by_aizawa_y = 0,
    by_aizawa_z = 0,
    by_thomas_x = 0.1,
    by_thomas_y = 0,
    by_thomas_z = 0,
    by_rabinovich_x = -1,
    by_rabinovich_y = 0,
    by_rabinovich_z = 0.5,
    by_three_scroll_x = 0.1,
    by_three_scroll_y = 0.1,
    by_three_scroll_z = 0.1,
    by_hyperchaos_w = 0.1,
    by_neural_network = {},
    by_nn_weights_l1 = {},
    by_nn_weights_l2 = {},
    by_nn_bias_l1 = {},
    by_nn_bias_l2 = {},
    by_genetic_population = {},
    by_genetic_fitness = {},
    by_genetic_generation = 0,
    by_simulated_annealing_temp = 100,
    by_sa_current_state = 0,
    by_sa_best_state = 0,
    by_particle_swarm = {},
    by_pso_velocity = {},
    by_pso_best_local = {},
    by_pso_best_global = 0,
    by_ant_colony_pheromone = {},
    by_ant_position = 1,
    by_reservoir_state = {},
    by_reservoir_weights = {},
    by_echo_state = {},
    by_wavelet_coeffs = {},
    by_wavelet_scale = 1,
    by_fourier_phase = {},
    by_fourier_amplitude = {},
    by_dct_coeffs = {},
    by_hilbert_phase = 0,
    by_empirical_mode = {},
    by_kolmogorov_complexity = 0,
    by_lempel_ziv_dict = {},
    by_lz_position = 1,
    by_entropy_rate = 0,
    by_mutual_info_history = {},
    by_transfer_entropy = 0,
    by_granger_causality = {},
    by_recurrence_matrix = {},
    by_lyapunov_exponent = 0,
    by_correlation_dimension = 0,
    by_hurst_exponent = 0.5,
    by_detrended_fluctuation = {},
    by_multifractal_spectrum = {},
    by_surrogate_data = {},
    by_bootstrap_samples = {},
    by_monte_carlo_state = 0,
    by_importance_sampling_weights = {},
    by_rejection_sampling_count = 0,
    by_metropolis_hastings_state = 0,
    by_gibbs_sampling_state = {},
    by_slice_sampling_width = 1,
    by_hamiltonian_momentum = 0,
    by_nuts_tree_depth = 0,
    by_variational_mean = 0,
    by_variational_var = 1,
    by_kl_divergence = 0,
    by_wasserstein_distance = 0,
    by_adversarial_generator_state = 0,
    by_adversarial_discriminator_state = 0,
    by_gan_latent_z = {},
    by_vae_latent_z = {},
    by_vae_mu = 0,
    by_vae_logvar = 0,
    by_flow_state = {},
    by_normalizing_flow_log_det = 0,
    by_diffusion_model_t = 0,
    by_score_function_estimate = 0,
    by_langevin_dynamics_x = 0,
    by_langevin_dynamics_v = 0,
    by_sde_wiener_process = 0,
    by_jump_diffusion_intensity = 0.1,
    by_poisson_process_count = 0,
    by_hawkes_process_intensity = 0.5,
    by_self_exciting_history = {},
    by_regime_switching_state = 1,
    by_hidden_markov_state = 1,
    by_hmm_emission_prob = {},
    by_kalman_state = 0,
    by_kalman_covariance = 1,
    by_particle_filter_weights = {},
    by_particle_filter_states = {},
    by_unscented_sigma_points = {},
    by_ensemble_kalman_states = {},
    by_adaptive_filter_coeffs = {},
    by_rls_gain = 1,
    by_lms_step_size = 0.01,
    by_nlms_normalization = 1,
    by_affine_projection_order = 4,
    by_subband_filter_states = {},
    by_frequency_domain_filter = {},
    by_overlap_save_buffer = {},
    by_polyphase_filter_states = {},
    by_multirate_decimation_factor = 2,
    by_interpolation_filter_state = 0,
    by_fractional_delay_filter = {},
    by_allpass_filter_state = 0,
    by_lattice_filter_coeffs = {},
    by_ladder_filter_state = 0,
    by_state_variable_filter = {lp = 0, bp = 0, hp = 0},
    by_biquad_state = {x1 = 0, x2 = 0, y1 = 0, y2 = 0},
    by_chebyshev_ripple = 0.5,
    by_elliptic_filter_state = 0,
    by_bessel_filter_state = 0,
    by_butterworth_order = 4,
    by_linkwitz_riley_state = 0,
    by_crossover_frequency = 1000,
    by_dynamic_range_compressor_state = 0,
    by_expander_state = 0,
    by_gate_state = 0,
    by_limiter_state = 0,
    by_soft_clipper_state = 0,
    by_waveshaper_state = 0,
    by_bitcrusher_state = 0,
    by_sample_rate_reducer_phase = 0,
    by_ring_modulator_phase = 0,
    by_frequency_shifter_phase = 0,
    by_pitch_shifter_state = {},
    by_granular_position = 0,
    by_granular_density = 10,
    by_spectral_freeze_state = {},
    by_convolution_ir = {},
    by_reverb_state = {},
    by_delay_line = {},
    by_delay_write_pos = 1,
    by_chorus_phase = 0,
    by_flanger_phase = 0,
    by_phaser_state = {},
    by_tremolo_phase = 0,
    by_vibrato_phase = 0,
    by_autopan_phase = 0,
    by_rotary_speaker_phase = 0,
    by_leslie_horn_angle = 0,
    by_doppler_velocity = 0
}
function on_use.handle(cmd)
    on_use.enabled = false
    if not menu.antiaim.utilities:get("Anti-Aim On Use") then
        return
    end
    if cmd.in_use == 0 then
        on_use.start_time = globals.realtime()
        return
    end
    local local_player = entity.get_local_player()
    if local_player == nil then
        return
    end
    local player_origin = {entity.get_origin(local_player)}
    local planted_bombs = entity.get_all("CPlantedC4")
    local bomb_distance = 999
    if #planted_bombs > 0 then
        local bomb_entity = planted_bombs[1]
        local bomb_origin = {entity.get_origin(bomb_entity)}
        bomb_distance = vector(player_origin[1], player_origin[2], player_origin[3]):dist(vector(bomb_origin[1], bomb_origin[2], bomb_origin[3]))
    end
    local hostages = entity.get_all("CHostage")
    local hostage_distance = 999
    if hostages ~= nil and #hostages > 0 then
        local hostage_origin = {entity.get_origin(hostages[1])}
        hostage_distance = vector(player_origin[1], player_origin[2], player_origin[3]):dist(vector(hostage_origin[1], hostage_origin[2], hostage_origin[3]))
    end
    if hostage_distance < 65 and entity.get_prop(local_player, "m_iTeamNum") ~= 2 then
        return
    end
    if bomb_distance < 65 and entity.get_prop(local_player, "m_iTeamNum") ~= 2 then
        return
    end
    if cmd.in_use == 1 and globals.realtime() - on_use.start_time < 0.02 then
        return
    end
    cmd.in_use = 0
    on_use.enabled = true
end
function on_use.ladder(cmd)
    if not menu.antiaim.utilities:get("Fast Ladder") then
        return
    end
    local me = entity.get_local_player()
    if not me then return end
    if entity.get_prop(me, "m_MoveType") ~= 9 or cmd.forwardmove == 0 then
        return
    end
    local cam_pitch, cam_yaw = client.camera_angles()
    local should_reverse = cmd.forwardmove < 0 or cam_pitch > 45
    cmd.in_moveleft = should_reverse and 1 or 0
    cmd.in_moveright = not should_reverse and 1 or 0
    cmd.in_forward = should_reverse and 1 or 0
    cmd.in_back = not should_reverse and 1 or 0
    cmd.pitch = 89
    local new_yaw = cmd.yaw + 90
    while new_yaw > 180 do new_yaw = new_yaw - 360 end
    while new_yaw < -180 do new_yaw = new_yaw + 360 end
    cmd.yaw = new_yaw
end

local manual_aa_active = nil
local manual_aa_items = {
    {name = "left", yaw = -90, item = nil, active = nil},
    {name = "right", yaw = 90, item = nil, active = nil},
    {name = "back", yaw = nil, item = nil, active = nil},
    {name = "forward", yaw = 180, item = nil, active = nil}
}
local function update_manual_aa()
    if not menu.manual_aa_hotkey then return end
    if manual_aa_items[1].item == nil then
        manual_aa_items[1].item = menu.manual_aa_hotkey.manual_left
        manual_aa_items[2].item = menu.manual_aa_hotkey.manual_right
        manual_aa_items[3].item = menu.manual_aa_hotkey.manual_back
        manual_aa_items[4].item = menu.manual_aa_hotkey.manual_forward
    end
    for i, item in ipairs(manual_aa_items) do
        if item.item then
            local is_active, mode = item.item:get()
            if item.active == nil then
                item.active = is_active
            end
            if item.active ~= is_active then
                item.active = is_active
                if item.yaw == nil then
                    manual_aa_active = nil
                end
                if mode == 1 then
                    manual_aa_active = is_active and i or nil
                elseif mode == 2 then
                    manual_aa_active = manual_aa_active ~= i and i or nil
                end
            end
        end
    end
    manual_dir = manual_aa_active and manual_aa_items[manual_aa_active].yaw or 0
end
global_anti_prediction.player_state = {
    on_ground = false,
    velocity = 0,
    shift = false,
    defensive_ticks_left = 0,
    defensive_diff = 0,
    defensivie_dadas = false,
    defensive = {
        default = 0,
        old = false,
        intelligent = false
    }
}
global_anti_prediction.entropy_streams = {
    yaw_left = { seed1 = 0, seed2 = 0, seed3 = 0, counter = 0 },
    yaw_right = { seed1 = 0, seed2 = 0, seed3 = 0, counter = 0 },
    body_left = { seed1 = 0, seed2 = 0, seed3 = 0, counter = 0 },
    body_right = { seed1 = 0, seed2 = 0, seed3 = 0, counter = 0 },
    xway = { seed1 = 0, seed2 = 0, seed3 = 0, counter = 0 },
    timing = { seed1 = 0, seed2 = 0, seed3 = 0, counter = 0 }
}
global_anti_prediction.entropy_state = {
    last_tick = 0,
    last_realtime = 0
}
local function init_entropy()
    local entropy_streams = global_anti_prediction.entropy_streams
    local entropy_state = global_anti_prediction.entropy_state
    local sys_time = { client.system_time() }
    local base = sys_time[1] * 3600000 + sys_time[2] * 60000 + sys_time[3] * 1000 + sys_time[4]
    local me = entity.get_local_player()
    local game_entropy = 0
    if me then
        local x, y, z = entity.get_origin(me)
        if x then
            game_entropy = math.floor((x * 1000 + y * 1000 + z * 1000) % 2147483647)
        end
    end
    local primes = {48271, 69621, 22695477, 1103515245, 16807, 2147483629}
    local stream_index = 1
    for stream_name, stream in pairs(entropy_streams) do
        local prime1 = primes[stream_index] or 48271
        local prime2 = primes[(stream_index % 6) + 1]
        local prime3 = primes[((stream_index * 2) % 6) + 1]
        stream.seed1 = (base * prime1 + game_entropy * stream_index) % 2147483647
        stream.seed2 = (base * prime2 + game_entropy * (stream_index * 7)) % 2147483647
        stream.seed3 = (base * prime3 + game_entropy * (stream_index * 13)) % 2147483647
        stream.counter = stream_index * 1000
        stream_index = stream_index + 1
    end
    entropy_state.last_tick = globals.tickcount()
    entropy_state.last_realtime = globals.realtime()
end
local function xorshift128plus(s1, s2)
    local x = s1
    local y = s2
    x = bit.bxor(x, bit.lshift(x, 23))
    x = bit.bxor(x, bit.rshift(x, 17))
    x = bit.bxor(x, y)
    x = bit.bxor(x, bit.rshift(y, 26))
    return x, y
end
for i = 1, global_anti_prediction.cache.entropy_pool_size do
    global_anti_prediction.cache.entropy_pool[i] = inject_true_entropy()
end
local function enhanced_random(min, max, stream_name)
    local entropy_streams = global_anti_prediction.entropy_streams
    local entropy_state = global_anti_prediction.entropy_state
    stream_name = stream_name or "yaw_left"
    local stream = entropy_streams[stream_name]
    if not stream then stream = entropy_streams.yaw_left end
    local true_entropy = inject_true_entropy()
    local tick_delta = globals.tickcount() - entropy_state.last_tick
    local time_delta = math.floor((globals.realtime() - entropy_state.last_realtime) * 1000000) % 2147483647
    stream.counter = (stream.counter + 1) % 1000000
    local mixed = bit.bxor(
        bit.bxor(stream.seed1, tick_delta * 69621),
        bit.bxor(stream.seed2, time_delta)
    )
    mixed = bit.bxor(mixed, stream.counter * 1103515245)
    mixed = bit.bxor(mixed, true_entropy)
    local new_s1, new_s2 = xorshift128plus(mixed, stream.seed3)
    stream.seed1 = (new_s1 + true_entropy) % 2147483647
    stream.seed2 = (stream.seed2 + new_s2 + true_entropy) % 2147483647
    stream.seed3 = (stream.seed3 + mixed) % 2147483647
    local range = max - min + 1
    local result = min + (math.abs(new_s1) % range)
    return result
end
local function init_yaw_offset_seeds()
    local yaw_offset_state = global_anti_prediction.yaw_offset_state
    local entropy_streams = global_anti_prediction.entropy_streams
    init_entropy()
    yaw_offset_state.lr_seed = entropy_streams.yaw_left.seed1
    yaw_offset_state.lr_variance_seed = entropy_streams.yaw_left.seed2
    yaw_offset_state.xway_seed = entropy_streams.xway.seed1
end
init_yaw_offset_seeds()
local function chaos_random(state_seed, min, max)
    local entropy_streams = global_anti_prediction.entropy_streams
    return enhanced_random(min, max, "timing"), entropy_streams.timing.seed1
end

local function calc_yaw_offset(vals)
    local yaw_offset_state = global_anti_prediction.yaw_offset_state
    local entropy_streams = global_anti_prediction.entropy_streams
    local desync_type = vals.desync_type
    local base_offset = vals.yaw_base_degrees or 0
    if type(desync_type) == "number" then
        local modes = {"Disabled", "L/R", "Multi-Way"}
        desync_type = modes[desync_type + 1] or "Disabled"
    end
    if desync_type == "Disabled" then
        return base_offset
    elseif desync_type == "L/R" then
        local left_limit = vals.desync_left_limit
        local right_limit = vals.desync_right_limit
        local base_delay = math.max(1, vals.timing_tick_delay)
        local randomization = vals.desync_randomization or 0
        
        local state = yaw_offset_state
        local current_side = state.lr_side
        
        if not state.desync_rand then
            state.desync_rand = {
                lorenz = {x = 0.1, y = 0.1, z = 0.1},
                rossler = {x = 0.1, y = 0.1, z = 0.1},
                henon = {x = 0.1, y = 0.1},
                logistic_x = 0.5,
                tent_x = 0.4,
                history = {},
                history_size = 16,
                pattern_detected = false,
                pattern_break_cooldown = 0,
                anti_resolver_mode = 0,
                burst_active = false,
                burst_cooldown = 0,
                burst_intensity = 0,
                osc_phase = 0,
                osc_frequency = 1.0,
                quantum_states = {},
                quantum_collapse_tick = 0,
                markov_state = 1,
                markov_history = {},
                adaptive_scale = 1.0,
                threat_level = 0,
                speed_mode = 1,
                speed_duration = 0,
                speed_momentum = 1.0,
                lfsr = 0xACE1,
                brownian_x = 0,
                brownian_v = 0,
                last_left = 0,
                last_right = 0,
                consecutive_similar = 0,
                freq_table = {2, 3, 5, 7, 11, 13, 17, 19},
                freq_index = 1,
                freq_counter = 0,
                weights = {0.5, 0.3, 0.2, 0.4, 0.6, 0.35, 0.45, 0.55},
                bias = 0,
                v13_hyper = {
                    x = 0.1, y = 0.1, z = 0.1, w = 0.1,
                    mode = 1, switch_cd = 0
                },
                v13_quantum = {
                    pairs = {}, history = {}, decoherence = 0, entangle_strength = 0.95
                },
                v13_lstm = {
                    hidden = 0, cell = 0, sequence = {},
                    wf = 0.8, wi = 0.8, wo = 0.8, wc = 0.8
                },
                v13_adv = {
                    weights = {}, momentum = {}, bias = 0,
                    lr = 0.08, prediction_error = 0
                },
                v13_fusion = {
                    scales = {0.5, 1.0, 2.0, 4.0},
                    scale_weights = {0.15, 0.35, 0.30, 0.20},
                    history = {}, adaptive_weights = {0.25, 0.25, 0.25, 0.25}
                },
                enemy_aim_tracking = {
                    detected = false, aim_time = 0, last_check = 0,
                    threat_multiplier = 1.0
                },
                hit_response = {
                    last_health = 100, damage_spike = 0, spike_decay = 0
                },
                fft_counter = {
                    samples = {}, freq_bins = {}, dominant_freq = 0
                },
                resolver_bait = {
                    active = false, bait_pattern = {}, bait_duration = 0,
                    real_pattern_hidden = true
                },
                v13_ensemble = {
                    layer_scores = {}, layer_outputs = {}, meta_weights = {}
                },
                anti_consecutive = {
                    streak = 0, last_values = {}, divergence_power = 1.0
                }
            }
        end
        
        local dr = state.desync_rand
        local v_left = left_limit
        local v_right = right_limit
        
        if randomization > 0 then
            dr.jitter_left = 0
            dr.jitter_right = 0
            dr.current_tick = globals.tickcount()
            
            local hyper = dr.v13_hyper
            local h_dt = 0.008
            local h_a, h_b, h_c, h_d = 36, 3, 20, -15.15
            local h_dx = h_a * (hyper.y - hyper.x) + hyper.w
            local h_dy = h_c * hyper.y - hyper.x * hyper.z
            local h_dz = hyper.x * hyper.y - h_b * hyper.z
            local h_dw = h_d * hyper.x + hyper.y * hyper.z
            hyper.x = math.max(-40, math.min(40, hyper.x + h_dx * h_dt))
            hyper.y = math.max(-40, math.min(40, hyper.y + h_dy * h_dt))
            hyper.z = math.max(0, math.min(60, hyper.z + h_dz * h_dt))
            hyper.w = math.max(-30, math.min(30, hyper.w + h_dw * h_dt))
            hyper.switch_cd = hyper.switch_cd - 1
            if hyper.switch_cd <= 0 then
                hyper.mode = (inject_true_entropy() % 4) + 1
                hyper.switch_cd = enhanced_random(12, 32, "timing")
            end
            local hyper_contrib = 0
            if hyper.mode == 1 then hyper_contrib = (hyper.x + hyper.y) * 0.015
            elseif hyper.mode == 2 then hyper_contrib = (hyper.z - hyper.w) * 0.012
            elseif hyper.mode == 3 then hyper_contrib = math.sin(hyper.x * 0.1) * hyper.w * 0.02
            else hyper_contrib = (hyper.x * hyper.y - hyper.z) * 0.008 end
            dr.C_HYPER = hyper_contrib * randomization
            
            if not dr.dual_attractor then
                dr.dual_attractor = {x1 = 0.1, y1 = 0.1, z1 = 0.1, x2 = -0.1, y2 = -0.1, z2 = -0.1, coupling = 0.3}
            end
            local da = dr.dual_attractor
            local dt_da = 0.01
            local dx1 = 10 * (da.y1 - da.x1) * dt_da + da.coupling * (da.x2 - da.x1)
            local dy1 = (da.x1 * (28 - da.z1) - da.y1) * dt_da
            local dz1 = (da.x1 * da.y1 - 2.667 * da.z1) * dt_da
            local dx2 = 10 * (da.y2 - da.x2) * dt_da + da.coupling * (da.x1 - da.x2)
            local dy2 = (da.x2 * (28 - da.z2) - da.y2) * dt_da
            local dz2 = (da.x2 * da.y2 - 2.667 * da.z2) * dt_da
            da.x1 = math.max(-50, math.min(50, da.x1 + dx1))
            da.y1 = math.max(-50, math.min(50, da.y1 + dy1))
            da.z1 = math.max(0, math.min(50, da.z1 + dz1))
            da.x2 = math.max(-50, math.min(50, da.x2 + dx2))
            da.y2 = math.max(-50, math.min(50, da.y2 + dy2))
            da.z2 = math.max(0, math.min(50, da.z2 + dz2))
            dr.C_DUAL = ((da.x1 - da.x2) + (da.y1 - da.y2)) * randomization * 0.025
            
            dr.dx = 10 * (dr.lorenz.y - dr.lorenz.x) * 0.01
            dr.dy = (dr.lorenz.x * (28 - dr.lorenz.z) - dr.lorenz.y) * 0.01
            dr.dz = (dr.lorenz.x * dr.lorenz.y - 2.667 * dr.lorenz.z) * 0.01
            dr.lorenz.x = math.max(-50, math.min(50, dr.lorenz.x + dr.dx))
            dr.lorenz.y = math.max(-50, math.min(50, dr.lorenz.y + dr.dy))
            dr.lorenz.z = math.max(0, math.min(50, dr.lorenz.z + dr.dz))
            dr.C1 = (dr.lorenz.x + dr.lorenz.y) * randomization * 0.02
            
            dr.rossler.x = math.max(-20, math.min(20, dr.rossler.x + (-dr.rossler.y - dr.rossler.z) * 0.05))
            dr.rossler.y = math.max(-20, math.min(20, dr.rossler.y + (dr.rossler.x + 0.2 * dr.rossler.y) * 0.05))
            dr.rossler.z = math.max(0, math.min(30, dr.rossler.z + (0.2 + dr.rossler.z * (dr.rossler.x - 5.7)) * 0.05))
            dr.C2 = dr.rossler.x * randomization * 0.03
            
            dr.hx_new = 1 - 1.4 * dr.henon.x * dr.henon.x + dr.henon.y
            dr.henon.y = 0.3 * dr.henon.x
            dr.henon.x = math.max(-1.5, math.min(1.5, dr.hx_new))
            dr.C3 = dr.henon.x * randomization * 0.4
            
            dr.logistic_x = math.max(0.001, math.min(0.999, 3.9 * dr.logistic_x * (1 - dr.logistic_x)))
            dr.C4 = (dr.logistic_x - 0.5) * randomization * 0.6
            dr.tent_x = dr.tent_x < 0.5 and 1.99 * dr.tent_x or 1.99 * (1 - dr.tent_x)
            dr.tent_x = math.max(0.001, math.min(0.999, dr.tent_x))
            dr.C5 = (dr.tent_x - 0.5) * randomization * 0.5
            
            local qe = dr.v13_quantum
            if #qe.pairs < 4 then
                for qi = 1, 4 do
                    qe.pairs[qi] = {
                        a = enhanced_random(-100, 100, "yaw_left") / 100,
                        b = enhanced_random(-100, 100, "yaw_right") / 100,
                        phase = enhanced_random(0, 360, "timing")
                    }
                end
            end
            qe.decoherence = qe.decoherence + 0.02
            if qe.decoherence > 1 or inject_true_entropy() % 100 < 5 then
                qe.decoherence = 0
                local reset_idx = (inject_true_entropy() % 4) + 1
                qe.pairs[reset_idx].a = enhanced_random(-100, 100, "yaw_left") / 100
                qe.pairs[reset_idx].b = -qe.pairs[reset_idx].a * qe.entangle_strength
                qe.pairs[reset_idx].phase = enhanced_random(0, 360, "timing")
            end
            dr.C_QUANTUM = 0
            for qi = 1, 4 do
                local pair = qe.pairs[qi]
                pair.phase = (pair.phase + 7.3) % 360
                local entangle_val = (pair.a * math.cos(math.rad(pair.phase)) + pair.b * math.sin(math.rad(pair.phase)))
                entangle_val = entangle_val * (1 - qe.decoherence * 0.3)
                dr.C_QUANTUM = dr.C_QUANTUM + entangle_val * 0.25
            end
            dr.C_QUANTUM = dr.C_QUANTUM * randomization * 0.35
            
            if not dr.freq_hopping then
                dr.freq_hopping = {phase = 0, freq_idx = 1, freqs = {0.5, 0.8, 1.2, 1.5, 2.0, 2.5, 3.0}, hop_cd = 0}
            end
            local fh = dr.freq_hopping
            fh.hop_cd = fh.hop_cd - 1
            if fh.hop_cd <= 0 then
                fh.freq_idx = (inject_true_entropy() % #fh.freqs) + 1
                fh.hop_cd = enhanced_random(3, 8, "timing")
            end
            fh.phase = (fh.phase + fh.freqs[fh.freq_idx] * 15) % 360
            dr.C_FREQ_HOP = math.sin(math.rad(fh.phase)) * randomization * 0.3
            
            if not dr.fractal_noise then
                dr.fractal_noise = {octaves = {0, 0, 0, 0}, persistence = 0.5, lacunarity = 2.0}
            end
            local fn = dr.fractal_noise
            local fractal_val = 0
            local amplitude = 1.0
            local frequency = 1.0
            for i = 1, 4 do
                fn.octaves[i] = (fn.octaves[i] + enhanced_random(-100, 100, "body_left") * 0.01 * frequency) % 1.0
                fractal_val = fractal_val + math.sin(fn.octaves[i] * math.pi * 2) * amplitude
                amplitude = amplitude * fn.persistence
                frequency = frequency * fn.lacunarity
            end
            dr.C_FRACTAL = fractal_val * randomization * 0.25
            
            dr.lfsr_bit = bit.band(dr.lfsr, 1)
            dr.lfsr = bit.rshift(dr.lfsr, 1)
            if dr.lfsr_bit == 1 then dr.lfsr = bit.bxor(dr.lfsr, 0xB400) end
            dr.C6 = ((dr.lfsr % 1000) / 1000 - 0.5) * randomization * 0.4
            
            local lstm = dr.v13_lstm
            table.insert(lstm.sequence, dr.C6)
            if #lstm.sequence > 16 then table.remove(lstm.sequence, 1) end
            if #lstm.sequence >= 4 then
                local input_val = lstm.sequence[#lstm.sequence]
                local forget_gate = 1 / (1 + math.exp(-(lstm.wf * input_val + lstm.hidden * 0.5)))
                local input_gate = 1 / (1 + math.exp(-(lstm.wi * input_val + lstm.hidden * 0.5)))
                local output_gate = 1 / (1 + math.exp(-(lstm.wo * input_val + lstm.hidden * 0.5)))
                local cell_candidate = math.tanh(lstm.wc * input_val + lstm.hidden * 0.3)
                lstm.cell = forget_gate * lstm.cell + input_gate * cell_candidate
                lstm.hidden = output_gate * math.tanh(lstm.cell)
                dr.C_LSTM = lstm.hidden * randomization * 0.4
                if #lstm.sequence >= 8 then
                    local pred_error = lstm.sequence[#lstm.sequence] - lstm.sequence[#lstm.sequence - 4]
                    lstm.wf = math.max(0.3, math.min(1.2, lstm.wf + pred_error * 0.01))
                    lstm.wi = math.max(0.3, math.min(1.2, lstm.wi - pred_error * 0.008))
                end
            else
                dr.C_LSTM = 0
            end
            
            dr.brownian_v = dr.brownian_v * 0.85 + enhanced_random(-100, 100, "yaw_left") / 100 * 0.3
            dr.brownian_x = math.max(-randomization, math.min(randomization, (dr.brownian_x + dr.brownian_v) * 0.95))
            dr.C7 = dr.brownian_x * 0.3
            
            if not dr.multiscale then
                dr.multiscale = {scales = {1, 2, 4, 8}, history = {}, max_len = 32}
            end
            local ms = dr.multiscale
            table.insert(ms.history, dr.C7)
            if #ms.history > ms.max_len then table.remove(ms.history, 1) end
            dr.C_MULTISCALE = 0
            if #ms.history >= 8 then
                for _, scale in ipairs(ms.scales) do
                    local idx = math.max(1, #ms.history - scale)
                    dr.C_MULTISCALE = dr.C_MULTISCALE + (ms.history[#ms.history] - ms.history[idx]) * (0.25 / scale)
                end
            end
            dr.C_MULTISCALE = dr.C_MULTISCALE * randomization * 0.2
            
            if not dr.nonlinear then
                dr.nonlinear = {tanh_scale = 1.5, sigmoid_scale = 2.0, relu_threshold = 0.3}
            end
            local nl = dr.nonlinear
            local nl_input = (dr.C1 + dr.C2 + dr.C3) / 3
            local tanh_out = math.tanh(nl_input * nl.tanh_scale)
            local sigmoid_out = 1 / (1 + math.exp(-nl_input * nl.sigmoid_scale))
            local relu_out = math.max(0, nl_input - nl.relu_threshold)
            dr.C_NONLINEAR = (tanh_out * 0.4 + sigmoid_out * 0.3 + relu_out * 0.3) * randomization * 0.3
            
            local adv = dr.v13_adv
            if #adv.weights < 8 then
                for ai = 1, 8 do
                    adv.weights[ai] = enhanced_random(-100, 100, "yaw_left") / 200
                    adv.momentum[ai] = 0
                end
            end
            local adv_input = {dr.C1, dr.C2, dr.C3, dr.C4, dr.C5, dr.C6, dr.C7, dr.C_HYPER}
            local adv_output = adv.bias
            for ai = 1, 8 do
                adv_output = adv_output + adv.weights[ai] * (adv_input[ai] or 0)
            end
            local target_unpredictability = enhanced_random(-randomization, randomization, "yaw_left")
            adv.prediction_error = target_unpredictability - adv_output
            for ai = 1, 8 do
                local grad = adv.prediction_error * (adv_input[ai] or 0) * 0.1
                adv.momentum[ai] = adv.momentum[ai] * 0.9 + grad * 0.1
                adv.weights[ai] = math.max(-1, math.min(1, adv.weights[ai] + adv.momentum[ai] * adv.lr))
            end
            adv.bias = adv.bias + adv.prediction_error * 0.02
            dr.C_ADV = adv_output * 0.5 + adv.prediction_error * 0.3
            
            if not dr.dynamic_weights then
                dr.dynamic_weights = {
                    weights = {0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1},
                    momentum = 0.9,
                    learning_rate = 0.05,
                    history = {}
                }
            end
            local dw = dr.dynamic_weights
            local components = {dr.C1, dr.C2, dr.C3, dr.C4, dr.C5, dr.C6, dr.C7, dr.C_HYPER, dr.C_QUANTUM, dr.C_DUAL}
            local weighted_sum = 0
            for i = 1, #components do
                weighted_sum = weighted_sum + components[i] * dw.weights[i]
            end
            table.insert(dw.history, weighted_sum)
            if #dw.history > 16 then table.remove(dw.history, 1) end
            if #dw.history >= 8 then
                local variance = 0
                local mean = 0
                for _, v in ipairs(dw.history) do mean = mean + v end
                mean = mean / #dw.history
                for _, v in ipairs(dw.history) do variance = variance + (v - mean) ^ 2 end
                variance = variance / #dw.history
                if variance < randomization * 0.1 then
                    for i = 1, #dw.weights do
                        local gradient = enhanced_random(-10, 10, "body_left") * 0.01
                        dw.weights[i] = dw.weights[i] * dw.momentum + gradient * dw.learning_rate
                        dw.weights[i] = math.max(0.05, math.min(0.3, dw.weights[i]))
                    end
                end
            end
            dr.C_DYNAMIC = weighted_sum * 0.4
            
            dr.osc_frequency = 0.8 + (inject_true_entropy() % 50) / 100
            dr.osc_phase = (dr.osc_phase + dr.osc_frequency * 15) % 360
            dr.C8 = math.sin(math.rad(dr.osc_phase)) * randomization * 0.25
            
            local fusion = dr.v13_fusion
            table.insert(fusion.history, dr.C8)
            if #fusion.history > 32 then table.remove(fusion.history, 1) end
            dr.C_FUSION = 0
            if #fusion.history >= 16 then
                for si, scale in ipairs(fusion.scales) do
                    local sample_idx = math.max(1, #fusion.history - math.floor(4 * scale))
                    local scale_val = fusion.history[sample_idx] or 0
                    dr.C_FUSION = dr.C_FUSION + scale_val * fusion.adaptive_weights[si]
                end
                local recent_var = 0
                for hi = math.max(1, #fusion.history - 8), #fusion.history do
                    recent_var = recent_var + math.abs(fusion.history[hi] - (fusion.history[hi-1] or 0))
                end
                recent_var = recent_var / 8
                if recent_var < randomization * 0.2 then
                    fusion.adaptive_weights[1] = math.min(0.4, fusion.adaptive_weights[1] + 0.02)
                    fusion.adaptive_weights[4] = math.max(0.1, fusion.adaptive_weights[4] - 0.02)
                else
                    for si = 1, 4 do
                        fusion.adaptive_weights[si] = fusion.adaptive_weights[si] * 0.95 + fusion.scale_weights[si] * 0.05
                    end
                end
            end
            
            if #dr.quantum_states < 8 then
                for qi = 1, 8 do dr.quantum_states[qi] = enhanced_random(-randomization * 2, randomization * 2, "yaw_left") end
            end
            dr.C9 = 0
            if dr.current_tick - dr.quantum_collapse_tick > enhanced_random(4, 12, "timing") then
                dr.quantum_collapse_tick = dr.current_tick
                dr.collapse_idx = (inject_true_entropy() % 8) + 1
                dr.C9 = dr.quantum_states[dr.collapse_idx] * 0.3
                dr.quantum_states[dr.collapse_idx] = enhanced_random(-randomization * 2, randomization * 2, "yaw_left")
            end
            
            dr.markov_rand = enhanced_random(1, 100, "timing") / 100
            dr.cumsum = 0
            dr.markov_trans = {{0.6, 0.25, 0.1, 0.05}, {0.15, 0.55, 0.2, 0.1}, {0.1, 0.2, 0.5, 0.2}, {0.15, 0.15, 0.2, 0.5}}
            for mi = 1, 4 do
                dr.cumsum = dr.cumsum + dr.markov_trans[dr.markov_state][mi]
                if dr.markov_rand <= dr.cumsum then dr.markov_state = mi break end
            end
            dr.markov_outputs = {enhanced_random(-randomization, 0, "yaw_left"), enhanced_random(0, randomization, "yaw_left"), enhanced_random(-randomization/2, randomization/2, "yaw_left"), enhanced_random(-randomization, randomization, "yaw_left") * 0.5}
            dr.C10 = dr.markov_outputs[dr.markov_state]
            
            if dr.speed_duration <= 0 then
                dr.mode_roll = inject_true_entropy() % 100
                if dr.mode_roll < 30 then dr.speed_mode, dr.speed_duration = 1, enhanced_random(8, 15, "timing")
                elseif dr.mode_roll < 70 then dr.speed_mode, dr.speed_duration = 2, enhanced_random(5, 12, "timing")
                else dr.speed_mode, dr.speed_duration = 3, enhanced_random(3, 8, "timing") end
            else dr.speed_duration = dr.speed_duration - 1 end
            dr.speed_momentum = dr.speed_momentum + (({0.5, 1.0, 2.0})[dr.speed_mode] - dr.speed_momentum) * 0.15
            
            dr.C11 = 0
            if dr.burst_cooldown > 0 then
                dr.burst_cooldown = dr.burst_cooldown - 1
                if dr.burst_active then dr.C11 = dr.burst_intensity * (dr.burst_cooldown / 8) end
            else
                dr.burst_active = false
                if enhanced_random(1, 100, "timing") > 90 then
                    dr.burst_active, dr.burst_cooldown = true, enhanced_random(4, 10, "timing")
                    dr.burst_intensity = enhanced_random(-randomization * 2, randomization * 2, "yaw_left")
                    dr.C11 = dr.burst_intensity
                end
            end
            
            dr.C12 = 0
            dr.freq_counter = dr.freq_counter + 1
            if dr.freq_counter >= dr.freq_table[dr.freq_index] then
                dr.freq_counter, dr.freq_index = 0, (dr.freq_index % #dr.freq_table) + 1
                dr.C12 = enhanced_random(-randomization, randomization, "yaw_left") * 0.5
            end
            
            dr.true_ent = inject_true_entropy()
            dr.C13 = ((dr.true_ent % (randomization * 2 + 1)) - randomization) * 0.3
            
            local bait = dr.resolver_bait
            dr.C_BAIT = 0
            if bait.bait_duration > 0 then
                bait.bait_duration = bait.bait_duration - 1
                if bait.active and #bait.bait_pattern > 0 then
                    local bait_idx = (dr.current_tick % #bait.bait_pattern) + 1
                    dr.C_BAIT = bait.bait_pattern[bait_idx] * 0.6
                end
            else
                bait.active = false
                if inject_true_entropy() % 100 < 8 then
                    bait.active = true
                    bait.bait_duration = enhanced_random(6, 14, "timing")
                    bait.bait_pattern = {}
                    local bait_type = inject_true_entropy() % 4
                    if bait_type == 0 then
                        local fake_val = enhanced_random(-randomization, randomization, "yaw_left")
                        for bi = 1, 8 do bait.bait_pattern[bi] = fake_val + enhanced_random(-2, 2, "yaw_left") end
                    elseif bait_type == 1 then
                        for bi = 1, 8 do bait.bait_pattern[bi] = (bi % 2 == 0) and randomization or -randomization end
                    elseif bait_type == 2 then
                        for bi = 1, 8 do bait.bait_pattern[bi] = -randomization + (bi - 1) * (randomization * 2 / 7) end
                    else
                        for bi = 1, 8 do bait.bait_pattern[bi] = math.sin(bi * 0.785) * randomization end
                    end
                end
            end
            
            local ensemble = dr.v13_ensemble
            ensemble.layer_outputs = {
                dr.C1, dr.C2, dr.C3, dr.C4, dr.C5, dr.C6, dr.C7, dr.C8, dr.C9, dr.C10, dr.C11, dr.C12, dr.C13,
                dr.C_HYPER, dr.C_QUANTUM, dr.C_LSTM, dr.C_ADV, dr.C_FUSION, dr.C_BAIT
            }
            if #ensemble.meta_weights < #ensemble.layer_outputs then
                for ei = 1, #ensemble.layer_outputs do
                    ensemble.meta_weights[ei] = 1.0 / #ensemble.layer_outputs
                    ensemble.layer_scores[ei] = 0.5
                end
            end
            if dr.pattern_detected then
                for ei = 1, #ensemble.layer_outputs do
                    if math.abs(ensemble.layer_outputs[ei]) > randomization * 0.5 then
                        ensemble.layer_scores[ei] = math.max(0.1, ensemble.layer_scores[ei] - 0.05)
                    end
                end
            else
                for ei = 1, #ensemble.layer_outputs do
                    ensemble.layer_scores[ei] = math.min(1.0, ensemble.layer_scores[ei] + 0.01)
                end
            end
            local score_sum = 0
            for ei = 1, #ensemble.layer_scores do score_sum = score_sum + ensemble.layer_scores[ei] end
            for ei = 1, #ensemble.meta_weights do
                ensemble.meta_weights[ei] = ensemble.layer_scores[ei] / score_sum
            end
            
            local anti_con = dr.anti_consecutive
            table.insert(anti_con.last_values, dr.jitter_left or 0)
            if #anti_con.last_values > 8 then table.remove(anti_con.last_values, 1) end
            if #anti_con.last_values >= 4 then
                local streak_detected = true
                for aci = 2, #anti_con.last_values do
                    if math.abs(anti_con.last_values[aci] - anti_con.last_values[aci-1]) > randomization * 0.3 then
                        streak_detected = false
                        break
                    end
                end
                if streak_detected then
                    anti_con.streak = anti_con.streak + 1
                    anti_con.divergence_power = math.min(3.0, anti_con.divergence_power + 0.2)
                else
                    anti_con.streak = 0
                    anti_con.divergence_power = math.max(1.0, anti_con.divergence_power - 0.1)
                end
            end
            
            dr.jitter_left = 0
            dr.jitter_left = dr.jitter_left + dr.C1 * dr.weights[1] * ensemble.meta_weights[1]
            dr.jitter_left = dr.jitter_left + dr.C2 * dr.weights[2] * ensemble.meta_weights[2]
            dr.jitter_left = dr.jitter_left + dr.C3 * dr.weights[3] * ensemble.meta_weights[3]
            dr.jitter_left = dr.jitter_left + dr.C4 * dr.weights[4] * ensemble.meta_weights[4]
            dr.jitter_left = dr.jitter_left + dr.C5 * dr.weights[5] * ensemble.meta_weights[5]
            dr.jitter_left = dr.jitter_left + dr.C6 * dr.weights[6] * ensemble.meta_weights[6]
            dr.jitter_left = dr.jitter_left + dr.C7 * dr.weights[7] * ensemble.meta_weights[7]
            dr.jitter_left = dr.jitter_left + dr.C8 * dr.weights[8] * ensemble.meta_weights[8]
            dr.jitter_left = dr.jitter_left + dr.C9 * 0.4 * ensemble.meta_weights[9]
            dr.jitter_left = dr.jitter_left + dr.C10 * 0.5 * ensemble.meta_weights[10]
            dr.jitter_left = dr.jitter_left + dr.C11 * 0.6 * ensemble.meta_weights[11]
            dr.jitter_left = dr.jitter_left + dr.C12 * 0.3 * ensemble.meta_weights[12]
            dr.jitter_left = dr.jitter_left + dr.C13 * 0.4 * ensemble.meta_weights[13]
            dr.jitter_left = dr.jitter_left + dr.C_HYPER * 0.45 * ensemble.meta_weights[14]
            dr.jitter_left = dr.jitter_left + dr.C_QUANTUM * 0.4 * ensemble.meta_weights[15]
            dr.jitter_left = dr.jitter_left + dr.C_LSTM * 0.35 * ensemble.meta_weights[16]
            dr.jitter_left = dr.jitter_left + dr.C_ADV * 0.5 * ensemble.meta_weights[17]
            dr.jitter_left = dr.jitter_left + dr.C_FUSION * 0.3 * ensemble.meta_weights[18]
            dr.jitter_left = dr.jitter_left + dr.C_BAIT * 0.25 * ensemble.meta_weights[19]
            
            if dr.C_DUAL then dr.jitter_left = dr.jitter_left + dr.C_DUAL * 0.35 end
            if dr.C_FREQ_HOP then dr.jitter_left = dr.jitter_left + dr.C_FREQ_HOP * 0.3 end
            if dr.C_FRACTAL then dr.jitter_left = dr.jitter_left + dr.C_FRACTAL * 0.25 end
            if dr.C_MULTISCALE then dr.jitter_left = dr.jitter_left + dr.C_MULTISCALE * 0.2 end
            if dr.C_NONLINEAR then dr.jitter_left = dr.jitter_left + dr.C_NONLINEAR * 0.3 end
            if dr.C_DYNAMIC then dr.jitter_left = dr.jitter_left + dr.C_DYNAMIC * 0.4 end
            
            dr.jitter_left = dr.jitter_left * dr.speed_momentum * anti_con.divergence_power
            local asymmetry_factor = 0.7 + (inject_true_entropy() % 60) / 100
            local right_chaos = enhanced_random(-randomization * 0.4, randomization * 0.4, "yaw_right")
            
            if not dr.asymmetry_enhancer then
                dr.asymmetry_enhancer = {phase = 0, intensity = 1.0, mode = 1}
            end
            local ae = dr.asymmetry_enhancer
            ae.phase = (ae.phase + 1) % 60
            if ae.phase == 0 then
                ae.mode = (inject_true_entropy() % 3) + 1
                ae.intensity = 0.6 + (inject_true_entropy() % 80) / 100
            end
            if ae.mode == 1 then
                asymmetry_factor = asymmetry_factor * ae.intensity
            elseif ae.mode == 2 then
                right_chaos = right_chaos * (1 + ae.intensity * 0.5)
            else
                asymmetry_factor = asymmetry_factor * (2 - ae.intensity)
            end
            
            dr.jitter_right = -dr.jitter_left * asymmetry_factor + right_chaos
            
            table.insert(dr.history, dr.jitter_left)
            if #dr.history > dr.history_size then table.remove(dr.history, 1) end
            dr.pattern_detected = false
            if #dr.history >= 6 then
                dr.pat_mean = 0
                for i = #dr.history - 5, #dr.history do dr.pat_mean = dr.pat_mean + dr.history[i] end
                dr.pat_mean = dr.pat_mean / 6
                dr.pat_var = 0
                for i = #dr.history - 5, #dr.history do dr.pat_var = dr.pat_var + (dr.history[i] - dr.pat_mean)^2 end
                local variance_pattern = dr.pat_var / 6 < randomization * 0.3
                
                local autocorr = 0
                if #dr.history >= 8 then
                    for lag = 2, 4 do
                        local corr = 0
                        for i = lag + 1, #dr.history do
                            corr = corr + dr.history[i] * dr.history[i - lag]
                        end
                        autocorr = math.max(autocorr, math.abs(corr / (#dr.history - lag)))
                    end
                end
                local periodic_pattern = autocorr > randomization * randomization * 0.5
                
                local trend_detected = false
                if #dr.history >= 6 then
                    local diffs = {}
                    for i = 2, 6 do
                        diffs[i-1] = dr.history[#dr.history - 6 + i] - dr.history[#dr.history - 7 + i]
                    end
                    local diff_var = 0
                    local diff_mean = 0
                    for _, d in ipairs(diffs) do diff_mean = diff_mean + d end
                    diff_mean = diff_mean / #diffs
                    for _, d in ipairs(diffs) do diff_var = diff_var + (d - diff_mean)^2 end
                    trend_detected = diff_var / #diffs < randomization * 0.1
                end
                
                dr.pattern_detected = variance_pattern or periodic_pattern or trend_detected
            end
            
            if dr.pattern_break_cooldown > 0 then 
                dr.pattern_break_cooldown = dr.pattern_break_cooldown - 1
            elseif dr.pattern_detected then
                dr.pattern_break_cooldown = enhanced_random(6, 14, "timing")
                dr.anti_resolver_mode = (dr.anti_resolver_mode + 1) % 10  
                dr.break_strength = randomization * 2
                
                if dr.anti_resolver_mode == 0 then
                    dr.jitter_left = dr.jitter_left + enhanced_random(-dr.break_strength, dr.break_strength, "yaw_left")
                elseif dr.anti_resolver_mode == 1 then
                    dr.jitter_left = -dr.jitter_left + enhanced_random(-dr.break_strength * 0.5, dr.break_strength * 0.5, "yaw_left")
                elseif dr.anti_resolver_mode == 2 then
                    dr.jitter_left = enhanced_random(-dr.break_strength, dr.break_strength, "yaw_left")
                elseif dr.anti_resolver_mode == 3 then
                    dr.jitter_left = dr.jitter_left * (enhanced_random(0, 1, "timing") == 0 and -1.5 or 1.5)
                elseif dr.anti_resolver_mode == 4 then
                    local collapse_val = dr.quantum_states[(inject_true_entropy() % 8) + 1] or 0
                    dr.jitter_left = collapse_val * 1.5
                elseif dr.anti_resolver_mode == 5 then
                    dr.jitter_left = dr.jitter_left + dr.C_HYPER * 3
                elseif dr.anti_resolver_mode == 6 then
                    dr.jitter_left = -dr.C_LSTM * 4 + enhanced_random(-dr.break_strength * 0.3, dr.break_strength * 0.3, "yaw_left")
                elseif dr.anti_resolver_mode == 7 then
                    dr.jitter_left = dr.C_ADV * 3 + enhanced_random(-dr.break_strength * 0.5, dr.break_strength * 0.5, "yaw_left")
                elseif dr.anti_resolver_mode == 8 then
                    dr.jitter_left = (dr.C_DUAL or 0) * 2.5 + (dr.C_FRACTAL or 0) * 2
                else
                    dr.jitter_left = enhanced_random(-randomization * 3, randomization * 3, "yaw_left")
                end
                
                local break_asymmetry = 0.5 + (inject_true_entropy() % 80) / 100
                dr.jitter_right = -dr.jitter_left * break_asymmetry + enhanced_random(-randomization * 0.5, randomization * 0.5, "yaw_right")
                
                dr.history = {}
                
                dr.v13_lstm.hidden = dr.v13_lstm.hidden * 0.3
                dr.v13_lstm.cell = dr.v13_lstm.cell * 0.3
            end
            
            local delta_left = math.abs(dr.jitter_left - dr.last_left)
            local delta_right = math.abs(dr.jitter_right - dr.last_right)
            if delta_left < 1.5 or delta_right < 1.5 then
                dr.consecutive_similar = dr.consecutive_similar + 1
                if dr.consecutive_similar >= 2 then
                    local diverge_mult = 1 + (dr.consecutive_similar - 2) * 0.3
                    dr.diverge = enhanced_random(-randomization * 1.5 * diverge_mult, randomization * 1.5 * diverge_mult, "yaw_left")
                    dr.jitter_left = dr.jitter_left + dr.diverge
                    dr.jitter_right = dr.jitter_right - dr.diverge * (0.6 + (inject_true_entropy() % 40) / 100)
                    if dr.consecutive_similar >= 4 then
                        dr.consecutive_similar = 0
                    end
                end
            else 
                dr.consecutive_similar = math.max(0, dr.consecutive_similar - 1) 
            end
            
            dr.last_left, dr.last_right = dr.jitter_left, dr.jitter_right
            dr.jitter_left = math.max(-randomization * 2.5, math.min(randomization * 2.5, dr.jitter_left))
            dr.jitter_right = math.max(-randomization * 2.5, math.min(randomization * 2.5, dr.jitter_right))
            
            state.jitter_offset_left = dr.jitter_left
            state.jitter_offset_right = dr.jitter_right
            
            v_left, v_right = left_limit + dr.jitter_left, right_limit + dr.jitter_right
        end
        
        if globals.chokedcommands() == 0 and state.lr_cycle >= state.lr_current_delay then
            current_side = current_side == 1 and 0 or 1
            local timing_variance = vals.timing_tick_variance or 0
            
            if timing_variance > 0 then
                    if not state.lr_chaos then
                        state.lr_chaos = {
                            smooth_factor = 0,
                            spike_cooldown = 0,
                            adaptive_velocity = 0,
                            lorenz_x = 0.1,
                            lorenz_y = 0.1,
                            lorenz_z = 0.1,
                            phase = 0,
                            burst_active = false,
                            burst_cooldown = 0,
                            pattern_history = {},
                            last_delay = 0
                        }
                    end
                    local chaos = state.lr_chaos
                    local chaos_entropy = inject_true_entropy() % 100
                    local variance_mult = 1.0
                    local extra_chaos = 0
                    
                    chaos.smooth_factor = chaos.smooth_factor + enhanced_random(-30, 30, "timing") / 100
                    chaos.smooth_factor = math.max(-1, math.min(1, chaos.smooth_factor))
                    local smooth_contrib = math.abs(chaos.smooth_factor) * 0.3
                    
                    if chaos.spike_cooldown > 0 then
                        chaos.spike_cooldown = chaos.spike_cooldown - 1
                    elseif chaos_entropy < 12 then
                        chaos.spike_cooldown = enhanced_random(8, 20, "timing")
                        extra_chaos = enhanced_random(timing_variance, timing_variance * 2, "timing")
                        if chaos_entropy < 6 then
                            variance_mult = 0.3  
                        end
                    end
                    
                    local me = entity.get_local_player()
                    if me then
                        local vx, vy = entity.get_prop(me, "m_vecVelocity")
                        if vx and vy then
                            local velocity = math.sqrt(vx * vx + vy * vy)
                            chaos.adaptive_velocity = chaos.adaptive_velocity * 0.9 + velocity * 0.1
                            if chaos.adaptive_velocity > 200 then
                                variance_mult = variance_mult * 0.7  
                            elseif chaos.adaptive_velocity < 10 then
                                variance_mult = variance_mult * 1.3  
                                if chaos_entropy < 15 then
                                    extra_chaos = extra_chaos + enhanced_random(0, timing_variance * 0.5, "timing")
                                end
                            end
                        end
                    end
                    
                    local sigma, rho, beta = 10, 28, 2.667
                    local dt = 0.02
                    local dx = sigma * (chaos.lorenz_y - chaos.lorenz_x) * dt
                    local dy = (chaos.lorenz_x * (rho - chaos.lorenz_z) - chaos.lorenz_y) * dt
                    local dz = (chaos.lorenz_x * chaos.lorenz_y - beta * chaos.lorenz_z) * dt
                    chaos.lorenz_x = math.max(-30, math.min(30, chaos.lorenz_x + dx))
                    chaos.lorenz_y = math.max(-30, math.min(30, chaos.lorenz_y + dy))
                    chaos.lorenz_z = math.max(0, math.min(50, chaos.lorenz_z + dz))
                    local lorenz_contrib = (chaos.lorenz_x + chaos.lorenz_y) * 0.02
                    
                    chaos.phase = (chaos.phase + enhanced_random(10, 30, "timing")) % 360
                    local phase_contrib = math.sin(math.rad(chaos.phase)) * 0.2
                    
                    if chaos.burst_cooldown > 0 then
                        chaos.burst_cooldown = chaos.burst_cooldown - 1
                        if chaos.burst_active then
                            extra_chaos = extra_chaos + enhanced_random(-timing_variance, timing_variance, "timing") * (chaos.burst_cooldown / 6)
                        end
                    elseif chaos_entropy > 92 then
                        chaos.burst_active = true
                        chaos.burst_cooldown = enhanced_random(4, 8, "timing")
                        extra_chaos = extra_chaos + enhanced_random(-timing_variance * 1.5, timing_variance * 1.5, "timing")
                    else
                        chaos.burst_active = false
                    end
                    
                    table.insert(chaos.pattern_history, state.lr_current_delay or base_delay)
                    if #chaos.pattern_history > 8 then table.remove(chaos.pattern_history, 1) end
                    if #chaos.pattern_history >= 4 then
                        local similar_count = 0
                        for i = #chaos.pattern_history, #chaos.pattern_history - 2, -1 do
                            if i > 1 and math.abs(chaos.pattern_history[i] - chaos.pattern_history[i-1]) < 1 then
                                similar_count = similar_count + 1
                            end
                        end
                        if similar_count >= 2 then
                            extra_chaos = extra_chaos + enhanced_random(-timing_variance * 2, timing_variance * 2, "timing")
                            chaos.pattern_history = {}
                        end
                    end
                    
                    local total_chaos_mult = 1.0 + smooth_contrib + lorenz_contrib + phase_contrib
                    total_chaos_mult = total_chaos_mult * variance_mult
                    total_chaos_mult = math.max(0.3, math.min(2.5, total_chaos_mult))
                    
                    local final_variance = timing_variance * total_chaos_mult
                    local random_offset = enhanced_random(-final_variance, final_variance, "timing") + extra_chaos
                    
                    local true_entropy_offset = (inject_true_entropy() % (math.floor(timing_variance * 2) + 1)) - timing_variance
                    random_offset = random_offset + true_entropy_offset * 0.3
                    
                    state.lr_current_delay = math.max(1, base_delay + random_offset)
                    chaos.last_delay = state.lr_current_delay
            else
                state.lr_current_delay = base_delay
            end
            state.lr_cycle = 1
        elseif globals.chokedcommands() == 0 then
            state.lr_cycle = state.lr_cycle + 1
        end
        
        state.lr_side = current_side
        local offset = current_side == 1 and v_left or v_right
        return base_offset + offset
    elseif desync_type == "Multi-Way" then
        local way_count = vals.desync_xway_count
        local steps = vals.desync_xway_steps
        local base_delay = vals.desync_xway_delay
        local variance = vals.desync_xway_variance
        local state = yaw_offset_state
        if globals.chokedcommands() == 0 and state.xway_cycle >= state.xway_current_delay then
            local timing_entropy = inject_true_entropy() % 100
            if timing_entropy < 10 then
                state.xway_cycle = state.xway_cycle - 1
                local step_offset = steps[state.xway_current_step] or 0
                return base_offset + step_offset
            elseif timing_entropy < 18 then
                state.xway_cycle = state.xway_current_delay
            elseif timing_entropy < 25 then
                state.xway_current_step = enhanced_random(1, way_count, "xway")
            end
            state.xway_current_step = (state.xway_current_step % way_count) + 1
            if variance > 0 then
                local var_offset = enhanced_random(-variance, variance, "xway")
                local true_entropy_offset = (inject_true_entropy() % (variance * 2)) - variance
                state.xway_current_delay = math.max(1, base_delay + var_offset + math.floor(true_entropy_offset * 0.3))
            else
                state.xway_current_delay = base_delay
            end
            state.xway_cycle = 1
        elseif globals.chokedcommands() == 0 then
            state.xway_cycle = state.xway_cycle + 1
        end
        local step_offset = steps[state.xway_current_step] or 0
        if inject_true_entropy() % 100 < 15 then
            local micro_adjust = (inject_true_entropy() % 10) - 5
            step_offset = step_offset + micro_adjust
        end
        return base_offset + step_offset
    end
    return base_offset
end
local function get_yaw_offset_values()
    local state = get_player_state(current_cmd)
    local vals = {}
    local state_config = menu.builder[state]
    if not state_config then
        state_config = menu.builder["Global"]
        state = "Global"
    end
    local is_enabled = true
    if state ~= "Global" and state_config.enable then
        is_enabled = state_config.enable:get()
        if not is_enabled then
            state_config = menu.builder["Global"]
            state = "Global"
        end
    end
    local base_yaw = state_config.yaw_base_degrees:get()
    local base_yaw_random = state_config.yaw_base_randomize:get()
    
    if base_yaw_random and base_yaw_random > 0 then
        local random_offset = enhanced_random(-base_yaw_random, base_yaw_random, "yaw_base")
        if inject_true_entropy() % 100 < 8 then
            random_offset = random_offset * (1.2 + (inject_true_entropy() % 50) / 100)
            random_offset = math.max(-base_yaw_random * 1.5, math.min(base_yaw_random * 1.5, random_offset))
        end
        base_yaw = base_yaw + random_offset
    end
    
    vals.yaw_base_degrees = base_yaw
        vals.desync_type = state_config.desync_type:get()
        vals.desync_left_limit = state_config.desync_left_limit:get()
        vals.desync_right_limit = state_config.desync_right_limit:get()
        vals.desync_randomization = state_config.desync_randomization:get()
        vals.timing_tick_delay = state_config.timing_tick_delay:get()
        vals.timing_tick_variance = state_config.timing_tick_variance:get()
        vals.desync_xway_count = state_config.desync_xway_count:get()
        vals.desync_xway_delay = state_config.desync_xway_delay:get()
        vals.desync_xway_variance = state_config.desync_xway_variance:get()
        vals.desync_xway_steps = {}
        for i = 1, 8 do
            vals.desync_xway_steps[i] = state_config.desync_xway_steps[i]:get()
        end
        vals.body_yaw_mode = state_config.body_yaw_mode:get()
        vals.body_yaw_degrees = state_config.body_yaw_degrees:get()
        vals.body_yaw_jitter_left = state_config.body_yaw_jitter_left:get()
        vals.body_yaw_jitter_right = state_config.body_yaw_jitter_right:get()
        vals.body_yaw_jitter_variance = state_config.body_yaw_jitter_variance:get()
        vals.body_yaw_variance_delay = state_config.body_yaw_variance_delay:get()
        vals.body_yaw_delay_variance = state_config.body_yaw_delay_variance:get()
    return vals
end
local function calc_body_yaw(vals, yaw_offset)
    local body_yaw_state = global_anti_prediction.body_yaw_state
    local yaw_offset_state = global_anti_prediction.yaw_offset_state
    local entropy_streams = global_anti_prediction.entropy_streams
    local body_yaw_mode = vals.body_yaw_mode
    if type(body_yaw_mode) == "number" then
        body_yaw_mode = ({"Disabled", "Static", "Jitter"})[body_yaw_mode + 1] or "Disabled"
    end
    if body_yaw_mode == "Disabled" then
        return 0
    elseif body_yaw_mode == "Static" then
        local static_offset = (vals.body_yaw_degrees or 0) * 2
        return static_offset
    elseif body_yaw_mode == "Jitter" then
        local state = body_yaw_state
        local offset_left = (vals.body_yaw_jitter_left or 30) * 2
        local offset_right = (vals.body_yaw_jitter_right or 30) * 2
        local jitter_variance = vals.body_yaw_jitter_variance or 0
        local base_delay = math.max(1, vals.body_yaw_variance_delay or 3)
        local delay_variance = vals.body_yaw_delay_variance or 0
        local MIN_BODY_YAW = 0
        local MAX_BODY_YAW = 120
        local MIN_DELAY = 1
        local MAX_DELAY = 20
        
        if jitter_variance == 0 then
            local desync_type = vals.desync_type
            if type(desync_type) == "number" then
                local modes = {"Disabled", "L/R", "Multi-Way"}
                desync_type = modes[desync_type + 1] or "Disabled"
            end
            
            if desync_type == "Multi-Way" then
                local current_step = yaw_offset_state.xway_current_step or 1
                local way_count = vals.desync_xway_count or 3
                local use_left = (current_step % 2) == 1
                return use_left and offset_left or -offset_right
            else
                local use_left = yaw_offset_state.lr_side == 1
                return use_left and offset_left or -offset_right
            end
        end
        
        local desync_type = vals.desync_type
        if type(desync_type) == "number" then
            local modes = {"Disabled", "L/R", "Multi-Way"}
            desync_type = modes[desync_type + 1] or "Disabled"
        end
        
        local current_side_for_body = 1
        if desync_type == "Multi-Way" then
            local current_step = yaw_offset_state.xway_current_step or 1
            current_side_for_body = (current_step % 2) == 1 and 1 or 0
        else
            current_side_for_body = yaw_offset_state.lr_side
        end
        
        if not state.by_v2 then
            state.by_v2 = {
                lorenz = {x = 0.1, y = 0.1, z = 0.1},
                rossler = {x = 0.1, y = 0.1, z = 0.1},
                duffing = {x = 0.1, v = 0},
                chua = {x = 0.1, y = 0.1, z = 0.1},
                henon = {x = 0.1, y = 0.1},
                logistic = {x = 0.5, r = 3.9},
                phase_osc = {p1 = 0, p2 = 0, p3 = 0},
                lfsr_state = 0xACE1,
                lfsr_poly = 0xB400,
                pattern_detector = {
                    history = {},
                    autocorr = 0,
                    entropy = 0,
                    last_break = 0,
                    consecutive_similar = 0,
                    variance_history = {}
                },
                multi_scale = {
                    fast = 0,
                    medium = 0,
                    slow = 0,
                    ultra_slow = 0
                },
                adaptive = {
                    scale = 1.0,
                    momentum = 0,
                    learning_rate = 0.08,
                    threat_multiplier = 1.0
                },
                quantum = {
                    state = 0,
                    phase = 0,
                    entangle = 0,
                    superposition = {0, 0, 0}
                },
                neural = {
                    weights = {0.5, 0.3, 0.2, 0.4, 0.6, 0.35, 0.45},
                    bias = 0,
                    learning_rate = 0.05
                },
                markov = {
                    state = 1,
                    transition = {{0.6, 0.25, 0.1, 0.05}, {0.15, 0.55, 0.2, 0.1}, {0.1, 0.2, 0.5, 0.2}, {0.15, 0.15, 0.2, 0.5}}
                },
                frequency_hopping = {
                    current_freq = 1,
                    freq_table = {0.5, 0.8, 1.2, 1.5, 2.0, 2.5, 3.0, 3.5},
                    hop_counter = 0
                },
                burst = {
                    active = false,
                    cooldown = 0,
                    intensity = 0,
                    duration = 0
                },
                enemy_tracking = {
                    last_angles = {},
                    aim_detected = false,
                    counter_mode = 0,
                    multi_threat = {},
                    threat_level = 0
                },
                last_left = 0,
                last_right = 0,
                micro_left = 0,
                micro_right = 0,
                divergence_power = 1.0,
                fractal = {
                    octaves = {0, 0, 0, 0},
                    persistence = 0.5,
                    lacunarity = 2.0
                },
                time_series = {
                    predictions = {},
                    actual = {},
                    error_threshold = 0
                },
                cross_coupling = {
                    lorenz_rossler = 0,
                    henon_logistic = 0,
                    coupling_strength = 0.15
                },
                memory_decay = {
                    long_term = {},
                    decay_rate = 0.02,
                    max_memory = 20
                },
                chaos_params = {
                    lorenz_sigma = 10,
                    rossler_a = 0.2,
                    adaptive_rate = 0.01
                }
            }
        end
        local v2 = state.by_v2
        
        if globals.chokedcommands() == 0 and state.jitter_cycle >= state.jitter_current_delay then
            local chaos_offset = 0
            if delay_variance > 0 then
                chaos_offset = enhanced_random(-delay_variance, delay_variance, "body_left")
            end
            state.jitter_current_delay = math.max(MIN_DELAY, math.min(MAX_DELAY, base_delay + chaos_offset))
            
            if jitter_variance > 0 then
                local dt = 0.012
                local sigma = v2.chaos_params.lorenz_sigma
                local dx = sigma * (v2.lorenz.y - v2.lorenz.x) * dt
                local dy = (v2.lorenz.x * (28 - v2.lorenz.z) - v2.lorenz.y) * dt
                local dz = (v2.lorenz.x * v2.lorenz.y - 2.667 * v2.lorenz.z) * dt
                v2.lorenz.x = math.max(-40, math.min(40, v2.lorenz.x + dx))
                v2.lorenz.y = math.max(-40, math.min(40, v2.lorenz.y + dy))
                v2.lorenz.z = math.max(0, math.min(50, v2.lorenz.z + dz))
                
                local dt_r = 0.04
                local a_r = v2.chaos_params.rossler_a
                v2.rossler.x = math.max(-25, math.min(25, v2.rossler.x + (-v2.rossler.y - v2.rossler.z) * dt_r))
                v2.rossler.y = math.max(-25, math.min(25, v2.rossler.y + (v2.rossler.x + a_r * v2.rossler.y) * dt_r))
                v2.rossler.z = math.max(0, math.min(35, v2.rossler.z + (0.2 + v2.rossler.z * (v2.rossler.x - 5.7)) * dt_r))
                
                local dt_d = 0.015
                local alpha, beta, delta, gamma = 1, -1, 0.3, 0.4
                local dv = v2.duffing.v + (gamma * math.cos(globals.curtime() * 1.2) - delta * v2.duffing.v - alpha * v2.duffing.x - beta * v2.duffing.x * v2.duffing.x * v2.duffing.x) * dt_d
                v2.duffing.v = math.max(-3, math.min(3, dv))
                v2.duffing.x = math.max(-2, math.min(2, v2.duffing.x + v2.duffing.v * dt_d))
                
                local dt_c = 0.01
                local a_c, b_c, c_c = 15.6, 28, -1.143
                local h_x = v2.chua.x < 0 and (b_c * v2.chua.x) or (c_c * v2.chua.x)
                v2.chua.x = math.max(-3, math.min(3, v2.chua.x + a_c * (v2.chua.y - v2.chua.x - h_x) * dt_c))
                v2.chua.y = math.max(-3, math.min(3, v2.chua.y + (v2.chua.x - v2.chua.y + v2.chua.z) * dt_c))
                v2.chua.z = math.max(-3, math.min(3, v2.chua.z + (-14.87 * v2.chua.y) * dt_c))
                
                local hx_new = 1 - 1.4 * v2.henon.x * v2.henon.x + v2.henon.y
                v2.henon.y = 0.3 * v2.henon.x
                v2.henon.x = math.max(-1.5, math.min(1.5, hx_new))
                
                v2.logistic.x = math.max(0.001, math.min(0.999, v2.logistic.r * v2.logistic.x * (1 - v2.logistic.x)))
                
                local cc = v2.cross_coupling
                cc.lorenz_rossler = v2.lorenz.x * 0.1 + v2.rossler.x * 0.1
                cc.henon_logistic = v2.henon.x * 0.15 + (v2.logistic.x - 0.5) * 0.2
                v2.lorenz.y = v2.lorenz.y + cc.lorenz_rossler * cc.coupling_strength
                v2.henon.y = v2.henon.y + cc.henon_logistic * cc.coupling_strength * 0.8
                
                v2.phase_osc.p1 = (v2.phase_osc.p1 + enhanced_random(10, 25, "body_left")) % 360
                v2.phase_osc.p2 = (v2.phase_osc.p2 + enhanced_random(15, 35, "body_right")) % 360
                v2.phase_osc.p3 = (v2.phase_osc.p3 + enhanced_random(5, 15, "timing")) % 360
                
                v2.lfsr_state = bit.bxor(v2.lfsr_state, bit.lshift(v2.lfsr_state, 13))
                v2.lfsr_state = bit.bxor(v2.lfsr_state, bit.rshift(v2.lfsr_state, 17))
                v2.lfsr_state = bit.bxor(v2.lfsr_state, bit.lshift(v2.lfsr_state, 5))
                local lfsr_bit = bit.band(v2.lfsr_state, 1)
                v2.lfsr_state = bit.rshift(v2.lfsr_state, 1)
                if lfsr_bit == 1 then 
                    v2.lfsr_state = bit.bxor(v2.lfsr_state, v2.lfsr_poly) 
                end
                local lfsr_val = ((v2.lfsr_state % 2000) - 1000) / 1000
                
                local C1 = (v2.lorenz.x + v2.lorenz.y) * 0.018
                local C2 = v2.rossler.x * 0.035
                local C3 = v2.duffing.x * 0.4
                local C4 = (v2.chua.x + v2.chua.y) * 0.3
                local C5 = math.sin(math.rad(v2.phase_osc.p1)) * 0.25
                local C6 = math.cos(math.rad(v2.phase_osc.p2)) * 0.2
                local C7 = math.sin(math.rad(v2.phase_osc.p3)) * math.cos(math.rad(v2.phase_osc.p1)) * 0.15
                local C8 = lfsr_val * 0.3
                
                local markov_rand = enhanced_random(1, 100, "timing") / 100
                local cumsum = 0
                for i = 1, 4 do
                    cumsum = cumsum + v2.markov.transition[v2.markov.state][i]
                    if markov_rand <= cumsum then
                        v2.markov.state = i
                        break
                    end
                end
                
                v2.frequency_hopping.hop_counter = v2.frequency_hopping.hop_counter + 1
                if v2.frequency_hopping.hop_counter >= enhanced_random(3, 8, "timing") then
                    v2.frequency_hopping.hop_counter = 0
                    v2.frequency_hopping.current_freq = (inject_true_entropy() % #v2.frequency_hopping.freq_table) + 1
                end
                local freq_phase = (globals.curtime() * v2.frequency_hopping.freq_table[v2.frequency_hopping.current_freq] * 15) % 360
                
                local me = entity.get_local_player()
                local threat = client.current_threat()
                if me and threat and not entity.is_dormant(threat) then
                    local enemy_pitch, enemy_yaw = entity.get_prop(threat, "m_angEyeAngles")
                    if enemy_pitch and enemy_yaw then
                        table.insert(v2.enemy_tracking.last_angles, {yaw = enemy_yaw, tick = globals.tickcount()})
                        if #v2.enemy_tracking.last_angles > 6 then
                            table.remove(v2.enemy_tracking.last_angles, 1)
                        end
                        
                        if #v2.enemy_tracking.last_angles >= 4 then
                            local aim_variance = 0
                            for i = 2, #v2.enemy_tracking.last_angles do
                                aim_variance = aim_variance + math.abs(v2.enemy_tracking.last_angles[i].yaw - v2.enemy_tracking.last_angles[i-1].yaw)
                            end
                            aim_variance = aim_variance / (#v2.enemy_tracking.last_angles - 1)
                            
                            v2.enemy_tracking.aim_detected = aim_variance < 5
                            if v2.enemy_tracking.aim_detected then
                                v2.adaptive.threat_multiplier = math.min(1.5, v2.adaptive.threat_multiplier + 0.1)
                                v2.enemy_tracking.counter_mode = (v2.enemy_tracking.counter_mode + 1) % 3
                            else
                                v2.adaptive.threat_multiplier = math.max(1.0, v2.adaptive.threat_multiplier - 0.05)
                            end
                        end
                    end
                end
                
                local C9 = v2.henon.x * 0.35
                local C10 = (v2.logistic.x - 0.5) * 0.5
                local C11 = math.sin(math.rad(freq_phase)) * 0.28
                
                local frac = v2.fractal
                frac.octaves[1] = math.sin(globals.curtime() * 2.1) * 0.5
                frac.octaves[2] = math.sin(globals.curtime() * 4.2 * frac.lacunarity) * 0.25
                frac.octaves[3] = math.sin(globals.curtime() * 8.4 * frac.lacunarity * frac.lacunarity) * 0.125
                frac.octaves[4] = math.sin(globals.curtime() * 16.8 * frac.lacunarity * frac.lacunarity * frac.lacunarity) * 0.0625
                local fractal_noise = 0
                for i = 1, 4 do
                    fractal_noise = fractal_noise + frac.octaves[i] * (frac.persistence ^ (i-1))
                end
                local C13 = fractal_noise * 0.4
                
                local C14 = cc.lorenz_rossler * 0.3
                local C15 = cc.henon_logistic * 0.35
                
                local markov_outputs = {
                    enhanced_random(-jitter_variance, 0, "body_left"),
                    enhanced_random(0, jitter_variance, "body_right"),
                    enhanced_random(-jitter_variance/2, jitter_variance/2, "body_left"),
                    enhanced_random(-jitter_variance, jitter_variance, "body_right") * 0.5
                }
                local C12 = markov_outputs[v2.markov.state]
                
                v2.multi_scale.fast = v2.multi_scale.fast * 0.3 + (C1 + C5) * 0.7
                v2.multi_scale.medium = v2.multi_scale.medium * 0.6 + (C2 + C3) * 0.4
                v2.multi_scale.slow = v2.multi_scale.slow * 0.85 + (C4 + C6) * 0.15
                v2.multi_scale.ultra_slow = v2.multi_scale.ultra_slow * 0.95 + (C7 + C8 + C12) * 0.05
                
                local neural_input = {C1, C2, C3, C4, C5, C6, C7, C13, C14, C15}
                if #v2.neural.weights < #neural_input then
                    for i = #v2.neural.weights + 1, #neural_input do
                        v2.neural.weights[i] = enhanced_random(-50, 50, "body_left") / 100
                    end
                end
                local neural_output = v2.neural.bias
                for i = 1, #neural_input do
                    neural_output = neural_output + v2.neural.weights[i] * neural_input[i]
                end
                neural_output = math.tanh(neural_output)
                
                local target_unpredictability = enhanced_random(-1, 1, "body_left")
                local prediction_error = target_unpredictability - neural_output
                for i = 1, #v2.neural.weights do
                    v2.neural.weights[i] = v2.neural.weights[i] + v2.neural.learning_rate * prediction_error * neural_input[i]
                    v2.neural.weights[i] = math.max(-1, math.min(1, v2.neural.weights[i]))
                end
                v2.neural.bias = v2.neural.bias + v2.neural.learning_rate * prediction_error * 0.1
                
                local base_left = enhanced_random(-jitter_variance, jitter_variance, "body_left")
                local base_right = enhanced_random(-jitter_variance, jitter_variance, "body_right")
                
                local ts = v2.time_series
                table.insert(ts.actual, base_left)
                if #ts.actual > 8 then table.remove(ts.actual, 1) end
                
                if #ts.actual >= 5 then
                    local predicted = 0
                    for i = 1, math.min(3, #ts.actual - 1) do
                        predicted = predicted + ts.actual[#ts.actual - i] * (0.4 / i)
                    end
                    table.insert(ts.predictions, predicted)
                    if #ts.predictions > 6 then table.remove(ts.predictions, 1) end
                    
                    if #ts.predictions >= 4 then
                        local pred_error = 0
                        for i = 1, #ts.predictions do
                            pred_error = pred_error + math.abs(ts.predictions[i] - (ts.actual[i] or 0))
                        end
                        pred_error = pred_error / #ts.predictions
                        
                        if pred_error < jitter_variance * 0.3 then
                            local anti_pred = enhanced_random(-jitter_variance * 1.5, jitter_variance * 1.5, "body_left")
                            base_left = base_left * 0.3 + anti_pred * 0.7
                            base_right = base_right * 0.3 - anti_pred * 0.6
                            ts.predictions = {}
                        end
                    end
                end
                
                local md = v2.memory_decay
                table.insert(md.long_term, {left = base_left, right = base_right, tick = globals.tickcount()})
                if #md.long_term > md.max_memory then table.remove(md.long_term, 1) end
                
                if #md.long_term >= 10 then
                    local pattern_strength = 0
                    for i = 2, #md.long_term do
                        pattern_strength = pattern_strength + math.abs(md.long_term[i].left - md.long_term[i-1].left)
                    end
                    pattern_strength = pattern_strength / (#md.long_term - 1)
                    
                    if pattern_strength < jitter_variance * 0.25 then
                        for i = 1, #md.long_term do
                            md.long_term[i].left = md.long_term[i].left * (1 - md.decay_rate * i)
                            md.long_term[i].right = md.long_term[i].right * (1 - md.decay_rate * i)
                        end
                        base_left = base_left + enhanced_random(-jitter_variance, jitter_variance, "body_left") * 0.5
                        base_right = base_right + enhanced_random(-jitter_variance, jitter_variance, "body_right") * 0.5
                    end
                end
                
                local pd = v2.pattern_detector
                table.insert(pd.history, base_left)
                if #pd.history > 12 then table.remove(pd.history, 1) end
                
                if #pd.history >= 6 then
                    local mean = 0
                    for _, v in ipairs(pd.history) do mean = mean + v end
                    mean = mean / #pd.history
                    
                    local variance = 0
                    for _, v in ipairs(pd.history) do variance = variance + (v - mean) ^ 2 end
                    variance = variance / #pd.history
                    
                    pd.entropy = variance / (jitter_variance * jitter_variance + 0.01)
                    
                    local autocorr = 0
                    for i = 2, #pd.history do
                        autocorr = autocorr + pd.history[i] * pd.history[i-1]
                    end
                    pd.autocorr = math.abs(autocorr / (#pd.history - 1))
                    
                    table.insert(pd.variance_history, variance)
                    if #pd.variance_history > 5 then table.remove(pd.variance_history, 1) end
                    
                    local variance_stable = true
                    if #pd.variance_history >= 3 then
                        for i = 2, #pd.variance_history do
                            if math.abs(pd.variance_history[i] - pd.variance_history[i-1]) > jitter_variance * 0.2 then
                                variance_stable = false
                                break
                            end
                        end
                    end
                    
                    local pattern_detected = (pd.entropy < 0.3) or (pd.autocorr > jitter_variance * jitter_variance * 0.6) or variance_stable
                    
                    if pattern_detected and (globals.tickcount() - pd.last_break) > 5 then
                        pd.last_break = globals.tickcount()
                        v2.adaptive.scale = math.min(3.0, v2.adaptive.scale + 0.35)
                        v2.divergence_power = math.min(4.0, v2.divergence_power + 0.3)
                        
                        local break_mode = inject_true_entropy() % 10
                        if break_mode == 0 then
                            base_left = enhanced_random(-jitter_variance * 2.8, jitter_variance * 2.8, "body_left")
                            base_right = -base_left * (0.5 + (inject_true_entropy() % 90) / 100)
                        elseif break_mode == 1 then
                            base_left = v2.duffing.x * jitter_variance * 2.5
                            base_right = v2.chua.y * jitter_variance * 2.3
                        elseif break_mode == 2 then
                            base_left = (C1 + C3 + C5 + C9 + C13) * jitter_variance * 2.0
                            base_right = (C2 + C4 + C6 + C10 + C14) * jitter_variance * 2.0
                        elseif break_mode == 3 then
                            v2.lorenz.x = enhanced_random(-30, 30, "body_left") / 10
                            v2.rossler.x = enhanced_random(-25, 25, "body_right") / 10
                            v2.henon.x = enhanced_random(-120, 120, "body_left") / 100
                        elseif break_mode == 4 then
                            base_left = lfsr_val * jitter_variance * 2.6
                            base_right = -lfsr_val * jitter_variance * 2.3
                        elseif break_mode == 5 then
                            base_left = neural_output * jitter_variance * 2.8
                            base_right = -neural_output * jitter_variance * 2.5
                        elseif break_mode == 6 then
                            base_left = C12 * 2.3
                            base_right = -C12 * 2.0
                        elseif break_mode == 7 then
                            base_left = (v2.multi_scale.fast + v2.multi_scale.medium) * jitter_variance * 2.2
                            base_right = (v2.multi_scale.slow + v2.multi_scale.ultra_slow) * jitter_variance * 2.2
                        elseif break_mode == 8 then
                            base_left = fractal_noise * jitter_variance * 2.5
                            base_right = -fractal_noise * jitter_variance * 2.2
                        else
                            base_left = (C14 + C15) * jitter_variance * 2.4
                            base_right = -(C14 + C15) * jitter_variance * 2.1
                        end
                        
                        pd.history = {}
                        pd.variance_history = {}
                        ts.predictions = {}
                        md.long_term = {}
                    else
                        v2.adaptive.scale = math.max(1.0, v2.adaptive.scale - 0.03)
                    end
                end
                
                if v2.burst.cooldown > 0 then
                    v2.burst.cooldown = v2.burst.cooldown - 1
                    if v2.burst.active and v2.burst.duration > 0 then
                        v2.burst.duration = v2.burst.duration - 1
                        local burst_mult = v2.burst.duration / 8
                        base_left = base_left + v2.burst.intensity * burst_mult
                        base_right = base_right - v2.burst.intensity * burst_mult * 0.9
                    else
                        v2.burst.active = false
                    end
                else
                    if inject_true_entropy() % 100 < 15 then
                        v2.burst.active = true
                        v2.burst.cooldown = enhanced_random(6, 12, "timing")
                        v2.burst.duration = enhanced_random(3, 7, "timing")
                        v2.burst.intensity = enhanced_random(-jitter_variance * 1.5, jitter_variance * 1.5, "body_left")
                    end
                end
                
                v2.quantum.phase = (v2.quantum.phase + 1) % 32
                if v2.quantum.phase == 0 then
                    v2.quantum.state = enhanced_random(-100, 100, "body_left") / 100
                    v2.quantum.entangle = enhanced_random(-100, 100, "body_right") / 100
                    for i = 1, 3 do
                        v2.quantum.superposition[i] = enhanced_random(-100, 100, "timing") / 100
                    end
                end
                local quantum_contrib = v2.quantum.state * math.cos(v2.quantum.phase * 0.196) * 0.3
                quantum_contrib = quantum_contrib + v2.quantum.entangle * math.sin(v2.quantum.phase * 0.196) * 0.25
                for i = 1, 3 do
                    quantum_contrib = quantum_contrib + v2.quantum.superposition[i] * math.sin((v2.quantum.phase + i * 10) * 0.196) * 0.1
                end
                
                v2.micro_left = v2.micro_left * 0.6 + enhanced_random(-3, 3, "body_left") * 0.4
                v2.micro_right = v2.micro_right * 0.6 + enhanced_random(-3, 3, "body_right") * 0.4
                
                local total_left = base_left * v2.adaptive.scale * v2.adaptive.threat_multiplier
                total_left = total_left + C1 * jitter_variance + C3 * jitter_variance + C5 * jitter_variance
                total_left = total_left + C9 * jitter_variance + C11 * jitter_variance + C13 * jitter_variance
                total_left = total_left + C14 * jitter_variance * 0.6 + C15 * jitter_variance * 0.5
                total_left = total_left + v2.multi_scale.fast * jitter_variance * 0.5
                total_left = total_left + v2.multi_scale.medium * jitter_variance * 0.3
                total_left = total_left + v2.multi_scale.ultra_slow * jitter_variance * 0.2
                total_left = total_left + quantum_contrib * jitter_variance
                total_left = total_left + neural_output * jitter_variance * 0.45
                total_left = total_left + v2.micro_left
                
                local total_right = base_right * v2.adaptive.scale * v2.adaptive.threat_multiplier
                total_right = total_right + C2 * jitter_variance + C4 * jitter_variance + C6 * jitter_variance
                total_right = total_right + C10 * jitter_variance + C12 * jitter_variance * 0.5
                total_right = total_right - C13 * jitter_variance * 0.8
                total_right = total_right - C14 * jitter_variance * 0.5 + C15 * jitter_variance * 0.4
                total_right = total_right - v2.multi_scale.fast * jitter_variance * 0.4
                total_right = total_right + v2.multi_scale.slow * jitter_variance * 0.5
                total_right = total_right + v2.multi_scale.ultra_slow * jitter_variance * 0.3
                total_right = total_right - quantum_contrib * jitter_variance * 0.8
                total_right = total_right - neural_output * jitter_variance * 0.4
                total_right = total_right + v2.micro_right
                
                if v2.enemy_tracking.aim_detected then
                    if v2.enemy_tracking.counter_mode == 0 then
                        total_left = total_left * 1.35
                        total_right = total_right * 1.35
                    elseif v2.enemy_tracking.counter_mode == 1 then
                        total_left = -total_left * 1.25
                        total_right = -total_right * 1.25
                    elseif v2.enemy_tracking.counter_mode == 2 then
                        local swap = total_left
                        total_left = total_right * 1.2
                        total_right = swap * 1.2
                    else
                        total_left = total_left + fractal_noise * jitter_variance * 1.5
                        total_right = total_right - fractal_noise * jitter_variance * 1.3
                    end
                    
                    if v2.enemy_tracking.threat_level >= 2 then
                        total_left = total_left * 1.2
                        total_right = total_right * 1.2
                    end
                end
                
                local asymmetry = 0.8 + (inject_true_entropy() % 40) / 100
                total_right = total_right * asymmetry
                
                local delta_left = math.abs(total_left - v2.last_left)
                local delta_right = math.abs(total_right - v2.last_right)
                if delta_left < jitter_variance * 0.08 and delta_right < jitter_variance * 0.08 then
                    pd.consecutive_similar = pd.consecutive_similar + 1
                    if pd.consecutive_similar >= 2 then
                        local diverge = enhanced_random(-jitter_variance, jitter_variance, "body_left") * v2.divergence_power
                        total_left = total_left + diverge
                        total_right = total_right - diverge * 0.85
                        pd.consecutive_similar = 0
                    end
                else
                    pd.consecutive_similar = 0
                end
                
                state.jitter_offset_left = math.max(-jitter_variance * 2.8, math.min(jitter_variance * 2.8, total_left))
                state.jitter_offset_right = math.max(-jitter_variance * 2.8, math.min(jitter_variance * 2.8, total_right))
                
                v2.last_left = state.jitter_offset_left
                v2.last_right = state.jitter_offset_right
            else
                state.jitter_offset_left = 0
                state.jitter_offset_right = 0
            end
            
            state.jitter_cycle = 0
        end
        if globals.chokedcommands() == 0 then
            state.jitter_cycle = (state.jitter_cycle or 0) + 1
        end
        
        local use_left_for_body = current_side_for_body == 1
        state.by_final_left = offset_left + (state.jitter_offset_left or 0)
        state.by_final_right = offset_right + (state.jitter_offset_right or 0)
        offset_left = math.max(MIN_BODY_YAW, math.min(MAX_BODY_YAW, state.by_final_left))
        offset_right = math.max(MIN_BODY_YAW, math.min(MAX_BODY_YAW, state.by_final_right))
        
        return use_left_for_body and offset_left or -offset_right
    end
    return 0
end
local normalize_yaw = utils.normalize_angle  
local movement = {
    globals = {
        nade = 0,
        in_ladder = 0
    }
}
local movement_side = false
local allow_send_packet = true
local function get_move_yaw(base_type)
    local me = entity.get_local_player()
    if not me then return 0 end
    local pitch, yaw = client.camera_angles()
    if base_type == "Local view" or base_type == nil then
        return yaw
    elseif base_type == "At targets" then
        local target = client.current_threat()
        if target then
            local ex, ey, ez = entity.hitbox_position(target, 0)
            if ex then
                local mx, my, mz = client.eye_position()
                if mx then
                    local dx, dy = ex - mx, ey - my
                    return math.deg(math.atan2(dy, dx))
                end
            end
        end
        return yaw
    end
    return yaw
end
local function apply_movement(cmd, is_send)
    local me = entity.get_local_player()
    if not me then return end
    local move_amount = 1.01
    local vx, vy, vz = entity.get_prop(me, "m_vecVelocity")
    if vx and math.sqrt(vx*vx + vy*vy) > 3 then
        return
    end
    local flags = entity.get_prop(me, "m_fFlags")
    if bit.band(flags, 4) == 4 then
        move_amount = move_amount * 2.94117647
    end
    if movement_side then
        cmd.sidemove = cmd.sidemove + move_amount
    else
        cmd.sidemove = cmd.sidemove - move_amount
    end
    movement_side = not movement_side
end
local function should_run_movement(cmd)
    local me = entity.get_local_player()
    if not me then return false end
    if cmd.in_use == 1 then
        return false
    end
    local weapon = entity.get_player_weapon(me)
    if not weapon then return false end
    if cmd.in_attack == 1 then
        local classname = entity.get_classname(weapon)
        if classname and (classname:find("Grenade") or classname:find("Flashbang")) then
            movement.globals.nade = globals.tickcount()
        elseif math.max(entity.get_prop(weapon, "m_flNextPrimaryAttack") or 0, entity.get_prop(me, "m_flNextAttack") or 0) - globals.tickinterval() - globals.curtime() < 0 then
            return false
        end
    end
    local throw_time = entity.get_prop(weapon, "m_fThrowTime")
    if movement.globals.nade + 15 == globals.tickcount() or (throw_time and throw_time ~= 0) then
        return false
    end
    local game_rules = entity.get_game_rules()
    if game_rules and entity.get_prop(game_rules, "m_bFreezePeriod") == 1 then
        return false
    end
    local movetype = entity.get_prop(me, "m_MoveType")
    if movetype == 9 or movement.globals.in_ladder > globals.tickcount() then
        return false
    end
    if movetype == 10 then
        return false
    end
    return true
end
local function is_grounded()
    if not native or not native.animstate or not native.animstate.get then
        return true
    end
    local lp = entity.get_local_player()
    if not lp then return true end
    local anim_state = native.animstate:get(lp)
    if not anim_state then
        return true
    end
    local anim_state_ptr = ffi.cast("uintptr_t", ffi.cast("void*", anim_state))
    local hit_in_ground_anim = ffi.cast("bool*", anim_state_ptr + 288)[0]
    return anim_state.on_ground and not hit_in_ground_anim
end
local function anim_breaker()
    local player_state = global_anti_prediction.player_state
    local lp = entity.get_local_player()
    if not lp then return end
    if not entity.is_alive(lp) then return end
    local self_index = entity_lib.new(lp)
    local leg_movement_ref = ui.reference("AA", "Other", "Leg movement")
    local ANIMATION_LAYER_MOVEMENT_MOVE = 6
    local ANIMATION_LAYER_LEAN = 12
    local MOVETYPE_WALK = 2
    local movetype = entity.get_prop(lp, "m_movetype")
    if movetype == MOVETYPE_WALK then
        if menu.misc.animation_ground and player_state.on_ground then
            local ground_mode = get_menu_value(menu.misc.animation_ground)
            if ground_mode == "Static" then
                ui.set(leg_movement_ref, "Always slide")
                entity.set_prop(lp, "m_flPoseParameter", 0, 0)
            elseif ground_mode == "Jitter" then
                ui.set(leg_movement_ref, "Always slide")
                entity.set_prop(lp, "m_flPoseParameter", globals.tickcount() % 4 > 1 and 9/10 or 1, 0)
            elseif ground_mode == "Moonwalk" then
                ui.set(leg_movement_ref, "Never slide")
                entity.set_prop(lp, 'm_flPoseParameter', 0, 7)
            end
        end
        if menu.misc.animation_air and not player_state.on_ground then
            local air_mode = get_menu_value(menu.misc.animation_air)
            if air_mode == "Static" then
                entity.set_prop(lp, "m_flPoseParameter", 1, 6)
            elseif air_mode == "Jitter" then
                entity.set_prop(lp, "m_flPoseParameter", globals.tickcount() % 4 > 1 and 9/10 or 0, 6)
            elseif air_mode == "Moonwalk" then
                local self_anim_overlay = self_index:get_anim_overlay(6)
                local x_velocity = entity.get_prop(lp, 'm_vecVelocity[0]')
                if math.abs(x_velocity) >= 3 then
                    self_anim_overlay.weight = 1
                end
            end
        end
        if not get_menu_value(menu.misc.pitch_on_land) or not player_state.on_ground then
        else
            if not native or not native.animstate or not native.animstate.get then
            else
                local animstate = native.animstate.get(native.user_input.vtbl, lp)
                if animstate == nil or not animstate.hit_in_ground_animation then
                else
                    entity.set_prop(lp, 'm_flPoseParameter', 0.5, 12)
                end
            end
        end
    end
    if menu.misc.body_lean then
        local lean_value = get_menu_value(menu.misc.body_lean)
        if lean_value > 0 then
            local layer_lean = self_index:get_anim_overlay(ANIMATION_LAYER_LEAN)
            if layer_lean then
                local x_velocity = entity.get_prop(lp, "m_vecVelocity[0]")
                if x_velocity and math.abs(x_velocity) >= 3 then
                    layer_lean.weight = lean_value * 2
                end
            end
        end
    end
    if menu.misc.earthquake and get_menu_value(menu.misc.earthquake) then
        local layer_lean = self_index:get_anim_overlay(ANIMATION_LAYER_LEAN)
        if layer_lean then
            local intensity = get_menu_value(menu.misc.earthquake_intensity) / 100
            local target_weight = client.random_float(0, 1)
            layer_lean.weight = layer_lean.weight + (target_weight - layer_lean.weight) * intensity
        end
    end
end
client.set_event_callback('pre_render', function()
    if get_menu_value(menu.misc.animation_breaker) then
        anim_breaker()
    end
end)
local function unsafe_charge_main(cmd)
    local player_state = global_anti_prediction.player_state
    if not get_menu_value(menu.ragebot.unsafe_charge) then
        rage_refs.rage_enabled:set(true)
        return
    end
    local me = entity.get_local_player()
    if not me then
        rage_refs.rage_enabled:set(true)
        return
    end
    local doubletap_active = ui.get(rage_refs.double_tap[2]) and not rage_refs.duck_peek_assist:get()
    if not doubletap_active then
        rage_refs.rage_enabled:set(true)
        return
    end
    local threat = client.current_threat()
    local should_disable_rage = false
    if threat then
        local esp_data = entity.get_esp_data(threat)
        if esp_data then
            local esp_flags = esp_data.flags
            if not player_state.shift and not player_state.on_ground and (bit.band(esp_flags, 2048) == 2048) then
                should_disable_rage = true
            end
        end
    end
    if should_disable_rage then
        rage_refs.rage_enabled:set(false)
    else
        rage_refs.rage_enabled:set(true)
    end
end
client.set_event_callback('setup_command', function(cmd)
    local player_state = global_anti_prediction.player_state
    local me = entity.get_local_player()
    if not me or not entity.is_alive(me) then return end
    local slowmotion_limit = ui.get(slowmotion_limit_ref)
    if slowmotion_limit < 57 then
        local slowmotion_checkbox = ui.get(slowmotion_checkbox_ref)
        local slowmotion_hotkey = ui.get(slowmotion_hotkey_ref)
        if slowmotion_checkbox and slowmotion_hotkey then
            modify_velocity(cmd, slowmotion_limit)
        end
    end
    current_cmd = cmd
    air_stop.process(cmd)
    peekbot.run(cmd)
    on_use.handle(cmd)
    on_use.ladder(cmd)
    update_manual_aa()
    unsafe_charge_main(cmd)
    local flags = entity.get_prop(me, "m_fFlags")
    local vx, vy, vz = entity.get_prop(me, "m_vecVelocity")
    player_state.velocity = vx and math.sqrt(vx*vx + vy*vy) or 0
    local current_state = get_player_state(cmd)
    local is_freestanding = false
    if menu.antiaim.freestanding and menu.antiaim.freestanding:get() then
        is_freestanding = true
        if manual_dir ~= 0 then
            is_freestanding = false
        end
    end
    local is_edge_yaw = false
    if menu.antiaim.edge_yaw and menu.antiaim.edge_yaw:get() then
        is_edge_yaw = true
    end
    
    if aa_ref.freestanding and aa_ref.freestanding[1] then
        ui.set(aa_ref.freestanding[1], is_freestanding)
        if is_freestanding then
            ui.set(aa_ref.freestanding[2], "Always on")
        end
    end
    if aa_ref.edge_yaw then
        ui.set(aa_ref.edge_yaw, is_edge_yaw)
    end
    if current_state == "Safe" then
        if menu.antiaim.utilities:get("Auto Duck in Air") then
            cmd.in_duck = 1
        end
    end
    local is_fakeducking = false
    if aa_ref.fakeduck then
        is_fakeducking = ui.get(aa_ref.fakeduck)
    end
    if is_fakeducking and menu.antiaim.utilities:get("Fakeduck Edge") then
        is_edge_yaw = true
        if aa_ref.edge_yaw then
            ui.set(aa_ref.edge_yaw, true)
        end
    end
    local vals = get_yaw_offset_values()
    local yaw_offset = calc_yaw_offset(vals)
    if manual_dir ~= 0 then
        yaw_offset = manual_dir
    end
    if menu.antiaim.utilities:get("Avoid Backstab") then
        local local_x, local_y, local_z = entity.get_origin(me)
        if local_x then
            local enemies = entity.get_players(true)
            local closest_knife_enemy = nil
            local closest_distance = 500
            local closest_dx, closest_dy = 0, 0
            for i = 1, #enemies do
                local enemy = enemies[i]
                if enemy and entity.is_alive(enemy) and not entity.is_dormant(enemy) then
                    local enemy_x, enemy_y, enemy_z = entity.get_origin(enemy)
                    if enemy_x then
                        local dx = enemy_x - local_x
                        local dy = enemy_y - local_y
                        local distance = math.sqrt(dx * dx + dy * dy)
                        local weapon = entity.get_player_weapon(enemy)
                        if weapon and distance < closest_distance then
                            local weapon_name = entity.get_classname(weapon)
                            if weapon_name == "CKnife" then
                                closest_knife_enemy = enemy
                                closest_distance = distance
                                closest_dx = dx
                                closest_dy = dy
                            end
                        end
                    end
                end
            end
            if closest_knife_enemy then
                local angle_to_enemy = math.deg(math.atan2(closest_dy, closest_dx))
                local _, current_yaw = client.camera_angles()
                local needed_offset = angle_to_enemy - current_yaw - 180
                while needed_offset > 180 do needed_offset = needed_offset - 360 end
                while needed_offset < -180 do needed_offset = needed_offset + 360 end
                yaw_offset = needed_offset
            end
        end
    end
    
    local body_yaw_offset = calc_body_yaw(vals, yaw_offset)
    
    if is_freestanding then
        
        if aa_ref.pitch and aa_ref.pitch[1] then
            if on_use.enabled then
                ui.set(aa_ref.pitch[1], "Custom")
                if aa_ref.pitch[2] then
                    ui.set(aa_ref.pitch[2], 0)
                end
            else
                ui.set(aa_ref.pitch[1], "Down")
            end
        end
        
        if aa_ref.yaw_base then
            ui.set(aa_ref.yaw_base, "At targets")
        end
        
        if aa_ref.yaw[1] and aa_ref.yaw[2] then
            ui.set(aa_ref.yaw[1], "180")
            local yaw_base_offset = on_use.enabled and 180 or 0
            local final_yaw = yaw_offset + yaw_base_offset
            local clamped_yaw = math.max(-180, math.min(180, normalize_yaw(final_yaw)))
            ui.set(aa_ref.yaw[2], clamped_yaw)
        end
        
        if aa_ref.body_yaw[1] then
            local body_yaw_mode = vals.body_yaw_mode
            if type(body_yaw_mode) == "number" then
                body_yaw_mode = ({"Disabled", "Static", "Jitter"})[body_yaw_mode + 1] or "Disabled"
            end
            if body_yaw_mode ~= "Disabled" then
                ui.set(aa_ref.body_yaw[1], "Static")
                if aa_ref.body_yaw[2] then
                    local clamped = math.max(-180, math.min(180, body_yaw_offset))
                    ui.set(aa_ref.body_yaw[2], clamped)
                end
            else
                ui.set(aa_ref.body_yaw[1], "Off")
            end
        end
        
        if aa_ref.yaw_jitter and aa_ref.yaw_jitter[1] then
            ui.set(aa_ref.yaw_jitter[1], "Off")
        end
        
        return
    end
    
    if aa_ref.body_yaw[1] then
        ui.set(aa_ref.body_yaw[1], "Off")
    end
    if aa_ref.yaw_jitter and aa_ref.yaw_jitter[1] then
        ui.set(aa_ref.yaw_jitter[1], "Off")
    end
    local yaw_base_offset = on_use.enabled and 180 or 0
    local final_yaw = yaw_offset + yaw_base_offset
    
    if aa_ref.pitch and aa_ref.pitch[1] then
        ui.set(aa_ref.pitch[1], "Down")
    end
    if aa_ref.yaw_base then
        ui.set(aa_ref.yaw_base, "At targets")
    end
    if aa_ref.yaw[1] and aa_ref.yaw[2] then
        ui.set(aa_ref.yaw[1], "180")
        ui.set(aa_ref.yaw[2], normalize_yaw(final_yaw))
    end
    
    if body_yaw_offset ~= 0 and globals.chokedcommands() == 0 then
        cmd.allow_send_packet = false
        cmd.no_choke = false
        ui.set(aa_ref.yaw[2], normalize_yaw(final_yaw + body_yaw_offset))
    end
end)
local function toticks(seconds)
    return seconds / globals.tickinterval()
end

local defensive_system = {
    max_tickbase = nil,
    tick_target = 0,
    data = {
        check = 0,
        defensive = 0,
        cmd = 0
    }
}

function defensive_system.update(cmd)
    local player_state = global_anti_prediction.player_state
    local me = entity.get_local_player()
    if not me or not entity.is_alive(me) then
        player_state.defensive_ticks_left = 0
        return
    end
    
    local current_tickbase = entity.get_prop(me, "m_nTickBase") or 0
    if defensive_system.max_tickbase == nil then
        defensive_system.max_tickbase = current_tickbase
    end
    
    if math.abs(current_tickbase - defensive_system.max_tickbase) > 64 then
        defensive_system.max_tickbase = current_tickbase
    end
    
    local defensive_ticks_left = 0
    if current_tickbase > defensive_system.max_tickbase then
        defensive_system.max_tickbase = current_tickbase
    elseif defensive_system.max_tickbase > current_tickbase then
        local raw_ticks = defensive_system.max_tickbase - current_tickbase - 1
        defensive_ticks_left = math.min(22, math.max(0, raw_ticks))
    end
    player_state.defensive_ticks_left = defensive_ticks_left
    
    if defensive_system.max_tickbase ~= nil then
        player_state.defensive_diff = current_tickbase - defensive_system.max_tickbase
        player_state.defensive.intelligent = player_state.defensive_diff < -2 and player_state.defensive_diff ~= 1
    end
    
    if cmd and cmd.command_number == defensive_system.data.cmd then
        local tickbase_prop = entity.get_prop(me, "m_nTickBase")
        if tickbase_prop then
            defensive_system.data.defensive = math.abs(tickbase_prop - defensive_system.data.check)
            defensive_system.data.check = math.max(tickbase_prop, defensive_system.data.check or 0)
            defensive_system.data.cmd = 0
            player_state.defensive.old = defensive_system.data.defensive > 3 and defensive_system.data.defensive < 15
        end
    end
end

function defensive_system.update_tick()
    local player_state = global_anti_prediction.player_state
    local me = entity.get_local_player()
    if not me or not entity.is_alive(me) then return end
    
    if not native.GetClientEntity then return end
    local client_entity = native.GetClientEntity(me)
    if not client_entity then return end
    
    local sim_time = entity.get_prop(me, "m_flSimulationTime")
    if not sim_time then return end
    
    local sim_time_diff = ffi.cast("float*", ffi.cast("uintptr_t", client_entity) + 620)[0] - sim_time
    if sim_time_diff > 0 then
        defensive_system.tick_target = globals.tickcount() + toticks(sim_time_diff - client.latency())
    end
    
    player_state.defensivie_dadas = globals.tickcount() <= defensive_system.tick_target - 2
end

function defensive_system.update_default()
    local player_state = global_anti_prediction.player_state
    local me = entity.get_local_player()
    if not me or not entity.is_alive(me) then return end
    
    if not native.GetClientEntity then return end
    local client_entity = native.GetClientEntity(me)
    if not client_entity then return end
    
    local sim_time = entity.get_prop(me, "m_flSimulationTime")
    if not sim_time then return end
    
    local sim_time_diff = ffi.cast("float*", ffi.cast("uintptr_t", client_entity) + 620)[0] - sim_time
    if sim_time_diff > 0 then
        player_state.defensive.default = globals.tickcount() + toticks(sim_time_diff - client.latency())
    end
end

function defensive_system.reset()
    defensive_system.data.check = 0
    defensive_system.data.defensive = 0
    defensive_system.max_tickbase = nil
    defensive_system.tick_target = 0
end

function defensive_system.get_ticks()
    return global_anti_prediction.player_state.defensive_ticks_left
end

function defensive_system.is_active()
    local player_state = global_anti_prediction.player_state
    return player_state.defensive.intelligent or player_state.defensive.old or player_state.defensivie_dadas
end

function defensive_system.get_info()
    local player_state = global_anti_prediction.player_state
    return {
        ticks_left = player_state.defensive_ticks_left,
        diff = player_state.defensive_diff,
        intelligent = player_state.defensive.intelligent,
        old = player_state.defensive.old,
        dadas = player_state.defensivie_dadas,
        default = player_state.defensive.default
    }
end

client.set_event_callback("run_command", function(cmd)
    defensive_system.data.cmd = cmd.command_number
end)

client.set_event_callback("level_init", function()
    defensive_system.reset()
end)

client.set_event_callback("predict_command", function(cmd)
    local player_state = global_anti_prediction.player_state
    player_state.on_ground = is_grounded()
    defensive_system.update(cmd)
    defensive_system.update_tick()
end)

client.set_event_callback("net_update_end", function()
    defensive_system.update_default()
end)

defensive_system.pitch_inverted = false
defensive_system.pitch_random_seed = 31337
defensive_system.pitch_generated = 0
defensive_system.yaw_generated = 0
defensive_system.jitter_cycle = 0
defensive_system.jitter_delay = 1
defensive_system.jitter_side = false
defensive_system.threeway_cycle = 0
defensive_system.threeway_index = 0
defensive_system.tick_interval = 1
defensive_system.last_defensive_tick = 0
defensive_system.tick_counter = 0
defensive_system.should_update = false
defensive_system.cached_pitch_mode = nil
defensive_system.cached_pitch_offset = 0
defensive_system.cached_yaw_mode = nil
defensive_system.cached_yaw_offset = 0
defensive_system.cached_yaw_base = nil

defensive_system.adaptive = {
    last_update_tick = 0,
    current_adaptive_offset = 0,
    target_offset = 0,
    direction = 1,
    change_interval = 0,
    next_change_tick = 0,
    chaos_seed = 0x9E3779B9,
    lorenz = {x = 0.1, y = 0.1, z = 0.1},
    enemy_aim = {
        aim_history = {}
    }
}

local function calc_pos(origin, distance, angle)
    if angle == nil or origin == nil or distance == nil then
        return nil
    end
    local angle_rad = angle * math.pi / 180
    if angle_rad == nil then
        return nil
    end
    return {
        origin[1] + math.cos(angle_rad) * distance,
        origin[2] + math.sin(angle_rad) * distance,
        origin[3]
    }
end

local function calc_freestand_side()
    local local_player = entity.get_local_player()
    local threat = client.current_threat()
    if not local_player or not threat or entity.is_dormant(threat) then
        return 0
    end
    local cam_pitch, cam_yaw = client.camera_angles(local_player)
    local local_right_far = calc_pos({entity.get_origin(local_player)}, 50, cam_yaw + 110)
    local local_right_near = calc_pos({entity.get_origin(local_player)}, 30, cam_yaw + 60)
    local local_left_far = calc_pos({entity.get_origin(local_player)}, 50, cam_yaw - 110)
    local local_left_near = calc_pos({entity.get_origin(local_player)}, 30, cam_yaw - 60)
    local enemy_pitch, enemy_yaw = entity.get_prop(threat, "m_angEyeAngles")
    local enemy_left_far = calc_pos({entity.get_origin(threat)}, 40, enemy_yaw - 115)
    local enemy_left_near = calc_pos({entity.get_origin(threat)}, 20, enemy_yaw - 35)
    local enemy_right_far = calc_pos({entity.get_origin(threat)}, 40, enemy_yaw + 115)
    local enemy_right_near = calc_pos({entity.get_origin(threat)}, 20, enemy_yaw + 35)
    local _, damage_right_far = client.trace_bullet(threat, enemy_right_far[1], enemy_right_far[2], enemy_right_far[3] + 70, local_right_far[1], local_right_far[2], local_right_far[3], true)
    local _, damage_left_far = client.trace_bullet(threat, enemy_left_far[1], enemy_left_far[2], enemy_left_far[3] + 70, local_left_far[1], local_left_far[2], local_left_far[3], true)
    local _, damage_right_near = client.trace_bullet(threat, enemy_right_near[1], enemy_right_near[2], enemy_right_near[3] + 30, local_right_near[1], local_right_near[2], local_right_near[3], true)
    local _, damage_left_near = client.trace_bullet(threat, enemy_left_near[1], enemy_left_near[2], enemy_left_near[3] + 30, local_left_near[1], local_left_near[2], local_left_near[3], true)
    local left_damage = damage_left_far + damage_left_near
    local right_damage = damage_right_far + damage_right_near
    if math.abs(left_damage - right_damage) < 5 then
        return 0
    elseif left_damage > right_damage then
        return -1
    else
        return 1
    end
end

local function adaptive_chaos_random(min, max)
    local state = defensive_system.adaptive
    local tick = globals.tickcount()
    local time = globals.realtime()
    
    state.chaos_seed = bit.bxor(state.chaos_seed, bit.lshift(state.chaos_seed, 13))
    state.chaos_seed = bit.bxor(state.chaos_seed, bit.rshift(state.chaos_seed, 17))
    state.chaos_seed = bit.bxor(state.chaos_seed, bit.lshift(state.chaos_seed, 5))
    state.chaos_seed = bit.bxor(state.chaos_seed, math.floor(time * 1000000) % 999983)
    state.chaos_seed = bit.bxor(state.chaos_seed, tick * 73939)
    
    local dt = 0.01
    local dx = 10 * (state.lorenz.y - state.lorenz.x) * dt
    local dy = (state.lorenz.x * (28 - state.lorenz.z) - state.lorenz.y) * dt
    local dz = (state.lorenz.x * state.lorenz.y - 2.667 * state.lorenz.z) * dt
    state.lorenz.x = math.max(-50, math.min(50, state.lorenz.x + dx))
    state.lorenz.y = math.max(-50, math.min(50, state.lorenz.y + dy))
    state.lorenz.z = math.max(0, math.min(50, state.lorenz.z + dz))
    local lorenz_contrib = (state.lorenz.x + state.lorenz.y) * 0.02
    
    local combined = lorenz_contrib
    local range = max - min + 1
    local normalized = (combined + 5) / 10
    normalized = math.max(0, math.min(1, normalized))
    
    local seed_influence = (math.abs(state.chaos_seed) % range)
    local final_value = min + math.floor(normalized * range * 0.6 + seed_influence * 0.4)
    
    return math.max(min, math.min(max, final_value))
end

local server_profile = {
    tickrate = 64,
    last_calibration = 0,
    ping_ms = 0,
    latency_comp = 0,
    jitter_mult = 1.0,
    server_quality = "good",
    adaptive_offset = 0,
    last_defensive_tick = 0,
    success_count = 0,
    fail_count = 0
}

local function calibrate_server()
    local me = entity.get_local_player()
    if not me then return end
    
    local tick = globals.tickcount()
    if tick - server_profile.last_calibration < 64 then return end
    server_profile.last_calibration = tick
    
    server_profile.tickrate = math.floor(1 / globals.tickinterval())
    local latency = client.latency()
    server_profile.ping_ms = latency * 1000
    server_profile.latency_comp = math.floor(latency * server_profile.tickrate)
    
    if server_profile.ping_ms < 30 then
        server_profile.server_quality = "excellent"
        server_profile.jitter_mult = 0.8
    elseif server_profile.ping_ms < 60 then
        server_profile.server_quality = "good"
        server_profile.jitter_mult = 1.0
    elseif server_profile.ping_ms < 100 then
        server_profile.server_quality = "fair"
        server_profile.jitter_mult = 1.3
    else
        server_profile.server_quality = "poor"
        server_profile.jitter_mult = 1.6
    end
    
    local success_rate = server_profile.success_count / math.max(1, server_profile.success_count + server_profile.fail_count)
    if success_rate < 0.5 and server_profile.success_count + server_profile.fail_count > 5 then
        server_profile.adaptive_offset = math.min(3, server_profile.adaptive_offset + 1)
    elseif success_rate > 0.8 and server_profile.adaptive_offset > 0 then
        server_profile.adaptive_offset = math.max(0, server_profile.adaptive_offset - 1)
    end
end

local function record_defensive_result(success)
    if success then
        server_profile.success_count = server_profile.success_count + 1
    else
        server_profile.fail_count = server_profile.fail_count + 1
    end
    
    local total_attempts = server_profile.success_count + server_profile.fail_count
    if total_attempts > 10 then
        local success_rate = server_profile.success_count / total_attempts
        
        if success_rate < 0.4 then
            server_profile.adaptive_offset = math.min(4, server_profile.adaptive_offset + 1)
        elseif success_rate > 0.85 then
            server_profile.adaptive_offset = math.max(-1, server_profile.adaptive_offset - 1)
        end
    end
    
    if total_attempts > 50 then
        server_profile.success_count = math.floor(server_profile.success_count * 0.7)
        server_profile.fail_count = math.floor(server_profile.fail_count * 0.7)
    end
end

local defensive_cache = {
    last_calculation_tick = 0,
    cached_result = 0,
    cached_delay = 0,
    velocity_history = {},
    threat_history = {},
    performance_score = 1.0,
    last_success_tick = 0,
    consecutive_failures = 0
}

local function calculate_defensive_speed(builder_state_items)
    local player_state = global_anti_prediction.player_state
    local tick = globals.tickcount()
    local time = globals.realtime()
    
    if defensive_cache.last_calculation_tick == tick then
        return defensive_cache.cached_result
    end
    
    local tick_mode = builder_state_items.def_tick_mode and builder_state_items.def_tick_mode() or "Custom"
    
    if tick % 16 == 0 then
        calibrate_server()
    end
    
    local final_tick_delay = 0
    
    if tick_mode == "Adaptive" then
        local adaptive = defensive_system.adaptive
        local me = entity.get_local_player()
        
        local base_delay = 6
        if defensive_cache.performance_score > 0.8 then
            base_delay = 5  
        elseif defensive_cache.performance_score < 0.4 then
            base_delay = 7  
        end
        
        local velocity_mod = 0
        local threat_mod = 0
        local ping_mod = 0
        
        if me then
            local vx, vy, vz = entity.get_prop(me, "m_vecVelocity")
            local velocity = vx and math.sqrt(vx*vx + vy*vy) or 0
            
            table.insert(defensive_cache.velocity_history, velocity)
            if #defensive_cache.velocity_history > 5 then
                table.remove(defensive_cache.velocity_history, 1)
            end
            
            local velocity_trend = 0
            if #defensive_cache.velocity_history >= 3 then
                velocity_trend = defensive_cache.velocity_history[#defensive_cache.velocity_history] - 
                                defensive_cache.velocity_history[1]
            end
            
            if velocity > 250 then
                velocity_mod = velocity_trend > 50 and 4 or 3
            elseif velocity > 150 then
                velocity_mod = velocity_trend > 30 and 3 or 2
            elseif velocity > 100 then
                velocity_mod = 1
            elseif velocity < 30 then
                velocity_mod = -1
            end
            
            velocity_mod = math.floor(velocity_mod * server_profile.jitter_mult)
        end
        
        local threat = client.current_threat()
        if threat and not entity.is_dormant(threat) then
            local enemy_pitch, enemy_yaw = entity.get_prop(threat, "m_angEyeAngles")
            if enemy_pitch and enemy_yaw then
                local enemy_aim = adaptive.enemy_aim
                table.insert(enemy_aim.aim_history, {yaw = enemy_yaw, pitch = enemy_pitch, tick = tick})
                if #enemy_aim.aim_history > 12 then
                    table.remove(enemy_aim.aim_history, 1)
                end
                
                if #enemy_aim.aim_history >= 4 then
                    local yaw_variance = 0
                    local pitch_variance = 0
                    for i = 2, #enemy_aim.aim_history do
                        yaw_variance = yaw_variance + math.abs(enemy_aim.aim_history[i].yaw - enemy_aim.aim_history[i-1].yaw)
                        pitch_variance = pitch_variance + math.abs(enemy_aim.aim_history[i].pitch - enemy_aim.aim_history[i-1].pitch)
                    end
                    yaw_variance = yaw_variance / (#enemy_aim.aim_history - 1)
                    pitch_variance = pitch_variance / (#enemy_aim.aim_history - 1)
                    
                    local total_variance = yaw_variance + pitch_variance
                    if total_variance < 3 then
                        threat_mod = 3  
                    elseif total_variance < 8 then
                        threat_mod = 2  
                    elseif total_variance < 20 then
                        threat_mod = 1  
                    end
                    
                    if #enemy_aim.aim_history >= 6 then
                        local recent_variance = 0
                        for i = #enemy_aim.aim_history - 2, #enemy_aim.aim_history do
                            recent_variance = recent_variance + math.abs(enemy_aim.aim_history[i].yaw - enemy_aim.aim_history[i-1].yaw)
                        end
                        recent_variance = recent_variance / 3
                        
                        if recent_variance < 2 then
                            threat_mod = threat_mod + 1  
                        end
                    end
                end
            end
        end
        
        if server_profile.ping_ms > 80 then
            ping_mod = 2
        elseif server_profile.ping_ms > 50 then
            ping_mod = 1
        end
        
        if adaptive.next_change_tick == 0 or tick >= adaptive.next_change_tick then
            local chaos_val = adaptive_chaos_random(0, 5)
            local direction_change = adaptive_chaos_random(1, 100) <= 30
            
            if direction_change then
                adaptive.direction = -adaptive.direction
            end
            
            adaptive.target_offset = base_delay + velocity_mod + threat_mod + ping_mod + server_profile.adaptive_offset
            adaptive.target_offset = adaptive.target_offset + (chaos_val * adaptive.direction)
            
            local max_offset = defensive_cache.performance_score > 0.7 and 14 or 13
            adaptive.target_offset = math.max(0, math.min(max_offset, adaptive.target_offset))
            
            local change_interval = adaptive_chaos_random(2, 5)
            if threat_mod > 1 then
                change_interval = math.max(1, change_interval - 1)  
            elseif threat_mod == 0 then
                change_interval = change_interval + 1  
            end
            adaptive.next_change_tick = tick + change_interval
        end
        
        local smooth_speed = 0.35
        if threat_mod > 1 then
            smooth_speed = 0.7  
        elseif threat_mod == 0 then
            smooth_speed = 0.2  
        end
        
        adaptive.current_adaptive_offset = adaptive.current_adaptive_offset + 
            (adaptive.target_offset - adaptive.current_adaptive_offset) * smooth_speed
        
        if math.abs(adaptive.current_adaptive_offset - adaptive.target_offset) < 0.1 then
            adaptive.current_adaptive_offset = adaptive.target_offset
        end
        
        final_tick_delay = math.floor(adaptive.current_adaptive_offset + 0.5)
        final_tick_delay = math.max(0, math.min(14, final_tick_delay))
    else
        final_tick_delay = builder_state_items.def_tick_speed and builder_state_items.def_tick_speed() or 0
    end
    
    local defensive_window = player_state.defensive.default - final_tick_delay
    local should_activate = tick <= defensive_window
    
    if not should_activate and tick >= defensive_window - 2 then
        should_activate = adaptive_chaos_random(1, 100) <= 30  
    end
    
    defensive_cache.last_calculation_tick = tick
    defensive_cache.cached_result = should_activate and 1 or 0
    defensive_cache.cached_delay = final_tick_delay
    
    return defensive_cache.cached_result
end

local function should_use_defensive_with_speed(builder_state_items, defensive_ticks_left)
    local sys = defensive_system
    local current_tick = globals.tickcount()
    
    if defensive_ticks_left == 0 then
        if sys.last_defensive_tick > 0 then
            local was_active = sys.should_update
            local duration = current_tick - sys.last_defensive_tick
            
            if was_active then
                record_defensive_result(true)
                defensive_cache.last_success_tick = current_tick
                defensive_cache.consecutive_failures = 0
                
                defensive_cache.performance_score = math.min(1.0, defensive_cache.performance_score + 0.05)
            else
                defensive_cache.consecutive_failures = defensive_cache.consecutive_failures + 1
                
                if defensive_cache.consecutive_failures >= 3 then
                    defensive_cache.performance_score = math.max(0.3, defensive_cache.performance_score - 0.1)
                end
            end
        end
        
        sys.tick_interval = 1
        sys.last_defensive_tick = 0
        sys.tick_counter = 0
        sys.should_update = false
        
        defensive_cache.last_calculation_tick = 0
        defensive_cache.cached_result = 0
        defensive_cache.velocity_history = {}
        defensive_cache.threat_history = {}
        
        defensive_system.adaptive.current_adaptive_offset = 0
        defensive_system.adaptive.direction = 1
        defensive_system.adaptive.next_change_tick = 0
        
        return false
    end
    
    if defensive_ticks_left > 0 and sys.last_defensive_tick == 0 then
        sys.tick_interval = 1
        sys.last_defensive_tick = current_tick
        sys.tick_counter = 0
        sys.should_update = true
        
        defensive_cache.start_tick = current_tick
    end
    
    local should_activate = calculate_defensive_speed(builder_state_items)
    sys.should_update = should_activate == 1
    
    if defensive_ticks_left <= 3 and not sys.should_update then
        sys.should_update = true
    end
    
    return sys.should_update
end

local function update_defensive_inverters(cmd)
    local sys = defensive_system
    if cmd.chokedcommands == 0 and sys.should_update then
        defensive_system.pitch_inverted = not defensive_system.pitch_inverted
    end
end

local function calculate_defensive_pitch(builder_state_items, cmd)
    local sys = defensive_system
    if not sys.should_update and sys.cached_pitch_mode ~= nil then
        return sys.cached_pitch_mode, sys.cached_pitch_offset
    end
    local pitch_mode = builder_state_items.def_pitch_mode()
    local pitch1 = builder_state_items.def_pitch_1()
    local pitch2 = builder_state_items.def_pitch_2()
    local speed = builder_state_items.def_pitch_speed()
    if pitch_mode == "Off" then
        sys.cached_pitch_mode = nil
        sys.cached_pitch_offset = 0
        return nil
    end
    local result_pitch = 0
    local result_mode = "Custom"
    if pitch_mode == "Static" then
        result_pitch = pitch1
    elseif pitch_mode == "Sway" then
        local time = globals.curtime() * speed * 0.1
        result_pitch = pitch1 + (pitch2 - pitch1) * (time % 1)
    elseif pitch_mode == "Switch" then
        result_pitch = defensive_system.pitch_inverted and pitch2 or pitch1
    elseif pitch_mode == "Random" then
        if cmd and cmd.chokedcommands == 0 then
            defensive_system.pitch_random_seed = bit.bxor(defensive_system.pitch_random_seed, bit.lshift(defensive_system.pitch_random_seed, 13))
            defensive_system.pitch_random_seed = bit.bxor(defensive_system.pitch_random_seed, bit.rshift(defensive_system.pitch_random_seed, 17))
            defensive_system.pitch_random_seed = bit.bxor(defensive_system.pitch_random_seed, bit.lshift(defensive_system.pitch_random_seed, 5))
            local range = pitch2 - pitch1 + 1
            defensive_system.pitch_generated = pitch1 + (math.abs(defensive_system.pitch_random_seed) % range)
        end
        result_pitch = defensive_system.pitch_generated
    end
    result_pitch = math.max(-89, math.min(89, result_pitch))
    sys.cached_pitch_mode = result_mode
    sys.cached_pitch_offset = result_pitch
    return result_mode, result_pitch
end

local function calculate_defensive_yaw(builder_state_items, freestand_side, cmd)
    local sys = defensive_system
    if not sys.should_update and sys.cached_yaw_mode ~= nil then
        return sys.cached_yaw_mode, sys.cached_yaw_offset, sys.cached_yaw_base
    end
    local yaw_mode = builder_state_items.def_yaw_mode()
    local yaw_offset = builder_state_items.def_yaw_offset()
    local yaw_left = builder_state_items.def_yaw_left()
    local yaw_right = builder_state_items.def_yaw_right()
    local speed = builder_state_items.def_yaw_speed()
    if yaw_mode == "Off" then
        sys.cached_yaw_mode = nil
        sys.cached_yaw_offset = 0
        sys.cached_yaw_base = nil
        return nil, nil, nil
    end
    local result_yaw_offset = 0
    local result_yaw_mode = "180"
    local result_yaw_base = nil
    local sign_multiplier = (freestand_side == -1) and -1 or 1
    if yaw_mode == "Static" then
        result_yaw_offset = yaw_offset * sign_multiplier
    elseif yaw_mode == "Spin" then
        result_yaw_offset = ((globals.curtime() * (speed * 12)) % 360) * sign_multiplier
    elseif yaw_mode == "Sway" then
        local time = globals.curtime() * speed * 0.1
        result_yaw_offset = (yaw_left + (yaw_right - yaw_left) * (time % 1)) * sign_multiplier
    elseif yaw_mode == "Jitter" then
        if cmd and cmd.chokedcommands == 0 then
            defensive_system.jitter_cycle = defensive_system.jitter_cycle + 1
            if defensive_system.jitter_cycle >= defensive_system.jitter_delay then
                defensive_system.jitter_cycle = 0
                defensive_system.jitter_side = not defensive_system.jitter_side
                local delay_min = builder_state_items.def_jitter_delay_min()
                local delay_max = builder_state_items.def_jitter_delay_max()
                defensive_system.jitter_delay = math.random(delay_min, delay_max)
            end
        end
        result_yaw_offset = (defensive_system.jitter_side and yaw_left or yaw_right) * sign_multiplier
    elseif yaw_mode == "3-Way" then
        if cmd and cmd.chokedcommands == 0 then
            defensive_system.threeway_cycle = defensive_system.threeway_cycle + 1
            local delay = builder_state_items.def_3way_delay()
            if defensive_system.threeway_cycle >= delay then
                defensive_system.threeway_cycle = 0
                defensive_system.threeway_index = (defensive_system.threeway_index + 1) % 3
            end
        end
        local angles = {
            builder_state_items.def_3way_angle1(),
            builder_state_items.def_3way_angle2(),
            builder_state_items.def_3way_angle3()
        }
        result_yaw_offset = angles[defensive_system.threeway_index + 1] * sign_multiplier
    elseif yaw_mode == "Random" then
        if cmd and cmd.chokedcommands == 0 then
            defensive_system.yaw_generated = math.random(-yaw_offset, yaw_offset)
        end
        result_yaw_offset = defensive_system.yaw_generated * sign_multiplier
    end
    while result_yaw_offset > 180 do result_yaw_offset = result_yaw_offset - 360 end
    while result_yaw_offset < -180 do result_yaw_offset = result_yaw_offset + 360 end
    sys.cached_yaw_mode = result_yaw_mode
    sys.cached_yaw_offset = result_yaw_offset
    sys.cached_yaw_base = result_yaw_base
    return result_yaw_mode, result_yaw_offset, result_yaw_base
end


client.set_event_callback('setup_command', function(cmd)
    local player_state = global_anti_prediction.player_state
    local me = entity.get_local_player()
    if not me or not entity.is_alive(me) then return end
    
    local dt_ref = ui.reference("RAGE", "Aimbot", "Double tap")
    local osaa_ref = ui.reference("AA", "Other", "On shot anti-aim")
    local fd_ref = ui.reference("RAGE", "Other", "Duck peek assist")
    
    local is_exploit = (dt_ref and ui.get(dt_ref)) or (osaa_ref and ui.get(osaa_ref))
    local is_fakeduck = fd_ref and ui.get(fd_ref)
    local defensive_is_shifting = player_state.defensive_ticks_left > 0
    
    local current_state = get_player_state(cmd)
    
    local def_settings = menu.defensive and menu.defensive[current_state]
    if not def_settings then
        def_settings = menu.defensive and menu.defensive["Global"]
    end
    
    local def_enabled = def_settings and def_settings.def_enable and def_settings.def_enable:get()
    
    if is_exploit and not is_fakeduck and def_enabled and defensive_is_shifting then
        local freestand_side = calc_freestand_side() or 0
        
        local builder_state_items = {
            def_tick_mode = function() return def_settings.def_tick_mode and def_settings.def_tick_mode:get() or "Custom" end,
            def_tick_speed = function() return def_settings.def_tick_speed and def_settings.def_tick_speed:get() or 0 end,
            def_pitch_mode = function() return def_settings.def_pitch_mode and def_settings.def_pitch_mode:get() or "Off" end,
            def_pitch_1 = function() return def_settings.def_pitch_1 and def_settings.def_pitch_1:get() or 0 end,
            def_pitch_2 = function() return def_settings.def_pitch_2 and def_settings.def_pitch_2:get() or 0 end,
            def_pitch_speed = function() return def_settings.def_pitch_speed and def_settings.def_pitch_speed:get() or 20 end,
            def_yaw_mode = function() return def_settings.def_yaw_mode and def_settings.def_yaw_mode:get() or "Off" end,
            def_yaw_offset = function() return def_settings.def_yaw_offset and def_settings.def_yaw_offset:get() or 0 end,
            def_yaw_left = function() return def_settings.def_yaw_left and def_settings.def_yaw_left:get() or 0 end,
            def_yaw_right = function() return def_settings.def_yaw_right and def_settings.def_yaw_right:get() or 0 end,
            def_yaw_speed = function() return def_settings.def_yaw_speed and def_settings.def_yaw_speed:get() or 20 end,
            def_jitter_delay_min = function() return def_settings.def_jitter_delay_min and def_settings.def_jitter_delay_min:get() or 1 end,
            def_jitter_delay_max = function() return def_settings.def_jitter_delay_max and def_settings.def_jitter_delay_max:get() or 3 end,
            def_3way_angle1 = function() return def_settings.def_3way_angle1 and def_settings.def_3way_angle1:get() or -60 end,
            def_3way_angle2 = function() return def_settings.def_3way_angle2 and def_settings.def_3way_angle2:get() or 0 end,
            def_3way_angle3 = function() return def_settings.def_3way_angle3 and def_settings.def_3way_angle3:get() or 60 end,
            def_3way_delay = function() return def_settings.def_3way_delay and def_settings.def_3way_delay:get() or 2 end
        }
        
        if should_use_defensive_with_speed(builder_state_items, player_state.defensive_ticks_left) then
            update_defensive_inverters(cmd)
            local def_pitch_mode, def_pitch_value = calculate_defensive_pitch(builder_state_items, cmd)
            local def_yaw_mode, def_yaw_offset, def_yaw_base = calculate_defensive_yaw(builder_state_items, freestand_side, cmd)
            
            if def_pitch_value then
                if aa_ref.pitch and aa_ref.pitch[1] then
                    ui.set(aa_ref.pitch[1], "Custom")
                    if aa_ref.pitch[2] then
                        local clamped_pitch = math.max(-89, math.min(89, def_pitch_value))
                        ui.set(aa_ref.pitch[2], clamped_pitch)
                    end
                end
            end
            
            if def_yaw_offset then
                if aa_ref.yaw_base then
                    ui.set(aa_ref.yaw_base, "At targets")
                end
                if aa_ref.yaw[1] and aa_ref.yaw[2] then
                    ui.set(aa_ref.yaw[1], def_yaw_mode or "180")
                    local clamped_yaw = math.max(-180, math.min(180, def_yaw_offset))
                    ui.set(aa_ref.yaw[2], clamped_yaw)
                end
            end
        end
    end
    
    if def_settings and def_settings.def_force and def_settings.def_force:get() then
        cmd.force_defensive = true
    end
end)

local function update_shift()
    local player_state = global_anti_prediction.player_state
    local me = entity.get_local_player()
    if not me or not entity.is_alive(me) then return end
    local tickbase = entity.get_prop(me, "m_nTickBase")
    if not tickbase then return end
    local latency = client.latency()
    local shift_amount = math.floor(tickbase - globals.tickcount() - 3 - toticks(latency) * 0.5 + 0.5 * (latency * 10))
    local dt_limit_ref = ui.reference("RAGE", "Aimbot", "Double tap fake lag limit")
    local dt_limit = dt_limit_ref and ui.get(dt_limit_ref) or 14
    local max_shift_limit = -14 + (dt_limit - 1) + 3
    player_state.shift = shift_amount <= max_shift_limit
end
client.set_event_callback('setup_command', update_shift)
client.set_event_callback('finish_command', function(cmd)
    local me = entity.get_local_player()
    if not me or not entity.is_alive(me) then return end
end)
local function animate_info_labels()
    local time = globals.realtime() * 0.8
    
    local function blue_white_gradient(text, offset)
        local chars = utils.utf8_chars(text)  
        local output = ""
        for i, char in ipairs(chars) do
            local progress = (i - 1) / math.max(1, #chars - 1)
            local wave = math.sin(time + (i + offset) * 0.3) * 0.15
            
            local r = math.max(0, math.min(255, math.floor(164 + (255 - 164) * (progress + wave))))
            local g = math.max(0, math.min(255, math.floor(178 + (255 - 178) * (progress + wave))))
            local b = math.max(0, math.min(255, math.floor(241 + (255 - 241) * (progress + wave))))
            
            output = output .. string.format("\a%02X%02X%02XFF", r, g, b) .. char
        end
        return output
    end

    local function pulse_blue(text)
        local pulse = (math.sin(time * 2) * 0.3 + 0.7)
        local r = math.floor(164 * pulse)
        local g = math.floor(178 * pulse)
        local b = math.floor(241 * pulse)
        return string.format("\a%02X%02X%02XFF", r, g, b) .. text
    end
    
    menu.welcome_label:set(blue_white_gradient("Welcome to AMGSENSE", -5))
    
    local separator = "═══════════════════════════════"
    menu.info.title:set(blue_white_gradient(separator, 0))
    menu.info.welcome:set("\aFFFFFFFF" .. "User: " .. blue_white_gradient(steam_name, 0))
    menu.info.script_name:set("\aFFFFFFFF" .. "Script: " .. blue_white_gradient("AMGSENSE", 5))
    menu.info.version:set("\aFFFFFFFF" .. "Version: " .. blue_white_gradient("RECODE", 10))
    menu.info.updated:set("\aFFFFFFFF" .. "Updated: " .. blue_white_gradient("2025.01.12", 15))
    menu.info.features:set("\aFFFFFFFF" .. "Features: " .. blue_white_gradient("Advanced Anti-Aim | Ragebot | Visuals", 20))
    menu.info.footer:set(blue_white_gradient(separator, 30))
end
client.set_event_callback('paint_ui', function()
    hide_aa(false)
    animate_info_labels()
    
    if aa_ref.enabled then
        ui.set(aa_ref.enabled, true)
    end
    if aa_ref.pitch and aa_ref.pitch[1] then
        ui.set(aa_ref.pitch[1], "Down")
    end
    if aa_ref.yaw_base then
        ui.set(aa_ref.yaw_base, "At targets")
    end
end)
client.set_event_callback('shutdown', function()
    hide_aa(true)
end)
draw_rounded_rect = utils.draw_rounded_rect  
local wm = {
    alpha = 0, fps = 0, ping = 0, time = "", tick = 0, content_alpha = 0
}
local glow_frame_counter = 0
local function render_watermark()
    glow_frame_counter = (glow_frame_counter + 1) % 10000
    local should_draw_glow = (glow_frame_counter % 2 == 0)
    local me = entity.get_local_player()
    if not me or not entity.is_alive(me) then
        wm.alpha = math.max(0, wm.alpha - globals.frametime() * 10)
        wm.content_alpha = math.max(0, wm.content_alpha - globals.frametime() * 8)
        if wm.alpha < 0.01 then return end
    end
    if not get_menu_value(menu.visual.watermark_enabled) then
        wm.alpha = math.max(0, wm.alpha - globals.frametime() * 10)
        if wm.alpha < 0.01 then return end
    else
        wm.alpha = math.min(1, wm.alpha + globals.frametime() * 10)
    end
    wm.content_alpha = me and entity.is_alive(me) and math.min(1, wm.content_alpha + globals.frametime() * 8) or math.max(0, wm.content_alpha - globals.frametime() * 8)
    local tick = globals.tickcount()
    if tick - wm.tick >= 16 then
        wm.fps = math.floor(1 / math.max(globals.frametime(), 0.001))
        wm.ping = me and math.floor(client.latency() * 1000) or 0
        local h, m = client.system_time()
        wm.time = string.format("%02d:%02d", h, m)
        wm.tick = tick
    end
    local sx, sy = client.screen_size()
    local ar, ag, ab = get_color_value(menu.visual.watermark_color)
    local a = wm.alpha
    local ca = wm.content_alpha
    local padding_x, padding_y = 10, 5
    local radius = 8
    local gap = 4
    local header = "amgsense"
    local header_w = renderer.measure_text("b", header)
    local header_h = 14
    local items = {}
    local steam_name = "user"
    if me then
        local name = entity.get_player_name(me)
        if name and name ~= '' and name ~= 'unknown' then
            steam_name = name
        end
    end
    table.insert(items, {icon = '\xEE\x84\xBD', text = steam_name, color = {ar, ag, ab}})
    local ping_icon = '\xEE\x87\xA9'
    if wm.ping >= 150 then ping_icon = '\xEE\x87\xA6' elseif wm.ping >= 100 then ping_icon = '\xEE\x87\xA7' elseif wm.ping >= 50 then ping_icon = '\xEE\x87\xA8' end
    table.insert(items, {icon = ping_icon, text = wm.ping .. " ms", color = {ar, ag, ab}})
    table.insert(items, {icon = '\xEE\x86\xA6', text = wm.fps .. " fps", color = {ar, ag, ab}})
    table.insert(items, {icon = '\xEE\x8A\xAD', text = wm.time, color = {ar, ag, ab}})
    local content_w = 0
    for i, item in ipairs(items) do
        local icon_w = renderer.measure_text("", item.icon)
        local text_w = renderer.measure_text("", item.text)
        content_w = content_w + icon_w + 3 + text_w
        if i < #items then content_w = content_w + 12 end
    end
    local header_box_w = header_w + padding_x * 2
    local header_box_h = header_h + padding_y * 2
    local content_box_w = content_w + padding_x * 2
    local total_w = header_box_w + (ca > 0.01 and (gap + content_box_w) or 0)
    local box_x = sx - total_w - 10
    local box_y = 10
    local bg_a = math.floor(225 * a / 4)
    local glow_strength = 8
    if a > 0.15 then
        for i = 1, glow_strength, 1 do
            local glow_alpha = (a * 255 / 255) * (100 / (i * i * 0.08 + i))
            renderer.circle_outline(box_x + radius, box_y + radius, ar, ag, ab, glow_alpha, radius + i, 180, 0.25, 1)
            renderer.circle_outline(box_x + header_box_w - radius, box_y + radius, ar, ag, ab, glow_alpha, radius + i, 270, 0.25, 1)
            renderer.circle_outline(box_x + radius, box_y + header_box_h - radius, ar, ag, ab, glow_alpha, radius + i, 90, 0.25, 1)
            renderer.circle_outline(box_x + header_box_w - radius, box_y + header_box_h - radius, ar, ag, ab, glow_alpha, radius + i, 0, 0.25, 1)
            renderer.rectangle(box_x + radius, box_y - i, header_box_w - radius * 2, 1, ar, ag, ab, glow_alpha)
            renderer.rectangle(box_x + radius, box_y + header_box_h + i - 1, header_box_w - radius * 2, 1, ar, ag, ab, glow_alpha)
            renderer.rectangle(box_x - i, box_y + radius, 1, header_box_h - radius * 2, ar, ag, ab, glow_alpha)
            renderer.rectangle(box_x + header_box_w + i - 1, box_y + radius, 1, header_box_h - radius * 2, ar, ag, ab, glow_alpha)
        end
    end
    draw_rounded_rect(box_x, box_y, header_box_w, header_box_h, radius, 18, 18, 18, bg_a, 0, 0, 0, 0)
    draw_rounded_rect(box_x, box_y, header_box_w, header_box_h, radius, 0, 0, 0, 0, 255, 255, 255, math.floor(60 * a))
    local text_x = box_x + padding_x
    local text_y = box_y + padding_y
    for i = 1, #header do
        local char = header:sub(i, i)
        local char_w = renderer.measure_text("b", char)
        local gradient_factor = (i - 1) / (#header - 1)
        local cr = math.floor(255 + (ar - 255) * gradient_factor)
        local cg = math.floor(255 + (ag - 255) * gradient_factor)
        local cb = math.floor(255 + (ab - 255) * gradient_factor)
        renderer.text(text_x, text_y, cr, cg, cb, math.floor(255 * a), "b", 0, char)
        text_x = text_x + char_w
    end
    if ca > 0.01 then
        local content_x = box_x + header_box_w + gap
        if ca > 0.15 then
            for i = 1, glow_strength, 1 do
                local glow_alpha = (a * ca * 255 / 255) * (100 / (i * i * 0.08 + i))
                renderer.circle_outline(content_x + radius, box_y + radius, ar, ag, ab, glow_alpha, radius + i, 180, 0.25, 1)
                renderer.circle_outline(content_x + content_box_w - radius, box_y + radius, ar, ag, ab, glow_alpha, radius + i, 270, 0.25, 1)
                renderer.circle_outline(content_x + radius, box_y + header_box_h - radius, ar, ag, ab, glow_alpha, radius + i, 90, 0.25, 1)
                renderer.circle_outline(content_x + content_box_w - radius, box_y + header_box_h - radius, ar, ag, ab, glow_alpha, radius + i, 0, 0.25, 1)
                renderer.rectangle(content_x + radius, box_y - i, content_box_w - radius * 2, 1, ar, ag, ab, glow_alpha)
                renderer.rectangle(content_x + radius, box_y + header_box_h + i - 1, content_box_w - radius * 2, 1, ar, ag, ab, glow_alpha)
                renderer.rectangle(content_x - i, box_y + radius, 1, header_box_h - radius * 2, ar, ag, ab, glow_alpha)
                renderer.rectangle(content_x + content_box_w + i - 1, box_y + radius, 1, header_box_h - radius * 2, ar, ag, ab, glow_alpha)
            end
        end
        draw_rounded_rect(content_x, box_y, content_box_w, header_box_h, radius, 18, 18, 18, math.floor(bg_a * ca), 0, 0, 0, 0)
        draw_rounded_rect(content_x, box_y, content_box_w, header_box_h, radius, 0, 0, 0, 0, 255, 255, 255, math.floor(60 * a * ca))
        local ctx = content_x + padding_x
        local cty = box_y + padding_y
        for i, item in ipairs(items) do
            local icon_w = renderer.measure_text("b", item.icon)
            renderer.text(ctx, cty, item.color[1], item.color[2], item.color[3], math.floor(255 * a * ca), "b", 0, item.icon)
            ctx = ctx + icon_w + 3
            local text_w = renderer.measure_text("", item.text)
            renderer.text(ctx, cty, 200, 200, 200, math.floor(255 * a * ca), "", 0, item.text)
            ctx = ctx + text_w
            if i < #items then ctx = ctx + 12 end
        end
    end
end
local spec_state = {
    alpha = 0,
    spectators = {},
    drag = {active = false, ox = 0, oy = 0},
    x = database.read("amgsense_spectators_x") or 10,
    y = database.read("amgsense_spectators_y") or 200
}
local function get_spectators()
    local specs = {}
    local me = entity.get_local_player()
    if not me then return specs end
    local players = entity.get_players(false)
    for _, player in ipairs(players) do
        if player ~= me and not entity.is_alive(player) then
            local obs_handle = entity.get_prop(player, "m_hObserverTarget")
            local obs_mode = entity.get_prop(player, "m_iObserverMode")
            if obs_handle and obs_handle == me and obs_mode and obs_mode >= 4 then
                local name = entity.get_player_name(player) or "Unknown"
                table.insert(specs, name)
            end
        end
    end
    return specs
end
local function render_spectators()
    if not get_menu_value(menu.visual.spectators_enabled) then
        spec_state.alpha = math.max(0, spec_state.alpha - globals.frametime() * 10)
        if spec_state.alpha < 0.01 then return end
    else
        spec_state.alpha = math.min(1, spec_state.alpha + globals.frametime() * 10)
    end
    local me = entity.get_local_player()
    if not me or not entity.is_alive(me) then
        spec_state.alpha = math.max(0, spec_state.alpha - globals.frametime() * 10)
        if spec_state.alpha < 0.01 then return end
    end
    spec_state.spectators = get_spectators()
    local specs = spec_state.spectators
    local a = spec_state.alpha
    local ar, ag, ab = get_color_value(menu.visual.spectators_color)
    local padding_x, padding_y = 10, 5
    local radius = 8
    local item_height = 16
    local header = "spectators"
    local header_w = renderer.measure_text("b", header)
    local header_h = 14
    local count_text = tostring(#specs)
    local count_w = renderer.measure_text("", count_text)
    local max_name_w = 0
    for _, name in ipairs(specs) do
        local nw = renderer.measure_text("", name)
        if nw > max_name_w then max_name_w = nw end
    end
    local header_title_w = header_w + 12 + count_w
    local header_box_w = math.max(header_title_w + padding_x * 2, max_name_w + padding_x * 2 + 20)
    local header_box_h = header_h + padding_y * 2
    local content_box_h = #specs > 0 and (#specs * item_height + padding_y * 2) or 0
    local box_x = spec_state.x
    local box_y = spec_state.y
    local mouse_x, mouse_y = ui.mouse_position()
    if client.key_state(0x01) then
        if spec_state.drag.active then
            local new_x = mouse_x - spec_state.drag.ox
            local new_y = mouse_y - spec_state.drag.oy
            spec_state.x = new_x
            spec_state.y = new_y
            database.write("amgsense_spectators_x", new_x)
            database.write("amgsense_spectators_y", new_y)
        elseif mouse_x >= box_x and mouse_x <= box_x + header_box_w and mouse_y >= box_y and mouse_y <= box_y + header_box_h then
            spec_state.drag.active = true
            spec_state.drag.ox = mouse_x - box_x
            spec_state.drag.oy = mouse_y - box_y
        end
    else
        spec_state.drag.active = false
    end
    local bg_a = math.floor(225 * a / 4)
    local glow_strength = 8
    if a > 0.15 then
        for i = 1, glow_strength, 1 do
            local glow_alpha = (a * 255 / 255) * (100 / (i * i * 0.08 + i))
            renderer.circle_outline(box_x + radius, box_y + radius, ar, ag, ab, glow_alpha, radius + i, 180, 0.25, 1)
            renderer.circle_outline(box_x + header_box_w - radius, box_y + radius, ar, ag, ab, glow_alpha, radius + i, 270, 0.25, 1)
            renderer.circle_outline(box_x + radius, box_y + header_box_h - radius, ar, ag, ab, glow_alpha, radius + i, 90, 0.25, 1)
            renderer.circle_outline(box_x + header_box_w - radius, box_y + header_box_h - radius, ar, ag, ab, glow_alpha, radius + i, 0, 0.25, 1)
            renderer.rectangle(box_x + radius, box_y - i, header_box_w - radius * 2, 1, ar, ag, ab, glow_alpha)
            renderer.rectangle(box_x + radius, box_y + header_box_h + i - 1, header_box_w - radius * 2, 1, ar, ag, ab, glow_alpha)
            renderer.rectangle(box_x - i, box_y + radius, 1, header_box_h - radius * 2, ar, ag, ab, glow_alpha)
            renderer.rectangle(box_x + header_box_w + i - 1, box_y + radius, 1, header_box_h - radius * 2, ar, ag, ab, glow_alpha)
        end
    end
    draw_rounded_rect(box_x, box_y, header_box_w, header_box_h, radius, 18, 18, 18, bg_a, 0, 0, 0, 0)
    draw_rounded_rect(box_x, box_y, header_box_w, header_box_h, radius, 0, 0, 0, 0, 255, 255, 255, math.floor(60 * a))
    local text_x = box_x + padding_x
    local text_y = box_y + padding_y
    for i = 1, #header do
        local char = header:sub(i, i)
        local char_w = renderer.measure_text("b", char)
        local gradient_factor = (i - 1) / (#header - 1)
        local cr = math.floor(255 + (ar - 255) * gradient_factor)
        local cg = math.floor(255 + (ag - 255) * gradient_factor)
        local cb = math.floor(255 + (ab - 255) * gradient_factor)
        renderer.text(text_x, text_y, cr, cg, cb, math.floor(255 * a), "b", 0, char)
        text_x = text_x + char_w
    end
    renderer.text(box_x + header_box_w - padding_x - count_w, box_y + padding_y + 1, ar, ag, ab, math.floor(255 * a), "", 0, count_text)
    if #specs > 0 then
        local content_y = box_y + header_box_h + 4
        if a > 0.15 then
            for i = 1, glow_strength, 1 do
                local glow_alpha = (a * 255 / 255) * (100 / (i * i * 0.08 + i))
                renderer.circle_outline(box_x + radius, content_y + radius, ar, ag, ab, glow_alpha, radius + i, 180, 0.25, 1)
                renderer.circle_outline(box_x + header_box_w - radius, content_y + radius, ar, ag, ab, glow_alpha, radius + i, 270, 0.25, 1)
                renderer.circle_outline(box_x + radius, content_y + content_box_h - radius, ar, ag, ab, glow_alpha, radius + i, 90, 0.25, 1)
                renderer.circle_outline(box_x + header_box_w - radius, content_y + content_box_h - radius, ar, ag, ab, glow_alpha, radius + i, 0, 0.25, 1)
                renderer.rectangle(box_x + radius, content_y - i, header_box_w - radius * 2, 1, ar, ag, ab, glow_alpha)
                renderer.rectangle(box_x + radius, content_y + content_box_h + i - 1, header_box_w - radius * 2, 1, ar, ag, ab, glow_alpha)
                renderer.rectangle(box_x - i, content_y + radius, 1, content_box_h - radius * 2, ar, ag, ab, glow_alpha)
                renderer.rectangle(box_x + header_box_w + i - 1, content_y + radius, 1, content_box_h - radius * 2, ar, ag, ab, glow_alpha)
            end
        end
        draw_rounded_rect(box_x, content_y, header_box_w, content_box_h, radius, 18, 18, 18, bg_a, 0, 0, 0, 0)
        draw_rounded_rect(box_x, content_y, header_box_w, content_box_h, radius, 0, 0, 0, 0, 255, 255, 255, math.floor(60 * a))
        local name_y = content_y + padding_y
        for i, name in ipairs(specs) do
            renderer.text(box_x + padding_x, name_y, ar, ag, ab, math.floor(255 * a), "", 0, "")
            renderer.text(box_x + padding_x + 16, name_y, 200, 200, 200, math.floor(255 * a), "", 0, name)
            name_y = name_y + item_height
        end
    end
end
local crosshair_state = {
    items = {},
    alpha = {},
    scope_offset = 0
}
local function render_crosshair()
    local me = entity.get_local_player()
    if not me or not entity.is_alive(me) then return end
    if not get_menu_value(menu.visual.crosshair_enabled) then return end
    local sx, sy = client.screen_size()
    local position_x = sx / 2
    local position_y = sy / 2 + 15
    local is_scoped = entity.get_prop(me, "m_bIsScoped") == 1
    local target_offset = is_scoped and 35 or 0
    local lerp_speed = globals.frametime() * 10
    crosshair_state.scope_offset = crosshair_state.scope_offset + (target_offset - crosshair_state.scope_offset) * lerp_speed
    position_x = position_x + crosshair_state.scope_offset
    local dt_ref = {ui.reference("RAGE", "Aimbot", "Double tap")}
    local os_ref = {ui.reference("AA", "Other", "On shot anti-aim")}
    local dmg_ref = {ui.reference("RAGE", "Aimbot", "Minimum damage override")}
    local baim_ref = ui.reference("RAGE", "Aimbot", "Force body aim")
    local dt_active = dt_ref[2] and ui.get(dt_ref[2])
    local dt_charge = 0
    if dt_active then
        local weapon = entity.get_player_weapon(me)
        if weapon then
            local next_attack = entity.get_prop(me, "m_flNextAttack") or 0
            local next_primary = entity.get_prop(weapon, "m_flNextPrimaryAttack") or 0
            local server_time = globals.curtime()
            local can_shoot = math.max(next_attack, next_primary) <= server_time
            if can_shoot then
                dt_charge = 1.0
            else
                local time_until_shoot = math.max(next_attack, next_primary) - server_time
                dt_charge = math.max(0, 1 - (time_until_shoot / 0.5))
            end
        end
    end
    local indicators = {}
    table.insert(indicators, {text = "AMGSENSE", is_title = true})
    if dt_active then
        table.insert(indicators, {text = "DT", color = {255, 255, 255, 255}, show_ring = true, charge = dt_charge})
    end
    if os_ref[1] and os_ref[2] and ui.get(os_ref[1]) and ui.get(os_ref[2]) then
        table.insert(indicators, {text = "OSAA", color = {255, 255, 255, 255}})
    end
    if dmg_ref[1] and dmg_ref[2] and ui.get(dmg_ref[1]) and ui.get(dmg_ref[2]) then
        table.insert(indicators, {text = "DMG", color = {255, 255, 255, 255}})
    end
    if baim_ref and ui.get(baim_ref) then
        table.insert(indicators, {text = "BAIM", color = {255, 255, 255, 255}})
    end
    local y_offset = 0
    local amgsense_start_x = 0
    for i, ind in ipairs(indicators) do
        if ind.is_title then
            local text = ind.text
            local text_w = renderer.measure_text("b", text)
            local start_x = position_x - text_w / 2
            amgsense_start_x = start_x
            local time = globals.realtime()
            local glow_intensity = 1.0
            local glow_pulse = (math.sin(time * 2.5) * 0.5 + 0.5) * 0.35 + 0.65
            for j = 1, #text do
                local char = text:sub(j, j)
                local char_w = renderer.measure_text("b", char)
                local color_offset = (time * 2.0 + j * 0.5) % 6.28
                local color_phase = color_offset / 6.28
                local cr, cg, cb
                if color_phase < 0.33 then
                    local t = color_phase / 0.33
                    cr = math.floor(135 + (164 - 135) * t)
                    cg = math.floor(206 + (178 - 206) * t)
                    cb = math.floor(235 + (241 - 235) * t)
                elseif color_phase < 0.66 then
                    local t = (color_phase - 0.33) / 0.33
                    cr = math.floor(164 + (255 - 164) * t)
                    cg = math.floor(178 + (200 - 178) * t)
                    cb = math.floor(241 + (255 - 241) * t)
                else
                    local t = (color_phase - 0.66) / 0.34
                    cr = math.floor(255 + (135 - 255) * t)
                    cg = math.floor(200 + (206 - 200) * t)
                    cb = math.floor(255 + (235 - 255) * t)
                end
                local brightness_pulse = (math.sin(time * 3 + j * 0.5) * 0.5 + 0.5) * 0.2 + 0.8
                cr = math.floor(cr * brightness_pulse)
                cg = math.floor(cg * brightness_pulse)
                cb = math.floor(cb * brightness_pulse)
                local glow_offset = (color_offset + 1.0) % 6.28
                local glow_phase = glow_offset / 6.28
                local glow_r, glow_g, glow_b
                if glow_phase < 0.5 then
                    local t = glow_phase / 0.5
                    glow_r = math.floor(164 + (200 - 164) * t)
                    glow_g = math.floor(178 + (220 - 178) * t)
                    glow_b = math.floor(241 + (255 - 241) * t)
                else
                    local t = (glow_phase - 0.5) / 0.5
                    glow_r = math.floor(200 + (164 - 200) * t)
                    glow_g = math.floor(220 + (178 - 220) * t)
                    glow_b = math.floor(255 + (241 - 255) * t)
                end
                for layer = 3, 1, -1 do
                    local blur_offset = layer * 1.5 * glow_intensity
                    local blur_alpha = math.floor(255 * 0.12 / layer * glow_pulse)
                    for angle = 0, 315, 45 do
                        local rad = math.rad(angle)
                        local glow_x = math.cos(rad) * blur_offset
                        local glow_y = math.sin(rad) * blur_offset
                        renderer.text(start_x + glow_x, position_y + y_offset + glow_y, glow_r, glow_g, glow_b, blur_alpha, "b", nil, char)
                    end
                end
                renderer.text(start_x + 1, position_y + y_offset + 1, 0, 0, 0, 120, "b", nil, char)
                renderer.text(start_x, position_y + y_offset, cr, cg, cb, 255, "b", nil, char)
                start_x = start_x + char_w
            end
            y_offset = y_offset + 12
        else
            local indicator_x
            if is_scoped then
                indicator_x = amgsense_start_x
            else
                local text_w = renderer.measure_text("-", ind.text)
                indicator_x = position_x - text_w / 2
            end
            if ind.show_ring and ind.charge then
                local text_w = renderer.measure_text("-", ind.text)
                local text_h = 10
                local circle_radius = 3
                local circle_gap = 3
                local circle_diameter = circle_radius * 2
                local total_width = text_w + circle_gap + circle_diameter
                local dt_x
                if is_scoped then
                    dt_x = amgsense_start_x
                else
                    dt_x = position_x - total_width / 2
                end
                renderer.text(dt_x, position_y + y_offset, ind.color[1], ind.color[2], ind.color[3], ind.color[4], "-", nil, ind.text)
                local ring_x = dt_x + text_w + circle_gap + circle_radius
                local ring_y = position_y + y_offset + text_h / 2 + 0.96
                renderer.circle_outline(ring_x, ring_y, 100, 100, 100, 150, circle_radius, 180, 1.0, 1)
                renderer.circle_outline(ring_x, ring_y, 255, 255, 255, 255, circle_radius, 180, ind.charge, 1)
            else
                renderer.text(indicator_x, position_y + y_offset, ind.color[1], ind.color[2], ind.color[3], ind.color[4], "-", nil, ind.text)
            end
            y_offset = y_offset + 11
        end
    end
end
local function render_damage_indicator()
    local me = entity.get_local_player()
    if not me or not entity.is_alive(me) then return end
    if not get_menu_value(menu.visual.damage_indicator) then return end
    local dmg_ref = {ui.reference("RAGE", "Aimbot", "Minimum damage")}
    local dmg_override_ref = {ui.reference("RAGE", "Aimbot", "Minimum damage override")}
    if not dmg_ref[1] then return end
    local sx, sy = client.screen_size()
    local position_x = sx / 2
    local position_y = sy / 2
    local damage_value = 0
    if dmg_override_ref[1] and dmg_override_ref[2] and dmg_override_ref[3] then
        local override_enabled = ui.get(dmg_override_ref[1])
        local override_hotkey = ui.get(dmg_override_ref[2])
        if override_enabled and override_hotkey then
            damage_value = ui.get(dmg_override_ref[3])
        else
            damage_value = ui.get(dmg_ref[1])
        end
    else
        damage_value = ui.get(dmg_ref[1])
    end
    local offset_x = 5
    local offset_y = -13
    renderer.text(position_x + offset_x, position_y + offset_y, 255, 255, 255, 255, nil, nil, tostring(damage_value))
end

local function render_peekbot_range()
    local me = entity.get_local_player()
    if not me or not entity.is_alive(me) then return end
    if not menu.ragebot.peekbot_enabled:get() then return end
    
    local user_range = menu.ragebot.peekbot_range:get()
    local origin = vector(entity.get_origin(me))
    
    local threat = client.current_threat()
    local threat_angle = 0
    
    if threat and not entity.is_dormant(threat) then
        local threat_origin = vector(entity.get_origin(threat))
        local _, yaw = origin:to(threat_origin):angles()
        threat_angle = math.rad(yaw)
    else
        local _, camera_yaw = client.camera_angles()
        threat_angle = math.rad(camera_yaw)
    end
    
    local segments = 32
    local arc_angle = math.pi / 4  
    
    local r, g, b = 164, 178, 241
    local alpha = 150

    local prev_x_left, prev_y_left
    for i = 0, segments do
        local t = i / segments
        local angle = threat_angle + math.pi / 2 - arc_angle / 2 + arc_angle * t
        
        local pos = vector(
            origin.x + user_range * math.cos(angle),
            origin.y + user_range * math.sin(angle),
            origin.z
        )
        
        local sx, sy = renderer.world_to_screen(pos.x, pos.y, pos.z)
        
        if sx and sy and prev_x_left and prev_y_left then
            renderer.line(prev_x_left, prev_y_left, sx, sy, r, g, b, alpha)
        end
        
        prev_x_left, prev_y_left = sx, sy
    end
    
    local prev_x_right, prev_y_right
    for i = 0, segments do
        local t = i / segments
        local angle = threat_angle - math.pi / 2 - arc_angle / 2 + arc_angle * t
        
        local pos = vector(
            origin.x + user_range * math.cos(angle),
            origin.y + user_range * math.sin(angle),
            origin.z
        )
        
        local sx, sy = renderer.world_to_screen(pos.x, pos.y, pos.z)
        
        if sx and sy and prev_x_right and prev_y_right then
            renderer.line(prev_x_right, prev_y_right, sx, sy, r, g, b, alpha)
        end
        
        prev_x_right, prev_y_right = sx, sy
    end
    
    if threat and not entity.is_dormant(threat) then
        local center_pos = vector(
            origin.x + user_range * math.cos(threat_angle),
            origin.y + user_range * math.sin(threat_angle),
            origin.z
        )
        
        local cx, cy = renderer.world_to_screen(center_pos.x, center_pos.y, center_pos.z)
        local ox, oy = renderer.world_to_screen(origin.x, origin.y, origin.z)
        
        if cx and cy and ox and oy then
            renderer.line(ox, oy, cx, cy, r, g, b, alpha * 0.5)
        end
    end
end
local hotkeys_state = {
    alpha = 0,
    drag = {active = false, ox = 0, oy = 0},
    x = database.read("amgsense_hotkeys_x") or 700,
    y = database.read("amgsense_hotkeys_y") or 800
}
local function get_active_hotkeys()
    local active = {}
    local dt_ref = {ui.reference("RAGE", "Aimbot", "Double tap")}
    local os_ref = {ui.reference("AA", "Other", "On shot anti-aim")}
    local dmg_ref = {ui.reference("RAGE", "Aimbot", "Minimum damage override")}
    local baim_ref = ui.reference("RAGE", "Aimbot", "Force body aim")
    local sp_ref = ui.reference("RAGE", "Aimbot", "Force safe point")
    local fd_ref = ui.reference("RAGE", "Other", "Duck peek assist")
    local fs_ref = menu.antiaim.freestanding
    if menu.ragebot.dormant_aimbot and menu.ragebot.dormant_aimbot:get() then
        table.insert(active, {name = "Dormant Aimbot", mode = "on"})
    end
    if dt_ref[2] and ui.get(dt_ref[2]) then
        table.insert(active, {name = "Double tap", mode = "on"})
    end
    if os_ref[2] and ui.get(os_ref[2]) then
        table.insert(active, {name = "Hide shots", mode = "on"})
    end
    if sp_ref and ui.get(sp_ref) then
        table.insert(active, {name = "Safe point", mode = "on"})
    end
    if baim_ref and ui.get(baim_ref) then
        table.insert(active, {name = "Body aim", mode = "on"})
    end
    if fd_ref and ui.get(fd_ref) then
        table.insert(active, {name = "Duck peek", mode = "on"})
    end
    if fs_ref and fs_ref:get() then
        table.insert(active, {name = "Freestanding", mode = "on"})
    end
    if dmg_ref[1] and dmg_ref[2] and ui.get(dmg_ref[1]) and ui.get(dmg_ref[2]) then
        local dmg_val = ui.get(dmg_ref[3])
        table.insert(active, {name = "Min. damage", mode = tostring(dmg_val)})
    end
    return active
end
local function render_hotkeys()
    if not get_menu_value(menu.visual.hotkeys_enabled) then
        hotkeys_state.alpha = math.max(0, hotkeys_state.alpha - globals.frametime() * 10)
        if hotkeys_state.alpha < 0.01 then return end
    else
        hotkeys_state.alpha = math.min(1, hotkeys_state.alpha + globals.frametime() * 10)
    end
    local me = entity.get_local_player()
    if not me or not entity.is_alive(me) then
        hotkeys_state.alpha = math.max(0, hotkeys_state.alpha - globals.frametime() * 10)
        if hotkeys_state.alpha < 0.01 then return end
    end
    local active_hotkeys = get_active_hotkeys()
    local current_count = #active_hotkeys
    local a = hotkeys_state.alpha
    local ar, ag, ab = get_color_value(menu.visual.hotkeys_color)
    local padding_x, padding_y = 10, 5
    local radius = 8
    local item_height = 16
    local header = "hotkeys"
    local header_w = renderer.measure_text("b", header)
    local header_h = 14
    local max_item_w = 0
    for _, item in ipairs(active_hotkeys) do
        local item_w = renderer.measure_text("", item.name)
        local mode_w = renderer.measure_text("", item.mode)
        local total_w = item_w + 16 + mode_w
        if total_w > max_item_w then max_item_w = total_w end
    end
    local header_box_w = math.max(header_w + padding_x * 2, max_item_w + padding_x * 2 + 20, 120)
    local header_box_h = header_h + padding_y * 2
    local content_padding = 8
    local content_box_h = current_count > 0 and (current_count * item_height + content_padding * 2) or 0
    local box_x = hotkeys_state.x
    local box_y = hotkeys_state.y
    local mouse_x, mouse_y = ui.mouse_position()
    if client.key_state(0x01) then
        if hotkeys_state.drag.active then
            local new_x = mouse_x - hotkeys_state.drag.ox
            local new_y = mouse_y - hotkeys_state.drag.oy
            hotkeys_state.x = new_x
            hotkeys_state.y = new_y
            database.write("amgsense_hotkeys_x", new_x)
            database.write("amgsense_hotkeys_y", new_y)
        elseif mouse_x >= box_x and mouse_x <= box_x + header_box_w and mouse_y >= box_y and mouse_y <= box_y + header_box_h then
            hotkeys_state.drag.active = true
            hotkeys_state.drag.ox = mouse_x - box_x
            hotkeys_state.drag.oy = mouse_y - box_y
        end
    else
        hotkeys_state.drag.active = false
    end
    local bg_a = math.floor(225 * a / 4)
    local glow_strength = 8
    if a > 0.15 then
        for i = 1, glow_strength, 1 do
            local glow_alpha = (a * 255 / 255) * (100 / (i * i * 0.08 + i))
            renderer.circle_outline(box_x + radius, box_y + radius, ar, ag, ab, glow_alpha, radius + i, 180, 0.25, 1)
            renderer.circle_outline(box_x + header_box_w - radius, box_y + radius, ar, ag, ab, glow_alpha, radius + i, 270, 0.25, 1)
            renderer.circle_outline(box_x + radius, box_y + header_box_h - radius, ar, ag, ab, glow_alpha, radius + i, 90, 0.25, 1)
            renderer.circle_outline(box_x + header_box_w - radius, box_y + header_box_h - radius, ar, ag, ab, glow_alpha, radius + i, 0, 0.25, 1)
            renderer.rectangle(box_x + radius, box_y - i, header_box_w - radius * 2, 1, ar, ag, ab, glow_alpha)
            renderer.rectangle(box_x + radius, box_y + header_box_h + i - 1, header_box_w - radius * 2, 1, ar, ag, ab, glow_alpha)
            renderer.rectangle(box_x - i, box_y + radius, 1, header_box_h - radius * 2, ar, ag, ab, glow_alpha)
            renderer.rectangle(box_x + header_box_w + i - 1, box_y + radius, 1, header_box_h - radius * 2, ar, ag, ab, glow_alpha)
        end
    end
    draw_rounded_rect(box_x, box_y, header_box_w, header_box_h, radius, 18, 18, 18, bg_a, 0, 0, 0, 0)
    draw_rounded_rect(box_x, box_y, header_box_w, header_box_h, radius, 0, 0, 0, 0, 255, 255, 255, math.floor(60 * a))
    local text_x = box_x + (header_box_w - header_w) / 2
    local text_y = box_y + padding_y
    for i = 1, #header do
        local char = header:sub(i, i)
        local char_w = renderer.measure_text("b", char)
        local gradient_factor = (i - 1) / (#header - 1)
        local cr = math.floor(255 + (ar - 255) * gradient_factor)
        local cg = math.floor(255 + (ag - 255) * gradient_factor)
        local cb = math.floor(255 + (ab - 255) * gradient_factor)
        renderer.text(text_x, text_y, cr, cg, cb, math.floor(255 * a), "b", 0, char)
        text_x = text_x + char_w
    end
    if current_count > 0 then
        local content_y = box_y + header_box_h + 4
        local content_padding_top = 8
        local content_padding_bottom = 5
        local actual_content_h = current_count * item_height + content_padding_top + content_padding_bottom
        if a > 0.15 then
            for i = 1, glow_strength, 1 do
                local glow_alpha = (a * 255 / 255) * (100 / (i * i * 0.08 + i))
                renderer.circle_outline(box_x + radius, content_y + radius, ar, ag, ab, glow_alpha, radius + i, 180, 0.25, 1)
                renderer.circle_outline(box_x + header_box_w - radius, content_y + radius, ar, ag, ab, glow_alpha, radius + i, 270, 0.25, 1)
                renderer.circle_outline(box_x + radius, content_y + actual_content_h - radius, ar, ag, ab, glow_alpha, radius + i, 90, 0.25, 1)
                renderer.circle_outline(box_x + header_box_w - radius, content_y + actual_content_h - radius, ar, ag, ab, glow_alpha, radius + i, 0, 0.25, 1)
                renderer.rectangle(box_x + radius, content_y - i, header_box_w - radius * 2, 1, ar, ag, ab, glow_alpha)
                renderer.rectangle(box_x + radius, content_y + actual_content_h + i - 1, header_box_w - radius * 2, 1, ar, ag, ab, glow_alpha)
                renderer.rectangle(box_x - i, content_y + radius, 1, actual_content_h - radius * 2, ar, ag, ab, glow_alpha)
                renderer.rectangle(box_x + header_box_w + i - 1, content_y + radius, 1, actual_content_h - radius * 2, ar, ag, ab, glow_alpha)
            end
        end
        draw_rounded_rect(box_x, content_y, header_box_w, actual_content_h, radius, 18, 18, 18, bg_a, 0, 0, 0, 0)
        draw_rounded_rect(box_x, content_y, header_box_w, actual_content_h, radius, 0, 0, 0, 0, 255, 255, 255, math.floor(60 * a))
        local item_y = content_y + content_padding_top
        for i, item in ipairs(active_hotkeys) do
            renderer.text(box_x + padding_x, item_y, 200, 200, 200, math.floor(255 * a), "", 0, item.name)
            local mode_w = renderer.measure_text("", item.mode)
            renderer.text(box_x + header_box_w - padding_x - mode_w, item_y, ar, ag, ab, math.floor(255 * a), "", 0, item.mode)
            item_y = item_y + item_height
        end
    end
end
client.set_event_callback('paint_ui', function()
    render_watermark()
    render_spectators()
    render_crosshair()
    render_damage_indicator()
    render_hotkeys()
    if get_menu_value(menu.visual.logs_enabled) then
        render_aimbot_logs()
    end
end)

client.set_event_callback('paint', function()
    render_peekbot_range()
end)
local e_hitgroup = {
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
local hurt_weapons = {
    ['c4'] = 'bombed',
    ['knife'] = 'knifed',
    ['decoy'] = 'decoyed',
    ['inferno'] = 'burned',
    ['molotov'] = 'harmed',
    ['flashbang'] = 'harmed',
    ['hegrenade'] = 'naded',
    ['incgrenade'] = 'harmed',
    ['smokegrenade'] = 'harmed'
}
local fire_data = {}
local screen_logs = {}
local notify_logs = {}

local function remove_hex(str)
    return string.gsub(str, '\a%x%x%x%x%x%x%x%x', '')
end

local function to_hex(r, g, b, a)
    return string.format("%02x%02x%02x%02x", math.floor(r), math.floor(g), math.floor(b), math.floor(a or 255))
end

local function from_hex(hex)
    local r = tonumber(hex:sub(1, 2), 16) or 255
    local g = tonumber(hex:sub(3, 4), 16) or 255
    local b = tonumber(hex:sub(5, 6), 16) or 255
    local a = tonumber(hex:sub(7, 8), 16) or 255
    return r, g, b, a
end

local function format_log_text(text, hex_a, hex_b)
    local result = string.gsub(text, '${(.-)}', string.format('\a%s%%1\a%s', hex_a, hex_b))
    if result:sub(1, 1) ~= '\a' then result = '\a' .. hex_b .. result end
    return result
end

local function parse_colored_text(text)
    local list, count, current_pos = {}, 0, 1
    while current_pos <= #text do
        local color_start = text:find('\a', current_pos, true)
        if not color_start then
            if current_pos <= #text then count = count + 1; list[count] = {text:sub(current_pos), nil} end
            break
        end
        if color_start > current_pos then count = count + 1; list[count] = {text:sub(current_pos, color_start - 1), nil} end
        local hex = text:sub(color_start + 1, color_start + 8)
        current_pos = color_start + 9
        local next_color = text:find('\a', current_pos, true)
        local segment_text = next_color and text:sub(current_pos, next_color - 1) or text:sub(current_pos)
        current_pos = next_color or (#text + 1)
        if segment_text ~= "" then count = count + 1; list[count] = {segment_text, hex} end
    end
    return list, count
end

local utf8_chars = utils.utf8_chars 
local draw_log_rounded_rect = utils.draw_rounded_rect 

local function has_notify_output() return menu.visual.logs_select:get("Notify") end
local function has_screen_output() return menu.visual.logs_select:get("Screen") end
local function has_console_output() return menu.visual.logs_select:get("Console") end

local function add_screen_log(r, g, b, a, text)
    local duration = get_menu_value(menu.visual.logs_duration) * 0.1
    table.insert(screen_logs, { text = remove_hex(text), color = {r, g, b, a}, time = duration, alpha = 0.0 })
end

local function add_notify_log(r, g, b, a, text)
    local pr, pg, pb, pa = get_color_value(menu.visual.logs_color_hit)
    text = '\a' .. to_hex(pr, pg, pb, pa) .. '[AMGSENSE] ' .. text
    local list, count = parse_colored_text(text)
    for i = 1, count do
        local hex = list[i][2] or to_hex(r, g, b, a)
        local cr, cg, cb, ca = from_hex(hex)
        list[i][2] = {cr, cg, cb, ca}
    end
    table.insert(notify_logs, { time = 7.0, alpha = 1.0, list = list, count = count })
    if #notify_logs > 7 then table.remove(notify_logs, 1) end
end

local function add_console_log(r, g, b, text)
    local pr, pg, pb = get_color_value(menu.visual.logs_color_hit)
    client.color_log(pr, pg, pb, '[AMGSENSE]\0 ')
    local list, count = parse_colored_text(text)
    for i = 1, count do
        local str = list[i][1] .. (i ~= count and '\0' or '')
        local hex = list[i][2]
        if hex then
            local hr, hg, hb = from_hex(hex)
            client.color_log(hr, hg, hb, str)
        else
            client.color_log(r, g, b, str)
        end
    end
end

function test_log()
    local r, g, b, a = get_color_value(menu.visual.logs_color_hit)
    local text = 'Hit ${TestPlayer} in ${head} for ${100} damage (${50} hp remaining | hc: ${85%} | bt: ${2t})'
    text = format_log_text(text, to_hex(r, g, b, a), 'c8c8c8ff')
    add_screen_log(r, g, b, a, text)
    add_notify_log(255, 255, 255, 255, text)
    add_console_log(255, 255, 255, text)
end

local function paint_notify_logs()
    local dt = globals.frametime()
    local pos_x, pos_y = 8, 5
    for i = #notify_logs, 1, -1 do
        local data = notify_logs[i]
        data.time = data.time - dt
        if data.time <= 0.0 then
            data.alpha = data.alpha - dt * 8
            if data.alpha <= 0.0 then table.remove(notify_logs, i) end
        end
    end
    for i = 1, #notify_logs do
        local data = notify_logs[i]
        local text_x = pos_x
        for j = 1, data.count do
            local text, col = data.list[j][1], data.list[j][2]
            local text_w = renderer.measure_text("", text)
            if col then
                renderer.text(text_x, pos_y, col[1], col[2], col[3], math.floor(col[4] * data.alpha), "", nil, text)
            else
                renderer.text(text_x, pos_y, 255, 255, 255, math.floor(255 * data.alpha), "", nil, text)
            end
            text_x = text_x + text_w
        end
        pos_y = pos_y + math.floor(14 * data.alpha)
    end
end

local screen_logs_style = { padding_x = 10, padding_y = 5, gap = 4, radius = 8, max_visible = 5 }

local function draw_screen_log_glow(box_x, box_y, box_w, box_h, radius, r, g, b, alpha)
    local glow_strength = 8
    if alpha > 0.15 then
        for i = 1, glow_strength do
            local glow_alpha = (alpha * 255) * (100 / (i * i * 0.08 + i)) / 255
            renderer.circle_outline(box_x + radius, box_y + radius, r, g, b, glow_alpha, radius + i, 180, 0.25, 1)
            renderer.circle_outline(box_x + box_w - radius, box_y + radius, r, g, b, glow_alpha, radius + i, 270, 0.25, 1)
            renderer.circle_outline(box_x + radius, box_y + box_h - radius, r, g, b, glow_alpha, radius + i, 90, 0.25, 1)
            renderer.circle_outline(box_x + box_w - radius, box_y + box_h - radius, r, g, b, glow_alpha, radius + i, 0, 0.25, 1)
            renderer.rectangle(box_x + radius, box_y - i, box_w - radius * 2, 1, r, g, b, glow_alpha)
            renderer.rectangle(box_x + radius, box_y + box_h + i - 1, box_w - radius * 2, 1, r, g, b, glow_alpha)
            renderer.rectangle(box_x - i, box_y + radius, 1, box_h - radius * 2, r, g, b, glow_alpha)
            renderer.rectangle(box_x + box_w + i - 1, box_y + radius, 1, box_h - radius * 2, r, g, b, glow_alpha)
        end
    end
end

local function paint_screen_logs()
    local s = screen_logs_style
    local dt = globals.frametime()
    local len = #screen_logs
    local screen_w, screen_h = client.screen_size()
    local offset = get_menu_value(menu.visual.logs_offset)
    local pos_x, pos_y = screen_w / 2, screen_h / 2 + offset
    for i = len, 1, -1 do
        local data = screen_logs[i]
        local is_life = data.time > 0 and (len - i) < s.max_visible
        if is_life then
            data.alpha = math.min(1, data.alpha + dt * 10)
            data.time = data.time - dt
        else
            data.alpha = data.alpha - dt * 8
            if data.alpha <= 0.01 then table.remove(screen_logs, i) end
        end
    end
    for i = 1, #screen_logs do
        local data = screen_logs[i]
        local r, g, b = data.color[1], data.color[2], data.color[3]
        local text, alpha = data.text, data.alpha
        if alpha >= 0.01 then
            local text_w, text_h = renderer.measure_text("", text)
            local box_w, box_h = text_w + s.padding_x * 2, text_h + s.padding_y * 2
            local box_x, box_y = pos_x - box_w / 2, pos_y - box_h / 2
            local bg_a = math.floor(225 * alpha / 4)
            draw_screen_log_glow(box_x, box_y, box_w, box_h, s.radius, r, g, b, alpha)
            draw_log_rounded_rect(box_x, box_y, box_w, box_h, s.radius, 18, 18, 18, bg_a, 0, 0, 0, 0)
            draw_log_rounded_rect(box_x, box_y, box_w, box_h, s.radius, 0, 0, 0, 0, 255, 255, 255, math.floor(60 * alpha))
            local chars = utf8_chars(text)
            local char_count = #chars
            local current_x = box_x + s.padding_x
            for j = 1, char_count do
                local char = chars[j]
                local char_w = renderer.measure_text("", char)
                local t = (j - 1) / math.max(char_count - 1, 1)
                local cr = math.floor(255 + (r - 255) * t)
                local cg = math.floor(255 + (g - 255) * t)
                local cb = math.floor(255 + (b - 255) * t)
                renderer.text(current_x, box_y + s.padding_y, cr, cg, cb, math.floor(255 * alpha), "", 0, char)
                current_x = current_x + char_w
            end
            pos_y = pos_y - math.floor((box_h + s.gap) * alpha)
        end
    end
end

local function on_aim_fire(e)
    local current_tick = globals.tickcount()
    for id, data in pairs(fire_data) do
        if current_tick - data.tick > 128 then fire_data[id] = nil end
    end
    fire_data[e.id] = { target = e.target, hitgroup = e.hitgroup, damage = e.damage, tick = current_tick }
end

local function on_aim_hit(e)
    local data = fire_data[e.id]
    if not data then return end
    fire_data[e.id] = nil
    local target = e.target
    if not target then return end
    local r, g, b, a = get_color_value(menu.visual.logs_color_hit)
    local name = entity.get_player_name(target)
    local hp = entity.get_prop(target, 'm_iHealth') or 0
    local dmg = e.damage or 0
    local hc = math.floor(e.hit_chance or 0)
    local bt = globals.tickcount() - data.tick
    local hitbox = e_hitgroup[e.hitgroup] or '?'
    local screen_text = hp == 0 
        and string.format('${kill} -> ${%s} ${%s}  ${%d} dmg | ${%d%%} | ${%dt}', name, hitbox, dmg, hc, bt)
        or string.format('${hit} -> ${%s} ${%s}  ${%d} dmg | ${%d} hp | ${%d%%} | ${%dt}', name, hitbox, dmg, hp, hc, bt)
    screen_text = format_log_text(screen_text, to_hex(r, g, b, a), 'c8c8c8ff')
    add_screen_log(r, g, b, a, screen_text)
    add_notify_log(255, 255, 255, 255, screen_text)
    add_console_log(255, 255, 255, screen_text)
end

local function on_aim_miss(e)
    local data = fire_data[e.id]
    if not data then return end
    fire_data[e.id] = nil
    local target = e.target
    if not target then return end
    local r, g, b, a = get_color_value(menu.visual.logs_color_miss)
    local name = entity.get_player_name(target)
    local reason = e.reason or '?'
    local hc = math.floor(e.hit_chance or 0)
    local bt = globals.tickcount() - data.tick
    local hitbox = e_hitgroup[data.hitgroup] or '?'
    local screen_text = string.format('${miss} -> ${%s} ${%s}  ${%s} | ${%d%%} | ${%dt}', name, hitbox, reason, hc, bt)
    screen_text = format_log_text(screen_text, to_hex(r, g, b, a), 'c8c8c8ff')
    add_screen_log(r, g, b, a, screen_text)
    add_notify_log(255, 255, 255, 255, screen_text)
    add_console_log(255, 255, 255, screen_text)
end

local function on_player_hurt(e)
    local me = entity.get_local_player()
    local attacker = client.userid_to_entindex(e.attacker)
    local victim = client.userid_to_entindex(e.userid)
    if attacker ~= me or victim == me then return end
    local action = hurt_weapons[e.weapon]
    if not action then return end
    local r, g, b, a = get_color_value(menu.visual.logs_color_hit)
    local name = entity.get_player_name(victim)
    local screen_text = string.format('${%s} | ${%s} | ${%d} dmg', name, action, e.dmg_health)
    screen_text = format_log_text(screen_text, to_hex(r, g, b, a), 'c8c8c8ff')
    add_screen_log(r, g, b, a, screen_text)
    add_notify_log(255, 255, 255, 255, screen_text)
    add_console_log(255, 255, 255, screen_text)
end

function render_aimbot_logs()
    if not get_menu_value(menu.visual.logs_enabled) then return end
    local me = entity.get_local_player()
    if not me or not entity.is_alive(me) then return end
    paint_notify_logs()
    paint_screen_logs()
end

local function init_logs()
    if not has_notify_output() and not has_screen_output() and not has_console_output() then
        menu.visual.logs_select:set({'Screen'})
    end
    local old_value = {'Screen'}
    ui.set_callback(menu.visual.logs_select.ref, function()
        local has_any = has_notify_output() or has_screen_output() or has_console_output()
        if not has_any then
            menu.visual.logs_select:set(old_value)
        else
            old_value = {}
            if has_notify_output() then table.insert(old_value, 'Notify') end
            if has_screen_output() then table.insert(old_value, 'Screen') end
            if has_console_output() then table.insert(old_value, 'Console') end
        end
    end)
    ui.set_callback(menu.visual.logs_enabled.ref, function()
        update_visual_visibility()
        if not get_menu_value(menu.visual.logs_enabled) then
            screen_logs = {}
            notify_logs = {}
        end
    end)
end

client.set_event_callback("aim_fire", on_aim_fire)
client.set_event_callback("aim_hit", function(e)
    if get_menu_value(menu.visual.logs_enabled) then on_aim_hit(e) end
end)
client.set_event_callback("aim_miss", function(e)
    if get_menu_value(menu.visual.logs_enabled) then on_aim_miss(e) end
end)
client.set_event_callback("player_hurt", function(e)
    if get_menu_value(menu.visual.logs_enabled) then on_player_hurt(e) end
end)
client.set_event_callback("round_prestart", function() fire_data = {} end)
init_logs()
local world_cache = {
    aspect_ratio = -1,
    thirdperson_distance = -1,
    viewmodel_fov = -1,
    viewmodel_x = -1,
    viewmodel_y = -1,
    viewmodel_z = -1,
    last_weapon_class = nil
}
local viewmodel_ffi = {
    classptr = ffi.typeof('void***'),
    client_entity = ffi.typeof('void*(__thiscall*)(void*, int)'),
    set_angles = nil,
    rawelist = nil,
    ientitylist = nil,
    get_client_entity = nil,
    set_angles_fn = nil
}
local function init_viewmodel_ffi()
    if viewmodel_ffi.set_angles then return true end
    local success, err = pcall(function()
        ffi.cdef('typedef struct { float x; float y; float z; } vmodel_vec3_t;')
        viewmodel_ffi.set_angles = ffi.typeof('void(__thiscall*)(void*, const vmodel_vec3_t&)')
        viewmodel_ffi.rawelist = client.create_interface('client_panorama.dll', 'VClientEntityList003')
        if not viewmodel_ffi.rawelist then error('VClientEntityList003 is nil') end
        viewmodel_ffi.ientitylist = ffi.cast(viewmodel_ffi.classptr, viewmodel_ffi.rawelist)
        if not viewmodel_ffi.ientitylist then error('ientitylist is nil') end
        viewmodel_ffi.get_client_entity = ffi.cast(viewmodel_ffi.client_entity, viewmodel_ffi.ientitylist[0][3])
        if not viewmodel_ffi.get_client_entity then error('get_client_entity is nil') end
        local set_angles_sig = client.find_signature('client_panorama.dll', '\x55\x8B\xEC\x83\xE4\xF8\x83\xEC\x64\x53\x56\x57\x8B\xF1')
        if not set_angles_sig then error('Couldn\'t find set_angles signature!') end
        viewmodel_ffi.set_angles_fn = ffi.cast(viewmodel_ffi.set_angles, set_angles_sig)
        if not viewmodel_ffi.set_angles_fn then error('Couldn\'t cast set_angles_fn') end
    end)
    return success
end
local function get_original_viewmodel()
    return {
        rhand = client.get_cvar('cl_righthand'),
        fov = client.get_cvar('viewmodel_fov'),
        x = client.get_cvar('viewmodel_offset_x'),
        y = client.get_cvar('viewmodel_offset_y'),
        z = client.get_cvar('viewmodel_offset_z')
    }
end
local function apply_viewmodel_settings()
    if not get_menu_value(menu.visual.viewmodel_enabled) then
        return
    end
    local multiplier = 0.0025
    local original = get_original_viewmodel()
    local data = {
        rhand = get_menu_value(menu.visual.knife_positioning),
        fov = get_menu_value(menu.visual.viewmodel_fov) * multiplier,
        x = get_menu_value(menu.visual.viewmodel_x) * multiplier,
        y = get_menu_value(menu.visual.viewmodel_y) * multiplier,
        z = get_menu_value(menu.visual.viewmodel_z) * multiplier
    }
    cvar.viewmodel_fov:set_raw_float(original.fov + data.fov)
    cvar.viewmodel_offset_x:set_raw_float(original.x + data.x)
    cvar.viewmodel_offset_y:set_raw_float(original.y + data.y)
    cvar.viewmodel_offset_z:set_raw_float(original.z + data.z)
    cvar.cl_righthand:set_raw_int(original.rhand)
    if data.rhand ~= "-" then
        local me = entity.get_local_player()
        local wpn = entity.get_player_weapon(me)
        local is_holding_knife = false
        if me and wpn then
            local classname = entity.get_classname(wpn) or ''
            is_holding_knife = classname:find('Knife') ~= nil
        end
        local hand_value = ({
            ["Left hand"] = is_holding_knife and 0 or 1,
            ["Right hand"] = is_holding_knife and 1 or 0,
        })[data.rhand]
        if hand_value then
            cvar.cl_righthand:set_raw_int(hand_value)
        end
    end
end
local function apply_viewmodel_roll()
    if not get_menu_value(menu.visual.viewmodel_enabled) then
        return
    end
    if not init_viewmodel_ffi() then
        return
    end
    local me = entity.get_local_player()
    if not me then return end
    local viewmodel = entity.get_prop(me, 'm_hViewModel[0]')
    if not viewmodel then return end
    local viewmodel_ent = viewmodel_ffi.get_client_entity(viewmodel_ffi.ientitylist, viewmodel)
    if not viewmodel_ent then return end
    local camera_angles = {client.camera_angles()}
    local angles = ffi.cast('vmodel_vec3_t*', ffi.new('char[?]', ffi.sizeof('vmodel_vec3_t')))
    angles.x = camera_angles[1]
    angles.y = camera_angles[2]
    angles.z = get_menu_value(menu.visual.viewmodel_roll)
    viewmodel_ffi.set_angles_fn(viewmodel_ent, angles)
end
client.set_event_callback('pre_render', apply_viewmodel_settings)
client.set_event_callback('override_view', apply_viewmodel_roll)
client.set_event_callback('paint', function()
    local enabled = get_menu_value(menu.visual.aspect_ratio_enabled)
    if not enabled then
        if world_cache.aspect_ratio ~= 0 then
            world_cache.aspect_ratio = 0
            client.set_cvar("r_aspectratio", "0")
        end
        return
    end
    local slider_value = get_menu_value(menu.visual.aspect_ratio)
    if world_cache.aspect_ratio ~= slider_value then
        world_cache.aspect_ratio = slider_value
        local screen_w, screen_h = client.screen_size()
        local multiplier = 2 - (slider_value * 0.01)
        local aspect_value = (screen_w * multiplier) / screen_h
        client.set_cvar("r_aspectratio", tostring(aspect_value))
    end
end)
client.set_event_callback('paint', function()
    local enabled = get_menu_value(menu.visual.thirdperson_collision)
    if enabled then
        cvar.cam_collision:set_int(1)
    else
        cvar.cam_collision:set_int(0)
    end
    if not enabled then
        return
    end
    local me = entity.get_local_player()
    if not me or not entity.is_alive(me) then return end
    local distance = get_menu_value(menu.visual.thirdperson_distance)
    if world_cache.thirdperson_distance ~= distance then
        world_cache.thirdperson_distance = distance
        cvar.c_mindistance:set_int(distance)
        cvar.c_maxdistance:set_int(distance)
    end
end)
local scope_state = {
    alpha = 0
}
local scope_overlay_ref = {ui.reference('Visuals', 'Effects', 'Remove scope overlay')}
local SEGMENT_SPACING = -2
local clamp = utils.clamp  
local function is_scoped()
    local me = entity.get_local_player()
    if not me or not entity.is_alive(me) then return false end
    local wpn = entity.get_player_weapon(me)
    if not wpn then return false end
    local scope_level = entity.get_prop(wpn, 'm_zoomLevel')
    if not scope_level or scope_level == 0 then return false end
    local scoped = entity.get_prop(me, 'm_bIsScoped') == 1
    local resume_zoom = entity.get_prop(me, 'm_bResumeZoom') == 1
    return scoped and not resume_zoom
end
local function draw_three_segment_gradient(x, y, w, h, color, alpha, horizontal, reverse, spacing)
    local total_length = horizontal and w or h
    local segment_length = (total_length - 2 * spacing) / 3
    local r, g, b, a = color[1], color[2], color[3], alpha * color[4]
    if horizontal then
        renderer.gradient(x, y, segment_length, h, r, g, b, 0, r, g, b, a, true)
        local x2 = x + segment_length + spacing
        local x3 = x + 2 * (segment_length + spacing)
        if not reverse then
            renderer.gradient(x2, y, segment_length, h, r, g, b, a, r, g, b, 0, true)
            renderer.gradient(x3, y, segment_length, h, r, g, b, a, r, g, b, 0, true)
        else
            renderer.gradient(x2, y, segment_length, h, r, g, b, 0, r, g, b, a, true)
            renderer.gradient(x3, y, segment_length, h, r, g, b, a, r, g, b, 0, true)
        end
    else
        renderer.gradient(x, y, w, segment_length, r, g, b, 0, r, g, b, a, false)
        local y2 = y + segment_length + spacing
        local y3 = y + 2 * (segment_length + spacing)
        if not reverse then
            renderer.gradient(x, y2, w, segment_length, r, g, b, a, r, g, b, 0, false)
            renderer.gradient(x, y3, w, segment_length, r, g, b, a, r, g, b, 0, false)
        else
            renderer.gradient(x, y2, w, segment_length, r, g, b, 0, r, g, b, a, false)
            renderer.gradient(x, y3, w, segment_length, r, g, b, a, r, g, b, 0, false)
        end
    end
end
client.set_event_callback('paint_ui', function()
    if get_menu_value(menu.visual.scope_lines) then
        ui.set(scope_overlay_ref[1], true)
    end
end)
client.set_event_callback('paint', function()
    if not get_menu_value(menu.visual.scope_lines) then
        scope_state.alpha = 0
        return
    end
    local offset = get_menu_value(menu.visual.scope_lines_offset)
    local initial_position = 0
    local fade_speed = 8
    local color = {menu.visual.scope_lines_color:get()}
    local fade_rate = globals.frametime() * fade_speed
    local width, height = client.screen_size()
    local center_x, center_y = width / 2, height / 2
    if is_scoped() then
        scope_state.alpha = clamp(scope_state.alpha + fade_rate, 0, 1)
    else
        scope_state.alpha = clamp(scope_state.alpha - fade_rate, 0, 1)
    end
    if scope_state.alpha > 0 then
        local line_length = initial_position - offset
        draw_three_segment_gradient(
            center_x - initial_position, center_y, line_length, 1,
            color, scope_state.alpha, true, false, SEGMENT_SPACING
        )
        draw_three_segment_gradient(
            center_x + offset, center_y, line_length, 1,
            color, scope_state.alpha, true, true, SEGMENT_SPACING
        )
        draw_three_segment_gradient(
            center_x, center_y - initial_position, 1, line_length,
            color, scope_state.alpha, false, false, SEGMENT_SPACING
        )
        draw_three_segment_gradient(
            center_x, center_y + offset, 1, line_length,
            color, scope_state.alpha, false, true, SEGMENT_SPACING
        )
    end
    ui.set(scope_overlay_ref[1], false)
end)
zeus_warning = {}
zeus_warning.svg = renderer.load_svg("<svg id=\"svg\" version=\"1.1\" width=\"608\" height=\"689\" xmlns=\"http://www.w3.org/2000/svg\" xmlns:xlink=\"http://www.w3.org/1999/xlink\" ><g id=\"svgg\"><path id=\"path0\" d=\"M185.803 18.945 C 184.779 19.092,182.028 23.306,174.851 35.722 C 169.580 44.841,157.064 66.513,147.038 83.882 C 109.237 149.365,100.864 163.863,93.085 177.303 C 88.686 184.901,78.772 202.072,71.053 215.461 C 63.333 228.849,53.959 245.069,50.219 251.505 C 46.480 257.941,43.421 263.491,43.421 263.837 C 43.421 264.234,69.566 264.530,114.025 264.635 L 184.628 264.803 181.217 278.618 C 179.342 286.217,174.952 304.128,171.463 318.421 C 167.974 332.714,160.115 364.836,153.999 389.803 C 147.882 414.770,142.934 435.254,143.002 435.324 C 143.127 435.452,148.286 428.934,199.343 364.145 C 215.026 344.243,230.900 324.112,234.619 319.408 C 238.337 314.704,254.449 294.276,270.423 274.013 C 286.397 253.750,303.090 232.582,307.519 226.974 C 340.870 184.745,355.263 166.399,355.263 166.117 C 355.263 165.937,323.554 165.789,284.798 165.789 C 223.368 165.789,214.380 165.667,214.701 164.831 C 215.039 163.949,222.249 151.366,243.554 114.474 C 280.604 50.317,298.192 19.768,298.267 19.444 C 298.355 19.064,188.388 18.576,185.803 18.945 \" stroke=\"none\" fill=\"#fff200\" fill-rule=\"evenodd\"></path></g></svg>", 25, 25)
function zeus_warning.get_player_weapons(idx)
    local list = {}
    for i = 0, 64 do
        local cwpn = entity.get_prop(idx, "m_hMyWeapons", i)
        if cwpn ~= nil then
            table.insert(list, cwpn)
        end
    end
    return list
end
function zeus_warning.paint()
    local me = entity.get_local_player()
    if not get_menu_value(menu.visual.zeus_warning) or zeus_warning.svg == nil or me == nil or not entity.is_alive(me) then
        return
    end
    for _, i in pairs(entity.get_players(true)) do
        local esp_data = entity.get_esp_data(i)
        if esp_data ~= nil then
            local has_taser = 0
            local x1, y1, x2, y2, a = entity.get_bounding_box(i)
            if esp_data.weapon_id == 31 then
                has_taser = 2
            end
            for _, v in pairs(zeus_warning.get_player_weapons(i)) do
                if v ~= nil and has_taser == 0 and entity.get_prop(v, "m_iItemDefinitionIndex") == 31 then
                    has_taser = 1
                end
            end
            if x1 ~= 0 and a > 0.000 and has_taser > 0 then
                local g, b = 255, 255
                if has_taser == 2 then
                    g, b = 0, 0
                end
                renderer.texture(zeus_warning.svg, x1 - 24, y1, 25, 25, 255, g, b, a * 255)
            end
        end
    end
end
client.set_event_callback('paint', zeus_warning.paint)
grenade_radius = {}
grenade_radius.smoke_duration = 17.55
grenade_radius.molotov_duration = 7
grenade_radius.fade_ticks = 15
grenade_radius.molotov_fade_ticks = 64
grenade_radius.pi2 = math.pi * 2
grenade_radius.angle = 0
grenade_radius.clamp = utils.clamp  
grenade_radius.contains = utils.table_contains  
function grenade_radius.distance(a, b)
    return utils.distance_3d(a.x, a.y, a.z, b.x, b.y, b.z) 
end
function grenade_radius.draw_smoke(radius, arc_len, start_angle, col, ent)
    local step = 50
    local end_angle = start_angle + arc_len
    local did_smoke = entity.get_prop(ent, "m_bDidSmokeEffect") == 1
    if not did_smoke then return end
    local origin = {entity.get_prop(ent, "m_vecOrigin")}
    local pos = vector(origin[1], origin[2], origin[3])
    local cx, cy = renderer.world_to_screen(pos.x, pos.y, pos.z)
    local tick_begin = entity.get_prop(ent, "m_nSmokeEffectTickBegin")
    local ticks = globals.tickcount() - tick_begin
    local time_elapsed = globals.tickinterval() * ticks
    local scale = (ticks < grenade_radius.fade_ticks and ticks or grenade_radius.fade_ticks) / grenade_radius.fade_ticks
    local fade = grenade_radius.clamp(1 - time_elapsed / grenade_radius.smoke_duration, 0, 1)
    local r = radius
    if scale ~= 1 then r = r * scale end
    for i = start_angle, end_angle, step do
        local next_i = i + step > end_angle and end_angle or i + step
        local p1 = vector(pos.x + r * math.cos(i), pos.y + r * math.sin(i))
        local p2 = vector(pos.x + r * math.cos(next_i), pos.y + r * math.sin(next_i))
        local x1, y1 = renderer.world_to_screen(p1.x, p1.y, pos.z)
        local x2, y2 = renderer.world_to_screen(p2.x, p2.y, pos.z)
        if x1 and x2 then
            local alpha = 255
            if scale ~= 1 then alpha = 255 * scale end
            if fade < 0.2 then alpha = 255 * (fade + fade * 4) end
            renderer.line(x1, y1, x2, y2, col[1], col[2], col[3], alpha)
        end
    end
    if col[4] > 1 then
        for i = 0, grenade_radius.pi2, step do
            local next_i = i + step > grenade_radius.pi2 and 0 or i + step
            local p1 = vector(pos.x + r * math.cos(i), pos.y + r * math.sin(i))
            local p2 = vector(pos.x + r * math.cos(next_i), pos.y + r * math.sin(next_i))
            local x1, y1 = renderer.world_to_screen(p1.x, p1.y, pos.z)
            local x2, y2 = renderer.world_to_screen(p2.x, p2.y, pos.z)
            if x1 and x2 and cx then
                local alpha = col[4]
                if scale ~= 1 then alpha = col[4] * scale end
                if fade < 0.2 then alpha = col[4] * (fade + fade * 4) end
                renderer.triangle(x1, y1, x2, y2, cx, cy, col[1], col[2], col[3], alpha)
            end
        end
    end
    local display = get_menu_value(menu.visual.grenade_radius_display)
    local show_bar = grenade_radius.contains(display, "Bar")
    local show_text = grenade_radius.contains(display, "Text")
    if cx and grenade_radius.smoke_duration - time_elapsed > 0 then
        local alpha_mult = 1
        if fade < 0.2 then alpha_mult = fade + fade * 4 end
        if show_bar then
            local bar_w = 26
            local bar_x = cx - bar_w / 2 + 2
            local progress = grenade_radius.clamp(1 - time_elapsed / grenade_radius.smoke_duration, 0, 1)
            renderer.rectangle(bar_x, cy + 17, bar_w, 4, 0, 0, 0, 150 * alpha_mult)
            renderer.rectangle(bar_x + 1, cy + 18, grenade_radius.clamp(bar_w * progress - 2, 0, bar_w), 2, col[1], col[2], col[3], 255)
        end
        if show_text then
            renderer.text(cx, cy + (show_bar and 25 or 20), 255, 255, 255, 200 * alpha_mult, "c-", 0, string.format("%.1f", grenade_radius.smoke_duration - time_elapsed))
        end
    end
end
function grenade_radius.draw_molotov(center, radius, arc_len, start_angle, col, ent)
    local step = 0.1
    local end_angle = start_angle + arc_len
    local tick_begin = entity.get_prop(ent, "m_nFireEffectTickBegin")
    local ticks = globals.tickcount() - tick_begin
    local time_elapsed = globals.tickinterval() * ticks
    local scale = (ticks < grenade_radius.molotov_fade_ticks and ticks or grenade_radius.molotov_fade_ticks) / grenade_radius.molotov_fade_ticks
    local fade = grenade_radius.clamp(1 - time_elapsed / grenade_radius.molotov_duration, 0, 1)
    for i = start_angle, end_angle, step do
        local next_i = i + step > end_angle and end_angle or i + step
        local p1 = vector(center.x + radius * math.cos(i), center.y + radius * math.sin(i))
        local p2 = vector(center.x + radius * math.cos(next_i), center.y + radius * math.sin(next_i))
        local x1, y1 = renderer.world_to_screen(p1.x, p1.y, center.z)
        local x2, y2 = renderer.world_to_screen(p2.x, p2.y, center.z)
        if x1 and x2 then            local alpha = 255            if scale ~= 1 then alpha = 255 * scale end
            if fade < 0.2 then alpha = 255 * (fade + fade * 4) end
            renderer.line(x1, y1, x2, y2, col[1], col[2], col[3], alpha)
        end
    end
    local cx, cy = renderer.world_to_screen(center.x, center.y, center.z)
    if col[4] > 1 then
        for i = 0, grenade_radius.pi2, step do
            local next_i = i + step > grenade_radius.pi2 and 0 or i + step
            local p1 = vector(center.x + radius * math.cos(i), center.y + radius * math.sin(i))
            local p2 = vector(center.x + radius * math.cos(next_i), center.y + radius * math.sin(next_i))
            local x1, y1 = renderer.world_to_screen(p1.x, p1.y, center.z)
            local x2, y2 = renderer.world_to_screen(p2.x, p2.y, center.z)
            if x1 and x2 and cx then
                local alpha = col[4]
                if scale ~= 1 then alpha = col[4] * scale end
                if fade < 0.2 then alpha = col[4] * (fade + fade * 4) end
                renderer.triangle(x1, y1, x2, y2, cx, cy, col[1], col[2], col[3], alpha)
            end
        end
    end
    local origin = {entity.get_prop(ent, "m_vecOrigin")}
    local origin_vec = vector(origin[1], origin[2], origin[3])
    cx, cy = renderer.world_to_screen(origin_vec.x, origin_vec.y, origin_vec.z)
    local display = get_menu_value(menu.visual.grenade_radius_display)
    local show_bar = grenade_radius.contains(display, "Bar")
    local show_text = grenade_radius.contains(display, "Text")
    if cx and grenade_radius.molotov_duration - time_elapsed > 0 then
        local alpha_mult = 1
        if fade < 0.2 then alpha_mult = fade + fade * 4 end
        if show_bar then
            local bar_w = 26
            local bar_x = cx - bar_w / 2 + 2
            local progress = grenade_radius.clamp(1 - time_elapsed / grenade_radius.molotov_duration, 0, 1)
            renderer.rectangle(bar_x, cy + 17, bar_w, 4, 0, 0, 0, 150 * alpha_mult)
            renderer.rectangle(bar_x + 1, cy + 18, grenade_radius.clamp(bar_w * progress - 2, 0, bar_w), 2, col[1], col[2], col[3], 255)
        end
        if show_text then
            renderer.text(cx, cy + (show_bar and 25 or 20), 255, 255, 255, 200 * alpha_mult, "c-", 0, string.format("%.1f", grenade_radius.molotov_duration - time_elapsed))
        end
    end
end
function grenade_radius.paint()
    if not get_menu_value(menu.visual.grenade_radius) then return end
    grenade_radius.angle = grenade_radius.angle + grenade_radius.pi2 / 1.25 * globals.frametime()
    if grenade_radius.angle > grenade_radius.pi2 then grenade_radius.angle = 0 end
    if get_menu_value(menu.visual.grenade_smoke) then
        local smoke_col = {get_color_value(menu.visual.grenade_smoke_color)}
        for _, ent in pairs(entity.get_all("CSmokeGrenadeProjectile")) do
            grenade_radius.draw_smoke(125, grenade_radius.pi2 * 0.5, grenade_radius.angle, smoke_col, ent)
        end
    end
    if get_menu_value(menu.visual.grenade_molotov) then
        local molotov_col = {get_color_value(menu.visual.grenade_molotov_color)}
        for _, ent in pairs(entity.get_all("CInferno")) do
            local origin = {entity.get_prop(ent, "m_vecOrigin")}
            local base_pos = vector(origin[1], origin[2], origin[3])
            local fire_points = {}
            for i = 1, 20 do
                local delta = vector(
                    entity.get_prop(ent, "m_fireXDelta", i),
                    entity.get_prop(ent, "m_fireYDelta", i),
                    entity.get_prop(ent, "m_fireZDelta", i)
                )
                fire_points[i] = delta + base_pos
            end
            local max_dist = 0
            local idx1, idx2 = 1, 1
            for i = 1, #fire_points do
                local p1 = fire_points[i]
                p1.z = origin[3]
                for j = 1, #fire_points do
                    local p2 = fire_points[j]
                    p2.z = origin[3]
                    local dist = grenade_radius.distance(p1, p2)
                    if dist > max_dist then
                        max_dist = dist
                        idx1, idx2 = i, j
                    end
                end
            end
            local pt1 = fire_points[idx1]
            local pt2 = fire_points[idx2]
            local center = vector((pt1.x + pt2.x) / 2, (pt1.y + pt2.y) / 2, (pt1.z + pt2.z) / 2)
            grenade_radius.draw_molotov(center, max_dist * 0.65, grenade_radius.pi2 * 0.25, grenade_radius.angle, molotov_col, ent)
        end
    end
end
client.set_event_callback('paint', grenade_radius.paint)
local autobuy_module = {}
autobuy_module.commands = {
    ["AWP"] = "buy awp", ["SCAR20/G3SG1"] = "buy scar20", ["Scout"] = "buy ssg08", ["M4/AK47"] = "buy m4a1",
    ["Famas/Galil"] = "buy famas", ["Aug/SG553"] = "buy aug", ["M249"] = "buy m249", ["Negev"] = "buy negev",
    ["Mag7/SawedOff"] = "buy mag7", ["Nova"] = "buy nova", ["XM1014"] = "buy xm1014", ["MP9/Mac10"] = "buy mp9",
    ["UMP45"] = "buy ump45", ["PPBizon"] = "buy bizon", ["MP7"] = "buy mp7",
    ["CZ75/Tec9/FiveSeven"] = "buy tec9", ["P250"] = "buy p250", ["Deagle/Revolver"] = "buy deagle", ["Dualies"] = "buy elite",
    ["HE Grenade"] = "buy hegrenade", ["Molotov"] = "buy molotov", ["Smoke"] = "buy smokegrenade", ["Flash"] = "buy flashbang", ["Decoy"] = "buy decoy",
    ["Armor"] = "buy vest", ["Helmet"] = "buy vesthelm", ["Zeus"] = "buy taser", ["Defuser"] = "buy defuser", ["Off"] = ""
}
autobuy_module.round_started = false
function autobuy_module.build_cmd()
    local cmd = ""
    local primary = get_menu_value(menu.misc.autobuy_primary)
    local secondary = get_menu_value(menu.misc.autobuy_secondary)
    local grenades = get_menu_value(menu.misc.autobuy_grenades)
    local utilities = get_menu_value(menu.misc.autobuy_utilities)
    if autobuy_module.commands[secondary] and autobuy_module.commands[secondary] ~= "" then
        cmd = cmd .. autobuy_module.commands[secondary] .. ";"
    end
    if type(utilities) == "table" then
        for _, v in ipairs(utilities) do
            if autobuy_module.commands[v] and autobuy_module.commands[v] ~= "" then
                cmd = cmd .. autobuy_module.commands[v] .. ";"
            end
        end
    end
    if autobuy_module.commands[primary] and autobuy_module.commands[primary] ~= "" then
        cmd = cmd .. autobuy_module.commands[primary] .. ";"
    end
    if type(grenades) == "table" then
        for _, v in ipairs(grenades) do
            if autobuy_module.commands[v] and autobuy_module.commands[v] ~= "" then
                cmd = cmd .. autobuy_module.commands[v] .. ";"
            end
        end
    end
    return cmd
end
function autobuy_module.on_net_update()
    if not get_menu_value(menu.misc.autobuy_enabled) or not autobuy_module.round_started then return end
    local me = entity.get_local_player()
    if not me then return end
    local cmd = autobuy_module.build_cmd()
    if cmd ~= "" then
        client.exec(cmd)
    end
    autobuy_module.round_started = false
end
function autobuy_module.on_round_prestart()
    if get_menu_value(menu.misc.autobuy_enabled) then
        autobuy_module.round_started = true
    end
end
function autobuy_module.on_player_spawn(e)
    if not get_menu_value(menu.misc.autobuy_enabled) then return end
    if not autobuy_module.round_started and not e.inrestart then
        local userid = client.userid_to_entindex(e.userid)
        if userid == entity.get_local_player() then
            autobuy_module.round_started = true
        end
    end
end
client.set_event_callback('net_update_end', autobuy_module.on_net_update)
client.set_event_callback('round_prestart', autobuy_module.on_round_prestart)
client.set_event_callback('player_spawn', autobuy_module.on_player_spawn)
local hideshots_module = {}
hideshots_module.old_weapons = { 'Auto Snipers', 'AWP', 'Scout', 'Desert Eagle', 'Pistols', 'SMG', 'Rifles' }
hideshots_module.old_states = { 'Slow', 'Crouch', 'C-Move' }
hideshots_module.cache = {
    last_update = 0,
    is_active = false,
    weapon_type = nil,
    state = nil
}
local function get_state_hideshots(cmd)
    local current_state = get_player_state(cmd)
    if current_state == "Stand" then return "Stand"
    elseif current_state == "Move" then return "Move"
    elseif current_state == "Crouch" then return "Crouch"
    elseif current_state == "C-Move" then return "C-Move"
    elseif current_state == "Air" then return "Air"
    elseif current_state == "C-Air" then return "C-Air"
    elseif current_state == "Slow" then return "Slow"
    end
    return current_state
end
local function get_weapon_type_hideshots(me)
    local weapon = entity.get_player_weapon(me)
    if not weapon then return nil end
    
    local weapon_idx = entity.get_prop(weapon, "m_iItemDefinitionIndex")
    if not weapon_idx then return nil end
    
    local weapon_data = csgo_weapons[weapon_idx]
    if not weapon_data then return nil end
    
    local weapon_type = weapon_data.type
    
    if weapon_type == "pistol" then
        if weapon_idx == 1 then
            return "Desert Eagle"
        end
        return "Pistols"
    end
    if weapon_type == "sniperrifle" then
        if weapon_idx == 9 then
            return "AWP"
        end
        if weapon_idx == 40 then
            return "Scout"
        end
        return "Auto Snipers"
    end
    if weapon_type == "smg" then
        return "SMG"
    end
    if weapon_type == "rifle" then
        return "Rifles"
    end
    return nil
end
function hideshots_module.update_values()
    ui.set(rage_refs.double_tap[1], false)
    ui.set(onshot_antiaim_ref[1], true)
    ui.set(onshot_antiaim_ref[2], "Always on")
    hideshots_module.cache.is_active = true
end
function hideshots_module.restore_values()
    ui.set(rage_refs.double_tap[1], true)
    ui.set(onshot_antiaim_ref[1], true)
    ui.set(onshot_antiaim_ref[2], "Toggle")
    hideshots_module.cache.is_active = false
end
function hideshots_module.should_update(cmd)
    local me = entity.get_local_player()
    if me == nil or not entity.is_alive(me) then
        return false
    end
    
    local dt_active = ui.get(rage_refs.double_tap[2])
    local fd_active = duck_peek_assist_ref and ui.get(duck_peek_assist_ref)
    
    if not dt_active or fd_active then
        return false
    end
    
    local weapon = entity.get_player_weapon(me)
    if not weapon then
        return false
    end
    
    local weapon_type = get_weapon_type_hideshots(me)
    if weapon_type == nil then
        return false
    end
    local selected_weapons = menu.ragebot.hideshots_weapons:get()
    local weapon_matched = false
    if type(selected_weapons) == "table" then
        for _, w in ipairs(selected_weapons) do
            if w == weapon_type then
                weapon_matched = true
                break
            end
        end
    else
        weapon_matched = selected_weapons == weapon_type
    end
    if not weapon_matched then
        return false
    end
    local current_state = get_state_hideshots(cmd)
    if current_state == nil then
        return false
    end
    local selected_states = menu.ragebot.hideshots_states:get()
    local state_matched = false
    if type(selected_states) == "table" then
        for _, s in ipairs(selected_states) do
            if s == current_state then
                state_matched = true
                break
            end
        end
    else
        state_matched = selected_states == current_state
    end
    return state_matched
end
function hideshots_module.main(cmd)
    if not get_menu_value(menu.ragebot.hideshots_enabled) then
        hideshots_module.restore_values()
        return
    end
    local me = entity.get_local_player()
    if me then
        hideshots_module.cache.weapon_type = get_weapon_type_hideshots(me)
        hideshots_module.cache.state = get_state_hideshots(cmd)
    end
    if hideshots_module.should_update(cmd) then
        hideshots_module.update_values()
        hideshots_module.cache.last_update = globals.tickcount()
    else
        if hideshots_module.cache.is_active then
            if globals.tickcount() - hideshots_module.cache.last_update > 3 then
                hideshots_module.restore_values()
            end
        else
            hideshots_module.restore_values()
        end
    end
end
client.set_event_callback('setup_command', function(cmd)
    local me = entity.get_local_player()
    if not me or not entity.is_alive(me) then return end
    hideshots_module.main(cmd)
end)
local clantag_module = {}
local clantag_last_frame = 0
local function build_clantag_frames(text)
    local frames = {}
    local text_len = #text
    for i = 1, text_len do
        frames[#frames + 1] = text:sub(1, i)
    end
    frames[#frames + 1] = text
    frames[#frames + 1] = text
    for i = text_len, 1, -1 do
        frames[#frames + 1] = text:sub(1, i)
    end
    frames[#frames + 1] = " "
    frames[#frames + 1] = " "
    return frames
end
function clantag_module.update()
    if not get_menu_value(menu.misc.clantag) then
        return
    end
    local custom_text = menu.misc.clantag_text:get()
    local clantag_text = (custom_text ~= nil and custom_text ~= "") and custom_text or "AMGSENSE"
    if not clantag_text:match("%s$") then
        clantag_text = clantag_text .. " "
    end
    local frames = build_clantag_frames(clantag_text)
    local current_frame = math.floor(globals.curtime() * 4.5)
    if clantag_last_frame ~= current_frame then
        client.set_clan_tag(frames[current_frame % #frames + 1])
    end
    clantag_last_frame = current_frame
    ui.set(ui.reference("Misc", "Miscellaneous", "Clan tag spammer"), false)
end
client.set_event_callback('net_update_end', clantag_module.update)
local chat_spam_module = {}
local chat_spam_messages = {
    "1",
}
function chat_spam_module.on_player_death(e)
    if not get_menu_value(menu.misc.chat_spammer) then
        return
    end
    local me = entity.get_local_player()
    if me == nil then
        return
    end
    local victim = client.userid_to_entindex(e.userid)
    if victim == nil or victim == me then
        return
    end
    if client.userid_to_entindex(e.attacker) ~= me then
        return
    end
    client.exec(("say %s"):format(chat_spam_messages[math.random(1, #chat_spam_messages)]))
end
client.set_event_callback('player_death', chat_spam_module.on_player_death)
client.set_event_callback('shutdown', function()
    hide_aa(true)
    hideshots_module.restore_values()
    client.set_cvar("r_aspectratio", "0")
    client.set_cvar('viewmodel_fov', '68')
    client.set_cvar('viewmodel_offset_x', '2.5')
    client.set_cvar('viewmodel_offset_y', '0')
    client.set_cvar('viewmodel_offset_z', '-1.5')
    client.set_cvar('cl_righthand', '1')
    ui.set(scope_overlay_ref[1], false)
end)
local da = {
    visible = client.visible,
    eye_position = client.eye_position,
    trace_bullet = client.trace_bullet,
    get_local_player = entity.get_local_player,
    get_player_resource = entity.get_player_resource,
    get_player_weapon = entity.get_player_weapon,
    get_prop = entity.get_prop,
    is_alive = entity.is_alive,
    get_player_name = entity.get_player_name,
    hitbox_position = entity.hitbox_position,
    tickcount = globals.tickcount,
    math_max = math.max,
    indicator = renderer.indicator,
    plist_get = plist.get,
    csgo_weapons = require("gamesense/csgo_weapons"),
    refs = {
        mindmg = ui.reference("RAGE", "Aimbot", "Minimum damage"),
        dormantEsp = ui.reference("VISUALS", "Player ESP", "Dormant"),
        override_mindmg = { ui.reference("RAGE", "Aimbot", "Minimum damage override") }
    },
    config = {
        hitboxes = {"Head", "Chest", "Stomach"},
        accuracy = 90,
        mindmg = 0,
        experimental = true,
        logs = true,
        indicator = true
    },
    hitgroup_names = {
        "generic", "head", "chest", "stomach", "left arm", "right arm", "left leg", "right leg", "neck", "?", "gear"
    },
    hitbox_map = {
        "", "Head", "Chest", "Stomach", "Chest", "Chest", "Legs", "Legs", "Head", "", ""
    },
    hitbox_offsets = {
        { scale = 5, hitbox = "Stomach", vec = vector(0, 0, 40) },
        { scale = 6, hitbox = "Chest", vec = vector(0, 0, 50) },
        { scale = 3, hitbox = "Head", vec = vector(0, 0, 58) },
        { scale = 4, hitbox = "Legs", vec = vector(0, 0, 20) }
    },
    hitbox_index_map = {
        [0] = "Head", nil, "Stomach", nil, "Stomach", "Chest", "Chest", "Legs", "Legs"
    },
    freeze_end_tick = 0,
    target_flags = {},
    last_seen = {},
    last_seen_cleanup_tick = 0,
    current_index = 1,
    fired_shot = nil,
    aim_hitbox = nil,
    aim_point = nil,
    aim_target = nil,
    aim_accuracy = nil,
    hit_confirmed = false
}
local da_can_fire_fn = vtable_thunk(166, "bool(__thiscall*)(void*)")
local da_get_spread_fn = vtable_thunk(483, "float(__thiscall*)(void*)")
local function da_get_multipoints(eye_pos, target_pos, scale)
    local pitch, yaw = eye_pos:to(target_pos):angles()
    local rad = math.rad(yaw + 90)
    local offset = vector(math.cos(rad), math.sin(rad), 0) * scale
    return {
        { text = "Middle", vec = target_pos },
        { text = "Left", vec = target_pos + offset },
        { text = "Right", vec = target_pos - offset }
    }
end
local function da_contains(arr, val)
    for i = 1, #arr do
        if arr[i] == val then return true end
    end
    return false
end
local function da_limit_speed(cmd, max_speed)
    local speed = math.sqrt(cmd.forwardmove * cmd.forwardmove + cmd.sidemove * cmd.sidemove)
    if max_speed <= 0 or speed <= 0 then return end
    if cmd.in_duck == 1 then max_speed = max_speed * 2.94117647 end
    if speed <= max_speed then return end
    local factor = max_speed / speed
    cmd.forwardmove = cmd.forwardmove * factor
    cmd.sidemove = cmd.sidemove * factor
end
local function da_get_enemies()
    local enemies = {}
    local resource = entity.get_player_resource()
    for i = 1, globals.maxplayers() do
        if da.get_prop(resource, "m_bConnected", i) == 1 and i ~= da.get_local_player() and entity.is_enemy(i) then
            enemies[#enemies + 1] = i
        end
    end
    return enemies
end
local function da_get_dormant_enemies()
    local dormant = {}
    local resource = da.get_player_resource()
    for i = 1, globals.maxplayers() do
        if da.get_prop(resource, "m_bConnected", i) == 1 and not da.plist_get(i, "Add to whitelist") then
            if entity.is_dormant(i) and entity.is_enemy(i) then
                dormant[#dormant + 1] = i
            end
        end
    end
    return dormant
end
local function da_in_list(list, ent)
    for _, v in ipairs(list) do
        if v[1] == ent then return true end
    end
    return false
end
local function da_on_setup_command(cmd)
    local hitboxes = da.config.hitboxes
    local accurate_history = {}
    local tick = da.tickcount()
    if tick - da.last_seen_cleanup_tick > 128 then
        da.last_seen_cleanup_tick = tick
        local new_last_seen = {}
        local count = 0
        for i, v in ipairs(da.last_seen) do
            if tick - v[2] < 512 and count < 64 then
                count = count + 1
                new_last_seen[count] = v
            end
        end
        da.last_seen = new_last_seen
        da.target_flags = {}
    end
    local enemies = da_get_enemies()
    for _, ent in ipairs(enemies) do
        local _, _, _, _, alpha = entity.get_bounding_box(ent)
        if alpha < 1 then
            if not da_in_list(da.last_seen, ent) and #da.last_seen < 64 then
                da.last_seen[#da.last_seen + 1] = { ent, tick }
            end
        elseif da_in_list(da.last_seen, ent) then
            for i = #da.last_seen, 1, -1 do
                if da.last_seen[i][1] == ent then
                    table.remove(da.last_seen, i)
                    break
                end
            end
        end
    end
    if not menu.ragebot.dormant_aimbot:get() then return end
    local me = da.get_local_player()
    local weapon = da.get_player_weapon(me)
    if not weapon then return end
    local weapon_ptr = native.GetClientEntity(weapon)
    if not weapon_ptr then return end
    if not da_can_fire_fn(weapon_ptr) then return end
    local spread = da_get_spread_fn(weapon_ptr)
    if not spread then return end
    local eye_pos = vector(da.eye_position())
    local sim_time = da.get_prop(me, "m_flSimulationTime")
    local tick = da.tickcount()
    local weapon_info = da.csgo_weapons(weapon)
    local is_scoped = da.get_prop(me, "m_bIsScoped") == 1
    local on_ground = bit.band(da.get_prop(me, "m_fFlags"), bit.lshift(1, 0))
    local dormant_enemies = da_get_dormant_enemies()
    if #dormant_enemies == 0 then
        da.target_flags = {}
        da.current_index = 1
        return
    end
    if da.current_index > #dormant_enemies then
        da.current_index = 1
    elseif tick % #dormant_enemies ~= 0 then
        da.current_index = ((da.current_index) % #dormant_enemies) + 1
    end
    local target = dormant_enemies[da.current_index]
    if not target then
        da.target_flags = {}
        return
    end
    if tick < da.freeze_end_tick then
        da.target_flags = {}
        return
    end
    if weapon_info.type == "grenade" or weapon_info.type == "knife" then
        da.target_flags = {}
        return
    end
    if cmd.in_jump == 1 and on_ground == 0 then
        da.target_flags = {}
        return
    end
    local target_hitboxes = {}
    local accuracy_threshold = da.config.accuracy
    local target_health = entity.get_esp_data(target).health
    local override_active = ui.get(da.refs.override_mindmg[1]) and ui.get(da.refs.override_mindmg[2])
    local min_damage
    if da.config.mindmg == 0 and not override_active then
        min_damage = ui.get(da.refs.mindmg)
    elseif da.config.mindmg == 0 and override_active then
        min_damage = ui.get(da.refs.override_mindmg[3])
    else
        min_damage = da.config.mindmg
    end
    if min_damage > 100 then
        min_damage = min_damage - 100 + target_health
    end
    local duck_amount = da.get_prop(target, "m_flDuckAmount")
    for _, hb in ipairs(da.hitbox_offsets) do
        if #hitboxes ~= 0 then
            if da_contains(hitboxes, hb.hitbox) then
                local adjusted_vec = hb.vec
                if hb.hitbox == "Head" then
                    adjusted_vec = hb.vec - vector(0, 0, duck_amount * 10)
                elseif hb.hitbox == "Chest" then
                    adjusted_vec = hb.vec - vector(0, 0, duck_amount * 4)
                end
                table.insert(target_hitboxes, { vec = adjusted_vec, scale = hb.scale, hitbox = hb.hitbox })
            end
        else
            table.insert(target_hitboxes, 1, { vec = hb.vec, scale = hb.scale, hitbox = hb.hitbox })
        end
    end
    local can_attack
    if weapon_info.is_revolver then
        can_attack = sim_time > da.get_prop(weapon, "m_flNextPrimaryAttack")
    else
        can_attack = sim_time > da.math_max(
            da.get_prop(me, "m_flNextAttack"),
            da.get_prop(weapon, "m_flNextPrimaryAttack"),
            da.get_prop(weapon, "m_flNextSecondaryAttack")
        )
    end
    if not can_attack then return end
    local origin = vector(entity.get_origin(target))
    local hitbox_pos = vector(da.hitbox_position(target, 4))
    local _, _, _, _, bbox_alpha = entity.get_bounding_box(target)
    da.target_flags[target] = nil
    for i = 1, 7 do
        if #hitboxes ~= 0 and da_contains(hitboxes, da.hitbox_index_map[i - 1]) and da.is_alive(target) and bbox_alpha > 0 and math.abs(origin.x - hitbox_pos.x) < 7 then
            local hb_pos = vector(da.hitbox_position(target, i - 1))
            if hb_pos and hb_pos.x then
                accurate_history[#accurate_history + 1] = {
                    scale = 3,
                    hitbox = da.hitbox_index_map[i - 1],
                    vec = hb_pos
                }
            end
            if #accurate_history >= 21 then break end
        end
    end
    if origin.x and bbox_alpha > 0 then
        local best_pos, best_damage, best_hitbox
        if da.config.experimental then
            for _, hb in ipairs(accurate_history) do
                local points = da_get_multipoints(eye_pos, hb.vec, 3)
                for _, pt in ipairs(points) do
                    local pos = pt.vec
                    local _, damage = client.trace_bullet(me, eye_pos.x, eye_pos.y, eye_pos.z, pos.x, pos.y, pos.z, true)
                    if hb.hitbox == "Head" then damage = damage * 4 end
                    if damage ~= 0 and min_damage < damage then
                        best_pos = pos
                        best_damage = damage
                        best_hitbox = hb.hitbox
                        break
                    end
                end
            end
        end
        if not (accuracy_threshold < math.floor(bbox_alpha * 100) + 5) then return end
        local aim_pos, aim_damage
        if best_damage ~= nil then
            aim_pos = best_pos
            aim_damage = best_damage
            da.aim_hitbox = best_hitbox
            da.aim_point = nil
            da.aim_target = target
            da.aim_accuracy = bbox_alpha
        else
            for _, hb in ipairs(target_hitboxes) do
                local target_pos = origin + hb.vec
                local points = da_get_multipoints(eye_pos, target_pos, hb.scale)
                for _, pt in ipairs(points) do
                    local pos = pt.vec
                    local _, damage = da.trace_bullet(me, eye_pos.x, eye_pos.y, eye_pos.z, pos.x, pos.y, pos.z, true)
                    if damage ~= 0 and min_damage < damage then
                        aim_pos = pos
                        aim_damage = damage
                        da.aim_hitbox = hb.hitbox
                        da.aim_point = pt.text
                        da.aim_target = target
                        da.aim_accuracy = bbox_alpha
                        break
                    end
                end
                if aim_pos and aim_damage then break end
            end
        end
        if not aim_damage then return end
        if not aim_pos then return end
        if da.visible(aim_pos.x, aim_pos.y, aim_pos.z) then return end
        da_limit_speed(cmd, (is_scoped and weapon_info.max_player_speed_alt or weapon_info.max_player_speed) * 0.33)
        local pitch, yaw = eye_pos:to(aim_pos):angles()
        if not is_scoped and weapon_info.type == "sniperrifle" and cmd.in_jump == 0 and on_ground == 1 then
            cmd.in_attack2 = 1
        end
        da.target_flags[target] = true
        if spread < 0.01 then
            cmd.pitch = pitch
            cmd.yaw = yaw
            cmd.in_attack = 1
            da.fired_shot = true
        end
    end
end
client.register_esp_flag("DA", 255, 255, 255, function(ent)
    if menu.ragebot.dormant_aimbot:get() and da.is_alive(da.get_local_player()) then
        return da.target_flags[ent]
    end
end)
client.set_event_callback("weapon_fire", function(e)
    client.delay_call(0.03, function()
        local me = da.get_local_player()
        if client.userid_to_entindex(e.userid) == me then
            if da.fired_shot and not da.hit_confirmed then
                client.fire_event("dormant_miss", {
                    userid = da.aim_target,
                    aim_hitbox = da.aim_hitbox,
                    aim_point = da.aim_point,
                    accuracy = da.aim_accuracy
                })
            end
            da.hit_confirmed = false
            da.fired_shot = false
            da.aim_hitbox = nil
            da.aim_point = nil
            da.aim_target = nil
            da.aim_accuracy = nil
        end
    end)
end)
local function da_on_player_hurt(e)
    local victim = client.userid_to_entindex(e.userid)
    local attacker = client.userid_to_entindex(e.attacker)
    local _, _, _, _, bbox_alpha = entity.get_bounding_box(victim)
    if attacker == da.get_local_player() and victim ~= nil and da.fired_shot == true then
        da.hit_confirmed = true
        client.fire_event("dormant_hit", {
            userid = victim,
            attacker = attacker,
            health = e.health,
            armor = e.armor,
            weapon = e.weapon,
            dmg_health = e.dmg_health,
            dmg_armor = e.dmg_armor,
            hitgroup = e.hitgroup,
            accuracy = bbox_alpha,
            aim_hitbox = da.aim_hitbox
        })
    end
end
local function da_on_round_prestart()
    local freeze_time = (cvar.mp_freezetime:get_float() + 1) / globals.tickinterval()
    da.freeze_end_tick = da.tickcount() + freeze_time
    da.last_seen = {}
    da.target_flags = {}
end
client.set_event_callback("dormant_hit", function(e)
end)
client.set_event_callback("dormant_miss", function(e)
end)
client.set_event_callback("setup_command", da_on_setup_command)
client.set_event_callback("round_prestart", da_on_round_prestart)
client.set_event_callback("player_hurt", da_on_player_hurt)
ui.set(da.refs.dormantEsp, true)-- dumped from hrisito forums by <youtube.com/@subtick> ~ rip hrisito 2025-2026
