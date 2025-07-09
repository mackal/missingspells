--- @type Mq
local mq = require("mq")
local utils = require("mq.Utils")
local PackageMan = require("mq.PackageMan")
local sql = PackageMan.Require("lsqlite3")
local state = require("utils.state")

--- Parses merchant window
---@return table? of the data we want
function ParseMerchant()
	mq.TLO.Window("MerchantWnd").DoClose()
	mq.delay("5s", function()
		return not mq.TLO.Merchant.Open()
	end)

	if not mq.TLO.Target() or mq.TLO.Target.Class() ~= "Merchant" then
		print("Need to target a merchant")
		return
	end

	local items = {}

	mq.TLO.Merchant.OpenWindow()
	mq.delay("5s", function()
		return mq.TLO.Merchant.Open() and mq.TLO.Merchant.ItemsReceived()
	end)

	for i = 1, mq.TLO.Merchant.Items() do
		local item = mq.TLO.Merchant.Item(i)
		-- ignore sold items, Scroll should be set for all spells/discs
		if item.MerchQuantity() < 0 and item.Scroll() then
			table.insert(items, {
				["spell"] = item.Scroll.Spell.Name(),
				["spell_id"] = item.Scroll.Spell.ID(),
				["item"] = item.Name(),
				["item_id"] = item.ID(),
				["item_icon"] = item.Icon(),
				["zone_id"] = mq.TLO.Zone.ID(),
				["merchant"] = mq.TLO.Target.CleanName(),
				["price"] = item.BuyPrice(),
			})
		end
	end

	-- ahh if we go too fast the UI fucks up :)
	mq.delay(250)
	mq.TLO.Window("MerchantWnd").DoClose()
	return items
end

--- Inits Merchant table if necessary
function MerchantInit()
	if not utils.File.Exists(state.db_path) then
		local db = sql.open(state.db_path)

		db:exec([[
      CREATE TABLE IF NOT EXISTS spells (
        "id" INTEGER PRIMARY KEY AUTOINCREMENT,
        "spell" TEXT NOT NULL,
        "spell_id" INTEGER NOT NULL,
        "item" TEXT NOT NULL,
        "item_id" INTEGER NOT NULL,
		    "item_icon" INTEGER NOT NULL,
        "zone_id" INTEGER NOT NULL,
        "merchant" TEXT NOT NULL,
        "price" INTEGER NOT NULL,
        UNIQUE("spell_id", "item_id", "zone_id", "merchant", "price") ON CONFLICT IGNORE
      );
    ]])

		db:close()
	end
end

---Gets the amount of merchants with the spell
---@param spell_id integer Spell ID we're looking for
---@return integer count of merchants with the spell
function GetMerchantCount(spell_id)
	local db = sql.open(state.db_path)

	if not db then
		return 0
	end

	local ret = 0

	for v in db:rows(string.format("SELECT COUNT(spell_id) FROM spells WHERE spell_id = %d", spell_id)) do
		ret = v[1]
	end

	db:close()

	return ret
end

---Saves table of item data to the DB
---@param items table
function SaveMerchantItems(items)
	local db = sql.open(state.db_path)

	if not db then
		return
	end

	local stmt = db:prepare([[
    INSERT INTO spells(spell, spell_id, item, item_id, item_icon, zone_id, merchant, price)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?)
  ]])

	for _, v in pairs(items) do
		stmt:bind_values(
			v["spell"],
			v["spell_id"],
			v["item"],
			v["item_id"],
			v["item_icon"],
			v["zone_id"],
			v["merchant"],
			v["price"]
		)
		stmt:step()
		stmt:reset()
	end
	stmt:finalize()
	db:close()
end

---Loads merchant data into a table
---@param spell_id number
---@return table? entries of all the tome/scrolls
function GetMerchantEntries(spell_id)
	local db = sql.open(state.db_path)

	if not db then
		return
	end

	local entries = {}

	for res in
		db:nrows(
			"SELECT spell, spell_id, item, item_id, item_icon, zone_id, merchant, price FROM spells WHERE spell_id = "
				.. tostring(spell_id)
		)
	do
		table.insert(entries, res)
	end

	db:close()
	return entries
end

---Gets the item from the merchant table, if it exists
---@param spell_id integer
---@return string item_name
function GetSpellItemName(spell_id)
	local db = sql.open(state.db_path)

	if not db then
		return ""
	end

	for name in db:urows("SELECT item FROM spells WHERE spell_id = " .. tostring(spell_id) .. " LIMIT 1") do
		return name
	end

	return ""
end
