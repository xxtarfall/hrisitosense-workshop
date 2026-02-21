-- Title: Cock/fish esp
-- Script ID: 149
-- Source: page_149.html
----------------------------------------

ui.new_label("LUA", "A", "========= [ COCKS ESP ] =======");
local master_switch = ui.new_checkbox("LUA", "A", "[Fish/Cock] Enable ESP")
local fNametags = ui.new_checkbox("LUA", "A", "[Fish] Nametags")
local fboudning_box = ui.new_checkbox("LUA", "A", "[Fish] Bounding box")
local fhealth_bar = ui.new_checkbox("LUA", "A", "[Fish] Health Bar")
local fFlags = ui.new_checkbox("LUA", "A", "[Fish] Flags")
local nametags = ui.new_checkbox("LUA", "A", "[Cock] Nametags")
local bounding_box = ui.new_checkbox("LUA", "A", "[Cock] Bounding box")
local health_bar = ui.new_checkbox("LUA", "A", "[Cock] Health Bar")
local flags = ui.new_checkbox("LUA", "A", "[Cock] Flags")

local function distanceSquared( x1, y1, x2, y2) --Edited version of distanceSquared (with the division only for the lua)
	return ((x2-x1)^2 + (y2-y1)^2)/10000, ((x2-x1)^2 + (y2-y1)^2)/4000
end

local function BoundingBox(x, y, w, h, r, g, b, a)
    renderer.rectangle(x, y, w, 1, r, g, b, a)
    renderer.rectangle(x, y, 1, h, r, g, b, a)
    renderer.rectangle(x, y+h-1, w, 1, r, g, b, a)
    renderer.rectangle(x+w-1, y, 1, h, r, g, b, a)
end

local fishName = {
    "niggafish",
    "bobfish",
    "pirexfish",
    "ballshackfish",
    "apesito fish",
    "best hvher",
    "mohammed",
}

local chickenName = {
    "pirexcock",
    "niggacock",
    "my nigga jerry",
    "baimer",
    "apesito cock",
}

-- Tables to store persistent names for each entity
local assigned_fish_names = {}
local assigned_chicken_names = {}

-- Table to store resolver state (changes randomly)
local chicken_resolver_state = {}
local last_resolver_update = 0

-- Function to get or assign a name for an entity
local function get_entity_name(entity_id, name_table, assigned_names)
    if not assigned_names[entity_id] then
        -- Find unused names first
        local used_names = {}
        for _, name in pairs(assigned_names) do
            used_names[name] = true
        end
        
        local available_names = {}
        for _, name in ipairs(name_table) do
            if not used_names[name] then
                table.insert(available_names, name)
            end
        end
        
        -- If all names are taken, just pick any random name
        if #available_names == 0 then
            assigned_names[entity_id] = name_table[math.random(1, #name_table)]
        else
            -- Pick a random unused name
            assigned_names[entity_id] = available_names[math.random(1, #available_names)]
        end
    end
    return assigned_names[entity_id]
end

local function on_paint()
    local local_x, local_y, local_z = entity.get_origin(entity.get_local_player())
    
    -- Update resolver states randomly every 0.5-2 seconds
    local current_time = globals.realtime()
    if current_time - last_resolver_update > math.random(50, 200) / 100 then
        last_resolver_update = current_time
        -- Randomly flip some cock's resolver states
        for entity_id, _ in pairs(assigned_chicken_names) do
            if math.random() > 0.5 then
                chicken_resolver_state[entity_id] = not chicken_resolver_state[entity_id]
            end
        end
    end
    
    for _, v in pairs(entity.get_all("CFish")) do
        local x, y, z = entity.get_origin(v)
        if not x then goto continue_fish end
        
        local sx, sy = renderer.world_to_screen(x, y, z)
        if not sx then goto continue_fish end
        
        -- Calculate distance and scale box accordingly
        local distance = math.sqrt((x - local_x)^2 + (y - local_y)^2 + (z - local_z)^2)
        local scale = math.max(0.3, 1 - (distance / 1000)) -- Scale based on distance
        local w, h = 30 * scale, 30 * scale
        local x1, y1 = sx - w/2, sy - h
        local x2, y2 = sx + w/2, sy
        
        if ui.get(fNametags) then
            local name = get_entity_name(v, fishName, assigned_fish_names)
            renderer.text(sx, y1 - 15, 255, 255, 255, 255, "c", 0, name)
        end
        
        if ui.get(fboudning_box) then
            BoundingBox(x1, y1, w, h, 255, 255, 255, 255)
            BoundingBox(x1-1, y1-1, w+2, h+2, 0, 0, 0, 255)
            BoundingBox(x1+1, y1+1, w-2, h-2, 0, 0, 0, 255)
        end
        
        if ui.get(fhealth_bar) then
            BoundingBox(x1-6, y1-1, 4, h+2, 0, 0, 0, 255)
            renderer.rectangle(x1-5, y1, 2, h, 0, 255, 0, 255)
        end
        
        if ui.get(fFlags) then
            renderer.text(x2+2, y1, 0, 255, 255, 255, "-", 0, "SWIM")
        end
        
        ::continue_fish::
    end
    for _, v in pairs(entity.get_all("CChicken")) do
        local x, y, z = entity.get_origin(v)
        if not x then goto continue_chicken end
        
        local sx, sy = renderer.world_to_screen(x, y, z)
        if not sx then goto continue_chicken end
        
        -- Calculate distance and scale box accordingly
        local distance = math.sqrt((x - local_x)^2 + (y - local_y)^2 + (z - local_z)^2)
        local scale = math.max(0.3, 1 - (distance / 1000)) -- Scale based on distance
        local w, h = 30 * scale, 30 * scale
        local x1, y1 = sx - w/2, sy - h
        local x2, y2 = sx + w/2, sy
        
        if ui.get(nametags) then
            local name = get_entity_name(v, chickenName, assigned_chicken_names)
            renderer.text(sx, y1 - 15, 255, 255, 255, 255, "c", 0, name)
        end
        
        if ui.get(bounding_box) then
            BoundingBox(x1, y1, w, h, 255, 255, 255, 255)
            BoundingBox(x1-1, y1-1, w+2, h+2, 0, 0, 0, 255)
            BoundingBox(x1+1, y1+1, w-2, h-2, 0, 0, 0, 255)
        end
        
        if ui.get(health_bar) then
            BoundingBox(x1-6, y1-1, 4, h+2, 0, 0, 0, 255)
            renderer.rectangle(x1-5, y1, 2, h, 0, 255, 0, 255)
        end
        
        if ui.get(flags) then
            -- Initialize resolver state if not set
            if chicken_resolver_state[v] == nil then
                chicken_resolver_state[v] = math.random() > 0.5
            end
            
            -- Show green for resolved, red for not resolved
            if chicken_resolver_state[v] then
                renderer.text(x2+2, y1, 0, 255, 0, 255, "-", 0, "RESOLVED")
            else
                renderer.text(x2+2, y1, 255, 0, 0, 255, "-", 0, "RESOLVED")
            end
        end
        
        ::continue_chicken::
    end
end

local function ui_callback(ref)
    client[(ui.get(ref) and "" or "un").."set_event_callback"]("paint", on_paint)
end

ui_callback(master_switch)
ui.set_callback(master_switch, ui_callback)

 local ffi = require("ffi");
ffi.cdef([[
    typedef struct { 
        float x;
        float y;
        float z; 
    } vec3_t;
]])

local SetAbsAngles = ffi.cast("void(__thiscall*)(void*, const vec3_t*)",  client.find_signature("client.dll", "\x55\x8B\xEC\x83\xE4\xF8\x83\xEC\x64\x53\x56\x57\x8B\xF1"));
local IEntityList = ffi.cast("void***", client.create_interface("client.dll", "VClientEntityList003"));
local GetClientEntity = ffi.cast("uintptr_t (__thiscall*)(void*, int)", IEntityList[0][3]);

local chicken_vec = ffi.new("vec3_t");

local function int24_color(r, g, b, a)
    local a = a/255;
    local str = "0x" .. ("%02x"):format(math.floor(b*a)) .. ("%02x"):format(math.floor(g*a)) .. ("%02x"):format(math.floor(r*a));
    return tonumber(str)
end

local config = {

    __glow = ui.new_checkbox("LUA", "A", "Enable Glowing Cocks");
    glow = false;

    [0] = ui.new_label("LUA", "A", "Claimed");

    __claimed = ui.new_color_picker("LUA", "A", "Claimed Cock Color", 0, 255, 0, 255);
    claimed = int24_color(255, 55, 55, 155);

    [1] = ui.new_label("LUA", "A", "Unclaimed");

    __unclaimed = ui.new_color_picker("LUA", "A", "Unclaimed Cock Color", 255, 0, 0, 255);
    unclaimed = int24_color(200, 255, 55, 155);

    __speed = ui.new_slider("LUA", "A", "Spin Speed", 0, 200, 100, true, "%", 1, {[0] = "Disabled"; [199] = "Max"; [200] = "Cock Anti-Aim"});
    speed = 0;

};

client.set_event_callback("setup_command", function()
    local glow = config.glow and 1 or 0;

    for _, index in pairs(entity.get_all("CChicken")) do
        if not entity.is_dormant(index) then
            entity.set_prop(index, "m_flGlowMaxDist", 2000)
            entity.set_prop(index, "m_bShouldGlow", glow)
            entity.set_prop(index, "m_clrGlow", config[(entity.get_prop(index, "m_leader") == -1) and "unclaimed" or "claimed"])
            entity.set_prop(index, "m_nGlowStyle", 0)
        end
    end
end)

client.set_event_callback("override_view", function()
    if config.speed == 0 then return end

    if config.speed == 2000 then
        chicken_vec.x = math.random(-180, 180);
        chicken_vec.y = math.random(-180, 180);

    else
        chicken_vec.y = (globals.curtime() * config.speed) % 360 - 180;

    end

    for _, index in pairs(entity.get_all("CChicken")) do
        if not entity.is_dormant(index) then
            local ptr = ffi.cast("int*", GetClientEntity(IEntityList, index));

            if not ptr then return end

            SetAbsAngles(ptr, chicken_vec)
        end
    end
end)

client.set_event_callback("shutdown", function()
    for _, index in pairs(entity.get_all("CChicken")) do
        if not entity.is_dormant(index) then
            entity.set_prop(index, "m_bShouldGlow", 0)
        end
    end
end)

ui.set_callback(config.__glow, function() config.glow = ui.get(config.__glow); end)
ui.set_callback(config.__claimed, function() config.claimed = int24_color(ui.get(config.__claimed)); end)
ui.set_callback(config.__unclaimed, function() config.unclaimed = int24_color(ui.get(config.__unclaimed)); end)
ui.set_callback(config.__speed, function() config.speed = ui.get(config.__speed)*10; if config.speed < 2000 then chicken_vec.x = 0; end end)

config.glow = ui.get(config.__glow);
config.claimed = int24_color(ui.get(config.__claimed));
config.unclaimed = int24_color(ui.get(config.__unclaimed));
config.speed = ui.get(config.__speed)*10; if config.speed < 2000 then chicken_vec.x = 0; end-- dumped from hrisito forums by <youtube.com/@subtick> ~ rip hrisito 2025-2026
