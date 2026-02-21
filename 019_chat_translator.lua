-- Title: Chat Translator
-- Script ID: 19
-- Source: page_19.html
----------------------------------------

local http = requrie("gamesense/http")
local chat = require("gamesense/chat")
local localize = require("gamesense/localize")

local LANGUAGES = {"Afrikaans - af", "Albanian - sq", "Amharic - am", "Arabic - ar", "Armenian - hy", "Azerbaijani - az", "Basque - eu", "Belarusian - be", "Bengali - bn", "Bosnian - bs", "Bulgarian - bg", "Catalan - ca", "Cebuano - ceb", "Chinese (Simplified) - zh", "Chinese (Traditional) - zh-tw", "Corsican - co", "Croatian - hr", "Czech - cs", "Danish - da", "Dutch - nl", "English - en", "Esperanto - eo", "Estonian - et", "Finnish - fi", "French - fr", "Frisian - fy", "Galician - gl", "Georgian - ka", "German - de", "Greek - el", "Gujarati - gu", "Haitian Creole - ha", "Haitian Creole - ht", "Hawaiian - haw", "Hebrew - iw", "Hindi - hi", "Hmong - hmn", "Hungarian - hu", "Icelandic - is", "Igbo - ig", "Indonesian - id", "Irish - ga", "Italian - it", "Japanese - ja", "Javanese - jv", "Kannada - kn", "Kazakh - kk", "Khmer - km", "Kinyarwanda - rw", "Korean - ko", "Kurdish - ku", "Kyrgyz - ky", "Lao - lo", "Latvian - lv", "Lithuanian - lt", "Luxembourgish - lb", "Macedonian - mk", "Malagasy - mg", "Malay - ms", "Malayalam - ml", "Maltese - mt", "Maori - mi", "Marathi - mr", "Mongolian - mn", "Myanmar (Burmese) - my", "Nepali - ne", "Norwegian - no", "Nyanja (Chichewa) - ny", "Odia (Oriya) - or", "Pashto - ps", "Persian - fa", "Polish - pl", "Portuguese (Portugal, Brazil) - pt", "Punjabi - pa", "Romanian - ro", "Russian - ru", "Samoan - sm", "Scots Gaelic - gd", "Serbian - sr", "Sesotho - st", "Shona - sn", "Sindhi - sd", "Sinhala (Sinhalese) - si", "Slovak - sk", "Slovenian - sl", "Somali - so", "Spanish - es", "Sundanese - su", "Swahili - sw", "Swedish - sv", "Tagalog (Filipino) - tl", "Tajik - tg", "Tamil - ta", "Tatar - tt", "Telugu - te", "Thai - th", "Turkish - tr", "Turkmen - tk", "Ukrainian - uk", "Urdu - ur", "Uyghur - ug", "Uzbek - uz", "Vietnamese - vi", "Welsh - cy", "Xhosa - xh", "Yiddish - yi", "Yoruba - yo", "Zulu - zu"}

local ISO_CODES = {
    ["auto"] = true
}

for i = 1, #LANGUAGES do
    local language = LANGUAGES[i]
    local seperator = language:find("-")

    ISO_CODES[language:sub(seperator + 2)] = true
end

local TEAM_CODES = {
    [1] = "SPEC",
    [2] = "T",
    [3] = "CT"
}

local TRANSLATE_URL = "https://clients5.google.com/translate_a/t"
local OPTIONS = { params = { client = "dict-chrome-ex", dt = "t", ie = "UTF-8", oe = "UTF-8", q = "text"} }

local translator_toggle = ui.new_checkbox("LUA", "B", "Translator")
local language_index = ui.new_listbox("LUA", "B", "Test", LANGUAGES)
local last_message = {}

local function translate_player_message(ent, team_only, from_lang, to_lang, message)
    OPTIONS.params.sl = from_lang
    OPTIONS.params.tl = to_lang
    OPTIONS.params.q = message

    http.get(TRANSLATE_URL, OPTIONS, function(success, response)
        if not success or response.status ~= 200 then
            chat.print(("{red}[Error] {white}Translation failed! Response status %d!"):format(response.status))
            return 
        end

        local body = json.parse(response.body)
        -- print(response.body) -- debug

        -- Fixed bug while using eg. /t de Hello world, for some reason it's retruned body in double tables
        if type(body[1]) == "table" then
            translated_message = body[1][1]
            from_lang = body[1][2]
        elseif type(body[1]) == "string" then
            translated_message = body[1]
            from_lang = body[1][2]
        else
            chat.print("{red}[Error] {white}Wrong format received from endpoint!")
            return
        end

        if type(team_only) == "string" then
            client.exec(string.format("%s \"%s\"", team_only, translated_message))
        elseif from_lang ~= to_lang and message:lower():gsub(" ", "") ~= translated_message:lower():gsub(" ", "") then
            local team = team_only and TEAM_CODES[entity.get_prop(entity.get_player_resource(), "m_iTeam", ent)] or "All"
            local alive = entity.is_alive(ent) and "" or (team_only and "_Dead" or "Dead")

            local translation_info = string.format("{green}[%s -> %s]{lime}", from_lang:upper(), to_lang:upper())
            local formatted_message = string.format("Cstrike_Chat_%s%s", team, alive)
            local localized_message = localize(formatted_message, {s1 = entity.get_player_name(ent), s2 = translated_message})
        
            chat.print_player(ent, string.format("%s %s", translation_info, localized_message))
        end
    end)
end

local function on_player_message(e)
    local language = LANGUAGES[ui.get(language_index) + 1]
    local seperator = language:find("-")
    local to_lang = language:sub(seperator + 2)

    local ent = e.entity or client.userid_to_entindex(e.userid)
    if ent == entity.get_local_player() then
        return
    end

    if e.text ~= "" then
        local last_msg = last_message[ent]
        if not last_msg or last_msg.msg ~= e.text or globals.realtime() > last_msg.sent + 0.1 then
            translate_player_message(ent, e.teamonly or false, "auto", to_lang, e.text)
        end

        last_message[ent] = {msg = e.text, sent = globals.realtime()}
    end
end

client.set_event_callback("string_cmd", function(cmd)
    local cmd_say, cmd_translate, language, message = cmd.text:match("^(say[^ ]*) \"(%/t)%s*(%S*)%s*(.*)\"")
    if not cmd_say or not cmd_translate then return false end

    if language == "" or message == "" then
        chat.print("{red}[Error] {white}No language or message given!")
        return true
    end

    local seperator = language:find("_")
    local source_lang = seperator and language:sub(1, seperator - 1) or "auto"
    local dest_lang = seperator and language:sub(seperator + 1) or language

    if ISO_CODES[source_lang] and ISO_CODES[dest_lang] then
        translate_player_message(entity.get_local_player(), cmd_say, source_lang, dest_lang, message)
    else
        chat.print("{red}[Error] {white}Language code doesn't exist!")
    end

    return true
end)

ui.set_callback(translator_toggle, function()
    local toggle_state = ui.get(translator_toggle)
    local update_callback = toggle_state and client.set_event_callback or client.unset_event_callback

    update_callback("player_chat", on_player_message)
    update_callback("player_say", on_player_message)
    ui.set_visible(language_index, toggle_state)
end)-- dumped from hrisito forums by <youtube.com/@subtick> ~ rip hrisito 2025-2026
