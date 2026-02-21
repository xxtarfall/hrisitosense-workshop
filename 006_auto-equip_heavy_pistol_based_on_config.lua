-- Title: Auto-equip Heavy Pistol based on config
-- Script ID: 6
-- Source: page_6.html
----------------------------------------

--
-- dependencies
--

local weapons = require "gamesense/csgo_weapons"

local js = panorama.open()
local LoadoutAPI, InventoryAPI = js.LoadoutAPI, js.InventoryAPI

--
-- constants
--

local EQUIPPED_ITEMS = {
	["Desert Eagle"] = weapons["weapon_deagle"].idx,
	["R8 Revolver"] = weapons["weapon_revolver"].idx
}

local TEAMS = {"ct", "t"}

--
-- utility functions
--

local function get_equipped_idx(idx_slot, team)
	local item = InventoryAPI.GetFauxItemIDFromDefAndPaintIndex(idx_slot)
	local slot = InventoryAPI.GetSlotSubPosition(item)

	local item_equipped = LoadoutAPI.GetItemID(team, slot)

	return InventoryAPI.GetItemDefinitionIndex(item_equipped)
end

local function equip_item(idx, team)
	local item = InventoryAPI.GetFauxItemIDFromDefAndPaintIndex(idx)
	local slot = InventoryAPI.GetSlotSubPosition(item)

	LoadoutAPI.EquipItemInSlot(team, item, slot)
end

--
-- ui reference + callback
--

local reference = ui.new_combobox("MISC", "Miscellaneous", "Auto-equip Heavy Pistol", {"Off", "Desert Eagle", "R8 Revolver"})

ui.set_callback(reference, function()
	local idx = EQUIPPED_ITEMS[ui.get(reference)]

	if idx ~= nil then
		for i, team in ipairs(TEAMS) do
			if get_equipped_idx(idx, team) ~= idx then
				equip_item(idx, team)
			end
		end
	end
end)-- dumped from hrisito forums by <youtube.com/@subtick> ~ rip hrisito 2025-2026
