--- @type Mq
local mq = require("mq")
local state = require("utils.state")
local Icons = require("mq.ICONS")
--- @type ImGui
require("ImGui")
require("utils.spells")
require("utils.merchant")

local MerchantUI = { _name = "Merchant Spells UI" }

MerchantUI.__index = MerchantUI

function MerchantUI:Render()
	if state.spell_search_id == 0 then
		return
	end

	state.show_merchant, state.draw_merchant = ImGui.Begin("Merchant Spells", state.show_merchant)
	if state.draw_merchant then
		local entries = GetMerchantEntries(state.spell_search_id)

		if entries and #entries then
			local item_icon = mq.FindTextureAnimation("A_DragItem")
			ImGui.BeginTable("MerchantSpells", 5, bit32.bor(ImGuiTableFlags.Resizable, ImGuiTableFlags.Borders))
			-- spell, spell_id, item, item_id, item_icon, zone_id, merchant, price
			ImGui.TableSetupColumn("Icon", ImGuiTableColumnFlags.WidthFixed, 25.0)
			ImGui.TableSetupColumn("Spell")
			ImGui.TableSetupColumn("Item")
			ImGui.TableSetupColumn("Zone")
			ImGui.TableSetupColumn("Merchant")
			ImGui.TableHeadersRow()

			for _, v in pairs(entries) do
				ImGui.TableNextRow()
				ImGui.TableNextColumn()
				item_icon:SetTextureCell(v["item_icon"] - 500)
				ImGui.DrawTextureAnimation(item_icon, 20, 20)

				ImGui.TableNextColumn()
				ImGui.Text(v["spell"])
				ImGui.SetItemTooltip("Spell ID: %d", v["spell_id"])

				ImGui.TableNextColumn()
				ImGui.Text(v["item"])
				ImGui.SetItemTooltip("Item ID: %d", v["item_id"])

				ImGui.TableNextColumn()
				ImGui.Text(mq.TLO.Zone(v["zone_id"]).Name())
				ImGui.SetItemTooltip("Zone ID: %d", v["zone_id"])

				ImGui.TableNextColumn()
				ImGui.Button(
					v["merchant"]
						.. "##"
						.. tostring(v["zone_id"] .. v["merchant"] .. v["spell"] .. tostring(v["item_id"]))
				)
				if state.have_nav and ImGui.BeginPopupContextItem() then
					if mq.TLO.Zone.ID() ~= v["zone_id"] then
						if ImGui.Selectable("Nav to Zone") then
							state.nav_zone = v["zone_id"]
						end
						if ImGui.Selectable("Nav to Zone and Spawn") then
							state.nav_zone = v["zone_id"]
							state.nav_spawn = v["merchant"]
						end
					else
						if ImGui.Selectable("Nav to Spawn") then
							state.nav_spawn = v["merchant"]
						end
					end
					ImGui.EndPopup()
				end
			end
			ImGui.EndTable()
		end
	end

	ImGui.End()
end

return MerchantUI
