-- Shared logic for the Afterlife defense, race and 2-4p scenarios.
afterlife = {}
local afterlife = afterlife
local wesnoth = wesnoth
local ipairs = ipairs
local pairs = pairs
local math = math
local string = string
local table = table
local gsub = string.gsub
local wml = wml
local on_event = wesnoth.require("lua/on_event.lua")
local T = wml.tag

---@param key string
function afterlife.get_variable(key)
	return wml.variables[key]
end

---@param key string
function afterlife.set_variable(key, value)
	wml.variables[key] = value
end


wesnoth.wml_conditionals = wesnoth.wml_conditionals or {}
wesnoth.wml_conditionals.has_unit = wesnoth.wml_conditionals.has_unit or function(cfg)
	afterlife.temp = false
	wesnoth.wml_actions["if"] {
		T.have_unit(cfg),
		T["then"] { T.lua { code = "afterlife.temp = true" } }
	}
	return afterlife.temp
end


local function unit_wml_copy(unit_userdata, x, y)
	wesnoth.wml_actions.store_unit {
		T.filter { id = unit_userdata.id },
		variable = "afterlife_unit",
	}
	local unit_var = afterlife.get_variable("afterlife_unit")
	local id = "afterlife_"
		.. mathx.random_choice("0..1000000000")
		.. mathx.random_choice("0..1000000000")
		.. mathx.random_choice("0..1000000000")
	unit_var.id = id
	unit_var.underlying_id = id
	unit_var.canrecruit = false
	unit_var.x = x
	unit_var.y = y
	afterlife.set_variable("afterlife_unit", unit_var)
	wesnoth.wml_actions.unstore_unit {
		variable = "afterlife_unit",
	}
	afterlife.set_variable("afterlife_unit", nil)
	return id
end


local function copy_unit(unit_original, to_pos, to_side, strength_percent)
	if to_pos == nil then return end
	if unit_original.type == "Fog Clearer" then return end
	local from_side = unit_original.side
	local new_id = unit_wml_copy(unit_original, to_pos.x, to_pos.y)
	local unit = wesnoth.units.find_on_map { id = new_id }[1]
	unit.side = to_side
	unit.status.poisoned = false
	unit.status.slowed = false
	unit.variables.afterlife_fresh_copy = true
	unit.moves = unit.max_moves
	wesnoth.units.add_modification(unit, "object", {
		id = "afterlife_grayscale",
		T.effect { apply_to = "image_mod", add = "GS()" },
		T.effect { apply_to = "zoc", value = false },
	})
	unit.status.petrified = false
	unit.status.invulnerable = true

	local increase_percent = strength_percent - 100
	local ability = T.name_only {
		name = "copy" .. strength_percent .. "%",
		description = strength_percent .. "% hitpoints, "
			.. strength_percent .. "% damage, "
			.. "unit copied from side " .. from_side
	}
	wesnoth.units.add_modification(unit, "object", {
		T.effect { apply_to = "attack", increase_damage = increase_percent .. "%" },
		T.effect { apply_to = "hitpoints", increase_total = increase_percent .. "%" },
		T.effect { apply_to = "new_ability", T.abilities { ability } },
	})
	unit.hitpoints = unit.max_hitpoints
	wesnoth.map.set_owner(to_pos.x, to_pos.y, to_side, false)
end


local function unpetrify_units()
	local status_filter = "invulnerable"
	local filtered_units = wesnoth.units.find_on_map { side = wesnoth.current.side, status = status_filter }
	for _, unit in ipairs(filtered_units) do
		if unit.variables.afterlife_fresh_copy then
			unit.status.petrified = false
			unit.status.invulnerable = false
			unit.variables.afterlife_fresh_copy = nil
			wesnoth.wml_actions.remove_object {
				id = unit.id,
				object_id = "afterlife_grayscale",
			}
			local img = gsub(unit.image_mods, "GS%(%)", "NOP()", 1)
			wesnoth.units.add_modification(unit, "object", {
				T.effect { apply_to = "image_mod", replace = img },
			})
			unit.hitpoints = unit.max_hitpoints
		end
	end
end


function afterlife.schedule_attack_abort_triggers()
	local invulnerable
	on_event("attack", function()
		local event = wesnoth.current.event_context
		local event_unit = wesnoth.units.find_on_map { x = event.x2, y = event.y2 }[1]
		if event_unit ~= nil and event_unit.variables.afterlife_fresh_copy == true then
			invulnerable = event_unit
			invulnerable:to_recall()
		end
	end)
	on_event("attack end", function()
		if invulnerable then
			invulnerable:to_map()
			invulnerable = nil
		end
	end)
end


local width = wesnoth.current.map.playable_width
local height = wesnoth.current.map.playable_height
local scrollable_height = math.ceil(height * 0.6) -- lower
local border = wesnoth.current.map.border_size
local half = (width - 1) / 2
local left_edge = border
local left_center = half + border - 1
local right_center = half + border + 1
local right_edge = border + width - 1

local terrain_base_probabilities = {
	["Gs"] = 4, -- grass
	["Gd"] = 4, -- grass
	["Gg"] = 3, -- grass
	["Wwf"] = 28, -- ford
	["Gs^Fms"] = 2, -- forest
	["Gll^Fp"] = 2, -- forest
	["Mm"] = 1, -- mountain
	["Ai"] = 1, -- ice
	["Hh"] = 2, -- hill
	["Hhd"] = 2, -- dry hill
	["Uu^Uf"] = 2, -- mushrooms
	["Dd^Do"] = 1, -- oasis
	["Ss"] = 1, -- swamp
	["Gs^Vh"] = 2, -- village
}
local terrain_variability_multiplier = 1 -- how variable terrain will be
local terrain_iterator = {}
local terrain_total = 0
local function set_probability(terrain_index, value)
	afterlife.set_variable("afterlife_terrain_prob_" .. terrain_index, value)
end
local function get_probability(terrain_index)
	return afterlife.get_variable("afterlife_terrain_prob_" .. terrain_index)
end

for terr, value in pairs(terrain_base_probabilities) do
	-- We will need to sort this later because `pairs` is an unordered (OOS-unsafe) iterator
	terrain_total = terrain_total + value
	terrain_iterator[#terrain_iterator + 1] = terr
end
table.sort(terrain_iterator)
for idx, terr in ipairs(terrain_iterator) do
	if get_probability(idx) == nil then
		local base = terrain_base_probabilities[terr]
		set_probability(idx, base * terrain_variability_multiplier)
	end
end

local function random_terrain()
	local offset = mathx.random_choice("1.." .. terrain_total * terrain_variability_multiplier)
	for idx, terrain in ipairs(terrain_iterator) do
		offset = offset - get_probability(idx)
		if offset <= 0 then
			-- Now that this terrain is chosen, decrease the chosen terr probability by total,
			-- and add a distributed base to all terrains
			set_probability(idx, get_probability(idx) - terrain_total)
			for small_idx, small_terrain in ipairs(terrain_iterator) do
				local base = terrain_base_probabilities[small_terrain]
				set_probability(small_idx, get_probability(small_idx) + base)
			end
			return terrain
		end
	end
	return "Aa^Ecf" -- snow with fire (to see the error)
end


function afterlife.scroll_terrain_down()
	local castle_length = math.ceil(width / 6)
	local scrolls = afterlife.get_variable("afterlife_scrolls") or 2
	afterlife.set_variable("afterlife_scrolls", scrolls + 1)

	for y = height - 1, scrollable_height, -1 do
		for x = left_edge, right_edge do
			local upper_terrain = wesnoth.current.map[{x, y - 1}]
			wesnoth.current.map[{x, y}] = upper_terrain
			wesnoth.map.set_owner(x, y, wesnoth.get_village_owner(x, y - 1), false)
			if wml.variables["bonustile_enabled"]
				and _G.bonustile ~= nil
				and _G.bonustile.exported_change_bonus_position_v1 ~= nil then
				bonustile.exported_change_bonus_position_v1(x, y - 1, x, y)
			end
		end
	end
	local y = scrollable_height + 1
	for x = left_edge, left_center do -- castle placement on the left and right
		local rem = scrolls % (castle_length * 4 - 2)
		local terrain
		if x == left_center and rem >= castle_length * 2 + 1 and rem <= castle_length * 3 then
			terrain = "Kh"
		elseif x == left_edge and rem >= 2 and rem <= castle_length + 1 then
			terrain = "Kh"
		else
			terrain = random_terrain()
		end
		wesnoth.set_terrain(x, y, terrain)
		wesnoth.set_terrain(width - x + 1, y, terrain)
	end
end


function afterlife.find_vacant(unit, y_min, honor_edge, flip)
	y_min = math.max(border, y_min)
	local x_start = unit.x < right_center and right_center or left_center
	local x_end = unit.x < right_center and right_edge or left_edge
	if flip then x_start, x_end = x_end, x_start end
	local x_step = (x_end - x_start) / math.abs(x_end - x_start)
	for y = y_min, height do
		for x = x_start, x_end, x_step do
			local is_edge = honor_edge and y == y_min and x == x_start
			if wesnoth.units.get(x, y) == nil
				and wesnoth.current.map[{x, y}] ~= "Xv"
				and not is_edge then
				return { x = x, y = y }
			end
		end
	end
end


function afterlife.kill_ai_leaders()
	for _, side in ipairs(wesnoth.sides) do
		if side.__cfg.allow_player == false then
			wesnoth.wml_actions.kill {
				canrecruit = true,
				side = side.side,
				fire_event = false,
				animate = false,
			}
		end
	end
end


local function endlevel_team(winner_team)
	local i_am_winner = false
	for _, side in ipairs(wesnoth.sides) do
		if side.team_name ~= winner_team and side.__cfg.allow_player == true then
			wesnoth.wml_actions.kill {
				side = side.side,
			}
		end
		if side.team_name == winner_team and side.__cfg.allow_player == true and side.is_local then
			i_am_winner = true
		end
	end

	wesnoth.wml_actions.endlevel {
		result = i_am_winner and "victory" or "defeat"
	}
end


afterlife.endlevel_team = endlevel_team
afterlife.copy_unit = copy_unit
afterlife.unpetrify_units = unpetrify_units


-- Defense and 2-4p modes. Called from the preload event.
function afterlife.init_defense()
	local is_team = #wesnoth.sides == 6
	local copy_strength_start = is_team and 26 or 32 -- point of no return is about 50%
	local copy_strength_increase = 2
	local teams = {}
	for _, side in ipairs(wesnoth.sides) do
		local team_id = teams[side.team_name] or (#teams + 1)
		teams[side.team_name] = team_id
		local team = teams[team_id] or { enemy = 3 - team_id, humans = {} }
		teams[team_id] = team
		local is_alive = wml.variables["afterlife_alive_" .. side.side] or #wesnoth.units.find_on_map { side = side.side } > 0
		wml.variables["afterlife_alive_" .. side.side] = is_alive
		if side.__cfg.allow_player == false then
			team.ai = side.side
		elseif is_alive then
			team.humans[#team.humans + 1] = side.side
		end
	end

	on_event("start", function()
		afterlife.kill_ai_leaders()
		for _, side in ipairs(wesnoth.sides) do
			side.village_support = side.village_support + 2
		end
	end)

	afterlife.schedule_attack_abort_triggers()

	local ai_starting_location_y = wesnoth.sides[#wesnoth.sides].starting_location[2]
	local function copy_units(from_side, to_side)
		for _, unit_original in ipairs(wesnoth.units.find_on_map { side = from_side }) do
			local percent = copy_strength_start + wesnoth.current.turn * copy_strength_increase
			local to_pos = afterlife.find_vacant(unit_original, ai_starting_location_y, true, is_team)
			if to_pos == nil then
				wesnoth.wml_actions.message {
					speaker = "narrator",
					message = "No free space to place a copy",
				}
				afterlife.endlevel_team(from_side, wesnoth.sides[from_side].team_name)
				break
			else
				afterlife.copy_unit(unit_original, to_pos, to_side, percent)
			end
		end
	end

	on_event("turn refresh", function()
		local wave_length = afterlife.get_variable("afterlife_wave_length") or 2
		if (wesnoth.current.turn - 1) % wave_length == 0 then
			if wesnoth.current.side == 1 then
				copy_units(teams[1].humans[wesnoth.current.turn % #teams[1].humans + 1], teams[1].ai)
				copy_units(teams[2].humans[wesnoth.current.turn % #teams[2].humans + 1], teams[2].ai)
			end
			if wesnoth.sides[wesnoth.current.side].__cfg.allow_player == false then
				afterlife.unpetrify_units()
			end
		end
		if wave_length > 1 then
			local next_wave_turn = wesnoth.current.turn
				- (wesnoth.current.turn - 2) % wave_length
				+ wave_length - 1
			wesnoth.wml_actions.label {
				x = math.ceil(wesnoth.current.map.playable_width / 2),
				y = 2,
				text = string.format("<span color='#FFFFFF'>Next wave:\n    turn %s</span>", next_wave_turn)
			}
		end
	end)

	on_event("side turn end", function()
		for _, unit in ipairs(wesnoth.units.find_on_map { canrecruit = true, side = wesnoth.current.side }) do
			unit.status.uncovered = true
		end
	end)
end


-- Race mode. Called from the preload event.
function afterlife.init_race()
	local human_side1, human_side2 = 1, 3
	local sides = {
		[1] = { enemy_human = 3, enemy_ai = 2, half_owner = 1 },
		[2] = { half_owner = 1 },
		[3] = { enemy_human = 1, enemy_ai = 4, half_owner = 3 },
		[4] = { half_owner = 2 },
	}

	wesnoth.wml_actions.event {
		name = "turn refresh",
		first_time_only = false,
		T.lua { code = "afterlife.turn_refresh_event()" }
	}
	wesnoth.wml_actions.event {
		name = "die",
		first_time_only = false,
		T.lua { code = "afterlife.die_event()" }
	}
	wesnoth.wml_actions.event {
		name = "prestart",
		first_time_only = false,
		T.lua { code = "afterlife.prestart_event()" }
	}

	local waves = {}
	local wave_count = afterlife.get_variable("afterlife_wave_count_") or 10
	for _, side in ipairs(wesnoth.sides) do
		local diff = (wave_count < 7 and 2) or (wave_count < 10 and 1) or 0
		side.village_gold = side.village_gold + diff
		side.village_support = side.village_support + diff
	end
	for idx = 0, wave_count - 1 do
		local step = wave_count > 12 and 35 / (wave_count - 1) or 35 / 11
		local y = math.floor(41 - idx * step + 0.5)
		waves[#waves + 1] = { y = y }
	end
	waves.strength = function(idx) return math.floor(40 + 30 * (idx - 1) / (#waves - 1) + 0.5) end

	local map_width, map_height, map_border = wesnoth.get_map_size()
	local left_label, right_label = map_border + math.floor(map_width * 1 / 4), map_border + math.floor(map_width * 3 / 4)

	local function copy_units(from_side, to_side, copy_strength, y_min)
		for _, unit_original in ipairs(wesnoth.units.find_on_map { side = from_side }) do
			local to_pos = afterlife.find_vacant(unit_original, y_min)
			afterlife.copy_unit(unit_original, to_pos, to_side, copy_strength)
		end
	end

	local function generate_wave(side)
		local prev_distance = afterlife.get_variable("afterlife_distance_" .. side) or map_height + 1
		local units = wesnoth.units.find_on_map { side = side }
		table.sort(units, function(a, b) return a.y > b.y end)
		local new_distance = math.min(prev_distance, units[#units].y)
		afterlife.set_variable("afterlife_distance_" .. side, new_distance)
		for idx, wave_info in ipairs(waves) do
			if new_distance <= wave_info.y and prev_distance > wave_info.y then
				(wesnoth.label or wesnoth.wml_actions.label) {
					x = side == human_side1 and left_label or right_label,
					y = wave_info.y,
					text = "",
				}
				copy_units(sides[side].enemy_human, sides[side].enemy_ai, waves.strength(idx), wave_info.y - 7)
			end
		end
	end

	local function check_win(side)
		if (side == human_side1 or side == human_side2)
			and afterlife.get_variable("afterlife_distance_" .. side) <= waves[#waves].y
			and not wesnoth.wml_conditionals.has_unit { side = sides[side].enemy_ai } then
			afterlife.endlevel_team(wesnoth.sides[side].team_name)
		end
	end

	local function green_to_red(frac)
		local red = math.min(255, math.ceil(frac * 2 * 255))
		local green = math.min(255, math.ceil(255 * 2 - frac * 2 * 255))
		return { red, green, 0, 255 }
	end

	function afterlife.prestart_event()
		for _, side in ipairs(wesnoth.sides) do
			side.village_support = side.village_support + 1
		end
		afterlife.kill_ai_leaders()
		for wave_index, wave_info in ipairs(waves) do
			for _, x in ipairs { left_label, right_label } do
				(wesnoth.label or wesnoth.wml_actions.label) {
					x = x,
					y = wave_info.y,
					color = green_to_red(wave_index / #waves),
					text = "____" .. waves.strength(wave_index) .. "%____",
				}
			end
		end
	end

	local function turn_refresh_event()
		if wesnoth.current.side == 1 then
			generate_wave(human_side1)
			generate_wave(human_side2)
		end
		if wesnoth.current.side == human_side2 then
			check_win(human_side1)
		end
		if wesnoth.current.side == human_side1 then
			check_win(human_side2)
		end
		afterlife.unpetrify_units()
	end

	function afterlife.die_event()
		check_win(sides[wesnoth.current.side].half_owner)
	end

	on_event("start", function()
		for _ = 0, 46 do
			afterlife.scroll_terrain_down()
		end
		wesnoth.wml_actions.redraw {}
	end)
	afterlife.turn_refresh_event = turn_refresh_event
	afterlife.schedule_attack_abort_triggers()
end
