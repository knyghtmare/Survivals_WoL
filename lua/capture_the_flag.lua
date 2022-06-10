local _ = wesnoth.textdomain "wesnoth-Survivals_WoL"
local old_unit_status = wesnoth.interface.game_display.unit_status

function wesnoth.interface.game_display.unit_status()
	local u = wesnoth.interface.get_displayed_unit()
	if not u then return {} end
	local s = old_unit_status()

    if u.status.flag_carrier then
		table.insert(s, { "element", { image = "misc/flag-carrier-icon.png",
			tooltip = _ "flag carrier: this unit is carrying the enemy flag. Protect them while they try to score for your team."
		} } )
	end

	return s
end