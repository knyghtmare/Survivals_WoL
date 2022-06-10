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

-- define 2 customised tags for this scenario
-- to register capture and release

function wml_actions.capture_flag(cfg)
	for index, unit in ipairs(wesnoth.units.find_on_map(cfg)) do
		if unit.valid and not unit.status.flag_carrier then
			unit.status.flag_carrier = true
			if unit.__cfg.gender == "female" then
				wesnoth.interface.float_label(unit.x, unit.y, string.format("<span color='red'>%s</span>", tostring( _"female^captured flag" ) ) )
			else
				wesnoth.interface.float_label(unit.x, unit.y, string.format("<span color='red'>%s</span>", tostring( _"captured flag" ) ) )
			end
		end
	end
end

function wml_actions.release_flag(cfg)
	-- removes flag_carrier from all units matching the filter.
	for index, unit in ipairs(wesnoth.units.find_on_map(cfg)) do
		if unit.valid and unit.status.flag_carrier then
			unit.status.flag_carrier = nil
			if unit.__cfg.gender == "female" then
				wesnoth.interface.float_label(unit.x, unit.y, string.format("<span color='red'>%s</span>", tostring( _"female^released flag" ) ) )
			else
				wesnoth.interface.float_label(unit.x, unit.y, string.format("<span color='red'>%s</span>", tostring( _"released flag" ) ) )
			end
		end
	end
end