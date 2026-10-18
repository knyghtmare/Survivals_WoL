local helper = wesnoth.require("helper")
local _ = wesnoth.textdomain 'wesnoth-multiplayer'
local T = wml.tag
local on_event = wesnoth.require("on_event")

-- generic functions

local function sum_table_values(table)
    local response = 0
    for str,val in pairs(table) do response = response + val end
    return response
end

local function sum_array_values(t)
    local response = 0
    for index,value in ipairs(t) do
        response = response + value
    end
    return response
end

function map(t, f)
    local response = {}
    for index,value in ipairs(t) do
        table.insert(response, f(index,value))
    end
    return response
end

function for_each_index(t,f)
    for index,value in ipairs(t) do
        f(index,value)
    end
end

function for_each_key(t,f)
    for key, value in pairs(t) do
        f(key,value)
    end
end

function key_map(t,f)
    local response = {}
    for key, value in pairs(t) do
        response[key] = f(key, value)
    end
    return response
end

function key_transform(t,f)
    local response = {}
    for key_string,value in pairs(t) do
        local result = f(key_string,value)
        response[result.key] = result.value
    end
    return response
end

function array_table_transform (t,f)
    local response = {}
    for index, value_literal in ipairs(t) do
        local result = f(index, value_literal)
        response[result.key] = result.value
    end
    return response
end

local function sequence_generator(initial_value, f, length)
    local counter = 0
    local response = {}
    response[1] = initial_value
    while counter < length do
        counter = counter + 1
        response[counter + 1] = f(response[counter])
    end
    return response
end


local function mutate_table(table, f)
  for index, value in ipairs(table) do table[index] = f(value, index) end
end

local function populate_tables(count)
  local parent_table = {}
  for i = 1, count do
    table.insert(parent_table, {})
  end
  return parent_table
end

local function another_sort_of_keys(t)
    local ordered_map = {}
    for k, v in pairs(t) do
        table.insert(ordered_map, k)
    end
    table.sort(ordered_map)
    return ordered_map
end

local function table_aggregator_commutative_only(t, f)
    local aggregate = {}
    local container = {}
    local initialized = false
    local counter = 1
    for key,value in pairs(t) do
        if initialized == false then
            aggregate[1] = key
            aggregate[2] = value
            initialized = true
        else
            container[0] = f(aggregate[1], aggregate[2], key,value)
            for k,v in pairs(container[0]) do
                aggregate[1] = k
                aggregate[2] = v
            end
        end
    end
    return aggregate
end

local function compose(f,g)
    return function(...)
        return f(g(...))
    end
end

--[[
local function ordered_map_of_keys(t, predicate_function)
    local ordered_map = {}
    local symmetric_error = false
    local transitive_error = false -- no test
    local temporary = 0
    local counter = 1
    local counter_two = 1

    for key,value in pairs(t) do
        ordered_map[counter] = key
        counter = counter + 1
    end

    if #table < 2 return ordered_map end

    for index, val in ipairs(ordered_map) do
        counter_two = 1
        while counter_two < #t do
            if predicate_function(ordered_map[counter_two], ordered_map[counter_two + 1]) == true then
                if predicate_function(ordered_map[counter_two + 1], ordered_map[counter_two]) == true then symmetric_error = true end
                temporary = ordered_map[counter_two]
                ordered_map[counter_two] = ordered_map[counter_two + 1]
                ordered_map[counter_two + 1] = temporary
            else if predicate_function(ordered_map[counter_two], ordered_map[counter_two + 1]) == false and predicate_function(ordered_map[counter_two + 1], ordered_map[counter_two]) == false then symmetric_error = true end
            end
            counter_two = counter_two + 1
        end
    end

    if symmetric_error == true then error("symmetric predicate function in ordered map") end
    return ordered_map
end
]]--


-- math functions

function normalized_gaussian_function(x,sigma,mu)
    return 1/((sigma * math.sqrt(2*math.pi)) * math.exp(-(((x-mu)^2)/(2*sigma^2))))
end

function gaussian_function(x,a,b,c)
    return a * math.exp(-(((x-b)^2)/(2*c^2)))
end

local function nested_radical_constant(n)
    local response = 0
    for i=0,n do
        response = math.sqrt(response + n - i)
    end
    return response
end

function weighted_random(odds)
    local total = sum_array_values(odds)
    local normalized = map(odds, function(i,v) return v / total end)
    local target = wesnoth.random()
    local sum = 0.0
    local counter = 1
    for index=1, #odds do
        sum = sum + normalized[counter]
        if target < sum then
            break
        end
        counter = counter + 1
    end
    return counter
end


local minor_spawns = {
    {
        {"Peasant", "more", "more", "more"},
        {"Woodsman", "more", "more", "more"},
    },
	{
		{"Dark Adept", "Dark Sorcerer", "Necromancer", "more"},
		{"Walking Corpse", "more", "more", "more"},
		{"Walking Corpse", "more", "more", "more"},
		{"Walking Corpse", "more", "more", "more"},
	},
    {
		{"Dwarvish Fighter", "Dwarvish Steelclad", "more", "Dwarvish Lord"},
		{"Dwarvish Thunderer", "more", "more", "Dwarvish Thunderguard"},
		{"Dwarvish Guardsman", "Dwarvish Stalwart", "none", "none"},
    },
	{
		{"Giant Mudcrawler", "Sea Serpent", "none", "none"},
		{"Mudcrawler", "more", "Giant Mudcrawler", "more"},
	},
	{
		{"Skeleton Archer", "Bone Shooter", "more", "Banebow"},
		{"Fencer", "Duelist", "none", "Master at Arms"},
		{"Drake Glider", "Sky Drake", "Hurricane Drake", "none"},
	},
	{
		{"Walking Corpse", "more", "more", "more"},
		{"Mage", "White Mage", "Mage of Light", "none"},
		{"Thug", "Bandit", "more", "none"},
	},
    {
        {"Spearman", "more", "more", "more"},
        {"Bowman", "more", "more", "more"},
    },
}

local loyalist_spawns = {
    {
        {"Spearman", "Pikeman", "more", "more"},
        {"Bowman", "Longbowman", "more", "more"},
        {"Cavalryman", "Dragoon", "more", "Cavalier"},
    },
    {
        {"Swordsman", "more", "more", "Royal Guard"},
        {"Heavy Infantryman", "Shock Trooper", "Iron Mauler", "more"},
        {"White Mage", "more", "more", "Mage of Light"},
    },
    {
		{"Fencer", "Duelist", "none", "Master at Arms"},
        {"Javelineer", "more", "none", "none"},
        {"Peasant", "Spearman", "Pikeman", "more"},
        {"Woodsman", "Bowman", "Longbowman", "more"},
    },
    {
        {"Merman Fighter", "Merman Warrior", "more", "Merman Triton"},
        {"Cavalryman", "Dragoon", "more", "Cavalier"},
        {"Fencer", "Duelist", "none", "Master at Arms"},
    },
    {
        {"Sergeant", "more", "more", "none"},
		{"Spearman", "Pikeman", "none", "Halberdier"},
        {"Woodsman", "Bowman", "Longbowman", "more"},
    },
}

local knalgan_rebel_spawns = {
    {
		{"Elvish Fighter", "Elvish Hero", "more", "Elvish Champion"},
		{"Elvish Fighter", "Elvish Captain", "Elvish Marshal", "none"},
		{"Thief", "Rogue", "more", "Assassin"},
    },
	{
		{"Elvish Shaman", "Elvish Druid", "Elvish Shyde", "Elvish Sylph"},
		{"Wose", "more", "Elder Wose", "Ancient Wose"},
		{"Dwarvish Guardsman", "Dwarvish Stalwart", "none", "none"},
	},
	{
		{"Poacher", "Ranger", "more", "none"},
		{"Trapper", "Huntsman", "more", "none"},
		{"Elvish Archer", "Elvish Ranger", "more", "Elvish Avenger"},
		{"Elvish Scout", "Elvish Rider", "more", "Elvish Outrider"},
	},
	{
		{"Dwarvish Fighter", "Dwarvish Steelclad", "more", "Dwarvish Lord"},
		{"Elvish Archer", "Elvish Marksman", "none", "Elvish Sharpshooter"},
		{"Elvish Shaman", "Elvish Druid", "Elvish Shyde", "Elvish Sylph"},
		{"Elvish Shaman", "Elvish Sorceress", "Elvish Enchantress", "Elvish Sylph"},
	},
	{
		{"Ruffian", "Footpad", "Outlaw", "more"},
		{"Ruffian", "Thug", "Bandit", "Highwayman"},
		{"Elvish Fighter", "Elvish Captain", "Elvish Marshal", "none"},
	},
}

local undead_monster_spawns = {
    {
        {"Dark Adept", "Dark Sorcerer", "Necromancer", "more"},
        {"Giant Scorpion", "more", "more", "none"},
        {"Wolf", "more", "Great Wolf", "Dire Wolf"},
    },
    {
        {"Ghost", "more", "more", "Wraith"},
        {"Water Serpent", "more", "more", "none"},
		{"Skeleton Archer", "Bone Shooter", "more", "Banebow"},
    },
    {
        {"Ghoul", "Necrophage", "Ghast", "none"},
        {"Sea Serpent", "more", "more", "none"},
        {"Vampire Bat", "Blood Bat", "Dread Bat", "more"},
		{"Walking Corpse", "more", "more", "Soulless"},
    },
    {
        {"Death Knight", "more", "none", "none"},
        {"Giant Rat", "more", "more", "more"},
		{"Walking Corpse", "more", "more", "Soulless"},
    },
    {
        {"Lich", "more", "none", "none"},
        {"Giant Spider", "more", "more", "more"},
		{"Skeleton Archer", "Bone Shooter", "more", "Banebow"},
    },
    {
        {"Young Ogre", "Ogre", "more", "none"},
		{"Skeleton", "Revenant", "more", "Draug"},
        {"Ghost", "Shadow", "none", "none"},
    },
}

local major_spawns = {
	{
		{"Heavy Infantryman", "Shock Trooper", "Iron Mauler", "none"},
		{"Elvish Fighter", "Elvish Hero", "more", "Elvish Champion"},
		{"Goblin Spearman", "more", "more", "more"},
		{"Goblin Spearman", "Goblin Rouser", "none", "none"},
		{"Elvish Fighter", "Elvish Captain", "Elvish Marshal", "none"},
	},
	{
		{"Merman Hunter", "Merman Spearman", "Merman Entangler", "none"},
		{"Naga Fighter", "Naga Warrior", "Naga Myrmidon", "none"},
		{"Spearman", "Pikeman", "none", "Halberdier"},
	},
	{
		{"Yeti", "more", "none", "none"},
        {"Mage", "Silver Mage", "none", "none"},
	},
	{
		{"Saurian Augur", "Saurian Oracle", "more", "none", },
        {"Dwarvish Ulfserker", "Dwarvish Berserker", "more", "none"},
		{"Drake Clasher", "Drake Thrasher", "more", "Drake Enforcer"},
	},
	{
		{"Elvish Shaman", "Elvish Druid", "Elvish Shyde", "Elvish Sylph"},
		{"Drake Burner", "Fire Drake", "Inferno Drake", "Armageddon Drake"},
		{"Heavy Infantryman", "Shock Trooper", "Iron Mauler", "none"},
	},
	{
		{"Elvish Shaman", "Elvish Druid", "Elvish Shyde", "Elvish Sylph"},
		{"Wose", "more", "Elder Wose", "Ancient Wose"},
		{"Elvish Fighter", "Elvish Hero", "more", "Elvish Champion"},
	},
	{
		{"Deathblade", "none", "none", "none"},
		{"Vampire Bat", "Blood Bat", "Dread Bat", "more"},
        {"Vampire Bat", "more", "more", "none"},
        {"Dark Adept", "Dark Sorcerer", "Necromancer", "none"},
	},
	{
		{"Mage", "Red Mage", "none", "none"},
		{"Drake Burner", "Fire Drake", "Inferno Drake", "Armageddon Drake"},
		{"Drake Fighter", "Drake Warrior", "Drake Blademaster", "none"},
		{"Drake Clasher", "Drake Thrasher", "more", "Drake Enforcer"},
	},
	{
		{"Ghoul", "Necrophage", "more", "none"},
		{"Elvish Archer", "Elvish Marksman", "none", "Elvish Sharpshooter"},
		{"Elvish Archer", "Elvish Ranger", "Elvish Avenger", "none"},
		{"Drake Clasher", "Drake Thrasher", "more", "Drake Enforcer"},
	},
	{
		{"Merman Fighter", "Merman Warrior", "more", "Merman Triton"},
		{"Dark Adept", "Dark Sorcerer", "Necromancer", "none"},
		{"Elvish Scout", "Elvish Rider", "more", "none"},
	},
	{
		{"Wose", "Elder Wose", "Ancient Wose", "none"},
		{"Orcish Archer", "Orcish Crossbowman", "Orcish Slurbow", "none"},
		{"Saurian Skirmisher", "more", "Saurian Ambusher", "more"},
	},
	{
		{"Orcish Grunt", "Orcish Warrior", "more", "none"},
		{"Vampire Bat", "Blood Bat", "more", "none"},
		{"Dwarvish Thunderer", "Dwarvish Thunderguard", "none", "none"},
		{"Peasant", "more", "more", "more"},
		{"Woodsman", "more", "Sergeant", "Orcish Ruler"},
	},
	{
		{"Orcish Assassin", "Orcish Slayer", "more", "none"},
		{"Troll Whelp", "more", "more", "none"},
		{"Troll Whelp", "Troll", "Troll Warrior", "none"},
	},
	{
		{"Troll Whelp", "Troll", "Troll Warrior", "none"},
		{"Wose", "Elder Wose", "Ancient Wose", "none"},
		{"Red Mage", "none", "none", "none"},
		{"Heavy Infantryman", "Shock Trooper", "Iron Mauler", "none"},
		{"Ruffian", "Thug", "Bandit", "Highwayman"},
	},
	{
		{"Orcish Assassin", "Orcish Slayer", "more", "none"},
		{"Cavalryman", "Dragoon", "more", "Cavalier"},
		{"Saurian Augur", "Saurian Soothsayer", "none", "none"},
	},
	{
		{"Ghoul", "Necrophage", "more", "none"},
		{"Ghost", "Shadow", "more", "more"},
		{"Skeleton", "Revenant", "more", "Draug"},
		{"Skeleton Archer", "Bone Shooter", "more", "Banebow"},
	},
	{
		{"Saurian Skirmisher", "more", "Saurian Ambusher", "more"},
		{"Thief", "Rogue", "more", "Assassin"},
	},
	{
		{"Gryphon Rider", "none", "more", "none"},
		{"Thief", "Rogue", "more", "Assassin"},
        {"Wolf Rider", "more", "Goblin Knight", "none"},
	},
	{
		{"Dwarvish Fighter", "Dwarvish Steelclad", "more", "Dwarvish Lord"},
		{"Poacher", "Trapper", "more", "none"},
		{"Cuttle Fish", "more", "more", "none"},
	},
}

local easter_egg_spawns = {
    {},
}

local function get_spawn_types(num_units, max_gold, unit_pool)
	local gold_left = max_gold
	local units_left = num_units
	local current_types = {}
	while gold_left > 0 and units_left > 0 do
		local unit_group = wesnoth.random(#unit_pool)
		local unit_rank = 1
		local unit_type = wesnoth.unit_types[unit_pool[unit_group][unit_rank]]
		table.insert(current_types, { group = unit_group, type =  unit_type})
		gold_left = gold_left - unit_type.cost
		units_left = units_left - 1
	end
	-- Upgrade units, eigher by replacing them with better units or by duplicating them.
	for next_rank = 2,4 do
		local next_types = {}
		for i,v in ipairs(current_types) do
			local advanceto = unit_pool[v.group][next_rank] or ""
			local unit_type = wesnoth.unit_types[advanceto]
			if unit_type then
				local upgrade_cost = math.ceil((unit_type.cost - v.type.cost) * 1.25)
				if gold_left >= upgrade_cost then
					gold_left = gold_left - upgrade_cost
					table.insert(next_types, { group = v.group, type = unit_type})
				else
					table.insert(next_types, { group = v.group, type = v.type})
				end
			elseif advanceto == "more" then
				local upgrade_cost = v.type.cost + 2
				if gold_left >= upgrade_cost then
					gold_left = gold_left - upgrade_cost
					table.insert(next_types, { group = v.group, type = v.type})
				end
				table.insert(next_types, { group = v.group, type = v.type})
			else
				table.insert(next_types, { group = v.group, type = v.type})
			end
		end
		current_types = next_types
	end
	--spend remaining gold
	local min_cost = 100
	for i,v in ipairs(unit_pool) do
		min_cost = math.min(min_cost, wesnoth.unit_types[v[1]].cost)
	end
	while gold_left >= min_cost do
		local possible_groups = {}
		for i,v in ipairs(unit_pool) do
			local unit_type = wesnoth.unit_types[v[1]]
			if unit_type.cost <= gold_left then
				table.insert(possible_groups, { group = i, type = unit_type})
			end
		end
		local index = wesnoth.random(#possible_groups)
		table.insert(current_types, possible_groups[index])
		gold_left = gold_left - possible_groups[index].type.cost
	end
	local res = {}
	for i,v in ipairs(current_types) do
		table.insert(res, v.type.id)
	end
	return res
end


local function gold_per_wave_coefficient(turns_over_max_turns)
    local x = turns_over_max_turns
    local term_one = math.sin((3.223 * math.pi)/(1 + math.exp(-x)))
    local term_two = (math.sin(x + 2 * math.pi))/math.pi^2
    local term_three = (math.cos(math.cos(28*x)))/math.pi
    local result = (term_one + term_two + term_three + 2.4)/3
    return result
end


local function choose_random_index(t)
    return t[wesnoth.random(#t)]
end

local logging = 1

local function choose_random_spawn_group(turn)
    local weighted_table_pointers = {
        { pointer = minor_spawns, a = 1 , b = 0, c = 3, },
        { pointer = loyalist_spawns, a = 1 , b = 16,  c = 7,  },
        { pointer = knalgan_rebel_spawns, a = 1 , b = 18,  c = 7,  },
        { pointer = undead_monster_spawns, a = 1 , b = 20,  c = 7,  },
        { pointer = major_spawns, a = 1 , b = 32 ,  c = 9,  },
    }
    local resolved_weights_table = map(weighted_table_pointers,
        function (index,value)
            return gaussian_function(turn, value.a, value.b, value.c)
        end
    )
    if logging == 1 then
        for_each_index(weighted_table_pointers, function (index, value) for_each_key(value, function (key,val) print(key, val) end) end)
        for_each_index(resolved_weights_table, function (i,v) print(i, v) end)
        print(weighted_random(resolved_weights_table))
        logging = 0
    end
    local selected_index = weighted_random(resolved_weights_table)
    print(selected_index)
    return choose_random_index(weighted_table_pointers[selected_index].pointer)
end

-- local pools = {}

-- creates the 'timed_spawn' wml array.
-- @a num_spawns: the total number of times units get spawned
-- @a interval: the number of turns between 2 spawns
-- @a base_gold_amount, gold_increment: used to cauculate the amount of gold available for each timed spawn
-- @a units_amount, gold_per_unit_amount: used to cauculate the number of units spawned in each timed spawn
local function create_timed_spaws(interval, num_spawns, base_gold_amount, gold_increment, units_amount, gold_per_unit_amount)
	local configure_gold_factor = ((wml.variables["enemey_gold_factor"] or 0) + 100)/100
	local final_turn = math.ceil((num_spawns) * interval + wesnoth.random(3,5))
	local end_spawns = 0
	for spawn_number = 1, num_spawns do
		local turn = 3 + (spawn_number - 1) * interval
        local turn_ratio = turn / (final_turn + 10)
		local gold = base_gold_amount + ((turn - 3) * gold_increment) * gold_per_wave_coefficient(turn_ratio)
        -- foruma taken from original Dark forecast, TODO: find easier formula.
        local unit_gold = (turn - 3) * gold_increment + math.min(wesnoth.random(base_gold_amount), wesnoth.random(base_gold_amount))
        local gold_per_unit = gold_per_unit_amount + turn / 1.5
        local units = unit_gold / gold_per_unit + units_amount + wesnoth.random(-1, 2)
        if wesnoth.random(5) == 5 then
            units = units - 1
        end
        -- end complicated formula
        turn = turn + wesnoth.random(-1, 1)
        -- reduce gold and units for spawns after the final spawn
        if turn >= final_turn then
            units = units / (end_spawns + 3)
            gold = gold / (end_spawns + 4)
            end_spawns = end_spawns + 1
            -- we only want two spawns after the final turn.
            if end_spawns > 2 then
                break
            end
        end
        -- pools[turn] = choose_random_spawn_group(turn)
        wml.variables[string.format("timed_spawn[%d]", spawn_number - 1)] = {
            units = math.ceil(units),
            turn = turn,
            gold = helper.round(gold * configure_gold_factor),
        }
	end
	wml.variables["final_turn"] = final_turn
end

local new_turn_event_array = {}

--[[
local function kool (turn)
    if turn == 13 and wesnoth.random() > 0.99 then
        local leaders = wesnoth.get_units { side = "3,4,5", canrecruit = true }
        if #leaders == 3 then
            local locations = wesnoth.get_locations({"14", "19"}, radius=1, include_borders = false)
            local kool_gummy_bear = wesnoth.create_unit{ type = "goblin", name = "Kool Gummy Bear", side = 2 }
            kool_gummy_bear: add_modification("object", {
                T.effect {
                    apply_to = "specials",
                    -- poison
                }
            })
            local x, y = wesnoth.find_vacant_tile(locations[1], locations[2], kool_gummy_bear)
            kool_gummy_bear:to_map(x,y)
        end
    end
end

]]--
-- table.insert(new_turn_event_array, kool)
-- table.insert(new_turn_event_array, elder)


local function new_turn_event_handler(turn)
    if #new_turn_event_array > 1 then
        for_each_index(new_turn_event_array, function (i,v) v(turn) end)
    end
end

-- @a unittypes: a array of strings
-- @a x,y: the location where to spawn the units on the map.
local function place_units(unittypes, x, y)
	for i,v in ipairs(unittypes) do
		local u = wesnoth.create_unit { type = v, generate_name = true, side = 2 }
		u:add_modification("object", {
			T.effect {
				apply_to = "movement_costs",
				replace = true,
				T.movement_costs {
					deep_water = 3,
				}
			}
		})
		-- give the unit less moves on its first turn.
		u.status.slowed = true
		u:add_modification("object", {
			duration = "turn end",
			T.effect {
				apply_to = "movement",
				increase = "-50%",
			}
		})
		local dst_x, dst_y = wesnoth.find_vacant_tile(x, y, u)
		u:to_map(dst_x, dst_y)
	end
end

local function final_spawn()
	local spawns_left = wml.variables["fixed_spawn.length"]
	if spawns_left == 0 then
		return
	end
	local spawn_index = wesnoth.random(spawns_left) - 1
	local spawn = wml.variables[string.format("fixed_spawn[%d]", spawn_index)]
	wml.variables[string.format("fixed_spawn[%d]", spawn_index)] = nil
	local types = {}
	for tag in wml.child_range(spawn, "type") do
		table.insert(types, tag.type)
	end
	place_units(types, spawn.x, spawn.y)
end

-- convert all 'veteran' units from side 2 to the more aggressive side 1
-- this must happen before the new units are created from spawns.
on_event("new turn", function()
	for i, unit in ipairs(wesnoth.get_units { side = 2 }) do
		unit.side = 1
	end
end)

on_event("prestart", function()
	local leaders = wesnoth.get_units { side = "3,4,5", canrecruit= true}
	if #leaders < 3 then
		create_timed_spaws(4, 10, 70, 4, 4, 22)
	else
		create_timed_spaws(3, 14, 75, 5, 5, 24)
	end
end)

-- the regular spawns:
--   when they appear is defined in the 'timed_spawn' wml array. which is created at prestart
--   which unit types get spawned is defined in the 'main_spawn' wml array which is also spawned at prestart
on_event("new turn", function()
    new_turn_event_handler(wesnoth.current.turn)
	local next_spawn = wml.variables["timed_spawn[0]"]
	if next_spawn == nil then
		return
	end
	if wesnoth.current.turn ~= next_spawn.turn then
		return
	end
	wml.variables["timed_spawn[0]"] = nil
  -- local unit_pool_temp = pools[wesnoth.current.turn]
	local unit_pool_temp = choose_random_spawn_group(next_spawn.turn)
	local unit_types = get_spawn_types(next_spawn.units, next_spawn.gold, unit_pool_temp)
	local spawn_areas = {{"11-12", "1-2"}, {"27-29", "1-2"}, {"34", "8-9"}, {"34", "14-16"},{"31-33", "21"},{"21-23", "23"},{"11-13", "23"},{"4", "17-18"},{"4", "6-9"},}
	local spawn_area = spawn_areas[wesnoth.random(#spawn_areas)]
	local locations_in_area = wesnoth.get_locations { x = spawn_area[1], y = spawn_area[2], radius=1, include_borders=false }
	local chosen_location = locations_in_area[wesnoth.random(#locations_in_area)]
	place_units(unit_types, chosen_location[1], chosen_location[2])
end)

-- on turn 'final_turn' the first 'final spawn' appears
on_event("new turn", function()
	if wesnoth.current.turn ~= wml.variables["final_turn"] then
		return
	end
	wesnoth.wml_actions.music {
		name = "battle.ogg",
		ms_before = 200,
		immediate = true,
		append = true,
	}
	final_spawn()
	wesnoth.game_config.last_turn = wesnoth.current.turn + 12
	wesnoth.wml_actions.message {
		side="3,4,5",
		canrecruit=true,
		message= _ "The last and most powerful of these creatures are almost upon us. I feel that if we can finish them off in time, we shall be victorious.",
	}
end)

-- after the first final spawn, spawn a new final spawn every 1 or 2 turns.
on_event("new turn", function()
	if wesnoth.current.turn ~= wml.variables["next_final_spawn"] then
		return
	end
	final_spawn()
	wml.variables["next_final_spawn"] = wesnoth.current.turn + wesnoth.random(1,2)
end)

-- The victory condition: win when there are no enemy unit after the first final spawn appeared.
on_event("die", function()
	if wesnoth.current.turn < wml.variables["final_turn"] then
		return
	end
	if wesnoth.wml_conditionals.have_unit { side = "1,2"} then
		return
	end
	wesnoth.wml_actions.music {
		name = "victory.ogg",
		play_once = true,
		immediate = true,
	}
	wesnoth.wml_actions.message {
		speaker = "narrator",
		message = _"The screams and pleas for mercy are finally silenced, as you remove your blood soaked blade from the last of the rebels. There will be no more resistance from the local scum. Your reign has finally earned stability.",
		image ="wesnoth-icon.png",
	}
	wesnoth.wml_actions.endlevel {
		result = "victory",
	}
end)

-- initilize the 'fixed_spawn' and 'main_spawn'
on_event("prestart", function()
	local fixed_spawn = function(x, y, ...)
		local res = { x = x, y = y }
		for i,v in ipairs {...} do
			table.insert(res, T.type { type = v })
		end
		return res
	end
	wml.array_access.set("fixed_spawn", {
		fixed_spawn(14, 19, "Ancient Lich", "Draug", "Draug", "Draug", "Banebow", "Banebow"),
		fixed_spawn(32, 5, "Lich", "Spectre", "Spectre", "Wraith", "Nightgaunt", "Nightgaunt", "Shadow"),
		fixed_spawn(20, 2, "Mermaid Enchantress", "Merman Triton", "Merman Triton", "Merman Triton", "Merman Entangler", "Merman Entangler"),
		fixed_spawn(31, 21, "Fire Dragon", "Armageddon Drake",  "Fire Drake", "Fire Drake", "Fire Drake", "Hurricane Drake"),
		fixed_spawn(6, 7, "Skeletal Dragon", "Ghast",  "Necrophage", "Necrophage"),
	})
end)

-------------------------------------------------------------------------------
-------------------------- Weather events -------------------------------------
-------------------------------------------------------------------------------
-- The weather evens are complateleey unrelated to the spawn events.

local function get_weather_duration(max_duration)
	local res = wesnoth.random(3)
	while res < max_duration and wesnoth.random() < 0.6 do
		res = res + 1
	end
	return res
end

local function get_next_weather_table(previous_weather)
    if previous_weather == "clear" then return              { ["clear"] = 5, ["drought"] = 3, ["rain"] = 2, ["snowfall"] = 1,     } end
    if previous_weather == "drought" then return            { ["clear"] = 2, ["drought"] = 1, ["desert"] = 1,                     } end
    if previous_weather == "desert" then return             { ["drought"] = 1, ["desert"] = 1,                                    } end
    if previous_weather == "rain" then return               { ["clear"] = 3, ["rain"] = 2, ["heavy rain"] = 1,                    } end
	if previous_weather == "heavy rain" then return         { ["rain"]  = 3, ["heavy rain"] = 1,                                  } end
    if previous_weather == "snowfall" then return           { ["clear"] = 3, ["snowfall"] = 2, ["heavy snowfall"] = 1,            } end
	if previous_weather == "heavy snowfall" then return     { ["snowfall"] = 3, ["heavy snowfall"] = 2, ["heavier snowfall"] = 1, } end
	if previous_weather == "heavier snowfall" then return   { ["heavy snowfall"] = 2, ["heavier snowfall"] = 1                    } end
    error("no weather was chosen")
end

local function weathertable_to_random_weather(weather_table)
    local dice_roll = wesnoth.random(sum_table_values(weather_table))
    local ordered_map = another_sort_of_keys(weather_table)
    local sum = 0
    local response = ""
    for index,value in ipairs(ordered_map) do
        sum = sum + weather_table[value]
        if dice_roll <= sum then
            response = value
            break
        end
    end
    return response
end

local function previous_weather_to_new_random_weather(previous_weather)
    local weather_table = get_next_weather_table(previous_weather)
    local response = weathertable_to_random_weather(weather_table)
    return response
end

-- initilize the weather_event wml array which defines at which turns the weather changes.
on_event("prestart", function()
	local event_num = 0
    local max_weather_duration = 8
	local turn = wesnoth.random(4,6)
	local num_turns = get_weather_duration(max_weather_duration)
	local weather_id = "clear"
    local roll = 0
    local weather_arrays = sequence_generator("clear", previous_weather_to_new_random_weather, 100)


	for index,value in ipairs(weather_arrays) do
            num_turns = get_weather_duration(max_weather_duration)
            wml.variables[string.format("weather_event[%d]", event_num)] = { turn = turn, weather_id = value, }
            event_num = event_num + 1
            turn = turn + num_turns
    end
end)

local function weather_alert(text, red, green, blue)
	wesnoth.wml_actions.print {
		text = text,
		duration = 120,
		size = 26,
		red = red,
		green = green,
		blue = blue,
	}
end

local function weather_map(name)
	wesnoth.wml_actions.terrain_mask {
		mask = filesystem.read_file(name),
		x = 1,
		y = 1,
		border = true,
	}
	wesnoth.redraw {}
end

-- change weather at side 3 turns, TODO: consider the case that side 3 is empty.
on_event("side 3 turn", function()
	-- get next weather event
	local weather_event = wml.variables["weather_event[0]"]
	if weather_event == nil then
		return
	end
	if wesnoth.current.turn ~= weather_event.turn then
		return
	end
	-- remove the to-be-consumed weather event from the todo list.
	wml.variables["weather_event[0]"] = nil
	if weather_event.weather_id == "clear" then
		weather_map("~add-ons/Survivals_WoL/maps/murky_weathercast/3p_murky_weathercast_basic.map")
		wesnoth.wml_actions.sound {
			name = "magic-holy-miss-2.ogg",
		}
		weather_alert(_"Clear Weather", 221, 253, 171)
	elseif weather_event.weather_id == "drought" then
		weather_map ("~add-ons/Survivals_WoL/maps/murky_weathercast/3p_murky_weathercast_drought.map")
		wesnoth.wml_actions.sound {
			name = "gryphon-shriek-1.ogg",
		}
		weather_alert(_"Drought", 251, 231, 171)
	elseif weather_event.weather_id == "desert" then
		weather_map ("~add-ons/Survivals_WoL/maps/murky_weathercast/3p_murky_weathercast_desert.map")
		wesnoth.wml_actions.sound {
			name = "gryphon-shriek-1.ogg",
		}
		weather_alert(_"Drought", 251, 231, 171)
	elseif weather_event.weather_id == "rain" then
		weather_map("~add-ons/Survivals_WoL/maps/murky_weathercast/3p_murky_weathercast_rain.map")
		wesnoth.wml_actions.sound {
			name = "magic-faeriefire-miss.ogg",
		}
		wesnoth.wml_actions.delay {
			time = 250,
		}
		wesnoth.wml_actions.sound {
			name = "ambient/ship.ogg",
		}
		weather_alert(_"Heavy Rains", 174, 220, 255)
	elseif weather_event.weather_id == "heavy rain" then
		weather_map("~add-ons/Survivals_WoL/maps/murky_weathercast/3p_murky_weathercast_heavyrain.map")
		wesnoth.wml_actions.sound {
			name = "magic-faeriefire-miss.ogg",
		}
		wesnoth.wml_actions.delay {
			time = 250,
		}
		wesnoth.wml_actions.sound {
			name = "ambient/ship.ogg",
		}
		weather_alert(_"Heavy Rains", 174, 220, 255)
	elseif weather_event.weather_id == "snowfall" then
		weather_map("~add-ons/Survivals_WoL/maps/murky_weathercast/3p_murky_weathercast_firstsnow.map")
		wesnoth.wml_actions.sound {
			name = "wail.wav",
		}
		weather_alert(_"Snowfall", 229, 243, 241)
	elseif weather_event.weather_id == "heavy snowfall" then
		weather_map("~add-ons/Survivals_WoL/maps/murky_weathercast/3p_murky_weathercast_secondsnow.map")
		wesnoth.wml_actions.sound {
			name = "bat-flapping.wav",
		}
		weather_alert(_"Heavy Snowfall", 224, 255, 251)
	elseif weather_event.weather_id == "heavier snowfall" then
		weather_map("~add-ons/Survivals_WoL/maps/murky_weathercast/3p_murky_weathercast_thirdsnow.map")
		wesnoth.wml_actions.sound {
			name = "bat-flapping.wav",
		}
		weather_alert(_"Heavier Snowfall", 224, 255, 251)
	else
		error("unknown weather '" .. tostring(weather_event.weather_id) .. "'")
	end
end)
