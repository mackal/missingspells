--- @type Mq
local mq = require("mq")
local state = require("utils.state")
local Icons = require("mq.ICONS")
--- @type ImGui
require("ImGui")
require("utils.spells")
require("utils.merchant")

local MissingUI = { _name = "Missing Spells UI" }

MissingUI.__index = MissingUI

local count_cache = {}

local function get_merchant_count(spell_id)
	if count_cache[spell_id] ~= nil then
		return count_cache[spell_id]
	end

	count_cache[spell_id] = GetMerchantCount(spell_id)
	return count_cache[spell_id]
end

function MissingUI:Render()
	state.show_missing, state.draw_missing = ImGui.Begin("Missing Spells", state.show_missing)
	if state.draw_missing then
		ImGui.PushItemWidth(100)
		state.min_level = ImGui.InputInt("Min Level", state.min_level)
		ImGui.SameLine()
		state.max_level = ImGui.InputInt("Max Level", state.max_level)
		ImGui.PopItemWidth()
		ImGui.SameLine()
		state.hide_no_merchants = ImGui.Checkbox("Hide No Merchants", state.hide_no_merchants)
		ImGui.SameLine(ImGui.GetWindowContentRegionWidth() - 80)
		local refresh = "Refresh"
		if state.refresh then
			refresh = "Refreshing"
		end
		if ImGui.Button(Icons.FA_REFRESH .. refresh) then
			state.refresh = true
		end
		if #state.missing_cache then
			local spell_icon = mq.FindTextureAnimation("A_SpellGems")
			ImGui.BeginTable("MissingSpells", 5, bit32.bor(ImGuiTableFlags.Resizable, ImGuiTableFlags.Borders))
			ImGui.TableSetupColumn("Icon", ImGuiTableColumnFlags.WidthFixed, 25.0)
			ImGui.TableSetupColumn("Name")
			ImGui.TableSetupColumn("Level")
			ImGui.TableSetupColumn("Merchants")
			ImGui.TableSetupColumn("Scribe")
			ImGui.TableHeadersRow()

			for _, v in pairs(state.missing_cache) do
				local count = get_merchant_count(v.ID())
				if
					state.min_level <= v.Level()
					and state.max_level >= v.Level()
					and (not state.hide_no_merchants or count > 0)
				then
					ImGui.TableNextRow()
					ImGui.TableNextColumn()
					spell_icon:SetTextureCell(v.SpellIcon())
					ImGui.DrawTextureAnimation(spell_icon)

					ImGui.TableNextColumn()
					if ImGui.Selectable(v.Name()) then
						v.Inspect()
					end
					ImGui.SetItemTooltip("Spell ID: %d", v.ID())

					ImGui.TableNextColumn()
					ImGui.Text(tostring(v.Level()))

					ImGui.TableNextColumn()
					if count > 0 then
						ImGui.PushStyleColor(ImGuiCol.Text, 0.3, 1.0, 0.3, 1.0)
						ImGui.PushID("##selectablesearch" .. v.ID())
						if ImGui.Selectable(string.format("%s   %d", Icons.FA_SEARCH, count)) then
							state.spell_search_id = v.ID()
							state.show_merchant = true
						end
						ImGui.PopID()
					else
						ImGui.PushStyleColor(ImGuiCol.Text, 1.0, 0.3, 0.3, 1.0)
						ImGui.Text(string.format("%s   %d", Icons.FA_SEARCH, count))
					end
					ImGui.PopStyleColor()

					ImGui.TableNextColumn()
					local name = GetSpellItemName(v.ID())
					if name == "" then
						ImGui.Text("")
					else
						local item = mq.TLO.FindItem(name)
						if item() then
							ImGui.PushID("##scribe" .. name)
							if ImGui.Button("Scribe") then
								mq.cmdf('/itemnotify "%s" rightmouseup', name)
							end
							ImGui.PopID()
						else
							ImGui.PushStyleColor(ImGuiCol.Text, 1.0, 0.3, 0.3, 1.0)
							ImGui.Text("Missing")
							ImGui.PopStyleColor()
						end
					end
				end
			end
			ImGui.EndTable()
		end
	end

	ImGui.End()
end

return MissingUI
