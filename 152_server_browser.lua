-- Title: server browser
-- Script ID: 152
-- Source: page_152.html
----------------------------------------

-- Server Browser for GameSense
local servers = {
    {
        name = "[RU] Imperial HvH |1 AWP 1 SCAR| ROLLFIX",
        map = "de_mirage",
        ip = "62.122.214.211:1488",
    },
    {
        name = "[RU] GetWex HvH | ONLY MIRAGE",
        map = "de_mirage",
        ip = "62.122.215.74:1337",
    },
    {
        name = "[20] [CS:GO] HvH 10v10 ONLY SCONT| D00X.RU |DUST2|MIRAGE",
        map = "de_dust2",
        ip = "82.208.123.206:27070",
    },
    {
        name = "[18] [CS:GO] HVH 5v5 MM COMPETITIVE| D00X.RU | ANTICHEAT |NO PL",
        map = "de_dust2",
    },
    {
        name = "[19] [CS:GO] 10v10 HVH PUBLIC FPS+| D00X.RU |DUST2|MIRAGE|",
        map = "de_dust2_fps_mr",
        ip = "82.208.123.206:27069",
    },
    {
        name = "[RU] PUZO HVH | ONLY SCOUT | MIRAGE",
        map = "de_mirage",
        ip = "37.230.162.58:1488",
    },
    {
        name = "eXpidors.Ru | HVH | ONLY SCOUT | MIRAGE | Roll Fix",
        map = "de_mirage",
        ip = "62.122.215.105:6666",
    },
    {
        name = "[SharkProject.ru] DM HVH",
        map = "dm_twentysixer_mirage_new",
        ip = "46.174.51.108:27015",
    },
    {
        name = "[RU] PUZO HVH | 16K | MM PUBLIC | 1 AWP",
        map = "de_mirage",
        ip = "45.136.204.145:1488",
    },
    {
        name = "██ ★ uwujka.pl ★ [HVH] ⚫ Hax vs Hax",
        map = "de_mirage",
        ip = "51.77.47.242:27015",
    },
    {
        name = "StarLess HvH Reborn [RU | NSK]",
        map = "de_mirage",
        ip = "185.135.83.176:1337",
    },
    {
        name = "eXpidors.Ru | HVH | MM PUBLIC | MIRAGE | Roll Fix",
        map = "de_mirage",
        ip = "46.174.51.137:7777",
    },
    {
        name = "sippin' on wok mm hvh",
        map = "de_mirage",
        ip = "46.174.55.52:1488",
    },
    {
        name = "[SharkProject.ru] 1x1 ARENA HVH",
        map = "am_infernew_mid",
        ip = "46.174.52.69:27015",
    },
    {
        name = "[SharkProject.ru] MM HVH | 16k | 1 AWP | Roll Fix",
        map = "de_mirage",
        ip = "37.230.228.148:27015",
    },
    {
        name = "[Ru] War3ft Project | HvH | Mirage | (Z)",
        map = "de_mirage",
        ip = "194.93.2.30:1337",
    },
    {
        name = "[hvhserver.xyz] roll fix |",
        map = "de_mirage",
        ip = "62.122.214.55:27015",
    },
    {
        name = "[RU/KZ] LivixProject HVH | 7x7 | ROLL FIX | MIRAGE",
        map = "de_mirage",
        ip = "79.143.20.199:27021",
    },
    {
        name = "[RU]Atomic MM HvH | HackVsHack | RPG | noVAC",
        map = "de_mirage",
        ip = "45.136.205.33:27015",
    },
    {
        name = "TOP 1 = 100$ | [RU] Celestix | MM HvH Mirage | 16K | RollFix",
        map = "de_mirage",
        ip = "37.230.210.180:27015",
    },
    {
        name = "GalaxyTaps |MM HvH| 16k V2 Hahahah",
        map = "[GalaxyTaps]de_mirage",
        ip = "185.175.158.17:1337",
    },
    -- Новые сервера
    {
        name = "[REMORSELESS.RU] MM HVH | 16k | Mirage| AWP | RollFix",
        map = "de_mirage",
        ip = "45.95.31.26:27415",
    },
    {
        name = "[Starlight League] MM HVH | 16k | Rollfix",
        map = "cs_office",
        ip = "85.192.12.197:25550",
    },
    {
        name = "[RU] EndlessHvH | 8x8 | Roll Fix | 1 AWP :3",
        map = "cs_italy",
        ip = "hvh.iminsane.ru:1488",
    },
    {
        name = "[RU] Odyssey | 16K MM HVH | Roll fix",
        map = "/1173548706/de_dust2",
        ip = "hvh.odyssey.pub:1337",
    },
    {
        name = "[Sippin on SharkProject.ru] 5x5 MM HVH | 16k",
        map = "de_mirage",
        ip = "194.93.2.243:27015",
    },
    {
        name = "[MrX] 2018 HvH MM",
        map = "de_dust2_mrx_2018",
        ip = "178.32.80.148:27015",
    },
    {
        name = "[Whoise] MM HVH | 16k | Rollfix | NoSpread",
        map = "cs_office",
        ip = "85.192.12.197:25555",
    },
    {
        name = "[RU] HackHaven HvH | MM 16k, 1 AWP, Roll Fix",
        map = "de_mirage",
        ip = "45.95.31.8:27315",
    },
    {
        name = "Gost Hub | HvH | public | 32k | MIRAGE",
        map = "de_mirage",
        ip = "31.184.218.228:27615",
    },
}

-- UI Elements
local server_browser_enabled = ui.new_checkbox("LUA", "B", "Get information about server!")
local server_list = ui.new_listbox("LUA", "B", "Servers", (function()
    local list = {}
    for i, server in ipairs(servers) do
        local ping_text = server.ping and ("[" .. server.ping .. "] ") or ""
        list[i] = ping_text .. server.name
    end
    return list
end)())

local connect_button = ui.new_button("LUA", "B", "Connect to Server", function()
    local selected = ui.get(server_list) + 1
    if selected >= 1 and selected <= #servers then
        local server = servers[selected]
        client.exec("connect " .. server.ip)
        client.color_log(255, 255, 0, "Connecting to: " .. server.name)
    end
end)

local refresh_button = ui.new_button("LUA", "B", "Refresh List", function()
    client.color_log(0, 255, 0, "Server list refreshed!")
end)

local server_info_label = ui.new_label("LUA", "B", "Select a server to view info")
local server_info_label = ui.new_label("LUA", "B", "Creator: dafer1337")
local server_info_label = ui.new_label("LUA", "B", "Do you want to add your server?")
local server_info_label = ui.new_label("LUA", "B", "Write me on Telegram - @statew1n")
-- Paint function to show server info
client.set_event_callback("paint", function()
    if not ui.get(server_browser_enabled) then return end
    
    local selected = ui.get(server_list) + 1
    if selected >= 1 and selected <= #servers then
        local server = servers[selected]
        
        local screen_x, screen_y = client.screen_size()
        local x, y = screen_x / 2 - 200, screen_y / 2 - 150
        
        -- Background
        renderer.rectangle(x, y, 400, 120, 20, 20, 20, 200)
        renderer.rectangle(x, y, 400, 1, 52, 152, 219, 255)
        
        -- Server info
        renderer.text(x + 10, y + 10, 255, 255, 255, 255, "", 0, server.name)
        renderer.text(x + 10, y + 30, 200, 200, 200, 255, "", 0, "Map: " .. server.map)
               
        -- Connect hint
        renderer.text(x + 10, y + 95, 52, 152, 219, 255, "", 0, "Press 'Connect to Server' button to join")
    end
end)

-- Auto-refresh every 30 seconds
local last_refresh = globals.realtime()
client.set_event_callback("paint", function()
    if not ui.get(server_browser_enabled) then return end
    
    if globals.realtime() - last_refresh > 30 then
        last_refresh = globals.realtime()
        client.color_log(0, 200, 255, "Server browser auto-refreshed")
    end
end)

-- Console command to quickly connect by IP
client.set_event_callback("console_input", function(text)
    if text:sub(1, 8) == "connect " then
        local ip = text:sub(9)
        client.exec("connect " .. ip)
    end
end)

client.color_log(52, 152, 219, "Server Browser [RU] loaded!")
client.color_log(52, 152, 219, #servers .. " servers available")-- dumped from hrisito forums by <youtube.com/@subtick> ~ rip hrisito 2025-2026
