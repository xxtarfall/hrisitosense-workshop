-- Title: Simple trashtalk
-- Script ID: 157
-- Source: page_157.html
----------------------------------------

--[[

Updated 04.11.2025

Changelogs 

- Added Russian to Deathsay
- Added multi-phrases (it's just that some phrases follow one another, w 0.15 cd) (multi-phrases using: {"1-st phrase","second", e.t.c})
- Added phrases to all Killsay/Deathsay

soon new lua w/anti-aims e.t.c.

]]



local ks = {
    { 
    name = "English", 
    phrases = {"sit down nn dog",
    {"get down rn", "im your capitan btw"},
    "ez, 1",
    "???",
    "l2p",
    "Tapped? No cry.",
    "How to download sk33t crack in 2k25",
    {"why you so bad?","l2p n1gg3r"},
    "ez n1gga"
    }
    },
    { 
        name = "Russian", 
        phrases = {"Оп бомжиха а че на колени упал то?))",
        "дефенсивы не помогают? Скачать конфиг на АА 2025 #гайд",
        "КАК ТАПНУТЬ БОМЖА С ПОМОЩЬЮ СКИТА. ГАЙД 2025 #RAT",
        "потел потел, да все равно вьебал((",
        "iба шлюшка улетела",
        "запомни брад. Мать одна, а стандофф два.",
        "накончал на ротан как сучке, вот это да.",
        "GTA San Andreas User Files",
        "визуал студио 2022 комьюнити эдишн",
        "гыг, а че такой кислый?",
        "тапнул как слоумошного деда на валиуме",
        "а че с хуя на хуй переключаешься пидор",
        {"ньюкамер detected!","а теперь вышел по приказу моему"},
        "как скачать конфиг с форума рейза?",
        {"missed due to ?","просто не юзай кастом.резики","ведь даже они тебе не помогают"},
        "вгетать скит in 2025 это сильно.",
        {"missed due to server rejection?","соррi я просто sm_metan.lua оффнуть забыл))"},
        "о нет юзер нн луа подьехал на своем ковре"
    }
    },
    { 
        name = "[RU] Rofl", 
        phrases = {"О нiт моi дiфiнсiвi растапалi твоi, как так?",
        "о нет юзер нн луа подьехал на своем ковре",
        "эм а чо так легко? 1 нищ ez ez ez ez",
        "Кагда в меня мисснули и я тапнул и я такой чооо",
        {"missed due to server rejection?","соррi я просто sm_metan.lua оффнуть забыл))"}},
    }
}

local ds = {
    { 
        name = "English", 
        phrases = {"wp idiot", "wp", "nigger tapped me, its real??", "oh no he so lucky(("}
    },
    { 
        name = "Russian", 
        phrases = {
            {"а типку везет за 30 тиков трекать","лакбустед хуесос"},
            "бекшутнул уебок жирный",
            "как всегда сервак хуйни даст челу шанс xD",
            {"давай в чат со своим нищим trashtalk","сам то нихуя высказать не можешь(("},
            "што такое скiт?"
        }
    }
}

local clantag = {
    "", "o", "ov", "ove", "over", "overd", "overdo", "overdos", "overdose ",
    "overdose`", "overdose`", "overdos", "overdo", "overd", "over", "ove", "ov", "o", ""
}

local uip = {}

uip.module = ui.new_multiselect("LUA", "A", "Enabled Features", {"Killsay", "Deathsay", "Clantag"})

local ksmode = {}
for i, list in ipairs(ks) do table.insert(ksmode, list.name) end
uip.ks_mode = ui.new_combobox("LUA", "A", "Killsay Mode", ksmode)

local dsmode = {}
for i, list in ipairs(ds) do table.insert(dsmode, list.name) end
uip.ds_mode = ui.new_combobox("LUA", "A", "Deathsay Mode", dsmode)

local function solodka(selection_table, option_name)
    if not selection_table then return false end
    for i, selected_option in ipairs(selection_table) do
        if selected_option == option_name then
            return true
        end
    end
    return false
end

local function visible()
    local selected = ui.get(uip.module)

    local killsay_visible = solodka(selected, "Killsay")
    ui.set_visible(uip.ks_mode, killsay_visible)

    local deathsay_visible = solodka(selected, "Deathsay")
    ui.set_visible(uip.ds_mode, deathsay_visible)
end

ui.set_callback(uip.module, visible)
visible()

local chat_queue = {}

local function add_to_chat_queue(phrase_list)
    local delay = 0
    for i, text in ipairs(phrase_list) do
        table.insert(chat_queue, {
            text = text,
            time_to_send = globals.curtime() + delay
        })
        delay = delay + 1.5
    end
end

local function process_chat_queue()
    if #chat_queue > 0 then
        local message_info = chat_queue[1]
        if globals.curtime() >= message_info.time_to_send then
            client.exec("say " .. message_info.text)
            table.remove(chat_queue, 1)
        end
    end
end

local function on_player_death(e)
    local lpid = entity.get_local_player()
    if not lpid then return end

    local attacker_entindex = client.userid_to_entindex(e.attacker)
    local victim_entindex = client.userid_to_entindex(e.userid)

    local selected_modules = ui.get(uip.module)

    -- Killsay
    if solodka(selected_modules, "Killsay") and attacker_entindex == lpid and victim_entindex ~= lpid then
        local s_name = ui.get(uip.ks_mode)
        
        local s_phrases = nil
        for i, list in ipairs(ks) do
            if list.name == s_name then
                s_phrases = list.phrases
                break
            end
        end

        if s_phrases and #s_phrases > 0 then
            local phrase = s_phrases[math.random(#s_phrases)]
            if type(phrase) == "table" then
                add_to_chat_queue(phrase)
            else
                add_to_chat_queue({phrase})
            end
        end
        return
    end

    -- Deathsay
    if solodka(selected_modules, "Deathsay") and victim_entindex == lpid then
        local s_name = ui.get(uip.ds_mode)

        local s_phrases = nil
        for i, list in ipairs(ds) do
            if list.name == s_name then
                s_phrases = list.phrases
                break
            end
        end

        if s_phrases and #s_phrases > 0 then
            local phrase = s_phrases[math.random(#s_phrases)]
            if type(phrase) == "table" then
                add_to_chat_queue(phrase)
            else
                add_to_chat_queue({phrase})
            end
        end
    end
end

local index = 1
local lastupd = 0

local function clantaglogik()
    local selected_modules = ui.get(uip.module)
    if not solodka(selected_modules, "Clantag") then return end

    local current_time = globals.curtime()
    if current_time - lastupd < 0.3 then return end
    lastupd = current_time
    client.set_clan_tag(clantag[index])
    
    index = index + 1
    if index > #clantag then
        index = 1
    end
end

local function on_shutdown()
    client.set_clan_tag("")
end
-- [НОВАЯ ФУНКЦИЯ] Главный обработчик события paint
local function on_paint()
    clantaglogik()
    process_chat_queue()
end

client.set_event_callback("player_death", on_player_death)
client.set_event_callback("paint", on_paint) -- Теперь вызываем единый обработчик
client.set_event_callback("shutdown", on_shutdown)-- dumped from hrisito forums by <youtube.com/@subtick> ~ rip hrisito 2025-2026
