--- @type Mq
local mq = require("mq")
local state = require("utils.state")
local MissingUI = require("ui.spells")
local MerchantUI = require("ui.merchant")
--- @type ImGui
require("ImGui")
require("utils.spells")
require("utils.merchant")

local MAX_LEVEL = 125

local function handle_missing()
	state.show_missing = not state.show_missing
	state.clear_cache = true
end

local function handle_merchant()
	local items = ParseMerchant()
	if not items then
		return
	end

	SaveMerchantItems(items)
end

local function init()
	MerchantInit()

	if not mq.TLO.Plugin("MQ2EasyFind")() then
		state.have_nav = false
	end

	print("Please allow time for the spells to be loaded.")
	state.max_level = mq.TLO.Me.Level()
	state.missing_cache = GetMissingSpells(1, MAX_LEVEL)
end

local function render_ui()
	if state.show_missing then
		MissingUI:Render()
	end

	if state.show_merchant then
		MerchantUI:Render()
	end
end

mq.bind("/parsemerchant", handle_merchant)
mq.bind("/missingspells", handle_missing)

local function handle_learned(_, spell)
	local spell_id = mq.TLO.Spell(spell).ID()
	local to_remove = -1
	for k, v in pairs(state.missing_cache) do
		if v.ID() == spell_id then
			to_remove = k
		end
	end
	if to_remove ~= -1 then
		table.remove(state.missing_cache, to_remove)
	end
end

mq.event("End Scribe", "You have finished scribing #1#.", handle_learned)
mq.event("Learned", "You have learned #1#!", handle_learned)
mq.event("Level", "You have gained a level! Welcome to level #1#!", function(_, lvl)
	-- well, we could handle multiple levels, but then it's hard to tell if they have it set manually, also unlikely so too bad!
	local level = tonumber(lvl)
	if state.max_level == level - 1 then
		state.max_level = level
	end
end)

function Main()
	if mq.TLO.EverQuest.GameState() ~= "INGAME" then
		mq.exit()
	end

	if state.refresh then
		state.missing_cache = GetMissingSpells(1, MAX_LEVEL)
		state.refresh = false
	end

	if state.scribe_spell ~= "" then
		local item = mq.TLO.FindItem(state.scribe_spell)
		if item() then
			if item.ItemSlot2() ~= -1 then
				local pack = "pack" .. tostring(item.ItemSlot() - 22)
				if mq.TLO.InvSlot(pack).Item.Open() == 0 then
					mq.cmd("/itemnotify " .. pack .. " rightmouseup")
					mq.delay(1000, function()
						return mq.TLO.InvSlot(pack).Item.Open() == 1
					end)
				end
			end
			mq.cmdf('/itemnotify "%s" rightmouseup', state.scribe_spell)
		end
		state.scribe_spell = ""
	end

	---@diagnostic disable-next-line: undefined-field
	if not mq.TLO.EasyFind.Active() and not mq.TLO.Navigation.Active() then
		if state.nav_zone > 0 then
			local nav_cmd = mq.TLO.Zone(state.nav_zone).ShortName()
			if state.nav_spawn ~= "" then
				nav_cmd = nav_cmd .. " @ " .. state.nav_spawn
			end
			mq.cmd("/travelto " .. nav_cmd)
			state.nav_zone = 0
			state.nav_spawn = ""
		end
		if state.nav_spawn ~= "" then
			if mq.TLO.Navigation.PathExists("spawn " .. state.nav_spawn) then
				mq.cmd("/nav spawn " .. state.nav_spawn)
			else
				print("Can't nav to spawn!")
			end
			state.nav_spawn = ""
		end
	end
end

init()
mq.imgui.init("missingspells", render_ui)

while state.running do
	Main()
	mq.doevents()
	mq.delay(250, function()
		return not state.running
	end)
end
