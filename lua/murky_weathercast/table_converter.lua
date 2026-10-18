--Wesnoth Table Converter by Choicerer
local lib = {}

local function is_integer(v)
	local n = tonumber(v)
	if n ~= nil then
		return n
	else 
		return v
	end
end

local function convert_to_lua_table_wrapped(t)	
	local lua_table = {}
	for i,v in pairs (t) do
		if (type(v) == "table") then							--We want to know if the value that used to be the index/key in our lua table
			lua_table[is_integer(v[1])] = convert_to_lua_table_wrapped(v[2])	--is convertible to an integer, if it is, we will convert it back to an index.
		else 
			lua_table[is_integer(i)] = v
		end
	end
	return lua_table
end

function lib.convert_to_lua_table(t)
	local lua_table = {}
	for i,v in pairs (t[1]) do   --Note the t[1], we must get rid of the initial [1] during our first iteration
		if (type(v) == "table") then
			lua_table[is_integer(v[1])] = convert_to_lua_table_wrapped(v[2])			
		else		    
			lua_table[is_integer(i)] = v
		end
	end
	return lua_table		
end	

local function convert_to_wml_table_wrapped(t)
	local wml_table = {}
	local subtable_index = 1		--We need to keep track of the number of elements in our subtables
	for i, v in pairs(t) do
		if (type(v) == "table") then				
			wml_table[subtable_index] = { }		
			wml_table[subtable_index][2]= convert_to_wml_table_wrapped(t[i])    --The contents of the table are pushed to subindex 2
			wml_table[subtable_index][1] = i                                    --While the previous table key becomes the value of subindex 1
			subtable_index = subtable_index + 1
		else
			if (type(i) ~= "string") then                                       --Wml tables can only have keys, indices serve a special function.
				i=tostring(i)												
			end
			wml_table[i] = v
		end
	end			
	return wml_table
end

function lib.convert_to_wml_table(t)
	local wml_table = {}
	wml_table = convert_to_wml_table_wrapped(t)
	wml_table = { [1] = wml_table }				--Append the whole table to index [1]
	return wml_table
end

return lib
