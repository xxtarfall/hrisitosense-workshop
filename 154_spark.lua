-- Title: Spark
-- Script ID: 154
-- Source: page_154.html
----------------------------------------

local ffi = require("ffi")
local vector = require("vector")
local slider1 = ui.new_slider("LUA", "A","Radius", 3,10,1)
local slider2 = ui.new_slider("LUA", "A","Length", 1,10,1)
local color = ui.new_color_picker("LUA", "A","Color", 255,255,255,255)
ffi.cdef[[
    typedef void(__fastcall*FX_ElectricSparkFn)(const Vector*,int,int,const Vector*);
]]
local FX_ElectricSpark = ffi.cast("FX_ElectricSparkFn",client.find_signature("client.dll","\x55\x8B\xEC\x83\xEC\x3C\x53\x8B\xD9\x89\x55\xFC\x8B\x0D\xCC\xCC\xCC\xCC\x56\x57"))
local spark_material = materialsystem.find_material("effects/spark", true)
client.set_event_callback("bullet_impact", function (event)
    local a = ui.get(slider1)
    local b = ui.get(slider2)
    local lp = entity.get_local_player()
    local shooter = client.userid_to_entindex(event.userid)
    if not lp then return end
    if shooter ~= lp then return end
    local color = {ui.get(color)}
    spark_material:alpha_modulate(color[4])
    spark_material:color_modulate(color[1],color[2],color[3])
    FX_ElectricSpark(vector( event.x, event.y, event.z),a,b,vector(0,0,0))
end)-- dumped from hrisito forums by <youtube.com/@subtick> ~ rip hrisito 2025-2026
