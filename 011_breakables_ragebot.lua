-- Title: Breakables Ragebot
-- Script ID: 11
-- Source: page_11.html
----------------------------------------

local vector = require "vector"
local csgo_weapons = require "gamesense/csgo_weapons"

local enabled = ui.new_checkbox("MISC", "Miscellaneous", "Breakables Ragebot")

local bDraw = true
local gDebug = false

local function contains(table, value)
	for i, v in ipairs(table) do
		if v == value then return true end
	end
	return false
end

local target_all = false

local targets = {}
local ignored_weapons = {
	"taser",
	"grenade",
	"c4"
}

local max_dist = 64

local function get_cen(entidx)
	if entity.get_prop(entidx, "m_nModelIndex") == 824 then
		--fix for the mirage window thing being cancer (the wrong way) as fuck. fuck you valve
		local vec = vector(entity.get_origin(entidx))
		vec.x = vec.x - 15
		return vec
	end
	local orig = vector(entity.get_origin(entidx))
	local vecMins = vector(entity.get_prop(entidx, "m_vecMins"))
	local vecMaxs = vector(entity.get_prop(entidx, "m_vecMaxs"))

	return orig + ((vecMins/2) + (vecMaxs/2))
end

local function get_all_breakables()
	local rets = {}
	--rough estimation of the max entidx of breakable objects
	for i = 65, 1000 do
		local success, value = pcall(entity.get_prop, i, "m_MoveType")
		--check for MOVETYPE_PUSH and FSOLID_NOT_MOVEABLE
		--and bit.band(entity.get_prop(i, "m_nSolidType"), 0xFFFF) == 1
		if success and value == 7 and bit.band(entity.get_prop(i, "m_usSolidFlags"), 0xFFFF) == 2048 then
			rets[#rets+1] = i
		end
	end
	return rets
end

local function get_tgts()
	targets = {}
	local breakables = get_all_breakables() --get_breakables_by_mat_name(map_targets[globals.mapname()] or nil)

	if #breakables > 0 then
		if target_all then
			targets = breakables
			return
		end
		local lp = entity.get_local_player()
		local eye_vec = vector(client.eye_position())

		--if we are not aiming at any object, check instead if we are trying to move into some object
		local lp_vel = vector(entity.get_prop(entity.get_local_player(), "m_vecVelocity"))
		lp_vel.z = 0

		lp_vel = eye_vec + (lp_vel:scaled(globals.tickinterval() * 64))
		for i, b_ent in ipairs(breakables) do
			--check if we are trying to move into this object
			local frac, entidx = client.trace_line(lp, eye_vec.x, eye_vec.y, eye_vec.z, lp_vel.x, lp_vel.y, lp_vel.z)
			if entidx == b_ent then
				--if we are break and select only this ent
				targets[#targets+1] = b_ent
				break
			end
		end

		if #targets == 0 then
			--check if we are aiming at any object
			local aim = vector():init_from_angles(client.camera_angles())
			aim:scale(max_dist/2)
			aim = aim + eye_vec
			for i, b_ent in ipairs(breakables) do
				--check if we are aiming at this object
				local frac, entidx = client.trace_line(lp, eye_vec.x, eye_vec.y, eye_vec.z, aim.x, aim.y, aim.z)
				if entidx == b_ent then
					--if we are break and select only this ent
					targets[#targets+1] = b_ent
					break
				end
			end
		end
	end
end

local function render_bounds(entidx)
	local origin = vector(entity.get_origin(entidx))
	local vecMins = vector(entity.get_prop(entidx, "m_vecMins"))
	local vecMaxs = vector(entity.get_prop(entidx, "m_vecMaxs"))

	local br = origin + vecMins
	local tl = origin + vecMaxs

	local cen = vector(renderer.world_to_screen(get_cen(entidx):unpack()))

	local s1 = vector(renderer.world_to_screen(br:unpack()))
	local s2 = vector(renderer.world_to_screen(tl:unpack()))

	renderer.line(s1.x, s1.y, s2.x, s2.y, 0, 0, 0, 255)

	renderer.circle(cen.x, cen.y, 50, 50, 50, 255, 3, 0, 100)
end

local function tgt_point(entidx, eye_vec)
	local origin = get_cen(entidx)
	local dist = origin:dist(eye_vec)
	local a_mod = math.min(1, 2 - (dist / (max_dist*2)))

	if a_mod > 0 then
		local r, g, b
		r = dist > max_dist and 255 or 0
		g = a_mod == 1 and 255 or 0
		b = 0

		local cen = vector(renderer.world_to_screen(origin:unpack()))
		--renderer.text(cen.x, cen.y + 12, 255, 255, 255, 255*a_mod, "c+", 0, string.format("%.1f", dist))
		renderer.circle(cen.x, cen.y, r, g, b, 255*a_mod, 5, 0, 100)
	end
end

local function tgt_esp()
	local eye_vec = vector(client.eye_position())
	
	for i, entidx in ipairs(targets) do
		--render_bounds(entidx)
		tgt_point(entidx, eye_vec)
	end

	if gDebug then
		--render bounds of breakables
		for index, value in ipairs(get_all_breakables()) do
			render_bounds(value)
		end

		--render velocity
		local lp_vel = vector(entity.get_prop(entity.get_local_player(), "m_vecVelocity"))
		lp_vel.z = 0

		lp_vel = eye_vec + (lp_vel:scaled(globals.tickinterval() * max_dist))

		local s1 = vector(renderer.world_to_screen(eye_vec:unpack()))
		local s2 = vector(renderer.world_to_screen(lp_vel:unpack()))

		renderer.line(s1.x, s1.y, s2.x, s2.y, 255, 255, 255, 255)

		--pdump entidx
		local aim = vector():init_from_angles(client.camera_angles())
		aim:scale(1024)
		aim = aim + eye_vec
		local frac, entidx = client.trace_line(entity.get_local_player(), eye_vec.x, eye_vec.y, eye_vec.z, aim.x, aim.y, aim.z)

		renderer.text(2560/2, 1440/2 + 10, 255, 255, 255, 255, "cd", 0, string.format("%.2f %d", frac, entidx))
		
		--print(entity.get_classname(entidx))
		cvar.cl_pdump:set_int(entidx)
		if entidx ~= -1 then
			print(bit.band(entity.get_prop(entidx, "m_nSolidType"), 0xFFFF))
			render_bounds(entidx)
		end
	end
end

local function tgt_ragebot(cmd)
	local lp = entity.get_local_player()
	local lp_wep = entity.get_player_weapon(lp)
	local weapon = csgo_weapons(lp_wep)
	if weapon == nil then return end

	local can_shoot = math.max(0, entity.get_prop(lp_wep, "m_flNextPrimaryAttack") or 0, entity.get_prop(lp, "m_flNextAttack") or 0) - globals.curtime() < 0 and (weapon.type == "knife" or entity.get_prop(lp_wep, "m_iClip1") > 0)

	--max_dist = weapon.type == "knife" and 64 or 128 --weapon.range for full ragebot

	--if we can shoot (and the weapon is not a taser)
	if can_shoot and not contains(ignored_weapons, weapon.type) then
		local eye = vector(client.eye_position())
		--run the ragebot
		local closest_dist = 256
		local closest_orig = nil
		for i, gi in ipairs(targets) do
			--calculate the distance
			local go = get_cen(gi) --vector(entity.get_origin(gi))
			local dist = eye:dist(go)
			if dist < max_dist and dist < closest_dist then
				local frac, entidx = client.trace_line(lp, eye.x, eye.y, eye.z, go.x, go.y, go.z)
				if frac >= 0.95 or entidx == gi then
					closest_dist = dist
					closest_orig = go
				end
			end
		end

		if closest_orig ~= nil then
			--aim at the glass and kill it
			local g_p, g_y = eye:to(closest_orig):angles()
			cmd.pitch = g_p
			cmd.yaw = g_y
			cmd.in_attack = 1
		end
	end
end

local function enable_handler()
	local state = ui.get(enabled)
	local update_callback = state and client.set_event_callback or client.unset_event_callback
	update_callback("net_update_end", get_tgts)
	if bDraw then update_callback("paint", tgt_esp) end
	update_callback("setup_command", tgt_ragebot)
end
ui.set_callback(enabled, enable_handler)
enable_handler()-- dumped from hrisito forums by <youtube.com/@subtick> ~ rip hrisito 2025-2026
