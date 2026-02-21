-- Title: Paranoia
-- Script ID: 153
-- Source: page_153.html
----------------------------------------

-- @ uwukson4800 ~ t.me/debugoverlay

_G._DEBUG = false
local safe do safe = { } function safe:print(...) if _DEBUG then print('[DEBUG] ', ...) end end function safe:require(module_name) local status, module = pcall(require, module_name) if status then return module else self:print('error loading module "' .. module_name .. '": ' .. module) return nil end end function safe:call(func, ...) local args = { ... } local status, err = pcall(func, unpack(args)) if not status then self:print('error with ' .. func .. ' : ' .. err) end end client.set_event_callback('shutdown', function() if safe then safe = nil end if _DEBUG then _DEBUG = false end end) end

local ffi      = safe:require 'ffi'
local bit      = safe:require 'bit'
local vector   = safe:require 'vector'
local c_entity = safe:require 'gamesense/entity'

-- uwukson4800 ~ https://yougame.biz/threads/349178/
local INetChannel=(function()ffi.cdef[[typedef struct{}i_net_channel_info;typedef struct{}c_net_message;typedef bool(__fastcall*send_net_msg_t)(i_net_channel_info*,void*,c_net_message*,bool,bool);typedef struct{uint32_t i_net_message_vtable;char pad_0004[4];uint32_t c_clc_msg_voice_data_vtable;char pad_000C[8];void*data;uint64_t xuid;int32_t format;int32_t sequence_bytes;uint32_t section_number;uint32_t uncompressed_sample_offset;int32_t cached_size;uint32_t flags;char pad_0038[255];}c_clc_msg_voice_data;typedef struct{int32_t vtable;void*msgbinder1;void*msgbinder2;void*msgbinder3;void*msgbinder4;unsigned char m_bProcessingMessages;unsigned char m_bShouldDelete;char pad_0x0016[0x2];int32_t m_nOutSequenceNr;int32_t m_nInSequenceNr;int32_t m_nOutSequenceNrAck;int32_t m_nOutReliableState;int32_t m_nInReliableState;int32_t m_nChokedPackets;char pad_0030[112];int32_t m_Socket;int32_t m_StreamSocket;int32_t m_MaxReliablePayloadSize;char remote_address[32];char m_szRemoteAddressName[64];float last_received;float connect_time;char pad_0114[4];int32_t m_Rate;char pad_011C[4];float m_fClearTime;char pad_0124[16688];char m_Name[32];unsigned int m_ChallengeNr;float m_flTimeout;char pad_427C[32];float m_flInterpolationAmount;float m_flRemoteFrameTime;float m_flRemoteFrameTimeStdDeviation;int32_t m_nMaxRoutablePayloadSize;int32_t m_nSplitPacketSequence;char pad_42B0[40];bool m_bIsValveDS;char pad_42D9[65];}CNetChannel;typedef struct{char pad_0000[0x9C];CNetChannel*m_NetChannel;uint32_t m_nChallengeNr;char pad_00A4[0x64];uint32_t m_nSignonState;char pad_010C[0x8];float m_flNextCmdTime;uint32_t m_nServerCount;uint32_t m_nCurrentSequence;char pad_0120[4];char m_ClockDriftMgr[0x50];int32_t m_nDeltaTick;bool m_bPaused;char pad_0179[7];uint32_t m_nViewEntity;uint32_t m_nPlayerSlot;char m_szLevelName[260];char m_szLevelNameShort[40];char m_szGroupName[40];char pad_02DC[52];uint32_t m_nMaxClients;char pad_0314[18820];float m_flLastServerTickTime;bool insimulation;char pad_4C9D[3];uint32_t oldtickcount;float m_tickRemainder;float m_frameTime;char pad_4CAC[0x78];char temp[0x8];int32_t lastoutgoingcommand;int32_t chokedcommands;int32_t last_command_ack;int32_t last_server_tick;int32_t command_ack;char pad_4CC0[80];char viewangles[0xC];char pad_4D14[0xD0];void*m_Events;}IClientState;typedef struct{char data[16];uint32_t current_len;uint32_t max_len;}communication_string_t;typedef struct{uint64_t xuid;int32_t sequence_bytes;uint32_t section_number;uint32_t uncompressed_sample_offset;}c_voice_communication_data;typedef uint32_t(__fastcall*construct_voicedata_message)(c_clc_msg_voice_data*,void*);typedef uint32_t(__fastcall*destruct_voicedata_message)(c_clc_msg_voice_data*);]];local memory do memory={};local cast=ffi.cast;local copy=ffi.copy;local new=ffi.new;local typeof=ffi.typeof;local tonumber=tonumber;local insert=table.insert;local function opcode_scan(module,pattern,offset)local sig=client.find_signature(module,pattern);if not sig then error(string.format('failed to find signature: %s',module))end;return cast('uintptr_t',sig)+(offset or 0)end;local jmp_ecx=opcode_scan('engine.dll','\xFF\xE1');local get_proc_addr=cast('uint32_t**',cast('uint32_t',opcode_scan('engine.dll','\xFF\x15\xCC\xCC\xCC\xCC\xA3\xCC\xCC\xCC\xCC\xEB\x05'))+2)[0][0];local fn_get_proc_addr=cast('uint32_t(__fastcall*)(unsigned int,unsigned int,uint32_t,const char*)',jmp_ecx);local get_module_handle=cast('uint32_t**',cast('uint32_t',opcode_scan('engine.dll','\xFF\x15\xCC\xCC\xCC\xCC\x85\xC0\x74\x0B'))+2)[0][0];local fn_get_module_handle=cast('uint32_t(__fastcall*)(unsigned int,unsigned int,const char*)',jmp_ecx);local proc_cache={};local function proc_bind(module_name,function_name,typedef)local cache_key=module_name..function_name;if proc_cache[cache_key]then return proc_cache[cache_key]end;local ctype=typeof(typedef);local module_handle=fn_get_module_handle(get_module_handle,0,module_name);local proc_address=fn_get_proc_addr(get_proc_addr,0,module_handle,function_name);local call_fn=cast(ctype,jmp_ecx);local fn=function(...)return call_fn(proc_address,0,...)end;proc_cache[cache_key]=fn;return fn end;local native_virtualprotect=proc_bind('kernel32.dll','VirtualProtect','int(__fastcall*)(unsigned int,unsigned int,void*lpAddress,unsigned long dwSize,unsigned long flNewProtect,unsigned long*lpflOldProtect)');function memory:virtual_protect(lpAddress,dwSize,flNewProtect,lpflOldProtect)return native_virtualprotect(cast('void*',lpAddress),dwSize,flNewProtect,lpflOldProtect)end;function memory:write_raw(dest,rawbuf,len)local old_prot=ffi.new('uint32_t[1]');self:virtual_protect(ffi.cast('uintptr_t',dest),len,0x40,old_prot);ffi.copy(ffi.cast('void*',dest),rawbuf,len);self:virtual_protect(ffi.cast('uintptr_t',dest),len,old_prot[0],old_prot)end end;local utils={};local signatures={};local INetChannel={};function utils.rel32(address,offset)if address==0 or address==nil then return 0 end;local target_addr=address+offset;local rel_offset=ffi.cast('uint32_t*',target_addr)[0];if rel_offset==0 then return 0 end;return target_addr+4+rel_offset end;signatures.client_state=client.find_signature('engine.dll','\xA1\xCC\xCC\xCC\xCC\x8B\x80\xCC\xCC\xCC\xCC\xC3')or error('clientstate error');signatures.client_state=ffi.cast('IClientState***',ffi.cast('uint32_t',signatures.client_state)+1)[0][0];signatures.send_net_msg=client.find_signature('engine.dll','\x55\x8B\xEC\x83\xEC\x08\x56\x8B\xF1\x8B\x4D\x04')or error('sendnetmsg error');signatures.voicedata_constructor=client.find_signature('engine.dll','\xC6\x46\xCC\xCC\x5E\xC3\x56\x57\x8B\xF9\x8D\x4F\xCC\xC7\x07\xCC\xCC\xCC\xCC\xE8');signatures.voicedata_constructor=ffi.cast('uint32_t',signatures.voicedata_constructor)+6;signatures.voicedata_destructor=client.find_signature('engine.dll','\xE8\xCC\xCC\xCC\xCC\x5E\x8B\xE5\x5D\xC3\xCC\xCC\xCC\xCC\xCC\xCC\xCC\xCC\xCC\xCC\xCC\xCC\x51');signatures.voicedata_destructor=utils.rel32(ffi.cast('uint32_t',signatures.voicedata_destructor),1);function INetChannel:SendNetMsg(custom_xuid_low,custom_xuid_high)custom_xuid_high=custom_xuid_high or 0xFFEA9F9A;local communication_string_t=ffi.new('communication_string_t[1]');communication_string_t[0].current_len=0;communication_string_t[0].max_len=15;local msg=ffi.new('c_clc_msg_voice_data[1]');ffi.cast('construct_voicedata_message',signatures.voicedata_constructor)(msg,ffi.cast('void*',0));safe:print(string.format('xuid_low: [0x%X] ~ xuid_high: [0x%X]',custom_xuid_low,custom_xuid_high));memory:write_raw(ffi.cast('uint32_t',msg)+0x18,ffi.new('uint32_t[1]',custom_xuid_low),4);memory:write_raw(ffi.cast('uint32_t',msg)+0x1C,ffi.new('uint32_t[1]',custom_xuid_high),4);msg[0].sequence_bytes=math.random(0,0xFFFFFFF);msg[0].section_number=math.random(0,0xFFFFFFF);msg[0].uncompressed_sample_offset=math.random(0,0xFFFFFFF);msg[0].data=communication_string_t;msg[0].format=0;msg[0].flags=63;ffi.cast('send_net_msg_t',signatures.send_net_msg)(ffi.cast('i_net_channel_info*',signatures.client_state[0].m_NetChannel),ffi.cast('void*',0),ffi.cast('c_net_message*',msg),false,true);ffi.cast('destruct_voicedata_message',signatures.voicedata_destructor)(msg)end;client.set_event_callback('shutdown',function()if ffi then ffi=nil end;if bit then bit=nil end;if memory then memory=nil end;if signatures then signatures=nil end;if INetChannel then INetChannel=nil end;collectgarbage('collect')end);return INetChannel end)()

local INetChannelInfo=(function()local interface_ptr=ffi.typeof('void***')local netc_bool=ffi.typeof('bool(__thiscall*)(void*)')local netc_bool2=ffi.typeof('bool(__thiscall*)(void*, int, int)')local netc_float=ffi.typeof('float(__thiscall*)(void*, int)')local netc_int=ffi.typeof('int(__thiscall*)(void*, int)')local rawivengineclient=client.create_interface('engine.dll','VEngineClient014')or error('VEngineClient014 wasnt found',2)local ivengineclient=ffi.cast(interface_ptr,rawivengineclient)or error('rawivengineclient is nil',2)local get_net_channel_info=ffi.cast('void*(__thiscall*)(void*)',ivengineclient[0][78])or error('ivengineclient is nil')local slv_is_ingame_t=ffi.cast('bool(__thiscall*)(void*)',ivengineclient[0][26])or error('is_in_game is nil')local function GetNetChannel(INetChannelInfo)if INetChannelInfo==nil then return end local seqNr_out=ffi.cast(netc_int,INetChannelInfo[0][17])(INetChannelInfo,1)return{seqNr_out=seqNr_out,is_loopback=ffi.cast(netc_bool,INetChannelInfo[0][6])(INetChannelInfo),is_timing_out=ffi.cast(netc_bool,INetChannelInfo[0][7])(INetChannelInfo),latency={crn=function(flow)return ffi.cast(netc_float,INetChannelInfo[0][9])(INetChannelInfo,flow)end,average=function(flow)return ffi.cast(netc_float,INetChannelInfo[0][10])(INetChannelInfo,flow)end,},loss=ffi.cast(netc_float,INetChannelInfo[0][11])(INetChannelInfo,1),choke=ffi.cast(netc_float,INetChannelInfo[0][12])(INetChannelInfo,1),got_bytes=ffi.cast(netc_float,INetChannelInfo[0][13])(INetChannelInfo,1),sent_bytes=ffi.cast(netc_float,INetChannelInfo[0][13])(INetChannelInfo,0),is_valid_packet=ffi.cast(netc_bool2,INetChannelInfo[0][18])(INetChannelInfo,1,seqNr_out-1),}end;return{get_net_channel_info=get_net_channel_info,slv_is_ingame_t=slv_is_ingame_t,GetNetChannel=GetNetChannel,ivengineclient=ivengineclient}end)()
local callbacks do callbacks = { } function callbacks:set(event, func) safe:call(function() client.set_event_callback(event, function(...) local status, err = pcall(func, ...) if not status then safe:print('error in callback "' .. event .. '": ' .. err) end end) end) end client.set_event_callback('shutdown', function() if callbacks then callbacks = nil end end) end
local wrapper=(function()local wrapper={}local refs={}local function create_base_object()local obj={}function obj:get()return ui.get(self.reference)end function obj:set(value)ui.set(self.reference,value)end function obj:set_callback(callback)ui.set_callback(self.reference,callback)end function obj:type()return ui.type(self.reference)end function obj:visibility(visible)ui.set_visible(self.reference,visible)end function obj:disabled(visible)ui.set_enabled(self.reference,visible)end function obj:update(value,...)ui.update(self.reference,value,...)end return obj end function wrapper.create(tab,container)local group={name=name,tab=tab,container=container,switch=function(self,name,default)local obj=create_base_object()obj.reference=ui.new_checkbox(self.tab,self.container,name)if default~=nil then ui.set(obj.reference,default)end return obj end,combo=function(self,name,...)local obj=create_base_object()local options={...}if type(options[1])=='table'then options=options[1]end obj.reference=ui.new_combobox(self.tab,self.container,name,unpack(options))return obj end,selectable=function(self,name,...)local obj=create_base_object()local options={...}if type(options[1])=='table'then options=options[1]end obj.reference=ui.new_multiselect(self.tab,self.container,name,unpack(options))return obj end,list=function(self,name,options)local obj=create_base_object()obj.reference=ui.new_listbox(self.tab,self.container,name,options)return obj end,slider=function(self,name,min,max,default,...)local obj=create_base_object()obj.reference=ui.new_slider(self.tab,self.container,name,min,max,default or min,...)return obj end,color_picker=function(self,name)local obj=create_base_object()obj.reference=ui.new_color_picker(self.tab,self.container,name)return obj end,label=function(self,text)local obj=create_base_object()obj.reference=ui.new_label(self.tab,self.container,text)return obj end,input=function(self,text)local obj=create_base_object()obj.reference=ui.new_textbox(self.tab,self.container,text)return obj end,button=function(self,name,callback)local obj=create_base_object()obj.reference=ui.new_button(self.tab,self.container,name,callback)return obj end,hotkey=function(self,name,...)local obj=create_base_object()obj.reference=ui.new_hotkey(self.tab,self.container,name,...)return obj end}return group end function wrapper.find(tab,container,name)local obj=create_base_object()obj.reference=ui.reference(tab,container,name)return obj end function wrapper.color(r,g,b,a)return{r=r,g=g,b=b,a=a}end return wrapper end)()
local gui=(function()local gui={}local ui_create=wrapper.create local empty_items={''}local empty_str=''local function create_element(func_name,...)local element=ui_create('LUA','A')return element[func_name](element,...)end local function create_element_right(func_name,...)local element=ui_create('AA','Fake Lag')return element[func_name](element,...)end gui.switch=function(c)local element=create_element('switch',c)return element end gui.slider=function(...)return create_element('slider',...)end gui.combo=function(c,items)return create_element('combo',c,items or empty_items)end gui.selectable=function(c,items)local element=create_element('selectable',c,items or empty_items)return element end gui.color_picker=function(...)return create_element('color_picker',...)end gui.button=function(c,func)local element=ui_create(a,b)return element:button(c,func)end gui.input=function(...)return create_element('input',...)end gui.list=function(c,items,d)if d=='right'then return create_element_right('list',c,items or empty_items)else return create_element('list',c,items or empty_items)end end gui.listable=function(c,items)return create_element('listable',c,items or empty_items)end gui.label=function(text)return create_element('label',text or empty_str)end return gui end)()

-- Hack3r_jopi ~ https://yougame.biz/threads/345134/
local exploits=(function()local clases={}function class(name)return function(tab)if not tab then return clases[name]end tab.__index,tab.__classname=tab,name if tab.call then tab.__call=tab.call end setmetatable(tab,tab)clases[name],_G[name]=tab,tab return tab end end local g_ctx={local_player=nil,weapon=nil,aimbot=ui.reference("RAGE","Aimbot","Enabled"),doubletap={ui.reference("RAGE","Aimbot",'Double tap')},hideshots={ui.reference("AA",'Other','On shot anti-aim')},fakeduck=ui.reference("RAGE","Other","Duck peek assist")}local clamp=function(value,min,max)return math.min(math.max(value,min),max)end class"exploits"{max_process_ticks=math.abs(client.get_cvar("sv_maxusrcmdprocessticks"))-1,tickbase_difference=0,ticks_processed=0,command_number=0,choked_commands=0,need_force_defensive=false,current_shift_amount=0,reset_vars=function(self)self.ticks_processed=0 self.tickbase_difference=0 self.choked_commands=0 self.command_number=0 end,store_vars=function(self,ctx)self.command_number=ctx.command_number self.choked_commands=ctx.chokedcommands end,store_tickbase_difference=function(self,ctx)if ctx.command_number==self.command_number then self.ticks_processed=clamp(math.abs(entity.get_prop(g_ctx.local_player,"m_nTickBase")-self.tickbase_difference),0,self.max_process_ticks-self.choked_commands)self.tickbase_difference=math.max(entity.get_prop(g_ctx.local_player,"m_nTickBase"),self.tickbase_difference or 0)self.command_number=0 end end,is_doubletap=function(self)return ui.get(g_ctx.doubletap[2])end,is_hideshots=function(self)return ui.get(g_ctx.hideshots[2])end,is_active=function(self)return self:is_doubletap()or self:is_hideshots()end,in_defensive=function(self)return self:is_active()and(self.ticks_processed>1 and self.ticks_processed<self.max_process_ticks)end,is_defensive_ended=function(self)return not self:in_defensive()or(self.ticks_processed>=0 and self.ticks_processed<=5)and self.tickbase_difference>0 end,is_lagcomp_broken=function(self)return not self:is_defensive_ended()or self.tickbase_difference<entity.get_prop(g_ctx.local_player,"m_nTickBase")end,can_recharge=function(self)if not self:is_active()then return false end local curtime=globals.tickinterval()*(entity.get_prop(g_ctx.local_player,"m_nTickBase")-16)if curtime<entity.get_prop(g_ctx.local_player,"m_flNextAttack")then return false end if curtime<entity.get_prop(g_ctx.weapon,"m_flNextPrimaryAttack")then return false end return true end,in_recharge=function(self)if not(self:is_active()and self:can_recharge())or self:in_defensive()then return false end local latency_shift=math.ceil(toticks(client.latency())*1.25)local current_shift_amount=((self.tickbase_difference-globals.tickcount())*-1)+latency_shift local max_shift_amount,min_shift_amount=(self.max_process_ticks-1)-latency_shift,-(self.max_process_ticks-1)+latency_shift if latency_shift~=0 then return current_shift_amount>min_shift_amount and current_shift_amount<max_shift_amount else return current_shift_amount>(min_shift_amount/2)and current_shift_amount<(max_shift_amount/2)end end,should_force_defensive=function(self,state)if not self:is_active()then return false end self.need_force_defensive=state and self:is_defensive_ended()end,allow_unsafe_charge=function(self,state)if not(self:is_active()and self:can_recharge())then ui.set(g_ctx.aimbot,true)return end if not state then ui.set(g_ctx.aimbot,true)return end if ui.get(g_ctx.fakeduck)then ui.set(g_ctx.aimbot,true)return end ui.set(g_ctx.aimbot,not self:in_recharge())end,force_reload_exploits=function(self,state)if not state then ui.set(g_ctx.doubletap[1],true)ui.set(g_ctx.hideshots[1],true)return end if self:is_doubletap()and not self:in_recharge()then ui.set(g_ctx.doubletap[1],false)else ui.set(g_ctx.doubletap[1],true)end if self:is_hideshots()and not self:in_recharge()then ui.set(g_ctx.hideshots[1],false)else ui.set(g_ctx.hideshots[1],true)end end}local event_list={on_setup_command=function(ctx)if not(entity.get_local_player()and entity.is_alive(entity.get_local_player())and entity.get_player_weapon(entity.get_local_player()))then return end g_ctx.local_player=entity.get_local_player()g_ctx.weapon=entity.get_player_weapon(g_ctx.local_player)if exploits.need_force_defensive then ctx.force_defensive=true end end,on_run_command=function(ctx)exploits:store_vars(ctx)end,on_predict_command=function(ctx)exploits:store_tickbase_difference(ctx)end,on_player_death=function(ctx)if not(ctx.userid and ctx.attacker)then return end if g_ctx.local_player~=client.userid_to_entindex(ctx.userid)then return end exploits:reset_vars()end,on_level_init=function()exploits:reset_vars()end,on_round_start=function()exploits:reset_vars()end,on_round_end=function()exploits:reset_vars()end,on_shutdown=function()collectgarbage("collect")end}for k,v in next,event_list do client.set_event_callback(k:sub(4),function(ctx)v(ctx)end)end return exploits end)()

-- Trich1337 ~ https://yougame.biz/threads/341992/
local render=(function() local inspect=require("gamesense/inspect") local render={} render.set_col=vtable_bind("vguimatsurface.dll","VGUI_Surface031",15,"void(__thiscall*)(void*, int, int, int, int)") render.filled_rect=vtable_bind("vguimatsurface.dll","VGUI_Surface031",16,"void(__thiscall*)(void*, int, int, int, int)") render.outlined_rect=vtable_bind("vguimatsurface.dll","VGUI_Surface031",18,"void(__thiscall*)(void*, int, int, int, int)") render.filled_rect_fade=vtable_bind("vguimatsurface.dll","VGUI_Surface031",123,"void(__thiscall*)(void*, int, int, int, int, unsigned int, unsigned int, bool)") render.filled_fast_fade=vtable_bind("vguimatsurface.dll","VGUI_Surface031",122,"bool(__thiscall*)(void*, int, int, int, int, int, int, unsigned int, unsigned int, bool)") render.line=vtable_bind("vguimatsurface.dll","VGUI_Surface031",19,"void(__thiscall*)(void*, int, int, int, int)") render.poly_line=vtable_bind("vguimatsurface.dll","VGUI_Surface031",20,"void(__thiscall*)(void*, int*, int*, int)") render.create_font=vtable_bind("vguimatsurface.dll","VGUI_Surface031",71,"unsigned int(__thiscall*)(void*)") render.font_col=vtable_bind("vguimatsurface.dll","VGUI_Surface031",25,"void(__thiscall*)(void*, int, int, int, int)") render.text_pos=vtable_bind("vguimatsurface.dll","VGUI_Surface031",26,"void(__thiscall*)(void*, int, int)") render.set_glyph=vtable_bind("vguimatsurface.dll","VGUI_Surface031",72,"bool(__thiscall*)(void*, unsigned long, const char*, int, int, int, int, unsigned long, int, int)") render.set_font=vtable_bind("vguimatsurface.dll","VGUI_Surface031",23,"void(__thiscall*)(void*, unsigned int)") render.draw_text=vtable_bind("vguimatsurface.dll","VGUI_Surface031",28,"void(__thiscall*)(void*, const wchar_t*, int, int)") render.draw_textcol=vtable_bind("vguimatsurface.dll","VGUI_Surface031",163,"void(__stdcall*)(void*, unsigned int, int, int, int, int, int, int, const char*, ...)") render.text_size=vtable_bind("vguimatsurface.dll","VGUI_Surface031",79,"bool(__stdcall*)(void*, unsigned long, const wchar_t*, int&, int&)") render.text_len=vtable_bind("vguimatsurface.dll","VGUI_Surface031",166,"int(__cdecl*)(void*, unsigned long, const char*, ...)") render.text_height=vtable_bind("vguimatsurface.dll","VGUI_Surface031",165,"int(__cdecl*)(void*, unsigned long, int, int&, const char*, ...)") render.circle_outline=vtable_bind("vguimatsurface.dll","VGUI_Surface031",103,"void(__thiscall*)(void*, int, int, int, int)") local function Color(r,g,b,a)return{r=r or 0,g=g or 0,b=b or 0,a=a or 255}end local utils,better_renderer,global,dragable,fonts={}, {}, {}, {}, {} local better_renderer_mt={__index=better_renderer} local g=Color(10,10,10) local a=Color(60,60,60) local b=Color(40,40,40) local l=Color(20,20,20) local g1=Color(100,150,200) local g2=Color(180,100,160) local g3=Color(180,230,100) local B="\x14\x14\x14\xFF" local C="\x0c\x0c\x0c\xFF" local skt=renderer.load_rgba(table.concat({B,B,B,C,B,C,B,C,B,C,B,B,B,C,B,C}),4,4) utils.lerp=function(start,end_pos,time,ampl)if start==end_pos then return end_pos end ampl=ampl or 1/globals.frametime() local frametime=globals.frametime()*ampl time=time*frametime local val=start+(end_pos-start)*time if(math.abs(val-end_pos)<0.01)then return end_pos end return val end utils.get_text_size=function(font,...)local height=ffi.new("int[1]")local weight=render.text_len(font,...)render.text_height(font,weight,height,...)return vector(weight,height[0])end utils.set_draw_col=function(color)render.set_col(color.r,color.b,color.g,color.a)end utils.in_range_triangle=function(curs,vertex)local a=(vertex[1].x-curs.x)*(vertex[2].y-vertex[1].y)-(vertex[2].x-vertex[1].x)*(vertex[1].y-curs.y)local b=(vertex[2].x-curs.x)*(vertex[3].y-vertex[2].y)-(vertex[3].x-vertex[2].x)*(vertex[2].y-curs.y)local c=(vertex[3].x-curs.x)*(vertex[1].y-vertex[3].y)-(vertex[1].x-vertex[3].x)*(vertex[3].y-curs.y)if(a>=0 and b>=0 and c>=0)then return true end return false end utils.in_range_rect=function(curs,pos,size)return curs.x>pos.x and curs.x<pos.x+size.x and curs.y>pos.y and curs.y<pos.y+size.y end utils.in_range_circle=function(curs,pos,radius)return(curs.x-pos.x)^2+(curs.y-pos.y)^2<=radius^2 end utils.rect_of_triangle=function(vertex1,vertex2,vertex3)local x=vertex1.x<=vertex2.x and vertex1.x<=vertex3.x and vertex1.x or vertex2.x<=vertex1.x and vertex2.x<=vertex3.x and vertex2.x or vertex3.x<=vertex2.x and vertex3.x<=vertex1.x and vertex3.x local y=vertex1.y<=vertex2.y and vertex1.y<=vertex3.y and vertex1.y or vertex2.y<=vertex1.y and vertex2.y<=vertex3.y and vertex2.y or vertex3.y<=vertex2.y and vertex3.y<=vertex1.y and vertex3.y local x2=vertex1.x>=vertex2.x and vertex1.x>=vertex3.x and vertex1.x or vertex2.x>=vertex1.x and vertex2.x>=vertex3.x and vertex2.x or vertex3.x>=vertex2.x and vertex3.x>=vertex1.x and vertex3.x local y2=vertex1.y>=vertex2.y and vertex1.y>=vertex3.y and vertex1.y or vertex2.y>=vertex1.y and vertex2.y>=vertex3.y and vertex2.y or vertex3.y>=vertex2.y and vertex3.y>=vertex1.y and vertex3.y return{x1=x,y1=y,x2=x2-x,y2=y2-y}end utils.rect_outline=function(pos,size,color,thickness)utils.set_draw_col(color)render.outlined_rect(pos.x,pos.y,pos.x+size.x,pos.y+size.y)local thickness=thickness or 1 if thickness>1 then for i=1,thickness,1 do render.outlined_rect(pos.x+i,pos.y+i,pos.x+size.x-i,pos.y+size.y-i)end end end utils.rect_filled=function(pos,size,color)utils.set_draw_col(color)render.filled_rect(pos.x,pos.y,pos.x+size.x,pos.y+size.y)end utils.rect_filled_fade=function(pos,size,color,alpha0,alpha1,horizontal)local horizontal=horizontal or false utils.set_draw_col(color)render.filled_rect_fade(pos.x,pos.y,pos.x+size.x,pos.y+size.y,alpha0,alpha1,horizontal)end utils.rect_fast_fade=function(pos,size,startend,color,alpha0,alpha1,horizontal)local horizontal=horizontal or false utils.set_draw_col(color)render.filled_fast_fade(pos.x,pos.y,pos.x+size.x,pos.y+size.y,startend.x,startend.y,alpha0,alpha1,horizontal)end utils.triangle_outline=function(vertex1,vertex2,vertex3,color,thickness)local thickness=thickness or 1 local x=ffi.new("int[3]",vertex1.x,vertex2.x,vertex3.x)local y=ffi.new("int[3]",vertex1.y,vertex2.y,vertex3.y)utils.set_draw_col(color)render.poly_line(x,y,3)if thickness>1 then for i=1,thickness,1 do local xi=ffi.new("int[3]",vertex1.x+i*2,vertex2.x,vertex3.x-i*2)local yi=ffi.new("int[3]",vertex1.y-i,vertex2.y+i,vertex3.y-i)render.poly_line(xi,yi,3)end end end utils.circle_outline=function(pos,color,radius,segments,thickness)local thickness=thickness or 1 utils.set_draw_col(color)render.circle_outline(pos.x,pos.y,radius,segments)if thickness>1 then for i=1,thickness,1 do if thickness>radius then return end render.circle_outline(pos.x,pos.y,radius-i,segments)end end end utils.rounded_rectangle=function(x,y,w,h,r,g,b,a,radius)y=y+radius local data_circle={{x+radius,y,180},{x+w-radius,y,90},{x+radius,y+h-radius*2,270},{x+w-radius,y+h-radius*2,0}}local data={{x+radius,y,w-radius*2,h-radius*2},{x+radius,y-radius,w-radius*2,radius},{x+radius,y+h-radius*2,w-radius*2,radius},{x,y,radius,h-radius*2},{x+w-radius,y,radius,h-radius*2}}for _,data in next,data_circle do renderer.circle(data[1],data[2],r,g,b,a,radius,data[3],0.25)end for _,data in next,data do renderer.rectangle(data[1],data[2],data[3],data[4],r,g,b,a)end end utils.outlined_rounded_rectangle=function(x,y,w,h,r,g,b,a,radius,thickness)y=y+radius local data_circle={{x+radius,y,180},{x+w-radius,y,270},{x+radius,y+h-radius*2,90},{x+w-radius,y+h-radius*2,0}}local data={{x+radius,y-radius,w-radius*2,thickness},{x+radius,y+h-radius-thickness,w-radius*2,thickness},{x,y,thickness,h-radius*2},{x+w-thickness,y,thickness,h-radius*2}}for _,data in next,data_circle do renderer.circle_outline(data[1],data[2],r,g,b,a,radius,data[3],0.25,thickness)end for _,data in next,data do renderer.rectangle(data[1],data[2],data[3],data[4],r,g,b,a)end end utils.skeety=function(pos,size,gradient)renderer.rectangle(pos.x,pos.y,size.x,size.y,g.r,g.g,g.b,g.a)renderer.rectangle(pos.x+1,pos.y+1,size.x-2,size.y-2,a.r,a.g,a.b,a.a)renderer.rectangle(pos.x+2,pos.y+2,size.x-4,size.y-4,b.r,b.g,b.b,b.a)renderer.rectangle(pos.x+4,pos.y+4,size.x-8,size.y-8,a.r,a.g,a.b,a.a)renderer.texture(skt,pos.x+5,pos.y+5,size.x-10,size.y-10,255,255,255,255,"t")if gradient then renderer.gradient(pos.x+6,pos.y+6,size.x/2,1,g1.r,g1.g,g1.b,g1.a,g2.r,g2.g,g2.b,g2.a,true)renderer.gradient(pos.x+6+size.x/2,pos.y+6,size.x/2-12,1,g2.r,g2.g,g2.b,255,g3.r,g3.g,g3.b,g3.a,true)end end global={}utils.global_handler=function()if ui.is_menu_open()then global.old_cursor_pos=global.cursor_pos or vector(ui.mouse_position())global.cursor_pos=vector(ui.mouse_position())global.oldclicked=global.clicked global.delta=global.cursor_pos-global.old_cursor_pos global.clicked=client.key_state(0x01)global.firstclick=not global.oldclicked and global.clicked global.on_menu=utils.in_range_rect(global.cursor_pos,vector(ui.menu_position()),vector(ui.menu_size()))end end function better_renderer:rectangle(id,pos,size,color)local id=self.i..":"..id self[id]=self[id] or setmetatable({type="rect",id=id,pos=pos,size=size},better_renderer_mt)utils.rect_filled(self[id].pos,self[id].size,color)return self[id]end function better_renderer:rectangle_fade(id,pos,size,color,alpha0,alpha1,horizontal)local id=self.i..":"..id self[id]=setmetatable({type="rect",id=id,pos=pos,size=size,},better_renderer_mt)utils.rect_filled_fade(self[id].pos,self[id].size,color,alpha0,alpha1,horizontal)return self[id]end function better_renderer:rectangle_outline(id,pos,size,color,thickness)local id=self.i..":"..id self[id]=setmetatable({type="rect",id=id,pos=pos,size=size,},better_renderer_mt)utils.rect_outline(self[id].pos,self[id].size,color,thickness)return self[id]end function better_renderer:rectangle_round(id,pos,size,color,radius)local id=self.i..":"..id self[id]=setmetatable({type="rect",id=id,pos=pos,size=size,},better_renderer_mt)utils.rounded_rectangle(self[id].pos.x,self[id].pos.y,self[id].size.x,self[id].size.y,color.r,color.g,color.b,color.a,radius)return self[id]end function better_renderer:rectangle_outline_round(id,pos,size,color,radius,thickness)local id=self.i..":"..id self[id]=self[id] or setmetatable({type="rect",id=id,pos=pos,size=size,},better_renderer_mt)utils.outlined_rounded_rectangle(self[id].pos.x,self[id].pos.y,size.x,size.y,color.r,color.g,color.b,color.a,radius,thickness)return self[id]end function better_renderer:blur(id,pos,size,alpha,amount)local id=self.i..":"..id self[id]=setmetatable({type="rect",id=id,pos=pos,size=size,},better_renderer_mt)renderer.blur(self[id].pos.x,self[id].pos.y,self[id].size.x,self[id].size.y,alpha,amount)return self[id]end function better_renderer:skeety(id,pos,size,gradient)local id=self.i..":"..id self[id]=self[id] or setmetatable({type="rect",id=id,pos=pos,size=size,},better_renderer_mt)utils.skeety(self[id].pos,self[id].size,gradient)return self[id]end function better_renderer:triangle(id,vertex1,vertex2,vertex3,color)local id=self.i..":"..id self[id]=self[id] or setmetatable({type="triangle",id=id,pos={vertex1,vertex2,vertex3}},better_renderer_mt)renderer.triangle(self[id].vertex1.x,self[id].vertex1.y,self[id].vertex2.x,self[id].vertex2.y,self[id].vertex3.x,self[id].vertex3.y,color.r,color.g,color.b,color.a)return self[id]end function better_renderer:triangle_outline(id,vertex1,vertex2,vertex3,color,thickness)local id=self.i..":"..id self[id]=self[id] or setmetatable({type="triangle",id=id,pos={vertex1,vertex2,vertex3}},better_renderer_mt)utils.triangle_outline(self[id].vertex1,self[id].vertex2,self[id].vertex3,color,thickness)return self[id]end function better_renderer:circle(id,pos,color,radius,start_degrees,percentage)local id=self.i..":"..id self[id]=self[id] or setmetatable({type="circle",id=id,pos=pos,radius=radius},better_renderer_mt)renderer.circle(self[id].pos.x,self[id].pos.y,color.r,color.g,color.b,color.a,radius,start_degrees,percentage)return self[id]end function better_renderer:circle_outline(id,pos,color,radius,start_degrees,percentage,thickness)local id=self.i..":"..id self[id]=self[id] or setmetatable({type="circle",id=id,pos=pos,radius=radius},better_renderer_mt)renderer.circle_outline(self[id].pos.x,self[id].pos.y,color.r,color.g,color.b,color.a,radius,start_degrees,percentage,thickness)return self[id]end function better_renderer:circle_fade(id,pos,color,radius,start_degrees,percentage,alpha0,alpha1,fade_speed)local id=self.i..":"..id self[id]=self[id] or setmetatable({type="circle",id=id,pos=pos,radius=radius},better_renderer_mt)for i=radius,1,-1 do alpha0=alpha0>alpha1 and math.floor(utils.lerp(alpha0,alpha1,fade_speed)) or math.ceil(utils.lerp(alpha0,alpha1,fade_speed))renderer.circle_outline(self[id].pos.x,self[id].pos.y,color.r,color.g,color.b,alpha0,i,start_degrees,percentage,1)end renderer.rectangle(self[id].pos.x-1,self[id].pos.x-1,2,2,color.r,color.g,color.b,alpha0)return self[id]end function better_renderer:text(id,pos,color,flags,maxwidth,...)local id=self.i..":"..id self[id]=self[id] or setmetatable({type="text",id=id,pos=pos,size=vector(renderer.measure_text(flags,...)),centred=string.match(flags,"c")},better_renderer_mt)renderer.text(self[id].pos.x,self[id].pos.y,color.r,color.g,color.b,color.a,flags,maxwidth,...)return self[id]end function better_renderer:add_font(fontname,height,width,blur,flags)local id=self.i..":"..string.format("%s%d%d%d",fontname,height,width,blur)if type(flags)~="number"and type(flags)~="table"then return client.error_log("flags must be number or table type")end local fflags=0 if type(flags)=="table"then for _,v in pairs(flags)do fflags=fflags+v end else fflags=flags end local font_handler=render.create_font()render.set_glyph(font_handler,fontname,height,width,blur,0,fflags,0,0)fonts[id]=setmetatable({id=id,font_handler=font_handler,fontname=fontname,size=vector(width,height),blur=blur,flags=fflags},better_renderer_mt)return fonts[id]end function better_renderer:set_glyph(height,width,blur,flags,fontname)if not self.font_handler then return client.error_log(":set_glyph() only avivable after :add_font() method.")end if fonts[self.id].size==vector(width,height)and fonts[self.id].blur==blur and fonts[self.id].flags==flags then return end local fontname=fontname or self.fontname if type(flags)~="number"and type(flags)~="table"then return client.error_log("flags must be number or table type")end local fflags=0 if type(flags)=="table"then for _,v in pairs(flags)do fflags=fflags+v end else fflags=flags end render.set_glyph(self.font_handler,fontname,height,width,blur,0,fflags,0,0)fonts[self.id]=setmetatable({id=id,type="font",font_handler=self.font_handler,fontname=fontname,size=vector(width,height),blur=blur,flags=fflags},better_renderer_mt)end function better_renderer:draw_text(id,pos,color,...)if not self.font_handler then return client.error_log(":draw_text() only avivable with :add_font() method. DID YOU MEAN :text()?")end local id=self.i..":"..id self[id]=self[id] or setmetatable({type="text",id=id,pos=pos,size=utils.get_text_size(self.font_handler,...)},better_renderer_mt)render.draw_textcol(self.font_handler,self[id].pos.x,self[id].pos.y,color.r,color.g,color.b,color.a,...)return self[id]end function better_renderer:text_size(...)return utils.get_text_size(self.font_handler,...)end local dragableabs={}local donotattack={}function better_renderer:drag(enable,hover)if self.type=="font"then return end local current_centred=self.centred and vector(self.pos.x-self.size.x*0.5,self.pos.y-self.size.y*0.5)or nil local inrange=(self.type=="rect"or self.type=="text")and utils.in_range_rect(global.cursor_pos,self.centred and current_centred or self.pos,self.size)or self.type=="triangle"and utils.in_range_triangle(global.cursor_pos,self.pos)or self.type=="circle"and utils.in_range_circle(global.cursor_pos,self.pos,self.radius)donotattack[self.id]=inrange or dragableabs[self.id]local clicked=global.clicked and inrange local firstclick=global.firstclick and inrange if enable and ui.is_menu_open()and not global.on_menu then if firstclick and clicked or dragableabs[self.id]then if inrange or dragableabs[self.id]then dragableabs[self.id]=global.clicked self.pos=self.pos+global.delta end end end end local scaleabs={}function better_renderer:scale(vertical,horizontal,adding,minsize)if self.type~="rect"then return end donotattack[self.id]=utils.in_range_rect(global.cursor_pos,self.pos,self.size)if utils.in_range_rect(global.cursor_pos,self.pos+self.size-vector(adding,adding),vector(adding,adding))and global.firstclick or scaleabs[self.id]then scaleabs[self.id]=global.clicked local sized=self.size+global.delta if vertical and sized.y>=minsize.y and global.cursor_pos.y>=self.pos.y then self.size.y=sized.y end if horizontal and sized.x>=minsize.x and global.cursor_pos.x>=self.pos.x then self.size.x=sized.x end end end utils.deattack=function(cmd)local lplayer=entity.get_local_player()if not lplayer or not entity.is_alive(lplayer)then return end for _,v in pairs(donotattack)do if v then cmd.in_attack=not v end end end local i=0 function better_renderer.new()i=i+1 client.set_event_callback("paint_ui",utils.global_handler)client.set_event_callback("setup_command",utils.deattack)return setmetatable({i=i},better_renderer_mt)end return setmetatable({color=Color,new=better_renderer.new},{__call=function(slot0)return better_renderer.new()end})end)()

local utils do utils = { } function utils:opcode_scan(module, signature, add) local buff = ffi.new("char[1024]") local c = 0 for char in string.gmatch(signature, "..%s?") do if char == "? " or char == "?? " then buff[c] = 0xcc else buff[c] = tonumber("0x" .. char) end c = c + 1 end local result = ffi.cast("uintptr_t", client.find_signature(module, ffi.string(buff))) if add and tonumber(result) ~= 0 then result = ffi.cast("uintptr_t", tonumber(result) + add) end return result end function utils:rel32(address, offset) if address == 0 or address == nil then return 0 end local target_addr = address + offset local rel_offset = ffi.cast("uint32_t*", target_addr)[0] if rel_offset == 0 then return 0 end return target_addr + 4 + rel_offset end function utils:vector_length(x, y) return math.sqrt(x * x + y * y) end end

local motion do
    motion = { }

    motion.lerp = function(start, vend, time)
        return start + (vend - start) * time
    end

    motion.clamp = function( value, min, max )
        return math.min( max, math.max( min, value ) )
    end

    motion.is_close = function(_a, _b, _epsilon)
        return math.abs(_a - _b) < _epsilon
    end
end

local function array_contains(array, value)
    for _, v in ipairs(array) do
        if v == value then
            return true
        end
    end
    return false
end

local context do
    context = { }

    context.local_player = nil
    context.weapon = nil

    context.refs = { 
        ['rage'] = {
            missed_log = ui.reference('RAGE', 'Other', 'Log misses due to spread')
        },

        ['visuals'] = {
            scope_overlay = ui.reference('VISUALS', 'Effects', 'Remove scope overlay'),
            sharedesp = ui.reference('VISUALS', 'Other ESP', 'Shared ESP')
        },

        ['misc'] = {
            output = ui.reference('MISC', 'Miscellaneous', 'Draw console output')
        }
    }

    context.screen_size = {
        x = function()
            return select(1, client.screen_size())
        end,
        
        y = function()
            return select(2, client.screen_size())
        end
    }

    context.information = {
        script = 'paranoia',
        username = panorama.open().MyPersonaAPI.GetName()
    }

    callbacks:set('setup_command', function(cmd)
        if not (entity.get_local_player() and entity.is_alive(entity.get_local_player()) and entity.get_player_weapon(entity.get_local_player())) then
            return
        end

        context.local_player = entity.get_local_player()
        context.weapon = entity.get_player_weapon(context.local_player)
    end)

    client.set_event_callback('shutdown', function()
        if context then
            context = nil
        end

        collectgarbage('collect')
    end)
end

local interfaces do
    interfaces = { }

    -- https://github.com/perilouswithadollarsign/cstrike15_src/blob/f82112a2388b841d72cb62ca48ab1846dfcc11c8/materialsystem/mat_stub.cpp#L449
    interfaces.material_system_hardware_config = { }
    do
        local native_SetHdrEnabled = vtable_bind('materialsystem.dll', 'MaterialSystemHardwareConfig013', 50, 'void(__thiscall*)(void*, bool)')
        local native_GetHdrEnabled = vtable_bind('materialsystem.dll', 'MaterialSystemHardwareConfig013', 49, 'bool(__thiscall*)(void*)')

        function interfaces.material_system_hardware_config:set_hdr_enabled(active)
            native_SetHdrEnabled(active)
        end
        
        function interfaces.material_system_hardware_config:get_hdr_enabled()
            return native_GetHdrEnabled()
        end
    end

    -- https://github.com/tickcount/cstrike15_src/blob/f82112a2388b841d72cb62ca48ab1846dfcc11c8/game/client/input.h#L51
    interfaces.input = { }
    do
        ffi.cdef[[
            typedef unsigned long crc32_t;
            
            typedef struct {
                float x, y, z;
            } vector3d;

            typedef struct {
                int command_number;
                int tickcount;
                vector3d viewangles;
                vector3d aimdirection;
                float forwardmove;
                float sidemove;
                float upmove;
                int buttons;
                char impulse;
                int weaponselect;
                int weaponsubtype;
                int random_seed;
                short mousedx;
                short mousedy;
                bool predicted;
                char pad[0x18];
            } c_usercmd;

            typedef struct {
                c_usercmd cmd;
                crc32_t crc;
            } c_verified_usercmd;

            typedef struct {
                char pad_1[0xC];
                bool trackir_available;
                bool mouse_initialized;
                bool mouse_active;
                char pad_2[0x9A];
                bool camera_in_third_person;
                char pad_3[0x2];
                vector3d camera_offset;
                char pad_4[0x38];
                c_usercmd* commands;
                c_verified_usercmd* verified_commands;
            } c_input;
        ]]

        local input_pattern = utils:opcode_scan('client.dll', 'B9 ? ? ? ? F3 0F 11 04 24 FF 50 10', 1)
  
        function interfaces.input:get()
            return ffi.cast('c_input**', ffi.cast('char*', input_pattern))[0]
        end

        function interfaces.input:thirdperson()
            return self:get().camera_in_third_person
        end

        function interfaces.input:predicted()
            return self:get().commands[0].predicted
        end
    end

    -- https://github.com/tickcount/cstrike15_src/blob/f82112a2388b841d72cb62ca48ab1846dfcc11c8/engine/cdll_engine_int.cpp#L341
    interfaces.engine = { }
    do
        local native_ConsoleOpened = vtable_bind('engine.dll', 'VEngineClient014', 11, 'bool(__thiscall*)(void*)')
        local native_GetLocalPlayer = vtable_bind('engine.dll', 'VEngineClient014', 12, 'int(__thiscall*)(void*)')
        local native_IsInGame = vtable_bind('engine.dll', 'VEngineClient014', 26, 'bool(__thiscall*)(void*)')
        local native_IsConnected = vtable_bind('engine.dll', 'VEngineClient014', 27, 'bool(__thiscall*)(void*)')
        local native_IsDrawingLoadingImage = vtable_bind('engine.dll', 'VEngineClient014', 28, 'bool(__thiscall*)(void*)')
        local native_HideLoadingPlaque = vtable_bind('engine.dll', 'VEngineClient014', 29, 'void(__thiscall*)(void*)')
        local native_GetGameDirectory = vtable_bind('engine.dll', 'VEngineClient014', 36, 'const char*(__thiscall*)(void*)')
        local native_FireEvents = vtable_bind('engine.dll', 'VEngineClient014', 58, 'void(__thiscall*)(void*)')

        function interfaces.engine:console_opened()
            return native_ConsoleOpened()
        end

        function interfaces.engine:get_local_player()
            return native_GetLocalPlayer()
        end

        function interfaces.engine:is_in_game()
            return native_IsInGame()
        end

        function interfaces.engine:is_connected()
            return native_IsConnected()
        end

        function interfaces.engine:is_drawing_loading_image()
            return native_IsDrawingLoadingImage()
        end

        function interfaces.engine:hide_loading_plaque()
            native_HideLoadingPlaque()
        end

        function interfaces.engine:get_game_directory()
            return ffi.string(native_GetGameDirectory())
        end

        function interfaces.engine:fire_events()
            native_FireEvents()
        end
    end

    -- https://github.com/tickcount/cstrike15_src/blob/f82112a2388b841d72cb62ca48ab1846dfcc11c8/engine/l_studio.cpp#L740
    interfaces.model_render = { }
    do
        local native_SuppressEngineLighting = vtable_bind('engine.dll', 'VEngineModel016', 24, 'void(__thiscall*)(void*, bool)')

        function interfaces.model_render:suppress_engine_lighting(suppress)
            native_SuppressEngineLighting(suppress)
        end
    end

    -- https://github.com/tickcount/cstrike15_src/blob/f82112a2388b841d72cb62ca48ab1846dfcc11c8/game/client/cstrike15/gameui/gameui_interface.h#L38
    interfaces.gameui = { }
    do
        local native_CreateCommandMsgBox = vtable_bind('client.dll', 'GameUI011', 19, 'void(__thiscall*)(void*, const char*, const char*, bool, bool, const char*, const char*, const char*, const char*, const char*)')

        function interfaces.gameui:create_command_msgbox(title, message, show_ok, show_cancel, ok_command, cancel_command, closed_command, custombuttontext, legend)
            native_CreateCommandMsgBox(title, message, show_ok or true, show_cancel or false, ok_command or nil, (not cancel_command) and (ok_command or nil) or nil, closed_command or nil, custombuttontext or nil, legend or nil)
        end
    end

    -- https://github.com/tickcount/cstrike15_src/blob/f82112a2388b841d72cb62ca48ab1846dfcc11c8/engine/view.cpp#L272
    interfaces.render_view = { }
    do
        local native_SetBlend = vtable_bind('engine.dll', 'VEngineRenderView014', 4, 'void(__thiscall*)(void*, float)')
        local native_GetBlend = vtable_bind('engine.dll', 'VEngineRenderView014', 5, 'float(__thiscall*)(void*)')

        function interfaces.render_view:set_blend(alpha)
            native_SetBlend(alpha)
        end
        
        function interfaces.render_view:get_blend()
            return native_GetBlend()
        end
    end

    -- https://github.com/tickcount/cstrike15_src/blob/master/game/shared/IEffects.h#L32
    interfaces.effects = { }
    do
        ffi.cdef[[
            typedef struct {
                float x, y, z;
            } vector3d;

            typedef struct {
                float x, y, z;
            } qangle;
        ]]

        local native_EnergySplash = vtable_bind('client.dll', 'IEffects001', 7, 'void(__thiscall*)(void*, const vector3d&, const qangle&, bool)')

        function interfaces.effects:energy_splash(position, angle, explosive)
            local pos = ffi.new('vector3d')
            pos.x = position.x
            pos.y = position.y
            pos.z = position.z

            local ang = ffi.new('qangle')
            ang.x = angle.x
            ang.y = angle.y
            ang.z = angle.z

            native_EnergySplash(pos, ang, explosive or false)
        end
    end

    -- https://github.com/tickcount/cstrike15_src/blob/f82112a2388b841d72cb62ca48ab1846dfcc11c8/vgui2/src/system_posix.cpp#L54
    interfaces.system = { }
    do
        local native_CommandLineParamExists = vtable_bind('vgui2.dll', 'VGUI_System010', 22, 'bool(__thiscall*)(void*, const char*)')

        function interfaces.system:command_line_param(param)
            return native_CommandLineParamExists(param)    
        end
    end
end

local function translate(english_text, russian_text)
    local is_russian = cvar.cl_language:get_string() == 'russian'
    return is_russian and russian_text or english_text
end

local menu do
    menu = { }

    menu.information = {
        ['about'] = {
            warning = gui.label(string.format('✧ %s ~ %s', context.information.script, _DEBUG and 'debug' or 'release')),
        }
    }

    menu.general = {
        tabs = gui.combo('\1', { 
            translate('• Animations', '• Анимации'),
            translate('• Visuals', '• Визуальные эффекты'), 
            translate('• World', '• Мир'), 
            translate('• Misc', '• Прочее') 
        }),

        ['animations'] = {
            player = gui.selectable(translate('Animations', 'Анимации'), { 
                translate('Disable Move Lean', 'Отключить наклон при движении'), 
                translate('Interpolate', 'Интерполяция') 
            }),
            falling = gui.combo(translate('Falling Animation', 'Анимация падения'), { 
                translate('Disabled', 'Отключено'), 
                translate('Forced', 'Принудительно'), 
                translate('Legacy', 'Устаревшая')
            }),
            freeze = gui.combo(translate('On freeze period', 'Во время заморозки'), { 
                translate('Disabled', 'Отключено'), 
                translate('Main menu', 'Главное меню'), 
                translate('"I give up"', '"Я сдаюсь"'), 
                translate('T-Pose', 'Т-поза') 
            })
        },

        ['visuals'] = {
            ['thirdperson'] = {
                distance = gui.slider(translate('Thirdperson distance', 'Дистанция от третьего лица'), 30, 230, 150, true, '', 1, { [30] = translate('Min', 'Минимальный'), [150] = translate('Default', 'По умолчанию'), [230] = translate('Max', 'Максимальный') } ),
            },

            accent_color_text = gui.label(translate('Accent Color', 'Цвет акцента')),
            accent_color = gui.color_picker(translate('Accent Color', 'Цвет акцента')),

            ['viewmodel'] = {
                in_scope = gui.switch(translate('Viewmodel in scope', 'Модель оружия в прицеле'))
            },

            ['scope'] = {
                enabled = gui.switch(translate('Custom scope overlay', 'Настраиваемый прицел')),
                gap = gui.slider(translate('Scope gap', 'Зазор прицела'), 0, 50, 5, true, 'px'),
                size = gui.slider(translate('Scope size', 'Размер прицела'), 15, 300, 30, true, 'px')
            },

            ['widgets'] = {
                watermark = gui.switch(translate('Watermark', 'Водяной знак')),
                crosshair = gui.switch(translate('Center Indicators', 'Центральные индикаторы')),
    
                ['metrics'] = {
                    enable = gui.switch(translate('Network Metrics', 'Сетевые показатели'))
                },

                eventlogs = gui.switch(translate('Event Logs', 'Логи'))
            }
        },

        ['world'] = {
            ['aspectratio'] = {
                enabled = gui.switch(translate('Aspect Ratio', 'Соотношение сторон')),
                value = gui.slider(translate('Aspect Ratio Value', 'Значение соотношения сторон'), 59, 200, 177, true, '', 1, { 
                    [59] = translate('Off', 'Выкл'), 
                    [125] = '5:4', 
                    [133] = '4:3', 
                    [150] = '3:2', 
                    [177] = '16:9', 
                    [161] = '16:10' 
                }),
            },

            ['ambient'] = {
                wall_dyeing = gui.switch(translate('Wall Dyeing', 'Окрашивание стен')),
                wall_dyeing_color = gui.color_picker(translate('Wall Dyeing Color', 'Цвет окрашивания стен')),
                model_ambient = gui.slider(translate('Model Brightness', 'Яркость модели'), 0, 100, 0),
                force_hdr = gui.switch(translate('Force HDR', 'Принудительный HDR'))
            },

            ['removals'] = {
                blood = gui.switch(translate('No Blood', 'Отключить кровь')),
                ragdolls = gui.combo(translate('Disable Ragdolls', 'Отключить регдоллы'), { 
                    translate('Disabled', 'Отключено'), 
                    translate('Physics', 'Физика'), 
                    translate('Rendering', 'Рендеринг') 
                })
            }
        },

        ['misc'] = {
            spawn_effect = gui.switch(translate('Spawn Effect', 'Эффект появления')),
            jittermove = gui.switch(translate('Jitter move', 'Дрожащее движение')),
            panorama = gui.selectable(translate('⋆☾⋆⁺₊ Panorama', '⋆☾⋆⁺₊ Панорама'), { 
                translate('CS:GO Logo', 'Логотип CS:GO'), 
                translate('Remove News and Shop', 'Убрать новости и магазин'), 
                translate('Change background', 'Изменить фон'), 
                translate('Remove stats button', 'Убрать кнопку статистики'), 
                translate('Remove watch button', 'Убрать кнопку просмотра'), 
                translate('Remove sidebar', 'Убрать боковую панель'), 
                translate('Remove model in mainmenu', 'Убрать модель в главном меню') 
            })
        }
    }
end

-- @ menu visibility
do
    local function menu_visibility(visible)
        -- @ main
        do
            local current_tab = menu.general.tabs:get()

            menu.general.animations.player:visibility(current_tab == translate('• Animations', '• Анимации'))
            menu.general.animations.falling:visibility(current_tab == translate('• Animations', '• Анимации'))
            menu.general.animations.freeze:visibility(current_tab == translate('• Animations', '• Анимации'))
        end

        -- @ visuals
        do
            local current_tab = menu.general.tabs:get()

            menu.general.visuals.accent_color_text:visibility(current_tab == translate('• Visuals', '• Визуальные эффекты'))
            menu.general.visuals.accent_color:visibility(current_tab == translate('• Visuals', '• Визуальные эффекты'))

            menu.general.visuals.thirdperson.distance:visibility(current_tab == translate('• Visuals', '• Визуальные эффекты'))

            menu.general.visuals.viewmodel.in_scope:visibility(current_tab == translate('• Visuals', '• Визуальные эффекты'))

            menu.general.visuals.scope.enabled:visibility(current_tab == translate('• Visuals', '• Визуальные эффекты'))
            menu.general.visuals.scope.gap:visibility(current_tab == translate('• Visuals', '• Визуальные эффекты') and menu.general.visuals.scope.enabled:get())
            menu.general.visuals.scope.size:visibility(current_tab == translate('• Visuals', '• Визуальные эффекты') and menu.general.visuals.scope.enabled:get())

            menu.general.visuals.widgets.watermark:visibility(current_tab == translate('• Visuals', '• Визуальные эффекты'))
            
            menu.general.visuals.widgets.crosshair:visibility(current_tab == translate('• Visuals', '• Визуальные эффекты'))

            menu.general.visuals.widgets.metrics.enable:visibility(current_tab == translate('• Visuals', '• Визуальные эффекты'))

            menu.general.visuals.widgets.eventlogs:visibility(current_tab == translate('• Visuals', '• Визуальные эффекты'))
        end

        -- @ world
        do
            local current_tab = menu.general.tabs:get()

            menu.general.world.aspectratio.enabled:visibility(current_tab == translate('• World', '• Мир'))
            menu.general.world.aspectratio.value:visibility(current_tab == translate('• World', '• Мир') and menu.general.world.aspectratio.enabled:get())

            menu.general.world.ambient.wall_dyeing:visibility(current_tab == translate('• World', '• Мир'))
            menu.general.world.ambient.wall_dyeing_color:visibility(current_tab == translate('• World', '• Мир') and menu.general.world.ambient.wall_dyeing:get())
            menu.general.world.ambient.model_ambient:visibility(current_tab == translate('• World', '• Мир') and menu.general.world.ambient.wall_dyeing:get())

            menu.general.world.ambient.force_hdr:visibility(current_tab == translate('• World', '• Мир'))

            menu.general.world.removals.blood:visibility(current_tab == translate('• World', '• Мир'))
            menu.general.world.removals.ragdolls:visibility(current_tab == translate('• World', '• Мир'))

            
        end

        -- @ misc
        do
            local current_tab = menu.general.tabs:get()

            menu.general.misc.spawn_effect:visibility(current_tab == translate('• Misc', '• Прочее'))

            menu.general.misc.jittermove:visibility(current_tab == translate('• Misc', '• Прочее'))
            menu.general.misc.panorama:visibility(current_tab == translate('• Misc', '• Прочее'))
        end

        -- @ for shared
        do
            local shared_esp = context.refs.visuals.sharedesp
            ui.set(shared_esp, false)
            ui.set_enabled(shared_esp, visible)
        end

        -- @ for logs
        do
            local missed_log = context.refs.rage.missed_log
            ui.set(missed_log, not menu.general.visuals.widgets.eventlogs:get() and ui.get(context.refs.rage.missed_log) or false)
            ui.set_enabled(missed_log, not menu.general.visuals.widgets.eventlogs:get())

            local output_console = context.refs.misc.output
            ui.set(output_console, menu.general.visuals.widgets.eventlogs:get())
            ui.set_enabled(output_console, not menu.general.visuals.widgets.eventlogs:get())
        end
    end

    local force_hdr = ui.reference('LUA', 'A', translate('Force HDR', 'Принудительный HDR'))
    ui.set(force_hdr, interfaces.material_system_hardware_config:get_hdr_enabled()) -- cringe =(

    callbacks:set('paint_ui', function()
        menu_visibility(false)
    end)

    callbacks:set('shutdown', function()
        menu_visibility(true)
    end)
end

-- @ force hdr [ needfix ]
do
    local forcehdr = { }

    function forcehdr:run()
        if not menu.general.world.ambient.force_hdr:get() then
            if interfaces.material_system_hardware_config:get_hdr_enabled() then
                interfaces.model_render:suppress_engine_lighting(true)
                interfaces.material_system_hardware_config:set_hdr_enabled(false)
                return
            else
               return 
            end
        else
            if not interfaces.material_system_hardware_config:get_hdr_enabled() then
                interfaces.model_render:suppress_engine_lighting(false)
                interfaces.material_system_hardware_config:set_hdr_enabled(true)
                return
            else
                return
            end
        end
    end

    callbacks:set('paint_ui', function()
        forcehdr:run()
    end)
end

-- @ jittermove
do
    local jittermove = { }

    function jittermove:run(cmd)
        if not menu.general.misc.jittermove:get() then
            return
        end

        if not context.local_player then
            return
        end

        local on_ground = bit.band(entity.get_prop(context.local_player, 'm_fFlags'), 1) == 1
        if not on_ground then
            return
        end

        local tickrate_rate = 5 / 64 -- 5 / TICKRATE
        local rate = ((cmd.command_number % 64) * tickrate_rate) + 95

        local strength = motion.clamp(rate, 95, 100)

        local max_speed = 250

        if context.weapon then
            local weapon_type = entity.get_prop(context.weapon, 'm_iItemDefinitionIndex')

            if weapon_type == 9 then -- AWP
                max_speed = 200
            elseif weapon_type == 40 then -- Scout
                max_speed = 230
            end

            local is_scoped = entity.get_prop(context.local_player, 'm_bIsScoped') == 1
            if is_scoped then
                max_speed = max_speed * 0.75
            end
        end

        local target_speed = (strength / 100) * max_speed
        local current_movement_speed = utils:vector_length(cmd.forwardmove, cmd.sidemove)
        
        if current_movement_speed > 0.1 and current_movement_speed > target_speed then
            local scale = target_speed / current_movement_speed
            cmd.forwardmove = cmd.forwardmove * scale
            cmd.sidemove = cmd.sidemove * scale
        end
        
        cmd.forwardmove = motion.clamp(cmd.forwardmove, -450, 450)
        cmd.sidemove = motion.clamp(cmd.sidemove, -450, 450)
    end

    callbacks:set('setup_command', function(cmd)
        jittermove:run(cmd)
    end)
end

-- @ animations
do
    local animations = { }
    function animations:init()
        if not context.local_player then
            return
        end

        local my_data = c_entity(context.local_player)
        if not my_data then
            return
        end

        local animstate = c_entity.get_anim_state(my_data)
        if not animstate then
            return
        end

        local velocity = vector(entity.get_prop(context.local_player, 'm_vecVelocity')):length2d() -- animstate.m_velocity
        local on_ground = animstate.on_ground

        local animations_select = menu.general.animations.player:get()
        local falling_animations = menu.general.animations.falling:get()
        local freeze_animations = menu.general.animations.freeze:get()

        if falling_animations == 'Forced' then
            entity.set_prop(context.local_player, 'm_flPoseParameter', 1, 6)
        end

        if falling_animations == 'Legacy' then -- [ needfix ]
            entity.set_prop(context.local_player, 'm_flPoseParameter', 0.35, 6)
        end

        if array_contains(animations_select, translate('Disable Move Lean', 'Отключить наклон при движении')) then
            my_data:get_anim_overlay(12).weight = 0
            my_data:get_anim_overlay(12).playback_rate = 0
        end

        local game_rules = entity.get_game_rules()
        if game_rules ~= nil then
            local is_freeze_time = entity.get_prop(game_rules, 'm_bFreezePeriod') == 1

            if is_freeze_time then
                if freeze_animations == 'Main menu' then
                    my_data:get_anim_overlay(0).cycle = 1
                    my_data:get_anim_overlay(0).sequence = 10
                end

                if freeze_animations == '"I give up"' then
                    my_data:get_anim_overlay(0).cycle = 0.8
                    my_data:get_anim_overlay(0).sequence = 262
                end

                if freeze_animations == 'T-Pose' then
                    my_data:get_anim_overlay(0).cycle = 0.2
                    my_data:get_anim_overlay(0).sequence = 11
                end
            end
        end
    end
    callbacks:set('pre_render', function()
        animations:init()
    end)

    local animation_fix = { }
    animation_fix.data = {
        layers = { },
        server_anim_states = { },
        history = 64,
        initialized = false
    }
    
    function animation_fix:initialize_layers()
        self.data.layers = { }
        
        for i = 0, 12 do
            self.data.layers[i] = {
                cycle = 0,
                weight = 0,
                playback_rate = 0,
                sequence = 0
            }
        end
        
        self.data.initialized = true
    end

    function animation_fix:capture_state()
        local animations_select = menu.general.animations.player:get()
        if not array_contains(animations_select, translate('Interpolate', 'Интерполяция')) then
            return nil
        end

        if context.local_player == nil or context.weapon == nil then
            return nil
        end

        local game_rules = entity.get_game_rules()
        if game_rules == nil then
            return
        end

        local is_freeze_time = entity.get_prop(game_rules, 'm_bFreezePeriod') == 1
        if is_freeze_time then
            return
        end
        
        local self_index = c_entity(context.local_player)
        local anim_state = self_index:get_anim_state()
        if not anim_state then
            return nil
        end
    
        local state = {
            time = globals.curtime(),
            layers = { }
        }
        
        for layer_idx, _ in pairs(self.data.layers) do
            local layer = self_index:get_anim_overlay(layer_idx)
            if layer then
                state.layers[layer_idx] = {
                    cycle = layer.cycle,
                    weight = layer.weight,
                    playback_rate = layer.playback_rate,
                    sequence = layer.sequence
                }
            end
        end
    
        return state
    end

    function animation_fix:setup_command()
        local animations_select = menu.general.animations.player:get()
        if not array_contains(animations_select, translate('Interpolate', 'Интерполяция')) then
            return
        end

        if not self.data.initialized then
            self:initialize_layers()
        end
        
        local state = self:capture_state()
        if not state then
            return
        end
        
        table.insert(self.data.server_anim_states, state)
        
        if #self.data.server_anim_states > self.data.history then
            table.remove(self.data.server_anim_states, 1)
        end
    end

    function animation_fix:find_interpolation_states(time)
        local server_states = self.data.server_anim_states
        
        -- if we don't have information for interpolate our states we can't interpolate
        if #server_states < 2 then
            return nil, nil
        end
        
        for i = #server_states - 1, 1, -1 do
            if server_states[i].time <= time and server_states[i+1].time >= time then
                return server_states[i], server_states[i+1]
            end
        end
        
        return server_states[#server_states - 1], server_states[#server_states]
    end
    
    function animation_fix:apply_interpolated_state(state1, state2, t)
        local animations_select = menu.general.animations.player:get()
        if not array_contains(animations_select, translate('Interpolate', 'Интерполяция')) then
            return
        end

        if context.local_player == nil or context.weapon == nil then
            return nil
        end

        local game_rules = entity.get_game_rules()
        if game_rules == nil then
            return
        end

        local is_freeze_time = entity.get_prop(game_rules, 'm_bFreezePeriod') == 1
        if is_freeze_time then
            return
        end
        
        local self_index = c_entity(context.local_player)
        if self_index == nil then
            return
        end
    
        for layer_idx, _ in pairs(self.data.layers) do
            local layer = self_index:get_anim_overlay(layer_idx)
            if layer and state1.layers[layer_idx] and state2.layers[layer_idx] then
                local layer1 = state1.layers[layer_idx]
                local layer2 = state2.layers[layer_idx]
                
                -- if the layer is the same as the previous one, don't interpolate
                layer.cycle = (layer1.cycle == layer2.cycle) and layer2.cycle or motion.lerp(layer1.cycle, layer2.cycle, t)
                layer.weight = (layer1.weight == layer2.weight) and layer2.weight or motion.lerp(layer1.weight, layer2.weight, t)
                layer.playback_rate = (layer1.playback_rate == layer2.playback_rate) and layer2.playback_rate or motion.lerp(layer1.playback_rate, layer2.playback_rate, t)
                layer.sequence = (layer1.sequence == layer2.sequence) and layer2.sequence or motion.lerp(layer1.sequence, layer2.sequence, t)
            end
        end
    end
    
    function animation_fix:interpolate()
        local animations_select = menu.general.animations.player:get()
        if not array_contains(animations_select, translate('Interpolate', 'Интерполяция')) then
            return
        end

        if not self.data.initialized then
            return
        end
        
        if context.local_player == nil or context.weapon == nil then
            return nil
        end

        local game_rules = entity.get_game_rules()
        if game_rules == nil then
            return
        end

        local is_freeze_time = entity.get_prop(game_rules, 'm_bFreezePeriod') == 1
        if is_freeze_time then
            return
        end
        
        local current_time = globals.curtime()
        
        local state1, state2 = self:find_interpolation_states(current_time)
        if not state1 or not state2 then
            return
        end
        
        local time_diff = state2.time - state1.time
        if time_diff <= 0 then
            return
        end
        
        local t = (current_time - state1.time) / time_diff
        t = motion.clamp(t, 0, 1)
    
        self:apply_interpolated_state(state1, state2, t)
    end
    
    function animation_fix:reset()
        self.data.server_anim_states = { }
        self:initialize_layers()
    end
    
    local event_list = {
        on_setup_command = function(ctx)
            animation_fix:setup_command()
        end,
        on_pre_render = function()
            animation_fix:interpolate()
        end,
        on_round_start = function()
            animation_fix:reset()
        end,
        on_player_death = function(ctx)
            if not (ctx.userid and ctx.attacker) then
                return
            end

            if context.local_player ~= client.userid_to_entindex(ctx.userid) then
                return
            end
    
            animation_fix:reset()
        end,
        on_level_init = function()
            animation_fix:reset()
        end,
        on_shutdown = function()
            if animation_fix then
                if animation_fix.data then
                    animation_fix.data.layers = { }
                    animation_fix.data.server_anim_states = { }
                    animation_fix.data = { }
                end
                
                for k, _ in pairs(animation_fix) do
                    animation_fix[k] = nil
                end
                
                animation_fix = nil
            end
        
            collectgarbage('collect')
            collectgarbage('collect') -- =)
        end
    }
    
    for k, v in next, event_list do
        client.set_event_callback(k:sub(4), function(ctx)
            v(ctx)
        end)
    end
end

-- @ viewmodel
do
    local _viewmodel = { }

    -- https://github.com/mmirraacclee/airflow-csgo-cheat/blob/c6341cb4449b424a69fb22fd5bc7f480e2f846e5/v1/Airflow/base/sdk/entity.h#L337
    local ccsweaponinfo_t = [[
        struct {
            char pad_0000[20];                 // 0x0000
            uint32_t max_ammo_1;                  // 0x0014
            char pad_0018[12];                 // 0x0018
            uint32_t max_ammo_2;                  // 0x0024
            char pad_0028[84];                 // 0x0028
            char* N00000985;                      // 0x007C
            char pad_0080[8];                  // 0x0080
            char* hud_name;                       // 0x0088
            char* weapon_name;                    // 0x008C
            char pad_0090[56];                 // 0x0090
            uint32_t weapon_type;                 // 0x00C8
            char pad_00CC[4];
            int weapon_price;
            int kill_award;
            char* animation_prefix;
            float cycle_time;
            float cycle_time_alt;
            float time_to_idle;
            float idle_interval;
            bool full_auto;
            char pad_0x00e5[3];
            uint32_t dmg;                         // 0x00F0
            float crosshair_delta_distance;       // 0x00F4
            float armor_ratio;                    // 0x00F8
            uint32_t bullets;                     // 0x00FC
            float penetration;                    // 0x0100
            float flinch_velocity_modifier_large; // 0x0104
            float flinch_velocity_modifier_small; // 0x0108
            float range;                          // 0x010C
            float range_modifier;                 // 0x0110
            float throw_velocity;                 // 0x0114
            char pad_0118[20];                 // 0x0118
            uint32_t crosshair_delta_dist;        // 0x012C
            uint32_t crosshair_min_dist;          // 0x0130
            float max_speed;                      // 0x0134
            float max_speed_alt;                  // 0x0138
            char pad_013C[12];                 // 0x013C
            float inaccuracy_crouch;              // 0x0148
            float inaccuracy_crouch_alt;          // 0x014C
            float inaccuracy_stand;               // 0x0150
            float inaccuracy_stand_alt;           // 0x0154
            float inaccuracy_jump;                // 0x0158
            float inaccuracy_jump_alt;            // 0x015C
            float inaccuracy_land;                // 0x0160
            float inaccuracy_land_alt;            // 0x0164
            char pad_0168[96];                 // 0x0168
            bool unk;                             // 0x01C8
            char pad_0169[4];                     // 0x01C9
            bool hide_viewmodel_in_zoom;          // 0x01CD
        }
    ]]

    local match = client.find_signature('client_panorama.dll', '\x8B\x35\xCC\xCC\xCC\xCC\xFF\x10\x0F\xB7\xC0')
    local weaponsystem_raw = ffi.cast('void****', ffi.cast('char*', match) + 2)[0]
    local get_weapon_info = vtable_thunk(2, ccsweaponinfo_t .. '*(__thiscall*)(void*, unsigned int)')

    function _viewmodel:hide_in_scope()
        if context.local_player == nil then
            return
        end

        if context.weapon == nil then
            return
        end

        local weapon_id = entity.get_prop(context.weapon, 'm_iItemDefinitionIndex')
        if not weapon_id then
            return
        end

        local weapon_info = get_weapon_info(weaponsystem_raw, weapon_id)
        if weapon_info == nil then
            return
        end

        weapon_info.hide_viewmodel_in_zoom = not menu.general.visuals.viewmodel.in_scope:get()
    end

    function _viewmodel:shutdown()
        if context.local_player == nil then
            return
        end

        if context.weapon == nil then
            return
        end

        local weapon_id = entity.get_prop(context.weapon, 'm_iItemDefinitionIndex')
        if not weapon_id then
            return
        end

        local weapon_info = get_weapon_info(weaponsystem_raw, weapon_id)
        if weapon_info == nil then
            return
        end

        weapon_info.hide_viewmodel_in_zoom = true
    end

    callbacks:set('run_command', function()
        _viewmodel:hide_in_scope()
    end)
    callbacks:set('shutdown', function()
        _viewmodel:shutdown()
    end)
end

-- @ thirdperson distance
context.thirdperson = 150
do
    local thirdperson = { }
    local current_distance = context.thirdperson
    local epsilon = 0.01

    function thirdperson:run()
        if interfaces.input:thirdperson() == false then
            current_distance = 30
            return
        end

        local target_distance = menu.general.visuals.thirdperson.distance:get()
        
        if not motion.is_close(current_distance, target_distance, epsilon) then
            local new_distance = motion.lerp(current_distance, target_distance, globals.frametime() * 8)
            
            if not motion.is_close(new_distance, current_distance, epsilon) then
                current_distance = new_distance
                cvar.cam_idealdist:set_float(current_distance)
            end
        end
    end

    function thirdperson:shutdown()
        cvar.cam_idealdist:set_float(context.thirdperson)
    end
    
    callbacks:set('paint', function() thirdperson:run() end)
    callbacks:set('shutdown', function() thirdperson:shutdown() end)
end

-- @ scope overlay
do
    local scope_overlay = { }
    function scope_overlay:paint_ui()
        ui.set(context.refs.visuals.scope_overlay, true)
    end

    function scope_overlay:render()
        if not menu.general.visuals.scope.enabled:get() then
            return
        end
    
        if context.local_player == nil then
            return
        end
    
        local me_alive = entity.is_alive(context.local_player)
        if not me_alive then
            return
        end
    
        ui.set(context.refs.visuals.scope_overlay, false)
    
        local scoped = entity.get_prop(context.local_player, 'm_bIsScoped') == 1

        local target_size = scoped and menu.general.visuals.scope.size:get() or 0

        if not animated_size then
            animated_size = 0
        end
        animated_size = motion.lerp(animated_size, target_size, globals.frametime() * 10)

        if animated_size < 0.1 then
            return
        end
        
        local scope_r, scope_g, scope_b, scope_a = menu.general.visuals.accent_color:get()
        local gap = menu.general.visuals.scope.gap:get()
        
        local screen_x, screen_y = context.screen_size.x(), context.screen_size.y()

        renderer.gradient(screen_x / 2, screen_y / 2 + gap, 1, animated_size, scope_r, scope_g, scope_b, scope_a, scope_r, scope_g, scope_b, 0, false)
        renderer.gradient(screen_x / 2, screen_y / 2 - gap, 1, -animated_size, scope_r, scope_g, scope_b, scope_a, scope_r, scope_g, scope_b, 0, false)

        renderer.gradient(screen_x / 2 + gap, screen_y / 2, animated_size, 1, scope_r, scope_g, scope_b, scope_a, scope_r, scope_g, scope_b, 0, true)
        renderer.gradient(screen_x / 2 - gap, screen_y / 2, -animated_size, 1, scope_r, scope_g, scope_b, scope_a, scope_r, scope_g, scope_b, 0, true)
    end

    callbacks:set('paint_ui', function()
        scope_overlay:paint_ui()
    end)

    callbacks:set('paint', function()
        scope_overlay:render()
    end)
end

-- @ network metrics
do
    -- https://github.com/tickcount/cstrike15_src/blob/f82112a2388b841d72cb62ca48ab1846dfcc11c8/public/tier0/cpumonitoring.h#L9
    ffi.cdef[[
        typedef struct {
            double m_timeStamp; // Time (from Plat_FloatTime) when the measurements were made.
            float m_GHz;
            float m_percentage;
            float m_lowestPercentage;
        } CPUFrequencyResults;
    ]]

    local fps_samples, avg_samples = { }, { }
    local function smooth_fps(current)
        table.insert(fps_samples, current)
        if #fps_samples > 64 then table.remove(fps_samples, 1) end
        local sum = 0
        for _, v in ipairs(fps_samples) do sum = sum + v end
        return sum / #fps_samples
    end
    local function avg_smooth(current)
        table.insert(avg_samples, current)
        if #avg_samples > 64 then table.remove(avg_samples, 1) end
        local sum = 0
        for _, v in ipairs(avg_samples) do sum = sum + v end
        return sum / #avg_samples
    end
    
    local signature_cpu = utils:opcode_scan('engine.dll', 'FF 15 ? ? ? ? 83 C4 ? 0F 10 08')
    local cpu_frequency_results = ffi.cast('CPUFrequencyResults*', ffi.cast('void**', ffi.cast('char***', ffi.cast('char*', signature_cpu) + 2)[0][0] + 237)[0])
    
    local metrics = {
        alpha = 0,
        data = {
            fps = { alpha = 0, height = 0 },
            cpu = { alpha = 0, height = 0 },
            latency = { alpha = 0, height = 0 },
            server = { alpha = 0, height = 0 },
            network = { alpha = 0, height = 0 }
        },
        height = 0
    }

    function metrics:is_connected()
        return interfaces.engine:is_in_game()
    end
    
    local function network_metrics()
        local better_render = render.new()
        local enabled = menu.general.visuals.widgets.metrics.enable:get()

        metrics.alpha = motion.lerp(metrics.alpha, enabled and 1 or 0, globals.frametime() * 6)
        if metrics.alpha < 0.01 and not enabled then return end

        local width = 305
        local x = context.screen_size.x() - width - 350
        local y = context.screen_size.y() - 189
    
        better_render:rectangle_round('bg_1', vector(x, y), vector(width, metrics.height - 5), render.color(25, 25, 30, math.floor(100 * metrics.alpha)), 15)
        better_render:blur('bg_2', vector(x, y), vector(width, metrics.height - 5), render.color(0, 0, 0, math.floor(220 * metrics.alpha)), 15)
        better_render:rectangle_outline_round('bg_3', vector(x, y), vector(width, metrics.height - 5), render.color(65, 65, 70, math.floor(235 * metrics.alpha)), 15, 1)
        better_render:text('title', vector(x + width/8 + 10, y + 10), render.color(255,255,255,math.floor(255*metrics.alpha)), 'c', 0, 'Network Metrics')
        renderer.line(x + 18, y + 24, x + width - 18, y + 24)
    
        local cpu_ghz = cpu_frequency_results.m_GHz
        local cpu_usage = cpu_frequency_results.m_percentage
        local lowest_usage = cpu_frequency_results.m_lowestPercentage
    
        local frametime = globals.frametime()
        local current_fps = math.floor(1 / frametime)
        local smoothed_fps = smooth_fps(current_fps)
        local avg_fps = avg_smooth(math.abs((frametime * 1000) - 5))
    
        local ping = metrics:is_connected() and client.latency() * 1000 or 0
        ping = metrics:is_connected() and math.floor(ping) or 0

        local netchan_ptr = metrics:is_connected() and INetChannelInfo.get_net_channel_info(INetChannelInfo.ivengineclient) or nil
        local net_channel = metrics:is_connected() and INetChannelInfo.GetNetChannel(ffi.cast('void***', netchan_ptr)) or nil
    
        local outgoing_cur, incoming_cur = 0, 0
        local outgoing_avg, incoming_avg = 0, 0
        local got_bytes, sent_bytes = 0, 0
        local choke, loss = 0, 0
    
        if metrics:is_connected() and net_channel then
            outgoing_cur = net_channel.latency.crn(0) * 1000
            incoming_cur = net_channel.latency.crn(1) * 1000
            outgoing_avg = math.abs(outgoing_cur - net_channel.latency.average(0) * 1000)
            incoming_avg = math.abs(incoming_cur - net_channel.latency.average(1) * 1000)
            got_bytes = net_channel.got_bytes/1024
            sent_bytes = net_channel.sent_bytes/1024
            choke = net_channel.choke*100
            loss = net_channel.loss*100
        end
    
        local metrics_data = {
            {
                name = '⚡ fps',
                value = string.format('%dfps (%.1fms)', math.floor(smoothed_fps), avg_fps),
                enabled = enabled,
                key = 'fps'
            },
            {
                name = '⚙️ cpu',
                value = string.format('%.1f%% (%.2f GHz), %.1f%%', cpu_usage, cpu_ghz, lowest_usage),
                enabled = enabled,
                key = 'cpu'
            },
            {
                name = '⏱ latency',
                value = string.format('ping: %sms, choke: %.1f%%, loss: %.1f%%', ping, choke, loss),
                enabled = enabled and metrics:is_connected(),
                key = 'latency'
            },
            {
                name = '⇅ server',
                value = string.format('↓ in: %.1fms +- %.1fms  ↑ out: %.1fms +- %.1fms', incoming_cur, incoming_avg, outgoing_cur, outgoing_avg),
                enabled = enabled and metrics:is_connected(),
                key = 'server'
            },
            {
                name = '⇅ network',
                value = string.format('↓ in: %.2f kb/s  ↑ out: %.2f kb/s', got_bytes, sent_bytes),
                enabled = enabled and metrics:is_connected(),
                key = 'network'
            }
        }
    
        local y_offset = 30
        local left_padding = 12
        local right_padding = 12
        local target_height = y_offset + 10
    
        for _, metric in ipairs(metrics_data) do
            local d = metrics.data[metric.key]
            d.alpha = d.alpha + (metric.enabled and (1 - d.alpha) or -d.alpha) * 0.1
            d.height = d.height + (metric.enabled and (20 - d.height) or -d.height) * 0.1
    
            if d.alpha > 0.01 then
                better_render:text('name_'..metric.key, vector(x + left_padding, y + y_offset), render.color(255,255,255,math.floor(255*d.alpha*metrics.alpha)), '', 0, metric.name)
                local value_text = metric.value
                local value_width = renderer.measure_text('', value_text)
                better_render:text('val_'..metric.key, vector(x + width - value_width - right_padding, y + y_offset), render.color(200,200,200,math.floor(255*d.alpha*metrics.alpha)), 'b', 0, value_text)
                y_offset = y_offset + d.height
            end
            target_height = target_height + d.height
        end
    
        metrics.height = metrics.height + (target_height - metrics.height) * 0.1
    end
    
    callbacks:set('paint_ui', function()
        network_metrics()
    end)
end

-- @ ambient
do
    local model_ambient = { }
    model_ambient.apply = function()
        cvar.r_modelAmbientMin:set_int(menu.general.world.ambient.model_ambient:get()/10)
    end

    model_ambient.unload = function()
        cvar.r_modelAmbientMin:set_int(0)
    end
    callbacks:set('paint', model_ambient.apply)
    callbacks:set('shutdown', model_ambient.unload)

    local world_color = { }
    world_color.init = function()
        if not menu.general.world.ambient.wall_dyeing:get() then
            cvar.mat_ambient_light_r:set_float(0)
            cvar.mat_ambient_light_g:set_float(0)
            cvar.mat_ambient_light_b:set_float(0)
            cvar.r_modelAmbientMin:set_int(0)
            return
        end

        local r, g, b, a = menu.general.world.ambient.wall_dyeing_color:get()

        cvar.mat_ambient_light_r:set_float(r / 100)
        cvar.mat_ambient_light_g:set_float(g / 100)
        cvar.mat_ambient_light_b:set_float(b / 100)
    end

    world_color.unload = function()
        cvar.mat_ambient_light_r:set_float(0)
        cvar.mat_ambient_light_g:set_float(0)
        cvar.mat_ambient_light_b:set_float(0)
    end
    callbacks:set('paint', world_color.init)
    callbacks:set('shutdown', world_color.unload)
end

-- @ no blood
do
    local blood = { }

    blood.data = {
        violence_ablood = {
            default = 1,
            new = 0
        },

        violence_hblood = {
            default = 1,
            new = 0
        }
    }

    function blood:remove()
        cvar.violence_ablood:set_string(menu.general.world.removals.blood:get() and self.data.violence_ablood.new or self.data.violence_ablood.default)
        cvar.violence_hblood:set_string(menu.general.world.removals.blood:get() and self.data.violence_hblood.new or self.data.violence_hblood.default)
    end

    function blood:shutdown()
        cvar.violence_ablood:set_string(self.data.violence_ablood.default)
        cvar.violence_hblood:set_string(self.data.violence_hblood.default)
    end

    callbacks:set('paint', function()
        blood:remove()
    end)
    callbacks:set('shutdown', function()
        blood:shutdown()
    end)
end

-- @ disable ragdolls
do
    local ragdolls = { }
    ragdolls.data = {
        cl_ragdoll_physics_enable = {
            default = 1,
            new = 0
        },

        cl_disable_ragdolls = {
            default = 0,
            new = 1
        }
    }

    function ragdolls:remove()
        local physics = menu.general.world.removals.ragdolls:get() == 'Physics'
        cvar.cl_ragdoll_physics_enable:set_int(physics and self.data.cl_ragdoll_physics_enable.new or self.data.cl_ragdoll_physics_enable.default)

        local rendering = menu.general.world.removals.ragdolls:get() == 'Rendering'
        cvar.cl_disable_ragdolls:set_int(rendering and self.data.cl_disable_ragdolls.new or self.data.cl_disable_ragdolls.default)
    end

    function ragdolls:shutdown()
        cvar.cl_ragdoll_physics_enable:set_int(self.data.cl_ragdoll_physics_enable.default)
        cvar.cl_disable_ragdolls:set_int(self.data.cl_disable_ragdolls.default)
    end

    callbacks:set('paint', function()
        ragdolls:remove()
    end)
    callbacks:set('shutdown', function()
        ragdolls:shutdown()
    end)
end

-- @ aspectratio
context.aspectratio = 177
do
    local aspectratio = function()
        local target_value
        local current_value = context.aspectratio
        local slider_value = menu.general.world.aspectratio.value:get()
        local epsilon = 0.01 
    
        if menu.general.world.aspectratio.enabled:get() then
            if slider_value ~= 59 then
                target_value = slider_value
            else
                target_value = 177
            end
        else
            target_value = 177
        end
    
        if not motion.is_close(current_value, target_value, epsilon) then
            local new_value = motion.lerp(current_value, target_value, globals.frametime() * 8)
            
            if not motion.is_close(new_value, current_value, epsilon) then
                context.aspectratio = new_value
                cvar.r_aspectratio:set_raw_float(new_value / 100)
            end
        end
    end
    
    callbacks:set('paint', aspectratio)
    callbacks:set('shutdown', function() cvar.r_aspectratio:set_raw_float(0) end)
end

-- @ panorama
do
    local _panorama = { }
    _panorama.current_state = {
        cslogo = false,
        news = false,
        background = false,
        stats = false,
        watch = false,
        sidebar = false,
        model = false
    }

    local cs_logo = panorama.loadstring([[
        var panel = null;
        var cs_logo = null;
        var original_transform = null;
        var original_visibility = null;

        var _Create = function() {
            cs_logo = $.GetContextPanel().FindChildTraverse("MainMenuNavBarHome");
            if (!cs_logo) {
                return;
            }

            original_transform = cs_logo.style.transform || 'none';
            original_visibility = cs_logo.style.visibility || 'visible';

            cs_logo.style.transform = 'translate3d(-9999px, -9999px, 0)';
            cs_logo.style.visibility = 'collapse';

            var parent = cs_logo.GetParent();
            if (!parent) {
                return;
            }

            panel = $.CreatePanel("Panel", parent, "CustomPanel");
            if (!panel) {
                return;
            }

            if (!panel.BLoadLayoutFromString(
            `<root>
                <Panel class="mainmenu-navbar__btn-small mainmenu-navbar__btn-home MainMenuModeOnly">
                    <RadioButton id="main_menu"
                        onactivate="MainMenu.OnHomeButtonPressed(); $.DispatchEvent( 'PlaySoundEffect', 'UIPanorama.mainmenu_press_home', 'MOUSE' ); $.DispatchEvent('PlayMainMenuMusic', true, true); GameInterfaceAPI.SetSettingString('panorama_play_movie_ambient_sound', '1');"
                        oncancel="MainMenu.OnEscapeKeyPressed();"
                        onmouseover="UiToolkitAPI.ShowTextTooltip('main_menu', 't.me/debugoverlay');"
						onmouseout="UiToolkitAPI.HideTextTooltip();">
                        <Image textureheight="128" texturewidth="-1" src="https://raw.githubusercontent.com/uwukson4800/paranoia-gs/e9d3def09892ecebff61dc5fbe21837559b88392/logo.svg" />
                    </RadioButton>
                </Panel>
            </root>`, 
        false, false)) {
            panel.DeleteAsync(0);
            panel = null;
            return;
            }

            parent.MoveChildBefore(panel, parent.GetChild(0));
        };

        var _Destroy = function() {
            if (cs_logo) {
            if (panel) {
                panel.DeleteAsync(0.0);
                panel = null;
            }

            cs_logo.style.transform = original_transform;
            cs_logo.style.visibility = original_visibility;
            }
        };

        return {
            create: _Create,
            destroy: _Destroy,
        };
    ]], "CSGOMainMenu")()
    local news_container = panorama.loadstring([[
        var panel = null;
        var js_news = null;
        var original_transform = null;
        var original_visibility = null;

        var _Create = function() {
            js_news = $.GetContextPanel().FindChildTraverse("JsNewsContainer");
            if (!js_news) {
                return;
            }

            original_transform = js_news.style.transform || 'none';
            original_visibility = js_news.style.visibility || 'visible';

            js_news.style.transform = 'translate3d(-9999px, -9999px, 0)';
            js_news.style.visibility = 'collapse';

            var parent = js_news.GetParent();
            if (!parent) {
                return;
            }
        
            panel = $.CreatePanel("Panel", parent, "news_panel");
            if(!panel) {
                return;
            }

            parent.MoveChildBefore(panel, js_news);
        };

        var _Destroy = function() {
            if (js_news) {
                if (panel) {
                    panel.DeleteAsync(0.0);
                    panel = null;
                }

                js_news.style.transform = original_transform;
                js_news.style.visibility = original_visibility;
            }
        };

        return {
            create: _Create,
            destroy: _Destroy,
        };

    ]], "CSGOMainMenu")()
    local background = panorama.loadstring([[
        var _ChangeBackground = function(imageUrl) {
            var movieElements = [
                "MainMenuMovie",
                "MainMenuMovieParent",
                "MoviePlayer"
            ];
            
            movieElements.forEach(function(id) {
                var element = $.GetContextPanel().FindChildTraverse(id);
                if (element) {
                    element.style.opacity = "0";
                    element.style.visibility = "collapse";
                }
            });
            
            var bgElements = [
                "MainMenuBackground",
                "MainMenu",
                "MainMenuContainerPanel"
            ];
            
            bgElements.forEach(function(id) {
                var panel = $.GetContextPanel().FindChildTraverse(id);
                if (panel) {
                    panel.style.backgroundImage = 'url("' + imageUrl + '")';
                    panel.style.backgroundPosition = 'center';
                    panel.style.backgroundSize = 'cover';
                    panel.style.backgroundRepeat = 'no-repeat';
                    panel.style.opacity = "1";
                }
            });
        };

        var _RestoreDefault = function() {
            var movieElements = [
                "MainMenuMovie",
                "MainMenuMovieParent",
                "MoviePlayer"
            ];
            
            movieElements.forEach(function(id) {
                var element = $.GetContextPanel().FindChildTraverse(id);
                if (element) {
                    element.style.opacity = "1";
                    element.style.visibility = "visible";
                }
            });
            
            var bgElements = [
                "MainMenuBackground",
                "MainMenu",
                "MainMenuContainerPanel"
            ];
            
            bgElements.forEach(function(id) {
                var panel = $.GetContextPanel().FindChildTraverse(id);
                if (panel) {
                    panel.style.backgroundImage = 'none';
                }
            });
        };

        return {
            change: _ChangeBackground,
            restore: _RestoreDefault
        };
    ]], "CSGOMainMenu")()
    local stats_button = panorama.loadstring([[
        var panel = null;
        var watch_btn = null;
        var original_transform = null;
        var original_visibility = null;

        var _Create = function() {
            watch_btn = $.GetContextPanel().FindChildTraverse("MainMenuNavBarStats");
            
            if (!watch_btn) {
                return;
            }

            original_transform = watch_btn.style.transform || 'none';
            original_visibility = watch_btn.style.visibility || 'visible';
            
            watch_btn.style.transform = 'translate3d(-9999px, -9999px, 0)';
            watch_btn.style.visibility = 'collapse';

            var parent = watch_btn.GetParent();
            if (!parent) {
                return;
            }

            panel = $.CreatePanel("RadioButton", parent, "custom_stats_button");
            if (!panel) {
                return;
            }

            parent.MoveChildBefore(panel, watch_btn);
        };

        var _Destroy = function() {
            if (watch_btn) {
                if (panel) {
                    panel.DeleteAsync(0.0);
                    panel = null;
                }
                watch_btn.style.transform = original_transform;
                watch_btn.style.visibility = original_visibility;
            }
        };

        return {
            hide: _Create,
            show: _Destroy
        };
    ]], "CSGOMainMenu")()
    local watch_button = panorama.loadstring([[
        var panel = null;
        var watch_btn = null;
        var original_transform = null;
        var original_visibility = null;

        var _Create = function() {
            watch_btn = $.GetContextPanel().FindChildTraverse("MainMenuNavBarWatch"); // MainMenuNavBarStats
            
            if (!watch_btn) {
                return;
            }

            original_transform = watch_btn.style.transform || 'none';
            original_visibility = watch_btn.style.visibility || 'visible';
            
            watch_btn.style.transform = 'translate3d(-9999px, -9999px, 0)';
            watch_btn.style.visibility = 'collapse';

            var parent = watch_btn.GetParent();
            if (!parent) {
                return;
            }

            panel = $.CreatePanel("RadioButton", parent, "custom_watch_button");
            if (!panel) {
                return;
            }

            parent.MoveChildBefore(panel, watch_btn);
        };

        var _Destroy = function() {
            if (watch_btn) {
                if (panel) {
                    panel.DeleteAsync(0.0);
                    panel = null;
                }
                watch_btn.style.transform = original_transform;
                watch_btn.style.visibility = original_visibility;
            }
        };

        return {
            hide: _Create,
            show: _Destroy
        };
    ]], "CSGOMainMenu")()
    local remove_sidebar = panorama.loadstring([[
        var panel = null;
        var original_panel = null;

        var _Create = function() {
            original_panel = $.GetContextPanel().FindChildTraverse("JsMainMenuSidebar");
            
            if (!original_panel) return;

            original_panel.style.visibility = "collapse";
            var parent = original_panel.GetParent();
            if (!parent) return;

            panel = $.CreatePanel("Panel", parent, "custom_sidebar_panel");
            if (!panel) return;
        };

        var _Destroy = function() {
            if (panel) {
                panel.DeleteAsync(0.0);
                panel = null;
            }
            if (original_panel) {
                original_panel.style.visibility = "visible";
            }
        };

        return {
            hide: _Create,
            show: _Destroy
        };
    ]], "CSGOMainMenu")()
    local remove_model = panorama.loadstring([[
        var panel = null;
        var original_panel = null;

        var _Create = function() {
            original_panel = $.GetContextPanel().FindChildTraverse("MainMenuVanityParent");
            
            if (!original_panel) return;

            original_panel.style.visibility = "collapse";
            var parent = original_panel.GetParent();
            if (!parent) return;

            panel = $.CreatePanel("Panel", parent, "custom_model_panel");
            if (!panel) return;
        };

        var _Destroy = function() {
            if (panel) {
                panel.DeleteAsync(0.0);
                panel = null;
            }
            if (original_panel) {
                original_panel.style.visibility = "visible";
            }
        };

        return {
            hide: _Create,
            show: _Destroy
        };
    ]], "CSGOMainMenu")()

    function _panorama:get( ecx, edx )
        return array_contains(ecx, edx)
    end

    function _panorama:create()
        local settings = {
            cslogo = self:get(menu.general.misc.panorama:get(), translate('CS:GO Logo', 'Логотип CS:GO')),
            news = self:get(menu.general.misc.panorama:get(), translate('Remove News and Shop', 'Убрать новости и магазин')),
            background = self:get(menu.general.misc.panorama:get(), translate('Change background', 'Изменить фон')),
            stats = self:get(menu.general.misc.panorama:get(), translate('Remove stats button', 'Убрать кнопку статистики')),
            watch = self:get(menu.general.misc.panorama:get(), translate('Remove watch button', 'Убрать кнопку просмотра')),
            sidebar = self:get(menu.general.misc.panorama:get(), translate('Remove sidebar', 'Убрать боковую панель')),
            model = self:get(menu.general.misc.panorama:get(), translate('Remove model in mainmenu', 'Убрать модель в главном меню'))
        }
    
        if settings.cslogo ~= _panorama.current_state.cslogo then
            if settings.cslogo then
                cs_logo.create()
            else
                cs_logo.destroy()
            end
            _panorama.current_state.cslogo = settings.cslogo
        end
    
        if settings.news ~= _panorama.current_state.news then
            if settings.news then
                news_container.create()
            else
                news_container.destroy()
            end
            _panorama.current_state.news = settings.news
        end
    
        if settings.background ~= _panorama.current_state.background then
            if settings.background then
                background.change("https://raw.githubusercontent.com/uwukson4800/paranoia-gs/refs/heads/main/background.png")
            else
                background.restore()
            end
            _panorama.current_state.background = settings.background
        end

        if settings.stats ~= _panorama.current_state.stats then
            if settings.stats then
                stats_button.hide()
            else
                stats_button.show()
            end
            _panorama.current_state.stats = settings.stats
        end

        if settings.watch ~= _panorama.current_state.watch then
            if settings.watch then
                watch_button.hide()
            else
                watch_button.show()
            end
            _panorama.current_state.watch = settings.watch
        end

        if settings.sidebar ~= _panorama.current_state.sidebar then
            if settings.sidebar then
                remove_sidebar.hide()
            else
                remove_sidebar.show()
            end
            _panorama.current_state.sidebar = settings.sidebar
        end

        if settings.model ~= _panorama.current_state.model then
            if settings.model then
                remove_model.hide()
            else
                remove_model.show()
            end
            _panorama.current_state.model = settings.model
        end
    end
    
    function _panorama:shutdown()
        cs_logo.destroy()
        news_container.destroy()
        background.restore()
        stats_button.show()
        watch_button.show()
        remove_sidebar.show()
        remove_model.show()
    end
    
    callbacks:set('paint_ui', function()
        _panorama:create()
    end)
    callbacks:set('shutdown', function()
        _panorama:shutdown()
    end)
end

-- @ send net message
do
    -- 0x31D8 -> release / 0xB8C4 -> debug
    callbacks:set('net_update_end', function()
        INetChannel:SendNetMsg(_DEBUG and 0xB8C4 or 0x31D8 , 0) -- xuid_low / xuid_high
    end)
end

-- @ revealer
do  
    local voice_data_t = ffi.typeof([[
        struct {
            char		 pad_0000[8];
            int32_t	client;
            int32_t	audible_mask;
            uint32_t xuid_low;
            uint32_t xuid_high;
            void*		voice_data;
            bool		 proximity;
            bool		 caster;
            char		 pad_001E[2];
            int32_t	format;
            int32_t	sequence_bytes;
            uint32_t section_number;
            uint32_t uncompressed_sample_offset;
            char		 pad_0030[4];
            uint32_t has_bits;
        } *
    ]])
    
    local js = panorama.loadstring([[
        let entity_panels = {}
        let entity_data = {}
        let event_callbacks = {}
            let SLOT_LAYOUT = `
                <root>
                    <Panel style="flow-children: left; margin-right: 0px;">
                        <Image id="image" textureheight="41" style="opacity: 0.01; transition: opacity 0.1s ease-in-out 0.0s, img-shadow 0.12s ease-in-out 0.0s; padding: 3px 5px; margin: -3px -5px; margin-top: -5px;" />
                    </Panel>
                </root>
            `
            let _DestroyEntityPanel = function (key) {
                let panel = entity_panels[key]
                if(panel != null && panel.IsValid()) {
                    var parent = panel.GetParent()
                    let musor = parent.GetChild(0)
                    musor.visible = true
                    if(parent.FindChildTraverse("id-sb-skillgroup-image") != null) {
                        parent.FindChildTraverse("id-sb-skillgroup-image").style.margin = "0px 0px 0px 0px"
                    }
                    panel.DeleteAsync(0.0)
                }
                delete entity_panels[key]
            }
            let _DestroyEntityPanels = function() {
                for(key in entity_panels){
                    _DestroyEntityPanel(key)
                }
            }
            let _GetOrCreateCustomPanel = function(xuid) {
                if(entity_panels[xuid] == null || !entity_panels[xuid].IsValid()){
                    entity_panels[xuid] = null
                    let scoreboard_context_panel = $.GetContextPanel().FindChildTraverse("ScoreboardContainer").FindChildTraverse("Scoreboard") || $.GetContextPanel().FindChildTraverse("id-eom-scoreboard-container").FindChildTraverse("Scoreboard")
                    if(scoreboard_context_panel == null){
                        _Clear()
                        _DestroyEntityPanels()
                        return
                    }
                    scoreboard_context_panel.FindChildrenWithClassTraverse("sb-row").forEach(function(el){
                        let scoreboard_el
                        if(el.m_xuid == xuid) {
                            el.Children().forEach(function(child_frame){
                                let stat = child_frame.GetAttributeString("data-stat", "")
                                if(stat == "rank")
                                    scoreboard_el = child_frame.GetChild(0)
                            })
                            if(scoreboard_el) {
                                let scoreboard_el_parent = scoreboard_el.GetParent()
                                let custom_icons = $.CreatePanel("Panel", scoreboard_el_parent, "revealer-icon", {
                                })
                                if(scoreboard_el_parent.FindChildTraverse("id-sb-skillgroup-image") != null) {
                                    scoreboard_el_parent.FindChildTraverse("id-sb-skillgroup-image").style.margin = "0px 0px 0px 0px"
                                }
                                scoreboard_el_parent.MoveChildAfter(custom_icons, scoreboard_el_parent.GetChild(1))
                                let prev_panel = scoreboard_el_parent.GetChild(0)
                                prev_panel.visible = false
                                let panel_slot_parent = $.CreatePanel("Panel", custom_icons, `icon`)
                                panel_slot_parent.visible = false
                                panel_slot_parent.BLoadLayoutFromString(SLOT_LAYOUT, false, false)
                                entity_panels[xuid] = custom_icons
                                return custom_icons
                            }
                        }
                    })
                }
                return entity_panels[xuid]
            }
            let _UpdatePlayer = function(entindex, path_to_image) {
                if(entindex == null || entindex == 0)
                    return
                entity_data[entindex] = {
                    applied: false,
                    image_path: path_to_image
                }
            }
            let _ApplyPlayer = function(entindex) {
                let xuid = GameStateAPI.GetPlayerXuidStringFromEntIndex(entindex)
                let panel = _GetOrCreateCustomPanel(xuid)
                if(panel == null)
                    return
                let panel_slot_parent = panel.FindChild(`icon`)
                panel_slot_parent.visible = true
                let panel_slot = panel_slot_parent.FindChild("image")
                panel_slot.visible = true
                panel_slot.style.opacity = "1"
                panel_slot.SetImage(entity_data[entindex].image_path)
                return true
            }
            let _ApplyData = function() {
                for(entindex in entity_data) {
                    entindex = parseInt(entindex)
                    let xuid = GameStateAPI.GetPlayerXuidStringFromEntIndex(entindex)
                    if(!entity_data[entindex].applied || entity_panels[xuid] == null || !entity_panels[xuid].IsValid()) {
                        if(_ApplyPlayer(entindex)) {
                            entity_data[entindex].applied = true
                        }
                    }
                }
            }
            let _Create = function() {
                event_callbacks["OnOpenScoreboard"] = $.RegisterForUnhandledEvent("OnOpenScoreboard", _ApplyData)
                event_callbacks["Scoreboard_UpdateEverything"] = $.RegisterForUnhandledEvent("Scoreboard_UpdateEverything", function(){
                    _ApplyData()
                })
                event_callbacks["Scoreboard_UpdateJob"] = $.RegisterForUnhandledEvent("Scoreboard_UpdateJob", _ApplyData)
            }
            let _Clear = function() { entity_data = {} }
            let _Destroy = function() {
                _Clear()
                _DestroyEntityPanels()
                for(event in event_callbacks){
                    $.UnregisterForUnhandledEvent(event, event_callbacks[event])
                    delete event_callbacks[event]
                }
            }
            return {
                create: _Create,
                destroy: _Destroy,
                clear: _Clear,
                update: _UpdatePlayer,
                destroy_panel: _DestroyEntityPanels
            }
    ]], "CSGOHud")()
    
    js.create()
    
    local main_data_table
    
    local function get_players()
        local players = { }
        local player_resource = entity.get_player_resource()
    
        for i = 1, globals.maxplayers() do
            repeat
                if entity.get_prop(player_resource, 'm_bConnected', i) == 0 then
                    if main_data_table.users[i] then
                        main_data_table.users[i] = nil
                    end
    
                    break
                else
                    local flags = entity.get_prop(i, 'm_fFlags')
                    if not flags then
                        break
                    end
    
                    if bit.band(flags, 512) == 512 then
                        break
                    end
                end
    
                players[#players + 1] = i
            until true
        end
    
        return players
    end
    
    main_data_table = {
        users = { }
    }
    
    local scoreboard_icon_enabled = false

    js.create()
    
    local last_scoreboard_icon_enabled = false 
    local icon_changed = false
    
    local CHEAT = {
        RELEASE = 'release',
        DEBUG = 'debug'
    }
    
    local ICONS = {
        [CHEAT.RELEASE] = 'https://raw.githubusercontent.com/uwukson4800/paranoia-gs/refs/heads/main/release.png',
        [CHEAT.DEBUG] = 'https://raw.githubusercontent.com/uwukson4800/paranoia-gs/refs/heads/main/beta.png'
    }
    
    local detector_table = {
        release = function(packet, target)
            local sig = ('%.02X'):format(ffi.cast('uint16_t*', ffi.cast('uintptr_t', packet) + 16)[0])

            return packet.xuid_high == 0 and sig == '31D8'
        end,

        debug = function(packet, target)
            local sig = ('%.02X'):format(ffi.cast('uint16_t*', ffi.cast('uintptr_t', packet) + 16)[0])

            return packet.xuid_high == 0 and sig == 'B8C4'
        end
    }
    
    local function info_update_callback()
        scoreboard_icon_enabled = true
    
        if icon_changed then
            icon_changed = false
            for _, user in pairs(main_data_table.users) do
                user.icon_set = false
            end
        end
    
        if scoreboard_icon_enabled and not last_scoreboard_icon_enabled then
            last_scoreboard_icon_enabled = true
    
            js.create()
        elseif not scoreboard_icon_enabled and last_scoreboard_icon_enabled then
            last_scoreboard_icon_enabled = false
    
            for _, user in pairs(main_data_table.users) do
                user.icon_set = false
            end
    
            js.destroy()
        end
    end
    
    callbacks:set('paint', function()
        if not scoreboard_icon_enabled then
            return
        end
    
        for _, target in pairs(get_players()) do
            local user = main_data_table.users[target]
            if user then
                if not user.icon_set then
                    local icon_url = ICONS[user.cheat] or target == entity.get_local_player() and (_DEBUG and ICONS[CHEAT.DEBUG] or ICONS[CHEAT.RELEASE]) or nil
                    js.update(target, icon_url)
                    
                    user.icon_set = true
                end
            else
                main_data_table.users[target] = { }
            end
        end
    end)
    
    callbacks:set('voice', function(msg)
        local packet = ffi.cast(voice_data_t, msg.data)
        local target = (ffi.cast('char*', packet) + 8)[0] + 1
    
        main_data_table.users[target] = main_data_table.users[target] or { }
        local user = main_data_table.users[target]
    
        for cheat_identifier, detection_function in pairs(detector_table) do
            if detection_function(packet, target) then
                safe:print(string.format('[REVEALER] entity: [%s] | pct: [0x%X]', entity.get_player_name(target), packet.xuid_low))

                local previous_cheat = user.cheat
                user.cheat = cheat_identifier
                user.icon_set = false

                if not previous_cheat or previous_cheat ~= cheat_identifier then
                    client.fire_event('cheat_detected', {
                        player = target,
                        cheat_id = cheat_identifier,
                    })
                end
            end
        end
    end)
    
    callbacks:set('player_connect_full', function(event)
        local target = client.userid_to_entindex(event.userid)
        if target == entity.get_local_player() then
            main_data_table.users = { }
            js.clear()
            js.destroy()
            client.delay_call(0.5, function()
                js.create()
            end)
        else
            for _, user in pairs(main_data_table.users) do
                user[target] = { }
            end
        end
    end)
    
    callbacks:set('game_start', function()
        for _, user in pairs(main_data_table.users) do
            user.icon_set = false
        end
    end)
    
    callbacks:set('paint', function()
        info_update_callback()
    end)
    
    client.set_event_callback('shutdown', function()
        js.clear()
        js.destroy()
    end)
end

-- @ remove useless animations
do
    cvar.r_eyemove:set_int(0)
    cvar.r_eyegloss:set_int(0)
    cvar.r_eyesize:set_int(0)
end

-- @ remove foot shadows
do
    cvar.cl_foot_contact_shadows:set_int(0)
end

-- @ remove shadows
do
    cvar.cl_csm_entity_shadows:set_int(0)
    cvar.cl_csm_shadows:set_int(0)
end

-- @ remove alert
do
    -- https://github.com/sapphyrus/panorama/blob/f8530fa796bf58699388f5fe7a69cd4ffc594258/scripts/mainmenu.js#L1161
    panorama.loadstring([[
        NewsAPI.IsNewClientAvailable = () => false;
    ]])()

    callbacks:set('shutdown', function()
        panorama.loadstring([[
            NewsAPI.IsNewClientAvailable = () => true;
        ]])()
    end)
end

-- @ unlock hidden convars
do
    ffi.cdef[[
        typedef struct {
            void* vtable;
            void* next;
            bool registered;
            const char* name;
            const char* help_string;
            int flags;
            void* s_cmd_base;
            void* accessor;
        } c_con_command_base;
    ]]

    local v_engine_cvar = client.create_interface('vstdlib.dll', 'VEngineCvar007')
    local hidden_cvars = { }

    local con_command_base = ffi.cast('c_con_command_base ***', ffi.cast('uint32_t', v_engine_cvar) + 0x34)[0][0]
    local cmd = ffi.cast('c_con_command_base *', con_command_base.next)

    while ffi.cast('uint32_t', cmd) ~= 0 do
        if bit.band(cmd.flags, 18) then
            table.insert(hidden_cvars, cmd)
        end
        cmd = ffi.cast('c_con_command_base *', cmd.next)
    end

    for i = 1, #hidden_cvars do
        hidden_cvars[i].flags = bit.band(hidden_cvars[i].flags, -19)
    end
end

-- @ cleaning
do
    local clean = false
    callbacks:set('paint_ui', function()
        if not ui.is_menu_open() then
			if clean then
                collectgarbage()

				clean = false
			end

			return
		end

        clean = true
    end)

    local cleaning = { }
    function cleaning:run()
        context.local_player = nil
        context.weapon = nil
        
        collectgarbage('collect')
    end

    callbacks:set('cs_game_disconnected', function()
        cleaning:run()
    end)

    callbacks:set('client_disconnect', function()
        cleaning:run()
    end)

    client.set_event_callback('shutdown', function()
        if cleaning then
            cleaning = nil
        end
    end)
end

-- @ logs
do
    local event_logs = { }
    event_logs.hitgroups = {
        [0] = 'generic', [1] = 'head', [2] = 'chest', [3] = 'stomach',
        [4] = 'left arm', [5] = 'right arm', [6] = 'left leg', [7] = 'right leg',
        [8] = 'neck', [9] = 'gear'
    }

    local last_shot = {
        backtrack = nil,
        wanted_hitgroup = nil,
        wanted_damage = nil,
        teleported = nil,
        high_priority = nil
    }

    function event_logs:print(text)
        local r, g, b = menu.general.visuals.accent_color:get()
        client.color_log(r, g, b, string.format('%s | \0', context.information.script))
        client.color_log(200, 200, 200, string.format('%s\n\0', text))
    end

    callbacks:set('aim_fire', function(e)
        if not menu.general.visuals.widgets.eventlogs:get() then
            return
        end

        last_shot.backtrack = globals.tickcount() - e.tick

        last_shot.wanted_hitgroup = e.hitgroup
        last_shot.wanted_damage = e.damage

        last_shot.teleported = e.teleported
        last_shot.high_priority = e.high_priority
    end)

    callbacks:set('aim_hit', function(e)
        if not menu.general.visuals.widgets.eventlogs:get() then
            return
        end

        local text = ''
        local _info = ''

        local actual_damage = e.damage or 0
        local wanted_damage = last_shot.wanted_damage or actual_damage

        local actual_hitgroup = e.hitgroup
        local wanted_hitgroup = last_shot.wanted_hitgroup or actual_hitgroup

        local hitgroup_str = event_logs.hitgroups[actual_hitgroup] or 'generic'
        if actual_hitgroup ~= wanted_hitgroup then
            hitgroup_str = string.format('%s(%s)', hitgroup_str, event_logs.hitgroups[wanted_hitgroup] or tostring(wanted_hitgroup))
        end

        local damage_str = tostring(actual_damage)
        if actual_damage ~= wanted_damage then
            damage_str = string.format('%d(%d)', actual_damage, wanted_damage)
        end

        if last_shot.teleported then
            _info = _info .. '| teleported '
        end
        if last_shot.high_priority then
            _info = _info .. '| high priority '
        end
    
        text = string.format(
            "hit %s in the %s for %s [ hc: %d | bt: %dt %s]",
            entity.get_player_name(e.target),
            hitgroup_str,
            damage_str,
            math.floor(e.hit_chance + 0.5) or 0,
            last_shot.backtrack or 0,
            _info
        )

        event_logs:print(text)
    end)

    callbacks:set('aim_miss', function(e)
        if not menu.general.visuals.widgets.eventlogs:get() then
            return
        end

        local text = ''
        local _info = ''

        local actual_hitgroup = e.hitgroup
        local wanted_hitgroup = last_shot.wanted_hitgroup or actual_hitgroup

        local hitgroup_str = event_logs.hitgroups[actual_hitgroup] or 'generic'
        if actual_hitgroup ~= wanted_hitgroup then
            hitgroup_str = string.format('%s(%s)', hitgroup_str, event_logs.hitgroups[wanted_hitgroup] or tostring(wanted_hitgroup))
        end

        if last_shot.teleported then
            _info = _info .. '| teleported '
        end
        if last_shot.high_priority then
            _info = _info .. '| high priority '
        end

        text = string.format(
            "missed %s's %s due to %s [ hc: %d | bt: %dt %s]",
            entity.get_player_name(e.target),
            hitgroup_str,
            e.reason or 'unk',
            math.floor(e.hit_chance + 0.5) or 0,
            last_shot.backtrack or 0,
            _info
        )

        event_logs:print(text)
    end)

    client.set_event_callback('shutdown', function()
        if event_logs then
            event_logs = nil
        end

        if last_shot then
            last_shot = nil
        end

        collectgarbage()
    end)
end

-- @ watermark
do
    local watermark = { }
    watermark.data = {
        alpha = 0,
        x_offset = 0
    }

    local rgba_to_hex = function(b, c, d, e)
        return string.format('%02x%02x%02x%02x', b, c, d, e)
    end

    function watermark:render()
        watermark.data.alpha = motion.lerp(watermark.data.alpha, menu.general.visuals.widgets.watermark:get() and 1 or 0, globals.frametime() * 8)
        watermark.data.x_offset = motion.lerp(watermark.data.x_offset, menu.general.visuals.widgets.watermark:get() and 0 or 350, globals.frametime() * 8)
    
        if watermark.data.alpha < 0.01 then
            return
        end
    
        local better_render = render.new()
        local screen = vector(context.screen_size.x(), context.screen_size.y())
    
        local r, g, b, a = menu.general.visuals.accent_color:get()
        local text_color = render.color(255, 255, 255, math.floor(255 * watermark.data.alpha))
        local accent_color = render.color(r, g, b, math.floor(a * watermark.data.alpha))
    
        local y_pos = 10
        local spacing = 5
    
        local script_text = context.information.script
        local script_width = renderer.measure_text('', script_text) + 20

        better_render:rectangle_round('script', 
            vector(screen.x - script_width - 10 + watermark.data.x_offset, y_pos), 
            vector(script_width, 22), 
            render.color(25, 25, 30, math.floor(255 * watermark.data.alpha)), 
            4
        )

        better_render:rectangle_outline_round('script', 
            vector(screen.x - script_width - 10 + watermark.data.x_offset, y_pos), 
            vector(script_width, 22), 
            render.color(65, 65, 70, math.floor(255 * watermark.data.alpha)), 
            4, 1
        )
        
        better_render:text('script_text', 
            vector(screen.x - script_width/2 - 10 + watermark.data.x_offset, y_pos + 10), 
            text_color, 
            'c', 
            0, 
            script_text
        )
    
        local info_text = string.format('%s ~ \ac8c8c8fe%s', context.information.username, _DEBUG and 'debug' or 'release')
        local info_width = renderer.measure_text('', info_text) + 20
        
        better_render:rectangle_round('info', 
            vector(screen.x - script_width - info_width - spacing - 10 + watermark.data.x_offset - 5, y_pos), 
            vector(info_width, 22), 
            render.color(r, g, b, math.floor(255 * watermark.data.alpha)), 
            4
        )

        better_render:rectangle_round('info', 
            vector(screen.x - script_width - info_width - spacing - 10 + watermark.data.x_offset, y_pos), 
            vector(info_width, 22), 
            render.color(25, 25, 30, math.floor(255 * watermark.data.alpha)), 
            4
        )

        better_render:rectangle_outline_round('info', 
            vector(screen.x - script_width - info_width - spacing - 10 + watermark.data.x_offset - 5, y_pos),
            vector(info_width, 22), 
            render.color(65, 65, 70, math.floor(255 * watermark.data.alpha)), 
            4, 1
        )
        
        better_render:text('info_text', 
            vector(screen.x - script_width - info_width/2 - spacing - 10 + watermark.data.x_offset, y_pos + 10), 
            text_color, 
            'c', 
            0, 
            info_text
        )
    end

    callbacks:set('paint_ui', function()
        watermark:render()
    end)
end

-- @ crosshair indicator
do
    local crosshair = { }
    crosshair.data = {
        offset = 0,
        offset_ind = 0,
        alpha = 255,
        indicators = { },
        anim = { },
        recharge_anim = 0,
        recharge_tickness = 2,

        other = { },
        anim_other = { }
    }

    local function get_accent_color(alpha)
        local accent = { menu.general.visuals.accent_color:get() }
        alpha = alpha or accent[4]
        return render.color(accent[1], accent[2], accent[3], alpha)
    end

    local function gradient_text(text, color1, color2, speed, amplitude, frequency)
        local len = #text
        local out = ''
        local time = globals.realtime() * speed
        for i = 1, len do
            local t = ( i-1 ) / ( len-1 )
            local wave = math.sin(time + i * frequency) * amplitude * 0.5 + 0.5
            local r = math.floor(color1[1] + (color2[1] - color1[1]) * wave)
            local g = math.floor(color1[2] + (color2[2] - color1[2]) * wave)
            local b = math.floor(color1[3] + (color2[3] - color1[3]) * wave)
            local a = math.floor(color1[4] + (color2[4] - color1[4]) * wave)
            out = out .. string.format('\a%02X%02X%02X%02X%s', r, g, b, a, text:sub(i,i))
        end
        return out
    end

    function crosshair:add_indicator(id, text, condition_fn)
        table.insert(self.data.indicators, {
            id = id,
            text = text,
            condition = condition_fn
        })

        self.data.anim[id] = 0
    end

    function crosshair:add_other(id, text, condition_fn)
        table.insert(self.data.other, {
            id = id,
            text = text,
            condition = condition_fn
        })
        self.data.anim_other[id] = 0
    end

    crosshair:add_indicator('dt', 'doubletap', 
        function() return exploits:is_doubletap() end
    )

    crosshair:add_indicator('hs', 'on-shot',
        function() return (exploits:is_hideshots() and not exploits:is_doubletap()) end
    )

    local function draw_recharge_circle(better_render, pos, radius, progress, color, thickness)
        local start_angle = -90
        local end_angle = start_angle + 360 * progress
        better_render:circle_outline('_recharge', pos, color, radius, start_angle, progress, thickness)
    end

    function crosshair:render()
        if not menu.general.visuals.widgets.crosshair:get() then
            return
        end

        if context.local_player == nil then
            return
        end

        if context.weapon == nil then
            return
        end

        local weapon_name = entity.get_classname(context.weapon)
        if weapon_name == nil then
            return
        end

        local r, g, b, a = menu.general.visuals.accent_color:get()
        local better_render = render.new()

        local screen = vector(context.screen_size.x() / 2, context.screen_size.y() / 2)

        local is_scoped = entity.get_prop(context.local_player, 'm_bIsScoped') == 1
        local is_grenade = weapon_name:match('Grenade') ~= nil

        local target_offset = is_scoped and 50 or 0
        local target_offset_ind = is_scoped and ((exploits:is_hideshots() and (not exploits:is_doubletap())) and 45 or 40) or 0 -- cringe =(
        local target_alpha = is_grenade and 150 or a

        self.data.offset = motion.lerp(self.data.offset, target_offset, globals.frametime() * 16)
        self.data.offset_ind = motion.lerp(self.data.offset_ind, target_offset_ind, globals.frametime() * 14)
        self.data.alpha = motion.lerp(self.data.alpha, target_alpha, globals.frametime() * 8)

        if self.data.alpha < 1 then
            return
        end

        local script_text = context.information.script
        local script_width = renderer.measure_text('c', script_text)
        better_render:text(
            'script_name',
            vector(screen.x + self.data.offset, screen.y + 10),
            render.color(0, 0, 0, 0),
            'c', 0,
            gradient_text(script_text, {r, g, b, math.floor(self.data.alpha)}, {34, 34, 35, math.floor(self.data.alpha)}, 2, 1, 0.5)
        )

        local main_indicators = { }
        local active_index = nil
        for i, ind in ipairs(self.data.indicators) do
            if ind.condition() and not active_index then
                active_index = i
            end
        end

        for i, ind in ipairs(self.data.indicators) do
            local target = (i == active_index) and 1 or 0
            local _anim = self.data.anim[ind.id] or 0
            _anim = motion.lerp(_anim, target, globals.frametime() * 14)
            self.data.anim[ind.id] = _anim
            if _anim > 0.01 then
                table.insert(main_indicators, {indicator = ind, anim = _anim})
            end
        end

        if #main_indicators > 0 then
            local y_pos = screen.y + 20
            for _, obj in ipairs(main_indicators) do
                local indicator = obj.indicator
                local anim = obj.anim
                local text_width = renderer.measure_text('c', indicator.text)
                local color = render.color(r, g, b, math.floor(self.data.alpha * anim))
                local x_offset = screen.x + self.data.offset - text_width / 2

                better_render:text(indicator.id,
                    vector(x_offset, y_pos),
                    color,
                    'b', 0,
                    indicator.text
                )
        
                if indicator.condition() then
                    local defensive = exploits:in_defensive()
                    local target_thickness = defensive and 3 or 1
                    self.data.recharge_tickness = motion.lerp(self.data.recharge_tickness, target_thickness, 0.2)
                    self.data.recharge_anim = motion.lerp(self.data.recharge_anim, exploits:in_recharge() and 0 or 1, 0.2)
                    local circle_pos = vector(x_offset + text_width + 5, y_pos + 7)
                    draw_recharge_circle(
                        better_render,
                        circle_pos,
                        3,
                        self.data.recharge_anim,
                        get_accent_color(math.floor(self.data.alpha * anim)),
                        self.data.recharge_tickness
                    )
                end
            end
        end

        local other_active = { }
        for _, indicator in ipairs(self.data.other) do
            local is_active = indicator.condition()
            local _anim = self.data.anim_other[indicator.id] or 0
            _anim = motion.lerp(_anim, is_active and 1 or 0, globals.frametime() * 8)
            self.data.anim_other[indicator.id] = _anim
            if _anim > 0.01 then
                table.insert(other_active, {indicator = indicator, anim = _anim})
            end
        end

        if #other_active > 0 then
            local total_width_extra = 0
            for i, obj in ipairs(other_active) do
                total_width_extra = total_width_extra + renderer.measure_text('c', obj.indicator.text)
                if i < #other_active then total_width_extra = total_width_extra + 10 end
            end
            local x_offset_extra = screen.x + self.data.offset - total_width_extra / 2
            local y_pos_extra = y_pos + 22
            for _, obj in ipairs(other_active) do
                local indicator = obj.indicator
                local anim = obj.anim
                local color = render.color(r, g, b, self.data.alpha)
                local text_width = renderer.measure_text('c', indicator.text)
                local text_color = render.color(color.r, color.g, color.b, math.floor(self.data.alpha * anim))
                local y_anim_offset = (1 - anim) * 10
                better_render:text('extra_'..indicator.id,
                    vector(x_offset_extra, y_pos_extra + y_anim_offset),
                    text_color,
                    'c', 0,
                    indicator.text
                )
                x_offset_extra = x_offset_extra + text_width + 10
            end
        end
    end
 
    callbacks:set('paint_ui', function()
        crosshair:render()
    end)
end

-- @ freeze
do
    local freeze = { }
    
    function freeze:render()
        if not menu.general.misc.spawn_effect:get() then
            return
        end

        if context.local_player == nil or context.weapon == nil then
            return
        end

        local game_rules = entity.get_game_rules()
        if game_rules == nil then
            return
        end

        local is_freeze_time = entity.get_prop(game_rules, 'm_bFreezePeriod') == 1
        local _x, _y, _z = entity.get_origin(context.local_player)
        
        if is_freeze_time then
            interfaces.effects:energy_splash(
                { x = _x, y = _y, z = _z },
                { x = 0, y = 0, z = 0 },
                true
            )
        end
    end

    callbacks:set('paint_ui', function()
        freeze:render()
    end)

    client.set_event_callback('shutdown', function()
        if freeze then
            freeze = nil
        end
    end)
end

-- @ console filter
do
    cvar.con_filter_text:set_string('[gamesense]')
    cvar.con_filter_enable:set_raw_int(1)

    client.set_event_callback('shutdown', function()
        cvar.con_filter_enable:set_raw_int(0)
    end)
end

-- @ lol
do
    interfaces.gameui:create_command_msgbox(context.information.script, 't.me/debugoverlay', true)
end-- dumped from hrisito forums by <youtube.com/@subtick> ~ rip hrisito 2025-2026
