-- Title: ESP Visuals Editor
-- Script ID: 135
-- Source: page_135.html
----------------------------------------

---@diagnostic disable: undefined-global, undefined-field, deprecated, need-check-nil, duplicate-index
--
-- Copyright (c) 2025 dragos112
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in all
-- copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.
local menu = {
    version = "1.0.0",
    author = "dragos112 & mirai",
    description = "Import and export ESP settings (with predefined modules)",
    url = "https://github.com/hiraeeth/Visuals-Editor",
    dependencies = {"gamesense/clipboard", "gamesense/base64", "gamesense/http"},
    configs = database.read("gamesense::esp_settings::configs") or {},
    options = database.read("gamesense::esp_settings::options") or {},
    editor_enabled = database.read("gamesense::esp_settings::editor_enabled") or false,
    loaded_modules = database.read("gamesense::esp_settings::loaded_modules") or {}
}

--- Safely require a library, printing an error message if it is not found.
--- @param name string The name of the library to require.
--- @param message string The error message to print if the library is not found.
local try_require = function(name, message)
    if not message then
        message = "You do not have '" .. name .. "' library."
    end

    local success, result = pcall(require, name)
    if success then
        return result
    else
        return error(message, 0)
    end
end

local clipboard = try_require("gamesense/clipboard", "You don't have 'gamesense/clipboard'. Subscribe to it: https://gamesense.pub/forums/viewtopic.php?id=28678")
local base64 = try_require("gamesense/base64", "You don't have 'gamesense/base64'. Subscribe to it: https://gamesense.pub/forums/viewtopic.php?id=21619")
local ffi = try_require("ffi", "You must enable 'Allow unsafe scripts'")

--- Prints the given arguments as strings, concatenated with spaces.
--- @param ... any The arguments to print.
local print = function(...)
    local args = {...}
    for k, v in ipairs(args) do
        args[k] = tostring(v)
    end
    print(table.concat(args, " "))
end

--- Finds a string in a table.
--- @param tbl table The table to search in.
--- @param string string The string to search for.
--- @return boolean True if the string is found, false otherwise.
---@diagnostic disable-next-line: duplicate-set-field
table.find = function(tbl, string)
    for k, v in pairs(tbl) do
        if v == string then
            return true
        end
    end
    return false
end

--- @class file_system
--- @field class ffi.cdata* FFI cast of VFileSystem017 interface
--- @field vftbl ffi.cdata* Virtual function table for the filesystem interface
--- @field func_create_dir function FFI cast of directory creation function
--- @field func_is_dir function FFI cast of directory check function
--- @field native_GetGameDirectory function FFI binding to get game directory
local file_system = {}

--- Cast the filesystem interface to a void*** type
file_system.class = ffi.cast(ffi.typeof("void***"), client.create_interface("filesystem_stdio.dll", "VFileSystem017"))
file_system.vftbl = file_system.class[0]

--- Cast the directory manipulation functions
file_system.func_create_dir = ffi.cast("void (__thiscall*)(void*, const char*, const char*)", file_system.vftbl[22])
file_system.func_is_dir = ffi.cast("bool(__thiscall*)(void*, const char*, const char*)", file_system.vftbl[23])

--- Bind the game directory getter function
file_system.native_GetGameDirectory = vtable_bind("engine.dll", "VEngineClient014", 36, "const char*(__thiscall*)(void*)")

--- Gets the CS:GO game directory path
--- @return string Game directory path
file_system.get_game_directory = function()
    return ffi.string(file_system.native_GetGameDirectory())
end

--- Checks if a path is a directory
--- @param path string Path to check
--- @param path_id string|nil Path ID to check against
--- @return boolean True if path is a directory
file_system.is_directory = function(path, path_id)
    return file_system.func_is_dir(file_system.class, path, path_id)
end

--- Creates a directory at the specified path
--- @param path string Path where to create directory
--- @param path_id string|nil Path ID for the new directory
file_system.create_directory = function(path, path_id)
    file_system.func_create_dir(file_system.class, path, path_id)
end

local function create_directory()
    local base = file_system.get_game_directory()
    local dir = base:match("^(.*)\\csgo$") or base

    local target = dir .. "\\visuals_editor"
    if not file_system.is_directory(target, nil) then
        file_system.create_directory(target, nil)
    end
end

-- Menu references for the ESP data.
menu.refs = {
    player_esp = {
        teammates = ui.reference("VISUALS", "Player ESP", "Teammates"),
        dormant = ui.reference("VISUALS", "Player ESP", "Dormant"),
        bounding_box = {ui.reference("VISUALS", "Player ESP", "Bounding box")},
        health_bar = ui.reference("VISUALS", "Player ESP", "Health bar"),
        name = {ui.reference("VISUALS", "Player ESP", "Name")},
        flags = ui.reference("VISUALS", "Player ESP", "Flags"),
        weapon_text = ui.reference("VISUALS", "Player ESP", "Weapon text"),
        weapon_icon = {ui.reference("VISUALS", "Player ESP", "Weapon icon")},
        ammo = {ui.reference("VISUALS", "Player ESP", "Ammo")},
        distance = ui.reference("VISUALS", "Player ESP", "Distance"),
        glow = {ui.reference("VISUALS", "Player ESP", "Glow")},
        hit_marker = ui.reference("VISUALS", "Player ESP", "Hit marker"),
        hit_marker_sound = ui.reference("VISUALS", "Player ESP", "Hit marker sound"),
        visualize_aimbot = {ui.reference("VISUALS", "Player ESP", "Visualize aimbot")},
        visualize_aimbot_safepoint = {ui.reference("VISUALS", "Player ESP", "Visualize aimbot (safe point)")},
        visualize_sounds = {ui.reference("VISUALS", "Player ESP", "Visualize sounds")},
        line_of_sight = {ui.reference("VISUALS", "Player ESP", "Line of sight")},
        money = ui.reference("VISUALS", "Player ESP", "Money"),
        skeleton = {ui.reference("VISUALS", "Player ESP", "Skeleton")},
        oof_arrows = {ui.reference("VISUALS", "Player ESP", "Out of FOV arrow")}
    },
    colored_models = {
        player = {ui.reference("VISUALS", "Colored models", "Player")},
        player_behind_wall = {ui.reference("VISUALS", "Colored models", "Player behind wall")},
        teammate = {ui.reference("VISUALS", "Colored models", "Teammate")},
        teammate_behind_wall = {ui.reference("VISUALS", "Colored models", "Teammate behind wall")},
        local_player = {ui.reference("VISUALS", "Colored models", "Local player")},
        local_player_transparency = ui.reference("VISUALS", "Colored models", "Local player transparency"),
        local_player_fake = {ui.reference("VISUALS", "Colored models", "Local player fake")},
        on_shot = {ui.reference("VISUALS", "Colored models", "On shot")},
        ragdolls = ui.reference("VISUALS", "Colored models", "Ragdolls"),
        hands = {ui.reference("VISUALS", "Colored models", "Hands")},
        weapon_viewmodel = {ui.reference("VISUALS", "Colored models", "Weapon viewmodel")},
        weapons = {ui.reference("VISUALS", "Colored models", "Weapons")},
        disable_model_occlusion = ui.reference("VISUALS", "Colored models", "Disable model occlusion"),
        shadow = {ui.reference("VISUALS", "Colored models", "Shadow")},
        props = {ui.reference("VISUALS", "Colored models", "Props")}
    },
    other_esp = {
        radar = ui.reference("VISUALS", "Other ESP", "Radar"),
        dropped_weapons = {ui.reference("VISUALS", "Other ESP", "Dropped weapons")},
        grenades = {ui.reference("VISUALS", "Other ESP", "Grenades")},
        inaccuracy_overlay = {ui.reference("VISUALS", "Other ESP", "Inaccuracy overlay")},
        recoil_overlay = ui.reference("VISUALS", "Other ESP", "Recoil overlay"),
        grenade_trajectory = {ui.reference("VISUALS", "Other ESP", "Grenade trajectory")},
        grenade_trajectory_hit = {ui.reference("VISUALS", "Other ESP", "Grenade trajectory (hit)")},
        grenade_proximity_warning = ui.reference("VISUALS", "Other ESP", "Grenade proximity warning"),
        spectators = ui.reference("VISUALS", "Other ESP", "Spectators"),
        penetration_reticle = ui.reference("VISUALS", "Other ESP", "Penetration reticle"),
        hostages = {ui.reference("VISUALS", "Other ESP", "Hostages")},
        feature_indicators = ui.reference("VISUALS", "Other ESP", "Feature indicators"),
        shared_esp = ui.reference("VISUALS", "Other ESP", "Shared ESP"),
        shared_esp_other_team = ui.reference("VISUALS", "Other ESP", "Shared ESP with other team"),
        shared_esp_restrict = ui.reference("VISUALS", "Other ESP", "Restrict shared ESP updates"),
        crosshair = ui.reference("VISUALS", "Other ESP", "Crosshair"),
        bomb = ui.reference("VISUALS", "Other ESP", "Bomb")
    },
    effects = {
        remove_flash_effects = ui.reference("VISUALS", "Effects", "Remove flashbang effects"),
        remove_smoke_grenades = ui.reference("VISUALS", "Effects", "Remove smoke grenades"),
        remove_fog = ui.reference("VISUALS", "Effects", "Remove fog"),
        remove_skybox = ui.reference("VISUALS", "Effects", "Remove skybox"),
        visual_recoil_adjustment = ui.reference("VISUALS", "Effects", "Visual recoil adjustment"),
        transparent_walls = ui.reference("VISUALS", "Effects", "Transparent walls"),
        transparent_props = ui.reference("VISUALS", "Effects", "Transparent props"),
        brightness_adjustment = {ui.reference("VISUALS", "Effects", "Brightness adjustment")},
        remove_scope_overlay = ui.reference("VISUALS", "Effects", "Remove scope overlay"),
        instant_scope = ui.reference("VISUALS", "Effects", "Instant scope"),
        disable_post_processing = ui.reference("VISUALS", "Effects", "Disable post processing"),
        force_thirdperson_alive = ui.reference("VISUALS", "Effects", "Force third person (alive)"),
        force_thirdperson_dead = ui.reference("VISUALS", "Effects", "Force third person (dead)"),
        disable_teammates_rendering = ui.reference("VISUALS", "Effects", "Disable rendering of teammates"),
        disable_ragdolls_rendering = ui.reference("VISUALS", "Effects", "Disable rendering of ragdolls"),
        bullet_tracers = {ui.reference("VISUALS", "Effects", "Bullet tracers")},
        bullet_impacts = {ui.reference("VISUALS", "Effects", "Bullet impacts")},
        modulate_harmless_molotovs = {ui.reference("VISUALS", "Effects", "Modulate harmless molotovs")}
    },
    menu = {
        color = {ui.reference("MISC", "Settings", "Menu color")}
    }
}

--- Gets the names of the configs.
--- @return table The names of the configs.
local function get_config_names()
    local names = {}
    for _, v in ipairs(menu.configs) do
        table.insert(names, v.name)
    end

    if #names == 0 then
        table.insert(names, "Nothing here :(")
    end

    return names
end

--- Initializes the UI elements.
menu.tabs = {"Configs", "Modules"}
menu.default_options = {"Player ESP", "Colored Models", "Other ESP", "Effects", "Menu"}
menu.elements = {
    enable_editor = ui.new_checkbox("LUA", "B", "Enable visuals editor", true),
    selection = ui.new_combobox("LUA", "B", "\n", menu.tabs),

    -- configs
    tip_label0 = ui.new_label("LUA", "B", "Tip! Double click on a config name to import it."),
    configs = ui.new_listbox("LUA", "B", "\n", get_config_names()),
    searchbar = ui.new_textbox("LUA", "B", "\n", "..."),
    options = ui.new_multiselect("LUA", "B", "\n", menu.default_options),
    save = ui.new_button("LUA", "B", "Save", function()
    end),
    delete = ui.new_button("LUA", "B", "Delete", function()
    end),
    import = ui.new_button("LUA", "B", "Import", function()
    end),
    export = ui.new_button("LUA", "B", "Export", function()
    end),

    -- modules
    tip_label1 = ui.new_label("LUA", "B", "Tip! Double click to load and unload modules."),
    modules = ui.new_listbox("LUA", "B", "\n", {"none"}),
    download_module = ui.new_button("LUA", "B", "Download", function()
    end)
}

ui.set_visible(menu.elements.download_module, false)

-- Load the editor enabled state from the database
if menu.editor_enabled then
    ui.set(menu.elements.enable_editor, menu.editor_enabled)
end

local available_modules = {{
    name = "esp_healthbar",
    url = "https://raw.githubusercontent.com/hiraeeth/Visuals-Editor/refs/heads/main/visuals_editor/esp_healthbar.lua",
    refs = {
        player_esp = {
            esp_healthbar_enabled = {"Visuals", "Player ESP", "Custom Health bar"},
            esp_healthbar_gradient = {"Visuals", "Player ESP", "Enable Gradient"},
            esp_healthbar_full_health = {"Visuals", "Player ESP", "Full Health"},
            esp_healthbar_empty_health = {"Visuals", "Player ESP", "Empty Health"}
        }
    }
}, {
    name = "esp_remap",
    url = "https://raw.githubusercontent.com/hiraeeth/Visuals-Editor/refs/heads/main/visuals_editor/esp_remap.lua",
    refs = {
        effects = {
            esp_remap_enabled = {"Visuals", "Effects", "Remap"}
        }
    }
}, {
    name = "esp_skybox",
    url = "https://raw.githubusercontent.com/hiraeeth/Visuals-Editor/refs/heads/main/visuals_editor/esp_skybox.lua",
    refs = {
        effects = {
            esp_skybox_override = {"VISUALS", "Effects", "Override skybox"},
            esp_skybox_name = {"VISUALS", "Effects", "Skybox name"},
            esp_skybox_remove_3d_sky = {"VISUALS", "Effects", "Remove 3D Sky"}
        }
    }
}, {
    name = "esp_fog",
    url = "https://raw.githubusercontent.com/hiraeeth/Visuals-Editor/refs/heads/main/visuals_editor/esp_fog.lua",
    refs = {
        effects = {
            esp_fog_override = {"VISUALS", "Effects", "Override fog"},
            esp_fog_skybox = {"VISUALS", "Effects", "Skybox fog"}
        }
    }
}, {
    name = "esp_bloom",
    url = "https://raw.githubusercontent.com/hiraeeth/Visuals-Editor/refs/heads/main/visuals_editor/esp_bloom.lua",
    refs = {
        effects = {
            esp_bloom_wall_color = {"VISUALS", "Effects", "Wall Color"},
            esp_bloom_bloom = {"VISUALS", "Effects", "Bloom scale"},
            esp_bloom_exposure = {"VISUALS", "Effects", "Auto Exposure"},
            esp_bloom_model_ambient_min = {"VISUALS", "Effects", "Minimum model brightness"}
        }
    }
}}

local downloaded_modules = {}
local function get_downloaded_modules()
    downloaded_modules = {}
    for _, module in ipairs(available_modules) do
        local success, content = pcall(readfile, ("visuals_editor/%s.lua"):format(module.name))
        if success and content then
            table.insert(downloaded_modules, module.name)
        end
    end
end
get_downloaded_modules()

local module_cache = {
    time = 0,
    clicks = 0
}

--- Loads a module
--- @param module table The module definition to load
--- @return boolean success True if the module loaded successfully, false otherwise
local function load_module(module)
    if table.find(menu.loaded_modules, module.name) then
        return true
    end

    local success, content = pcall(readfile, ("visuals_editor/%s.lua"):format(module.name))
    if not success then
        error("Failed to read module file: " .. module.name)
        return false
    end

    local fn, err = load(content)
    if not fn then
        error("Failed to load module " .. module.name .. ": " .. err)
        return false
    end

    local success, err = pcall(fn)
    if not success then
        error("Failed to execute module " .. module.name .. ": " .. err)
        return false
    end

    for category, refs in pairs(module.refs) do
        for name, ref in pairs(refs) do
            if not menu.refs[category] then
                menu.refs[category] = {}
            end

            local ui_refs = {ui.reference(unpack(ref))}
            if menu.refs[category][name] then
                for _, ui_ref in ipairs(ui_refs) do
                    table.insert(menu.refs[category][name], ui_ref)
                end
            else
                menu.refs[category][name] = ui_refs
            end
        end
    end

    table.insert(menu.loaded_modules, module.name)
    database.write("gamesense::esp_settings::loaded_modules", menu.loaded_modules)

    return true
end

--- Unloads a module 
--- @param module table The module definition to unload
--- @return boolean success True if the module unloaded successfully, false otherwise
local function unload_module(module)
    local idx, loaded_idx
    for i, name in ipairs(menu.loaded_modules) do
        if name == module.name then
            idx = i
            break
        end
    end

    if not idx then
        return false
    end

    for category, refs in pairs(module.refs) do
        for name, _ in pairs(refs) do
            if menu.refs[category] and menu.refs[category][name] then
                menu.refs[category][name] = nil
            end
        end
    end

    table.remove(menu.loaded_modules, idx)
    database.write("gamesense::esp_settings::loaded_modules", menu.loaded_modules)
    client.reload_active_scripts()

    return true
end

local function sync(module)
    if table.find(menu.loaded_modules, module.name) then
        unload_module(module)
    else
        load_module(module)
    end
end

local function init_modules()
    local loaded_modules_copy = {}
    for _, name in ipairs(menu.loaded_modules) do
        table.insert(loaded_modules_copy, name)
    end

    menu.loaded_modules = {}

    local to_remove = {}
    for i, module_name in ipairs(loaded_modules_copy) do
        local found = false
        local module

        for _, m in ipairs(available_modules) do
            if m.name == module_name then
                module = m
                found = true
                break
            end
        end

        if found then
            if table.find(downloaded_modules, module.name) then
                if not load_module(module) then
                    table.insert(to_remove, i)
                end
            else
                table.insert(to_remove, i)
            end
        else
            table.insert(to_remove, i)
        end
    end

    database.write("gamesense::esp_settings::loaded_modules", menu.loaded_modules)
end

local function update_modules_list()
    local items = {}
    for _, module in ipairs(available_modules) do
        local prefix
        if table.find(downloaded_modules, module.name) then
            if table.find(menu.loaded_modules, module.name) then
                prefix = "[✔] "
            else
                prefix = ""
            end
        else
            prefix = "[+] "
        end
        table.insert(items, prefix .. module.name)
    end
    ui.update(menu.elements.modules, items)
end

ui.set_callback(menu.elements.modules, function()
    local idx = ui.get(menu.elements.modules)
    if not idx or idx + 1 > #available_modules then
        return
    end

    local module = available_modules[idx + 1]
    local cur_time = globals.curtime()

    if module_cache.clicks == idx and module_cache.time + 0.5 > cur_time then
        if table.find(downloaded_modules, module.name) then
            sync(module)
            update_modules_list()
        else
            ui.set_visible(menu.elements.download_module, true)
        end
        module_cache.clicks = -1
    else
        module_cache.clicks = idx
        module_cache.time = cur_time
    end

    ui.set_visible(menu.elements.download_module, not table.find(downloaded_modules, module.name))
end)

init_modules()
update_modules_list()

ui.set_callback(menu.elements.download_module, function()
    local _success, http = pcall(function()
        return require("gamesense/http")
    end)

    if not _success then
        return error("To download modules you need to have 'gamesense/http' library. Subscribe to it: ...")
    end

    local module = available_modules[ui.get(menu.elements.modules) + 1]
    http.get(module.url, function(status, response)
        if not status then
            return error("Failed to download module")
        end

        ui.set_enabled(menu.elements.download_module, false)
        ui.set_enabled(menu.elements.modules, false)

        local success, err = pcall(function()
            create_directory()
            local body = response.body
            writefile(("visuals_editor/%s.lua"):format(module.name), body)

            get_downloaded_modules()
            init_modules()
            update_modules_list()
            ui.set_visible(menu.elements.download_module, false)

            print(("Downloaded module %s to visuals_editor/%s.lua"):format(module.name, module.name))
        end)

        ui.set_enabled(menu.elements.download_module, true)
        ui.set_enabled(menu.elements.modules, true)

        if not success then
            return error("Failed to download module: " .. err)
        end
    end)
end)

local function visibility()
    local editor_enabled = ui.get(menu.elements.enable_editor)
    ui.set_visible(menu.elements.selection, editor_enabled)

    local selection = ui.get(menu.elements.selection)
    for _, element in ipairs({"configs", "searchbar", "options", "save", "tip_label0", "delete", "import", "export"}) do
        ui.set_visible(menu.elements[element], selection == menu.tabs[1] and editor_enabled)
    end

    for _, element in ipairs({"tip_label1", "modules"}) do
        ui.set_visible(menu.elements[element], selection == menu.tabs[2] and editor_enabled)
    end
end

visibility()
ui.set_callback(menu.elements.selection, visibility)
ui.set_callback(menu.elements.enable_editor, function()
    visibility()
    database.write("gamesense::esp_settings::editor_enabled", ui.get(menu.elements.enable_editor))
end)

-- Save the options to the database
ui.set_callback(menu.elements.options, function()
    local options = {}
    for _, v in ipairs(ui.get(menu.elements.options)) do
        table.insert(options, v)
    end

    database.write("gamesense::esp_settings::options", options)
end)

-- Load the options from the database
if #menu.options > 0 then
    ui.set(menu.elements.options, menu.options)
end

--- Determines if a UI element is likely a color picker
--- @param reference userdata The UI reference to check
--- @return boolean true if the element is likely a color picker
menu.is_color_picker = function(reference)
    local success, r, g, b, a = pcall(ui.get, reference)
    for _, v in ipairs({r, g, b, a}) do
        if type(v) ~= "number" then
            return false
        end
    end
    return success
end

--- Exports the settings of a specified category if it is selected in the options.
--- @param exported table The table to store the exported settings.
--- @param category string The category of settings to export.
--- @param alias string The alias of the category to check against the options.
menu.export = function(exported, category, alias)
    if table.find(ui.get(menu.elements.options), alias) then
        exported[category] = {}
        for k, v in pairs(menu.refs[category]) do
            if type(v) == "table" then
                exported[category][k] = {}
                for i, j in ipairs(v) do
                    if menu.is_color_picker(j) then
                        local r, g, b, a = ui.get(j)
                        exported[category][k][i] = {r, g, b, a}
                    else
                        local value = ui.get(j)
                        if type(value) == "table" then
                            exported[category][k][i] = value
                        else
                            exported[category][k][i] = value
                        end
                    end
                end
            else
                exported[category][k] = ui.get(v)
            end
        end
    end
end

--- Imports the settings of a specified category if it is selected in the options.
--- @param data table The table containing the settings to import.
--- @param category string The category of settings to import.
menu.import = function(data, category)
    local categories = {
        player_esp = "Player ESP",
        colored_models = "Colored Models",
        other_esp = "Other ESP",
        effects = "Effects",
        menu = "Menu"
    }

    if not menu.refs[category] or not table.find(ui.get(menu.elements.options), categories[category]) then
        return
    end

    for name, setting_data in pairs(data) do
        if not menu.refs[category][name] then
            print("Skipping", name, "(module not loaded)")
            goto continue
        end

        if type(menu.refs[category][name]) == "table" then
            for i, ui_ref in ipairs(menu.refs[category][name]) do
                if setting_data[i] then
                    if menu.is_color_picker(ui_ref) then
                        local color_data = setting_data[i]
                        if type(color_data) == "table" and #color_data == 4 then
                            ui.set(ui_ref, color_data[1], color_data[2], color_data[3], color_data[4])
                        end
                    else
                        ui.set(ui_ref, setting_data[i])
                    end
                end
            end
        else
            ui.set(menu.refs[category][name], setting_data)
        end

        ::continue::
    end
end

--- Creates a new button in the UI with the label "Import" that, when clicked, attempts to import settings from the clipboard.
--- If the import is successful, it prints a success message; otherwise, it prints a failure message.
ui.set_callback(menu.elements.import, function()
    local success, call_error = pcall(function()
        local text = clipboard.get()
        if not text then
            return error("No settings found in clipboard")
        end

        if not text:find("gamesense::esp_settings::") then
            return error("No settings found in clipboard")
        end

        local encoded_data, found_position = text:gsub("gamesense::esp_settings::", "")
        if found_position == 0 then
            return error("No settings found in clipboard")
        end

        local settings = json.parse(base64.decode(encoded_data))
        if settings.metadata and settings.metadata.version ~= menu.version then
            return error("Incompatible version, this version is " .. menu.version .. " and the imported version is " .. settings.metadata.version)
        end

        for category, data in pairs(settings) do
            menu.import(data, category)
        end
    end)

    if success then
        print("Imported settings from clipboard")
    else
        print("Failed to import settings from clipboard:", call_error)
    end
end)

--- Creates a new button in the UI with the label "Export" that, when clicked, attempts to export selected settings to the clipboard.
--- If the export is successful, it prints a success message with the categories exported; otherwise, it prints a failure message.
ui.set_callback(menu.elements.export, function()
    if #ui.get(menu.elements.options) == 0 then
        return error("No settings selected to export")
    end

    local success, call_error = pcall(function()
        local exported = {}
        for _, category in ipairs({{"player_esp", "Player ESP"}, {"colored_models", "Colored Models"}, {"other_esp", "Other ESP"}, {"effects", "Effects"}, {"menu", "Menu"}}) do
            menu.export(exported, category[1], category[2])
        end

        exported.metadata = {
            version = menu.version,
            author = menu.author
        }

        clipboard.set(("gamesense::esp_settings::%s"):format(base64.encode(json.stringify(exported))))
    end)

    if success then
        print(("Exported %s to clipboard"):format(table.concat(ui.get(menu.elements.options), ", ")))
    else
        print("Failed to export settings from clipboard:", call_error)
    end
end)

--- Updates the configs list with the current configs.
--- @note The index is 0-based but configs table is 1-based, so we add 1 to the index
local function update_configs()
    local configs = {}
    for _, v in ipairs(menu.configs) do
        table.insert(configs, v.name)
    end

    ui.update(menu.elements.configs, configs)
    database.write("gamesense::esp_settings::configs", menu.configs)
end

--- Deletes the currently selected config from the configs list.
--- Gets the selected index from the listbox and finds the matching config by name.
--- After deleting the config, it updates the configs list.
--- @note The index is 0-based but configs table is 1-based, so we add 1 to the index
ui.set_callback(menu.elements.delete, function()
    local idx = ui.get(menu.elements.configs)
    for i, v in ipairs(menu.configs) do
        local name = menu.configs[idx + 1].name
        if v.name == name then
            table.remove(menu.configs, i)
            print("Config", name, "deleted")
        end
    end

    update_configs()
end)

--- Creates a new config or saves an existing one with the name from the searchbar.
--- The name must not be empty.
--- After saving/creating the config, it updates the configs list.
--- @error "Name cannot be empty" when the searchbar is empty
--- @error "No settings selected to save" when no settings are selected
ui.set_callback(menu.elements.save, function()
    if #ui.get(menu.elements.options) == 0 then
        return error("No settings selected to save")
    end

    local name = ui.get(menu.elements.searchbar)
    local idx

    if name == "" then
        idx = ui.get(menu.elements.configs) + 1
        if not menu.configs[idx] then
            return error("No name provided, please provide a name for the new config")
        end
    else
        for i, v in ipairs(menu.configs) do
            if v.name == name then
                idx = i
                break
            end
        end

        if not idx then
            table.insert(menu.configs, {
                name = name,
                data = {}
            })
            idx = #menu.configs
            update_configs()
        end
    end

    print("Config", menu.configs[idx].name, "saved")
    menu.configs[idx].data = {}
    for _, category in ipairs({{"player_esp", "Player ESP"}, {"colored_models", "Colored Models"}, {"other_esp", "Other ESP"}, {"effects", "Effects"}, {"menu", "Menu"}}) do
        menu.export(menu.configs[idx].data, category[1], category[2])
    end
end)

-- Load the current config by double clicking the config name
local cache = {
    time = 0,
    clicks = 0
}

ui.set_callback(menu.elements.configs, function()
    local idx = (ui.get(menu.elements.configs) + 1)
    if idx == nil then
        return
    end

    local cur_time = globals.curtime()
    if cache.clicks == idx and cache.time + 0.5 > cur_time then
        if #ui.get(menu.elements.options) == 0 then
            return error("No settings selected to load")
        end

        if not menu.configs[idx] then
            return error("No config selected or config does not exist")
        end

        for category, data in pairs(menu.configs[idx].data) do
            menu.import(data, category)
        end

        print("Config", menu.configs[idx].name, "imported")
        cache.clicks = -1
    else
        cache.clicks = idx
        cache.time = cur_time
    end
end)-- dumped from hrisito forums by <youtube.com/@subtick> ~ rip hrisito 2025-2026
