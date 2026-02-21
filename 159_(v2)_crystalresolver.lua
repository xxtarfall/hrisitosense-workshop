-- Title: (V2) CrystalResolver
-- Script ID: 159
-- Source: page_159.html
----------------------------------------

-- CrystalResolver.gs V2 
-- bulid: january 1 2026 beta
-- Writted by osk4rrv

local ffi = require 'ffi'

ffi.cdef[[
    typedef struct {
        float x;
        float y;
        float z;
    } Vector;

    typedef struct {
        float m[3][4];
    } matrix3x4_t;

    struct animation_layer_t {
        char pad_0000[20];
        uint32_t m_nOrder;
        uint32_t m_nSequence;
        float m_flPrevCycle;
        float m_flWeight;
        float m_flWeightDeltaRate;
        float m_flPlaybackRate;
        float m_flCycle;
        void *m_pOwner;
        char pad_0038[4];
    };

    struct animstate_t {
        char pad[3];
        char m_bForceWeaponUpdate;
        char pad1[91];
        void* m_pBaseEntity;
        void* m_pActiveWeapon;
        void* m_pLastActiveWeapon;
        float m_flLastClientSideAnimationUpdateTime;
        int m_iLastClientSideAnimationUpdateFramecount;
        float m_flAnimUpdateDelta;
        float m_flEyeYaw;
        float m_flPitch;
        float m_flGoalFeetYaw;
        float m_flCurrentFeetYaw;
        float m_flCurrentTorsoYaw;
        float m_flUnknownVelocityLean;
        float m_flLeanAmount;
        char pad2[4];
        float m_flFeetCycle;
        float m_flFeetYawRate;
        char pad3[4];
        float m_fDuckAmount;
        float m_fLandingDuckAdditiveSomething;
        char pad4[4];
        float m_vOriginX;
        float m_vOriginY;
        float m_vOriginZ;
        float m_vLastOriginX;
        float m_vLastOriginY;
        float m_vLastOriginZ;
        float m_vVelocityX;
        float m_vVelocityY;
        char pad5[4];
        float m_flUnknownFloat1;
        char pad6[8];
        float m_flUnknownFloat2;
        float m_flUnknownFloat3;
        float m_flUnknown;
        float m_flSpeed2D;
        float m_flUpVelocity;
        float m_flSpeedNormalized;
        float m_flFeetSpeedForwardsOrSideWays;
        float m_flFeetSpeedUnknownForwardOrSideways;
        float m_flTimeSinceStartedMoving;
        float m_flTimeSinceStoppedMoving;
        bool m_bOnGround;
        bool m_bInHitGroundAnimation;
        char pad7[2];
        float m_flJumpToFall;
        float m_flTimeSinceInAir;
        float m_flLastOriginZ;
        float m_flHeadHeightOrOffsetFromHittingGroundAnimation;
        float m_flStopToFullRunningFraction;
        char pad8[4];
        float m_flMagicFraction;
        char pad9[60];
        float m_flWorldForce;
        char pad10[462];
        float m_flMaxYaw;
    };
]]

local hazedumper_offsets = {
    signatures = {
        dwEntityList = 81793068,
        dwLocalPlayer = 14596508,
        dwClientState = 5894556,
        dwGlowObjectManager = 87407312,
        dwForceAttack = 52620952,
        dwForceAttack2 = 52620964,
        dwForceForward = 52621012,
        dwForceBackward = 52621024,
        dwForceLeft = 52620880,
        dwForceRight = 52620892,
        dwForceJump = 86756744,
        dwClientState_ViewAngles = 19856,
        dwClientState_MaxPlayer = 904,
        dwClientState_PlayerInfo = 21184,
        dwClientState_State = 264,
        dwClientState_LastOutgoingCommand = 19756,
        dwClientState_ChokedCommands = 19760,
        dwClientState_DeltaTicks = 372,
        dwClientState_IsHLTV = 19784,
        dwClientState_Map = 652,
        dwClientState_MapDirectory = 392,
        dwClientState_GetLocalPlayer = 384,
        dwClientState_NetChannel = 156,
        dwViewMatrix = 81731188,
        dwInput = 86369792,
        dwGlobalVars = 5893728,
        dwGameRulesProxy = 87229844,
        dwGameDir = 6532608,
        dwMouseEnable = 86221408,
        dwMouseEnablePtr = 86221360,
        dwPlayerResource = 52613584,
        dwRadarBase = 86211332,
        dwSensitivity = 14613432,
        dwSensitivityPtr = 14613432,
        dwSetClanTag = 580272,
        dwWeaponTable = 86374108,
        dwWeaponTableIndex = 12908,
        dwYawPtr = 14612808,
        dwZoomSensitivityRatioPtr = 14635960,
        dwbSendPackets = 905938,
        dwInterfaceLinkList = 10080132,
        dwClientState_ClockDriftManager = 41200,
        dwModelPrecache = 10111688,
        dwViewRender = 81831444,
        dwSndMixTime = 10118984,
        dwClientState_PlayerInfo = 21184,
        dwClientState_ViewModel = 20464,
        dwClientState_ArmourValue = 20448,
        dwClientState_BestTimes = 19808,
        dwClientState_FOV = 20444,
        dwClientState_HltvReplay = 19880,
        dwClientState_ItemServices = 20432,
        dwClientState_KillCamEntity = 19864,
        dwClientState_LastNetSetConVar = 19872,
        dwClientState_LobbyPlayerSlot = 19884,
        dwClientState_Mapgroup = 19824,
        dwClientState_Name = 21248,
        dwClientState_NewCommands = 19748,
        dwClientState_NextCommandNr = 19764,
        dwClientState_OLREngine = 19888,
        dwClientState_OLREnvironment = 19892,
        dwClientState_OLRUIEngine = 19896,
        dwClientState_OnLevelLoadingStarted = 19792,
        dwClientState_PacketChoke = 19776,
        dwClientState_PacketStart = 19768,
        dwClientState_PlayerSlot = 19744,
        dwClientState_PostProcessingVolume = 19876,
        dwClientState_RemoteViewAngles = 19860,
        dwClientState_ScreenFade = 20456,
        dwClientState_Scoreboard = 19820,
        dwClientState_ServerAddr = 19800,
        dwClientState_SignonState = 19736,
        dwClientState_Sound = 19816,
        dwClientState_Team = 20440,
        dwClientState_Timestamp = 19740,
        dwClientState_Voice = 19832,
        dwClientState_VoiceCodec = 19836,
        dwClientState_VoiceInit = 19840,
        dwClientState_VoiceLoopback = 19844,
        dwClientState_Watch = 19848,
        dwClientState_WeaponData = 19852,
        dwClientState_WeaponForNumber = 19868,
        dwClientState_WeaponXuid = 19876,
        dwClientState_WeaponXuidLow = 19880,
        dwClientState_WeaponXuidHigh = 19884,
        dwClientState_WeaponEntity = 19888,
        dwClientState_WeaponOwner = 19892,
        dwClientState_WeaponSpread = 19896,
        dwClientState_WeaponType = 19900,
        dwClientState_WeaponName = 19904,
        dwClientState_WeaponAmmo = 19908,
        dwClientState_WeaponClip = 19912,
        dwClientState_WeaponReserve = 19916,
        dwClientState_WeaponState = 19920,
        dwClientState_WeaponFlags = 19924,
        dwClientState_WeaponModelIndex = 19928,
        dwClientState_WeaponViewModel = 19932,
        dwClientState_WeaponWorldModel = 19936,
        dwClientState_WeaponWorldModelIndex = 19940,
        dwClientState_WeaponViewModelIndex = 19944,
        dwClientState_WeaponWorldViewModelIndex = 19948,
        dwClientState_WeaponViewModelFov = 19952,
        dwClientState_WeaponWorldViewModelFov = 19956,
        dwClientState_WeaponViewModelOrigin = 19960,
        dwClientState_WeaponWorldViewModelOrigin = 19964,
        dwClientState_WeaponViewModelAngles = 19968,
        dwClientState_WeaponWorldViewModelAngles = 19972,
        dwClientState_WeaponViewModelScale = 19976,
        dwClientState_WeaponWorldViewModelScale = 19980,
        dwClientState_WeaponViewModelRenderMode = 19984,
        dwClientState_WeaponWorldViewModelRenderMode = 19988,
        dwClientState_WeaponViewModelBody = 19992,
        dwClientState_WeaponWorldViewModelBody = 19996,
        dwClientState_WeaponViewModelSkin = 20000,
        dwClientState_WeaponWorldViewModelSkin = 20004,
        dwClientState_WeaponViewModelSequence = 20008,
        dwClientState_WeaponWorldViewModelSequence = 20012,
        dwClientState_WeaponViewModelCycle = 20016,
        dwClientState_WeaponWorldViewModelCycle = 20020,
        dwClientState_WeaponViewModelAnimTime = 20024,
        dwClientState_WeaponWorldViewModelAnimTime = 20028,
        dwClientState_WeaponViewModelAnimCycle = 20032,
        dwClientState_WeaponWorldViewModelAnimCycle = 20036,
        dwClientState_WeaponViewModelSequenceActivity = 20040,
        dwClientState_WeaponWorldViewModelSequenceActivity = 20044,
        dwClientState_WeaponViewModelSequenceActivityModifier = 20048,
        dwClientState_WeaponWorldViewModelSequenceActivityModifier = 20052,
        dwClientState_WeaponViewModelSequenceActivityWeight = 20056,
        dwClientState_WeaponWorldViewModelSequenceActivityWeight = 20060,
        dwClientState_WeaponViewModelSequenceActivityWeight = 20056,
        dwClientState_WeaponWorldViewModelSequenceActivityWeight = 20060,
        dwClientState_WeaponViewModelSequenceActivityWeight = 20056,
        dwClientState_WeaponWorldViewModelSequenceActivityWeight = 20060,
    },
    netvars = {
        cs_gamerules_data = 0,
        m_ArmorValue = 71628,
        m_Collision = 800,
        m_CollisionGroup = 1140,
        m_Local = 12236,
        m_MoveType = 604,
        m_OriginalOwnerXuidHigh = 12756,
        m_OriginalOwnerXuidLow = 12752,
        m_SurvivalGameRuleDecisionTypes = 4904,
        m_SurvivalRules = 3328,
        m_aimPunchAngle = 12348,
        m_aimPunchAngleVel = 12360,
        m_angEyeAnglesX = 71632,
        m_angEyeAnglesY = 71636,
        m_bBombDefused = 10688,
        m_bBombPlanted = 2469,
        m_bBombTicking = 10640,
        m_bFreezePeriod = 32,
        m_bGunGameImmunity = 39312,
        m_bHasDefuser = 71644,
        m_bHasHelmet = 71616,
        m_bInReload = 12981,
        m_bIsDefusing = 39292,
        m_bIsQueuedMatchmaking = 116,
        m_bIsScoped = 39284,
        m_bIsValveDS = 124,
        m_bSpotted = 2365,
        m_bSpottedByMask = 2432,
        m_bStartedArming = 13312,
        m_bUseCustomAutoExposureMax = 2521,
        m_bUseCustomAutoExposureMin = 2520,
        m_bUseCustomBloomScale = 2522,
        m_clrRender = 112,
        m_dwBoneMatrix = 9896,
        m_fAccuracyPenalty = 13120,
        m_fFlags = 260,
        m_flC4Blow = 10656,
        m_flCustomAutoExposureMax = 2528,
        m_flCustomAutoExposureMin = 2524,
        m_flCustomBloomScale = 2532,
        m_flDefuseCountDown = 10684,
        m_flDefuseLength = 10680,
        m_flFallbackWear = 12768,
        m_flFlashDuration = 66672,
        m_flFlashMaxAlpha = 66668,
        m_flLastBoneSetupTime = 10536,
        m_flLowerBodyYawTarget = 39644,
        m_flNextAttack = 11648,
        m_flNextPrimaryAttack = 12872,
        m_flSimulationTime = 616,
        m_flTimerLength = 10660,
        m_hActiveWeapon = 12040,
        m_hBombDefuser = 10692,
        m_hMyWeapons = 11784,
        m_hObserverTarget = 13212,
        m_hOwner = 10716,
        m_hOwnerEntity = 332,
        m_hViewModel = 13064,
        m_iAccountID = 12248,
        m_iClip1 = 12916,
        m_iCompetitiveRanking = 6788,
        m_iCompetitiveWins = 7048,
        m_iCrosshairId = 71736,
        m_iDefaultFOV = 13116,
        m_iEntityQuality = 12220,
        m_iFOV = 12788,
        m_iFOVStart = 12792,
        m_iGlowIndex = 66696,
        m_iHealth = 256,
        m_iItemDefinitionIndex = 12218,
        m_iItemIDHigh = 12240,
        m_iMostRecentModelBoneCounter = 9872,
        m_iObserverMode = 13192,
        m_iShotsFired = 66528,
        m_iState = 12904,
        m_iTeamNum = 244,
        m_lifeState = 607,
        m_nBombSite = 10644,
        m_nFallbackPaintKit = 12760,
        m_nFallbackSeed = 12764,
        m_nFallbackStatTrak = 12772,
        m_nForceBone = 9868,
        m_nModelIndex = 600,
        m_nTickBase = 13376,
        m_nViewModelIndex = 10704,
        m_rgflCoordinateFrame = 1092,
        m_szCustomName = 12364,
        m_szLastPlaceName = 13764,
        m_thirdPersonViewAngles = 12776,
        m_vecOrigin = 312,
        m_vecVelocity = 276,
        m_vecViewOffset = 264,
        m_viewPunchAngle = 12336,
        m_zoomLevel = 13280,
    }
}


local resolver_enabled = ui.new_checkbox("RAGE", "Other", "Enable CrystalResolver")
local resolver_type = ui.new_combobox("RAGE", "Other", "Resolver Type", "Default", "Aggressive", "Defensive", "Bruteforce", "Dynamic", "LBY")
local resolver_logs = ui.new_checkbox("RAGE", "Other", "Enable Resolver Logs")


local prediction_mode = ui.new_combobox("RAGE", "Other", "Prediction Mode", "Automatic", "Manual")
local general_prediction = ui.new_slider("RAGE", "Other", "General Prediction Strength", 0, 100, 50, true, "%")


local scout_override = ui.new_checkbox("RAGE", "Other", "Override Scout Prediction Strength")
local awp_override = ui.new_checkbox("RAGE", "Other", "Override AWP Prediction Strength")
local autosniper_override = ui.new_checkbox("RAGE", "Other", "Override Auto Sniper Prediction Strength")


local scout_prediction = ui.new_slider("RAGE", "Other", "Scout Prediction Strength", 0, 100, 60, true, "%")
local awp_prediction = ui.new_slider("RAGE", "Other", "AWP Prediction Strength", 0, 100, 70, true, "%")
local autosniper_prediction = ui.new_slider("RAGE", "Other", "Auto Sniper Prediction Strength", 0, 100, 65, true, "%")

local label = ui.new_label("RAGE", "Other", "CrystalResolver V2 2026 Project by @osk4rrv")
local label2 = ui.new_label("RAGE", "Other", "Official download only from hrisitosense.top")


local weapon_prediction_values = {
    default = 50,
    scout = 60,
    awp = 70,
    autosniper = 65
}
local current_weapon = nil


local player_data = {}
local MAX_PLAYERS = 64


for i = 1, MAX_PLAYERS do
    player_data[i] = {
        last_eye_yaw = 0,
        last_lby = 0,
        lby_timer = 0,
        update_time = 0,
        shot_angles = {},
        shot_count = 0,
        last_shot_time = 0,
        misses = 0,
        hit_angles = {},
        hit_count = 0,
        resolver_mode = "default",
        current_offset = 0,
        last_update = 0,
        is_moving = false,
        on_ground = false,
        velocity = 0,
        last_simtime = 0,
        backtrack_records = {},
        is_fakelagging = false,
        fakelag_ticks = 0,
        lby_updated = false,
        last_lby_update = 0,
        lby_delta = 0,
        desync_delta = 0,
        resolved_yaw = 0,
        fake_angles_detected = false,
        last_miss_reason = "",
        hit_ratio = 0.0,
        prediction_data = {},
        animstate_data = {},
        resolver_state = "idle",
        resolver_confidence = 0.0,
        resolver_method = "none",
        hit_angles_history = {},
        hit_count_history = 0,
        miss_angles_history = {},
        miss_count_history = 0,
        last_hit_time = 0,
        last_miss_time = 0,
        hit_streak = 0,
        miss_streak = 0,
        adaptive_factor = 1.0,
        last_velocity = 0,
        velocity_delta = 0,
        on_peek = false,
        peek_start_time = 0,
        last_peek_time = 0,
        peek_angle = 0,
        is_jumping = false,
        is_crouching = false,
        duck_amount = 0,
        flags = 0,
        last_flags = 0,
        lby_flicker_detector = 0,
        lby_flicker_count = 0,
        lby_flicker_threshold = 0,
        lby_flicker_active = false,
        anim_layers = {},
        anim_layer_history = {},
        last_anim_update = 0,
        anim_delta = 0,
        anim_delta_history = {},
        anim_delta_avg = 0,
        anim_delta_variance = 0,
        desync_pattern = "unknown",
        desync_pattern_confidence = 0,
        desync_history = {},
        desync_avg = 0,
        desync_variance = 0,
        last_desync_update = 0,
        desync_trend = 0,
        desync_trend_confidence = 0,
        lby_history = {},
        lby_avg = 0,
        lby_variance = 0,
        lby_trend = 0,
        lby_trend_confidence = 0,
        eye_yaw_history = {},
        eye_yaw_avg = 0,
        eye_yaw_variance = 0,
        eye_yaw_trend = 0,
        eye_yaw_trend_confidence = 0,
        resolver_accuracy = 0.0,
        resolver_accuracy_history = {},
        resolver_accuracy_avg = 0.0,
        resolver_method_success = {},
        resolver_method_attempts = {},
        resolver_method_hits = {},
        resolver_method_misses = {},
        resolver_method_accuracy = {},
        last_resolver_update = 0,
        resolver_cycle = 0,
        resolver_cycle_max = 8,
        resolver_cycle_delay = 0,
        resolver_cycle_active = false,
        resolver_cycle_start = 0,
        resolver_cycle_end = 0,
        resolver_cycle_target = 0,
        resolver_cycle_current = 0,
        resolver_cycle_delta = 0,
        resolver_cycle_direction = 1,
        resolver_cycle_pattern = {},
        resolver_cycle_pattern_idx = 1,
        resolver_cycle_pattern_size = 0,
        resolver_cycle_pattern_active = false,
        resolver_cycle_pattern_last = 0,
        resolver_cycle_pattern_next = 0,
        resolver_cycle_pattern_complete = false,
        resolver_cycle_pattern_success = false,
        resolver_cycle_pattern_failures = 0,
        resolver_cycle_pattern_successes = 0,
        resolver_cycle_pattern_accuracy = 0.0,
        resolver_cycle_pattern_attempts = 0,
        resolver_cycle_pattern_hits = 0,
        resolver_cycle_pattern_misses = 0,
        resolver_cycle_pattern_last_update = 0,
        resolver_cycle_pattern_next_update = 0,
        resolver_cycle_pattern_update_interval = 0,
        resolver_cycle_pattern_update_counter = 0,
        resolver_cycle_pattern_update_threshold = 0,
        resolver_cycle_pattern_update_active = false,
        resolver_cycle_pattern_update_pending = false,
        resolver_cycle_pattern_update_required = false,
        resolver_cycle_pattern_update_scheduled = false,
        resolver_cycle_pattern_update_delayed = false,
        resolver_cycle_pattern_update_delay = 0,
        resolver_cycle_pattern_update_delay_counter = 0,
        resolver_cycle_pattern_update_delay_max = 0,
        resolver_cycle_pattern_update_delay_active = false,
        resolver_cycle_pattern_update_delay_pending = false,
        resolver_cycle_pattern_update_delay_required = false,
        resolver_cycle_pattern_update_delay_scheduled = false,
        resolver_cycle_pattern_update_delay_delayed = false,
        
        
        desync_direction = 1,
        current_pitch = 0,
        last_pitch = 0,
        pitch_delta = 0,
        shots_fired = 0,
        last_shots_fired = 0,
        shot_fired = false,
        prev_simtime = 0,
        prev_tickbase = 0,
        jitter_pattern = "unknown",
        jitter_amount = 0,
        jitter_frequency = 0,
        lby_flick_detected = false,
        miss_count = 0,
        
        
        shot_cache = {},
        last_shot_time = 0,
        last_shot_yaw = 0,
        last_resolver_offset = 0,
        last_shot_tick = 0,
    }
end


local function normalize_yaw(yaw)
    while yaw > 180 do yaw = yaw - 360 end
    while yaw < -180 do yaw = yaw + 360 end
    return yaw
end

local function angle_diff(a, b)
    local diff = math.abs(normalize_yaw(a) - normalize_yaw(b))
    return diff > 180 and 360 - diff or diff
end

local function get_velocity(player)
    local vx = entity.get_prop(player, "m_vecVelocity[0]") or 0
    local vy = entity.get_prop(player, "m_vecVelocity[1]") or 0
    local vz = entity.get_prop(player, "m_vecVelocity[2]") or 0
    return math.sqrt(vx*vx + vy*vy + vz*vz)
end

local function is_moving(player)
    local velocity = get_velocity(player)
    return velocity > 5
end

local function is_on_ground(player)
    local flags = entity.get_prop(player, "m_fFlags") or 0
    return bit.band(flags, 1) == 1
end

local function is_crouching(player)
    local duck_amount = entity.get_prop(player, "m_flDuckAmount") or 0
    return duck_amount > 0.5
end

local function is_jumping(player)
    local flags = entity.get_prop(player, "m_fFlags") or 0
    return bit.band(flags, 1) == 0
end

local function get_last_shot(player)
    if not player_data[player] or not player_data[player].shot_cache then
        return {
            player = player,
            time = 0,
            tick = 0,
            eye_yaw = 0,
            lby = 0,
            resolver_offset = 0,
            simtime = 0,
            shot_number = 0,
        }
    end
    
    local shot_cache = player_data[player].shot_cache
    if #shot_cache > 0 then
        return shot_cache[1]  
    else
        return {
            player = player,
            time = 0,
            tick = 0,
            eye_yaw = 0,
            lby = 0,
            resolver_offset = 0,
            simtime = 0,
            shot_number = 0,
        }
    end
end


local function update_player_state(player, data)
    data.is_moving = is_moving(player)
    data.on_ground = is_on_ground(player)
    data.is_crouching = is_crouching(player)
    data.is_jumping = is_jumping(player)
    data.velocity = get_velocity(player)
    data.velocity_delta = math.abs(data.velocity - data.last_velocity)
    data.last_velocity = data.velocity
    
    data.last_flags = data.flags
    data.flags = entity.get_prop(player, "m_fFlags") or 0
    
    data.duck_amount = entity.get_prop(player, "m_flDuckAmount") or 0
    
    local simtime = entity.get_prop(player, "m_flSimulationTime") or 0
    if simtime <= data.last_simtime then
        data.is_fakelagging = true
        data.fakelag_ticks = data.fakelag_ticks + 1
    else
        data.is_fakelagging = false
        data.fakelag_ticks = 0
    end
    data.last_simtime = simtime
    
    local lby = entity.get_prop(player, "m_flLowerBodyYawTarget") or 0
    local eye_yaw = entity.get_prop(player, "m_angEyeAngles[1]") or 0
    
    local old_lby = data.last_lby
    data.last_lby = lby
    
    if math.abs(angle_diff(lby, old_lby)) > 35 and data.is_moving == false and data.on_ground then
        data.lby_updated = true
        data.last_lby_update = globals.curtime()
    else
        data.lby_updated = false
    end
    
    data.lby_delta = angle_diff(eye_yaw, lby)
    
    data.desync_direction = (eye_yaw - lby) > 0 and 1 or -1
    
    data.last_eye_yaw = eye_yaw
    
    data.update_time = globals.curtime()
    
    data.last_pitch = data.current_pitch or 0
    data.current_pitch = entity.get_prop(player, "m_angEyeAngles[0]") or 0
    data.pitch_delta = math.abs(data.current_pitch - data.last_pitch)
    
    data.last_shots_fired = data.shots_fired or 0
    data.shots_fired = entity.get_prop(player, "m_iShotsFired") or 0
    data.shot_fired = data.shots_fired > data.last_shots_fired
end

local function detect_fakelag(player, data)
    local simtime = entity.get_prop(player, "m_flSimulationTime") or 0
    local tickbase = entity.get_prop(player, "m_nTickBase") or 0
    
    if not data.prev_simtime then
        data.prev_simtime = simtime
        data.prev_tickbase = tickbase
        return false
    end
    
    local expected_simtime = data.prev_simtime + (tickbase - data.prev_tickbase) * globals.tickinterval()
    local simtime_diff = math.abs(simtime - expected_simtime)
    
    local is_fakelagging = simtime_diff > globals.tickinterval() * 2
    
    data.prev_simtime = simtime
    data.prev_tickbase = tickbase
    
    return is_fakelagging
end

local function detect_jitter_pattern(player, data)
    local eye_yaw = entity.get_prop(player, "m_angEyeAngles[1]") or 0
    
    table.insert(data.eye_yaw_history, 1, {yaw = eye_yaw, time = globals.curtime()})
    if #data.eye_yaw_history > 20 then
        table.remove(data.eye_yaw_history)
    end
    
    if #data.eye_yaw_history < 3 then
        return "unknown", 0
    end
    
    local changes = 0
    local total_change = 0
    local last_yaw = data.eye_yaw_history[1].yaw
    
    for i = 2, #data.eye_yaw_history do
        local current_yaw = data.eye_yaw_history[i].yaw
        local diff = angle_diff(current_yaw, last_yaw)
        
        if diff > 5 then 
            changes = changes + 1
            total_change = total_change + diff
        end
        
        last_yaw = current_yaw
    end
    
    local avg_change = total_change / math.max(1, changes)
    local change_frequency = changes / #data.eye_yaw_history
    
    local pattern = "unknown"
    if change_frequency < 0.1 then
        pattern = "static"
    elseif change_frequency < 0.3 then
        pattern = "predictable"
    elseif change_frequency < 0.6 then
        pattern = "semi_random"
    else
        pattern = "random"
    end
    
    data.jitter_pattern = pattern
    data.jitter_amount = avg_change
    data.jitter_frequency = change_frequency
    
    return pattern, avg_change
end

local function detect_lby_flick(player, data)
    local lby = entity.get_prop(player, "m_flLowerBodyYawTarget") or 0
    
    table.insert(data.lby_history, 1, {yaw = lby, time = globals.curtime()})
    if #data.lby_history > 10 then
        table.remove(data.lby_history)
    end
    
    if #data.lby_history < 2 then
        return false
    end
    
    local flick_detected = false
    for i = 1, #data.lby_history - 1 do
        local diff = angle_diff(data.lby_history[i].yaw, data.lby_history[i+1].yaw)
        if diff > 35 then 
            flick_detected = true
            break
        end
    end
    
    data.lby_flick_detected = flick_detected
    return flick_detected
end

local function detect_animation_layers(player, data)
    local layer_12_weight = entity.get_prop(player, "m_flPoseParameter[12]") or 0 
    
    table.insert(data.anim_layer_history, 1, {
        weight = layer_12_weight,
        time = globals.curtime()
    })
    
    if #data.anim_layer_history > 10 then
        table.remove(data.anim_layer_history)
    end
    
    if #data.anim_layer_history >= 2 then
        local prev_weight = data.anim_layer_history[2].weight
        data.anim_delta = math.abs(layer_12_weight - prev_weight)
        
        
        table.insert(data.anim_delta_history, 1, data.anim_delta)
        if #data.anim_delta_history > 10 then
            table.remove(data.anim_delta_history)
        end
        
        
        local sum = 0
        for i = 1, #data.anim_delta_history do
            sum = sum + data.anim_delta_history[i]
        end
        data.anim_delta_avg = sum / #data.anim_delta_history
    end
end

local function detect_desync_pattern(player, data)
    table.insert(data.desync_history, 1, data.lby_delta)
    if #data.desync_history > 20 then
        table.remove(data.desync_history)
    end
    
    if #data.desync_history >= 5 then
        local sum = 0
        for i = 1, #data.desync_history do
            sum = sum + data.desync_history[i]
        end
        data.desync_avg = sum / #data.desync_history
        
        local variance_sum = 0
        for i = 1, #data.desync_history do
            local diff = data.desync_history[i] - data.desync_avg
            variance_sum = variance_sum + diff * diff
        end
        data.desync_variance = variance_sum / #data.desync_history
        
        
        if #data.desync_history >= 3 then
            local recent_avg = 0
            for i = 1, 3 do
                recent_avg = recent_avg + data.desync_history[i]
            end
            recent_avg = recent_avg / 3
            
            local older_avg = 0
            for i = 4, 6 do
                if data.desync_history[i] then
                    older_avg = older_avg + data.desync_history[i]
                end
            end
            if older_avg ~= 0 then
                older_avg = older_avg / math.min(3, #data.desync_history - 3)
                data.desync_trend = recent_avg - older_avg
            end
        end
        
        
        if data.desync_variance < 5 then
            data.desync_pattern = "static"
        elseif data.desync_variance < 20 and math.abs(data.desync_trend) < 5 then
            data.desync_pattern = "predictable"
        elseif math.abs(data.desync_trend) > 10 then
            data.desync_pattern = "trending"
        else
            data.desync_pattern = "random"
        end
        
        data.desync_pattern_confidence = math.min(1.0, data.desync_variance / 30)
    end
end


local function resolver_default(player, data)
    if data.lby_updated and math.abs(data.lby_delta) < 35 then
        return data.lby_delta
    else
        return 0
    end
end

local function resolver_aggressive(player, data)
    if data.lby_delta ~= 0 then
        return data.desync_direction * 58
    else
        
        if data.desync_pattern == "static" then
            return data.desync_avg
        elseif data.desync_pattern == "predictable" then
            return data.lby_delta
        else
            
            return 45 * data.desync_direction
        end
    end
end

local function resolver_defensive(player, data)
    if data.lby_delta > 35 then
        return -data.lby_delta * 0.8 
    elseif data.lby_delta < -35 then
        return -data.lby_delta * 0.8
    elseif math.abs(data.lby_delta) < 10 then
        
        return 50 * data.desync_direction
    else
        
        return data.lby_delta
    end
end

local function resolver_bruteforce(player, data)
    data.resolver_cycle = (data.resolver_cycle + 1) % data.resolver_cycle_max
    
    if data.hit_ratio < 0.3 then
        
        local aggressive_offsets = {0, 25, -25, 45, -45, 58, -58, 35, -35}
        return aggressive_offsets[(data.resolver_cycle % #aggressive_offsets) + 1]
    elseif data.hit_ratio > 0.7 then
        
        local fine_offsets = {data.current_offset - 5, data.current_offset, data.current_offset + 5}
        return fine_offsets[(data.resolver_cycle % #fine_offsets) + 1]
    else
        
        local standard_offsets = {0, 15, -15, 30, -30, 45, -45, 60, -60}
        return standard_offsets[(data.resolver_cycle % #standard_offsets) + 1]
    end
end

local function resolver_lby(player, data)
    if data.lby_updated then
        return data.lby_delta
    else
        
        if #data.lby_history >= 3 then
            local sum = 0
            for i = 1, math.min(3, #data.lby_history) do
                sum = sum + data.lby_history[i].yaw
            end
            local avg_lby = sum / math.min(3, #data.lby_history)
            local current_eye = entity.get_prop(player, "m_angEyeAngles[1]") or 0
            return angle_diff(current_eye, avg_lby)
        else
            return 0
        end
    end
end

local function resolver_dynamic(player, data)
    
    local method_scores = {}
    
    local lby_score = 0
    if data.lby_updated and globals.curtime() - data.last_lby_update < 0.5 then
        lby_score = 0.9
    elseif data.lby_updated then
        lby_score = 0.7 
    end
    method_scores.lby = lby_score
    
    local pattern_score = 0
    if data.desync_pattern ~= "unknown" then
        pattern_score = data.desync_pattern_confidence
        
        if data.desync_variance < 10 then
            pattern_score = pattern_score * 1.2
        end
    end
    method_scores.pattern = pattern_score
    
    local hit_score = 0
    if data.hit_ratio > 0.7 then
        hit_score = data.hit_ratio
    elseif data.hit_ratio < 0.3 then
        hit_score = 0.4 
    else
        hit_score = 0.5
    end
    method_scores.adaptive = hit_score
    
    local movement_score = 0
    if data.is_moving and data.velocity > 100 then
        movement_score = 0.7
        
        if data.velocity_delta < 5 then
            movement_score = movement_score * 1.1
        end
    elseif not data.on_ground then
        movement_score = 0.8 
    elseif data.is_crouching then
        movement_score = 0.6 
    end
    method_scores.movement = movement_score
    
    local fakelag_score = 0
    if data.is_fakelagging then
        fakelag_score = 0.6 
    elseif data.fakelag_ticks > 5 then
        fakelag_score = 0.7
    end
    method_scores.fakelag = fakelag_score
    
    local jitter_score = 0
    if data.jitter_pattern ~= "unknown" then
        if data.jitter_pattern == "static" then
            jitter_score = 0.8
        elseif data.jitter_pattern == "predictable" then
            jitter_score = 0.7
        else
            jitter_score = 0.5
        end
    end
    method_scores.jitter = jitter_score
    
    local bruteforce_score = 0
    if data.hit_ratio < 0.3 and data.resolver_method ~= "bruteforce" then
        bruteforce_score = 0.7 
    elseif data.hit_ratio > 0.7 and data.resolver_method == "bruteforce" then
        bruteforce_score = 0.1 
    else
        bruteforce_score = 0.4
    end
    method_scores.bruteforce = bruteforce_score
    
    local best_method = "default"
    local best_score = 0
    
    for method, score in pairs(method_scores) do
        if score > best_score then
            best_score = score
            best_method = method
        end
    end
    
    local context_multiplier = 1.0
    
    if data.resolver_method ~= best_method and data.hit_streak > 2 then
        context_multiplier = 0.8 
    end
    
    if data.miss_streak > 3 then
        context_multiplier = 1.2 
    end
    
    local offset = 0
    
    if best_method == "lby" then
        offset = resolver_lby(player, data)
    elseif best_method == "pattern" then
        if data.desync_pattern == "static" then
            offset = data.desync_avg
        elseif data.desync_pattern == "predictable" then
            offset = data.lby_delta
        elseif data.desync_pattern == "trending" then
            
            offset = data.lby_delta + data.desync_trend
        else
            offset = resolver_bruteforce(player, data)
        end
    elseif best_method == "adaptive" then
        if data.hit_ratio > 0.7 then
            
            offset = data.current_offset * 0.98
        elseif data.hit_ratio < 0.3 then
            
            offset = -data.current_offset
        else
            offset = data.lby_delta
        end
    elseif best_method == "movement" then
        
        local eye_yaw = entity.get_prop(player, "m_angEyeAngles[1]") or 0
        local velocity_yaw = math.atan2(entity.get_prop(player, "m_vecVelocity[1]") or 0, 
                                      entity.get_prop(player, "m_vecVelocity[0]") or 0)
        velocity_yaw = velocity_yaw * 180 / math.pi
        
        if data.is_moving then
            
            local movement_diff = angle_diff(eye_yaw, velocity_yaw)
            offset = movement_diff * 0.5 
        elseif not data.on_ground then
            
            offset = data.lby_delta * 0.3
        elseif data.is_crouching then
            
            offset = data.lby_delta * 1.2
        end
    elseif best_method == "fakelag" then
        
        if data.fakelag_ticks > 10 then
            
            offset = data.lby_delta * 0.7
        else
            
            offset = data.lby_delta
        end
    elseif best_method == "jitter" then
        
        if data.jitter_pattern == "static" then
            offset = data.lby_delta
        elseif data.jitter_pattern == "semi_random" then
            
            offset = data.lby_delta * 0.8
        else
            
            offset = resolver_bruteforce(player, data)
        end
    elseif best_method == "bruteforce" then
        offset = resolver_bruteforce(player, data)
    else
        offset = resolver_default(player, data)
    end
    
    offset = offset * context_multiplier
    
    offset = math.max(-58, math.min(58, offset))
    
    data.resolver_method = best_method
    data.resolver_confidence = best_score
    
    return offset
end

local function calculate_resolver_offset(player, data)
    local resolver_type_val = ui.get(resolver_type) or "Default"  
    local offset = 0
    
    if resolver_type_val == "Default" then
        offset = resolver_default(player, data)
    elseif resolver_type_val == "Aggressive" then
        offset = resolver_aggressive(player, data)
    elseif resolver_type_val == "Defensive" then
        offset = resolver_defensive(player, data)
    elseif resolver_type_val == "Bruteforce" then
        offset = resolver_bruteforce(player, data)
    elseif resolver_type_val == "LBY" then
        offset = resolver_lby(player, data)
    elseif resolver_type_val == "Dynamic" then
        offset = resolver_dynamic(player, data)
    end
    
    offset = math.max(-58, math.min(58, offset))
    
    offset = offset * data.adaptive_factor
    
    if data.is_fakelagging then
        
        offset = offset * 0.8
    end
    
    if data.lby_flick_detected then
        
        if #data.lby_history >= 5 then
            local sum = 0
            for i = 1, 3 do
                sum = sum + data.lby_history[i].yaw
            end
            local recent_avg = sum / 3
            local current_eye = entity.get_prop(player, "m_angEyeAngles[1]") or 0
            local flick_adjusted = angle_diff(current_eye, recent_avg)
            offset = flick_adjusted
        end
    end
    
    data.current_offset = offset
    
    return offset
end

local function update_resolver_accuracy(player, data)
    local total_shots = data.hit_count + data.miss_count
    if total_shots > 0 then
        data.hit_ratio = data.hit_count / total_shots
    else
        data.hit_ratio = 0.0
    end
    
    table.insert(data.resolver_accuracy_history, 1, data.hit_ratio)
    if #data.resolver_accuracy_history > 10 then
        table.remove(data.resolver_accuracy_history)
    end
    
    local sum = 0
    for i = 1, #data.resolver_accuracy_history do
        sum = sum + data.resolver_accuracy_history[i]
    end
    data.resolver_accuracy_avg = sum / #data.resolver_accuracy_history
end

local function adaptive_resolver_adjustment(player, data)
    if data.hit_ratio > 0.7 then
        
        data.adaptive_factor = math.min(1.2, data.adaptive_factor + 0.05)
    elseif data.hit_ratio < 0.4 then
        
        data.adaptive_factor = math.max(0.7, data.adaptive_factor - 0.1)
    else
        
        if data.adaptive_factor > 1.0 then
            data.adaptive_factor = math.max(1.0, data.adaptive_factor - 0.02)
        elseif data.adaptive_factor < 1.0 then
            data.adaptive_factor = math.min(1.0, data.adaptive_factor + 0.02)
        end
    end
end

local function dynamic_resolver_system(player, data)
    local best_method = "default"
    local best_confidence = 0.0
    
    if data.lby_updated and globals.curtime() - data.last_lby_update < 1.0 then
        best_method = "lby"
        best_confidence = 0.9
    end
    
    if data.desync_pattern ~= "unknown" and data.desync_pattern_confidence > 0.6 then
        best_method = "pattern"
        best_confidence = math.max(best_confidence, data.desync_pattern_confidence)
    end
    
    if data.hit_ratio > 0.6 then
        best_method = "adaptive"
        best_confidence = math.max(best_confidence, data.hit_ratio)
    elseif data.hit_ratio < 0.3 then
        best_method = "bruteforce"
        best_confidence = math.max(best_confidence, 0.5)
    end
    
    data.resolver_method = best_method
    data.resolver_confidence = best_confidence
    data.resolver_state = "active"
    
    
    if not data.resolver_method_attempts[best_method] then
        data.resolver_method_attempts[best_method] = 0
    end
    if not data.resolver_method_hits[best_method] then
        data.resolver_method_hits[best_method] = 0
    end
    if not data.resolver_method_misses[best_method] then
        data.resolver_method_misses[best_method] = 0
    end
    
    data.resolver_method_attempts[best_method] = data.resolver_method_attempts[best_method] + 1
end

local function resolver_update()
    if not ui.get(resolver_enabled) then
        return
    end
    
    local players = entity.get_players(true)
    
    for _, player in ipairs(players) do
        if entity.is_alive(player) then
            local data = player_data[player]
            
            update_player_state(player, data)
            
            detect_desync_pattern(player, data)
            
            update_resolver_accuracy(player, data)
            
            adaptive_resolver_adjustment(player, data)
            
            dynamic_resolver_system(player, data)
            
            local offset = calculate_resolver_offset(player, data)
            data.current_offset = offset
            
            plist.set(player, "Force Body Yaw", true)
            plist.set(player, "Force Body Yaw Value", offset)
            
            local mode = ui.get(prediction_mode) or "Automatic"  
            local strength = (ui.get(general_prediction) or 50) / 100  
            
            if mode == "Manual" then
                local local_player = entity.get_local_player()
                if local_player then
                    local active_weapon = entity.get_player_weapon(local_player)
                    if active_weapon then
                        local weapon_name = entity.get_classname(active_weapon):gsub("CWeapon", ""):lower()
                        
                        
                        if weapon_name == "ssg08" and ui.get(scout_override) then
                            strength = (ui.get(scout_prediction) or 60) / 100
                        elseif weapon_name == "awp" and ui.get(awp_override) then
                            strength = (ui.get(awp_prediction) or 70) / 100
                        elseif (weapon_name == "scar20" or weapon_name == "g3sg1") and ui.get(autosniper_override) then
                            strength = (ui.get(autosniper_prediction) or 65) / 100
                        end
                    end
                end
            end
            
            offset = offset * strength
            
            plist.set(player, "Force Body Yaw", true)
            plist.set(player, "Force Body Yaw Value", offset)
        end
    end
end


client.set_event_callback("net_update_end", resolver_update)


client.set_event_callback("weapon_fire", function(e)
    if not ui.get(resolver_enabled) then return end
    
    local player = e.userid
    local entindex = client.userid_to_entindex(player)
    
    if entindex and entity.is_enemy(entindex) then
        local eye_yaw = entity.get_prop(entindex, "m_angEyeAngles[1]") or 0
        local lby = entity.get_prop(entindex, "m_flLowerBodyYawTarget") or 0
        local simtime = entity.get_prop(entindex, "m_flSimulationTime") or 0
        local tickbase = entity.get_prop(entindex, "m_nTickBase") or 0
        
        local data = player_data[entindex]
        local resolver_offset = data and data.current_offset or 0
        
        
        local shot_record = {
            player = entindex,
            time = globals.curtime(),
            tick = tickbase,
            eye_yaw = eye_yaw,
            lby = lby,
            resolver_offset = resolver_offset,
            simtime = simtime,
            shot_number = globals.tickcount(), 
        }
        
        if not player_data[entindex].shot_cache then
            player_data[entindex].shot_cache = {}
        end
        
        table.insert(player_data[entindex].shot_cache, 1, shot_record)
        if #player_data[entindex].shot_cache > 10 then
            table.remove(player_data[entindex].shot_cache, #player_data[entindex].shot_cache)
        end
        
        player_data[entindex].last_shot_time = globals.curtime()
        player_data[entindex].last_shot_yaw = eye_yaw
        player_data[entindex].last_resolver_offset = resolver_offset
        player_data[entindex].last_shot_tick = tickbase
    end
end)


client.set_event_callback("aim_hit", function(e)
    if not ui.get(resolver_enabled) then return end
    
    local player = e.target
    if not player_data[player] then return end
    
    local data = player_data[player]
    data.hit_count = data.hit_count + 1
    data.last_hit_time = globals.curtime()
    data.hit_streak = data.hit_streak + 1
    data.miss_streak = 0
    
    local eye_yaw = entity.get_prop(player, "m_angEyeAngles[1]") or 0
    table.insert(data.hit_angles_history, 1, {yaw = eye_yaw, time = globals.curtime()})
    if #data.hit_angles_history > 10 then
        table.remove(data.hit_angles_history)
    end
    
    
    if data.resolver_method and data.resolver_method_hits[data.resolver_method] then
        data.resolver_method_hits[data.resolver_method] = data.resolver_method_hits[data.resolver_method] + 1
    end
    
    if ui.get(resolver_logs) then
        local player_name = entity.get_player_name(player) or "Unknown"
        local hitgroup_names = {'generic', 'head', 'chest', 'stomach', 'left arm', 'right arm', 'left leg', 'right leg', 'neck', 'gear'}
        local hitbox = hitgroup_names[e.hitgroup + 1] or '?'
        local hitchance = e.hit_chance or 0 
        
        
        local shot = get_last_shot(player)
        local resolver_yaw_choice = shot.resolver_offset or 0
        
        
        local actual_eye_yaw = entity.get_prop(player, "m_angEyeAngles[1]") or 0
        local actual_lby = entity.get_prop(player, "m_flLowerBodyYawTarget") or 0
        local actual_desync = angle_diff(actual_eye_yaw, actual_lby)
        
        
        local missmatch = angle_diff(math.abs(resolver_yaw_choice), math.abs(actual_desync))
        
        client.color_log(150, 255, 150, string.format("[CrystalResolver] Hit %s in %s for %d [%d HP Left | hc: %d%% | Missmatch: %.2f]", player_name, hitbox, e.damage, entity.get_prop(player, 'm_iHealth') or 0, math.floor(hitchance * 1), missmatch))
    end
end)

client.set_event_callback("aim_miss", function(e)
    if not ui.get(resolver_enabled) then return end
    
    local player = e.target
    if not player_data[player] then return end
    
    local data = player_data[player]
    data.miss_count = data.miss_count + 1
    data.last_miss_time = globals.curtime()
    data.miss_streak = data.miss_streak + 1
    data.hit_streak = 0
    data.last_miss_reason = e.reason or "unknown"
    
    local eye_yaw = entity.get_prop(player, "m_angEyeAngles[1]") or 0
    table.insert(data.miss_angles_history, 1, {yaw = eye_yaw, time = globals.curtime()})
    if #data.miss_angles_history > 10 then
        table.remove(data.miss_angles_history)
    end
    
    
    if data.resolver_method and data.resolver_method_misses[data.resolver_method] then
        data.resolver_method_misses[data.resolver_method] = data.resolver_method_misses[data.resolver_method] + 1
    end
    
    if ui.get(resolver_logs) then
        local player_name = entity.get_player_name(player) or "Unknown"
        local hitgroup_names = {'generic', 'head', 'chest', 'stomach', 'left arm', 'right arm', 'left leg', 'right leg', 'neck', 'gear'}
        local hitbox = hitgroup_names[e.hitgroup + 1] or '?'
        local reason = e.reason or "unknown"
        
        
        local shot = get_last_shot(player)
        local resolver_yaw_choice = shot.resolver_offset or 0
        
        
        local actual_eye_yaw = entity.get_prop(player, "m_angEyeAngles[1]") or 0
        local actual_lby = entity.get_prop(player, "m_flLowerBodyYawTarget") or 0
        local actual_desync = angle_diff(actual_eye_yaw, actual_lby)
        
        
        local missmatch = angle_diff(math.abs(resolver_yaw_choice), math.abs(actual_desync))

        if missmatch > 20 and data.miss_streak >= 2 then
            if not data.state_confidence then data.state_confidence = 1.0 end
            data.state_confidence = data.state_confidence - 0.2
        end

        local hitchance = e.hit_chance or 0 

        client.color_log(255, 100, 100, string.format("[CrystalResolver] Missed %s in %s due to %s [Missmatch: %.2f | hc: %d%% ]", player_name, hitbox, reason, missmatch, math.floor(hitchance * 1)))
    end
end)


local function update_ui_visibility()
    local enabled = ui.get(resolver_enabled)
    
    ui.set_visible(resolver_type, enabled)
    ui.set_visible(resolver_logs, enabled)
    ui.set_visible(prediction_mode, enabled)
    
    local mode = ui.get(prediction_mode)
    ui.set_visible(general_prediction, enabled and mode == "Manual")
    
    ui.set_visible(scout_override, enabled and mode == "Manual")
    ui.set_visible(awp_override, enabled and mode == "Manual")
    ui.set_visible(autosniper_override, enabled and mode == "Manual")
    
    ui.set_visible(scout_prediction, enabled and mode == "Manual" and ui.get(scout_override))
    ui.set_visible(awp_prediction, enabled and mode == "Manual" and ui.get(awp_override))
    ui.set_visible(autosniper_prediction, enabled and mode == "Manual" and ui.get(autosniper_override))
end

ui.set_callback(resolver_enabled, update_ui_visibility)
ui.set_callback(prediction_mode, update_ui_visibility)
ui.set_callback(scout_override, update_ui_visibility)
ui.set_callback(awp_override, update_ui_visibility)
ui.set_callback(autosniper_override, update_ui_visibility)
update_ui_visibility()

client.exec "clear"
client.color_log(0, 255, 0, "[CrystalResolver] CrystalResolver Loaded successfully!")
client.color_log(0, 200, 255, "[CrystalResolver] Your version is: V2 | Created by @osk4rrv")


local function draw_center_text()
    local screen_w, screen_h = client.screen_size()
    local text = "CrystalResolver V2 by @osk4rrv"
    
    local text_w, text_h = renderer.measure_text("c", text)
    
    local x = screen_w / 2
    local y = screen_h - 30
    
    renderer.text(x, y, 255, 255, 255, 255, "c", 0, text)
end

client.set_event_callback("paint", draw_center_text)


local original_clantag = client.get_clan_tag and client.get_clan_tag() or ""

local function update_clantag()
    if ui.get(resolver_enabled) then
        client.set_clan_tag("CrystalResolver")
    else
        client.set_clan_tag(original_clantag)
    end
end


local kill_messages = {
    "get good get crystalresolver",
    "ONLY crystalresolver",
    "2 top script on hrisito forums",
    "1",
    "ez. ",
    "dyk that having a crystalresolver is a flex",
    "are you for real? i thought you were a bot",
    "osk4rrv cooked",
    "just grab a link: bit.ly/crystal-resolver",
    "i bet youre mad rn"
}

client.set_event_callback("player_death", function(e)
    
    if not ui.get(resolver_enabled) then return end
    
    local attacker = client.userid_to_entindex(e.attacker)
    local victim = client.userid_to_entindex(e.userid)
    local local_player = entity.get_local_player()
    
    if attacker == local_player and victim ~= local_player then
        
        local random_message = kill_messages[math.random(#kill_messages)]
        client.exec("say " .. random_message)
    end
end)


client.set_event_callback("paint", function()
    update_clantag()
end)


client.set_event_callback("shutdown", function()
    client.set_clan_tag(original_clantag)
end)-- dumped from hrisito forums by <youtube.com/@subtick> ~ rip hrisito 2025-2026
