-- Title: Desync Fakewalk (Customizable!)
-- Script ID: 38
-- Source: page_38.html
----------------------------------------

-- [x]============================[ Cache Common Functions ]============================[x]
local client_set_event_callback, entity_get_local_player, entity_get_player_weapon, entity_get_prop, math_abs, math_atan2, math_ceil, math_cos, math_floor, math_max, math_sin, math_sqrt, ui_get, ui_new_combobox, ui_reference, ui_set, ui_set_visible = client.set_event_callback, entity.get_local_player, entity.get_player_weapon, entity.get_prop, math.abs, math.atan2, math.ceil, math.cos, math.floor, math.max, math.sin, math.sqrt, ui.get, ui.new_combobox, ui.reference, ui.set, ui.set_visible

-- [x]============================[ UI References ]============================[x]
local limit = ui_reference( "AA", "Fake lag", "Limit" )
local variance = ui_reference( "AA", "Fake lag", "Variance" )
local slowmotion, slowmotion_state = ui_reference( "AA", "Other", "Slow motion" )
local fake_limit = ui_reference( "AA", "Anti-aimbot angles", "Fake yaw limit" )
local onshot = ui_reference( "AA", "Other", "On shot anti-aim" )
local fast_walk = ui_reference( "Misc", "Movement", "Fast walk" )

-- [x]================================================[ UI Additions ]================================================[x]
local fakewalk_mode = ui_new_combobox( "AA", "Anti-aimbot angles", "Fakewalk mode", { "Opposite", "Extend", "Jitter" } )

-- [x]============[ Data Structures ]============[x]
local function vec_3( _x, _y, _z ) 
	return { x = _x or 0, y = _y or 0, z = _z or 0 } 
end

-- [x]================================================[ Math Functions ]================================================[x]
local function deg_to_rad( val ) 
	return val * ( math.pi / 180. )
end

local function vector_to_angles( forward, angles )
	if forward.x == 0 and forward.y == 0 then
		if forward.z > 0 then
			angles.x = -90
		else
			angles.x = 90
		end
		angles.y = 0
	else
		angles.x = math_atan2( -forward.z, math_sqrt( forward.x * forward.x + forward.y * forward.y ) ) * ( 180 / math.pi )
		angles.y = math_atan2( forward.y, forward.x ) * ( 180 / math.pi )
	end

	angles.z = 0
end

local function angle_to_vector( angles, forward )
	local sp = math_sin( deg_to_rad( angles.x ) )
	local cp = math_cos( deg_to_rad( angles.x ) )
	local sy = math_sin( deg_to_rad( angles.y ) )
	local cy = math_cos( deg_to_rad( angles.y ) )

	forward.x = cp * cy
	forward.y = cp * sy
	forward.z = -sp
end

function round( x ) -- https://stackoverflow.com/questions/18313171/lua-rounding-numbers-and-then-truncate
    return x >= 0 and math_floor( x+0.5 ) or math_ceil( x-0.5 )
end

local function normalize_as_yaw( yaw )
	if yaw > 180 or yaw < -180 then
		local revolutions = round( math_abs( yaw / 360 ) )

		if yaw < 0 then
			yaw = yaw + 360 * revolutions
		else
			yaw = yaw - 360 * revolutions
		end
	end

	return yaw
end

-- [x]======================================[ Local Functions ]======================================[x]
local function quick_stop( cmd )
	local velocity_prop = vec_3( entity_get_prop( entity_get_local_player( ), "m_vecVelocity" ) )
	local velocity = math_sqrt( velocity_prop.x * velocity_prop.x + velocity_prop.y * velocity_prop.y )
	local direction = vec_3( 0, 0, 0 )
	vector_to_angles( velocity_prop, direction )
	direction.y = cmd.yaw - direction.y;

	local new_move = vec_3( 0, 0, 0 )
	angle_to_vector( direction, new_move );
	local max_move = math_max( math_abs( cmd.forwardmove ), math_abs( cmd.sidemove ) )
	local multiplier = 450 / max_move
	new_move = vec_3( new_move.x * -multiplier, new_move.y * -multiplier, new_move.z * -multiplier )

	cmd.forwardmove = new_move.x
	cmd.sidemove = new_move.y
end

local equiped_type = 0
local equiped_name = ""
local function get_stop_tick( )
	local weapon = entity_get_player_weapon( entity_get_local_player( ) )
	local scoped = entity_get_prop( entity_get_local_player( ), "m_bIsScoped" )

	-- Because Valve
	if equiped_name == "deagle"
		or ( equiped_name == "aug" and scoped == 1 ) then
		return 10
	end

	if equiped_name == "negev"
		or ( equiped_name == "sg556" and scoped == 1 ) then
		return 9
	end
	
	return 8
end

-- [x]======================================[ Callbacks ]======================================[x]
local fakewalking = false
local stored_onshot = ui_get( onshot )
local stored_limit = ui_get( limit )
local stored_variance = ui_get( variance )
local stored_fastwalk = ui_get( fast_walk )
local flicks = 0
client_set_event_callback( "setup_command", function( cmd )	
	if ui_get( slowmotion ) then
		return
	end	
	
	if not ui_get( slowmotion_state ) then
		if fakewalking and stored_limit > 0 then
			ui_set( onshot, stored_onshot )
			ui_set( limit, stored_limit )
			ui_set( variance, stored_variance )
			ui_set( fast_walk, stored_fastwalk )
		end
		stored_onshot = ui_get( onshot )
		stored_limit = ui_get( limit )
		stored_variance = ui_get( variance )
		stored_fastwalk = ui_get( fast_walk )
		fakewalking = false
		return
	end
	
	-- Setup angles
	local eye_angles = vec_3( entity_get_prop( entity_get_local_player( ), "m_angEyeAngles" ) )
	local real_angles = vec_3( entity_get_prop( entity_get_local_player( ), "m_angAbsRotation" ) )
	local fake_side = ( normalize_as_yaw( real_angles.y - eye_angles.y ) > 0 ) and -1 or 1
	
	-- Get velocity
	local velocity_prop = vec_3( entity_get_prop( entity_get_local_player( ), "m_vecVelocity" ) )
	local velocity = math_sqrt( velocity_prop.x * velocity_prop.x + velocity_prop.y * velocity_prop.y )
	
	-- Set some shit up
	fakewalking = true
	ui_set( onshot, false )
	ui_set( limit, 14 )
	ui_set( variance, 0 )
	ui_set( fast_walk, true )

	local stop_tick = get_stop_tick( )
	if cmd.chokedcommands >= ( ui_get( limit ) - stop_tick ) then 
		if cmd.forwardmove ~= 0 or cmd.sidemove ~= 0 then
			quick_stop( cmd )
		end
	end

	if cmd.chokedcommands == ( ui_get( limit ) - 3 ) then
		if velocity <= 0 then
			cmd.forwardmove = -1.01
		end
		flicks = flicks + 1
		if ui_get( fakewalk_mode ) == "Opposite" then
			cmd.yaw = normalize_as_yaw( eye_angles.y + ( 60 * fake_side ) )
		elseif ui_get( fakewalk_mode ) == "Extend" then
			cmd.yaw = normalize_as_yaw( eye_angles.y + ( 90 * fake_side ) )
		elseif ui_get( fakewalk_mode ) == "Jitter" then
			cmd.yaw = normalize_as_yaw( eye_angles.y + ( 60 * ( flicks % 2 == 0 and -1 or 1 ) ) )
		end
	end
end )

client_set_event_callback( "item_equip", function( event_data )
	equiped_name = event_data.item
	equiped_type = event_data.weptype
end )

client_set_event_callback( "pre_render", function( )
	ui_set_visible( fakewalk_mode, not ui_get( slowmotion ) and true or false )
end )-- dumped from hrisito forums by <youtube.com/@subtick> ~ rip hrisito 2025-2026
