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
    local i = 1
    sum = sum + normalized[1]
        while sum <= target and i <= #odds do
        sum = sum + normalized[i]
        i = i + 1
    end
    return i
end
