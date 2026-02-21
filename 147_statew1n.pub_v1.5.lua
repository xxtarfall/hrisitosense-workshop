-- Title: StateW1n.pub v1.5
-- Script ID: 147
-- Source: page_147.html
----------------------------------------

local vector = require 'vector'
local c_entity = require 'gamesense/entity'
local http = require 'gamesense/http'
local base64 = require 'gamesense/base64'
local clipboard = require 'gamesense/clipboard'
local steamworks = require 'gamesense/steamworks'

local function open_url(url)
    client.exec("start " .. url)
    client.log("[StateW1n] Opening: " .. url)
    return true
end

local client_set_event_callback, client_unset_event_callback = client.set_event_callback, client.unset_event_callback
local entity_get_local_player, entity_get_player_weapon, entity_get_prop = entity.get_local_player, entity.get_player_weapon, entity.get_prop
local ui_get, ui_set, ui_set_callback, ui_set_visible, ui_reference, ui_new_checkbox, ui_new_slider = ui.get, ui.set, ui.set_callback, ui.set_visible, ui.reference, ui.new_checkbox, ui.new_slider

local reference = {

    double_tap = {ui.reference('RAGE', 'Aimbot', 'Double tap')},
    duck_peek_assist = ui.reference('RAGE', 'Other', 'Duck peek assist'),
    pitch = {ui.reference('AA', 'Anti-aimbot angles', 'Pitch')},
    yaw_base = ui.reference('AA', 'Anti-aimbot angles', 'Yaw base'),
    yaw = {ui.reference('AA', 'Anti-aimbot angles', 'Yaw')},
    yaw_jitter = {ui.reference('AA', 'Anti-aimbot angles', 'Yaw jitter')},
    body_yaw = {ui.reference('AA', 'Anti-aimbot angles', 'Body yaw')},
    freestanding_body_yaw = ui.reference('AA', 'Anti-aimbot angles', 'Freestanding body yaw'),
    edge_yaw = ui.reference('AA', 'Anti-aimbot angles', 'Edge yaw'),
    freestanding = {ui.reference('AA', 'Anti-aimbot angles', 'Freestanding')},
    roll = ui.reference('AA', 'Anti-aimbot angles', 'Roll'),
    on_shot_anti_aim = {ui.reference('AA', 'Other', 'On shot anti-aim')},
    slow_motion = {ui.reference('AA', 'Other', 'Slow motion')},
    fakelag_limit = ui.reference('AA', 'Fake lag', 'Limit')
}

local startup_animation = {
    start_time = nil,
    duration = 3.0,  -- Длительность всей анимации в секундах
    fade_in_duration = 1,  -- Длительность затемнения
    stay_duration = 2.0,  -- Длительность темного экрана
    fade_out_duration = 1,  -- Длительность осветления
    completed = false  -- Флаг завершения анимации
}

-- Функция для запуска анимации
local function start_startup_animation()
    startup_animation.start_time = globals.realtime()
    startup_animation.completed = false
end

-- Функция для отрисовки анимации
local function draw_startup_animation()
    if startup_animation.start_time == nil or startup_animation.completed then 
        return 
    end
    
    local current_time = globals.realtime()
    local elapsed = current_time - startup_animation.start_time
    
    -- Если анимация завершена
    if elapsed >= startup_animation.duration then
        startup_animation.completed = true
        startup_animation.start_time = nil
        return
    end
    
    local screen_width, screen_height = client.screen_size()
    local alpha = 0
    
    if elapsed < startup_animation.fade_in_duration then
        -- Фаза затемнения
        alpha = math.floor(255 * (elapsed / startup_animation.fade_in_duration))
    elseif elapsed < startup_animation.fade_in_duration + startup_animation.stay_duration then
        -- Фаза темного экрана
        alpha = 255
    else
        -- Фаза осветления
        local fade_out_elapsed = elapsed - (startup_animation.fade_in_duration + startup_animation.stay_duration)
        alpha = math.floor(255 * (1 - (fade_out_elapsed / startup_animation.fade_out_duration)))
    end
    
    -- Рисуем черный полупрозрачный прямоугольник на весь экран
    renderer.rectangle(0, 0, screen_width, screen_height, 0, 0, 0, alpha)
    
    -- Можно добавить текст поверх
    if alpha > 100 then
        local text = "StateW1n.pub \ae67e22ffV1.5"
        local text_width = renderer.measure_text("", text)
        local x = (screen_width - text_width) * 0.52
        local y = screen_height * 0.49
        
        -- Текст
        renderer.text(x, y, 52, 152, 219, alpha, "c+", 0, text)
        
        -- Дополнительный текст
        local sub_text = "\aff0000ffTHANKS FOR USE STATEW1N!! @statew1n"
        local sub_text_width = renderer.measure_text("", sub_text)
        local sub_x = (screen_width - sub_text_width) * 0.54
        local sub_y = y + 500
        renderer.text(sub_x, y + 20, 255, 255, 255, alpha, "c+", 0, sub_text)
    end
end

-- Запускаем анимацию при загрузке луа
start_startup_animation()

-- Добавляем в существующую функцию paint
client.set_event_callback('paint', function()
    -- Рисуем анимацию запуска (если активна) независимо от того, в меню или в катке
    draw_startup_animation()
end)

-- Альтернативный вариант: проверка, находимся ли мы в меню
client.set_event_callback('paint', function()
    local local_player = entity.get_local_player()
    
    -- Если мы не в игре (local_player == nil) или находимся в меню, показываем анимацию
    if local_player == nil or not entity.is_alive(local_player) then
        draw_startup_animation()
    else	
        -- Если в катке, тоже можно показывать анимацию или сделать отдельную логику
        draw_startup_animation()
    end
end)

-- Или самый простой вариант - всегда показывать анимацию, пока она не завершится
client.set_event_callback('paint', function()
    draw_startup_animation()
end)


local globals_frametime = globals.frametime
local globals_tickinterval = globals.tickinterval
local entity_is_enemy = entity.is_enemy
local entity_is_dormant = entity.is_dormant
local entity_is_alive = entity.is_alive
local entity_get_origin = entity.get_origin
local entity_get_player_resource = entity.get_player_resource
local table_insert = table.insert
local math_floor = math.floor

local last_press = 0
local direction = 0
local anti_aim_on_use_direction = 0
local cheked_ticks = 0

local E_POSE_PARAMETERS = {
    STRAFE_YAW = 0,
    STAND = 1,
    LEAN_YAW = 2,
    SPEED = 3,
    LADDER_YAW = 4,
    LADDER_SPEED = 5,
    JUMP_FALL = 6,
    MOVE_YAW = 7,
    MOVE_BLEND_CROUCH = 8,
    MOVE_BLEND_WALK = 9,
    MOVE_BLEND_RUN = 10,
    BODY_YAW = 11,
    BODY_PITCH = 12,
    AIM_BLEND_STAND_IDLE = 13,
    AIM_BLEND_STAND_WALK = 14,
    AIM_BLEND_STAND_RUN = 14,
    AIM_BLEND_CROUCH_IDLE = 16,
    AIM_BLEND_CROUCH_WALK = 17,
    DEATH_YAW = 18
}

local function contains(source, target)
	for id, name in pairs(ui.get(source)) do
		if name == target then
			return true
		end
	end

	return false
end

local function is_defensive(index)
    cheked_ticks = math.max(entity.get_prop(index, 'm_nTickBase'), cheked_ticks or 0)

    return math.abs(entity.get_prop(index, 'm_nTickBase') - cheked_ticks) > 2 and math.abs(entity.get_prop(index, 'm_nTickBase') - cheked_ticks) < 14
end

local settings = {}
local anti_aim_settings = {}
local anti_aim_states = {'Global', 'Standing', 'Moving', 'Slow motion', 'Crouching', 'Crouching & moving', 'In air', 'In air & crouching', 'No exploits', 'On use'}
local anti_aim_different = {'', ' ', '  ', '   ', '    ', '     ', '      ', '       ', '        ', '         '}

-- Добавлена вкладка Rage
current_tab = ui.new_combobox('AA', 'Anti-aimbot angles', 'Tabs', {'Home', 'Rage', 'Anti-Aim', 'Misc/Vis'})
local text1 = ui.new_label('AA', 'Anti-aimbot angles', '\a4169e1ff✦StateW1n.pub \bBeta✦ ~ \a3498dbff⇘Version 1.5⇙', 'string')
local text2 = ui.new_label('AA', 'Anti-aimbot angles', '\a1abc9cfflast update ~ 7.11.2025', 'string')
local text3 = ui.new_label('AA', 'Anti-aimbot angles', '\affff00ffif you find a bug, write to Offical Telegram', 'string')
local text4 = ui.new_label('AA', 'Anti-aimbot angles', '\a9b59b6ff✟hrisitosense.top is best crack skeet❤', 'string')
local text5 = ui.new_label('AA', 'Anti-aimbot angles', '\a9b59b6ffCreators: ✿dafer1337✿ ♱ oexxeu ♱', 'string')
local telegram_btn = ui.new_button('AA', 'Anti-aimbot angles', ' Official Telegram', function()
    panorama.open('CSGOHud').SteamOverlayAPI.OpenExternalBrowserURL('https://t.me/statew1n')
    end)
	
settings.anti_aim_state = ui.new_combobox('AA', 'Anti-aimbot angles', 'Anti-aimbot state', anti_aim_states)

local master_switch = ui.new_checkbox('AA', 'Anti-aimbot angles', '↔ Log Aimbot Shots(in console)')
local console_filter = ui.new_checkbox('AA', 'Anti-aimbot angles', '✘ Console Filter')
local anim_breakerx = ui.new_checkbox('AA', 'Anti-aimbot angles', '⍟ Animation Breaker')
local force_safe_point = ui.reference('RAGE', 'Aimbot', 'Force safe point')

local trashtalk = ui.new_checkbox('AA', 'Anti-aimbot angles', '▷ Trash Talk')
local watermark = ui.new_checkbox('AA', 'Anti-aimbot angles', '✤ Watermark')
local clantagchanger = ui.new_checkbox('AA', 'Anti-aimbot angles', '♫ Clan Tag')
local fastladder = ui.new_checkbox('AA', 'Anti-aimbot angles', '↑Fast Ladder')
local hitmarker = ui.new_checkbox('AA', 'Anti-aimbot angles', '♯ 3D Hit Marker')

local ai_resolver = ui.new_checkbox('AA', 'Anti-aimbot angles', '\a2ecc71ff● AI Resolver')
local resolver_mode = ui.new_combobox('AA', 'Anti-aimbot angles', '\a2ecc71ffResolver Mode', {'∆Auto∆', '►Force Brute◄', '★Smart Predict★'})
local resolver_strength = ui.new_slider('AA', 'Anti-aimbot angles', '\a2ecc71ffResolver Strength', 0, 100, 75, true, '%')
local before_resolver = ui.new_label('AA', 'Anti-aimbot angles', '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━')

local no_spread = ui.new_checkbox('AA', 'Anti-aimbot angles', '\aff0000ff◆ No Spread ✘Experemental✘')
local no_spread_mode = ui.new_combobox('AA', 'Anti-aimbot angles', '\aff0000ffNo Spread Mode', {'◕Default◕', '✔Advanced✔', 'Prediction ✘Experemental✘'})
local no_spread_strength = ui.new_slider('AA', 'Anti-aimbot angles', '\aff0000ffNo Spread Strength', 0, 100, 75, true, '%')
local before_spread = ui.new_label('AA', 'Anti-aimbot angles', '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━')

local dt_enabled = ui.new_checkbox('AA', 'Anti-aimbot angles', '\aFFA500ff★ Better/Custom Double-Tap★')
local dt_enhanced_mode = ui.new_combobox('AA', 'Anti-aimbot angles', '\aFFA500ffDT Mode', {'Default', 'Fast', 'Safe', 'Custom'})
local dt_adaptive_ticks = ui.new_checkbox('AA', 'Anti-aimbot angles', '\af9e79ff Adaptive Ticks')
local dt_break_lagcomp = ui.new_checkbox('AA', 'Anti-aimbot angles', '\a808000ffBreak Lag Compensation')
local dt_custom_ticks = ui.new_slider('AA', 'Anti-aimbot angles', '\a00ff00ffDT Custom Ticks', 1, 16, 14, true, "ticks")
local before_dt = ui.new_label('AA', 'Anti-aimbot angles', '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━')

local cover_awareness = ui.new_checkbox('AA', 'Anti-aimbot angles', '\a1abc9cff ✪ Cover Awareness')
local cover_adaptive_aa = ui.new_checkbox('AA', 'Anti-aimbot angles', 'Adaptive AA in Cover')
local before_cover = ui.new_label('AA', 'Anti-aimbot angles', '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━')

local backtrack_exploit = ui.new_checkbox('AA', 'Anti-aimbot angles', '\a9b59b6ff ☯ Enhanced Backtrack exploit')
local backtrack_mode = ui.new_combobox('AA', 'Anti-aimbot angles', 'Backtrack Mode', {'Default', 'Aggressive', 'Smart', 'On Peek'})
local backtrack_ticks = ui.new_slider('AA', 'Anti-aimbot angles', 'Backtrack Ticks', 1, 14, 12, true, 'ticks')
local backtrack_adaptive = ui.new_checkbox('AA', 'Anti-aimbot angles', 'Adaptive Backtrack')
local backtrack_visualize = ui.new_checkbox('AA', 'Anti-aimbot angles', 'Visualize Backtrack')
local before_backtrack = ui.new_label('AA', 'Anti-aimbot angles', '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━')

local prediction_enemy = ui.new_checkbox('AA', 'Anti-aimbot angles', '\aFF69B4ff ⚠ Prediction Enemy')
local prediction_mode = ui.new_combobox('AA', 'Anti-aimbot angles', 'Prediction Mode', {'Linear', 'Quadratic', 'Adaptive', 'Neural'})
local prediction_strength = ui.new_slider('AA', 'Anti-aimbot angles', 'Prediction Strength', 0, 100, 75, true, '%')
local prediction_visualize = ui.new_checkbox('AA', 'Anti-aimbot angles', 'Visualize Prediction')
local before_prediction = ui.new_label('AA', 'Anti-aimbot angles', '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━')
-- Переменные состояния
local cover_state = {
    in_cover = false,
    last_check = 0,
    cover_timer = 0
}

local backtrack_players = {}



-- Переменные состояния DT
local dt_state = {
    active = false,
    last_shot = 0,
    recharge_time = 0,
    was_charged = false
}

local last_shot_time = 0

local aspectratio = ui.new_slider('AA', 'Anti-aimbot angles', '\a2ecc71ff↔Aspect Ratio↔', 0, 200, 0, true, nil, 0.01, {[0] = "Off"})

local buybot_enabled = ui.new_checkbox('AA', 'Anti-aimbot angles', '$ AutoBuy')
local buybot_primary = ui.new_combobox('AA', 'Anti-aimbot angles', 'Primary Weapon', {'None', 'FAMAS/GALIL', 'M4A4/AK-47', 'AWP', 'SSG-08', 'Auto Sniper'})
local buybot_secondary = ui.new_combobox('AA', 'Anti-aimbot angles', 'Secondary Weapon', {'None', 'Deagle', 'Dual Berettas', 'Five-Seven/Tec-9', 'P250'})
local buybot_equipment = ui.new_multiselect('AA', 'Anti-aimbot angles', 'Equipment', {'Kevlar+Helmet', 'Defuse Kit', 'HE Grenade', 'Flashbang', 'Smoke', 'Molotov'})
local buybot_auto_buy = ui.new_checkbox('AA', 'Anti-aimbot angles', 'Auto Buy Each Round')
local buybot_key = ui.new_hotkey('AA', 'Anti-aimbot angles', 'BuyBot Key', true)

for i = 1, #anti_aim_states do
    anti_aim_settings[i] = {
        override_state = ui.new_checkbox('AA', 'Anti-aimbot angles', 'Override ' .. string.lower(anti_aim_states[i])),
        pitch1 = ui.new_combobox('AA', 'Anti-aimbot angles', 'Pitch' .. anti_aim_different[i], 'Off', 'Default', 'Up', 'Down', 'Minimal', 'Random', 'Custom'),
        pitch2 = ui.new_slider('AA', 'Anti-aimbot angles', '\nPitch' .. anti_aim_different[i], -89, 89, 0, true, '°'),
        yaw_base = ui.new_combobox('AA', 'Anti-aimbot angles', 'Yaw base' .. anti_aim_different[i], 'Local view', 'At targets'),
        yaw1 = ui.new_combobox('AA', 'Anti-aimbot angles', 'Yaw' .. anti_aim_different[i], 'Off', '180', 'Spin', 'Static', '180 Z', 'Crosshair'),
        yaw2_left = ui.new_slider('AA', 'Anti-aimbot angles', 'Yaw left' .. anti_aim_different[i], -180, 180, 0, true, '°'),
        yaw2_right = ui.new_slider('AA', 'Anti-aimbot angles', 'Yaw right' .. anti_aim_different[i], -180, 180, 0, true, '°'),
        yaw2_randomize = ui.new_slider('AA', 'Anti-aimbot angles', 'Yaw randomize' .. anti_aim_different[i], 0, 180, 0, true, '°'),
        yaw_jitter1 = ui.new_combobox('AA', 'Anti-aimbot angles', 'Yaw jitter' .. anti_aim_different[i], 'Off', 'Offset', 'Center', 'Random', 'Skitter', 'Delay'),
        yaw_jitter2_left = ui.new_slider('AA', 'Anti-aimbot angles', 'Yaw jitter left' .. anti_aim_different[i], -180, 180, 0, true, '°'),
        yaw_jitter2_right = ui.new_slider('AA', 'Anti-aimbot angles', 'Yaw jitter right' .. anti_aim_different[i], -180, 180, 0, true, '°'),
        yaw_jitter2_randomize = ui.new_slider('AA', 'Anti-aimbot angles', 'Yaw jitter randomize' .. anti_aim_different[i], 0, 180, 0, true, '°'),
        yaw_jitter2_delay = ui.new_slider('AA', 'Anti-aimbot angles', 'Yaw jitter delay' .. anti_aim_different[i], 2, 10, 2, true, 't'),
        body_yaw1 = ui.new_combobox('AA', 'Anti-aimbot angles', 'Body yaw' .. anti_aim_different[i], 'Off', 'Opposite', 'Jitter', 'Static'),
        body_yaw2 = ui.new_slider('AA', 'Anti-aimbot angles', 'Body Yaw' .. anti_aim_different[i], -180, 180, 0, true, '°'),
        freestanding_body_yaw = ui.new_checkbox('AA', 'Anti-aimbot angles', 'Freestanding body yaw' .. anti_aim_different[i]),
        roll = ui.new_slider('AA', 'Anti-aimbot angles', 'Roll' .. anti_aim_different[i], -45, 45, 0, true, '°'),
        force_defensive = ui.new_checkbox('AA', 'Anti-aimbot angles', 'Force defensive' .. anti_aim_different[i]),
        defensive_anti_aimbot = ui.new_checkbox('AA', 'Anti-aimbot angles', '\a3498dbff✥ Defensive AA' .. anti_aim_different[i]),
        defensive_pitch = ui.new_checkbox('AA', 'Anti-aimbot angles', '\a3498dbff· Pitch' .. anti_aim_different[i]),
        defensive_pitch1 = ui.new_combobox('AA', 'Anti-aimbot angles', '\n· Pitch 2' .. anti_aim_different[i], 'Off', 'Default', 'Up', 'Down', 'Minimal', 'Random', 'Custom'),
        defensive_pitch2 = ui.new_slider('AA', 'Anti-aimbot angles', '\n· Pitch 3' .. anti_aim_different[i], -89, 89, 0, true, '°'),
        defensive_pitch3 = ui.new_slider('AA', 'Anti-aimbot angles', '\n· Pitch 4' .. anti_aim_different[i], -89, 89, 0, true, '°'),
        defensive_yaw = ui.new_checkbox('AA', 'Anti-aimbot angles', '\a3498dbff· Yaw' .. anti_aim_different[i]),
        defensive_yaw1 = ui.new_combobox('AA', 'Anti-aimbot angles', '· Yaw 1' .. anti_aim_different[i], '180', 'Spin', '180 Z', 'Sideways', 'Random'),
        defensive_yaw2 = ui.new_slider('AA', 'Anti-aimbot angles', '· Yaw 2' .. anti_aim_different[i], -180, 180, 0, true, '°')
    }
end

settings.avoid_backstab = ui.new_checkbox('AA', 'Anti-aimbot angles', 'Avoid backstab')
settings.safe_head_in_air = ui.new_checkbox('AA', 'Anti-aimbot angles', 'Safe head in air')
settings.manual_forward = ui.new_hotkey('AA', 'Anti-aimbot angles', 'Manual forward')
settings.manual_right = ui.new_hotkey('AA', 'Anti-aimbot angles', 'Manual right')
settings.manual_left = ui.new_hotkey('AA', 'Anti-aimbot angles', 'Manual left')
settings.edge_yaw = ui.new_hotkey('AA', 'Anti-aimbot angles', 'Edge yaw')
settings.freestanding = ui.new_hotkey('AA', 'Anti-aimbot angles', 'Freestanding')
settings.freestanding_conditions = ui.new_multiselect('AA', 'Anti-aimbot angles', '\nFreestanding', 'Standing', 'Moving', 'Slow motion', 'Crouching', 'In air')
settings.tweaks = ui.new_multiselect('AA', 'Anti-aimbot angles', '\nTweaks', 'Off jitter while freestanding', 'Off jitter on manual')

local data = {
    integers = {
        settings.anti_aim_state,
        anti_aim_settings[1].override_state, anti_aim_settings[2].override_state, anti_aim_settings[3].override_state, anti_aim_settings[4].override_state, anti_aim_settings[5].override_state, anti_aim_settings[6].override_state, anti_aim_settings[7].override_state, anti_aim_settings[8].override_state, anti_aim_settings[9].override_state, anti_aim_settings[10].override_state,
        anti_aim_settings[1].force_defensive, anti_aim_settings[2].force_defensive, anti_aim_settings[3].force_defensive, anti_aim_settings[4].force_defensive, anti_aim_settings[5].force_defensive, anti_aim_settings[6].force_defensive, anti_aim_settings[7].force_defensive, anti_aim_settings[8].force_defensive, anti_aim_settings[9].force_defensive, anti_aim_settings[10].force_defensive,
        anti_aim_settings[1].pitch1, anti_aim_settings[2].pitch1, anti_aim_settings[3].pitch1, anti_aim_settings[4].pitch1, anti_aim_settings[5].pitch1, anti_aim_settings[6].pitch1, anti_aim_settings[7].pitch1, anti_aim_settings[8].pitch1, anti_aim_settings[9].pitch1, anti_aim_settings[10].pitch1,
        anti_aim_settings[1].pitch2, anti_aim_settings[2].pitch2, anti_aim_settings[3].pitch2, anti_aim_settings[4].pitch2, anti_aim_settings[5].pitch2, anti_aim_settings[6].pitch2, anti_aim_settings[7].pitch2, anti_aim_settings[8].pitch2, anti_aim_settings[9].pitch2, anti_aim_settings[10].pitch2,
        anti_aim_settings[1].yaw_base, anti_aim_settings[2].yaw_base, anti_aim_settings[3].yaw_base, anti_aim_settings[4].yaw_base, anti_aim_settings[5].yaw_base, anti_aim_settings[6].yaw_base, anti_aim_settings[7].yaw_base, anti_aim_settings[8].yaw_base, anti_aim_settings[9].yaw_base, anti_aim_settings[10].yaw_base,
        anti_aim_settings[1].yaw1, anti_aim_settings[2].yaw1, anti_aim_settings[3].yaw1, anti_aim_settings[4].yaw1, anti_aim_settings[5].yaw1, anti_aim_settings[6].yaw1, anti_aim_settings[7].yaw1, anti_aim_settings[8].yaw1, anti_aim_settings[9].yaw1, anti_aim_settings[10].yaw1,
        anti_aim_settings[1].yaw2_left, anti_aim_settings[2].yaw2_left, anti_aim_settings[3].yaw2_left, anti_aim_settings[4].yaw2_left, anti_aim_settings[5].yaw2_left, anti_aim_settings[6].yaw2_left, anti_aim_settings[7].yaw2_left, anti_aim_settings[8].yaw2_left, anti_aim_settings[9].yaw2_left, anti_aim_settings[10].yaw2_left,
        anti_aim_settings[1].yaw2_right, anti_aim_settings[2].yaw2_right, anti_aim_settings[3].yaw2_right, anti_aim_settings[4].yaw2_right, anti_aim_settings[5].yaw2_right, anti_aim_settings[6].yaw2_right, anti_aim_settings[7].yaw2_right, anti_aim_settings[8].yaw2_right, anti_aim_settings[9].yaw2_right, anti_aim_settings[10].yaw2_right,
        anti_aim_settings[1].yaw2_randomize, anti_aim_settings[2].yaw2_randomize, anti_aim_settings[3].yaw2_randomize, anti_aim_settings[4].yaw2_randomize, anti_aim_settings[5].yaw2_randomize, anti_aim_settings[6].yaw2_randomize, anti_aim_settings[7].yaw2_randomize, anti_aim_settings[8].yaw2_randomize, anti_aim_settings[9].yaw2_randomize, anti_aim_settings[10].yaw2_randomize,
        anti_aim_settings[1].yaw_jitter1, anti_aim_settings[2].yaw_jitter1, anti_aim_settings[3].yaw_jitter1, anti_aim_settings[4].yaw_jitter1, anti_aim_settings[5].yaw_jitter1, anti_aim_settings[6].yaw_jitter1, anti_aim_settings[7].yaw_jitter1, anti_aim_settings[8].yaw_jitter1, anti_aim_settings[9].yaw_jitter1, anti_aim_settings[10].yaw_jitter1,
        anti_aim_settings[1].yaw_jitter2_left, anti_aim_settings[2].yaw_jitter2_left, anti_aim_settings[3].yaw_jitter2_left, anti_aim_settings[4].yaw_jitter2_left, anti_aim_settings[5].yaw_jitter2_left, anti_aim_settings[6].yaw_jitter2_left, anti_aim_settings[7].yaw_jitter2_left, anti_aim_settings[8].yaw_jitter2_left, anti_aim_settings[9].yaw_jitter2_left, anti_aim_settings[10].yaw_jitter2_left,
        anti_aim_settings[1].yaw_jitter2_right, anti_aim_settings[2].yaw_jitter2_right, anti_aim_settings[3].yaw_jitter2_right, anti_aim_settings[4].yaw_jitter2_right, anti_aim_settings[5].yaw_jitter2_right, anti_aim_settings[6].yaw_jitter2_right, anti_aim_settings[7].yaw_jitter2_right, anti_aim_settings[8].yaw_jitter2_right, anti_aim_settings[9].yaw_jitter2_right, anti_aim_settings[10].yaw_jitter2_right,
        anti_aim_settings[1].yaw_jitter2_randomize, anti_aim_settings[2].yaw_jitter2_randomize, anti_aim_settings[3].yaw_jitter2_randomize, anti_aim_settings[4].yaw_jitter2_randomize, anti_aim_settings[5].yaw_jitter2_randomize, anti_aim_settings[6].yaw_jitter2_randomize, anti_aim_settings[7].yaw_jitter2_randomize, anti_aim_settings[8].yaw_jitter2_randomize, anti_aim_settings[9].yaw_jitter2_randomize, anti_aim_settings[10].yaw_jitter2_randomize,
        anti_aim_settings[1].yaw_jitter2_delay, anti_aim_settings[2].yaw_jitter2_delay, anti_aim_settings[3].yaw_jitter2_delay, anti_aim_settings[4].yaw_jitter2_delay, anti_aim_settings[5].yaw_jitter2_delay, anti_aim_settings[6].yaw_jitter2_delay, anti_aim_settings[7].yaw_jitter2_delay, anti_aim_settings[8].yaw_jitter2_delay, anti_aim_settings[9].yaw_jitter2_delay, anti_aim_settings[10].yaw_jitter2_delay,
        anti_aim_settings[1].body_yaw1, anti_aim_settings[2].body_yaw1, anti_aim_settings[3].body_yaw1, anti_aim_settings[4].body_yaw1, anti_aim_settings[5].body_yaw1, anti_aim_settings[6].body_yaw1, anti_aim_settings[7].body_yaw1, anti_aim_settings[8].body_yaw1, anti_aim_settings[9].body_yaw1, anti_aim_settings[10].body_yaw1,
        anti_aim_settings[1].body_yaw2, anti_aim_settings[2].body_yaw2, anti_aim_settings[3].body_yaw2, anti_aim_settings[4].body_yaw2, anti_aim_settings[5].body_yaw2, anti_aim_settings[6].body_yaw2, anti_aim_settings[7].body_yaw2, anti_aim_settings[8].body_yaw2, anti_aim_settings[9].body_yaw2, anti_aim_settings[10].body_yaw2,
        anti_aim_settings[1].freestanding_body_yaw, anti_aim_settings[2].freestanding_body_yaw, anti_aim_settings[3].freestanding_body_yaw, anti_aim_settings[4].freestanding_body_yaw, anti_aim_settings[5].freestanding_body_yaw, anti_aim_settings[6].freestanding_body_yaw, anti_aim_settings[7].freestanding_body_yaw, anti_aim_settings[8].freestanding_body_yaw, anti_aim_settings[9].freestanding_body_yaw, anti_aim_settings[10].freestanding_body_yaw,
        anti_aim_settings[1].roll, anti_aim_settings[2].roll, anti_aim_settings[3].roll, anti_aim_settings[4].roll, anti_aim_settings[5].roll, anti_aim_settings[6].roll, anti_aim_settings[7].roll, anti_aim_settings[8].roll, anti_aim_settings[9].roll, anti_aim_settings[10].roll,
        anti_aim_settings[1].defensive_anti_aimbot, anti_aim_settings[2].defensive_anti_aimbot, anti_aim_settings[3].defensive_anti_aimbot, anti_aim_settings[4].defensive_anti_aimbot, anti_aim_settings[5].defensive_anti_aimbot, anti_aim_settings[6].defensive_anti_aimbot, anti_aim_settings[7].defensive_anti_aimbot, anti_aim_settings[8].defensive_anti_aimbot, anti_aim_settings[9].defensive_anti_aimbot, anti_aim_settings[10].defensive_anti_aimbot,
        anti_aim_settings[1].defensive_pitch, anti_aim_settings[2].defensive_pitch, anti_aim_settings[3].defensive_pitch, anti_aim_settings[4].defensive_pitch, anti_aim_settings[5].defensive_pitch, anti_aim_settings[6].defensive_pitch, anti_aim_settings[7].defensive_pitch, anti_aim_settings[8].defensive_pitch, anti_aim_settings[9].defensive_pitch, anti_aim_settings[10].defensive_pitch,
        anti_aim_settings[1].defensive_pitch1, anti_aim_settings[2].defensive_pitch1, anti_aim_settings[3].defensive_pitch1, anti_aim_settings[4].defensive_pitch1, anti_aim_settings[5].defensive_pitch1, anti_aim_settings[6].defensive_pitch1, anti_aim_settings[7].defensive_pitch1, anti_aim_settings[8].defensive_pitch1, anti_aim_settings[9].defensive_pitch1, anti_aim_settings[10].defensive_pitch1,
        anti_aim_settings[1].defensive_pitch2, anti_aim_settings[2].defensive_pitch2, anti_aim_settings[3].defensive_pitch2, anti_aim_settings[4].defensive_pitch2, anti_aim_settings[5].defensive_pitch2, anti_aim_settings[6].defensive_pitch2, anti_aim_settings[7].defensive_pitch2, anti_aim_settings[8].defensive_pitch2, anti_aim_settings[9].defensive_pitch2, anti_aim_settings[10].defensive_pitch2,
        anti_aim_settings[1].defensive_pitch3, anti_aim_settings[2].defensive_pitch3, anti_aim_settings[3].defensive_pitch3, anti_aim_settings[4].defensive_pitch3, anti_aim_settings[5].defensive_pitch3, anti_aim_settings[6].defensive_pitch3, anti_aim_settings[7].defensive_pitch3, anti_aim_settings[8].defensive_pitch3, anti_aim_settings[9].defensive_pitch3, anti_aim_settings[10].defensive_pitch3,
        anti_aim_settings[1].defensive_yaw, anti_aim_settings[2].defensive_yaw, anti_aim_settings[3].defensive_yaw, anti_aim_settings[4].defensive_yaw, anti_aim_settings[5].defensive_yaw, anti_aim_settings[6].defensive_yaw, anti_aim_settings[7].defensive_yaw, anti_aim_settings[8].defensive_yaw, anti_aim_settings[9].defensive_yaw, anti_aim_settings[10].defensive_yaw,
        anti_aim_settings[1].defensive_yaw1, anti_aim_settings[2].defensive_yaw1, anti_aim_settings[3].defensive_yaw1, anti_aim_settings[4].defensive_yaw1, anti_aim_settings[5].defensive_yaw1, anti_aim_settings[6].defensive_yaw1, anti_aim_settings[7].defensive_yaw1, anti_aim_settings[8].defensive_yaw1, anti_aim_settings[9].defensive_yaw1, anti_aim_settings[10].defensive_yaw1,
        anti_aim_settings[1].defensive_yaw2, anti_aim_settings[2].defensive_yaw2, anti_aim_settings[3].defensive_yaw2, anti_aim_settings[4].defensive_yaw2, anti_aim_settings[5].defensive_yaw2, anti_aim_settings[6].defensive_yaw2, anti_aim_settings[7].defensive_yaw2, anti_aim_settings[8].defensive_yaw2, anti_aim_settings[9].defensive_yaw2, anti_aim_settings[10].defensive_yaw2,
        settings.avoid_backstab,
        settings.safe_head_in_air,
        settings.freestanding_conditions,
        settings.tweaks, master_switch, console_filter, anim_breakerx, aspectratio, hitmarker, fastladder, clantagchanger, trashtalk, watermark,
        -- Добавлены элементы ИИ Резольвера
        ai_resolver, resolver_mode, resolver_strength, cover_awareness, cover_adaptive_aa, cover_indicators, no_spread, no_spread_mode, no_spread_strength,
		
		buybot_enabled, buybot_primary, buybot_secondary, buybot_equipment, buybot_auto_buy, buybot_key
    }
}

local function import(text)
    local status, config =
        pcall(
        function()
            return json.parse(base64.decode(text))
        end
    )

    if not status or status == nil then
        print("StateW1n.pub \\beta/ - error while importing!")
        return
    end

    if config ~= nil then
        for k, v in pairs(config) do
            k = ({[1] = 'integers'})[k]

            for k2, v2 in pairs(v) do
                if k == 'integers' then
                    ui.set(data[k][k2], v2)
                end
            end
        end
    end

    print("StateW1n.pub \\beta/ - config successfully imported!")

end

-- Функция Trash Talk
local function on_player_death(e)
    if not ui.get(trashtalk) then return end
    
    local victim = client.userid_to_entindex(e.userid)
    local attacker = client.userid_to_entindex(e.attacker)
    local local_player = entity.get_local_player()
    
    if attacker == local_player and victim ~= local_player then
        local messages = {
            "𝕭𝖊𝖘𝖙 𝖑𝖚𝖆 𝖋𝖔𝖗 𝕲𝖘 - 𝕾𝖙𝖆𝖙𝖊𝖂1𝖓",
            "𝘽𝙚𝙨𝙩 𝙡𝙪𝙖 𝙛𝙤𝙧 𝙂𝙎 𝙞𝙣 𝙩𝙜 ▶ @𝙎𝙩𝙖𝙩𝙚𝙒1𝙣",
            "𝘩𝘳𝘪𝘴𝘪𝘵𝘰𝘴𝘦𝘯𝘴𝘦.𝘵𝘰𝘱/𝘧𝘰𝘳𝘶𝘮𝘴/𝘷𝘪𝘦𝘸𝘴𝘤𝘳𝘪𝘱𝘵.𝘱𝘩𝘱?𝘪𝘥=147"
        }
        
        local random_message = messages[math.random(1, #messages)]
        client.exec("say " .. random_message)
    end
end

local buybot_executed = false
local last_buy_time = 0

local weapon_commands = {
    -- Основное оружие
    ['FAMAS/GALIL'] = "buy famas; buy galilar",
    ['M4A4/AK-47'] = "buy m4a1; buy ak47", 
    ['AWP'] = "buy awp",
    ['SSG-08'] = "buy ssg08",
    ['Auto Sniper'] = "buy scar20; buy g3sg1",
    
    -- Пистолеты
    ['Deagle'] = "buy deagle",
    ['Dual Berettas'] = "buy elite",
    ['Five-Seven/Tec-9'] = "buy fiveseven; buy tec9",
    ['P250'] = "buy p250"
}

local function execute_buybot()
    if not ui.get(buybot_enabled) then return end
    
    local local_player = entity.get_local_player()
    if not local_player or not entity.is_alive(local_player) then return end
    
    local current_time = globals.realtime()
    if current_time - last_buy_time < 0.5 then return end
    
    local primary = ui.get(buybot_primary)
    local secondary = ui.get(buybot_secondary)
    local equipment = ui.get(buybot_equipment)
    
    client.exec("buycancel")
    
    -- Основное оружие
    if primary ~= 'None' then
        client.exec(weapon_commands[primary])
    end
    
    -- Пистолет
    if secondary ~= 'None' then
        client.exec(weapon_commands[secondary])
    end
    
    -- Экипировка
    for i, item in ipairs(equipment) do
        if item == 'Kevlar+Helmet' then
            client.exec("buy vesthelm")
        elseif item == 'Defuse Kit' then
            client.exec("buy defuser")
        elseif item == 'HE Grenade' then
            client.exec("buy hegrenade")
        elseif item == 'Flashbang' then
            client.exec("buy flashbang")
        elseif item == 'Smoke' then
            client.exec("buy smokegrenade")
        elseif item == 'Molotov' then
            client.exec("buy molotov; buy incgrenade")
        end
    end
    
    buybot_executed = true
    last_buy_time = current_time
    client.color_log(52, 152, 219, "[BuyBot] Purchase completed")
end

-- Обработка событий
client.set_event_callback('round_start', function(e)
    if ui.get(buybot_enabled) and ui.get(buybot_auto_buy) then
        buybot_executed = false
        client.delay_call(0.5, function()
            if not buybot_executed then
                execute_buybot()
            end
        end)
    end
end)


-- Функция ИИ Резольвера
local resolver_data = {}
local function ai_resolver_callback()
    if not ui.get(ai_resolver) then return end
    
    local local_player = entity.get_local_player()
    if not local_player or not entity.is_alive(local_player) then return end
    
    local players = entity.get_players(true)
    if not players then return end
    
    for i = 1, #players do
        local enemy_index = players[i]  -- ИСПРАВЛЕНИЕ: players[i] это число, а не таблица
        if entity.is_alive(enemy_index) and not entity.is_dormant(enemy_index) then
            -- Инициализация данных для игрока
            if not resolver_data[enemy_index] then
                resolver_data[enemy_index] = {
                    last_angles = {0, 0, 0},
                    angle_changes = 0,
                    last_resolved = 0,
                    patterns = {},
                    brute_stage = 0
                }
            end
            
            local data = resolver_data[enemy_index]
            local current_angles = {entity.get_prop(enemy_index, 'm_angEyeAngles')}  -- ИСПРАВЛЕНИЕ: enemy_index вместо enemy
            
            -- Обнаружение изменений углов
            if current_angles[1] and current_angles[2] then
                local angle_diff = math.abs(current_angles[2] - data.last_angles[2])
                if angle_diff > 5 then
                    data.angle_changes = data.angle_changes + 1
                    table.insert(data.patterns, current_angles[2])
                    
                    -- Ограничение размера истории паттернов
                    if #data.patterns > 10 then
                        table.remove(data.patterns, 1)
                    end
                end
                
                data.last_angles = current_angles
            end
            
            -- Применение резольвера в зависимости от режима
            local resolver_mode_val = ui.get(resolver_mode)
            local strength = ui.get(resolver_strength) / 100
            
            if resolver_mode_val == 'Auto' then
                -- Автоматический режим с анализом паттернов
                if #data.patterns >= 3 then
                    local avg_angle = 0
                    for j = 1, #data.patterns do
                        avg_angle = avg_angle + data.patterns[j]
                    end
                    avg_angle = avg_angle / #data.patterns
                    
                    local resolved_angle = avg_angle + (math.random(-30, 30) * (1 - strength))
                    plist.set(enemy_index, 'Correction active', true)
                    plist.set(enemy_index, 'Yaw add', resolved_angle)
                end
                
            elseif resolver_mode_val == 'Force Brute' then
                -- Форс брут режим
                data.brute_stage = (data.brute_stage % 3) + 1
                local brute_angles = {0, 60, -60}
                local resolved_angle = brute_angles[data.brute_stage] * strength
                
                plist.set(enemy_index, 'Correction active', true)
                plist.set(enemy_index, 'Yaw add', resolved_angle)
                
            elseif resolver_mode_val == 'Smart Predict' then
                -- Умное предсказание на основе движения
                local velocity = {entity.get_prop(enemy_index, 'm_vecVelocity')}  -- ИСПРАВЛЕНИЕ: enemy_index вместо enemy
                local speed = math.sqrt(velocity[1]^2 + velocity[2]^2)
                
                if speed > 5 then
                    -- Предсказание для движущихся целей
                    local predicted_angle = current_angles[2] + (speed * 0.1 * strength)
                    plist.set(enemy_index, 'Correction active', true)
                    plist.set(enemy_index, 'Yaw add', predicted_angle)
                else
                    -- Для стоящих целей используем рандомизацию
                    local random_angle = math.random(-45, 45) * strength
                    plist.set(enemy_index, 'Correction active', true)
                    plist.set(enemy_index, 'Yaw add', random_angle)
                end
            end
            
            data.last_resolved = globals.tickcount()
        end
    end
end

-- Функция No Spread (исправленная)
local function no_spread_callback(cmd)
    if not ui.get(no_spread) then return end
    
    local local_player = entity.get_local_player()
    if not local_player or not entity.is_alive(local_player) then return end
    
    local weapon = entity.get_player_weapon(local_player)
    if not weapon then return end
    
    local weapon_id = entity.get_prop(weapon, 'm_iItemDefinitionIndex')
    
    -- Пропускаем ножи, гранаты и т.д.
    if weapon_id == nil or weapon_id == 42 or weapon_id == 59 or 
       (weapon_id >= 500 and weapon_id <= 517) then 
        return 
    end
    
    local mode = ui.get(no_spread_mode)
    local strength = ui.get(no_spread_strength) / 100
    
    -- Получаем текущие углы spread
    local pitch, yaw = client.camera_angles()
    
    -- ИСПРАВЛЕНИЕ: правильно получаем и используем значения отдачи
    local recoil_punch = entity.get_prop(local_player, 'm_aimPunchAngle')
    local recoil_vel = entity.get_prop(local_player, 'm_aimPunchAngleVel')
    
    if mode == 'Default' then
        -- Базовая компенсация спреда
        if recoil_punch and recoil_vel then
            -- ИСПРАВЛЕНИЕ: проверяем что это таблицы и берем нужные элементы
            local punch_pitch = (type(recoil_punch) == 'table' and recoil_punch[1]) or 0
            local vel_yaw = (type(recoil_vel) == 'table' and recoil_vel[2]) or 0
            
            cmd.pitch = cmd.pitch - (punch_pitch * 2.0 * strength)
            cmd.yaw = cmd.yaw - (vel_yaw * 2.0 * strength)
        end
        
    elseif mode == 'Advanced' then
        -- Продвинутая компенсация с учетом оружия
        local weapon_inaccuracy = entity.get_prop(weapon, 'm_fAccuracyPenalty') or 0
        local base_inaccuracy = 0.0
        
        -- Базовые значения спреда для разных типов оружия
        if weapon_id == 7 then -- AK-47
            base_inaccuracy = 0.02
        elseif weapon_id == 16 then -- M4A4
            base_inaccuracy = 0.018
        elseif weapon_id == 9 then -- AWP
            base_inaccuracy = 0.01
        elseif weapon_id == 11 then -- G3SG1
            base_inaccuracy = 0.025
        else
            base_inaccuracy = 0.015
        end
        
        local total_inaccuracy = base_inaccuracy + (weapon_inaccuracy * 0.1)
        
        -- Компенсация спреда
        local spread_x = math.random() * total_inaccuracy * 2 - total_inaccuracy
        local spread_y = math.random() * total_inaccuracy * 2 - total_inaccuracy
        
        cmd.pitch = cmd.pitch - (spread_x * 100 * strength)
        cmd.yaw = cmd.yaw - (spread_y * 100 * strength)
        
    elseif mode == 'Prediction' then
        -- Предсказательная компенсация
        local velocity_x, velocity_y, velocity_z = entity.get_prop(local_player, 'm_vecVelocity')
        local speed = math.sqrt(velocity_x^2 + velocity_y^2)
        
        -- Учет движения для предсказания спреда
        local movement_factor = math.min(speed / 250, 1.0)
        local predicted_spread = movement_factor * 0.05 * strength
        
        -- Случайное смещение для обхода анти-читов
        local random_factor = (math.random() * 2 - 1) * 0.01 * (1 - strength)
        
        cmd.pitch = cmd.pitch + (predicted_spread + random_factor)
        cmd.yaw = cmd.yaw + (predicted_spread + random_factor)
    end
    
    -- Ограничение углов
    cmd.pitch = math.max(-89, math.min(89, cmd.pitch))
    cmd.yaw = cmd.yaw % 360
end

-- Prediction Enemy System
local prediction_data = {}
local last_prediction_update = 0

local function update_enemy_prediction()
    if not ui.get(prediction_enemy) then 
        prediction_data = {}
        return 
    end
    
    local local_player = entity.get_local_player()
    if not local_player or not entity.is_alive(local_player) then return end
    
    local players = entity.get_players(true)
    if not players then return end
    
    local current_time = globals.curtime()
    
    -- Обновляем не чаще чем раз в 0.05 секунды
    if current_time - last_prediction_update < 0.05 then
        return
    end
    
    last_prediction_update = current_time
    
    for i = 1, #players do
        local enemy_index = players[i]
        if entity.is_alive(enemy_index) and not entity.is_dormant(enemy_index) then
            -- Инициализация данных для игрока
            if not prediction_data[enemy_index] then
                prediction_data[enemy_index] = {
                    positions = {},
                    velocities = {},
                    timestamps = {},
                    predicted_position = nil,
                    last_update = 0
                }
            end
            
            local data = prediction_data[enemy_index]
            local current_pos = {entity.get_origin(enemy_index)}
            local current_vel = {entity.get_prop(enemy_index, 'm_vecVelocity')}
            local current_time = globals.curtime()
            
            -- Добавляем текущие данные
            table.insert(data.positions, current_pos)
            table.insert(data.velocities, current_vel)
            table.insert(data.timestamps, current_time)
            
            -- Ограничиваем размер истории
            local max_history = 10
            if #data.positions > max_history then
                table.remove(data.positions, 1)
                table.remove(data.velocities, 1)
                table.remove(data.timestamps, 1)
            end
            
            -- Предсказание позиции
            if #data.positions >= 3 then
                local mode = ui.get(prediction_mode)
                local strength = ui.get(prediction_strength) / 100
                
                if mode == 'Linear' then
                    -- Линейное предсказание
                    local last_pos = data.positions[#data.positions]
                    local prev_pos = data.positions[#data.positions - 1]
                    
                    local delta_x = last_pos[1] - prev_pos[1]
                    local delta_y = last_pos[2] - prev_pos[2]
                    local delta_z = last_pos[3] - prev_pos[3]
                    
                    -- Предсказываем на 0.2 секунды вперед
                    local prediction_time = 0.2 * strength
                    data.predicted_position = {
                        last_pos[1] + delta_x * prediction_time * 10,
                        last_pos[2] + delta_y * prediction_time * 10,
                        last_pos[3] + delta_z * prediction_time * 10
                    }
                    
                elseif mode == 'Quadratic' then
                    -- Квадратичное предсказание (учитывает ускорение)
                    if #data.positions >= 4 then
                        local pos1 = data.positions[#data.positions - 3]
                        local pos2 = data.positions[#data.positions - 2]
                        local pos3 = data.positions[#data.positions - 1]
                        local pos4 = data.positions[#data.positions]
                        
                        -- Вычисляем ускорение
                        local vel1 = {pos2[1]-pos1[1], pos2[2]-pos1[2], pos2[3]-pos1[3]}
                        local vel2 = {pos3[1]-pos2[1], pos3[2]-pos2[2], pos3[3]-pos2[3]}
                        local vel3 = {pos4[1]-pos3[1], pos4[2]-pos3[2], pos4[3]-pos3[3]}
                        
                        local accel = {
                            (vel3[1] - vel2[1]) * 0.5,
                            (vel3[2] - vel2[2]) * 0.5,
                            (vel3[3] - vel2[3]) * 0.5
                        }
                        
                        local prediction_time = 0.15 * strength
                        local current_vel = data.velocities[#data.velocities]
                        
                        data.predicted_position = {
                            pos4[1] + current_vel[1] * prediction_time + 0.5 * accel[1] * prediction_time * prediction_time,
                            pos4[2] + current_vel[2] * prediction_time + 0.5 * accel[2] * prediction_time * prediction_time,
                            pos4[3] + current_vel[3] * prediction_time + 0.5 * accel[3] * prediction_time * prediction_time
                        }
                    end
                    
                elseif mode == 'Adaptive' then
                    -- Адаптивное предсказание на основе паттернов движения
                    local movement_pattern = analyze_movement_pattern(data.positions)
                    local prediction_time = 0.25 * strength
                    
                    if movement_pattern == "strafe" then
                        -- Для страйферов предсказываем резкие изменения направления
                        data.predicted_position = predict_strafe_movement(data.positions, prediction_time)
                    elseif movement_pattern == "linear" then
                        -- Для линейного движения используем простую экстраполяцию
                        data.predicted_position = predict_linear_movement(data.positions, prediction_time)
                    else
                        -- По умолчанию - линейное предсказание
                        data.predicted_position = predict_linear_movement(data.positions, prediction_time)
                    end
                    
                elseif mode == 'Neural' then
                    -- Упрощенная "нейросетевая" логика (на основе анализа паттернов)
                    data.predicted_position = neural_prediction(data.positions, strength)
                end
            end
            
            data.last_update = current_time
        end
    end
end

-- Вспомогательные функции для Prediction
local function analyze_movement_pattern(positions)
    if #positions < 3 then return "unknown" end
    
    local direction_changes = 0
    local total_distance = 0
    
    for i = 2, #positions do
        local dx = positions[i][1] - positions[i-1][1]
        local dy = positions[i][2] - positions[i-1][2]
        local distance = math.sqrt(dx*dx + dy*dy)
        total_distance = total_distance + distance
        
        if i > 2 then
            local prev_dx = positions[i-1][1] - positions[i-2][1]
            local prev_dy = positions[i-1][2] - positions[i-2][2]
            
            local angle_change = math.abs(math.atan2(dy, dx) - math.atan2(prev_dy, prev_dx))
            if angle_change > 0.5 then -- ~28 градусов
                direction_changes = direction_changes + 1
            end
        end
    end
    
    local avg_distance = total_distance / (#positions - 1)
    local change_frequency = direction_changes / (#positions - 2)
    
    if change_frequency > 0.3 then
        return "strafe"
    elseif avg_distance > 50 then
        return "linear"
    else
        return "stationary"
    end
end

local function predict_linear_movement(positions, time)
    local last_pos = positions[#positions]
    local prev_pos = positions[#positions - 1]
    
    local dx = last_pos[1] - prev_pos[1]
    local dy = last_pos[2] - prev_pos[2]
    local dz = last_pos[3] - prev_pos[3]
    
    return {
        last_pos[1] + dx * time * 15,
        last_pos[2] + dy * time * 15,
        last_pos[3] + dz * time * 15
    }
end

local function predict_strafe_movement(positions, time)
    local last_pos = positions[#positions]
    
    -- Для страйферов добавляем случайный элемент в предсказание
    local random_factor = (math.random() * 2 - 1) * 20 * time
    
    return {
        last_pos[1] + random_factor,
        last_pos[2] + random_factor,
        last_pos[3]
    }
end

local function neural_prediction(positions, strength)
    -- Упрощенная "нейросетевая" логика
    local last_pos = positions[#positions]
    
    -- Анализ тренда движения
    local trend_x, trend_y, trend_z = 0, 0, 0
    local weight_total = 0
    
    for i = 2, #positions do
        local weight = i / #positions  -- Более свежие данные имеют больший вес
        local dx = positions[i][1] - positions[i-1][1]
        local dy = positions[i][2] - positions[i-1][2]
        local dz = positions[i][3] - positions[i-1][3]
        
        trend_x = trend_x + dx * weight
        trend_y = trend_y + dy * weight
        trend_z = trend_z + dz * weight
        weight_total = weight_total + weight
    end
    
    if weight_total > 0 then
        trend_x = trend_x / weight_total
        trend_y = trend_y / weight_total
        trend_z = trend_z / weight_total
    end
    
    local prediction_time = 0.2 * strength
    
    return {
        last_pos[1] + trend_x * prediction_time * 20,
        last_pos[2] + trend_y * prediction_time * 20,
        last_pos[3] + trend_z * prediction_time * 20
    }
end

local function enhanced_double_tap(cmd)
    -- Проверка активации (как у резольвера и ноу спреда)
    if not ui.get(dt_enabled) then
        dt_state.active = false
        return
    end

    local double_tap_enabled = ui.get(reference.double_tap[1]) and ui.get(reference.double_tap[2])
    if not double_tap_enabled then
        dt_state.active = false
        return
    end

    local local_player = entity.get_local_player()
    if not local_player or not entity.is_alive(local_player) then
        dt_state.active = false
        return
    end

    local weapon = entity.get_player_weapon(local_player)
    if not weapon then 
        dt_state.active = false
        return
    end

    -- Проверка оружия
    local weapon_id = entity.get_prop(weapon, 'm_iItemDefinitionIndex')
    if weapon_id == 64 then -- R8 Revolver
        dt_state.active = false
        return
    end

    -- Определение оптимального количества тиков
    local optimal_ticks = 14
    local dt_mode = ui.get(dt_enhanced_mode)
    
    if dt_mode == "Fast" then
        optimal_ticks = 16
    elseif dt_mode == "Safe" then
        optimal_ticks = 12
    elseif dt_mode == "Custom" then
        optimal_ticks = ui.get(dt_custom_ticks)
    end

    -- Адаптивные тики
    if ui.get(dt_adaptive_ticks) then
        local ping = client.latency() * 1000
        if ping > 80 then
            optimal_ticks = math.max(10, optimal_ticks - 2)
        elseif ping < 30 then
            optimal_ticks = math.min(16, optimal_ticks + 1)
        end
    end

    -- Break Lag Compensation
    if ui.get(dt_break_lagcomp) then
        local velocity_x, velocity_y, velocity_z = entity.get_prop(local_player, 'm_vecVelocity')
        local speed = math.sqrt(velocity_x^2 + velocity_y^2)
        
        if speed < 5 and cmd then -- Если стоим, немного двигаемся для сброса LC
            cmd.in_moveleft = 1
            cmd.in_moveright = 0
        end
    end

    dt_state.active = true
end

-- Индикаторы Double-Tap
local function draw_dt_indicators()
    -- Проверка активации
    if not ui.get(dt_enabled) or not ui.get(dt_indicators) then 
        return 
    end
    
    local double_tap_enabled = ui.get(reference.double_tap[1]) and ui.get(reference.double_tap[2])
    if not double_tap_enabled then return end
    
    local local_player = entity.get_local_player()
    if not local_player or not entity.is_alive(local_player) then return end
    
    local screen_width, screen_height = client.screen_size()
    local x, y = screen_width / 2, screen_height / 2 + 50
    
    if dt_state.active then
        renderer.text(x, y, 0, 255, 0, 255, "c", 0, "[ENHANCED DT]")
    else
        renderer.text(x, y, 255, 0, 0, 255, "c", 0, "[ENHANCED DT]")
    end
end

-- Функция проверки укрытия
local function check_cover_awareness()
    if not ui.get(cover_awareness) then
        cover_state.in_cover = false
        return false
    end

    local local_player = entity.get_local_player()
    if not local_player or not entity.is_alive(local_player) then
        cover_state.in_cover = false
        return false
    end

    -- Проверяем не чаще чем раз в 0.1 секунды
    if globals.curtime() - cover_state.last_check < 0.1 then
        return cover_state.in_cover
    end

    cover_state.last_check = globals.curtime()

    local in_cover = false
    local players = entity.get_players(true) -- враги

    for i = 1, #players do
        local enemy = players[i]
        if entity.is_alive(enemy) and not entity.is_dormant(enemy) then
            -- Проверяем есть ли укрытие между нами и врагом
            local my_eyes = {client.eye_position()}
            local enemy_eyes = {entity.hitbox_position(enemy, 0)} -- голова
            
            local fraction, entindex = client.trace_line(local_player, 
                my_eyes[1], my_eyes[2], my_eyes[3],
                enemy_eyes[1], enemy_eyes[2], enemy_eyes[3])
            
            -- Если трасса попадает в мир (укрытие), а не в игрока
            if fraction < 1.0 and entindex ~= enemy then
                in_cover = true
                break
            end
        end
    end

    cover_state.in_cover = in_cover
    return in_cover
end

-- Функция применения настроек укрытия (ПОЛНОСТЬЮ ИСПРАВЛЕННАЯ)
local function apply_cover_settings()
    local in_cover = check_cover_awareness()
    
    if in_cover and ui.get(cover_awareness) then
        -- Только меняем настройки Anti-Aim для укрытия (без Fake Lag)
        if ui.get(cover_adaptive_aa) then
            ui.set(reference.yaw_base, "Local view")
            ui.set(reference.body_yaw[1], "Opposite")
            ui.set(reference.edge_yaw, true)
        end
        
        cover_state.cover_timer = globals.curtime()
        
        -- Логирование для отладки
        if globals.tickcount() % 128 == 0 then
            client.log("[Cover Awareness] In cover - Adaptive AA active")
        end
        
    else
        -- Возвращаем обычные настройки (если вышли из укрытия)
        if cover_state.cover_timer > 0 and globals.curtime() - cover_state.cover_timer > 2.0 then
            cover_state.cover_timer = 0
            
            -- Логирование выхода из укрытия
            if globals.tickcount() % 128 == 0 then
                client.log("[Cover Awareness] Left cover - Settings reset")
            end
        end
    end
end

-- Индикаторы Cover Awareness
local function draw_cover_indicators()
    if not ui.get(cover_awareness) or not ui.get(cover_indicators) then 
        return 
    end
    
    local local_player = entity.get_local_player()
    if not local_player or not entity.is_alive(local_player) then return end
    
    local screen_width, screen_height = client.screen_size()
    local x, y = screen_width / 2, screen_height / 2 + 70
    
    if cover_state.in_cover then
        renderer.text(x, y, 0, 255, 0, 255, "c", 0, "[COVER]")
    else
        renderer.text(x, y, 255, 100, 100, 255, "c", 0, "[NO COVER]")
    end
end

local function get_optimal_ticks()
    local ping = entity.get_prop(entity.get_player_resource(), 'm_iPing', entity.get_local_player()) or 0
    local latency = (ping / 1000) + globals.tickinterval()
    local max_ticks = math.floor(0.2 / globals.tickinterval()) -- 200ms max
    
    if ui.get(backtrack_adaptive) then
        local adaptive_ticks = math.min(14, math.floor(latency / globals.tickinterval()) + 2)
        return adaptive_ticks
    end
    
    return ui.get(backtrack_ticks)
end

-- Запись позиций игроков
client.set_event_callback('net_update_end', function()
    if not ui.get(backtrack_exploit) then return end
    
    local local_player = entity.get_local_player()
    if not local_player or not entity.is_alive(local_player) then return end
    
    local players = entity.get_players(true)
    if not players then return end
    
    for i = 1, #players do
        local player = players[i]
        if entity.is_alive(player) and not entity.is_dormant(player) then
            local player_index = entity.get_prop(player, 'm_iIndex')
            
            if not backtrack_players[player_index] then
                backtrack_players[player_index] = {
                    records = {},
                    last_update = 0,
                    movement_pattern = {},
                    prediction_angle = 0
                }
            end
            
            local player_data = backtrack_players[player_index]
            local current_time = globals.tickcount()
            local origin = {entity.get_origin(player)}
            local simtime = entity.get_prop(player, 'm_flSimulationTime')
            
            -- Анализ паттернов движения
            if #player_data.movement_pattern > 0 then
                local last_pos = player_data.movement_pattern[#player_data.movement_pattern]
                local distance = vector(origin):dist(vector(last_pos))
                if distance > 5 then -- Игрок движется
                    table.insert(player_data.movement_pattern, origin)
                    if #player_data.movement_pattern > 10 then
                        table.remove(player_data.movement_pattern, 1)
                    end
                end
            else
                table.insert(player_data.movement_pattern, origin)
            end
            
            -- Предсказание угла движения
            if #player_data.movement_pattern >= 3 then
                local angle = calculate_movement_angle(player_data.movement_pattern)
                player_data.prediction_angle = angle
            end
            
            -- Добавление новой записи
            table.insert(player_data.records, {
                tick = current_time,
                origin = origin,
                simtime = simtime,
                head_position = {entity.hitbox_position(player, 0)},
                velocity = {entity.get_prop(player, 'm_vecVelocity')},
                flags = entity.get_prop(player, 'm_fFlags'),
                prediction_angle = player_data.prediction_angle
            })
            
            -- Ограничение размера истории
            local max_records = get_optimal_ticks() + 5
            while #player_data.records > max_records do
                table.remove(player_data.records, 1)
            end
            
            player_data.last_update = current_time
        end
    end
    
    -- Очистка старых записей
    for player_index, data in pairs(backtrack_players) do
        if globals.tickcount() - data.last_update > 100 then -- 5 секунд
            backtrack_players[player_index] = nil
        end
    end
end)

-- Функция расчета угла движения
local function calculate_movement_angle(positions)
    if #positions < 3 then return 0 end
    
    local recent_pos = positions[#positions]
    local old_pos = positions[1]
    
    local delta_x = recent_pos[1] - old_pos[1]
    local delta_y = recent_pos[2] - old_pos[2]
    
    local angle = math.deg(math.atan2(delta_y, delta_x))
    return angle % 360
end

-- Улучшенная логика выбора лучшего тика для backtrack
local function get_best_backtrack_tick(target_index, shoot_pos)
    local player_data = backtrack_players[target_index]
    if not player_data or #player_data.records == 0 then return nil end
    
    local best_tick = nil
    local best_score = -1
    local mode = ui.get(backtrack_mode)
    
    for i = #player_data.records, 1, -1 do
        local record = player_data.records[i]
        local score = 0
        
        -- Расчет расстояния
        local distance = vector(record.head_position):dist(vector(shoot_pos))
        
        if mode == 'Default' then
            score = 1000 - distance -- Простая логика по расстоянию
            
        elseif mode == 'Aggressive' then
            -- Предпочтение более старым тикам
            local age_bonus = (#player_data.records - i) * 10
            score = (1000 - distance) + age_bonus
            
        elseif mode == 'Smart' then
            -- Умная логика с учетом движения
            local velocity = vector(record.velocity):length()
            local movement_bonus = 0
            
            if velocity > 5 then
                movement_bonus = math.min(50, velocity * 2)
            end
            
            score = (1000 - distance) + movement_bonus
            
        elseif mode == 'On Peek' then
            -- Логика для пиков
            local is_peeking = is_player_peeking(record, player_data)
            local peek_bonus = is_peeking and 200 or 0
            score = (1000 - distance) + peek_bonus
        end
        
        -- Бонус за свежесть записи (новые записи лучше)
        local freshness = math.max(0, 14 - (globals.tickcount() - record.tick))
        score = score + (freshness * 5)
        
        if score > best_score then
            best_score = score
            best_tick = record
        end
    end
    
    return best_tick
end

-- Функция определения пикающего противника
local function is_player_peeking(record, player_data)
    if #player_data.movement_pattern < 2 then return false end
    
    local current_pos = player_data.movement_pattern[#player_data.movement_pattern]
    local previous_pos = player_data.movement_pattern[#player_data.movement_pattern - 1]
    
    local delta_x = math.abs(current_pos[1] - previous_pos[1])
    local delta_y = math.abs(current_pos[2] - previous_pos[2])
    
    -- Быстрое изменение позиции = пик
    return (delta_x > 20 or delta_y > 20)
end

-- Применение backtrack в setup_command
client.set_event_callback('setup_command', function(cmd)
    if not ui.get(backtrack_exploit) then return end
    
    local local_player = entity.get_local_player()
    if not local_player or not entity.is_alive(local_player) then return end
    
    -- Проверка на выстрел
    if cmd.in_attack == 1 and globals.curtime() - last_shot_time > 0.1 then
        local shoot_pos = {client.eye_position()}
        local best_target = nil
        local best_record = nil
        local best_distance = math.huge
        
        -- Поиск лучшей цели для backtrack
        for player_index, player_data in pairs(backtrack_players) do
            if entity.is_alive(player_index) and not entity.is_dormant(player_index) then
                local record = get_best_backtrack_tick(player_index, shoot_pos)
                if record then
                    local distance = vector(record.head_position):dist(vector(shoot_pos))
                    if distance < best_distance and distance < 8192 then -- Max range
                        best_distance = distance
                        best_target = player_index
                        best_record = record
                    end
                end
            end
        end
        
        -- Применение backtrack
        if best_target and best_record then
            local tick_delta = globals.tickcount() - best_record.tick
            local max_ticks = get_optimal_ticks()
            
            if tick_delta <= max_ticks and tick_delta > 0 then
                cmd.tick_count = best_record.tick
                last_shot_time = globals.curtime()
                
                -- Логирование для отладки
                if ui.get(master_switch) then
                    print(string.format("Backtrack: target=%d, ticks=%d, distance=%.1f", 
                          best_target, tick_delta, best_distance))
                end
            end
        end
    end
end)

-- Визуализация backtrack
client.set_event_callback('paint', function()
    if not ui.get(backtrack_exploit) or not ui.get(backtrack_visualize) then return end
    
    local local_player = entity.get_local_player()
    if not local_player or not entity.is_alive(local_player) then return end
    
    for player_index, player_data in pairs(backtrack_players) do
        if entity.is_alive(player_index) and not entity.is_dormant(player_index) then
            local alpha = 255
            local color = {255, 50, 50, alpha} -- Красный цвет
            
            -- Отрисовка записей backtrack
            for i, record in ipairs(player_data.records) do
                local screen_x, screen_y = renderer.world_to_screen(record.head_position[1], record.head_position[2], record.head_position[3])
                if screen_x and screen_y then
                    local size = 3
                    local record_alpha = math.floor(alpha * (i / #player_data.records))
                    
                    -- Разный цвет в зависимости от свежести записи
                    local record_color = {255, 255 - (i * 20), 50, record_alpha}
                    
                    renderer.circle(screen_x, screen_y, record_color[1], record_color[2], record_color[3], record_color[4], size, 0, 1, 10)
                    
                    -- Линия к текущей позиции
                    if i == #player_data.records then
                        local current_x, current_y = renderer.world_to_screen(
                            entity.get_prop(player_index, 'm_vecOrigin')
                        )
                        if current_x and current_y then
                            renderer.line(screen_x, screen_y, current_x, current_y, 255, 255, 255, 100)
                        end
                    end
                end
            end
        end
    end
end)


client.set_event_callback('setup_command', function(cmd)
    local self = entity.get_local_player()

    if entity.get_player_weapon(self) == nil then return end

    local using = false
    local anti_aim_on_use = false

    local inverted = entity.get_prop(self, "m_flPoseParameter", 11) * 120 - 60

    local is_planting = entity.get_prop(self, 'm_bInBombZone') == 1 and entity.get_classname(entity.get_player_weapon(self)) == 'CC4' and entity.get_prop(self, 'm_iTeamNum') == 2
    local CPlantedC4 = entity.get_all('CPlantedC4')[1]

    local eye_x, eye_y, eye_z = client.eye_position()
	local pitch, yaw = client.camera_angles()

    local sin_pitch = math.sin(math.rad(pitch))
	local cos_pitch = math.cos(math.rad(pitch))

	local sin_yaw = math.sin(math.rad(yaw))
	local cos_yaw = math.cos(math.rad(yaw))

    local direction_vector = {cos_pitch * cos_yaw, cos_pitch * sin_yaw, -sin_pitch}

    local trace = {
        start = {eye_x, eye_y, eye_z},
        end_ = {eye_x + direction_vector[1] * 8192, eye_y + direction_vector[2] * 8192, eye_z + direction_vector[3] * 8192}
    }

    local trace_result = client.trace_line(self, trace.start[1], trace.start[2], trace.start[3], trace.end_[1], trace.end_[2], trace.end_[3])

    if trace_entity ~= nil and entity.is_enemy(trace_entity) then
        if entity.get_classname(trace_entity) == 'CWeaponAWP' or entity.get_classname(trace_entity) == 'CWeaponSSG08' then
            anti_aim_on_use = true
        end
    end

    if is_planting then
        anti_aim_on_use = true
    end

    if CPlantedC4 ~= nil then
        local bomb_origin = {entity.get_prop(CPlantedC4, 'm_vecOrigin')}
        local distance = math.sqrt((eye_x - bomb_origin[1])^2 + (eye_y - bomb_origin[2])^2 + (eye_z - bomb_origin[3])^2)

        if distance < 80 then
            anti_aim_on_use = true
        end
    end

    if anti_aim_on_use then
        anti_aim_on_use_direction = anti_aim_on_use_direction == 0 and 1 or 0
    end

    if ui.get(settings.manual_forward) then
        direction = 0
    elseif ui.get(settings.manual_right) then
        direction = 1
    elseif ui.get(settings.manual_left) then
        direction = 2
    elseif ui.get(settings.edge_yaw) then
        direction = 3
    elseif ui.get(settings.freestanding) then
        direction = 4
    end

    if ui.get(settings.manual_forward) or ui.get(settings.manual_right) or ui.get(settings.manual_left) or ui.get(settings.edge_yaw) or ui.get(settings.freestanding) then
        last_press = globals.curtime()
    end

    if globals.curtime() - last_press > 0.2 then
        direction = 0
    end

    if anti_aim_on_use then
        direction = 5
    end

    if direction == 0 then
        ui.set(reference.yaw_base, 'Local view')
    elseif direction == 1 then
        ui.set(reference.yaw_base, 'At targets')
    elseif direction == 2 then
        ui.set(reference.yaw_base, 'At targets')
    elseif direction == 3 then
        ui.set(reference.yaw_base, 'At targets')
    elseif direction == 4 then
        ui.set(reference.yaw_base, 'At targets')
    elseif direction == 5 then
        ui.set(reference.yaw_base, 'At targets')
    end
	
	apply_cover_settings()
	
	enhanced_double_tap(cmd)

    -- Вызов ИИ Резольвера
    ai_resolver_callback()
    
    -- Вызов No Spread
    no_spread_callback(cmd)
end)

-- Обработка событий для Trash Talk
client.set_event_callback('player_death', on_player_death)

-- Функция для Watermark
local function watermark_callback()
    if not ui.get(watermark) then return end
    
    local screen_width, screen_height = client.screen_size()
    local text = "\a9b59b6ff✟StateW1n.pub V1.5✟"
    local text_width, text_height = renderer.measure_text("", text)
    
    local x = screen_width - text_width - 900
    local y = 950
    
    -- Фон
    renderer.rectangle(x - 5, y - 2, text_width + 10, text_height + 4, 0, 0, 0, 150)
    -- Текст
    renderer.text(x, y, 255, 255, 255, 255, "", 0, text)
end

client.set_event_callback('paint', watermark_callback)


client.set_event_callback('setup_command', function(cmd)
    local self = entity.get_local_player()

    if entity.get_player_weapon(self) == nil then return end

    local using = false
    local anti_aim_on_use = false

    local inverted = entity.get_prop(self, "m_flPoseParameter", 11) * 120 - 60

    local is_planting = entity.get_prop(self, 'm_bInBombZone') == 1 and entity.get_classname(entity.get_player_weapon(self)) == 'CC4' and entity.get_prop(self, 'm_iTeamNum') == 2
    local CPlantedC4 = entity.get_all('CPlantedC4')[1]

    local eye_x, eye_y, eye_z = client.eye_position()
	local pitch, yaw = client.camera_angles()

    local sin_pitch = math.sin(math.rad(pitch))
	local cos_pitch = math.cos(math.rad(pitch))

	local sin_yaw = math.sin(math.rad(yaw))
	local cos_yaw = math.cos(math.rad(yaw))

    local direction_vector = {cos_pitch * cos_yaw, cos_pitch * sin_yaw, -sin_pitch}

    local fraction, entity_index = client.trace_line(self, eye_x, eye_y, eye_z, eye_x + (direction_vector[1] * 8192), eye_y + (direction_vector[2] * 8192), eye_z + (direction_vector[3] * 8192))

    if CPlantedC4 ~= nil then
        dist_to_c4 = vector(entity.get_prop(self, 'm_vecOrigin')):dist(vector(entity.get_prop(CPlantedC4, 'm_vecOrigin')))

        if entity.get_prop(CPlantedC4, 'm_bBombDefused') == 1 then dist_to_c4 = 56 end

        is_defusing = dist_to_c4 < 56 and entity.get_prop(self, 'm_iTeamNum') == 3
    end

    if entity_index ~= -1 then
        if vector(entity.get_prop(self, 'm_vecOrigin')):dist(vector(entity.get_prop(entity_index, 'm_vecOrigin'))) < 146 then
            using = entity.get_classname(entity_index) ~= 'CWorld' and entity.get_classname(entity_index) ~= 'CFuncBrush' and entity.get_classname(entity_index) ~= 'CCSPlayer'
        end
    end

    if cmd.in_use == 1 and not using and not is_planting and not is_defusing and ui.get(anti_aim_settings[10].override_state) then cmd.buttons = bit.band(cmd.buttons, bit.bnot(bit.lshift(1, 5))); anti_aim_on_use = true; state_id = 10 else if (ui.get(reference.double_tap[1]) and ui.get(reference.double_tap[2])) == false and (ui.get(reference.on_shot_anti_aim[1]) and ui.get(reference.on_shot_anti_aim[2])) == false and ui.get(anti_aim_settings[9].override_state) then anti_aim_on_use = false; state_id = 9 else if (cmd.in_jump == 1 or bit.band(entity.get_prop(self, 'm_fFlags'), 1) == 0) and entity.get_prop(self, 'm_flDuckAmount') > 0.8 and ui.get(anti_aim_settings[8].override_state) then anti_aim_on_use = false; state_id = 8 elseif (cmd.in_jump == 1 or bit.band(entity.get_prop(self, 'm_fFlags'), 1) == 0) and entity.get_prop(self, 'm_flDuckAmount') < 0.8 and ui.get(anti_aim_settings[7].override_state) then anti_aim_on_use = false; state_id = 7 elseif bit.band(entity.get_prop(self, 'm_fFlags'), 1) ~= 0 and (entity.get_prop(self, 'm_flDuckAmount') > 0.8 or ui.get(reference.duck_peek_assist)) and vector(entity.get_prop(self, 'm_vecVelocity')):length() > 2 and ui.get(anti_aim_settings[6].override_state) then anti_aim_on_use = false; state_id = 6 elseif bit.band(entity.get_prop(self, 'm_fFlags'), 1) ~= 0 and entity.get_prop(self, 'm_flDuckAmount') > 0.8 and vector(entity.get_prop(self, 'm_vecVelocity')):length() < 2 and ui.get(anti_aim_settings[5].override_state) then anti_aim_on_use = false; state_id = 5 elseif bit.band(entity.get_prop(self, 'm_fFlags'), 1) ~= 0 and vector(entity.get_prop(self, 'm_vecVelocity')):length() > 2 and entity.get_prop(self, 'm_flDuckAmount') < 0.8 and (ui.get(reference.slow_motion[1]) and ui.get(reference.slow_motion[2])) == true and ui.get(anti_aim_settings[4].override_state) then anti_aim_on_use = false; state_id = 4 elseif bit.band(entity.get_prop(self, 'm_fFlags'), 1) ~= 0 and vector(entity.get_prop(self, 'm_vecVelocity')):length() > 2 and entity.get_prop(self, 'm_flDuckAmount') < 0.8 and (ui.get(reference.slow_motion[1]) and ui.get(reference.slow_motion[2])) == false and ui.get(anti_aim_settings[3].override_state) then anti_aim_on_use = false; state_id = 3 elseif bit.band(entity.get_prop(self, 'm_fFlags'), 1) ~= 0 and vector(entity.get_prop(self, 'm_vecVelocity')):length() < 2 and entity.get_prop(self, 'm_flDuckAmount') < 0.8 and ui.get(anti_aim_settings[2].override_state) then anti_aim_on_use = false; state_id = 2 else anti_aim_on_use = false; state_id = 1 end end end
    if cmd.in_jump == 1 or bit.band(entity.get_prop(self, 'm_fFlags'), 1) == 0 then freestanding_state_id = 5 elseif (entity.get_prop(self, 'm_flDuckAmount') > 0.8 or ui.get(reference.duck_peek_assist)) and bit.band(entity.get_prop(self, 'm_fFlags'), 1) ~= 0 then freestanding_state_id = 4 elseif bit.band(entity.get_prop(self, 'm_fFlags'), 1) ~= 0 and vector(entity.get_prop(self, 'm_vecVelocity')):length() > 2 and (ui.get(reference.slow_motion[1]) and ui.get(reference.slow_motion[2])) == true and ui.get(anti_aim_settings[4].override_state) then freestanding_state_id = 3 elseif bit.band(entity.get_prop(self, 'm_fFlags'), 1) ~= 0 and vector(entity.get_prop(self, 'm_vecVelocity')):length() > 2 and (ui.get(reference.slow_motion[1]) and ui.get(reference.slow_motion[2])) == false and ui.get(anti_aim_settings[3].override_state) then freestanding_state_id = 2 elseif bit.band(entity.get_prop(self, 'm_fFlags'), 1) ~= 0 and vector(entity.get_prop(self, 'm_vecVelocity')):length() < 2 and entity.get_prop(self, 'm_flDuckAmount') < 0.8 and ui.get(anti_aim_settings[2].override_state) then freestanding_state_id = 1 end

    ui.set(settings.manual_forward, 'On hotkey')
    ui.set(settings.manual_right, 'On hotkey')
    ui.set(settings.manual_left, 'On hotkey')

    cmd.force_defensive = ui.get(anti_aim_settings[state_id].force_defensive)

    ui.set(reference.pitch[1], ui.get(anti_aim_settings[state_id].pitch1))
    ui.set(reference.pitch[2], ui.get(anti_aim_settings[state_id].pitch2))
    ui.set(reference.yaw_base, (direction == 180 or direction == 90 or direction == -90) and anti_aim_on_use == false and 'Local view' or ui.get(anti_aim_settings[state_id].yaw_base))
    ui.set(reference.yaw[1], (direction == 180 or direction == 90 or direction == -90) and anti_aim_on_use == false and '180' or ui.get(anti_aim_settings[state_id].yaw1))

    if ui.get(anti_aim_settings[state_id].yaw1) ~= 'Off' and ui.get(anti_aim_settings[state_id].yaw_jitter1) == 'Delay' then
        if inverted > 0 then
            if ui.get(settings.manual_left) and last_press + 0.2 < globals.realtime() then
                direction = direction == -90 and ui.get(anti_aim_settings[state_id].yaw_jitter2_left) or -90

                last_press = globals.realtime()
            elseif ui.get(settings.manual_right) and last_press + 0.2 < globals.realtime() then
                direction = direction == 90 and ui.get(anti_aim_settings[state_id].yaw_jitter2_left) or 90

                last_press = globals.realtime()
            elseif ui.get(settings.manual_forward) and last_press + 0.2 < globals.realtime() then
                direction = direction == 180 and ui.get(anti_aim_settings[state_id].yaw_jitter2_left) or 180

                last_press = globals.realtime()
            end
        else
            if ui.get(settings.manual_left) and last_press + 0.2 < globals.realtime() then
                direction = direction == -90 and ui.get(anti_aim_settings[state_id].yaw_jitter2_right) or -90

                last_press = globals.realtime()
            elseif ui.get(settings.manual_right) and last_press + 0.2 < globals.realtime() then
                direction = direction == 90 and ui.get(anti_aim_settings[state_id].yaw_jitter2_right) or 90

                last_press = globals.realtime()
            elseif ui.get(settings.manual_forward) and last_press + 0.2 < globals.realtime() then
                direction = direction == 180 and ui.get(anti_aim_settings[state_id].yaw_jitter2_right) or 180

                last_press = globals.realtime()
            end
        end
    else
        if inverted > 0 then
            if ui.get(settings.manual_left) and last_press + 0.2 < globals.realtime() then
                direction = direction == -90 and ui.get(anti_aim_settings[state_id].yaw2_left) or -90

                last_press = globals.realtime()
            elseif ui.get(settings.manual_right) and last_press + 0.2 < globals.realtime() then
                direction = direction == 90 and ui.get(anti_aim_settings[state_id].yaw2_left) or 90

                last_press = globals.realtime()
            elseif ui.get(settings.manual_forward) and last_press + 0.2 < globals.realtime() then
                direction = direction == 180 and ui.get(anti_aim_settings[state_id].yaw2_left) or 180

                last_press = globals.realtime()
            end
        else
            if ui.get(settings.manual_left) and last_press + 0.2 < globals.realtime() then
                direction = direction == -90 and ui.get(anti_aim_settings[state_id].yaw2_right) or -90

                last_press = globals.realtime()
            elseif ui.get(settings.manual_right) and last_press + 0.2 < globals.realtime() then
                direction = direction == 90 and ui.get(anti_aim_settings[state_id].yaw2_right) or 90

                last_press = globals.realtime()
            elseif ui.get(settings.manual_forward) and last_press + 0.2 < globals.realtime() then
                direction = direction == 180 and ui.get(anti_aim_settings[state_id].yaw2_right) or 180

                last_press = globals.realtime()
            end
        end
    end

    if ui.get(anti_aim_settings[state_id].yaw1) ~= 'Off' and ui.get(anti_aim_settings[state_id].yaw_jitter1) == 'Delay' then
        if math.random(0, 1) ~= 0 then
            yaw_jitter2_left = ui.get(anti_aim_settings[state_id].yaw_jitter2_left) - math.random(0, ui.get(anti_aim_settings[state_id].yaw_jitter2_randomize))
            yaw_jitter2_right = ui.get(anti_aim_settings[state_id].yaw_jitter2_right) - math.random(0, ui.get(anti_aim_settings[state_id].yaw_jitter2_randomize))
        else
            yaw_jitter2_left = ui.get(anti_aim_settings[state_id].yaw_jitter2_left) + math.random(0, ui.get(anti_aim_settings[state_id].yaw_jitter2_randomize))
            yaw_jitter2_right = ui.get(anti_aim_settings[state_id].yaw_jitter2_right) + math.random(0, ui.get(anti_aim_settings[state_id].yaw_jitter2_randomize))
        end

        if inverted > 0 then
            if yaw_jitter2_left == 180 then yaw_jitter2_left = -180 elseif yaw_jitter2_left == 90 then yaw_jitter2_left = 89 elseif yaw_jitter2_left == -90 then yaw_jitter2_left = -89 end

            if not (direction == 180 or direction == 90 or direction == -90) then direction = yaw_jitter2_left end
        else
            if yaw_jitter2_right == 180 then yaw_jitter2_right = -180 elseif yaw_jitter2_right == 90 then yaw_jitter2_right = 89 elseif yaw_jitter2_right == -90 then yaw_jitter2_right = -89 end

            if not (direction == 180 or direction == 90 or direction == -90) then direction = yaw_jitter2_right end
        end
    else
        if inverted > 0 then
            if math.random(0, 1) ~= 0 then yaw2_left = ui.get(anti_aim_settings[state_id].yaw2_left) - math.random(0, ui.get(anti_aim_settings[state_id].yaw2_randomize)) else yaw2_left = ui.get(anti_aim_settings[state_id].yaw2_left) + math.random(0, ui.get(anti_aim_settings[state_id].yaw2_randomize)) end

            if yaw2_left == 180 then yaw2_left = -180 elseif yaw2_left == 90 then yaw2_left = 89 elseif yaw2_left == -90 then yaw2_left = -89 end

            if not (direction == 90 or direction == -90 or direction == 180) then direction = yaw2_left end
        else
            if math.random(0, 1) ~= 0 then yaw2_right = ui.get(anti_aim_settings[state_id].yaw2_right) - math.random(0, ui.get(anti_aim_settings[state_id].yaw2_randomize)) else yaw2_right = ui.get(anti_aim_settings[state_id].yaw2_right) + math.random(0, ui.get(anti_aim_settings[state_id].yaw2_randomize)) end

            if yaw2_right == 180 then yaw2_right = -180 elseif yaw2_right == 90 then yaw2_right = 89 elseif yaw2_right == -90 then yaw2_right = -89 end

            if not (direction == 90 or direction == -90 or direction == 180) then direction = yaw2_right end
        end
    end

    if anti_aim_on_use == true then
        if ui.get(anti_aim_settings[state_id].yaw1) ~= 'Off' and ui.get(anti_aim_settings[state_id].yaw_jitter1) == 'Delay' then
            if inverted > 0 then
                if math.random(0, 1) ~= 0 then
                    anti_aim_on_use_direction = ui.get(anti_aim_settings[state_id].yaw_jitter2_left) - math.random(0, ui.get(anti_aim_settings[state_id].yaw_jitter2_randomize))
                else
                    anti_aim_on_use_direction = ui.get(anti_aim_settings[state_id].yaw_jitter2_left) + math.random(0, ui.get(anti_aim_settings[state_id].yaw_jitter2_randomize))
                end
            else
                if math.random(0, 1) ~= 0 then
                    anti_aim_on_use_direction = ui.get(anti_aim_settings[state_id].yaw_jitter2_right) - math.random(0, ui.get(anti_aim_settings[state_id].yaw_jitter2_randomize))
                else
                    anti_aim_on_use_direction = ui.get(anti_aim_settings[state_id].yaw_jitter2_right) + math.random(0, ui.get(anti_aim_settings[state_id].yaw_jitter2_randomize))
                end
            end
        else
            if inverted > 0 then
                if math.random(0, 1) ~= 0 then
                    anti_aim_on_use_direction = ui.get(anti_aim_settings[state_id].yaw2_left) - math.random(0, ui.get(anti_aim_settings[state_id].yaw2_randomize))
                else
                    anti_aim_on_use_direction = ui.get(anti_aim_settings[state_id].yaw2_left) + math.random(0, ui.get(anti_aim_settings[state_id].yaw2_randomize))
                end
            else
                if math.random(0, 1) ~= 0 then
                    anti_aim_on_use_direction = ui.get(anti_aim_settings[state_id].yaw2_right) - math.random(0, ui.get(anti_aim_settings[state_id].yaw2_randomize))
                else
                    anti_aim_on_use_direction = ui.get(anti_aim_settings[state_id].yaw2_right) + math.random(0, ui.get(anti_aim_settings[state_id].yaw2_randomize))
                end
            end
        end
    end

    if direction > 180 or direction < -180 then direction = -180 end
    if anti_aim_on_use_direction > 180 or anti_aim_on_use_direction < -180 then anti_aim_on_use_direction = -180 end

    ui.set(reference.yaw[2], anti_aim_on_use == false and direction or anti_aim_on_use_direction)
    ui.set(reference.yaw_jitter[1], ((direction == 180 or direction == 90 or direction == -90) and contains(settings.tweaks, 'Off jitter on manual') and anti_aim_on_use == false or ui.get(anti_aim_settings[state_id].yaw_jitter1) == 'Delay' or ui.get(anti_aim_settings[state_id].yaw1) == 'Off') and 'Off' or ui.get(anti_aim_settings[state_id].yaw_jitter1))

    if inverted > 0 then
        if math.random(0, 1) ~= 0 then yaw_jitter2_left = ui.get(anti_aim_settings[state_id].yaw_jitter2_left) - math.random(0, ui.get(anti_aim_settings[state_id].yaw_jitter2_randomize)) else yaw_jitter2_left = ui.get(anti_aim_settings[state_id].yaw_jitter2_left) + math.random(0, ui.get(anti_aim_settings[state_id].yaw_jitter2_randomize)) end

        if yaw_jitter2_left > 180 or yaw_jitter2_left < -180 then yaw_jitter2_left = -180 end

        ui.set(reference.yaw_jitter[2], ui.get(anti_aim_settings[state_id].yaw1) ~= 'Off' and yaw_jitter2_left or 0)
    else
        if math.random(0, 1) ~= 0 then yaw_jitter2_right = ui.get(anti_aim_settings[state_id].yaw_jitter2_right) - math.random(0, ui.get(anti_aim_settings[state_id].yaw_jitter2_randomize)) else yaw_jitter2_right = ui.get(anti_aim_settings[state_id].yaw_jitter2_right) + math.random(0, ui.get(anti_aim_settings[state_id].yaw_jitter2_randomize)) end

        if yaw_jitter2_right > 180 or yaw_jitter2_right < -180 then yaw_jitter2_right = -180 end

        ui.set(reference.yaw_jitter[2], ui.get(anti_aim_settings[state_id].yaw1) ~= 'Off' and yaw_jitter2_right or 0)
    end

    if ui.get(anti_aim_settings[state_id].yaw1) ~= 'Off' and ui.get(anti_aim_settings[state_id].yaw_jitter1) == 'Delay' then
        if (ui.get(reference.double_tap[1]) and ui.get(reference.double_tap[2])) == true or (ui.get(reference.on_shot_anti_aim[1]) and ui.get(reference.on_shot_anti_aim[2])) == true then
            ui.set(reference.body_yaw[1], (direction == 180 or direction == 90 or direction == -90) and contains(settings.tweaks, 'Off jitter on manual') and anti_aim_on_use == false and 'Opposite' or 'Static')
        else
            ui.set(reference.body_yaw[1], (direction == 180 or direction == 90 or direction == -90) and contains(settings.tweaks, 'Off jitter on manual') and anti_aim_on_use == false and 'Opposite' or 'Jitter')
        end
    else
        ui.set(reference.body_yaw[1], (direction == 180 or direction == 90 or direction == -90) and contains(settings.tweaks, 'Off jitter on manual') and anti_aim_on_use == false and 'Opposite' or ui.get(anti_aim_settings[state_id].body_yaw1))
    end

    if cmd.command_number % ui.get(anti_aim_settings[state_id].yaw_jitter2_delay) + 1 > ui.get(anti_aim_settings[state_id].yaw_jitter2_delay) - 1 then
        delayed_jitter = not delayed_jitter
    end

    if ui.get(anti_aim_settings[state_id].yaw1) ~= 'Off' and ui.get(anti_aim_settings[state_id].yaw_jitter1) == 'Delay' then
        if (ui.get(reference.double_tap[1]) and ui.get(reference.double_tap[2])) == true or (ui.get(reference.on_shot_anti_aim[1]) and ui.get(reference.on_shot_anti_aim[2])) == true then
            ui.set(reference.body_yaw[2], delayed_jitter and -90 or 90)
        else
            ui.set(reference.body_yaw[2], -40)
        end
    else
        ui.set(reference.body_yaw[2], ui.get(anti_aim_settings[state_id].body_yaw2))
    end

    ui.set(reference.freestanding_body_yaw, ui.get(anti_aim_settings[state_id].yaw1) ~= 'Off' and ui.get(anti_aim_settings[state_id].yaw_jitter1) == 'Delay' and false or ui.get(anti_aim_settings[state_id].freestanding_body_yaw))
    ui.set(reference.roll, ui.get(anti_aim_settings[state_id].roll))

    if ui.get(anti_aim_settings[state_id].defensive_anti_aimbot) and is_defensive_active and ((ui.get(reference.double_tap[1]) and ui.get(reference.double_tap[2])) or (ui.get(reference.on_shot_anti_aim[1]) and ui.get(reference.on_shot_anti_aim[2]))) and not (direction == 180 or direction == 90 or direction == -90) then
        if ui.get(anti_aim_settings[state_id].defensive_pitch) then
            ui.set(reference.pitch[1], ui.get(anti_aim_settings[state_id].defensive_pitch1))

            if ui.get(anti_aim_settings[state_id].defensive_pitch1) == 'Random' then
                ui.set(reference.pitch[1], 'Custom')
                ui.set(reference.pitch[2], math.random(ui.get(anti_aim_settings[state_id].defensive_pitch2), ui.get(anti_aim_settings[state_id].defensive_pitch3)))
            else
                ui.set(reference.pitch[2], ui.get(anti_aim_settings[state_id].defensive_pitch2))
            end
        end

        if ui.get(anti_aim_settings[state_id].defensive_yaw) then
            ui.set(reference.yaw_jitter[1], 'Off')
            ui.set(reference.body_yaw[1], 'Opposite')

            if ui.get(anti_aim_settings[state_id].defensive_yaw1) == '180' then
                ui.set(reference.yaw[1], '180')

                ui.set(reference.yaw[2], ui.get(anti_aim_settings[state_id].defensive_yaw2))
            elseif ui.get(anti_aim_settings[state_id].defensive_yaw1) == 'Spin' then
                ui.set(reference.yaw[1], 'Spin')

                ui.set(reference.yaw[2], ui.get(anti_aim_settings[state_id].defensive_yaw2))
            elseif ui.get(anti_aim_settings[state_id].defensive_yaw1) == '180 Z' then
                ui.set(reference.yaw[1], '180 Z')

                ui.set(reference.yaw[2], ui.get(anti_aim_settings[state_id].defensive_yaw2))
            elseif ui.get(anti_aim_settings[state_id].defensive_yaw1) == 'Sideways' then
                ui.set(reference.yaw[1], '180')

                if cmd.command_number % 4 >= 2 then
                    ui.set(reference.yaw[2], math.random(85, 100))
                else
                    ui.set(reference.yaw[2], math.random(-100, -85))
                end
            elseif ui.get(anti_aim_settings[state_id].defensive_yaw1) == 'Random' then
                ui.set(reference.yaw[1], '180')

                ui.set(reference.yaw[2], math.random(-180, 180))
            end
        end
    end

    if ui.get(settings.safe_head_in_air) and (cmd.in_jump == 1 or bit.band(entity.get_prop(self, 'm_fFlags'), 1) == 0) and entity.get_prop(self, 'm_flDuckAmount') > 0.8 and (entity.get_classname(entity.get_player_weapon(self)) == 'CKnife' or entity.get_classname(entity.get_player_weapon(self)) == 'CWeaponTaser') and anti_aim_on_use == false and not (direction == 180 or direction == 90 or direction == -90) then
        ui.set(reference.pitch[1], 'Down')
        ui.set(reference.yaw[1], '180')
        ui.set(reference.yaw[2], 0)
        ui.set(reference.yaw_jitter[1], 'Off')
        ui.set(reference.body_yaw[1], 'Off')
        ui.set(reference.roll, 0)
    end

    ui.set(reference.edge_yaw, ui.get(settings.edge_yaw) and anti_aim_on_use == false and true or false)

    if ui.get(settings.freestanding) and ((contains(settings.freestanding_conditions, 'Standing') and freestanding_state_id == 1) or (contains(settings.freestanding_conditions, 'Moving') and freestanding_state_id == 2) or (contains(settings.freestanding_conditions, 'Slow motion') and freestanding_state_id == 3) or (contains(settings.freestanding_conditions, 'Crouching') and freestanding_state_id == 4) or (contains(settings.freestanding_conditions, 'In air') and freestanding_state_id == 5)) and anti_aim_on_use == false and not (direction == 180 or direction == 90 or direction == -90) then
        ui.set(reference.freestanding[1], true)
        ui.set(reference.freestanding[2], 'Always on')

        if contains(settings.tweaks, 'Off jitter while freestanding') then
            ui.set(reference.yaw[1], '180')
            ui.set(reference.yaw[2], 0)
            ui.set(reference.yaw_jitter[1], 'Off')
            ui.set(reference.body_yaw[1], 'Opposite')
            ui.set(reference.body_yaw[2], 0)
            ui.set(reference.freestanding_body_yaw, true)
        end
    else
        ui.set(reference.freestanding[1], false)
        ui.set(reference.freestanding[2], 'On hotkey')
    end

    if ui.get(settings.avoid_backstab) and anti_aim_on_use == false and not (direction == 180 or direction == 90 or direction == -90) then
        local players = entity.get_players(true)

        if players ~= nil then
            for i, enemy in pairs(players) do
                for h = 0, 18 do
                    local head_x, head_y, head_z = entity.hitbox_position(players[i], h)
                    local wx, wy = renderer.world_to_screen(head_x, head_y, head_z)
                    local fractions, entindex_hit = client.trace_line(self, eye_x, eye_y, eye_z, head_x, head_y, head_z)

                    if 250 >= vector(entity.get_prop(enemy, 'm_vecOrigin')):dist(vector(entity.get_prop(self, 'm_vecOrigin'))) and entity.is_alive(enemy) and entity.get_player_weapon(enemy) ~= nil and entity.get_classname(entity.get_player_weapon(enemy)) == 'CKnife' and (entindex_hit == players[i] or fractions == 1) and not entity.is_dormant(players[i]) then
                        ui.set(reference.yaw[1], '180')
                        ui.set(reference.yaw[2], -180)
                    end
                end
            end
        end
    end
end)

local function on_paint()
    local me = entity.get_local_player()
    if me == nil then return end
    local rr,gg,bb = 52, 152, 219  -- Синие оттенки
    local width, height = client.screen_size()
    local r2, g2, b2, a2 = 65, 105, 225, 255  -- Темно-синий для анимации
    local highlight_fraction =  (globals.realtime() / 2 % 1.2 * 2) - 1.2
    local output = ""
    local text_to_draw = " S T A T E W 1 N . P U B "
    for idx = 1, #text_to_draw do
        local character = text_to_draw:sub(idx, idx)
        local character_fraction = idx / #text_to_draw
        local r1, g1, b1, a1 = 255, 255, 255, 255
        local highlight_delta = (character_fraction - highlight_fraction)
        if highlight_delta >= 0 and highlight_delta <= 1.4 then
            if highlight_delta > 0.7 then
            highlight_delta = 1.4 - highlight_delta
            end
            local r_fraction, g_fraction, b_fraction, a_fraction = r2 - r1, g2 - g1, b2 - b1
            r1 = r1 + r_fraction * highlight_delta / 0.8
            g1 = g1 + g_fraction * highlight_delta / 0.8
            b1 = b1 + b_fraction * highlight_delta / 0.8
        end
        output = output .. ('\a%02x%02x%02x%02x%s'):format(r1, g1, b1, 255, text_to_draw:sub(idx, idx))
    end
    output = output
    
    local r,g,b,a = 52, 152, 219, 255  -- Основной синий цвет
    renderer.text(width - (width-960), height - 500, r, g, b, 255, "c", 0, output .. ' \ae67e22ffV1.5 ')
end
client.set_event_callback("paint", on_paint)

client.set_event_callback('paint_ui', function()
    if entity.get_local_player() == nil then cheked_ticks = 0 end


    if ui.is_menu_open() then
	    ui.set_visible(ai_resolver, ui.get(current_tab) == 'Rage')
        ui.set_visible(resolver_mode, ui.get(current_tab) == 'Rage' and ui.get(ai_resolver))
        ui.set_visible(resolver_strength, ui.get(current_tab) == 'Rage' and ui.get(ai_resolver))
        ui.set_visible(no_spread, ui.get(current_tab) == 'Rage')
		ui.set_visible(before_resolver, ui.get(current_tab) == 'Rage')
        ui.set_visible(no_spread_mode, ui.get(current_tab) == 'Rage' and ui.get(no_spread))
        ui.set_visible(no_spread_strength, ui.get(current_tab) == 'Rage' and ui.get(no_spread))
		ui.set_visible(before_spread, ui.get(current_tab) == 'Rage')
        ui.set_visible(cover_awareness, ui.get(current_tab) == 'Rage')
        ui.set_visible(cover_adaptive_aa, ui.get(current_tab) == 'Rage' and ui.get(cover_awareness))
		ui.set_visible(before_cover, ui.get(current_tab) == 'Rage')
        ui.set_visible(dt_enabled, ui.get(current_tab) == 'Rage')
        ui.set_visible(dt_enhanced_mode, ui.get(current_tab) == 'Rage' and ui.get(dt_enabled))
        ui.set_visible(dt_adaptive_ticks, ui.get(current_tab) == 'Rage' and ui.get(dt_enabled))
        ui.set_visible(dt_break_lagcomp, ui.get(current_tab) == 'Rage' and ui.get(dt_enabled))
        ui.set_visible(dt_custom_ticks, ui.get(current_tab) == 'Rage' and ui.get(dt_enabled) and ui.get(dt_enhanced_mode) == 'Custom')
		ui.set_visible(before_dt, ui.get(current_tab) == 'Rage')
		ui.set_visible(backtrack_exploit, ui.get(current_tab) == 'Rage')
        ui.set_visible(backtrack_mode, ui.get(current_tab) == 'Rage' and ui.get(backtrack_exploit))
        ui.set_visible(backtrack_ticks, ui.get(current_tab) == 'Rage' and ui.get(backtrack_exploit))
        ui.set_visible(backtrack_adaptive, ui.get(current_tab) == 'Rage' and ui.get(backtrack_exploit))
        ui.set_visible(backtrack_visualize, ui.get(current_tab) == 'Rage' and ui.get(backtrack_exploit))
		ui.set_visible(before_backtrack, ui.get(current_tab) == 'Rage')
		ui.set_visible(prediction_enemy, ui.get(current_tab) == 'Rage')
        ui.set_visible(prediction_mode, ui.get(current_tab) == 'Rage' and ui.get(prediction_enemy))
        ui.set_visible(prediction_strength, ui.get(current_tab) == 'Rage' and ui.get(prediction_enemy))
        ui.set_visible(prediction_visualize, ui.get(current_tab) == 'Rage' and ui.get(prediction_enemy))
        ui.set_visible(before_prediction, ui.get(current_tab) == 'Rage')
        ui.set_visible(reference.pitch[1], false)
        ui.set_visible(reference.pitch[2], false)
        ui.set_visible(reference.yaw_base, false)
        ui.set_visible(reference.yaw[1], false)
        ui.set_visible(reference.yaw[2], false)
        ui.set_visible(reference.yaw_jitter[1], false)
        ui.set_visible(reference.yaw_jitter[2], false)
        ui.set_visible(reference.body_yaw[1], false)
        ui.set_visible(reference.body_yaw[2], false)
        ui.set_visible(reference.freestanding_body_yaw, false)
        ui.set_visible(reference.edge_yaw, false)
        ui.set_visible(reference.freestanding[1], false)
        ui.set_visible(reference.freestanding[2], false)
        ui.set_visible(reference.roll, false)
        ui.set_visible(settings.anti_aim_state, ui.get(current_tab) == 'Anti-Aim')
        ui.set_visible(settings.avoid_backstab, ui.get(current_tab) == 'Anti-Aim')
        ui.set_visible(settings.safe_head_in_air, ui.get(current_tab) == 'Anti-Aim')
        ui.set_visible(settings.manual_forward, ui.get(current_tab) == 'Anti-Aim')
        ui.set_visible(settings.manual_right, ui.get(current_tab) == 'Anti-Aim')
        ui.set_visible(settings.manual_left, ui.get(current_tab) == 'Anti-Aim')
        ui.set_visible(settings.edge_yaw, ui.get(current_tab) == 'Anti-Aim')
        ui.set_visible(settings.freestanding, ui.get(current_tab) == 'Anti-Aim')
        ui.set_visible(settings.freestanding_conditions, ui.get(current_tab) == 'Anti-Aim')
        ui.set_visible(settings.tweaks, ui.get(current_tab) == 'Anti-Aim')
        ui.set_visible(trashtalk, ui.get(current_tab) == 'Misc/Vis')
        ui.set_visible(watermark, ui.get(current_tab) == 'Misc/Vis')
        ui.set_visible(master_switch, ui.get(current_tab) == 'Misc/Vis')
        ui.set_visible(console_filter, ui.get(current_tab) == 'Misc/Vis')
        ui.set_visible(anim_breakerx, ui.get(current_tab) == 'Misc/Vis')
        ui.set_visible(aspectratio, ui.get(current_tab) == 'Misc/Vis')
        ui.set_visible(hitmarker, ui.get(current_tab) == 'Misc/Vis')
        ui.set_visible(fastladder, ui.get(current_tab) == 'Misc/Vis')
        ui.set_visible(clantagchanger, ui.get(current_tab) == 'Misc/Vis')
		ui.set_visible(buybot_enabled, ui.get(current_tab) == 'Misc/Vis')
		ui.set_visible(buybot_primary, ui.get(current_tab) == 'Misc/Vis' and ui.get(buybot_enabled))
		ui.set_visible(buybot_secondary, ui.get(current_tab) == 'Misc/Vis' and ui.get(buybot_enabled))
		ui.set_visible(buybot_equipment, ui.get(current_tab) == 'Misc/Vis' and ui.get(buybot_enabled))
		ui.set_visible(buybot_auto_buy, ui.get(current_tab) == 'Misc/Vis' and ui.get(buybot_enabled))
		ui.set_visible(buybot_key, ui.get(current_tab) == 'Misc/Vis' and ui.get(buybot_enabled))
        ui.set_visible(text1, ui.get(current_tab) == 'Home')
        ui.set_visible(text2, ui.get(current_tab) == 'Home')
        ui.set_visible(text3, ui.get(current_tab) == 'Home')


        for i = 1, #anti_aim_states do
            ui.set_visible(anti_aim_settings[i].override_state, ui.get(current_tab) == 'Anti-Aim' and ui.get(settings.anti_aim_state) == anti_aim_states[i]); ui.set(anti_aim_settings[1].override_state, true); ui.set_visible(anti_aim_settings[1].override_state, false)
            ui.set_visible(anti_aim_settings[i].force_defensive, ui.get(current_tab) == 'Anti-Aim' and ui.get(settings.anti_aim_state) == anti_aim_states[i]); ui.set_visible(anti_aim_settings[9].force_defensive, false)
            ui.set_visible(anti_aim_settings[i].pitch1,ui.get(current_tab) == 'Anti-Aim' and  ui.get(settings.anti_aim_state) == anti_aim_states[i])
            ui.set_visible(anti_aim_settings[i].pitch2, ui.get(current_tab) == 'Anti-Aim' and ui.get(settings.anti_aim_state) == anti_aim_states[i] and ui.get(anti_aim_settings[i].pitch1) == 'Custom')
            ui.set_visible(anti_aim_settings[i].yaw_base, ui.get(current_tab) == 'Anti-Aim' and ui.get(settings.anti_aim_state) == anti_aim_states[i])
            ui.set_visible(anti_aim_settings[i].yaw1, ui.get(current_tab) == 'Anti-Aim' and ui.get(settings.anti_aim_state) == anti_aim_states[i])
            ui.set_visible(anti_aim_settings[i].yaw2_left, ui.get(current_tab) == 'Anti-Aim' and ui.get(settings.anti_aim_state) == anti_aim_states[i] and ui.get(anti_aim_settings[i].yaw1) ~= 'Off' and ui.get(anti_aim_settings[i].yaw_jitter1) ~= 'Delay')
            ui.set_visible(anti_aim_settings[i].yaw2_right, ui.get(current_tab) == 'Anti-Aim' and ui.get(settings.anti_aim_state) == anti_aim_states[i] and ui.get(anti_aim_settings[i].yaw1) ~= 'Off' and ui.get(anti_aim_settings[i].yaw_jitter1) ~= 'Delay')
            ui.set_visible(anti_aim_settings[i].yaw2_randomize, ui.get(current_tab) == 'Anti-Aim' and ui.get(settings.anti_aim_state) == anti_aim_states[i] and ui.get(anti_aim_settings[i].yaw1) ~= 'Off' and ui.get(anti_aim_settings[i].yaw_jitter1) ~= 'Delay')
            ui.set_visible(anti_aim_settings[i].yaw_jitter1, ui.get(current_tab) == 'Anti-Aim' and ui.get(settings.anti_aim_state) == anti_aim_states[i] and ui.get(anti_aim_settings[i].yaw1) ~= 'Off')
            ui.set_visible(anti_aim_settings[i].yaw_jitter2_left, ui.get(current_tab) == 'Anti-Aim' and ui.get(settings.anti_aim_state) == anti_aim_states[i] and ui.get(anti_aim_settings[i].yaw1) ~= 'Off' and ui.get(anti_aim_settings[i].yaw_jitter1) ~= 'Off')
            ui.set_visible(anti_aim_settings[i].yaw_jitter2_right, ui.get(current_tab) == 'Anti-Aim' and ui.get(settings.anti_aim_state) == anti_aim_states[i] and ui.get(anti_aim_settings[i].yaw1) ~= 'Off' and ui.get(anti_aim_settings[i].yaw_jitter1) ~= 'Off')
            ui.set_visible(anti_aim_settings[i].yaw_jitter2_randomize, ui.get(current_tab) == 'Anti-Aim' and ui.get(settings.anti_aim_state) == anti_aim_states[i] and ui.get(anti_aim_settings[i].yaw1) ~= 'Off' and ui.get(anti_aim_settings[i].yaw_jitter1) ~= 'Off')
            ui.set_visible(anti_aim_settings[i].yaw_jitter2_delay, ui.get(current_tab) == 'Anti-Aim' and ui.get(settings.anti_aim_state) == anti_aim_states[i] and ui.get(anti_aim_settings[i].yaw1) ~= 'Off' and ui.get(anti_aim_settings[i].yaw_jitter1) == 'Delay')
            ui.set_visible(anti_aim_settings[i].body_yaw1, ui.get(current_tab) == 'Anti-Aim' and ui.get(settings.anti_aim_state) == anti_aim_states[i] and ui.get(anti_aim_settings[i].yaw_jitter1) ~= 'Delay')
            ui.set_visible(anti_aim_settings[i].body_yaw2, ui.get(current_tab) == 'Anti-Aim' and ui.get(settings.anti_aim_state) == anti_aim_states[i] and (ui.get(anti_aim_settings[i].body_yaw1) ~= 'Off' and ui.get(anti_aim_settings[i].body_yaw1) ~= 'Opposite') and ui.get(anti_aim_settings[i].yaw_jitter1) ~= 'Delay')
            ui.set_visible(anti_aim_settings[i].freestanding_body_yaw, ui.get(current_tab) == 'Anti-Aim' and ui.get(settings.anti_aim_state) == anti_aim_states[i] and ui.get(anti_aim_settings[i].body_yaw1) ~= 'Off' and ui.get(anti_aim_settings[i].yaw_jitter1) ~= 'Delay')
            ui.set_visible(anti_aim_settings[i].roll, ui.get(current_tab) == 'Anti-Aim' and ui.get(settings.anti_aim_state) == anti_aim_states[i])
            ui.set_visible(anti_aim_settings[i].defensive_anti_aimbot, ui.get(current_tab) == 'Anti-Aim' and ui.get(settings.anti_aim_state) == anti_aim_states[i]); ui.set_visible(anti_aim_settings[9].defensive_anti_aimbot, false)
            ui.set_visible(anti_aim_settings[i].defensive_pitch, ui.get(current_tab) == 'Anti-Aim' and ui.get(settings.anti_aim_state) == anti_aim_states[i] and ui.get(anti_aim_settings[i].defensive_anti_aimbot)); ui.set_visible(anti_aim_settings[9].defensive_pitch, false)
            ui.set_visible(anti_aim_settings[i].defensive_pitch1, ui.get(current_tab) == 'Anti-Aim' and ui.get(settings.anti_aim_state) == anti_aim_states[i] and ui.get(anti_aim_settings[i].defensive_anti_aimbot) and ui.get(anti_aim_settings[i].defensive_pitch)); ui.set_visible(anti_aim_settings[9].defensive_pitch1, false)
            ui.set_visible(anti_aim_settings[i].defensive_pitch2, ui.get(current_tab) == 'Anti-Aim' and ui.get(settings.anti_aim_state) == anti_aim_states[i] and ui.get(anti_aim_settings[i].defensive_anti_aimbot) and ui.get(anti_aim_settings[i].defensive_pitch) and (ui.get(anti_aim_settings[i].defensive_pitch1) == 'Random' or ui.get(anti_aim_settings[i].defensive_pitch1) == 'Custom')); ui.set_visible(anti_aim_settings[9].defensive_pitch2, false)
            ui.set_visible(anti_aim_settings[i].defensive_pitch3, ui.get(current_tab) == 'Anti-Aim' and ui.get(settings.anti_aim_state) == anti_aim_states[i] and ui.get(anti_aim_settings[i].defensive_anti_aimbot) and ui.get(anti_aim_settings[i].defensive_pitch) and ui.get(anti_aim_settings[i].defensive_pitch1) == 'Random'); ui.set_visible(anti_aim_settings[9].defensive_pitch3, false)
            ui.set_visible(anti_aim_settings[i].defensive_yaw, ui.get(current_tab) == 'Anti-Aim' and  ui.get(settings.anti_aim_state) == anti_aim_states[i] and ui.get(anti_aim_settings[i].defensive_anti_aimbot)); ui.set_visible(anti_aim_settings[9].defensive_yaw, false)
            ui.set_visible(anti_aim_settings[i].defensive_yaw1, ui.get(current_tab) == 'Anti-Aim' and ui.get(settings.anti_aim_state) == anti_aim_states[i] and ui.get(anti_aim_settings[i].defensive_anti_aimbot) and ui.get(anti_aim_settings[i].defensive_yaw)); ui.set_visible(anti_aim_settings[9].defensive_yaw1, false)
            ui.set_visible(anti_aim_settings[i].defensive_yaw2, ui.get(current_tab) == 'Anti-Aim' and ui.get(settings.anti_aim_state) == anti_aim_states[i] and ui.get(anti_aim_settings[i].defensive_anti_aimbot) and ui.get(anti_aim_settings[i].defensive_yaw) and (ui.get(anti_aim_settings[i].defensive_yaw1) == '180' or ui.get(anti_aim_settings[i].defensive_yaw1) == 'Spin' or ui.get(anti_aim_settings[i].defensive_yaw1) == '180 Z')); ui.set_visible(anti_aim_settings[9].defensive_yaw2, false)
        end
    end
end)

import_btn = ui.new_button("AA", "Anti-aimbot angles", "Import settings", function() import(clipboard.get()) end)
export_btn = ui.new_button("AA", "Anti-aimbot angles", "Export settings", function() 
    local code = {{}}

    for i, integers in pairs(data.integers) do
        table.insert(code[1], ui.get(integers))
    end

    clipboard.set(base64.encode(json.stringify(code)))
    print('StateW1n.pub \\beta/ ~ successfully exported your config')
end)
default_btn = ui.new_button("AA", "Anti-aimbot angles", "Recommended Config", function() 
    import('W1siR2xvYmFsIix0cnVlLHRydWUsdHJ1ZSx0cnVlLHRydWUsdHJ1ZSx0cnVlLHRydWUsdHJ1ZSx0cnVlLGZhbHNlLGZhbHNlLGZhbHNlLGZhbHNlLGZhbHNlLGZhbHNlLHRydWUsdHJ1ZSxmYWxzZSxmYWxzZSwiT2ZmIiwiTWluaW1hbCIsIk1pbmltYWwiLCJNaW5pbWFsIiwiTWluaW1hbCIsIk1pbmltYWwiLCJNaW5pbWFsIiwiTWluaW1hbCIsIk1pbmltYWwiLCJPZmYiLDAsMCwwLDAsMCwwLDAsMCwwLDAsIkxvY2FsIHZpZXciLCJBdCB0YXJnZXRzIiwiQXQgdGFyZ2V0cyIsIkF0IHRhcmdldHMiLCJMb2NhbCB2aWV3IiwiQXQgdGFyZ2V0cyIsIkF0IHRhcmdldHMiLCJBdCB0YXJnZXRzIiwiQXQgdGFyZ2V0cyIsIkxvY2FsIHZpZXciLCJPZmYiLCIxODAiLCIxODAgWiIsIlNwaW4iLCIxODAiLCIxODAiLCIxODAiLCIxODAiLCIxODAiLCJPZmYiLDAsMywtNSwtMzAsMCwtMTUsMCwwLDcsMCwwLDMsLTUsMzAsMCwtMTUsMCwwLDcsMCwwLDAsMCwwLDAsMCwwLDAsMCwwLCJPZmYiLCJPZmZzZXQiLCJDZW50ZXIiLCJDZW50ZXIiLCJSYW5kb20iLCJPZmZzZXQiLCJEZWxheSIsIkRlbGF5IiwiQ2VudGVyIiwiT2ZmIiwwLDMwLDI1LDQwLDQ1LDUxLC0yNSwtMjMsNTAsMCwwLDMwLC0yNSw0MCwtNDUsNTEsNDAsNDEsNTAsMCwwLDAsMCw0LDQ1LDMsMCwwLDAsMCwyLDIsMiwyLDQsMiw2LDQsMiwyLCJPZmYiLCJKaXR0ZXIiLCJPcHBvc2l0ZSIsIlN0YXRpYyIsIkppdHRlciIsIkppdHRlciIsIk9mZiIsIk9mZiIsIkppdHRlciIsIk9wcG9zaXRlIiwwLC02MCwtNjAsLTkwLC01NywtNDAsMCwwLC00MCwwLGZhbHNlLGZhbHNlLGZhbHNlLGZhbHNlLGZhbHNlLGZhbHNlLGZhbHNlLGZhbHNlLGZhbHNlLHRydWUsMCwwLDAsMCwwLDAsMCwwLDAsMCxmYWxzZSx0cnVlLHRydWUsdHJ1ZSx0cnVlLGZhbHNlLGZhbHNlLGZhbHNlLGZhbHNlLGZhbHNlLGZhbHNlLHRydWUsdHJ1ZSx0cnVlLHRydWUsZmFsc2UsZmFsc2UsZmFsc2UsZmFsc2UsZmFsc2UsIk9mZiIsIk9mZiIsIk9mZiIsIk9mZiIsIk9mZiIsIk9mZiIsIk9mZiIsIk9mZiIsIk9mZiIsIk9mZiIsMCw4OSw4OSw4OSwwLDAsMCwwLDAsMCwwLC04OSwtODksLTg5LDAsMCwwLDAsMCwwLGZhbHNlLGZhbHNlLGZhbHNlLGZhbHNlLGZhbHNlLGZhbHNlLGZhbHNlLGZhbHNlLGZhbHNlLGZhbHNlLCIxODAiLCIxODAgWiIsIjE4MCIsIjE4MCIsIjE4MCIsIjE4MCIsIjE4MCIsIjE4MCIsIjE4MCIsIjE4MCIsMCwtNSwwLDAsMCwwLDAsMCwwLDAsdHJ1ZSx0cnVlLFsiU3RhbmRpbmciLCJNb3ZpbmciLCJDcm91Y2hpbmciXSxbIk9mZiBqaXR0ZXIgd2hpbGUgZnJlZXN0YW5kaW5nIiwiT2ZmIGppdHRlciBvbiBtYW51YWwiXSx0cnVlLHRydWUsdHJ1ZSwwLHRydWUsdHJ1ZSx0cnVlLHRydWUsdHJ1ZSxmYWxzZSwi4oiGQXV0b+KIhiIsNzUsZmFsc2UsZmFsc2UsZmFsc2UsIuKXlURlZmF1bHTil5UiLDc1XV0=')
end)

client.set_event_callback('paint_ui', function()
    if entity.get_local_player() == nil then cheked_ticks = 0 end

    ui.set_visible(export_btn, ui.get(current_tab) == 'Home')
    ui.set_visible(import_btn, ui.get(current_tab) == 'Home')
    ui.set_visible(default_btn, ui.get(current_tab) == 'Home')
end)

ui.set_callback(console_filter, function()
    cvar.con_filter_text:set_string("cool text")
    cvar.con_filter_enable:set_int(1)
end)

-- Регистрация Trash Talk
client.set_event_callback('player_death', on_player_death)

local clantag = {
    steam = steamworks.ISteamFriends,
    prev_ct = "",
    orig_ct = "",
    enb = false,
}

local function get_original_clantag()
    local clan_id = cvar.cl_clanid.get_int()
    if clan_id == 0 then return "\0" end

    local clan_count = clantag.steam.GetClanCount()
    for i = 0, clan_count do 
        local group_id = clantag.steam.GetClanByIndex(i)
        if group_id == clan_id then
            return clantag.steam.GetClanTag(group_id)
        end
    end
end

local clantag_anim = function(text, indices)

    time_to_ticks = function(t)
        return math.floor(0.5 + (t / globals.tickinterval()))
    end

    local text_anim = "               " .. text ..                       "" 
    local tickinterval = globals.tickinterval()
    local tickcount = globals.tickcount() + time_to_ticks(client.latency())
    local i = tickcount / time_to_ticks(0.3)
    i = math.floor(i % #indices)
    i = indices[i+1]+1
    return string.sub(text_anim, i, i+15)
end

local function clantag_set()
    local lua_name = "StateW1n.pub "
    if ui.get(clantagchanger) then
        if ui.get(ui.reference("Misc", "Miscellaneous", "Clan tag spammer")) then ui.set(ui.reference("Misc", "Miscellaneous", "Clan tag spammer"), false) end

		local clan_tag = clantag_anim(lua_name, {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 11, 11, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25})

        if entity.get_prop(entity.get_game_rules(), "m_gamePhase") == 5 then
            clan_tag = clantag_anim('StateW1n.pub ', {13})
            client.set_clan_tag(clan_tag)
        elseif entity.get_prop(entity.get_game_rules(), "m_timeUntilNextPhaseStarts") ~= 0 then
            clan_tag = clantag_anim('StateW1n.pub ', {13})
            client.set_clan_tag(clan_tag)
        elseif clan_tag ~= clantag.prev_ct  then
            client.set_clan_tag(clan_tag)
        end

        clantag.prev_ct = clan_tag
        clantag.enb = true
    elseif clantag.enb == true then
        client.set_clan_tag(get_original_clantag())
        clantag.enb = false
    end
end

clantag.paint = function()
    if entity.get_local_player() ~= nil then
        if globals.tickcount() % 2 == 0 then
            clantag_set()
        end
    end
end

clantag.run_command = function(e)
    if entity.get_local_player() ~= nil then 
        if e.chokedcommands == 0 then
            clantag_set()
        end
    end
end

clantag.player_connect_full = function(e)
    if client.userid_to_entindex(e.userid) == entity.get_local_player() then 
        clantag.orig_ct = get_original_clantag()
    end
end

clantag.shutdown = function()
    client.set_clan_tag(get_original_clantag())
end

client.set_event_callback("paint", clantag.paint)
client.set_event_callback("run_command", clantag.run_command)
client.set_event_callback("player_connect_full", clantag.player_connect_full)
client.set_event_callback("shutdown", clantag.shutdown)


client.set_event_callback('net_update_end', function()
    if entity.get_local_player() ~= nil then
        is_defensive_active = is_defensive(entity.get_local_player())
    end
end)


client.set_event_callback('setup_command', function(cmd)
    if ui.get(fastladder) then
        local pitch, yaw = client.camera_angles()
        if entity.get_prop(entity.get_local_player(), "m_MoveType") == 9 then
            cmd.yaw = math.floor(cmd.yaw+0.5)
            cmd.roll = 0
            
            if cmd.forwardmove > 0 then
                if pitch < 45 then

                    cmd.pitch = 89
                    cmd.in_moveright = 1
                    cmd.in_moveleft = 0
                    cmd.in_forward = 0
                    cmd.in_back = 1

                    if cmd.sidemove == 0 then
                        cmd.yaw = cmd.yaw + 90
                    end

                    if cmd.sidemove < 0 then
                        cmd.yaw = cmd.yaw + 150
                    end

                    if cmd.sidemove > 0 then
                        cmd.yaw = cmd.yaw + 30
                    end
                end 
            end

            if cmd.forwardmove < 0 then
                cmd.pitch = 89
                cmd.in_moveleft = 1
                cmd.in_moveright = 0
                cmd.in_forward = 1
                cmd.in_back = 0
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
    end
end)


local ref = {
    leg_movement = ui.reference('AA', 'Other', 'Leg movement')
}

local ab = {}

ab.pre_render = function()
    if ui.get(anim_breakerx) then
        local local_player = entity.get_local_player()
        if not entity.is_alive(local_player) then return end

        entity.set_prop(local_player, "m_flPoseParameter", client.random_float(0.8/10, 1), 0)
        ui.set(ref.leg_movement, client.random_int(1, 2) == 1 and "Off" or "Always slide")
    end
end

ab.setup_command = function(e)
    if not ui.get(anim_breakerx) then return end

    local local_player = entity.get_local_player()
    if not entity.is_alive(local_player) then return end

    ui.set(ref.leg_movement, 'Always slide')
end

local ui_callback = function(c)
    local enabled, addr = ui.get(c), ''

    if not enabled then
        addr = 'un'
    end
    
    local _func = client[addr .. 'set_event_callback']

    _func('pre_render', ab.pre_render)
    _func('setup_command', ab.setup_command)
end

ui.set_callback(master_switch, ui_callback)
ui_callback(master_switch)

local is_on_ground = false


client.set_event_callback("setup_command", function(cmd)
    is_on_ground = cmd.in_jump == 0

    if ui.get(anim_breakerx) then
        ui.set(ref.leg_movement, cmd.command_number % 3 == 0 and "Off" or "Always slide")
    end
end)

client.set_event_callback("pre_render", function()
    local self = entity.get_local_player()
    if not self or not entity.is_alive(self) then
        return
    end

    local self_index = c_entity.new(self)
    local self_anim_state = self_index:get_anim_state()

    if not self_anim_state then
        return
    end

    if ui.get(anim_breakerx) then
        entity.set_prop(self, "m_flPoseParameter", E_POSE_PARAMETERS.STAND, globals.tickcount() % 4 > 1 and 5 / 10 or 1)
    
        local self_anim_overlay = self_index:get_anim_overlay(12)
        if not self_anim_overlay then
            return
        end

        local x_velocity = entity.get_prop(self, "m_vecVelocity[0]")
        if math.abs(x_velocity) >= 3 then
            self_anim_overlay.weight = 100 / 100
        end
    end
end)


-- Удалена секция Second Zoom FOV

client.set_event_callback('paint', function()
    cvar.r_aspectratio:set_float(ui.get(aspectratio)/100)
end)


local queue = {}

local function aim_firec(c)
	queue[globals.tickcount()] = {c.x, c.y, c.z, globals.curtime() + 2}
end

local function paintc(c)
	if ui.get(hitmarker) then
        for tick, data in pairs(queue) do
            if globals.curtime() <= data[4] then
                local x1, y1 = renderer.world_to_screen(data[1], data[2], data[3])
                if x1 ~= nil and y1 ~= nil then
                    renderer.line(x1 - 6, y1, x1 + 6, y1, 0, 100, 255, 255)  -- Синий цвет
                    renderer.line(x1, y1 - 6, x1, y1 + 6, 30, 144, 255, 255)  -- Светло-синий цвет
                end
            end
        end
    end
end

client.set_event_callback("aim_fire", aim_firec)
client.set_event_callback("paint", paintc)
client.set_event_callback("round_prestart", function() queue = {} end)


local time_to_ticks = function(t) return math_floor(0.5 + (t / globals_tickinterval())) end
local vec_substract = function(a, b) return { a[1] - b[1], a[2] - b[2], a[3] - b[3] } end
local vec_lenght = function(x, y) return (x * x + y * y) end

local g_impact = { }
local g_aimbot_data = { }
local g_sim_ticks, g_net_data = { }, { }

local cl_data = {
    tick_shifted = false,
    tick_base = 0
}

local float_to_int = function(n) 
	return n >= 0 and math.floor(n+.5) or math.ceil(n-.5)
end

local get_entities = function(enemy_only, alive_only)
    local enemy_only = enemy_only ~= nil and enemy_only or false
    local alive_only = alive_only ~= nil and alive_only or true
    
    local result = {}
    local player_resource = entity_get_player_resource()
    
    for player = 1, globals.maxplayers() do
        local is_enemy, is_alive = true, true
        
        if enemy_only and not entity_is_enemy(player) then is_enemy = false end
        if is_enemy then
            if alive_only and entity_get_prop(player_resource, 'm_bAlive', player) ~= 1 then is_alive = false end
            if is_alive then table_insert(result, player) end
        end
    end

    return result
end

local generate_flags = function(e, on_fire_data)
    return {
		e.refined and 'R' or '',
		e.expired and 'X' or '',
		e.noaccept and 'N' or '',
		cl_data.tick_shifted and 'S' or '',
		on_fire_data.teleported and 'T' or '',
		on_fire_data.interpolated and 'I' or '',
		on_fire_data.extrapolated and 'E' or '',
		on_fire_data.boosted and 'B' or '',
		on_fire_data.high_priority and 'H' or ''
    }
end

local hitgroup_names = { 'generic', 'head', 'chest', 'stomach', 'left arm', 'right arm', 'left leg', 'right leg', 'neck', '?', 'gear' }
local weapon_to_verb = { knife = 'Knifed', hegrenade = 'Naded', inferno = 'Burned' }


local function g_net_update()
	local me = entity_get_local_player()
    local players = get_entities(true, true)
	local m_tick_base = entity_get_prop(me, 'm_nTickBase')
	
    cl_data.tick_shifted = false
    
	if m_tick_base ~= nil then
		if cl_data.tick_base ~= 0 and m_tick_base < cl_data.tick_base then
			cl_data.tick_shifted = true
		end
	
		cl_data.tick_base = m_tick_base
    end

	for i=1, #players do
		local idx = players[i]
        local prev_tick = g_sim_ticks[idx]
        
        if entity_is_dormant(idx) or not entity_is_alive(idx) then
            g_sim_ticks[idx] = nil
            g_net_data[idx] = nil
        else
            local player_origin = { entity_get_origin(idx) }
            local simulation_time = time_to_ticks(entity_get_prop(idx, 'm_flSimulationTime'))
    
            if prev_tick ~= nil then
                local delta = simulation_time - prev_tick.tick

                if delta < 0 or delta > 0 and delta <= 64 then
                    local m_fFlags = entity_get_prop(idx, 'm_fFlags')

                    local diff_origin = vec_substract(player_origin, prev_tick.origin)
                    local teleport_distance = vec_lenght(diff_origin[1], diff_origin[2])

                    g_net_data[idx] = {
                        tick = delta-1,

                        origin = player_origin,
                        tickbase = delta < 0,
                        lagcomp = teleport_distance > 4096,
                    }
                end
            end

            g_sim_ticks[idx] = {
                tick = simulation_time,
                origin = player_origin,
            }
        end
    end
end


local function g_aim_fire(e)
    local data = e


    local plist_sp = plist.get(e.target, 'Override safe point')
    local plist_fa = plist.get(e.target, 'Correction active')
    local checkbox = ui.get(force_safe_point)

    if g_net_data[e.target] == nil then
        g_net_data[e.target] = { }
    end

    data.tick = e.tick

    data.eye = vector(client.eye_position)
    data.shot = vector(e.x, e.y, e.z)

    data.teleported = g_net_data[e.target].lagcomp or false
    data.choke = g_net_data[e.target].tick or '?'
    data.self_choke = globals.chokedcommands()
    data.correction = plist_fa and 1 or 0
    data.safe_point = ({
        ['Off'] = 'off',
        ['On'] = true,
        ['-'] = checkbox
    })[plist_sp]

    g_aimbot_data[e.id] = data
end

local function g_aim_hit(e)
    if not ui.get(master_switch) or g_aimbot_data[e.id] == nil then
        return
    end

    local on_fire_data = g_aimbot_data[e.id]
	local name = string.lower(entity.get_player_name(e.target))
	local hgroup = hitgroup_names[e.hitgroup + 1] or '?'
    local aimed_hgroup = hitgroup_names[on_fire_data.hitgroup + 1] or '?'
    
    local hitchance = math_floor(on_fire_data.hit_chance + 0.5) .. '%'
    local health = entity_get_prop(e.target, 'm_iHealth')

    local flags = generate_flags(e, on_fire_data)
	
    local reason = e.reason
    if reason == 'unknown' then
        reason = 'Resolver'
    end

    print(string.format(
        'Hit %s\'s %s for %i(%d) (%i remaining) aimed=%s(%s) sp=%s (%s) LC=%s TC=%s', 
        name, hgroup, e.damage, on_fire_data.damage, health, aimed_hgroup, hitchance, on_fire_data.safe_point,
        table.concat(flags), on_fire_data.self_choke, on_fire_data.choke
    ))

end

local function g_aim_miss(e)
    if not ui.get(master_switch) or g_aimbot_data[e.id] == nil then
        return
    end

    local on_fire_data = g_aimbot_data[e.id]
    local name = string.lower(entity.get_player_name(e.target))

	local hgroup = hitgroup_names[e.hitgroup + 1] or '?'
    local hitchance = math_floor(on_fire_data.hit_chance + 0.5) .. '%'

    local flags = generate_flags(e, on_fire_data)
    local reason = e.reason == '?' and 'unknown' or e.reason

    local inaccuracy = 0
    for i=#g_impact, 1, -1 do
        local impact = g_impact[i]

        if impact and impact.tick == globals.tickcount() then
            local aim, shot = 
                (impact.origin-on_fire_data.shot):angles(),
                (impact.origin-impact.shot):angles()

            inaccuracy = vector(aim-shot):length2d()
            break
        end
    end

    print(string.format(
        'StateW1n Missed %s\'s %s(%i)(%s) due to %s:%.2f°, sp=%s (%s) LC=%s TC=%s', 
        name, hgroup, on_fire_data.damage, hitchance, reason, inaccuracy, on_fire_data.safe_point, 
        table.concat(flags), on_fire_data.self_choke, on_fire_data.choke
    ))
end

local function g_player_hurt(e)
    local attacker_id = client.userid_to_entindex(e.attacker)
	
    if not ui.get(master_switch) or attacker_id == nil or attacker_id ~= entity.get_local_player() then
        return
    end

    local group = hitgroup_names[e.hitgroup + 1] or "?"
	
    if group == "generic" and weapon_to_verb[e.weapon] ~= nil then
        local target_id = client.userid_to_entindex(e.userid)
		local target_name = entity.get_player_name(target_id)

		print(string.format("%s %s for %i damage (%i remaining)", weapon_to_verb[e.weapon], string.lower(target_name), e.dmg_health, e.health))
	end
end

local function g_bullet_impact(e)
    local tick = globals.tickcount()
    local me = entity.get_local_player()
    local user = client.userid_to_entindex(e.userid)
    
    if user ~= me then
        return
    end

    if #g_impact > 150 and g_impact[#g_impact].tick ~= tick then
        g_impact = { }
    end

    g_impact[#g_impact+1] = 
    {
        tick = tick,
        origin = vector(client.eye_position()), 
        shot = vector(e.x, e.y, e.z)
    }
end

client.set_event_callback('aim_fire', g_aim_fire)
client.set_event_callback('aim_hit', g_aim_hit)
client.set_event_callback('aim_miss', g_aim_miss)
client.set_event_callback('net_update_end', g_net_update)

client.set_event_callback('player_hurt', g_player_hurt)
client.set_event_callback('bullet_impact', g_bullet_impact)

client.set_event_callback('aim_hit', g_aim_hit)
client.set_event_callback('aim_miss', g_aim_miss)
client.set_event_callback('player_hurt', g_player_hurt)

client.set_event_callback('shutdown', function()
    ui.set_visible(reference.pitch[1], true)
    ui.set_visible(reference.yaw_base, true)
    ui.set_visible(reference.yaw[1], true)
    ui.set_visible(reference.body_yaw[1], true)
    ui.set_visible(reference.edge_yaw, true)
    ui.set_visible(reference.freestanding[1], true)
    ui.set_visible(reference.freestanding[2], true)
    ui.set_visible(reference.roll, true)

    cvar.r_aspectratio:set_float(0)
    -- Удален reset override_zoom_fov
    ui.set(reference.pitch[1], 'Off')
    ui.set(reference.pitch[2], 0)
    ui.set(reference.yaw_base, 'Local view')
    ui.set(reference.yaw[1], 'Off')
    ui.set(reference.yaw[2], 0)
    ui.set(reference.yaw_jitter[1], 'Off')
    ui.set(reference.yaw_jitter[2], 0)
    ui.set(reference.body_yaw[1], 'Off')
    ui.set(reference.body_yaw[2], 0)
    ui.set(reference.freestanding_body_yaw, false)
    ui.set(reference.edge_yaw, false)
    ui.set(reference.freestanding[1], false)
    ui.set(reference.freestanding[2], 'On hotkey')
    ui.set(reference.roll, 0)
    
    -- Сброс No Spread
    ui.set(no_spread, false)
    ui.set(no_spread_mode, '◕Default◕')
    ui.set(no_spread_strength, 75)
end)

local IsNewClientAvailable = panorama.loadstring([[
	var oldClientStatus = NewsAPI.IsNewClientAvailable;

	return {
		disable: function(){
			NewsAPI.IsNewClientAvailable = function(){ return false };
		},
		restore: function(){
            NewsAPI.IsNewClientAvailable = oldClientStatus;
		}
	}
]])()

IsNewClientAvailable.disable()

client.set_event_callback("shutdown", function()
	IsNewClientAvailable.restore()
end)

ui.set_callback(dt_enabled, function()
    if ui.is_menu_open() then
        local in_rage_tab = ui.get(current_tab) == 'Rage'
        local dt_active = ui.get(dt_enabled)
        
        ui.set_visible(dt_enhanced_mode, in_rage_tab and dt_active)
        ui.set_visible(dt_adaptive_ticks, in_rage_tab and dt_active)
        ui.set_visible(dt_break_lagcomp, in_rage_tab and dt_active)
        ui.set_visible(dt_custom_ticks, in_rage_tab and dt_active and ui.get(dt_enhanced_mode) == 'Custom')
    end
end)

-- Callback для режима DT (чтобы обновлять видимость custom_ticks)
ui.set_callback(dt_enhanced_mode, function()
    if ui.is_menu_open() then
        ui.set_visible(dt_custom_ticks, ui.get(current_tab) == 'Rage' and ui.get(dt_enabled) and ui.get(dt_enhanced_mode) == 'Custom')
    end
end)

ui.set_callback(cover_awareness, function()
    if ui.is_menu_open() then
        local in_rage_tab = ui.get(current_tab) == 'Rage'
        local cover_active = ui.get(cover_awareness)
        
        ui.set_visible(cover_adaptive_aa, in_rage_tab and cover_active)
    end
end)-- dumped from hrisito forums by <youtube.com/@subtick> ~ rip hrisito 2025-2026
