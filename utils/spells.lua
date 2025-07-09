--- @type Mq
local mq = require("mq")

--- Finds spells and discs you're missing
---@param low? number lowest Level
---@param high? number highest Level
---@return spell[]
function GetMissingSpells(low, high)
	low = low == nil and 1 or low
	high = high == nil and mq.TLO.Me.Level() or high

	local highest_id = mq.TLO.Spell("ESR").ID()

	local missing = {}

	for i = 3, highest_id do
		local spell = mq.TLO.Spell(i)
		if
			spell() ~= nil
			and spell.Level() >= low
			and spell.Level() <= high
			and not mq.TLO.Me.Book(spell.RankName.Name())()
			and not mq.TLO.Me.CombatAbility(spell.RankName.Name())()
			and spell.Rank() < 2
		then
			table.insert(missing, spell)
		end
	end

	return missing
end
