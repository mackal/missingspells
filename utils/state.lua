--- @type Mq
local mq = require("mq")

local state = {
	db_path = string.format("%s/merchant_spells.db", mq.configDir),
	min_level = 1,
	max_level = 125,
	show_missing = false,
	draw_missing = true,
	clear_cache = false,
	show_merchant = false,
	draw_merchant = false,
	refresh = false,
	hide_no_merchants = false,
	spell_search_id = 0,
	have_nav = true,
	nav_zone = 0,
	nav_spawn = "",
	buy_spell = "",
	running = true,
	---@type spell[]
	missing_cache = {},
}

return state
