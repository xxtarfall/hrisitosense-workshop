-- Title: Automatically Reload Scripts (For Developers)
-- Script ID: 8
-- Source: page_8.html
----------------------------------------

-- Bind to a method in the game's engine
local engine_bind = vtable_bind("engine.dll", "VEngineClient014", 196, "bool(__thiscall*)(void*)")
local old_checksums = {}
local new_checksums = {}

-- Calculate the checksum of a string using CRC32
function calculate_checksum(value, crc_table)
    local checksum, slot3, slot4 = nil

    if not (crc_table or old_checksums)[1] then
        for i = 1, 256 do
            checksum = i - 1

            for j = 1, 8 do
                checksum = bit.bxor(bit.rshift(checksum, 1), bit.band(3988292384.0, -bit.band(checksum, 1)))
            end

            crc_table[i] = checksum
        end
    end

    checksum = 4294967295.0

    for i = 1, #value do
        checksum = bit.bxor(bit.rshift(checksum, 8), crc_table[bit.band(bit.bxor(checksum, string.byte(value, i)), 255) + 1])
    end

    return bit.band(bit.bnot(checksum), 4294967295.0)
end

-- Check if any Lua files have been modified
function check_lua_file_changes()
    for file_name, file in pairs(package.loaded) do
        -- Check both root and lua/ directory
        for _, path in pairs({"", "lua/"}) do
            if readfile(path .. file_name .. ".lua") then
                if old_checksums[file_name] then
                    if old_checksums[file_name] ~= calculate_checksum(file) then
                        print(string.format("%s was changed, reloading active scripts!", file_name))
                        client.reload_active_scripts()

                        return
                    end
                else
                    old_checksums[file_name] = calculate_checksum(file)
                end
            end
        end
    end
end

local game_is_running = false

-- Set the callback to check if the game is running and if any Lua files have been modified
client.set_event_callback("paint_ui", function ()
    local is_game_running = engine_bind()

    if game_is_running == false and is_game_running then
        check_lua_file_changes()
        client.delay_call(0.5, check_lua_file_changes)
    end

    game_is_running = is_game_running
end)-- dumped from hrisito forums by <youtube.com/@subtick> ~ rip hrisito 2025-2026
